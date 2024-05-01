		.include "dp_bbc.inc"
		.include "hardware.inc"
		.include "debug.inc"
		.include "sysvars.inc"
		.include "oslib.inc"
		
		.export roms_scanroms
		.export roms_init_services
		.export roms_selX
		.export _OSBYTE_143

ROM_SERVICE=$8003

		.segment "BMOS_NAT_CODE"

roms_selA:	php
		sep	#$20
		sta	z:dp_mos_curROM		; assumes DP set
		sta	f:sheila_ROMCTL_SWR	; set register
		plp
		rts		

roms_selX:	pha				; push A (whatever size)
		txa
		jsr	roms_selA
		pla
		rtl		


roms_scanroms:	php
		sep	#$30
		.a8
		.i8

		pea	$FFFF
		plb
		plb

;;; - adapted from Tom's MOS disassembly TODO: insert/unplug stuff hacked out

		ldx	#0			; the current ROM being checked

scanROMlp:	jsr	isRomValid		; check for valid ROM, rest relies on F4 being set here
		bcc	currentROMInvalid

		ldx	z:dp_mos_curROM
		txy
nextOtherROM:
;;		DEBUG_PRINTF "nextOtherROM X=%X, Y=%Y\n"
		iny                          	;next other ROM
		cpy	#$10                    ;out of other ROMs?
		bcs	currentROMValid		;taken if no more other ROMs

		lda	#$0
		sta	z:dp_mos_OS_wksp2
		lda	#$80
		sta	z:dp_mos_OS_wksp2+1

;;		DEBUG_PRINTF "compare X=%X, Y=%Y\n"

compareLoop:
		sty	sheila_ROMCTL_SWR & $FFFF	;select other ROM
		lda	(dp_mos_OS_wksp2)
		stx	sheila_ROMCTL_SWR & $FFFF	;select ROM
		cmp	(dp_mos_OS_wksp2)
		bne	nextOtherROM		;taken if other ROM is good
		inc	dp_mos_OS_wksp2+0
		bne	compareLoop
		inc	dp_mos_OS_wksp2+1
		lda	dp_mos_OS_wksp2+1
		cmp	#$84			;compare only the first 1 KB
		bcc	compareLoop
		; The first 1 KB of the current ROM matches the first
		; 1 KB of some higher-priority ROM, so the current ROM
		; is invalid.
		lda	#0			; TODO: not line 350 here - set to 0 for BLTUTIL
		jsr	staRomTableX		; mark bad
;;		DEBUG_PRINTF "matched"
currentROMInvalid:
		ldx	z:dp_mos_curROM
;;		DEBUG_PRINTF "invalid X=%X\n"
		lda	#0			; TODO: not line 350 here - set to 0 for BLTUTIL
		jsr	staRomTableX
		bra	nextROM

currentROMValid:
		lda	$8006
;;		DEBUG_PRINTF "VAL #%X, type=%A\n"
		jsr	staRomTableX
		and	#$8F
		bne	nextROM			;taken if any mandatory bits are set

		phb
;;		DEBUG_PRINTF "BASIC #%X\n"
		pea	0
		plb
		plb
		stx	sysvar_ROMNO_BASIC
		plb

nextROM:
		inx
		cpx	#$10
		bcc	scanROMlp

		plp
		rtl


		; this call assumes a8/i8 on entry/exit
isRomValid:	
		jsl	roms_selX
		ldy	$8007		; fetch ROM copyright offset pointer
		clc             	; assume no match
		ldx	#3
@lp:	       	phb
		phk
		plb			; program bank for match string
		lda	strr_copy,X     ; Z=1 if it matches "(C)" (not backwards we can use ,Y)
		plb			; back to FF
		eor	$8000,Y		; fetch possible ROM copyright char
		bne	@ex           	; branch taken if no match
		iny             	; next copyright byte
		dex             	; count 4 chars
		bpl	@lp
		sec             	; C=1 means a match
@ex:           	rts


strr_copy: 	.byte	")C(",0

staRomTableX:	phb
		pea	0
		plb
		plb
		sta	oswksp_ROMTYPE_TAB,X
		plb
		rts


		.code



;*************************************************************************
;*									 *
;*	 OSBYTE 143							 *
;*	 Pass service commands to sideways ROMs				 *
;*									 *
;*************************************************************************
				; On entry X=service call number
				; Y=any additional parameter
				; On exit X=0 if claimed, or preserved if unclaimed
				; Y=any returned parameter
				; When called internally, EQ set if call claimed

		.a8
		.i8
_OSBYTE_143:	

		lda	dp_mos_curROM			; Get current ROM number
		pha					; Save it

		; enter emulation mode
		pea	.loword(@c)
		php
		lda	#0
		pha
		jml	nat2emu_rti
@c:		

		txa					; Pass service call number to  A
		ldx	#$0f				; Start at ROM 15
		; Issue service call loop
_BF16E:		bit	oswksp_ROMTYPE_TAB,X		; Read bit 7 on ROM type table (no ROM has type 254 &FE)
		bpl	_BF183				; If not set (+ve result), step to next ROM down
		stx	dp_mos_curROM			; Otherwise, select this ROM, &F4 RAM copy
		stx	.loword(sheila_ROMCTL_SWR)	; Page in selected ROM
		jsr	ROM_SERVICE			; Call the ROM's service entry
							; X and P do not need to be preserved by the ROM
		tax					; On exit pass A to X to check if claimed
		beq	_BF186				; If 0, service call claimed, re-select ROM and exit
		ldx	dp_mos_curROM			; Otherwise, get current ROM back
_BF183:		dex					; Step to next ROM down
		bpl	_BF16E				; Loop until done ROM 0

_BF186:		

		; leave emulation mode
		pea	@c2>>8
		lda	#<@c2
		pha
		php
		lda	#0
		pha
		pha
		jml	emu2nat_rti
@c2:		

		pla					; Get back original ROM number
		sta	dp_mos_curROM			; Set ROM number RAM copy
		sta	sheila_ROMCTL_SWR		; Page in the original ROM
		txa					; Pass X back to A to set zero flag
		rtl					; And return



		.segment "BMOS_NAT_CODE"

.proc roms_init_services:far
		php
		sep	#$30
		.a8
		.i8

		; TODO: hard/soft/cold boot
		lda	#0
		ldx	#$F
@lp:		sta	swrom_wksp_tab,X
		dex
		bpl	@lp

		; TODO: auto-hazel

		ldy	#$0e				; set current value of PAGE
		ldx	#$01				; issue claim absolute workspace call	
		lda	#OSBYTE_143_SERVICE_CALL
		cop	COP_06_OPOSB
		ldx	#$02				; send private workspace claim call
		lda	#OSBYTE_143_SERVICE_CALL
		cop	COP_06_OPOSB
		sty	sysvar_PRI_OSHWM		; set primary OSHWM
		sty	sysvar_CUR_OSHWM		; set current OSHWM
		ldx	#$fe				; issue call for Tube to explode character set etc.
		ldy	sysvar_TUBE_PRESENT		; Y=FF if tube present else Y=0
		lda	#OSBYTE_143_SERVICE_CALL
		cop	COP_06_OPOSB


		plp
		rtl
.endproc
