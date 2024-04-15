
		.include "dp_bbc.inc"
		.include "debug.inc"
		.include "vectors.inc"
		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "sysvars.inc"
		.include "vduvars.inc"

		.export doOSBYTE
		.export doOSWORD


;	********************************************************************************
;	* Main OSBYTE and OSWORD dispatchers are executed in native mode               *
;	********************************************************************************



doOSBYTE:	DEBUG_PRINTF "OSBYTE #%A, X=%X, Y=%Y\n"

		sep	#$30	
		.a8
		.i8
		pha					; save A
		php					; save Processor flags
		sei					; disable interrupts
		sta	dp_mos_OSBW_A			; store A,X,Y in zero page
		stx	dp_mos_OSBW_X			; 
		sty	dp_mos_OSBW_Y			; 
		ldx	#$07				; X=7 to signal osbyte is being attempted
		cmp	#$75				; if A=0-116
		bcc	_BE7C2				; then E7C2
		cmp	#$a1				; if A<161
		bcc	_BE78E				; then E78E
		cmp	#$a6				; if A=161-165
		bcc	_BE7C8				; then EC78
		clc					; clear carry

_BE78A:		lda	#$a1				; A=&A1
		adc	#$00				; increment to &A2 if entered via OSWORD

;********* process osbyte calls 117 - 160 *****************************

_BE78E:		sec					; set carry
		sbc	#$5f				; convert to &16 to &41 (22-65)

_BE791:		asl					; double it (44-130)
		sec					; set carry

_BE793:		sty	dp_mos_OSBW_Y			; store Y
		tay					; Y=A
		bit	sysvar_ECO_OSBW_INTERCEPT		; read econet intercept flag
		bpl	_BE7A2				; if no econet intercept required E7A2

		txa					; else A=X
		clv					; V=0
		php					; preserve Cy (OSBYTE/OSWORD)
		cop	COP_08_OPCAV			; to JMP via ECONET vector
		.byte   IX_NETV
		plp
		bvs	_LE7BC				; if return with V set E7BC

_BE7A2:		phk
		plb

		lda	_OSBYTE_TABLE + 1,Y		; get address from table
		sta	dp_mos_OS_wksp2+1			; store it as hi byte
		lda	_OSBYTE_TABLE,Y			; repeat for lo byte
		sta	dp_mos_OS_wksp2			; 
		
		pea	0				; always enter handler with B=0, DP=0, .a8, .i8
		plb
		plb

		lda	dp_mos_OSBW_A			; restore A
		ldy	dp_mos_OSBW_Y			; Y
		bcs	_BE7B6				; if carry is set E7B6

		; get OSWORD byte pointed to by XY
		lda	(dp_mos_OSBW_X)			; get value from address pointed to by &F0/1 (Y,X)

_BE7B6:		sec					; set carry
		ldx	dp_mos_OSBW_X			; restore X
		phk					; !!!!!! LONG CALL API CHANGE !!!!!
		jsr	_LF058				; call &FA/B
		bvs	_BE7D6				; check for V set (not implemented)

_LE7BC:		ror					; C=bit 0
		plp					; get back flags
		rol					; bit 0=Carry
		pla					; get back A
		clv					; clear V
		rtl					; and exit

;*************** Process OSBYTE CALLS BELOW &75 **************************

_BE7C2:		ldy	#$00				; Y=0
		cmp	#$16				; if A<&16
		bcc	_BE791				; goto E791

_BE7C8:		php					; push flags
		php					; push flags

_BE7CA:		pla					; pull flags
		pla					; pull flags

		jsr	_OSBYTE_143			; offer paged ROMS service 7/8 unrecognised osbyte/word

		bne	_BE7D6				; if roms don't recognise it then E7D6
		ldx	dp_mos_OSBW_X			; else restore X
		jmp	_LE7BC				; and exit

_BE7D6:		plp					; else pull flags (settings C)
		pla					; and A
		sep	#$40				; set V
		rtl					; and return

_LF058:		jmp	(dp_mos_OS_wksp2)			; 


;**************************************************************************
;**************************************************************************
;**									 **
;**	 OSWORD	 DEFAULT ENTRY POINT					 **
;**									 **
;**	 pointed to by default WORDV					 **
;**									 **
;**************************************************************************
;**************************************************************************

