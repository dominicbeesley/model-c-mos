
		.include "dp_sys.inc"
		.include "hardware.inc"
		.include "deice.inc"
		.include "debug.inc"
		.include "vectors.inc"
		.include "nat-layout.inc"

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

		.export bank0
		.export bankFF

		.segment "default_handlers"

; deice - all 65816 entries are initially ABORT
; entry point inspects instruction and changes to BP if WDM instruction
nat_handle_abort:	
		.a16
		.i16
		rep	#$30
		pha
		lda	#DEICE_STATE_ABORT
		jml	deice_enter_nat
		rti
emu_handle_abort:
		pha
		lda	#DEICE_STATE_ABORT
		jml	deice_enter_emu
		rti



nat_handle_cop:		
nat_handle_brk:	rti
nat_handle_nmi:		
nat_handle_irq:	rti

		.a8
emu_handle_cop:	rti
emu_handle_irq:	
emu_handle_nmi:	rti


		.segment "boot_CODE"

; The reset handler will always enter here direct to the boot ROM
; reset will have re-enabled boot mode (bank 00 maps to bank FF)
emu_handle_res:	
		.a8
		.i8
		; we're in E=1 mode and can assume that all regs are 8 bit
		; and that DP, B and K are all zero
		; interrupts are inhibited and decimal mode is off

		ldx	#$FF
		txs

; We're in boot mode - running from bank 0, first jump to bank FF before
; turning off boot mode

		; Enter auto-boot mode
		lda	sheila_MEM_CTL
		and	#<~BITS_MEM_CTL_BOOT_MASK
		ora	#MEM_CTL_AUTOBOOT_MODE
		sta	sheila_MEM_CTL
		
		; enter native mode
		clc
		jml	enter_FF

		.code
enter_FF:	xce

		pea	0
		pld			; direct page is at 0		
		phk
		plb			; ensure bank FF

		; enable JIM interface
		lda	#JIM_DEVNO_BLITTER
		sta	fred_JIM_DEVNO


; Map the BLTURBO registers so that both native and emulation modes see the 
; same RAM in 0-FFFF, the rest from motherboard
		lda	#$01
		sta	sheila_MEM_LOMEMTURBO

		rep	#$30
		.i16
		.a16


; There need to be two copies of the extra vectors $00 8FE0 in boot-mode and 
; 00 FFE0 in non-boot mode

		; copy to "RUN" address which is 00 FFE0
		ldx	#.loword(__HW816_VECS_LOAD__)
		ldy	#.loword(__HW816_VECS_RUN__)
		lda	#__HW816_VECS_SIZE__
		mvn	#^__HW816_VECS_LOAD__, #^__HW816_VECS_RUN__

		; copy to frigged boot-mode location TODO: can't we have both at 00 FFE0? check BAS816, beeb816 and change VHDL, API doco
		ldx	#.loword(__HW816_VECS_LOAD__)
		ldy	#$8FE0
		lda	#__HW816_VECS_SIZE__
		mvn	#^__HW816_VECS_LOAD__, #0

;;;; We are now running in BOOT MODE but will soon switch boot mode off - vectors
;;;; need to be copied from FF FFFA to 00 FFFA
;;;
;;;		ldx	#.loword(__HWBBC_VECS_LOAD__)
;;;		ldy	#.loword(__HWBBC_VECS_RUN__)
;;;		lda	#__HWBBC_VECS_SIZE__
;;;		mvn	#^__HWBBC_VECS_LOAD__, #^__HWBBC_VECS_RUN__
		

; We are now running in BOOT MODE but will soon switch boot mode off - default
; handlers for the vectors must be copied to RAM TODO: this will need to be
; aligned at the same address in ROM/RAM for boot mode switching!
; TODO: these could rom from boot rom - always EMU mode?!

		ldx	#.loword(__default_handlers_LOAD__)
		ldy	#.loword(__default_handlers_RUN__)
		lda	#__default_handlers_SIZE__
		mvn	#^__default_handlers_LOAD__, #^__default_handlers_RUN__

		sep	#$30		; 8 bits registers
		.i8
		.a8

		jsr	deice_init

		jsr	roms_scanroms	; only on ctrl-break, but always for now...
		jsr	initB0Blocks

		jsr	cfgGetMosBase
		DEBUG_PRINTF "MOS_BASE =%H%A\n"

		
