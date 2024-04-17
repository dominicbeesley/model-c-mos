;	********************************************************************************
;	* Hardware specific routines                                                   *
;	*                                                                              *
;	* This file contains hardware-specific routines which should be moved to       *
;	* relevant modules as they are developed. This may evolve into some sort of    *
;	* HAL or maybe hardware specific modules will be developed - still not sure    *
;	********************************************************************************


		.include "hardware.inc"
		.include "sysvars.inc"
		.include "oslib.inc"
		.include "dp_bbc.inc"
		.include "nat-layout.inc"

		.export	hardwareDetectHardReset
		.export	hardwareInit
		.export OPIIQ_SYSVIA_IRQ	; used in Keyboard - duplicate?


;	********************************************************************************
;	* Detect a hard reset                                                          *
;	*                                                                              *
;	* Returns A=0, Cy=C if a hard reset
;	********************************************************************************

hardwareDetectHardReset:
		php
		sep	#$20
		.a8
		.i16
		lda	f:sheila_SYSVIA_ier
		asl	A
		cmp	#1
		bcc	@retclc
		plp
		sec
		rts
@retclc:	plp
		clc
		rts




;	********************************************************************************
;	* Initialise hardware to a known reset state                                   *
;	*                                                                              *
;	* SysVia:                                                                      *
;	* 	PortB output on bits 3..0                                              *
;	* UserVia:                                                                     *
;	*       PortA output on all bits                                               *
;	* IC32:                                                                        *
;	*       Set all except F                                                       *
;	* User/SysVia:                                                                 *
;	*       Clear all interrupt flags and enables                                  *
;	*                                                                              *
;	********************************************************************************

hardwareInit:	
		php		
		sep	#$30
		.a8
		.i8

		pea	^sheila_SYSVIA_ddrb<<8
		plb
		plb
		; Set sysPORTB to output on bits 3..0
		lda	#$0f				; set PORT B to output on bits 0-3 Input 4-7
		sta	a:.loword(sheila_SYSVIA_ddrb)	; 

		; Set all IC32 latches
@lpl:		dec	A				; loop start
		sta	a:.loword(sheila_SYSVIA_orb)	; write latch IC32
		cmp	#$09				; is it 9
		bcs	@lpl				; if so go back and do it again
							; A=8 at this point
							; Caps lock On, SHIFT lock undetermined
							; Keyboard Autoscan on
							; sound disabled (may still sound)
	
		stz	a:.loword(sheila_USRVIA_ddra)	; set port A of user via to all outputs (printer out)


		lda	#$7f				; 
		ldx	#1				; 
@lprv:		sta	a:.loword(sheila_SYSVIA_ifr),X	; index to both IFR/IER
		sta	a:.loword(sheila_USRVIA_ifr),X	; 
		dex					; 
		bpl	@lprv				; 


;TODO: KEYBOARD
;TODO: ADC
;TODO: SPEECH
;;		lda	#$f2				; enable interrupts 1,4,5,6 of system VIA
		lda	#$C2				; enable interrupts 1,6 of system VIA
		sta	sheila_SYSVIA_ier		; 
							; 0	 Keyboard enabled as needed
							; 1	 Frame sync pulse
							; 4	 End of A/D conversion
							; 5	 T2 counter (for speech)
							; 6	 T1 counter (10 mSec intervals)
							;
		lda	#$04				; set system VIA PCR
		sta	sheila_SYSVIA_pcr		; 
							; CA1 to interrupt on negative edge (Frame sync)
							; CA2 Handshake output for Keyboard
							; CB1 interrupt on negative edge (end of conversion)
							; CB2 Negative edge (Light pen strobe)
							;
		lda	#$60				; set system VIA ACR
		sta	sheila_SYSVIA_acr		; 
							; disable latching
							; disable shift register
							; T1 counter continuous interrupts
							; T2 counter timed interrupt

TIMER_PER = 1000000/100

		lda	#<(TIMER_PER-2)			; set system VIA T1 counter (Low)
		sta	sheila_SYSVIA_t1ll		; 
							; this becomes effective when T1 hi set

;;		lda	#$0E
		sta	sheila_USRVIA_pcr		; set user VIA PCR
							; CA1 interrupt on -ve edge (Printer Acknowledge)
							; CA2 High output (printer strobe)
							; CB1 Interrupt on -ve edge (user port)
							; CB2 Negative edge (user port)

		sta	sheila_ADC_sr			; set up A/D converter
							; Bits 0 & 1 determine channel selected
							; Bit 3=0 8 bit conversion bit 3=1 12 bit

		cmp	sheila_USRVIA_pcr		; read user VIA IER if = &0E then DAA2 chip present
		beq	_BDAA2				; so goto DAA2
		inc	sysvar_USERVIA_IRQ_MASK_CPY	; else increment user VIA mask to 0 to bar all
							; user VIA interrupts

