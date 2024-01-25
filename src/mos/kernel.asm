
		.autoimport +

		.include "dp_sys.inc"
		.include "boot_vecs.inc"
		.include "hardware.inc"
		.include "deice.inc"

		.export nat_handle_cop
		.export nat_handle_brk
		.export nat_handle_abort
		.export nat_handle_irq
		.export nat_handle_nmi

		.export emu_handle_abort
		.export emu_handle_cop
		.export emu_handle_irq
		.export emu_handle_nmi
		.export emu_handle_res

		.code
nat_handle_cop:		
		.a16
		.i16
		rep	#$30
		pha
		lda	#DEICE_STATE_BP
		jml	deice_enter_nat

nat_handle_brk:		rti
nat_handle_abort:	rti
nat_handle_nmi:		rti
nat_handle_irq:		rti

emu_handle_abort:	rti
emu_handle_cop:		
		.a8
		pha
		lda	#DEICE_STATE_BP
		jml	deice_enter_emu
emu_handle_irq:		rti
emu_handle_nmi:		rti
emu_handle_res:	
		.a8
		.i8
		; we're in E=1 mode and can assume that all regs are 8 bit
		; and that DP, B and K are all zero
		; interrupts are inhibited and decimal mode is off

		ldx	#$FF
		txs

; We are now running in BOOT MODE and will continue to do so for now
; BANK 00 will map to BANK FF and hardware interrupt vectors will come from
; Phys 00 8FE0-008FF9 for new vectors and FF FFFA - FF FFFF for old (emu irq, nmi, res)

		; Use JIM interface to copy data
		lda	#JIM_DEVNO_BLITTER
		sta	fred_JIM_DEVNO
		sta	<dp_mos_jimdevsave
		lda	#>boot_vecs_shadow
		sta	fred_JIM_PAGE_LO
		lda	#^boot_vecs_shadow
		sta	fred_JIM_PAGE_HI
		ldx	#<boot_vecs_new_len - 1
@lp:		lda	boot_vecs_new,X
		sta	JIM+<boot_vecs_shadow,X
		dex
		bpl	@lp

		; ENTER NATIVE MODE
		clc
		xce

		sep	#$30		; 8 bits registers

		jsr	deice_init

		.i16
		rep	#$10
		phk
		plb
;		ldx	#test_str
;		jsr	deice_printStrzX


		cop	1

here:		jmp	here


test_str:	.byte "This is a test string...",13,10,"So there!",13,10,0