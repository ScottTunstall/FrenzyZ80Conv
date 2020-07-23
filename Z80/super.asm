B>type super.asm

.title	"SUPER-ROBOT"
.sbttl	"FRENZY"
.ident SUPER
;-------------+
; super robot |
;-------------+
.insert EQUS
.intern SETVXY
.extern NEXT.J,J.WAIT,D.TAB,V.ZERO,SR.0
Down=	3
Up=	2
Right=	1
Left=	0
;-------------
; Initialize
;-------------
SUPER::
	xor	a
	ld	(CACKLE+1),a	;otto death flag
	ld hl, (ManX)		;set position
	ld	a,l
	cp	32
	jr nc,	..r
	ld	L,2
	jr	..y
..r:	cp	240
	jr c,	..y
	ld	L,248
..y:	ld	a,h
	cp	180
	jr c,	..t
	ld	H,160
..T:	ld(SSpos),hl
	ld a,	Rsaved		; calc time til start
	ld	b,a
	ld a,	Rwait
	rrc
	rrc
	and	7
	add	a,b
	ld	(STIME),a
	ld	e,0		;speed=1
; wait for stime seconds
..LOOP: WAIT	40
	ld	hl,STIME
	dec	(hl)
	jr nz,	..LOOP
	ld hl,	(SSpos)		;super start pos
	ld	a,30
	ld	(KWait),a
	jr	INIT
;~~~~~~~~~~~~~~~~~~~~~~~
; Moms own SUPER Ottos
;_______________________
;de=yx to start
Klutz:: ld	de,(84<8)!128
MSUPER::
	ex de,hl			;get hl=YX
	ld	de,1		;sportingly fast ottos
; initialize, e=speed
INIT:	push	de
	push	hl
	call	V.ZERO		; zap vector
	pop	hl
	pop	de
	jc	JobDel#		;if none available forget it
	ld	a,e		;if faster speed no talk
	or	a
	jr nz,	REDO		;go fast
	push	de
	push	hl
	call	S.TALK#
	pop	bc
	pop	de
	WAIT	60
	ld	h,b
	ld	l,c		;start position
REDO:	ld	P.X(x),L	;set pos
	ld	P.Y(x),H
	xor	a
	ld	V.X(x),a
	ld	V.Y(x),a
	ld	hl,SR.0
	ld	D.P.L(x),L
	ld	D.P.H(x),H
	ld	TIME(x),1
	ld	TPRIME(x),2	;slower than normal
	ld	d,0		;number of hits taken
	ld	V.STAT(x),(1<InUse)!(1<Move)!(1<Write)
	xor	a
	call	SETDIR
	WAIT	60
	res	HIT,V.STAT(x)
;------------------------+
; super robot's job loop |
;------------------------+
SEEK:	lxi	y,Vectors	; mans vector
	push	de
;calc delta x => e
	ld	a,P.X(y)	;man x
	sub	P.X(x)		;robot x
;calc x index
	ld	B,0		;0 velocity in x
	jr z,	X.D
	ld	B,1<RIGHT	;+ vel in x
	jr nc,	X.D
	ld	B,1<LEFT	;- vel in x
	neg
;calc delta y => d
X.D:	ld	d,a		;save |delta X|
	ld	a,P.Y(y)	;mans Y
	add	e		;drift down with speed
	ld	e,d		;save delta in right place
	sub	1
	cp	175+1
	jc	..ok		;adjust mans x
	ld	a,175
..ok:	sub	P.Y(x)
;calc y index
	ld	c,0		;0 velocity in y
	jr z,	Y.D
	ld	c,1<DOWN	;+ vel in y
	jr nc,	Y.D
	ld	c,1<UP		;- vel in y
	neg
Y.D:	ld	d,a		;save abs(delta Y)
	ld	a,b		;add offsets
	add	a,c		;to from direction
	ld	b,d		;bc=de
	ld	c,e
	pop	de		;speed
	call	SETDIR
	bit	HIT,V.STAT(x)	;check for hits
	jr z,	..wait
	res	HIT,V.STAT(x)	;reset hit bit
	call	SBLAM#		;hit sound
	inc	d		;number of hits taken
	push	de
; set new pattern
	ld	hl,SR.1#
	dec	d
	jp z,	..stdp
	ld	hl,SR.2#
..stdp: ld	D.P.L(x),L
	ld	D.P.H(x),H
	ld	TIME(x),1
	ld	bc,102h		;50pts
	call	ADDS#
	pop	de
	ld	a,d		;check hits
	cp	3		;if 3 then DIE sucker
	jr z,	DIE
..wait: call	NEXT.J
	jr	SEEK
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Otto Deflates
;_______________________________
DIE:	xor	a
	ld	V.X(x),a
	ld	V.Y(x),a
	cpl
	ld	(CACKLE+1),a	;otto death flag
	call	SD.TALK#
	ld	hl,SR.3#
	ld	D.P.L(x),L
	ld	D.P.H(x),H
	ld	TPRIME(x),4	;real slow
	WAIT	60
	ld	V.STAT(x),(1<InUse)!(1<Erase)
	WAIT	10
; start a new otto
	ld	a,e
	cp	7
	jr nc,	..n
	inc	e		;up the speed
..n:	ld hl,	(SSpos)
	jp	REDO
;-----------------------------
; change direction of robot
; a=durl, e=speed
;-----------------------------
SETDIR: and	0FH		; SUPER ROBOTS VERSION
	jr nz,	..nor
	ld	bc,0
	jp	SETV
..nor:	push	bc		;save deltas
	ex af,af'			;save durl
;get speed numbers
	ld	hl,SpeedTab
	ld	B,0
	ld	c,e
	add	hl,bc
	add	hl,bc
	ld	a,(hl)
	ld	TPRIME(x),a
	inc	hl
	ld	a,(hl)		;speed
; now set vel
	pop	bc		;delta yx
	cp	b		;is vy<|delta|
	jr nc,	..sy
	ld	b,a		;save smaller
..sy:	cp	c		;is vx<delta
	jr nc,	..sx
	ld	c,a		;save smaller
..sx:	ex af,af'			;get durl
	bit	up,a
	jr z,	..dx
	ex af,af'
	ld	a,b
	neg			;vel=-vel
	ld	b,a
	ex af,af'
..dx:	bit	left,a
	jr z,	..sv
	ex af,af'
	ld	a,c
	neg			;vel=-vel
	ld	c,a
	ex af,af'
..sv:
SETV:	ld	V.X(x),c
	ld	V.Y(x),b
	ret

; normal robot version
SETVXY: ld	c,a		;update tracker
	ld	B,0
	ld	hl,D.TAB		;convert direction to offset
	add	hl,bc
	ld	e,(hl)		;load offset
	ld	d,b
	ld	hl,M.TAB		;index move table
	add	hl,de
	ld	a,(hl)		;get vx
	ld	V.X(x),a
	inc	hl
	ld	a,(hl)		;get vy
	ld	V.Y(x),a
	ret
;----------------------
;  move table
;  x,y
M.TAB:	.byte	0,0
	.byte	1,-1
	.byte	1,0
	.byte	1,1
	.byte	0,1
	.byte	-1,1
	.byte	-1,0
	.byte	-1,-1
	.byte	0,-1
	.byte	0,0

.define ST[Tprime,Vel]=
[	.byte	Tprime,Vel
]
SpeedTab:
	ST	3,1
	ST	1,1
	ST	1,3
	ST	1,4
	ST	1,6
	ST	1,8
	ST	1,10
	ST	1,12

	.end
