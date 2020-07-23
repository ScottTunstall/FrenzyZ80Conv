B>type coins.asm

.title	"Coins and credits"
.sbttl	"FRENZY"
.ident COINS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Coins Subroutines
;_______________________________
.insert equs
.intern CREDS,GetC,COINCK
.intern DECCRD
.extern SHOWN,GO,ItemInc,S.Free
ItemOffset	== 0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Wait for Coins
;----------------------------
; B=number of seconds to hang around
COIN0:: ld	B,5
COIN1:: call	GetTimer#	;returns in HL
..Coin:
	ld	(hl),30		;set timer to 30/60's or 1/2 second
..Fast:
	push	hl		;save timer
	call	FreeCred	;check for service switch
	call	COINCK		;check coins
	jr nz,	GO		;if a button down GO play
	pop	hl		;->timer
	ld	a,(hl)		;check if timer still going
	or	a
	jr nz,	..Fast
	djnz	..Coin		;one less second to wait
	call	FreeTimer#
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 Display Credits
;--------------------------------------
CREDS:
	push	hl		;create a 2 byte string on the stack
	ld	hl,0		;get its address into hl
	add	hl,sp
	call	GetC		;a:=credits
	ld	(hl),a		;store into 1st byte of stack
	ld	B,2		;# of digits to show
	ld	de,213*256+120	;where to show
	call	SHOWN		;show number
	pop	hl		;remove temp from stack
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Get Credits into A
;--------------------------------------
GetC:
	ld a,	(CREDITS+1)	;load low nibble of credits
	rrc			;which is in high nibble
	rrc			;battery ram
	rrc			;into low nibble of A
	rrc
	and	0FH		;mask off trash
	ld	c,a		;save low nibble
	ld a,(CREDITS)		;get high nibble
	and	0F0H		;mask trash
	or	c		;or in low nibble
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Increment Credits by 1
;--------------------------------------
IncCred:
	call	GetC
	cp	99H
	ret z	
	add	a,1
	daa
	jr	PutCred
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Decrement Credits by 1
;--------------------------------------
DECCRD:
	call	GetC		;get credits
	add	a,99H		;add -1 in 9's complement arithmetic
	daa			;decimal adjust
	jr	PutCred		;store credits
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Put Credits in A into Battery RAM
;--------------------------------------
PutCred:
	push	bc
	ld	(CREDITS),a		;store in high nibble battery ram
	ld	c,a
	rlc			;rotate nibble
	rlc			;note-I dont mask extra bits here
	rlc			;but in getcred I do
	rlc
	ld (CREDITS+1),a	;store
	and	0f0h
	add	a,c
	and	0f0h
	ld (CREDITS-1),a	;xsum
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Convert Coin-Clicks to Credits
;--------------------------------------
; HL->coins for chute[x]
; C = i/o port with coin setting dips for chute[x]
; B = 2,1
ClickToCredit:
	in	a,(DIP5)		;credit amount
	or	a
	jr nz,	..pay
	push	bc
	push	hl
	ld	b,1		;give a credit
	jr	..lp		;jump into loop
..pay:	ld	a,(hl)		;check coin clinks
	or	a		;if no clinks
	ret z			; leave
	push	bc		;save i/o port
	push	hl		;save pointer to clinks thru chute
	dec	(hl)		;do one clink
	push	bc
	ld	a,b		;get chute number
	add	a,ItemOffset	;add offset
	ld	c,a		;pass in C to
	call	ItemInc		;do book-keeping
	pop	bc
	pop	hl		;restore pointer to clinks
	push	hl
	ld	b,-1		;no credits yet(adds one
	in	a,(DIP5)		;credit amount
	ld	e,a		;in E
	ld	hl,CACKLE	;move to fractional coins
	in	a,(C)		;get dips
	add	a,(hl)		;get fractional
..cr:	inc	b		;got enough for a credit
	ld	(hl),a		;store remaining credits
	sub	e		;subtract credit amount
	jr nc,	..cr		;do another cred
	ld	a,b		;check credits
	or	a
	jr z,	..sk		;no creds-exit
..lp:	call	IncCred		;add a credit
	djnz	..lp		;b=number to add
..sk:	pop	hl
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check Coins and Show New Credits
;--------------------------------------
COINCK: push	bc
	ld	hl,Coins		;check coins
	call	GetC		;get credits
	push	af
	ld	bc,DIP3!(2<8)	;2 dip banks
ChuteLoop:
	call	ClickToCredit	;clinks to credits
	inc	hl
	inc	c
	djnz	ChuteLoop
	call	GetC		;if new credits
	pop	bc		; aren't
	cp	b		;  equal to old
	call nz,	CREDS		;  then show em
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check for Free Credit Button
;-------------------------------
FreeCred:
	call	S.Free
	ret z	
	call	IncCred
..lp:	call	S.Free
	jr nz,	..lp
	ret

	.end
