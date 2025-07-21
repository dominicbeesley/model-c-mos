
		.autoimport +

		.include "hardware.inc"
		.include "deice.inc"

		.export deice_init
		.export deice_printStrzX
		.export deice_printA

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
deice_reg_P:		.res 1		; order of P, PC important in nat exit shim
deice_reg_PC:		.res 3		; 24 bit
deice_regs_len := *-deice_regs

deice_run_flag: 	.res 1
COMBUF:			.res $80
COMBUF_SIZE := *-COMBUF
TMP:			.res 1
TMP2:			.res 1
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
		sta	f:sheila_SERIAL_ULA	; set for 19200/19200

		lda	#%01010111
		sta	f:sheila_ACIA_CTL	; master reset
		lda	#%01010110
		sta	f:sheila_ACIA_CTL	; RTS high, no interrupts, 8N1, div64
		
		lda	#0
		sta	f:deice_run_flag
		
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
@l1:		lda	f:SERIAL_STATUS
		and	#RXRDY
		beq	@sk1
		lda	f:SERIAL_RXDATA
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
PC10:		lda	f:SERIAL_STATUS		;CHECK TX STATUS        		
		and     #TXRDY
        	beq     PC10			;READY ?
        	pla
        	sta     f:SERIAL_TXDATA   	;TRANSMIT CHAR.
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
; Note: this shim expects the emu to native switch to already have occurred!
deice_enter_emu:
		.a8
		.i8
		sta	f:deice_reg_status	; save status code
		pla
		sta	f:deice_reg_A
		phb	
		pla
		sta	f:deice_reg_DBR		; bank
		pea	$FF00
		plb				; bank is now deice bank (0)
		pla
		sta	deice_reg_E		; set emulation mode in regs		
		
		lda	#$80
		tsb	deice_run_flag
		bne	deice_emu_already_running

		rep	#$10
		.i16
		xba
		sta	deice_reg_A+1		; store high byte of AH
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
		stz	deice_reg_PC+2		; TODO: check always bank 0 for emu
		bra	deice_enter

deice_emu_already_running:
		; DeIce monitor already running exit with RTI
		lda	f:deice_reg_DBR
		pha
		plb
		lda	f:deice_reg_A
		jml	deice_nat2emu_rti

		.a16
		.i16
deice_nat_already_running:
		lda	z:<deice_reg_DP
		tcd
		lda	f:deice_reg_A
		rti		

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

		; now can use direct page addressing
		sta	f:deice_reg_DP
		lda	#deice_base
		tcd

		sep	#$20
		.a8
		lda	#$80
		tsb	z:<deice_run_flag
		bne	deice_nat_already_running
		rep	#$20
		.a16

		; now can use bank rel addressing
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
deice_enter:	ldx	#DEICESTACKTOP-1
		txs

		; make sure of modes
		sep	#$24		; I=1 .a8
		rep	#$18		; D=0 .i16

;;		lda	z:<deice_reg_status
;;		cmp	#DEICE_STATE_BP
;;		bne	@notbp
;;		; adjust COP's PC back by 2
;;		ldx	z:<deice_reg_PC
;;		dex
;;		dex
;;		stx	z:<deice_reg_PC

		; TODO: if emu/nat address mappings are different this will need changed
		; inspect what's at PC, if WDM then change status to DEICE_BP
		lda	[<deice_reg_PC]
		cmp	#$42			; WDM instruction
		bne	@notbp
		lda	#DEICE_STATE_BP
		sta	z:<deice_reg_status

@notbp:		lda	#FN_RUN_TARG
		sta	z:<COMBUF
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
		lda	#0
		clc
		sbc	z:<COMBUF+0		; $100 - THE FUNCTION CODE - 1
		cmp	#$100-FN_MIN
		bcs	RETURN_ERROR
		asl	A
		xba
		lda	#0
		xba
		tax

		jmp	(.loword(FNTBL),X)
