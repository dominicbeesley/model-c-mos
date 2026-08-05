		.include "vectors_i.inc"
		
		.export tblNatShims
		.export tblNatShimsEnd



	; these entry points are used to enter native mode from emu mode
	; as a BBC vector's default entry
	; all entries jump to bbcNatVecEnter which uses the stacked
	; return address to figure out which vector to call

		.segment "BBCCODE"
		.i8
		.a8
	
	; These are the BBC native vector entry points, they should
	; be entered in emulation mode only

	; the entry points below bounce to the routine bbcEmu2NatVectorEntry which
	; uses the return address here to figure out which vector and then passes
	; it on through the EMU2NAT_VEC_SHIMS entry to callAvector to call the
	; native mode handler

	; There is a double indirection, the first uses this table to get us into
	; native mode and derive the index, then the bbcEmu2NatVectorEntry routine
	; passes on to any registered shims. This may change to be a single
	; indirection in future.

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