_BDAA2:		lda	#>(TIMER_PER-2)			; set T1 (hi) to &27 this sets T1 to &270E (9998 uS)
		sta	sheila_SYSVIA_t1lh		; or 10msec, interrupts occur every 10msec therefore
		sta	sheila_SYSVIA_t1ch		; 

		lda	#>hardwareIrqHandleSysVia_T1
		xba
		lda	#<hardwareIrqHandleSysVia_T1
		ldy	#IRQ_PRIOR_T1
		ldx	#VIA_IFR_BIT_T1
		jsr	OPIIQ_SYSVIA_IRQ

		lda	#>hardwareIrqHandleSysVia_Vsync
		xba
		lda	#<hardwareIrqHandleSysVia_Vsync
		ldy	#IRQ_PRIOR_VSYNC
		ldx	#VIA_IFR_BIT_CA1
		jsr	OPIIQ_SYSVIA_IRQ

		plp
		rts

OPIIQ_SYSVIA_IRQ:
		phk
		plb
		phx
		ldx	#$00
		pea	DPBBC
		pld
		cop	COP_2F_OPIIQ
		.faraddr sheila_SYSVIA_ifr
		.byte	$00

		plx
		pea	^sheila_SYSVIA_ier<<8
		plb
		plb
		lda	#>sheila_SYSVIA_ier
		xba
		lda	#<sheila_SYSVIA_ier
		cop	COP_31_OPMIQ

		rts


;;		php
;;		rep	#$30
;;		.a16
;;		.i16
;;		phd
;;		phb
;;
;;DPSYS = 0
;;
;;;;	TODO: allocate stack for IRQ handlers - for now use $01xx
;;;;		cop	COP_13_OPAST    ;allocate a stack
;;;;		.word	$0100			; stack size
;;;;@lockup:	bcs	@lockup         ;if carry set here lock up the machine !
;;		lda	#$0000
;;		sta	f:B0_IRQ_STACK
;;		lda	#$0000
;;		sta	f:B0LL_IRQ_BLOCKS
;;		phk
;;		plb
;;		sep	#$30
;;		.a8
;;		.i8
;;		lda	#>irqh_catchall
;;		xba
;;		lda	#<irqh_catchall
;;		ldx	#$ff
;;		ldy	#$00
;;		pea	DPSYS
;;		pld
;;		cop	COP_2F_OPIIQ    ;set up a catch-all IRQ handler with lowest priority
;;		.faraddr $00ffff         ;device address
;;		.byte	$00  			; device eor mask
;;		lda	#>irqh_ula_rtc
;;		xba
;;		lda	#<irqh_ula_rtc
;;		ldy	#$21 			; rtc priority
;;		jsr	OPIIQ_ULA_IRQ
;;		ldx	#$08 			; real time clock interrupt mask
;;		jsr	OPMIQ_ULA_IRQ   ;also mask with SYSVAR_ELK_ULA_IE
;;		lda	#>irqh_vsync
;;		xba
;;		lda	#<irqh_vsync
;;		ldy	#$20 			; vsync priority
;;		jsr	OPIIQ_ULA_IRQ
;;		ldx	#$04 			; vsync interrupt mask
;;		jsr	OPMIQ_ULA_IRQ   ;also mask with SYSVAR_ELK_ULA_IE
;;		lda	#>irqh_via_cb1
;;		xba
;;		lda	#<irqh_via_cb1
;;		phk
;;		plb
;;		ldx	#$00
;;		ldy	#$10 			; priority
;;		pea	DPSYS
;;		pld
;;		cop	COP_2F_OPIIQ
;;		.faraddr	VIA_IFR
;;		.byte	$00
;;		ldx	#$10 			; via_cb1
;;		pea	$4200			; TODO: set to >VIA base
;;		plb
;;		plb
;;		lda	#>VIA_IER
;;		xba
;;		lda	#<VIA_IER
;;		cop	COP_31_OPMIQ
;;		plb
;;		pld
;;		plp
;;		rts
;;
;;OPMIQ_ULA_IRQ:	pea   $0000
;;		plb
;;		plb
;;		lda	#>SYSVAR_ELK_ULA_IE
;;		xba
;;		lda	#<SYSVAR_ELK_ULA_IE
;;		cop	COP_31_OPMIQ
;;		rts
;;
;;OPIIQ_ULA_IRQ:	
;;		phk
;;		plb
;;		ldx	#$00
;;		pea	DPSYS
;;		pld
;;		cop	COP_2F_OPIIQ
;;		.faraddr sheila_ULA_IRQ_CTL
;;		.byte	$00
;;		rts



;============================================ IRQ handlers ============================================
; TODO: check/change API to set bank 0 in dispatcher?

hardwareIrqHandleSysVia_T1:
		.a8
		.i8

		pea	0
		plb
		plb

		lda	#VIA_IFR_BIT_T1
		sta	f:sheila_SYSVIA_ifr


	; This needs to do more, there needs to be a 100Hz poll sent to keyboard/vdu

		lda	sysvar_TIMER_SWITCH		; get current system clock store pointer (5,or 10)
		tax					; put A in X
		eor	#$0f				; and invert lo nybble (5 becomes 10 and vv)
		pha					; store A
		tay					; put A in Y

	; Carry is always set at this point
