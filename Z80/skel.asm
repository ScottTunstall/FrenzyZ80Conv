B>type skel.asm

.title	"Skeletons"
.sbttl	"FRENZY"
.ident	SKEL
;-------------+
; robot mover |
;-------------+
.insert equs
.extern SHOWO,V.ZERO,SHOWA,R.9D,J.WAIT,NEXT.J,ADDS,SETVXY
.extern R.9,D.TAB,IQ,RANDOM
;------------+
; initialize |
;------------+
;MinWait=	45
MinWait=	35		;harder 3/12/82
SKEL::
;	ld	hl,Robots	;NOW DONE IN ROBOT-3/12/82
;	inc	(hl)		;inc number of robots
;	ld	a,(hl)
;	ld	(Rsaved),a		;save number of robots
;	call	V.ZERO		;get vector
;	JC	JobDel#		;if non leave
; find a spot to put me
	call	InitPosition#
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
	ld	a,MinWait		;minimum wait
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
;------------------
; Skel job loop
;------------------
; ix->vector
; hl->timer
SEEK:	lxi	y,Vectors	;mans vector
	push	bc		;save tracker
; test if anything happened first??
	ld	a,P.X(y)	;man x
	sub	1
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
	push	hl
	and	0FH		;if tracker non-0
	jr z,	..ud
	ld	hl,IqFlg
	bit	1,(hl)		;stop moving
	jr z,	..1
	xor	a
	jr	..ud
..1:	bit	0,(hl)		;no iq
	cz	IQ		;then check walls returns a
	bit	0,a
	jr nz,	..go
	bit	1,a
	jr z,	..ud
..go:	and	3		;go rl first	
..ud:	cp	c		;if tracker and new direction
	pop	hl
	jr z,	..sl		;are the same then return
	ld	c,a		;update tracker
	call	SETPAT		;does IQ
..sl:	call	NEXT.J
R.RET:	bit	INEPT,V.STAT(x)
	jp z,	SEEK
	jp	BLAM#
;-----------------------------+
; change direction of robot
;	a=data, c=tracker [0=stop]
;-----------------------------+
SETPAT: push	hl
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
;----------------
; pattern table
;
P.TAB:	.word	S.0#
	.word	S.2#
	.word	S.2
	.word	S.2
	.word	S.4#
	.word	S.6#
	.word	S.6
	.word	S.6
	.word	S.8#
;---------------------------------------
; if (a bolt is available) then
; if (it is possible to shoot at the man)
;	Shoot;
;---------------------------------------
; a=DURL to man
; hl->timer
SHOOT:
	push	hl		;timer
	push	bc		;tracker
	push	af		;DURL
	ld	c,a		;save DURL
	ld	a,(hl)		;check timer
	or	a
	jr nz,	..exit
	ld a,	IqFlg
	bit	2,a
	jr nz,	..exit
; check if bolt available
	ld a,	Rbolts		;check if shooting
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
	jnc	FIREY		;out of range
	cp	6
	jr c,	FIREY
;check for a left or right shot
	ld	a,e		;e=delta y
	cp	-10
	jr nc,	FIREX
	cp	2
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
	ld	V.X(x),B	;b=0
	ld	V.Y(x),B	;robot stops moving
	ld	a,(hl)		;get pattern address
	inc	hl
	di
	ld	D.P.L(x),A
	ld	a,(hl)
	ld	D.P.H(x),A
	ei
	inc	hl
	ld	TIME(x),1	;make it write
	ld	b,(hl)		;xoffset
	inc	hl
	ld	c,(hl)		;yoffset
	inc	hl
	ld	d,(hl)		;vx.vy
	ld	a,P.X(x)	;calc offset from robot
	add	a,b
	ld	b,a
	ld	a,P.Y(x)	;same for y
	add	a,c
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
	bit	INEPT,V.STAT(x)
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
	ld a,	Rwait
	srl	A
	cp	c		;compare and use
	jr c,	..t		;lesser delay
	ld	a,c
..t:	ld	(hl),a
	ld	c,10H		;force new setpat
	jp	R.ret
;
.define SS[Xoffset,Yoffset,Pat,Dir]=[
	.word	Pat
	.byte	Xoffset
	.byte	Yoffset
	.byte	Dir<4
	.byte	0
]
; shoot table
;
S.TAB:	SS	0,0,S.0,0	;0
	SS	5,0,S.0,6	;1ur
	SS	6,1,S.0,2	;2r
	SS	6,2,S.0,10	;3dr
	SS	6,10,S.0,8	;4d
	SS	0,2,S.0,9	;5dl
	SS	0,1,S.0,1	;6l
	SS	0,0,S.0,5	;7ul
	SS	5,0,S.0,4	;8u

	.end

