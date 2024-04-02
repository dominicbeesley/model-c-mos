.ifndef __MODES_INC__
__MODES_INC__:


		.macro ENTER_NATIVE far_a
		clc
		pea	far_a >> 8
		pea	((<far_a) << 8) + $34		; interrupts off .a8, i8
		jml	OSXCERTI	
		.endmacro

.endif