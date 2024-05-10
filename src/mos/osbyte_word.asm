
		.include "dp_bbc.inc"
		.include "cop.inc"
		.include "debug.inc"
		.include "vectors.inc"
		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "sysvars.inc"
		.include "vduvars.inc"

		.export doOSBYTE
		.export doOSWORD
		.export osByteWordInit:far
		.export COP_06
		.export COP_07
		.export COP_3F


;	********************************************************************************
;	* Main OSBYTE and OSWORD dispatchers are executed in native mode               *
;	********************************************************************************


.proc osByteWordInit:far
		; copy the dispatch table to RAM so that modules
		; can intercept
		php
		rep	#$30
		.a16
		.i16
		lda	#_OSBYTE_TABLE_SIZE
		ldx	#.loword(_OSBYTE_TABLE)
		ldy	#.loword(OSBYTE_TABLE)
		mvn	#^_OSBYTE_TABLE, #^OSBYTE_TABLE

		plp
		rtl


.endproc

;	********************************************************************************
;	* COP 3F - OPBWV = Capture an OSBYTE/WORD                                      *
;	*                                                                              *
;	* This call allows modules to update the OSBYTE/WORD dispatch table by         *
;	* supplying their own routines.                                                *
;	*                                                                              *
;	* Not all calls are passed through the dispatch table, if the number is        *
;	* not in the covered range an error will be returned. Also, note that some     *
;	* codes share a handler i.e. OSBYTES 166..255                                  *
;	*                                                                              *
;	* Not all OSBYTES/WORDS can be overridden in this way and this is very much    *
;	* an OS internals routine                                                      *
;	*                                                                              *
;	* On entry:                                                                    *
;	*    X    contains the OSBYTE index. For OSWORD add 256                        *
;	*    BHA  contains the handler address                                         *
;	*                                                                              *
;	* On exit: 								       *
;	*    Cy=1 indicates an error occurred                                          *
;	*    BHA  points to an error block                                             *
;	*                                                                              *
;	*    Cy=0 indicates success                                                    *
;	*    BHA  contains the old handler address or 0 if not handled                 *
;	*                                                                              *
;	* D preserved                                                                  *
;	********************************************************************************
		.a16
		.i16
COP_3F:		lda	DPCOP_X
		cmp	#256
		bcc	@byte
		cmp	#256+256
		bcs	@badIndex
		cmp	#256+$E0
		bcc	@skn
		lda	#TBLIX_OSWORDEOPLUS
		bra	@gotix
@skn:		cmp	#256+14		; OSWORD max+1
		bcs	@badIndex		
		sbc	#TBLD_WORD-1
@gotix:		pha
		asl	A
		adc	1,S
		sta	1,S
		plx
		pea	^OSBYTE_TABLE<<8
		plb
		plb
		php
		sei
		lda	OSBYTE_TABLE+1,X
		pha
		lda	OSBYTE_TABLE,X
		pha
		lda	DPCOP_AH+1
		sta	OSBYTE_TABLE+1,X
		lda	DPCOP_AH
		dec	A			; make suitable for RTL
		sta	OSBYTE_TABLE,X
		pla
		sta	DPCOP_AH
		pla
		sta	DPCOP_AH+1		
		plp
		ror	DPCOP_P
		sec
		rol	DPCOP_P
		rtl


@byte:		cmp	#22
		bcc	@gotix
		cmp	#117
		bcc	@badIndex
		cmp	#161
		bcs	@skn2
		sbc	#TBLD_BYTE_117_160-1
		bra	@gotix
@skn2:		cmp	#166
		bcc	@badIndex
		lda	#TBLIX_OSBYTE166PLUS
		bra	@gotix


@badIndex:	cop	COP_26_OPBHA
		.byte	0, "Bad Index", 0
		lda	#1
		ror	DPCOP_P
		sec
		rol	DPCOP_P
		rtl




;	********************************************************************************
;	* COP 06 - OPOSB = OSBYTE                                                      *
;	*                                                                              *
;	* This call caries out various operations, the specific operation depending on *
;	* the contents of A on entry. Other data can be passed in X and Y. If results  *
;	* are generated, these are returned in X and Y.                                *
;	*                                                                              *
;	* On entry: A contains the reason code. The reason code determines the         *
;	* function of the call.                                                        *
;	*                                                                              *
;	* On exit: X and Y will contain results if the call produces them.             *
;	*                                                                              *
;	* D preserved                                                                  *
;	********************************************************************************
		.a16
		.i16