; Set up the BBC/emulation mode OS vectors to point at their defaults
; which are the entry points in bbc-nat-vectors
		rep	#$30
		.i16
		.a16
		pea	0
		plb
		plb						; bank 0
		ldx	#(tblNatShimsEnd-tblNatShims)/3		; number to copy
		ldy	#.loword(BBC_USERV)			; destination in BBC vectors
		lda	#.loword(tblNatShims)			; address
@lp:		sta	a:0,Y					; store in bank 0
		inc	A
		inc	A
		inc	A
		iny
		iny
		dex
		bne	@lp

; zeroes to the native OS Vecs
		lda	#0
		ldx	#NAT_OS_VECS_COUNT*3
@lp2:		sta	a:NAT_OS_VECS-3,X
		dex
		dex	
		bne	@lp2	

		sep	#$30
		.i8
		.a8
		phk
		plb			; databank is code		

here:		
		ldy	#10		
		ldx	#0
		stx	$0
@wlp:		dex
		bne	@wlp
		dec	$0
		bne	@wlp
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
@lp:		lda	f:SERIAL_STATUS		;CHECK TX STATUS        		
		and     #TXRDY
        	beq     @lp			;READY ?
        	lda	1,S
		and	#$7F	;make safe for Deice protocol
        	sta     f:SERIAL_TXDATA   	;TRANSMIT CHAR.
        	pla
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



bank0:		pea	$0000
		plb
		plb
		rts

bankFF:		pea	$FFFF
		plb
		plb
		rts

test_call_bbc_vector:
		rep	#$30
		.a16
		.i16
		phk
		plb
		lda	#$D00B
		tcd
		lda	#.loword(test_handler_1)
		ldx	#IX_IND1V
		jsl	AddToVector

		phk
		plb
		lda	#$1515
		tcd
		lda	#.loword(test_handler_2)
		ldx	#IX_IND1V
		jsl	AddToVector


		pea	IX_IND1V
		pld
		jsl	CallAVector_NAT

		DEBUG_PRINTF	"EXIT A=%H%A, X=%X, Y=%Y, DP=%D, B=%B, PC=%K%P, Flags=%F"
		wdm	7


jind1v_0:	jml	.loword(jind1v)		; enter in bank 0
jind1v:		jmp	(BBC_IND1V)




		.a16
		.i16

test_handler_1:	DEBUG_PRINTF	"HANDLER 1 A=%H%A, X=%X, Y=%Y, DP=%D, B=%B, PC=%K%P, Flags=%F\n"
		lda	#$B00B
		ldx	#$DEAD
		ldy	#$BEEF
		pea	$2222
		plb
		plb
		sec		
		rtl


test_handler_2:	DEBUG_PRINTF	"HANDLER 2 A=%H%A, X=%X, Y=%Y, DP=%D, B=%B, PC=%K%P, Flags=%F\n"
		lda	#0
		php
		lda	#$D0B0
		ldx	#$1580
		ldy	#$5140
		pea	$3333
		plb
		plb
		plp
		clc
		rtl



; These are cut-down configuration routines, only for use during boot
; they have a similar API to those found in the bltutils rom
; all expect .a8, .i8
		.a8
		.i8

;-----------------------------------------------------------------------------
; cfgGetAPILevel
;-----------------------------------------------------------------------------
; Returns API level in A
; Z flag is set if API=0
cfgGetAPILevel:
		lda	f:VERSION_API_level
		bpl	@ret
		lda	#0			; if -ve set to 0
@ret:		rts


;-----------------------------------------------------------------------------
; cfgGetAPISubLevel
;-----------------------------------------------------------------------------
; Returns API level in A, Sublevel in X
; Z flag is set if API=0
cfgGetAPISubLevel:
		ldx	#0
		jsr	cfgGetAPILevel		
		beq	@ret
		pha
		lda	f:VERSION_API_sublevel
		tax
		pla
