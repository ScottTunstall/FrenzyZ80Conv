B>type factory.asm

.title	"Robot Factory & MaMa Otto"
.sbttl	"FRENZY"
.ident	FACTORY
.insert equs
.extern RtoAx,PLOT,V.ZERO
; MACROS
RD=8	;room drop
XX=120+RD	;x of left edge
YY=48+RD	;y of top corner
.define START[Pat,Xoff,Yoff]=[
	ld	hl,Pat#
	ld	de,((Yoff+YY)<8)!(Xoff+XX)
	call	%START
]
.define DRAW[Pat,Xoff,Yoff]=[
	ld	de,Pat#
	ld	hl,((Yoff+YY)<8)!(Xoff+XX)
	call	%DRAW
]
.define COLOR[Ctable]=[
	ld	hl,Ctable
	call	%Color
]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	ROBOT FACTORY
;_______________________________
FACTORY::
	ld	a,(RoomCnt)
	bit	3,a
	jp z,	..8
	bit	2,a
	jp z,	Plant		;do mama otto 1
	jp	Compu		;2
..8:	bit	2,a
	jr nz,	MaMa		;2
; 4-factory is farthest
	COLOR	FCOLS
	DRAW	PTA,3,3
	DRAW	PTB,4,18
	DRAW	PTC,12,16
; 4 vectored parts (Conveyor,Handle,WhirlCCW,WhirlCW)
	START	C.IDLE,8,8
	START	H.IDLE,28,32
	START	W.CCW,14,29
	ld	(ix+TPRIME),1
	START	W.CW,19,36
	ld	(ix+TPRIME),1
	pop	bc		;wcw save vector pointers
	pop	bc		;wccw
	pop	de		;handle
	pop	ix		;conveyor
..n:	call	NEXT.J#
	ld	a,(Robots)
	or	a
	jr m,	..go
	cp	13
	jr nc,	..n
; start one up
..go:	ld	hl,C.PART#	;go conveyor
	call	ChangePat		
	WAIT	50
	push	de		;ex ix,iy
	xtix
	pop	de
	ld	hl,H.GO#
	call	ChangePat
	WAIT	60
	FORK	FROBOT#
	WAIT	90
	ld	hl,H.IDLE#
	Call	ChangePat
	push	de		;ex ix,iy
	xtix
	pop	de
	WAIT	30		;idle
	jr	..n
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Mother Otto
;_______________________________
MaMa:	call	M.TALK#
	COLOR	MCOLS
	DRAW	MAL,4,4
	DRAW	MAR,20,4
	call	Sleep
..sl:	call	NEXT.J
	ld a,(CACKLE+1)	;ottos hit
	or	a
	jr nz,	..xsl		;stay asleep
	ld	a,(Vectors)		;check on man
	bit	INEPT,a
	jr z,	..sl
	call	UnM
	jr	..xdl
..xsl:	call	Sleep		;erase old
	call	Angry
	ld	de,(82<8)!110
	FORK	MSUPER#
	ld	de,(82<8)!170
	FORK	MSUPER
	ld	de,(40<8)!148
	FORK	MSUPER
	ld	de,(90<8)!148
	FORK	MSUPER
..dl:	call	NEXT.J
	ld	a,(Vectors)		;check on man
	bit	INEPT,a
	jr z,	..dl
	call	AngryM		;erase old mouth
..xdl:	call	Smile	
	jp	JobDEL#		;no need for me any more
;draw smile
Smile:	DRAW	MASML,4,30
	DRAW	MASMR,20,30
	RET
;draw eyes and mouth angry
Angry:	DRAW	MAEL,11,9
	DRAW	MAER,21,9
	COLOR	ECOLS
AngryM: DRAW	MAFL,4,30
	DRAW	MAFR,20,30
	ret
;draw eyes and mouth sleep
Sleep:	DRAW	MASL,4,13
	DRAW	MASR,20,13
