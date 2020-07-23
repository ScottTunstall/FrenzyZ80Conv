B>type room.asm

.title	"Draw Room and Set Pointers"
.sbttl	"FRENZY"
.ident	ROOM
;--------------------+
; room related stuff |
;--------------------+
.insert equs
.extern SHOWC,SHOWS,SHOWA,SHOWN,RtoA
.extern CREDS,C.WALLS,PLOT,RANDOM
; Equates
BDOWN	==	3
BUP	==	2
BRIGHT	==	1
BLEFT	==	0
ORWRITE ==	10H
.define XY[PX,PY]=[
	ld	hl,PY*256+PX]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on left
;_______________________________
RoomLeft::
	call	RINIT
	set	BLEFT,0+24(x)
	set	BLEFT,6+24(x)
	set	BLEFT,12+24(x)
	set	BLEFT,18+24(x)
	ld hl, (ManX))
	ld	l,h		;get y
	ld	h,240		;set x
	call	WallIndex#
	ld	hl,24
	add	hl,de
	set	BRIGHT,(hl)
	jp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on Right
;_______________________________
RoomRight::
	call	RINIT
	set	BRIGHT,5+24(x)
	set	BRIGHT,11+24(x)
	set	BRIGHT,17+24(x)
	set	BRIGHT,23+24(x)
	ld hl, (ManX))
	ld	l,h		;get y
	ld	h,16		;set x
	call	WallIndex#
	ld	hl,24
	add	hl,de
	set	BLEFT,(hl)
	jp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on Down
;_______________________________
RoomDown::
	call	RINIT
	set	BDOWN,18+24(x)
	set	BDOWN,19+24(x)
	set	BDOWN,20+24(x)
	set	BDOWN,21+24(x)
	set	BDOWN,22+24(x)
	set	BDOWN,23+24(x)
	ld hl, (ManX)
	ld	h,l		;get x
	ld	l,16		;set y
	call	WallIndex#
	ld	hl,24
	add	hl,de
	set	BUP,(hl)
	jp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on Up
;_______________________________
RoomUp::
	call	RINIT
	set	BUP,0+24(x)
	set	BUP,1+24(x)
	set	BUP,2+24(x)
	set	BUP,3+24(x)
	set	BUP,4+24(x)
	set	BUP,5+24(x)
	ld hl, (ManX)
	ld	h,l		;get x
	ld	l,180		;set y
	call	WallIndex#
	ld	hl,24
	add	hl,de
	set	BDOWN,(hl)
	jp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show outline of room
;_______________________________
ROOM::	ld	hl,RoomCnt
	dec	(hl)
	call	RINIT
; generate walls bits
DoRo:	lxi	x,WALLS
	call	ROW
	call	ROW
	call	ROW
; draw walls
	call	RoomDraw
	call	C.WALLS		; color walls
	call	Wdot		;add white dots
	call	SHOWS
; show number of deaths left
SHOWD:: ld a,	PLAYER
	cp	2
	XY	56,213
	jr nz,	DPI
	ld	L,232
DPI:	ld	B,0
	call	RtoA
	ex de,hl
	ex af,af'
	ld a,	DEATHS
	ld	b,a
	ex af,af'
	dec	b
	jr z,	SSE
DLP:	push	bc
	ld	c,80H		;man
	call	SHOWC
	inc	de
	ex af,af'
	ld	a,(Flip)
	or	a
	jr z,	..
	dec	de
	dec	de
..:	ex af,af'
	pop	bc
	djnz	DLP
SSE:	ld a,	Demo		;if demo,show credits
	or	a
	call nz,	CREDS
	ret
;---------------------------+
; Generate 0-4 random walls |
;---------------------------+
ROW:	ld	b,5
..lp:	push	bc
	call	RANDOM
	ld	bc,..ret		;return address for all
	push	bc		;do table call sort of
	and	3
	jz	UP
	dec	a
	jz	DOWN
	dec	a
	jz	RIGHT
	jp	LEFT