COP_06:		ldx	DPCOP_X
		ldy	DPCOP_Y
		cop	COP_08_OPCAV
		.byte	IX_BYTEV
		sty	DPCOP_Y
		stx	DPCOP_X
		php
		sep	#$30
		.a8
		.i8
		txa
		php
		lda	1,S
		eor	DPCOP_P
		and	#$CF			; keep original M/X flags
		eor	DPCOP_P			; get back Caller's flags and nothing else
		sta	DPCOP_P			; set flags but keep M/X from caller
		plp
		plp		
		rtl
		.a16
		.i16


; TODO: - this must depend on whether called from EMU or NAT mode as b0 is 
;	  different!
;	********************************************************************************
;	* COP 07 - OPOSW = OSWORD                                                      *
;	*                                                                              *
;	* Action: This call caries out various operations, the specific operation      *
;	* depending on the contents of A on entry. 0YX points to a control block in    *
;	* memory, and this block contains data for the call, and will contain results  *
;	* from the call.                                                               *
;	* On entry:                                                                    *
;	* EITHER: 0YX points to a control block in memory                              *
;	* OR: Y = 0 and X contains an offset from the direct page register D. The      *
;	* start of the control block is in the direct page at address D+X.             *
;	* A contains the reason code. The reason code determines the function of the   *
;	* call.                                                                        *
;	* On exit: D preserved                                                         *
;	*                                                                              *
;	* For OPOSW with A = 0 (read line from input)                                  *
;	* Y = line length (including CR if applicable).                                *
;	* If C = 0 then CR termimated input.                                           *
;	* If C = 1 then ESCAPE terminated input                                        *
;	********************************************************************************
COP_07:		;TODO
		rtl



doOSBYTE:	;;DEBUG_PRINTF "OSBYTE #%A, X=%X, Y=%Y\n"

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

_BE791:		sec					; set carry


_BE793:		php
		pha
		asl	A
		adc	1,S
		sta	1,S				; multiply by **3** for far addresses
		pla
		plp

		sty	dp_mos_OSBW_Y			; store Y
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

_BE7A2:		phk					; return address bank
		per    	_OSBYTEWORD_EXIT_NAT-1

		lda	#^OSBYTE_TABLE			; RAM copy of OSBYTE dispatch table
		pha
		plb

		lda	.loword(OSBYTE_TABLE) + 2,Y	; get address from table
		pha					; handler bank
		lda	.loword(OSBYTE_TABLE) + 1,Y	; repeat for hi byte
		pha					; handler bank
		lda	.loword(OSBYTE_TABLE),Y		; repeat for lo byte
		pha					; handler bank
		
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
		rtl					; call handler (address pushed above)


_OSBYTEWORD_EXIT_NAT:
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
		
		;NOTE: this must be a direct call to _OSBYTE_143 to avoid
		; overwriting the osbyte DP registers!
		jsl	_OSBYTE_143			; offer paged ROMS service 7/8 unrecognised osbyte/word

		bne	_BE7D6				; if roms don't recognise it then E7D6
		ldx	dp_mos_OSBW_X			; else restore X
		jmp	_LE7BC				; and exit

_BE7D6:		plp					; else pull flags (settings C)
		pla					; and A
		sep	#$40				; set V
		rtl					; and return



;**************************************************************************
;**************************************************************************
;**									 **
;**	 OSWORD	 DEFAULT ENTRY POINT					 **
;**									 **
;**	 pointed to by default WORDV					 **
;**									 **
;**************************************************************************
;**************************************************************************

doOSWORD:	;;DEBUG_PRINTF "OSWORD #%A, X=%X, Y=%Y\n"	
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
;;;		asl					; double it
		clc
		bra	_BE793				; goto E793 ALWAYS!! (carry clear E7F8)
							; this reads bytes from table and enters routine


