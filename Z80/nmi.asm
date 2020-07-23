B>type nmi.asm

.title	"Non-Maskable Interrupt"
.sbttl	"FRENZY"
.ident NMI
;------------------------+
; Non-Maskable Interrupt |
;------------------------+
.insert EQUS
CR1	==	40H
VOICE	==	44H
;------------------------+
; Non-Maskable Interrupt |
;------------------------+
NMI::
;	push	af		;done at 66h
	push	bc
	push	de
	push	hl
	call	S.BOOK#		;CHECK CLEAR BUTTON
	jr nz,	BOOKS#
	ld a,	(Demo)
	or	a
	jr z,	..ok
	ld	a,1
	ld	(TCR1),a
	jp	..no
..ok:	call	SCPU		;0=NORMAL
..no:	call	C.LOAD
; Do voice if not demo
	ld a,	(Demo)
	or	a
	jr nz,	..stop
	ld hl,	(V.PC)		;GET VOICE PC
..lop:	ld	a,h		;IF 0 SKIP
	or	l
	jr z,	..exit
	in	a,(VOICE)		;IF BUSY SKIP
	and	0C0H
	cp	40H
	jr nz,	..exit
	ld	a,(hl)		;GET DATA
	bit	7,A		;IF NEGATIVE SKIP
	jr nz,	..stop
	inc	hl
	out	(VOICE),a		;OUTPUT THE DATA
	bit	6,A		;IF A WORD
	jr z,	..exit		; WAIT A 60TH
	jp	..lop		;DO ANOTHER BYTE
..stop: ld	hl,0		;STOP TALKING
..exit: ld (V.PC),hl		;STORE POINTER
	pop	hl
	pop	de
	pop	bc
	pop	af
	out	(NMION),a
	retn
;--------------------------------------+
; OUTPUT DATA TO ALL REGISTERS FROM RAM
; DO CONTROL REGISTERS
;
C.LOAD: ld	hl,TCR1		;->CR1 TRACKER
	ld	b,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	c,CR1+1		;->CR2
	res	0,B		;ALL COUNTERS GO
	set	0,D		;SELECT CR1
	OUTP	D		;2
	dec	c		;->C1:2
	OUTP	B		;1
	inc	c		;->C2
	res	0,D		;SELECT CR3
	OUTP	D		;2
	dec	c		;->C1:3
	OUTP	E		;3
;DO TIMERS
T.LOAD: inc	c
	inc	c		;->MSB BUFFER
	ld	B,3
	ld	a,c		;SAVE MSB PORT ADDRESS
	inc	c		;->LSB LATCH #1
	ld	d,c		;SAVE LSB PORT ADDRESS
T.LOOP: ld	e,(hl)		;GET LSB DATA
	inc	hl
	ld	c,a
	ld	a,(hl)
	inc	hl
	OUTP	A
	ld	a,c
	ld	c,d
	OUTP	E
	inc	d
	inc	d		;->LSB LATCH#N+1
	djnz	T.LOOP
;DO NOISE AND VOLUMES
V.LOAD: dec	c		;->NOISE/VOLUME PORT
	ld	a,0		;BITS6,7 FOR SELECT=NOISE
	ld	B,4		;NUMBER OF REGISTERS
V.LOOP: or	(hl)		;OR IN DATA[BETTER BE GOOD]
	inc	hl		;->NEXT REGISTER DATA
	OUTP	A		;OUTPUT
	and	0C0H		;SELECT NEXT REGISTER
	add	a,40H
	djnz	V.LOOP
	ret
.PAGE
.title	"SOUNDS AND MACROS"
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Sound Process
;_______________________________
SCPU::	ld a, (RFSND)
	or	a
	call nz,RSND
	ld a, (WLSND)
	or	a
	call nz,    WSND
	ld hl,	(PC0)		;get where we left off
	ld	A,H		;if 0 don't do anything
	or	L
	ret z
	jp (hl)			;goto routine
; stop completely
$STOP:	ld	hl,0
	ld	(PC0),hl
	ret