doOSWORD:	DEBUG_PRINTF "OSWORD #%A, X=%X, Y=%Y\n"	
		sep	#$30	
		.a8
		.i8
		pha					; save A
		php					; save Processor flags
		sei					; disable interrupts
		sta	dp_mos_OSBW_A			; store A,X,Y
		stx	dp_mos_OSBW_X			; 
		sty	dp_mos_OSBW_Y			; 
		ldx	#$08				; X=8 - signal OSWORD
		cmp	#$e0				; if A=>224
		bcs	_BE78A				; then E78A with carry set

		cmp	#$0e				; else if A=>14
		bcs	_BE7C8				; else E7C8 with carry set pass to ROMS & exit

		adc	#$44				; add to form pointer to table
		asl					; double it
		bra	_BE793				; goto E793 ALWAYS!! (carry clear E7F8)
							; this reads bytes from table and enters routine


;TODO: consider making these far vectors in RAM somewhere to allow modules to implement?
_OSBYTE_TABLE:	.addr	_OSBYTE_0			; OSBYTE   0  (&E821)
		.addr	_OSBYTE_1_6			; OSBYTE   1  (&E988)
		.addr	_OSBYTE_2			; OSBYTE   2  (&E6D3)
		.addr	_OSBYTE_3_4			; OSBYTE   3  (&E997)
		.addr	_OSBYTE_3_4			; OSBYTE   4  (&E997)
		.addr	_OSBYTE_5			; OSBYTE   5  (&E976)
		.addr	_OSBYTE_1_6			; OSBYTE   6  (&E988)
		.addr	_OSBYTE_7			; OSBYTE   7  (&E68B)
		.addr	_OSBYTE_8			; OSBYTE   8  (&E689)
		.addr	_OSBYTE_9			; OSBYTE   9  (&E6B0)
		.addr	_OSBYTE_10			; OSBYTE  10  (&E6B2)
		.addr	_OSBYTE_11			; OSBYTE  11  (&E995)
		.addr	_OSBYTE_12			; OSBYTE  12  (&E98C)
		.addr	_OSBYTE_13			; OSBYTE  13  (&E6F9)
		.addr	_OSBYTE_14			; OSBYTE  14  (&E6FA)
		.addr	_OSBYTE_15			; OSBYTE  15  (&F0A8)
		.addr	_OSBYTE_16			; OSBYTE  16  (&E706)
		.addr	_OSBYTE_17			; OSBYTE  17  (&DE8C)
		.addr	_OSBYTE_18			; OSBYTE  18  (&E9C8)
		.addr	_OSBYTE_19			; OSBYTE  19  (&E9B6)
		.addr	_OSBYTE_20			; OSBYTE  20  (&CD07)
		.addr	_OSBYTE_21			; OSBYTE  21  (&F0B4)
		.addr	_OSBYTE_117			; OSBYTE 117  (&E86C)
		.addr	_OSBYTE_118			; OSBYTE 118  (&E9D9)
		.addr	_OSBYTE_119			; OSBYTE 119  (&E275)
		.addr	_OSBYTE_120			; OSBYTE 120  (&F045)
		.addr	_OSBYTE_121			; OSBYTE 121  (&F0CF)
		.addr	_OSBYTE_122			; OSBYTE 122  (&F0CD)
		.addr	_OSBYTE_123			; OSBYTE 123  (&E197)
		.addr	_OSBYTE_124			; OSBYTE 124  (&E673)
		.addr	_OSBYTE_125			; OSBYTE 125  (&E674)
		.addr	_OSBYTE_126			; OSBYTE 126  (&E65C)
		.addr	_OSBYTE_127			; OSBYTE 127  (&E035)
		.addr	_OSBYTE_128			; OSBYTE 128  (&E74F)
		.addr	_OSBYTE_129			; OSBYTE 129  (&E713)
		.addr	_OSBYTE_130			; OSBYTE 130  (&E729)
		.addr	_OSBYTE_131			; OSBYTE 131  (&F085)
		.addr	_OSBYTE_132			; OSBYTE 132  (&D923)
		.addr	_OSBYTE_133			; OSBYTE 133  (&D926)
		.addr	_OSBYTE_134			; OSBYTE 134  (&D647)
		.addr	_OSBYTE_135			; OSBYTE 135  (&D7C2)
		.addr	_OSBYTE_136			; OSBYTE 136  (&E657)
		.addr	_OSBYTE_137			; OSBYTE 137  (&E67F)
		.addr	_OSBYTE_138			; OSBYTE 138  (&E4AF)
		.addr	_OSBYTE_139			; OSBYTE 139  (&E034)
		.addr	_OSBYTE_140_141			; OSBYTE 140  (&F135)
		.addr	_OSBYTE_140_141			; OSBYTE 141  (&F135)
		.addr	_OSBYTE_142			; OSBYTE 142  (&DBE7)
		.addr	_OSBYTE_143			; OSBYTE 143  (&F168)
		.addr	_OSBYTE_144			; OSBYTE 144  (&EAE3)
		.addr	_OSBYTE_145			; OSBYTE 145  (&E460)
		.addr	_OSBYTE_146			; OSBYTE 146  (&FFAA)
		.addr	_OSBYTE_147			; OSBYTE 147  (&EAF4)
		.addr	_OSBYTE_148			; OSBYTE 148  (&FFAE)
		.addr	_OSBYTE_149			; OSBYTE 149  (&EAF9)
		.addr	_OSBYTE_150			; OSBYTE 150  (&FFB2)
		.addr	_OSBYTE_151			; OSBYTE 151  (&EAFE)
		.addr	_OSBYTE_152			; OSBYTE 152  (&E45B)
		.addr	_OSBYTE_153			; OSBYTE 153  (&E4F3)
		.addr	_OSBYTE_154			; OSBYTE 154  (&E9FF)
		.addr	_OSBYTE_155			; OSBYTE 155  (&EA10)
		.addr	_OSBYTE_156			; OSBYTE 156  (&E17C)
		.addr	_OSBYTE_157			; OSBYTE 157  (&FFA7)
		.addr	_OSBYTE_158			; OSBYTE 158  (&EE6D)
		.addr	_OSBYTE_159			; OSBYTE 159  (&EE7F)
		.addr	_OSBYTE_160			; OSBYTE 160  (&E9C0)
		.addr	_OSBYTE_166_255			; OSBYTE 166+
		.addr	_OSCLI_USERV			; OSWORD &E0+


