
		.include "dp_bbc.inc"
		.include "hardware.inc"
		.include "deice.inc"
		.include "debug.inc"
		.include "vectors.inc"
		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "sysvars.inc"
		.include "vduvars.inc"

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

		.export nat2emu_rti
		.export deice_nat2emu_rti
		.export emu2nat_rti


		.export bank0
		.export bankFF

		.export kernelRaiseEvent

		.export default_BBC_vectors
		.export default_BBC_vectors_len

		.segment "default_handlers"


		.a8
		.i8
emu_handle_abort:
		pha
		lda	#DEICE_STATE_ABORT
		clc
		xce				; switch to native mode
		bra	enter_deice

; deice - all 65816 entries are initially ABORT
; entry point inspects instruction and changes to BP if WDM instruction
nat_handle_abort:	
		.a16
		.i16
		rep	#$30
		pha
		lda	#DEICE_STATE_ABORT
enter_deice:	jml	deice_enter_nat



deice_nat2emu_rti:
		sec
		xce
		rti



nat_handle_cop:	jml	cop_handle_nat	
nat_handle_brk:	jml	brk_handle_nat


nat_handle_nmi:	rti
nat_handle_irq:	jml	default_IVIRQ	


		.a8
		.i8
emu_handle_irq:	sta	dp_mos_INT_A
		lda	1,S
		and	#$10
		beq	@sl
		jmp	emu_handle_brk
@sl:		pea	@c>>8
		pea	$04 + ((<@c)<<8)
		pea	0
		jmp	emu2nat_rti
@c:		pea	>@ret			; fake flags and bank 0 (return)
		pea	4 + (<@ret * 256)
		jml	default_IVIRQ
@ret:		pea	@c2
		pea	$0400
		jmp	nat2emu_rti
@c2:		lda	dp_mos_INT_A
		rti

;;	; TODO: Move this lot to ROM and call entry/exit shims
;;emu_handle_irq:	sta	dp_mos_INT_A
;;		lda	1,S
;;		and	#$10
;;		bne	emu_handle_brk
;;		clc
;;		xce
;;		pea	>@ret			; fake flags and bank 0 (return)
;;		pea	4 + (<@ret * 256)
;;		jml	default_IVIRQ
;;@ret:		pea	0
;;		pld
;;		phd
;;		plb
;;		plb
;;		sec
;;		xce
;;		lda	dp_mos_INT_A
;;		rti

emu_handle_nmi:	rti

		; enter emu mode and set DP/B to 0
		; stacked should be:
		; +3..4	Addr	Address to continue at in bank 0
		; +2	P	Flags to pass to caller
		; +1	#	number of bytes extra of stack to transfer
.proc nat2emu_rti
		sei			; turn interrupts off - an NMI might occur though that shouldn't disturb stack pointer
		rep	#$31		; we should still be careful of data below stack pointer possibly changing, clear carry
		sep	#$10		; we can afford to lose top part of X/Y as they will get lost when we xce
		.a16
		.i8
		phy
		phx
		pha			; save caller A

		; must switch to DP=B=0 before switching to emu mode
		; as interrupts etc in emu mode may assume them
		pea	0
		pld
		phd
		plb
		plb

		tsc			; A = nat stack pointer
	; nat stack now contains
	;	Stack/DP offset
	;	+7..8	RTI address (16 bits)
	;	+6	caller's flags
	;	+5	# number of bytes extra of stack to transfer
	;	+4	caller's Y (8 bit)
	;	+3	caller's X (8 bit)
	;	+1..2   caller's A
N_STACKED = 8
		sta	a:B0_NAT_STACK	; save nat stack pointer (temporary)

		lda	5,S
		and	#$00FF		; get 8 bit # extra bytes into A
					; carry was cleared in rep above
		adc	#N_STACKED	; step back over saved stuff will get moved to emu stack
		pha
		adc	a:B0_NAT_STACK
		sta	a:B0_NAT_STACK	; store back adjusted stack
		rep	#$10
		.i16
		tax			; source for copy (top)
		lda	a:B0_EMU_STACK	; get emu stack pointer
		sec
		sbc	1,S
		ply			; count
		tcs
		; we are now using the emu mode stack, copy across stuff from
		; native mode stack
		
		tya
		ldy	a:B0_EMU_STACK

		mvp	#0,#0		; copy stack data across


		sep	#$30
		.i8
		.a8

		inc	A
		sta	5,S

	; emu stack now contains
	;	Stack/DP offset
	;	+9....	extra bytes requested
	;	+7..8	RTI address (16 bits)
	;	+6	caller's flags
	;	+5	"0"
	;	+4	caller's Y (8 bit)
	;	+3	caller's X (8 bit)
	;	+1..2   caller's A (16 bit)


		pla
		xba
		pla
		xba
		plx
		ply
		plb		; "0"

		sec
		xce
		rti

