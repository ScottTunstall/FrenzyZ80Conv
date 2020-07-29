B>type init.asm

.title	"INTERRUPT ROUTINE"
.sbttl	"FRENZY"
.ident	INT
;--------------------
; interrupt routine
;--------------------
.insert equs
.intern INT,PLOT
.extern RtoA
;---------------------------------------
; this routine does writing, erasing,
; moving, and pattern animation based
; on the following structure
;	---- v.stat	vector status	<- IY points here
;	---- setup	last magic value
;   -------- o.a.l/h	old screen address
;   -------- o.p.l/h	last pattern addr.
;	---- tprime	value to stuff into time
;	---- time	time til move
;	---- v.x	x velocity
;	---- v.y	y velocity
;	---- p.x	x position
;	---- p.y	y position
;   -------- d.p.l/h	pattern pointer
;--------------------------------------
INT:	out	(NMIOFF),a		;turn off nmi's
	di			;believe it [cuz of calls]
	push	af
	in	a,(WHATI)		;bottom of screen?
	rar			;test bit 0
	jr c,	BS		;skip if middle of screen
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Middle of Screen Interrupt
;_______________________________
; use only AF,BC,HL
	out	(NMION),a		;prob get nmi immed'ly
	push	hl		;save em
	push	bc
	ld	hl,SWD		; check coins
	ld	a,(hl)		;oldset switch
	inc	hl
	ld	b,(hl)		;old sw.
	xor	b		;difference in a
	ld	c,a		; in c
	in	a,(I.O2)		;new sw.s
	cpl
	ld	(hl),a		;store new switch
	dec	hl
	ld	(hl),b		;make old->oldest
	and	c		;check new=1 old=1 oldest=0
	and	0c0H
..lp:	dec	hl		;->cackle
	bit	7,a		; check bit
	jr z,	..sk
	inc	(hl)		;inc coin counter
..sk:	add	a		;shift bits
	jr nz,	..lp
; update man alternator
	ld	hl,Man.Alt
	srlr	m
;take care of seconds counter
	ld	hl,T60cnt
	dec	(hl)
	jp	..ous
	ld	(hl),60		;reset seconds timer
	ld	c,8		;inc total seconds in backgnd
	call	ItemInc#	;pushes all reg used
	ld	a,(Demo)
	or	a
	ld	c,7		;total game time
	call z,	ItemInc
	ld	hl,KWait		;adjust kill off
	ld	a,(hl)
	or	a
	jr z,	..ous
	dec	a
	ld	(hl),a
..ous:	call	GetC#		;if no credits
	ld	L,0
	or	a		;skip to waiter
	jr z,	I.but
	cp	1		;if only one credit
	ld	L,1		;then check only button1
	jr z,	I.but
	ld	L,3
I.but:	in	a,(I.O2)		;check start button[s]
	cpl
	and	l
	ld	l,a		;save buttons
	ld	a,(StartB)		;previous buttons
	or	l
	ld	(StartB),a		;save for main
	jp z,	..exit
	bit	7,a		;in play flag
	jp z,	GO#		;go play NOW
..exit: pop	bc
	pop	hl
	jp	BYE
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Bottom of Screen Interrupt
;_______________________________
BS:	push	iy		;save old jobs
	push	ix
	push	hl
	push	de
	push	bc
	ex af,af'
	push	af
;< do color man every 4 int?>
	ld	hl,0		;null vector pointer
	ld	(OLD1),hl
	ld	(OLD2),hl
	ld	(OLD3),hl
	ld	hl,Inttyp	;test alternator
	rlcr	m		;by rotating the bits
	ld	b,3		;do 2 others if no man
	ld	hl,(L.PTR)		;robot list pointer
	jc	..ilp
	ld	hl,Vectors
	ld	(Old3),hl		;save for updates
	call	SECT1		;rewrite man
	call	UNCMAN#		;uncolor man
	ld	hl,Vectors
	bit	COLOR,(hl)		;do color
	call nz,	COLMAN#
	ld	hl,(L.PTR)		;robot list pointer
	ld	b,2		;# of robots to do
..ilp:	push	bc
	call	SECT1		;rewrite robot
	pop	bc
	ld	hl,(V.PTR)		;Get vector pointer
; save pointer for later update
	ex de,hl
	ld	a,b		;get index
	add	a		;double
	ld	hl,Old1-2	;save array start
	add	a,l		;add b*2 to hl
	ld	l,a
	ld	a,h
	adc	a,0
	ld	h,a
	ld	(hl),e		;store vector address
	inc	hl		;for later update
	ld	(hl),d
	ex de,hl
