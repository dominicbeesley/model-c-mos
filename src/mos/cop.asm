
		.include "cop.inc"
		.include "oslib.inc"
		.include "vectors.inc"
		.include "debug.inc"

		.export cop_handle_emu
		.export cop_handle_nat


	; The shim in bank 0 will already have switched to Native mode (to page in this address space)
		.a8
		.i8
cop_handle_emu: plp
		php                   		; Get back P as stacked on entry and resestablish interrupts
		rep   #$38			; turn of decimal mode, turn on big regs
		.a16
		.i16

		; massage the stack at this point to look as if we'd entered from native mode
		; i.e. insert a phoney FF for the pushed K register
		phb				; room for a little'un
		phd				; 8
		phb				; 7
		pha				; 5
		phx				; 3
		phy				; 1

	; Stack
	; 
	;	+12..13	PC
	;	+11	P
	;	+10	-spare-
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y


		lda	11,S
		sta	10,S
		lda	13,S
		ora	#$FF00
		sta	12,S

	; Stack
	; 	+13	PBR=$FF
	;	+11..12	PC
	;	+10	P
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y
		jsr	cop_dispatch_int

	; Stack
	; 	+13	PBR=$FF
	;	+11..12	PC-1	(dispatch code makes PC ready for an RTL instead of RTI!)
	;	+10	P
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y


	lda	11,S
	inc	A
	sta	12,S
	lda	10
	xba
	and	#$FF0
	sta	10,S


	; Stack
	; 	+12..13	PC
	;	+11	P	(dispatch code makes PC ready for an RTL instead of RTI!)
	;	+10	"0"
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y

		ply
		plx
		pla
		plb				; NOTE: this gets set back to 0
		pld				; NOTE: this gets set back to 0

	; Stack
	; 	+3..5	PC
	;	+2	P	(dispatch code makes PC ready for an RTL instead of RTI!)
	;	+1	"0"

		plb
		phb
		phb

	; Stack
	; 	+4..6	PC
	;	+3	P	(dispatch code makes PC ready for an RTL instead of RTI!)
	;	+2	"0"
	;	+1	"0"	# extra bytes to transfer to emu stack
	
		jml	nat2emu_rti		; native mode to emu mode exit shim

cop_handle_nat: plp
		php                   ;reestablish interrupts
		rep   #$38
		.a16
		.i16
		phd                   ;8
		phb                   ;7
		pha                   ;5
		phx                   ;3
		phy                   ;1
	; Stack
	; 	+13	PBR
	;	+11..12	PC
	;	+10	P
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y
		jsr	cop_dispatch_int
	; Stack
	; 	+13	PBR
	;	+11..12	PC-1	(dispatch code makes PC ready for an RTL instead of RTI!)
	;	+10	P
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y


		ply
		plx
		pla
		plb
		pld
		plp
		rtl

cop_dispatch_int:
		tsc
		inc	A
		inc	A
		tcd				; point DP at Stacked registers

		dec	DPCOP_PC        	;decrement 16 bit return pointer to point at the signature byte
		lda	[DPCOP_PC]      	;get signature byte
		asl	A               	;multiply by 2 to get index
		and	#$00ff          	;mask off whatever we fetched in high byte
		cmp	#tblCopDispatchLen	;compare to end of cop table
		bcs	@ret_unimplemented	;jump forward for high COPs
		tax				;transfer index to X
		lda	DPCOP_AH		;restore A from stack
		phk
; The callee stack will now look like this:
; 
; +16   PBR
; +14   PC
; +13   P
; +11   DP
; +10   B
; +8    A
; +6    X
; +4    Y
; +1    FE/B673 - return address of COP dispatcher
; 
; The DP register will point at byte below Y
; 
; +13   PBR
; +11   PC
; +10   P
; +8    DP
; +7    B
; +5    A
; +3    X
; +1    Y
		jsr   (.loword(tblCOPDispatch),x)	;long jump to handler in dispatch table
@ret:		rep   #$30
		.a16
		.i16
		tsc
		inc	A
		inc	A
		tcd				; point DP at Stacked registers
	; internal API Change cop handlers must set DPCOP_P explicitly
;;		php
;;		ror	DPCOP_P
;;		plp
;;		rol	DPCOP_P			; get returned Cy into flags
		rts

		.a16
		.i16
@ret_unimplemented:
		stz	DPCOP_X			;clear saved X
		lda	#$41
		tsb	DPCOP_P			;return error/V/Cy
		bra   @ret

