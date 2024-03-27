.ifndef __DEBUG_INC__
__DEBUG_INC__:

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
