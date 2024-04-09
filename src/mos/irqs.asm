
		.include	"dp_sys.inc"
		.include	"hardware.inc"
		.include	"vectors.inc"
		.include	"nat-layout.inc"
		.include	"oslib.inc"
		.include	"sysvars.inc"
		.include	"cop.inc"

		.export		COP_2F
		.export		COP_30
		.export		COP_31

		.export		default_IVIRQ_emu
		.export		default_IVIRQ
		.export		setupIRQstackandhandlers

;	********************************************************************************
;	* Main emu interrupt handler                                                   *
;	*                                                                              *
;	* The entry shim in bank 0 has already poked us into native mode but we need   *
;	* to massage the stack for a RTI to take us back from native mode to bank 0    *
;	* shim                                                                         *
;	********************************************************************************
default_IVIRQ_emu:

	; Stack
	; +5..6	PC  emu mode return address
	; +4	P   entry flags
	; +1..3 RTL return address-1 to b0 shim
		php
	; Stack
	; +6..7	PC  emu mode return address
	; +5	P   entry flags
	; +2..4 RTL return address-1 to b0 shim
	; +1	Phoney native mode flags
		
	; fall through to native handler

;	********************************************************************************
;	* Main native interrupt handler                                                *
;	*                                                                              *
;	* This (after preserving some registers) sets up an IRQ handler stack then     *
;	* scans through the priority list of registered IRQ handlers calling ones      *
;	* which have a pending irq (detected by using their registered hardware        *
;	* address and masks)                                                           *
;	********************************************************************************
default_IVIRQ:	rep   #$30
		.a16
		.i16
	; Stack
	;	+2..4	rti return address
	;	+1	Caller flags
		phb
		pha
		phx
	; Stack
	;	+7..8	rti return address
	;	+6	Caller flags
	;	+5	Caller B
	;	+3..4	Caller A (16bit)
	;	+1..2	Caller X
	; This is the exit stack should there be no stack swap below
		lda	f:B0_IRQ_STACK  		; get interrupt stack
		beq	@nos				; if 0 then we're already running from that stack TODO: hopefully! check in Mame
		tsx					; X = current stack
		tcs					; set up new interrupt stack
		phk					; push long address of stack restore code
		per	@restoreOrgStack
		pea	$0400				; push phoney flags (0x04) and bank to be discarded in restore
		pha        				; push A (contains stack top)
		phx        				; push X (original stack)
		lda	#$0000
		sta	f:B0_IRQ_STACK
	; IRQ private Stack
	;	+7..9	far rti address to @restoreOrgStack
	;	+6	flags = 04
	;	+5	bank = 00
	;	+3..4	B0_IRQ_STACK contents - IRQ private stack pointer
	;	+1..2	Caller stack pointer (16)
	; This is the exit stack after a stack swap

@nos:		phd
		phy
		pea	B0LL_IRQ_BLOCKS			; point at list head in B0		
@lp2:		sep	#$30
		.a8
		.i8
		pld        				; pop list header address or previous primary block
@lp:		pei	(b0b_ll_irq_pri::next)		; get address of next item
		pld        				; into DP
		lda	[b0b_ll_irq_pri::irqf]		; read hardware test register into A
		tay        				; into Y
		and	[b0b_ll_irq_pri::fpand]		; and with pointer AND mask
		eor	b0b_ll_irq_pri::meor		; eor with mask
		and	b0b_ll_irq_pri::mand		; and with other AND mask
		beq	@lp
		phd        				; push block primary pointer to stack - if handler returns with CS this is used to continue the loop
		phk        				; push program bank
		pea	.loword(@interruptEx)-1		; and address of an rti
		pei	(b0b_ll_irq_pri::psec)		; address of secondary irq block
		pld        				; into DP
		; now editing secondary block
		inc	b0b_ll_irq_sec::hitct
		bne	@skinccy
		inc	b0b_ll_irq_sec::hitct+1
		bne	@skinccy
		inc	b0b_ll_irq_sec::hitct+2
		bne	@skinccy
		inc	b0b_ll_irq_sec::hitct+3
@skinccy:	pei	(b0b_ll_irq_sec::fphand+1)	; push handler K,PCH
		pei	(b0b_ll_irq_sec::flags)		; push handler P, PCL
		pei	(b0b_ll_irq_sec::dp)		; get handler DP
		pld
		rti

@interruptEx:	bcs	@lp2 				; if Cy set at handler exit continue with other handlers
		pld        				; discard stacked block pointer
		rep	#$30
		.a16
		.i16
		ply        			
		pld

	; Depending on whether a stack swap occurred this will pop the caller
	; registers and do and RTI _OR_ if there was a stack swap will set
	;	X = Caller's stack pointer
	;	A = top of IRQ stack (original contents of B0_IRQ_STACK)
	;	B = 0
	;	RTI will jump to @restoreOrgStack

		plx
		pla
		plb
		rti


