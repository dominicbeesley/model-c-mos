		.include "oslib.inc"	
		.include "vectors.inc"
	
		
		.segment "BBCCODE"

bbc_OSRDRM: rts
bbc_VDUCHR: rts
bbc_OSEVEN: rts
bbc_GSINIT: rts
bbc_GSREAD: rts
bbc_NVRDCH: rts
bbc_NVWRCH: rts


		.segment "BBC_MOS_OSAPI"


		.byte	<default_BBC_vectors_len	; length of look up table in bytes
		.addr	default_BBC_vectors		; address of this table


;**************************************************************************
;**************************************************************************
;**									 **
;**	 OPERATING SYSTEM FUNCTION CALLS				 **
;**									 **
;**************************************************************************
;**************************************************************************


OSRDRM:			jmp	bbc_OSRDRM			; OSRDRM get a byte from sideways ROM
VDUCHR:			jmp	bbc_VDUCHR			; VDUCHR VDU character output
OSEVEN:			jmp	bbc_OSEVEN			; OSEVEN generate an EVENT
GSINIT:			jmp	bbc_GSINIT			; GSINIT initialise OS string
GSREAD:			jmp	bbc_GSREAD			; GSREAD read character from input stream
NVRDCH:			jmp	bbc_NVRDCH			; NVRDCH non vectored OSRDCH
NVWRCH:			jmp	bbc_NVWRCH			; NVWRCH non vectored OSWRCH
OSFIND:			jmp	(BBC_FINDV)			; OSFIND open or close a file
			jmp	(BBC_GBPBV)			; OSGBPB transfer block to or from a file
OSBPUT:			jmp	(BBC_BPUTV)			; OSBPUT save a byte to file
OSBGET:			jmp	(BBC_BGETV)			; OSBGET get a byte from file
OSARGS:			jmp	(BBC_ARGSV)			; OSARGS read or write file arguments
OSFILE:			jmp	(BBC_FILEV)			; OSFILE read or write a file
OSRDCH:			jmp	(BBC_RDCHV)			; OSRDCH get a byte from current input stream
OSASCI:			cmp	#$0d				; OSASCI output a byte to VDU stream expanding
			bne	OSWRCH				; carriage returns (&0D) to LF/CR (&0A,&0D)
OSNEWL:			lda	#$0a				; OSNEWL output a CR/LF to VDU stream
			jsr	OSWRCH				; Outputs A followed by CR to VDU stream
			lda	#$0d				; OSWRCR output a CR to VDU stream
OSWRCH:			jmp	(BBC_WRCHV)			; OSWRCH output a character to the VDU stream
OSWORD:			jmp	(BBC_WORDV)			; OSWORD perform operation using parameter table
OSBYTE:			jmp	(BBC_BYTEV)			; OSBYTE perform operation with single bytes
OSCLI:			jmp	(BBC_CLIV)			; OSCLI	 pass string to command line interpreter