.endproc

		.a8
		.i8
emu_handle_cop:	php				; caller's flags
		pea	cop_handle_emu >> 8
		pea	$04 + ((>cop_handle_emu) << 8)
		pea	1			; copy 1 extra byte (flags)
		; fall through to emu2nat_rti!

		; enter nat mode from emu
		; stacked should be:
		; +4..6	Addr	Address to continue at 24-bit
		; +3	P	Flags to pass to caller
		; +2	0	reserved "0"
		; +1	#	number of stacked bytes to transfer across

.proc emu2nat_rti
		sei		; turn interrupts off - an NMI might occur though that shouldn't disturb stack pointer
		clc
		xce
		rep	#$21	; clear carry for ADC below
		.a16
		.i8
		phy
		phx			; save caller X (8bit)
		pha			; save caller A

;		;TODO: force bank 0 - maybe remove?
;		pea	0
;		plb
;		plb


	; emu stack now contains
	;	Stack/DP offset
	;	+11...  extra bytes
	;	+8..10	RTI address (16 bits)
	;	+7	caller's flags
	;	+6	reserved "0"
	;	+5	# number of extra bytes to transfer
	;	+4	caller's Y
	;	+3	caller's X
	;	+1..2   caller's A

	N_STACKED = 10

		tsc
		sta	a:B0_EMU_STACK	; save nat stack pointer (temporary)

		lda	5,S		; get 8 bit # extra bytes into A (0 must be pushed above 8 bit len)
		adc	#N_STACKED	; step back over saved stuff will get moved to emu stack
		rep	#$11		; clear carry and choose big index registers
		.i16
		pha			; number of bytes to copy
		adc	a:B0_EMU_STACK
		sta	a:B0_EMU_STACK	; store back adjusted stack
		tax			; set source for copy (topmost)
		lda	a:B0_NAT_STACK	; get emu stack pointer
		sec
		sbc	1,S		; make room on native stack
		ply
		tcs

		tya		
		ldy	a:B0_NAT_STACK	; set dest for copy (topmost) - still pointing at top

		; we are now using the native mode stack, copy across stuff from
		; emu mode stack into the space we reserved

		; X points at emu stack
		; Y points at native stack
		; A contains number of bytes to copy

		mvp	#0,#0		; copy stack data

	; emu stack now contains
	;	Stack/DP offset
	;	+11...  extra bytes
	;	+8..10	RTI address (16 bits)
	;	+7	caller's flags
	;	+6	reserved "0"
	;	+5	# number of extra bytes to transfer
	;	+4	caller's Y
	;	+3	caller's X
	;	+1..2   caller's A

		sep	#$10
		.i8
		pla
		plx
		ply
		plb
		plb

		rti
.endproc

		.segment "boot_CODE"
		.i8
		.a8


emu_default_irq1v:
emu_default_irq2v:
		rti

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
;;		ora	#MEM_CTL_AUTOBOOT_THROT_MODE	; production mode - but no hoglet debugger
		ora	#MEM_CTL_AUTOBOOT_MODE
		sta	sheila_MEM_CTL

; Map the BLTURBO registers so that both native and emulation modes see the 
; same RAM in 0-FFFF, the rest from motherboard
		lda	#$01
		sta	sheila_MEM_LOMEMTURBO

		lda	#BITS_MEM_TURBO2_THROTTLE	
		sta	sheila_MEM_TURBO2

		
		; enter native mode
		clc
		jml	enter_FF

		.code
enter_FF:	xce

		pea	0
		pld			; direct page is at 0		
		phk
		plb			; ensure bank FF

		rep	#$30
		.a16
		.i16

		; set up stacks
		lda	#STACKBBC_TOP
		sta	f:B0_EMU_STACK	; indicate EMU_STACK in use
		lda	#STACKNAT_TOP
		sta	f:B0_NAT_STACK	; top of NAT stack
		tcs

		sep	#$30
		.a8
		.i8


		; enable JIM interface
		lda	#JIM_DEVNO_BLITTER
		sta	fred_JIM_DEVNO




;TODO:::::::::::::::: ZERO DPSYS :::::::::: This should depend on break type -see original MOS

		lda	#0
		ldx	#$C0
