		.include "dp_bbc.inc"
		.include "hardware.inc"
		.include "debug.inc"
		.include "deice.inc"

		.export debug_printf
		.export debug_printHexA
		.export debug_printA
		
		.code

;	**************************************************************
;	* debug_printf - far, native                                 *
;	**************************************************************
;	*Print a formatted string as debug output                    *
;	*                                                            *
;	*The string may contain the following which are expanded in  *
;	*line                                                        *
;	*                                                            *
;	*  %A    Low 8 bits of A register (irrespective of mode)     *
;	*  %H    High 8 bits of A                                    *
;	*  %X    X register                                          *
;	*  %Y    Y register                                          *      
;	*  %D    DP register                                         *
;	*  %B    Data bank register                                  *
;	*  %K    Program bank register                               *
;	*  %P    Program counter (16 bit)                            *
;	*  %F    Flags register (as letters NVMXDIZC) upper on       *
;	*                                                            *
;	*Entry:  Address of format string in the program bank of the *
;        *        caller should be pushed on the stack using pea.     *
;	*                                                            *
;	*Exit:   All registers preserved                             *
;	*                                                            *
;	**************************************************************

	

debug_printf:	
	php
	clc
	xce
	php

	rep	#$30
	.a16
	.i16
	pha
	phx
	phy
	phb
	phd

	; stack:
	;	+15..16	String address
	;	+14	Caller K
	;	+12..13	Caller PC-1
	;	+11	Original Flags
	;	+10	Caller Flags Cy is Emu mode marker
	;	+8..9	Caller A (16)
	;	+6..7	Caller X (16)
	;	+4..4	Caller Y (16)
	;	+3	Caller B
	;	+1..2	Caller DP

	; now rearrange for return by moving string address
	lda	15,S		; string address
	tax			; into X
	lda	13,S		; K/PCH
	sta	15,S		; K/PCH
	lda	11,S		; PCL/P
	sta	13,S		; PCL/P
	lda	9,S		; P XCE/AH
	sta	11,S		; P XCE/AH
	lda	8,S		; A
	sta	10,S		; A
	txa	
	sta	8,S		; string address

	; stack:
	;	+16	Caller K
	;	+14..15	Caller PC-1
	;	+13	Caller Flags
	;	+12	Caller Flags with Cy=XCE
	;	+10..11	Caller A (16)
	;	+8..9	String address
	;	+6..7	Caller X (16)
	;	+4..5	Caller Y (16)
	;	+3	Caller B
	;	+1..2	Caller DP


	sep	#$20
	.a8

	tsc
	tcd

;;	phk
;;	plb		; Assume strings are in our bank!

	pea	$7D00
	plb
	plb

	ldy	#0
@lp:	lda 	(8),Y
	beq	@end
	iny
	cmp	#'%'
	beq	@interp
@prag:	jsr	deice_printA
	bra	@lp
@end:	rep	#$30
	pld
	plb
	ply
	plx
	pla	;skip string address
	pla
	plp
	xce
	plp
	rtl	

@tblSpecs:
	.byte "A",10
	.byte "H",11
	.byte "X",6+$80
	.byte "Y",4+$80
	.byte "D",1+$80
	.byte "B",3
	.byte "K",16
	.byte "P",14+$80
	.byte "F",13+$40
	.byte $FF

@interp:	lda	(8),Y		; get specifier
	beq	@nope
	
	phb
	phk
	plb			;swap to code bank to search table
	ldx	#0
@slp:	bit	@tblSpecs,X
	bmi	@nope2
	cmp	@tblSpecs,X
	beq	@fnd
	inx
	inx
	bra	@slp

@fnd:	iny
	lda	@tblSpecs+1,X	
	bmi	@b16
	bit	#$40
	bne	@flags
@b8:	and	#$0F
	xba
	lda	#0
	xba
	tax
	lda	0,X
	jsl	debug_printHexA
@cont:	plb
	bra	@lp	
@b16:	and	#$0F
	xba
	lda	#0
	xba
	tax
	lda	1,X
	xba
	lda	0,X
	tax
	jsl	debug_printHexX16
	bra	@cont
@nope2:	plb
@nope:	lda 	#'%'
	bra	@prag

@tblflags:
	.byte	"NVMXDIZC"

@flags:	and	#$0F
	xba
	lda	#0
	xba
	tax
	lda	0,X
	pha

	dex
	lda	0,X
	and	#1
	clc
	ror	A
	ror	A
	ror	A
	ror	A
	eor	#'e'
	jsr	deice_printA
	lda	#' '
	jsr	deice_printA

	pla
	ldx	#0
@flp:	rol	A
	pha
	lda	@tblflags,X
	bcs	@fsk1
	ora	#$20		; make lowercase if not set
@fsk1:	jsr	deice_printA
	pla
	inx
	cpx	#8
	bcc	@flp
	bra	@cont


debug_printHexA:
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
@s:	jsr	deice_printA
	rts

debug_printHexX16:
	php
	rep	#$30
	pha
	txa
	xba
	jsl	debug_printHexA
	xba
	jsl	debug_printHexA
	pla
	plp
	rtl

debug_printA:
	jsr	deice_printA
	rtl

