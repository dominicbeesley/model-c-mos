.ifndef __SYSVARS_INC__
__SYSVARS_INC__:

sysvar_OSVARADDR			:= $0236	; fx166/7 &A6/7 Address of OS variables
sysvar_ROMPTRTAB			:= $0238	; fx168/9 &A8/9 Address of ROM pointer table
sysvar_ROMINFOTAB			:= $023A	; fx170/1 &AA/B Address of ROM info table
sysvar_KEYB_ADDRTRANS			:= $023C	; fx172/3 &AC/D Address of key translation table
sysvar_ADDRVDUVARS			:= $023E	; fx174/5 &AE/F Address of VDU variables
sysvar_CFSTOCTR				:= $0240	; fx176	  &B0	CFS timeout counter, decremented every frame flyback
sysvar_CURINSTREAM			:= $0241	; fx177	  &B1	Currently selected input stream set with FX2
sysvar_KEYB_SEMAPHORE			:= $0242	; fx178	  &B2	BBC, Master: Keyboard semaphore
sysvar_PRI_OSHWM			:= $0243	; fx179	  &B3	Primary OSHWM
sysvar_CUR_OSHWM			:= $0244	; fx180	  &B4	Current OSHWM
sysvar_RS423_MODE			:= $0245	; fx181	  &B5	RS423 mode
sysvar_EXPLODESTATUS			:= $0246	; fx182	  &B6	BBC, Electron: Character definition explosion status
sysvar_CFSRFS_SWITCH			:= $0247	; fx183	  &B7	CFS/RFS switch
sysvar_VIDPROC_CTL_COPY			:= $0248	; fx184	  &B8	BBC, Master: RAM copy of VIDPROC control register
sysvar_VIDPROC_PAL_COPY			:= $0249	; fx185	  &B9	BBC, Master: RAM copy of VIDPROC palette register
sysvar_ROMNO_ATBREAK			:= $024A	; fx186	  &BA	ROM active last BRK
sysvar_ROMNO_BASIC			:= $024B	; fx187	  &BB	BASIC ROM number
sysvar_ADC_CUR				:= $024C	; fx188	  &BC	Current ADC Channel
sysvar_ADC_MAX				:= $024D	; fx189	  &BD	Maximum ADC Channel number
sysvar_ADC_ACCURACY			:= $024E	; fx190	  &BE	ADC conversion type/accuracy
sysvar_RS423_USEFLAG			:= $024F	; fx191	  &BF	RS423 use flag
sysvar_RS423_CTL_COPY			:= $0250	; fx192	  &C0	RAM copy of RS423 control register
sysvar_FLASH_CTDOWN			:= $0251	; fx193	  &C1	Flashing colour countdown timer
sysvar_FLASH_SPACE_PERIOD		:= $0252	; fx194	  &C2	Flashing colour space period count set by FX9
sysvar_FLASH_MARK_PERIOD		:= $0253	; fx195	  &C3	Flashing colour mark period count set by FX10
sysvar_KEYB_AUTOREP_DELAY		:= $0254	; fx196	  &C4	Keyboard auto-repeat delay set by FX11
sysvar_KEYB_AUTOREP_PERIOD		:= $0255	; fx197	  &C5	Keyboard auto-repeat period set by FX12
sysvar_EXEC_FILE			:= $0256	; fx198	  &C6	*EXEC file
sysvar_SPOOL_FILE			:= $0257	; fx199	  &C7	*SPOOL file handle
sysvar_BREAK_EFFECT			:= $0258	; fx200	  &C8	ESCAPE, BREAK effect
sysvar_KEYB_DISABLE			:= $0259	; fx201	  &C9	Keyboard disable
sysvar_KEYB_STATUS			:= $025A	; fx202	  &CA	Keyboard status byte
							;Bit 7  =1 shift enabled   
							;Bit 6  =1 control pressed 
							;bit 5  =0 shift lock      
							;Bit 4  =0 Caps lock       
							;Bit 3  =1 shift pressed   

