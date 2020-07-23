B>type play.asm

.title	"PLAY A ROUND"
.sbttl	"FRENZY"
.ident PLAY
;--------------+
; PLAY A ROUND |
;--------------+
.insert equs
.intern PLAY,ScorePtr,REST,ADDS,SHOWS
.extern COINCK,ItemInc,RANDOM,C.MOVE,SHOWN
;-----------------------
; PLAY 1 ROUND OF ROBO
;-----------------------
PLAY:	pop	hl
	ld	(PlayRet),hl
	call	CLEAR#		;ERASE Screen
	call	ROOM#		;DRAW ROOM
	ld a,	(Demo)		;IF DEMO DONT FLASH MAN
	or	a
	jr nz,	AGAIN
; FLASH MAN
	call	M.INIT#
	ld	bc,(16<8)!(1<COLOR)!(1<WRITE)
	ld a,	(N.PLRS)
	cp	2
	jr z,	..lp
	ld	B,6		;short flashing
..lp:	ld	V.STAT(x),c	
	WAIT	10
	ld	a,(1<COLOR)!(1<BLANK)!(1<WRITE)!(1<ERASE)
	xor	c
	ld	c,a
	djnz	..lp
	call	REST		;vector initialize
;PLAY AGAIN LOOP
AGAIN:	ei
	xor	a
	ld(IqFlg),a
	ld(WallPts),a
	ld	a,90		;(otto resets it)
	ld	(KWait),a		;killoff wait
	ld a,	PERCENT		;figure new percent
..ad:	add	a,6
..lp:	cp	22+1
	jr c,	..ok
	sub	22
	cp	7
	jr c,	..ad
	jr	..lp
..ok:	
	ld	(PERCENT),a
	ld	(MEMPHS),a
	FORK	MAN#
	FORK	SUPER#
	ld a,	(RoomCnt)
	or	A
	jr z,	..NSP
	and	3		;test for special room
	jr nz,	..nsp
	FORK	FACTORY#
..nsp:	xor	a
	ld	(Robots),a
; start up man,robots,otto
..rlp:	FORK	ROBOT#
	ld	hl,PERCENT
	dec	(hl)
	jr nz,	..rlp
	ld	a,(MEMPHS)
	ld	(PERCENT),a
;--------------------------------
; TEST FOR MAN DEAD [GAME OVER]
;--------------------------------
TLOP:	call	NEXT.J#
	lxi	x,Vectors	;man vector
	bit	MOVE,0(x)	;if no moving he's dead
	jp z,	DEAD
	ld	a,P.Y(x)	;STORE LATEST X AND Y
	ld	(ManY),a		;INTO INITIAL X,Y
	ld	b,a
	ld	a,P.X(x)
	ld	(ManX),a
	bit	INEPT,0(x)
	jr nz,	NoWAY		;skip tests if man is hit
	ld	de,AGAIN		;common return address after
	push	de		;scrolling
	cp	5
	jc	OLEFT
	cp	246
	jnc	ORIGHT
	ld	a,b
	cp	5
	jc	OUP
	cp	190
	jnc	ODOWN
	pop	de
;not off edges
NoWAY:	call	Awpts		;award wall pts
	ld a,(UPDATE)		;if score hasn't changed
	or	a		;then skip
	call nz,	SHOWS		;show score
	ld a,(Kwait)		;killoff?
	or	a
	jr nz,	..nk
	dec	a
	ld	(KWait),a
	FORK	KLUTZ#
..nk:	
	ld a,(Demo)		;TEST FOR Demo GAME
	or	a
	jr z,	..sk
; if in a demo game
	call	COINCK		;show new coins
..sk:
	jp	TLOP
;return to go or main
DEAD:	call	NoSnd#
	ld hl,	(PlayRet)		;return to caller
	jp (hl)
;-------------------------
; MOVED OFF EDGE ROUTINES
;-------------------------
ODOWN:	ld	a,10
	ld	(ManY),a
	ld	hl,RoomX+1
	inc	(hl)
	ld	hl,RoomUp#		;type of room routine
	push	hl			;to execute after scroll
	call	TREST
	jr z,	NorD
	ld	de,Screen+223*Hsize-1
	jp	S.D