UnM:	DRAW	MAM,12,30
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Electric Plant
;_______________________________
Plant:
	COLOR	PLCOLS
	call	UnReflect
	DRAW	BULB,8,4
	DRAW	BULB,8,20
	DRAW	BULB,28,12
	DRAW	STALK,28,28
	DRAW	RFILL,3,36
	DRAW	FILL,16,36
	DRAW	RFILL,28,36
; 4 vectored parts (W.CW,W.CCW,TL,BL)
	START	TL,12,7
	ld	(ix+TPRIME),1
	START	BL,12,16
	ld	(ix+TPRIME),1
	START	W.CCW,8,38
	ld	(ix+TPRIME),1
	START	W.CW,28,38
	ld	(ix+TPRIME),1
; save vector pointers
	pop	bc
	pop	de
	pop	hl
	pop	ix
..loop: call	NEXT.J
	call	HitChk
	jr z,	..loop
..Hit:	di
	ldax	b		;stop the whirlies
	res	MOVE,a
	stax	b
	ld	a,(de)
	res	MOVE,a
	ld	(de),a
	ld	a,(hl)
	and	#((1<MOVE)!(1<WRITE))
	ld	(hl),a
	ld	a,(ix+V.STAT)
	and	#((1<MOVE)!(1<WRITE))
	ld	(ix+V.STAT),a
	ei
	ld	a,2
	ld	(IqFlg),a		;go for slow moving
	ld	bc,201h		;100
	call	ADDS#
	jp	JobDel#
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Computer Control
;_______________________________
Compu:
	COLOR	CPCOLS
	call	UnReflect
	DRAW	RTL,4,12
	DRAW	LTL,24,12
	DRAW	Nose,18,15
; 3 vectored parts (CMS,TRCCW,TRCCW)
	START	CMS,16,2
	ld	(ix+TPRIME),1
	START	CMouth,12,28
	START	TRCCW,4,4
	ld	(ix+TPRIME),1
	START	TRCCW,30,4
	ld	(ix+TPRIME),1
; save vector pointers
	pop	ix
	pop	hl
	pop	de		;mouth
	pop	bc		;message
..loop: call	NEXT.J
	call	HitChk
	jr z,	..loop
..Hit:	di			;stop tape reels
	ldax	b		;stop message
	and	#(1<MOVE)
	stax	b
	ld	a,(hl)
	and	#(1<MOVE)
	ld	(hl),a
	ld	a,(ix+V.STAT)
	and	#(1<MOVE)
	ld	(ix+V.STAT),a
;do mouth
	push	de
	pop	ix
	ld	hl,CMDIE#
	ld	(ix+D.P.H),h
	ld	(ix+D.P.L),l
	ei
	ld	a,5		;no shoot/iq
	ld	(IqFlg),a		;go for Crasho
	ld	bc,201h		;100
	call	ADDS#
	call	C.TALK#
	jp	JobDel#
;~~~~~~~~~~~~~~~~~~~~
; Check for man bolts
;____________________
PX=1
PY=2
HitChk: ld	iy,BUL1
	call	HC
	ld	iy,BUL1+BLength
	call	HC
	xor	a
	ret
;
HC:	ld	a,PX(iy)
	cp	XX
	rc
	cp	XX+40
	ret nc
	ld	a,PY(iy)
	cp	YY
	rc
	cp	YY+46
	ret nc
	inc	sp	;drop return address
	inc	sp
	ret		;nz
;~~~~~~~~~~~~~~~~~~~~
; Unreflecto the area
;____________________
UnReflect:
	ld	a,(Flip)
	or	a
	jr nz,	%FUC

	ld	ix,82b0h
	ld	de,Hsize
	call	lin0
	ld	b,11
	call	sid0
	call	lin0
; write grapes on wall
Wallo:	di
	ld	hl,3480h		;((YY-4)<8)!XX
	push	hl
	call	HWB#
	pop	hl
	call	VWB#
	ld	hl,34a8h		;((YY-4)<8)!(XX+40)
	call	VWB
	ld	hl,6480h		;((YY+44)<8)!XX
	call	HWB
	ei
	ret