_BDDD9:		lda	oswksp_TIME-1,X			; get timer value
		adc	#$00				; update it
		sta	oswksp_TIME-1,Y			; store result in alternate
		dex					; decrement X
		beq	_BDDE7				; if 0 exit
		dey					; else decrement Y
		bne	_BDDD9				; and go back and do next byte

_BDDE7:		pla					; get back A
		sta	sysvar_TIMER_SWITCH		; and store back in clock pointer (i.e. inverse previous
								; contents)
		ldx	#$05				; set loop pointer for countdown timer
_BDDED:		inc	oswksp_OSWORD3_CTDOWN-1,X	; increment byte and if
		bne	_BDDFA				; not 0 then DDFA
		dex					; else decrement pointer
		bne	_BDDED				; and if not 0 do it again
		ldy	#EVENT_05_INTERVAL		; process EVENT 5 interval timer
		jsr	kernelRaiseEvent		; 

_BDDFA:	
		; TODO: get rid of phb/plb?
		phb
		; call the 100Hz poll vectors
		cop	COP_08_OPCAV			
		.byte   IX_N_P100V
		plb
		

; TODO: Keyboard
;;;			lda	INKEY_TIMER			; get byte of inkey countdown timer
;;;			bne	_BDE07				; if not 0 then DE07
;;;			lda	INKEY_TIMER_HI			; else get next byte
;;;			beq	_BDE0A				; if 0 DE0A
;;;			dec	INKEY_TIMER_HI			; decrement 2B2
;;;_BDE07:			dec	INKEY_TIMER			; and 2B1

; TODO: SOUND
;;;_BDE0A:			bit	SOUND_SEMAPHORE			; read bit 7 of envelope processing byte
;;;			bpl	_BDE1A				; if 0 then DE1A
;;;			inc	SOUND_SEMAPHORE			; else increment to 0
;;;			cli					; allow interrupts
;;;			jsr	_SOUND_IRQ			; and do routine sound processes
;;;			sei					; bar interrupts
;;;			dec	SOUND_SEMAPHORE			; DEC envelope processing byte back to 0

; TODO: SPEECH
;;_BDE1A:			bit	BUFFER_8_BUSY			; read speech buffer busy flag
;;			bmi	_BDE2B				; if set speech buffer is empty, skip routine
;;			jsr	_OSBYTE_158			; update speech system variables
;;			eor	#$a0				; 
;;			cmp	#$60				; 
;;			bcc	_BDE2B				; if result >=&60 DE2B
;;			jsr	_LDD79				; else more speech work

; TODO: SERIAL
;;_BDE2B:			bit	_BD9B7				; set V and C
;;			jsr	_POLL_ACIA_IRQ			; check if ACIA needs attention

; TODO: Keyboard
;;			lda	KEYNUM_FIRST			; check if key has been pressed
;;			ora	KEYNUM_LAST			; 
;;			and	OSB_KEY_SEM			; (this is 0 if keyboard is to be ignored, else &FF)
;;			beq	_BDE3E				; if 0 ignore keyboard
;;			sec					; else set carry
;;			jsr	_LF065				; and call keyboard

;TODO: ADC
;;_BDE3E:			jsr	_LE19B				; check for data in user defined printer channel
;;			bit	ADC_SR				; if ADC bit 6 is set ADC is not busy
;;			bvs	_BDE4A				; so DE4A
;;			rts					; else return

		rtl

	
hardwareIrqHandleSysVia_Vsync:
; Entered in .a8 .i8 with DP=0
		.a8
		.i8

		pea	0
		plb
		plb

		dec	a:sysvar_CFSTOCTR		; decrement vertical sync counter
		lda	z:dp_mos_rs423timeout		; A=RS423 Timeout counter
		bpl	_BDD1E				; if +ve then DD1E
		inc	z:dp_mos_rs423timeout		; else increment it
_BDD1E:		lda	a:sysvar_FLASH_CTDOWN		; load flash counter
		beq	_BDD3D				; if 0 then system is not in use, ignore it
		dec	a:sysvar_FLASH_CTDOWN		; else decrement counter
		bne	_BDD3D				; and if not 0 go on past reset routine

		ldx	sysvar_FLASH_SPACE_PERIOD	; else get mark period count in X
		lda	sysvar_VIDPROC_CTL_COPY		; current VIDEO ULA control setting in A
		lsr					; shift bit 0 into C to check if first colour
		bcc	_BDD34				; is effective if so C=0 jump to DD34

		ldx	sysvar_FLASH_MARK_PERIOD	; else get space period count in X
_BDD34:		rol					; restore bit
		eor	#$01				; and invert it
		jsl	vduSetULACTL			; then change colour

		stx	sysvar_FLASH_CTDOWN		; &0251=X resetting the counter

_BDD3D:		ldy	#EVENT_04_VSYNC			; Y=4 and call E494 to check and implement vertical
		jsr	kernelRaiseEvent		; sync event (4) if necessary
		
		lda	#VIA_IFR_BIT_CA1		; A=2
		jmp	_LDE6E				; clear interrupt 1 and exit





_LDE6E:		sta	sheila_SYSVIA_ifr		; 
		clc
		rtl					; and return
