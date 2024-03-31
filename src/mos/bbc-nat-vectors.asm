		
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
		jsr	bbcNatVecEnter			; XUSERV
		jsr	bbcNatVecEnter			; XBRKV
		jsr	bbcNatVecEnter			; XIRQ1V
		jsr	bbcNatVecEnter			; XIRQ2V
		jsr	bbcNatVecEnter			; XCLIV
		jsr	bbcNatVecEnter			; XBYTEV
		jsr	bbcNatVecEnter			; XWORDV
		jsr	bbcNatVecEnter			; XWRCHV
		jsr	bbcNatVecEnter			; XRDCHV
		jsr	bbcNatVecEnter			; XFILEV
		jsr	bbcNatVecEnter			; XARGSV
		jsr	bbcNatVecEnter			; XBGETV
		jsr	bbcNatVecEnter			; XBPUTV
		jsr	bbcNatVecEnter			; XGBPBV
		jsr	bbcNatVecEnter			; XFINDV
		jsr	bbcNatVecEnter			; XFSCV
		jsr	bbcNatVecEnter			; XEVENTV
		jsr	bbcNatVecEnter			; XUPTV
		jsr	bbcNatVecEnter			; XNETV
		jsr	bbcNatVecEnter			; XVDUV
		jsr	bbcNatVecEnter			; XKEYV
		jsr	bbcNatVecEnter			; XINSV
		jsr	bbcNatVecEnter			; XREMV
		jsr	bbcNatVecEnter			; XCNPV
		jsr	bbcNatVecEnter			; XIND1V
		jsr	bbcNatVecEnter			; XIND2V
		jsr	bbcNatVecEnter			; XIND3V
tblNatShimsEnd:

