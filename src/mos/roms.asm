		.include "dp_bbc.inc"
		.include "hardware.inc"
		.include "debug.inc"
		.include "sysvars.inc"
		
		.export roms_scanroms

		.code

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
		rts		


roms_scanroms:	php
		sep	#$30
		.a8
		.i8

		jsr	bankFF

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
		lda	#1
		jsr	staRomTableX		; mark bad
;;		DEBUG_PRINTF "matched"
currentROMInvalid:
		ldx	z:dp_mos_curROM
;;		DEBUG_PRINTF "invalid X=%X\n"
		lda	#1			; like MOS 350 blank out bad uns
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
		jsr	bank0
		stx	sysvar_ROMNO_BASIC
		plb

nextROM:
		inx
		cpx	#$10
		bcc	scanROMlp

		plp
		rts


		; this call assumes a8/i8 on entry/exit
isRomValid:	
		jsr	roms_selX
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
		jsr	bank0
		sta	oswksp_ROMTYPE_TAB,X
		plb
		rts

