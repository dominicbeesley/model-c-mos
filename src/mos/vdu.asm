
		.include "dp_bbc.inc"
		.include "sysvars.inc"
		.include "vduvars.inc"
		.include "hardware.inc"
		.include "vectors.inc"
		.include "oslib.inc"
		.include "debug.inc"


		.export VDU_INIT
		.export _NVWRCH
		.export vduSetULACTL

		.export _OSBYTE_20
		.export _OSBYTE_132
		.export _OSBYTE_133
		.export _OSBYTE_134
		.export _OSBYTE_135
		.export _OSBYTE_154
		.export _OSBYTE_155

		.export _OSWORD_9
		.export _OSWORD_10
		.export _OSWORD_11
		.export _OSWORD_12
		.export _OSWORD_13



; This taken from https://github.com/raybellis/mos120/blob/master/mos120.s
; and hacked for native mode

;THIS CODE ASSUMES IT IS RUNNING IN BANK FF/Same bank as Screen


			.byte	$08,$0d,$0d			; Termination byte in next table


;****** 16 COLOUR MODE BYTE MASK LOOK UP TABLE******

_COL16_MASK_TAB:	.byte	$00				; 00000000
			.byte	$11				; 00010001
			.byte	$22				; 00100010
			.byte	$33				; 00110011
			.byte	$44				; 01000100
			.byte	$55				; 01010101
			.byte	$66				; 01100110
			.byte	$77				; 01110111
			.byte	$88				; 10001000
			.byte	$99				; 10011001
			.byte	$aa				; 10101010
			.byte	$bb				; 10111011
			.byte	$cc				; 11001100
			.byte	$dd				; 11011101
			.byte	$ee				; 11101110
			.byte	$ff				; 11111111


;****** 4 COLOUR MODE BYTE MASK LOOK UP TABLE******

_COL4_MASK_TAB:		.byte	$00				; 00000000
			.byte	$55				; 01010101
			.byte	$aa				; 10101010
			.byte	$ff				; 11111111


;****** VDU ENTRY POINT LO	 LOOK UP TABLE******

.macro vdu_tbl		addr, count
			.word	.loword(addr)
			.byte    <(256 - count)
.endmacro

_VDU_TABLE:		vdu_tbl	_VDU_0, 0			; VDU  0   - &C511, no parameters
			vdu_tbl	_VDU_1, 1			; VDU  1   - &C53B, 1 parameter
			vdu_tbl	_VDU_2, 0			; VDU  2   - &C596, no parameters
			vdu_tbl	_VDU_3, 0			; VDU  3   - &C5A1, no parameters
			vdu_tbl	_VDU_4, 0			; VDU  4   - &C5AD, no parameters
			vdu_tbl	_VDU_5, 0			; VDU  5   - &C5B9, no parameters
			vdu_tbl	_VDU_6, 0			; VDU  6   - &C511, no parameters
			vdu_tbl	_VDU_7, 0			; VDU  7   - &E86F, no parameters
			vdu_tbl	_VDU_8, 0			; VDU  8   - &C5C5, no parameters
			vdu_tbl	_VDU_9, 0			; VDU  9   - &C664, no parameters
			vdu_tbl	_VDU_10, 0			; VDU 10  - &C6F0, no parameters
			vdu_tbl	_VDU_11, 0			; VDU 11  - &C65B, no parameters
			vdu_tbl	_VDU_12, 0			; VDU 12  - &C759, no parameters
			vdu_tbl	_VDU_13, 0			; VDU 13  - &C7AF, no parameters
			vdu_tbl	_VDU_14, 0			; VDU 14  - &C58D, no parameters
			vdu_tbl	_VDU_15, 0			; VDU 15  - &C5A6, no parameters
			vdu_tbl	_VDU_16, 0			; VDU 16  - &C7C0, no parameters
			vdu_tbl	_VDU_17, 1			; VDU 17  - &C7F9, 1 parameter
			vdu_tbl	_VDU_18, 2			; VDU 18  - &C7FD, 2 parameters
			vdu_tbl	_VDU_19, 5			; VDU 19  - &C892, 5 parameters
			vdu_tbl	_VDU_20, 0			; VDU 20  - &C839, no parameters
			vdu_tbl	_VDU_21, 0			; VDU 21  - &C59B, no parameters
			vdu_tbl	_VDU_22, 1			; VDU 22  - &C8EB, 1 parameter
			vdu_tbl	_VDU_23, 9			; VDU 23  - &C8F1, 9 parameters
			vdu_tbl	_VDU_24, 8			; VDU 24  - &CA39, 8 parameters
			vdu_tbl	_VDU_25, 5			; VDU 25  - &C9AC, 5 parameters
			vdu_tbl	_VDU_26, 0			; VDU 26  - &C9BD, no parameters
			vdu_tbl	_VDU_27, 0			; VDU 27  - &C511, no parameters
			vdu_tbl	_VDU_28, 4			; VDU 28  - &C6FA, 4 parameters
			vdu_tbl	_VDU_29, 4			; VDU 29  - &CAA2, 4 parameters
			vdu_tbl	_VDU_30, 0			; VDU 30  - &C779, no parameters
			vdu_tbl	_VDU_31, 2			; VDU 31  - &C787, 2 parameters
			vdu_tbl	_VDU_127, 0			; VDU 127 - &CAAC, no parameters


;****** 640 MULTIPLICATION TABLE  40COL, 80COL MODES  HIBYTE, LOBYTE ******

_MUL640_TABLE:		.dbyt	640 *  0
			.dbyt	640 *  1
			.dbyt	640 *  2
			.dbyt	640 *  3
			.dbyt	640 *  4
			.dbyt	640 *  5
			.dbyt	640 *  6
			.dbyt	640 *  7
			.dbyt	640 *  8
			.dbyt	640 *  9
			.dbyt	640 * 10
			.dbyt	640 * 11
			.dbyt	640 * 12
			.dbyt	640 * 13
			.dbyt	640 * 14
			.dbyt	640 * 15
			.dbyt	640 * 16
			.dbyt	640 * 17
			.dbyt	640 * 18
			.dbyt	640 * 19
			.dbyt	640 * 20
			.dbyt	640 * 21
			.dbyt	640 * 22
			.dbyt	640 * 23
			.dbyt	640 * 24
			.dbyt	640 * 25
			.dbyt	640 * 26
			.dbyt	640 * 27
			.dbyt	640 * 28
			.dbyt	640 * 29
			.dbyt	640 * 30
			.dbyt	640 * 31

;****** *40 MULTIPLICATION TABLE  TELETEXT  MODE   HIBYTE, LOBYTE  ******

_MUL40_TABLE:		.dbyt	40 *  0
			.dbyt	40 *  1
			.dbyt	40 *  2
			.dbyt	40 *  3
			.dbyt	40 *  4
			.dbyt	40 *  5
			.dbyt	40 *  6
			.dbyt	40 *  7
			.dbyt	40 *  8
			.dbyt	40 *  9
			.dbyt	40 * 10
			.dbyt	40 * 11
			.dbyt	40 * 12
			.dbyt	40 * 13
			.dbyt	40 * 14
			.dbyt	40 * 15
			.dbyt	40 * 16
			.dbyt	40 * 17
			.dbyt	40 * 18
			.dbyt	40 * 19
			.dbyt	40 * 20
			.dbyt	40 * 21
			.dbyt	40 * 22
			.dbyt	40 * 23
			.dbyt	40 * 24


;****** TEXT WINDOW -BOTTOM ROW LOOK UP TABLE ******

_TEXT_ROW_TABLE:	.byte	$1f				; MODE 0 - 32 ROWS
			.byte	$1f				; MODE 1 - 32 ROWS
			.byte	$1f				; MODE 2 - 32 ROWS
			.byte	$18				; MODE 3 - 25 ROWS
			.byte	$1f				; MODE 4 - 32 ROWS
			.byte	$1f				; MODE 5 - 32 ROWS
			.byte	$18				; MODE 6 - 25 ROWS
			.byte	$18				; MODE 7 - 25 ROWS


;****** TEXT WINDOW -RIGHT HAND COLUMN LOOK UP TABLE ******

_TEXT_COL_TABLE:	.byte	$4f				; MODE 0 - 80 COLUMNS
			.byte	$27				; MODE 1 - 40 COLUMNS
			.byte	$13				; MODE 2 - 20 COLUMNS
			.byte	$4f				; MODE 3 - 80 COLUMNS
			.byte	$27				; MODE 4 - 40 COLUMNS
			.byte	$13				; MODE 5 - 20 COLUMNS
			.byte	$27				; MODE 6 - 40 COLUMNS
			.byte	$27				; MODE 7 - 40 COLUMNS


;*************************************************************************
;*									 *
;*	 SEVERAL OF THE FOLLOWING TABLES OVERLAP EACH OTHER		 *
;*	 SOME ARE DUAL PURPOSE						 *
;*									 *
;*************************************************************************

;************** VIDEO ULA CONTROL REGISTER SETTINGS ***********************

_ULA_SETTINGS:		.byte	$9c				; 10011100
			.byte	$d8				; 11011000
			.byte	$f4				; 11110100
			.byte	$9c				; 10011100
			.byte	$88				; 10001000
			.byte	$c4				; 11000100
			.byte	$88				; 10001000
			.byte	$4b				; 01001011


;******** NUMBER OF BYTES PER CHARACTER FOR EACH DISPLAY MODE ************

_TXT_BPC_TABLE:		.byte	$08				; 00001000
			.byte	$10				; 00010000
			.byte	$20				; 00100000
			.byte	$08				; 00001000
			.byte	$08				; 00001000
			.byte	$10				; 00010000
			.byte	$08				; 00001000
_TAB_VDU_MASK_R:	.byte	$01				; 00000001
	; _TAB_VDU_MASK_R is used to make a right most pixel mask by taking the
	; number of pixels per byte-1 (7,3,1)*2 as an index ($01,$11,$55)

;******************* MASK TABLE FOR  2 COLOUR MODES **********************

_COL2_MASK_TAB:		.byte	$aa				; 10101010
			.byte	$55				; 01010101


;****************** MASK TABLE FOR  4 COLOUR MODES ***********************

			.byte	$88				; 10001000
			.byte	$44				; 01000100
			.byte	$22				; 00100010
			.byte	$11				; 00010001


;********** MASK TABLE FOR  4 COLOUR MODES FONT FLAG MASK TABLE **********

_LC40D:			.byte	$80				; 10000000
			.byte	$40				; 01000000
			.byte	$20				; 00100000
			.byte	$10				; 00010000
			.byte	$08				; 00001000
			.byte	$04				; 00000100
			.byte	$02				; 00000010  -  NEXT BYTE IN FOLLOWING TABLE


;********* NUMBER OF TEXT COLOURS -1 FOR EACH MODE ************************

_TBL_MODE_COLOURS:	.byte	$01				; MODE 0 - 2 COLOURS
			.byte	$03				; MODE 1 - 4 COLOURS
			.byte	$0f				; MODE 2 - 16 COLOURS
			.byte	$01				; MODE 3 - 2 COLOURS
			.byte	$01				; MODE 4 - 2 COLOURS
			.byte	$03				; MODE 5 - 4 COLOURS
			.byte	$01				; MODE 6 - 2 COLOURS
_LC41B:			.byte	$00				; MODE 7 - 1 'COLOUR'


;************** GCOL PLOT OPTIONS PROCESSING LOOK UP TABLE ***************

_LC41C:			.byte	$ff				; 11111111
_LC41D:			.byte	$00				; 00000000
			.byte	$00				; 00000000
			.byte	$ff				; 11111111
_LC420:			.byte	$ff				; 11111111
			.byte	$ff				; 11111111
			.byte	$ff				; 11111111
_LC423:			.byte	$00				; 00000000


;********** 2 COLOUR MODES PARAMETER LOOK UP TABLE WITHIN TABLE **********

			.byte	$00				; 00000000
			.byte	$ff				; 11111111


;*************** 4 COLOUR MODES PARAMETER LOOK UP TABLE ******************

			.byte	$00				; 00000000
			.byte	$0f				; 00001111
			.byte	$f0				; 11110000
			.byte	$ff				; 11111111


;***************16 COLOUR MODES PARAMETER LOOK UP TABLE ******************

			.byte	$00				; 00000000
			.byte	$03				; 00000011
			.byte	$0c				; 00001100
			.byte	$0f				; 00001111
			.byte	$30				; 00110000
			.byte	$33				; 00110011
			.byte	$3c				; 00111100
			.byte	$3f				; 00111111
			.byte	$c0				; 11000000
			.byte	$c3				; 11000011
			.byte	$cc				; 11001100
			.byte	$cf				; 11001111
			.byte	$f0				; 11110000
			.byte	$f3				; 11110011
			.byte	$fc				; 11111100
			.byte	$ff				; 11111111


;********** DISPLAY MODE PIXELS/BYTE-1 TABLE *********************

_TBL_VDU_PIXPB:		.byte	$07				; MODE 0 - 8 PIXELS/BYTE
			.byte	$03				; MODE 1 - 4 PIXELS/BYTE
			.byte	$01				; MODE 2 - 2 PIXELS/BYTE
_LC43D:			.byte	$00				; MODE 3 - 1 PIXEL/BYTE (NON-GRAPHICS)
			.byte	$07				; MODE 4 - 8 PIXELS/BYTE
			.byte	$03				; MODE 5 - 4 PIXELS/BYTE

;********* SCREEN DISPLAY MEMORY TYPE TABLE OVERLAPS ************

; _TAB_MAP_TYPE - indexed by mode, type of mode (0=20K, 1=16K, 2=10k, 3=8K, 4=1K)
_TAB_MAP_TYPE:		.byte	$00				; MODE 6 - 1 PIXEL/BYTE	 //  MODE 0 - TYPE 0

;***** SOUND PITCH OFFSET BY CHANNEL TABLE WITHIN TABLE **********

			.byte	$00				; MODE 7 - 1 PIXEL/BYTE	 //  MODE 1 - TYPE 0  //  CHANNEL 0
			.byte	$00				; //  MODE 2 - TYPE 0  //  CHANNEL 1
			.byte	$01				; //  MODE 3 - TYPE 1  //  CHANNEL 2
			.byte	$02				; //  MODE 4 - TYPE 2  //  CHANNEL 3

;**** REST OF DISPLAY MEMORY TYPE TABLE ****

			.byte	$02				; //  MODE 5 - TYPE 2
			.byte	$03				; //  MODE 6 - TYPE 3

;***************** VDU SECTION CONTROL NUMBERS ***************************

_LC447:			.byte	$04				; 00000100		  //  MODE 7 - TYPE 4
			.byte	$00				; 00000000
			.byte	$06				; 00000110
			.byte	$02				; 00000010

;*********** CRTC SETUP PARAMETERS TABLE 1 WITHIN TABLE ******************

; value to write to 8 bit latch bit 4 indexed by mode size type (see _TAB_MAP_TYPE)
_TAB_LAT4_MOSZ:		.byte	$0d				; 00001101
			.byte	$05				; 00000101
			.byte	$0d				; 00001101
			.byte	$05				; 00000101

;*********** CRTC SETUP PARAMETERS TABLE 2 WITHIN TABLE *****************

; value to write to 8 bit latch bit 4 indexed by mode size type (see _TAB_MAP_TYPE)
_TAB_LAT5_MOSZ:		.byte	$04				; 00000100
			.byte	$04				; 00000100
			.byte	$0c				; 00001100
			.byte	$0c				; 00001100
			.byte	$04				; 00000100

;;;;;;;;;;;;;;;;; removed CLS entry points table

;************** MSB OF MEMORY OCCUPIED BY SCREEN BUFFER	 *****************

_VDU_MEMSZ_TAB:		.byte	$50				; Type 0: &5000 - 20K
			.byte	$40				; Type 1: &4000 - 16K
			.byte	$28				; Type 2: &2800 - 10K
			.byte	$20				; Type 3: &2000 - 8K
			.byte	$04				; Type 4: &0400 - 1K


;************ MSB OF FIRST LOCATION OCCUPIED BY SCREEN BUFFER ************

_VDU_MEMLOC_TAB:	.byte	$30				; Type 0: &3000
			.byte	$40				; Type 1: &4000
			.byte	$58				; Type 2: &5800
			.byte	$60				; Type 3: &6000
			.byte	$7c				; Type 4: &7C00


;***************** NUMBER OF BYTES PER ROW *******************************

_TAB_BPR:		.byte	$28				; 00101000
			.byte	$40				; 01000000
			.byte	$80				; 10000000


;******** ROW MULTIPLIACTION TABLE POINTER TO LOOK UP TABLE **************

_TAB_MULTBL_LKUP_L:	.byte	<_MUL40_TABLE			; 10110101
			.byte	<_MUL640_TABLE			; 01110101
			.byte	<_MUL640_TABLE			; 01110101

_TAB_MULTBL_LKUP_H:	.byte	>_MUL40_TABLE			; 10110101
			.byte	>_MUL640_TABLE			; 01110101
			.byte	>_MUL640_TABLE			; 01110101


;********** CRTC CURSOR END REGISTER SETTING LOOK UP TABLE ***************

; CRTC last register to program by mode size
_TAB_CRTCBYMOSZ:	.byte	$0b				; 20k mode 0,1,2
			.byte	$17				; 16k mode 3
			.byte	$23				; 10k mode 4,5
			.byte	$2f				; 8k mode 6
			.byte	$3b				; 1k mode 7


;************* 6845 REGISTERS 0-11 FOR SCREEN TYPE 0 - MODES 0-2 *********

_CRTC_REG_TAB:		.byte	$7f				; 0 Horizontal Total	 =128
			.byte	$50				; 1 Horizontal Displayed =80
			.byte	$62				; 2 Horizontal Sync	 =&62
			.byte	$28				; 3 HSync Width+VSync	 =&28  VSync=2, HSync Width=8
			.byte	$26				; 4 Vertical Total	 =38
			.byte	$00				; 5 Vertial Adjust	 =0
			.byte	$20				; 6 Vertical Displayed	 =32
			.byte	$22				; 7 VSync Position	 =&22
			.byte	$01				; 8 Interlace+Cursor	 =&01  Cursor=0, Display=0, Interlace=Sync
			.byte	$07				; 9 Scan Lines/Character =8
			.byte	$67				; 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=7
			.byte	$08				; 11 Cursor End Line	  =8


;************* 6845 REGISTERS 0-11 FOR SCREEN TYPE 1 - MODE 3 ************

			.byte	$7f				; 0 Horizontal Total	 =128
			.byte	$50				; 1 Horizontal Displayed =80
			.byte	$62				; 2 Horizontal Sync	 =&62
			.byte	$28				; 3 HSync Width+VSync	 =&28  VSync=2, HSync=8
			.byte	$1e				; 4 Vertical Total	 =30
			.byte	$02				; 5 Vertical Adjust	 =2
			.byte	$19				; 6 Vertical Displayed	 =25
			.byte	$1b				; 7 VSync Position	 =&1B
			.byte	$01				; 8 Interlace+Cursor	 =&01  Cursor=0, Display=0, Interlace=Sync
			.byte	$09				; 9 Scan Lines/Character =10
			.byte	$67				; 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=7
			.byte	$09				; 11 Cursor End Line	  =9


;************ 6845 REGISTERS 0-11 FOR SCREEN TYPE 2 - MODES 4-5 **********

			.byte	$3f				; 0 Horizontal Total	 =64
			.byte	$28				; 1 Horizontal Displayed =40
			.byte	$31				; 2 Horizontal Sync	 =&31
			.byte	$24				; 3 HSync Width+VSync	 =&24  VSync=2, HSync=4
			.byte	$26				; 4 Vertical Total	 =38
			.byte	$00				; 5 Vertical Adjust	 =0
			.byte	$20				; 6 Vertical Displayed	 =32
			.byte	$22				; 7 VSync Position	 =&22
			.byte	$01				; 8 Interlace+Cursor	 =&01  Cursor=0, Display=0, Interlace=Sync
			.byte	$07				; 9 Scan Lines/Character =8
			.byte	$67				; 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=7
			.byte	$08				; 11 Cursor End Line	  =8


;********** 6845 REGISTERS 0-11 FOR SCREEN TYPE 3 - MODE 6 ***************

			.byte	$3f				; 0 Horizontal Total	 =64
			.byte	$28				; 1 Horizontal Displayed =40
			.byte	$31				; 2 Horizontal Sync	 =&31
			.byte	$24				; 3 HSync Width+VSync	 =&24  VSync=2, HSync=4
			.byte	$1e				; 4 Vertical Total	 =30
			.byte	$02				; 5 Vertical Adjust	 =0
			.byte	$19				; 6 Vertical Displayed	 =25
			.byte	$1b				; 7 VSync Position	 =&1B
			.byte	$01				; 8 Interlace+Cursor	 =&01  Cursor=0, Display=0, Interlace=Sync
			.byte	$09				; 9 Scan Lines/Character =10
			.byte	$67				; 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=7
			.byte	$09				; 11 Cursor End Line	  =9


;********* 6845 REGISTERS 0-11 FOR SCREEN TYPE 4 - MODE 7 ****************

			.byte	$3f				; 0 Horizontal Total	 =64
			.byte	$28				; 1 Horizontal Displayed =40
			.byte	$33				; 2 Horizontal Sync	 =&33  Note: &31 is a better value
			.byte	$24				; 3 HSync Width+VSync	 =&24  VSync=2, HSync=4
			.byte	$1e				; 4 Vertical Total	 =30
			.byte	$02				; 5 Vertical Adjust	 =2
			.byte	$19				; 6 Vertical Displayed	 =25
			.byte	$1b				; 7 VSync Position	 =&1B
			.byte	$93				; 8 Interlace+Cursor	 =&93  Cursor=2, Display=1, Interlace=Sync+Video
			.byte	$12				; 9 Scan Lines/Character =19
			.byte	$72				; 10 Cursor Start Line	  =&72	Blink=On, Speed=1/32, Line=18
			.byte	$13				; 11 Cursor End Line	  =19


;************* VDU ROUTINE VECTOR ADDRESSES   ******************************

_LC4AA:			.addr	_LD386
			.addr	_LD37E


;************ VDU ROUTINE BRANCH VECTOR ADDRESS LO ***********************

