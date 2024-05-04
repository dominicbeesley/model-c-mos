.ifndef __MODULES__
__MODULES__:


.struct modhdr
	brlstart	.byte
	offstart	.word

	brlinit		.byte
	offinit		.word

	brlfin		.byte
	offfin		.word

	brlserv		.byte
	offserv		.word

	length		.word
	resv1		.word

	flags1		.dword
	flags2		.dword
	flags3		.dword

	offtit		.word
	version		.word
	offhelp		.word
	offcmd		.word

.endstruct


.endif