B>type powerup.asm

.title	"Powerup tests"
.sbttl	"FRENZY"
.ident	POWERUP
;----------------
; power up tests
;----------------
.insert EQUS
.extern MAIN,NMI,DSPSW,ALIGN
; locations NMIflg are scratch flags. they are cleared by the game
; when it starts up. NMIflg is used to select which nmi routine to run.

%Zero	==	.

.main.::
	nop		;this must be here for the sound processor
	di		;this is a good idea.
	xor	a
	out	NMIOFF
	ld	i,a
; test vfb signature analysis dip
	in	DIP1	;bottom dip bank
	bit	0,A
	jr nz,	VFBSA	;do vfb signature analysis if switch one closed
	bit	2,A
	jr nz,	DSPSW
	bit	3,A
	jr nz,	ALIGN
	ld	ix,ROMTST
	jr	D2

;MACROS
.define PCALL[ADR]=[
	ld	ix,.+4+3
	jp	ADR
]

ROMNUM: .byte	4		;number of roms (not including utility)
RAMST:	.word	BatteryRAM	;start of battery backup ram
RAMS12: .word	Credits-BatteryRAM-2	;length of battery backup ram

; flash LED ring bell
D0:	ld	bc,00		;delay
DEL1:	dec	c
	jr nz,	DEL1
	djnz	DEL1
D1:	in	a,(66H)		;led on
D2:	ld	a,1		;tone on
	ld	bc,0141H
	ld	de,8247H
D3:	OUTP	B		; 01 to 41 or 51
	dec	c
	OUTP	D		; 82 to 40 or 50
	inc	c
	inc	c
	OUTP	B		; 01 to 42 or 52
	inc	c
	OUTP	B		; 01 to 43 or 53
	inc	c
	inc	c
	inc	c
	OUTP	E		; 47 to 46 or 56
	ld	c,51H
	dec	a
	jr z,	D3
	ld	bc,00		;delay
DEL2:	dec	c
	jr nz,	DEL2
	djnz	DEL2
	in	a,(67H)		;led off
	xor	a
	out	(40H),a		;tone off
	out	(50H),a		;tone off
	jp	(ix)
;-------------------
; place nmi in here
;-------------------
.blkb	66h-(.-%Zero)
.ifn	(.-%Zero)-66h,[.error /NMI Address/]
	out	NMIOFF
	push	af	;don't change this without fixing nmi in file main
	ld	a,NMIflg
	or	a
	jr nz,	NMIADD	; do test nmi
;	pop	af	;done in nmi
	jp	NMI

; ROM test
;this routine reads romnum from the first game rom.
;it tests the checksum in the first romnum game roms and flags an error
;if there is one. It checks the remaining game roms to see if they contain
;any zeros. if a rom does, it tests its checksum and flags an error if
;there is one. it tests the checksum of the utility rom and flags an error
;if necessary. If I=1 it goes to scrram if no error and to exclp if an error.
;e will equal
;1 error in game rom 6 [C000-Cfff]
;2		5 [3000-3Fff]
;3		3 [2000-2Fff]
;4		1 [1000-1Fff]
;80 error in utility rom [0-Fff]
;if i = 0 and there is an error it will halt if no error it will go to romrtn.
ROMTST:: ld	E,4
	ld	ix,1000H
ROM1:	ld	bc,1000H		;bc = 4096
	ld	H,0		;h = 0
	ld	L,0FFH		;l = ff
ROM2:	ld	a,(ix+0)		;a = [ix]
	ld	d,a
	and	l
	ld	l,a		;l = l and a
	ld	a,d
	add	a,H
	ld	h,a		;h = h + a
	inc	ixx		;ix = ix + 1
	dec	c
	jr nz,	ROM2
	djnz	ROM2		;loop 2048 times
	ld	a,ROMNUM
	cp	0FFH		;bad system rom
	jr z,	ROM5
	ld	a,E
	cp	2
	jr nz,	..
	ld	ix,0C000H
..:	or	a
	jp	ROM3		;jmp if testing system rom
	ld	a,l		;test for empty socket
	inc	a
	jr z,	ROM4		;jmp to rom4 if l = ff
