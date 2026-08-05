
		.include "nat-layout.inc"
		.include "hardware.inc"
		.include "vectors.inc"

		.include "cop_i.inc"
		.include "debug_i.inc"
		.include "b0blocks_i.inc"
		.include "kernel_i.inc"
		.include "bbc-nat-vectors_i.inc"

		.export bbcEmu2NatVectorEntry:near
		.export vector_next:far
		.export COP_08:far
		.export COP_09:far
		.export vectors_init:far

		.segment "BBCCODE"
;
; When a BBC API vector is called at 2xx any emulation mode claimer of 
; the respective vector is called first. However, at boot time the 
; emulation mode vectors are setup to point at the tblNatShims table 
; which points to bbcEmu2NatVectoryEntry. 
;
; The bbcEmu2NatVectoryEntry routine will pass the call on  to 
; callNativeVectorChain or, if a shim has been registered in the 
; EMU2NAT_VEC_SHIMS then it is called with registers set up ready
; to call callNativeVectorChain after possibly massaging any registers
; or data blocks to match native mode APIs.

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

		pha			; make space
		pha			; make space
		phx
		pha

		;stack
		;	+12..13	caller's return address-1
		;	+10..11	return address to entry shim+2
		;	+9	P 	(caller)
		;	+5..8	spare
		;	*3..4	X
		;	+1..2	A

		lda	10,S
		sec
		sbc	#.loword(tblNatShims+2)
		; A now contains IX*3		
		tcd					; pass DP=IX*3 to callNativeVectorChain/shim
		tax
		lda 	9,S
		sta	5,S				; move P down
		lda	EMU2NAT_VEC_SHIMS,X
		sta	6,S
		lda	EMU2NAT_VEC_SHIMS+1,X
		sta	7,S
		lda	#.loword(@continue-1)
		sta	9,S
		lda	#.loword((@continue-1) >> 8)
		sta	10,S

		;	+12	caller's bank 0 return address
		;	+9	rtl far return address to @continue (note -1)
		;	+6	far addr of shim (or callNativeVectorChain)
		;	+5	P
		;	+3	X
		;	+1	A

		pla
		plx

		;	+8	caller's bank 0 return address
		;	+5	rtl far return address to @continue (note -1)
		;	+2	far addr of shim (or callNativeVectorChain) from EMU2NAT_VEC_SHIMS table
		;	+1	P
		
		rti

@continue:

		;stack
		;	+1..2   caller's return address-1
		php
		php
		rep	#$30
		.a16
		.i16
		pha
		tsc					; quick stack access
		tcd					; DP will get forced to 0 by nat2emu_0_rti

		;stack/DP
		;	+5..6   Vector callers rts address
		;	+4	P
		;	+3	spare
		;	+1..2	A

		inc	5	; make return address suitable for rti
		lda	3
		and	#$FF00
		sta	3

		;stack
		;	+5..6	vectors caller's rti address (bank 0)
		;	+4	P
		;	+3	0
		;	+1..2	A
		pla

		;stack
		;	+3..4	vectors caller's rti address (bank 0)
		;	+2	P
		;	+1	0
		jml	nat2emu_0_rti	; no extras

; *******************************************************************************
; * 										*
; * 	callNativeVectorChain:far						*
; * 		On Entry:							*
; * 			DP contains the native vector index multiplied by 3	*
; * 			B,A,X,Y contain parameters				*
; * 										*
; * 		On Exit:							*
; *			DP = FFFF when the vector was claimed, else 0		*
; *			B,A,X,Y,P as per vector API				*
; *										*
; *	The native OS vector indicated by the index in DP is traversed and	*
; *	registered handlers are called. A handler may return any registers	*
; *	except DP which is corrupted, including flags.				*
; *										*
; *	Handlers can "take over" by cancelling the traversal by rewriting 	*
; *	the two bytes of the stack above the far return address to 0. 		*
; *	Otherwise the handler should leave registers in a state that the next 	*
; *	handler can utilise as entry arguments.					*
; *										*
; *******************************************************************************
		.i16
		.a16
	; DP contains index *3, A,X,Y as per vector call
