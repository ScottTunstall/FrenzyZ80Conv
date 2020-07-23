B>type books.asm

.title	"Show Book-Keeping"
.sbttl	"FRENZY"
.ident	BOOKS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Book keeping stuff
;_______________________________
.insert equs
.extern MAIN,SHOWC,CLEAR,RtoA,SHOWN,C.BOOKS,Zap
.extern S.Fire,S.Book
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 Show book-keeping
;_______________________________
BOOKS::
	xor	a		;turn off interrupts
	out	(I.ENAB),a
	in	a,(WHATI)		;clear any pending interrupts
	ld	sp,SPos		;reset stack pointer
..T1:	CALL	S.Book
	jr nz,	..T1
	call	CLEAR		;erase screen
	call	C.BOOKS		;color it for book-keeping
	di			;re DI cuz CLEAR does EI

	ld	hl,Strings	;point to book.keeping table
	ld	c,-1		;item number=c
..loop:
	inc	c		;->next item
	ld	a,c		;test for end of table
	cp	NItems
	jp z,	..exit
..skip:
	call	SCROLL		;scroll up to make room for text
	push	bc
	ld	B,0		;plop write
	ld	de,256*207	;at x=0 y=207
	call	ASHOW		;show the text
	pop	bc
	call	SCROLL		;make room for number
..Show:
	call	ItemShow
..wait:
	call	S.Book		;door switch
	jr z,	..tst2
	call	Debounce
..deb:	call	S.Book		;wait for debounce
	jr nz,	..deb
	call	Debounce
	jp	..loop		;do it again
..tst2:
	call	S.Fire
	jr z,	..wait
	call	ItemClear	; clear this book-keeping
	jr	..Show		;show it

..exit: call	S.Book
	jr nz,	..exit
	call	Debounce
	jp	MAIN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Subroutines for book-keeping
;-------------------------------
; Show Item #(C) in hex/BCD
;_______________________________
ItemShow:
	push	bc		;save registers
	push	hl
	call	ItemPtr
	ex de,hl
	ld	hl,0		;make stack frame
	push	hl
	push	hl
	push	hl
	add	hl,sp		;point hl->stack frame
	call	MOVEN		;move number
	ld	de,207		;at x=0,y=207
	call	SSHON		;show number
	pop	hl		;remove stack frame
	pop	hl
	pop	hl
POPER:	pop	hl		;restore registers
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Clear Item #(C) in hex/BCD
;_______________________________
ItemClear:
	push	bc
	push	hl
	ld	a,c
	cp	NItems-1
	jr nz,	..
	inc	c		;special for high scores
..:	call	ItemPtr
	dec	hl		;->xsum
	inc	b		;+1 for xsum byte
ClearLoop:
	ld	(hl),0
	inc	hl
	djnz	ClearLoop
	jr	POPER
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Increment Item #(C) in BCD nibbles
;_______________________________
ItemInc::
	push	af
	push	bc
	push	de
	push	hl
	call	ItemPtr		;get hl,b
	ld	D,0		;-> end of BCD
	ld	e,b
	dec	e		;not beyond end
	add	hl,de
;DE useable now
;BCD is one digit per byte in upper half of byte
	ld	c,10H		;inc BCD by 1
	ld	e,0		;xsum nibble
Lip:	ld	a,(hl)		;get digit
	and	0F0H		;mask garbage
	add	a,c		;add C
	daa			;decimal adjust
	ld	(hl),a		;store back in nibble RAM
	jr c,	..con		;if no carry clear C
	ld	c,0
..con:	dec	hl		;point to next msd
	add	a,e		;add in xsum
	ld	e,a		;save xsum
	djnz	Lip		;one less digit to do
	ld	(hl),e		;store xsum
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Get info on Item #(C) in hex/BCD
; output:hl->item b=# of bytes
;_______________________________
ItemPtr::
	ld	hl,Items		;->Item[0]
	ld	e,c
	ld	D,0
	add	hl,de		;->Item[b]
	add	hl,de		;->Item[2*b]
	add	hl,de		;->Item[3*b]
	ld	e,(hl)		;low address
	inc	hl
	ld	d,(hl)		;address of item
	inc	hl
	ld	b,(hl)		;number of nibbles in item
	ex de,hl
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Move @DE,@DE+1 to @HL for B NIBBLES
;_______________________________
MOVEN:: push	hl		;save all regs
	push	de
	push	bc
	srar	b		;divive nibbles by 2
