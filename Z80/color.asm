B>type color.asm

.title	"Color Subroutines"
.sbttl	"FRENZY"
.ident COLOR
;---------------------------+
; color related subroutines |
;---------------------------+
.insert EQUS
.intern C.GO,C.L1,C.L2,C.LI,C.DIPS
.intern C.HIGH,C.WALLS,C.BOOKS
.intern C.MOVE
.extern ScorePtr
.extern J.WAIT
; equates
BRIGHT	==	88H
BLUE	==	44H
GREEN	==	22H
RED	==	11H
WHITE	==	77H
PURPLE	==	RED+BLUE
CYAN	==	BLUE+GREEN
YELLOW	==	RED+GREEN
; macros
.define LINES[LINE1,LINE2,COLOR]=[
	call	C.BOX
	.word	(LINE1*8)
	.byte	(LINE2-LINE1)/4
	.byte	32
	.byte	COLOR
]
.define BOX[X,Y,LINE2,WIDTH,COLOR]=[
	call	C.BOX
	.word	X+(Y*8)
	.byte	(LINE2-Y)/4
	.byte	WIDTH
	.byte	COLOR
]
;
; setup colors for game over / high scores
;
C.GO:	LINES	0,40,BRIGHT+RED
	LINES	40,56,Yellow
	LINES	56,60,77H
	BOX	0,60,184,10,GREEN
	BOX	10,60,184,8,RED
	BOX	17,60,184,15,Yellow
	LINES	184,224,077H
C.INFO: BOX	0,208,224,10,M1color
	BOX	22,208,224,10,M2color
	ret
; colors for title
C.TITLE::
	LINES	0,76,BRIGHT+RED
	LINES	76,224,BRIGHT+Yellow
	LINES	188,204,BLUE
	ret
; white screen for diag displays
C.DIPS:
	LINES	0,224,0FFH
	ret
;
; setup colors for insert coin
;
C.LI:	LINES	188,204,Yellow
	ret
;
; setup colors for press 1 or 2 player
;
C.L1:
C.L2:	LINES	188,204,Cyan
	ret
;
; setup colors for congratulations
;
C.HIGH: LINES	0,32,BRIGHT+Yellow
	LINES	32,96,Cyan
	LINES	96,112,0FFH
	LINES	112,224,BRIGHT+GREEN
	jp	C.INFO
;
; setup colors for book-keeping show
;
C.BOOKS: LINES	0,188,BRIGHT+BLUE
	LINES	188,224,BRIGHT+GREEN
	ret
; colors for moveing room
C.MOVE: LINES	0,208,Purple
	ret
;-----------------------------
; fill color ram with a value
; inline parms:
; word 1:start address
; byte 2:number of lines
; byte 3:width in bytes
; byte 4:color fill value
; uses flip to determine direction
;-----------------------------
C.BOX:	pop	hl		;get parameters address
	ld	e,(hl)		;get start address
	inc	hl
	ld	d,(hl)
	inc	hl
	push	hl
; convert to offset
	ld	a,(Flip)
	or	a
	jr nz,	Up
Down:	ld	hl,ColorScreen
	add	hl,de
	jr	Brk
Up:	ld	hl,EndColor
	dsbc	d
Brk:	ex de,hl
	pop	hl
	ld	c,(hl)		;number of lines
	inc	hl
	ex af,af'
	ld	a,(hl)		;get width
	inc	hl
	ex af,af'
	or	a		;test flipped=nz
Normal: ld	a,(hl)		;get color
	inc	hl
	push	hl		;new return address
	ex de,hl
	jr nz,	Fli
	ld	de,32		;# of bytes = x width
..y:	ex af,af'
	ld	b,a		;put copy of width in b
	ex af,af'
	push	hl
..x:	ld	(hl),a		;put color into ram
	inc	hl
	djnz	..x
	pop	hl
	add	hl,de		;goto next line down
	dec	c
	jr nz,	..y
	ret
Fli: ld	de,-32		;# of bytes = x
..y:	ex af,af'
	ld	b,a		;put copy of width in b
	ex af,af'
	push	hl
..x:	ld	(hl),a		;put color into ram
	dec	hl
	djnz	..x
	pop	hl
	add	hl,de		;goto next line down
	dec	c
	jr nz,	..y
	ret
;
; color walls of room
;
C.WALLS:
	LINES	208,224,077H
	call	C.INFO
	ld	hl,R.table	;percentage table
	ld	bc,RE.len	;length of robot table entry
	ld	a,(RoomCnt)		;total rooms travelled
	ex af,af'
R.loop: ex af,af'
	cp	(hl)
	jr c,	R.set
	ex af,af'
	add	hl,bc
	ld	a,(hl)
	or	a
	jr nz,	R.loop
; HL -> number of rooms to be travelled before using this mode
;	# of robot bolts,wait,robot color,wall color
R.set:	inc	hl
	ld	a,(hl)		;set total number of robot bolts
	inc	hl
	ld (Rbolts),a
	ld	a,(hl)		;set recharge time
	inc	hl
	ld (Rwait),a
	ld	a,(hl)		;robot color
	inc	hl
	ld	c,a
	ld (Rcolor),a
	ld	a,(hl)
	inc	hl
	ld	(Dcolor),a		;set Dotted wall color
	ld	a,(hl)
	inc	hl
	ld	(Wcolor),a		;set wall color
	ld	a,(hl)
	ld	(Wpoint),a		;#point for wall hit
;now go color walls C=robot color
	ld	a,(Flip)
	or	a
	ld	hl,ColorScreen
	ld	ix,ScreenRAM
	jr z,	Ok
	ld	hl,ColorScreen+4*32
	ld	ix,ScreenRAM+16*Hsize
