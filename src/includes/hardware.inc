	.IFNDEF __HARDWARE_INC__
__HARDWARE_INC__:


sheila_MEM_CTL			:= $FFFE31
BITS_MEM_CTL_SWMOS		:= $01
BITS_MEM_CTL_SWMOS_DEBUG	:= $04
BITS_MEM_CTL_SWMOS_DEBUG_EN	:= $08
BITS_MEM_CTL_FLEX		:= $10
BITS_MEM_CTL_SWMOS_DEBUG_5C	:= $40
BITS_MEM_CTL_SWMOS_DEBUG_ACT	:= $80
sheila_MEM_DEBUG_SAVE		:= $FFFE32

sheila_MEM_TURBO2		:= $FFFE36
BITS_MEM_TURBO2_THROTTLE	:= $80

sheila_MEM_LOMEMTURBO		:= $FFFE37
sheila_ROM_THROTTLE_0		:= $FFFE33
sheila_ROM_THROTTLE_1		:= $FFFE35

sheila_ACIA_CTL			:= $FFFE08
ACIA_RDRF			:= $01
ACIA_TDRE			:= $02

sheila_ACIA_DATA		:= $FFFE09
sheila_SERIAL_ULA		:= $FFFE10


; BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
; the exec flags are first set
; then with top bit set the active flag, bit mode and cell flags are set
; BLTCON/ACT byte flags

BLITCON_ACT_ACT			:=	$80		; always set when setting act constants/execing  
BLITCON_ACT_CELL		:=	$40		; cell addressing used i.e. move one byte left adds 8 to address
							; moving one line down either adds 1 byte or STRIDE depending on whether 
							; line crosses an 8 line boundary
BLITCON_ACT_MODE_1BBP		:=	$00		; 1 bit per pixel mapping 2 colours
BLITCON_ACT_MODE_2BBP		:=	$10		; 2 bit per pixel mapping 4 colours
BLITCON_ACT_MODE_4BBP		:=	$20		; 4 bit per pixel mapping 16 colours
BLITCON_ACT_MODE_8BBP		:=	$30		; 8 bit per pixel mapping 256 colours
BLITCON_ACT_LINE		:=	$08		; draw a line
BLITCON_ACT_COLLISION		:=	$04		; gets reset for any non-zero D data (even in EXEC_D is clear)
BLITCON_ACT_WRAP		:=	$02		; wrap C/D addresses to fit between min/max

BLITCON_LINE_MAJOR_UPnRIGHT	:=	$10		; line draw major axis is up
BLITCON_LINE_MINOR_CCW		:=	$20		; minor axis is CCW to MAJOR i.e.:
							;  - left when maj up, up when maj right
							;  - otherwise, right when maj up, down when maj right

BLITCON_EXEC_A			:=	$01
BLITCON_EXEC_B			:=	$02
BLITCON_EXEC_C			:=	$04
BLITCON_EXEC_D			:=	$08
BLITCON_EXEC_E			:=	$10

AERIS_CTL_ACT			:=	$80

; DMA controller control flags
DMACTL_ACT			:=	$80		; always set to initiate a transfer

DMACTL_EXTEND			:=	$20		; use extended functions from control2
DMACTL_HALT			:=	$10		; halt cpu during transfer
DMACTL_STEP_DEST_NONE		:=	$00		; do not step destination address
DMACTL_STEP_DEST_UP		:=	$04		; step destination up after transfer
DMACTL_STEP_DEST_DOWN		:=	$08		; step destination down after transfer
DMACTL_STEP_DEST_NOP		:=	$0C		; skip writes, do not increment address
DMACTL_STEP_SRC_NONE		:=	$00		; do not step destination address
DMACTL_STEP_SRC_UP		:=	$01		; step destination up after transfer
DMACTL_STEP_SRC_DOWN		:=	$02		; step destination down after transfer
DMACTL_STEP_SRC_NOP		:=	$03		; skip reads, do not incrememnt address

DMACTL2_IF			:=	$80		; interrupt occurred
DMACTL2_IE			:=	$02		; interrupt enable, interrupt after transfer
DMACTL2_SZ_BYTE			:=	$00
DMACTL2_SZ_WORD			:=	$04
DMACTL2_SZ_WORDSWAPDEST		:=	$08
DMACTL2_SZ_WORDSWAPSRC		:=	$0C
DMACTL2_PAUSE			:=	$01

; Sound Status / control bits
SND_CTL_ACT			:=	$80
SND_CTL_REPEAT			:=	$01