.proc callNativeVectorChain:far
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
	;	+	far return address to vector_next -1 (suitable for RTL)
	;	+4	far address of handler (suitable for RTI)
	;	+3	Flags
	;	+1	DP			
		pld				; setup routine's DP
		rti				; branch to routine

::vector_next:	rep	#$38			; ensure 16 bit regs and no decimal
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
		lda	#$FFFF
		tcd				; mark vector claimed

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
		rtl

.endproc
		.i16
		.a16

;		********************************************************************************
;		* COP 08 - OPCAV - Call A Vector                                               *
;		*                                                                              *
;		* Calls the vector whose index is in the byte following the COP instruction.   *
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
;		*                                                                              *
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
		jsl	callNativeVectorChain
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



;		********************************************************************************
;		* COP 09 - OPADV - Add to vector                                               *
;		*                                                                              *
;		* Adds the routine to the indicated vector chain                               *
;		*                                                                              *
;		* Entry                                                                        *
;		*   BHA   the address of the vector handler to add                             *
;		*     X   A reason code - always 0 for add to front of list                    *
;		*     Y   The index of the vector to update                                    *
;		*    DP   For add reason codes the DP to assign to the handler                 *
;		* Exit                                                                         *
;		*    TODO: define other reasons, return parameters etc                         *
;		*    TODO: proper error returns                                                *
;		********************************************************************************
COP_09:		.a16
		.i16
		ldx	DPCOP_X
		bne	@retBadCall

		; add to head of vector chain
		ldx	DPCOP_Y
		cpx	#IX_VEC_MAX+1
		beq	@retBadCall


		lda	#B0B_TYPE_LL_NATVEC
		jsl	allocB0Block		
		bcs	@retNoMem

		; store vector pointer (low 16)
		lda	DPCOP_AH
		sta	f:b0b_ll_nat_vec::handler,X
		; store return pointer (low 16)
		lda	#.loword(vector_next-1)
		sta	f:b0b_ll_nat_vec::return,X
		; store handler DP
		lda	DPCOP_DP
		sta	f:b0b_ll_nat_vec::dp,X
		sep	#$20
		.a8
		; store handler bank
		lda	DPCOP_B
		sta	f:b0b_ll_nat_vec::handler+2,X
		; store return bank
		phk
		pla
		sta	f:b0b_ll_nat_vec::return+2,X
		rep	#$30
		.a16
		.i16

		txy
		
		lda 	DPCOP_Y				; get back index
		asl	A
		adc	DPCOP_Y
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

		clc
		rtl

@retNoMem:
@retBadCall:	sec
		rtl	
		
.proc vectors_init:far
		php
		rep	#$30
		.a16
		.i16
; Set up the BBC/emulation mode OS vectors to point at their defaults
; which are the entry points in bbc-nat-vectors
		ldx	#.loword(default_BBC_vectors)
		ldy	#.loword(BBC_USERV)
		lda	#default_BBC_vectors_len
		mvn	#^default_BBC_vectors, #^BBC_USERV

; point all the EMU2NAT_VEC table entries to callNativeVectorChain
		lda	#.loword(callNativeVectorChain)
		sta	EMU2NAT_VEC_SHIMS
		lda	#.loword(callNativeVectorChain >> 8)
		sta	EMU2NAT_VEC_SHIMS + 1
		lda	#(IX_VEC_BBC_MAX-1)*3-1
		ldx	#EMU2NAT_VEC_SHIMS
		ldy	#EMU2NAT_VEC_SHIMS+3
		mvn	#0, #0
		

; zeroes to the native OS Vecs
		lda	#0
		ldx	#NAT_OS_VECS_COUNT*3
		sep	#$20
		.a8
@lp2:		sta	a:NAT_OS_VECS-1,X
		dex	
		bne	@lp2


		plp
		rtl
.endproc