tblCOPDispatch:	.word	.loword(COP_00)		;OPWRC 00 = OSWRCH
		.word	.loword(COP_01)		;OPWRS 01 = Write String Immediate
		.word	.loword(COP_02)		;OPWRA 02 = Write string at BHA
		.word	.loword(COP_03)		;OPNLI 03 = OSNEWL - write CR/LF
		.word   .loword(COP_04)		;OPRDC 04 = OSRDCH - read a char
		.word   .loword(COP_05)		;OPCLI 05 = OPCLI - execute command at BYX [deprecated]
		.word   .loword(COP_06)		;OPOSB 06 = OSBYTE
		.word   .loword(COP_07)		;OPOSW 07 = OSWORD
		.word   .loword(COP_08)		;OPCAV 08 = Call A Vector **NEW**
		.word   .loword(COP_NotImpl)	;9
		.word   .loword(COP_NotImpl)	;A
		.word   .loword(COP_NotImpl)	;B
		.word   .loword(COP_NotImpl)	;C
		.word   .loword(COP_NotImpl)	;D
		.word   .loword(COP_0E)		;OPCOM 0E = OPCOM - execute command at BHA
		.word   .loword(COP_NotImpl)	;F

		.word   .loword(COP_NotImpl)	;10
		.word   .loword(COP_NotImpl)	;11
		.word   .loword(COP_NotImpl)	;12
		.word   .loword(COP_NotImpl)	;13
		.word   .loword(COP_NotImpl)	;14
		.word   .loword(COP_15)		;OPASC = OSASCI - write and expand <CR> to <LF><CR>
		.word   .loword(COP_NotImpl)	;16
		.word   .loword(COP_NotImpl)	;17
		.word   .loword(COP_NotImpl)	;18
		.word   .loword(COP_NotImpl)	;19
		.word   .loword(COP_NotImpl)	;1A
		.word   .loword(COP_NotImpl)	;1B
		.word   .loword(COP_NotImpl)	;1C
		.word   .loword(COP_NotImpl)	;1D
		.word   .loword(COP_NotImpl)	;1E
		.word   .loword(COP_NotImpl)	;1F

		.word   .loword(COP_NotImpl)	;20
		.word   .loword(COP_NotImpl)	;21
		.word   .loword(COP_NotImpl)	;22
		.word   .loword(COP_NotImpl)	;23
		.word   .loword(COP_NotImpl)	;24
		.word   .loword(COP_NotImpl)	;24
		.word   .loword(COP_26)		;OPBHA - return address of immediate string in BHA
		.word   .loword(COP_NotImpl)	;27
		.word   .loword(COP_NotImpl)	;28
		.word   .loword(COP_NotImpl)	;29
		.word   .loword(COP_NotImpl)	;2A
		.word   .loword(COP_NotImpl)	;2B
		.word   .loword(COP_NotImpl)	;2C
		.word   .loword(COP_NotImpl)	;2D
		.word   .loword(COP_NotImpl)	;2E
		.word   .loword(COP_2F)		;OPIIQ - insert interrupt handler

		.word   .loword(COP_30)		;OPRIQ - remove interrupt handler
		.word   .loword(COP_31)		;OPMIQ - modify interrupt handler
		.word   .loword(COP_32)		;OPSUM - do carry-round checksum of memory area
		.word   .loword(COP_NotImpl)	;33
		.word   .loword(COP_NotImpl)	;34
		.word   .loword(COP_NotImpl)	;34
		.word   .loword(COP_NotImpl)	;36
		.word   .loword(COP_NotImpl)	;37
		.word   .loword(COP_NotImpl)	;38
		.word   .loword(COP_NotImpl)	;39
		.word   .loword(COP_NotImpl)	;3A
		.word   .loword(COP_NotImpl)	;3B
		.word   .loword(COP_NotImpl)	;3C
		.word   .loword(COP_NotImpl)	;3D
		.word   .loword(COP_NotImpl)	;3E
		.word   .loword(COP_NotImpl)	;3F

tblCopDispatchLen := *-tblCOPDispatch

;	********************************************************************************
;	* either: BYX contains the absolute address                                    *
;	* OR: Y(16) = 0 and X contains an offset from the direct page register D. The  *
;	* pointer is D+X.                                                              *
;	*                                                                              *
;	* This assumes a COP entry frame in DP                                         *
;	*                                                                              *
;	********************************************************************************
                .a16
                .i16