_LC4AE:			.byte	<_PLOT_D36A
			.byte	<_PLOT_D374
			.byte	<_PLOT_D342
			.byte	<_PLOT_D34B


;************ VDU ROUTINE BRANCH VECTOR ADDRESS HI ***********************

_LC4B2:			.byte	>_PLOT_D36A
			.byte	>_PLOT_D374
			.byte	>_PLOT_D342
			.byte	>_PLOT_D34B


;*********** TELETEXT CHARACTER CONVERSION TABLE  ************************

_TELETEXT_CHAR_TAB:	.byte	$23				; '#' -> '_'
			.byte	$5f				; '_' -> '`'
			.byte	$60				; '`' -> '#'
			.byte	$23				; '#'


;*********** SOFT CHARACTER RAM ALLOCATION   *****************************

_LC4BA:			.byte	$04				; &20-&3F - OSHWM+&0400
			.byte	$05				; &40-&5F - OSHWM+&0500
			.byte	$06				; &60-&7F - OSHWM+&0600
			.byte	$00				; &80-&9F - OSHWM+&0000
			.byte	$01				; &A0-&BF - OSHWM+&0100
			.byte	$02				; &C0-&DF - OSHWM+&0200


		.a8
		.i8


;**************************************************************************
;**************************************************************************
;**									 **
;**	 OSWRCH	 MAIN ROUTINE  entry from E0C5				 **
;**									 **
;**	 output a byte via the VDU stream				 **
;**									 **
;**************************************************************************
;**************************************************************************


_VDUCHR_NAT:		sep	#$30
			.i8
			.a8
			ldx	sysvar_VDU_Q_LEN		; get number of items in VDU queue
			bne	_BC512				; if parameters needed then C512
			bit	dp_mos_vdu_status		; else check status byte
			bvc	__vdu_check_delete		; if cursor editing enabled two cursors exist
			jsr	_LC568_swapcurs			; swap values
			jsr	_LCD6A				; then set up write cursor
			bmi	__vdu_check_delete		; if display disabled C4D8
			cmp	#$0d				; else if character in A=RETURN teminate edit
			bne	__vdu_check_delete		; else C4D8

			jsr	_LD918				; terminate edit

__vdu_check_delete:	cmp	#$7f				; is character DELETE ?
			beq	_BC4ED				; if so C4ED

			cmp	#' '				; is it less than space? (i.e. VDU control code)
			bcc	_BC4EF				; if so C4EF
			bit	dp_mos_vdu_status		; else check VDU byte ahain
			bmi	_BC4EA				; if screen disabled C4EA
			jsr	_VDU_OUT_CHAR			; else display a character
			jsr	_VDU_9				; and cursor right
_BC4EA:			jmp	_LC55E				; 

;********* read link addresses and number of parameters *****************

_BC4ED:			lda	#$20				; to replace delete character

;********* read link addresses and number of parameters *****************

_BC4EF:			tay					; save A for later
			pha					; X=char*3
			asl	A
			adc	1,S
			sta	1,S
			pla
			tax

			rep	#$30
			.a16
			.i16
			lda	f:_VDU_TABLE,X			; get lo byte of link address
			sta	vduvar_VDU_VEC_JMP		; store it in jump vector
			sep	#$20
			.a8
			lda	f:_VDU_TABLE+2,X		; get Q len
			sta	sysvar_VDU_Q_LEN		; store it
			sep	#$10
			.i8
			beq	execVDUVEC			; no parameters - execute
			bit	dp_mos_vdu_status		; check if cursor editing enabled
			bvs	_BC52F				; if so re-exchange pointers
			clc					; clear carry
_VDU_0_6_27:
_VDU_0:
_VDU_6:
_VDU_27:		rts					; and exit

;return with carry clear indicates that printer action not required.

;********** parameters are outstanding ***********************************
; X=&26A = 2 complement of number of parameters X=&FF for 1, FE for 2 etc.

_BC512:			sta	vduvar_VDU_Q_START+8 - 255,X	; store parameter in queue
			inx					; increment X
			stx	sysvar_VDU_Q_LEN		; store it as VDU queue
			bne	_BC532				; if not 0 C532 as more parameters are needed
			bit	dp_mos_vdu_status		; get VDU status byte
			bmi	_BC534				; if screen disabled C534
			bvs	_BC526				; else if cursor editing C526

;;;; TODO: make _VDU_JUMP work if called via emu mode!
;;;; TODO: this assumes only our module uses this address and is in same bank
			jsr	_VDU_JUMP			; execute required function
			clc					; clear carry
			rts					; and exit

_BC526:			jsr	_LC568_swapcurs			; swap values of cursors
			jsr	_LCD6A				; set up write cursor
			jsr	_VDU_JUMP			; execute required function
_BC52F:			jsr	_LC565				; re-exchange pointers

_BC532:			clc					; carry clear
			rts					; exit

;*************************************************************************
;*									 *
;*	 VDU 1 - SEND NEXT CHARACTER TO PRINTER				 *
;*									 *
;*	 1 parameter required						 *
;*									 *
;*************************************************************************

	;; TODO: need a different way to detect printables
;;_BC534:			ldy	vduvar_VDU_VEC_JMP+1		; if upper byte of link address not &C5
;;			cpy	#$c5				; printer is not interested
;;			bne	_BC532				; so C532
_BC534:			bra	_BC532
	;; TODO: printer
_VDU_1:			bra	_VDU_0_6_27
;;			tax					; else X=A
;;			lda	dp_mos_vdu_status		; A=VDU status byte
;;			lsr					; get bit 0 into carry
;;			bcc	_VDU_0_6_27			; if printer not enabled exit
;;			txa					; restore A
;;			jmp	_PRINTER_OUT_ALWAYS		; else send byte in A (next byte) to printer

;*********** if explicit link address found, no parameters ***************

execVDUVEC:		tya					; restore A
			cmp	#$08				; is it 7 or less?
			bcc	_BC553				; if so C553
			eor	#$ff				; invert it
			cmp	#$f2				; c is set if A >&0D
			eor	#$ff				; re invert

_BC553:			bit	dp_mos_vdu_status		; VDU status byte
			bmi	_BC580				; if display disabled C580
			php					; push processor flags
			jsr	_VDU_JUMP			; execute required function
			plp					; get back flags
			bcc	_BC561				; if carry clear (from C54B/F)

;**************** main exit routine **************************************

_LC55E:			lda	dp_mos_vdu_status		; VDU status byte
			lsr					; Carry is set if printer is enabled
_BC561:			bit	dp_mos_vdu_status		; VDU status byte
			bvc	_VDU_0_6_27			; if no cursor editing	C511 to exit

;***************** cursor editing routines *******************************

_LC565:			jsr	_LCD7A				; restore normal write cursor

_LC568_swapcurs:	php					; save flags and
			pha					; A
			ldx	#<vduvar_TXT_CUR_X		; X=&18
			ldy	#<vduvar_TEXT_IN_CUR_X		; Y=&64
			jsr	_LCDDE_EXG2_P3			; exchange &300/1+X with &300/1+Y
			jsr	_LCF06				; set up display address
			jsr	SET_CURS_CHARSCANAX		; set cursor position
			lda	dp_mos_vdu_status		; VDU status byte
			eor	#$02				; invert bit 1 to allow or bar scrolling
			sta	dp_mos_vdu_status		; VDU status byte
			pla					; restore flags and A
			plp					; 
			rts					; and exit

_BC580:			eor	#$06				; if A<>6
			bne	_BC58C				; return via C58C
			lda	#$7f				; A=&7F
			bcc	AND_VDU_STATUS			; and goto C5A8 ALWAYS!!

;******************* check text cursor in use ***************************

_LC588:			lda	dp_mos_vdu_status		; VDU status byte
			and	#$20				; set A from bit 5 of status byte
_BC58C:			rts					; and exit

; A=0 if text cursor, &20 if graphics

;*************************************************************************
;*									 *
;*	 VDU 14 - SET PAGED MODE					 *
;*									 *
;*************************************************************************

_VDU_14:		ldy	#$00				; Y=0
			sty	sysvar_SCREENLINES_SINCE_PAGE	; paged mode counter
			lda	#$04				; A=04
			bne	OR_VDU_STATUS			; jump to C59D

;*************************************************************************
;*									 *
;*	 VDU 2	- PRINTER ON (START PRINT JOB)				 *
;*									 *
;*************************************************************************

_VDU_2:			
		;;TODO: printer
		;;	jsr	_LE1A2				; select printer buffer and output character
			lda	#$94				; A=&94
								; when inverted at C59B this becomes =&01

;*************************************************************************
;*									 *
;*	 VDU 21 - DISABLE DISPLAY					 *
;*									 *
;*************************************************************************

_VDU_21:		eor	#$95				; if A=&15 A now =&80: if A=&94 A now =1

OR_VDU_STATUS:		ora	dp_mos_vdu_status		; VDU status byte set bit 0 or bit 7
			bne	STA_VDU_STATUS			; branch forward to store



;*************************************************************************
;*									 *
;*	 VDU 3	- PRINTER OFF (END PRINT JOB)				 *
;*									 *
;*************************************************************************

_VDU_3:
		;;TODO: printer
		;;	jsr	_LE1A2				; select printer buffer and output character
			lda	#$0a				; A=10 to clear status bits below...

;*************************************************************************
;*									 *
;*	 VDU 15 - PAGED MODE OFF					 *
;*									 *
;*************************************************************************
; A=&F or &A

_VDU_15:		eor	#$f4				; convert to &FB or &FE
AND_VDU_STATUS:		and	dp_mos_vdu_status		; VDU status byte clear bit 0 or bit 2 of status
STA_VDU_STATUS:		sta	dp_mos_vdu_status		; VDU status byte
_BC5AC_rts:		rts					; exit

;*************************************************************************
;*									 *
;*	 VDU 4	- OUTPUT AT TEXT CURSOR					 *
;*									 *
;*************************************************************************

_VDU_4:			lda	vduvar_PIXELS_PER_BYTE_MINUS1	; pixels per byte
			beq	_BC5AC_rts			; if no graphics in current mode C5AC
			jsr	_LC951				; set CRT controller for text cursor
			lda	#$df				; this to clear bit 5 of status byte
			bne	AND_VDU_STATUS			; via C5A8 exit

;*************************************************************************
;*									 *
;*	 VDU 5	- OUTPUT AT GRAPHICS CURSOR				 *
;*									 *
;*************************************************************************

_VDU_5:			lda	vduvar_PIXELS_PER_BYTE_MINUS1	; pixels per byte
			beq	_BC5AC_rts			; if none this is text mode so exit
			lda	#$20				; set up graphics cursor
			jsr	_LC954				; via C954
			bne	OR_VDU_STATUS			; set bit 5 via exit C59D

;*************************************************************************
;*									 *
;*	 VDU 8	- CURSOR LEFT						 *
;*									 *
;*************************************************************************

_VDU_8:			jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	_BC61F				; move cursor left 8 pixels if graphics
			dec	vduvar_TXT_CUR_X		; else decrement text column
			ldx	vduvar_TXT_CUR_X		; store new text column
			cpx	vduvar_TXT_WINDOW_LEFT		; if it is less than text window left
			bmi	__curs_t_wrap_left		; do wraparound	 cursor to rt of screen 1 line up
			lda	vduvar_6845_CURSOR_ADDR		; text cursor 6845 address
			sec					; subtract
			sbc	vduvar_BYTES_PER_CHAR		; bytes per character
			tax					; put in X
			lda	vduvar_6845_CURSOR_ADDR+1	; get text cursor 6845 address
			sbc	#$00				; subtract 0
			cmp	vduvar_SCREEN_BOTTOM_HIGH	; compare with hi byte of screen RAM address
			bcs	__curs_t_wrap_top		; if = or greater
			adc	vduvar_SCREEN_SIZE_HIGH		; add screen RAM size hi byte to wrap around
__curs_t_wrap_top:	tay					; Y=A
			jmp	SET_CRTC_CURSeqAX_adj		; A hi and X lo byte of cursor position

;***************** execute wraparound left-up*****************************

__curs_t_wrap_left:	lda	vduvar_TXT_WINDOW_RIGHT		; text window right
			sta	vduvar_TXT_CUR_X		; text column

;*************** cursor up ***********************************************

_BC5F4:			dec	sysvar_SCREENLINES_SINCE_PAGE	; paged mode counter
			bpl	_BC5FC				; if still greater than 0 skip next instruction
			inc	sysvar_SCREENLINES_SINCE_PAGE	; paged mode counter to restore X=0
_BC5FC:			ldx	vduvar_TXT_CUR_Y		; current text line
			cpx	vduvar_TXT_WINDOW_TOP		; top of text window
			beq	_BC60A				; if its at top of window C60A
			dec	vduvar_TXT_CUR_Y		; else decrement current text line
			jmp	_LC6AF				; and carry on moving cursor

;******** cursor at top of window ****************************************

_BC60A:			clc					; clear carry
			jsr	_LCD3F				; check for window violatations
			lda	#$08				; A=8 to check for software scrolling
			bit	dp_mos_vdu_status		; compare against VDU status byte
			bne	_BC619				; if not enabled C619
			jsr	_LC994				; set screen start register and adjust RAM
			bne	_BC61C				; jump C61C

_BC619:			jsr	_LCDA4				; soft scroll 1 line
_BC61C:			jmp	_LC6AC				; and exit

;**********cursor left and down with graphics cursor in use **************

_BC61F:			ldx	#$00				; X=0 to select horizontal parameters

;********** cursor down with graphics in use *****************************
;X=2 for vertical or 0 for horizontal

_LC621:			stx	dp_mos_vdu_wksp+1		; store X
			jsr	_LD10D				; check for window violations
			ldx	dp_mos_vdu_wksp+1		; restore X
			sec					; set carry
			lda	vduvar_GRA_CUR_INT,X		; current graphics cursor X>1=vertical
			sbc	#$08				; subtract 8 to move back 1 character
			sta	vduvar_GRA_CUR_INT,X		; store in current graphics cursor X>1=verticaal
			bcs	_BC636				; if carry set skip next
			dec	vduvar_GRA_CUR_INT+1,X		; current graphics cursor hi -1
_BC636:			lda	dp_mos_vdu_wksp			; &DA=0 if no violation else 1 if vert violation
								; 2 if horizontal violation
			bne	_BC658				; if violation C658
			jsr	_LD10D				; check for window violations
			beq	_BC658				; if none C658

			ldx	dp_mos_vdu_wksp+1		; else get back X
			lda	vduvar_GRA_WINDOW_RIGHT,X	; graphics window rt X=0 top X=2
			cpx	#$01				; is X=0
			bcs	_BC64A				; if not C64A
			sbc	#$06				; else subtract 7

_BC64A:			sta	vduvar_GRA_CUR_INT,X		; current graphics cursor X>1=vertical
			lda	vduvar_GRA_WINDOW_RIGHT+1,X	; graphics window hi rt X=0 top X=2
			sbc	#$00				; subtract carry
			sta	vduvar_GRA_CUR_INT+1,X		; current graphics cursor X<2=horizontal else vertical
			txa					; A=X
			beq	_BC660				; cursor up
_BC658:			jmp	_LD1B8				; set up external coordinates for graphics

;*************************************************************************
;*									 *
;*	 VDU 11 - CURSOR UP						 *
;*									 *
;*************************************************************************

_VDU_11:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC5F4				; if text cursor then C5F4
_BC660:			ldx	#$02				; else X=2
			bne	_BC6B6				; goto C6B6

;*************************************************************************
;*									 *
;*	 VDU 9	- CURSOR RIGHT						 *
;*									 *
;*************************************************************************

_VDU_9:			lda	dp_mos_vdu_status		; VDU status byte
			and	#$20				; check bit 5
			bne	_BC6B4				; if set then graphics cursor in use so C6B4
			ldx	vduvar_TXT_CUR_X		; text column
			cpx	vduvar_TXT_WINDOW_RIGHT		; text window right
			bcs	_BC684				; if X exceeds window right then C684
			inc	vduvar_TXT_CUR_X		; text column
			lda	vduvar_6845_CURSOR_ADDR		; text cursor 6845 address
			adc	vduvar_BYTES_PER_CHAR		; add bytes per character
			tax					; X=A
			lda	vduvar_6845_CURSOR_ADDR+1	; text cursor 6845 address
			adc	#$00				; add carry if set
			jmp	SET_CRTC_CURSeqAX_adj		; use AX to set new cursor address

;********: text cursor down and right *************************************

_BC684:			lda	vduvar_TXT_WINDOW_LEFT		; text window left
			sta	vduvar_TXT_CUR_X		; text column

;********: text cursor down *************************************

_BC68A:			clc					; clear carry
			jsr	_LCAE3				; check bottom margin, X=line count
			ldx	vduvar_TXT_CUR_Y		; current text line
			cpx	vduvar_TXT_WINDOW_BOTTOM	; bottom margin
			bcs	_BC69B				; if X=>current bottom margin C69B
			inc	vduvar_TXT_CUR_Y		; else increment current text line
			bcc	_LC6AF				; 
_BC69B:			jsr	_LCD3F				; check for window violations
			lda	#$08				; check bit 3
			bit	dp_mos_vdu_status		; VDU status byte
			bne	_BC6A9				; if software scrolling enabled C6A9
			jsr	_LC9A4				; perform hardware scroll
			bne	_LC6AC				; 
_BC6A9:			jsr	_LCDFF				; execute upward scroll
_LC6AC:			jsr	_LCEAC				; clear a line

_LC6AF:			jsr	_LCF06				; set up display address
			bcc	_BC732				; 

;*********** graphic cursor right ****************************************

_BC6B4:			ldx	#$00				; 

;************** graphic cursor up  (X=2) **********************************

_BC6B6:			stx	dp_mos_vdu_wksp+1		; store X
			jsr	_LD10D				; check for window violations
			ldx	dp_mos_vdu_wksp+1		; get back X
			clc					; clear carry
			lda	vduvar_GRA_CUR_INT,X		; current graphics cursor X>1=vertical
			adc	#$08				; Add 8 pixels
			sta	vduvar_GRA_CUR_INT,X		; current graphics cursor X>1=vertical
			bcc	_BC6CB				; 
			inc	vduvar_GRA_CUR_INT+1,X		; current graphics cursor X<2=horizontal else vertical
_BC6CB:			lda	dp_mos_vdu_wksp			; A=0 no window violations 1 or 2 indicates violation
			bne	_BC658				; if outside window C658
			jsr	_LD10D				; check for window violations
			beq	_BC658				; if no violations C658

			ldx	dp_mos_vdu_wksp+1		; get back X
			lda	vduvar_GRA_WINDOW_LEFT,X	; graphics window X<2 =left else bottom
			cpx	#$01				; If X=0
			bcc	_BC6DF				; C6DF
			adc	#$06				; else add 7
_BC6DF:			sta	vduvar_GRA_CUR_INT,X		; current graphics cursor X>1=vertical
			lda	vduvar_GRA_WINDOW_LEFT+1,X	; graphics window hi X<2 =left else bottom
			adc	#$00				; add anny carry
			sta	vduvar_GRA_CUR_INT+1,X		; current graphics cursor X<2=horizontal else vertical
			txa					; A=X
			beq	_BC6F5				; if X=0 C6F5 cursor down
			jmp	_LD1B8				; set up external coordinates for graphics

;*************************************************************************
;*									 *
;*	 VDU 10	 - CURSOR DOWN						 *
;*									 *
;*************************************************************************

_VDU_10:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC68A				; if text cursor back to C68A
_BC6F5:			ldx	#$02				; else X=2 to indicate vertical movement
			jmp	_LC621				; move graphics cursor down

;*************************************************************************
;*									 *
;*	 VDU 28 - DEFINE TEXT WINDOW					 *
;*									 *
;*	 4 parameters							 *
;*									 *
;*************************************************************************
;parameters are set up thus
;0320  P1 left margin
;0321  P2 bottom margin
;0322  P3 right margin
;0323  P4 top margin
;Note that last parameter is always in 0323

_VDU_28:		ldx	vduvar_MODE			; screen mode
			lda	vduvar_VDU_Q_START+6		; get bottom margin
			cmp	vduvar_VDU_Q_START+8		; compare with top margin
			bcc	_BC758				; if bottom margin exceeds top return
			cmp	_TEXT_ROW_TABLE,X		; text window bottom margin maximum
			beq	_BC70C				; if equal then its OK
			bcs	_BC758				; else exit

_BC70C:			lda	vduvar_VDU_Q_START+7		; get right margin
			tay					; put it in Y
			cmp	_TEXT_COL_TABLE,X		; text window right hand margin maximum
			beq	_BC717				; if equal then OK
			bcs	_BC758				; if greater than maximum exit

_BC717:			sec					; set carry to subtract
			sbc	vduvar_VDU_Q_START+5		; left margin
			bmi	_BC758				; if left greater than right exit
			tay					; else A=Y (window width)
			jsr	_LCA88				; calculate number of bytes in a line
			lda	#$08				; A=8 to set bit  of &D0
			jsr	OR_VDU_STATUS			; indicating that text window is defined
			ldx	#$20				; point to parameters
			ldy	#$08				; point to text window margins
			jsr	_LD48A				; (&300/3+Y)=(&300/3+X)
			jsr	_LCEE8				; set up screen address
			bcs	_VDU_30				; home cursor within window
_BC732:			jmp	SET_CURS_CHARSCANAX		; set cursor position


;*************************************************************************
;*									 *
;*	 OSWORD 9  - READ A PIXEL					 *
;*	 =POINT(X,Y)							 *
;*									 *
;*************************************************************************
;on entry  &EF=A=9
;	   &F0=X=low byte of parameter block address
;	   &F1=Y=high byte of parameter block address
;	PARAMETER BLOCK
;	0,1=X coordinate
;	2,3=Y coordinate
;on exit, result in BLOCK+4
;     =&FF if point was of screen or logical colour of point if on screen


_OSWORD_9:		ldy	#$03				; Y=3 to point to hi byte of Y coordinate
_BC737:			lda	(dp_mos_OSBW_X),Y		; get it
			sta	vduvar_TEMP_8,Y			; store it
			dey					; point to next byte
			bpl	_BC737				; transfer till Y=&FF lo byte of X coordinate in &328
			lda	#$28				; 
			jsr	_LD839				; check window boundaries
			ldy	#$04				; Y=4
			bne	_BC750				; jump to C750