ROM3:
;	ld	a,0FFH
	ld	a,e		;get rom number
	cp	h		;xsum = romnum?
	jr nz,	ROM5		;jmp to rom5 if checksum <> ff
ROM4:	ld	a,e		;here if chksm = ff or empty socket
	rlc	a		;contains all zeros
	jc	ROMRTN		;to romrtn if e = 80
	dec	e		;e = e - 1
	jr nz,	ROM1		;to rom1 if e <> 0
	ld	a,i
	and	a
	jr nz,	SCRRAM		;jump to scrram if in sa
	ld	ix,0		;ix = 0
	ld	E,080H		;e = 80h
	jr	ROM1		;to rom1 to start new rom
ROM5:	ld	a,i		;here if checksum error
	and	a
	jr nz,	EXCLP		;to exclp if in sa
CKTRAP::			;halt if in powerup (cksum error)
	jr	.		;hang in the real system
;
ROMRTN: PCALL	D0		;in power up, ring bell & led
	jp	SCRRAM
BYTE1:: .byte	0

; zpu sa loop
ZPUSA:	ld	a,1
	ld	i,a		;i = 1
	jp	ROMTST

; you get here by restarting with the sae connector in the test position
;	.loc	100H
.blkb	100h-(.-%Zero)
.ifn	(.-%Zero)-100h,[.error /100 Address/]
	jr	ZPUSA

; sa error execution loop
; e = one of the following numbers upon entering this routine
;e = 20 no ram or rom errors - - sa = 0
;e = 1	rom error 3800-3fff
;e = 2	rom error 3000-37ff
;e = 3	"	"	2800-2fff
;e = 4	"	"	2000-27ff
;e = 5	"	"	1800-1fff - - sa = 5220 VCC = 8A02
;e = 6	"	"	1000-17ff
;e = 10 ram error both nibbles - - sa = 6u6f
;e = 11 ram error low nibble - - sa = fa6p
;e = 12 ram error high nibble - - sa = ufp4
;the routine will loop forever and a signature corresponding
;to the value of e can be read on a13 with the rising edge of
; 0 as the clock and a15 as the start/stop signal
EXCLP:	ld	bc,08C0H
	ld	hl,0H
	ld	D,8
RDLP:	ld	a,(hl)	;read once from each rom and
	add	hl,bc	;ram chip, write to ram chips
	xor	a
	ld	r,a
	ld	(1000H),a
	dec	d
	jr nz,	RDLP
	ld	c,7FH	;c = 7f
	ld	D,20H
INPLP:	ld	a,e
	and	20H
	ld	b,a	;b = e and 20h
	in	a,(C)	;input w.bit 5 of e on a13
	rrcr	E	;rotate e right
	dec	c	;c = c - 1
	dec	d
	jr nz,	INPLP	;do it for c=7f to 60(ports on zpu board)
	ld	a,80H
	ld	bc,8057H
OUTLP:	OUTP	A
	dec	b
	dec	c
	rrcr	A
	jr nc,	OUTLP
	ld	c,47H
OUTLP1: OUTP	A
	dec	c
	rrcr	A
	jr nc,	OUTLP1
	jr	EXCLP

;	scratch ram test
;
;this routine tests the scratchpad ram, starting at location ramst,
;and going to location ramst+rams12-1. ramst and rams12 are read from
;the first game rom. If I=1 then you are in sa and the routine goes
;to exclp with e = 20h if no errors, e = 12 if only errors in bits 4-7,
;e = 11 if only errors in bits 0 - 3, or e=10 if errors in both.
;if i = 0 then you are in game power up routine and it will halt if
;there are errors or go to ramt if no errors.
SCRRAM: ld	hl,(RAMST)
	lbcd	RAMS12
SCR1:	ld	(hl),55H		;fill ram with 55 s
	dec	hl
	cci			;bc = bc - 1
	jpo	SCR2		;jump if bc=0
	inc	hl		;hl = hl + 1
	jr	SCR1		;loop
SCR2:	ld	D,0AAH
	ld	sp,0FFFFH