makeBYXptr:     php
                sep   #$30
                .i8
                .a8
                tya                   ;A(8)=Y(8)
                xba                   ;put Y in H
                lda   DPCOP_X         ;get X in A
                rep   #$30
                .a16
                .i16
                ldy   DPCOP_Y         ;check for 0 in Y
                bne   @ret
                clc                   ;if Y is zero
                lda   DPCOP_X         ;add original X to DP and set B=0
                adc   DPCOP_DP
                pea   $0000
                plb
                plb
@ret:           plp
                rts



;		********************************************************************************
;		* COP 15 - OPASC - BBC OPASCI                                                  *
;		*                                                                              *
;		* Action: Send the byte in A to the VDU drivers. If the byte is &0D (carriage  *
;		* return) then send &0A, &0D to the VDU drivers (line feed+ carriage return).  *
;		*                                                                              *
;		* On entry: A = character code.                                                *
;		* On exit:  DBAXY preserved                                                    *
;		********************************************************************************
COP_15:		and   #$00ff
                cmp   #$000d
                bne   COP_00
;		********************************************************************************
;		* COP 03 - OSNLI - BBC OSNEWL                                                  *
;		*                                                                              *
;		* Action: Send LF CR to the VDU drivers. Line feed is ASCII 10 (decimal),      *
;		* carriage return is ASCII 13 (decimal).                                       *
;		*                                                                              *
;		* On entry: No requirement                                                     *
;		* On exit:  DBAXY preserved                                                    *
;		********************************************************************************
COP_03:		lda   #$000a
                phk
                jsr   COP_00
                lda   #$000d

;		********************************************************************************
;		* COP 00 - OPWRC - Write Char in A                                             *
;		*                                                                              *
;		* Action: Send the byte in A to the VDU drivers.                               *
;		*                                                                              *
;		* On entry: A = character code                                                 *
;		* On exit:  DBAXY preserved                                                    *
;		*                                                                              *
;		********************************************************************************
COP_00:		cop	COP_08_OPCAV
		.byte   IX_WRCHV
		rtl


;		********************************************************************************
;		* COP 01 - OPWRS - write string immediate                                      *
;		*                                                                              *
;		* read characters from bytes following cop, check for 0 and pass on to write   *
;		* character routine                                                            *
;		********************************************************************************
COP_01:		inc	DPCOP_PC
		sep	#$20
		.a8
                lda	[DPCOP_PC]
                sta	DPCOP_AH
                rep	#$20
                .a16
                beq	@ret
                phd
                phk
                jsr	COP_00
                pld
                bra	COP_01

@ret:		rtl

;		********************************************************************************
;		* COP 02 - OPWRA - write string at BHA                                         *
;		*                                                                              *
;		* TODO: DOCO: NOTE: This seems to imply that X is set to 0 for 0 terminated, 1 *
;		* for control terminated string - not in systems manual                        *
;		*                                                                              *
;		********************************************************************************
COP_02:		lda   DPCOP_X         ;get passed X and check is < 2 and use to determine type of terminator
                lsr   A
                cmp   #$0002
                bcc   @skok
                brk   $00

                .byte "COP `OPWRA: invalid termination option"

@skok:		tax
                ldy   #$0000
@lp:		lda   [DPCOP_AH],y    ;use BHA at 05 as pointer
                and   #$00ff
                beq   @ret            ;check for 0 terminator
                cpx   #$0001
                bne   @sknocc         ;if X<>1 skip forwards
                cmp   #$0020
                bcc   @ret            ;else exit on control character
@sknocc:	phx
                phy
                phk
                jsr   COP_00
                ply
                plx
                iny
                bra   @lp

@ret:		rtl


COP_NotImpl:	sec
		stz	DPCOP_X
		rtl


;	********************************************************************************
;	* COP 04 - OPRDC - read a character from input                                 *
;	*                                                                              *
;	* No conditions                                                                *
;	*                                                                              *
;	* On exit:                                                                     *
;	* if C = 0 then A contains the ASCII value of the character.                   *
;	* if C = 1 then                                                                *
;	*   if HA = $1B (@SCESC) then the ESCAPE key was pressed                       *
;	*   if HA = $00 (@SCPRE) then the current task was pre-empted.                 *
;	*                                                                              *
;	* DBXY preserved                                                               *
;	********************************************************************************