;*************************************************************************
;*									 *
;*	 OSWORD 11 - READ PALLETTE					 *
;*									 *
;*************************************************************************
;on entry  &EF=A=11
;	   &F0=X=low byte of parameter block address
;	   &F1=Y=high byte of parameter block address
;	PARAMETER BLOCK
;	0=logical colour to read
;on exit, result in BLOCK
;	0=logical colour
;	1=physical colour
;	2=red colour component	\
;	3=green colour component } when set using analogue colours
;	4=blue colour component /

_OSWORD_11:		and	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			tax					; put it in X
			lda	vduvar_PALLETTE,X		; colour pallette
_BC74F:			iny					; increment Y to point to byte 1

_BC750:			sta	(dp_mos_OSBW_X),Y		; store data
			lda	#$00				; issue 0s
			cpy	#$04				; to next bytes until Y=4
			bne	_BC74F				; 

_BC758:			rtl					; and exit


;*************************************************************************
;*									 *
;*	 VDU 12 - CLEAR TEXT SCREEN					 *
;*	 CLS								 *
;*									 *
;*************************************************************************

_VDU_12:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	_BC7BD				; if graphics cursor &C7BD
			lda	dp_mos_vdu_status		; VDU status byte
			and	#$08				; check if software scrolling (text window set)
			bne	_BC767				; if so C767
			jmp	_LCBC1_DOCLS			; initialise screen display and home cursor

_BC767:			ldx	vduvar_TXT_WINDOW_TOP		; top of text window
_BC76A:			stx	vduvar_TXT_CUR_Y		; current text line
			jsr	_LCEAC				; clear a line

			ldx	vduvar_TXT_CUR_Y		; current text line
			cpx	vduvar_TXT_WINDOW_BOTTOM	; bottom margin
			inx					; X=X+1
			bcc	_BC76A				; if X at compare is less than bottom margin clear next


;*************************************************************************
;*									 *
;*	 VDU 30 - HOME CURSOR						 *
;*									 *
;*************************************************************************

_VDU_30:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC781				; if text cursor C781
			jmp	_LCFA6				; home graphic cursor if graphic
_BC781:			sta	vduvar_VDU_Q_START+8		; store 0 in last two parameters
			sta	vduvar_VDU_Q_START+7		; 


;*************************************************************************
;*									 *
;*	 VDU 31 - POSITION TEXT CURSOR					 *
;*	 TAB(X,Y)							 *
;*									 *
;*	 2 parameters							 *
;*									 *
;*************************************************************************
;0322 = supplied X coordinate
;0323 = supplied Y coordinate

_VDU_31:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	_BC758				; exit
			jsr	_LC7A8				; exchange text column/line with workspace 0328/9
			clc					; clear carry
			lda	vduvar_VDU_Q_START+7		; get X coordinate
			adc	vduvar_TXT_WINDOW_LEFT		; add to text window left
			sta	vduvar_TXT_CUR_X		; store as text column
			lda	vduvar_VDU_Q_START+8		; get Y coordinate
			clc					; 
			adc	vduvar_TXT_WINDOW_TOP		; add top of text window
			sta	vduvar_TXT_CUR_Y		; current text line
			jsr	_LCEE8				; set up screen address
			bcc	_BC732				; set cursor position if C=0 (point on screen)
_LC7A8:			ldx	#<vduvar_TXT_CUR_X		; else point to workspace
			ldy	#<vduvar_TEMP_8			; and line/column to restore old values
			jmp	_LCDDE_EXG2_P3			; exchange &300/1+X with &300/1+Y


;*************************************************************************
;*									 *
;*	 VDU 13 - CARRIAGE RETURN					 *
;*									 *
;*************************************************************************

_VDU_13:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC7B7				; if text C7B7
			jmp	_LCFAD				; else set graphics cursor to left hand columm

_BC7B7:			jsr	_LCE6E				; set text column to left hand column
			jmp	_LC6AF				; set up cursor and display address

_BC7BD:			jsr	_LCFA6				; home graphic cursor


;*************************************************************************
;*									 *
;*	 VDU 16 - CLEAR GRAPHICS SCREEN					 *
;*	 CLG								 *
;*									 *
;*************************************************************************

_VDU_16:		lda	vduvar_PIXELS_PER_BYTE_MINUS1	; pixels per byte
			beq	_BC7F8				; if 0 current mode has no graphics so exit
			ldx	vduvar_GRA_BACK			; Background graphics colour
			ldy	vduvar_GRA_PLOT_BACK		; background graphics plot mode (GCOL n)
			jsr	_LD0B3				; set graphics byte mask in &D4/5
			ldx	#$00				; graphics window
			ldy	#$28				; workspace
			jsr	_LD47C				; set(300/7+Y) from (300/7+X)
			sec					; set carry
			lda	vduvar_GRA_WINDOW_TOP		; graphics window top lo.
			sbc	vduvar_GRA_WINDOW_BOTTOM	; graphics window bottom lo
			tay					; Y=difference
			iny					; increment
			sty	vduvar_GRA_WKSP			; and store in workspace (this is line count)
_BC7E1:			ldx	#$2c				; 
			ldy	#$28				; 
			jsr	_VDU_G_CLR_LINE			; clear line
			lda	vduvar_TEMP_8+6			; decrement window height in pixels
			bne	_BC7F0				; 
			dec	vduvar_TEMP_8+7			; 
_BC7F0:			dec	vduvar_TEMP_8+6			; 
			dec	vduvar_GRA_WKSP			; decrement line count
			bne	_BC7E1				; if <>0 then do it again
_BC7F8:			rts					; exit


;*************************************************************************
;*									 *
;*	 VDU 17 - DEFINE TEXT COLOUR					 *
;*	 COLOUR n							 *
;*									 *
;*	 1 parameter							 *
;*									 *
;*************************************************************************
;parameter in &0323

_VDU_17:		ldy	#$00				; Y=0
			beq	_BC7FF				; jump to C7FF


;*************************************************************************
;*									 *
;*	 VDU 18 - DEFINE GRAPHICS COLOUR				 *
;*	 GCOL k,c							 *
;*									 *
;*	 2 parameters							 *
;*									 *
;*************************************************************************
;parameters in 323,322

_VDU_18:		ldy	#$02				; Y=2

_BC7FF:			lda	vduvar_VDU_Q_START+8		; get last parameter
			bpl	_BC805				; if +ve it's foreground colour so C805
			iny					; else Y=Y+1
_BC805:			and	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			sta	dp_mos_vdu_wksp			; store it
			lda	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			beq	_BC82B				; if none exit
			and	#$07				; else limit to an available colour and clear M
			clc					; clear carry
			adc	dp_mos_vdu_wksp			; Add last parameter to get pointer to table
			tax					; pointer into X

			lda	f:_LC423,X			; get colour to mask from table
			sta	vduvar_TXT_FORE,Y		; colour Y=0=text fgnd 1= text bkgnd 2=graphics fg etc
			cpy	#$02				; If Y>1
			bcs	_BC82C				; then its graphics so C82C else
			lda	vduvar_TXT_FORE			; foreground text colour
			eor	#$ff				; invert
			sta	dp_mos_vdu_txtcolourEOR		; text colour byte to be orred or EORed into memory
			eor	vduvar_TXT_BACK			; background text colour
			sta	dp_mos_vdu_txtcolourOR		; text colour byte to be orred or EORed into memory
_BC82B:			rts					; and exit

_BC82C:			lda	vduvar_VDU_Q_START+7		; get first parameter
			sta	vduvar_GRA_FORE,Y		; text colour Y=0=foreground 1=background etc.
			rts					; exit

_BC833:			lda	#$20				; 
			sta	vduvar_TXT_BACK			; background text colour
			rts					; 


;*************************************************************************
;*									 *
;*	 VDU 20 - RESTORE DEFAULT COLOURS				 *
;*									 *
;*************************************************************************

_VDU_20:		ldx	#$05				; X=5

			lda	#$00				; A=0
_BC83D:			sta	vduvar_TXT_FORE,X		; zero all colours
			dex					; 
			bpl	_BC83D				; until X=&FF
			ldx	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			beq	_BC833				; if none its MODE 7 so C833
			lda	#$ff				; A=&FF (white, all bits set)
			cpx	#$0f				; if not mode 2 (16 colours)
			bne	_BC850				; goto C850

			lda	#$3f				; else A=&3F (white, no flash)
_BC850:			sta	vduvar_TXT_FORE			; foreground text colour
			sta	vduvar_GRA_FORE			; foreground graphics colour
			eor	#$ff				; invert A
			sta	dp_mos_vdu_txtcolourOR		; text colour byte to be orred or EORed into memory
			sta	dp_mos_vdu_txtcolourEOR		; text colour byte to be orred or EORed into memory
			stx	vduvar_VDU_Q_START+4		; set first parameter of 5
			cpx	#$03				; if there are 4 colours
			beq	_BC874				; goto C874
			bcc	_BC885				; if less there are 2 colours goto C885
								; else there are 16 colours
			stx	vduvar_VDU_Q_START+5		; set second parameter
_BC868:			jsr	_VDU_19				; do VDU 19 etc
			dec	vduvar_VDU_Q_START+5		; decrement first parameter
			dec	vduvar_VDU_Q_START+4		; and last parameter
			bpl	_BC868				; 
			rts					; 

;********* 4 colour mode *************************************************

_BC874:			ldx	#$07				; X=7
			stx	vduvar_VDU_Q_START+5		; set first parameter
_BC879:			jsr	_VDU_19				; and do VDU 19
			lsr	vduvar_VDU_Q_START+5		; 
			dec	vduvar_VDU_Q_START+4		; 
			bpl	_BC879				; 
			rts					; exit

;********* 2 colour mode ************************************************

_BC885:			ldx	#$07				; X=7
			jsr	_LC88F				; execute VDU 19
			ldx	#$00				; X=0
			stx	vduvar_VDU_Q_START+4			; store it as
_LC88F:			stx	vduvar_VDU_Q_START+5			; both parameters


;*************************************************************************
;*									 *
;*	 VDU 19 - DEFINE COLOURS					 *
;*	[COLOUR l,p]							 *
;*	[COLOUR l,r,g,b]						 *
;*									 *
;*	 5 parameters							 *
;*									 *
;*************************************************************************
;&31F=first parameter logical colour
;&320=second physical colour

_VDU_19:		php					; push processor flags
			sei					; disable interrupts
			lda	vduvar_VDU_Q_START+4		; get first parameter and
			and	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			tax					; toi make legal  X=A
			lda	vduvar_VDU_Q_START+5		; A=second parameter
_LC89E:			and	#$0f				; make legal
			sta	vduvar_PALLETTE,X		; colour pallette
			tay					; Y=A
			lda	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			sta	dp_mos_X			; store it
			cmp	#$03				; is it 4 colour mode??
			php					; save flags
			txa					; A=X
_BC8AD:			ror					; rotate A into &FA
			ror	dp_mos_X			; 
			bcs	_BC8AD				; 
			asl	dp_mos_X			; 
			tya					; A=Y
			ora	dp_mos_X			; 
			tax					; 
			ldy	#$00				; Y=0
_BC8BA:			plp					; check flags
			php					; 
			bne	_BC8CC				; if A<>3 earlier C8CC
			and	#$60				; else A=&60 to test bits 5 and 6
			beq	_BC8CB				; if not set C8CB
			cmp	#$60				; else if both set
			beq	_BC8CB				; C8CB
			txa					; A=X
			eor	#$60				; invert
			bne	_BC8CC				; and if not 0 C8CC

_BC8CB:			txa					; X=A
_BC8CC:			jsl	_LEA11				; call Osbyte 155 pass data to pallette register
			tya					; 
			sec					; 
			adc	vduvar_COL_COUNT_MINUS1			; number of logical colours less 1
			tay					; 
			txa					; 
			adc	#$10				; 
			tax					; 
			cpy	#$10				; if Y<16 do it again
			bcc	_BC8BA				; 
			plp					; pull flags twice
			plp					; 
			rts					; and exit


;*************************************************************************
;*									 *
;*	 OSWORD 12 - WRITE PALLETTE					 *
;*									 *
;*************************************************************************
;on entry X=&F0:Y=&F1:YX points to parameter block
;byte 0 = logical colour;  byte 1 physical colour; bytes 2-4=0

_OSWORD_12:		php					; push flags
			and	vduvar_COL_COUNT_MINUS1		; and with number of logical colours less 1
			tax					; X=A
			iny					; Y=Y+1
			lda	(dp_mos_OSBW_X),Y		; get phsical colour
			jsr	_LC89E				; do VDU19 with parameters in X and A
			rtl


;*************************************************************************
;*									 *
;*	 VDU 22 - SELECT MODE						 *
;*	 MODE n								 *
;*									 *
;*	 1 parameter							 *
;*									 *
;*************************************************************************
;parameter in &323

_VDU_22:		lda	vduvar_VDU_Q_START+8		; get parameter
			jmp	setMode				; goto CB33


;*************************************************************************
;*									 *
;*	 VDU 23 - DEFINE CHARACTERS					 *
;*									 *
;*	 9 parameters							 *
;*									 *
;*************************************************************************
;parameters are:-
;31B character to define
;31C to 323 definition

_VDU_23:		lda	vduvar_VDU_Q_START		; get character to define
			cmp	#$20				; is it ' '
			bcc	_VDU_23_CTRL			; if less then it is a control instruction, goto C93F
_VDU_23_DEFINE_CHAR:	pha					; else save parameter
			lsr					; A=A/32
			lsr					; 
			lsr					; 
			lsr					; 
			lsr					; 
			tax					; X=A
			lda	_LC40D,X			; get font flag mask from table (A=&80/2^X)
			bit	vduvar_EXPLODE_FLAGS		; font flag
			bne	_BC927				; and if A<>0 C927 storage area is established already
			ora	vduvar_EXPLODE_FLAGS		; or with font flag to set bit found to be 0
			sta	vduvar_EXPLODE_FLAGS		; font flag
			txa					; get back A
			and	#$03				; And 3 to clear all but bits 0 and 1
			clc					; clear carry
			adc	#$bf				; add &BF (A=&C0,&C1,&C2) to select a character page
			sta	dp_mos_vdu_wksp+5		; store it
			lda	vduvar_EXPLODE_FLAGS,X		; get font location byte (normally &0C)
			sta	dp_mos_vdu_wksp+3		; store it
			ldy	#$00				; Y=0 so (&DE) holds (&C000 -&C2FF)
			sty	dp_mos_vdu_wksp+2		; 
			sty	dp_mos_vdu_wksp+4		; 
_BC920:			lda	(dp_mos_vdu_wksp+4),Y		; transfer page to storage area
			sta	(dp_mos_vdu_wksp+2),Y		; 
			dey					; 
			bne	_BC920				; 

_BC927:			pla					; get back A
			jsr	_LD03E				; set up character definition pointers

			ldy	#$07				; Y=7
_BC92D:			lda	vduvar_VDU_Q_START+1,Y		; transfer definition parameters
			sta	(dp_mos_vdu_wksp+4),Y		; to RAM definition
			dey					; 
			bpl	_BC92D				; 
			rts					; and exit

			pla					; Pull A
_BC937:			rts					; and exit


;************ VDU EXTENSION **********************************************

_LC938:			lda	vduvar_VDU_Q_START+4		; A=fifth VDU parameter
			clc					; clear carry
__vdu_23_vduv:		pea	IX_VDUV
			pld
			cop	COP_08_OPCAV
			rts

;********** VDU control commands *****************************************

_VDU_23_CTRL:		cmp	#$01				; is A=1
			bcc	_VDU_23_SET_CRTC		; if less (0) then set CRT register directly

			bne	__vdu_23_vduv			; if not 1 jump to VDUV for VDU extension

;********** turn cursor on/off *******************************************

			jsr	_LC588				; A=0 if text cursor, A=&20 if graphics cursor
			bne	_BC937				; if graphics exit
			lda	#$20				; A=&20 - preload to turn cursor off
			ldy	vduvar_VDU_Q_START+1		; Y=second VDU parameter
			beq	_LC954				; if 0, jump to C954 to turn cursor off
_LC951:			lda	vduvar_CUR_START_PREV		; get last setting of CRT controller register
								; for cursor on
_LC954:			ldy	#$0a				; Y=10 - cursor control register number
			bne	_BC985				; jump to C985, Y=register, Y=value

;********** set CRT controller *******************************************

_VDU_23_SET_CRTC:	lda	vduvar_VDU_Q_START+2		; get third
			ldy	vduvar_VDU_Q_START+1		; and second parameter
SET_CRTC_YeqA:		cpy	#$07				; is Y=7
			bcc	_BC985				; if less C985
			bne	_BC967				; else if >7 C967
			adc	oswksp_VDU_VERTADJ		; else ADD screen vertical display adjustment

_BC967:			cpy	#$08				; If Y<>8
			bne	_BC972				; C972
			ora	#$00				; if bit 7 set
			bmi	_BC972				; C972
			eor	oswksp_VDU_INTERLACE		; else EOR with interlace toggle

_BC972:			cpy	#$0a				; Y=10??
			bne	_BC985				; if not C985
			sta	vduvar_CUR_START_PREV		; last setting of CRT controller register
			tay					; Y=A
			lda	dp_mos_vdu_status		; VDU status byte
			and	#$20				; check bit 5 printing at graphics cursor??
			php					; push flags
			tya					; Y=A
			ldy	#$0a				; Y=10
			plp					; pull flags
			bne	_BC98B				; if graphics in use then C98B


			;;; TODO: native
_BC985:			pha
			tya
			sta	f:sheila_CRTC_reg		; else set CRTC address register
			pla
			sta	f:sheila_CRTC_rw		; and poke new value to register Y
;;			DEBUG_PRINTF "CRTC %Y=%A  %F\n"
_BC98B:			rts					; exit


;*************************************************************************
;*									 *
;*	 VDU 25 - PLOT							 *
;*	 PLOT k,x,y							 *
;*	 DRAW x,y							 *
;*	 MOVE x,y							 *
;*	 PLOT x,y							 *
;*	 5 parameters							 *
;*									 *
;*************************************************************************

_VDU_25:		
			DEBUG_PRINTF "VDU 25\n"

			ldx	vduvar_PIXELS_PER_BYTE_MINUS1	; pixels per byte
			beq	_LC938				; if no graphics available go to VDU Extension
			jmp	_LD060				; else enter Plot routine at D060

;********** adjust screen RAM addresses **********************************

_LC994:			ldx	vduvar_6845_SCREEN_START	; window area start address lo
			lda	vduvar_6845_SCREEN_START+1	; window area start address hi
			jsr	_LCCF8				; subtract bytes per character row from this
			bcs	_BC9B3				; if no wraparound needed C9B3

			adc	vduvar_SCREEN_SIZE_HIGH		; screen RAM size hi byte to wrap around
			bcc	_BC9B3				; 

_LC9A4:			ldx	vduvar_6845_SCREEN_START	; window area start address lo
			lda	vduvar_6845_SCREEN_START+1	; window area start address hi
			jsr	_LCAD4				; add bytes per char. row
			bpl	_BC9B3				; 

			sec					; wrap around i other direction
			sbc	vduvar_SCREEN_SIZE_HIGH		; screen RAM size hi byte
_BC9B3:			sta	vduvar_6845_SCREEN_START+1	; window area start address hi
			stx	vduvar_6845_SCREEN_START	; window area start address lo
			ldy	#$0c				; Y=12
			bne	SET_CRTCY_AXDIV8		; jump to CA0E


;*************************************************************************
;*									 *
;*	 VDU 26 - SET DEFAULT WINDOWS					 *
;*									 *
;*************************************************************************

_VDU_26:		lda	#$00				; A=0
			ldx	#$2c				; X=&2C

_BC9C1:			sta	vduvar_GRA_WINDOW_LEFT,X	; clear all windows
			dex					; 
			bpl	_BC9C1				; until X=&FF

			ldx	vduvar_MODE			; screen mode
			lda	f:_TEXT_COL_TABLE,X		; text window right hand margin maximum
			sta	vduvar_TXT_WINDOW_RIGHT		; text window right
			tay
			jsr	_LCA88				; calculate number of bytes in a line
			lda	f:_TEXT_ROW_TABLE,X		; text window bottom margin maximum
			sta	vduvar_TXT_WINDOW_BOTTOM	; bottom margin			
			ldy	#$03				; Y=3
			sty	vduvar_VDU_Q_START+8		; set as last parameter
			iny					; increment Y
			sty	vduvar_VDU_Q_START+6		; set parameters
			dec	vduvar_VDU_Q_START+7		; 
			dec	vduvar_VDU_Q_START+5		; 
			jsr	_VDU_24				; and do VDU 24
			lda	#$f7				; 
			jsr	AND_VDU_STATUS			; clear bit 3 of &D0
			ldx	vduvar_6845_SCREEN_START	; window area start address lo
			lda	vduvar_6845_SCREEN_START+1	; window area start address hi
SET_CRTC_CURSeqAX_adj:	stx	vduvar_6845_CURSOR_ADDR		; text cursor 6845 address
			sta	vduvar_6845_CURSOR_ADDR+1	; text cursor 6845 address
			bpl	SET_CURS_CHARSCANAX		; set cursor position
			sec					; 
			sbc	vduvar_SCREEN_SIZE_HIGH		; screen RAM size hi byte

;**************** set cursor position ************************************

SET_CURS_CHARSCANAX:	stx	dp_mos_vdu_top_scanline		; set &D8/9 from X/A
			sta	dp_mos_vdu_top_scanline+1	; 
			ldx	vduvar_6845_CURSOR_ADDR		; text cursor 6845 address
			lda	vduvar_6845_CURSOR_ADDR+1	; text cursor 6845 address
			ldy	#$0e				; Y=14
SET_CRTCY_AXDIV8:	pha					; Push A
			lda	vduvar_MODE			; screen mode
			cmp	#$07				; is it mode 7?
			pla					; get back A
			bcs	_BCA27				; if mode 7 selected CA27
			stx	dp_mos_vdu_wksp			; else store X
			lsr					; divide X/A by 8
			ror	dp_mos_vdu_wksp			; 
			lsr					; 
			ror	dp_mos_vdu_wksp			; 
			lsr					; 
			ror	dp_mos_vdu_wksp			; 
			ldx	dp_mos_vdu_wksp			; 
			jmp	SET_CRTC_YeqAX			; goto CA2B