..ret:	pop	bc		;move to next column
	inx	x
	djnz	..lp
	inx	x
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Wall setting routines
;_______________________________
DOWN:	set	BRIGHT,6(x)
	set	BLEFT,7(x)
	ld a,	SEED		;reflecto wall?
	rlc
	ret nc
	set	BRIGHT,24+6(x)	;set reflecto
	set	BLEFT,24+7(x)
	ret
;
UP:	set	BRIGHT,0(x)
	set	BLEFT,1(x)
	ld a,	SEED
	rlc
	ret nc
	set	BRIGHT,24+0(x)
	set	BLEFT,24+1(x)
	ret
;
RIGHT:	set	BDOWN,1(x)
	set	BUP,7(x)
	ld a,	SEED
	rlc
	ret nc
	set	BDOWN,24+1(x)
	set	BUP,24+7(x)
	ret
;
LEFT:	set	BDOWN,0(x)
	set	BUP,6(x)
	ld a,	SEED
	rlc
	ret nc
	set	BDOWN,24+0(x)
	set	BUP,24+6(x)
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Draw a Room
;_______________________________
RoomDraw:
	ld	h,4
	lxi	x,walls
	ld	bc,(4<8)!(1<BUP)
..lp:	call	HORIZ
	ld	a,48
	add	a,h
	ld	h,a
	djnz	..lp
	lxi	x,walls+(3*6)	; do last wall
	ld	c,1<BDOWN
	call	HORIZ
	lxi	x,walls		; do verticals
	ld	bc,(6<8)!(1<BLEFT)
	ld	L,8
..kp:	call	VERT
	ld	a,40
	add	a,l
	ld	l,a
	djnz	..kp
	dcx	x		;do last vert wall
	ld	c,1<BRight
	call	VERT
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Draw complete horizontal
;_______________________________
HORIZ:	push	bc
	ld	l,8
	ld	b,6
..lp:	push	hl
	push	bc
	ld	a,24(x)		;check reflecto wall
	and	c
	jr z,	..nor		;0=non reflecto
	ld	a,0(x)
	and	c
	jr z,	..sq
	call	HWR
	jr	..open
..sq:	call	HWS
	jr	..open
..nor:	ld	a,0(x)
	and	c
	jr z,	..open
	call	HWB
..open: pop	bc
	pop	hl
	inx	x
	ld	a,40
	add	a,l
	ld	l,a
	djnz	..lp
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~
; Draw complete Vertical
;__________________________
VERT:	push	bc
	ld	h,4
	ld	b,4
..lp:	push	hl
	push	bc
	ld	a,24(x)		;check reflecto wall
	and	c
	jr z,	..nor		;0=non reflecto
	ld	a,0(x)
	and	c
	jr z,	..sq
	call	VWR
	jr	..open
..sq:	call	VWS
	jr	..open
..nor:	ld	a,0(x)
	and	c
	jr z,	..open
	call	VWB
..open: pop	bc
	pop	hl
	ld	de,6
	dadx	d
	ld	a,48
	add	a,h
	ld	h,a
	djnz	..lp
	ld	de,-(6*4)+1
	dadx	d
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Horizontal wall of Crosses
;_______________________________
HWB::	ld	B,11
Hlp:	push	bc		;number of bricks to write
	push	hl		;x and y relative addr
	call	RELOR		;convert coordinates
	ld	hl,CROSS		;brick pattern
	call	PLOT		;plot a brick
	pop	hl
	pop	bc
	ld	a,4		;move to end of brick in x
	add	a,l		;to lay next one
	ld	l,a
	djnz	Hlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Horizontal wall of Squares
;_______________________________
HWS:	ld	B,11
..Hlp:	push	bc		;number of bricks to write
	push	hl		;x and y relative addr
	call	RELOR		;convert coordinates
	ld	hl,CUBE		;brick pattern
	call	PLOT		;plot a brick
	pop	hl
	pop	bc
	ld	a,4		;move to end of brick in x
	add	a,l		;to lay next one
	ld	l,a
	djnz	..Hlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Horizontal wall of Reflecto