;*************************************************************************
;*			                                              *
;*	  OSWORD LOOK UP TABLE                                          *
;*			                                              *
;*************************************************************************

		.addr	_OSWORD_0			; OSWORD   0  (&E902)
		.addr	_OSWORD_1			; OSWORD   1  (&E8D5)
		.addr	_OSWORD_2			; OSWORD   2  (&E8E8)
		.addr	_OSWORD_3			; OSWORD   3  (&E8D1)
		.addr	_OSWORD_4			; OSWORD   4  (&E8E4)
		.addr	_OSWORD_5			; OSWORD   5  (&E803)
		.addr	_OSWORD_6			; OSWORD   6  (&E80B)
		.addr	_OSWORD_7			; OSWORD   7  (&E82D)
		.addr	_OSWORD_8			; OSWORD   8  (&E8AE)
		.addr	_OSWORD_9			; OSWORD   9  (&C735)
		.addr	_OSWORD_10			; OSWORD  10  (&CBF3)
		.addr	_OSWORD_11			; OSWORD  11  (&C748)
		.addr	_OSWORD_12			; OSWORD  12  (&C8E0)
		.addr	_OSWORD_13			; OSWORD  13  (&D5CE)


_OSWORD_1:
_OSWORD_2:
_OSWORD_3:
_OSWORD_4:
_OSWORD_5:
_OSWORD_6:
_OSWORD_7:
_OSWORD_8:
_OSBYTE_0:
_OSBYTE_1_6:
_OSBYTE_2:
_OSBYTE_3_4:
_OSBYTE_5:
_OSBYTE_7:
_OSBYTE_8:
_OSBYTE_9:
_OSBYTE_10:
_OSBYTE_11:
_OSBYTE_12:
_OSBYTE_13:
_OSBYTE_14:
_OSBYTE_15:
_OSBYTE_16:
_OSBYTE_17:
_OSBYTE_18:
_OSBYTE_19:
_OSBYTE_21:
_OSBYTE_117:
_OSBYTE_118:
_OSBYTE_119:
_OSBYTE_120:
_OSBYTE_121:
_OSBYTE_122:
_OSBYTE_123:
_OSBYTE_126:
_OSBYTE_127:
_OSBYTE_128:
_OSBYTE_129:
_OSBYTE_130:
_OSBYTE_136:
_OSBYTE_137:
_OSBYTE_139:
_OSBYTE_140_141:
_OSBYTE_142:
_OSBYTE_143:
_OSBYTE_144:
_OSBYTE_146:
_OSBYTE_147:
_OSBYTE_148:
_OSBYTE_149:
_OSBYTE_150:
_OSBYTE_151:
_OSBYTE_152:
_OSBYTE_156:
_OSBYTE_157:
_OSBYTE_158:
_OSBYTE_159:
_OSBYTE_160:
_OSBYTE_166_255:
_OSCLI_USERV:
		; not implemented!
		sep	#$40
		rtl







