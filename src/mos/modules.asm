
                .include "cop.inc"
                .include "oslib.inc"
                .include "vectors.inc"
                .include "debug.inc"
                .include "modules.inc"

                .export COP_32
                .export COP_34
                .export modules_init
                .export modules_list:far
                .export modules_help:far

                .segment "BMOS_NAT_CODE"

                .i16
                .a16
modules_init:
                lda     #0
                sta     f:B0LL_MODULES
                rtl


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
COP_34:         lda     DPCOP_X
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
                beq     @skokbrl
                brl     @retBadModule
@skokbrl:       dey
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
                adc     #2                      ; add 1 + BRL offset - 1
                adc     DPCOP_X                 ; add BRL location
                ldy     #modhdr::length         
                cmp     [DPCOP_AH],Y            ; compare with module length
                bcs     @retBadModule        


@sknexlpoffs:   dec     DPCOP_X
                dec     DPCOP_X
                dec     DPCOP_X
                bpl     @lpoffs


                ; TODO check title etc

                cop     COP_32_OPSUM
                bcs     @retBadModule


                ; TODO check for duplicate module (by name)

                ; make module B0Block
                lda     #B0B_TYPE_LL_MODULE
                jsl     allocB0Block
                bcs     @retMemorySpace

                lda     DPCOP_AH
                sta     f:b0b_ll_mod::addr,X
                lda     DPCOP_AH+2
                sta     f:b0b_ll_mod::addr+2,X

                phd                             ; save DP
                phx
                txa
                tcd

                lda     #0
                sta     z:b0b_ll_mod::next
                sta     z:b0b_ll_mod::resv
                sta     z:b0b_ll_mod::pri
                sta     z:b0b_ll_mod::pri+2

                ; call the module's init entry before adding to the list

                phk
                per     @rc-1                   ; return here after init

                pei     (b0b_ll_mod::addr+1)    ; top of call address
                plb                             ; discard high byte
                lda     b0b_ll_mod::addr
                clc
                adc     #modhdr::brlinit-1      ; adjust to call init entry, adjust for an RTL
                pha

                ldx     #0                      ; TODO: count other instances
                tdc
                adc     #b0b_ll_mod::pri        ; point at private word
                tcd
                rtl                             ; call entry point
                        
@rc:            bvc     @okinit
                plx                             ; get back module pointer
                pld                             ; get back COPDP
                ; bha should already be an error block
                bra     @retsecX1

@okinit:        ply                             ; block
                pld
                php
                sei                             ; turn off interrupts while updating ll
                
                ; find end of linked list and insert there
                lda     #B0LL_MODULES
                tax
@llloop:        lda     f:0,X
                beq     @skend

                tax
                bra     @llloop

@skend:         ; X points at list end pointer
                tya
                sta     f:0,X                   ; update ll to point to our block

                plp                             ; restore interrupts

                ldx     #0
                stx     DPCOP_X
                rtl


;TODO: harmonize errors API
@retMemorySpace:rep     #$20
                .a16
                cop     COP_26_OPBHA
                .byte   "Out of Memory",0
                bra     @retsecX1

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

rtlflags:	php
                sep	#$30
		.a8
		.i8		
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


.proc modules_help:far
                php
                rep     #$30
                .a16
                .i16

                lda     #B0LL_MODULES
                pha
@lp:            pld
                pei     (b0b_ll_mod::next)
                pld
                beq     @done
                phd


                ldy     #modhdr::offhelp
                ldx     #0
                lda     [b0b_ll_mod::addr],Y
                tay
                sep     #$20
                .a8

@lptit:         lda     [b0b_ll_mod::addr],Y
                beq     @sktit
                cmp     #9                      ; tab
                bne     @skf
@tt:            lda     #' '
                cop     COP_00_OPWRC
                inx
                txa
                and     #$7
                bne     @tt
                bra     @tt2

@skf:           cop     COP_00_OPWRC
                inx
@tt2:           iny
                bra     @lptit

@sktit:         
                cop     COP_03_OPNLI

                rep     #$30
                .a16
                .i16

                bra     @lp

@done:          plp
                rtl

.endproc


.proc modules_list:far
                php
                rep     #$30
                .a16
                .i16

                lda     #B0LL_MODULES
                pha
@lp:            pld
                pei     (b0b_ll_mod::next)
                pld
                beq     @done
                phd

                ; module bank/addr
                lda     b0b_ll_mod::addr+2
                jsl     PrintHexA
                ldx     b0b_ll_mod::addr
                jsl     PrintHexX
                
                jsl     Print2Spc

                sep     #$20
                .a8

                ; private data
                ldx     #0
@plp:           lda     b0b_ll_mod::pri,X
                jsl     PrintHexA
                jsl     PrintSpc
                inx
                cpx     #4
                bcc     @plp
                
                jsl     Print2Spc

                rep     #$20
                .a16
                ldy     #modhdr::offtit
                lda     [b0b_ll_mod::addr],Y
                tay
                sep     #$20
                .a8

@lptit:         lda     [b0b_ll_mod::addr],Y
                beq     @sktit
                cop     COP_00_OPWRC
                iny
                bra     @lptit

@sktit:         
                cop     COP_03_OPNLI

                rep     #$30
                .a16
                .i16

                bra     @lp

@done:          plp
                rtl

.endproc