..inc:	ld	de,VLEN		;delta to next vector
	add	hl,de		;point to next
	ld	de,Vectors+(MaxVec*VLEN) ;end of list
	ld	a,l		;see if at end
	cp	e
	jr nz,	..tst
	ld	a,h
	cp	d
	jp z,	..end
..tst:	ld	a,(hl)		;see if vector is on
	and	(1<INUSE)
	jr z,	..inc		;if not look at another
	djnz	..ilp
	jp	..done
..end:	ld	hl,Vectors+VLEN	;first non-man vector
..done: ld	(L.PTR),hl		;next one to look at
	call	BUL.V#		;rewrite & vector bolts
; now that bolts have done hitting things
; update Vectors (coordinates)
	ld	hl,(OLD3)		;first vector written
	call	SECT3
	ld	hl,(OLD2)
	call	SECT3
	ld	hl,(OLD1)		;last vector written
	call	SECT3		;update animation and vector
	call	TIMERS		;do job timers
	pop	af		;restore all registers
	ex af,af'
	pop	bc
	pop	de
	pop	hl
	pop	ix
	pop	iy
BYE:	ld	a,1		;turn on interrupts
	out	(I.ENAB),a
	out	(NMION),a		;prob get nmi immed'ly
	ld	a,ITAB/256
	ld	i,a
	im2
	pop	af
	ei
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; all below assume iy -> vector
;	and [v.ptr]=iy
;----------------
; erase pattern
;________________
SECT1:	ld	(V.PTR),hl
	liyd	V.PTR
	bit	ERASE,(hl)		;hl->v.stat
	jp z,	SECT2
	res	ERASE,(hl)		;never erase more than once
	inc	hl		;->setup
	ld	a,(hl)		;get old magic value
	out	MAGIC
	inc	hl		;->old address
	ld	e,(hl)
	inc	hl		;->o.a.h
	ld	d,(hl)
	inc	hl		;->old pattern
	ld	a,(hl)		;hl:=[hl]
	inc	hl		;->o.a.h
	ld	h,(hl)
	ld	l,a
	call	PLOT		;xor write
	ld	hl,(V.PTR)
;----------------
; write pattern
;----------------
SECT2:	bit	WRITE,(hl)		;check if should write
	ret z
	res	WRITE,(hl)		;never write twice either
	ld	de,P.X
	add	hl,de		;->p.x
	ld	e,(hl)		;x position
	inc	hl		;->v.y
	inc	hl		;->p.y
	ld	d,(hl)		;y position
	inc	hl
	ld	B,90H		;xor write
	ex de,hl
	call	RtoA
	ld	SETUP(iy),A	;save magic
; get pattern address := @pattern.pointer
	ex de,hl
	ld	a,(hl)		;->d.p.l
	inc	hl
	ld	h,(hl)		;->d.p.h
	ld	l,a
	ld	a,(hl)		;get word in table
	inc	hl		;which ->pattern
	ld	h,(hl)
	ld	l,a
; check for offset pattern
	inc	hl		;->y
	ld	a,(hl)
	dec	hl
	bit	7,A
	jr z,	..noo		;normal non offset
	and	7FH
	ld	b,a
	ld	c,(hl)
	inc	hl
	inc	hl
	ex de,hl
	ld	a,(Flip)
	or	a
	jp z,	..down
	sbc	hl,bc
	.byte	(3eh)		;mvi a,(dad b)
..down: add	hl,bc
	ex de,hl
; store pattern away
..noo:	ld	O.P.L(iy),L
	ld	O.P.H(iy),H
	ld	O.A.L(iy),E	;save screen address
	ld	O.A.H(iy),D
	call	PLOT
	ld	hl,(V.PTR)
; check intercept
	in	WHATI
	bit	7,A		;nz means 1 writtn over 1
	ret z
	set	INEPT,(hl)		;set intercept bit
	ret			;no point in moving object
;--------------------------
; move position, animate
;--------------------------
SECT3:	ld (V.PTR),hl
;	bit	Color,(hl) 
;	call nz,	COLMAN#
	bit	MOVE,(hl)		;should be moved?
	ret z
	push	hl
	pop	iy		;iy->vector
; MOVE bit reset by routine that set it
	ld	de,TPRIME
	add	hl,de		;->tprime
	ld	a,(hl)
	inc	hl		;->time
	dec	(hl)		;dec time,if0 then
	ret nz
	ld	(hl),a		;time:=tprime
; vector in x
	inc	hl		;->V.X
	ld	a,(hl)
	inc	hl		;->p.x
	add	(hl)
	ld	(hl),a
;vector y
	inc	hl		;->v.y
	ld	a,(hl)
	inc	hl		;->p.y
	add	(hl)
	ld	(hl),a