NorD:	ld	de,Screen
;--------------------
;	SCROLL UP
;--------------------
S.U:	ld	a,27
..lp:	ld	hl,8*Hsize
	add	hl,de
	ld	bc,200*Hsize
	push	de
	ldir			;scroll up 8 lines
	pop	de
	ld	bc,8*Hsize
..lp2:	dec	hl		;clear junk under room edge
	ld	(hl),0
	dec	c
	jr nz,	..lp2
	djnz	..lp2
	dec	a
	jr nz,	..lp
	ret			;will goto RoomXX then AGAIN
;---------------------
;	OFF TOP
;---------------------
OUP:	ld	a,178
	ld	(ManY),a
	ld	hl,RoomX+1
	dec	(hl)
	ld	hl,RoomDown#		;type of room routine
	push	hl			;to execute after scroll
	call	TREST
	jr z,	NorU
	ld	de,Screen+16*Hsize
	jp	S.U
NorU:	ld	de,208*Hsize+Screen-1
;---------------------
;	SCROLL DOWN
;---------------------
S.D:	ld	a,26
DL:	ld	bc,200*Hsize
	ld	hl,-8*Hsize
	add	hl,de
	push	de
	lddr
	pop	de
	ld	bc,8*Hsize
DL2:	inc	hl
	ld	(hl),0
	dec	c
	jr nz,	DL2
	djnz	DL2
	dec	a
	jr nz,	DL
	ret			;goes to room,again
;---------------------
; OFF RIGHT EDGE
;---------------------
ORIGHT: ld	a,19
	ld	(ManX),a
	ld	hl,RoomX+0
	inc	(hl)
	ld	hl,RoomLeft#		;type of room routine
	push	hl			;to execute after scroll
	call	TREST
	jr z,	NorR
	ld	de,Screen+223*Hsize
	jp	S.R
NorR:	ld	de,Screen
;---------------------
;	SCROLL LEFT
;---------------------
S.L:	ld	a,Hsize
LL:	ld	bc,Hsize*208-1
	ld	hl,1
	add	hl,de
	push	de
	ldir
	ld	B,208
	ld	de,-Hsize+1
LL2:	ld	(hl),0
	dec	hl
	ld	(hl),0
	add	hl,de
	djnz	LL2
	pop	de
	dec	a
	jr nz,	LL
	ret			;goes to room,again
;---------------------
;	OFF LEFT EDGE
;---------------------
OLEFT:	ld	a,228
	ld	(ManX),a
	ld	hl,RoomX+0
	dec	(hl)
	ld	hl,RoomRight#		;type of room routine
	push	hl			;to execute after scroll
	call	TREST
	jr z,	NorL
	ld	de,Screen+16*Hsize
	jp	S.L
NorL:	ld	de,Screen+208*Hsize
;---------------------
;	SCROLL RIGHT
;---------------------
S.R:	ld	a,Hsize
XRL:	ld	bc,Hsize*208
	ld	hl,-1
	add	hl,de
	push	de
	lddr
	ld	de,Hsize-1
XRL2:	ld	(hl),0
	inc	hl
	ld	(hl),0
	add	hl,de
	djnz	XRL2
	pop	de
	dec	a
	jr nz,	XRL
	ret			;goes to room,again
;----------------------------
; STOP TALKING,MOVES & COLOR
;----------------------------
TREST:	call	C.MOVE
REST:	di
	call	STOP.B
	ld	hl,Vectors+VLEN
	ld	(L.PTR),hl
	ld	hl,Vectors
	ld	(V.PTR),hl
	ld	bc,VLEN*MaxVec
	call	Zap#
	call	JobInit#
	call	TimerInit#
	ld	a,(Flip)
	or	a
	ret
;---------------------
; STOP BULLET VECTORS
;---------------------
STOP.B: ld	hl,BUL1
	ld	bc,Blength*Bolts
	call	Zap
	ret
