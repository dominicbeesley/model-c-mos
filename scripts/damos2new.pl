#!/usr/bin/env perl

# Convert zp/sys variable names in mos disassembly to model-c-mos names

use strict;

while (<>) {

# ZP MOS
	s/\bVDU_STATUS\b/dp_mos_vdu_status/g;
	s/\bVDU_G_PIX_MASK\b/dp_mos_vdu_grpixmask/g;
	s/\bVDU_T_OR_MASK\b/dp_mos_vdu_txtcolourOR/g;
	s/\bVDU_T_EOR_MASK\b/dp_mos_vdu_txtcolourEOR/g;
	s/\bVDU_G_OR_MASK\b/dp_mos_vdu_gracolourOR/g;
	s/\bVDU_G_EOR_MASK\b/dp_mos_vdu_gracolourEOR/g;
	s/\bVDU_G_MEM\b/dp_mos_vdu_gra_char_cell/g;
	s/\bVDU_G_MEM_HI\b/dp_mos_vdu_gra_char_cell+1/g;
	s/\bVDU_TOP_SCAN\b/dp_mos_vdu_top_scanline/g;
	s/\bVDU_TOP_SCAN_HI\b/dp_mos_vdu_top_scanline+1/g;
	s/\bVDU_TMP1\b/dp_mos_vdu_wksp/g;
	s/\bVDU_TMP2\b/dp_mos_vdu_wksp+1/g;
	s/\bVDU_TMP3\b/dp_mos_vdu_wksp+2/g;
	s/\bVDU_TMP4\b/dp_mos_vdu_wksp+3/g;
	s/\bVDU_TMP5\b/dp_mos_vdu_wksp+4/g;
	s/\bVDU_TMP6\b/dp_mos_vdu_wksp+5/g;
	s/\bVDU_ROW_MULT\b/dp_mos_vdu_mul/g;
	s/\bVDU_ROW_MULT_HI\b/dp_mos_vdu_mul+1/g;
	s/\bCRFS_STATUS\b/dp_mos_cfs_w/g;
	s/\bCRFS_OPTIONS\b/dp_mos_opt_val/g;
	s/\bOSBYTE_PAR_3\b/dp_mos_GSREAD_quoteflag/g;
	s/\bOSBYTE_PAR_2\b/dp_mos_GSREAD_characc/g;
	s/\bMOS_WS\b/dp_mos_OS_wksp/g;
	s/\bAUTO_REPEAT_TIMER\b/dp_mos_autorep_countdown/g;
	s/\bOSW_0_PTR\b/dp_mos_input_buf/g;
	s/\bOSW_0_PTR_HI\b/dp_mos_input_buf+1/g;
	s/\bRS423_TIMEOUT\b/dp_mos_rs423timeout/g;
	s/\bCRFS_ACTIVE\b/dp_mos_cfs_critical/g;
	s/\bKEYNUM_FIRST\b/dp_mos_keynumlast/g;
	s/\bKEYNUM_LAST\b/dp_mos_keynumfirst/g;
	s/\bOSW_A\b/dp_mos_OSBW_A/g;
	s/\bOSW_X\b/dp_mos_OSBW_X/g;
	s/\bOSW_Y\b/dp_mos_OSBW_Y/g;
	s/\bTEXT_PTR\b/dp_mos_txtptr/g;
	s/\bTEXT_PTR_HI\b/dp_mos_txtptr+1/g;
	s/\bROM_SELECT\b/dp_mos_curROM/g;
	s/\bRFS_SELECT\b/dp_mos_curPHROM/g;
	s/\bROM_PTR\b/dp_mos_genPTR/g;
	s/\bROM_PTR_HI\b/dp_mos_genPTR+1/g;
	s/\bMOS_WS_0\b/dp_mos_OS_wksp2/g;
	s/\bMOS_WS_1\b/dp_mos_OS_wksp2+1/g;
	s/\bIRQ_COPY_A\b/dp_mos_INT_A/g;
	s/\bERR_MSG_PTR\b/dp_mos_error_ptr/g;
	s/\bERR_MSG_PTR_HI\b/dp_mos_error_ptr+1/g;
	s/\bESCAPE_FLAG\b/dp_mos_ESC_flag/g;

# VDU Variables

	s/VDU_VARS_BASE\b/vduvars_start/g;
	s/VDU_G_WIN_L\b/vduvar_GRA_WINDOW_LEFT/g;
	s/VDU_G_WIN_L_HI\b/vduvar_GRA_WINDOW_LEFT+1/g;
	s/VDU_G_WIN_B\b/vduvar_GRA_WINDOW_BOTTOM/g;
	s/VDU_G_WIN_B_HI\b/vduvar_GRA_WINDOW_BOTTOM+1/g;
	s/VDU_G_WIN_R\b/vduvar_GRA_WINDOW_RIGHT/g;
	s/VDU_G_WIN_R_HI\b/vduvar_GRA_WINDOW_RIGHT+1/g;
	s/VDU_G_WIN_T\b/vduvar_GRA_WINDOW_TOP/g;
	s/VDU_G_WIN_T_HI\b/vduvar_GRA_WINDOW_TOP+1/g;
	s/VDU_T_WIN_L\b/vduvar_TXT_WINDOW_LEFT/g;
	s/VDU_T_WIN_B\b/vduvar_TXT_WINDOW_BOTTOM/g;
	s/VDU_T_WIN_R\b/vduvar_TXT_WINDOW_RIGHT/g;
	s/VDU_T_WIN_T\b/vduvar_TXT_WINDOW_TOP/g;
	s/VDU_G_ORG_XX\b/vduvar_GRA_ORG_EXT/g;
	s/VDU_G_ORG_XX_HI\b/vduvar_GRA_ORG_EXT+1/g;
	s/VDU_G_ORG_YX\b/vduvar_GRA_ORG_EXT+2/g;
	s/VDU_G_ORG_YX_HI\b/vduvar_GRA_ORG_EXT+3/g;
	s/VDU_G_CUR_XX\b/vduvar_GRA_CUR_EXT/g;
	s/VDU_G_CUR_XX_HI\b/vduvar_GRA_CUR_EXT+1/g;
	s/VDU_G_CUR_YX\b/vduvar_GRA_CUR_EXT+2/g;
	s/VDU_G_CUR_YX_HI\b/vduvar_GRA_CUR_EXT+3/g;

	s/\bVDU_T_CURS_X\b/vduvar_TXT_CUR_X/g;
	s/\bVDU_T_CURS_Y\b/vduvar_TXT_CUR_Y/g;
	s/\bVDU_G_CURS_SCAN\b/vduvar_GRA_CUR_CELL_LINE/g;
	s/\bVDU_QUEUE\b/vduvar_VDU_Q_START/g;
	s/\bVDU_QUEUE_1\b/vduvar_VDU_Q_START+1/g;
	s/\bVDU_QUEUE_2\b/vduvar_VDU_Q_START+2/g;
	s/\bVDU_QUEUE_3\b/vduvar_VDU_Q_START+3/g;
	s/\bVDU_QUEUE_4\b/vduvar_VDU_Q_START+4/g;
	s/\bVDU_QUEUE_5\b/vduvar_VDU_Q_START+5/g;
	s/\bVDU_QUEUE_6\b/vduvar_VDU_Q_START+6/g;
	s/\bVDU_QUEUE_7\b/vduvar_VDU_Q_START+7/g;
	s/\bVDU_QUEUE_8\b/vduvar_VDU_Q_START+8/g;
	s/\bVDU_G_CURS_H\b/vduvar_GRA_CUR_INT/g;
	s/\bVDU_G_CURS_H_HI\b/vduvar_GRA_CUR_INT+1/g;
	s/\bVDU_G_CURS_V\b/vduvar_GRA_CUR_INT+2/g;
	s/\bVDU_G_CURS_V_HI\b/vduvar_GRA_CUR_INT+3/g;
	s/\bVDU_BITMAP_READ\b/vduvar_TEMP_8/g;
	s/\bVDU_BITMAP_RD_1\b/vduvar_TEMP_8+1/g;
	s/\bVDU_BITMAP_RD_2\b/vduvar_TEMP_8+2/g;
	s/\bVDU_BITMAP_RD_3\b/vduvar_TEMP_8+3/g;
	s/\bVDU_BITMAP_RD_4\b/vduvar_TEMP_8+4/g;
	s/\bVDU_BITMAP_RD_5\b/vduvar_TEMP_8+5/g;
	s/\bVDU_BITMAP_RD_6\b/vduvar_TEMP_8+6/g;
	s/\bVDU_BITMAP_RD_7\b/vduvar_TEMP_8+7/g;

	s/\bVDU_WORKSPACE\b/vduvar_GRA_WKSP/g;

	s/\bVDU_CRTC_CUR\b/vduvar_6845_CURSOR_ADDR/g;
	s/\bVDU_CRTC_CUR_HI\b/vduvar_6845_CURSOR_ADDR+1/g;
	s/\bVDU_T_WIN_SZ\b/vduvar_TXT_WINDOW_WIDTH_BYTES/g;
	s/\bVDU_T_WIN_SZ_HI\b/vduvar_TXT_WINDOW_WIDTH_BYTES+1/g;
	s/\bVDU_PAGE\b/vduvar_SCREEN_BOTTOM_HIGH/g;
	s/\bVDU_BPC\b/vduvar_BYTES_PER_CHAR/g;

	s/\bVDU_MEM\b/vduvar_6845_SCREEN_START/g;
	s/\bVDU_MEM_HI\b/vduvar_6845_SCREEN_START+1/g;
	s/\bVDU_BPR\b/vduvar_BYTES_PER_ROW/g;
	s/\bVDU_BPR_HI\b/vduvar_BYTES_PER_ROW+1/g;
	s/\bVDU_MEM_PAGES\b/vduvar_SCREEN_SIZE_HIGH/g;
	s/\bVDU_MODE\b/vduvar_MODE/g;
	s/\bVDU_MAP_TYPE\b/vduvar_MODE_SIZE/g;
	s/\bVDU_T_FG\b/vduvar_TXT_FORE/g;
	s/\bVDU_T_BG\b/vduvar_TXT_BACK/g;
	s/\bVDU_G_FG\b/vduvar_GRA_FORE/g;
	s/\bVDU_G_BG\b/vduvar_GRA_BACK/g;
	s/\bVDU_P_FG\b/vduvar_GRA_PLOT_FORE/g;
	s/\bVDU_P_BG\b/vduvar_GRA_PLOT_BACK/g;
	s/\bVDU_JUMPVEC\b/vduvar_VDU_VEC_JMP/g;
	s/\bVDU_JUMPVEC_HI\b/vduvar_VDU_VEC_JMP+1/g;
	s/\bVDU_CURS_PREV\b/vduvar_CUR_START_PREV/g;

	s/\bVDU_COL_MASK\b/vduvar_COL_COUNT_MINUS1/g;
	s/\bVDU_PIX_BYTE\b/vduvar_PIXELS_PER_BYTE_MINUS1/g;
	s/\bVDU_MASK_RIGHT\b/vduvar_LEFTMOST_PIX_MASK/g;
	s/\bVDU_MASK_LEFT\b/vduvar_RIGHTMOST_PIX_MASK/g;
	s/\bVDU_TI_CURS_X\b/vduvar_TEXT_IN_CUR_X/g;
	s/\bVDU_TI_CURS_Y\b/vduvar_TEXT_IN_CUR_Y/g;
	s/\bVDU_TTX_CURSOR\b/vduvar_MO7_CUR_CHAR/g;
	s/\bVDU_FONT_FLAGS\b/vduvar_EXPLODE_FLAGS/g;
	s/\bVDU_FONTLOC_20\b/vduvar_FONT_LOC32_63/g;
	s/\bVDU_FONTLOC_40\b/vduvar_FONT_LOC64_95/g;
	s/\bVDU_FONTLOC_60\b/vduvar_FONT_LOC96_127/g;
	s/\bVDU_FONTLOC_80\b/vduvar_FONT_LOC128_159/g;
	s/\bVDU_FONTLOC_A0\b/vduvar_FONT_LOC160_191/g;
	s/\bVDU_FONTLOC_B0\b/vduvar_FONT_LOC192_223/g;
	s/\bVDU_FONTLOC_C0\b/vduvar_FONT_LOC224_255/g;
	s/\bVDU_PALETTE\b/vduvar_PALLETTE/g;

# Sysvars

	s/\bOSB_BASE\b/sysvar_OSVARADDR/g;
	s/\bOSB_EXT_VEC\b/sysvar_ROMPTRTAB/g;
	s/\bOSB_ROM_TABLE\b/sysvar_ROMINFOTAB/g;
	s/\bOSB_KEY_TABLE\b/sysvar_KEYB_ADDRTRANS/g;
	s/\bOSB_VDU_TABLE\b/sysvar_ADDRVDUVARS/g;

	s/\bOSB_CFS_TIMEOUT\b/sysvar_CFSTOCTR/g;
	s/\bOSB_IN_STREAM\b/sysvar_CURINSTREAM/g;
	s/\bOSB_KEY_SEM\b/sysvar_KEYB_SEMAPHORE/g;
	s/\bOSB_OSHWM_DEF\b/sysvar_PRI_OSHWM/g;
	s/\bOSB_OSHWM_CUR\b/sysvar_CUR_OSHWM/g;
	s/\bOSB_RS423_MODE\b/sysvar_RS423_MODE/g;
	s/\bOSB_CHAR_EXPL\b/sysvar_EXPLODESTATUS/g;
	s/\bOSB_CFSRFC_SW\b/sysvar_CFSRFS_SWITCH/g;
	s/\bOSB_VIDPROC_CTL\b/sysvar_VIDPROC_CTL_COPY/g;
	s/\bOSB_VIDPROC_PAL\b/sysvar_VIDPROC_PAL_COPY/g;
	s/\bOSB_LAST_ROM\b/sysvar_ROMNO_ATBREAK/g;
	s/\bOSB_BASIC_ROM\b/sysvar_ROMNO_BASIC/g;
	s/\bOSB_ADC_CHAN\b/sysvar_ADC_CUR/g;
	s/\bOSB_ADC_MAX\b/sysvar_ADC_MAX/g;
	s/\bOSB_ADC_ACC\b/sysvar_ADC_ACCURACY/g;
	s/\bOSB_RS423_USE\b/sysvar_RS423_USEFLAG/g;

	s/\bOSB_RS423_CTL\b/sysvar_RS423_CTL_COPY/g;
	s/\bOSB_FLASH_TIME\b/sysvar_FLASH_CTDOWN/g;
	s/\bOSB_FLASH_SPC\b/sysvar_FLASH_SPACE_PERIOD/g;
	s/\bOSB_FLASH_MARK\b/sysvar_FLASH_MARK_PERIOD/g;
	s/\bOSB_KEY_DELAY\b/sysvar_KEYB_AUTOREP_DELAY/g;
	s/\bOSB_KEY_REPEAT\b/sysvar_KEYB_AUTOREP_PERIOD/g;
	s/\bOSB_EXEC_HND\b/sysvar_EXEC_FILE/g;
	s/\bOSB_SPOOL_HND\b/sysvar_SPOOL_FILE/g;
	s/\bOSB_ESC_BRK\b/sysvar_BREAK_EFFECT/g;
	s/\bOSB_KEY_DISABLE\b/sysvar_KEYB_DISABLE/g;
	s/\bOSB_KEY_STATUS\b/sysvar_KEYB_STATUS/g;
	s/\bOSB_SER_BUF_EX\b/sysvar_RS423_BUF_EXT/g;
	s/\bOSB_SER_BUF_SUP\b/sysvar_RS423_SUPPRESS/g;
	s/\bOSB_SER_CAS_FLG\b/sysvar_RS423CASS_SELECT/g;
	s/\bOSB_ECONET_INT\b/sysvar_ECO_OSBW_INTERCEPT/g;
	s/\bOSB_OSRDCH_INT\b/sysvar_ECO_OSRDCH_INTERCEPT/g;

	s/\bOSB_OSWRCH_INT\b/sysvar_ECO_OSWRCH_INTERCEPT/g;
	s/\bOSB_SPEECH_OFF\b/sysvar_SPEECH_SUPPRESS/g;
	s/\bOSB_SOUND_OFF\b/sysvar_SOUND_SUPPRESS/g;
	s/\bOSB_BELL_CHAN\b/sysvar_BELL_CH/g;
	s/\bOSB_BELL_ENV\b/sysvar_BELL_ENV/g;
	s/\bOSB_BELL_FREQ\b/sysvar_BELL_FREQ/g;
	s/\bOSB_BELL_LEN\b/sysvar_BELL_DUR/g;
	s/\bOSB_BOOT_DISP\b/sysvar_STARTUP_DISPOPT/g;
	s/\bOSB_SOFT_KEYLEN\b/sysvar_KEYB_SOFTKEY_LENGTH/g;
	s/\bOSB_HALT_LINES\b/sysvar_SCREENLINES_SINCE_PAGE/g;
	s/\bOSB_VDU_QSIZE\b/sysvar_VDU_Q_LEN/g;
	s/\bOSB_TAB\b/sysvar_KEYB_TAB_CHAR/g;
	s/\bOSB_ESCAPE\b/sysvar_KEYB_ESC_CHAR/g;
	s/\bOSB_CHAR_C0\b/sysvar_KEYB_C0CF_INSERT_INT/g;
	s/\bOSB_CHAR_D0\b/sysvar_KEYB_D0DF_INSERT_INT/g;
	s/\bOSB_CHAR_E0\b/sysvar_KEYB_E0EF_INSERT_INT/g;

	s/\bOSB_CHAR_F0\b/sysvar_KEYB_F0FF_INSERT_INT/g;
	s/\bOSB_CHAR_80\b/sysvar_KEYB_808F_INSERT_INT/g;
	s/\bOSB_CHAR_90\b/sysvar_KEYB_909F_INSERT_INT/g;
	s/\bOSB_CHAR_a0\b/sysvar_KEYB_A0AF_INSERT_INT/g;
	s/\bOSB_CHAR_b0\b/sysvar_KEYB_B0BF_INSERT_INT/g;
	s/\bOSB_ESC_ACTION\b/sysvar_KEYB_ESC_ACTION/g;
	s/\bOSB_ESC_EFFECTS\b/sysvar_KEYB_ESC_EFFECT/g;
	s/\bOSB_UVIA_IRQ_M\b/sysvar_USERVIA_IRQ_MASK_CPY/g;
	s/\bOSB_ACIA_IRQ_M\b/sysvar_ACIA_IRQ_MASK_CPY/g;
	s/\bOSB_SVIA_IRQ_M\b/sysvar_SYSVIA_IRQ_MASK_CPY/g;
	s/\bOSB_TUBE_FOUND\b/sysvar_TUBE_PRESENT/g;
	s/\bOSB_SPCH_FOUND\b/sysvar_SPEECH_PRESENT/g;
	s/\bOSB_OUT_STREAM\b/sysvar_OUTSTREAM_DEST/g;
	s/\bOSB_CURSOR_STAT\b/sysvar_KEY_CURSORSTAT/g;
	s/\bOSB_KEYPAD_BASE\b/sysvar_FX238/g;
	s/\bOSB_SHADOW_RAM\b/sysvar_FX239/g;

	s/\bOSB_COUNTRY\b/sysvar_COUNTRY/g;
	s/\bOSB_USER_FLAG\b/sysvar_USERFLAG/g;
	s/\bOSB_SERPROC\b/sysvar_SERPROC_CTL_CPY/g;
	s/\bOSB_TIME_SWITCH\b/sysvar_TIMER_SWITCH/g;
	s/\bOSB_SOFTKEY_FLG\b/sysvar_KEYB_SOFT_CONSISTANCY/g;
	s/\bOSB_PRINT_DEST\b/sysvar_PRINT_DEST/g;
	s/\bOSB_PRINT_IGN\b/sysvar_PRINT_IGNORE/g;
	s/\bOSB_BRK_INT_JMP\b/sysvar_BREAK_VECTOR_JMP/g;
	s/\bOSB_BRK_INT_LO\b/sysvar_BREAK_VECTOR_LOW/g;
	s/\bOSB_BRK_INT_HI\b/sysvar_BREAK_VECTOR_HIGH/g;
	s/\bOSB_FA_UNUSED\b/sysvar_SHADOW1/g;
	s/\bOSB_FB_UNUSED\b/sysvar_SHADOW2/g;
	s/\bOSB_CUR_LANG\b/sysvar_CUR_LANG/g;
	s/\bOSB_LAST_BREAK\b/sysvar_BREAK_LAST_TYPE/g;
	s/\bOSB_RAM_PAGES\b/sysvar_RAM_AVAIL/g;
	s/\bOSB_STARTUP_OPT\b/sysvar_STARTUP_OPT/g;

	s/\bVDU_ADJUST\b/oswksp_VDU_VERTADJ/g;
	s/\bVDU_INTERLACE\b/oswksp_VDU_INTERLACE/g;

	s/\bBUFFER_0_BUSY\b/mosbuf_buf_busy/g;
	s/\bBUFFER_1_BUSY\b/mosbuf_buf_busy+1/g;
	s/\bBUFFER_2_BUSY\b/mosbuf_buf_busy+2/g;
	s/\bBUFFER_3_BUSY\b/mosbuf_buf_busy+3/g;
	s/\bBUFFER_4_BUSY\b/mosbuf_buf_busy+4/g;
	s/\bBUFFER_5_BUSY\b/mosbuf_buf_busy+5/g;
	s/\bBUFFER_6_BUSY\b/mosbuf_buf_busy+6/g;
	s/\bBUFFER_7_BUSY\b/mosbuf_buf_busy+7/g;
	s/\bBUFFER_8_BUSY\b/mosbuf_buf_busy+8/g;

	s/\bBUFFER_0_OUT\b/mosbuf_buf_start/g;
	s/\bBUFFER_1_OUT\b/mosbuf_buf_start+1/g;
	s/\bBUFFER_2_OUT\b/mosbuf_buf_start+2/g;
	s/\bBUFFER_3_OUT\b/mosbuf_buf_start+3/g;
	s/\bBUFFER_4_OUT\b/mosbuf_buf_start+4/g;
	s/\bBUFFER_5_OUT\b/mosbuf_buf_start+5/g;
	s/\bBUFFER_6_OUT\b/mosbuf_buf_start+6/g;
	s/\bBUFFER_7_OUT\b/mosbuf_buf_start+7/g;
	s/\bBUFFER_8_OUT\b/mosbuf_buf_start+8/g;

	s/\bBUFFER_0_IN\b/mosbuf_buf_end/g;
	s/\bBUFFER_1_IN\b/mosbuf_buf_end+1/g;
	s/\bBUFFER_2_IN\b/mosbuf_buf_end+2/g;
	s/\bBUFFER_3_IN\b/mosbuf_buf_end+3/g;
	s/\bBUFFER_4_IN\b/mosbuf_buf_end+4/g;
	s/\bBUFFER_5_IN\b/mosbuf_buf_end+5/g;
	s/\bBUFFER_6_IN\b/mosbuf_buf_end+6/g;
	s/\bBUFFER_7_IN\b/mosbuf_buf_end+7/g;
	s/\bBUFFER_8_IN\b/mosbuf_buf_end+8/g;


# Hardware
	s/\bCRTC_ADDRESS\b/sheila_CRTC_reg/g;
	s/\bCRTC_DATA\b/sheila_CRTC_rw/g;

	print $_;

}