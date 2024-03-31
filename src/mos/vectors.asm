
		.include "nat-layout.inc"

		.export bbcNatVecEnter

		.segment "boot_CODE"

	; we are still running from the MOS rom in bank 0, we need
	; to enter native mode - but that would map our ROM out
	; so we need to construct a jump block on the stack to run
	; from while we switch
bbcNatVecEnter:
		php
		pha
		phx

	; stack
	;	+4..5	address of routine pushed above
	;	+3	Flags
	;	+2	A
	;	+1	X

		ldx	#natEntryJmpLen-1
@lp:		lda	natEntryJmp,X
		pha
		dex
		bpl	@lp

	; stack
	;	+n+4..5	address of routine pushed above
	;	+n+3	Flags
	;	+n+2	A
	;	+n+1	X
	;	+1..n	shim routine

		tsx

		lda	#1
		pha			; high address of shim routine on stack
		phx			; low address of shim rountine on stack-1
		clc
		rts			; call shim routine on stack

	; TODO: instead of stack, copy this to B0 at boot? Where though it would to be in <E00
natEntryJmp:
		xce
		jml	bbcNatVecEnter2		
natEntryJmpLen := *-natEntryJmp

		.code

	.assert natEntryJmpLen=5, error
	; we're now in native mode with registers as per emu->nat entry	
bbcNatVecEnter2:
	; stack
	;	+9..10	address of routine pushed above
	;	+8	Flags
	;	+7	A
	;	+6	X
	;	+1..5	shim routine
		
		rep	#$20
		.a16
		lda	9,S
		clc
		adc	#.loword(.loword(NAT_OS_VECS)-.loword(tblNatShims))
		tcd			; this points at vector chain start in NAT_OS_VECS

		lda	7,S		; move Flags,A,X and last byte of shim up
		sta	9,S
		lda	5,S		; move Flags,A,X and last byte of shim up
		sta	7,S

	; stack
	;	+10	Flags
	;	+9	A
	;	+8	X
	;	+1..7	-spare-

		tsc
		clc
		adc	#7		; skip stuff on stack
		tcs

		sep	#$20
		.a8
	
		plx
		pla
		plp

HERE:		jmp 	HERE




