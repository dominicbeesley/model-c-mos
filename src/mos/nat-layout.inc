.ifndef __NAT_LAYOUT_INC__
__NAT_LAYOUT_INC__:


TEST_AREA	:= $1000

NAT_OS_VECS := $8000
NAT_OS_VECS_COUNT := 26

BLOCK_TYPE_LL_NATVEC	= 	10

; each vector is 2 bytes long - points to a 12 byte block in B0 as in struct llent_nat_vec

.struct llent_nat_vec
	next		.word		; next entry in the linked list (or zero for last)
	dp			.word		; handler's private DP
	handler		.faraddr	; far pointer to handler routine (not checked for sanity) suitable for rti
	return		.faraddr	; far pointer to the exit routine-1 (suitable for rtl)
	resv		.res 1		; ignored
	type		.byte		; type should be BLOCK_TYPE_LL_NATVEC
.endstruct

.assert .sizeof(llent_nat_vec) = 12, error

; NOTE: that the native vectors are 3 byte each, the 3rd byte of each is unused and reserved

NAT_USERV					:=	NAT_OS_VECS+ $00	; User vector, called by *LINE, *CODE, OSWORD >=&E0
NAT_BRKV					:=	NAT_OS_VECS+ $03	; The BRK vector
NAT_IRQ1V					:=	NAT_OS_VECS+ $06	; Main interrupt vector
NAT_IRQ2V					:=	NAT_OS_VECS+ $09	; Secondary interrupt vector
NAT_CLIV					:=	NAT_OS_VECS+ $0C	; Command Line Interpreter vector
NAT_BYTEV					:=	NAT_OS_VECS+ $0F	; OSBYTE (*FX) calls
NAT_WORDV					:=	NAT_OS_VECS+ $12	; OSWORD calls
NAT_WRCHV					:=	NAT_OS_VECS+ $15	; Send character to current output stream
NAT_RDCHV					:=	NAT_OS_VECS+ $18	; Wait for a character from current input stream
NAT_FILEV					:=	NAT_OS_VECS+ $1B	; Operate on a whole file, eg loading/saving/delete/etc
NAT_ARGSV					:=	NAT_OS_VECS+ $1E	; Read/Write arguments on an open file
NAT_BGETV					:=	NAT_OS_VECS+ $21	; Read a byte from an open file
NAT_BPUTV					:=	NAT_OS_VECS+ $24	; Write a byte to an open file
NAT_GBPBV					:=	NAT_OS_VECS+ $27	; Read/Write block of data from/to open file or device
NAT_FINDV					:=	NAT_OS_VECS+ $2A	; Open or close a file
NAT_FSCV					:=	NAT_OS_VECS+ $2D	; Various filing system control calls
NAT_EVNTV					:=	NAT_OS_VECS+ $30	; Event handler
NAT_UPTV					:=	NAT_OS_VECS+ $33	; User Print vector
NAT_NETV					:=	NAT_OS_VECS+ $36	; Network Print vector
NAT_VDUV					:=	NAT_OS_VECS+ $39	; Unrecognised VDU commands
NAT_KEYV					:=	NAT_OS_VECS+ $3C	; Read the keyboard
NAT_INSV					:=	NAT_OS_VECS+ $3F	; Insert characters into a buffer
NAT_REMV					:=	NAT_OS_VECS+ $42	; Remove characters from a buffer
NAT_CNPV					:=	NAT_OS_VECS+ $45	; Count or Purge a buffer
NAT_IND1V					:=	NAT_OS_VECS+ $48	; Spare 
NAT_IND2V					:=	NAT_OS_VECS+ $4B	; Spare
NAT_IND3V					:=	NAT_OS_VECS+ $4E	; Spare


.endif