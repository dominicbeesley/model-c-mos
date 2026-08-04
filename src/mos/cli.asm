		.include "nat-layout.inc"
		.include "oslib.inc"
		.include "dp_bbc.inc"
		.include "sysvars.inc"

		.include "modules_i.inc"
		.include "gsread_i.inc"
		.include "brk_i.inc"
		.include "utils_i.inc"
		.include "b0blocks_i.inc"

		.export doCLIV


.proc _LE004:near
		.a8
		.i8
		lda	f:_OSCLI_TABLE + 2,X		; Get table parameter
		bmi	exitrts				; If >=&80, number follow
		; else string follows

.proc _LE009:near
		.a8
		.i8
		phy					; Pass Y line offset to A for later
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

.endproc
exitrts:	rts					
.endproc

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
		jsr	_LE004::_LE009	; Convert &F2/3,Y->XY, ignore returned A
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
		; push routine pointer	FAR - is this necessary?
		pha					
		lda	f:_OSCLI_TABLE + 1,X		
		pha					
		jsr	utilSkipSpace			
		clc					
		php					
		jsr	_LE004				
		rti					; Jump to routine


.endproc




; Pass command on to other ROMs and to filing system
.proc doSvc4:far
		.a8
		.i8
		ldy	dp_mos_OS_wksp			; Restore pointer to start of command
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
exitrtl:	rtl
.endproc


		.macro OSCLTBL str, hand, val
			.byte	str, >hand, <hand, val
		.endmacro

;**** COMMMANDS ****
;				Command    	Address	   	A/number	Call goes to
_OSCLI_TABLE:		
			OSCLTBL	".",		_OSCLI_FSCV	,$05	; *.	    &E031, A=5	   FSCV, XY=>String
_OSCLI_TABLE2:		
			OSCLTBL	"FX",		_OSCLI_FX	,$ff	; *FX	    &E342, A=&FF   Number parameters
			OSCLTBL	"BASIC",	_OSCLI_BASIC	,$00	; *BASIC    &E018, A=0	   XY=>String
			OSCLTBL	"CAT",		_OSCLI_FSCV	,$05	; *CAT	    &E031, A=5	   FSCV, XY=>String
			OSCLTBL	"CODE",		_OSCLI_OSBYTE	,$88	; *CODE	    &E348, A=&88   OSBYTE &88
;			OSCLTBL	"EXEC",		_OSCLI_EXEC	,$00	; *EXEC	    &F68D, A=0	   XY=>String
			OSCLTBL	"HELP",		_OSCLI_HELP	,$ff	; *HELP	    &F0B9, A=&FF   F2/3=>String
;			OSCLTBL	"KEY",		_OSCLI_KEY	,$ff	; *KEY	    &E327, A=&FF   F2/3=>String
			OSCLTBL	"LOAD",		_OSCLI_LOAD	,$00	; *LOAD	    &E23C, A=0	   XY=>String
;			OSCLTBL	"LINE",		_OSCLI_USERV	,$01	; *LINE	    &E659, A=1	   USERV, XY=>String
;;			OSCLTBL	"MOTOR",	_OSCLI_OSBYTE	,$89	; *MOTOR    &E348, A=&89   OSBYTE
			OSCLTBL	"MODULES",	_OSCLI_MODULES	,$00	; *MODULES  !!!! NEW !!!!!
			OSCLTBL	"OPT",		_OSCLI_OSBYTE	,$8b	; *OPT	    &E348, A=&8B   OSBYTE
			OSCLTBL	"RUN",		_OSCLI_FSCV	,$04	; *RUN	    &E031, A=4	   FSCV, XY=>String
;;			OSCLTBL	"ROM",		_OSCLI_OSBYTE	,$8d	; *ROM	    &E348, A=&8D   OSBYTE
			OSCLTBL	"SAVE",		_OSCLI_SAVE	,$00	; *SAVE	    &E23E, A=0	   XY=>String
