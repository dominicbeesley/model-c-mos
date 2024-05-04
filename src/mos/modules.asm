
                .include "cop.inc"
                .include "oslib.inc"
                .include "vectors.inc"
                .include "debug.inc"
                .include "modules.inc"

                .export COP_32
                .export COP_34

                .segment "BMOS_NAT_CODE"


;       ********************************************************************************
;       * COP 34 - OPMOD - module management                                           *
;       *                                                                              *
;       * On entry: X contains a reason code                                           *
;       *                                                                              *
;       ********************************************************************************

tblCOP_34:      .addr   .loword(tblCOP_34_0)
                .addr   .loword(tblCOP_34_1)
                .addr   .loword(tblCOP_34_2)
                .addr   .loword(tblCOP_34_3)
                .addr   .loword(tblCOP_34_4)
                .addr   .loword(tblCOP_34_5)
                .addr   .loword(tblCOP_34_6)
                .addr   .loword(tblCOP_34_7)
                .addr   .loword(tblCOP_34_8)
                .addr   .loword(tblCOP_34_9)
                .addr   .loword(tblCOP_34_10)
TBLCOP34MAX     := 10

                .a16
                .i16
COP_34:         lda     DPCOP_AH
                cmp     #TBLCOP34MAX+1
                bcs     @rtl
                asl     A
                tax
                jmp     (.loword(tblCOP_34),X)
@rtl:           rtl

tblCOP_34_0:    
tblCOP_34_1:    
tblCOP_34_2:    
tblCOP_34_3:    
tblCOP_34_4:    
tblCOP_34_5:    
tblCOP_34_6:    
tblCOP_34_7:    
tblCOP_34_8:    
tblCOP_34_9:    
                sec
                rtl
;       ********************************************************************************
;       * COP 34 - OPMOD - module management                                           *
;       *                                                                              *
;       * 10 - insert a module from memory                                             *
;       *                                                                              *
;       * The module whose address is supplied in BHA is checked for validity and      *
;       * placed in the active modules list.                                           *
;       *                                                                              *
;       * The module's initialise entry is called with a newly allocated private word  *
;       *                                                                              *
;       *                                                                              *
;       * TODO: instances                                                              *
;       * TODO: check for duplicate, kill and reinit all instances                     *
;       *                                                                              *
;       * On entry:                                                                    *
;       *    X    #10                                                                  *
;       *    BHA  address of module                                                    *
;       *                                                                              *
;       ********************************************************************************
tblCOP_34_10:   
                ; check BRL opcodes
                sep     #$20
                .a8
                ldy     #modhdr::brlserv
@lpbrl:         lda     [DPCOP_AH], Y
                cmp     #$82
                bne     @retBadModule
                dey
                dey
                dey
                bpl     @lpbrl

                ; check branch offsets are within module length
                rep     #$20
                .a16
                ldy     #modhdr::offserv
                sty     DPCOP_X                 ; use as temporary storage
@lpoffs:        ldy     DPCOP_X
                lda     [DPCOP_AH],Y
                beq     @sknexlpoffs

                clc
                adc     #3                      ; add 1 + BRL offset
                adc     DPCOP_X                 ; add BRL location
                ldy     #modhdr::length         
                cmp     [DPCOP_AH],Y            ; compare with module length
                bcs     @retBadModule




@sknexlpoffs:   dec     DPCOP_X
                dec     DPCOP_X
                dec     DPCOP_X
                bpl     @lpoffs





@retBadModule:  rep     #$20
                .a16
                cop     COP_26_OPBHA
                .byte   "Bad module",0
@retsecX1:      ldx     #$0001
                sec
                brl     retCopXBHA



retCopXBHA:     stx   DPCOP_X
                sta   DPCOP_AH
                sep   #$20
                .a8
                phb
                pla
                sta   DPCOP_B
                rep   #$20
                .a16
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


; Check if the character passed in A is in '!', '.', '0'..'9', 'A'..'Z',
; 'a'..'z'
                
isValidModNameStartChar:
                php
                sep   #$20
                .a8
                cmp   #'{'
                bcs   @retsec
                cmp   #'a'
                bcs   @retCLC
                cmp   #'['
                bcs   @retsec
                cmp   #'A'
                bcs   @retCLC
                cmp   #':'
                bcs   @retsec
                cmp   #'0'
                bcs   @retCLC
                cmp   #'.'
                beq   @retCLC
                cmp   #'!'
                beq   @retCLC
@retsec:        plp
                sec
                rts                
@retCLC:        plp
                clc
                rts


