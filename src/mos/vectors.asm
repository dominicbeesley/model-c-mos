
		.include "nat-layout.inc"
		.include "hardware.inc"
		.include "cop.inc"
		.include "vectors.inc"
		.include "debug.inc"

		.export bbcEmu2NatVectorEntry
		.export vector_next
		.export COP_08
		.export AddToVector

;TODO: how should a vector signal "claimed" and not pass on to next?
;TODO: currently can store 0 on stack above return address to cancel [TODO: API: DOCUMENT]


		.segment "BBCCODE"

	; we are still running from the MOS rom in bank 0, we need
	; to enter native mode 
	; we've got here via an entry shim the stack will be
	;	
	; 	Stack
	;	+3..4	return address-1 [depends on which vector, usually ready for an RTS (for IRQ1/2/BRK ready for an RTI)] - only works for RTS type vectors at present
	; 	+1..2	shim "return" address+2 (used to calculate index of vector*3)

	; TODO: This doesn't work for IRQ1/2/BRK!

		; enter here in emu mode
		.a8
		.i8
bbcEmu2NatVectorEntry:
		php							; caller's flags
		pea	bbcEmu2NatVectorEntry_ff >> 8
		pea	$04 + ((<bbcEmu2NatVectorEntry_ff) << 8) 	; flags, all off except I
		pea	5						; bring 5 bytes of stack with us
		jml	emu2nat_rti

		;stack
		;	+2..3	return address to entry shim+2
		;	+1	P

		.code
bbcEmu2NatVectorEntry_ff:	
	; Now we want to execute the right routine

		.a16			; these set in code above
		.i16

		pha

		;stack
		;	+6..7	caller's return address-1
		;	+4..5	return address to entry shim+2
		;	+3	P
		;	+1..2	A


		lda	4,S
		sec
		sbc	#.loword(tblNatShims+2)
		; A now contains IX*3
		tcd
		pla
		plp
		jsr	callNativeVectorChain


		;stack
		;	+3..4   caller's return address-1
		;	+1..2	return address to entry shim+-1
		php
		rep	#$30
		.a16
		.i16
		pha
		tsc
		tcd

		;stack/DP
		;	+6..7   Vector callers rts address
		;	+4..5	return address to entry shim+-1
		;	+3	P
		;	+1..2	A

		inc	6	; make return address suitable for rti
		lda	2
		and	#$FF00
		sta	4
		lda	1
		sta	2


		;stack/DP
		;	+6..7   Vector callers rts address
		;	+5	P
		;	+4	0
		;	+2..3	A
		;	+1	spare
	
		plb

		;stack
		;	+5..6	vectors caller's rti address (bank 0)
		;	+4	P
		;	+3	0
		;	+1..2	A
		pla

		jml	nat2emu_rti


		.i16
		.a16
	; DP contains index *3, A,X,Y as per vector call
callNativeVectorChain:
		php
		rep	#$38			; ensure 16 bit registers, decimal off
		pha
		tdc				; get index into A
		clc
		adc	#.loword(NAT_OS_VECS)		
		tcd
vector_loop:	
		pei	(0)			; move to next (or first) item in linked-list
		pld
		beq	vec_done
	; stack
	;	+3	Flags
	;	+1..2	A (16 bits)
		
		pla
		plp
		rep	#$38			; ensure 16 bit registers, decimal off
		phd				; save LL pointer

		pei	(b0b_ll_nat_vec::return + 1); construct stack 
		pei	(b0b_ll_nat_vec::handler+ 2)
		pei	(b0b_ll_nat_vec::handler)
		php
		pei	(b0b_ll_nat_vec::dp)
	; stack	
	;		Linked list pointer
	;		far return address to vector_next -1 (suitable for RTL)
	;		far address of handler (suitable for RTI)
	;		Flags
	;		DP			
		pld				; setup routine's DP
		rti				; branch to routine

