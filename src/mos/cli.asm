		.include "nat-layout.inc"
		.include "oslib.inc"


		.export doCLIV

		.a16
		.i16
doCLIV:		
		; figure out if this is an address in window and setup BHA
		jsl	windowYXtoBHA

		tax
@lp:		lda	a:0,X
		inx
		cop	COP_15_OPASC
		cmp	#$D
		bne	@lp
		

		rtl