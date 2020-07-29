B>type shoot.asm

.title	"SHOOT AT MAN"
.sbttl	"FRENZY"
.ident SHOOT
;---------------------------------------
; if (a bolt is available) then
; if (it is possible to shoot at the man)
;	Shoot;
;---------------------------------------
.insert equs
.extern D.TAB,SETPAT,NEXT.J
; a=DURL to man
; hl->timer
SHOOT::
	push	hl		;timer
	push	bc		;tracker
	push	af		;DURL
	ld	c,a		;save DURL
	ld	a,(hl)		;check timer
	or	a
	jr nz,	..exit
	ld	a,(IqFlg)
	bit	2,a
	jr nz,	..exit
; check if bolt available
	ld	a,(RBolts)		;check if shooting
	or	a
	jr z,	..exit
	ld	b,a		;number of bolts useable
	ld	hl,BUL1+(2*Blength)	;check 3rd bolt on
	push	de
	ld	de,Blength	;delta to next bolt
..lp:	ld	a,(hl)		;check vx.vy=0
	or	a
	jr z,	..OK		;have a bolt
	add	hl,de
	djnz	..lp
	pop	de
..exit: pop	af
	pop	bc
	pop	hl		;timer
	ret			;no bolt
; Have Bolt Will Shoot
..OK:	pop	de
;HL now points at bullet to use
;now check if man is up or down from you
	ld	a,d		;d=delta x
	cp	-2
	jr nc	FIREY		;out of range
	cp	8
	jr c,	FIREY
;check for a left or right shot
	ld	a,e		;e=delta y
	cp	-10
	jr nc,	FIREX
	cp	5
	jr c,	FIREX
;check for a diagonal shot
	ld	a,d		;abs[delta x]
	bit	0,C		;bit left
	jr z,	..dox
	neg
	ld	d,a
..dox:	ld	a,e		;abs[delta y]
	bit	2,C		;bit up
	jr z,	..doy
	neg
	ld	e,a
..doy:	sub	d		;if (|dX|-|dY|)
	cp	-10		;is in range then shoot
	jr nc,	FIRE
	cp	6
	jr nc,	..exit
	jr	FIRE
;make shot go horizontal
FIREX:	ld	a,c
	and	3
	ld	c,a
	jr	FIRE
;make vertical shot
FIREY:	ld	a,c
	and	0CH
	ld	c,a
	jr	FIRE
;---------------------------------------
; set up robot and bolt
;---------------------------------------
;hl->bolt,c=direction(DURL)
FIRE:
	push	hl		;save bolt pointer
; zero the whole bolt
	ld	b,Blength
	xor	a
..zap:	ld	(hl),a
	inc	hl
	djnz	..zap		;b=0
	call	SRFIRE#		;make noise
	ld	hl,D.TAB		;translate DURL to clock
	add	hl,bc		;b=0,c=durl
	ld	c,(hl)		;direction offset
	ld	hl,S.TAB
	add	hl,bc		;entry 2
	add	hl,bc		;4
	add	hl,bc		;6
	ld	(ix+V.X),B	;b=0
	ld	(ix+V.Y),B	;robot stops moving
	ld	a,(hl)		;get pattern address
	inc	hl
	di
	ld	(ix+D.P.L),A
	ld	a,(hl)
	ld	(ix+D.P.H),A
	ei
	inc	hl
	ld	(ix+TIME),1	;make it write
	ld	b,(hl)		;xoffset
	inc	hl
	ld	c,(hl)		;yoffset
	inc	hl
	ld	d,(hl)		;vx.vy
	ld	a,(ix+P.X)	;calc offset from robot
	add	a,B
	ld	b,a
	ld	a,(ix+P.Y)	;same for y
	add	a,C
	ld	c,a
	pop	hl		;-> bolt
	ld	a,d
	or	3		;length of bolt
	di
	ld	(hl),a		;vx.vy
	inc	hl
	ld	(hl),b		;xposition
	inc	hl
	ld	(hl),c		;yposition
	inc	hl		;repeat for tail
	ld	(hl),b		;xposition
	inc	hl
	ld	(hl),c		;yposition
	ei
	pop	af		;durl
	pop	bc		;tracker
	pop	hl		;timer
	ld	(hl),10
..wlp:	call	NEXT.J
	bit	INEPT,(ix+V.STAT)
	jr nz,	..sk
	ld	a,(hl)
	or	a
	jr nz,	..wlp
..sk:
; wait is lesser of (Robots*4)+5 or (Rwait/2)
; RWait comes into play later in the game
	ld	a,(Robots)		;bolt hold off
	add	a,a
	add	a,a
	add	a,5		;was 10
	ld	c,a		;save this delay
	ld	a,(Rwait)
	srl	A
	cp	c		;compare and use
	jr c,	..t		;lesser delay
	ld	a,c
..t:	ld	(hl),a
	ld	c,10H		;force new setpat
	jp	R.ret#
;
.define SS[Xoffset,Yoffset,Pat,Dir]=[
	.word	Pat
	.byte	Xoffset
	.byte	Yoffset
	.byte	Dir<4
	.byte	0
]
;
; shoot table
;
.extern R.0
S.TAB:	SS	0,0,R.0,0	;0
	SS	7,1,R.0,6	;1ur
	SS	8,2,R.0,2	;2r
	SS	8,4,R.0,10	;3dr
	SS	6,11,R.0,8	;4d
	SS	-1,4,R.0,9	;5dl
	SS	-1,2,R.0,1	;6l
	SS	0,1,R.0,5	;7ul
	SS	6,0,R.0,4	;8u
	.end