@restoreOrgStack:		
		sta	f:B0_IRQ_STACK 			; restore irq stack address in B0
		txs        				; restore original stack
		plx        				; exit to outer vector
		pla
		plb
		rti

;	********************************************************************************
;	* COP 2F - OPIIQ - Add interrupt handler                                       *
;	*                                                                              *
;	* Action: This call is used to add a device's interrupt service to the list of *
;	* such services maintained by the operating system.                            *
;	*                                                                              *
;	* On entry: Inline 3 byte hardware address of the device which requires        *
;	*           servicing's status register.                                       *
;	*           Inline 1 byte EOR mask, allowing inversion of bits to the correct  *
;	*           logic level if necessary.                                          *
;	*  BHA      points to the start address of the interrupt routine.              *
;	*  X        contains an AND mask to discriminate between different devices     *
;	*           causing interrupts. (X must be set to zero if a call to OPMIQ is   *
;	*           required.)                                                         *
;	*  Y        contains the priority (range 1 to 255). This will be the           *
;	*           position within the list of devices which the new entry will occupy*
;	*           The lower the value the higher the priority.                       *
;	*  DP       is set to the direct page required whilst in the interrupt         *
;	*           routine.                                                           *
;	*  P        flags are set to give the mode required in the interrupt routine.  *
;	*           (The operating system sets the I flag.)                            *
;	* routine.                                                                     *
;	*           (The operating system sets the I flag.)                            *
;	* On exit:  If C = O then the call succeeded. Y = handle and HA = handle.      *
;	*           If C = 1 then the call failed. Y = 0 and HA = O.                   *
;	*           No registers preserved (all preserved QRY?)                        *
;	********************************************************************************
		.a16
		.i16
COP_2F:		cpy	#$0000
		bne	@YnZ
		lda	f:B0LL_IRQ_BLOCKS
		beq	@YnZ
		brl	@retSec

@YnZ:		lda	#B0B_TYPE_LL_IRQ
		jsr	allocB0Block
		bcc	@skok1
		brl	@retSec

@skok1:		phx
		lda	#B0B_TYPE_LL_IRQ
		jsr	allocB0Block
		bcc	@skok2
		brl	@retSec2

@skok2:		sep	#$20
		.a8
	; first do the secondary block
		lda	DPCOP_Y
		sta	f:b0b_ll_irq_sec::prior,x
		lda	DPCOP_P
		ora	#$04
		sta	f:b0b_ll_irq_sec::flags,x
		rep	#$20
		.a16
		lda	DPCOP_AH+1
		sta	f:b0b_ll_irq_sec::fphand+1,x
		lda	DPCOP_AH
		sta	f:b0b_ll_irq_sec::fphand,x
		lda	DPCOP_DP
		sta	f:b0b_ll_irq_sec::dp,x
		lda	#$0000
		sta	f:b0b_ll_irq_sec::hitct,x
		sta	f:b0b_ll_irq_sec::hitct+2,x
		txa
		plx
	; no do the primary block
		sta	f:b0b_ll_irq_pri::psec,x
		ldy	#$0001
		lda	[DPCOP_PC],y
		sta	f:b0b_ll_irq_pri::irqf,x
		iny
		lda	[DPCOP_PC],y
		sta	f:b0b_ll_irq_pri::irqf+1,x
		sep	#$20
		.a8
		iny
		iny
		lda	[DPCOP_PC],y
		sta	f:b0b_ll_irq_pri::meor,x
		lda	DPCOP_X
		sta	f:b0b_ll_irq_pri::mand,x
		rep	#$20
		.a16
		lda	#.loword(LFD06_anFF)		; default the pointer to and to point at FF
		sta	f:b0b_ll_irq_pri::fpand,x
		sep	#$20
		.a8
		phk
		pla
		sta	f:b0b_ll_irq_pri::fpand+2,x
		rep	#$20
		.a16
		pea	$0000
		plb		
		plb					; Bank = 0
		pei	(DPCOP_Y)       		; push original Y parameter
		phd        				; push DP of COP handler stack frame
		php        				; push current flags/mode
		sei        				; disable interrupts
		phx        				; push X of 1st IRQ handler block
		pea	B0LL_IRQ_BLOCKS 		; push address of IRQ list head
		pld        				; make that DP
