B>type title.asm

.title	"TITLE PAGE"
.sbttl	"FRENZY"
.ident	TITLE
;~~~~~~~~~~~~~~~~~~~~~~~
;	TITLE PAGE
;_______________________
.insert equs
.define P[A]=[
.byte	^b'A
]
TITLE:: call	CLEAR#
	call	C.TITLE#	;for now
	call	CopyR#		;display copyright
; display STERN
	ld	iy,CROSS
	ld	ix,STERN
	ld	hl,12<8!16	;start pos
	ld	de,5<8!4		;offsets
	call	PLOTER
; display FRENZY
	ld	iy,SQUARE
	ld	ix,FRENZY
	ld	hl,84<8!16	;start pos
	ld	de,8<8!5		;offsets
	call	PLOTER		;**was plotes
	ret
; gamevoer frenzy
SmallTitle::
	ld	iy,Little
	ld	ix,FRENZY
	ld	hl,2<8!61	;start pos
	ld	de,4<8!3		;offsets
	call	PLOTER
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; PLOTER
; Purpose: Diplays pattern using big patterns as pixel
; Inputs:
; DE = Yoffset,Xoffset
; HL = Y start pos,X start pos
; IX-> Display Data String (i.e. STERN)(*CharArray)
; IY-> Object to use as dots
; additional Regs:
; C = one bit mask
; B = DELAY on each dot
PLOTES: ld	b,-1
	jr	Pl2
PLOTER: ld	b,0
Pl2:	ld	c,1		;first bit mask
..lop1: push	hl		;save YX
	push	ix		;save *CharArray
..lop2: ld	a,(ix+0)		;check bit for write
	and	c		;is bit=1
	jp z,	..inc		;else skip
; plot *iy at H,L
	push	bc		;save all
	push	de
	push	hl
	call	RtoAx#		;convert hl
	ex de,hl
	push	iy		;get ob pointer
	pop	hl		;to hl
	call	PLOT#
	pop	hl		;restore all
	pop	de
	pop	bc
	ld	a,b
	or	a
	jp z,	..inc
	ld	b,0
..l:	xtix
	xtix
	xtix
	xtix
	djnz	..l		;delay slightly
	ld	b,a
..inc:	ld	a,l		;x
	add	e		;xoffset
	ld	l,a		;x +=offset
	inc	ixx		;++CArray
	ld	a,(ix+0)		;test if at end of array
	or	(ix+-1)		;both 0 means end
	jr nz,	..lop2		;go do next dot
	pop	ix		;*CA=&start of array
	pop	hl		;restore X to begin of line
	ld	a,h		;y
	add	d		;Yoffset
	ld	h,a		;y+=Yoffset
	sla	c		;maskbit=maskbit<<1
	jr nz,	..lop1		;if still a bit left do it
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Data for display
; organized as strips
;-------------------------------
STERN:
P	11001110
P	11011011
P	11011011
P	11111011
P	01110011
P	00000000
P	00000011
P	00000011
P	11111111
P	11111111
P	00000011
P	00000011
P	00000000
P	11111111
P	11111111
P	11011011
P	11011011
P	11000011
P	00000000
P	11111111
P	11111111
P	00011011
P	00011011
P	11111111
P	11101110
P	00000000
P	11111111
P	11111111
P	00001110
P	00011100
P	00111000
P	11111111
P	11111111
P	00000000
P	00000000

FRENZY:
P	11111111
P	11111111
P	00011011
P	00011011
P	00000011
P	00000011
P	00000000
P	11111111
P	11111111
P	00011011
P	00011011
P	11111111
P	11101110
P	00000000
P	11111111
P	11111111
P	11011011
P	11011011
P	11000011
P	11000011
P	00000000
P	11111111
P	11111111
P	00001110
P	00011100
P	00111000
P	11111111
P	11111111
P	00000000
P	11100011
P	11110011
P	11111011
P	11011111
P	11001111
P	11000111
P	00000000
P	00000111
P	00001111
P	11111100
P	11111100
P	00001111
P	00000111
.byte	0,0

CROSS:	.byte	1,4
P	01000000
P	11100000
P	11100000
P	01000000

SQUARE: .byte	1,9
P	01111100
P	10000100
P	10000100
P	10000100
P	11111100
P	10000100
P	10000100
P	10000100
P	11111000

Little: .byte	1,4
P	11000000
P	11000000
P	11000000
P	00000000

	.end