SCR3:	lbcd	RAMS12		;bc = rams12
SCR4:	ld	a,d
	cpl			;a = invert d
	xor	(hl)
	jr nz,	SCRERR		;jump if error
	ld	(hl),d		;[hl] = d
	dec	hl
	cci			;bc = bc - 1
	jpe	SCR6		;jump if bc <> 0
	ld	a,d
	cp	55H
	jr z,	SCR5		;to scr5 if d = 55h
	ld	sp,1H		;sp = 1
	ld	D,55H		;d = 55
	jr	SCR3
SCR6:	add	hl,sp		;hl = hl + sp
	jr	SCR4
SCRERR: ld	d,a
	ld	a,i
	rrcr	A
	jr c,	SCR7		;jump if in sa
	hlt			;halt if in power up
SCR7:	ld	E,12H
	ld	a,d
	and	0FH		;test for error in low nibble
	jp z,	EXCLP		;jmp w. e = 12 if no error
	dec	e
	ld	a,d
	and	0F0H		;test for error in high nibble
	jp z,	EXCLP		;jump w. e = 11 if no error
	dec	e
	jp	EXCLP		;jump w. e=10 if error in both
SCR5:	ld	a,i
	rrcr	A
	ld	E,20H
	jr nc	RAMT		;to ramt if in game powerup
	jp	EXCLP
;---------------------
; report ram errors Part of RAMTST
; bc=error bits
ERROR:	ld	hl,TABLE		;of screen addresses
	ld	de,1		; test bit
CHECK:	ld	a,b		; bad ram bit?
	and	d
	jr nz,	PLOT
	ld	a,c		; bad ram2 bit
	and	e
	jp	PLOT
RET1:	ex de,hl
	add	hl,hl		; shift test bit
	ex de,hl
	jr nc	CHECK
	ld	de,4000H		; wait value
..wt:	dec	e
	ld	a,(iy+0)		; waste time
	jr nz,	..wt
	dec	d
	jr nz,	..wt
	jp	RAMT2
;---------------+
; plot bad dips
;---------------+
PLOT:	ex af,af'			; save whether good or bad
	ld	a,(hl)		; get screen address word
	inc	hl
	exx
	ld	l,a
	exx
	ld	a,(hl)
	inc	hl
	exx
	ld	h,a
	ld	de,32-1		; offset to next line
	ld	B,3		; number of notch lines
	ex af,af'			; bad/good flag
ZORK:	or	a
	jr z,	GOOD1
	ld	(hl),0FCH		; half of ic
	inc	hl
	ld	(hl),03FH		; second half
	jr	ON1
GOOD1:	ld	(hl),84H		; first 1/2
	inc	hl
	ld	(hl),21H		; second 1/2
ON1:	add	hl,de		; goto next line
	djnz	ZORK
	ld	B,36		; lines of body of ic
ZAP:	or	a
	jr z,	GOOD2
	ld	(hl),0FFH
	inc	hl
	ld	(hl),0FFH
	jr	ON2
GOOD2:	ld	(hl),80H
	inc	hl
	ld	(hl),01H
ON2:	add	hl,de
	djnz	ZAP
	exx
	jp	ret1

;vfb signature analysis routine
;you get here by resetting with switch one of dip switch chip #26 closed
;	.loc	01fcH
.blkb	1fch-(.-%Zero)
.ifn	(.-%Zero)-1fch,[.error /1FC TITAB Address/]

TITAB:	.word	INTADD		;general interupts
	.word	BADINT		;general interupts with a bit stuck
;.=200
VFBSA:	ld	bc,1048H
	in	a,(C)		;in from 48
	inc	c
	in	a,(C)		;in from 49
	inc	c
	in	a,(C)		;in from 4a
	inc	c
	inc	c
	in	a,(C)		;in from 4c
	inc	c
	in	a,(C)		;in from 4d
	inc	c
	in	a,(C)		;in from 4e
	inc	c
	ld	a,1
	OUTP	A		;out 01 to 4f
	ld	bc,0048H
	in	a,(C)		;in from 48
	inc	c
	in	a,(C)		;in from 49
	inc	c
	in	a,(C)		;in from 4a
