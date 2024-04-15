
		.include "dp_bbc.inc"
		.include "vectors.inc"
		.include "sysvars.inc"
		.include "nat-layout.inc"
		.include "oslib.inc"


		.export initBuffers
		.export _OSBYTE_124
		.export _OSBYTE_125
		.export _OSBYTE_138
		.export _OSBYTE_145
		.export _OSBYTE_153


		.i16
		.a16
initBuffers:
		pea	DPBBC
		pld
		ldx	#IX_INSV
		phk
		plb
		lda	#.loword(_INSBV)
		jsl	AddToVector

		pea	DPBBC
		pld
		ldx	#IX_REMV
		phk
		plb
		lda	#.loword(_REMVB)
		jsl	AddToVector


		pea	DPBBC
		pld
		ldx	#IX_RDCHV
		phk
		plb
		lda	#.loword(_NVRDCH)
		jsl	AddToVector

		rts


; buffer tables - the buffer pointers are all calculated so that an offset
; will wrap to zero at then end of the buffer.

	.macro bufHI start, len
		.byte >(start+len-$100)
	.endmacro

	.macro bufLO start, len
		.byte <(start+len-$100)
	.endmacro

	.macro bufStartOffs start, len
		.byte <($100-<len)
	.endmacro

tblBufferHI:
	bufHI BUFFER_KEYB_START, BUFFER_KEYB_SIZE
	bufHI BUFFER_SERI_START, BUFFER_SERI_SIZE
	bufHI BUFFER_SERO_START, BUFFER_SERO_SIZE
	bufHI BUFFER_LPT_START, BUFFER_LPT_SIZE
	bufHI BUFFER_SND0_START, BUFFER_SND0_SIZE
	bufHI BUFFER_SND1_START, BUFFER_SND1_SIZE
	bufHI BUFFER_SND2_START, BUFFER_SND2_SIZE
	bufHI BUFFER_SND3_START, BUFFER_SND3_SIZE
	bufHI BUFFER_SPCH_START, BUFFER_SPCH_SIZE

tblBufferLO:
	bufLO BUFFER_KEYB_START, BUFFER_KEYB_SIZE
	bufLO BUFFER_SERI_START, BUFFER_SERI_SIZE
	bufLO BUFFER_SERO_START, BUFFER_SERO_SIZE
	bufLO BUFFER_LPT_START, BUFFER_LPT_SIZE
	bufLO BUFFER_SND0_START, BUFFER_SND0_SIZE
	bufLO BUFFER_SND1_START, BUFFER_SND1_SIZE
	bufLO BUFFER_SND2_START, BUFFER_SND2_SIZE
	bufLO BUFFER_SND3_START, BUFFER_SND3_SIZE
	bufLO BUFFER_SPCH_START, BUFFER_SPCH_SIZE

tblBufferStarts:
	bufStartOffs BUFFER_KEYB_START, BUFFER_KEYB_SIZE
	bufStartOffs BUFFER_SERI_START, BUFFER_SERI_SIZE
	bufStartOffs BUFFER_SERO_START, BUFFER_SERO_SIZE
	bufStartOffs BUFFER_LPT_START, BUFFER_LPT_SIZE
	bufStartOffs BUFFER_SND0_START, BUFFER_SND0_SIZE
	bufStartOffs BUFFER_SND1_START, BUFFER_SND1_SIZE
	bufStartOffs BUFFER_SND2_START, BUFFER_SND2_SIZE
	bufStartOffs BUFFER_SND3_START, BUFFER_SND3_SIZE
	bufStartOffs BUFFER_SPCH_START, BUFFER_SPCH_SIZE


;TODO: move this - not sure where to though

;**************************************************************************
;**************************************************************************
;**									 **
;**	 OSRDCH Default entry point					 **
;**									 **
;**	 RDCHV entry point	 read a character			 **
;**									 **
;**************************************************************************
;**************************************************************************

_NVRDCH:		sep	#$30
			.a8
			.i8
			phd
			plb
			plb

			lda	#$00				; A=0 to flag wait forever

