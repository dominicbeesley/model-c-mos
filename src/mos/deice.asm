
		.autoimport +

		.include "hardware.inc"
		.include "deice.inc"

		.export deice_init
		.export deice_printStrzX

		.export deice_enter_emu
		.export deice_enter_nat

; local serial hardware defs
SERIAL_STATUS	:= sheila_ACIA_CTL
RXRDY		:= ACIA_RDRF
SERIAL_RXDATA	:= sheila_ACIA_DATA
TXRDY		:= ACIA_TDRE
SERIAL_TXDATA	:= sheila_ACIA_DATA

		.segment "DEICE_BSS"
deice_base:
deice_regs:
deice_reg_status:	.res 1
deice_reg_A:		.res 2
deice_reg_X:		.res 2
deice_reg_Y:		.res 2
deice_reg_DP:		.res 2
deice_reg_SP:		.res 2
deice_reg_E:		.res 1		; 1 bit in bottom order of E and DBR important in nat entry shim		
deice_reg_DBR:		.res 1		; order of DBR and P important in nat entry shim
deice_reg_P:		.res 1
deice_reg_PC:		.res 3		; 24 bit
deice_regs_len := *-deice_regs

deice_run_flag: 	.res 1
COMBUF:			.res $80
COMBUF_SIZE := *-COMBUF
DEICSTACK:		
DEICESTACKTOP := __RAM_DEICE_BSS_START__ + __RAM_DEICE_BSS_SIZE__

		.code
		.a8
		.i8

deice_init:
		php
		sep	#$30
		.a8
		.i8
		lda 	#$40
		sta	sheila_SERIAL_ULA	; set for 19200/19200

		lda	#%01010111
		sta	sheila_ACIA_CTL		; master reset
		lda	#%01010110
		sta	sheila_ACIA_CTL		; RTS high, no interrupts, 8N1, div64
		
		stz	deice_run_flag
		
		plp
		rts

		



;
;===========================================================================
; Get a character to A
;
; Return A=char, CY=0 if data received
;        CY=1 if timeout (0.5 seconds)
;
; Uses 5 bytes of stack including return address
;
; mode = a8 i?

GETCHAR:	php
		rep	#$10		; big X
		phx
		ldx	#0
		lda	#RXRDY
@l1:		bit	SERIAL_STATUS
		beq	@sk1
		lda	SERIAL_RXDATA
		plx
		plp
		clc
		rts

@sk1:		dex
		bne	@l1
		plx
		plp
		sec
		rts

;
;===========================================================================
; Output character in A
;
; Uses 3 bytes of stack including return address
;
; mode = a8 i?
PUTCHAR:	pha        	
   		lda     #TXRDY
PC10:		bit	SERIAL_STATUS  		;CHECK TX STATUS        		
        	beq     PC10			;READY ?
        	pla
        	sta     SERIAL_TXDATA   	;TRANSMIT CHAR.
        	rts



;==========================================================================
; Output string at X in current databank to deice
;
; returns with X pointing after 0, A=0
;
; mode = a8, i16
;
deice_printStrzX:
		lda	a:0,X
		beq	@out
		and	#$7F	;make safe for Deice protocol
		jsr	PUTCHAR
		inx
		bra	deice_printStrzX

@out:		inx
		rts


;
;===========================================================================
; Interrupt entry point from emulation mode
;
; Entry:
;	A = task status code
;	Stack:
;		+3..4	PC	(16 bit program counter K lost!)
;		+2	P	flags
;		+1	A	A at entry
;		
; Note: this shim attempts to only re-use the stack that is already used
; for pushing the interrupt return
deice_enter_emu:
		.a8
		.i8
		sta	f:deice_reg_status	; save status code
		pla
		sta	f:deice_reg_A
		phb	
		pla
		sta	f:deice_reg_DBR		; bank

		; enter native mode for rest of handler
		clc
		xce				; enter native mode

		rep	#$10
		.i16
		pea	$0100
		plb				; bank is now deice bank (0)
		pla
		sta	deice_reg_E		; set emulation mode in regs		
		stx	deice_reg_X
		; we can now use X as 16 bit reg
		pla
		sta	deice_reg_P		; flags from stack
		plx
		stx	deice_reg_PC
		phd
		pea	deice_base
		pld
		; direct page now points at our area
		plx	
		stx	<deice_reg_DP
		xba
		sta	<deice_reg_A+1
		sty	<deice_reg_Y
		; stack pointer is now back to how it was before the interrupt
		tsx
		stx	<deice_reg_SP
		bra	deice_enter