@ret:		rts

;-----------------------------------------------------------------------------
; cfgGetRomMap
;-----------------------------------------------------------------------------
; Returns current ROM map number in A 
; Notes: unlike bltutil doesn't check for MEMI or T65 as these are N/A for 65816
; A is 0 if CS set
; Note: though the SWROMX bits are same for mk.2 and mk.3 coded separately for
; flexibility - may chose to reorder later
cfgGetRomMap:
		jsr	cfgGetAPILevel
		clv
		bcs	@ret
		beq	@API0

		lda	f:VERSION_Board_level
		cmp	#3			; check for >= Mk.3 assume Mk.1 and Mk.2 same config
		bcc	@mk2

		; mk.3 switches
		; assume future boards have same config options as mk.3
		lda	f:VERSION_cfg_bits+0
		and	#BLT_MK3_CFG0_SWROMX	; get SWROMX bit
		bra	@skswromx


@mk2:		; Mk.2 detect
		lda	f:VERSION_cfg_bits+0	
		and	#BLT_MK2_CFG0_SWROMX	; get SWROMX bit
		bra	@skswromx		; if SWROMX not fitted jump



@API0:		lda	f:sheila_BLT_API0_CFG0
		and	#BLT_MK2_CFG0_SWROMX
@skswromx:	beq	@ok
		lda	#1
@ok:		clc
@ret:		rts

;-----------------------------------------------------------------------------
; cfgGetMosRam
;-----------------------------------------------------------------------------
; Returns current MosRAM setting (could be jumpers or ROMCTL_MOS_SWMOS bit in 
; sheila_ROMCTL_MOS)
; Notes: unlike bltutil doesn't check for MEMI or T65 as these are N/A for 65816
; A is 0 if CS set
; returns A = 1 for active
; Note: though the MOSRAM bits are same for mk.2 and mk.3 coded separately for
; flexibility - may chose to reorder later
cfgGetMosRam:
		lda	f:sheila_MEM_CTL
		and	#BITS_MEM_CTL_SWMOS
		bne	@skswromx

		jsr	cfgGetAPILevel
		clv
		bcs	@ret
		beq	@API0

		lda	f:VERSION_Board_level
		cmp	#3				; check for >= Mk.3 assume Mk.1 and Mk.2 same config
		bcc	@mk2

		; mk.3 switches
		; assume future boards have same config options as mk.3
		lda	f:VERSION_cfg_bits+0
		and	#BLT_MK3_CFG0_MOSRAM		; get MOSRAM bit
		bra	@skswromx


@mk2:		; Mk.2 detect
		lda	f:VERSION_cfg_bits+0	
		and	#BLT_MK3_CFG0_MOSRAM		; get MOSRAM bit
		bra	@skswromx			; if SWROMX not fitted jump



@API0:		lda	f:sheila_BLT_API0_CFG0
		and	#BLT_MK3_CFG0_MOSRAM
@skswromx:	beq	@ok
		lda	#1
@ok:		eor	#1
		clc
@ret:		rts


;-----------------------------------------------------------------------------
; cfgGetRomMap
;-----------------------------------------------------------------------------
; Returns base address of MOS rom depending on settings of jumpers and 
; ROMCTL_MOS_SWMOS bit in sheila_ROMCTL_MOS
cfgGetMosBase:	jsr	cfgGetRomMap
		pha
		jsr	cfgGetMosRam
		ror	A
		pla
		rol	A
		rol	A
		clc
		phb
		phk					; table bank
		plb
		tax
		lda	tblMosLocs+1,X
		xba
		lda	tblMosLocs,X
		plb					; restore bank
		rts
		

tblMosLocs:	.word	$FFC0	; map 0, mosram dis
		.word	$7F00	; map 0, mosram en
		.word	$9D00	; map 1, mosrom dis
		.word	$7D00	; map 1, mosram en


