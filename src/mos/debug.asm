		.include "dp_bbc.inc"
		.include "hardware.inc"
		.include "debug.inc"
		.include "deice.inc"

		.export debug_printf
		
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
	rep	#$30
	.a16
	.i16
	pha
	phx
	phy
	phb
	phd

	; stack:
	;	+1	Caller DP
	;	+3	Caller B
	;	+4	Caller Y (16)
	;	+6	Caller X (16)
	;	+8	Caller A (16)
	;	+10	Caller Flags
	;	+11	Caller PC
	;	+13	Caller K
	;	+14	String address

	; now rearrange for return by moving string address
	lda	14,S
	tax
	lda	12,S
	sta	14,S
	lda	10,S
	sta	12,S
	lda	8,S
	sta	10,S
	txa	
	sta	8,S

	; stack:
	;	+1	Caller DP
	;	+3	Caller B
	;	+4	Caller Y (16)
	;	+6	Caller X (16)
	;	+8	String address
	;	+10	Caller A (16)
	;	+12	Caller Flags
	;	+13	Caller PC
	;	+15	Caller K


	sep	#$20
	.a8

	tsc
	tcd

	pei	(14)	; push K and rubbish on stack
	plb
	plb		; caller K
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
	rtl	

@tblSpecs:
	.byte "A",10
	.byte "H",11
	.byte "X",6+$80
	.byte "Y",4+$80
	.byte "D",1+$80
	.byte "B",3
	.byte "K",15
	.byte "P",13+$80
	.byte "F",12+$40
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
	jsr	debug_printHexA
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
	jsr	debug_printHexX16
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
	rts
@nyb:	and	#$F
	ora	#'0'
	cmp	#$3A
	bcc	@s
	adc	#'A'-$3A-1
@s:	jmp	deice_printA

debug_printHexX16:
	php
	rep	#$30
	pha
	txa
	xba
	jsr	debug_printHexA
	xba
	jsr	debug_printHexA
	pla
	plp
	rts

