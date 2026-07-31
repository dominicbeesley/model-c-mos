		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "dp_bbc.inc"
		.include "sysvars.inc"

		.include "brk_i.inc"


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
		; TODO: this is duplicated in cli.asm - export/import or remove?
		brk					; 
		.byte	$fe				; error number
		.byte	"Bad command"			;
		.byte    0 

@rtl:		rtl

.endproc