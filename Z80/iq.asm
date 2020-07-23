B>type iq.asm

.title	"WALL DETECTER AND AVOIDANCE CONTROL"
.sbttl	"FRENZY"
.ident IQ
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Intelligence
;_______________________________
.insert EQUS
; DURL refered to thru out this program stands for
; Down,Up,Right,Left bits in directions and wall encoding.
DOWN	==	3
UP	==	2
RIGHT	==	1
LEFT	==	0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Check walls and avoid them
;_______________________________
;a=new DURL, c=old DURL, ix->vector, iy->mans
IQ::	push	bc		;save tracker
	push	de
	ld	l,D.P.L(x)	;get height thru
	ld	h,D.P.H(x)	;pattern pointer
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex de,hl
	ld	d,a		;save DURL	
	inc	hl		;skip x bytes
	ld	a,(hl)		;y lines (height)
	ld	c,a		;for down test
	srl	A		;h/2
	add	a,1		;(h/2)+2
	ld	e,a		;number of lines to test
	ld	h,P.Y(x)	;get current position
	ld	l,P.X(x)
; Regs: HL=YXpos, E=height, c=DURL to test
; Down tests
	bit	DOWN,d
	jp z,	..TU
	push	hl
	ld	a,c		;height of pattern
	add	a,3		;margin of error
	add	a,h		;offset to look
	ld	h,a		;at for wall color
	push	de
	ld	e,5
	call	testx		;check for white below
	pop	de
	pop	hl
	jp z,	..TR		;if ok check right,left
	res	DOWN,d		;else forget that direction
	jp	..TR
;up tests
..TU:	bit	UP,d
	jp z,	..TR
	push	hl
	ld	a,-3
	add	a,h
	ld	h,a
	push	de
	ld	e,5
	call	testx
	pop	de
	pop	hl
	jp z,	..TR
	res	UP,d
;	jp	..TR
;right tests
..TR:	bit	RIGHT,d
	jp z,	..TL
	push	hl
	ld	a,11
	add	a,l
	ld	l,a
	push	de
	call	testy
	pop	de
	pop	hl
	jp z,	..done
	res	RIGHT,d
	jp	..done
;left tests
..TL:	bit	LEFT,d
	jp z,	..done
	push	hl
	ld	a,-3
	add	a,l
	ld	l,a
	push	de
	call	testy
	pop	de
	pop	hl
	jp z,	..done
	res	LEFT,d
;	jp	..done
..done:
	ld	a,d		;final result DURL
	pop	de
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Test in X direction
;_______________________________
; input: h=Y, l=X, c=DURL
; output: Z if robot color in that box
Testx:
	dec	l		;test -1 line
	inc	e
..x:	call	CheckBox
	ret nz
	ex af,af'			;save test results
	ld	a,l		;get x
	add	a,2		;add 2
	ld	l,a
	ex af,af'			;now return test results
	dec	e		;number of times to look
	jr nz,	..x
	ret			;returns Z
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Test in Y direction
;_______________________________
; input: h=Y, l=X, c=DURL
; output: Z if robot color in that box
Testy:	dec	h
	inc	e
..y:	call	CheckBox
	ret nz
	ex af,af'			;save test results
	ld	a,h		;get Y
	add	a,2		;add 2
	ld	h,a
	ex af,af'			;now return test results
	dec	e		;number of times to look
	jr nz,	..y
	ret			;returns Z
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check pixel for use
;_______________________________
CheckBox:
	push	hl		;save YX
	call	RtoAx#		;in hl out hl,a
	and	0fh		;save shift&flop
	bit	Flop,a
	jp z,	..fl
	xor	0Fh		;flip flop and shift
..fl:	xor	07h		;reverse shift
	di			;using magic
	out	(MAGIC),a
	res	5,h		;convert magic->normal addr
	ld	a,(hl)		;get normal screen
	ld	(TEMP+(1<13)),a	;magic scratch
	ei
	ld a,	TEMP		;normal scratch
	and	1		;check it
	pop	hl		;restore YX
	ret
;---------------+
; get durl bits |
;---------------+
; input: h=x l=y
; output: a=durl bits for room xy is in
; used by man,robot to check for others in square
WallIndex::
	ld	a,l		;get y position
	sub	8		;edge of first room
	ld	e,0
	cp	48		;1st row
	jr c,	..sk
	ld	e,6		;2nd row
	cp	48*2
	jr c,	..sk
	ld	e,6*2		;3rd row
	cp	48*3
	jr c,	..sk
	ld	e,6*3		;4th row
..sk:	ld	a,h		;x pos
	sub	8		;edge of first room
	dec	e
..xlp:	sub	40		;room x width
	inc	e
	jr nc,	..xlp
	ex de,hl
	ld	bc,WALLS		;->walls array
	ld	H,0		;add index
	add	hl,bc
	ld	a,(hl)		;get durl for room
	ex de,hl
	ret

	.end
