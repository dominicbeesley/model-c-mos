
		.include "debug.inc"
		.include "oslib.inc"
		.include "dp_bbc.inc"
		.include "vectors.inc"
		.include "hardware.inc"
		.include "sysvars.inc"

		.export	brkBadKey
		.export	brkBadCommand

		.export emu_handle_brk
		.export brk_handle_nat
		.export default_emu_brkv

brkBadCommand:		brk					; 
			.byte	$fe				; error number
			.byte	"Bad command"			; 
brkBadKey:		brk					
			.byte	$fb				; 
			.byte	"Bad key"			; 
			brk					



		.segment "boot_CODE"



default_emu_brkv:
		DEBUG_PRINTF "EMU BREAK A=%H%A, X=%X, Y=%Y, F=%F, PC="
		pla
		pla
		sec
		sbc	#2
		tay
		pla
		jsl	debug_printHexA
		tya
		sbc	#0
		jsl	debug_printHexA
		lda	#13
		jsl	debug_printA
@x:		jmp	@x


emu_handle_brk:
		; mos BRK handler - TODO: what to do for native BRKs passing back up to emu?

		txa					; save X on stack
		pha					; 
		tsx					; get status pointer
		lda	$0103,X				; get Program Counter lo
		cld					; 
		sec					; set carry
		sbc	#$01				; subtract 2 (1+carry)
		sta	dp_mos_error_ptr		; and store it in &FD
		lda	$0104,X				; get hi byte
		sbc	#$00				; subtract 1 if necessary
		sta	dp_mos_error_ptr+1		; and store in &FE
		lda	dp_mos_curROM			; get currently active ROM
		sta	sysvar_ROMNO_ATBREAK		; and store it in &24A
		stx	dp_mos_OSBW_X			; store stack pointer in &F0

	; TODO: OSBYTE 143
	;	ldx	#$06				; and issue ROM service call 6
	;	jsr	_OSBYTE_143			; (User BRK) to ROMs
							; at this point &FD/E point to byte after BRK
							; ROMS may use BRK for their own purposes

		ldx	sysvar_CUR_LANG			; get current language
		jsr	_LDC16				; and activate it
		pla					; get back original value of X
		tax					; 
		lda	dp_mos_INT_A			; get back original value of A
		cli					; allow interrupts
		jmp	(BBC_BRKV)			; and JUMP via BRKV (normally into current language)



_LDC16:		stx	dp_mos_curROM			; RAM copy of rom latch
		stx	.loword(sheila_ROMCTL_SWR)	; write to rom latch
		rts					; and return



		.segment "CODE"


brk_handle_nat:	
		sep	#$20
		rep	#$10
		.i16
		.a8
		xba
		pha
		xba
		pha
		phy
		phx

	; stack
	;	+8..10	BRK addr (native)
	;	+7	P
	;	+6	H
	;	+5	A
	;	+3..4	Y
	;	+1..2	X

		lda	10,S
		pha
		plb
		lda	9,S
		xba
		lda	8,S
	; BHA is now the RTI return address, get it into WINDOW

		jsl	windowPush

	; Spoof a stack ready for emu BRK handler and switch to emu mode
		
		phx
		pla
		sta	10,S
		pla
		sta	10,S
		lda	7,S
		sta	8,S


	; stack
	;	+9..10	BRK addr (emu/WINDOW)
	;	+8	P
	;	+7	P
	;	+6	H
	;	+5	A
	;	+3..4	Y
	;	+1..2	X


		plx
		ply
		pla
		xba
		pla
		xba
		plb
		pea	emu_handle_brk	
		pea	$0403

		jml	nat2emu_rti



;;		DEBUG_PRINTF "NAT BREAK A=%H%A, X=%X, Y=%Y, F=%F, "
;;		rep	#$30
;;		.a16
;;		.i16
;;		lda	2,S
;;		sec
;;		sbc	#2
;;		tax
;;		sep	#$20
;;		.a8
;;		.i16
;;		lda	4,S
;;		DEBUG_PRINTF "PC=%A%X\n"
;;		sei
;;@x:		jmp	@x