_BCA27:			sbc	#$74				; mode 7 subtract &74
			eor	#$20				; EOR with &20
SET_CRTC_YeqAX:		
;;			DEBUG_PRINTF "CRTC %Y=%A %X %F\n"
			pha
			tya
			sta	f:sheila_CRTC_reg		; write to CRTC address file register
			pla
			pha
			sta	f:sheila_CRTC_rw		; and to relevant address (register 14)
			iny
			tya					; Increment Y
			sta	f:sheila_CRTC_reg		; write to CRTC address file register
			txa
			sta	f:sheila_CRTC_rw		; and to relevant address (register 15)
			pla
			rts					; and RETURN

;*************************************************************************
;*									 *
;*	 VDU 24 - DEFINE GRAPHICS WINDOW				 *
;*									 *
;*	 8 parameters							 *
;*									 *
;*************************************************************************
;&31C/D Left margin
;&31E/F Bottom margin
;&320/1 Right margin
;&322/3 Top margin


_VDU_24:		jsr	_LCA81				; exchange 310/3 with 328/3
			ldx	#$1c				; 
			ldy	#$2c				; 
			jsr	_LD411				; calculate width=right - left
								; height = top-bottom
			ora	vduvar_TEMP_8+5			; 
			bmi	_LCA81				; exchange 310/3 with 328/3 and exit
			ldx	#$20				; X=&20
			jsr	_LD149				; scale pointers to mode
			ldx	#$1c				; X=&1C
			jsr	_LD149				; scale pointers to mode
			lda	vduvar_VDU_Q_START+4		; check for negative margins
			ora	vduvar_VDU_Q_START+2		; 
			bmi	_LCA81				; if found exchange 310/3 with 328/3 and exit
			lda	vduvar_VDU_Q_START+8		; 
			bne	_LCA81				; exchange 310/3 with 328/3 and exit
			ldx	vduvar_MODE			; screen mode
			lda	vduvar_VDU_Q_START+6		; right margin hi
			sta	dp_mos_vdu_wksp			; store it
			lda	vduvar_VDU_Q_START+5		; right margin lo
			lsr	dp_mos_vdu_wksp			; /2
			ror					; A=A/2
			lsr	dp_mos_vdu_wksp			; /2
			bne	_LCA81				; exchange 310/3 with 328/3
			ror					; A=A/2
			lsr					; A=A/2
			cmp	f:_TEXT_COL_TABLE,X		; text window right hand margin maximum
			beq	_BCA7A				; if equal CA7A
			bpl	_LCA81				; exchange 310/3 with 328/3

_BCA7A:			ldy	#$00				; Y=0
			ldx	#$1c				; X=&1C
			jsr	_LD47C				; set(300/7+Y) from (300/7+X)

;***************** exchange 310/3 with 328/3 *****************************

_LCA81:			ldx	#<vduvar_GRA_CUR_EXT			; X=10
			ldy	#<vduvar_TEMP_8		; Y=&28
			jmp	_LCDE6_EXG4_P3			; exchange 300/3+Y and 300/3+X

_LCA88:			iny					; Y=Y+1
			tya					; A=Y
			ldy	#$00				; Y=0
			sty	vduvar_TXT_WINDOW_WIDTH_BYTES+1			; text window width hi (bytes)
			sta	vduvar_TXT_WINDOW_WIDTH_BYTES			; text window width lo (bytes)
			lda	vduvar_BYTES_PER_CHAR				; bytes per character
			lsr					; /2
			beq	_BCAA1				; if 0 exit
_BCA98:			asl	vduvar_TXT_WINDOW_WIDTH_BYTES			; text window width lo (bytes)
			rol	vduvar_TXT_WINDOW_WIDTH_BYTES+1			; text window width hi (bytes)
			lsr					; /2
			bcc	_BCA98				; 
_BCAA1:			rts					; 


;*************************************************************************
;*									 *
;*	 VDU 29 - SET GRAPHICS ORIGIN					 *
;*									 *
;*	 4 parameters							 *
;*									 *
;*************************************************************************

_VDU_29:		ldx	#$20				; 
			ldy	#$0c				; 
			jsr	_LD48A				; (&300/3+Y)=(&300/3+X)
			jmp	_LD1B8				; set up external coordinates for graphics


;*************************************************************************
;*									 *
;*	 VDU 127 (&7F) - DELETE (entry 32)				 *
;*									 *
;*************************************************************************

_VDU_127:		jsr	_VDU_8				; cursor left
			jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	__vdu_del_modeX			; if graphics then CAC7
			ldx	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			beq	__vdu_del_mode7			; if mode 7 CAC2
			sta	dp_mos_vdu_wksp+4		; else store A (always 0)
			lda	#$c0				; A=&C0
			sta	dp_mos_vdu_wksp+5		; store in &DF (&DE) now points to C300 SPACE pattern
			jmp	_LCFBF				; display a space

__vdu_del_mode7:	lda	#$20				; A=&20
			jmp	_VDU_OUT_MODE7			; and return to display a space

__vdu_del_modeX:	lda	#$7f				; for graphics cursor
			jsr	_LD03E				; set up character definition pointers
			ldx	vduvar_GRA_BACK			; Background graphics colour
			ldy	#$00				; Y=0
			jmp	_LCF63				; invert pattern data (to background colour)

;***** Add number of bytes in a line to X/A ******************************

_LCAD4:			pha					; store A
			txa					; A=X
			clc					; clear carry
			adc	vduvar_BYTES_PER_ROW				; bytes per character row
			tax					; X=A
			pla					; get back A
			adc	vduvar_BYTES_PER_ROW+1			; bytes per character row
			rts					; and return

;********* control scrolling in paged mode *******************************

_BCAE0:			jsr	_LCB14				; zero paged mode line counter
_LCAE3:			lda	#OSBYTE_118_SET_KEYBOARD_LEDS
			cop	COP_06_OPOSB			; osbyte 118 check keyboard status; set LEDs
			bcc	_BCAEA				; if carry clear CAEA
			bmi	_BCAE0				; if M set CAE0 do it again

_BCAEA:			lda	dp_mos_vdu_status			; VDU status byte
			eor	#$04				; invert bit 2 paged scrolling
			and	#$46				; and if 2 cursors, paged mode off, or scrolling
			bne	_BCB1C				; barred then CB1C to exit

			lda	sysvar_SCREENLINES_SINCE_PAGE			; paged mode counter
			bmi	_BCB19				; if negative then exit via CB19

			lda	vduvar_TXT_CUR_Y			; current text line
			cmp	vduvar_TXT_WINDOW_BOTTOM			; bottom margin
			bcc	_BCB19				; increment line counter and exit

			lsr					; A=A/4
			lsr					; 
			sec					; set carry
			adc	sysvar_SCREENLINES_SINCE_PAGE			; paged mode counter
			adc	vduvar_TXT_WINDOW_TOP			; top of text window
			cmp	vduvar_TXT_WINDOW_BOTTOM			; bottom margin
			bcc	_BCB19				; increment line counter and exit

			clc					; clear carry
_BCB0E:			lda	#OSBYTE_118_SET_KEYBOARD_LEDS
			cop	COP_06_OPOSB			; osbyte 118 check keyboard status; set LEDs
			sec					; set carry
			bpl	_BCB0E				; if +ve result then loop till shift pressed

;**************** zero paged mode  counter *******************************

_LCB14:			lda	#$ff				; 
			sta	sysvar_SCREENLINES_SINCE_PAGE			; paged mode counter
_BCB19:			inc	sysvar_SCREENLINES_SINCE_PAGE			; paged mode counter
_BCB1C:			rts					; 

;********* intitialise VDU driver with MODE in A *************************
	; FAR call!
VDU_INIT:		php
			sep	#$30
			.a8
			.i8
			pea	0
			pld
			phd
			plb
			plb					; bank 0 / DPSYS

			pha					; Save MODE in A
			ldx	#$7f				; Prepare X=&7F for reset loop
			lda	#$00				; A=0
			sta	dp_mos_vdu_status		; Clear VDU status byte to set default conditions

__vdu_mode_init_loop:	sta	vduvars_start-1,X		; Zero VDU workspace at &300 to &37E
			dex					
			bne	__vdu_mode_init_loop		

			;;jsl	_OSBYTE_20			; Implode character definitions
			pla					; Get initial MODE back to A
			ldx	#$7f				; X=&7F
			stx	vduvar_MO7_CUR_CHAR		; MODE 7 copy cursor character (could have set this at CB1E)
			jsr	setMode

			; setup WRCHV vector native mode
			rep	#$30
			.a16
			.i16
			phb
			pea	0
			pld				
			phk
			plb
			lda	#.loword(_NVWRCH)
			ldx	#IX_WRCHV
			jsl	AddToVector
			plb			

			plp
			rtl
		
			.a8
			.i8

;********* enter here from VDU 22,n - MODE *******************************

setMode:		
;;			DEBUG_PRINTF "MODE %A\n"

			bit	sysvar_RAM_AVAIL		; Check available RAM
			bmi	_BCB3A				; If 32K, use all MODEs
			ora	#$04				; Only 16K available, force to use MODEs 4-7

_BCB3A:			and	#$07				; X=A and 7 ensure legal mode
			tax					; X=mode			
			stx	vduvar_MODE			; Save current screen MODE

			phk
			plb

			lda	_TBL_MODE_COLOURS,X		; Get number of colours -1 for this MODE
			sta	f:vduvar_COL_COUNT_MINUS1		; Set current number of logical colours less 1
			lda	_TXT_BPC_TABLE,X		; Get bytes/character for this MODE
			sta	f:vduvar_BYTES_PER_CHAR		; Set bytes per character
			lda	_TBL_VDU_PIXPB,X		; Get pixels/byte for this MODE
			sta	f:vduvar_PIXELS_PER_BYTE_MINUS1	; Set pixels per byte
			bne	_BCB56				; If non-zero, skip past
			lda	#$07				; byte/pixel=0, this is MODE 7, prepare A=7 offset into mask table

_BCB56:			asl					; A=A*2
			tay					; Y=A

			lda	_TAB_VDU_MASK_R,Y		; mask table
			sta	f:vduvar_RIGHTMOST_PIX_MASK	; colour mask left
_BCB5E:			asl					; A=A*2
			bpl	_BCB5E				; If still +ve CB5E
			sta	f:vduvar_LEFTMOST_PIX_MASK			; colour mask right
			lda	_TAB_MAP_TYPE,X			; screen display memory index table
			sta	f:vduvar_MODE_SIZE		; memory map type
			tay
			lda	_TAB_LAT5_MOSZ,Y		; VDU section control
			jsr	_WRITE_SYS_VIA_PORTB		; set hardware scrolling to VIA
			lda	_TAB_LAT4_MOSZ,Y		; VDU section control
			jsr	_WRITE_SYS_VIA_PORTB		; set hardware scrolling to VIA
			lda	_VDU_MEMSZ_TAB,Y		; Screen RAM size hi byte table
			sta	f:vduvar_SCREEN_SIZE_HIGH	; screen RAM size hi byte
			lda	_VDU_MEMLOC_TAB,Y		; screen ram address hi byte
			sta	f:vduvar_SCREEN_BOTTOM_HIGH	; hi byte of screen RAM address

			; translate mode map type (0=20K, 1=16K, 2=10k, 3=8K, 4=1K)
			; to index into 	0 => 3,C=1
			;			1 => 2,C=0
			;			2 => 1,C=1
			;			3 => 1,C=0
			;			4 => 0,C=1

			tya					; Y=A
			adc	#$02				; Add 2
			eor	#$07				; 
			lsr					; /2
			tax					; X=A
			lda	_TAB_MULTBL_LKUP_L,X		; row multiplication table pointer
			sta	z:dp_mos_vdu_mul		; store it
			lda	_TAB_MULTBL_LKUP_H,X		; row multiplication table pointer
			sta	z:dp_mos_vdu_mul+1		; store it (&E0) now points to C3B5 or C375

			lda	_TAB_BPR,X			; get nuber of bytes per row from table
			sta	vduvar_BYTES_PER_ROW		; store as bytes per character row

			stx	vduvar_BYTES_PER_ROW+1		; bytes per character row
			lda	#$43				; A=&43
			jsr	AND_VDU_STATUS			; A=A and &D0:&D0=A
			ldx	vduvar_MODE			; screen mode
			lda	_ULA_SETTINGS,X			; get video ULA control setting
			jsl	vduSetULACTL			; set video ULA using osbyte 154 code
			php					; push flags
			sei					; set interrupts
			ldx	_TAB_CRTCBYMOSZ,Y			; get cursor end register data from table
			ldy	#$0b				; Y=11


			pea	0
			plb
			plb

@lp:			lda	f:_CRTC_REG_TAB,X		; get end of 6845 registers 0-11 table
			jsr	SET_CRTC_YeqA			; set register Y
			dex					; reduce pointers
			dey					; 
			bpl	@lp				; and if still >0 do it again

			plp					; pull flags

			jsr	_VDU_20				; set default colours
			jsr	_VDU_26				; set default windows

_LCBC1_DOCLS:		ldx	#$00				; X=0
			lda	vduvar_SCREEN_BOTTOM_HIGH			; hi byte of screen RAM address
			stx	vduvar_6845_SCREEN_START				; window area start address lo
			sta	vduvar_6845_SCREEN_START+1			; window area start address hi
			jsr	SET_CRTC_CURSeqAX_adj		; use AX to set new cursor address
			ldy	#$0c				; Y=12
			jsr	SET_CRTC_YeqAX			; set registers 12 and 13 in CRTC


			php
			rep	#$10
			.i16
			lda	#0
			xba
			lda	vduvar_SCREEN_BOTTOM_HIGH
			xba
			tax					; set copy source
			txy
			iny					; set copy dest

			xba					; B=0
			lda	vduvar_TXT_BACK			; background text colour
			sta	f:$FF0000,X				
			lda	vduvar_SCREEN_SIZE_HIGH
			xba
			dec	A
			mvn	#$FF,#$FF			; CLS


			plp
			.i8

			ldx	#$00				; X=0
			stx	sysvar_SCREENLINES_SINCE_PAGE			; paged mode counter
			stx	vduvar_TXT_CUR_X			; text column
			stx	vduvar_TXT_CUR_Y			; current text line
			rts


;*************************************************************************
;*									 *
;*	 OSWORD 10 - READ CHARACTER DEFINITION				 *
;*									 *
;*************************************************************************
;&EF=A:&F0=X:&F1=Y, on entry YX contains character number to be read
;(&DE) points to address
;on exit byte YX+1 to YX+8 contain definition

_OSWORD_10:		jsr	_LD03E				; set up character definition pointers
			ldy	#$00				; Y=0
_BCBF8:			lda	(dp_mos_vdu_wksp+4),Y			; get first byte
			iny					; Y=Y+1
			sta	(dp_mos_OSBW_X),Y			; store it in YX
			cpy	#$08				; until Y=8
			bne	_BCBF8				; 
			rtl					; then exit



;****************** execute required function ****************************

;;;; TODO: make _VDU_JUMP work if called via emu mode!
;;;; TODO: this assumes only our module uses this address and is in same bank

_VDU_JUMP:		jmp	(vduvar_VDU_VEC_JMP)			; jump vector set up previously

;********* subtract bytes per line from X/A ******************************

_LCCF8:			pha					; Push A
			txa					; A=X
			sec					; set carry for subtraction
			sbc	vduvar_BYTES_PER_ROW				; bytes per character row
			tax					; restore X
			pla					; and A
			sbc	vduvar_BYTES_PER_ROW+1			; bytes per character row
			cmp	vduvar_SCREEN_BOTTOM_HIGH			; hi byte of screen RAM address
_BCD06:			rts					; return


;*************************************************************************
;*									 *
;*	 OSBYTE 20 - EXPLODE CHARACTERS					 *
;*									 *
;*************************************************************************

_OSBYTE_20:		lda	#$0f				; A=15
			sta	vduvar_EXPLODE_FLAGS		; font flag indicating that page &0C,&C0-&C2 are
								; used for user defined characters
			lda	#$0c				; A=&0C
			ldy	#$06				; set loop counter

_BCD10:			sta	vduvar_FONT_LOC32_63,Y		; set all font location bytes
			dey					; to page &0C to indicate only page available
			bpl	_BCD10				; for user character definitions

			cpx	#$07				; is X= 7 or greater
			bcc	_BCD1C				; if not CD1C
			ldx	#$06				; else X=6
_BCD1C:			stx	sysvar_EXPLODESTATUS		; character definition explosion switch
			lda	sysvar_PRI_OSHWM		; A=primary OSHWM
			ldx	#$00				; X=0

_BCD24:			cpx	sysvar_EXPLODESTATUS		; character definition explosion switch
			bcs	_BCD34				; 
			ldy	_LC4BA,X			; get soft character  RAM allocation
			sta	vduvar_FONT_LOC32_63,Y		; font location bytes
			adc	#$01				; Add 1
			inx					; X=X+1
			bne	_BCD24				; if X<>0 then CD24

_BCD34:			sta	sysvar_CUR_OSHWM		; current value of page (OSHWM)
			tay					; Y=A
			beq	_BCD06				; return via CD06 (ERROR?)

			ldx	#SERVICE_11_FONT_BANG		; X=&11
			lda	#OSBYTE_143_SERVICE_CALL
			cop	COP_06_OPOSB			; issue paged ROM service call &11
								; font implosion/explosion warning
			rtl


;******** move text cursor to next line **********************************

_LCD3F:			lda	#$02				; A=2 to check if scrolling disabled
			bit	dp_mos_vdu_status			; VDU status byte
			bne	_BCD47				; if scrolling is barred CD47
			bvc	_BCD79				; if cursor editing mode disabled RETURN

_BCD47:			lda	vduvar_TXT_WINDOW_BOTTOM			; bottom margin
			bcc	_BCD4F				; if carry clear on entry CD4F
			lda	vduvar_TXT_WINDOW_TOP			; else if carry set get top of text window
_BCD4F:			bvs	_BCD59				; and if cursor editing enabled CD59
			sta	vduvar_TXT_CUR_Y			; get current text line
			pla					; pull return link from stack
			pla					; 
			jmp	_LC6AF				; set up cursor and display address

_BCD59:			php					; push flags
			cmp	vduvar_TEXT_IN_CUR_Y			; Y coordinate of text input cursor
			beq	_BCD78				; if A=line count of text input cursor CD78 to exit
			plp					; get back flags
			bcc	_BCD66				; 
			dec	vduvar_TEXT_IN_CUR_Y			; Y coordinate of text input cursor

_BCD65:			rts					; exit

_BCD66:			inc	vduvar_TEXT_IN_CUR_Y			; Y coordinate of text input cursor
			rts					; exit

;*********************** set up write cursor ********************************

_LCD6A:			php					; save flags
			pha					; save A
			ldy	vduvar_BYTES_PER_CHAR				; bytes per character
			dey					; Y=Y-1
			bne	_BCD8F				; if Y=0 Mode 7 is in use

			lda	vduvar_GRA_WKSP+8			; so get mode 7 write character cursor character &7F
			sta	(dp_mos_vdu_top_scanline),Y		; store it at top scan line of current character
_LCD77:			pla					; pull A
_BCD78:			plp					; pull flags
_BCD79:			rts					; and exit

_LCD7A:			php					; push flags
			pha					; push A
			ldy	vduvar_BYTES_PER_CHAR				; bytes per character
			dey					; 
			bne	_BCD8F				; if not mode 7
			lda	(dp_mos_vdu_top_scanline),Y		; get cursor from top scan line
			sta	vduvar_GRA_WKSP+8			; store it
			lda	vduvar_MO7_CUR_CHAR			; mode 7 write cursor character
			sta	(dp_mos_vdu_top_scanline),Y		; store it at scan line
			jmp	_LCD77				; and exit

_BCD8F:			lda	#$ff				; A=&FF =cursor
			cpy	#$1f				; except in mode 2 (Y=&1F)
			bne	_BCD97				; if not CD97
			lda	#$3f				; load cursor byte mask

;********** produce white block write cursor *****************************

_BCD97:			sta	dp_mos_vdu_wksp			; store it
_BCD99:			lda	(dp_mos_vdu_top_scanline),Y		; get scan line byte
			eor	dp_mos_vdu_wksp			; invert it
			sta	(dp_mos_vdu_top_scanline),Y		; store it on scan line
			dey					; decrement scan line counter
			bpl	_BCD99				; do it again
			bmi	_LCD77				; then jump to &CD77

_LCDA4:			jsr	_LCE5B				; exchange line and column cursors with workspace copies
			lda	vduvar_TXT_WINDOW_BOTTOM			; bottom margin
			sta	vduvar_TXT_CUR_Y			; current text line
			jsr	_LCF06				; set up display address
_BCDB0:			jsr	_LCCF8				; subtract bytes per character row from this
			bcs	_BCDB8				; wraparound if necessary
			adc	vduvar_SCREEN_SIZE_HIGH			; screen RAM size hi byte
_BCDB8:			sta	dp_mos_vdu_wksp+1			; store A
			stx	dp_mos_vdu_wksp			; X
			sta	dp_mos_vdu_wksp+2			; A again
			bcs	_BCDC6				; if C set there was no wraparound so CDC6
_BCDC0:			jsr	_LCE73				; copy line to new position
								; using (&DA) for read
								; and (&D8) for write
			jmp	_LCDCE				; 

_BCDC6:			jsr	_LCCF8				; subtract bytes per character row from X/A
			bcc	_BCDC0				; if a result is outside screen RAM CDC0
			jsr	_LCE38				; perform a copy

_LCDCE:			lda	dp_mos_vdu_wksp+2			; set write pointer from read pointer
			ldx	dp_mos_vdu_wksp			; 
			sta	dp_mos_vdu_top_scanline+1			; 
			stx	dp_mos_vdu_top_scanline			; 
			dec	dp_mos_vdu_wksp+4			; decrement window height
			bne	_BCDB0				; and if not zero CDB0