Ok:	ld	a,208/4		;number of lines of room
..y:	ex af,af'
	ld	B,Hsize
..x:	ld	a,(ix+0)		;get screen
	xor	(ix+Hsize)
	or	(ix+Hsize)
;nibble results 0=no wall, 9=cross, others=reflecto
	ld	d,a		;save
	and	0fh		;isolate lower nibble
	jr nz,	..lr
	ld	a,c
	jr	..LOW	
..lr:	cp	0fh
	jr nz,	..gry
	xor	(ix+0)
	and	0fh
	jr nz,	..c1
	ld	a,(Dcolor)
	jr	..LOW
..c1:	cp	0Fh
	jr z,	..gry
	ld	a,(Wcolor)		;get wall color
	jr	..LOW
..gry:	ld	a,WHITE
..LOW:	and	0fh
	ld	e,a		;save lower
	ld	a,d		;get top nibble
	and	0f0h		;isolate lower nibble
	jr nz,	..tr
	ld	a,c
	jr	..top	
..tr:	cp	0f0h
	jr nz,	..tig
	xor	(ix+0)
	and	0f0h
	jr nz,	..c2
	ld	a,(Dcolor)
	jr	..top
..c2:	cp	0F0h
	jr z,	..tig
	ld	a,(Wcolor)		;get wall color
	jr	..top
..tig:	ld	a,WHITE
..TOP:	and	0F0h
	or	e		;or in lower
	ld	(hl),A		;write to colorRAM
	inc	hl
	inc	ixx
	djnz	..x
	ld	de,Hsize*3
	add	ix,de
	ex af,af'
	dec	a
	jr nz,	..y
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~
; un-color man as he moves
;___________________________
UNCMAN::
	ld	hl,VECTORS
	bit	BLANK,(hl)
	ret z
	res	BLANK,(hl)
;restore old area of man
	ld	hl,(Caddr)
	ld	de,Csave		;save area
	ld	bc,Hsize-1	;move to next line
	ld	a,5		;is 5 x 4 high
..Ylp:	ex af,af'
	ld	a,(de)		;get old
	inc	de		;->next
	ld	(hl),a		;store back to color ram
	inc	hl		;->next door loc
	ld	a,(de)		;get another old one
	inc	de		;->next old line
	ld	(hl),a		;store to color ram
	add	hl,bc		;->next line down in color ram
	ex af,af'			;get counter
	dec	a		;one less y line to do
	jr nz,	..Ylp
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; color man as he moves
;_______________________________
COLMAN::
	SET	BLANK,(hl)
	ld	de,P.X		;get to px
	add	hl,de		;->p.x.h
	ld	e,(hl)		;x position
	inc	hl		;->v.y
	inc	hl		;->p.y
	ld	a,(Flip)
	or	a		;test for flip screen
	ld	a,(hl)		;y position
	jr z,	..ok
	neg
	add	a,208		;index screen
	ex af,af'
	ld	a,247
	sub	e
	ld	e,a
	ex af,af'
..ok:	srl	A
	srl	A
	ld	h,a
	ld	l,e
	srl	H
	rr	L
	srl	H
	rr	L
	srl	H
	rr	L
	ld	bc,ColorScreen
	add	hl,bc
; save/write box to screen
	ld	(Caddr),hl		;save address of box
	ld	a,(Mcolor)		;get player color
	ld	c,a		;save new color
	ld	de,Csave
	ld	a,5		;number of bytes high
..Ylp:	ex af,af'
	ld	a,(hl)		;get current data
	ld	(de),a		;save
	inc	de
	ld	(hl),c		;write new color
	inc	hl
	ld	a,(hl)		;get current data
	ld	(de),a		;save
	inc	de
	ld	(hl),c		;write new color
	ld	a,c		;save color
	ld	bc,Hsize-1
	add	hl,bc		;->next line
	ld	c,a		;restore color
	ex af,af'
	dec	a
	jr nz,	..Ylp
	ld	hl,(V.PTR)
	ret

;THIS SHOULD BE IN PLAY
; Robot Initializer Table
;		xx99xx,#	,0 or 1,bolt holdoff,color
.define RE[Room,Bolts,Wait,RCol,Dcol,Walls,Wp]=[
	.byte	Room,Bolts,Wait
	.byte	RCol,Dcol,Walls,Wp
]
;
BR=Bright
R.table: RE	01,0,90,Yellow,		Blue,	Purple,1
RE.len	== .-R.table
	RE	03,1,90,BR+Red,		Blue,	Purple, 1
	RE	05,2,75,Cyan,		Blue,	Purple, 1
	RE	07,3,60,BR+Green,	Yellow, BR+Red, 2
	RE	09,4,45,BR+Blue,	Yellow, BR+Red, 2
	RE	15,5,40,Purple,		Yellow, BR+Red, 2
	RE	16,3,25,BR+Green,	Purple, Blue,	3
	RE	17,4,20,Blue,		Yellow, Green,	4
	RE	21,5,15,Purple,		Yellow, Green,	4
	RE	23,5,45,BR+PURPLE,	Blue,	White,	4
	RE	24,2,15,Cyan,		Blue,	Green,	4
	RE	25,3,10,BR+Green,	Yellow, Blue,	3
	RE	27,4,05,Blue,		Purple, BR+Red, 2
	RE	30,5,05,Purple,		Cyan,	BR+Red, 2
	RE	00,5,05,Yellow,		Blue,	Cyan,	5

	.end