DMAC_BLITCON_offs		:=	0
DMAC_FUNCGEN_offs		:=	$1
DMAC_WIDTH_offs			:=	$2
DMAC_HEIGHT_offs		:=	$3
DMAC_SHIFT_offs			:=	$4
DMAC_MASK_FIRST_offs		:=	$5
DMAC_MASK_LAST_offs		:=	$6
DMAC_DATA_A_offs		:=	$7
DMAC_ADDR_A_offs		:=	$8
DMAC_DATA_B_offs		:=	$B
DMAC_ADDR_B_offs		:=	$C
DMAC_ADDR_C_offs		:=	$F
DMAC_ADDR_D_offs		:=	$12
DMAC_ADDR_E_offs		:=	$15
DMAC_STRIDE_A_offs		:=	$18
DMAC_STRIDE_B_offs		:=	$1A
DMAC_STRIDE_C_offs		:=	$1C
DMAC_STRIDE_D_offs		:=	$1E

DMAC_BLIT_EXT_offs		:=	$40
DMAC_ADDR_D_MIN_offs		:=	DMAC_BLIT_EXT_offs
DMAC_ADDR_D_MAX_offs		:=	DMAC_BLIT_EXT_offs+3



DMAC_SND_DATA_offs		:=	$20
DMAC_SND_ADDR_offs		:=	$21
DMAC_SND_PERIOD_offs		:=	$24
DMAC_SND_LEN_offs		:=	$26
DMAC_SND_STATUS_offs		:=	$28
DMAC_SND_VOL_offs		:=	$29
DMAC_SND_REPOFF_offs		:=	$2A
DMAC_SND_PEAK_offs		:=	$2C

DMAC_SND_MA_VOL_offs		:=	$2E
DMAC_SND_SEL_offs		:=	$2F

DMAC_DMA_CTL_offs		:=	$30
DMAC_DMA_SRC_ADDR_offs		:=	$31
DMAC_DMA_DEST_ADDR_offs		:=	$34
DMAC_DMA_COUNT_offs		:=	$37
DMAC_DMA_DATA_offs		:=	$39
DMAC_DMA_CTL2_offs		:=	$3A
DMAC_DMA_PAUSE_VAL_offs		:=	$3B
DMAC_DMA_SEL_offs		:=	$3F



DMAC_AERIS_CTL_offs		:=	$50
DMAC_AERIS_PROGBASE_offs	:=	$51


DMAC_I2C_offs			:=	$70

jim_page_DMAC			:=	$FEFC

jim_page_VERSION		:=	$FC00

jim_offs_VERSION_API_level	:=	$80
jim_offs_VERSION_Board_level	:=	$81
jim_offs_VERSION_API_sublevel	:=	$82
jim_offs_VERSION_cfg_bits	:=	$84
jim_offs_VERSION_cap_bits	:=	$88

; Mk.2/1 option switches - note in API level >1 the sense of these is reversed!
BLT_MK2_CFG0_T65		:=	$01
BLT_MK2_CFG0_CPU_6502A_2M	:=	$00
BLT_MK2_CFG0_CPU_65C02_4M	:=	$02
BLT_MK2_CFG0_CPU_65C02_8M	:=	$04
BLT_MK2_CFG0_CPU_6x09_2M	:=	$08
BLT_MK2_CFG0_CPU_6309_4M	:=	$0A
BLT_MK2_CFG0_CPU_Z80_8M		:=	$0C
BLT_MK2_CFG0_CPU_68008		:=	$0E
BLT_MK2_CFG0_SWROMX		:=	$10
BLT_MK2_CFG0_BUGBTN		:=	$80

BLT_MK2_CFG1_MEMI		:=	$01
BLT_MK2_CFG1_BUGOUT		:=	$02

; Mk.3 switches from PORTF/G
BLT_MK3_CFG0_T65		:=	$08
BLT_MK3_CFG0_SWROMX		:=	$10
BLT_MK3_CFG0_MEMI		:=	$40



