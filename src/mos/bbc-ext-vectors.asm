
		.include "dp_sys.inc"
		.include "hardware.inc"
		.include "deice.inc"
		.include "debug.inc"
		.include "vectors.inc"


		.segment "BBC_EXT_VECS"

STACK=$100

		.i8
		.a8
	
; These are the BBC extended vector entry points, they should
; be entered in emulation mode only

; the entry points below bounce to the routine doExtended which
; uses the return address here to figure out which vector

		jsr	doExtended			; XUSERV
		jsr	doExtended			; XBRKV
		jsr	doExtended			; XIRQ1V
		jsr	doExtended			; XIRQ2V
		jsr	doExtended			; XCLIV
		jsr	doExtended			; XBYTEV
		jsr	doExtended			; XWORDV
		jsr	doExtended			; XWRCHV
		jsr	doExtended			; XRDCHV
		jsr	doExtended			; XFILEV
		jsr	doExtended			; XARGSV
		jsr	doExtended			; XBGETV
		jsr	doExtended			; XBPUTV
		jsr	doExtended			; XGBPBV
		jsr	doExtended			; XFINDV
		jsr	doExtended			; XFSCV
		jsr	doExtended			; XEVENTV
		jsr	doExtended			; XUPTV
		jsr	doExtended			; XNETV
		jsr	doExtended			; XVDUV
		jsr	doExtended			; XKEYV
		jsr	doExtended			; XINSV
		jsr	doExtended			; XREMV
		jsr	doExtended			; XCNPV
		jsr	doExtended			; XIND1V
		jsr	doExtended			; XIND2V
		jsr	doExtended			; XIND3V

;at this point the stack will hold 4 bytes (at least)
;S 0,1 extended vector address
;S 2,3 address of calling routine
;A,X,Y,P will be as at entry

doExtended:		

	; STACK  offset	descriptions
	;	+3..4	caller return - return address from original caller
	;	+1..2	"return" address to jsr in table above

		pea	returnExtended-1
		pha					; reserve space
		pha					; reserve space
		php					; save flags on stack
		pha					; save A on stack
		phy

	; STACK  offset	descriptions
	;	+10..11	caller return - return address from original caller
	;	+8..9	"return" address to jsr in table above
	;	+6..7	returnExtended exit routine -1
	;	+4..5	-spare-
	;	+3	Flags
	;	+2	A
	;	+1	Y

		lda	8,S				; this is VECTOR number*3+2!!
		tay
		lda	EXT_USERV-1,Y			; lo byte of action address
		sta	4,S				; store it on stack
		lda	EXT_USERV-2,Y			; get hi byte
		sta	5,S				; store it on stack


	; STACK  offset	descriptions
	;	+10..11	caller return - return address from original caller
	;	+8..9	-spare-
	;	+6..7	returnExtended exit routine -1
	;	+4..5	ROM routine to be called
	;	+3	Flags
	;	+2	A
	;	+1	Y

		lda	z:dp_mos_curROM			; 
		sta	9,S				; store original ROM number below this
		lda	EXT_USERV,Y			; get new ROM number
		sta	z:dp_mos_curROM			; store it as ram copy
		sta	a:.loword(sheila_ROMCTL_SWR)	; and switch to that ROM

	; STACK  offset	descriptions
	;	+10..11	caller return - return address from original caller
	;	+9	caller's rom #
	;	+8	-spare-
	;	+6..7	returnExtended exit routine -1
	;	+4..5	ROM routine to be called
	;	+3	Flags
	;	+2	A
	;	+1	Y


		ply					; get back Y
		pla					; get back A
		rti					; get back flags and jump to ROM vectored entry

	; The ROM routine will enter with the stack:
	; STACK  offset	descriptions
	;	+5..6	caller return - return address from original caller
	;	+4	caller's rom #
	;	+3	-spare-
	;	+1..2	returnExtended exit routine -1




;************ return address from ROM indirection ************************

;at this point stack comprises original ROM number,return from JSR &FF51,
;return from original call the return from FF51 is garbage so;

returnExtended:
	; STACK  offset	descriptions
	;	+3..4	caller return - return address from original caller
	;	+2	caller's rom #
	;	+1	-spare-

			php					; save flags on stack
			sta	2,S				; save A on stack

	; STACK  offset	descriptions
	;	+4..5	caller return - return address from original caller
	;	+3	caller's rom #
	;	+2	A save
	;	+1	Flags


			lda	3,S
			sta	z:dp_mos_curROM			; store it
			sta	a:.loword(sheila_ROMCTL_SWR)	; and set it

			lda	1,S				; hiding garbage by duplicating A and X just saved
			sta	3,S				; 


	; STACK  offset	descriptions
	;	+4..5	caller return - return address from original caller
	;	+3	Flags
	;	+2	A
	;	+1	-spare-

			pla					; skip spare
			pla					; get back A
			plp					; get back flags
_NOTIMPV:		rts					; return and exit pulling original return address
