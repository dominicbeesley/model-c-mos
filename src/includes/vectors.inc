.ifndef __VECTORS_INC__
__VECTORS_INC__:

		.include "nat-layout.inc"

;------------------------------- New Vectors---------------------------------

; OS Vectors

BBC_VECTORS_BASE			:= $0200
BBC_EXT_VEC_ENTRY_BASE			:= $FF00
BBC_EXT_VEC_BASE			:= $0D9F

; Indices - these are used in 16 bit calls i.e. CallAVector
IX_USERV				:= $00
IX_BRKV					:= $01
IX_IRQ1V				:= $02
IX_IRQ2V				:= $03
IX_CLIV					:= $04
IX_BYTEV				:= $05
IX_WORDV				:= $06
IX_WRCHV				:= $07
IX_RDCHV				:= $08
IX_FILEV				:= $09
IX_ARGSV				:= $0A
IX_BGETV				:= $0B
IX_BPUTV				:= $0C
IX_GBPBV				:= $0D
IX_FINDV				:= $0E
IX_FSCV					:= $0F
IX_EVNTV				:= $10
IX_UPTV					:= $11
IX_NETV					:= $12
IX_VDUV					:= $13
IX_KEYV					:= $14
IX_INSV					:= $15
IX_REMV					:= $16
IX_CNPV					:= $17
IX_IND1V				:= $18
IX_IND2V				:= $19
IX_IND3V				:= $1A

IX_VEC_BBC_MAX				:= $1A

IX_N_P100V				:= $1B

IX_VEC_MAX				:= $1B

;------------------------------- BBC Vectors --------------------------------
; These are to be used by emulation mode programs only
; the default entry will point at a bank0 code block that calls the 
; 24bit vector, extended vectors may be used to call emulation mode ROMs
; These vectors are always called in emulation mode .a8 i8, DP=0, B=0, SH=1

BBC_USERV		:= BBC_VECTORS_BASE + 2*IX_USERV	; User vector, called by *LINE, *CODE, OSWORD >=&E0
BBC_BRKV		:= BBC_VECTORS_BASE + 2*IX_BRKV		; The BRK vector
BBC_IRQ1V		:= BBC_VECTORS_BASE + 2*IX_IRQ1V	; Main interrupt vector
BBC_IRQ2V		:= BBC_VECTORS_BASE + 2*IX_IRQ2V	; Secondary interrupt vector
BBC_CLIV		:= BBC_VECTORS_BASE + 2*IX_CLIV		; Command Line Interpreter vector
BBC_BYTEV		:= BBC_VECTORS_BASE + 2*IX_BYTEV	; OSBYTE (*FX) calls
BBC_WORDV		:= BBC_VECTORS_BASE + 2*IX_WORDV	; OSWORD calls
BBC_WRCHV		:= BBC_VECTORS_BASE + 2*IX_WRCHV	; Send character to current output stream
BBC_RDCHV		:= BBC_VECTORS_BASE + 2*IX_RDCHV	; Wait for a character from current input stream
BBC_FILEV		:= BBC_VECTORS_BASE + 2*IX_FILEV	; Operate on a whole file, eg loading/saving/delete/etc
BBC_ARGSV		:= BBC_VECTORS_BASE + 2*IX_ARGSV	; Read/Write arguments on an open file
BBC_BGETV		:= BBC_VECTORS_BASE + 2*IX_BGETV	; Read a byte from an open file
BBC_BPUTV		:= BBC_VECTORS_BASE + 2*IX_BPUTV	; Write a byte to an open file
BBC_GBPBV		:= BBC_VECTORS_BASE + 2*IX_GBPBV	; Read/Write block of data from/to open file or device
BBC_FINDV		:= BBC_VECTORS_BASE + 2*IX_FINDV	; Open or close a file
BBC_FSCV		:= BBC_VECTORS_BASE + 2*IX_FSCV		; Various filing system control calls
BBC_EVNTV		:= BBC_VECTORS_BASE + 2*IX_EVNTV	; Event handler
BBC_UPTV		:= BBC_VECTORS_BASE + 2*IX_UPTV		; User Print vector
BBC_NETV		:= BBC_VECTORS_BASE + 2*IX_NETV		; Network Print vector
BBC_VDUV		:= BBC_VECTORS_BASE + 2*IX_VDUV		; Unrecognised VDU commands
BBC_KEYV		:= BBC_VECTORS_BASE + 2*IX_KEYV		; Read the keyboard
BBC_INSV		:= BBC_VECTORS_BASE + 2*IX_INSV		; Insert characters into a buffer
BBC_REMV		:= BBC_VECTORS_BASE + 2*IX_REMV		; Remove characters from a buffer
BBC_CNPV		:= BBC_VECTORS_BASE + 2*IX_CNPV		; Count or Purge a buffer
BBC_IND1V		:= BBC_VECTORS_BASE + 2*IX_IND1V	; Spare 
BBC_IND2V		:= BBC_VECTORS_BASE + 2*IX_IND2V	; Spare
BBC_IND3V		:= BBC_VECTORS_BASE + 2*IX_IND3V	; Spare


; BBC extended vectors - entry points, these addresses placed in BBC_* vector
; to call via the 3 byte addresses in the EXT_* vectors
; these are entry points in the emulation mode ROM