@l:		sta	z:0,X
		inx
		bne	@l

;TODO:::::::::::::::: ZERO/FF SYSVARS :::::::::: This should depend on break type -see original MOS


			ldx	#$90
			ldy	#$87-$36
			lda	#$00				; A=0
_BDA44:			cpx	#$ce				; zero &200+X to &2CD
			bcc	_BDA4A				; 
			lda	#$ff				; then set &2CE to &2FF to &FF
_BDA4A:			sta	$200,X				; 
			inx					; 
			bne	_BDA44				; 




_BDA5B:			lda	default_sysvars-1,Y		; copy data from &D93F+Y
			sta	$236-1,Y			; to &1FF+Y
			dey					; until
			bne	_BDA5B				; 1FF+Y=&200



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


		jsr	cfgGetMosBase
		DEBUG_PRINTF "MOS_BASE =%H%A\n"

		rep	#$30
		.i16
		.a16

		DEBUG_PRINTF "OSBYTEWORD init\n"
		jsl	osByteWordInit

		DEBUG_PRINTF "IRQdisp\n"
		jsr	initIRQdispatcher


		DEBUG_PRINTF "initHandles\n"
		jsl	initHandles

		DEBUG_PRINTF "initB0Blocks\n"
		jsl	initB0Blocks

		DEBUG_PRINTF "Init modules\n"
		jsl	modules_init


; Set up the BBC/emulation mode OS vectors to point at their defaults
; which are the entry points in bbc-nat-vectors
		ldx	#.loword(default_BBC_vectors)
		ldy	#.loword(BBC_USERV)
		lda	#default_BBC_vectors_len
		mvn	#^default_BBC_vectors, #^BBC_USERV

; zeroes to the native OS Vecs
		lda	#0
		ldx	#NAT_OS_VECS_COUNT*3
		sep	#$20
@lp2:		sta	a:NAT_OS_VECS-1,X
		dex	
		bne	@lp2
		rep	#$20	

		; set up OSBYTE/WORD native vector handlers
		pea	DPBBC
		pld
		ldx	#0
		ldy	#IX_BYTEV
		cop	COP_27_OPBHI
		.faraddr doOSBYTE
		cop	COP_09_OPADV

		pea	DPBBC
		pld
		ldx	#0
		ldy	#IX_WORDV
		cop	COP_27_OPBHI
		.faraddr doOSWORD
		cop	COP_09_OPADV

		pea	DPBBC
		pld
		ldx	#0
		ldy	#IX_CLIV
		cop	COP_27_OPBHI
		.faraddr doCLIV
		cop	COP_09_OPADV

		pea	DPBBC
		pld
		ldx	#0
		ldy	#IX_FSCV
		cop	COP_27_OPBHI
		.faraddr doFSCV
		cop	COP_09_OPADV

		DEBUG_PRINTF "buffers\n"
		jsl	initBuffers
	
		sep	#$30
		.i8
		.a8
		lda	#$80
		sta	sysvar_RAM_AVAIL

		DEBUG_PRINTF "hardware\n"
		jsr	hardwareInit


;		DEBUG_PRINTF "VDU\n"
;		lda	#0
;		jsl	VDU_INIT

;;		pea	DPBBC
;;		pld
;;		ldx	#0
;;		ldy	#IX_WRCHV
;;		cop	COP_27_OPBHI
;;		.faraddr debug_printA
;;		cop	COP_09_OPADV
		

		rep	#$30
		.i16
		.a16

		DEBUG_PRINTF "insert VDU module\n"
		ldx	#10
		pea	$007D
		plb
		lda	#$4000
		cop	COP_34_OPMOD

		DEBUG_PRINTF "insert KEYBOARD module\n"
		ldx	#10
		pea	$007D
		plb
		lda	#$8000
		cop	COP_34_OPMOD



		sep	#$20
		.a8


		phk
		plb		
		ldx	#.loword(str_boot_7)		
		lda	vduvar_MODE
		eor	#7
		beq	@lp
		ldx	#.loword(str_boot)
@lp:		lda	a:0,X
		beq	@sk
		cop	COP_00_OPWRC
		inx
		bra	@lp
@sk:		cop	COP_03_OPNLI
		cop	COP_03_OPNLI

		rep	#$30
		.a16
		.i16





		DEBUG_PRINTF "scan ROMs\n"
		jsl	roms_scanroms			; only on ctrl-break, but always for now...
		jsl	roms_init_services		; call initialisation service calls



		cli