;
;===========================================================================
; Interrupt entry point from natural mode
;
; Entry:
;	A = task status code
;	Stack:
;		+4..5	PC	(24 bit program counter)
;		+3	P	flags
;		+1..2	A	A 16 bits irrespective of mode when interrupt occurred
; mode a16, i16
deice_enter_nat:
		.a16
		.i16
		sta	f:deice_reg_status	; save status code
		pla
		sta	f:deice_reg_A
		tdc
		sta	deice_reg_DP
		lda	#deice_base
		tcd				
		; now can use direct page addressing
		phb
		pea	0
		plb
		pla				; actually pulls E=0, DBR
		sta	<deice_reg_E		; set E = 0, DBR = original
		pla				; pull P, PCL
		sta	<deice_reg_P
		pla				; pull PCH, K
		sta	<deice_reg_PC+1
		stx	<deice_reg_X
		sty	<deice_reg_Y
		tsx
		stx	<deice_reg_SP
		sep	#$20
		.a8
		; fall through to deice_enter

;
;===========================================================================
; Interrupt entry point after mode dependent shims
;
; Entry:
; mode = i16 a8, DBR=0, DP points at base of deice_ram
;		
		.i16
		.a8
deice_enter:	lda	#$01			; TODO try and do this earlier
		tsb	<deice_run_flag
		ldx	#DEICESTACKTOP-1
		txs

		lda	#FN_RUN_TARG
		bra	RETURN_REGS


MAIN:		jmp	MAIN


;
;*======================================================================
;*  Response string for GET TARGET STATUS request
;*  Reply describes target:
TSTG:	
		.byte	$10			; 2: PROCESSOR TYPE = 65816
		.byte	COMBUF_SIZE		; 3: SIZE OF COMMUNICATIONS BUFFER
		.byte	0			; 4: NO TASKING SUPPORT
		.byte	0,0
		.byte	$FF,$FF			; 5-8: LOW AND HIGH LIMIT OF MAPPED MEM (ALL!)		-- note 68008 has 24 bit address space "paging" register is just the high MSB!
		.byte	1			; 9:  BREAKPOINT INSTR LENGTH
deice_BPINST:	.byte	$42			; WDM
		.asciiz	"65816 monitor v1.1-model-c-mos"
TSTG_SIZE	:=	* - TSTG			; SIZE OF STRING

;===========================================================================
;
;  Read registers:  FN, len=0
;
;  Entry with A=function code
;
; mode a8 i16
READ_REGS:
		; enter with A is function code to return either FN_RUN_TARG or FN_READ_REGS
RETURN_REGS:	ldx	#deice_regs
		ldy	#COMBUF
		sta	a:0,Y		
		lda	#0
		xba
		lda	#deice_regs_len
		sta	a:1,Y
		iny
		iny
		mvn	#^deice_regs, #^COMBUF
		bra	SEND


;===========================================================================
;  Append checksum to COMBUF and send to master
;
;
; mode a8 i16
SEND:		jsr	CHECKSUM		; GET A=CHECKSUM, X->checksum location
		eor	#$FF
		inc	A			; negate checksom
		sta	a:0,X			; STORE NEGATIVE OF CHECKSUM
;
;  Send buffer to master
		ldx	#COMBUF			; POINTER TO DATA
		lda	a:1,X			; LENGTH OF DATA
		clc
		adc	#3			; PLUS FUNCTION, LENGTH, CHECKSUM
		tay
@lp:		lda	a:0,X
		inx
		jsr	PUTCHAR			; SEND A BYTE
		dey
		bne	@lp
		jmp	MAIN			; BACK TO MAIN LOOP

;===========================================================================
;  Compute checksum on COMBUF.	COMBUF+1 has length of data,
;  Also include function byte and length byte
;
;  Returns:
;	A = checksum
;	X = pointer to next byte in buffer (checksum location)
;	B is scratched
;
; mode a8 i16
CHECKSUM:
		ldx	#COMBUF			; POINTER TO DATA
		lda	#0
		xba				; clear top half of acc
		lda	a:1,X			; LENGTH OF DATA
		clc
		adc	#2			; PLUS FUNCTION, LENGTH, CHECKSUM
		tay
		lda	#0			; init checksum to 0
@lp:		clc
		adc	a:0,X
		inx
		dey
		bne	@lp
		rts				; return with checksum in A