_BDEC7:			sta	dp_mos_OS_wksp			; store entry value of A
			txa					; save X and Y
			pha					; 
			tya					; 
			pha					; 
			ldy	sysvar_EXEC_FILE		; get *EXEC file handle
			beq	_BDEE6				; if 0 (not open) then DEE6
			sec					; set carry
			ror	dp_mos_cfs_critical		; set bit 7 of CFS active flag to prevent clashes
			cop	COP_0A_OPBGT			; get a byte from the file
			php					; push processor flags to preserve carry
			lsr	dp_mos_cfs_critical		; restore &EB
			plp					; get back flags
			bcc	_BDF03				; and if carry clear, character found so exit via DF03
			lda	#$00				; else A=00 as EXEC file empty
			sta	sysvar_EXEC_FILE		; store it in exec file handle
			cop	COP_0D_OPFND			; and close file via OSFIND

_BDEE6:			bit	dp_mos_ESC_flag			; check ESCAPE flag, if bit 7 set Escape pressed
			bmi	_BDF00				; so off to DF00
			ldx	sysvar_CURINSTREAM		; else get current input buffer number
			jsr	_LE577				; get a byte from input buffer
			bcc	_BDF03				; and exit if character returned

			bit	dp_mos_OS_wksp			; (E6=0 or FF)
			bvc	_BDEE6				; if entry was OSRDCH not timed keypress, so go back and
								; do it again i.e. perform GET function
			lda	oswksp_INKEY_CTDOWN		; else check timers
			ora	oswksp_INKEY_CTDOWN+1		; 
			bne	_BDEE6				; and if not zero go round again
			bcs	_BDF05				; else exit

_BDF00:			sec					
			lda	#$1b				
_BDF03:			sta	dp_mos_OS_wksp				
_BDF05:			pla					
			tay					
			pla					
			tax					
			lda	dp_mos_OS_wksp				
			rtl			

		
;*************************************************************************
;*									 *
;*	 OSBYTE 145 Get byte from Buffer				 *
;*									 *
;*************************************************************************
;on entry X = buffer number
; ON EXIT Y is character extracted
;if buffer is empty C=1, else C=0

		.a8
		.i8
_OSBYTE_145:	clv					; clear V

_BE461:		cop	COP_08_OPCAV			; Jump via REMV
		.byte	IX_REMV
		rtl


;*************************************************************************
;*									 *
;*	 REMV buffer remove vector default entry point			 *
;*									 *
;*************************************************************************
;on entry X = buffer number
;on exit if buffer is empty C=1, Y is preserved else C=0
		.i16
		.a16

_REMVB:		php					; save flags
		; bar interrupts, set small registers and reset decimal
		sep	#$34
		rep	#$08
		.a8
		.i8
		phd
		plb
		plb

		cpx	#MOSBUF_COUNT
		bcs	plpSecSevRtl

		lda	mosbuf_buf_start,X		; get output pointer for buffer X
		cmp	mosbuf_buf_end,X		; compare to input pointer
		beq	plpSecRtl			; if equal buffer is empty so E4E0 to exit

		tay					; else Y=A
		jsr	_GET_BUFFER_ADDRESS		; and get buffer pointer into FA/B
		lda	(dp_mos_OS_wksp2),Y		; read byte from buffer
		bvs	_BE491				; if V is set (on input) exit with CARRY clear
							; Osbyte 152 has been done
		pha					; else must be osbyte 145 so save byte
		iny					; increment Y
		tya					; A=Y
		bne	_BE47E				; if end of buffer not reached <>0 E47E

		lda	f:tblBufferStarts,X		; get pointer start from offset table

_BE47E:		sta	mosbuf_buf_start,X		; set buffer output pointer
		cpx	#$02				; if buffer is input (0 or 1)
		bcc	_BE48F				; then E48F

		cmp	mosbuf_buf_end,X		; else for output buffers compare with buffer start
		bne	_BE48F				; if not the same buffer is not empty so E48F

		ldy	#EVENT_00_OUTPUT_BUF_EMPTY	; buffer is empty so Y=0
		jsr	kernelRaiseEvent		; and enter EVENT routine to signal EVENT 0 buffer
							; becoming empty

