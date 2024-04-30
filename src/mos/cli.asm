		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "dp_bbc.inc"
		.include "sysvars.inc"


		.export doCLIV

		.a16
		.i16
;	*************************************************************************
;	*   CLI - COMMAND LINE INTERPRETER					 *
;	*									 *
;	*   ENTRY: XY=>Command line either an emu bank or WINDOW address	 *
;	*   EXIT:  All registers corrupted					 *
;	*   [ A=13 - unterminated string ]					 *
;	*************************************************************************
.proc doCLIV:far
		sep	#$30
		.a8
		.i8

		pea	$FFFF
		plb
		plb					; bank FF

		stx	dp_mos_txtptr			; Store XY in &F2/3
		sty	dp_mos_txtptr+1			
		lda	#FSCV_08_CLI_INIT				
		cop	COP_08_OPCAV
		.byte	IX_FSCV				; Inform filing system CLI being processed
		ldy	#$00				; Check the line is correctly terminated
crlp:		lda	(dp_mos_txtptr),Y			
		cmp	#$0d				; Loop until CR is found
		beq	sktermok				
		iny					; Move to next character
		bne	crlp				; Loop back if less than 256 bytes long
		rtl					; Exit if string > 255 characters

; String is terminated - skip prepended spaces and '*'s
sktermok:	ldy	#$ff				
spclp:		jsl	utilNextSkipSpace		; Skip any spaces
		beq	exitrtl			; Exit if at CR
		cmp	#'*'				; Is this character '*'?
		beq	spclp				; Loop back to skip it, and check for spaces again

		jsl	utilSkipSpace			; Skip any more spaces
		beq	exitrtl			; Exit if at CR
		cmp	#'|'				; Is it '|' - a comment
		beq	exitrtl			; Exit if so
		cmp	#'/'				; Is it '/' - pass straight to filing system
		bne	skNotRun			; Jump forward if not
		iny					; Move past the '/'
		jsr	_LE009				; Convert &F2/3,Y->XY, ignore returned A
		lda	#FSCV_02_RUN			; 2=RunSlashCommand
		cop	COP_08_OPCAV
		.byte	IX_FSCV				; Execute FS Command
		lda	#0
		sta	3,S
		sta	4,S				; cancel vector chain
exitrtl:	rtl

; Look command up in command table
skNotRun:	sty	dp_mos_OS_wksp				; Store offset to start of command
		ldx	#$00				
		beq	tbllpfirst				

matlp:		eor	f:_OSCLI_TABLE,X			
		and	#$df				
		bne	skNotMatch				
		iny					
		clc					

tbllp:		bcs	hadDot					; skip forward if '.'
		inx					
		lda	(dp_mos_txtptr),Y			
		jsl	utilsAisAlpha				
		bcc	matlp				

tbllpfirst:	lda	f:_OSCLI_TABLE,X			
		bmi	gotPtr				
		lda	(dp_mos_txtptr),Y			
		cmp	#'.'				
		beq	skDot				
skNotMatch:	clc					
		ldy	dp_mos_OS_wksp				
		dey					
skDot:		iny					
		inx					
skaddlp:	inx					
		lda	f:_OSCLI_TABLE - 2,X		
		beq	doSvc4			
		bpl	skaddlp			; skip forwards to pointer
		bmi	tbllp				

gotPtr:		inx					
		inx					

hadDot:		dex					
		dex					
		phk
		; push routine pointer
		pha					
		lda	f:_OSCLI_TABLE + 1,X		
		pha					
		jsl	utilSkipSpace			
		clc					
		php					
		jsr	_LE004				
		rti					; Jump to routine

_LE004:		lda	f:_OSCLI_TABLE + 2,X		; Get table parameter
		bmi	exitrts				; If >=&80, number follow
		; else string follows

_LE009:		pha					; Pass Y line offset to A for later
		lda	f:_OSCLI_TABLE + 2,X		; Get looked-up parameter from table
		tay
		pla

; Convert &F2/3,A to XY, put Y in A
::_GET_TEXT_PTR:clc					
		adc	dp_mos_txtptr			
		tax					
		tya					; Pass supplied Y into A
		ldy	dp_mos_txtptr+1			
		bcc	exitrts		
		iny					

exitrts:	rts					



; Pass command on to other ROMs and to filing system
::doSvc4:	ldy	dp_mos_OS_wksp			; Restore pointer to start of command
		ldx	#SERVICE_4_UKCMD		; 4=UnknownCommand
		lda	#OSBYTE_143_SERVICE_CALL
		cop	COP_06_OPOSB			; Pass to sideways ROMs
		txa
		beq	exitrtl				; If claimed, exit
		lda	dp_mos_OS_wksp			; Restore pointer to start of command
		jsr	_GET_TEXT_PTR			; Convert &F2/3,A to XY, ignore returned A
		lda	#FSCV_03_FSCMD			; 3=PassCommandToFilingSystem
		cop	COP_08_OPCAV
		.byte	IX_FSCV
		rtl

	
.endproc


		.macro OSCLTBL str, hand, val
			.byte	str, >hand, <hand, val
		.endmacro

;**** COMMMANDS ****
;				  Command    Address	   Call goes to
_OSCLI_TABLE:		
			OSCLTBL	".",	_OSCLI_FSCV	,$05	; *.	    &E031, A=5	   FSCV, XY=>String
			OSCLTBL	"FX",	_OSCLI_FX	,$ff	; *FX	    &E342, A=&FF   Number parameters
			OSCLTBL	"BASIC",_OSCLI_BASIC	,$00	; *BASIC    &E018, A=0	   XY=>String
			OSCLTBL	"CAT",	_OSCLI_FSCV	,$05	; *CAT	    &E031, A=5	   FSCV, XY=>String
			OSCLTBL	"CODE",	_OSCLI_OSBYTE	,$88	; *CODE	    &E348, A=&88   OSBYTE &88
