
		.include "dp_bbc.inc"
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


	; note this could be (and was) optimized further but has been put
	; back so that the stack will contain the same information as
	; certain ROMs rely on and manipulate the stack contents
doExtended:		

	; STACK  offset	descriptions
	;	+3..4	caller return - return address from original caller
	;	+1..2	"return" address to jsr in table above

		pha
		pea	returnExtended-1
		pha					; reserve space
		pha					; reserve space
		php					; save flags on stack
		pha					; save A on stack
		phy

	; STACK  offset	descriptions
	;	+11..12	caller return - return address from original caller
	;	+9..10	"return" address to jsr in table above
	;	+8	-spare-
	;	+6..7	returnExtended exit routine -1
	;	+4..5	-spare-
	;	+3	Flags
	;	+2	A
	;	+1	Y

		lda	9,S				; this is VECTOR number*3+2!!
		tay
		lda	EXT_USERV-2,Y			; lo byte of action address
		sta	4,S				; store it on stack
		lda	EXT_USERV-1,Y			; get hi byte
		sta	5,S				; store it on stack


	; STACK  offset	descriptions
	;	+11..12	caller return - return address from original caller
	;	+9..10	"return" address to jsr in table above
	;	+8	-spare-
	;	+6..7	returnExtended exit routine -1
	;	+4..5	ROM routine address
	;	+3	Flags
	;	+2	A
	;	+1	Y

		lda	z:dp_mos_curROM			; 
		sta	8,S				; store original ROM number below this
		lda	EXT_USERV,Y			; get new ROM number
		sta	z:dp_mos_curROM			; store it as ram copy
		sta	a:.loword(sheila_ROMCTL_SWR)	; and switch to that ROM

	; STACK  offset	descriptions
	;	+11..12	caller return - return address from original caller
	;	+9..10   "return" address to jsr in table above
	;	+8	caller's rom #
	;	+6..7	returnExtended exit routine -1
	;	+4..5	ROM routine to be called
	;	+3	Flags
	;	+2	A
	;	+1	Y


		ply					; get back Y
		pla					; get back A
		rti					; get back flags and jump to ROM vectored entry

	; STACK  offset	descriptions
	;	+6..7	caller return - return address from original caller
	;	+4..5   "return" address to jsr in table above
	;	+3	caller's rom #
	;	+1..2	returnExtended exit routine -1




;************ return address from ROM indirection ************************

;at this point stack comprises original ROM number,return from JSR &FF51,
;return from original call the return from FF51 is garbage so;

returnExtended:
	; STACK  offset	descriptions
	;	+4..5	caller return - return address from original caller
	;	+2..3   "return" address to jsr in table above
	;	+1	caller's rom #

			php					; save flags on stack
			sta	3,S				; save A on stack

	; STACK  offset	descriptions
	;	+5..6	caller return - return address from original caller
	;	+4       -spare-
	;	+3	saved A
	;	+2	caller's rom #
	;	+1	Flags

			pla
			sta	3,S

	; STACK  offset	descriptions
	;	+4..5	caller return - return address from original caller
	;	+3       saved Flags (moved)
	;	+2	saved A
	;	+1	caller's rom #

			pla
			sta	z:dp_mos_curROM			; store it
			sta	a:.loword(sheila_ROMCTL_SWR)	; and set it


	; STACK  offset	descriptions
	;	+4..5	caller return - return address from original caller
	;	+3       saved Flags (moved)
	;	+2	saved A

			pla					; get back A
			plp					; get back flags
_NOTIMPV:		rts					; return and exit pulling original return address
