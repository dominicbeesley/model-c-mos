.ifndef __NAT_LAYOUT_INC__
__NAT_LAYOUT_INC__:

		.include "vectors.inc"
		

TEST_AREA		:= $1000

NAT_OS_VECS 		:= $8000
NAT_OS_VECS_COUNT 	:= 26


B0LL_FREE_BLOCKS	:= $00FE00
B0LL_FREE_BLOCKS_END	:= $00FE02

B0B_BASE		:= $00E000
B0B_END			:= $00FCF8


B0B_TYPE_FREE		:= 0
B0B_TYPE_LL_NATVEC	:= 10
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

.assert .sizeof(b0b_ll_nat_vec) = 12, error
.assert .sizeof(b0b_ll_free) = 12, error

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