; wait for next interrupt
$TICK:	pop	hl		;get where it was
	ld	(PC0),hl		;save 
	ret			;back to nmi routine
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Sound Macros
;_______________________________
.slist
.xlist
.define STOP=[	jp	$STOP
]
.define TICK=[	call	$TICK
]
.define BR[LABEL]=[	jp	LABEL
]
.define SOB[ByteAdr,Label]=[
	ld	hl,ByteAdr
	dec	(hl)
	jr nz,	Label
]
.define MVIB[Value,Location]=[
	ld	a,Value
	ld	(Location),a
]
.define MVIW[Value,Location]=[
	ld	hl,Value
	ld	(Location),hl
]
.define ADIB[Value,Location]=[
	ld	hl,Location
	ld	a,(hl)
	add	a,Value
	ld	(hl),a
]
.define ADIW[Value,Location]=[
	ld hl,	(Location)
	ld	de,Value
	add	hl,de
	ld	(Location),hl
]
.define MVIBM[Addr,V0,V1,V2,V3,V4,V5,V6,V7]=[
	ld	hl,Addr
	ld	(hl),V0
	$XB	V1,V2,V3,V4,V5,V6,V7
]
.define $XB[V0,V1,V2,V3,V4,V5,V6]=[
.ifb	[V0],[.exit]
	inc	hl
	ld	(hl),V0
	$XB	V1,V2,V3,V4,V5,V6
]
.define MVIWM[Addr,V0,V1,V2,V3,V4,V5,V6,V7]=[
.ifb	[V0],[.exit]
	ld	hl,V0
	ld hl,	(Addr)
	MVIWM	\Addr+1,V1,V2,V3,V4,V5,V6,V7
]
.define QUIET=[
	ld	hl,0
	xor	a
	ld	(TCR1),hl
	ld	(TCR3),a
	ld	(NOISE),hl
	ld	(VOL2),hl
]
.define SETUP[R1,R2,R3,$NOISE,$VOL1,$VOL2,$VOL3]=[
	ld	hl,TCR1
	ld	(hl),R1
	inc	hl
	ld	(hl),R2
	inc	hl
	ld	(hl),R3
	ld	hl,NOISE
	ld	(hl),$NOISE
	inc	hl
	ld	(hl),$VOL1
	inc	hl
	ld	(hl),$VOL2
	inc	hl
	ld	(hl),$VOL3
]
.define TIMERS[T1,T2,T3]=[
	ld	hl,T1
	ld	(TMR1),hl
	ld	hl,T2
	ld	(TMR2),hl
	ld	hl,T3
	ld	(TMR3),hl
]
.define START[Sound,Priority]=[
Sound:: push	af
	ld	a,(PC1)		;now priority
	cp	Priority	;new "
	jc	..load
	jp z,	..load
	pop	af
	ret
..load: ld	a,Priority
	ld	(PC1),a
	push	hl
	ld	hl,$'Sound
	ld	(PC0),hl
	pop	hl
	pop	af
	ret
$'Sound:
]
.rlist
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Sounds
;_______________________________
NoSnd:: push	af
	push	hl
	QUIET
	xor	a
	ld	(PC1),a
	pop	hl
	pop	af
	ret

FAP:	QUIET
	xor	a		;zap priority
	ld	(PC1),a
	STOP

START	SFIRE,10
	SETUP	92H,92H,92H,0,5,6,6
	TIMERS	50,50,50
	MVIB	50,AC0
..2:	TICK
	ADIW	15,TMR1
	ADIW	17,TMR2
	ADIW	16,TMR3
	SOB	AC0,..2
	MVIB	50,AC0
..3:	TICK
	ADIW	10,TMR1
	ADIW	13,TMR2
	ADIW	15,TMR3
	SOB	AC0,..3
	BR	FAP

START	SFRY,13
	SETUP	90H,90H,90H,0,6,7,7
	MVIB	16,AC0
	MVIW	230,TMR1
..1:	MVIWM	TMR2,20,10
	MVIB	20,AC1
..2:	TICK
	ADIB	5,TMR2
	ADIB	30,TMR3
	SOB	AC1,..2
	ADIB	-4,TMR1
	SOB	AC0,..1
	BR	FAP

START	SBLAM,11
	SETUP	82H,80H,80H,3,7,7,7
	TIMERS	1,1,5
	TICK
	MVIBM	TCR1,92H,90H,90H
	MVIB	55,AC1
..1:	MVIB	6,AC0
..2:	TICK
	SOB	AC0,..2
	ADIW	1,TMR1
	SOB	AC1,..1
	BR	FAP

START	SRFIRE,11
	SETUP	92H,92H,92H,0,6,6,7
	TIMERS	20,45,90
	MVIB	4,AC1
..1:	MVIB	80,AC0
..2:	TICK
	ADIW	8,TMR1
	ADIW	17,TMR2
	ADIW	47,TMR3
	SOB	AC0,..2
	SOB	AC1,..1
	BR	FAP

START	SXLIFE,12
	SETUP	92H,92H,92H,0,7,7,7
	TIMERS	200,60,40
	MVIB	20,AC1
..1:	MVIB	20,AC0
..2:	TICK
	ADIW	20,TMR1
	ADIW	6,TMR2
	ADIW	4,TMR3
	SOB	AC0,..2
	MVIB	20,AC0
..3:	TICK
	ADIW	-20,TMR1
	ADIW	-6,TMR2
	ADIW	-4,TMR3
	SOB	AC0,..3
	SOB	AC1,..1
	BR	FAP
;rick O'shay sound
RSND:	xor	a
	ld	(RFSND),a		;clear flag
	ld	(WLSND),a		;clear flag
	ld	a,(PC1)		;now priority
	cp	11		;new "
	jc	..go
	jp z,	..go
	ret
..go:				;do the sound
	ld	a,11
	ld	(PC1),a
	SETUP	92H,92H,92H,0,7,7,7
	TIMERS	48,56,64
	ld	a,r			;get refresh reg!
	and	1fh
	ld	(AC1),a
..1:	TICK
	ld a,	AC1
	and	7
	jr nz,	..on	
	ld	hl,VOL1
	ld	a,(hl)		;v1
	dec	a
	ld	(hl),a		;v1
	inc	hl
	ld	(hl),a		;v2
	inc	hl
	ld	(hl),a		;v3
..on:	ADIB	6,TMR1
	ADIB	7,TMR2
	ADIB	8,TMR3
	SOB	AC1,..1
	BR	FAP

; Wall sound
WSND:	xor	a
	ld	(WLSND),a		;clear flag
	ld a,(PC1)		;now priority
	cp	10		;new "
	jc	..go
	jp z,	..go
	ret
..go:				;do the sound
	ld	a,10
	ld	(PC1),a
	SETUP	82H,80H,80H,3,7,7,7
	TIMERS	1,1,2
	TICK
	MVIBM	TCR1,92H,90H,90H
	MVIB	55,AC1
..1:	TICK
	ADIB	1,TMR2
	ADIB	1,TMR3
	SOB	AC1,..1
	BR	FAP

	.end

