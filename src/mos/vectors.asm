
		.include "nat-layout.inc"
		.include "hardware.inc"

		.export bbcNatVecEnter
		.export vector_next
		.export CallAVector_NAT

		.segment "boot_CODE"

	; we are still running from the MOS rom in bank 0, we need
	; to enter native mode 
bbcNatVecEnter:
		pld				; DP contains the return address from the entry point
		php				; save flags
		xba
		pha				; save B
		xba
		pha				; save A

	; stack
	;	+3	Flags
	;	+1..2	A (16 bits)

		clc
		jml	@bankFF			; we get an extra instruction in boot mode, use it to swap 
						; to running in bank FF
		.code
@bankFF:	xce
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

		pei	(llent_nat_vec::return + 1); construct stack 
		pei	(llent_nat_vec::handler+ 2)
		pei	(llent_nat_vec::handler)
		php
		pei	(llent_nat_vec::dp)
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
 	;-----------------------------------------------------------------------------
	; CallAVector_NAT - FAR
	;-----------------------------------------------------------------------------
	; Call a vector from Native/non-boot mode
	; The vector INDEX to be called should be in DP
	; entry/exit always in i16/a16
	; Entry
	;	DP 	vector index
	;		other registers except DP as per vector definition
	; Exit
	;	DP 	undefined	
	;		other registers except DP as per vector definition
CallAVector_NAT:
		php					; original caller's flags, preserve mode bits
		per	@ret-1				; 16 bit emu/boot mode return address
		php					; flags
		rep	#$20
		pha					; spare
		pha

	; Stack
	;	+8	caller flags
	;	+6..7	return address from vector
	;	+5	flags
	;	+3..4	spare
	;	+1..2	A

		; move flags down to +3
		lda	5,S
		sta	3,S

	; Stack
	;	+8	caller flags
	;	+6..7	return address from vector
	;	+4..5	-spare-
	;	+3      flags
	;	+1..2	A

		tdc
		asl	A
		ora	#$200
		tcd
		lda	z:0
		sta	4,S

	; Stack
	;	+8	caller flags
	;	+6..7	return address from vector
	;	+4..5	vector contents
	;	+3	Flags
	;	+1..2	A

		; switch to emu mode, we're running FFxxxx so safe to switch
		; to switch as MOS is mapped at same addr in both modes
		sec
		xce
		.a8
		.i8
	
		pla
		xba
		pla
		xba
		rti
@ret:		
		.a8
		.i8

	;;TODO: CHECK: DOES PHP in emu push 1's in M/X
		php
		pha

	; Stack
	;	+3	original caller flags
	;	+2	flags returned from vector
	;	+1	A (8 bit)
		
		clc
		jml	@c		
@c:		; TODO: this assumes that no interrupt will occur during xce
		xce

		lda 	3,S
		and	#$30				; isolate caller's M/X mode flags
		eor	#$30				; invert
		eor	2,S				; assume returned M/X flags are both 1
		sta	3,S				; back on stack

		pla	
		plp
		plp
		rtl
