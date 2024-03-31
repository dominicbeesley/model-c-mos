.ifndef __NAT_LAYOUT_INC__
__NAT_LAYOUT_INC__:

NAT_OS_VECS := $8000

NAT_USERV					:=	NAT_OS_VECS+ $00	; User vector, called by *LINE, *CODE, OSWORD >=&E0
NAT_BRKV					:=	NAT_OS_VECS+ $02	; The BRK vector
NAT_IRQ1V					:=	NAT_OS_VECS+ $04	; Main interrupt vector
NAT_IRQ2V					:=	NAT_OS_VECS+ $06	; Secondary interrupt vector
NAT_CLIV					:=	NAT_OS_VECS+ $08	; Command Line Interpreter vector
NAT_BYTEV					:=	NAT_OS_VECS+ $0A	; OSBYTE (*FX) calls
NAT_WORDV					:=	NAT_OS_VECS+ $0C	; OSWORD calls
NAT_WRCHV					:=	NAT_OS_VECS+ $0E	; Send character to current output stream
NAT_RDCHV					:=	NAT_OS_VECS+ $10	; Wait for a character from current input stream
NAT_FILEV					:=	NAT_OS_VECS+ $12	; Operate on a whole file, eg loading/saving/delete/etc
NAT_ARGSV					:=	NAT_OS_VECS+ $14	; Read/Write arguments on an open file
NAT_BGETV					:=	NAT_OS_VECS+ $16	; Read a byte from an open file
NAT_BPUTV					:=	NAT_OS_VECS+ $18	; Write a byte to an open file
NAT_GBPBV					:=	NAT_OS_VECS+ $1A	; Read/Write block of data from/to open file or device
NAT_FINDV					:=	NAT_OS_VECS+ $1C	; Open or close a file
NAT_FSCV					:=	NAT_OS_VECS+ $1E	; Various filing system control calls
NAT_EVNTV					:=	NAT_OS_VECS+ $20	; Event handler
NAT_UPTV					:=	NAT_OS_VECS+ $22	; User Print vector
NAT_NETV					:=	NAT_OS_VECS+ $24	; Network Print vector
NAT_VDUV					:=	NAT_OS_VECS+ $26	; Unrecognised VDU commands
NAT_KEYV					:=	NAT_OS_VECS+ $28	; Read the keyboard
NAT_INSV					:=	NAT_OS_VECS+ $2A	; Insert characters into a buffer
NAT_REMV					:=	NAT_OS_VECS+ $2C	; Remove characters from a buffer
NAT_CNPV					:=	NAT_OS_VECS+ $2E	; Count or Purge a buffer
NAT_IND1V					:=	NAT_OS_VECS+ $30	; Spare 
NAT_IND2V					:=	NAT_OS_VECS+ $32	; Spare
NAT_IND3V					:=	NAT_OS_VECS+ $34	; Spare


.endif