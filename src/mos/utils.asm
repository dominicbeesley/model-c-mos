

		.export utilsAisAlpha

		; ENTRY	 character in A
		; exit with carry set if non-Alpha character
_LE4E3:	
utilsAisAlpha:	php
		sep	#$30		
		pha					; Save A
		and	#$df				; convert lower to upper case
		cmp	#$41				; is it 'A' or greater ??
		bcc	_BE4EE				; if not exit routine with carry set
		cmp	#$5b				; is it less than 'Z'
		bcc	_BE4EF				; if so exit with carry clear
_BE4EE:		pla
		plp
		sec					; else clear carry
		rts
_BE4EF:		pla					; get back original value of A
		plp
		clc
		rts					; and Return