;
;  Error: unknown function.  Complain
RETURN_ERROR:
		lda	#FN_ERROR
		sta	z:<COMBUF		; SET FUNCTION AS "ERROR"
		lda	#1
		jmp	SEND_STATUS		; VALUE IS "ERROR"


FNTBL:
		.addr	TARGET_STAT
		.addr	READ_MEM
		.addr	WRITE_MEM
		.addr	READ_REGS
		.addr	WRITE_REGS
		.addr	RUN_TARGET
		.addr	SET_BYTES
		.addr	IN_PORT
		.addr	OUT_PORT


;===========================================================================
;
;  Target Status:  FN, len
;
TARGET_STAT:	
		lda	#0
		xba
		lda	#TSTG_SIZE
		sta	z:<COMBUF+1
		ldy	#COMBUF+2
		ldx	#.loword(TSTG)
		mvn	#^*,#^COMBUF
;
;  Compute checksum on buffer, and send to master, then return
		jmp	SEND

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
; NOTE: depart from NoIce - 32 bit addresses
READ_MEM:

		lda	z:<COMBUF+6		; get length
		beq	GLP90
		sta	z:<TMP
		sta	z:<COMBUF+1
		phb				; save our bank
		lda	z:<COMBUF+3		; src bank
		pha
		plb
		lda	z:<COMBUF+4		; get source ptr high
		xba				; swap BE->LE
		lda	z:<COMBUF+5		; get source ptr low
		tay				; src pointer
		ldx	#<COMBUF+2
@lp:		lda	a:0,Y
		iny
		sta	z:0,X
		inx
		dec	z:<TMP
		bne	@lp

		plb				; restore bank register

;  Compute checksum on buffer, and send to master, then return
GLP90:		jmp	SEND


;===========================================================================
;
;  Write Memory:  FN, len, Add32BE, (len-4 bytes of Data)
;
WRITE_MEM:

		phb				; save our bank
		lda	z:<COMBUF+1
		sec
		sbc	#4
		beq	WLP50			; nothing to do
		sta	z:<TMP
		lda	z:<COMBUF+3		; dest bank
		pha
		plb
		lda	z:<COMBUF+4		; get dest pointer high
		xba				; swap BE->LE
		lda	z:<COMBUF+5		; get dest pointer low
		tay				; dest pointer
		phy
		ldx	#<COMBUF+6		; source pointer (DP relative)

@lp:		lda	z:0,X
		inx
		sta	a:0,Y
		iny
		dec	z:<TMP
		bne	@lp

		lda	z:<COMBUF+1
		sec
		sbc	#4
		sta	z:<TMP			; get back count
		ply
		ldx	#<COMBUF+6
@lp2:		lda	z:0,X
		inx
		cmp	a:0,Y
		bne	WLP80
		iny
		dec	z:<TMP
		bne	@lp2

WLP50:		lda	#0			; RETURN STATUS = 0
WLP51:		plb				; restore bank register
		jmp	SEND_STATUS
;
;  Write failed:  return status = 1
WLP80:		lda	#1
WLP90:		bra	WLP51


;===========================================================================
;
;  Read registers:  FN, len=0
;
; mode a8 i16
;NOTE: the FN may be FA (run target) or FC (read regs) caller sets in COMBUF+0
READ_REGS:
RETURN_REGS:	lda	#0
		xba
		lda	#deice_regs_len
		sta	z:<COMBUF+1
		ldx	#deice_regs
		ldy	#COMBUF+2
		mvn	#^deice_regs, #^COMBUF
		jmp	SEND


;===========================================================================
;
;  Write registers:  FN, len, (register image)
;
WRITE_REGS:
;
		lda	#deice_regs_len
		cmp	<COMBUF+1
		bne	@exbad			; wrong size registers		
		xba				; get 0 into top of AH
		lda	#0
		xba
		ldx	#COMBUF+2
		ldy	#deice_regs
		mvn	#^COMBUF, #^deice_regs
;
;  Return OK status
		lda	#0
