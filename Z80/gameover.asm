B>type gameover.asm

.title	"Game Over Show"
.sbttl	"FRENZY"
.ident	GOVER
;~~~~~~~~~~~~~~~~~~~~~~~
;	game over
;_______________________
.insert equs
.intern GOVER,CLEAR,INSERT
.intern LINE,LTABLE
.extern SHOWN,SHOWO,SHOWA,SHOWC,GETC,CREDS,SHOWS
.extern C.GO,C.L1,C.L2,C.LI,PH1,NoVoice,Zap

; macros
.define WROTE[Magic,X,Y,String]=[
	call	SHOWA
	.byte	Magic,X,Y
	.asciz	String
]
; language tabled subroutine call
.define LANG[Name]=[
	call	LTABLE
	.word	E.'Name		;;English
	.word	G.'Name		;;German
	.word	F.'Name		;;French
	.word	S.'Name		;;Spanish
]
; equates
S.END	==	EndScreen
LINE1	==	190
;---------------------------------+
; clear screen and show copyright |
;---------------------------------+
GOVER:	call	CLEAR		; erase.screen
	call	C.GO		; setup color gameover
	call	CREDS		;show credits
	call	SHOWS		;show scores
;----------------------------+
; show high scores and names |
;----------------------------+
	call	SmallTitle#	;FRENZY
	LANG	High
	ld	hl,56*Hsize+Screen	; start position
	call	LINE
	ld	hl,HIGH1		; first high score
	ld	a,1
	ld	(TEMP),a		; number 1 line
	ld	de,63<8!64	; YX position
..loop: push	de
	push	hl
	ld	a,(hl)		;if score is zero dont show it
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	pop	hl
	push	hl
	jr nz,	..skip
	pop	hl
	pop	de
	jr	DRAW
..skip: ld	hl,TEMP		; shown line number
	ld	B,2		; 2 digits long
	call	SHOWN
	inc	de		; spc over one byte
	pop	hl
	ld	B,6		; shown high score,6digits
	call	SHOWO
	inc	de		;space over
	xor	a		;plop write
	ld	c,(hl)
	call	SHOWC
	inc	de
	inc	hl
	ld	c,(hl)
	call	SHOWC
	inc	de
	inc	hl
	ld	c,(hl)
	call	SHOWC
	inc	hl		; -> next high score
	pop	de
	ld	a,d
	add	a,12
	ld	d,a
	ld a,	TEMP
	add	a,1
	daa
	ld  (TEMP),A
	cp	11H
	jr nz,	..loop
;------------+
; draw lines
;------------+
DRAW:	ld	hl,184*Hsize+Screen
	call	LINE
	ld	hl,204*Hsize+Screen
;	call	line
;	2
;------------------+
; draw line across |
;------------------+
LINE:	ld	a,0FFH
	ld	B,64
L.LOP:	ld	(hl),a
	inc	hl
	djnz	L.LOP
	ret
;--------------+
; erase screen |
;--------------+
CLEAR:	ld	hl,ColorScreen
	ld	bc,700H
	call	Zap
	di
	sspd	Temp
	ld	sp,S.END+1
	ld	B,Vsize
	ld	de,0
E.L:	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	push	de
	djnz	E.L
	lspd	Temp
	ei
; set flip state by player number
SFLIP:	in	a,(I.O3)		;is it a cocktail
	bit	7,A
	jr nz,	Normal		;if not cocktail
	ld a,	PLAYER		;is cocktail version
	cp	2		;flip screen? for player2
	jr nz,	Normal
	ld	a,8		;the flip bit
	ld (FLIP),a
	ret
Normal: xor	a
	ld (FLIP),a
	ret
; Copyright
CopyR:: call	SHOWA			; @ 1980 stern electronics
	.byte	90H
	.byte	12,LINE1,1FH
	.asciz	"1982 STERN Electronics, Inc."
	ret
;---------------------------+
; insert coin / press start |
;---------------------------+
INSERT: CALL	LERASE		;erase line for text
	call	GETC		;get credits
	jr z,	INSSS
	dec	a
	jr z,	PRESS1
	call	C.L2
	LANG	Pus2
	ret
;
PRESS1: CALL	C.L1
	LANG	Push1
	ret
;
INSSS:	call	C.LI
	LANG	In
; coins detected in pocket
	ld	hl,PH1		;phrase
	ld (V.PC),hl		;into voice pc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~
; xtra man level 
;__________________________
XMLEV:: call	LERASE
	in	Dip2
	and	15		;# of k for extra man
	jr z,	..cheap
	ld	b,a
	and	8
	ld	c,a
	ld	a,b
	and	7
	add	a,c
	daa			;now its in BCD
	ld	(TEMP),a
	ld	de,LINE1<8!88	; y:x position
	ld	hl,TEMP		; number
	ld	B,2		; 2 digits long
	call	SHOWN		; show it
	WROTE	90h,104,LINE1,"000 = ~"
	ret
..cheap:
	WROTE	90H,72,LINE1,"No Extra Lives"
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~
; erase line for messages
;__________________________
LERASE: ld	hl,LINE1*Hsize+Screen
	ld	bc,2C0H		;2 lines less than 16
	xor	a
LELE:	ld	(hl),a
	inc	hl
	dec	c
	jr nz,	LELE
	djnz	LELE
	ret
;---------------------------------+
; Language tabled subroutine call |
;---------------------------------+
LTABLE: pop	hl		;get table address
	ld	d,h
	ld	e,l		;save table address
	ld	bc,8		;offset to end of table
	add	hl,bc		;calc return address
	push	hl		;put return address on stack
	ex de,hl			;get table address
	in	a,(diP2)		;get language bits
	and	0C0H
	rlc			;rotate bits into low bits
	rlc
	rlc			;A=language#*2
	ld	c,a		;BC=language#*2
	add	hl,bc		;address into table
	ld	a,(hl)		;get low address
	inc	hl
	ld	h,(hl)		;get high address
	ld	l,a		;HL=subroutine address
	jp (hl)
;------+
; Text |
;------+
E.High: WROTE	90H,80,42,"High Scores"
	ret
F.High: WROTE	90H,68,42,"Meilleur Score"
	ret
G.High: WROTE	90H,60,42,"Hoechster Gebnis"
	ret
S.High: WROTE	90H,96,42,"Records"
	ret
;-------------------------
E.Push1: WROTE	90H,20,LINE1,"Push 1 Player Start Button"
	ret
F.Push1: WROTE	90H,36,LINE1,"Pousser bouton start 1"
	ret
;-------------------------
E.Pus2: WROTE	90H,4,LINE1,"Push 1 or 2 Player Start Button"
	ret
F.Pus2: WROTE	90H,16,LINE1,"Pousser bouton start 1 ou 2"
	ret
G.Push1:
G.Pus2: WROTE	90H,32,LINE1,"Startknoepfe druecken"
	ret
S.Push1:
S.Pus2: WROTE	90H,68,LINE1,"Pulsar Start"
	ret
;-----------------
E.In:	WROTE	90H,88,LINE1,"Insert Coin"
	ret
F.In:	WROTE	90H,48,LINE1,"Introduire la monnaie"
	ret
G.In:	WROTE	90H,72,LINE1,"Munze einwerfen"
	ret
S.In:	WROTE	90H,72,LINE1,"Ponga la moneda"
	ret

	.end