_BE48F:		pla					; get back byte from buffer
		tay					; put it in Y
_BE491:		plp					; get back flags
		clc					; clear carry to indicate success
		rtl					; and exit



		.a8
		.i8

;********* check event 2 character entering buffer ***********************

_BE4A8:		tya					; A=Y
		ldy	#EVENT_02_INPUT_BUF_ENTER	; Y=2
		jsr	kernelRaiseEvent		; check event
		tay					; Y=A

		; drop through to _OSBYTE_138

;*************************************************************************
;*									 *
;*	 OSBYTE 138 Put byte into Buffer				 *
;*									 *
;*************************************************************************
;on entry X is buffer number, Y is character to be written
_OSBYTE_138:	tya					; A=Y
		cop	COP_08_OPCAV
		.byte   IX_INSV
		rtl

		.a16
		.i16

;*************************************************************************
;*									 *
;*	 INSV insert character in buffer vector default entry point	 *
;*									 *
;*************************************************************************
;on entry X is buffer number, A is character to be written
; API CHANGE: V is set if X is out of range

;ASSUME DP = 0

_INSBV:			php					; save flags
			; bar interrupts, set small registers and reset decimal
			sep	#$34
			rep	#$08
			.a8
			.i8
			phd
			plb
			plb

			pha					; save A - character to insert
			cpx	#MOSBUF_COUNT
			bcs	plaPlpSecSevRtl
			lda	mosbuf_buf_end,X		; get buffer input pointer
			inc	A				; increment Y
			bne	@nowrap				; if Y=0 then buffer is full else E4BF
			lda	f:tblBufferStarts,X		; get default buffer start

@nowrap:		cmp	mosbuf_buf_start,X		; compare it with input pointer
			beq	@full				; if equal buffer is full so E4D4
			ldy	mosbuf_buf_end,X		; else get buffer end in Y
			sta	mosbuf_buf_end,X		; and set it from A
			jsr	_GET_BUFFER_ADDRESS		; and point &FA/B at it
			pla					; get back byte
			sta	(dp_mos_OS_wksp2),Y			; store it in buffer
			plp					; pull flags
			clc					; clear carry for success
			rtl					; and exit

@full:			pla					; get back byte
			cpx	#$02				; if we are working on input buffer
			bcs	plpSecRtl				; then E4E0

			ldy	#$01				; else Y=1
			jsr	kernelRaiseEvent		; to service input buffer full event
			pha

plaPlpSecRtl:		pla
plpSecRtl:		plp					; restore flags
			sec					; set carry
			rtl					; and exit

plaPlpSecSevRtl:	pla
plpSecSevRtl:		plp
			sep	#$41
			rtl


				; ON ENTRY X=buffer number
				; Buffer number	 Address	 Flag	 Out pointer	 In pointer
				; 0=Keyboard	 3E0-3FF	 2CF	 2D8		 2E1
				; 1=RS423 Input	 A00-AFF	 2D0	 2D9		 2E2
				; 2=RS423 output 900-9BF	 2D1	 2DA		 2E3
				; 3=printer	 880-8BF	 2D2	 2DB		 2E4
				; 4=sound0	 840-84F	 2D3	 2DC		 2E5
				; 5=sound1	 850-85F	 2D4	 2DD		 2E6
				; 6=sound2	 860-86F	 2D5	 2DE		 2E7
				; 7=sound3	 870-87F	 2D6	 2DF		 2E8
				; 8=speech	 8C0-8FF	 2D7	 2E0		 2E9

_GET_BUFFER_ADDRESS:	.a8
			.i8
			lda	f:tblBufferLO,X			; get buffer base address lo
			sta	dp_mos_OS_wksp2			; store it
			lda	f:tblBufferHI,X			; get buffer base address hi
			sta	dp_mos_OS_wksp2+1		; store it
			rts					; exit





		.a8
		.i8

;*************************************************************************
;*									 *
;*	 OSBYTE 153 Put byte in input Buffer checking for ESCAPE	 *
;*									 *
;*************************************************************************
;on entry X = buffer number (either 0 or 1)
;X=1 is RS423 input
;X=0 is Keyboard
;Y is character to be written