;flip style
%FUC:	ld	ix,864fh		;flip version
	ld	de,-Hsize
	call	lin1
	ld	b,11
	call	sid1
	call	lin1
	jp	wallo
;
Lin0:	ld	b,5
	push	ix
	pop	hl
	ld	a,(Wcolor)
..loop: ld	(hl),a
	inc	hl
	djnz	..loop
	ld	b,1
;	jp	Sid0
;
Sid0:	ld	a,(Wcolor)
	and	0F0h
	ld	c,a
..loop: ld	a,(ix+0)
	and	0Fh
	or	c
	ld	(ix+0),a
	ld	a,(ix+5)
	and	0Fh
	or	c
	ld	(ix+5),a
	add	ix,de
	djnz	..loop
	ret
;
Lin1:	ld	b,5
	push	ix
	pop	hl
	ld	a,(Wcolor)
..loop: ld	(hl),a
	dec	hl
	djnz	..loop
	ld	b,1
;	jp	sid1
;
Sid1:	ld	a,(Wcolor)
	and	0Fh
	ld	c,a
..loop: ld	a,(ix+0)
	and	0F0h
	or	c
	ld	(ix+0),a
	ld	a,(ix+-5)
	and	0F0h
	or	c
	ld	(ix+-5),a
	add	ix,de
	djnz	..loop
	ret
;~~~~~~~~~~~~~~~~~~~~
; Color the area
;____________________
%Color:			;FIX FOR COCKTAIL
	ld	a,(Flip)
	or	a
	jr nz,	%FC
	ld	ix,82B0h
	ld	de,Hsize-5
	ld	c,12
..y:	ld	b,5
..x:	ld	a,(hl)
	inc	hl
	ld	(ix+0),a
	inc	ixx
	djnz	..x
	add	ix,de
	dec	c
	jr nz,	..y
	ret
;
%FC:	ld	ix,864fh		;flip version
	ld	de,-Hsize+5
	ld	c,12
..y:	ld	b,5
..x:	ld	a,(hl)
	inc	hl
	rlc
	rlc
	rlc
	rlc
	ld	(ix+0),a
	dec	ix
	djnz	..x
	add	ix,de
	dec	c
	jr nz,	..y
	ret
;~~~~~~~~~~~~~~~~~~~~~
; Change (ix) pattern
;_____________________
ChangePat:
	di
	ld	(ix+D.P.L),l
	ld	(ix+D.P.H),h
	ei
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~
; Draw does the xor write
;_________________________
;de=pattern hl=yx
%DRAW:	di
	call	RtoAx
	ex de,hl
	call	PLOT
	ei
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Start a sub part
; push ix on stack on exit
%START:
	push	de
	push	hl
	call	V.ZERO#
	pop	hl
	pop	de
	rc
	ld	(ix+P.X),e
	ld	(ix+P.Y),d
	ld	(ix+D.P.L),l
	ld	(ix+D.P.H),h
	ld	(ix+TIME),1
	ld	(ix+TPRIME),2
	ld	(ix+V.STAT),(1<InUse)!(1<Move)!(1<Write)	
	pop	hl		;get return address
	push	ix		;save vector pointer
	jp (hl)			;return 
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Set up a square around box 9
;_______________________________
DOWN=3
UP=2
RIGHT=1
LEFT=0
S.ROOM::
	ld	ix,Walls		;set up walls
;reflecto
	set	DOWN,(ix+24+9)
	set	UP,(ix+24+9)
	set	RIGHT,(ix+24+9)
	set	LEFT,(ix+24+9)
	set	DOWN,(ix+24+3)
	set	UP,(ix+24+15)
	set	RIGHT,(ix+24+8)
	set	LEFT,(ix+24+10)
;set walls
	set	DOWN,(ix+9)
	set	UP,(ix+9)
	set	RIGHT,(ix+9)
	set	LEFT,(ix+9)
	set	DOWN,3(ix)
	set	UP,15(ix)
	set	RIGHT,8(ix)
	set	LEFT,10(ix)
