	.IFNDEF __DP_SYS_INC__
__DP_SYS_INC__:

	; the SYS direct page - this is retained for compatibility with 6502 programs
	; and will always reside at 00 0000

 	dp_mos_lang				:= $00
 	dp_mos_eco				:= $90
 	dp_mos_nmi				:= $A0
 	dp_mos_fs_s				:= $B0
 	dp_mos_fs_w				:= $C0
 	dp_mos_vdu_status			:= $D0	; VDU Status as read by OSBYTE &75
 	dp_mos_vdu_grpixmask			:= $D1	; Graphics pixel mask
 	dp_mos_vdu_txtcolourOR			:= $D2	; Text colour OR mask
 	dp_mos_vdu_txtcolourEOR			:= $D3	; Text colour EOR mask
 	dp_mos_vdu_gracolourOR			:= $D4	; Graphics colour OR mask
 	dp_mos_vdu_gracolourEOR			:= $D5	; Graphics colour EOR mask
 	dp_mos_vdu_gra_char_cell		:= $D6	; Graphics character cell
 	dp_mos_vdu_top_scanline			:= $D8	; Top scan line
 	dp_mos_vdu_wksp				:= $DA	; Temporary workspace
 	dp_mos_vdu_mul				:= $E0	; BBC, Electron: Row multiplication
 	dp_mos_cfs_w				:= $E2
 	dp_mos_opt_val				:= $E3	; DB? check
 	dp_mos_GSREAD_quoteflag			:= $E4	; GSREAD quote flag
 	dp_mos_GSREAD_characc			:= $E5	; GSREAD character accumulator
 	dp_mos_OS_wksp				:= $E6	; General OS workspace
 	dp_mos_autorep_countdown		:= $E7	; Auto repeat countdown timer
 	dp_mos_input_buf			:= $E8	; Input buffer pointer for OSWORD 0
 	dp_mos_rs423timeout			:= $EA	; RS423 timeout counter, unused if no RS423
 	dp_mos_cfs_critical			:= $EB	; CFS/RFS 'critical' flag
 	dp_mos_keynumlast			:= $EC	; Internal key number (last)
 	dp_mos_keynumfirst			:= $ED	; Internal key number (first)
 	dp_mos_jimdevsave			:= $EE	; Internal key number of character to be ignored by OSBYTE &79, also the 1MHz bus paging register
 	dp_mos_OSBW_A				:= $EF	; OSBYTE/OSWORD A reg value
 	dp_mos_OSBW_X				:= $F0	; OSBYTE/OSWORD X reg value
 	dp_mos_OSBW_Y				:= $F1	; OSBYTE/OSWORD Y reg value

	dp_mos_lptr				:= $EF	; overlays OSBYTE, TODO: move, or rethink

 	dp_mos_txtptr				:= $F2	; OS Text pointer (eg star commands and filenames)
 	dp_mos_curROM				:= $F4	; Currently selected ROM
 	dp_mos_curPHROM				:= $F5	; Current PHROM or RFS ROM number or OSRDSC/OSWRSC number
 	dp_mos_genPTR				:= $F6	; PHROM/RFSROM/OSRDSC/OSWRSC pointer
 	dp_mos_X				:= $F8	; BBC, Electron: Unused, Master: Soft key expansion pointer
 	dp_mos_OS_wksp2				:= $FA	; General OS workspace, used by buffer access code in interrupts
 	dp_mos_INT_A				:= $FC	; Interrupt Temp A reg store
 	dp_mos_error_ptr			:= $FD	; Error message pointer, initially set to language version string
 	dp_mos_ESC_flag				:= $FF	; Escape flag (bit 7)


	.ENDIF