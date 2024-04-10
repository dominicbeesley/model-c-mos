
		.include "nat-layout.inc"
		.include "hardware.inc"
		.include "cop.inc"
		.include "vectors.inc"

		.export bbcEmu2NatVectorEntry
		.export vector_next
		.export COP_08
		.export AddToVector

		.segment "boot_CODE"

	; we are still running from the MOS rom in bank 0, we need
	; to enter native mode 
bbcEmu2NatVectorEntry:
		pld				; DP contains the return address from the entry point
		php				; save flags
		xba
		pha				; save B
		xba
		pha				; save A

	; stack
	;	+3	Flags
	;	+1..2	A (16 bits)

		lda	#^bbcEmu2NatVectorEntry_ff
		pha
		pea	bbcEmu2NatVectorEntry_ff-1
		jml	emu2nat_rtl	

		.code
bbcEmu2NatVectorEntry_ff:	
	; Now we want to execute the right routine

		rep	#$30
		.a16
		.i16
		tdc				; return address as pushed by entry point
		clc
		adc	#.loword(.loword(NAT_OS_VECS)-.loword(tblNatShims)-2)		
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
		rep	#$30			; ensure 16 bit registers
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

vector_next:	rep	#$30			; ensure 16 bit regs
		php
		pha
	; stack
	;	+4..5	LL pointer
	;	+3	Flags
	;	+1..2	A

		lda	4,S
		tcd				; get back LL pointer
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

vec_done:		
	; now to figure out how to return to caller - always emu/boot
	; this exit only works for RTS exiting routines

		sep	#$30
		.a8
		; switch to emu mode, we're running FFxxxx so safe to switch
		; to switch as MOS is mapped at same addr in both modes
		sec
		xce					; emu mode
		jml	.loword(@ret)
@ret:		pla
		xba
		pla
		xba
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
;		*    DP   The INDEX of the vector to be called.                                *
;		*         Other registers as per vector API.                                   *
;		*                                                                              *
;		* Exit                                                                         *
;		*    DP   Corrupted                                                            *
;		*         Other registers updated as per vector API.                           *
;		*         8 bit vectors will not alter the high bytes of A,X,Y registers and   *
;		*         B/DP are not altered updated for 8 bit vectors.                      *
;		*                                                                              *
;		*         8 bit vectors are those with IX<=$1A even where they are handled by  *
;		*         a native mode handler.                                               *
;		********************************************************************************
COP_08:

		lda	DPCOP_DP			; vector index
		asl	A				; vector index * 2
		adc	#BBC_USERV			; turn to BBC vector address				

		phd					; save COP DP
		tcd					; DP = vector address
		lda	z:0				; A = vector contents
		dec	A				; decrement - suitable for an RTL
		pld					; get back COP DP

		phd					; save COP DP
		per	@ret-1				; 16 bit emu/boot mode return address - TODO: IRQ1/IRQ2/BRKV need to be made suitable for RTI instead of RTS
		pea	0
		plb					; bank = 0 / ignored, stack a 0
		pha					; stack vector address

		; set entry registers for the vector
		ldx	DPCOP_X
		ldy	DPCOP_Y

	; Stack
	;	+6	COP_DP
	;	+4..5	return address from vector
	;	+3	0
	;	+1..2   vector contents / handler address

		; switch to emu mode, we're running FFxxxx so safe to switch
		; to switch as MOS is mapped at same addr in both modes
		sec
		xce
		.a8
		.i8

		lda	DPCOP_P
		pha					; Caller's flags	

	; Stack
	;	+7	COP_DP
	;	+5..6	return address from vector
	;	+4	0 program bank address
	;	+2..3   vector contents / handler address
	;	+1	caller's flags

		lda	DPCOP_AH+1
		xba
		lda	DPCOP_AH
		
		plp					; pop caller's flags
		jml	nat2emu_rtl			; enter emu mode and set DP/B to 0
	; The vector handler will be entered with stack:
	; Stack
	;	+3..4	COP_DP
	;	+1..2	return address from vector	; suitable for RTS or RTI


@ret:		
		.a8
		.i8
	;;TODO: CHECK: DOES PHP in emu push 1's in M/X
		pha
		php
		
	; Stack
	;	+3..4	COP_DP
	;	+2	A (8 bit)
	;	+1	flags returned from vector
		

		lda	#^@c
		pha
		pea	.loword(@c-1)
		jml	emu2nat_rtl
	;;;;;;;;; enter native mode ;;;;;;;;;;;;
@c:		; get back DP cop
		tsc
		tcd
		pei	(3)
		pld


		pla
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
		sta	f:b0b_ll_nat_vec::handler+2,X
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
		plp
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
		