;ocupied
	set	InUse,(ix+9)
	res	DOWN,(ix+24+15)		;make sure there is
	res	UP,(ix+24+21)		;a shootable area under
	res	RIGHT,(ix+24+14)
	res	LEFT,(ix+24+15)
	res	RIGHT,(ix+24+15)
	res	LEFT,(ix+24+16)
	ret				;the factory
;----------------------------
FCOLS:	.byte	77h,77h,77h,77h,77h	;top
	.byte	77h,77h,77h,77h,77h	;0
	.byte	77h,55h,55h,55h,77h	;1
	.byte	77h,55h,55h,55h,77h	;2
	.byte	77h,55h,55h,55h,77h	;3
	.byte	74h,41h,11h,13h,33h	;4
	.byte	74h,46h,66h,63h,33h	;5
	.byte	74h,46h,66h,63h,33h	;6
	.byte	74h,46h,66h,63h,33h	;7
	.byte	74h,46h,66h,63h,33h	;7
	.byte	74h,46h,66h,63h,33h	;7
	.byte	74h,46h,66h,63h,33h	;7

MCOLS:	.byte	77h,77h,77h,77h,77h	;top
	.byte	73h,33h,33h,33h,33h	;0
	.byte	73h,33h,33h,33h,33h	;1
	.byte	73h,33h,33h,33h,33h	;2
	.byte	73h,33h,33h,33h,33h	;3
	.byte	73h,33h,33h,33h,33h	;4
	.byte	73h,33h,33h,33h,33h	;5
	.byte	73h,33h,33h,33h,33h	;6
	.byte	73h,33h,33h,33h,33h	;7
	.byte	73h,33h,33h,33h,33h	;8
	.byte	73h,33h,33h,33h,33h	;9
	.byte	73h,33h,33h,33h,33h	;9

ECOLS:	.byte	77h,77h,77h,77h,77h	;top
	.byte	73h,33h,33h,33h,33h	;0
	.byte	73h,33h,33h,33h,33h	;1
	.byte	73h,33h,33h,33h,33h	;2
	.byte	73h,33h,33h,33h,33h	;3
	.byte	73h,31h,33h,13h,33h	;4
	.byte	73h,33h,33h,33h,33h	;5
	.byte	73h,33h,33h,33h,33h	;6
	.byte	73h,33h,33h,33h,33h	;7
	.byte	73h,33h,33h,33h,33h	;8
	.byte	73h,33h,33h,33h,33h	;9
	.byte	73h,33h,33h,33h,33h	;9

CPCOLS: .byte	77h,77h,77h,77h,77h	;top
	.byte	76h,66h,22h,26h,66h	;0
	.byte	76h,66h,22h,26h,66h	;1
	.byte	76h,66h,22h,26h,66h	;2
	.byte	76h,66h,0cch,0c6h,66h	;3
	.byte	7ch,3ch,33h,3ch,3ch	;4
	.byte	7ch,3ch,33h,3ch,3ch	;5
	.byte	7ch,3ch,11h,1ch,3ch	;6
	.byte	7ch,3ch,11h,1ch,3ch	;7
	.byte	7ch,3ch,11h,1ch,3ch	;8
	.byte	7ch,3ch,11h,1ch,3ch	;9
	.byte	7ch,0cch,11h,1ch,0cch	;9

PLCOLS: .byte	77h,77h,77h,77h,77h	;0
	.byte	73h,33h,33h,33h,33h	;1
	.byte	73h,33h,55h,53h,33h	;2
	.byte	73h,33h,55h,53h,33h	;3
	.byte	73h,66h,55h,53h,33h	;4
	.byte	73h,66h,55h,53h,33h	;5
	.byte	73h,33h,55h,56h,63h	;6
	.byte	73h,33h,55h,56h,63h	;7
	.byte	73h,66h,55h,56h,63h	;8
	.byte	73h,66h,55h,56h,63h	;9
	.byte	77h,77h,77h,77h,77h	;10
	.byte	73h,33h,33h,33h,33h	;11

	.end
