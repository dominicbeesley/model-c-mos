.ifndef __NAT_LAYOUT_INC__
__NAT_LAYOUT_INC__:

		.include "vectors.inc"
		
DPBBC			:= $0000
STACKBBC		:= $0100
STACKBBC_TOP		:= $01FF


HANDLER_TRAMPOLINES	:= $0B00			; set in .cfg file - Repurposes Soft Keys expansion buffer

TEST_AREA		:= $1000

SOFTKEYS		:= $2000			; moved WRT to BBC mos was 0B00
DEICEBSS		:= $2100
STACKNAT		:= $2600
STACKNAT_TOP		:= $2A00
NAT_OS_VECS 		:= $8000
NAT_OS_VECS_COUNT 	:= IX_VEC_MAX+1

B0B_BASE		:= $00E000
B0B_END			:= $00FCF8

B0LL_FREE_BLOCKS	:= $00FE00
B0LL_FREE_BLOCKS_END	:= $00FE02
B0LL_IRQ_BLOCKS		:= $00FE06
B0_IRQ_STACK		:= $00FE10
B0_EMU_STACK		:= $00FE12
B0_NAT_STACK		:= $00FE14

EXSYS			:= $00FF00
EXSYS_FpHandles		:= $00FF02

HANDLE_BLOCK		:= $010000
HANDLE_BLOCK_LEN	:= $000100

B0B_TYPE_FREE		:= 0
B0B_TYPE_LL_NATVEC	:= 10
B0B_TYPE_LL_IRQ		:= 14
B0B_SIZE		:= 12
; each vector is 2 bytes long - points to a 12 byte block in B0 as in struct llent_nat_vec

.struct b0b_ll_nat_vec
	next	.word		; next entry in the linked list (or zero for last)
	dp	.word		; handler's private DP
	handler	.faraddr	; far pointer to handler routine (not checked for sanity) suitable for rti
	return	.faraddr	; far pointer to the exit routine-1 (suitable for rtl)
	resv	.res 1		; ignored
	type	.byte		; type should be B0B_TYPE_LL_NATVEC
.endstruct

.struct b0b_ll_free
	next	.word		; next entry in the "free" chain
	resv	.res 9
	type	.byte
.endstruct

; IRQ blocks have a primary and secondary block
.struct b0b_ll_irq_pri
	next	.word		; 0..1	next entry in the "free" chain
	irqf	.faraddr	; 2..4	far pointer to HW status register	
	mand	.byte		; 5	and mask
	meor    .byte		; 6	eor mask
	psec	.word		; 7..8  pointer to secondary block
	fpand	.faraddr	; 9..11 far pointer to AND mask
.endstruct

.struct b0b_ll_irq_sec
	prior	.byte		; 0	interrupt priority
	dp	.word		; 1..2	handler DP
	flags	.byte		; 3	handler flags on entry
	fphand  .faraddr	; 4..6  handler far address
	hitct	.dword		; 7..10	count of accesses
	type    .byte		; 11	= 14
.endstruct

.assert .sizeof(b0b_ll_nat_vec) = 12, error
.assert .sizeof(b0b_ll_free) = 12, error
.assert .sizeof(b0b_ll_irq_pri) = 12, error
.assert .sizeof(b0b_ll_irq_sec) = 12, error

; NOTE: that the native vectors are 3 byte each, the 3rd byte of each is unused and reserved

NAT_USERV					:=	NAT_OS_VECS+3*IX_USERV	; User vector, called by *LINE, *CODE, OSWORD >=&E0
NAT_BRKV					:=	NAT_OS_VECS+3*IX_BRKV	; The BRK vector
NAT_IRQ1V					:=	NAT_OS_VECS+3*IX_IRQ1V	; Main interrupt vector
NAT_IRQ2V					:=	NAT_OS_VECS+3*IX_IRQ2V	; Secondary interrupt vector
NAT_CLIV					:=	NAT_OS_VECS+3*IX_CLIV	; Command Line Interpreter vector
NAT_BYTEV					:=	NAT_OS_VECS+3*IX_BYTEV	; OSBYTE (*FX) calls
NAT_WORDV					:=	NAT_OS_VECS+3*IX_WORDV	; OSWORD calls
NAT_WRCHV					:=	NAT_OS_VECS+3*IX_WRCHV	; Send character to current output stream
NAT_RDCHV					:=	NAT_OS_VECS+3*IX_RDCHV	; Wait for a character from current input stream
NAT_FILEV					:=	NAT_OS_VECS+3*IX_FILEV	; Operate on a whole file, eg loading/saving/delete/etc
NAT_ARGSV					:=	NAT_OS_VECS+3*IX_ARGSV	; Read/Write arguments on an open file
NAT_BGETV					:=	NAT_OS_VECS+3*IX_BGETV	; Read a byte from an open file
NAT_BPUTV					:=	NAT_OS_VECS+3*IX_BPUTV	; Write a byte to an open file
NAT_GBPBV					:=	NAT_OS_VECS+3*IX_GBPBV	; Read/Write block of data from/to open file or device
NAT_FINDV					:=	NAT_OS_VECS+3*IX_FINDV	; Open or close a file
NAT_FSCV					:=	NAT_OS_VECS+3*IX_FSCV	; Various filing system control calls
NAT_EVNTV					:=	NAT_OS_VECS+3*IX_EVNTV	; Event handler
NAT_UPTV					:=	NAT_OS_VECS+3*IX_UPTV	; User Print vector
NAT_NETV					:=	NAT_OS_VECS+3*IX_NETV	; Network Print vector
NAT_VDUV					:=	NAT_OS_VECS+3*IX_VDUV	; Unrecognised VDU commands
NAT_KEYV					:=	NAT_OS_VECS+3*IX_KEYV	; Read the keyboard
NAT_INSV					:=	NAT_OS_VECS+3*IX_INSV	; Insert characters into a buffer
NAT_REMV					:=	NAT_OS_VECS+3*IX_REMV	; Remove characters from a buffer
NAT_CNPV					:=	NAT_OS_VECS+3*IX_CNPV	; Count or Purge a buffer
NAT_IND1V					:=	NAT_OS_VECS+3*IX_IND1V	; Spare 
NAT_IND2V					:=	NAT_OS_VECS+3*IX_IND2V	; Spare
NAT_IND3V					:=	NAT_OS_VECS+3*IX_IND3V	; Spare


.endif