@ex:		jmp	SEND_STATUS
@exbad:		lda	#1
		bra	@ex

;===========================================================================
;
;  Run Target:	FN, len=0
;

RUN_TARGET:	
		; restore state from register save area and continue

		; restore data bank - use DP from now on
		lda	z:<deice_reg_DBR
		pha
		plb

		; restore user stack
		ldx	z:<deice_reg_SP
		txs

		ldy	z:<deice_reg_Y

		; B
		lda	z:<deice_reg_A+1
		xba


		bit	z:<deice_reg_E
		bmi	emu_exit		

		; we need to push K,PCH,PCL,P - this assumes that DeIce is in bank 0, need to think about how to restore K to 0/saved bank
		ldx	z:<deice_reg_P+2
		phx
		ldx	z:<deice_reg_P
		phx
		lda	z:<deice_reg_A
		ldx	z:<deice_reg_DP
		phx
		ldx	z:<deice_reg_X
		stz	z:<deice_run_flag
		pld
		rti
		

emu_exit:	; we need to push PCH,PCL,P - this assumes that DeIce is in bank 0, need to think about how to restore K to 0/saved bank
		ldx	z:<deice_reg_PC
		phx
		lda	z:<deice_reg_P
		pha
		lda	z:<deice_reg_A
		ldx	z:<deice_reg_DP
		phx
		ldx	z:<deice_reg_X
		stz	z:<deice_run_flag
		pld
		sec
		xce				; back to emu mode
		rti





;===========================================================================
;
;  Set target byte(s):	FN, len { (Add32(BE), data), (...)... }  - note address sense reversed from noice
;
;  Return has FN, len, (data from memory locations)
;
;  If error in insert (memory not writable), abort to return short data
;
;  This function is used primarily to set and clear breakpoints
;
;  NOTE: this is different to the standard NoICE protocol as it works with 32 bit addresses and 8 bit data
;  
SET_BYTES:

		ldy	#COMBUF+2		; POINTER TO RETURN BUFFER
		ldx	#<COMBUF+2		; POINTER TO PARAM BUFFER
		lda	z:<COMBUF+1
		sta	z:<TMP
		sta	z:<TMP2
		stz	z:<COMBUF+1		; SET RETURN COUNT AS ZERO
		phy
					
;
;  Loop on inserting bytes
SB10:
		sec
		lda	z:<TMP
		sbc	#5		
		bcc	SB99			; JIF NO BYTES (COMBUF+1 = 0)
		sta	z:<TMP

		lda	z:1,X
		pha
		plb
		lda	z:2,X
		xba
		lda	z:3,X
		tay				; DBR,Y points at memory location

;
;  Read current data at word location
		lda	a:0,Y
		pha
;
;  Insert new data at byte location
		lda	z:4,X			; GET BYTE TO BE STORED	
		sta	a:0,Y			; WRITE TARGET MEMORY
;
;  Verify write
		cmp	a:0,Y			; READ TARGET MEMORY
		bne	SB90			; BR IF INSERT FAILED: ABORT
		pla
;	
;  Save target byte in return buffer
		pea	0
		plb
		plb
		ply
		sta	a:0,Y
		iny
		phy
		inc	z:<COMBUF+1		; COUNT ONE RETURN BYTE
;
;  Loop for next byte
		inx
		inx
		inx
		inx
		inx
		bra	SB10			; *LOOP FOR ALL BYTES

; Early exit due to read back mismatch, clean up stack reset DBR
SB90:		pla
		ply
		pea	0
		plb
		plb
;
;  Return buffer with data from byte locations
;
;  Compute checksum on buffer, and send to master, then return
SB99:		bra	SEND



IN_PORT:	jmp	RETURN_ERROR
OUT_PORT:	jmp	RETURN_ERROR

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


deice_printA:
		php
		sep	#$20
		.a8
		and	#$7F		; make 7 bit ASCII for deice
		jsr	PUTCHAR
		plp
		rts		