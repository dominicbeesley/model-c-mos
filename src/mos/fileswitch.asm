	.include "oslib.inc"
	.include "nat-layout.inc"
	.include "dp_bbc.inc"

	.include "roms_i.inc"
	.include "window_i.inc"

	.export fileswitch_init:far

.proc fileswitch_init:far
	;!.a?
	;!.i?
	php
	rep	#$30
	.a16
	.i16

	; mos DP
	lda	#0
	tcd

	; bank 1
	pea	.bankbyte(FSINFO_8BIT)<<8
	plb
	plb

	ldx	#FSINFO_8BIT_LEN	
	; a already zeroed above
@lp:	sta	a:.loword(FSINFO_8BIT)-2,X
	dex
	dex
	bne	@lp

	; Get 8-bit ROM FSINFO blocks
	cop	COP_27_OPBHI
	.faraddr FSINFO_8BIT
	jsl	windowPush
	phy
	stx	z:dp_mos_txtptr

	lda	#OSBYTE_143_SERVICE_CALL
	ldy	#0
	ldx	#SERVICE_25_FSINFO
	cop	COP_06_OPOSB

	ply
	jsl	windowPop

	plp
	rtl
.endproc