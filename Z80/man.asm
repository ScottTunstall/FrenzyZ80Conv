B>type man.asm

.title	"MOVE MAN"
.sbttl	"FRENZY"
.ident MAN
;~~~~~~~~~~~~
; man mover
;____________
.insert EQUS
.intern V.ZERO,M.INIT,D.TAB
.extern SETVXY,WallIndex,Man.Next
ManP	=	6		;bit number in walls
SHOOT	==	4		;shoot button bit
DOWN	==	3
UP	==	2
RIGHT	==	1
LEFT	==	0
;~~~~~~~~~~~~~
; initialize
;_____________
MAN::	call	M.INIT
	ld	V.STAT(x),(1<InUse)!(1<Color)!(1<Move)!(1<Write)
	ld	bc,-1		;tracker
	call	GetTimer#
	ex de,hl
;~~~~~~~~~~~~~~~~
; mans job loop
;________________
;bc=tracker
;de->timer
;ix->vector
C.LOOP: call	Man.Next
	bit	INEPT,V.STAT(x) ; check if alive
	jr nz,	DEAD
	ld a,	Demo		;check for demo
	or	a
	jr z,	..real
;automatic demo mode
	ld	a,(de)
	or	a
	jr z,	..new
	ld	a,c
	jr	ARGH
..new:	ld hl,	(DemoPtr)
	ld	a,(hl)
	inc	hl
	ld	(DemoPtr),hl
	bit	7,A
	jr z,	..go
	res	7,A
	ld	(de),a		;start timer
	jr	C.LOOP
..real: call	S.STICK#
..go:	bit	SHOOT,A		; if(shoot) fire
	jr nz,	TRY.F
ARGH:	and	0FH		;mask off DURL bits
	call	IQ#
	cp	c		;compare to tracker
	call nz,	CHANGE		;if changed update vector
	jr	C.LOOP
;~~~~~~~~~~~~~~
; try to fire
;______________
TRY.F:	ld	b,a		;save control
	ld	a,(de)		;get timer
	or	a
	jr nz,	..0
	xor	a
	lxi	y,BUL1		;bolt one available?
	or	0(y)		;check Vxy.len
	jr z,	FIRE		;then fire
	lxi	y,BUL1+Blength	;bolt 2 available?
	xor	a
	or	0(y)
	jr z,	FIRE
..0:	ld	a,0
	jr	ARGH		;none available=loop
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	shoot plasma bolt
;_______________________________
FIRE:	ld	a,b		;last control
	and	0FH		; look at direction
	jp z,	C.LOOP		;COULD DEFAULT TO LAST DIR
	push	de		;save ->timer
	call	SFIRE#
	ld	c,a
	ld	B,0		;bc=direction bits DURL
	ld	d,b		;zero d too
	ld	hl,D.TAB		;->direction table
	add	hl,bc		;->offset for direction
	ld	e,(hl)
	ld	hl,SR.TAB	;->shoot table
	add	hl,de		;2 per entry
	add	hl,de		;4
	add	hl,de		;6
	ld	V.X(x),0	;set velocitys to 0
	ld	V.Y(x),0
	ld	a,(hl)		;get shoot animation table
	inc	hl
	di
	ld	D.P.L(x),A
	ld	a,(hl)
	inc	hl
	ld	D.P.H(x),A
	ei
	ld	TIME(x),1
	pop	de		;restore ->timer
	ex de,hl
	ld	(hl),2		;wait for 2 ints
..wt:	call	Man.Next	;wait for pattern to be written
	ld	a,(hl)		;get the timer
	or	a
	jr nz,	..wt
	ex de,hl			;hl->offsets
	push	de		;save ->timer
	ld	b,(hl)		;x offset from man
	inc	hl
	ld	c,(hl)		;y offset from man
	inc	hl
	ld	a,(hl)		;vx.vy for bullet
	or	6		;length of bolt
	ld	d,a		;vxy.len
	ld	a,P.X(x)	;load mans x position
	add	a,b		;add x offset
	ld	e,a		;px
	ld	a,P.Y(x)	;load mans y position
	add	a,c		;add y offset
	ld	c,a		;py
	push	Y
	pop	hl
	ld	b,BLength
	xor	a
..zap:	ld	(hl),a
	inc	hl
	djnz	..zap
	di
	ld	0(y),D		;head vx.vy
	ld	1(y),E		;set px	 py for head
	ld	2(y),C
	ld	3(y),E		;set px	 py for tail
	ld	4(y),C
	ei
	ld	c,00		;set automatic fire
	pop	hl		;->timer
	ld	(hl),4		;wait for exit from gun
