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
spclp:		jsr	utilNextSkipSpace		; Skip any spaces
		beq	exitrtl			; Exit if at CR
		cmp	#'*'				; Is this character '*'?
		beq	spclp				; Loop back to skip it, and check for spaces again

		jsr	utilSkipSpace			; Skip any more spaces
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
		jsr	utilsAisAlpha				
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
		jsr	utilSkipSpace			
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
		beq	exitrtl				; If claimed, exit
		lda	dp_mos_OS_wksp			; Restore pointer to start of command
		jsr	_GET_TEXT_PTR			; Convert &F2/3,A to XY, ignore returned A
		lda	#FSCV_03_FSCMD			; 3=PassCommandToFilingSystem
		cop	COP_08_OPCAV
		.byte	IX_FSCV
		rtl

; Skip spaces
utilNextSkipSpace:	iny					
utilSkipSpace:		lda	(dp_mos_txtptr),Y			
			cmp	#$20				
			beq	utilNextSkipSpace		
__compare_newline:	cmp	#$0d				
			rts					

_LE043:			bcc	utilSkipSpace			
_SKIP_COMMA:		jsr	utilSkipSpace			
			cmp	#$2c				
			bne	__compare_newline		
			iny					
			rts					

_LE04E:			jsr	utilSkipSpace			
			jsr	_CHECK_FOR_DIGIT		
			bcc	__not_digit			
_BE056:			sta	dp_mos_OS_wksp				
			jsr	_CHECK_FOR_DIGIT_NXT		
			bcc	_BE076				
			tax					
			lda	dp_mos_OS_wksp				
			asl	A				
			bcs	__not_digit			
			asl	A				
			bcs	__not_digit			
			adc	dp_mos_OS_wksp				
			bcs	__not_digit			
			asl	A				
			bcs	__not_digit			
			sta	dp_mos_OS_wksp				
			txa					
			adc	dp_mos_OS_wksp				
			bcs	__not_digit			
			bcc	_BE056				
_BE076:			ldx	dp_mos_OS_wksp				
			cmp	#$0d				
			sec					
			rts					

_CHECK_FOR_DIGIT_NXT:	iny					
_CHECK_FOR_DIGIT:	lda	(dp_mos_txtptr),Y			
			cmp	#$3a				
			bcs	__not_digit			
			cmp	#$30				
			bcc	__not_digit			
			and	#$0f				
			rts					

__next_field:		jsr	_SKIP_COMMA			
__not_digit:		clc					
			rts					

_CHECK_FOR_HEX:		jsr	_CHECK_FOR_DIGIT		
			bcs	__check_hex_done		
			and	#$df				
			cmp	#$47				
			bcs	__next_field			
			cmp	#$41				
			bcc	__next_field			
			php					
			sbc	#$37				
			plp					
__check_hex_done:	iny					
			rts	
		
.endproc


		.macro OSCLTBL str, hand, val
			.byte	str, >hand, <hand, val
		.endmacro

;**** COMMMANDS ****
;				  Command    Address	   Call goes to
_OSCLI_TABLE:		
			OSCLTBL	".",	_OSCLI_FSCV	,$05	; *.	    &E031, A=5	   FSCV, XY=>String
;			OSCLTBL	"FX",	_OSCLI_FX	,$ff	; *FX	    &E342, A=&FF   Number parameters
			OSCLTBL	"BASIC",_OSCLI_BASIC	,$00	; *BASIC    &E018, A=0	   XY=>String
			OSCLTBL	"CAT",	_OSCLI_FSCV	,$05	; *CAT	    &E031, A=5	   FSCV, XY=>String
;			OSCLTBL	"CODE",	_OSCLI_OSBYTE	,$88	; *CODE	    &E348, A=&88   OSBYTE &88
;			OSCLTBL	"EXEC",	_OSCLI_EXEC	,$00	; *EXEC	    &F68D, A=0	   XY=>String
;			OSCLTBL	"HELP",	_OSCLI_HELP	,$ff	; *HELP	    &F0B9, A=&FF   F2/3=>String
;			OSCLTBL	"KEY",	_OSCLI_KEY	,$ff	; *KEY	    &E327, A=&FF   F2/3=>String
;			OSCLTBL	"LOAD",	_OSCLI_LOAD	,$00	; *LOAD	    &E23C, A=0	   XY=>String
;			OSCLTBL	"LINE",	_OSCLI_USERV	,$01	; *LINE	    &E659, A=1	   USERV, XY=>String
;			OSCLTBL	"MOTOR",_OSCLI_OSBYTE	,$89	; *MOTOR    &E348, A=&89   OSBYTE
;			OSCLTBL	"OPT",	_OSCLI_OSBYTE	,$8b	; *OPT	    &E348, A=&8B   OSBYTE
			OSCLTBL	"RUN",	_OSCLI_FSCV	,$04	; *RUN	    &E031, A=4	   FSCV, XY=>String
;			OSCLTBL	"ROM",	_OSCLI_OSBYTE	,$8d	; *ROM	    &E348, A=&8D   OSBYTE
;			OSCLTBL	"SAVE",	_OSCLI_SAVE	,$00	; *SAVE	    &E23E, A=0	   XY=>String
;			OSCLTBL	"SPOOL",_OSCLI_SPOOL	,$00	; *SPOOL    &E281, A=0	   XY=>String
;			OSCLTBL	"TAPE",	_OSCLI_OSBYTE	,$8c	; *TAPE	    &E348, A=&8C   OSBYTE
;			OSCLTBL	"TV",	_OSCLI_OSBYTE	,$90	; *TV	    &E348, A=&90   OSBYTE
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


