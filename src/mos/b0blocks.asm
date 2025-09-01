
		.include	"nat-layout.inc"


		.export	initB0Blocks:far
		.export	freeB0Block:far
		.export	allocB0Block:far

		.export	initHandles:far
		.export findHandleByAddr:far
		.export allocHandle:far
		.export getHandleYtoX:far
		.export freeHandleForB0BlockX:far

	; b0blocks are 12 byte long blocks that are pre-allocated in bank 0 
	; that can be allocated by the OS. They are typically used to contain
	; information associated with a handle.
	; the blocks are 12 bytes long with only the byte at offset 11 having
	; a definitive purpose (a type indicator).


	; These are inspired by the Communicator MOS blocks (See de/cdb5 on in MOS100)


.proc initB0Blocks:far
		php
		rep  	 #$30
		.a16
		.i16
		lda	#$0000
		sta	f:B0LL_FREE_BLOCKS		; set list to empty
		lda	#.loword(B0LL_FREE_BLOCKS)
		sta	f:B0LL_FREE_BLOCKS_END		; point table back at list start
		lda	#B0B_BASE	
@lp:		pha
		tax
		jsl	freeB0Block
		pla
		clc
		adc	#B0B_SIZE
		cmp	#B0B_END
		bcc	@lp
		plp
		rtl
.endproc

;	********************************************************************************
;	* Return the block pointed to X to the free list                               *
;	*                                                                              *
;	* On Entry:                                                                    *
;	*    X   is a pointer to a B0Block                                             *
;	********************************************************************************
.proc freeB0Block:far
		phy
		php
		sei
		rep	#$30
		.i16
		.a16
		txy                   			
		lda	#$0000
		sta	f:b0b_ll_free::next,x		; clear X->[0]
		;TODO: change to 16 bit store-1?
		sep	#$20
		.a8
		sta	f:b0b_ll_free::type,x		; clear X->[b]
		rep	#$20
		.a16
		lda	f:B0LL_FREE_BLOCKS_END		
		tax					; X - will point to a block or the list 	
							; start pointer when empty
		tya					; A=org X
		sta	f:$000000,x			; store pointer to block being freed in 
							; "last" or the list start pointer when 
							; empty
		sta	f:B0LL_FREE_BLOCKS_END
		plp
		ply
		clc
		rtl
.endproc

;	********************************************************************************
;	* Allocate a B0Block from the free list                                        *
;	*                                                                              *
;	* On entry:                                                                    *
;	*     A   contains the B0B type                                                *
;	*                                                                              *
;	* On exit:                                                                     *
;	* If Cy=1:                                                                     *
;	*     X=A on entry there was an error not allocated                            *
;	* If Cy=0:                                                                     *
;	*     X=A=B0 pointer to 12 byte block with type set, other fields = $FF        *
;	*                                                                              *
;	*                                                                              *
;	*******************************************************************************

.proc allocB0Block:far
		php
		sei
		rep	#$30
		.a16
		.i16
		tax
		lda	f:B0LL_FREE_BLOCKS
		bne	 @ok
		plp
		sec
		rtl
@ok:		phx
		tax
		cmp	f:B0LL_FREE_BLOCKS_END
		bne	@sk
		; if this was the last block then clear the last block pointer - point the last
		; block pointer at the front pointer this will cause the next "free" to
		; magically update both list pointers
		lda	#B0LL_FREE_BLOCKS
		sta	f:B0LL_FREE_BLOCKS_END
@sk:		lda	f:$000000,x     		; get the blocks next pointer
		sta	f:B0LL_FREE_BLOCKS		; store as the front pointer (will be 0 if last block)
		lda	#$ffff          		; blank out the block
		sta	f:$00000a,x
		sta	f:$000008,x
		sta	f:$000006,x
		sta	f:$000004,x
		sta	f:$000002,x
		sta	f:$000000,x
		pla
		sep	#$20
		.a8
		sta	f:b0b_ll_free::type,x		; set the type byte
		rep	#$20
		.a16
		txa
		plp
		clc
		rtl
.endproc



.proc initHandles:far
		phd
		; TODO: In the commy MOS this block is allocated with the MM functions
		; see fe/b2fc
		pea	EXSYS
		pld
		
		ldx	#.loword(HANDLE_BLOCK >> 8)
		stx   	<EXSYS_FpHandles+1
		ldx	#.loword(HANDLE_BLOCK)
		stx   	<EXSYS_FpHandles

		lda	#HANDLE_BLOCK_LEN
		sta  	[<EXSYS_FpHandles]

		tay
		lda	#$0000
		dey
		dey
@cllp:		sta	[<EXSYS_FpHandles],y
		dey
		dey
		bne	@cllp

;;                lda	f:$00fe04
;;                ldy	#$0002
;;                sta	[<EXSYS_FpHandles],y

		pld
		rtl
.endproc