;;		pea	$7D7D
;;		plb
;;		plb
;;		lda	#$4000
;;		ldy	$4000 + 12
;;		cop	COP_32_OPSUM
;;
;;		wdm 0


;		cop	COP_26_OPBHA
;		.byte	"HELP",13,0
;		cop	COP_0E_OPCOM

		sep	#$30
		.a8
		.i8
		pea	0
		pld
		phd
		plb
		plb
		ldx	sysvar_ROMNO_BASIC
		lda	#OSBYTE_142_ENTER_LANGUAGE
		cop	COP_06_OPOSB

		wdm 0


str_basprog:	.byte "OLD",13,"RUN",13,0
		;;.byte "P.\"DOMISH\"",13,0




SERIAL_STATUS	:= sheila_ACIA_CTL
RXRDY		:= ACIA_RDRF
SERIAL_RXDATA	:= sheila_ACIA_DATA
TXRDY		:= ACIA_TDRE
SERIAL_TXDATA	:= sheila_ACIA_DATA


		
		.a8
DbgPrintA:	php				; register size agnostic!
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
DbgPrintStrBHA:	phx
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
		jsr	DbgPrintA
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


str_boot_7:
		.incbin "logo.bin"
		.byte	0

str_boot:	.byte	"Dossytronics 816 MOS", 0

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


	; Move event stuff to a module?
.proc kernelRaiseEvent:far
		sec
		rtl
.endproc 

;;;;;;;;;;;;;;;;;; TODO: split this up into relevant modules?




default_BBC_vectors:
		.addr	tblNatShims+0*3			; USERV
		.addr	default_emu_brkv		; BRKV
		.addr	emu_default_irq1v		; IRQ1V
		.addr	emu_default_irq2v		; IRQ2V

		.repeat IX_VEC_BBC_MAX+1-4, ix
		.addr	tblNatShims+3*(ix+4)
		.endrepeat
default_BBC_vectors_len := *-default_BBC_vectors

; -------------------------------------------------------------------------
; |									  |
; |	  DEFAULT MOS VARIABLES SETTINGS				  |
; |									  |
; -------------------------------------------------------------------------

;* Read/Written by OSBYTE &A6 to &FC

