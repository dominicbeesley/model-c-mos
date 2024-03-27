		.include "dp_sys.inc"
		.include "boot_vecs.inc"
		.include "hardware.inc"
		.include "debug.inc"

		
		.export roms_scanroms

		.code

roms_selA:	php
		sep	#$20
		sta	z:dp_mos_curROM		; assumes DP set
		sta	f:sheila_ROMCTL_SWR	; set register
		plp
		rts		

roms_scanroms:	php
		rep	#$30
		.a16
		.i16
		lda	#$AAAA
		ldx	#$4444
		ldy 	#$7777

		DEBUG_PRINTF "A=%H%A, X=%X, Y=%Y, DP=%D, B=%B, K=%K, PC=%P, P=%F\n"

		plp
		rts