;_______________________________
HWR:	push	hl
	call	RELOR
	ld	hl,HSTART
	call	PLOT
	pop	hl
	ld	a,4		;move to end of brick in x
	add	a,l		;to lay next one
	ld	l,a
	ld	B,9
..lp:	push	bc		;number of bricks to write
	push	hl		;x and y relative addr
	call	RELOR		;convert coordinates
	ld	hl,HBLOCK		;brick pattern
	call	PLOT		;plot a brick
	pop	hl
	pop	bc
	ld	a,4		;move to end of brick in x
	add	a,l		;to lay next one
	ld	l,a
	djnz	..lp		;do another brick
	call	RELOR		;convert coordinates
	ld	hl,HEND
	jp	PLOT
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vertical wall of Crosses
;_______________________________
VWB::	ld	B,13
Vlp:	push	bc		;number of bricks to write
	push	hl		;x and y relative addr
	call	RELOR		;convert coordinates
	ld	hl,CROSS
	call	PLOT
	pop	hl
	pop	bc
	ld	a,4		;move to end of brick in y
	add	a,h		;to lay next one
	ld	h,a
	djnz	Vlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vertical wall of Squares
;_______________________________
VWS:	ld	B,13
..Vlp:	push	bc		;number of bricks to write
	push	hl		;x and y relative addr
	call	RELOR		;convert coordinates
	ld	hl,CUBE
	call	PLOT
	pop	hl
	pop	bc
	ld	a,4		;move to end of brick in y
	add	a,h		;to lay next one
	ld	h,a
	djnz	..Vlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vertical wall of Crosses
;_______________________________
VWR:	push	hl
	call	RELOR
	ld	hl,VSTART
	call	PLOT
	pop	hl
	ld	a,4		;move to end of brick in y
	add	a,h		;to lay next one
	ld	h,a
	ld	B,11
..lp:	push	bc		;number of bricks to write
	push	hl		;x and y relative addr
	call	RELOR		;convert coordinates
	ld	hl,VBLOCK
	call	PLOT
	pop	hl
	pop	bc
	ld	a,4		;move to end of brick in y
	add	a,h		;to lay next one
	ld	h,a
	djnz	..lp		;do another brick
	call	RELOR
	ld	hl,VEND
	jp	PLOT
;----------------------+
; relative to absolute |
;----------------------+
RELOR:	ld	B,ORWRITE
	call	RtoA
	ex de,hl
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Initialize walls arrays etc
;_______________________________
RINIT:	ld hl,	(RoomX)		;put room number
	shld	SEED		;in seed
;erase message area
	ld	a,(Flip)
	or	a
	jr nz,	..flp
	ld	hl,10+211*Hsize+Screen	;modify for upside down??
	jr	..Nor
..flp:	ld	hl,Screen+10+2*Hsize
..Nor:	ld	de,Hsize-12
	xor	a
	ld	c,12		;for 12 lines
..JEL:	ld	B,12		;erase 12 bytes
..MEL:	ld	(hl),a
	inc	hl
	djnz	..MEL
	add	hl,de
	dec	c
	jr nz,	..JEL
; initialize walls array
	ld	bc,4*6*2
	ld	de,WALLS
	ld	hl,R.DATA
	ldir
;generate doors - TOP
	lxi	x,Walls
	ld hl,	(RoomX)		;get coords
	ld	a,l		;get y
	and	3
	ld	e,a
	ld	d,0
	ld	h,d
	ld	l,e		;1
	add	hl,hl		;2
	add	hl,de		;3
	add	hl,hl
	ex de,hl
	dadx	d		;6*
	RES	BLEFT,0(x)	;set door bit
;right
	lxi	x,Walls
	ld hl,	(RoomX)		;get coords
	ld	a,l		;get x
	inc	a
	and	3
	ld	e,a
	ld	d,0
	ld	h,d
	ld	l,e		;1
	add	hl,hl		;2
	add	hl,de		;3
	add	hl,hl
	ex de,hl
	dadx	d		;6*
	RES	BRIGHT,5(x)	;set door bit