default_sysvars:
			.addr	$0190				; OSBYTE variables base address		 &236	*FX166/7
								; (address to add to osbyte number)
			.addr	BBC_EXT_VEC_BASE		; Address of extended vectors		 &238	*FX168/9
			.addr	oswksp_ROMTYPE_TAB		; Address of ROM information table	 &23A	*FX170/1
			.addr	0				; Address of key translation table	 &23C	*FX172/3  ;;;;TODO: Do this in keyboard module?!
			.word	vduvars_start			; Address of VDU variables		 &23E	*FX174/5

			.byte	$00				; CFS/Vertical sync Timeout counter	 &240	*FX176
			.byte	$00				; Current input buffer number		 &241	*FX177
			.byte	$ff				; Keyboard interrupt processing flag	 &242	*FX178
			.byte	$00				; Primary OSHWM (default PAGE)		 &243	*FX179
			.byte	$00				; Current OSHWM (PAGE)			 &244	*FX180
			.byte	$01				; RS423 input mode			 &245	*FX181
			.byte	$00				; Character explosion state		 &246	*FX182
			.byte	$00				; CFS/RFS selection, CFS=0 ROM=2	 &247	*FX183
			.byte	$00				; Video ULA control register copy	 &248	*FX184
			.byte	$00				; Pallette setting copy			 &249	*FX185
			.byte	$00				; ROM number selected at last BRK	 &24A	*FX186
			.byte	$ff				; BASIC ROM number			 &24B	*FX187
			.byte	$04				; Current ADC channel number		 &24C	*FX188
			.byte	$04				; Maximum ADC channel number		 &24D	*FX189
			.byte	$00				; ADC conversion 0/8bit/12bit		 &24E	*FX190
			.byte	$ff				; RS423 busy flag (bit 7=0, busy)	 &24F	*FX191

			.byte	$56				; ACIA control register copy		 &250	*FX192
			.byte	$19				; Flash counter				 &251	*FX193
			.byte	$19				; Flash mark period count		 &252	*FX194
			.byte	$19				; Flash space period count		 &253	*FX195
			.byte	$32				; Keyboard auto-repeat delay		 &254	*FX196
			.byte	$08				; Keyboard auto-repeat rate		 &255	*FX197
			.byte	$00				; *EXEC file handle			 &256	*FX198
			.byte	$00				; *SPOOL file handle			 &257	*FX199
			.byte	$00				; Break/Escape handing			 &258	*FX200
			.byte	$00				; Econet keyboard disable flag		 &259	*FX201
			.byte	$20				; Keyboard status			 &25A	*FX202
								; bit 3=1 shift pressed
								; bit 4=0 caps	lock
								; bit 5=0 shift lock
								; bit 6=1 control bit
								; bit 7=1 shift enabled
			.byte	$09				; Serial input buffer full threshold	 &25B	*FX203
			.byte	$00				; Serial input suppression flag		 &25C	*FX204
			.byte	$00				; Cassette/RS423 flag (0=CFS, &40=RS423) &25D	*FX205
			.byte	$00				; Econet OSBYTE/OSWORD interception flag &25E	*FX206
			.byte	$00				; Econet OSRDCH interception flag	 &25F	*FX207

			.byte	$00				; Econet OSWRCH interception flag	 &260	*FX208
			.byte	$50				; Speech enable/disable flag (&20/&50)	 &261	*FX209
			.byte	$00				; Sound output disable flag		 &262	*FX210
			.byte	$03				; BELL channel number			 &263	*FX211
			.byte	$90				; BELL amplitude/Envelope number	 &264	*FX212
			.byte	$64				; BELL frequency			 &265	*FX213
			.byte	$06				; BELL duration				 &266	*FX214
			.byte	$81				; Startup message/!BOOT error status	 &267	*FX215
			.byte	$00				; Length of current soft key string	 &268	*FX216
			.byte	$00				; Lines printed since last paged halt	 &269	*FX217
			.byte	$00				; 0-(Number of items in VDU queue)	 &26A	*FX218
			.byte	$09				; TAB key value				 &26B	*FX219
			.byte	$1b				; ESCAPE character			 &26C	*FX220

				; The following are input buffer code interpretation variables for
				; bytes entered into the input buffer with b7 set (is 128-255).
				; The standard keyboard only enters characters &80-&BF with the
				; function keys, but other characters can be entered, for instance
				; via serial input of via other keyboard input systems.
				; 0=ignore key
				; 1=expand as soft key
				; 2-FF add to base for ASCII code
			.byte	$01				; C0-&CF				 &26D	*FX221
			.byte	$d0				; D0-&DF				 &26E	*FX222
			.byte	$e0				; E0-&EF				 &26F	*FX223
			.byte	$f0				; F0-&FF				 &270	*FX224
			.byte	$01				; 80-&8F function key			 &271	*FX225
			.byte	$80				; 90-&9F Shift+function key		 &272	*FX226
			.byte	$90				; A0-&AF Ctrl+function key		 &273	*FX227
			.byte	$00				; B0-&BF Shift+Ctrl+function key	 &274	*FX228

			.byte	$00				; ESCAPE key status (0=ESC, 1=ASCII)	 &275	*FX229
			.byte	$00				; ESCAPE action				 &276	*FX230
_BD9B7:			.byte	$ff				; USER 6522 Bit IRQ mask		 &277	*FX231
			.byte	$ff				; 6850 ACIA Bit IRQ bit mask		 &278	*FX232
			.byte	$ff				; System 6522 IRQ bit mask		 &279	*FX233
			.byte	$00				; Tube prescence flag			 &27A	*FX234
			.byte	$00				; Speech processor prescence flag	 &27B	*FX235
			.byte	$00				; Character destination status		 &27C	*FX236
			.byte	$00				; Cursor editing status			 &27D	*FX237

;****************** Soft Reset high water mark ***************************

			.byte	$00				; unused				 &27E	*FX238
			.byte	$00				; unused				 &27F	*FX239
			.byte	$00				; Country code				 &280	*FX240
			.byte	$00				; User flag				 &281	*FX241
			.byte	$64				; Serial ULA control register copy	 &282	*FX242
			.byte	$05				; Current system clock state		 &283	*FX243
			.byte	$ff				; Soft key consitancy flag		 &284	*FX244
			.byte	$01				; Printer destination			 &285	*FX245
			.byte	$0a				; Printer ignore character		 &286	*FX246

;****************** Hard Reset High water mark ***************************

			.byte	$00				; Break Intercept Vector JMP opcode	 &288	*FX247
			.byte	$00				; Break Intercept Vector address low	 &288	*FX248
			.byte	$00				; Break Intercept Vector address high	 &289	*FX249
			.byte	$00				; unused (memory used for VDU)		 &28A	*FX250
			.byte	$00				; unused (memory used for display)	 &28B	*FX251
			.byte	$ff				; Current language ROM number		 &28C	*FX252