;this routine fully exercises the shifter,flopper, and intercept logic
;1.75 msec
	ld	hl,5000H
	ld	de,7000H
	ld	B,10H
VSA2:	ld	a,b
	dec	a		;a = b - 1
	out	(4BH),a		;output a to magic reg
	ld	a,80H
VSA3:	ld	(hl),a		;write a to 5000h
	ld	(de),a		;write a to 7000h
	ld	c,(hl)
	rrcr	A
	jr nc,	VSA3		;loop 8 times
	xor	a
	in	a,(4EH)		;input from intercept
	ld	a,08H
	ld	(5000H),a
	ld	(7000H),a
	xor	a
	in	4EH
	inc	hl
	inc	de
	djnz	VSA2		;loop 16 times
;this routine exercises all address bits to the ram and writes a pattern
;which can sa'ed at the serial video output
;228 usec
	ld	B,0DH		;b = 13
	ld	de,0A000H
	ld	hl,05FFEH
	ld	a,80H		;a = 80
VSA1:	dec	h
	ld	(hl),a		;[hl] = a write to ram
	ld	c,(hl)		;c = [hl] read it back
	inc	h
	scf
	ralr	L
	ralr	H
	add	hl,de
	rrcr	A		;rotate a right
	djnz	VSA1		;loop 13 times
; fill bs color ram
	ld	hl,1111H
	ld	de,1111H
	ld	sp,8800H
	ld	c,16
BS1:	ld	B,16
BS2:	push	hl
	push	hl
	push	hl
	push	hl
	djnz	BS2
	add	hl,de
	pop	af
	dcx	sp
	dcx	sp
	dec	c
	jr nz,	BS1
;----
	in	4CH	;turn on nmi
	xor	a
	in	4EH	;input interrupt feedback
	xor	a
	in	DIP1
	BIT	1,A
VSA6:	jr z,	VSA6	;loop if not to do full test
;here to do full alu test
;you get here by closing switches 1,2 of dip switch pack 1
	ld	hl,5000H
	ld	de,7000H
	ld	a,0F0H
	ld	i,a		;i = f0h
VSA10:	ld	bc,004BH
	ld	a,i
	OUTP	A		;output to magic reg
	ld	c,0
VSA11:	ld	a,c
	ld	(hl),b		;write b to 5000h
	ld	(de),a		;write c,a to 7000h
	ld	c,b
	cpl
	ld	b,(hl)		;read back from 5000h
	ld	b,a
	or	c
	jr nz,	VSA11
	ld	a,i
	sub	10H
	ld	i,a		;i = i - 16
	jr nz,	VSA10		;loop if i >= 0
VSA12:	jr	VSA12
;------------------------
; official vfb ram test
;------------------------
RAMT:	PCALL	D0		;ring bell & led
RAMT2:	ld	hl,5FFFH
	ld	de,0
	PCALL	UPDN
	ld	bc,0		;clear error bits
	ld	hl,4000H		;start of ram
	PCALL	CELL.T		;test data lines
;do up down testing for address line problems
	ld	hl,4000H
	ld	de,0055H
	PCALL	UPDN
	ld	hl,5FFFH
	ld	de,55AAH
	PCALL	UPDN
	ld	hl,4000H
	ld	de,0AAFFH
	PCALL	UPDN
	ld	hl,5FFFH
	ld	de,0FF00H
	PCALL	UPDN
	ld	a,c
	or	b
	jr nz,	ERROR
	PCALL	D0		;ring bell & led
;do color ram testing
	ld	hl,87FFH
	ld	de,0
	PCALL	UPDN
	ld	bc,0		;clear error bits
	ld	hl,8000H		;start of 1kx4 ram
	PCALL	CELL.T		;test data lines
	ld	hl,8400H		;start of 1kx4 ram
	PCALL	CELL.T		;test data lines
;do up down testing for address line problems
	ld	hl,8000H
	ld	de,0055H
	PCALL	UPDN2
	ld	hl,87FFH
	ld	de,55AAH
	PCALL	UPDN2
	ld	hl,8000H
	ld	de,0AAFFH
	PCALL	UPDN2
	ld	hl,87FFH
	ld	de,0FF00H
	PCALL	UPDN2
	ld	a,c
	or	b