;TODO: consider making these far vectors in RAM somewhere to allow modules to implement?
_OSBYTE_TABLE:	.faraddr	_OSBYTE_0-1			; OSBYTE   0  (&E821)	; 0 ; = 3*(ix)
		.faraddr	_OSBYTE_1_6-1			; OSBYTE   1  (&E988)	; 1 ; = 3*(ix)
		.faraddr	_OSBYTE_2-1			; OSBYTE   2  (&E6D3)	; 2 ; = 3*(ix)
		.faraddr	_OSBYTE_3_4-1			; OSBYTE   3  (&E997)	; 3 ; = 3*(ix)
		.faraddr	_OSBYTE_3_4-1			; OSBYTE   4  (&E997)	; 4 ; = 3*(ix)
		.faraddr	_OSBYTE_5-1			; OSBYTE   5  (&E976)	; 5 ; = 3*(ix)
		.faraddr	_OSBYTE_1_6-1			; OSBYTE   6  (&E988)	; 6 ; = 3*(ix)
		.faraddr	_OSBYTE_7-1			; OSBYTE   7  (&E68B)	; 7 ; = 3*(ix)
		.faraddr	_OSBYTE_8-1			; OSBYTE   8  (&E689)	; 8 ; = 3*(ix)
		.faraddr	_OSBYTE_9-1			; OSBYTE   9  (&E6B0)	; 9 ; = 3*(ix)
		.faraddr	_OSBYTE_10-1			; OSBYTE  10  (&E6B2)	; 10 ; = 3*(ix)
		.faraddr	_OSBYTE_11-1			; OSBYTE  11  (&E995)	; 11 ; = 3*(ix)
		.faraddr	_OSBYTE_12-1			; OSBYTE  12  (&E98C)	; 12 ; = 3*(ix)
		.faraddr	_OSBYTE_13-1			; OSBYTE  13  (&E6F9)	; 13 ; = 3*(ix)
		.faraddr	_OSBYTE_14-1			; OSBYTE  14  (&E6FA)	; 14 ; = 3*(ix)
		.faraddr	_OSBYTE_15-1			; OSBYTE  15  (&F0A8)	; 15 ; = 3*(ix)
		.faraddr	_OSBYTE_16-1			; OSBYTE  16  (&E706)	; 16 ; = 3*(ix)
		.faraddr	_OSBYTE_17-1			; OSBYTE  17  (&DE8C)	; 17 ; = 3*(ix)
		.faraddr	_OSBYTE_18-1			; OSBYTE  18  (&E9C8)	; 18 ; = 3*(ix)
		.faraddr	_OSBYTE_19-1			; OSBYTE  19  (&E9B6)	; 19 ; = 3*(ix)
		.faraddr	_OSBYTE_20-1			; OSBYTE  20  (&CD07)	; 20 ; = 3*(ix)
		.faraddr	_OSBYTE_21-1			; OSBYTE  21  (&F0B4)	; 21 ; = 3*(ix)
		.faraddr	_OSBYTE_117-1			; OSBYTE 117  (&E86C)	; 22 ; = 3*(ix-117+22)   
		.faraddr	_OSBYTE_118-1			; OSBYTE 118  (&E9D9)	; 23 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_119-1			; OSBYTE 119  (&E275)	; 24 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_120-1			; OSBYTE 120  (&F045)	; 25 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_121-1			; OSBYTE 121  (&F0CF)	; 26 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_122-1			; OSBYTE 122  (&F0CD)	; 27 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_123-1			; OSBYTE 123  (&E197)	; 28 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_124-1			; OSBYTE 124  (&E673)	; 29 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_125-1			; OSBYTE 125  (&E674)	; 30 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_126-1			; OSBYTE 126  (&E65C)	; 31 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_127-1			; OSBYTE 127  (&E035)	; 32 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_128-1			; OSBYTE 128  (&E74F)	; 33 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_129-1			; OSBYTE 129  (&E713)	; 34 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_130-1			; OSBYTE 130  (&E729)	; 35 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_131-1			; OSBYTE 131  (&F085)	; 36 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_132-1			; OSBYTE 132  (&D923)	; 37 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_133-1			; OSBYTE 133  (&D926)	; 38 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_134-1			; OSBYTE 134  (&D647)	; 39 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_135-1			; OSBYTE 135  (&D7C2)	; 40 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_136-1			; OSBYTE 136  (&E657)	; 41 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_137-1			; OSBYTE 137  (&E67F)	; 42 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_138-1			; OSBYTE 138  (&E4AF)	; 43 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_139-1			; OSBYTE 139  (&E034)	; 44 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_140_141-1		; OSBYTE 140  (&F135)	; 45 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_140_141-1		; OSBYTE 141  (&F135)	; 46 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_142-1			; OSBYTE 142  (&DBE7)	; 47 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_143-1			; OSBYTE 143  (&F168)	; 48 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_144-1			; OSBYTE 144  (&EAE3)	; 49 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_145-1			; OSBYTE 145  (&E460)	; 50 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_146-1			; OSBYTE 146  (&FFAA)	; 51 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_147-1			; OSBYTE 147  (&EAF4)	; 52 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_148-1			; OSBYTE 148  (&FFAE)	; 53 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_149-1			; OSBYTE 149  (&EAF9)	; 54 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_150-1			; OSBYTE 150  (&FFB2)	; 55 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_151-1			; OSBYTE 151  (&EAFE)	; 56 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_152-1			; OSBYTE 152  (&E45B)	; 57 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_153-1			; OSBYTE 153  (&E4F3)	; 58 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_154-1			; OSBYTE 154  (&E9FF)	; 59 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_155-1			; OSBYTE 155  (&EA10)	; 60 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_156-1			; OSBYTE 156  (&E17C)	; 61 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_157-1			; OSBYTE 157  (&FFA7)	; 62 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_158-1			; OSBYTE 158  (&EE6D)	; 63 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_159-1			; OSBYTE 159  (&EE7F)	; 64 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_160-1			; OSBYTE 160  (&E9C0)	; 65 ; = 3*(ix-117+22)
		.faraddr	_OSBYTE_166_255-1		; OSBYTE 166+		; 66 ; = 3*(66)
		.faraddr	_OSCLI_USERV-1			; OSWORD &E0+		; 67 ; = 3*(67)
