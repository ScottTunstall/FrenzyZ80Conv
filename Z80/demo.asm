B>type demo.asm

.title	"Demo Game"
.sbttl	"FRENZY"
.ident DEMO
;~~~~~~~~~~~~~~~~~~
;    Demo Mode
;------------------
.insert equs
.extern PLAY,ScorePtr
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Play Demo Game
;-----------------------------
PLAYDEMO::
	call	ScorePtr	;point at players score
	ld	de,SavedScore
	call	ScoreMove

	ld	hl,(Seed)
	push	hl

	ld	hl,DemoData	;fake the control
	ld	(DemoPtr),hl		; inputs data

	ld	a,-1		;set to demo mode
	ld	(Demo),a
	xor	a
	ld	(WallPts),a

	ld	bc,Other-Player	;move demo setup data
	ld	de,Player	; into player data
	ld	hl,D.DATA
	ldir

	call	PLAY		;play one deaths worth

	pop	hl		;restore random number seed
	push	af		;save button status
	ld	(Seed),hl
	call	RANDOM		;do another randomize

	call	ScorePtr	;restore old player score
	ld	de,SavedScore
	ex de,hl
	call	ScoreMove

	pop	af		;restore button status
	jp	DemoRet#

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Move Score and Zero Source
;--------------------------------------
ScoreMove:
	ld	B,3		;score bytes
ZapLoop:
	ld	a,(hl)		; get score byte
	ld	(hl),0		;zero it
	inc	hl
	ld	(de),a		;store in save area
	inc	de
	djnz	ZapLoop
	ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Random Number Generator
;--------------------------------------
RANDOM::
	push	hl
	ld	hl,(Seed)
	ld	d,h
	ld	e,l
	add	hl,hl
	add	hl,de
	add	hl,hl
	add	hl,de
	ld	de,3153H
	add	hl,de
	ld	(Seed),hl
	ld	a,h
	pop	hl
	ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Demo Game Initialization Data
;--------------------------------------
; Player Info Area
;Player	 Player # of this player
;RoomX	 room #
;ManX	 mans room-exit position
;MPY=	 ManX+1
;DEATHS	 # of man lives
;PERCENT %  of robots
;Rbolts	 # of robot bolts
;Rtime	 robot speed
;Rwait	 robot hold off time
;STIME	 time until otto attacks
;XtraMen=extra man flags
;--------------------------------------
D.DATA: .byte	1	;Player
	.byte	20,40	;RoomX
	.byte	30	;ManX
	.byte	116	;MPY
	.byte	1	;DEATHS
	.byte	8	;PERCENT
	.byte	1	;Rbolts
	.byte	32	;Rwait
	.byte	4	;STIME
	.byte	0	;XtraMen
	.byte	8	;RoomCnt
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Fake Control Input Data
; if bit 7=1 then it is a delay of(X  7fh) 60ths
;--------------------------------------
DemoData:
.byte	01h,8fh,18H,05H,8Fh,1Ah,14h,02h,9Fh,1Ah,02h,94h,16h,0Ah,92h,16h
.byte	02h,0BFh,14h,8Fh,09h,9Fh,1Ah,8Fh,14h,8Fh,09h,0BFh,02h,0BFh,14h,8Fh
.byte	14h,8Fh,0Ah,94h,0Ah,9Fh,02h,0CFh,14H,-1,11h,11h,11h,11h,11h,11h
.byte	11h,11h,11h,11h,11h,9Fh,12h,04h,9fh,16h,9fh,14h,0,-1,-1,-1

	.end
