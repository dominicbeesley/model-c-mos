
		.include "nat-layout.inc"


		.export initB0Blocks
		.export freeB0Block
		.export allocB0Block

	; b0blocks are 12 byte long blocks that are pre-allocated in bank 0 
	; that can be allocated by the OS. They are typically used to contain
	; information associated with a handle.
	; the blocks are 12 bytes long with only the byte at offset 11 having
	; a definitive purpose (a type indicator).


	; These are inspired by the Communicator MOS blocks (See de/cdb5 on in MOS100)


initB0Blocks:	php
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
		jsr	freeB0Block
		pla
		clc
		adc	#B0B_SIZE
		cmp	#B0B_END
		bcc	@lp
		plp
		rts

;	********************************************************************************
;	* Return the block pointed to X to the free list                               *
;	*                                                                              *
;	* On Entry:                                                                    *
;	*    X   is a pointer to a B0Block                                             *
;	********************************************************************************
freeB0Block:	phy
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
		rts

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

allocB0Block:	php
		sei
		rep	#$30
		.a16
		.i16
		tax
		lda	f:B0LL_FREE_BLOCKS
		bne	 @ok
		plp
		sec
		rts
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
		rts

