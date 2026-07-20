.ifndef __KERNEL_I_INC__
__KERNEL_I_INC__:

		.import nat_handle_cop
		.import nat_handle_brk
		.import nat_handle_abort
		.import nat_handle_irq
		.import nat_handle_nmi
		.import emu_handle_abort
		.import emu_handle_cop
		.import emu_handle_irq
		.import emu_handle_nmi
		.import emu_handle_res
		.import nat2emu_rti
		.import deice_nat2emu_rti
		.import emu2nat_rti
		.import bank0
		.import bankFF
		.import kernelRaiseEvent:far
		.import default_BBC_vectors
		.import default_BBC_vectors_len


.endif 