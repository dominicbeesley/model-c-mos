
		.include "oslib.inc"

		.export utilsAisAlpha:far
		.export PrintHexA:far
		.export PrintHexX:far
		.export Print2Spc:far
		.export PrintSpc:far

		.code

		; ENTRY	 character in A
		; exit with carry set if non-Alpha character
_LE4E3:	
.proc utilsAisAlpha:far
		php
		sep	#$30		
		pha					; Save A
		and	#$df				; convert lower to upper case
		cmp	#$41				; is it 'A' or greater ??
		bcc	_BE4EE				; if not exit routine with carry set
		cmp	#$5b				; is it less than 'Z'
		bcc	_BE4EF				; if so exit with carry clear
_BE4EE:		pla
		plp
		sec					; else clear carry
		rtl
_BE4EF:		pla					; get back original value of A
		plp
		clc
		rtl					; and Return

.endproc

.proc PrintHexA:far
	php
	sep	#$20
	.a8
	pha
	lsr	A
	lsr	A
	lsr	A
	lsr	A
	jsr	@nyb
	pla
	pha
	jsr	@nyb
	pla
	plp
	rtl
@nyb:	and	#$F
	ora	#'0'
	cmp	#$3A
	bcc	@s
	adc	#'A'-$3A-1
@s:	cop	COP_00_OPWRC
	rts
.endproc

.proc PrintHexX:far
	php
	rep	#$30
	.i16
	.a16
	pha
	txa
	xba
	jsl	PrintHexA
	xba
	jsl	PrintHexA
	pla
	plp
	rtl
.endproc


.proc Print2Spc:far
	jsl	PrintSpc
.endproc
	

.proc PrintSpc:far
	php
	sep	#$20
	.a8
	pha
	lda	#' '
	cop	COP_00_OPWRC
	pla
	plp
	rtl
.endproc
	