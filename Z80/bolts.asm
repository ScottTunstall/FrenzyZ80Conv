B>type bolts.asm

.title	"PLASMA BOLTS"
.sbttl	"FRENZY"
.ident	BOLTS
.insert equs
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Bolt Data Structure
;	bit number
; +---7-+---6-+---5-+---4-+---3-+---2-+---1-+---0-+
; |down | up  |right| left|	Length of	  |	VX.VY
; | v	| ^   | >   | <	  |	Bolt 1-6	  |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; BUL1:
;	---- VX.VY	[DURL in top,length in bottom]
;	---- PX		[position in x]
;	---- PY		[ "	in y]
;	 .
;	 :
;	---- oldX	[Old positions *6]
;	---- oldY
;------------------------
;	Equates
VX.VY	==	0		; byte offsets to bolt contents
PX	==	1
PY	==	2
LEFT	==	0		; direction bit numbers
RIGHT	==	1
UP	==	2
DOWN	==	3
GREY	==	77H		;mirror color
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Do all bolts
;_______________________________
BUL.V:: exx
	push	bc		;set up wall color in alt set
	ld	a,(Wcolor)
	ld	b,a		;save
	and	0F0H		;hi nib in C
	ld	c,a
	ld	a,b		;lo nib in b
	and	0Fh
	ld	b,a
	exx
	ld	B,2		;# man's bolts
	call	BOLT		;do 2 bolts
	ld	B,2		;# man's bolts
	call	BOLT		;do 2 bolts
	ld	b,BOLTS		;do all bolts
	call	BOLT
	exx
	pop	bc
	exx
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vector (B) Bolts
;_______________________________
BOLT:	ld	hl,BUL1		;-> at 1st bolt
B.LOP:	push	bc		;save counter
	push	hl		;save pointer
	call	VEC.B		;erase/write a single bolt
	pop	hl		;restore pointer
	pop	bc		;restore counter
	ld	de,Blength	;point at next bolt
	add	hl,de
	djnz	B.LOP		;do for B bolts
	ret
.page
.sbttl	/Erase Bolts/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Vector Bolts
;_______________________________
; HL->bolt top
VEC.B:
	ld	a,(hl)		;vx.vy
	push	af		;save vxy.len
	and	0Fh		;isolate length
	jr nz,	..cont
	pop	af
	RET
; ERASE Oldest position
..cont:
	ld	bc,PX
	add	hl,bc		;->PX
	add	a		;double length
	ld	c,a		;bc=length*2
	add	hl,bc		;->oldestX
	ld	e,(hl)		;oldX
	inc	hl		;oldestY
	ld	d,(hl)		;oldY
	ex de,hl
	ld	a,l
	or	h		;no write if 0
	jr z,	..skip
;BC=Length, DE->OldestY, HL=YX
	call	RELX		;convert to screen coords
	ld	(hl),80h		;write dot
..skip:
	pop	af		;restore vxy.len
	and	0F0h		;check if still writing
	jr nz,	..ok
	ld	hl,-1
	add	hl,de
	sbc	hl,bc		;->vxy.len
	dec	(hl)		;one less in length
	RET
; Move array of old positions down
..ok:	ld	h,d
	ld	l,e		;->oldestY
	dec	hl
	dec	hl		;->previous
	LDDR			;move down
	inc	hl		;->px
; Update coords & WRITE DOT
; A=Vxy&F0, BC=0, DE->newest, HL->PX
	rrc			;do table jump
	rrc
	rrc
	ld	c,a		;bc=offset (DURL*2)
	ex de,hl			;de->px
	ld	hl,JTable	;look up vectoring
	add	hl,bc		;add offset
	ld	a,(hl)		;routine in table
	inc	hl		;and jump to it
	ld	h,(hl)
	ld	l,a
	ex de,hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;bc=YX
	ex de,hl
	jp (hl)			;jump
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Update Coords
;_______________________________
JTable: .word	Rstop	;0
	.word	RLeft	;1
	.word	RRight	;2
	.word	Rstop	;3
	.word	RUp	;4
	.word	RUL	;5
	.word	RUR	;6
	.word	Rstop	;7
	.word	RDown	;8
	.word	RDL	;9
	.word	RDR	;10
	.word	Rstop	;11
	.word	Rstop	;12
	.word	Rstop	;13
	.word	Rstop	;14
	.word	Rstop	;15
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; all these routines get as input
; BC=pYpX, de->pY, hl=label address
;_______________________________
Rstop:	ex de,hl			;hl->py
Stop:	xor	a		;0
	ld	(hl),a		;py=0
	dec	hl		;->px
	ld	(hl),a		;px=0
	dec	hl		;->vxy.len
	ld	a,(hl)		;get vxy.len
	and	0Fh		;leave length
	ld	(hl),a		;stop bolt
	RET
;set to 4 to protect outer walls
wallo	==	0
.define ULIMIT=[ld	a,b
	cp	4+wallo		;;check limit
	jr c,	STOP
]
.define DLIMIT=[ld	a,b
	cp	200-wallo
	jr nc,	STOP
]
.define RLIMIT=[ld	a,c
	cp	252-wallo
	jr nc,	STOP
]
.define LLIMIT=[ld	a,c
	cp	8+wallo
	jr c,	STOP
]

RUp:	ex de,hl			; hl->py de=YX
	dec	b		;y--
	ULIMIT
	jp	Writ

RDown:	ex de,hl
	inc	b		;y++
	DLIMIT
	jp	Writ

RRight: ex de,hl
	inc	c		;x++
	RLIMIT
	jp	Writ

RLeft:	ex de,hl
	dec	c		;x--
	LLIMIT
	jp	Writ

RUL:	ex de,hl
	dec	c		;x--
	dec	b		;y--
	ULIMIT
	LLIMIT
	jp	Writ

RUR:	ex de,hl
	inc	c		;x++
	dec	b		;y--
	ULIMIT
	RLIMIT
	jp	Writ

RDL:	ex de,hl
	dec	c		;x--
	inc	b		;y++
	DLIMIT
	LLIMIT
	jp	Writ

RDR:	ex de,hl
	inc	c		;x++
	inc	b		;y++
	DLIMIT
	RLIMIT
	jp	Writ
.sbttl	/Write Dots/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Write the Dot
;_______________________________
; hl->py,bc=YX
Writ:	ld	(hl),b		;update py
	dec	hl		;->px
	ld	(hl),c		;update px
	ex de,hl			;de->px, hl?
	ld	h,b		;get pY
	ld	l,c		;pX
	call	RELX		;convert to screen addr
	ld	(hl),80h		;write the dot
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Check for intercepts
;_______________________________
;BC=yx,DE->px, hl->screen
	in	WHATI
	rlc
	ret nc
; Erase dot
	ld	(hl),80h		;erase the dot
	ld	(Temp),hl		;save address for reflect
	dec	de		;->vxy.len
; Hit Check by looking at the color bolt hit
	push	bc		;save YX
	srl	B		;index the 4x4 box
	srl	B		;y/2
	srl	B		;YX/8
	rr	c
	srl	B
	rr	c
	srl	B
	rr	c		;carry=Low nibble
	ex af,af'
	ld	a,(Flip)		;test cocktail
	or	a
	jp z,	..norm
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
..tt:	jc	LoNib
; Check hi nibble
	ld	a,(hl)		;get 2 color boxes
	and	0f0h		;isolate left one
	cp	GREY&0f0h	;gry=mirror
	jp z,	REFLECT
	exx
	cp	c		;hi nib wall color	
	exx
	jp z,	WALLHIT
;must have hit another bolt or object
	jp	HITCHK
; Check Lo Nibble
LoNib:
	ld	a,(hl)		;add box offset
	and	0fh		;isolate right one
	cp	GREY&0fh	;gry=mirror
	jp z,	REFLECT
	exx
	cp	b		;lo nib wall color
	exx
	jp z,	WALLHIT
;must have hit another bolt or object
	jp	HITCHK
.sbttl	/Reflect the bolt/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Reflect the bolt
;_______________________________
;BC=yx, DE->vxy.len
REFLECT:
	ld	a,(de)		;get vxy
	and	0C0h		;check for any up/down
	jr z,	..Ve		;right/left hit only verticals
	ld	hl,(Temp)		;get magic address
	res	5,h		;convert to normal
	ld	a,(hl)		;get pixels of wall
	ld	h,90h		;left nibble test
	bit	2,C		;if ((x.mod.8)<4)
	jr z,	..test		; then left nibble
	ld	h,09h		;right nibble test
..test: ex af,af'			;save pixels
	ld	a,(Flip)
	or	a
	jp z,	..on
	ld	a,99h
	xor	h
	ld	h,a
..on:	ex af,af'			;restore pixels
	and	h		;look for non 60(vertical)
	jr nz,	..Ho
..Ve:	ld	bc,VerTab	;vertical table
	jp	..Go
..Ho:	ld	bc,HorTab	;horizontal table
;bc=table de->vxy,hl->screen
..Go:	ld	a,(de)		;get vxy
	and	0f0h
	rrc
	rrc			;vxy*4
	ld	l,a
	ld	h,0
	add	hl,bc		;->RefTab[vxy]
	ld	a,(de)		;->vxy.length
	and	0fh		;keep length
	or	(hl)		;new vxy
	ld	(de),a		;update vxy.len
	inc	de		;->px
	inc	hl		;->offset x
	ld	a,(de)		;get px
	add	(hl)		;add offset
	ld	c,a		;save new x
	ld	(de),a		;update px
	inc	de		;->py
	inc	hl		;->offset y
	ld	a,(de)		;get py
	add	(hl)		;add offset
	ld	b,a		;save new y
	ld	(de),a		;update py
;now write the new dot
	ld	h,b		;pY
	ld	l,c		;pX
	call	RELX
	ld	(hl),80h		;write the new head
	ld	(RFSND),a		;make ping sound
	RET

.define RE[vxy,xoffset,yoffset]=
[	.byte	vxy<4,xoffset,yoffset,0
]
VerTab: RE	0,0,0		;0 stoped
	RE	2,1,-4		;1 Left
	RE	1,-1,-4		;2 Right
	RE	0,0,0		;3
	RE	8,3,1		;4 Up-stop
	RE	6,1,-1		;5 UL->ur
	RE	5,-1,-1		;6 UR->ul
	RE	0,0,0		;7
	RE	4,3,-1		;8 Down-stop
	RE	10,1,1		;9 DL->dr
	RE	9,-1,1		;10 DR->dl
	RE	0,0,0		;11
	RE	0,0,0		;12
	RE	0,0,0		;13
	RE	0,0,0		;14
	RE	0,0,0		;15
; the horizontal version
HorTab: RE	0,0,0		;0 stoped
	RE	2,1,-4		;1 Left stop
	RE	1,-1,-4		;2 Right stop
	RE	0,0,0		;3
	RE	8,4,1		;4 Up
	RE	9,-1,1		;5 UL->dl
	RE	10,1,1		;6 UR->dr
	RE	0,0,0		;7
	RE	4,4,-1		;8 Down
	RE	5,-1,-1		;9 DL->ul
	RE	6,1,-1		;10 DR->ur
	RE	0,0,0		;11
	RE	0,0,0		;12
	RE	0,0,0		;13
	RE	0,0,0		;14
	RE	0,0,0		;15
.page
.sbttl	/Hit a Wall routine/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Blast the Wall
;_______________________________
;BC=yx, DE->vxy, hl->color
WallHit:
	ld	a,(de)		;get vxy
	and	0fh		;stop the vxy
	ld	(de),a		;store 0.len
	xor	a		;0
	inc	de		;->px
	ld	(de),a		;px=0
	inc	de		;->py
	ld	(de),a		;py=0 (finished with DE)
; change color box to robot color
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
	ld	a,(Rcolor)		;get robot color
	and	e		;isolate nibble
	or	d		;combine nibbles
	ld	(hl),a		;store new color
;index the box's pixels = (Y&!3) (X&!3)
	ld	a,b		;pY
	and	#3		;move to nearest multiple of 4
	ld	h,a
	ld	a,c		;pX
	and	#3
	ld	l,a
	call	RELAnd
	ex de,hl
	ld	hl,WallPts	;add 1 pt
	ld	a,(hl)		;for hitting wall
	add	a,1
	daa
	ld	(hl),a
	ld	(WLSND),a		;make sound
	ld	hl,Cross
	jp	Plot#
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Special Relative to Absolute
;_______________________________
;save all but hl,af
;HL=YX
RELAnd::
RELX:	push	bc
	ld	B,90H		;xor write
	call	RtoA#
	pop	bc
	ret
.page
.sbttl	/Hit Check for objects/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Find Out What Got hit
;_______________________________
; BC=YX,de->vxy
HITCHK:
	ld	a,(de)		;get vxy
	and	0fh		;stop it
	ld	(de),a		;store 0,len
	ld	a,MaxVec	;number of vectors to check
	ld	ix,Vectors	;->first vector
..LOOP:
	ex af,af'			;save count
	bit	Move,(ix+V.STAT)	;check if moving
	jp z,	..next
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check Vector[ix] Against Bolt
;_______________________________
;NOTE: should mans bolt kill him?
;ix->object, BC=YX, a'=counter
	ld	a,c		;bolt X
	sub	(ix+P.X)		;object Y
	inc	a
;	ld	c,a		;save it
	jr m,	..next		;outside on left?
	cp	10		;max width
	jr nc,	..next		;ok in x
	ld	a,b		;now do y
	sub	(ix+P.Y)
	inc	a
	jr m,	..next
	cp	30
	jr nc	..next
;check with real pattern size
	ld	h,(ix+D.P.H)	;get pattern pointer
	ld	l,(ix+D.P.L)
	ld	e,(hl)		;get address of pattern
	inc	hl
	ld	d,(hl)
	ex de,hl			;hl->pattern
	ld	e,(hl)		;get width in bytes of pattern
	inc	hl
	ld	d,(hl)		;get height
	bit	7,d		;check for DROP
	jp z,	..ok
	ex de,hl			;special for otto drop
	add	hl,hl
	add	hl,hl
	add	hl,hl		;drop/32
	sub	h		;adjust delta Y
	ex de,hl
	inc	hl		;now get real Y height
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
..ok:	inc	d		;adjust for 1 higher in Y
	inc	d
; now check if bolt y is in pattern
	cp	d		;a still y delta
	jr nc	..next
;now x NOT NEEDED ALL ARE 8 WIDE
;	ld	a,c		;restore delta
;	sub	(ix+P.X)
;	sla	e		;multiply X.size**NEW
;	sla	e		;by 8 cuz of 8 bits to byte
;	sla	e		;of pattern
;	inc	e		;add one for slop
;	cp	e		;is in past right side?
;	jr nc,	..next
; hit this vector, so set his inept bit
	set	Hit,(ix+V.STAT)
	set	INEPT,(ix+V.STAT) ;cause an explosion
	RET			;leave loop
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	End of Loop
;_______________________________
..next: ld	de,VLEN		;distance to
	add	ix,de		;next vector
..exit: ex af,af'			;get counter
	dec	a		;any more vectors left?
	jr nz,	..LOOP		;if not,go check this one
	ret			;go do another bolt

; Pattern of wall
Cross:	.byte	1,4
	.byte	060h,0f0h,0f0h,060h

	.end
