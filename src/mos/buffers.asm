
		.include "dp_bbc.inc"
		.include "vectors.inc"
		.include "sysvars.inc"
		.include "nat-layout.inc"


		.export initBuffers

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

		.a16
		.i16

;*************************************************************************
;*									 *
;*	 INSV insert character in buffer vector default entry point	 *
;*									 *
;*************************************************************************
;on entry X is buffer number, A is character to be written
; API CHANGE: V is set if X is out of range

;ASSUME bank = 0, DP = 0

_INSBV:			php					; save flags
			; bar interrupts, set small registers and reset decimal
			sep	#$34
			rep	#$08
			.a8
			.i8
			pha					; save A - character to insert
			cpx	#MOSBUF_COUNT
			bcs	@retSecSev
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
			rts					; and exit

@full:			pla					; get back byte
			cpx	#$02				; if we are working on input buffer
			bcs	@retsec				; then E4E0

			ldy	#$01				; else Y=1
			jsr	kernelRaiseEvent		; to service input buffer full event

@retsec:		pla
			plp					; restore flags
			sec					; set carry
			rts					; and exit

@retSecSev:		pla
			plp
			sep	#$41
			rts


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
			lda	tblBufferLO,X			; get buffer base address lo
			sta	dp_mos_OS_wksp2			; store it
			lda	tblBufferHI,X			; get buffer base address hi
			sta	dp_mos_OS_wksp2+1		; store it
			rts					; exit