vector_next:	rep	#$38			; ensure 16 bit regs and no decimal
		php
		pha
	; stack
	;	+4..5	LL pointer
	;	+3	Flags
	;	+1..2	A

		lda	4,S
		tcd				; get back LL pointer
		beq	vec_done2		; vector handler has cancelled [API:!:!: TODO: DOCUMENT]
		lda	2,S
		sta	4,S
	; stack
	;	+5	Flags
	;	+3..4	-spare-
	;	+1..2	A

		pla
	; stack
	;	+3	Flags
	;	+1..2	-spare-
		sta	1,S
	; stack
	;	+3	Flags
	;	+1..2	A

		bra	vector_loop

vec_done2:
		lda	2,S
		sta	4,S
	; stack
	;	+5	Flags
	;	+3..4	-spare-
	;	+1..2	A

		pla
	; stack
	;	+3	Flags
	;	+1..2	-spare-
		sta	1,S
	; stack
	;	+3	Flags
	;	+1..2	A


vec_done:	pla
		plp
		rts


		.i16
		.a16

;		********************************************************************************
;		* COP 08 - OPCAV - Call A Vector                                               *
;		*                                                                              *
;		* Calls the vector whose index is in DP                                        *
;		*                                                                              *
;		* Entry                                                                        *
;		*         one byte following cop is the vector index                           *
;		*                                                                              *
;		* Exit                                                                         *
;		*         Other registers updated as per vector API.                           *
;		*         8 bit vectors will not alter the high bytes of A,X,Y registers and   *
;		*         B/DP are not altered updated for 8 bit vectors.                      *
;		*                                                                              *
;		*         8 bit vectors are those with IX<=$1A even where they are handled by  *
;		*         a native mode handler.                                               *
;		*                                                                              *
;		*         Bad vector indices will return V=C=1                                 *
;		*                                                                              *
;		*         Flags are returned as per vector but E/M/X are preserved from        *
;		*         caller                                                               *
;		*                                                                              *12331
;		*         TODO: update DP/B or disallow as part of API                         *
;		********************************************************************************
COP_08:
		phd					; save COP DP
		; set entry registers for the vector
		ldx	DPCOP_X
		ldy	DPCOP_Y

		inc	DPCOP_PC			; increment PC to skip index byte
		lda	[DPCOP_PC]			; vector index
		and	#$00FF				; mask low byte

		cmp	#IX_VEC_MAX+1
		bcs	@badIx
		cmp	#IX_VEC_BBC_MAX+1
		bcs	@natOnly
		asl	A				; vector index * 2
		adc	#BBC_USERV			; turn to BBC vector address				

		tcd					; DP = vector address
		lda	z:0				; A = vector contents
		pld					; get back COP DP

		phd					; save COP DP
		per	@ret-1				; 16 bit emu/boot mode return address - TODO: IRQ1/IRQ2/BRKV need to be made suitable for RTI instead of RTS
		pha					; stack vector address

		sep	#$30
		.a8
		.i8

	; Stack
	;	+5..6	COP_DP
	;	+3..4	return address from vector
	;	+1..2	Vector address


		lda	DPCOP_P
		pha					; Caller's flags	
		lda	#2				; number of bytes of stack to transfer
		pha

	; Stack
	;	+7	COP_DP
	;	+5..6	return address from vector
	;	+3..4	Vector address
	;	+2	P
	;	+1	"2" number of bytes of stack to transfer

		lda	DPCOP_AH+1
		xba
		lda	DPCOP_AH

		jml	nat2emu_rti			; enter emu mode and set DP/B to 0
	; The vector handler will be entered with emu stack:
	; Emu Stack
	;	+1..2	return address from vector	; suitable for RTS or RTI
	; The native stack will hold the saved DP
	; Nat Stack
	;	+1..2	DP


@ret:		
		.a8
		.i8
		pha
		php
		
	; Stack
	;	+3..4	COP_DP
	;	+2	A (8 bit)
	;	+1	flags returned from vector
		
		
		pea	@c>>8
		pea	$34 + ((<@c)<<8)
		pea	2			; transfer 2 bytes from emu to nat stack (P, A)
		jml	emu2nat_rti

	;;;;;;;;; enter native mode ;;;;;;;;;;;;