@lp:		phd
	; stack 
	; +8 Y param (priority)
	; +6 COP frame
	; +5 flags/mode
	; +3 pointer to IQ block
	; +1 next entry pointer
		lda	b0b_ll_irq_pri::next		; get pointer at offset 0 (next item)
		beq	@skdone         		; if 0 exit
		tcd        				; make DP point at it
		lda	(b0b_ll_irq_pri::psec)		; get the interrupt priority from the 1st byte of the second block
		and	#$00ff
		cmp	$08,S				; compare with stacked Y parameters
		pla
		bcs	@lp  				; if current entry higher or same priority loop
		pha
		tdc
	; we're now at a point in the list that is lower priority - insert here, or at
	; the end
	; 
	; stack
	; +8 Y param (priority)
	; +6 COP frame
	; +5 flags/mode
	; +3 pointer to IQ block
	; +1 address of pointer to current entry (or B0LST_IRQ_HANDLER)
	; 
	; A points at current entry or zero if end of list
@skdone:	pld
		plx
		sta	f:b0b_ll_irq_pri::next,x     	;store pointer to new entry at next pointer
		txa
		sta	b0b_ll_irq_pri::next		; update previous item's (or list front) to point at new entry
		plp
		pld
		plx        				; discard stacked Y (priority)
		tax
		jsr	allocHandle			;allocate a handle
		sty	DPCOP_Y         		;return in Y
		bcc	@retY				; success
		phx        				; fail, save X (pointer to 1st block)
		lda	f:b0b_ll_irq_pri::psec,x	;get second block
		tax
		jsr	freeB0Block			; free second block
@retSec2:	plx        				; pop pointer to 1st block
		jsr	freeB0Block ;free 1st block
@retSec:	sec        				; return fail
		stz	DPCOP_Y         		; zero Y
@retY:		lda	DPCOP_Y
		sta	DPCOP_AH
		inc	DPCOP_PC        		; step over the immediate parameters
		inc	DPCOP_PC
		inc	DPCOP_PC
		inc	DPCOP_PC
		rtl

LFD06_anFF:	.byte	$ff

;	********************************************************************************
;	* COP 31 - OPMIQ - Modify interrupt intercept                                  *
;	*                                                                              *
;	* Action: This call allows the modification of the address of the AND mask (by *
;	* default set to a location containing &FF), and the value of the AND mask     *
;	* contained in X. (X should be set to zero by OPIIQ before using OPMIQ. OPMIQ  *
;	* is then used to specify the required mask.)                                  *
;	*                                                                              *
;	* On entry: Y = handle returned by OPIIQ.                                      *
;	*           BHA = 0 means do not modify the address of the AND mask.           *
;	*           BHA <> 0 means BHA is the new address of the AND mask.             *
;	*           X = 0 means do not modify the AND mask.                            *
;	*           X <> 0 means X is the new AND mask.                                *
;	* On exit:  C = 0 means that the interrupt intercept was modified.             *
;	*           C = 1 means that the interrupt intercept was not modified.         *
;	*           No registers preserved                                             *
;	********************************************************************************
COP_31:		jsr	getHandleYtoX			; look up handle
		bcs	@retsec				; fail
		phx					; save pointer to 1st block
		lda	f:b0b_ll_irq_pri::psec,x	; get second block pointer
		tax        				; put it in X
		lda	f:b0b_ll_irq_sec::type,x     	; get type byte in to AH
		plx        			        ; get back 1st block pointer
		and	#$00ff          		; mask off type
		cmp	#B0B_TYPE_LL_IRQ 		; check that this is correct type
		bne	@retsec         		; fail
		lda	DPCOP_AH+1
		ora	DPCOP_AH        		; Z will be set if passed in BHA = 0
		php        				; save mode before disable interrupts
		sei        				; disable interrupts
		beq	@sk  				; skip forward for BHA=0
		lda	DPCOP_AH+1      		; update address of AND mask to BHA
		sta	f:b0b_ll_irq_pri::fpand+1,x
		lda	DPCOP_AH
		sta	f:b0b_ll_irq_pri::fpand,x
@sk:		lda	DPCOP_X
		beq	@plpretclc
		sep	#$20
		.a8
		sta	f:b0b_ll_irq_pri::mand,x	; store updated AND mask
		rep	#$20
		.a16
@plpretclc:	plp
		clc
		rtl

@retsec:	sec
		rtl

;	********************************************************************************
;	* COP 30 - OPRIQ - release interrupt                                           *
;	*                                                                              *
;	* Action: This call removes the specified interrupt service from the list      *
;	*                                                                              *
;	* On entry: Y = handle returned by OPIIQ.                                      *
;	* On exit:  C = 0 means that the call released the interrupt intercept.        *
;	*           C = 1 means that the call failed to release the interrupt          *
;	* intercept                                                                    *
;	*           No registers preserved                                             *
;	********************************************************************************
COP_30:		jsr	getHandleYtoX			; get block address from handle
		bcs	@retsec
		phx        				; save X
		php        				; save mode before disable interrupts
		sei
		lda	f:b0b_ll_irq_pri::next,x	; get address of next lower priority interrupt handler
		pha        				; save it
		lda	#B0LL_IRQ_BLOCKS		; get address of front of priority list in A