sysvar_RS423_BUF_EXT			:= $025B	; fx203	  &CB	BBC, Master: Serial input buffer extent
sysvar_RS423_SUPPRESS			:= $025C	; fx204	  &CC	BBC, Master: Serial input supression flag
sysvar_RS423CASS_SELECT			:= $025D	; fx205	  &CD	BBC, Master: Serial/cassette selection flag
sysvar_ECO_OSBW_INTERCEPT		:= $025E	; fx206	  &CE	Econet OSBYTE/OSWORD intercept flag
sysvar_ECO_OSRDCH_INTERCEPT		:= $025F	; fx207	  &CF	Econet OSRDCH intercept flag
sysvar_ECO_OSWRCH_INTERCEPT		:= $0260	; fx208	  &D0	Econet OSWRCH intercept flag
sysvar_SPEECH_SUPPRESS			:= $0261	; fx209	  &D1	Speech suppression status
sysvar_SOUND_SUPPRESS			:= $0262	; fx210	  &D2	Sound suppression status
sysvar_BELL_CH				:= $0263	; fx211	  &D3	BELL channel number
sysvar_BELL_ENV				:= $0264	; fx212	  &D4	BELL envelope number/amplitude
sysvar_BELL_FREQ			:= $0265	; fx213	  &D5	BELL frequency
sysvar_BELL_DUR				:= $0266	; fx214	  &D6	BELL duration
sysvar_STARTUP_DISPOPT			:= $0267	; fx215	  &D7	Startup display and BOOT error options
sysvar_KEYB_SOFTKEY_LENGTH		:= $0268	; fx216	  &D8	Soft key string length
sysvar_SCREENLINES_SINCE_PAGE		:= $0269	; fx217	  &D9	Screen lines since last page
sysvar_VDU_Q_LEN			:= $026A	; fx218	  &DA	256-number of items in VDU queue
sysvar_KEYB_TAB_CHAR			:= $026B	; fx219	  &DB	BBC, Master: TAB key character
sysvar_KEYB_ESC_CHAR			:= $026C	; fx220	  &DC	ESCAPE character
sysvar_KEYB_C0CF_INSERT_INT		:= $026D	; fx221	  &DD	Char &C0-&CF buffer insert interpretation
sysvar_KEYB_D0DF_INSERT_INT		:= $026E	; fx222	  &DE	Char &D0-&DF buffer insert interpretation
sysvar_KEYB_E0EF_INSERT_INT		:= $026F	; fx223	  &DF	Char &E0-&EF buffer insert interpretation
sysvar_KEYB_F0FF_INSERT_INT		:= $0270	; fx224	  &E0	Char &F0-&FF buffer insert interpretation
sysvar_KEYB_808F_INSERT_INT		:= $0271	; fx225	  &E1	Char &80-&8F buffer insert interpretation (FKey)
sysvar_KEYB_909F_INSERT_INT		:= $0272	; fx226	  &E2	Char &90-&9F buffer insert interpretation (Sh+FKey)
sysvar_KEYB_A0AF_INSERT_INT		:= $0273	; fx227	  &E3	Char &A0-&AF buffer insert interpretation (Ct+FKey)
sysvar_KEYB_B0BF_INSERT_INT		:= $0274	; fx228	  &E4	Char &B0-&BF buffer insert interpretation (Ct+Sh+FKey)
sysvar_KEYB_ESC_ACTION			:= $0275	; fx229	  &E5	ESCAPE key action
sysvar_KEYB_ESC_EFFECT			:= $0276	; fx230	  &E6	ESCAPE effects
sysvar_USERVIA_IRQ_MASK_CPY		:= $0277	; fx231	  &E7	User 6522 VIA IRQ mask
sysvar_ACIA_IRQ_MASK_CPY		:= $0278	; fx232	  &E8	6850 ACIA IRQ bit mask
sysvar_SYSVIA_IRQ_MASK_CPY		:= $0279	; fx233	  &E9	System 6522 VIA IRQ mask
sysvar_TUBE_PRESENT			:= $027A	; fx234	  &EA	Tube presence flag
sysvar_SPEECH_PRESENT			:= $027B	; fx235	  &EB	Speech processor presence flag
sysvar_OUTSTREAM_DEST			:= $027C	; fx236	  &EC	Output stream character destination, set with FX3
sysvar_KEY_CURSORSTAT			:= $027D	; fx237	  &ED	Cursor key status, set with FX4
sysvar_FX238				:= $027E	; fx238	  &EE	BBC, Electron: unused
sysvar_FX239				:= $027F	; fx239	  &EF	unused
sysvar_COUNTRY				:= $0280	; fx240	  &F0	Country code
sysvar_USERFLAG				:= $0281	; fx241	  &F1	User flag location, set with FX1
sysvar_SERPROC_CTL_CPY			:= $0282	; fx242	  &F2	BBC, Master: RAM copy of SERPROC control register
sysvar_TIMER_SWITCH			:= $0283	; fx243	  &F3	Timer switch state
sysvar_KEYB_SOFT_CONSISTANCY		:= $0284	; fx244	  &F4	Soft key consistancy flag
sysvar_PRINT_DEST			:= $0285	; fx245	  &F5	Printer destination, set with FX5
sysvar_PRINT_IGNORE			:= $0286	; fx246	  &F6	Printer ignore character, set with FX6
sysvar_BREAK_VECTOR_JMP			:= $0287	; fx247	  &F7	Break Intercept Vector JMP
sysvar_BREAK_VECTOR_LOW			:= $0288	; fx248	  &F8	Break Intercept Vector address low byte
sysvar_BREAK_VECTOR_HIGH		:= $0289	; fx249	  &F9	Break Intercept Vector address high byte
sysvar_SHADOW1				:= $028A	; fx250	  &FA	BBC, Electron: unused, unless shadow screen present
sysvar_SHADOW2				:= $028B	; fx251	  &FB	BBC, Electron: unused, unless shadow screen present
sysvar_CUR_LANG				:= $028C	; fx252	  &FC	Current language ROM
sysvar_BREAK_LAST_TYPE			:= $028D	; fx253	  &FD	Last BREAK type
sysvar_RAM_AVAIL			:= $028E	; fx254	  &FE	BBC: Available RAM
sysvar_STARTUP_OPT			:= $028F	; fx255	  &FF	Startup options
oswksp_VDU_VERTADJ			:= $0290	; VDU vertical adjust, *TV first parameter
oswksp_VDU_INTERLACE			:= $0291	; Interlace toggle flag, *TV second parameter
oswksp_TIME				:= $0292	; TIME value 1, high byte...low byte
oswksp_TIME2				:= $0297	; TIME value 2, high byte...low byte
oswksp_OSWORD3_CTDOWN			:= $029C	; OSWORD 3/4 Countdown interval timer value
oswksp_ROMTYPE_TAB			:= $02A1	; Paged ROM type table
oswksp_INKEY_CTDOWN			:= $02B1	; INKEY countdown timer
oswksp_OSWORD0_LINE_LEN			:= $02B3	; OSWORD 0 maximum line length
oswksp_OSWORD0_MIN_CH			:= $02B4	; OSWORD 0 minimum character
oswksp_OSWORD0_MAX_CH			:= $02B5	; OSWORD 0 maximum character
adc_CH1_LOW				:= $02B6	; Channel 1 ADC value low
adc_CH2_LOW				:= $02B7	; Channel 2 ADC value low
adc_CH3_LOW				:= $02B8	; Channel 3 ADC value low
adc_CH4_LOW				:= $02B9	; Channel 4 ADC value low
adc_CH1_HI				:= $02BA	; Channel 1 ADC value high
adc_CH2_HI				:= $02BB	; Channel 2 ADC value high
adc_CH3_HI				:= $02BC	; Channel 3 ADC value high
adc_CH4_HI				:= $02BD	; Channel 4 ADC value high
adc_CH_LAST				:= $02BE	; Last ADC channel converted
mosvar_EVENT_ENABLE			:= $02BF	; MOS Event enable flags
mosvar_SOFTKEY_PTR			:= $02C9	; Soft key expansion pointer
mosvar_KEYB_AUTOREPEAT_COUNT		:= $02CA	; First auto repeat count
mosvar_KEYB_TWOKEY_ROLLOVER		:= $02CB	; Two key rollover workspace
mosvar_SOUND_SEMAPHORE			:= $02CE	; Sound semaphore

