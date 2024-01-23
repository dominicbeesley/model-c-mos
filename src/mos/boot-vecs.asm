
	.autoimport +

; These boot vectors are used at boot mode and when in 6502 compatibility mode

	.segment "BOOT_VECS"
boot_vec_nmi:	.addr	emu_handle_nmi
boot_vec_reset:	.addr	emu_handle_res
boot_vec_irq:	.addr	emu_handle_irq