
		.include "nat-layout.inc"
		.include "hardware.inc"

		.export bbcNatVecEnter
		.export vector_next

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
	; now to figure out how to return to caller - could be emu or nat!



HERE:		WDM	0