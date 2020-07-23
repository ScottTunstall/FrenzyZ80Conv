B>type robot.asm

.title	"MOVE ROBOTS"
.sbttl	"FRENZY"
.ident	ROBOT
;-------------+
; robot mover |
;-------------+
.insert equs
.intern SETPAT
.extern SHOWO,V.ZERO,SHOWA,R.9D,J.WAIT,NEXT.J,ADDS,SETVXY
.extern R.9,D.TAB,SHOOT,IQ,RANDOM
;------------+
; initialize |
;------------+
;minwait=	40	;2/22/82
MinWait=	30		;Harder 3/12/82
FROBOT::call	V.ZERO		;get vector
	JC	JobDel#		;if non leave
	ldar
	rrc
	jr c,	..2
	call	F1.TALK#
	jr	..1
..2:	call	F2.TALK#
..1:	ld	P.X(x),146	;start pos
	ld	P.Y(x),104
	ld	hl,R.LAY#
	ld	D.P.L(x),l
	ld	D.P.H(x),h
	ld	c,0
	jr	RGO
ROBOT::
	call	V.ZERO		;get vector
	JC	JobDel#		;if non leave
	ld	hl,Robots
	inc	(hl)		;inc number of robots
	ld	a,(hl)
	ld	(Rsaved),a		;save number of robots
	ldar
	and	1
	jr nz,	SKEL#
; find a spot to put me
	call	InitPosition
	xor	a		;stop mode
	ld	c,-1		;force on
	call	SETPAT		; set up vector
RGO:	ld	TPRIME(x),2	;standard wait time
	ld	TIME(x),1	;update
	ld	V.STAT(x),86h	;write|move
	call	GetTimer#
	ld a,	Rwait		;initial hold off
	cp	MinWait
	jr nc,	..1		;safety 1st
	ld	a,MinWait	;minimum wait
; initial wait period hl->timer
..1:	ld	b,a
	call	RANDOM		;slight randomness in
	and	0F8h		;wake-up time
	rrc
	rrc
	rrc
	add	a,b
	ld	(hl),a
..wlp:	call	NEXT.J
	bit	INEPT,V.STAT(x)
	jr nz,	..blam
	ld	a,(hl)
	or	a
	jr nz,	..wlp
..blam:
	ld	c,0		;set tracker=stop
;-----------------+
; robots job loop |
;-----------------+
; ix->vector
; hl->timer
SEEK:	lxi	y,Vectors	;mans vector
	push	bc		;save tracker
; test if anything happened first??
	ld	a,P.X(y)	;man x
	sub	P.X(x)		;robot x
	ld	d,a		;save delta x
;calc x index
	ld	bc,0		;0 velocity in x
	jr z,	..dx
	ld	B,1		;-	"	in x
	jr c,	..dx
	ld	B,2		;+	"	in x
..dx:	ld	a,P.Y(y)	;man y
	add	a,2
	sub	P.Y(x)		;robot y
	ld	e,a		;save delta y
;calc y index
	jr z,	..dy
	ld	c,4		;-	"	in y
	jr c,	..dy
	ld	c,8		;+	"	in y
..dy:	ld	a,b		;add offsets
	add	a,c		;to from direction
	pop	bc		;restore tracker
	call	SHOOT		;need hl->timer
	call	SETPAT		;does IQ
	call	NEXT.J
R.RET:: bit	INEPT,V.STAT(x)
	jz	SEEK
	jr	BLAM
;-----------------------------+
; change direction of robot
;	a=data, c=tracker [0=stop]
;-----------------------------+
SETPAT: push	hl
	ld	hl,IqFlg
	bit	1,(hl)		;stop moving
	jr z,	..1
	xor	a
	jr	..2
..1:	and	0Fh		;check for no moving
	jr z,	..2
	bit	0,(hl)		;no iq
	cz	IQ		;then check walls returns a
..2:	cp	c		;if tracker and new direction
	jr z,	..exit		;are the same then return
	ld	c,a		;update tracker
	call	SETVXY
	ld	hl,P.TAB		;index pattern table
	add	hl,de		;returned from setvxy
	ld	a,(hl)		;get pattern address
	inc	hl
	ld	h,(hl)
	di
	ld	D.P.L(x),A	;set pattern
	ld	D.P.H(x),H
	ei
..exit: pop	hl
	ret