..lp:	ld	a,(de)		;get a nibble
	inc	de		;point to next
	and	0F0H		;isolate battery half
	ld	c,a		;save in C
	ld	a,(de)		;get next nibble
	inc	de		;point at next
	rlc			;isolate battery half into
	rlc			;lower nibble
	rlc
	rlc
	and	0FH		;mask off battery ram
	or	c		;or in high nible
	ld	(hl),a		;store at HL
	inc	hl		;point at next
	djnz	..lp		;two ess nibbles to do
	pop	bc		;restore
	pop	de
	pop	hl
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show # at hl,b digits,e=y position
;_______________________________
SSHON:	push	bc		;save all
	push	de
	push	hl
	ld	d,e		;move Y position to D
	ld	E,0		;set X to 0
	call	SHOWN		;show number
	pop	hl
	pop	de
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Scroll Screen and Erase Area for Show
;_______________________________
SCROLL:: push	bc		;save all
	push	de
	push	hl
	ld	bc,206*Hsize	;size of area to move
	ld	de,ScreenRAM	;at starting address
	ld	hl,16*Hsize+ScreenRAM	;move up 16 lines
	ldir
	ex de,hl
	ld	bc,16*Hsize	;erase 16 lines at bottom
	call	Zap
	pop	hl		;restore all
	pop	de
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show A String
; hl->string,de=y and x,b=magic
;_______________________________
ASHOW:: ex de,hl			;relabs take coords in HL
	call	RtoA		;convert coordinates
	ex de,hl
AS.L:	ld	c,(hl)		;get character
	call	SHOWC		;show it
	inc	de		;point to next screen byte
	inc	hl		;point to next letter
	ld	b,a		;save magic/shift
	ld	a,(hl)		;test next letter
	or	a		;if 0 leave
	ld	a,b		;restore magic/shift
	jr nz,	AS.L		;else loop
	inc	hl		;skip over 0 byte
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Delay for time here
;_______________________________
Debounce:
	ld	b,0		;adjust for best response
..lop:	xtix			;long time instr
	xtix
	xtix
	xtix
	djnz	..lop
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check the XSUMs and zap bad ones
;_______________________________
CheckBooks::
	ld	c,0		;get 1st item
..lp1:	call	ItemPtr		;get the pointers
..do:	dec	hl		;->xsum
	ld	a,(hl)		;get xsum
	and	0F0h
	ex af,af'
	ld	d,0		;temp xsum
..lp2:	inc	hl		;->next byte
	ld	a,(hl)		;get book nibble
	and	0F0h		;isolate nibble
	add	a,d		;add xsum
	ld	d,a		;save
	djnz	..lp2		;for b nibbles
	ex af,af'			;get original xsum
	cp	d		;temp sum the same?
	call nz,	ItemClear	;no-clear item
	inc	c		;goto next item
	ld	a,c
	cp	NItems-1	;all but high scores
	jr c,	..lp1
; do high scores as big number
	ret nz
	inc	c		;use special item#10
	jr	..lp1
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; book-keeping tables
;
; macro for setting up book-keeping
;
.define ITEM[Address,Length]=[
	.word	Address
	.byte	Length
]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; pointers and strings for book items
;_______________________________
Items:
	ITEM	CREDITS,2
	ITEM	Chute1,8
	ITEM	Chute2,8
	ITEM	Play1,6
	ITEM	Play2,6
	ITEM	Plays,6
	ITEM	ScoreSum,12
	ITEM	PlayTime,12
	ITEM	OnTime,12
	ITEM	HIGH2,6
NItems==10	
	ITEM	HIGH2,12*5	;special for clearing
Strings:
	.asciz	"Credits"
	.asciz	"Chute 1"
	.asciz	"Chute 2"
	.asciz	"1 Player Games"
	.asciz	"2 Player Games"
	.asciz	"Total Plays"
	.asciz	"Total Score"
	.asciz	"Total Seconds of Play"
	.asciz	"Total Seconds Game On"
	.asciz	"High Scores"

	.end
