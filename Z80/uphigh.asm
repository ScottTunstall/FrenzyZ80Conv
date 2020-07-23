B>type uphigh.asm

.title	"Update High Scores"
.sbttl	"FRENZY"
.ident	UPHIGH
;-------------------+
; High Score Update |
;-------------------+
.insert EQUS
.extern CLEAR,ScorePtr,SHOWA,RtoA,SHOWC,SHOWO
.extern C.HIGH,J.WAIT,LTABLE,S.STICK,NEXT.J
.define WROTE[Magic,X,Y,String]=[
	call	SHOWA
	.byte	Magic,X,Y
	.asciz	String
]
; language tabled subroutine call
.define LANG[Name]=[
	call	LTABLE
	.word	E'Name		;;English
	.word	G'Name		;;German
	.word	F'Name		;;French
	.word	S'Name		;;Spanish
]
UPHIGH::
	CALL	ScorePtr
B.BOP:	push	hl
; hl->players score
	inc	hl
	inc	hl		;->last byte
; add score to total
	ld	c,6
	ex de,hl			;->de score
	push	de
	call	ItemPtr#	;->hl at books
	ld	e,b		;->end
	ld	d,0		; by adding offset
	dec	e		; -1
	add	hl,de
	pop	de
; b=# bytes hl->books end de->score end
	ld	c,0		;no carry flag
	ld	a,(de)		;get score 2 digits
	dec	de
	call	AdBtoN
	ld	a,(de)		;get score 2 digits
	dec	de
	call	AdBtoN
	ld	a,(de)		;get score 2 digits
	dec	de
	call	AdBtoN		;done with player score
	ld	b,3		;the rest of the score area
..loop: xor	a
	call	AdBtoN
	djnz	..loop
; now xsum it
	ld	c,6		;scum #
	call	ItemPtr
	push	hl
	ld	c,0		;put xsum in c
..xsum: ld	a,(hl)		;add nibble to xsum
	and	0F0h
	add	a,c
	ld	c,a
	inc	hl
	djnz	..xsum
	pop	hl
	dec	hl		;->xsum byte
	ld	(hl),c
;check for high score
	ld	c,10		;number of high scores
	ld	de,HIGH1		;-> highest high
	pop	hl
..HLP:	push	hl
	push	de		;save pointer to high score
	ld	B,3		;number of bytes in high
..test: ld	a,(de)		;get high
	cp	(hl)		;compare to score
	jr c,	NEW.HI		;high exceeded?
	jr nz,	..SKIP		;equal maybe new high
	inc	de
	inc	hl
	djnz	..test
..SKIP: pop	de		;restore high pointer
	ld	hl,6		;length of high entry
	add	hl,de		;point to next entry
	ex de,hl			;put in de
	pop	hl
	dec	c		;one less entry to look at
	jr nz,	..HLP		;out of entries?
	ret
;------------------------+
; new high score to date |
;------------------------+
; enter new score by pushing down old ones
NEW.HI: pop	de		;get pointer to high score beaten
	push	de
	ld	B,0		; c=number of entries left
	dec	c
	jr z,	..SK
	ld	hl,0		;hl=bc*6
	add	hl,bc
	add	hl,hl
	add	hl,bc
	add	hl,hl
	push	hl		;save for later
	add	hl,de		;point at end
	dec	hl
	ld	d,h
	ld	e,l
	ld	bc,+6
	add	hl,bc
	ex de,hl
	pop	bc
	lddr
..SK:	pop	de		;new high
	pop	hl		;->score
	ld	B,3
..LP:	ld	a,(hl)
	inc	hl
	ld	(de),a
	inc	de
	djnz	..LP
	ex de,hl
;~~~~~~~~~~~~~~~~~~~~~
; get player initials
;_____________________
	push	hl
	call	CLEAR
	call	C.HIGH
	call	SHOWS#
	LANG	Line1
	ex af,af'
	ld	B,1
	ld	hl,PLAYER	;show player number
	call	SHOWO
	LANG	Line2
	WROTE	90H,120,98,("___")
	LANG	Line3
	call	GetTimer#
	push	hl
	pop	y		;iy->timer
;get letters
	ld	B,0
	ld	hl,96*256+120	;start char
	call	RtoA		;a=magic
	ex de,hl
	pop	hl		;restore pointer to letters
	push	hl
	ld	B,3
..fill: ld	(hl),' '
	inc	hl
	djnz	..fill
	pop	hl
	ld	a,30		;# of seconds to wait
	ld	(DEATHS),a		; for initials
	ld	B,3		;number of chars
	ld	c,'A'
S.L:	push	bc
	ld	a,(Flip)		;0 or 8=flop
	call	SHOWC
	pop	bc
	ld	0(y),15
..wlp:	call	NEXT.J
	ld	a,0(y)
	or	a
	jr nz,	..wlp
