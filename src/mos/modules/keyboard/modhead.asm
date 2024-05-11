		.include "oslib.inc"


		.segment "MODHEAD"
mod_start:	brl	serv
		brl	start
		brl	init
		brl	fini
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


title:		.byte "Keyboard",0
help:		.byte "Keyboard\t\t0.01\t(10 May 2024)x",0


		.a16
		.i16
start:		rtl

		.a16
		.i16
init:		jsr	initKeyboard

		rtl

		.a16
		.i16
fini:		rtl

		.a16
		.i16
serv:		rtl