.ifndef __DEBUG_I_INC__
__DEBUG_I_INC__:

    .import debug_printf:far
    .import debug_printHexA:far
    .import debug_printA:far

  .ifndef __DEBUG

    .macro DEBUG_PRINTF fmt
    .endmacro
  .else

    .macro DEBUG_PRINTF fmt
    		.local str
		.pushseg
		.segment "debug_strings"

str:		.byte 	fmt, 0	
		.popseg
		pea	str
		jsl	debug_printf
    .endmacro
  .endif
.endif
