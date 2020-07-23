B>type align.asm

.title	"CrossHatch and Red Screen"
.sbttl	"FRENZY"
.ident	ALIGN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Do a cross-hatch display
;--------------------------------------
.insert equs
.extern C.DIPS,W.Fire
.extern ASHOW,CLEAR,LINE
; Put up cross-hatch on screen
ALIGN:: ld	hl,ScreenRAM	;start vertical lines
	ld	d,h
	ld	e,l
	ld	(hl),1		;turn on one dot
	inc	hl
	ld	(hl),e		;=0
	inc	hl		;so 1 dot per 16
	ld	bc,EndScreen-(ScreenRAM+2)
	ex de,hl
	ldir			;fill screen
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; now screen has vertical lines of dots
; fill in horizontal lines
;--------------------------------------
	ld	hl,ScreenRAM+Hsize*8	;start 8 lines down
	ld	d,h
	ld	e,l
	ld	b,Hsize		;32 bytes across screen
Hloop:	ld	(hl),-1		;fill in line
	inc	hl
	djnz	Hloop
	ld	bc,20*Hsize	;drop down 20 lines
	add	hl,bc		;and do it again
	ex de,hl			;by copying top many times
	ld	bc,(EndScreen-ScreenRAM)-(28*Hsize)
	ldir
	call	C.DIPS		;set color ram to white
	call	W.Fire		;wait for fire button
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Make a red screen for purity adj
;--------------------------------------
	ld	hl,ScreenRAM	;fill screen
	ld	de,ScreenRAM+1	;with -1's
	ld	bc,EndScreen-ScreenRAM	;to make
	ld	(hl),-1		;white backgnd
	ldir
	ld	hl,ColorRAM	;fill color ram
	ld	de,ColorRAM+1	;with 11's (RED)
	ld	bc,EndColor-ColorRAM
	ld	(hl),11H		;red
	ldir
	call	W.Fire		;wait for fire button
	jp	ALIGN		;jump back in a loop
.PAGE
.title	"Display ZPU dipsw and VFB switch ports"
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Display Switch Status
;-------------------------------
Linof	==	256*16

; Start of Main Test Sequence
DSPSW::
	di
	in	a,(WHATI)
	xor	a
	out	I.ENAB
	out	NMIOFF
	ld	sp,SPos		;need a stack pointer

	call	CLEAR		;clear screen
	call	C.DIPS		;color screen

	ld	hl,ZPUSW		;message for zpu switches
	ld	de,Linof*0+32	;on line 0
	call	SHOW

;	ld	hl,VFBSW		;message for vfb switches
	ld	de,Linof*8+32	;on line 8
	call	SHOW

;	ld	hl,BITS		;message for bit position
	ld	de,Linof*1+8	;on line 1
	call	SHOW

;	ld	hl,DEF		;message for character def
	ld	de,Linof*13+16	;on line 13
	call	SHOW

	ld	hl,ScreenRAM+16*32*2-96
	call	LINE

	ld	hl,ScreenRAM+16*32*9-96
	call	LINE
..LOOP:
	ld	de,Linof*2+8	;zpu switches line 2 - 6

	in	a,(DIP1)		;top dip
	call	SWSHOW		;zpu switches on = 1

	in	DIP2
	call	SWSHOW

	in	DIP3
	call	SWSHOW

	in	DIP4
	call	SWSHOW

	in	DIP5
	call	SWSHOW

	ld	de,Linof*9+8	;vfb switches lines 9 - 11
	in	a,(I.O1)		;first connector
	call	SWSHWI		;vfb switches on = 0

	in	a,(I.O2)
	call	SWSHWI

	in	a,(I.O3)
	call	SWSHWI

	jp	..LOOP
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	go show the string
;-------------------------------
SHOW:	ld	B,0		;magic reg.
	jp	ASHOW
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; general show switches routine 1 byte/line
; input de = crt x,y address for message (next line when done)
;	a = bit pattern 1 = on
;-------------------------------
SWSHWI: cpl			;now 1 = on
SWSHOW: ld	c,8		;8 bits / byte
..Loop: rar
	ld	hl,SWON		;assume switch on
	jr c,	..sk1
	ld	hl,SWOFF		;switch was off
..sk1:
	push	af		;save bits
	push	de		;save address
	push	bc		;save bit counter
	call	SHOW
	pop	bc		;restore registes
	pop	de
	pop	af

	ld	hl,8*4		;next position on screen
	add	hl,de
	ex de,hl

	dec	c		;all bits displayed?
	jr nz,	..Loop

	ld	hl,Linof-256	;point to next line
	add	hl,de		;for writing
	ex de,hl

	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 .asciz Messages
;--------------------------------------
ZPUSW:	.asciz	"ZPU DIP SWITCHES"
VFBSW:	.asciz	"VFB SWITCHES"
BITS:	.asciz	"1   2	 3   4	 5   6	 7   8"
DEF:	.asciz	"0=OFF	1=ON"
SWON:	.asciz	"1"
SWOFF:	.asciz	"0"
	.end
