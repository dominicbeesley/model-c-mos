.ifndef __VECTORS_INC__
__VECTORS_INC__:


;------------------------------- New Vectors---------------------------------



;------------------------------- BBC Vectors --------------------------------
; These are to be used by emulation mode programs only
; the default entry will point at a bank0 code block that calls the 
; 24bit vector, extended vectors may be used to call emulation mode ROMs
; These vectors are always called in emulation mode .a8 i8, DP=0, B=0, SH=1

BBC_USERV					:=	$0200	; User vector, called by *LINE, *CODE, OSWORD >=&E0
BBC_BRKV					:=	$0202	; The BRK vector
BBC_IRQ1V					:=	$0204	; Main interrupt vector
BBC_IRQ2V					:=	$0206	; Secondary interrupt vector
BBC_CLIV					:=	$0208	; Command Line Interpreter vector
BBC_BYTEV					:=	$020A	; OSBYTE (*FX) calls
BBC_WORDV					:=	$020C	; OSWORD calls
BBC_WRCHV					:=	$020E	; Send character to current output stream
BBC_RDCHV					:=	$0210	; Wait for a character from current input stream
BBC_FILEV					:=	$0212	; Operate on a whole file, eg loading/saving/delete/etc
BBC_ARGSV					:=	$0214	; Read/Write arguments on an open file
BBC_BGETV					:=	$0216	; Read a byte from an open file
BBC_BPUTV					:=	$0218	; Write a byte to an open file
BBC_GBPBV					:=	$021A	; Read/Write block of data from/to open file or device
BBC_FINDV					:=	$021C	; Open or close a file
BBC_FSCV					:=	$021E	; Various filing system control calls
BBC_EVNTV					:=	$0220	; Event handler
BBC_UPTV					:=	$0222	; User Print vector
BBC_NETV					:=	$0224	; Network Print vector
BBC_VDUV					:=	$0226	; Unrecognised VDU commands
BBC_KEYV					:=	$0228	; Read the keyboard
BBC_INSV					:=	$022A	; Insert characters into a buffer
BBC_REMV					:=	$022C	; Remove characters from a buffer
BBC_CNPV					:=	$022E	; Count or Purge a buffer
BBC_IND1V					:=	$0230	; Spare 
BBC_IND2V					:=	$0232	; Spare
BBC_IND3V					:=	$0234	; Spare


; OS Extended Vectors Marker addresses
; the kernel places code in bank 0 at these addresses that will perform the same
; operations as the BBC/Master MOS roms

EXTVEC_ENTER_USERV			:=	$FF00	; User vector, called by *LINE, *CODE, OSWORD >=&E0
EXTVEC_ENTER_BRKV			:=	$FF03	; The BRK vector
EXTVEC_ENTER_IRQ1V			:=	$FF06	; Main interrupt vector
EXTVEC_ENTER_IRQ2V			:=	$FF09	; Secondary interrupt vector
EXTVEC_ENTER_CLIV			:=	$FF0C	; Command Line Interpreter vector
EXTVEC_ENTER_BYTEV			:=	$FF0F	; OSBYTE (*FX) calls
EXTVEC_ENTER_WORDV			:=	$FF12	; OSWORD calls
EXTVEC_ENTER_WRCHV			:=	$FF15	; Send character to current output stream
EXTVEC_ENTER_RDCHV			:=	$FF18	; Wait for a character from current input stream
EXTVEC_ENTER_FILEV			:=	$FF1B	; Operate on a whole file, eg loading/saving/delete/etc
EXTVEC_ENTER_ARGSV			:=	$FF1E	; Read/Write arguments on an open file
EXTVEC_ENTER_BGETV			:=	$FF21	; Read a byte from an open file
EXTVEC_ENTER_BPUTV			:=	$FF24	; Write a byte to an open file
EXTVEC_ENTER_GBPBV			:=	$FF27	; Read/Write block of data from/to open file or device
EXTVEC_ENTER_FINDV			:=	$FF2A	; Open or close a file
EXTVEC_ENTER_FSCV			:=	$FF2D	; Various filing system control calls
EXTVEC_ENTER_EVNTV			:=	$FF30	; Event handler
EXTVEC_ENTER_UPTV			:=	$FF33	; User Print vector
EXTVEC_ENTER_NETV			:=	$FF36	; Network Print vector
EXTVEC_ENTER_VDUV			:=	$FF39	; Unrecognised VDU commands
EXTVEC_ENTER_KEYV			:=	$FF3C	; Read the keyboard
EXTVEC_ENTER_INSV			:=	$FF3F	; Insert characters into a buffer
EXTVEC_ENTER_REMV			:=	$FF42	; Remove characters from a buffer
EXTVEC_ENTER_CNPV			:=	$FF45	; Count or Purge a buffer
EXTVEC_ENTER_IND1V			:=	$FF48	; Spare
EXTVEC_ENTER_IND2V			:=	$FF4B	; Spare
EXTVEC_ENTER_IND3V			:=	$FF4E	; Spare

; These are the three byte extended vectors as used in the BBC MOS

EXT_USERV				:=	$0D9F	; User vector, called by *LINE, *CODE, OSWORD >=&E0
EXT_BRKV				:=	$0DA2	; The BRK vector
EXT_IRQ1V				:=	$0DA5	; Main interrupt vector
EXT_IRQ2V				:=	$0DA8	; Secondary interrupt vector
EXT_CLIV				:=	$0DAB	; Command Line Interpreter vector
EXT_BYTEV				:=	$0DAE	; OSBYTE (*FX) calls
EXT_WORDV				:=	$0DB1	; OSWORD calls
EXT_WRCHV				:=	$0DB4	; Send character to current output stream
EXT_RDCHV				:=	$0DB7	; Wait for a character from current input stream
EXT_FILEV				:=	$0DBA	; Operate on a whole file, eg loading/saving/delete/etc
EXT_ARGSV				:=	$0DBD	; Read/Write arguments on an open file
EXT_BGETV				:=	$0DC0	; Read a byte from an open file
EXT_BPUTV				:=	$0DC3	; Write a byte to an open file
EXT_GBPBV				:=	$0DC6	; Read/Write block of data from/to open file or device
EXT_FINDV				:=	$0DC9	; Open or close a file
EXT_FSCV				:=	$0DCC	; Various filing system control calls
EXT_EVNTV				:=	$0DCF	; Event handler
EXT_UPTV				:=	$0DD2	; User Print vector
EXT_NETV				:=	$0DD5	; Network Print vector
EXT_VDUV				:=	$0DD8	; Unrecognised VDU commands
EXT_KEYV				:=	$0DDB	; Read the keyboard
EXT_INSV				:=	$0DDE	; Insert characters into a buffer
EXT_REMV				:=	$0DE1	; Remove characters from a buffer
EXT_CNPV				:=	$0DE4	; Count or Purge a buffer
EXT_IND1V				:=	$0DE7	; Spare
EXT_IND2V				:=	$0DEA	; Spare
EXT_IND3V				:=	$0DED	; Spare


.endif