..wlp:	call	Man.Next
	ld	a,(hl)		;test timer
	or	a
	jr nz,	..wlp
	ld	(hl),13		;in the timer
	ex de,hl			;put -> back in de
	jp	C.LOOP		;goto control loop
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; change direction of man
;  a=data, c=tracker [0=stop]
;_______________________________
CHANGE: and	0FH
;changed direction and moving
CDIR:	push	de		;save timer->
	call	SetVXY		;updates c:=tracker
	ld	hl,P.TAB
	add	hl,de		;offset calced in setvxy
	ld	a,(hl)		;dpl
	inc	hl
	ld	h,(hl)
	di
	ld	D.P.L(x),A
	ld	D.P.H(x),H
	ei
	pop	de		;restore timer->
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Kill Man job off
;_______________________________
DEAD:	call	SFRY#
	ld	a,10H		;electrocute
	call	CDIR
	ex de,hl
	ld	(hl),150		;electrocution timer
..wlp:	call	Man.Next
	ld a,	Mcolor		;get man color
	add	a,55h		;change for explosion
	or	88h
	ld	(Mcolor),a
	ld	a,(hl)
	or	a
	jr nz,	..wlp
	ld	V.STAT(x),(1<InUse)!(1<BLANK)!(1<ERASE)
..lp:	call	Man.Next
	bit	ERASE,V.STAT(x)
	jr nz,	..lp
	ld	(hl),30
..wt:	call	Man.Next
	ld	a,(hl)
	or	a
	jr nz,	..wt
	ld	V.STAT(x),0	;free the vector
	xor	a
	ld	(Man.Alt),a		;don't do me anymore
..end:	call	Man.Next
	jp	..end		;just in case
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Start a man vector
;_______________________________
M.INIT:
	call	V.ZERO		;ix->vector
; man must be first vector
	ld a,	PLAYER
	cp	1
	ld	a,M1color
	jr z,	..s
	ld	a,M2color
..s:	ld	(Mcolor),a		; set color of man
	ld hl, (ManX)		;gets x and y position
	ld	P.X(x),L	;set x
	ld	P.Y(x),H	;set y
	ld	a,l		;swap h:l
	ld	l,h
	ld	h,a
	call	WallIndex	;see what room # im in
	ex de,hl
	set	ManP,(hl)		;warns robots to stay away
	xor	a		;stand still
	call	CHANGE		;set up vector
	ld	TPRIME(x),1
	ld	TIME(x),1
	ld	a,0aah		;force man to plot
	ld	(IntTyp),a
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; find and zero a vector
;_______________________________
V.ZERO: ld	hl,Vectors	;->vector area
	ld	de,VLEN		;vector length
	ld	b,MaxVec	;# of vectors
..test: bit	InUse,(hl)		;check if in use
	jr z,	..ok
	add	hl,de
	djnz	..test
	scf			;error return
	ret
..ok:	push	hl		;->your new vector
	ld	bc,VLEN		;# of bytes to zero
	call	Zap#		;zero the vector
	pop	x		;save vector pointer in x
	set	InUse,V.STAT(x)
	or	a		;normal return
	ret
;~~~~~~~~~~~~~~~~~~
; direction table
;__________________
D.TAB:	.byte	0		;no move
	.byte	6*2		;left
	.byte	2*2		;right
	.byte	0
	.byte	8*2		;up
	.byte	7*2		;up,left
	.byte	1*2		;up,right
	.byte	8*2		;up default
	.byte	4*2		;down
	.byte	5*2		;down,left
	.byte	3*2		;down,right
	.byte	4*2		;down default
	.byte	0
	.byte	6*2		;left default
	.byte	2*2		;right default
	.byte	0
	.byte	9*2		;explode
;~~~~~~~~~~~~
; move table
;		x ,y ,animation-table
.define PAT[ADDR]=[
.extern ADDR
	.word	ADDR
]
P.TAB:	PAT	M.0
	PAT	M.1
	PAT	M.2
	PAT	M.3
	PAT	M.4
	PAT	M.5
	PAT	M.6
	PAT	M.7
	PAT	M.8
	PAT	M.9
;~~~~~~~~~~~~~~~~~~~~~~
;	Shoot table
;______________________
.define SS[Xo,Yo,Pat,VXY]=[
.extern Pat
	.word	Pat
	.byte	Xo,Yo,VXY<4,0
]
SR.TAB: SS	0,0,MS.0,0
	SS	8,2,MS.1,6
	SS	8,3,MS.2,2
	SS	7,7,MS.3,10
	SS	6,8,MS.4,8
	SS	-1,7,MS.5,9
	SS	-1,3,MS.6,1
	SS	-1,-1,MS.7,5
	SS	7,1,MS.8,4

	.end