_LCDDA_EXG_BMPR_CURS_X:	ldx	#<vduvar_TEMP_8		; point to workspace
			ldy	#<vduvar_TXT_CUR_X			; point to text column/line
_LCDDE_EXG2_P3:		lda	#$02				; number of bytes to swap
			bne	_BCDE8				; exchange (328/9)+Y with (318/9)+X
_LCDE2:			ldx	#<vduvar_GRA_CUR_INT			; point to graphics cursor
_LCDE4:			ldy	#<vduvar_GRA_CUR_EXT+3+1		; point to last graphics cursor
								; A=4 to swap X and Y coordinates

;*************** exchange 300/3+Y with 300/3+X ***************************

_LCDE6_EXG4_P3:		lda	#$04				; A =4

;************** exchange (300/300+A)+Y with (300/300+A)+X *****************

_BCDE8:			sta	dp_mos_vdu_wksp			; store it as loop counter

_BCDEA:			lda	vduvar_GRA_WINDOW_LEFT,X			; get byte
			pha					; store it
			lda	vduvar_GRA_WINDOW_LEFT,Y			; get byte pointed to by Y
			sta	vduvar_GRA_WINDOW_LEFT,X			; put it in 300+X
			pla					; get back A
			sta	vduvar_GRA_WINDOW_LEFT,Y			; put it in 300+Y
			inx					; increment pointers
			iny					; 
			dec	dp_mos_vdu_wksp			; decrement loop counter
			bne	_BCDEA				; and if not 0 do it again
			rts					; and exit

;******** execute upward scroll ******************************************


_LCDFF:			jsr	_LCE5B				; exchange line and column cursors with workspace copies
			ldy	vduvar_TXT_WINDOW_TOP			; top of text window
			sty	vduvar_TXT_CUR_Y			; current text line
			jsr	_LCF06				; set up display address
_BCE0B:			jsr	_LCAD4				; add bytes per char. row
			bpl	_BCE14				; 
			sec					; 
			sbc	vduvar_SCREEN_SIZE_HIGH			; screen RAM size hi byte

_BCE14:			sta	dp_mos_vdu_wksp+1			; (&DA)=X/A
			stx	dp_mos_vdu_wksp			; 
			sta	dp_mos_vdu_wksp+2			; &DC=A
			bcc	_BCE22				; 
_BCE1C:			jsr	_LCE73				; copy line to new position
								; using (&DA) for read
								; and (&D8) for write
			jmp	_LCE2A				; exit


_BCE22:			jsr	_LCAD4				; add bytes per char. row
			bmi	_BCE1C				; if outside screen RAM CE1C
			jsr	_LCE38				; perform a copy
_LCE2A:			lda	dp_mos_vdu_wksp+2			; 
			ldx	dp_mos_vdu_wksp			; 
			sta	dp_mos_vdu_top_scanline+1			; 
			stx	dp_mos_vdu_top_scanline			; 
			dec	dp_mos_vdu_wksp+4			; decrement window height
			bne	_BCE0B				; CE0B if not 0
			beq	_LCDDA_EXG_BMPR_CURS_X				; exchange text column/linelse CDDA


;*********** copy routines ***********************************************

_LCE38:			ldx	vduvar_TXT_WINDOW_WIDTH_BYTES+1			; text window width hi (bytes)
			beq	_BCE4D				; if no more than 256 bytes to copy X=0 so CE4D

			ldy	#$00				; Y=0 to set loop counter

_BCE3F:			lda	(dp_mos_vdu_wksp),Y			; copy 256 bytes
			sta	(dp_mos_vdu_top_scanline),Y		; 
			iny					; 
			bne	_BCE3F				; Till Y=0 again
			inc	dp_mos_vdu_top_scanline+1			; increment hi bytes
			inc	dp_mos_vdu_wksp+1			; 
			dex					; decrement window width
			bne	_BCE3F				; if not 0 go back and do loop again

_BCE4D:			ldy	vduvar_TXT_WINDOW_WIDTH_BYTES			; text window width lo (bytes)
			beq	_BCE5A				; if Y=0 CE5A

_BCE52:			dey					; else Y=Y-1
			lda	(dp_mos_vdu_wksp),Y			; copy Y bytes
			sta	(dp_mos_vdu_top_scanline),Y		; 
			tya					; A=Y
			bne	_BCE52				; if not 0 CE52
_BCE5A:			rts					; and exit


_LCE5B:			jsr	_LCDDA_EXG_BMPR_CURS_X				; exchange text column/line with workspace
			sec					; set carry
			lda	vduvar_TXT_WINDOW_BOTTOM			; bottom margin
			sbc	vduvar_TXT_WINDOW_TOP			; top of text window
			sta	dp_mos_vdu_wksp+4			; store it
			bne	_LCE6E				; set text column to left hand column
			pla					; get back return address
			pla					; 
			jmp	_LCDDA_EXG_BMPR_CURS_X				; exchange text column/line with workspace

_LCE6E:			lda	vduvar_TXT_WINDOW_LEFT			; text window left
			bpl	_BCEE3				; Jump CEE3 always!

_LCE73:			lda	dp_mos_vdu_wksp			; get back A
			pha					; push A
			sec					; set carry
			lda	vduvar_TXT_WINDOW_RIGHT			; text window right
			sbc	vduvar_TXT_WINDOW_LEFT			; text window left
			sta	dp_mos_vdu_wksp+5			; 
_BCE7F:			ldy	vduvar_BYTES_PER_CHAR				; bytes per character to set loop counter

			dey					; copy loop
_BCE83:			lda	(dp_mos_vdu_wksp),Y			; 
			sta	(dp_mos_vdu_top_scanline),Y		; 
			dey					; 
			bpl	_BCE83				; 

			ldx	#$02				; X=2
_BCE8C:			clc					; clear carry
			lda	dp_mos_vdu_top_scanline,X			; 
			adc	vduvar_BYTES_PER_CHAR				; bytes per character
			sta	dp_mos_vdu_top_scanline,X			; 
			lda	dp_mos_vdu_top_scanline+1,X		; 
			adc	#$00				; 
			bpl	_BCE9E				; if this remains in screen RAM OK

			sec					; else wrap around screen
			sbc	vduvar_SCREEN_SIZE_HIGH			; screen RAM size hi byte
_BCE9E:			sta	dp_mos_vdu_top_scanline+1,X		; 
			dex					; X=X-2
			dex					; 
			beq	_BCE8C				; if X=0 adjust second set of pointers
			dec	dp_mos_vdu_wksp+5			; decrement window width
			bpl	_BCE7F				; and if still +ve do it all again
			pla					; get back A
			sta	dp_mos_vdu_wksp			; and store it
			rts					; then exit

;*********** clear a line ************************************************

_LCEAC:			lda	vduvar_TXT_CUR_X		; text column
			pha					; save it
			jsr	_LCE6E				; set text column to left hand column
			jsr	_LCF06				; set up display address
			sec					; set carry
			lda	vduvar_TXT_WINDOW_RIGHT		; text window right
			sbc	vduvar_TXT_WINDOW_LEFT		; text window left
			sta	dp_mos_vdu_wksp+2		; as window width
_BCEBF:			lda	vduvar_TXT_BACK			; background text colour
			ldy	vduvar_BYTES_PER_CHAR		; bytes per character

			phb
			phk
			plb
_BCEC5:			dey					; Y=Y-1 decrementing loop counter
			sta	(dp_mos_vdu_top_scanline),Y	; store background colour at this point on screen
			bne	_BCEC5				; if Y<>0 do it again
			plb
			txa					; else A=X
			clc					; clear carry to add
			adc	vduvar_BYTES_PER_CHAR		; bytes per character
			tax					; X=A restoring it
			lda	dp_mos_vdu_top_scanline+1	; get hi byte
			adc	#$00				; Add carry if any
			bpl	_BCEDA				; if +ve CeDA
			sec					; else wrap around
			sbc	vduvar_SCREEN_SIZE_HIGH		; screen RAM size hi byte






_BCEDA:			stx	dp_mos_vdu_top_scanline			; restore D8/9
			sta	dp_mos_vdu_top_scanline+1			; 
			dec	dp_mos_vdu_wksp+2			; decrement window width
			bpl	_BCEBF				; ind if not 0 do it all again
			pla					; get back A
_BCEE3:			sta	vduvar_TXT_CUR_X			; restore text column
_BCEE6:			sec					; set carry
			rts					; and exit


_LCEE8:			ldx	vduvar_TXT_CUR_X			; text column
			cpx	vduvar_TXT_WINDOW_LEFT			; text window left
			bmi	_BCEE6				; if less than left margin return with carry set
			cpx	vduvar_TXT_WINDOW_RIGHT			; text window right
			beq	_BCEF7				; if equal to right margin thats OK
			bpl	_BCEE6				; if greater than right margin return with carry set

_BCEF7:			ldx	vduvar_TXT_CUR_Y			; current text line
			cpx	vduvar_TXT_WINDOW_TOP			; top of text window
			bmi	_BCEE6				; if less than top margin
			cpx	vduvar_TXT_WINDOW_BOTTOM			; bottom margin
			beq	_LCF06				; set up display address
			bpl	_BCEE6				; or greater than bottom margin return with carry set



;************:set up display address *************************************

;Mode 0: (0319)*640+(0318)* 8
;Mode 1: (0319)*640+(0318)*16
;Mode 2: (0319)*640+(0318)*32
;Mode 3: (0319)*640+(0318)* 8
;Mode 4: (0319)*320+(0318)* 8
;Mode 5: (0319)*320+(0318)*16
;Mode 6: (0319)*320+(0318)* 8
;Mode 7: (0319)* 40+(0318)
;this gives a displacement relative to the screen RAM start address
;which is added to the calculated number and stored in in 34A/B
;if the result is less than &8000, the top of screen RAM it is copied into X/A
;and D8/9.
;if the result is greater than &7FFF the hi byte of screen RAM size is
;subtracted to wraparound the screen. X/A, D8/9 are then set from this

_LCF06:			lda	vduvar_TXT_CUR_Y		; current text line
			asl					; A=A*2
			tay					; Y=A
			phb
			phk
			plb
			lda	(dp_mos_vdu_mul),Y		; get CRTC multiplication table pointer
			sta	z:dp_mos_vdu_top_scanline+1	; &D9=A
			iny					; Y=Y+1
			lda	(dp_mos_vdu_mul),Y		; get CRTC multiplication table pointer
			plb
			pha
			lda	vduvar_MODE_SIZE		; memory map type
			ror	A
			ror	A
			pla
			bcc	_BCF1E				; 
			lsr	z:dp_mos_vdu_top_scanline+1	; &D9=&D9/2
			ror	A				; A=A/2 +(128*carry)
_BCF1E:			adc	vduvar_6845_SCREEN_START	; window area start address lo
			sta	dp_mos_vdu_top_scanline		; store it
			lda	dp_mos_vdu_top_scanline+1	; 
			adc	vduvar_6845_SCREEN_START+1	; window area start address hi
			tay					; 
			lda	vduvar_TXT_CUR_X		; text column
			ldx	vduvar_BYTES_PER_CHAR		; bytes per character
			dex					; X=X-1
			beq	_BCF44				; if X=0 mode 7 CF44
			cpx	#$0f				; is it mode 1 or mode 5?
			beq	_BCF39				; yes CF39 with carry set
			bcc	_BCF3A				; if its less (mode 0,3,4,6) CF3A
			asl					; A=A*16 if entered here (mode 2)

_BCF39:			asl					; A=A*8 if entered here

_BCF3A:			asl					; A=A*4 if entered here
			asl					; 
			bcc	_BCF40				; if carry clear
			iny					; Y=Y+2
			iny					; 
_BCF40:			asl					; A=A*2
			bcc	_BCF45				; if carry clear add to &D8
			iny					; if not Y=Y+1

_BCF44:			clc					; clear carry
_BCF45:			adc	dp_mos_vdu_top_scanline		; add to &D8
			sta	dp_mos_vdu_top_scanline		; and store it
			sta	vduvar_6845_CURSOR_ADDR		; text cursor 6845 address
			tax					; X=A
			tya					; A=Y
			adc	#$00				; Add carry if set
			sta	vduvar_6845_CURSOR_ADDR+1		; text cursor 6845 address
			bpl	_BCF59				; if less than &800 goto &CF59
			sec					; else wrap around
			sbc	vduvar_SCREEN_SIZE_HIGH		; screen RAM size hi byte

_BCF59:			sta	dp_mos_vdu_top_scanline+1	; store in high byte
			clc					; clear carry
			rts					; and exit


;******** Graphics cursor display routine ********************************

_BCF5D:			ldx	vduvar_GRA_FORE			; foreground graphics colour
			ldy	vduvar_GRA_PLOT_FORE		; foreground graphics plot mode (GCOL n)
_LCF63:			jsr	_LD0B3				; set graphics byte mask in &D4/5
			jsr	_LD486				; copy (324/7) graphics cursor to workspace (328/B)
			ldy	#$00				; Y=0
_BCF6B:			sty	dp_mos_vdu_wksp+2		; &DC=Y
			ldy	dp_mos_vdu_wksp+2		; Y=&DC
			lda	(dp_mos_vdu_wksp+4),Y		; get pattern byte
			beq	_BCF86				; if A=0 CF86
			sta	dp_mos_vdu_wksp+3		; else &DD=A
_BCF75:			bpl	_BCF7A				; and if >0 CF7A
			jsr	_LD0E3				; else display a pixel
_BCF7A:			inc	vduvar_GRA_CUR_INT		; current horizontal graphics cursor
			bne	_BCF82				; 
			inc	vduvar_GRA_CUR_INT+1		; current horizontal graphics cursor

_BCF82:			asl	dp_mos_vdu_wksp+3		; &DD=&DD*2
			bne	_BCF75				; and if<>0 CF75
_BCF86:			ldx	#$28				; point to workspace
			ldy	#$24				; point to horizontal graphics cursor
			jsr	_LD482				; 0300/1+Y=0300/1+X
			ldy	vduvar_GRA_CUR_INT+2		; current vertical graphics cursor
			bne	_BCF95				; 
			dec	vduvar_GRA_CUR_INT+3		; current vertical graphics cursor
_BCF95:			dec	vduvar_GRA_CUR_INT+2		; current vertical graphics cursor
			ldy	dp_mos_vdu_wksp+2		; 
			iny					; 
			cpy	#$08				; if Y<8 then do loop again
			bne	_BCF6B				; else
			ldx	#$28				; point to workspace
			ldy	#$24				; point to graphics cursor
			jmp	_LD48A				; (&300/3+Y)=(&300/3+X)


;*********** home graphics cursor ***************************************

_LCFA6:			ldx	#$06				; point to graphics window TOP
			ldy	#$26				; point to workspace
			jsr	_LD482				; 0300/1+Y=0300/1+X


;************* set graphics cursor to left hand column *******************

_LCFAD:			ldx	#$00				; X=0 point to graphics window left
			ldy	#$24				; Y=&24
			jsr	_LD482				; 0300/1+Y=0300/1+X
			jmp	_LD1B8				; set up external coordinates for graphics

;************* Character rendering routine *******************

_VDU_OUT_CHAR:		ldx	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			beq	_VDU_OUT_MODE7			; if MODE 7 CFDC

			jsr	_LD03E				; set up character definition pointers
_LCFBF:			ldx	vduvar_COL_COUNT_MINUS1		; number of logical colours less 1
			lda	dp_mos_vdu_status		; VDU status byte
			and	#$20				; and out bit 5 printing at graphics cursor
			bne	_BCF5D				; if set CF5D
			ldy	#$07				; else Y=7

			phb
			phk
			plb					; TODO: assume FONT/Screen in same bank

			cpx	#$03				; if X=3
			beq	_VDU_OUT_COL4			; goto CFEE to handle 4 colour modes
			bcs	_VDU_OUT_COL16			; else if X>3 D01E to deal with 16 colours

_VDU_OUT_COL2:		lda	(dp_mos_vdu_wksp+4),Y		; get pattern byte
			ora	z:dp_mos_vdu_txtcolourOR	; text colour byte to be orred or EORed into memory
			eor	z:dp_mos_vdu_txtcolourEOR	; text colour byte to be orred or EORed into memory
			sta	(dp_mos_vdu_top_scanline),Y	; write to screen
			dey					; Y=Y-1
			bpl	_VDU_OUT_COL2			; if still +ve do loop again
			plb
			rts					; and exit

;******* convert teletext characters *************************************
;mode 7
_VDU_OUT_MODE7:		phb
			phk
			plb
			ldy	#$02				; Y=2
__mode7_xlate_loop:	cmp	_TELETEXT_CHAR_TAB,Y		; compare with teletext conversion table
			beq	__mode7_xlate_char		; if equal then CFE9
			dey					; else Y=Y-1
			bpl	__mode7_xlate_loop		; and if +ve CFDE

__mode7_out_char:	sta	(dp_mos_vdu_top_scanline)	; if not write byte to screen
			plb
			rts					; and exit

__mode7_xlate_char:	lda	_TELETEXT_CHAR_TAB+1,Y	; convert with teletext conversion table
			bne	__mode7_out_char		; and write it


;***********four colour modes ********************************************

_VDU_OUT_COL4:		
@lp:
			;;TODO: assumes font in bank FF and this code in FF and screen in FF!
			lda	(dp_mos_vdu_wksp+4),Y		; get pattern byte
			pha					; save it
			lsr					; move hi nybble to lo
			lsr					; 
			lsr					; 
			lsr					; 
			tax					; X=A
			lda	_COL16_MASK_TAB,X		; 4 colour mode byte mask look up table
			ora	z:dp_mos_vdu_txtcolourOR	; text colour byte to be orred or EORed into memory
			eor	z:dp_mos_vdu_txtcolourEOR	; text colour byte to be orred or EORed into memory
			sta	(dp_mos_vdu_top_scanline),Y	; write to screen
			tya					; A=Y

			clc					; clear carry
			adc	#$08				; add 8 to move screen RAM pointer 8 bytes
			tay					; Y=A
			pla					; get back A
			and	#$0f				; clear high nybble
			tax					; X=A
			lda	_COL16_MASK_TAB,X		; 4 colour mode byte mask look up table
			ora	z:dp_mos_vdu_txtcolourOR	; text colour byte to be orred or EORed into memory
			eor	z:dp_mos_vdu_txtcolourEOR	; text colour byte to be orred or EORed into memory
			sta	(dp_mos_vdu_top_scanline),Y	; write to screen
			tya					; A=Y
			sbc	#$08				; A=A-9
			tay					; Y=A
			bpl	@lp				; if +ve do loop again
_BD017:			plb
			rts					; exit



_BD018:			tya					; Y=Y-&21
			sbc	#$21				; 
			bmi	_BD017				; IF Y IS negative then RETURN
			tay					; else A=Y

;******* 16 COLOUR MODES *************************************************

_VDU_OUT_COL16:		lda	(dp_mos_vdu_wksp+4),Y		; get pattern byte
			sta	z:dp_mos_vdu_wksp+2		; store it
			sec					; set carry
_BD023:			lda	#$00				; A=0
			rol	z:dp_mos_vdu_wksp+2		; carry now occupies bit 0 of DC
			beq	_BD018				; when DC=0 again D018 to deal with next pattern byte
			rol					; get bit 7 from &DC into A bit 0
			asl	z:dp_mos_vdu_wksp+2		; rotate again to get second
			rol					; bit into A
			tax					; and store result in X
			lda	_COL4_MASK_TAB,X		; multiply by &55 using look up table
			ora	z:dp_mos_vdu_txtcolourOR	; and set colour factors
			eor	z:dp_mos_vdu_txtcolourEOR	; 
			sta	(dp_mos_vdu_top_scanline),Y	; and store result
			clc					; clear carry
			tya					; Y=Y+8 moving screen RAM pointer on 8 bytes
			adc	#$08				; 
			tay					; 
			bra	_BD023				; iloop to D023 to deal with next bit pair


;************* calculate pattern address for given code ******************
;A contains code on entry = 12345678

_LD03E:			asl					; 23456780  C holds 1
			rol					; 34567801  C holds 2
			rol					; 45678012  C holds 3
			sta	z:dp_mos_vdu_wksp+4		; save this pattern
			and	#$03				; 00000012
			rol					; 00000123 C=0
			tax					; X=A=0 - 7
			and	#$03				; A=00000023
			adc	#$bf				; A=&BF,C0 or C1
			tay					; this is used as a pointer
			lda	f:_LC40D,X			; A=&80/2^X i.e.1,2,4,8,&10,&20,&40, or &80
			bit	vduvar_EXPLODE_FLAGS		; with font flag
			beq	_BD057				; if 0 D057
			ldy	vduvar_EXPLODE_FLAGS,X		; else get hi byte from table
_BD057:			sty	dp_mos_vdu_wksp+5		; store Y
			lda	dp_mos_vdu_wksp+4		; get back pattern
			and	#$f8				; convert to 45678000
			sta	dp_mos_vdu_wksp+4		; and re store it
			rts					; exit
								;
;*************************************************************************
;*************************************************************************
;**									 **
;**									 **
;**	 PLOT ROUTINES ENTER HERE					 **
;**									 **
;**									 **
;*************************************************************************
;*************************************************************************
;on entry    ADDRESS	PARAMETER	 DESCRIPTION
;	    031F    1		    plot type
;	    0320/1  2,3		    X coordinate
;	    0322/3  4,5		    Y coordinate

_LD060:			ldx	#$20				; X=&20
			jsr	_LD14D				; translate coordinates

			lda	vduvar_VDU_Q_START+4		; get plot type
			cmp	#$04				; if its 4
			beq	_LD0D9				; D0D9 move absolute
			ldy	#$05				; Y=5
			and	#$03				; mask only bits 0 and 1
			beq	_BD080				; if result is 0 then its a move (multiple of 8)
			lsr					; else move bit 0 int C
			bcs	_BD078				; if set then D078 graphics colour required
			dey					; Y=4
			bne	_BD080				; logic inverse colour must be wanted

;******** graphics colour wanted *****************************************

_BD078:			tax					; X=A if A=0 its a foreground colour 1 its background
			ldy	vduvar_GRA_PLOT_FORE,X		; get fore or background graphics PLOT mode
			lda	vduvar_GRA_FORE,X		; get fore or background graphics colour
			tax					; X=A