_OSBYTE_153:		txa					; A=buffer number
			and	sysvar_RS423_MODE		; and with RS423 mode (0 treat as keyboard
								; 1 ignore Escapes no events no soft keys)
			bne	_OSBYTE_138			; so if RS423 buffer AND RS423 in normal mode (1) E4AF

			tya					; else Y=A character to write
			eor	sysvar_KEYB_ESC_CHAR		; compare with current escape ASCII code (0=match)
			ora	sysvar_KEYB_ESC_ACTION		; or with current ESCAPE status (0=ESC, 1=ASCII)
			bne	_BE4A8				; if ASCII or no match E4A8 to enter byte in buffer
			lda	sysvar_BREAK_EFFECT		; else get ESCAPE/BREAK action byte
			ror					; Rotate to get ESCAPE bit into carry
			tya					; get character back in A
			bcs	@clcrtl				; and if escape disabled exit with carry clear
			ldy	#EVENT_06_ESCAPE		; else signal EVENT 6 Escape pressed
			jsr	kernelRaiseEvent		; 
			bcc	@clcrtl				; if event handles ESCAPE then exit with carry clear
			jsl	_OSBYTE_125			; else set ESCAPE flag
@clcrtl:		clc					; clear carry
			rtl					; and exit

;******** get a byte from keyboard buffer and interpret as necessary *****
;on entry A=cursor editing status 1=return &87-&8B,
;2= use cursor keys as soft keys 11-15
;this area not reached if cursor editing is normal

_BE515:			ror					; get bit 1 into carry
			pla					; get back A
			bcs	_BE592				; if carry is set return
								; else cursor keys are 'soft'
_BE519:			tya					; A=Y get back original key code (&80-&FF)
			pha					; PUSH A
			lsr					; get high nybble into lo
			lsr					; 
			lsr					; 
			lsr					; A=8-&F
			eor	#$04				; and invert bit 2
								; &8 becomes &C
								; &9 becomes &D
								; &A becomes &E
								; &B becomes &F
								; &C becomes &8
								; &D becomes &9
								; &E becomes &A
								; &F becomes &B

			tay					; Y=A = 8-F
			lda	sysvar_BELL_FREQ,Y		; read 026D to 0274 code interpretation status
								; 0=ignore key, 1=expand as 'soft' key
								; 2-&FF add this to base for ASCII code
								; note that provision is made for keypad operation
								; as codes &C0-&FF cannot be generated from keyboard
								; but are recognised by OS
								;
			cmp	#$01				; is it 01
			beq	_BE594				; if so expand as 'soft' key via E594
			pla					; else get back original byte
			bcc	_BE539				; if above CMP generated Carry then code 0 must have
								; been returned so E539 to ignore
			and	#$0f				; else add ASCII to BASE key number so clear hi nybble
			clc					; clear carry
			adc	sysvar_BELL_FREQ,Y		; add ASCII base
			clc					; clear carry
			rts					; and exit
								;
;*********** ERROR MADE IN USING EDIT FACILITY ***************************

_BE534:			lda	#7				; produce bell
			cop	COP_00_OPWRC
			pla					; get back A, buffer number
			tax					; X=buffer number

;********get byte from buffer ********************************************

_BE539:			jsl	_OSBYTE_145			; get byte from buffer X
			bcs	_BE593				; if buffer empty E593 to exit
			pha					; else Push byte
; TODO: serial
;;			cpx	#$01				; and if RS423 input buffer is not the one
;;			bne	_BE549				; then E549
;;
;;			jsr	_LE173				; else oswrch DB:RS432 ECHO?
;;			ldx	#$01				; X=1 (RS423 input buffer)
;;			sec					; set carry

_BE549:			pla					; get back original byte
			bcc	_BE551				; if carry clear (I.E not RS423 input) E551
			ldy	sysvar_RS423_MODE			; else Y=RS423 mode (0 treat as keyboard )
			bne	_BE592				; if not 0 ignore escapes etc. goto E592