@c:		; get back DP cop
		tsc
		tcd
		pei	(3)
		pld


		pla				; get back flags
		eor	DPCOP_P
		and	#$CF			; mask out original flags
		eor	DPCOP_P			; get back Caller's flags and nothing else
		sta	DPCOP_P			; set flags but keep M/X from caller

		pla				; get back 8 bit A
		sta	DPCOP_AH		; store only bottom 8 bits!
		stx	DPCOP_X			; store only bottom 8 bits!
		sty	DPCOP_Y			; store only bottom 8 bits!

		rep	#$30
		.a16
		.i16

		pld				; discard/re-pull DP cop

		; BANK/DP in COP DP left as on entry for 8 bit vectors

		rtl

@badIx:		pld
		lda	DPCOP_P
		ora	#$41			; set V/C
		sta	DPCOP_P
		sec
		rtl


	; Entered here when this is a native-only vector

@natOnly:	php
	; Stack	
	;	+2..3	DP
	;	+1	P - spare
		lda	DPCOP_P-1
		sta	0,S			; put caller's P on stack in P
	; Stack	
	;	+2..3	DP
	;	+1	COP caller's P
		phx
	; Stack	
	;	+4..5	DP
	;	+3	COP caller's P
	;	+1..2	COP caller's X
		lda	[DPCOP_PC]
		and	#$00FF
		asl	A
		adc	[DPCOP_PC]		; A = IX*3
		and	#$00FF
		ldx	DPCOP_AH
		tcd				; DP = IX*3
		txa				; A = entry A	
		plx			
		plp
		jsr	callNativeVectorChain
		php
		rep	#$38
		pha
		tsc
		tcd
		pei	(4)			; get back DP
		pld
		pla
		stx	DPCOP_X
		sty	DPCOP_Y
		sta	DPCOP_AH
		sep	#$20
		.a8
		pla
		eor	DPCOP_P
		and	#$CF			; mask out original flags
		eor	DPCOP_P			; get back Caller's flags and nothing else
		sta	DPCOP_P			; set flags but keep M/X from caller
		rep	#$38
		pld				; get back pushed DP
		clc
		rtl



	;BHA contains vector handler address
	;X   contains vector index
	;DP  contains handler DP
	;TODO: use DP instead of f:,X for smaller code?
AddToVector:	php
		rep	#$30
		.a16
		.i16
		phy
		phx
		cpx	#IX_VEC_MAX+1
		beq	@retsec
		pha
		lda	#B0B_TYPE_LL_NATVEC
		jsr	allocB0Block
		pla		
		bcs	@retsec		
		; store vector pointer (low 16)
		sta	f:b0b_ll_nat_vec::handler,X
		; store return pointer (low 16)
		lda	#.loword(vector_next-1)
		sta	f:b0b_ll_nat_vec::return,X
		; store handler DP
		tdc
		sta	f:b0b_ll_nat_vec::dp,X
		sep	#$20
		.a8
		; store handler bank
		phb
		pla
		sta	f:b0b_ll_nat_vec::handler+2,X
		; store return bank
		phk
		pla
		sta	f:b0b_ll_nat_vec::return+2,X
		rep	#$30
		.a16
		.i16

		txy
		
		lda 	1,S				; get back index
		asl	A
		adc	1,S
		and	#$FF
		adc	#NAT_OS_VECS
		tax

		; Y points at newly allocated block
		; X pointer at native vector head

		; turn off interrupts whilst messing with vector
		php
		sei

		lda	f:0,X				; get old head pointer
		pha
		tya
		sta	f:0,X				; head pointer at our block

		tax					; X points at our block again
		pla
		sta	f:b0b_ll_nat_vec::next,X	; store old pointer in our block
		plp					; interrupts back on

		plx
		ply
		plp
		clc
		rtl

@retsec:	plx
		ply
		plp
		sec
		rtl	
		