T.L:	ld	0(y),60		;sixty ticks to a second
I.L:	ld	a,0(y)		;if a second is up
	or	a
	jr nz,	I.S
	ld	a,(DEATHS)		;then if[[--wait.time]==0]
	dec	a
	ld	(DEATHS),a
	jr z,	BUP		;leave else goto t.l
	jr	T.L
I.S:	call	S.STICK
	bit	4,A		;fire:lock in letter?
	jr z,	ROTA
	ld	(hl),c		;store
	push	bc		;save number of letters
	ld	a,(Flip)
	or	a
	ld	bc,64		;shift down 2 lines
	jr z,	..up
	ld	bc,-64
..up:	push	de
	ex de,hl
	add	hl,bc
	ex de,hl
	ld	a,(Flip)		;0 or 8=flop
	or	90H		;xor
	ld	c,'_'		;erase underline
	call	SHOWC
	pop	de
	pop	bc
	inc	hl		;point to next letter
	ld	a,(Flip)
	or	a
	inc	de		;move screen position
	jr z,	..dl
	dec	de		;backwards writing
	dec	de
..dl:	call	S.STICK
	bit	4,A
	jr nz,	..dl
	djnz	S.L		;dec chars left
; update battery backed up score
BUP:	ld	hl,HIGH1
	ld	de,HIGH2
	ld	bc,(5*6<8)!0
BHLP:	ld	a,(hl)
	and	0F0h
	ld	(de),a
	inc	de
	add	a,c		;check sum it on fly
	ld	c,a
	ld	a,(hl)
	inc	hl
	rlc
	rlc
	rlc
	rlc
	and	0F0h
	ld	(de),a
	inc	de
	add	a,c		;check sum it on fly
	ld	c,a
	djnz	BHLP
	ld	a,c		;get xsum
	ld	(HIGH2-1),a		;store it
	ret
; change letter?
ROTA:	bit	0,A		;down,left=less
	jr nz,	..su
	bit	3,A
	jr nz,	..su
	bit	1,A		;up/right=more
	jr nz,	..ad
	bit	2,a
	jr nz,	..ad
	jp	I.L
..su:	ld	a,-1
	jr	..adj
..ad:	ld	a,1
..ADJ:	add	a,c		;change char
	cp	'A'-1		;check in range a-z
	jr nz,	..2
	ld	a,'Z'
..2:	cp	'Z'+1
	jr nz,	..3
	ld	a,'A'
..3:	ld	c,a		;store new char
	jp	S.L
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Add A to 2 nibble in books
; c=carry status
;______________________________
AdBtoN: push	af
	rlc
	rlc
	rlc
	rlc
	call	Nib
	pop	af
;	call	Nib
Nib:	and	0f0h
	ex af,af'
	ld	a,(hl)
	and	0f0h
	add	a,c
	daa
	ld	(hl),a
	ex af,af'
	add	(hl)
	daa
	ld	(hl),a		;store the books
	dec	hl
	ld	c,0
	ret nc
	ld	c,10h		;carry
	ret
;---------------
ELine1: WROTE	90H,32,08,("Congratulations Player ")
	ret
FLine1: WROTE	90H,16,08,("Felicitations au joueur ")
	ret

GLine1: WROTE	90H,32,08,("Gratuliere, Spieler ")
	ret
SLine1: WROTE	90H,32,08,("Felicitaciones jugador ")
	ret
;---------------
ELine2: WROTE	90H,08,32,("You have joined the immortals")
	WROTE	90H,16,48,("in the FRENZY hall of fame")
	WROTE	90H,24,80,("Enter your initials:")
	ret
FLine2: WROTE	90H,08,32,("Vous avez joint les immortels")
	WROTE	90H,24,48,("du pantheon FRENZY.")
	WROTE	90H,08,80,("Inscrire vos initiales:")
	ret
; ----------------------	123456789012345678901234567890
GLine2: WROTE	90H,08,32,("Das War ein Ruhmvoller Sieg!")
	WROTE	90H,08,64,("Trag Deinen Namen in die")
	WROTE	90H,16,80,("Heldenliste ein!")
	ret
SLine2: WROTE	90H,04,32,("Se puntaje esta entre los diez")
	WROTE	90H,08,48,("mejores.")
	WROTE	90H,24,80,("Entre sus iniciales:")
	ret
;---------------
GLine3	==	.
ELine3: WROTE	90H,8,128,("Move stick to change letter")
	WROTE	90H,8,144,("then press FIRE to store it.")
	ret
FLine3: WROTE	90H,4,128,("Poussez batonnet pour vos")
	WROTE	90H,4,144,("initiales. Poussez FIRE quand")
	WROTE	90H,4,160,("lettre correcte")
	ret
;
SLine3: WROTE	90H,4,128,("Moviendo la palanca para")
	WROTE	90H,4,144,("cambiar las letras, luego")
	WROTE	90H,4,160,("aplaste el boton de disparo")
	WROTE	90H,4,176,("para retenerlas.")
	ret

	.end

