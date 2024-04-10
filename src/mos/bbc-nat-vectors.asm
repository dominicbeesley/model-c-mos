		
		.export tblNatShims
		.export tblNatShimsEnd


	; these entry points are used to enter native mode from emu mode
	; as a BBC vector's default entry
	; all entries jump to bbcNatVecEnter which uses the stacked
	; return address to figure out which vector to call

		.segment "BBC_NAT_VEC_SHIMS"
		.i8
		.a8
	
	; These are the BBC native vector entry points, they should
	; be entered in emulation mode only

	; the entry points below bounce to the routine doExtended which
	; uses the return address here to figure out which vector

tblNatShims:
		jsr	bbcEmu2NatVectorEntry		; XUSERV
		jsr	bbcEmu2NatVectorEntry		; XBRKV
		jsr	bbcEmu2NatVectorEntry		; XIRQ1V
		jsr	bbcEmu2NatVectorEntry		; XIRQ2V
		jsr	bbcEmu2NatVectorEntry		; XCLIV
		jsr	bbcEmu2NatVectorEntry		; XBYTEV
		jsr	bbcEmu2NatVectorEntry		; XWORDV
		jsr	bbcEmu2NatVectorEntry		; XWRCHV
		jsr	bbcEmu2NatVectorEntry		; XRDCHV
		jsr	bbcEmu2NatVectorEntry		; XFILEV
		jsr	bbcEmu2NatVectorEntry		; XARGSV
		jsr	bbcEmu2NatVectorEntry		; XBGETV
		jsr	bbcEmu2NatVectorEntry		; XBPUTV
		jsr	bbcEmu2NatVectorEntry		; XGBPBV
		jsr	bbcEmu2NatVectorEntry		; XFINDV
		jsr	bbcEmu2NatVectorEntry		; XFSCV
		jsr	bbcEmu2NatVectorEntry		; XEVENTV
		jsr	bbcEmu2NatVectorEntry		; XUPTV
		jsr	bbcEmu2NatVectorEntry		; XNETV
		jsr	bbcEmu2NatVectorEntry		; XVDUV
		jsr	bbcEmu2NatVectorEntry		; XKEYV
		jsr	bbcEmu2NatVectorEntry		; XINSV
		jsr	bbcEmu2NatVectorEntry		; XREMV
		jsr	bbcEmu2NatVectorEntry		; XCNPV
		jsr	bbcEmu2NatVectorEntry		; XIND1V
		jsr	bbcEmu2NatVectorEntry		; XIND2V
		jsr	bbcEmu2NatVectorEntry		; XIND3V
tblNatShimsEnd:

