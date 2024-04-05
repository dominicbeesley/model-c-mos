
		.include "cop.inc"
		.include "oslib.inc"
		.include "vectors.inc"

		.export cop_handle_emu
		.export cop_handle_nat


	; The shim in bank 0 will already have switched to Native mode (to page in this address space)
		.a8
		.i8
cop_handle_emu: plp
		php                   		; Get back P as stacked on entry
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
		and	#$00FF
		sta	11,S

	; Stack
	; 	+13	PBR=0
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

		jml	nat2emu_rtl		; native mode to emu mode exit shim

cop_handle_nat: plp
		php                   ;Not sure what this sequence is for, reestablish caller's SEI or SED flags - seems dodgy
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
		php
		ror	DPCOP_P
		plp
		rol	DPCOP_P			; get returned Cy into flags
		rts

		.a16
		.i16
@ret_unimplemented:
		stz	DPCOP_X			;clear saved X
		sec				;return error
		bra   @ret

tblCOPDispatch:	.word	.loword(COP_00)		;OPWRC 00 = OSWRCH
		.word	.loword(COP_01)		;OPWRS 01 = Write String Immediate
		.word	.loword(COP_02)		;OPWRA 02 = Write string at BHA
		.word	.loword(COP_03)		;OPNLI 03 = OSNEWL - write CR/LF
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)

		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_NotImpl)
		.word   .loword(COP_15)			;OPASC = OSASCI - write and expand <CR> to <LF><CR>

tblCopDispatchLen := *-tblCOPDispatch


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
COP_00:		pea	IX_WRCHV
		pld
		jml	CallAVector_NAT


;		********************************************************************************
;		* COP 01 - OPWRS - write string immediate                                      *
;		*                                                                              *
;		* read characters from bytes following cop, check for 0 and pass on to write   *
;		* character routine                                                            *
;		********************************************************************************
COP_01:		inc   DPCOP_PC
                lda   [DPCOP_PC]
                and   #$00ff
                beq   @ret
                phd
                phk
                jsr   COP_00
                pld
                bra   COP_01

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