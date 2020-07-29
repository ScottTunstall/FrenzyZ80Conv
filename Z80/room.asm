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
	set	BLEFT,(ix+24)
	set	BLEFT,(ix+24+6)
	set	BLEFT,(ix+24+12)
	set	BLEFT,(ix+24+18)
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
	set	BRIGHT,(ix+24+5)
	set	BRIGHT,(ix+24+11)
	set	BRIGHT,(ix+24+17)
	set	BRIGHT,(x+24+23)
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
	set	BDOWN,(ix+24+18)
	set	BDOWN,(ix+24+19)
	set	BDOWN,(ix+24+20)
	set	BDOWN,(ix+24+21)
	set	BDOWN,(ix+24+22)
	set	BDOWN,(ix+24+23)
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
	set	BUP,(ix+24+0)
	set	BUP,(ix+24+1)
	set	BUP,(ix+24+2)
	set	BUP,(ix+24+3)
	set	BUP,(ix+24+4)
	set	BUP,(ix+24+5)
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
DoRo:	ld	ix,WALLS
	call	ROW
	call	ROW
	call	ROW
; draw walls
	call	RoomDraw
	call	C.WALLS		; color walls
	call	Wdot		;add white dots
	call	SHOWS
; show number of deaths left
SHOWD:: ld	a,(PLAYER)
	cp	2
	XY	56,213
	jr nz,	DPI
	ld	L,232
DPI:	ld	B,0
	call	RtoA
	ex de,hl
	ex af,af'
	ld	a,(DEATHS)
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
SSE:	ld	a,(Demo)		;if demo,show credits
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
	inc	ixx
	djnz	..lp
	inc	ixx
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Wall setting routines
;_______________________________
DOWN:	set	BRIGHT,(ix+6)
	set	BLEFT,(ix+7)
	ld	a,(SEED)		;reflecto wall?
	rlc
	ret nc
	set	BRIGHT,(ix+30)	;set reflecto
	set	BLEFT,(ix+32)
	ret
;
UP:	set	BRIGHT,(ix+0)
	set	BLEFT,(ix+1)
	ld	a,(SEED)
	rlc
	ret nc
	set	BRIGHT,(ix+24)
	set	BLEFT,(ix+25)
	ret
;
RIGHT:	set	BDOWN,(ix+1)
	set	BUP,(ix+7)
	ld	a,(SEED)
	rlc
	ret nc
	set	BDOWN,(ix+25)
	set	BUP,(ix+32)
	ret
;
LEFT:	set	BDOWN,(ix+0)
	set	BUP,(ix+6)
	ld	a,(SEED)
	rlc
	ret nc
	set	BDOWN,(ix+24)
	set	BUP,(ix+30)
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Draw a Room
;_______________________________
RoomDraw:
	ld	h,4
	ld	ix,walls
	ld	bc,(4<8)!(1<BUP)
..lp:	call	HORIZ
	ld	a,48
	add	a,h
	ld	h,a
	djnz	..lp
	ld	ix,walls+(3*6)	; do last wall
	ld	c,1<BDOWN
	call	HORIZ
	ld	ix,walls		; do verticals
	ld	bc,(6<8)!(1<BLEFT)
	ld	L,8
..kp:	call	VERT
	ld	a,40
	add	a,l
	ld	l,a
	djnz	..kp
	dec	ix		;do last vert wall
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
	ld	a,(ix+24)		;check reflecto wall
	and	c
	jr z,	..nor		;0=non reflecto
	ld	a,(ix+0)
	and	c
	jr z,	..sq
	call	HWR
	jr	..open
..sq:	call	HWS
	jr	..open
..nor:	ld	a,(ix+0)
	and	c
	jr z,	..open
	call	HWB
..open: pop	bc
	pop	hl
	inc	ixx
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
	ld	a,(ix+24)		;check reflecto wall
	and	c
	jr z,	..nor		;0=non reflecto
	ld	a,(ix+0)
	and	c
	jr z,	..sq
	call	VWR
	jr	..open
..sq:	call	VWS
	jr	..open
..nor:	ld	a,(ix+0)
	and	c
	jr z,	..open
	call	VWB
..open: pop	bc
	pop	hl
	ld	de,6
	add	ix,de
	ld	a,48
	add	a,h
	ld	h,a
	djnz	..lp
	ld	de,-(6*4)+1
	add	ix,de
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
RINIT:	ld	hl, (RoomX)		;put room number
	ld	(SEED),hl		;in seed
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
	ld	ix,Walls
	ld	hl,(RoomX)		;get coords
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
	add	ix,de		;6*
	RES	BLEFT,(ix+0)	;set door bit
;right
	ld	ix,Walls
	ld	hl,(RoomX)		;get coords
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
	add	ix,de		;6*
	RES	BRIGHT,(ix+5)	;set door bit
;top
	ld	ix,Walls
	ld	hl,(RoomX)		;get coords
	ld	a,h		;get y
	and	3
	inc	a
	ld	e,a
	ld	d,0
	add	ix,de
	RES	BUP,(ix+0)	;set door bit
;bottom
	ld	ix,Walls
	ld	hl,(RoomX)		;get coords
	ld	a,h		;get y
	inc	a
	and	3
	inc	a
	ld	e,a
	ld	d,0
	add	ix,de
	RES	BDOWN,(ix+18)	;set door bit
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
	call z,	S.ROOM#
..skw:	ld	ix,Walls		;everyone needs this
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
	sbc	hl,bc		;subtract box offset
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
	ld	a,(Dcolor)		;get dot color
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