@lp:		tax					; X=A
		lda	f:b0b_ll_irq_pri::next,x	; get address of next item in list
		beq	@retsk				; end of queue
		cmp	$04,S				; is this the item being removed
		bne	@lp				; not keep looking
		pla					; get address of item following the one being removed
		sta	f:b0b_ll_irq_pri::next,x	; store in the previous item's next pointer (or front of list)
		plp        				; restore interrupt state
		plx        				; get back X
		jsr	freeHandleForB0BlockX		; free the handle for this block (TODO: why not use Y to index here?)P
		phx					; save X
		lda	f:b0b_ll_irq_pri::psec,x	; get pointer to secondary block
		tax
		jsr	freeB0Block 			; free secondary block
		plx        				; get back address of primary block
		jsr	freeB0Block 			; free it
		clc        				; indicate success
		rtl

;;@retsk:		plp        				; TODO: this is a failure route - I think it should SEC here?
;;		pld
;;		pld
@retsk:		pld					; discard saved A
		plp					; restore interrupt status
		pld					; discard saved X
		sec					; indicate error
@retsec:	rtl

setupIRQstackandhandlers:
		wdm 0
;;		php
;;		rep	#$30
;;		.a16
;;		.i16
;;		phd
;;		phb
;;
;;DPSYS = 0
;;
;;;;	TODO: allocate stack for IRQ handlers - for now use $01xx
;;;;		cop	COP_13_OPAST    ;allocate a stack
;;;;		.word	$0100			; stack size
;;;;@lockup:	bcs	@lockup         ;if carry set here lock up the machine !
;;		lda	#$0000
;;		sta	f:B0_IRQ_STACK
;;		lda	#$0000
;;		sta	f:B0LL_IRQ_BLOCKS
;;		phk
;;		plb
;;		sep	#$30
;;		.a8
;;		.i8
;;		lda	#>irqh_catchall
;;		xba
;;		lda	#<irqh_catchall
;;		ldx	#$ff
;;		ldy	#$00
;;		pea	DPSYS
;;		pld
;;		cop	COP_2F_OPIIQ    ;set up a catch-all IRQ handler with lowest priority
;;		.faraddr $00ffff         ;device address
;;		.byte	$00  			; device eor mask
;;		lda	#>irqh_ula_rtc
;;		xba
;;		lda	#<irqh_ula_rtc
;;		ldy	#$21 			; rtc priority
;;		jsr	OPIIQ_ULA_IRQ
;;		ldx	#$08 			; real time clock interrupt mask
;;		jsr	OPMIQ_ULA_IRQ   ;also mask with SYSVAR_ELK_ULA_IE
;;		lda	#>irqh_vsync
;;		xba
;;		lda	#<irqh_vsync
;;		ldy	#$20 			; vsync priority
;;		jsr	OPIIQ_ULA_IRQ
;;		ldx	#$04 			; vsync interrupt mask
;;		jsr	OPMIQ_ULA_IRQ   ;also mask with SYSVAR_ELK_ULA_IE
;;		lda	#>irqh_via_cb1
;;		xba
;;		lda	#<irqh_via_cb1
;;		phk
;;		plb
;;		ldx	#$00
;;		ldy	#$10 			; priority
;;		pea	DPSYS
;;		pld
;;		cop	COP_2F_OPIIQ
;;		.faraddr	VIA_IFR
;;		.byte	$00
;;		ldx	#$10 			; via_cb1
;;		pea	$4200			; TODO: set to >VIA base
;;		plb
;;		plb
;;		lda	#>VIA_IER
;;		xba
;;		lda	#<VIA_IER
;;		cop	COP_31_OPMIQ
;;		plb
;;		pld
;;		plp
;;		rts
;;
;;OPMIQ_ULA_IRQ:	pea   $0000
;;		plb
;;		plb
;;		lda	#>SYSVAR_ELK_ULA_IE
;;		xba
;;		lda	#<SYSVAR_ELK_ULA_IE
;;		cop	COP_31_OPMIQ
;;		rts
;;
;;OPIIQ_ULA_IRQ:	phk
;;		plb
;;		ldx	#$00
;;		pea	DPSYS
;;		pld
;;		cop	COP_2F_OPIIQ
;;		.faraddr sheila_ULA_IRQ_CTL
;;		.byte	$00
;;		rts