jim_DMAC			:=	$FD60
jim_DMAC_BLITCON		:=	jim_DMAC + DMAC_BLITCON_offs
jim_DMAC_FUNCGEN		:=	jim_DMAC + DMAC_FUNCGEN_offs
jim_DMAC_WIDTH			:=	jim_DMAC + DMAC_WIDTH_offs
jim_DMAC_HEIGHT			:=	jim_DMAC + DMAC_HEIGHT_offs
jim_DMAC_SHIFT			:=	jim_DMAC + DMAC_SHIFT_offs
jim_DMAC_MASK_FIRST		:=	jim_DMAC + DMAC_MASK_FIRST_offs
jim_DMAC_MASK_LAST		:=	jim_DMAC + DMAC_MASK_LAST_offs
jim_DMAC_DATA_A			:=	jim_DMAC + DMAC_DATA_A_offs
jim_DMAC_ADDR_A			:=	jim_DMAC + DMAC_ADDR_A_offs
jim_DMAC_DATA_B			:=	jim_DMAC + DMAC_DATA_B_offs
jim_DMAC_ADDR_B			:=	jim_DMAC + DMAC_ADDR_B_offs
jim_DMAC_ADDR_C			:=	jim_DMAC + DMAC_ADDR_C_offs
jim_DMAC_ADDR_D			:=	jim_DMAC + DMAC_ADDR_D_offs
jim_DMAC_ADDR_E			:=	jim_DMAC + DMAC_ADDR_E_offs
jim_DMAC_STRIDE_A		:=	jim_DMAC + DMAC_STRIDE_A_offs
jim_DMAC_STRIDE_B		:=	jim_DMAC + DMAC_STRIDE_B_offs
jim_DMAC_STRIDE_C		:=	jim_DMAC + DMAC_STRIDE_C_offs
jim_DMAC_STRIDE_D		:=	jim_DMAC + DMAC_STRIDE_D_offs
jim_DMAC_ADDR_D_MIN		:=	jim_DMAC + DMAC_ADDR_D_MIN_offs
jim_DMAC_ADDR_D_MAX		:=	jim_DMAC + DMAC_ADDR_D_MAX_offs




jim_DMAC_SND_DATA		:= 	jim_DMAC + DMAC_SND_DATA_offs
jim_DMAC_SND_ADDR		:= 	jim_DMAC + DMAC_SND_ADDR_offs
jim_DMAC_SND_PERIOD		:= 	jim_DMAC + DMAC_SND_PERIOD_offs
jim_DMAC_SND_LEN		:= 	jim_DMAC + DMAC_SND_LEN_offs
jim_DMAC_SND_STATUS		:= 	jim_DMAC + DMAC_SND_STATUS_offs
jim_DMAC_SND_VOL		:= 	jim_DMAC + DMAC_SND_VOL_offs
jim_DMAC_SND_REPOFF		:= 	jim_DMAC + DMAC_SND_REPOFF_offs
jim_DMAC_SND_PEAK		:= 	jim_DMAC + DMAC_SND_PEAK_offs

jim_DMAC_SND_SEL		:= 	jim_DMAC + DMAC_SND_SEL_offs
jim_DMAC_SND_MA_VOL		:= 	jim_DMAC + DMAC_SND_MA_VOL_offs

jim_DMAC_DMA_CTL		:=	jim_DMAC + DMAC_DMA_CTL_offs
jim_DMAC_DMA_SRC_ADDR		:=	jim_DMAC + DMAC_DMA_SRC_ADDR_offs
jim_DMAC_DMA_DEST_ADDR		:=	jim_DMAC + DMAC_DMA_DEST_ADDR_offs
jim_DMAC_DMA_COUNT		:=	jim_DMAC + DMAC_DMA_COUNT_offs
jim_DMAC_DMA_DATA		:=	jim_DMAC + DMAC_DMA_DATA_offs
jim_DMAC_DMA_CTL2		:=	jim_DMAC + DMAC_DMA_CTL2_offs
jim_DMAC_DMA_PAUSE_VAL		:=	jim_DMAC + DMAC_DMA_PAUSE_VAL_offs
jim_DMAC_DMA_SEL		:=	jim_DMAC + DMAC_DMA_SEL_offs

jim_DMAC_AERIS_CTL		:=	jim_DMAC + DMAC_AERIS_CTL_offs
jim_DMAC_AERIS_PROGBASE		:=	jim_DMAC + DMAC_AERIS_PROGBASE_offs


jim_I2C_BASE			:= 	jim_DMAC + DMAC_I2C_offs
jim_I2C_STAT			:= 	jim_I2C_BASE
jim_I2C_DATA			:= 	jim_I2C_BASE + 1

I2C_BUSY	:= $80
I2C_NACK	:= $40
I2C_STOP	:= $04
I2C_START	:= $02
I2C_RNW		:= $01


fred_JIM_PAGE_HI2		:=	$FFFCFC		; note ignored Blitter/Paula
fred_JIM_PAGE_HI		:=	$FFFCFD
fred_JIM_PAGE_LO		:=	$FFFCFE
fred_JIM_DEVNO			:=	$FFFCFF

jim_base			:=	$FFFD00
JIM				:=	jim_base

sheila_ROMCTL_SWR	:=	$FFFE30
sheila_ROMCTL_MOS	:=	$FFFE31

ROMCTL_BITS_FLEX	:=	$10
ROMCTL_MOS_JIMEN	:=	$02
ROMCTL_MOS_SWMOS	:=	$01

	
sheila_NULA_CTLAUX	:=	$FFFE22
sheila_NULA_PALAUX	:=	$FFFE23