;	********************************************************************************
;	* Allocate a Handle                                                            *
;	*                                                                              *
;	* On Entry                                                                     *
;	*   X     The B0Block address to store in the handle                           *
;	*                                                                              *
;	* On Exit                                                                      *
;	*   If Cy=1:                                                                   *
;	*         No handle allocated, run out of handles                              *
;	*   If Cy=0:                                                                   *
;	*   Y     The handle                                                           *
;	*                                                                              *
;	* Others preserved                                                             *
;	********************************************************************************
.proc allocHandle:far
		phd
		pha
		pea	EXSYS
		pld
		ldy	#$0000
		lda	[<EXSYS_FpHandles],y		; getHandleBlockSize
		and	#$fffe
		beq	@retsec
		tay
@lp:		dey
		dey
		beq	@retsec
		lda	[<EXSYS_FpHandles],y
		bne	@lp
		txa
		sta	[<EXSYS_FpHandles],y
		pla
		pld
		clc
		rtl

@retsec:	pla
		pld
		sec
		rtl
.endproc

;	********************************************************************************
;	* Given a handle in Y returns the B0Block pointer. For odd numbered handles    *
;	* (well known handles) the block is returned for valid handles. For even       *
;	* numbered handles, searches the [Handle Allocation Table].                    *
;	*                                                                              *
;	* On Entry:                                                                    *
;	*    Y   Contains a handle                                                     *
;	*                                                                              *
;	* On Exit:                                                                     *
;	*    C=0 Found                                                                 *
;	*    DP  the address of the handle block                                       *
;	* or C=1 Failed - no such handle allocated                                     *
;	*                                                                              *
;	* TODO: corrupts X unnecessarily, lots of tax etc that is unnecessary          *
;	********************************************************************************
.proc getHandleYtoX:far
		phd
		pha
		tya
		beq	@retsec
		bit	#$0001
		bne	@wellknownhandle
		pea	EXSYS
		pld
		lda	[<EXSYS_FpHandles],y
@ok:		tax
		beq	@retsec
		cpx	#$ffff
		beq	@retsec
		bne	@retclc

@wellknownhandle:
;;		tyx
;;		cpx	#$000a
;;		bcs	@retsec
;;		phb
;;		phk
;;		.dbank	K (auto)
;;		plb
;;		lda	0+(tblWellKnownHandlePointers & $ffff)-1,x
;;		plb
;;		eor	#$0000
;;		beq	@retsec
;;		pha
;;		pld
;;		lda	bob_ll_irq_pri__next
;;		bra	@ok

@retsec:	pla
		pld
		sec
		rtl


@retclc:	pla
		pld
		clc
		rtl
.endproc


;;tblWellKnownHandlePointers:	.dd2 $fe04 ;HDMMM
;;		.dd2	$0000           ;HDMM0 - QRY
;;		.dd2	$fe08           ;HDMMC
;;		.dd2	$fe0a           ;HDMMW
;;		.dd2	$fe0c           ;HDMMV

;	********************************************************************************
;	* The [Handle Allocation Table] pointed to by long pointer at $FF02 is         *
;	* searched for this entry and its entry is zeroed if found                     *
;	*                                                                              *
;	* On entry:                                                                    *
;	*    X    contains a handle block pointer                                      *
;	*                                                                              *
;	* On exit:                                                                     *
;	*    C=0  indicates block found                                                *
;	*    Y    contains the index of the entry (handle ? QRY?)                      *
;	*    X,D  preserved                                                            *
;	* or C=1  the pointer was not found                                            *
;	*    Y    contains the index of the last entry (entries are allocated          *
;	* descending                                                                   *
;	*         so the first in address order)                                       *
;	*                                                                              *
;	* TODO: why not use the find method below!                                     *
;	********************************************************************************
.proc freeHandleForB0BlockX:far
		phx
		pea	EXSYS
		pld
		ldy	#$0000
		lda	[<EXSYS_FpHandles],y ;get pointer to end of handle block + 2
		tay
		dey
		dey
@lp:		lda	[<EXSYS_FpHandles],y
		cmp	$01,S           ;compare to passed in X
		beq	@fnd
		dey
		dey                   ;move backwards through handle list
		bne	@lp
		plx
		sec
		rtl

@fnd:		lda	#$0000
		sta	[<EXSYS_FpHandles],y ;zero out the entry and return clc
		plx
		clc
		rtl
.endproc

;	********************************************************************************
;	* The [Handle Allocation Table] pointed to by long pointer at $FF02 is         *
;	* searched for an entry that contains X                                        *
;	*                                                                              *
;	* On entry:                                                                    *
;	*    X    contains a handle block pointer                                      *
;	*                                                                              *
;	* On exit:                                                                     *
;	*    C=0  indicates block found                                                *
;	*    Y    contains the index of the entry (handle)                             *
;	* or C=1  the pointer was not found                                            *
;	*    Y    contains the index of the last entry (entries are allocated          *
;	* descending                                                                   *
;	*         so the first in address order)                                       *
;	*                                                                              *
;	*    X    preserved                                                            *
;	*    D,A  corrupted                                                            *
;	********************************************************************************
.proc findHandleByAddr:far
		pea	EXSYS
		pld
		ldy	#$0000
		lda	[<EXSYS_FpHandles],y
		tay
		dey
		dey
		txa
@lp:		cmp	[<EXSYS_FpHandles],y
		beq	@retclc
		dey
		dey
		bne	@lp
		sec
		rtl
@retclc:	clc
		rtl
.endproc