EXTVEC_ENTER_USERV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_USERV	; User vector, called by *LINE, *CODE, OSWORD >=&E0
EXTVEC_ENTER_BRKV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_BRKV	; The BRK vector
EXTVEC_ENTER_IRQ1V	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_IRQ1V	; Main interrupt vector
EXTVEC_ENTER_IRQ2V	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_IRQ2V	; Secondary interrupt vector
EXTVEC_ENTER_CLIV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_CLIV	; Command Line Interpreter vector
EXTVEC_ENTER_BYTEV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_BYTEV	; OSBYTE (*FX) calls
EXTVEC_ENTER_WORDV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_WORDV	; OSWORD calls
EXTVEC_ENTER_WRCHV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_WRCHV	; Send character to current output stream
EXTVEC_ENTER_RDCHV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_RDCHV	; Wait for a character from current input stream
EXTVEC_ENTER_FILEV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_FILEV	; Operate on a whole file, eg loading/saving/delete/etc
EXTVEC_ENTER_ARGSV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_ARGSV	; Read/Write arguments on an open file
EXTVEC_ENTER_BGETV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_BGETV	; Read a byte from an open file
EXTVEC_ENTER_BPUTV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_BPUTV	; Write a byte to an open file
EXTVEC_ENTER_GBPBV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_GBPBV	; Read/Write block of data from/to open file or device
EXTVEC_ENTER_FINDV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_FINDV	; Open or close a file
EXTVEC_ENTER_FSCV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_FSCV	; Various filing system control calls
EXTVEC_ENTER_EVNTV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_EVNTV	; Event handler
EXTVEC_ENTER_UPTV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_UPTV	; User Print vector
EXTVEC_ENTER_NETV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_NETV	; Network Print vector
EXTVEC_ENTER_VDUV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_VDUV	; Unrecognised VDU commands
EXTVEC_ENTER_KEYV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_KEYV	; Read the keyboard
EXTVEC_ENTER_INSV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_INSV	; Insert characters into a buffer
EXTVEC_ENTER_REMV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_REMV	; Remove characters from a buffer
EXTVEC_ENTER_CNPV	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_CNPV	; Count or Purge a buffer
EXTVEC_ENTER_IND1V	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_IND1V	; Spare
EXTVEC_ENTER_IND2V	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_IND2V	; Spare
EXTVEC_ENTER_IND3V	:= BBC_EXT_VEC_ENTRY_BASE + 3*IX_IND3V	; Spare

; These are the three byte extended vectors as used in the BBC MOS

EXT_USERV		:= BBC_EXT_VEC_BASE + 3*IX_USERV	; User vector, called by *LINE, *CODE, OSWORD >=&E0
EXT_BRKV		:= BBC_EXT_VEC_BASE + 3*IX_BRKV		; The BRK vector
EXT_IRQ1V		:= BBC_EXT_VEC_BASE + 3*IX_IRQ1V	; Main interrupt vector
EXT_IRQ2V		:= BBC_EXT_VEC_BASE + 3*IX_IRQ2V	; Secondary interrupt vector
EXT_CLIV		:= BBC_EXT_VEC_BASE + 3*IX_CLIV		; Command Line Interpreter vector
EXT_BYTEV		:= BBC_EXT_VEC_BASE + 3*IX_BYTEV	; OSBYTE (*FX) calls
EXT_WORDV		:= BBC_EXT_VEC_BASE + 3*IX_WORDV	; OSWORD calls
EXT_WRCHV		:= BBC_EXT_VEC_BASE + 3*IX_WRCHV	; Send character to current output stream
EXT_RDCHV		:= BBC_EXT_VEC_BASE + 3*IX_RDCHV	; Wait for a character from current input stream
EXT_FILEV		:= BBC_EXT_VEC_BASE + 3*IX_FILEV	; Operate on a whole file, eg loading/saving/delete/etc
EXT_ARGSV		:= BBC_EXT_VEC_BASE + 3*IX_ARGSV	; Read/Write arguments on an open file
EXT_BGETV		:= BBC_EXT_VEC_BASE + 3*IX_BGETV	; Read a byte from an open file
EXT_BPUTV		:= BBC_EXT_VEC_BASE + 3*IX_BPUTV	; Write a byte to an open file
EXT_GBPBV		:= BBC_EXT_VEC_BASE + 3*IX_GBPBV	; Read/Write block of data from/to open file or device
EXT_FINDV		:= BBC_EXT_VEC_BASE + 3*IX_FINDV	; Open or close a file
EXT_FSCV		:= BBC_EXT_VEC_BASE + 3*IX_FSCV		; Various filing system control calls
EXT_EVNTV		:= BBC_EXT_VEC_BASE + 3*IX_EVNTV	; Event handler
EXT_UPTV		:= BBC_EXT_VEC_BASE + 3*IX_UPTV		; User Print vector
EXT_NETV		:= BBC_EXT_VEC_BASE + 3*IX_NETV		; Network Print vector
EXT_VDUV		:= BBC_EXT_VEC_BASE + 3*IX_VDUV		; Unrecognised VDU commands
EXT_KEYV		:= BBC_EXT_VEC_BASE + 3*IX_KEYV		; Read the keyboard
EXT_INSV		:= BBC_EXT_VEC_BASE + 3*IX_INSV		; Insert characters into a buffer
EXT_REMV		:= BBC_EXT_VEC_BASE + 3*IX_REMV		; Remove characters from a buffer
EXT_CNPV		:= BBC_EXT_VEC_BASE + 3*IX_CNPV		; Count or Purge a buffer
EXT_IND1V		:= BBC_EXT_VEC_BASE + 3*IX_IND1V	; Spare
EXT_IND2V		:= BBC_EXT_VEC_BASE + 3*IX_IND2V	; Spare
EXT_IND3V		:= BBC_EXT_VEC_BASE + 3*IX_IND3V	; Spare


; NOTE: the native vector entry points are not listed here as they are not part of the OS
; API, instead API calls should be used to call/manipulate the native OS vectors
; the layout of the native vectors is in nat-layout.inc


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
NAT_N_P100V					:=	NAT_OS_VECS+3*IX_N_P100V; 100Hz poll vector


.endif