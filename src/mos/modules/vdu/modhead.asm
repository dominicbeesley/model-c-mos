


		.segment "MODHEAD"
mod_start:	brl	start
		brl	init
		brl	fini
		brl	serv
		.dword	__MODULE_LAST__-__MODULE_START__	
					; module length
		.dword  $0		; flags
		.dword  $0		; flags
		.dword  $0		; flags
		.word	title-mod_start	; title offset
		.word   $0001		; version number BCD
		.word	help-mod_start	; help string
		.word	$0000		; commands
		.dword  .loword(-1)	; COP base
		.dword  .loword(-1)	; COP top

		.code 


title:		.byte "VDU",0
help:		.byte "VDU\t\t0.01\t(01 May 2024)x",0



start:		rtl
init:		rtl
fini:		rtl
serv:		rtl