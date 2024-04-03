.ifndef __VDUVARS_INC__
__VDUVARS_INC__:

vduvars_start				:= $0300
vduvar_GRA_WINDOW			:= $0300				
vduvar_GRA_WINDOW_LEFT			:= $0300	; Current graphics window left column in pixels
vduvar_GRA_WINDOW_BOTTOM		:= $0302	; Current graphics window bottom row in pixels
vduvar_GRA_WINDOW_RIGHT			:= $0304	; Current graphics window right column in pixels
vduvar_GRA_WINDOW_TOP			:= $0306	; Current graphics window top row in pixels
vduvar_TXT_WINDOW_LEFT			:= $0308	; Current text window left hand column
vduvar_TXT_WINDOW_BOTTOM		:= $0309	; Current text window bottom row
vduvar_TXT_WINDOW_RIGHT			:= $030A	; Current text window right hand column
vduvar_TXT_WINDOW_TOP			:= $030B	; Current text window top column
vduvar_GRA_ORG_EXT			:= $030C	; Current graphics origin in external coordinates
vduvar_GRA_CUR_EXT			:= $0310	; Current graphics cursor in external coordinates
vduvar_GRA_CUR_INT_OLD			:= $0314	; Old graphics cursor in external coordinates
vduvar_TXT_CUR_X			:= $0318	; Current text cursor X
vduvar_TXT_CUR_Y			:= $0319	; Current text cursor Y
vduvar_GRA_CUR_CELL_LINE		:= $031A	; Line within current graphics cell of graphics cursor
vduvar_VDU_Q_START			:= $031B
vduvar_VDU_Q_END			:= $0324	; end of VDU Q (well 1 after!)
vduvar_GRA_CUR_INT			:= $0324	; Current graphics cursor in internal coordinates
vduvar_TEMP_8				:= $0328	; Bitmap read from screen by OSBYTE 135, various coordinate routines
vduvar_GRA_WKSP				:= $0330	; Graphics workspace
vduvar_6845_CURSOR_ADDR			:= $034A	; Text cursor address for 6845
vduvar_TXT_WINDOW_WIDTH_BYTES		:= $034C	; Text window width in bytes
vduvar_SCREEN_BOTTOM_HIGH		:= $034E	; High byte of bottom of screen memory
vduvar_BYTES_PER_CHAR			:= $034F	; Bytes per character for current mode
vduvar_6845_SCREEN_START		:= $0350	; Screen display start address for 6845
vduvar_BYTES_PER_ROW			:= $0352	; Bytes per screen row
vduvar_SCREEN_SIZE_HIGH			:= $0354	; Screen memory size high byte
vduvar_MODE				:= $0355	; Current screen mode
vduvar_MODE_SIZE			:= $0356	; Memory map type: 0 - 20K, 1 - 16K, 2 - 10K, 3 - 8K, 4 - 1K
vduvar_TXT_FORE				:= $0357	; Foreground text colour
vduvar_TXT_BACK				:= $0358	; Background text colour
vduvar_GRA_FORE				:= $0359	; Foreground graphics colour
vduvar_GRA_BACK				:= $035A	; Background graphics colour
vduvar_GRA_PLOT_FORE			:= $035B	; Foreground plot mode
vduvar_GRA_PLOT_BACK			:= $035C	; Background plot mode
vduvar_VDU_VEC_JMP			:= $035D	; General VDU jump vector
vduvar_CUR_START_PREV			:= $035F	; Cursor start register previous setting
vduvar_COL_COUNT_MINUS1			:= $0360	; Number logical colours -1
vduvar_PIXELS_PER_BYTE_MINUS1		:= $0361	; Pixels per byte -1 (zero if text only mode)
vduvar_LEFTMOST_PIX_MASK		:= $0362	; Leftmost pixel colour mask
vduvar_RIGHTMOST_PIX_MASK		:= $0363	; Rightmost pixel colour mask
vduvar_TEXT_IN_CUR_X			:= $0364	; Text input cursor X
vduvar_TEXT_IN_CUR_Y			:= $0365	; Text input cursor Y
vduvar_MO7_CUR_CHAR			:= $0366	; Teletext output cursor character
vduvar_EXPLODE_FLAGS			:= $0367	; Font explosion flags, b1=224-255 in RAM, b7=32-63 in RAM
vduvar_FONT_LOC32_63			:= $0368	; Font location, characters 32-63
vduvar_FONT_LOC64_95			:= $0369	; Font location, characters 64-95 
vduvar_FONT_LOC96_127			:= $036A	; Font location, characters 96-127
vduvar_FONT_LOC128_159			:= $036B	; Font location, characters 128-159
vduvar_FONT_LOC160_191			:= $036C	; Font location, characters 160-191
vduvar_FONT_LOC192_223			:= $036D	; Font location, characters 192-223
vduvar_FONT_LOC224_255			:= $036E	; Font location, characters 224-255
vduvar_PALLETTE				:= $036F	; Palette for colours 0 to 15


.endif