..err:	jr nz,	..err
	ld	ix,SHFTST	;ring bell & led
	jp	D0
;----------------------------------
; cell test for data line problems
;----------------------------------
CELL.T: ld	D,0		; test value
C.LOOP: ld	(hl),d		; write test value
	ld	a,(hl)		; read back
	xor	d		; check for bad bits
	or	b		; add old bad bits
	ld	b,a		; save error bits
	inc	hl		; test bank2
	ld	(hl),d
	ld	a,(hl)
	xor	d
	or	c
	ld	c,a
	dec	hl
	dec	d		; new test value
	jr nz,	C.LOOP
	ld	(hl),0
	inc	hl
	ld	(hl),0
	jp	(ix)
;--------------------------------------
; up down test for addressing problems
;--------------------------------------
UPDN2:	exx
	ld	bc,800H
	jr	UPDN3
;
UPDN:	exx
	ld	bc,2000H		; length of screen
UPDN3:	exx
D.LOOP: ld	a,(hl)		; read old value
	xor	d		; set error bits
	or	b		; add old errors
	ld	b,a		; save errors
	ld	(hl),e		; store new value
	ld	a,(hl)		; test now
	xor	e		; check
	or	b		; save errors
	ld	b,a
	bit	0,E		; test direction
	jr nz,	UP
	dec	hl
;	ld a,<dec hl> for timing considerations
	.byte	3Eh		; mvi a,next byte
UP:	inc	hl
	ld	a,b		; swap b:c
	ld	b,c
	ld	c,a
	exx
	dec	c
	jr nz,	D.E
	dec	b
	jp z,	DONE
D.E:	exx
	jp	D.LOOP
DONE:	exx
	ld	a,b		; swap b:c
	ld	b,c
	ld	c,a
	jp	(ix)
;-----------------------+
; table of ic locations
; arranged by bit number
; odd bank first
;-----------------------+
.define XY[PAR1,PAR2]=[
	.word	PAR1+PAR2+4400H
]
;
C1	==	9		;column xs
C2	==	C1+4
C3	==	C2+4
C4	==	C3+4
R1	==	0		;row ys
R2	==	50*32
R3	==	100*32
R4	==	150*32
;
TABLE:	XY	C2,R3		;o0
	XY	C2,R2		;o1
	XY	C2,R1		;o2
	XY	C2,R4		;o3
	XY	C4,R1		;o4
	XY	C4,R2		;o5
	XY	C4,R3		;o6
	XY	C4,R4		;o7
	XY	C1,R3		;e0
	XY	C1,R2		;e1
	XY	C1,R1		;e2
	XY	C1,R4		;e3
	XY	C3,R1		;e4
	XY	C3,R2		;e5
	XY	C3,R3		;e6
	XY	C3,R4		;e7
;------------------------------------------------
;this routine loops forever if there is an
;error in the shifter or flopper
;if no error it turns on the led and
;tone for 1/4 second then turns them off
;and goes to alutst
SHFTST: ld	hl,6000H		;magic ram address
	ld	D,01H		;shift bit pattern
SHFT6:	ld	b,d		;b=shift bit pattern
	xor	a
	ld	c,a		;c=
	ld	e,a		;e=expected value
	ld	i,a		;i= magic value
SHFT5:	ld	a,i
	out	(4BH),a		;magic register = i
	ld	(hl),0FFH		;prime HI
	ld	(hl),d		;6000h = d
	ld	(hl),0		;6000h = 0
	ld	a,(hl)		;get result
	cp	e		;compare to expected
	jr nz,	.		;error-loop forever
	ld	a,i		;get magic value
	inc	a		;inc the shift
	ld	i,a		;store magic
	cp	10H		;compare to legal range
	jr nz,	SHFT1		;jump if .ne. 16
	ralr	D		;rotate left the bit pattern
	jr nc,	SHFT6		; so try all patterns of one bit
	ld	ix,ALUTST	;go to next test
	jp	D0		;delay, then to alutst

