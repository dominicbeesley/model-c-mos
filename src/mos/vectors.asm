
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
		xce				; enter native mode

		lda	f:sheila_MEM_CTL
		and	#<~BITS_MEM_CTL_BOOT_MODE
		sta	f:sheila_MEM_CTL		; exit boot mode
		jml	@bankFF			; we get an extra instruction in boot mode, use it to swap 
						; to running in bank FF
		.code
@bankFF:		
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
		sec
		xce					; emu mode
		lda	f:sheila_MEM_CTL
		ora	#BITS_MEM_CTL_BOOT_MODE
		sta	f:sheila_MEM_CTL			; boot mode
		nop					; waste an instruction before mode swap
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

		sec
		xce
		.a8
		.i8
							; emu mode
		lda	f:sheila_MEM_CTL
		ora	#BITS_MEM_CTL_BOOT_MODE
		sta	f:sheila_MEM_CTL		; boot mode
	
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
		
		; enter native mode
		clc
		xce
		; enter boot mode
		lda	f:sheila_MEM_CTL
		and	#<~BITS_MEM_CTL_BOOT_MODE
		sta	f:sheila_MEM_CTL		; boot mode
		jml	@c				; jump back to bank FF
@c:		
		lda 	3,S
		and	#$30				; isolate caller's M/X mode flags
		eor	#$30				; invert
		eor	2,S				; assume returned M/X flags are both 1
		sta	3,S				; back on stack

		pla	
		plp
		plp
		rtl
