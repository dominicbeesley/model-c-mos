
		.include "nat-layout.inc"
		.include "hardware.inc"

		.export windowPush
		.export windowPop
		.export windowYXtoBHA


; WINDOW is a 4K address space hole in the emu bank 0/nat bank FF map that
; can be pointed at any area in _pysical_ map
; 
; This can be used to expose memory areas in the for 24bit range available in
; emulation mode
;


;	********************************************************************************
;	* windowPush:far                                                               *
;	*                                                                              *
;	* Action: The window is pointed to the address contained in BHA such that the  *
;	* 4K window is arranged to contain the address at BHA in the bottome half of   *
;	* the 4K window (the 4K window can be located at an 2K boundary).              *
;	*                                                                              *
;	* The X register is updated to a 16bit address within WINDOW that coincides    *
;	* with the physical address in BHA.                                            *
;	*                                                                              *
;	* If BHA points to bank FF then the address is left as is and X=HA and WINDOW  *
;	* is not updated though current window is returned.                            *
;	*                                                                              *
;	* Note: it is an error to call with BHA pointing at and address in WINDOW      *
;	* i.e. FF E000-FF EFFF                                                         *
;	*                                                                              *
;	* Note: the address in BHA is a _physical_ address before the the bank0/FF     *
;	* address mappings have been applied.                                          *
;	*                                                                              *
;	* On entry:                                                                    *
;	*    BHA  points to a physical address in physical memory                      *
;	*                                                                              *
;	*    the CPU must be in 16 bit index mode on entry/exit                        *
;	*                                                                              *
;	* On exit:                                                                     *
;	*    X    points to BHA's corresponding address in WINDOW                      *
;	*    Y    contains the old value of the Window Pointer to be used with         *
;	*         the corresponding popWindow call.                                    *
;	*                                                                              *
;	********************************************************************************

.proc		windowPush:far
		php
		sei
		rep	#$30
		.a16
		.i16
		phb
		pha
		
		ldy	WINDOW_CUR		; preserve current WINDOW


	;TODO: this assumes MOS at 7D0000
		lda	2,S			; A = BH
		and	#$FFC0
		cmp	#$FFC0
		bne	@sk1
		lda	2,S
		and	#$003F
		ora	#$7D00
		bra	@sk2
@sk1:		lda	2,S			; A = BH
@sk2:		and	#$FFF8			; mask off 2K block boundary
		sta	f:WINDOW_CUR
		sta	f:sheila_WINDOW
		lda	2,S
		sec
		sbc	f:WINDOW_CUR
		xba
		sep	#$20
		.a8
		lda	1,S
		rep	#$20
		.a16
		ora	#WINDOW
		tax

		pla
		plb
		plp
		rtl
.endproc


;	********************************************************************************
;	* windowPop:far                                                                *
;	*                                                                              *
;	* Action: restore WINDOW mapping after a previous pushWindow call              *
;	*                                                                              *
;	* On entry:                                                                    *
;	*    Y    value returned by pushWindow                                         *
;	*    the CPU must be in 16 bit index mode on entry/exit                        *
;	*                                                                              *                                                                              *
;	********************************************************************************

.proc		windowPop:far
		php
		sei
		rep	#$30
		.a16
		.i16
		pha
		tya
		sta	f:WINDOW_CUR
		sta	f:sheila_WINDOW
		pla
		plp
		rtl
.endproc



;	********************************************************************************
;	* windowYXtoBHA:far                                                            *
;	*                                                                              *
;	* Action: map an emu mode YX pointer to BHA extending to 24 bit pointer if     *
;	* in WINDOW                                                                    *
;	*                                                                              *
;	* On entry:                                                                    *
;	*    Y    value returned by pushWindow                                         *
;	*    the CPU must be in 16 bit index mode on entry/exit                        *
;	*                                                                              *                                                                              *
;	********************************************************************************
.proc	windowYXtoBHA
		
		phx
		phy
		php
		sep	#$30
		.a8
		.i8

		cpy	#$E0
		bcc	@notW
		cpy	#$F0
		bcs	@notW
		tya	
		and	#$0F
		pha
		lda	f:WINDOW_CUR
		and	#$F8
		adc	1,S
		ply				; discard stacked masked #
		xba
		lda	f:WINDOW_CUR+1
		adc	#0
		pha
		plb
		txa
		plp
		ply
		plx
		rtl

@notW:		pea	$FFFF
		plb
		plb
		tya
		xba
		txa
		plp
		ply
		plx
		rtl		

.endproc