;top
	lxi	x,Walls
	ld hl,	(RoomX)		;get coords
	ld	a,h		;get y
	and	3
	inc	a
	ld	e,a
	ld	d,0
	dadx	d
	RES	BUP,0(x)	;set door bit
;bottom
	lxi	x,Walls
	ld hl,	(RoomX)		;get coords
	ld	a,h		;get y
	inc	a
	and	3
	inc	a
	ld	e,a
	ld	d,0
	dadx	d
	RES	BDOWN,18(x)	;set door bit
;inc number of rooms seen
	ld	hl,RoomCnt
	inc	(hl)		;inc room count
	ld	a,(hl)
	cp	32+1
	jr c,	..rm
	cp	-1
	jr z,	..rm
	ld	(hl),19		;3 rooms of white hell
..rm:	ld	a,(hl)
	or	a
	jr z,	..skw
	and	3		;test for special room
	cz	S.ROOM#
..skw:	lxi	x,Walls		;everyone needs this
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Put white dot around edge
;_______________________________
Wdot:	ld	hl,D.Table	;dot table
..loop: ld	a,(hl)		;x
	or	a
	ret z
	ld	c,a		;set X
	inc	hl
	ld	b,(hl)		;set Y
	inc	hl
	push	hl
	call	Cdot
	pop	hl	
	jp	..loop
; change dot at bc to white
Cdot:	push	bc		;save YX
	srl	B		;index the 4x4 box
	srl	B		;y/2
	srl	B		;YX/8
	rr	c
	srl	B
	RR	c
	srl	B
	rr	c		;carry=Low nibble
	ex af,af'
	ld	a,(Flip)		;test cocktail
	or	a
	jz	..norm
	ld	hl,EndColor
	dsbc	b		;subtract box offset
	pop	bc		;restore YX
	ex af,af'
	ccf			;complement hi/lo
	jp	..tt
..norm: ld	hl,ColorScreen	;base of color area
	add	hl,bc		;add box offset
	pop	bc		;restore YX
	ex af,af'
..tt:
; change color box to grey
	bit	2,C		;left/right nibble bit(4)
	ld	de,0ff0h		;left half mask
	jr z,	..fix
	ld	de,#0ff0h	;right mask
..fix:	ld	a,(Flip)
	or	a
	jr z,	..auk
	ld	a,d		;swap em
	ld	d,e
	ld	e,a
..auk:	ld	a,(hl)		;get 2 color boxes
	and	d		;mask valid part
	ld	d,a		;save
	ld a,	Dcolor		;get dot color
	and	e		;isolate nibble
	or	d		;combine nibbles
	ld	(hl),a		;store new color
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; initial room data
;__________	d.u.r.l
R.DATA: .byte	5,4,4,4,4,6
	.byte	1,0,0,0,0,2
	.byte	1,0,0,0,0,2
	.byte	9,8,8,8,8,10
	.byte	0,0,0,0,0,0
	.byte	0,0,0,0,0,0
	.byte	0,0,0,0,0,0
	.byte	0,0,0,0,0,0
; table of dot positions
D.Table:
	.byte	8,4,8,52,8,100,8,148,8,196
	.byte	248,4,248,52,248,100,248,148,248,196
	.byte	48,4,88,4,128,4,168,4,208,4
	.byte	48,196,88,196,128,196,168,196,208,196
	.byte	0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; patterns for walls
;__________________________________
CUBE:	.byte	1,4
	.byte	0F0h,090h,090h,0F0h
CROSS:	.byte	1,4
	.byte	060h,0F0h,0F0h,060h
Vblock: .byte	1,4
	.byte	060h,060h,060h,060h
VSTART: .byte	1,4
	.byte	000h,060h,060h,060h
VEND:	.byte	1,4
	.byte	060h,060h,060h,000h
HBLOCK: .byte	1,4
	.byte	000h,0F0h,0F0h,000h
HSTART: .byte	1,4
	.byte	000h,070h,070h,000h
HEND:	.byte	1,4
	.byte	000h,0E0h,0E0h,000h

	.end
