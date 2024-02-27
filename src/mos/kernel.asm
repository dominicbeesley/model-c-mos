
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
nat_handle_nmi:		
		.a16
		.i16
		rep	#$30
		pha
		lda	#DEICE_STATE_NMI
		jml	deice_enter_nat
nat_handle_irq:	rti

emu_handle_abort:	rti
emu_handle_cop:		
		.a8
		pha
		lda	#DEICE_STATE_BP
		jml	deice_enter_emu
emu_handle_irq:	rti
emu_handle_nmi:	pha
		lda	#DEICE_STATE_NMI
		jml	deice_enter_emu
emu_handle_res:	
		.a8
		.i8
		; we're in E=1 mode and can assume that all regs are 8 bit
		; and that DP, B and K are all zero
		; interrupts are inhibited and decimal mode is off

		ldx	#$FF
		txs
		pea	0
		pld		; direct page is at 0

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
		
		.i8
		.a8
		sep	#$30
		phk
		plb			; databank is code
		

here:		;cop	1
		;jmp	here

		ldy	#10		
		ldx	#0
;;		stx	$0
@wlp:		dex
		bne	@wlp
;;		dec	$0
;;		bne	@wlp
		dey
		bne	@wlp

		phk
		plb
		lda	#>test_str
		xba
		lda	#<test_str
		jsr	printStrBHA
		jmp	here

SERIAL_STATUS	:= sheila_ACIA_CTL
RXRDY		:= ACIA_RDRF
SERIAL_RXDATA	:= sheila_ACIA_DATA
TXRDY		:= ACIA_TDRE
SERIAL_TXDATA	:= sheila_ACIA_DATA


		
		.a8
PrintA:		php				; register size agnostic!
		sep	#$20
		pha        	
   		lda     #TXRDY
@lp:		bit	SERIAL_STATUS  		;CHECK TX STATUS        		
        	beq     @lp			;READY ?
        	pla
        	sta     SERIAL_TXDATA   	;TRANSMIT CHAR.
        	plp
        	rts

		.a8
		.i8
printStrBHA:	phx
		phy
		php
		sep	#$30
		sta	dp_mos_lptr
		xba
		sta	dp_mos_lptr+1
		phb
		pla
		sta	dp_mos_lptr+2
		ldy	#0
@lp:		lda	[dp_mos_lptr],Y		; long pointer!
		beq	@out
		and	#$7F	;make safe for Deice protocol
		jsr	PrintA
		iny
		bne	@lp			; max 256 chars
@out:		iny
		clc
		tya
		adc	dp_mos_lptr
		pha			
		lda	dp_mos_lptr+1
		adc	#0
		xba
		lda	dp_mos_lptr+2
		adc	#0
		pha
		plb
		pla
		plp
		ply
		plx
		rts


test_str:	.byte "This is a test string...",13,10,"So there!",13,10,0