TBLD_BYTE_117_160	:= 117-22
TBLIX_OSBYTE166PLUS 	:= 66
TBLIX_OSWORDEOPLUS 	:= 67

;*************************************************************************
;*			                                              *
;*	  OSWORD LOOK UP TABLE                                          *
;*			                                              *
;*************************************************************************

TBLD_WORD		:= 68
		.faraddr	_OSWORD_0-1			; OSWORD   0  (&E902)	; 68 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_1-1			; OSWORD   1  (&E8D5)	; 69 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_2-1			; OSWORD   2  (&E8E8)	; 70 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_3-1			; OSWORD   3  (&E8D1)	; 71 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_4-1			; OSWORD   4  (&E8E4)	; 72 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_5-1			; OSWORD   5  (&E803)	; 73 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_6-1			; OSWORD   6  (&E80B)	; 74 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_7-1			; OSWORD   7  (&E82D)	; 75 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_8-1			; OSWORD   8  (&E8AE)	; 76 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_9-1			; OSWORD   9  (&C735)	; 77 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_10-1			; OSWORD  10  (&CBF3)	; 78 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_11-1			; OSWORD  11  (&C748)	; 79 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_12-1			; OSWORD  12  (&C8E0)	; 80 ; = 3*(ix-256-68)
		.faraddr	_OSWORD_13-1			; OSWORD  13  (&D5CE)	; 81 ; = 3*(ix-256-68)
_OSBYTE_TABLE_SIZE := * - _OSBYTE_TABLE

_OSWORD_5:
_OSWORD_6:
_OSWORD_7:
_OSWORD_8:
_OSWORD_9:
_OSWORD_10:
_OSWORD_11:
_OSWORD_12:
_OSWORD_13:


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
_OSBYTE_16:
_OSBYTE_17:
_OSBYTE_18:
_OSBYTE_19:
_OSBYTE_20:
_OSBYTE_117:
_OSBYTE_119:
_OSBYTE_123:
_OSBYTE_127:
_OSBYTE_128:
_OSBYTE_129:
_OSBYTE_132:
_OSBYTE_133:
_OSBYTE_134:
_OSBYTE_135:
_OSBYTE_136:
_OSBYTE_137:
_OSBYTE_139:
_OSBYTE_140_141:
_OSBYTE_144:
_OSBYTE_146:
_OSBYTE_147:
_OSBYTE_148:
_OSBYTE_149:
_OSBYTE_150:
_OSBYTE_151:
_OSBYTE_152:
_OSBYTE_154:
_OSBYTE_155:
_OSBYTE_156:
_OSBYTE_157:
_OSBYTE_158:
_OSBYTE_159:
_OSBYTE_160:
_OSCLI_USERV:

	; consume return address from stack and jump back to 

		; not implemented!
		sep	#$40
		rtl

; TODO: pass on unregistered OSBYTES but avoid loops?
;;		pla
;;		brl	_BE7CA
;;



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
;;		DEBUG_PRINTF "OSW0 RDCH A=%A F=%F\n"
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



;*************************************************************************
;*									 *
;*	 OSWORD	 03   ENTRY POINT					 *
;*									 *
;*	 read interval timer						 *
;*									 *
;*************************************************************************
;F0/1 points to block to store data

_OSWORD_3:		ldx	#$0f				; X=&F displacement from clock to timer
			bne	_BE8D8				; jump to E8D8