; update pattern [animate]
	inc	hl		;->d.p.l
	ld	e,(hl)
	inc	hl		;->d.p.h
	ld	d,(hl)		;get table address
	inc	de
	inc	de		;point to next entry
	ex de,hl
	ld	a,(hl)		;if0 then
	inc	hl
	or	(hl)		;jump
	jr nz,	..sk
	inc	hl		;get pointer
	ld	a,(hl)		; to value of next word
	inc	hl
	ld	h,(hl)
	ld	l,a		;->head of table
	.byte	(3eh)		;mvi a,dcx h (7 T not 12)
..sk:	dec	hl
	ex de,hl			;de=table address
	ld	(hl),d		;hl->d.p.h
	dec	hl
	ld	(hl),e		;->d.p.l
	ld	a,(1<Write)!(1<Erase)
	ld	hl,(V.Ptr)
	or	(hl)		;or with V.STAT
	ld	(hl),A
	ret
;-----------------------
; decrement job timers
;-----------------------
TIMERS: ld	hl,Timer0
	ld	b,24
..loop: ld	a,(hl)
	or	a
	jr z,	..dl
	dec	(hl)
..dl:	inc	hl
	djnz	..loop
	ret
;-------------------------------
; write pattern with intercept
; 2 byte wide routine	
;-------------------------------
;hl->pattern	de->screen data
PLOT:	ld	B,0		; bc=pattern x size
	ld	a,(hl)
	inc	hl
	dec	a
	jp z,	X1PLOT		;if not 1 then 2 bytes only!
	ld	a,(Flip)
	or	a		;check flip state
	ld	a,(hl)		; y size
	inc	hl
	jr nz,	XF2PLT
	ld	bc,Hsize-2
	ex de,hl			;de->pattern byte
Y.LOOP: ex af,af'			;save y size
	ld	a,(de)		;get pattern byte
	inc	de		;->next pattern byte
	ld	(hl),a		;write to screen
	inc	hl
	ld	a,(de)		;repeat for next byte
	inc	de
	ld	(hl),a
	inc	hl
	ld	(hl),b		;flush shifter(b=0)
	ex af,af'
	add	hl,bc		;hl->next line of screen
	dec	a		;--y.size
	jr nz,	Y.LOOP
	ret
;-----------------------------------------
; two byte wide upside-down plot routine
;-----------------------------------------
XF2PLT: ld	bc,2-Hsize
	ex de,hl			;de->pattern byte
Y.Lp:	ex af,af'			;save y size
	ld	a,(de)		;get pattern byte
	inc	de		;->next pattern byte
	ld	(hl),a		;write to screen
	dec	hl
	ld	a,(de)		;repeat for next byte
	inc	de
	ld	(hl),a
	dec	hl
	ld	(hl),0		;flush shifter(b=0)
	ex af,af'
	add	hl,bc		;hl->next line of screen
	dec	a		;--y.size
	jr nz,	Y.Lp
	ret
;-----------------------------
; one byte wide plot routine
;-----------------------------
;hl->pattern	de->screen data
X1PLOT: ld	a,(Flip)		;hl->y size
	or	a		;check flip state
	ld	a,(hl)		;load y size
	inc	hl		;->first data byte
	jr nz,	XF1PLT
	ld	bc,Hsize-1
	ex de,hl			;de->pattern byte
..loop: ex af,af'			;save y size
	ld	a,(de)		;get pattern byte
	inc	de		;->next pattern byte
	ld	(hl),a		;write to screen
	inc	hl
	ld	(hl),b		;flush shifter(b=0)
	ex af,af'
	add	hl,bc		;hl->next line of screen
	dec	a		;--y.size
	jr nz,	..loop
	ret
;-----------------------------------
; flipped 1 byte wide plot routine
;-----------------------------------
XF1PLT: ld	bc,1-Hsize
	ex de,hl			;de->pattern byte
..loop: ex af,af'			;save y size
	ld	a,(de)		;get pattern byte
	inc	de		;->next pattern byte
	ld	(hl),a		;write to screen
	dec	hl		;backwards writing
	ld	(hl),0		;flush shifter(b=0)
	ex af,af'
	add	hl,bc		;hl->next line of screen
	dec	a		;--y.size
	jr nz,	..loop
	ret
BYTE2:: .byte	0
;------------------
; interrupt table
;------------------
	.loc	3FFCH

ITAB:	.word	INT		;video
BYTE4:: .word	0		;xsum

	.loc	4000h
	.word	BYTE1#
	.word	BYTE2
	.word	BYTE3#
	.word	BYTE4
	.word	BYTE5#

	.end