;			OSCLTBL	"SPOOL",	_OSCLI_SPOOL	,$00	; *SPOOL    &E281, A=0	   XY=>String
			OSCLTBL	"TAPE",		_OSCLI_OSBYTE	,$8c	; *TAPE	    &E348, A=&8C   OSBYTE
			OSCLTBL	"TV",		_OSCLI_OSBYTE	,$90	; *TV	    &E348, A=&90   OSBYTE
			OSCLTBL "GO",		_OSCLI_GO	,$80	; *GO (NEW)
			OSCLTBL "BOBDUMP",	_OSCLI_B0BDUMP	,$00	; dump B0B block info
			OSCLTBL	"",		_OSCLI_FSCV	,$03	; Unmatched &E031, A=3	   FSCV, XY=>String			
			.byte	$00				; Table end marker


_OSCLI_FSCV:
		cop	COP_08_OPCAV
		.byte	IX_FSCV
		rtl


; *BASIC
; ======
_OSCLI_BASIC:		ldx	sysvar_ROMNO_BASIC	; Get BASIC ROM number
			bpl	@ok
			jmp	.loword(doSvc4)		; If none set, jump to pass command on
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
.proc _OSCLI_HELP:far
		phy						; save Y for later passing to modules
keys:			
		sty	dp_mos_OS_wksp
		ldx	#$00				
		beq	tbllpfirst				

matlp:		eor	f:tblHELP,X			
		and	#$df				
		bne	skNotMatch				
		iny					
		clc					

tbllp:		bcs	hadDot					; skip forward if '.'
		inx					
tbllpfirst:	lda	(dp_mos_txtptr),Y			
		jsl	utilsAisAlpha				
		bcc	matlp				

		lda	f:tblHELP,X			
		beq	endstr				
		lda	(dp_mos_txtptr),Y			
		cmp	#'.'				
		beq	skDot				
skNotMatch:	clc					
		ldy	dp_mos_OS_wksp				
		dey					
skDot:		iny					
		inx					
		inx
skaddlp:	inx					
		lda	f:tblHELP - 4,X		
		beq	tbllp
		inc	A
		beq	doSvc9
		bra	skaddlp			; skip forwards to pointer

endstr:		inx					
		inx					
		inx					
		inx					

hadDot:		dex					
		dex					
		dex		

		; save pointer
		phy
		; push return address
		phk
		per	@ret-1

		; push routine pointer
		lda	f:tblHELP + 2,X
		pha					
		lda	f:tblHELP + 1,X		
		pha					
		lda	f:tblHELP,X		
		pha					
		php					
		rti					; Jump to routine

@ret:		ply
		bra	keys


doSvc9:
		ply
		phy
		ldx	#SERVICE_9_HELP			; 
		lda	#OSBYTE_143_SERVICE_CALL
		cop	COP_06_OPOSB			; 


		ply
		jsr	utilSkipSpace	
		bne	@nomos

		; show MOS if no other params

		cop	COP_01_OPWRS			; print following message routine return after BRK
		.byte	$0d,$0a				; carriage return
		.byte	"MODEL C MOS 6.00"		; help message
		.byte	$0d,$0a				; carriage return
		.byte    "  MODULES"
		.byte	$0d,$0a				; carriage return
		.byte 	0


@nomos:			rtl					; 
.endproc
		.macro HENT keyword, fn
		.asciiz keyword
		.faraddr fn
		.endmacro

tblHELP:	HENT "MODULES", modules_help
		.byte $FF

;*************************************************************************
;*									 *
;*	 *FX   OSBYTE							 *
;*									 *
;*************************************************************************
;	A=number

.proc _OSCLI_FX:far
		jsr	utilReadDigits8bit		; convert the number to binary
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
; DB: Cy on entry - expect space sep, else commas

