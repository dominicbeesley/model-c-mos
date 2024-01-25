
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
TMP:			.res 1
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
		.a8
GETCHAR:	php
		rep	#$10		; big X
		.i16
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
		stx	z:<deice_reg_DP
		xba
		sta	z:<deice_reg_A+1
		sty	z:<deice_reg_Y
		; stack pointer is now back to how it was before the interrupt
		tsx
		stx	z:<deice_reg_SP
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
		sta	z:<deice_reg_E		; set E = 0, DBR = original
		pla				; pull P, PCL
		sta	z:<deice_reg_P
		pla				; pull PCH, K
		sta	z:<deice_reg_PC+1
		stx	z:<deice_reg_X
		sty	z:<deice_reg_Y
		tsx
		stx	z:<deice_reg_SP
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
		tsb	z:<deice_run_flag
		ldx	#DEICESTACKTOP-1
		txs

		lda	#FN_RUN_TARG
		jmp	RETURN_REGS

;
;===========================================================================
;
;	MAIN LOOP 
;
; mode = i16 a8
MAIN:		; TODO: get rid of this bit - should be unnecessary - just belt and braces
		ldx	#DEICESTACKTOP-1
		txs
		sep	#$20
		rep	#$10
		pea	0
		plb
		plb
		pea	deice_base
		pld
		ldx	#<COMBUF
		jsr	GETCHAR
		bcs	MAIN
		cmp	#FN_MIN
		bcc	MAIN
		sta	z:0,X			; store FN code
		inx
;
;  Second byte is data byte count (may be zero)
		jsr	GETCHAR			; GET A LENGTH BYTE
		bcs	MAIN			; JIF TIMEOUT: RESYNC
		cmp	#COMBUF_SIZE
		bcs	MAIN			; JIF TOO LONG: ILLEGAL LENGTH
		sta	z:0,X			; SAVE LENGTH
		cmp	#0
		beq	MA80			; SKIP DATA LOOP IF LENGTH = 0
		inx
;
;  Loop for data
		xba
		lda	#0
		xba
		tay				; Y contains 16 bit length
MA10:		jsr	GETCHAR			; GET A DATA BYTE
		bcs	MAIN			; JIF TIMEOUT: RESYNC
		sta	z:0,X			; SAVE DATA BYTE
		inx
		dey	
		bne	MA10
;
;  Get the checksum
MA80:		jsr	GETCHAR			; GET THE CHECKSUM
		bcs	MAIN			; JIF TIMEOUT: RESYNC
		pha				; SAVE CHECKSUM
;
;  Compare received checksum to that calculated on received buffer
;  (Sum should be 0)
		jsr	CHECKSUM
		clc
		adc	1,S			; ADD SAVED CHECKSUM TO COMPUTED
		bne	MAIN			; JIF BAD CHECKSUM

		pla
;
;  Process the message.
		ldx	#<COMBUF+2
		lda	#0
		xba
		lda	z:<COMBUF+1		; GET THE LENGTH
		tay				; Y holds 16 bit length
		lda	z:<COMBUF+0		; GET THE FUNCTION CODE
		cmp	#FN_GET_STAT
		beq	TARGET_STAT
		cmp	#FN_READ_MEM
		beq	READ_MEM
;;		cmp	#FN_WRITE_M
;;		beq	WRITE_MEM
		cmp	#FN_READ_RG
		beq	READ_REGS
;;		cmp	#FN_WRITE_RG
;;		beq	WRITE_REGS
;;		cmp	#FN_RUN_TARG
;;		beq	RUN_TARGET
;;		cmp	#FN_SET_BYTES
;;		beq	SET_BYTES
;;		cmp	#FN_IN
;;		beq	IN_PORT
;;		cmp	#FN_OUT
;;		beq	OUT_PORT
;
;  Error: unknown function.  Complain
		lda	#FN_ERROR
		sta	z:<COMBUF		; SET FUNCTION AS "ERROR"
		lda	#1
		jmp	SEND_STATUS		; VALUE IS "ERROR"

;===========================================================================
;
;  Target Status:  FN, len
;
;  Entry with A=function code, Y=data in size, X=COMBUF+2
;
TARGET_STAT:	
		lda	#0
		xba
		lda	#TSTG_SIZE
		sta	z:<COMBUF+1
		ldy	#COMBUF+2
		ldx	#TSTG
		mvn	#^*,^COMBUF
;
;  Compute checksum on buffer, and send to master, then return
		bra	SEND

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
;  Read Memory:	 FN, len, Add32(BE), Nbytes
;
;  Entry with A=function code, B=data size, X=COMBUF+2
;
; NOTE: depart from NoIce - 32 bit addresses
READ_MEM:

		lda	z:4,X			; get length
		sta	z:<COMBUF+1		; store
		beq	GLP90
		sta	z:<TMP
		phb				; save our bank
		lda	z:1,X			; src bank
		pha
		plb
		lda	z:2,X
		xba
		lda	z:3,X
		tay				; src pointer
@lp:		lda	a:0,Y
		iny
		sta	z:0,X
		inx
		dec	z:<TMP
		bne	@lp

		plb				; restore bank register

;  Compute checksum on buffer, and send to master, then return
GLP90:		bra	SEND


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
;  Build status return with value from D0
;
SEND_STATUS:
		sta	z:<COMBUF+2		; SET STATUS
		lda	#1
		sta	z:<COMBUF+1		; SET LENGTH
		
		; fall through to SEND


;===========================================================================
;  Append checksum to COMBUF and send to master
;
;
; mode a8 i16
SEND:		jsr	CHECKSUM		; GET A=CHECKSUM, X->checksum location
		eor	#$FF
		inc	A			; negate checksom
		sta	0,X			; STORE NEGATIVE OF CHECKSUM
;
;  Send buffer to master
		ldx	#<COMBUF		; POINTER TO DATA
		lda	z:1,X			; LENGTH OF DATA
		clc
		adc	#3			; PLUS FUNCTION, LENGTH, CHECKSUM
		tay
@lp:		lda	z:0,X
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
		ldx	#<COMBUF		; POINTER TO DATA
		lda	#0
		xba				; clear top half of acc
		lda	z:1,X			; LENGTH OF DATA
		clc
		adc	#2			; PLUS FUNCTION, LENGTH, CHECKSUM
		tay
		lda	#0			; init checksum to 0
@lp:		clc
		adc	z:0,X
		inx
		dey
		bne	@lp
		rts				; return with checksum in A


