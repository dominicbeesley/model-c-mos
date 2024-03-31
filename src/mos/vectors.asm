
		.include "nat-layout.inc"
		.include "hardware.inc"

		.export bbcNatVecEnter

		.segment "boot_CODE"

	; we are still running from the MOS rom in bank 0, we need
	; to enter native mode 
bbcNatVecEnter:
		pha	; spare
		php
		pha

	; stack
	;	+3..4	address of routine pushed above
	;	+3	- spare -
	;	+2	Flags
	;	+1	A

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

		rep	#$20
		.a16
		lda	4,S			; return address as pushed by entry point
		clc
		adc	#.loword(.loword(NAT_OS_VECS)-.loword(tblNatShims)-2)
		tcd				; this points at vector chain start in NAT_OS_VECS

		wdm	0