_BD080:			jsr	_LD0B3				; set up colour masks in D4/5

			lda	vduvar_VDU_Q_START+4		; get plot type
			bmi	_BD0AB				; if &80-&FF then D0AB type not implemented
			asl					; bit 7=bit 6
			bpl	_BD0C6				; if bit 6 is 0 then plot type is 0-63 so D0C6
			and	#$f0				; else mask out lower nybble
			asl					; shift old bit 6 into C bit old 5 into bit 7
			beq	_BD0D6				; if 0 then type 64-71 was called single point plot
								; goto D0D6
			eor	#$40				; if bit 6 NOT set type &80-&87 fill triangle
			beq	_BD0A8				; so D0A8
			pha					; else push A
			jsr	_LD0DC				; copy 0320/3 to 0324/7 setting XY in current graphics
								; coordinates
			pla					; get back A
			eor	#$60				; if BITS 6 and 5 NOT SET type 72-79 lateral fill
			beq	_BD0AE				; so D0AE
			cmp	#$40				; if type 88-95 horizontal line blanking
			bne	_BD0AB				; so D0AB

			lda	#$02				; else A=2
			sta	dp_mos_vdu_wksp+2		; store it
			jmp	_LD506				; and jump to D506 type not implemented

_BD0A8:			jmp	_LD5EA				; to fill triangle routine

_BD0AB:			jmp	_LC938				; VDU extension access entry

_BD0AE:			sta	dp_mos_vdu_wksp+2		; store A
			jmp	_LD4BF				; 

;*********:set colour masks **********************************************
;graphics mode in Y
;colour in X

_LD0B3:			phb
			phk
			plb
			txa					; A=X
			ora	_LC41C,Y			; or with GCOL plot options table byte
			eor	_LC41D,Y			; EOR with following byte
			sta	dp_mos_vdu_gracolourOR		; and store it
			txa					; A=X
			ora	_LC41B,Y			; 
			eor	_LC420,Y			; 
			sta	dp_mos_vdu_gracolourEOR		; 
			plb
			rts					; exit with masks in &D4/5


;************** analyse first parameter in 0-63 range ********************
				;
_BD0C6:			asl					; shift left again
			bmi	_BD0AB				; if -ve options are in range 32-63 not implemented
			asl					; shift left twice more
			asl					; 
			bpl	_BD0D0				; if still +ve type is 0-7 or 16-23 so D0D0
			jsr	_LD0EB				; else display a point

_BD0D0:			jsr	_LD1ED				; perform calculations
			jmp	_LD0D9				; 


;*************************************************************************
;*									 *
;*	 PLOT A SINGLE POINT						 *
;*									 *
;*************************************************************************

_BD0D6:			jsr	_LD0EB				; display a point
_LD0D9:			jsr	_LCDE2				; swap current and last graphics position
_LD0DC:			ldy	#$24				; Y=&24
_LD0DE:			ldx	#$20				; X=&20
			jmp	_LD48A				; copy parameters to 324/7 (300/3 +Y)


_LD0E3:			ldx	#$24				; 
			jsr	_LD85F				; calculate position
			beq	_LD0F0				; if result =0 then D0F0
			rts					; else exit
								;
_LD0EB:			jsr	_LD85D				; calculate position
			bne	_BD103				; if A<>0 D103 and return
_LD0F0:			ldy	vduvar_GRA_CUR_CELL_LINE	; else get current graphics scan line
_LD0F3:			
			phb
			phk
			plb

			lda	dp_mos_vdu_grpixmask		; pick up and modify screen byte
			and	dp_mos_vdu_gracolourOR		; 
			ora	(dp_mos_vdu_gra_char_cell),Y	; 
			sta	dp_mos_vdu_wksp			; 
			lda	dp_mos_vdu_gracolourEOR		; 
			and	dp_mos_vdu_grpixmask		; 
			eor	dp_mos_vdu_wksp			; 
			sta	(dp_mos_vdu_gra_char_cell),Y	; put it back again
			plb
_BD103:			rts					; and exit
								;

_LD104:			phb
			phk
			plb
			lda	(dp_mos_vdu_gra_char_cell),Y	; this is a more simplistic version of the above
			ora	dp_mos_vdu_gracolourOR		; 
			eor	dp_mos_vdu_gracolourEOR		; 
			sta	(dp_mos_vdu_gra_char_cell),Y		; 
			plb
			rts					; and exit



;************************** Check window limits *************************
				;

_LD10D:			ldx	#$24				; X=&24
_LD10F:			ldy	#$00				; Y=0
			sty	dp_mos_vdu_wksp			; &DA=0
			ldy	#$02				; Y=2
			jsr	_LD128				; check vertical graphics position 326/7
								; bottom and top margins 302/3, 306/7
			asl	dp_mos_vdu_wksp			; DATA is set in &DA bits 0 and 1 then shift left
			asl	dp_mos_vdu_wksp			; twice to make room for next pass
			dex					; X=&22
			dex					; 
			ldy	#$00				; Y=0
			jsr	_LD128				; left and right margins 300/1, 304/5
								; cursor horizontal position 324/5
			inx					; X=X+2
			inx					; 
			lda	dp_mos_vdu_wksp			; A=&DA
			rts					; exit

;*** cursor and margins check ******************************************
				;
_LD128:			lda	vduvar_GRA_WINDOW_BOTTOM,X			; check for window violation
			cmp	vduvar_GRA_WINDOW_LEFT,Y			; 300/1 +Y > 302/3+X
			lda	vduvar_GRA_WINDOW_BOTTOM+1,X		; then window fault
			sbc	vduvar_GRA_WINDOW_LEFT+1,Y		; 
			bmi	_BD146				; so D146

			lda	vduvar_GRA_WINDOW_RIGHT,Y			; check other windows
			cmp	vduvar_GRA_WINDOW_BOTTOM,X			; 
			lda	vduvar_GRA_WINDOW_RIGHT+1,Y		; 
			sbc	vduvar_GRA_WINDOW_BOTTOM+1,X		; 
			bpl	_BD148				; if no violation exit
			inc	dp_mos_vdu_wksp			; else DA=DA+1

_BD146:			inc	dp_mos_vdu_wksp			; DA=DA+1
_BD148:			rts					; and exit  DA=0 no problems DA=1 first check 2, 2nd

;***********set up and adjust positional data ****************************

_LD149:			lda	#$ff				; A=&FF
			bne	_BD150				; then &D150

_LD14D:			lda	vduvar_VDU_Q_START+4			; get first parameter in plot

_BD150:			sta	dp_mos_vdu_wksp			; store in &DA
			ldy	#$02				; Y=2
			jsr	_LD176				; set up vertical coordinates/2
			jsr	_LD1AD				; /2 again to convert 1023 to 0-255 for internal use
								; this is why minimum vertical plot separation is 4
			ldy	#$00				; Y=0
			dex					; X=x-2
			dex					; 
			jsr	_LD176				; set up horiz. coordinates/2 this is OK for mode0,4
			ldy	vduvar_PIXELS_PER_BYTE_MINUS1			; get number of pixels/byte (-1)
			cpy	#$03				; if Y=3 (modes 1 and 5)
			beq	_BD16D				; D16D
			bcs	_BD170				; for modes 0 & 4 this is 7 so D170
			jsr	_LD1AD				; for other modes divide by 2 twice

_BD16D:			jsr	_LD1AD				; divide by 2
_BD170:			lda	vduvar_MODE_SIZE			; get screen display type
			bne	_LD1AD				; if not 0 (modes 3-7) divide by 2 again
			rts					; and exit

;for mode 0 1 division	1280 becomes 640 = horizontal resolution
;for mode 1 2 divisions 1280 becomes 320 = horizontal resolution
;for mode 2 3 divisions 1280 becomes 160 = horizontal resolution
;for mode 4 2 divisions 1280 becomes 320 = horizontal resolution
;for mode 5 3 divisions 1280 becomes 160 = horizontal resolution

;********** calculate external coordinates in internal format ***********
;on entry X is usually &1E or &20

_LD176:			clc					; clear carry
			lda	dp_mos_vdu_wksp			; get &DA
			and	#$04				; if bit 2=0
			beq	_BD186				; then D186 to calculate relative coordinates
			lda	vduvar_GRA_WINDOW_BOTTOM,X			; else get coordinate
			pha					; 
			lda	vduvar_GRA_WINDOW_BOTTOM+1,X		; 
			bcc	_BD194				; and goto D194

_BD186:			lda	vduvar_GRA_WINDOW_BOTTOM,X			; get coordinate
			adc	vduvar_GRA_CUR_EXT,Y			; add cursor position
			pha					; save it
			lda	vduvar_GRA_WINDOW_BOTTOM+1,X		; 
			adc	vduvar_GRA_CUR_EXT+1,Y		; add cursor
			clc					; clear carry

_BD194:			sta	vduvar_GRA_CUR_EXT+1,Y		; save new cursor
			adc	vduvar_GRA_ORG_EXT+1,Y		; add graphics origin
			sta	vduvar_GRA_WINDOW_BOTTOM+1,X		; store it
			pla					; get back lo byte
			sta	vduvar_GRA_CUR_EXT,Y			; save it in new cursor lo
			clc					; clear carry
			adc	vduvar_GRA_ORG_EXT,Y			; add to graphics orgin
			sta	vduvar_GRA_WINDOW_BOTTOM,X			; store it
			bcc	_LD1AD				; if carry set
			inc	vduvar_GRA_WINDOW_BOTTOM+1,X	; increment hi byte as you would expect!

_LD1AD:			lda	vduvar_GRA_WINDOW_BOTTOM+1,X	; get hi byte
			asl					; 
			ror	vduvar_GRA_WINDOW_BOTTOM+1,X	; divide by 2
			ror	vduvar_GRA_WINDOW_BOTTOM,X	; 
			rts					; and exit

;***** calculate external coordinates from internal coordinates************

_LD1B8:			ldy	#$10				; Y=10
			jsr	_LD488				; copy 324/7 to 310/3 i.e.current graphics cursor
								; position to position in external values
			ldx	#$02				; X=2
			ldy	#$02				; Y=2
			jsr	_LD1D5				; multiply 312/3 by 4 and subtract graphics origin
			ldx	#$00				; X=0
			ldy	#$04				; Y=4
			lda	vduvar_PIXELS_PER_BYTE_MINUS1	; get  number of pixels/byte
_BD1CB:			dey					; Y=Y-1
			lsr					; divide by 2
			bne	_BD1CB				; if result not 0 D1CB
			lda	vduvar_MODE_SIZE		; else get screen display type
			beq	_LD1D5				; and if 0 D1D5
			iny					; 

_LD1D5:			asl	vduvar_GRA_CUR_EXT,X		; multiply coordinate by 2
			rol	vduvar_GRA_CUR_EXT+1,X		; 
			dey					; Y-Y-1
			bne	_LD1D5				; and if Y<>0 do it again
			sec					; set carry
			jsr	_LD1E3				; 
			inx					; increment X

_LD1E3:			lda	vduvar_GRA_CUR_EXT,X		; get current graphics position in external coordinates
			sbc	vduvar_GRA_ORG_EXT,X		; subtract origin
			sta	vduvar_GRA_CUR_EXT,X		; store in graphics position
			rts					; and exit

;************* compare X and Y PLOT spans ********************************

_LD1ED:			jsr	_LD40D				; Set X and Y spans in workspace 328/9 32A/B
			lda	vduvar_TEMP_8+3			; compare spans
			eor	vduvar_TEMP_8+1			; if result -ve spans are different in sign so
			bmi	_BD207				; goto D207
			lda	vduvar_TEMP_8+2			; else A=hi byte of difference in spans
			cmp	vduvar_TEMP_8			; 
			lda	vduvar_TEMP_8+3			; 
			sbc	vduvar_TEMP_8+1			; 
			jmp	_LD214				; and goto D214

_BD207:			lda	vduvar_TEMP_8			; A = hi byte of SUM of spans
			clc					; 
			adc	vduvar_TEMP_8+2			; 
			lda	vduvar_TEMP_8+1			; 
			adc	vduvar_TEMP_8+3			; 

_LD214:			ror					; A=A/2
			ldx	#$00				; X=0
			eor	vduvar_TEMP_8+3			; 
			bpl	_BD21E				; if positive result D21E

			ldx	#$02				; else X=2

_BD21E:			stx	dp_mos_vdu_wksp+4		; store it
			lda	f:_LC4AA,X			; set up vector address
			sta	vduvar_VDU_VEC_JMP		; in 35D
			lda	f:_LC4AA + 1,X			; 
			sta	vduvar_VDU_VEC_JMP+1		; and 35E
			lda	vduvar_TEMP_8+1,X		; get hi byte of span
			bpl	_BD235				; if +ve D235
			ldx	#$24				; X=&24
			bne	_BD237				; jump to D237

_BD235:			ldx	#$20				; X=&20
_BD237:			stx	dp_mos_vdu_wksp+5		; store it
			ldy	#$2c				; Y=&2C
			jsr	_LD48A				; get X coordinate data or horizontal coord of
								; curent graphics cursor
			lda	dp_mos_vdu_wksp+5		; get back original X
			eor	#$04				; covert &20 to &24 and vice versa
			sta	dp_mos_vdu_wksp+3		; 
			ora	dp_mos_vdu_wksp+4		; 
			tax					; 
			jsr	_LD480				; copy 330/1 to 300/1+X
			lda	vduvar_VDU_Q_START+4		; get plot type
			and	#$10				; check bit 4
			asl					; 
			asl					; 
			asl					; move to bit 7
			sta	dp_mos_vdu_wksp+1		; store it
			ldx	#$2c				; X=&2C
			jsr	_LD10F				; check for window violations
			sta	dp_mos_vdu_wksp+2		; 
			beq	_BD263				; if none then D263
			lda	#$40				; else set bit 6 of &DB
			ora	dp_mos_vdu_wksp+1		; 
			sta	dp_mos_vdu_wksp+1		; 

_BD263:			ldx	dp_mos_vdu_wksp+3		; 
			jsr	_LD10F				; check window violations again
			bit	dp_mos_vdu_wksp+2		; if bit 7 of &DC NOT set
			beq	_BD26D				; D26D
			rts					; else exit
								;
_BD26D:			ldx	dp_mos_vdu_wksp+4		; X=&DE
			beq	_BD273				; if X=0 D273
			lsr					; A=A/2
			lsr					; A=A/2

_BD273:			and	#$02				; clear all but bit 2
			beq	_BD27E				; if bit 2 set D27E
			txa					; else A=X
			ora	#$04				; A=A or 4 setting bit 3
			tax					; X=A
			jsr	_LD480				; set 300/1+x to 330/1
_BD27E:			jsr	_LD42C				; more calcualtions
			lda	dp_mos_vdu_wksp+4		; A=&DE EOR 2
			eor	#$02				; 
			tax					; X=A
			tay					; Y=A
			lda	vduvar_TEMP_8+1			; compare upper byte of spans
			eor	vduvar_TEMP_8+3			; 
			bpl	_BD290				; if signs are the same D290
			inx					; else X=X+1
_BD290:			lda	f:_LC4AE,X			; get vector addresses and store 332/3
			sta	vduvar_GRA_WKSP+2		; 
			lda	f:_LC4B2,X			; 
			sta	vduvar_GRA_WKSP+3		; 

			lda	#$7f				; A=&7F
			sta	vduvar_GRA_WKSP+4		; store it
			bit	dp_mos_vdu_wksp+1		; if bit 6 set
			bvs	_BD2CE				; the D2CE
			lda	f:_LC447,X			; get VDU section number
			tax					; X=A
			sec					; set carry
			lda	vduvar_GRA_WINDOW_LEFT,X	; subtract coordinates
			sbc	vduvar_TEMP_8+4,Y		; 
			sta	dp_mos_vdu_wksp			; 
			lda	vduvar_GRA_WINDOW_LEFT+1,X	; 
			sbc	vduvar_TEMP_8+5,Y		; 
			ldy	dp_mos_vdu_wksp			; Y=hi
			tax					; X=lo=A
			bpl	_BD2C0				; and if A+Ve D2C0
			jsr	_LD49B				; negate Y/A

_BD2C0:			tax					; X=A increment Y/A
			iny					; Y=Y+1
			bne	_BD2C5				; 
			inx					; X=X+1
_BD2C5:			txa					; A=X
			beq	_BD2CA				; if A=0 D2CA
			ldy	#$00				; else Y=0

_BD2CA:			sty	dp_mos_vdu_wksp+5		; &DF=Y
			beq	_BD2D7				; if 0 then D2D7
_BD2CE:			txa					; A=X
			lsr					; A=A/4
			ror					; 
			ora	#$02				; bit 1 set
			eor	dp_mos_vdu_wksp+4		; 
			sta	dp_mos_vdu_wksp+4		; and store
_BD2D7:			ldx	#$2c				; X=&2C
			jsr	_LD864				; 
			ldx	dp_mos_vdu_wksp+2		; 
			bne	_BD2E2				; 
			dec	dp_mos_vdu_wksp+3		; 
_BD2E2:			dex					; X=X-1
_LD2E3:			lda	dp_mos_vdu_wksp+1		; A=&3B
			beq	_BD306				; if 0 D306
			bpl	_BD2F9				; else if +ve D2F9
			bit	vduvar_GRA_WKSP+4		; 
			bpl	_BD2F3				; if bit 7=0 D2F3
			dec	vduvar_GRA_WKSP+4		; else decrement
			bne	_BD316				; and if not 0 D316

_BD2F3:			inc	vduvar_GRA_WKSP+4		; 
			asl					; A=A*2
			bpl	_BD306				; if +ve D306
_BD2F9:			stx	dp_mos_vdu_wksp+2		; 
			ldx	#$2c				; 
			jsr	_LD85F				; calcualte screen position
			ldx	dp_mos_vdu_wksp+2		; get back original X
			ora	#$00				; 
			bne	_BD316				; 
_BD306:			phb
			phk
			plb
			lda	dp_mos_vdu_grpixmask		; byte mask for current graphics point
			and	dp_mos_vdu_gracolourOR		; and with graphics colour byte
			ora	(dp_mos_vdu_gra_char_cell),Y	; or  with curent graphics cell line
			sta	dp_mos_vdu_wksp			; store result
			lda	dp_mos_vdu_gracolourEOR		; same again with next byte (hi??)
			and	dp_mos_vdu_grpixmask		; 
			eor	dp_mos_vdu_wksp			; 
			sta	(dp_mos_vdu_gra_char_cell),Y	; then store it inm current graphics line
			plb
_BD316:			sec					; set carry
			lda	vduvar_GRA_WKSP+5		; A=&335/6-&337/8
			sbc	vduvar_GRA_WKSP+7		; 
			sta	vduvar_GRA_WKSP+5		; 
			lda	vduvar_GRA_WKSP+6		; 
			sbc	vduvar_GRA_WKSP+8		; 
			bcs	_BD339				; if carry set D339
			sta	dp_mos_vdu_wksp			; 
			lda	vduvar_GRA_WKSP+5		; 
			adc	vduvar_GRA_WKSP+9		; 
			sta	vduvar_GRA_WKSP+5		; 
			lda	dp_mos_vdu_wksp			; 
			adc	vduvar_GRA_WKSP+$A		; 
			clc					; 
_BD339:			sta	vduvar_GRA_WKSP+6		; 
			php					; 
			bcs	_BD348				; if carry clear jump to VDU routine else D348
			jmp	(vduvar_GRA_WKSP+2)		; 

;****** vertical scan module 1******************************************

_PLOT_D342:
			dey					; Y=Y-1
			bpl	_BD348				; if + D348
			jsr	_LD3D3				; else d3d3 to advance pointers
_BD348:			jmp	(vduvar_VDU_VEC_JMP)		; and JUMP (&35D)

;****** vertical scan module 2******************************************

_PLOT_D34B:
			iny					; Y=Y+1
			cpy	#$08				; if Y<>8
			bne	_BD348				; then D348
			clc					; else clear carry
			lda	dp_mos_vdu_gra_char_cell	; get address of top line of cuirrent graphics cell
			adc	vduvar_BYTES_PER_ROW		; add number of bytes/character row
			sta	dp_mos_vdu_gra_char_cell	; store it
			lda	dp_mos_vdu_gra_char_cell+1	; do same for hibyte
			adc	vduvar_BYTES_PER_ROW+1		; 
			bpl	_BD363				; if result -ve then we are above screen RAM
			sec					; so
			sbc	vduvar_SCREEN_SIZE_HIGH		; subtract screen memory size hi
_BD363:			sta	dp_mos_vdu_gra_char_cell+1	; store it this wraps around point to screen RAM
			ldy	#$00				; Y=0
			jmp	(vduvar_VDU_VEC_JMP)		; 

;****** horizontal scan module 1******************************************

_PLOT_D36A:
			lsr	dp_mos_vdu_grpixmask		; shift byte mask
			bcc	_BD348				; if carry clear (&D1 was +ve) goto D348
			jsr	_LD3ED				; else reset pointers
			jmp	(vduvar_VDU_VEC_JMP)		; and off to do more

;****** horizontal scan module 2******************************************

_PLOT_D374:
			asl	dp_mos_vdu_grpixmask		; shift byte mask
			bcc	_BD348				; if carry clear (&D1 was +ve) goto D348
			jsr	_LD3FD				; else reset pointers
			jmp	(vduvar_VDU_VEC_JMP)		; and off to do more

_LD37E:			dey					; Y=Y-1
			bpl	_BD38D				; if +ve D38D
			jsr	_LD3D3				; advance pointers
			bne	_BD38D				; goto D38D normally
_LD386:			lsr	dp_mos_vdu_grpixmask		; shift byte mask
			bcc	_BD38D				; if carry clear (&D1 was +ve) goto D348
			jsr	_LD3ED				; else reset pointers
_BD38D:			plp					; pull flags
			inx					; X=X+1
			bne	_BD395				; if X>0 D395
			inc	dp_mos_vdu_wksp+3		; else increment &DD
			beq	_BD39F				; and if not 0 D39F
_BD395:			bit	dp_mos_vdu_wksp+1		; else if BIT 6 = 1
			bvs	_BD3A0				; goto D3A0
			bcs	_BD3D0				; if BIT 7=1 D3D0
			dec	dp_mos_vdu_wksp+5		; else Decrement &DF
			bne	_BD3D0				; and if not Zero D3D0
