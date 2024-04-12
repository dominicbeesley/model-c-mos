
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

		sep	#$30		; disable interrupts!
		.a8
		.i8
		pha					; save A
			php					; save Processor flags
			sei					; disable interrupts
			sta	OSW_A				; store A,X,Y in zero page
			stx	OSW_X				; 
			sty	OSW_Y				; 
			ldx	#$07				; X=7 to signal osbyte is being attempted
			cmp	#$75				; if A=0-116
			bcc	_BE7C2				; then E7C2
			cmp	#$a1				; if A<161
			bcc	_BE78E				; then E78E
			cmp	#$a6				; if A=161-165
			bcc	_BE7C8				; then EC78
			clc					; clear carry

_BE78A:			lda	#$a1				; A=&A1
			adc	#$00				; 

;********* process osbyte calls 117 - 160 *****************************

_BE78E:			sec					; set carry
			sbc	#$5f				; convert to &16 to &41 (22-65)

_BE791:			asl					; double it (44-130)
			sec					; set carry

_BE793:			sty	OSW_Y				; store Y
			tay					; Y=A
			bit	OSB_ECONET_INT			; read econet intercept flag
			bpl	_BE7A2				; if no econet intercept required E7A2

			txa					; else A=X
			clv					; V=0
			jsr	_NETV				; to JMP via ECONET vector
			bvs	_LE7BC				; if return with V set E7BC

_BE7A2:			lda	_OSBYTE_TABLE + 1,Y		; get address from table
			sta	MOS_WS_1			; store it as hi byte
			lda	_OSBYTE_TABLE,Y			; repeat for lo byte
			sta	MOS_WS_0			; 
			lda	OSW_A				; restore A
			ldy	OSW_Y				; Y
			bcs	_BE7B6				; if carry is set E7B6

			ldy	#$00				; else
			lda	(OSW_X),Y			; get value from address pointed to by &F0/1 (Y,X)

_BE7B6:			sec					; set carry
			ldx	OSW_X				; restore X
			jsr	_LF058				; call &FA/B

_LE7BC:			ror					; C=bit 0
			plp					; get back flags
			rol					; bit 0=Carry
			pla					; get back A
			clv					; clear V
			rts					; and exit

;*************** Process OSBYTE CALLS BELOW &75 **************************

_BE7C2:			ldy	#$00				; Y=0
			cmp	#$16				; if A<&16
			bcc	_BE791				; goto E791

_BE7C8:			php					; push flags
			php					; push flags

_BE7CA:			pla					; pull flags
			pla					; pull flags
			jsr	_OSBYTE_143			; offer paged ROMS service 7/8 unrecognised osbyte/word
			bne	_BE7D6				; if roms don't recognise it then E7D6
			ldx	OSW_X				; else restore X
			jmp	_LE7BC				; and exit

_BE7D6:			plp					; else pull flags
			pla					; and A
			bit	_BD9B7				; set V and C
			rts					; and return

_CFS_CHECK_BUSY:	lda	CRFS_ACTIVE			; read cassette critical flag bit 7 = busy
			bmi	_BE812				; if busy then EB12

			lda	#$08				; else A=8 to check current Catalogue status
			and	CRFS_STATUS			; by anding with CFS status flag
			bne	__check_busy_cfs_done		; if not set (not in use) then E7EA RTS
			lda	#$88				; A=%10001000
			and	CRFS_OPTS			; AND with FS options (short msg bits)
__check_busy_cfs_done:	rts					; RETURN


;**************************************************************************
;**************************************************************************
;**									 **
;**	 OSWORD	 DEFAULT ENTRY POINT					 **
;**									 **
;**	 pointed to by default WORDV					 **
;**									 **
;**************************************************************************
;**************************************************************************

_WORDV:			pha					; Push A
			php					; Push flags
			sei					; disable interrupts
			sta	OSW_A				; store A,X,Y
			stx	OSW_X				; 
			sty	OSW_Y				; 
			ldx	#$08				; X=8
			cmp	#$e0				; if A=>224
			bcs	_BE78A				; then E78A with carry set

			cmp	#$0e				; else if A=>14
			bcs	_BE7C8				; else E7C8 with carry set pass to ROMS & exit

			adc	#$44				; add to form pointer to table
			asl					; double it
			bcc	_BE793				; goto E793 ALWAYS!! (carry clear E7F8)
								; this reads bytes from table and enters routine

doOSWORD:	DEBUG_PRINTF "OSWORD #%A, X=%X, Y=%Y\n"
		sec
		rtl		