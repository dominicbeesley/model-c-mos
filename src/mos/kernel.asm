

	.export emu_handle_irq
	.export emu_handle_nmi
	.export emu_handle_res

emu_handle_irq: 	rti
emu_handle_nmi: 	rti
emu_handle_res:		jmp emu_handle_res