

	.include "kernel.asm"
	.include "deice.asm"
	.include "boot-vecs.asm"
	.include "font.asm"

* = $600
	.desction DEICE_BSS
	.cerror * > $700, "DEICE_BSS too big"

* = $C000
	.dsection font
	.dsection code

	.cerror * > $FFFA, "code too big"

* = $FFFA
	.dsection BOOT_VECS
	.cerror * != $10000, "BOOT_VECS wrong size"