;*************************************************************************
;*									 *
;*	 OSWORD	 00   ENTRY POINT					 *
;*									 *
;*	 read line from current input to memory				 *
;*									 *
;*************************************************************************
;F0/1 points to parameter block
;	+0/1 Buffer address for input
;	+2   Maximum line length
;	+3   minimum acceptable ASCII value
;	+4   maximum acceptable ASCII value

_OSWORD_0:		ldy	#$04				; Y=4

_BE904:			lda	(dp_mos_OSBW_X),Y		; transfer bytes 4,3,2 to 2B3-2B5
			sta	oswksp_OSWORD0_LINE_LEN-2,Y	; 
			dey					; decrement Y
			cpy	#$02				; until Y=1
			bcs	_BE904				; 

			lda	(dp_mos_OSBW_X),Y		; get address of input buffer
			sta	dp_mos_input_buf+1		; store it in &E9 as temporary buffer
			dey					; decrement Y
			sty	sysvar_SCREENLINES_SINCE_PAGE	; Y=0 store in print line counter for paged mode
			lda	(dp_mos_OSBW_X),Y		; get lo byte of address
			sta	dp_mos_input_buf		; and store in &E8
			cli					; allow interrupts
			bcc	_BE924				; Jump to E924

_BE91D:			lda	#$07				; A=7
_BE91F:			dey					; decrement Y
_BE920:			iny					; increment Y
_BE921:			cop	COP_00_OPWRC			; and call OSWRCH

_BE924:			cop	COP_04_OPRDC			; else read character  from input stream
		DEBUG_PRINTF "OSW0 RDCH A=%A F=%F\n"
			bcs	_BE972				; if carry set then illegal character or other error
								; exit via E972
			tax					; X=A
			lda	sysvar_OUTSTREAM_DEST		; A=&27C get character destination status
			ror					; put VDU driver bit in carry
			ror					; if this is 1 VDU driver is disabled
			txa					; X=A
			bcs	_BE937				; if Carry set E937
			ldx	sysvar_VDU_Q_LEN		; get number of items in VDU queque
			bne	_BE921				; if not 0 output character and loop round again

_BE937:			cmp	#$7f				; if character is not delete
			bne	_BE942				; goto E942
			cpy	#$00				; else is Y=0
			beq	_BE924				; and goto E924
			dey					; decrement Y
			bcs	_BE921				; and if carry set E921 to output it
_BE942:			cmp	#$15				; is it delete line &21
			bne	_BE953				; if not E953
			tya					; else Y=A, if its 0 we are still reading first
								; character
			beq	_BE924				; so E924
			lda	#$7f				; else output DELETES

_BE94B:			cop	COP_00_OPWRC			; until Y=0
			dey					; 
			bne	_BE94B				; 

			beq	_BE924				; then read character again

_BE953:			sta	(dp_mos_input_buf),Y		; store character in designated buffer
			cmp	#$0d				; is it CR?
			beq	_BE96C				; if so E96C
			cpy	oswksp_OSWORD0_LINE_LEN		; else check the line length
			bcs	_BE91D				; if = or greater loop to ring bell
			cmp	oswksp_OSWORD0_MIN_CH		; check minimum character
			bcc	_BE91F				; if less than minimum backspace
			cmp	oswksp_OSWORD0_MAX_CH		; check maximum character
			beq	_BE920				; if equal E920
			bcc	_BE920				; or less E920
			bcs	_BE91F				; then JUMP E91F

_BE96C:			cop	COP_03_OPNLI			; output CR/LF
			cop	COP_08_OPCAV			; call Econet vector
			.byte   IX_NETV

_BE972:			lda	dp_mos_ESC_flag			; A=ESCAPE FLAG
			rol					; put bit 7 into carry
			rtl					; and exit routine


;*************************************************************************
;*									 *
;*	 OSBYTE 131  READ OSHWM	 (PAGE in BASIC)			 *
;*									 *
;*************************************************************************

			.a8
			.i8
_OSBYTE_131:		ldy	sysvar_CUR_OSHWM			; read current OSHWM
			ldx	#$00				; 
			rtl					; 