_BD39F:			rts					; else return
								;
_BD3A0:			lda	dp_mos_vdu_wksp+4		; A=&DE
			stx	dp_mos_vdu_wksp+2		; &DC=X
			and	#$02				; clear all but bit 1
			tax					; X=A
			bcs	_BD3C2				; and if carry set goto D3C2
			bit	dp_mos_vdu_wksp+4		; if Bit 7 of &DE =1
			bmi	_BD3B7				; then D3B7
			inc	vduvar_TEMP_8+4,X		; else increment
			bne	_BD3C2				; and if not 0 D3C2
			inc	vduvar_TEMP_8+5,X		; else increment hi byte
			bcc	_BD3C2				; and if carry clear D3C2
_BD3B7:			lda	vduvar_TEMP_8+4,X		; esle A=32C,X
			bne	_BD3BF				; and if not 0 D3BF
			dec	vduvar_TEMP_8+5,X		; decrement hi byte
_BD3BF:			dec	vduvar_TEMP_8+4,X		; decrement lo byte

_BD3C2:			txa					; A=X
			eor	#$02				; invert bit 2
			tax					; X=A
			inc	vduvar_TEMP_8+4,X		; Increment 32C/D
			bne	_BD3CE				; 
			inc	vduvar_TEMP_8+5,X		; 
_BD3CE:			ldx	dp_mos_vdu_wksp+2		; X=&DC
_BD3D0:			jmp	_LD2E3				; jump to D2E3

;**********move display point up a line **********************************
_LD3D3:			sec					; SET CARRY
			lda	dp_mos_vdu_gra_char_cell			; subtract number of bytes/line from address of
			sbc	vduvar_BYTES_PER_ROW				; top line of current graphics cell
			sta	dp_mos_vdu_gra_char_cell			; 
			lda	dp_mos_vdu_gra_char_cell+1			; 
			sbc	vduvar_BYTES_PER_ROW+1			; 
			cmp	vduvar_SCREEN_BOTTOM_HIGH			; compare with bottom of screen memory
			bcs	_BD3E8				; if outside screen RAM
			adc	vduvar_SCREEN_SIZE_HIGH			; add screen memory size to wrap it around
_BD3E8:			sta	dp_mos_vdu_gra_char_cell+1			; store in current address of graphics cell top line
			ldy	#$07				; Y=7
			rts					; and RETURN

_LD3ED:			lda	vduvar_LEFTMOST_PIX_MASK			; get current left colour mask
			sta	dp_mos_vdu_grpixmask			; store it
			lda	dp_mos_vdu_gra_char_cell			; get current top line of graphics cell
			adc	#$07				; ADD 7
			sta	dp_mos_vdu_gra_char_cell			; 
			bcc	_BD3FC				; 
			inc	dp_mos_vdu_gra_char_cell+1			; 
_BD3FC:			rts					; and return

_LD3FD:			lda	vduvar_RIGHTMOST_PIX_MASK			; get right colour mask
			sta	dp_mos_vdu_grpixmask			; store it
			lda	dp_mos_vdu_gra_char_cell			; A=top line graphics cell low
			bne	_BD408				; if not 0 D408
			dec	dp_mos_vdu_gra_char_cell+1			; else decrement hi byte

_BD408:			sbc	#$08				; subtract 9 (8 + carry)
			sta	dp_mos_vdu_gra_char_cell			; and store in low byte
			rts					; return

;********:: coordinate subtraction ***************************************

_LD40D:			ldy	#$28				; X=&28
			ldx	#$20				; Y=&20
_LD411:			jsr	_LD418				; 
			inx					; X=X+2
			inx					; 
			iny					; Y=Y+2
			iny					; 

_LD418:			sec					; set carry
			lda	vduvar_GRA_WINDOW_RIGHT,X			; subtract coordinates
			sbc	vduvar_GRA_WINDOW_LEFT,X			; 
			sta	vduvar_GRA_WINDOW_LEFT,Y			; 
			lda	vduvar_GRA_WINDOW_RIGHT+1,X		; 
			sbc	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sta	vduvar_GRA_WINDOW_LEFT+1,Y		; 
			rts					; and return

_LD42C:			lda	dp_mos_vdu_wksp+4			; A=&DE
			bne	_BD437				; if A=0 D437
			ldx	#<vduvar_TEMP_8		; X=&28
			ldy	#<vduvar_TEMP_8+2		; Y=&2A
			jsr	_LCDDE_EXG2_P3				; exchange 300/1+Y with 300/1+X
								; IN THIS CASE THE X AND Y SPANS!

_BD437:			ldx	#<vduvar_TEMP_8		; X=&28
			ldy	#<vduvar_GRA_WKSP+7		; Y=&37
			jsr	_LD48A				; copy &300/4+Y to &300/4+X
								; transferring X and Y spans in this case
			sec					; set carry
			ldx	dp_mos_vdu_wksp+4			; X=&DE
			lda	vduvar_GRA_WKSP			; subtract 32C/D,X from 330/1
			sbc	vduvar_TEMP_8+4,X		; 
			tay					; partial answer in Y
			lda	vduvar_GRA_WKSP+1			; 
			sbc	vduvar_TEMP_8+5,X		; 
			bmi	_BD453				; if -ve D453
			jsr	_LD49B				; else negate Y/A

_BD453:			sta	dp_mos_vdu_wksp+3			; store A
			sty	dp_mos_vdu_wksp+2			; and Y
			ldx	#$35				; X=&35
_LD459:			jsr	_LD467				; get coordinates
			lsr					; 
			sta	vduvar_GRA_WINDOW_LEFT+1,X		; 
			tya					; 
			ror					; 
			sta	vduvar_GRA_WINDOW_LEFT,X			; 
			dex					; 
			dex					; 

_LD467:			ldy	vduvar_GRA_WINDOW_RIGHT,X			; 
			lda	vduvar_GRA_WINDOW_RIGHT+1,X		; 
			bpl	_BD47B				; if A is +ve RETURN
			jsr	_LD49B				; else negate Y/A
			sta	vduvar_GRA_WINDOW_RIGHT+1,X		; store back again
			pha					; 
			tya					; 
			sta	vduvar_GRA_WINDOW_RIGHT,X			; 
			pla					; get back A
_BD47B:			rts					; and exit
								;
_LD47C:			lda	#$08				; A=8
			bne	_VDU_VAR_COPY			; copy 8 bytes
_LD480:			ldy	#$30				; Y=&30
_LD482:			lda	#$02				; A=2
			bne	_VDU_VAR_COPY			; copy 2 bytes
_LD486:			ldy	#$28				; copy 4 bytes from 324/7 to 328/B
_LD488:			ldx	#$24				; 
_LD48A:			lda	#$04				; 

;***********copy A bytes from 300,X to 300,Y ***************************

_VDU_VAR_COPY:		sta	dp_mos_vdu_wksp			; 
__vdu_var_copy_next:	lda	vduvar_GRA_WINDOW_LEFT,X			; 
			sta	vduvar_GRA_WINDOW_LEFT,Y			; 
			inx					; 
			iny					; 
			dec	dp_mos_vdu_wksp			; 
			bne	__vdu_var_copy_next		; 
			rts					; and return

;************* negation routine ******************************************

_LD49B:			pha					; save A
			tya					; A=Y
			eor	#$ff				; invert
			tay					; Y=A
			pla					; get back A
			eor	#$ff				; invert
			iny					; Y=Y+1
			bne	_BD4A9				; if not 0 exit
			clc					; else
			adc	#$01				; add 1 to A
_BD4A9:			rts					; return
								;
_LD4AA:			jsr	_LD85D				; check window boundaries and set up screen pointer
			bne	_BD4B7				; if A<>0 D4B7
			lda	(dp_mos_vdu_gra_char_cell),Y			; else get byte from current graphics cell
			eor	vduvar_GRA_BACK			; compare with current background colour
			sta	dp_mos_vdu_wksp			; store it
			rts					; and RETURN

_BD4B7:			pla					; get back return link
			pla					; 
_BD4B9:			inc	vduvar_GRA_CUR_INT+2			; increment current graphics cursor vertical lo
			jmp	_LD545				; 


; OS SERIES IV
; GEOFF COX

;*************************************************************************
;*									 *
;*  LATERAL FILL ROUTINE						 *
;*									 *
;*************************************************************************


_LD4BF:			jsr	_LD4AA				; check current screen state
			and	dp_mos_vdu_grpixmask			; if A and &D1 <> 0 a plotted point has been found
			bne	_BD4B9				; so D4B9
			ldx	#$00				; X=0
			jsr	_LD592				; update pointers
			beq	_BD4FA				; if 0 then D4FA
			ldy	vduvar_GRA_CUR_CELL_LINE			; else Y=graphics scan line
			asl	dp_mos_vdu_grpixmask			; 
			bcs	_BD4D9				; if carry set D4D9
			jsr	_LD574				; else D574
			bcc	_BD4FA				; if carry clear D4FA
_BD4D9:			jsr	_LD3FD				; else D3FD to pick up colour multiplier
			lda	(dp_mos_vdu_gra_char_cell),Y			; get graphics cell line
			eor	vduvar_GRA_BACK			; EOR with background colour
			sta	dp_mos_vdu_wksp			; and store
			bne	_BD4F7				; if not 0 D4F7
			sec					; else set carry
			txa					; A=X
			adc	vduvar_PIXELS_PER_BYTE_MINUS1			; add pixels/byte
			bcc	_BD4F0				; and if carry clear D4F0
			inc	dp_mos_vdu_wksp+1			; else increment &DB
			bpl	_BD4F7				; and if +ve D4F7

_BD4F0:			tax					; else X=A
			jsr	_LD104				; display a pixel
			sec					; set carry
			bcs	_BD4D9				; goto D4D9

_BD4F7:			jsr	_LD574				; 
_BD4FA:			ldy	#$00				; Y=0
			jsr	_LD5AC				; 
			ldy	#<vduvar_VDU_Q_START+5			; 
			ldx	#<vduvar_GRA_CUR_INT			; 
			jsr	_LCDE6_EXG4_P3				; exchange 300/3 +Y with 300/3+X
_LD506:			jsr	_LD4AA				; check screen pixel
			ldx	#$04				; Y=5
			jsr	_LD592				; 
			txa					; A=x
			bne	_BD513				; if A<>0 d513
			dec	dp_mos_vdu_wksp+1			; else	&DB=&dB-1

_BD513:			dex					; X=X-1
_BD514:			jsr	_LD54B				; 
			bcc	_BD540				; 
_BD519:			jsr	_LD3ED				; update pointers
			lda	(dp_mos_vdu_gra_char_cell),Y			; get byte from graphics line
			eor	vduvar_GRA_BACK			; EOR with background colour
			sta	dp_mos_vdu_wksp			; and store it
			lda	dp_mos_vdu_wksp+2			; 
			bne	_BD514				; If A-0 back to D514
			lda	dp_mos_vdu_wksp			; else A=&DA
			bne	_BD53D				; if A<>d53D
			sec					; else set carry
			txa					; A=x
			adc	vduvar_PIXELS_PER_BYTE_MINUS1			; Add number of pixels/byte
			bcc	_BD536				; and if carry clear D536
			inc	dp_mos_vdu_wksp+1			; else inc DB
			bpl	_BD53D				; and if +ve D53D
_BD536:			tax					; get back X
			jsr	_LD104				; display a point
			sec					; set carry
			bcs	_BD519				; goto D519

_BD53D:			jsr	_LD54B				; 
_BD540:			ldy	#$04				; 
			jsr	_LD5AC				; 

_LD545:			jsr	_LD0D9				; 
			jmp	_LD1B8				; scale pointers

_LD54B:			lda	dp_mos_vdu_grpixmask			; get byte mask
			pha					; save it
			clc					; clear carry
			bcc	_BD560				; 

_BD551:			pla					; get back A
			inx					; X=X+1
			bne	_BD559				; if not 0 D559
			inc	dp_mos_vdu_wksp+1			; else inc &DB
			bpl	_BD56F				; if +ve D56F
_BD559:			lsr	dp_mos_vdu_grpixmask			; 
			bcs	_BD56F				; if Bit 7 D1 set D56F
			ora	dp_mos_vdu_grpixmask			; else or withA
			pha					; save result
_BD560:			lda	dp_mos_vdu_grpixmask			; A=&D1
			bit	dp_mos_vdu_wksp			; test bits 6 and 7 of &DA
			php					; save flags
			pla					; get into A
			eor	dp_mos_vdu_wksp+2			; EOR and DC
			pha					; save A
			plp					; 
			beq	_BD551				; 

			pla					; A=A EOR &D1 (byte mask)
			eor	dp_mos_vdu_grpixmask			; 
_BD56F:			sta	dp_mos_vdu_grpixmask			; store it
			jmp	_LD0F0				; and display a pixel

_LD574:			lda	#$00				; A=0
			clc					; Clear carry

			bcc	_BD583				; goto D583 if carry clear

_BD579:			inx					; X=X+1
			bne	_BD580				; If <>0 D580
			inc	dp_mos_vdu_wksp+1			; else inc &DB
			bpl	_BD56F				; and if +ve d56F

_BD580:			asl					; A=A*2
			bcs	_BD58E				; if C set D58E
_BD583:			ora	dp_mos_vdu_grpixmask			; else A=A OR (&D1)
			bit	dp_mos_vdu_wksp			; set V and M from &DA b6 b7
			beq	_BD579				; 
			eor	dp_mos_vdu_grpixmask			; A=AEOR &D1
			lsr					; /2
			bcc	_BD56F				; if carry clear D56F
_BD58E:			ror					; *2
			sec					; set carry
			bcs	_BD56F				; to D56F

_LD592:			lda	vduvar_GRA_WINDOW_LEFT,X			; Y/A=(&300/1 +X)-(&320/1)
			sec					; 
			sbc	vduvar_VDU_Q_START+5			; 
			tay					; 
			lda	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sbc	vduvar_VDU_Q_START+6			; 
			bmi	_BD5A5				; if result -ve D5A5
			jsr	_LD49B				; or negate Y/A
_BD5A5:			sta	dp_mos_vdu_wksp+1			; store A
			tya					; A=Y
			tax					; X=A
			ora	dp_mos_vdu_wksp+1			; 
			rts					; exit

_LD5AC:			sty	dp_mos_vdu_wksp			; Y=&DA
			txa					; A=X
			tay					; Y=A
			lda	dp_mos_vdu_wksp+1			; A=&DB
			bmi	_BD5B6				; if -ve D5B6
			lda	#$00				; A=0
_BD5B6:			ldx	dp_mos_vdu_wksp			; X=&DA
			bne	_BD5BD				; if <>0 D5BD
			jsr	_LD49B				; negate
_BD5BD:			pha					; 
			clc					; 
			tya					; 
			adc	vduvar_GRA_WINDOW_LEFT,X			; Y/A+(&300/1 +X)=(&320/1)
			sta	vduvar_VDU_Q_START+5			; 
			pla					; 
			adc	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sta	vduvar_VDU_Q_START+6			; 
			rts					; return


;*************************************************************************
;*									 *
;*	 OSWORD 13 - READ LAST TWO GRAPHIC CURSOR POSITIONS		 *
;*									 *
;*************************************************************************
				;
_OSWORD_13:		lda	#$03				; A=3
			jsr	_LD5D5				; 
			lda	#$07				; A=7
_LD5D5:			pha					; Save A
			jsr	_LCDE2				; exchange last 2 graphics cursor coordinates with
								; current coordinates
			jsr	_LD1B8				; convert to external coordinates
			ldx	#$03				; X=3
			pla					; save A
			tay					; Y=A
_BD5E0:			lda	vduvar_GRA_CUR_EXT,X		; get graphics coordinate
			sta	(dp_mos_OSBW_X),Y		; store it in OS buffer
			dey					; decrement Y and X
			dex					; 
			bpl	_BD5E0				; if +ve do it again
			rtl					; then Exit


;*************************************************************************
;*									 *
;*	 PLOT Fill triangle routine					 *
;*									 *
;*************************************************************************

_LD5EA:			ldx	#<vduvar_VDU_Q_START+5			; X=&20
			ldy	#<vduvar_GRA_WKSP+$E		; Y=&3E
			jsr	_LD47C				; copy 300/7+X to 300/7+Y
								; this gets XY data parameters and current graphics
								; cursor position
			jsr	_LD632				; exchange 320/3 with 324/7 if 316/7=<322/3
			ldx	#<vduvar_GRA_CUR_EXT+3+1		; X=&14
			ldy	#<vduvar_GRA_CUR_INT			; Y=&24
			jsr	_LD636				; 
			jsr	_LD632				; 

			ldx	#<vduvar_VDU_Q_START+5			; 
			ldy	#<vduvar_TEMP_8+2		; 
			jsr	_LD411				; calculate 032A/B-(324/5-320/1)
			lda	vduvar_TEMP_8+3			; and store
			sta	vduvar_GRA_WKSP+2			; result

			ldx	#<vduvar_TEMP_8		; set pointers
			jsr	_LD459				; 
			ldy	#<vduvar_TEMP_8+6		; 

			jsr	_LD0DE				; copy 320/3 32/31
			jsr	_LCDE2				; exchange 314/7 with 324/7
			clc					; 
			jsr	_LD658				; execute fill routine

			jsr	_LCDE2				; 
			ldx	#<vduvar_VDU_Q_START+5			; 
			jsr	_LCDE4				; 
			sec					; 
			jsr	_LD658				; 

			ldx	#<vduvar_GRA_WKSP+$E		; ;X=&3E
			ldy	#<vduvar_VDU_Q_START+5			; ;Y=&20
			jsr	_LD47C				; ;copy 300/7+X to 300/7+Y
			jmp	_LD0D9				; ;this gets XY data parameters and current graphics
								; cursor position

_LD632:			ldx	#<vduvar_VDU_Q_START+5			; X=&20
			ldy	#<vduvar_GRA_CUR_EXT+3+1		; Y=&14
_LD636:			lda	vduvar_GRA_WINDOW_BOTTOM,X			; 
			cmp	vduvar_GRA_WINDOW_BOTTOM,Y			; 
			lda	vduvar_GRA_WINDOW_BOTTOM+1,X		; 
			sbc	vduvar_GRA_WINDOW_BOTTOM+1,Y		; 
			bmi	_BD657				; if 302/3+Y>302/3+X return
			jmp	_LCDE6_EXG4_P3				; else swap 302/3+X with 302/3+Y


;*************************************************************************
;*									 *
;*	 OSBYTE 134 - READ CURSOR POSITION				 *
;*									 *
;*************************************************************************

_OSBYTE_134:		lda	vduvar_TXT_CUR_X		; read current text cursor (X)
			sec					; set carry
			sbc	vduvar_TXT_WINDOW_LEFT		; subtract left hand column of current text window
			tax					; X=A
			lda	vduvar_TXT_CUR_Y		; get current text cursor (Y)
			sec					; 
			sbc	vduvar_TXT_WINDOW_TOP		; suptract top row of current window
			tay					; Y=A
			rtl

_BD657:			rts					; and exit

				; PLOT routines continue
				; many of the following routines are just manipulations
				; only points of interest will be explained
_LD658:			php					; store flags
			ldx	#$20				; X=&20
			ldy	#$35				; Y=&35
			jsr	_LD411				; 335/6=(324/5+X-320/1)
			lda	vduvar_GRA_WKSP+6			; 
			sta	vduvar_GRA_WKSP+$D		; 
			ldx	#$33				; 
			jsr	_LD459				; set pointers

			ldy	#$39				; set 339/C=320/3
			jsr	_LD0DE				; 
			sec					; 
			lda	vduvar_VDU_Q_START+7		; 
			sbc	vduvar_GRA_CUR_INT+2		; 
			sta	vduvar_VDU_Q_START		; 
			lda	vduvar_VDU_Q_START+8		; 
			sbc	vduvar_GRA_CUR_INT+3		; 
			sta	vduvar_VDU_Q_START+1		; 
			ora	vduvar_VDU_Q_START		; check VDU queque
			beq	_BD69F				; 

_BD688:			jsr	_LD6A2				; display a line
			ldx	#$33				; 
			jsr	_LD774				; update pointers
			ldx	#$28				; 
			jsr	_LD774				; and again!
			inc	vduvar_VDU_Q_START			; update VDU queque
			bne	_BD688				; and if not empty do it again
			inc	vduvar_VDU_Q_START+1			; else increment next byte
			bne	_BD688				; and do it again

_BD69F:			plp					; pull flags
			bcc	_BD657				; if carry clear exit
_LD6A2:			ldx	#$39				; 
			ldy	#$2e				; 
_VDU_G_CLR_LINE:	stx	dp_mos_vdu_wksp+4			; 
			lda	vduvar_GRA_WINDOW_LEFT,X			; is 300/1+x<300/1+Y
			cmp	vduvar_GRA_WINDOW_LEFT,Y			; 
			lda	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sbc	vduvar_GRA_WINDOW_LEFT+1,Y		; 
			bmi	_BD6BC				; if so D6BC
			tya					; else A=Y
			ldy	dp_mos_vdu_wksp+4			; Y=&DE
			tax					; X=A
			stx	dp_mos_vdu_wksp+4			; &DE=X
_BD6BC:			sty	dp_mos_vdu_wksp+5			; &DF=Y
			lda	vduvar_GRA_WINDOW_LEFT,Y			; 
			pha					; 
			lda	vduvar_GRA_WINDOW_LEFT+1,Y		; 
			pha					; 
			ldx	dp_mos_vdu_wksp+5			; 
			jsr	_LD10F				; check for window violations
			beq	_BD6DA				; 
			cmp	#$02				; 
			bne	_LD70E				; 
			ldx	#$04				; 
			ldy	dp_mos_vdu_wksp+5			; 
			jsr	_LD482				; 
			ldx	dp_mos_vdu_wksp+5			; 
_BD6DA:			jsr	_LD864				; set a screen address
			ldx	dp_mos_vdu_wksp+4			; X=&DE
			jsr	_LD10F				; check for window violations
			lsr					; A=A/2
			bne	_LD70E				; if A<>0 then exit
			bcc	_BD6E9				; else if C clear D6E9
			ldx	#$00				; 