MOSBUF_COUNT				:= 9		; number of buffers defined just here - more may be added to model c mos later but will live elsewhere
mosbuf_buf_busy				:= $02CF	; Buffer busy flags	      
mosbuf_buf_start			:= $02D8	; Buffer start indexes	      
mosbuf_buf_end				:= $02E1	; Buffer end indexes	      

cfsrfs_BLK_SIZE				:= $02EA	; Block size
cfsrfs_BLK_FLAG				:= $02EC	; Block flag
cfsrfs_LAST_CHA				:= $02ED	; Last input character
osfile_ctlblk				:= $02EE	; OSFILE control blocks for *LOAD, *SAVE, *CREATE and *DELETE.


; ********************************************************
; *           B U F F E R   A D D R E S S E S            *
; ********************************************************

BUFFER_KEYB_START			:= $03E0
BUFFER_KEYB_SIZE			:= $0020

BUFFER_SERI_START			:= $0A00
BUFFER_SERI_SIZE			:= $0100

BUFFER_SERO_START			:= $0900
BUFFER_SERO_SIZE			:= $00C0

BUFFER_LPT_START			:= $0880
BUFFER_LPT_SIZE				:= $0040

BUFFER_SND0_START			:= $0840
BUFFER_SND0_SIZE			:= $0010

BUFFER_SND1_START			:= $0850
BUFFER_SND1_SIZE			:= $0010

BUFFER_SND2_START			:= $0860
BUFFER_SND2_SIZE			:= $0010

BUFFER_SND3_START			:= $0870
BUFFER_SND3_SIZE			:= $0010

BUFFER_SPCH_START			:= $09C0
BUFFER_SPCH_SIZE			:= $0040

swrom_wksp_tab				:= $0DF0


.endif