;-------------
; SHOW	SCORE
;-------------
SHOWS:	xor	a
	ld	(UPDATE),a
	ld	de,213*256+0
	ld	hl,SCORE1
	ld	B,6
	call	SHOWN
	ld a,	N.PLRS
	cp	2
	ret nz	
	ld	de,213*256+176
	ld	hl,SCORE2
	ld	B,6
	jp	SHOWN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  ->HL AT PLAYERS SCORE
;_______________________________
ScorePtr:
	ld a,	PLAYER
	cp	2
	ld	hl,SCORE2
	ret z	
	ld	hl,SCORE1
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Award wall points
;_______________________________
Awpts:	ld	hl,WallPts
	ld	a,(hl)		;check wall points
	or	a
	ret z
	ld	c,a		;save score
	NEG
	di			;points maybe awarded in int by now
	add	a,(hl)		;sub the point awarded
	ld	(hl),a		;update it
	ei
	ld	a,c
	push	af
	rrc			;get 10's
	rrc
	rrc
	rrc
	ld	b,1		;10's
	call	..awd
	pop	af
	ld	b,0		;1's
..awd:	and	0fh		;isolate score
	ld	c,a		;save in c for adds
	ld a,	Wpoint		;multiplier
..1:	push	af
	push	bc
	call	ADDS		;score 1's
	pop	bc
	pop	af
	dec	a		;dec multiplier
	jr nz,	..1
	ret
;------------------------+
; ADD C X 10**B TO SCORE |
;------------------------+
ADDS:	ld	a,0FFH
	ld	(UPDATE),a
	ld	E,3+1		;NUMBER OF BYTES
	call	ScorePtr
	inc	hl
	inc	hl
	inc	hl
	srl	B		;DIVIDE BY 2, REMAINDER TO CARRY
	ex af,af'			;SAVE CARRY
	inc	b
..lp:	dec	hl
	dec	e		;ONE LESS BYTE
	djnz	..lp
; HL->SCORE BYTE CARRY FLAG = ODD/EVEN, C=VALUE
	ex af,af'			;RESTORE CARRY
	jr nc,	..skp
	sla	C		;SHIFT SCORE
	sla	C
	sla	C
	sla	C
..skp:	ld	a,e		;byte number
	cp	2		;checking for thousands
	jr z,	..td
	ld	a,c		;add score
	add	a,(hl)
	daa
	ld	(hl),a
	jr nc,	..done
..entr: dec	hl
	ld	c,1
	dec	e		;ONE LESS BYTE
	jr nz,	..skp
..done: ret

; test thousands for extra man award
..td:	ld	a,(hl)
	ld	b,a		;save it
	add	a,c		;add score
	daa
	ld	(hl),a
	ld	c,2		;flag for add 1 to next
	jr c,	..noc		;if carry then 2 else 1
	dec	c		;c=1
..noc:	and	0F0h		;isolate top nibble
	ex af,af'
	ld	a,b		;do same to b
	and	0F0h
	ld	b,a
	ex af,af'
	sub	b		;check for change
	daa
	jr z,	..ext
	rrc
	rrc
	rrc
	rrc			;1-10 bcd
;now see if time for extra life
	ld	b,a		;save change
	ld a,	XtraMen
	or	a
	jr z,	..ext
	sub	b		;b=#of 1k's
	jr c,	..give		;should be Minus?
	jr z,	..give
	ld	(XtraMen),a		;put away extra life accum
..ext:	dec	c
	jp z,	..done
	jp	..entr
;award extra life
..give: ld	b,a		;save negative or zero remainder
	in	a,(DIP2)		;get extra life dip
	and	15		;0-15
	sub	b		;sub remainder
	ld	(XtraMen),a
	push	bc
	push	de
	push	hl
	ld	hl,DEATHS
	inc	(hl)		;inc [deaths]
	call	SXLIFE#
	call	SHOWD#
	pop	hl
	pop	de
	pop	bc
	jp	..ext

	.end