_BD6E9:			ldy	dp_mos_vdu_wksp+5			; 
			sec					; 
			lda	vduvar_GRA_WINDOW_LEFT,Y			; 
			sbc	vduvar_GRA_WINDOW_LEFT,X			; 
			sta	dp_mos_vdu_wksp+2			; 
			lda	vduvar_GRA_WINDOW_LEFT+1,Y		; 
			sbc	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sta	dp_mos_vdu_wksp+3			; 
			lda	#$00				; 
_BD6FE:			asl					; 
			ora	dp_mos_vdu_grpixmask			; 
			ldy	dp_mos_vdu_wksp+2			; 
			bne	_BD719				; 
			dec	dp_mos_vdu_wksp+3			; 
			bpl	_BD719				; 
			sta	dp_mos_vdu_grpixmask			; 
			jsr	_LD0F0				; display a point
_LD70E:			ldx	dp_mos_vdu_wksp+5			; restore X
			pla					; and A
			sta	vduvar_GRA_WINDOW_LEFT+1,X		; store it
			pla					; get back A
			sta	vduvar_GRA_WINDOW_LEFT,X			; and store it
			rts					; exit
								;
_BD719:			dec	dp_mos_vdu_wksp+2			; 
			tax					; 
			bpl	_BD6FE				; 
			sta	dp_mos_vdu_grpixmask			; 
			jsr	_LD0F0				; display a point
			ldx	dp_mos_vdu_wksp+2			; 
			inx					; 
			bne	_BD72A				; 
			inc	dp_mos_vdu_wksp+3			; 
_BD72A:			txa					; 
			pha					; 
			lsr	dp_mos_vdu_wksp+3			; 
			ror					; 
			ldy	vduvar_PIXELS_PER_BYTE_MINUS1			; number of pixels/byte
			cpy	#$03				; if 3 mode = goto D73B
			beq	_BD73B				; 
			bcc	_BD73E				; else if <3 mode 2 goto D73E
			lsr	dp_mos_vdu_wksp+3			; else rotate bottom bit of &DD
			ror					; into Accumulator

_BD73B:			lsr	dp_mos_vdu_wksp+3			; rotate bottom bit of &DD
			lsr					; into Accumulator
_BD73E:			ldy	vduvar_GRA_CUR_CELL_LINE			; Y=line in current graphics cell containing current
								; point
			tax					; X=A
			beq	_BD753				; 
_BD744:			tya					; Y=Y-8
			sec					; 
			sbc	#$08				; 
			tay					; 

			bcs	_BD74D				; 
			dec	dp_mos_vdu_gra_char_cell+1			; decrement byte of top line off current graphics cell
_BD74D:			jsr	_LD104				; display a point
			dex					; 
			bne	_BD744				; 
_BD753:			pla					; 
			and	vduvar_PIXELS_PER_BYTE_MINUS1			; pixels/byte
			beq	_LD70E				; 
			tax					; 
			lda	#$00				; A=0
_BD75C:			asl					; 
			ora	vduvar_RIGHTMOST_PIX_MASK			; or with right colour mask
			dex					; 
			bne	_BD75C				; 
			sta	dp_mos_vdu_grpixmask			; store as byte mask
			tya					; Y=Y-8
			sec					; 
			sbc	#$08				; 
			tay					; 
			bcs	_BD76E				; if carry clear
			dec	dp_mos_vdu_gra_char_cell+1			; decrement byte of top line off current graphics cell
_BD76E:			jsr	_LD0F3				; display a point
			jmp	_LD70E				; and exit via D70E

_LD774:			inc	vduvar_TXT_WINDOW_LEFT,X			; 
			bne	_BD77C				; 
			inc	vduvar_TXT_WINDOW_BOTTOM,X			; 
_BD77C:			sec					; 
			lda	vduvar_GRA_WINDOW_LEFT,X			; 
			sbc	vduvar_GRA_WINDOW_BOTTOM,X			; 
			sta	vduvar_GRA_WINDOW_LEFT,X			; 
			lda	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sbc	vduvar_GRA_WINDOW_BOTTOM+1,X		; 
			sta	vduvar_GRA_WINDOW_LEFT+1,X		; 
			bpl	_BD7C1				; 
_BD791:			lda	vduvar_TXT_WINDOW_RIGHT,X			; 
			bmi	_BD7A1				; 
			inc	vduvar_GRA_WINDOW_TOP,X			; 
			bne	_LD7AC				; 
			inc	vduvar_GRA_WINDOW_TOP+1,X		; 
			jmp	_LD7AC				; 
_BD7A1:			lda	vduvar_GRA_WINDOW_TOP,X			; 
			bne	_BD7A9				; 
			dec	vduvar_GRA_WINDOW_TOP+1,X		; 
_BD7A9:			dec	vduvar_GRA_WINDOW_TOP,X			; 
_LD7AC:			clc					; 
			lda	vduvar_GRA_WINDOW_LEFT,X			; 
			adc	vduvar_GRA_WINDOW_RIGHT,X			; 
			sta	vduvar_GRA_WINDOW_LEFT,X			; 
			lda	vduvar_GRA_WINDOW_LEFT+1,X		; 
			adc	vduvar_GRA_WINDOW_RIGHT+1,X		; 
			sta	vduvar_GRA_WINDOW_LEFT+1,X		; 
			bmi	_BD791				; 
_BD7C1:			rts					; 


;*************************************************************************
;*									 *
;*	 OSBYTE 135 - READ CHARACTER AT TEXT CURSOR POSITION		 *
;*									 *
;*************************************************************************

_OSBYTE_135:		ldy	vduvar_COL_COUNT_MINUS1			; get number of logical colours
			bne	_BD7DC				; if Y<>0 mode <>7 so D7DC
			lda	(dp_mos_vdu_top_scanline),Y		; get address of top scan line of current text chr
			ldy	#$02				; Y=2
_BD7CB:			cmp	_TELETEXT_CHAR_TAB+1,Y		; compare with conversion table
			bne	_BD7D4				; if not equal D7d4
			lda	_TELETEXT_CHAR_TAB,Y		; else get next lower byte from table
			dey					; Y=Y-1
_BD7D4:			dey					; Y=Y-1
			bpl	_BD7CB				; and if +ve do it again
_BD7D7:			ldy	vduvar_MODE			; Y=current screen mode
			tax					; return with character in X
			rts					; 
								;
_BD7DC:			jsr	_LD808				; set up copy of the pattern bytes at text cursor
			ldx	#$20				; X=&20
_BD7E1:			txa					; A=&20
			pha					; Save it
			jsr	_LD03E				; get pattern address for code in A
			pla					; get back A
			tax					; and X
_BD7E8:			ldy	#$07				; Y=7
_BD7EA:			lda	vduvar_TEMP_8,Y		; get byte in pattern copy
			cmp	(dp_mos_vdu_wksp+4),Y			; check against pattern source
			bne	_BD7F9				; if not the same D7F9
			dey					; else Y=Y-1
			bpl	_BD7EA				; and if +ve D7EA
			txa					; A=X
			cpx	#$7f				; is X=&7F (delete)
			bne	_BD7D7				; if not D7D7
_BD7F9:			inx					; else X=X+1
			lda	dp_mos_vdu_wksp+4			; get byte lo address
			clc					; clear carry
			adc	#$08				; add 8
			sta	dp_mos_vdu_wksp+4			; store it
			bne	_BD7E8				; and go back to check next character if <>0

			txa					; A=X
			bne	_BD7E1				; if <>0 D7E1
			beq	_BD7D7				; else D7D7

;***************** set up pattern copy ***********************************

_LD808:			ldy	#$07				; Y=7

_BD80A:			sty	dp_mos_vdu_wksp			; &DA=Y
			lda	#$01				; A=1
			sta	dp_mos_vdu_wksp+1			; &DB=A
_BD810:			lda	vduvar_LEFTMOST_PIX_MASK			; A=left colour mask
			sta	dp_mos_vdu_wksp+2			; store an &DC
			lda	(dp_mos_vdu_top_scanline),Y		; get a byte from current text character
			eor	vduvar_TXT_BACK			; EOR with text background colour
			clc					; clear carry
_BD81B:			bit	dp_mos_vdu_wksp+2			; and check bits of colour mask
			beq	_BD820				; if result =0 then D820
			sec					; else set carry
_BD820:			rol	dp_mos_vdu_wksp+1			; &DB=&DB+Carry
			bcs	_BD82E				; if carry now set (bit 7 DB originally set) D82E
			lsr	dp_mos_vdu_wksp+2			; else	&DC=&DC/2
			bcc	_BD81B				; if carry clear D81B
			tya					; A=Y
			adc	#$07				; ADD ( (7+carry)
			tay					; Y=A
			bcc	_BD810				; 
_BD82E:			ldy	dp_mos_vdu_wksp			; read modified values into Y and A
			lda	dp_mos_vdu_wksp+1			; 
			sta	vduvar_TEMP_8,Y		; store copy
			dey					; and do it again
			bpl	_BD80A				; until 8 bytes copied
			rtl					; exit

;********* pixel reading *************************************************

_LD839:			pha					; store A
			tax					; X=A
			jsr	_LD149				; set up positional data
			pla					; get back A
			tax					; X=A
			jsr	_LD85F				; set a screen address after checking for window
								; violations
			bne	_BD85A				; if A<>0 D85A to exit with A=&FF
			lda	(dp_mos_vdu_gra_char_cell),Y			; else get top line of current graphics cell
_BD847:			asl					; A=A*2 C=bit 7
			rol	dp_mos_vdu_wksp			; &DA=&DA+2 +C	C=bit 7 &DA
			asl	dp_mos_vdu_grpixmask			; byte mask=bM*2 +carry from &DA
			php					; save flags
			bcs	_BD851				; if carry set D851
			lsr	dp_mos_vdu_wksp			; else restore &DA with bit '=0
_BD851:			plp					; pull flags
			bne	_BD847				; if Z set D847
			lda	dp_mos_vdu_wksp			; else A=&DA AND number of colours in current mode -1
			and	vduvar_COL_COUNT_MINUS1			; 
			rts					; then exit
								;
_BD85A:			lda	#$ff				; A=&FF
_BD85C:			rts					; exit

;********** check for window violations and set up screen address **********

_LD85D:			ldx	#$20				; X=&20
_LD85F:			jsr	_LD10F				; 
			bne	_BD85C				; if A<>0 there is a window violation so D85C
_LD864:			lda	vduvar_GRA_WINDOW_BOTTOM,X			; else set up graphics scan line variable
			eor	#$ff				; 
			tay					; 
			and	#$07				; 
			sta	vduvar_GRA_CUR_CELL_LINE			; in 31A
			tya					; A=Y
			lsr					; A=A/2
			lsr					; A=A/2
			lsr					; A=A/2
			asl					; A=A*2 this gives integer value bit 0 =0
			tay					; Y=A
			phb
			phk
			plb
			lda	(dp_mos_vdu_mul),Y		; get high byte of offset from screen RAM start
			sta	dp_mos_vdu_wksp			; store it
			iny					; Y=Y+1
			lda	(dp_mos_vdu_mul),Y		; get lo byte
			plb
			ldy	vduvar_MODE_SIZE			; get screen map type
			beq	_BD884				; if 0 (modes 0,1,2) goto D884
			lsr	dp_mos_vdu_wksp			; else &DA=&DA/2
			ror					; and A=A/2 +C if set
								; so 2 byte offset =offset/2

_BD884:			adc	vduvar_6845_SCREEN_START				; add screen top left hand corner lo
			sta	dp_mos_vdu_gra_char_cell			; store it
			lda	dp_mos_vdu_wksp			; get high  byte
			adc	vduvar_6845_SCREEN_START+1			; add top left hi
			sta	dp_mos_vdu_gra_char_cell+1			; store it
			lda	vduvar_GRA_WINDOW_LEFT+1,X		; 
			sta	dp_mos_vdu_wksp			; 
			lda	vduvar_GRA_WINDOW_LEFT,X			; 
			pha					; 
			and	vduvar_PIXELS_PER_BYTE_MINUS1			; and then Add pixels per byte-1
			adc	vduvar_PIXELS_PER_BYTE_MINUS1			; 
			tax					; Y=A
			lda	f:_TAB_VDU_MASK_R,X		; A=&80 /2^Y using look up table
			sta	dp_mos_vdu_grpixmask			; store it
			pla					; get back A
			ldy	vduvar_PIXELS_PER_BYTE_MINUS1			; Y=&number of pixels/byte
			cpy	#$03				; is Y=3 (modes 1,6)
			beq	_BD8B2				; goto D8B2
			bcs	_BD8B5				; if mode =1 or 4 D8B5
			asl					; A/&DA =A/&DA *2
			rol	dp_mos_vdu_wksp			; 

_BD8B2:			asl					; 
			rol	dp_mos_vdu_wksp			; 

_BD8B5:			and	#$f8				; clear bits 0-2
			clc					; clear carry

			adc	dp_mos_vdu_gra_char_cell			; add A/&DA to &D6/7
			sta	dp_mos_vdu_gra_char_cell			; 
			lda	dp_mos_vdu_wksp			; 
			adc	dp_mos_vdu_gra_char_cell+1			; 
			bpl	_BD8C6				; if result +ve D8C6
			sec					; else set carry
			sbc	vduvar_SCREEN_SIZE_HIGH			; and subtract screen memory size making it wrap round

_BD8C6:			sta	dp_mos_vdu_gra_char_cell+1			; store it in &D7
			ldy	vduvar_GRA_CUR_CELL_LINE			; get line in graphics cell containing current graphics
_BD8CB:			lda	#$00				; point	 A=0
			rts					; And exit
								;
_LD8CE:			pha					; Push A
			lda	#$a0				; A=&A0
			ldx	sysvar_VDU_Q_LEN			; X=number of items in VDU queque
			bne	_BD916				; if not 0 D916
			bit	dp_mos_vdu_status			; else check VDU status byte
			bne	_BD916				; if either VDU is disabled or plot to graphics
								; cursor enabled then D916
			bvs	_BD8F5				; if cursor editing enabled D8F5
			lda	vduvar_CUR_START_PREV			; else get 6845 register start setting
			and	#$9f				; clear bits 5 and 6
			ora	#$40				; set bit 6 to modify last cursor size setting
			jsr	_LC954				; change write cursor format
			ldx	#$18				; X=&18
			ldy	#$64				; Y=&64
			jsr	_LD482				; set text input cursor from text output cursor
			jsr	_LCD7A				; modify character at cursor poistion
			lda	#$02				; A=2
			jsr	OR_VDU_STATUS				; bit 1 of VDU status is set to bar scrolling


_BD8F5:			lda	#$bf				; A=&BF
			jsr	AND_VDU_STATUS				; bit 6 of VDU status =0
			pla					; Pull A
			and	#$7f				; clear hi bit (7)
			jsr	_VDUCHR_NAT				; entire VDU routine !!
			lda	#$40				; A=&40
			jmp	OR_VDU_STATUS				; exit


_LD905:			lda	#$20				; A=&20
			bit	dp_mos_vdu_status			; if bit 6 cursor editing is set
			bvc	_BD8CB				; 
			bne	_BD8CB				; or bit 5 is set exit &D8CB
			jsl	_OSBYTE_135			; read a character from the screen
			beq	_BD917				; if A=0 on return exit via D917
			pha					; else store A
			jsr	_VDU_9				; perform cursor right

_BD916:			pla					; restore A
_BD917:			rts					; and exit
								;
_LD918:			lda	#$bd				; zero bits 2 and 6 of VDU status
			jsr	AND_VDU_STATUS				; 
			jsr	_LC951				; set normal cursor
			lda	#$0d				; A=&0D
			rts					; and return
								; this is response of CR as end of edit line


;*************************************************************************
;*									 *
;*	 OSBYTE 132 - READ BOTTOM OF DISPLAY RAM			 *
;*									 *
;*************************************************************************

_OSBYTE_132:		ldx	vduvar_MODE			; Get current screen mode


;*************************************************************************
;*									 *
;*	 OSBYTE 133 - READ LOWEST ADDRESS FOR GIVEN MODE		 *
;*									 *
;*************************************************************************

_OSBYTE_133:		txa					; A=X
			and	#$07				; Ensure mode 0-7
			tay					; Pass to Y into index into screen size table
			phb
			phk
			plb
			ldx	_TAB_MAP_TYPE,Y			; X=screen size type, 0-4
			lda	_VDU_MEMLOC_TAB,X		; A=high byte of start address for screen type
			plb
			ldx	#$00				; Returned address is &xx00
			bit	sysvar_RAM_AVAIL		; Check available RAM
			bmi	_BD93E				; If bit 7 set then 32K RAM, so return address
			and	#$3f				; 16K RAM, so drop address to bottom 16K
			cpy	#$04				; Check screen mode
			bcs	_BD93E				; If mode 4-7, return the address
			txa					; If mode 0-3, return &0000 as not enough memory
; exit
_BD93E:			tay					; Pass high byte of address to Y
			rtl					; and return address in YX


;*************************************************************************
;*									 *
;*	 OSBYTE 154 (&9A) SET VIDEO ULA					 *
;*									 *
;*************************************************************************

_OSBYTE_154:		txa					; osbyte entry! X transferred to A thence to


vduSetULACTL:		php					; save flags
			sep	#$24				; set 8 bit mode and disable interrupts
			.a8
			sta	f:sysvar_VIDPROC_CTL_COPY	; save RAM copy of new parameter
			sta	f:sheila_VIDULA_ctl		; write to control register
			lda	f:sysvar_FLASH_MARK_PERIOD	; read	space count
			sta	f:sysvar_FLASH_CTDOWN		; set flash counter to this value
			plp					; get back status
			rtl					; and return



;*************************************************************************
;*									 *
;*	  OSBYTE &9B (155) write to palette register			 *
;*									 *
;*************************************************************************
;entry X contains value to write
_OSBYTE_155:		txa					; A=X
_LEA11:			eor	#$07				; convert to palette format
			php					; 
			sei					; prevent interrupts
			sta	sysvar_VIDPROC_PAL_COPY		; store as current palette setting
			sta	f:sheila_VIDULA_pal		; store actual colour in register
			plp					; get back flags
			rtl					; and exit

; WRCH control routine
; ====================
		; Enter her from main NATIVE vector as a FAR call
			.a16
			.i16

_NVWRCH:		pha					; Save all registers
			phx
			phy

			pea	0
			pld					; TODO: get rid - set by CallAVector?
			phd
			plb
			plb

			sep	#$30
			.a8
			.i8


			lda	5,S				; Get A back from stack
			pha					; Save A
			bit	sysvar_ECO_OSWRCH_INTERCEPT	; Check OSWRCH interception flag
			bpl	__no_intercept			; Not set, skip interception call
			tay					; Pass character to Y
			lda	#$04				; A=4 for OSWRCH call
			pea	IX_NETV
			pld
			cop	COP_08_OPCAV
			bcs	_BE10D				; If claimed, jump past to exit
__no_intercept:		clc					; Prepare to not send this to printer
			lda	#$02				; Check output destination
			bit	sysvar_OUTSTREAM_DEST		; Is VDU driver disabled?
			bne	_BE0C8				; Yes, skip past VDU driver
			pla					; Get character back
			pha					; Resave character
			jsr	_VDUCHR_NAT			; Call VDU driver
								; On exit, C=1 if character to be sent to printer

_BE0C8:			

;;TODO:printer/serial
;;
;;			lda	#$08				; Check output destination
;;			bit	sysvar_OUTSTREAM_DEST		; Is printer seperately enabled?
;;			bne	_BE0D1				; Yes, jump to call printer driver
;;			bcc	_BE0D6				; Carry clear, don't sent to printer
;;_BE0D1:			pla					; Get character back
;;			pha					; Resave character
;;			jsr	_PRINTER_OUT			; Call printer driver
;;
;;_BE0D6:			lda	sysvar_OUTSTREAM_DEST		; Check output destination
;;			ror	A				; Is serial output enabled?
;;			bcc	_BE0F7				; No, skip past serial output
;;			ldy	RS423_TIMEOUT			; Get serial timout counter
;;			dey					; Decrease counter
;;			bpl	_BE0F7				; Timed out, skip past serial code
;;			pla					; Get character back
;;			pha					; Resave character
;;			php					; Save IRQs
;;			sei					; Disable IRQs
;;			ldx	#$02				; X=2 for serial output buffer
;;			pha					; Save character
;;			jsr	_OSBYTE_152			; Examine serial output buffer
;;			bcc	_BE0F0				; Buffer not full, jump to send character
;;			jsr	_LE170				; Wait for buffer to empty a bit
;;_BE0F0:			pla					; Get character back
;;			ldx	#$02				; X=2 for serial output buffer
;;			jsr	_BUFFER_SAVE			; Send character to serial output buffer
;;			plp					; Restore IRQs
;;
;;TODO:spool/files
;;_BE0F7:		lda	#$10				; Check output destination
;;			bit	sysvar_OUTSTREAM_DEST		; Is SPOOL output disabled?
;;			bne	_BE10D				; Yes, skip past SPOOL output
;;			ldy	OSB_SPOOL_HND			; Get SPOOL handle
;;			beq	_BE10D				; If not open, skip past SPOOL output
;;			pla					; Get character back
;;			pha					; Resave character
;;			sec					
;;			ror	CRFS_ACTIVE			; Set RFS/CFS's 'spooling' flag
;;			jsr	OSBPUT				; Write character to SPOOL channel
;;			lsr	CRFS_ACTIVE			; Reset RFS/CFS's 'spooling' flag

_BE10D:			pla					; get back 8 bit (ignored)
			
			rep	#$30				; back to 16 bit registers for vector code
			.a16
			.i16
								; Restore all registers 16 bit
			ply					
			plx					
			pla
			rtl					; Exit



		;;TODO sound
_VDU_7:			rts


;****************** Write A to SYSTEM VIA register B *************************
				; called from &CB6D, &CB73
_WRITE_SYS_VIA_PORTB:	php					; push flags
			sep	#$24				; disable interupts and little A
			.a8
			sta	f:sheila_SYSVIA_orb		; write register B from Accumulator
			plp					; get back flags
			rts					; and exit