;			OSCLTBL	"EXEC",	_OSCLI_EXEC	,$00	; *EXEC	    &F68D, A=0	   XY=>String
			OSCLTBL	"HELP",	_OSCLI_HELP	,$ff	; *HELP	    &F0B9, A=&FF   F2/3=>String
;			OSCLTBL	"KEY",	_OSCLI_KEY	,$ff	; *KEY	    &E327, A=&FF   F2/3=>String
;			OSCLTBL	"LOAD",	_OSCLI_LOAD	,$00	; *LOAD	    &E23C, A=0	   XY=>String
;			OSCLTBL	"LINE",	_OSCLI_USERV	,$01	; *LINE	    &E659, A=1	   USERV, XY=>String
;;			OSCLTBL	"MOTOR",_OSCLI_OSBYTE	,$89	; *MOTOR    &E348, A=&89   OSBYTE
			OSCLTBL	"OPT",	_OSCLI_OSBYTE	,$8b	; *OPT	    &E348, A=&8B   OSBYTE
			OSCLTBL	"RUN",	_OSCLI_FSCV	,$04	; *RUN	    &E031, A=4	   FSCV, XY=>String
;;			OSCLTBL	"ROM",	_OSCLI_OSBYTE	,$8d	; *ROM	    &E348, A=&8D   OSBYTE
;			OSCLTBL	"SAVE",	_OSCLI_SAVE	,$00	; *SAVE	    &E23E, A=0	   XY=>String
;			OSCLTBL	"SPOOL",_OSCLI_SPOOL	,$00	; *SPOOL    &E281, A=0	   XY=>String
			OSCLTBL	"TAPE",	_OSCLI_OSBYTE	,$8c	; *TAPE	    &E348, A=&8C   OSBYTE
			OSCLTBL	"TV",	_OSCLI_OSBYTE	,$90	; *TV	    &E348, A=&90   OSBYTE
			OSCLTBL	"",	_OSCLI_FSCV	,$03	; Unmatched &E031, A=3	   FSCV, XY=>String
			.byte	$00				; Table end marker


_OSCLI_FSCV:
		cop	COP_08_OPCAV
		.byte	IX_FSCV
		rtl


; *BASIC
; ======
_OSCLI_BASIC:		ldx	sysvar_ROMNO_BASIC	; Get BASIC ROM number
			bpl	@ok
			jmp	doSvc4			; If none set, jump to pass command on
@ok:			sec				; Set Carry = not entering from RESET
		;TODO: Reset stacks here - it won't return?
			lda	#OSBYTE_142_ENTER_LANGUAGE
			cop	COP_06_OPOSB		; Enter language rom in X
			rtl



;*************************************************************************
;*									 *
;*		 Issue *HELP to ROMS					 *
;*									 *
;*************************************************************************
_OSCLI_HELP:		ldx	#SERVICE_9_HELP			; 
			lda	#OSBYTE_143_SERVICE_CALL
			cop	COP_06_OPOSB			; 
			cop	COP_01_OPWRS			; print following message routine return after BRK
			.byte	$0d,$0a				; carriage return
			.byte	"MODEL C MOS 6.00"		; help message
			.byte	$0d,$0a				; carriage return
			.byte 	0
			rtl					; 


;*************************************************************************
;*									 *
;*	 *FX   OSBYTE							 *
;*									 *
;*************************************************************************
;	A=number

.proc _OSCLI_FX:far
		jsl	utilReadDigits8bit		; convert the number to binary
		bcs	_ok
::_badCmd:	jmp	brkBadCommand			; if bad number call bad command
_ok:		txa					; save X
.endproc
		; FALL THROUGH!

;*************************************************************************
;*									 *
;*	 *CODE	 *MOTOR	  *OPT	 *ROM	*TAPE	*TV			 *
;*									 *
;*************************************************************************
				; enter codes	 *CODE	 &88
;			*MOTOR	&89
;			*OPT	&8B
;			*TAPE	&8C
;			*ROM	&8D
;			*TV	&90

.proc _OSCLI_OSBYTE:far
		pha					; save A
		lda	#$00				; clear &E4/E5
		sta	dp_mos_GSREAD_characc		; 
		sta	dp_mos_GSREAD_quoteflag		; 
		jsl	_LE043				; skip commas and check for newline (CR)
		beq	_BE36C				; if CR found E36C
		jsl	utilReadDigits8bit		; convert character to binary
		bcc	_badCmd				; if bad character bad command error
		stx	dp_mos_GSREAD_characc		; else save it
		jsl	utilSkipComma			; skip comma and check CR
		beq	_BE36C				; if CR then E36C
		jsl	utilReadDigits8bit		; get another parameter
		bcc	_badCmd				; if bad error
		stx	dp_mos_GSREAD_quoteflag		; else store in E4
		jsl	utilSkipSpace			; now we must have a newline
		bne	_badCmd				; if none then output an error

_BE36C:		ldy	dp_mos_GSREAD_quoteflag		; Y=third osbyte parameter
		ldx	dp_mos_GSREAD_characc		; X=2nd
		pla					; A=first
		cop	COP_06_OPOSB			; call osbyte
		bvs	_badCmd				; if V set on return then error
		rtl					; else RETURN

.endproc 

_LE043:		bcc	@ss
		jml	utilSkipComma
@ss:		jml	utilSkipSpace			