;--------------+
; blow up time |
;--------------+
BLAM::	call	FreeTimer#
	push	x		;->vector
	call	SBLAM#
	pop	hl		;->vector
	ld	de,V.X		;hl=>v.x
	add	hl,de
	di
	ld	(hl),d		;d=0 v.x
	inc	hl		;->p.x
	ld	a,(hl)
	sub	4		;offset blast pattern
	ld	(hl),a
	inc	hl		;->v.y
	ld	(hl),d		;d=0
	inc	hl		;->p.y
	ld	a,(hl)		;get position
	sub	6		;offset for large blast
	ld	(hl),a
	inc	hl		;->d.p.l
	ld	bc,R.9		;blast pattern
	ld	(hl),c
	inc	hl
	ld	(hl),b
	ei
	ld	TIME(x),1
	ld	TPRIME(x),1
	push	x		;->vector
	ld	bc,105H		;50
	call	ADDS
	ld	hl,Robots	;score bonus
	ld	a,(hl)
	or	a
	jz	XXX
	dec	(hl)		;one less robot
	ld	(STIME),a		;new robot hold off
	jr nz,	XXX		;if all killed then
	ld a,	Rsaved		;get original number of robots
SCLOP:	push	af
	ld	bc,101H		;score 10 for each killed
	call	ADDS
	pop	af
	dec	a
	jr nz,	SCLOP
; write bonus
	call	SHOWA
	.byte	0,96,213
	.asciz	"BONUS"
; show how much
	push	af
	ld a,	Rsaved
	ld	b,a		;convert to BCD
	xor	a		;0
..:	add	a,1		;+1
	daa			;adjust
	djnz	..		;for number of robots
	rrc
	rrc
	rrc
	rrc
	ld	l,a
	and	0F0H
	ld	h,a
	ld	a,0FH
	and	l
	ld	l,a
	pop	af
	push	hl		;put number on stack
	ld	hl,0
	add	hl,sp		;->number on stack
	ex af,af'
	ld	B,4
	call	SHOWO
	pop	hl		;remove number from stack
XXX:	pop	x
	WAIT	30
..test: ld	hl,R.9D
	ld	a,O.P.L(x)	;see if on last pattern
	cp	l
	jr nz,	..no
	ld	a,O.P.H(x)
	cp	h
	jr z,	..done
..no:	call	NEXT.J
	jr	..test
..done: ld	V.STAT(x),0	;free vector
	jp	JobDel		;delete job
;~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Find a spot for this robot to start
;___________________________
InitPosition::
	call	RANDOM
..sl:	sub	24
	jr nc,	..sl
	add	a,24
	ld	b,0
	ld	c,a
	ld	hl,Walls
	add	hl,bc		;->walls array
	ld	a,(hl)		;test if in use,exit or man
	and	0F0h		;non wall bits
	jr z,	..use
	ld	a,c
	inc	a
	jr	..sl
; fix up faster with linear probe?
..use:	set	InUse,(hl)		;save our square
	ld	hl,R.Tab		;->starting squares
	add	hl,bc
	add	hl,bc
	ld	d,(hl)		;get x position
	inc	hl
	ld	e,(hl)
	call	Rand27
	add	a,d
	ld	P.X(x),a	;set position
	call	Rand27
	add	a,e
	ld	P.Y(x),a
	ret
Rand27: push	de
	call	RANDOM
	pop	de
..:	sub	26
	jr nc,	..
	add	a,26
	ret
;--------------------------------
; ROBOT starting position table
X1	==	12
X2	==	X1+(40*1)
X3	==	X1+(40*2)
X4	==	X1+(40*3)
X5	==	X1+(40*4)
X6	==	X1+(40*5)
Y1	==	8
Y2	==	Y1+(48*1)
Y3	==	Y1+(48*2)
Y4	==	Y1+(48*3)
R.TAB:	.byte	X1,Y1
	.byte	X2,Y1
	.byte	X3,Y1
	.byte	X4,Y1
	.byte	X5,Y1
	.byte	X6,Y1

	.byte	X1,Y2
	.byte	X2,Y2
	.byte	X3,Y2
	.byte	X4,Y2
	.byte	X5,Y2
	.byte	X6,Y2

	.byte	X1,Y3
	.byte	X2,Y3
	.byte	X3,Y3
	.byte	X4,Y3
	.byte	X5,Y3
	.byte	X6,Y3

	.byte	X1,Y4
	.byte	X2,Y4
	.byte	X3,Y4
	.byte	X4,Y4
	.byte	X5,Y4
	.byte	X6,Y4
;----------------
; pattern table
;
.define PAT[P1]=[
.extern P1
	.word	P1]

P.TAB:	PAT	R.0
	PAT	R.1
	PAT	R.2
	PAT	R.3
	PAT	R.4
	PAT	R.5
	PAT	R.6
	PAT	R.7
	PAT	R.8

BYTE3:: .byte	0

	.end