;***********************************************************************
;* System VIA                                                          *
;***********************************************************************
sheila_SYSVIA_orb			:= $FFFE40
sheila_SYSVIA_ora			:= $FFFE41
sheila_SYSVIA_ddrb			:= $FFFE42
sheila_SYSVIA_ddra			:= $FFFE43
sheila_SYSVIA_t1cl			:= $FFFE44
sheila_SYSVIA_t1ch			:= $FFFE45
sheila_SYSVIA_t1ll			:= $FFFE46
sheila_SYSVIA_t1lh			:= $FFFE47
sheila_SYSVIA_t2cl			:= $FFFE48
sheila_SYSVIA_t2ch			:= $FFFE49
sheila_SYSVIA_sr			:= $FFFE4A
sheila_SYSVIA_acr			:= $FFFE4B
sheila_SYSVIA_pcr			:= $FFFE4C
sheila_SYSVIA_ifr			:= $FFFE4D
sheila_SYSVIA_ier			:= $FFFE4E
sheila_SYSVIA_ora_nh			:= $FFFE4F

;***********************************************************************
;* SYS VIA - slow data bus RTC                                         *
;***********************************************************************

	.IFDEF MACH_CHIPKIT
BITS_RTC_AS_ON	:=		$88			; PB7
BITS_RTC_AS_OFF :=		$08			;
BITS_RTC_CS	:=		$04			; latch
BITS_RTC_DS	:=		$02			; latch
BITS_RTC_RnW	:=		$01			; latch
BITS_LAT_ON	:=		$08			; latch

RTC_REG_SECONDS	:=		$0
RTC_REG_MINUTES	:=		$2
RTC_REG_HOURS	:=		$4
RTC_REG_DOW	:=		$6
RTC_REG_DAY	:=		$7
RTC_REG_MONTH	:=		$8
RTC_REG_YEAR	:=		$9
	.ENDIF


;***********************************************************************
;* User VIA                                                            *
;***********************************************************************
sheila_USRVIA_orb			:= $FFFE60
sheila_USRVIA_ora			:= $FFFE61
sheila_USRVIA_ddrb			:= $FFFE62
sheila_USRVIA_ddra			:= $FFFE63
sheila_USRVIA_t1cl			:= $FFFE64
sheila_USRVIA_t1ch			:= $FFFE65
sheila_USRVIA_t1ll			:= $FFFE66
sheila_USRVIA_t1lh			:= $FFFE67
sheila_USRVIA_t2cl			:= $FFFE68
sheila_USRVIA_t2ch			:= $FFFE69
sheila_USRVIA_sr			:= $FFFE6A
sheila_USRVIA_acr			:= $FFFE6B
sheila_USRVIA_pcr			:= $FFFE6C
sheila_USRVIA_ifr			:= $FFFE6D
sheila_USRVIA_ier			:= $FFFE6E
sheila_USRVIA_ora_nh			:= $FFFE6F

;***********************************************************************
;*  VIA constants                                                      *
;***********************************************************************

VIA_IFR_BIT_ANY				:= $80
VIA_IFR_BIT_T1				:= $40
VIA_IFR_BIT_T2				:= $20
VIA_IFR_BIT_CB1				:= $10
VIA_IFR_BIT_CB2				:= $08
VIA_IFR_BIT_SR				:= $04
VIA_IFR_BIT_CA1				:= $02
VIA_IFR_BIT_CA2				:= $01

VIA_ACR_SHIFTMODE_0			:= $00
VIA_ACR_SHIFTMODE_1			:= $04
VIA_ACR_SHIFTMODE_2			:= $08
VIA_ACR_SHIFTMODE_3			:= $0C
VIA_ACR_SHIFTMODE_4			:= $10
VIA_ACR_SHIFTMODE_5			:= $14
VIA_ACR_SHIFTMODE_6			:= $18
VIA_ACR_SHIFTMODE_7			:= $1C

VIA_ACR_T1_MASK				:= $C0
VIA_ACR_T1_CONT				:= $40


;***********************************************************************
;* BBC B/B+ WD177x                                                     *
;***********************************************************************

sheila_1770_dcontrol			:=	$FFFE80
sheila_1770_wdc_cmd			:=	$FFFE84
sheila_1770_wdc_trk			:=	$FFFE85
sheila_1770_wdc_sec			:=	$FFFE86
sheila_1770_wdc_dat			:=	$FFFE87

W1770_DRVSEL_BIT_SEL0			:= $01
W1770_DRVSEL_BIT_SEL1			:= $02
W1770_DRVSEL_BIT_SIDE1			:= $04
W1770_DRVSEL_BIT_nDDEN			:= $08
W1770_DRVSEL_BIT_nMR			:= $20


;***********************************************************************
;* NEW API JIM DEVICE NOs                                              *
;***********************************************************************


JIM_DEVNO_HOG1MPAULA			:= $D0
JIM_DEVNO_BLITTER			:= $D1

	.ENDIF