.proc _OSCLI_OSBYTE:far
		pha					; save A
		lda	#$00				; clear &E4/E5
		sta	dp_mos_GSREAD_characc		; 
		sta	dp_mos_GSREAD_quoteflag		; 
		jsr	_LE043				; skip commas and check for newline (CR)
		beq	_BE36C				; if CR found E36C
		jsr	utilReadDigits8bit		; convert character to binary
		bcc	_badCmd				; if bad character bad command error
		stx	dp_mos_GSREAD_characc		; else save it
		jsr	utilSkipComma			; skip comma and check CR
		beq	_BE36C				; if CR then E36C
		jsr	utilReadDigits8bit		; get another parameter
		bcc	_badCmd				; if bad error
		stx	dp_mos_GSREAD_quoteflag		; else store in E4
		jsr	utilSkipSpace			; now we must have a newline
		bne	_badCmd				; if none then output an error

_BE36C:		ldy	dp_mos_GSREAD_quoteflag		; Y=third osbyte parameter
		ldx	dp_mos_GSREAD_characc		; X=2nd
		pla					; A=first
		cop	COP_06_OPOSB			; call osbyte
		bvs	_badCmd				; if V set on return then error
		rtl					; else RETURN

_LE043:		bcc	@ss
		jmp	utilSkipComma
@ss:		jmp	utilSkipSpace			

.endproc 

.proc addnibble32:near
		php
		rep	#$30
		.a16
		.i16
		phy
		ldy	#4

		ror	A
		ror	A
		ror	A
		ror	A
		ror	A	; left align nybble

@lp:		rol	A
		pha
		lda	f:B0_OSFILE_BLOCK + 0,X
		rol	A
		sta	f:B0_OSFILE_BLOCK + 0,X
		lda	f:B0_OSFILE_BLOCK + 2,X
		rol	A
		sta	f:B0_OSFILE_BLOCK + 2,X
		pla
		bcs	brkBadAddress
		dey
		bne	@lp
		ply
		plp		
		rts
.endproc

	; Read a hex digit
	; On Entry:
	;	dp_mos_txtptr,Y	string to parse as hex
	;	B0_OSFILE_BLOCK,X	to store 32 bit number
	; On Exit:
	;	Cy=0		No hex number found
	;	Z		set if end of line reached
	;	A 		corrupted
	;	B0_OSFILE_BLOCK,X	I Cy=1 contains updated number else is left intact
	;Skip spaces at (dp_mos_txtptr),Y
.proc loadsave_readhex32:near
		;!.i?
		.a8
		jsr	utilSkipSpace
		jsr	_CHECK_FOR_HEX
		bcc	@retclc
		jsr	clearhex32
@lp:		jsr	addnibble32
		jsr	_CHECK_FOR_HEX
		bcs	@lp
		sec
		rts
@retclc:	clc				; no number found
		rts
.endproc


.proc _OSCLI_GO:far
		.a8
		.i8
		ldx	#2				; use LOAD address space
		jsr	loadsave_readhex32
		bcc	brkBadAddress
		phk
		pea	@rtl-1
		jml	[B0_OSFILE_BLOCK + 2]		; jump indirect, assume rtl and native
@rtl:		rtl
.endproc


;*************************************************************************
;*									 *
;*	 *LOAD ENTRY							 *
;*									 *
;*************************************************************************

.proc _OSCLI_LOAD:far
		.a8
		.i8
		lda	#$ff				; signal that load is being performed
.endproc ; fall through

;*************************************************************************
;*									 *
;*	 *SAVE ENTRY							 *
;*									 *
;*************************************************************************
;on entry A=0 for save &ff for load

.proc _OSCLI_SAVE:far
		.a8
		.i8
		pha					; Push A (FF or 00)
		stx	dp_mos_txtptr			; store address of rest of command line
		sty	dp_mos_txtptr+1			; 
		txa
		sta	f:B0_OSFILE_BLOCK		; x and Y are stored in OSfile control block
		tya
		sta	f:B0_OSFILE_BLOCK+1		; 		
		lda	#$ff				; Y=255
		sta	f:B0_OSFILE_BLOCK+2		; bank is always FF for string (maybe WINDOW!)
		sta	f:B0_OSFILE_BLOCK+8			; store in low byte of exec address (signal no address in load/save)

		ldy	#0
		jsr	_clcGSINIT			; and call GSINIT to prepare for reading text line