SHFT1:	ld	a,c		;rotate bc right
	rr	A
	rr	B		;bit pattern
	rr	c
	ld	e,c		;e = c
	ld	a,i		;check if floping
	cp	8		;8=flop
	jr c,	SHFT5		;if i<8 to shft5
	ld	a,8		;this routine sets
SHFT4:	rrcr	B		;e = b flop
	ralr	E		;does not affect b
	dec	a
	jr nz,	SHFT4
	jr	SHFT5

;this routine loops forever if there is an
;error in the alu or interrcept logic
;if no error it turns on the led and
;tone for 1/4 second then turns them off
;and goes to inttst

ALUTST: ld	E,0
	ld	ix,ALUSIM	;ix = alusim
	ld	hl,6000H		;hl = 6000
	ld	bc,0101H		;bc = 0101
ALU2:	ld	a,e
	out	(4BH),a		;e to magic reg
	ld	a,b
	ld	(4000H),a		;4000h = b
	ld	(hl),c		;6000h = c
	ld	a,c
	jp	(ix)		;simulate the alu
ALURET: xor	(hl)		;xor simulation with [hl]
	jr nz,	.		;loop if not equal
	ld	(hl),a		;(6000h) = 0
	ld	a,b
	and	c
	jr z,	ALU1
	ld	a,80H
ALU1:	ld	d,a		;simulated intercept in bit 7 of d
	in	4EH
	xor	d
	ral
	jr c,	.		;loop if intercept error
	rlc	b		;rotate b and try again
	jr nc,	ALU2
	rlc	c		;rotate c and try again
	jr nc,	ALU2
	inc	ixx
	inc	ixx
	inc	ixx
	ld	a,10H		;update alu function
	add	a,E
	ld	e,a
	jr nc,	ALU2
	ld	ix,INTTST
	jp	D0		;delay then to inttst
;
ALUSIM: NOP			;0,a
	jr	ALURET
ALUOR:	or	b		;1,a or b
	jr	ALURET
	cpl			;2, (a + not(b)) , not(not(a) and +b)
	jr	ALUANC
	xor	a		;3, 1
	jr	ALUCMP
ALUAN:	and	b		;4, a and b
	jr	ALURET
	ld	a,b		;5, b
	jr	ALURET
	xor	b		;6,not(a eor b)
	jr	ALUCMP
	cpl			;7, not(a) or b
	jr	ALUOR
	cpl			;8, (a and not(b)), not(not(a) or b)
	jr	ALUORC
	xor	b		;9, a eor b
	jr	ALURET
	ld	a,b		;10, not(b)
	jr	ALUCMP
ALUANC: and	b		;11, not(a and b)
	jr	ALUCMP
	xor	a		;12, 0
	jr	ALURET
	cpl			;13, not(a) and b
	jr	ALUAN
ALUORC: or	b		;14, not(a or b)
	jr	ALUCMP
ALUCMP: cpl			;15, not(a)
	jr	ALURET

;this routine loops forever if interupts or
;nmi does not work properly. if they are
;ok it turns the led and tone on for 1/4 second
;then turns them off and goes to gamst

INTTST	==	.
	IM2			;mode 2
	ld	a,01	;table start
	ld	i,a		;point to 7fch
	ld	ix,MAIN
	ld	a,0FFH
	out	(4FH),a		;enable interupt
	ld	b,a
INTADD: ld	sp,SCREEN-1	;give a stack pointer position
	in	a,(4EH)		;clear int
	rar
	ralr	B
	ld	a,b
	xor	55H
	jr z,	NMITST
	ei
BADINT: jr	.

NMITST: out	(4FH),a		;disable interupts
	ld	B,0FFH
NMIADD: ld	sp,SCREEN-1	;give a stack pointer position
	in	a,(4DH)		;disable nmi
	in	a,(4EH)		;read center/bottom screen
	rar
	ralr	B
	ld	a,b
	xor	020H
	jp z,	D0		;to delay if done
	in	a,(4CH)		;enable nmi
	jr	.

	.end
