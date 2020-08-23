B>type showa.asm

.title	"SHOW ALPHABETIC"
.sbttl	"FRENZY"
.ident SHOWA
;-----------------
; string display
;-----------------
.insert EQUS
.extern CHARSET
;-----------------------------------
; show a string
; inline parms: x,y bytes
; followed by a string ending in 0
;-----------------------------------
SHOWA:: pop	hl		; hl -> inline parms
	ld	b,(hl)		; magic value
	inc	hl
	ld	e,(hl)		; load x
	inc	hl
	ld	d,(hl)		; load y
	inc	hl
	ex de,hl
	call	RtoA
	ex de,hl
..lp:	ld	c,(hl)		; get char
	res	7,C		; clear end of string indicator
	call	SHOWC		; show char
	ld	b,a		; save magic
	ld	a,(Flip)
	or	a
	jr nz,	..1
	inc	de		; point to next char position
	jr	..2
..1:	dec	de
..2:	inc	hl		; point to next character
	ld	a,(hl)		; test next character
	or	a		; if zero
	ld	a,b
	jr nz,	..lp		; then loop
	inc	hl		;return past
	jp (hl)		; data bytes
;-------------------------------
; relative to absolute	
; in:	b=magic ,h=y,l=x
; out:a=magic+shift,hl=address
;-------------------------------
RtoAx:: ld	B,90H		;xor write
RtoA::	ld	a,(Flip)
	or	a
	ld	a,7
	jr nz,	..flp
	and	l
	or	b
	out	(MAGIC),a		; set magic register
	srl	H
	rr	L
	srl	H
	rr	L
	srl	H
	rr	L
	ld	bc,MagicScreen
	add	hl,bc
	ret
;flipped version
..flp:	and	l
	or	b
	set	FLOP,A
	out	(MAGIC),a		; set magic register
	srl	H
	rr	L
	srl	H
	rr	L
	srl	H
	rr	L
	ld	b,h
	ld	c,l
	ld	hl,Hsize*224+MagicScreen-1
	or	a
	sbc	hl,bc
	ret
;-------------------
; show a character
; in:	a=magic trash
;	c=char
;	hl->string
;	de->mscreen
;-------------------
VOFSET	==	3
CHARV	==	9
;
SHOWC:: push	hl		; savestring pointer
	ld	hl,0
	ld	B,0
	add	hl,bc
	add	hl,hl		; calc char offset
	add	hl,hl
	add	hl,hl
	add	hl,bc
	ld	bc,CHARSET-(1FH*CHARV)
	add	hl,bc		;hl->char data
	push	de
	push	af
	ex de,hl			;hl->screen
	ld	a,(Flip)		;check for flipped state
	or	a
	ld	a,(de)		;test for lower case
	jr nz,	FLIPD
	or	a
	jp	..no
	ld	bc,Hsize*VOFSET
	add	hl,bc		;decender offset
..no:	ld	a,CHARV		;number of bytes high
	ld	bc,Hsize-1	; offset to next line
..lp:	ex af,af'
	pop	af
	push	af
	di
	out	MAGIC
	ld	a,(de)		;get data
	and	7FH		;clear shift bit
	inc	de
	ld	(hl),a		;write to screen
	inc	hl
	ld	(hl),0		;flush magic register
	ei
	add	hl,bc		;move down a line
	ex af,af'
	dec	a
	jr nz,	..lp
	pop	af
	pop	de
	pop	hl
	ret
;flipped version
FLIPD:	or	a
	jp	..no
	ld	bc,-Hsize*VOFSET
	add	hl,bc		;decender offset
..no:	ld	a,CHARV		;number of bytes high
	ld	bc,-Hsize+1	; offset to next line
..lp:	ex af,af'
	pop	af
	push	af
	di
	out	MAGIC
	ld	a,(de)		;get data
	and	7FH		;clear shift bit
	inc	de
	ld	(hl),a		;write to screen
	dec	hl
	ld	(hl),0		;flush magic register
	ei
	add	hl,bc		;move down a line
	ex af,af'
	dec	a
	jr nz,	..lp
	pop	af
	pop	de
	pop	hl
	ret
;-------------------------------
; show a number
; i:	b = number of digits
;	de= y and x postition
;	hl= address of bcd string
;	does a plop write	
;-------------------------------
SHOWN:: push	bc		;save number of digits
	ld	B,0		;plop write
	ex de,hl
	call	RtoA		;convert xy to address
	ex de,hl
	ex af,af'			;save magic reg
	pop	bc
SHOWO:: res	0,C		;zero suppress on
..loop: ld	a,b		;get count
	dec	a		;if last digit-
	jr nz,	..skip		; dont suppress it
	set	0,C		;dont zero suppress
..skip: ld	a,(hl)		;get 2 bcd digits
	bit	0,B		;odd or even digit?
	jr nz,	..no		;shift
	srl	A		;top digit
	srl	A		;into bottom
	srl	A
	srl	A
	dec	hl
..no:	inc	hl
	and	0FH		;isolate digit
	jr nz,	..SUP		;if 0 check-
	bit	0,C		; for suppress
	jr nz,	..2
	ld	a," "		;suppress it
	jr	..dec
..SUP:	SET	0,C		;no more suppress
..2:	add	a,90h		;hex to ascii trick
	daa
	add	a,40h
	daa
..dec:	push	hl
	push	bc
	ld	c,a		;char into c
	ex af,af'			;restore magic reg
	call	SHOWC		;display one digit
	ex af,af'			;save magic
	pop	bc
	pop	hl
	ld	a,(Flip)
	or	a
	jr nz,	..ss
	inc	de		; point to next char position
	jr	..xx
..ss:	dec	de
..xx:	djnz	..loop
	ret

	.end