@lp:		jsr	_GSREAD				; read a code from text line if OK read next
		bcc	@lp				; until end of line reached
		ldx	#$04				; X=4 (load address)
		pla					; get back A without stack changes
		pha					; 
		beq	_BE2C2				; IF A=0 (SAVE)	 E2C2
		jsr	loadsave_readhex32		; set up file block
		bcs	_BE2A0				; if carry set do OSFILE
		beq	_BE2A5				; if A=0 line ended OSFILE else bad address
.endproc ; fall through
brkBadAddress:	brk					; 
		.byte	$fc				; 
		.byte	"Bad address"			; error
		brk					; 

.proc	_BE2A0:near
		.a8
		.i8
		bne	brkBadCommand
		lda	#0
		sta	f:B0_OSFILE_BLOCK+8		; indicate address provided
.endproc
.proc	_BE2A5:near
		.a8
		.i8

		pla
		sta	f:B0_OSFILE_BLOCK+3
		cop	COP_27_OPBHI
		.faraddr	B0_OSFILE_BLOCK
		cop	COP_0C_OPFILE
		rtl
.endproc

.proc	_BE2C2:near
		.a8
		.i8
		ldx	#12				; start address for save
		jsr	loadsave_readhex32		; 
		bcc	brkBadCommand			; if no hex digit found EXIT via BAD Command error
		clv					

;******************READ file length from text line************************

		lda	(dp_mos_txtptr),Y		; read next byte from text line
		cmp	#'+'				; is it '+'
		bne	_BE2D4				; if not assume its a last byte address so e2d4
		sep	#$c0				; else set V and M flags
		iny					; increment Y to point to hex group

_BE2D4:		ldx	#16				; end address for save
		jsr	loadsave_readhex32		; 
		bcc	brkBadCommand			; if carry clear no hex digit so exit via error
		php					; save flags
		rep	#$21				; clear carry, 16 bit accumulator
		.a16
		bvc	_BE2ED				; if V set them E2ED explicit end address found
		ldx	#256-4
@alp:		lda	f:B0_OSFILE_BLOCK+16-(256-4),X
		adc	f:B0_OSFILE_BLOCK+12-(256-4),X
		sta	f:B0_OSFILE_BLOCK+16-(256-4),X
		inx
		inx
		bne	@alp

_BE2ED:		ldx	#$02				; X=3
_BE2EF:		lda	f:B0_OSFILE_BLOCK+12		; copy start adddress to load and execution addresses
		sta	f:B0_OSFILE_BLOCK+4
		sta	f:B0_OSFILE_BLOCK+8
		dex					; 
		dex
		bpl	_BE2EF				; 
		plp					; get back flag
		.a8
		beq	_BE2A5				; if end of command line reached then E2A5
							; to do osfile
		ldx	#$08				; else set up execution address
		jsr	loadsave_readhex32		; 
		bcc	brkBadCommand			; if error BAD COMMAND
		beq	_BE2A5				; and if end of line reached do OSFILE

		ldx	#$04				; else set up load address
		jsr	loadsave_readhex32		; 
		bcc	brkBadCommand			; if error BAD command
		beq	_BE2A5				; else on end of line do OSFILE
							; anything else is an error!!!!

.endproc ; fall through


.proc brkBadCommand
		brk					; 
		.byte	$fe				; error number
		.byte	"Bad command"			; 
		.byte   0
.endproc


.proc	clearhex32:near
		;!.i?
		;!.a?
		php
		rep	#$20
		pha
		.a16
		lda	#0
		sta	f:B0_OSFILE_BLOCK + 0,X
		sta	f:B0_OSFILE_BLOCK + 2,X
		pla
		plp
		rts
.endproc






_OSCLI_B0BDUMP: jmp B0BDump
_OSCLI_MODULES: jml modules_list			; we need to trampoline this to ensure high bit set in address?