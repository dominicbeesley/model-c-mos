.ifndef __NAT_LAYOUT_INC__
__NAT_LAYOUT_INC__:

		.include "vectors.inc"
		
DPBBC			:= $0000
STACKBBC		:= $0100
STACKBBC_TOP		:= $01FF

SOFTKEYS		:= $0B00


B0B_BASE		:= $00A000
B0B_END			:= $00BCF8


;---- C000 - E000 must be left free for Hazel overlay

STACKNAT		:= $00F700
STACKNAT_TOP		:= $00FB00
HANDLER_TRAMPOLINES	:= $00FB00			; set in .cfg file - Repurposes Soft Keys expansion buffer
DEICEBSS		:= $00FC00
NAT_OS_VECS 		:= $00FD00
NAT_OS_VECS_COUNT 	:= IX_VEC_MAX+1
B0LL_FREE_BLOCKS	:= $00FE00
B0LL_FREE_BLOCKS_END	:= $00FE02
B0LL_IRQ_BLOCKS		:= $00FE06
B0LL_MODULES		:= $00FE08
B0_IRQ_STACK		:= $00FE10
B0_EMU_STACK		:= $00FE12
B0_NAT_STACK		:= $00FE14
WINDOW_CUR		:= $00FE16			; current value of the window registers

EXSYS			:= $00FF00
EXSYS_FpHandles		:= $00FF02

HANDLE_BLOCK		:= $010000
HANDLE_BLOCK_LEN	:= $000100

B0B_TYPE_FREE		:= 0
B0B_TYPE_LL_NATVEC	:= 10
B0B_TYPE_LL_MODULE	:= 12
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

.struct b0b_ll_mod
	next	.word		; 0..1	next entry in the "free" chain
	resv	.word		; 2..3	reserved
	addr	.faraddr	; 4..6  module base address
	pri	.dword		; 7..10 module instance private space
	type	.byte		; 11	= 12
.endstruct


.assert .sizeof(b0b_ll_nat_vec) = 12, error
.assert .sizeof(b0b_ll_free) = 12, error
.assert .sizeof(b0b_ll_irq_pri) = 12, error
.assert .sizeof(b0b_ll_irq_sec) = 12, error

.endif