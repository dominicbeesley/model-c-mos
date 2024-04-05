
		.include "dp_sys.inc"
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

		.export nat2emu_rtl


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



nat_handle_cop:	jml	cop_handle_nat	
nat_handle_brk:	rti
nat_handle_nmi:		
nat_handle_irq:	rti

		.a8
emu_handle_cop:	clc		
		xce				; enter native mode 
		jml	cop_handle_emu
emu_handle_irq:	
emu_handle_nmi:	rti


nat2emu_rtl:	sec
		xce
		rtl

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
		lda	#$80
		sta	sysvar_RAM_AVAIL

		DEBUG_PRINTF "VDU_INIT\n"
		lda	#3
		jsl	VDU_INIT

		DEBUG_PRINTF "TEST_VDU\n"
		lda	#65
		pea	IX_WRCHV
		pld
		jsl	CallAVector_NAT

		rep	#$30
		.i16
		.a16

		ldx	#0
here:		lda	#17
		cop	COP_00_OPWRC
		txa
		and	#$0F
		cop	COP_00_OPWRC
		lda	#17
		cop	COP_00_OPWRC
		txa
		lsr	A
		lsr	A
		lsr	A
		lsr	A
		and	#$0F
		ora	#$80
		cop	COP_00_OPWRC

		cop	COP_01_OPWRS
		.byte	"Hello ",0	
		inx
		jsr	PrintHexX
		bra	here


PrintHexA:
	php
	sep	#$20
	.a8
	pha
	lsr	A
	lsr	A
	lsr	A
	lsr	A
	jsr	@nyb
	pla
	pha
	jsr	@nyb
	pla
	plp
	rts
@nyb:	and	#$F
	ora	#'0'
	cmp	#$3A
	bcc	@s
	adc	#'A'-$3A-1
@s:	cop	COP_00_OPWRC
	rts

PrintHexX:
	php
	rep	#$30
	.i16
	.a16
	pha
	txa
	xba
	jsr	PrintHexA
	xba
	jsr	PrintHexA
	pla
	plp
	rts




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



;;;;;;;;;;;;;;;;;; TODO: split this up into relevant modules?


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
