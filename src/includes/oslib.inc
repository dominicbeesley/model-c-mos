.ifndef __OSLIB_INC__
__OSLIB_INC__:


OSBYTE_0_HOST_OS			:=	0
OSBYTE_13_DISABLE_EVENT			:=	13
OSBYTE_14_ENABLE_EVENT			:=	14
OSBYTE_15_FLUSH_INPUT			:=	15
OSBYTE_21_FLUSH_BUFFER			:=	21
OSBYTE_108_WRITE_SHADOW_STATE		:=	108
OSBYTE_118_SET_KEYBOARD_LEDS		:=	118
OSBYTE_119_CLOSE_SPOOL_AND_EXEC		:=	119
OSBYTE_126_ESCAPE_ACK			:=	126
OSBYTE_129_INKEY			:=	129
OSBYTE_135_GET_MODE			:=	135
OSBYTE_143_SERVICE_CALL			:=	143
OSBYTE_156_SERIAL_STATE			:=	156
OSBYTE_160_READ_VDU_VARIABLE		:=	160
OSBYTE_168_READ_ROM_POINTER_TABLE	:=	168
OSBYTE_171_ROMTAB			:=	170
OSBYTE_232_VAR_IRQ_MASK_SERIAL		:=	232
OSBYTE_234_VAR_TUBE			:=	234
OSBYTE_253_VAR_LAST_RESET		:=	253


;;;; COP CALLS - from Communicator 
COP_06_OPOSB				:=	$06		; OBYTE


;;;; Service calls

SERVICE_0_NOP				:=	$0
SERVICE_1_ABSWKSP_REQ			:=	$1
SERVICE_2_RELWKSP_REQ			:=	$2
SERVICE_3_AUTOBOOT			:=	$3
SERVICE_4_UKCMD				:=	$4
SERVICE_5_UKINT				:=	$5
SERVICE_6_BRK				:=	$6
SERVICE_7_UKOSBYTE			:=	$7
SERVICE_7_UKOSWORD			:=	$8
SERVICE_9_HELP				:=	$9
SERVICE_A_ABSWKSP_CLAIM			:=	$A
SERVICE_B_NMI_RELEASE			:=	$B
SERVICE_C_NMI_CLAIM			:=	$C
SERVICE_D_ROMFS_INIT			:=	$D
SERVICE_E_ROMFS_GETB			:=	$E
SERVICE_F_FSVEC_CLAIMED			:=	$F
SERVICE_10_SPOOL_CLOSE			:=	$10
SERVICE_11_FONT_BANG			:=	$11
SERVICE_12_INITFS			:=	$12
SERVICE_13_SERIAL_CHAR			:=	$13
SERVICE_14_PRINT_CHAR			:=	$14
SERVICE_15_100Hz			:=	$15
SERVICE_25_FSINFO			:=	$25

.endif