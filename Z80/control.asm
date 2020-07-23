B>type control.asm

.title	"Input control routines"
.sbttl	"FRENZY"
.ident	CONTROLS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Control input routines
; generally return z if off, nz if on
;______________________________
.insert equs
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	wait for fire button
;______________________________
W.Fire::call	S.Fire
	jr nz,	W.Fire		;if up goto loop
..Loop: call	S.Fire
	jr z,	..Loop
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Check Fire button
;________________________________
S.Fire::
	call	S.STICK
	bit	4,A
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Book-Keeping Switch
;________________________________
S.Book::in	ZPU
	bit	7,A
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Free Credit Switch
;________________________________
S.Free::in	ZPU
	bit	0,A
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Control Stick
;________________________________
S.STICK::
	ld	a,(Flip)
	or	a
	in	a,(I.O1)
	jr z,	..fix
	in	a,(I.O3)
..fix:	cpl			;convert to positive logic
	and	1Fh		;4 direction, 1 shoot
	ret

	.end