;*************************************************************************
;*									 *
;*	 OSWORD	 01   ENTRY POINT					 *
;*									 *
;*	 read system clock						 *
;*									 *
;*************************************************************************
;F0/1 points to block to store data

_OSWORD_1:		ldx	sysvar_TIMER_SWITCH		; X=current system clock store pointer

_BE8D8:			ldy	#$04				; Y=4
_BE8DA:			lda	oswksp_TIME-5,X			; read byte
			sta	(dp_mos_OSBW_X),Y		; store it in parameter block
			inx					; X=x+1
			dey					; Y=Y-1
			bpl	_BE8DA				; if Y>0 then do it again
_BE8E3:			rtl					; else exit


;*************************************************************************
;*									 *
;*	 OSWORD	 04   ENTRY POINT					 *
;*									 *
;*	 write interval timer						 *
;*									 *
;*************************************************************************
; F0/1 points to block to store data

_OSWORD_4:		lda	#$0f				; offset between clock and timer
			bne	_BE8EE				; jump to E8EE ALWAYS!!


;*************************************************************************
;*									 *
;*	 OSWORD	 02   ENTRY POINT					 *
;*									 *
;*	 write system clock						 *
;*									 *
;*************************************************************************
; F0/1 points to block to store data

_OSWORD_2:		lda	sysvar_TIMER_SWITCH		; get current clock store pointer
			eor	#$0f				; and invert to get inactive timer
			clc					; clear carry

_BE8EE:			pha					; store A
			tax					; X=A
			ldy	#$04				; Y=4
_BE8F2:			lda	(dp_mos_OSBW_X),Y		; and transfer all 5 bytes
			sta	oswksp_TIME-5,X			; to the clock or timer
			inx					; 
			dey					; 
			bpl	_BE8F2				; if Y>0 then E8F2
			pla					; get back stack
			bcs	_BE8E3				; if set (write to timer) E8E3 exit
			sta	sysvar_TIMER_SWITCH		; write back current clock store
			rtl					; and exit


;*************************************************************************
;*									 *
;*	 OSBYTE 142 - ENTER LANGUAGE ROM AT &8000			 *
;*									 *
;*	 X=rom number C set if OSBYTE call clear if initialisation	 *
;*									 *
;*************************************************************************

_OSBYTE_142:		php					; save flags
			stx	sysvar_CUR_LANG			; put X in current ROM page
			jsl	roms_selX			; select that ROM
			ldy	#8
			lda	#$FF
			pha
			plb	
			inc	A
			sta	dp_mos_error_ptr
			lda	#$80
			sta	dp_mos_error_ptr+1
			; display text string held in ROM at &8009,Y
@lp:			iny
			lda	(dp_mos_error_ptr),Y
			beq	@sk
			cop	COP_00_OPWRC
			bra	@lp
@sk:			pea	0
			plb
			plb
			sty	dp_mos_error_ptr		; save Y on exit (end of language string)
			cop	COP_03_OPNLI			; two line feeds
			cop	COP_03_OPNLI			; are output
			plp					; then get back flags
			lda	#$01				; A=1 required for language entry
;TODO: TUBE
;;			bit	sysvar_TUBE_PRESENT			; check if tube exists
;;			bmi	_START_TUBE			; and goto DC08 if it does

		; enter language at 8000 in emu mode
		pea	$8000			; address
		pea	$0000			; flags
		jml	nat2emu_rti




;*************************************************************************
;*									 *
;*	 OSBYTE 130 - GET HIGH ORDER ADDRESS     			 *
;*									 *
;*	 Returns X=Y=FF                                           	 *
;*	TODO: should this return something different for EMU/NAT?	 *
;*************************************************************************
;NOTE: we have to return FFFF for BASIC2's Tube check
_OSBYTE_130:
		ldx	#$FF
		txy
		rtl

;*************************************************************************
;*									 *
;*	 OSBYTE	 A6-FF	 ENTRY POINT					 *
;*									 *
;*	 READ/ WRITE SYSTEM VARIABLE OSBYTE NO. +&190			 *
;*									 *
;*************************************************************************

_OSBYTE_166_255:	tay					; Y=A
			lda	$0190,Y				; i.e. A=&190 +osbyte call!
			tax					; preserve this
			and	dp_mos_OSBW_Y			; new value = OLD value AND Y EOR X!
			eor	dp_mos_OSBW_X			; 
			sta	$0190,Y				; store it
			lda	$0191,Y				; get value of next byte into A
			tay					; Y=A
_BE9AC:			rtl					; and exit