COP_04:         cop	COP_08_OPCAV
		.byte   IX_RDCHV
		php
		ror	DPCOP_P
		plp
		rol 	DPCOP_P
		sta	DPCOP_AH
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

; ********************************************************************************
; * COP 26 - OPBHA                                                               *
; *                                                                              *
; * returns the immediate string following the COP call as BHA                   *
; ********************************************************************************
                .a16
                .i16
COP_26:	        lda   DPCOP_PC+1
                sta   DPCOP_AH+1
                lda   DPCOP_PC
                inc   A
                sta   DPCOP_AH
; This skips over any string following the cop call
@copExitImmedStr:
		inc  DPCOP_PC
                lda   [DPCOP_PC]
                and   #$00ff
                bne   @copExitImmedStr
                rtl


; ********************************************************************************
; * COP 05 - OPCLI - execute command line                                        *
; *                                                                              *
; * Action: This call sends the address of a command line string to the          *
; * operating system's command line interpreter. The string must be terminated   *
; * by CR (ASCII &0D).                                                           *
; * On entry: either: BYX contains the absolute address of the start of the      *
; * command line                                                                 *
; * OR: Y is 0 and X contains an offset from the direct page register D. The     *
; * start of the command line is in the direct page at address D+X.              *
; * On exit: No registers preserved                                              *
; ********************************************************************************
                .a16
                .i16
COP_05:          jsr   makeBYXptr
; ********************************************************************************
; * COP 0E OPCOM - execute command at BHA                                        *
; *                                                                              *
; * Action: This call sends the address of a command line string to the          *
; * operating system's command line interpreter. The string must be terminated   *
; * by CR (ASCII &0D).                                                           *
; * On entry: BHA points to the start of the command                             *
; * On exit: No registers preserved                                              *
; ********************************************************************************
                .a16
                .i16
COP_0E:         phd

		jsl	windowPush
		phy

		txa
		xba
		tay

		cop	COP_08_OPCAV
		.byte	IX_CLIV

		ply
		jsl	windowPop


                pld                   ;back to COP DP that points at user stack


                sta   DPCOP_AH
                stx   DPCOP_X
                sty   DPCOP_Y
                sep   #$30
                .a8
                .i8
                phb
                pla
                sta   DPCOP_B
                rtl


;	********************************************************************************
;	* COP 32 - OPSUM - compute end-around-carry sum                                *
;	*                                                                              *
;	* Action: Gives a sum of all the bits in a block whose start is pointed to by  *
;	* BHA and whose length in bytes is in Y.                                       *
;	*                                                                              *
;	* On entry: BHA points to thestartof the block to be summed.                   *
;	*           Y = length of block in bytes.                                      *
;	* On exit:  If C = 0 then thesum has been computed and the result is in HA.    *
;	*           If C = 1 then either the length was zero (Y = 0)                   *
;	*           DXY preserved                                                      *
;	*                                                                              *
;	* API change: Also returns Z if the word after the block contains a matching   *
;       * checksum but NOT if all the bytes in the block are zeroes                    *
;	*                                                                              *
;	********************************************************************************
		.i16
		.a16

COP_32:         tyx                   ;byte count into X
                beq   @retzsec
                lda   #$0000          ;sum
                tay                   ;zero offset
                clc
@lp:            dex
                bne   @nla            ;if zero here then 1 byte left
                pha
                lda   [DPCOP_AH],y
                iny
                and   #$00ff
                adc   $01,S           ;add to low part of stacked A
                sta   $01,S
                pla                   ;pop A
                bra   @fin	      ;and return

@nla:           adc   [DPCOP_AH],y
                iny
                iny
                dex
                bne   @lp
@fin:        	adc   #$0000          ;add last carry in
                tax			; we're going to update DPCOP_AH but still want a pointer
                eor   [DPCOP_AH],y    ;this looks to additionally check against any checksum after the block
                stx   DPCOP_AH
                eor	#0		; set Z flag based on compare result
                clc
                jmp	rtlflags

@retzsec:       stz   DPCOP_AH
                sec
                jmp	rtlflags



rtlflags:	sep	#$30
		.a8
		.i8
		php
		lda	1,S
		eor	DPCOP_P
		and	#$CF			; keep original M/X flags
		eor	DPCOP_P			; get back Caller's flags and nothing else
		sta	DPCOP_P			; set flags but keep M/X from caller
		plp
		rtl
