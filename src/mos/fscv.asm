		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "dp_bbc.inc"
		.include "sysvars.inc"



		.export doFSCV

		.a16
		.i16
.proc doFSCV:far
		sep	#$30
		.a8
		.i8

		; TODO: FSCV
		cmp	#$6
		bcs	@rtl
		jml	brkBadCommand

@rtl:		rtl

.endproc