_BE551:			tay					; Y=A
			bpl	_BE592				; if code is less that &80 its simple so E592
			and	#$0f				; else clear high nybble
			cmp	#$0b				; if less than 11 then treat as special code
			bcc	_BE519				; or function key and goto E519
			adc	#$7b				; else add &7C (&7B +C) to convert codes B-F to 7-B
			pha					; Push A
			lda	sysvar_KEY_CURSORSTAT		; get cursor editing status
			bne	_BE515				; if not 0 (normal) E515
			lda	sysvar_OUTSTREAM_DEST		; else get character destination status

;Bit 0 enables	RS423 driver
;BIT 1 disables VDU driver
;Bit 2 disables printer driver
;BIT 3 enables	printer independent of CTRL B or CTRL C
;Bit 4 disables spooled output
;BIT 5 not used
;Bit 6 disables printer driver unless VDU 1 precedes character
;BIT 7 not used

			ror					; get bit 1 into carry
			ror					; 
			pla					; 
			bcs	_BE539				; if carry is set E539 screen disabled
			cmp	#$87				; else is it COPY key
			beq	_BE5A6				; if so E5A6

			tay					; else Y=A
			txa					; A=X
			pha					; Push X
			tya					; get back Y
; TODO: cursor editing - make into a VDU call?
;;;			jsr	_LD8CE				; execute edit action

			pla					; restore X
			tax					; 
;TODO: check with keyboard input stuff
_LE577:			bit	sysvar_ECO_OSRDCH_INTERCEPT	; check econet RDCH flag
			bpl	_BE581				; if not set goto E581
			lda	#$06				; else Econet function 6
_NETV:			cop	COP_08_OPCAV			; to the Econet vector
			.byte	IX_NETV
			rts

;********* get byte from key string **************************************
;on entry 0268 contains key length
;and 02C9 key string pointer to next byte

_BE581:			lda	sysvar_KEYB_SOFTKEY_LENGTH	; get length of keystring
			beq	_BE539				; if 0 E539 get a character from the buffer
			ldy	mosvar_SOFTKEY_PTR		; get soft key expansion pointer
			lda	SOFTKEYS+1,Y			; get character from string
			inc	mosvar_SOFTKEY_PTR		; increment pointer
			dec	sysvar_KEYB_SOFTKEY_LENGTH	; decrement length

;************** exit with carry clear ************************************

_BE592:			clc					; 
_BE593:			rts					; exit

;*** expand soft key strings *********************************************
; Y=pointer to sring number

_BE594:			pla					; restore original code
			and	#$0f				; blank hi nybble to get key string number
			tay					; Y=A
;TODO: SOFTKEYS
;;			jsr	_LE3A8				; get string length in A
			sta	sysvar_KEYB_SOFTKEY_LENGTH			; and store it
			lda	SOFTKEYS,Y			; get start point
			sta	mosvar_SOFTKEY_PTR		; and store it
			bne	_LE577				; if not 0 then get byte via E577 and exit

;*********** deal with COPY key ******************************************

_BE5A6:			txa					; A=X
			pha					; Push A

;TODO: cursor editing - call OSBYTE 135
;;			jsr	_LD905				; read a character from the screen
			tay					; Y=A
			beq	_BE534				; if not valid A=0 so BEEP
			pla					; else restore X
			tax					; 
			tya					; and Y
			clc					; clear carry
			rts					; and exit


;*************************************************************************
;*									 *
;*	 OSBYTE	 124  Clear ESCAPE condition				 *
;*									 *
;*************************************************************************

_OSBYTE_124:		clc					; clear carry


;*************************************************************************
;*									 *
;*	 OSBYTE	 125  Set ESCAPE flag					 *
;*									 *
;*************************************************************************

_OSBYTE_125:		ror	dp_mos_ESC_flag			; clear	 bit 7 of ESCAPE flag
; TODO: TUBE
;;			bit	sysvar_TUBE_PRESENT			; read bit 7 of Tube flag
;;			bmi	_BE67C				; if set TUBE exists so E67C
			rtl					; else RETURN
								;
;;_BE67C:			jmp	TUBE_ENTRY_1			; Jump to Tube entry point

