
		.autoimport +


		.export boot_vecs_new	
		.export boot_vecs_new_len
		.export bbc_vecs_base

		.segment "EXTRA_VECS"
; These vectors will get copied to the shadow vectors area at 00 8Fxx
boot_vecs_new:	
		.word	$FFFF
		.word	$FFFF
		.addr	nat_handle_cop
		.addr 	nat_handle_brk
		.addr	nat_handle_abort
		.addr	nat_handle_nmi
		.word   $FFFF
		.addr	nat_handle_irq

		.word	$FFFF
		.word	$FFFF
		.addr	emu_handle_cop
		.addr 	$FFFF
		.addr	emu_handle_abort
boot_vecs_new_len := *-boot_vecs_new

	.segment "BBC_VECS"
; These boot vectors are used at boot mode and when in 6502 compatibility mode
bbc_vecs_base:
		.addr	emu_handle_nmi
		.addr	emu_handle_res
		.addr	emu_handle_irq

