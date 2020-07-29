B>type main.asm

.title	"MAIN LOOP"
.sbttl	"FRENZY"
.ident MAIN
;----------------------
;	main loop
;----------------------
.insert equs
.extern GOVER,INSERT,PLAYDEMO,NMI,JobInit
.extern REST,INT,MOVEN
.extern UPHIGH,PLAY,SHOWN,RANDOM
.extern DECCRD,NoVoice,NoSnd,ItemInc
DEATH2	==	DEATHS+(OTHER-PLAYER)
;----------------------
; start of main module
;----------------------
MAIN::	di			;initial
	ld	sp,SPos		;set stack
;zero locations for sounds and battery ram scratch
	ld	hl,SPos
	ld	bc,T60cnt-SPos	;# of bytes
	call	Zap
; zero above screen ram
	ld	hl,VideoRAM
	ld	bc,ScreenRAM-VideoRam
	call	Zap
;start sounds
	call	66h		;nmi routine
;move high scores from backup
	call	CheckBooks#
	ld	hl,HIGH1		;shown
	ld	de,HIGH2		;backed up
	ld	B,5*12		;# of nibbles
	call	MOVEN
;setup debouncer coin switches
	in	a,(I.O2)
	cpl
	ld	hl,SWD		;switch debouncer
	ld	(hl),a
	inc	hl
	ld	(hl),a
; main attract loop
MLOOP::
	ld	sp,SPos		;reset stack
	xor	a
	ld	(StartB),a		;no start yet
	call	SET1		;reset everything
	call	TITLE#
	call	CheckBooks
	ld	b,8
	call	COIN1#
MENTR:	xor	a
	ld	(StartB),a		;no start yet
	call	GOVER		;high score display
	call	INSERT		;insert coin/press start
	ld	b,3
	call	COIN1#		;check coins and wait
	call	XMLEV#		;insert coin/press start
	call	COIN0#		;check coins and wait
	jp	PLAYDEMO	;play a demo game
DemoRet::
	jp z,	MLOOP
	jp	GO		;play a complete game
;---------------
SET1:	di
	xor	a
	ld	(player),a		;forces upside up mode
	dec	a		;-1
	ld	(DEMO),a		;is demo mode
	call	JobInit
	call	REST		;stop bolt and vectors
	ld	a,55h		;alternater
	ld	(IntTyp),a
	call	INT		;start interrupts
	ret
;-----------------------
; Play 1 complete game
;-----------------------
; take away credits and go play a game
GO::
	ld	sp,SPos		;reset stack
	ld	hl,StartB
	set	7,(hl)		;no jump while playing
	call	SET1		;reset everything
	ld	a,(StartB)
	ld	l,a
	call	DECCRD		;take away 1st player credit
	bit	1,L		;test for 2 player button
	ld	a,1		;# of players:=1
	jr z,	..st		;0=one player game
	call	DECCRD		;take away 2nd player credit
	ld	a,2		;# of players:=2
..st:	ld	(N.PLRS),a		;store # of players
	cp	2
	jr z,	..two
	ld	c,3		;1 player plays
	call	ItemInc
	jr	..tp
..two:	ld	c,4		;2 player games
	call	ItemInc
	ld	c,5		;total plays
	call	ItemInc
..tp:	ld	c,5		;total plays
	call	ItemInc
	call	ZSCORE		;zero the score
	ld	bc,OTHER-PLAYER
	ld	de,PLAYER
	ld	hl,Idata
	ldir			;initial the player
	ld	hl,(SEED)
	ex de,hl
	ld	hl,(OnTime+10)	;part of second count
	add	hl,de
	ld	(SEED),hl		;new random room
	ld	(RoomX),hl
	in	a,(Dip2)		;extra lives
	and	15
	ld	(XtraMen),a
	xor	a
	ld	(DEMO),a		;not a demo
	ld	(CHIKEN),a		;not a chicken yet
	ld	(RoomCnt),a		;hasn't seen any rooms yet
	inc	a
	ld	(T.TMR),a		;set talk timer for 1 second
	ld	hl,PLAYER	; Set 2nd players bank
	ld	de,OTHER
	ld	bc,OTHER-PLAYER
	ldir
	ld	a,2		;SET AS PLAYER NUMBER 2
	ld	(hl),a
; Turn second player off if 1 player game
	ld	a,(N.PLRS)
	cp	2
	jr z,	SLOP
	xor	a		;if no deaths
	ld	(DEATH2),a		; then no playing either
SLOP:	ei
	ld	hl,(Manxi)
	ld	(ManX),hl
	ld	a,(PLAYER)
; Play out one life
	call	PLAY
	call	RANDOM
	WAIT	90		;pause to show trouble
	call	REST		;stop moving stuff on screen
	ld	hl,(SEED)		;goto a new random room
	ld (RoomX),hl
	ld	hl,DEATHS	;take away a life
	dec	(hl)
	call	SWAP		;swap to other player
	jr nz,	SLOP		;if so go play his round
	call	SWAP		;do you have any lives left?
	jr nz,	SLOP
; Update High Scores
	ld	a,-1
	ld	(DEMO),a		;not playing anymore
	call	NoSnd
UPITY:	call	UPHIGH		;Check for high score
;get other player
	call	SWAP		;(in 1 player its score is 0)
	call	UPHIGH		;Check for high score
	ld	sp,SPos		;reset stack
	call	SET1		;reset everything
	jp	MENTR		;right to high scores
;---------------------------
; ZERO both players scores
; and can the 1/2 credits
;---------------------------
ZSCORE: ld	hl,0
	ld(SCORE1),hl
	ld(SCORE1+2),hl
	ld(SCORE2+1),hl
	ld(CACKLE),hl		;zero fractional coin
	ld	hl,NoVoice
	ld (V.PC),hl
	jp	NoSnd
;----------------------------
; Swap players banks of ram
;----------------------------
SWAP:	push	hl
	ld	hl,PLAYER
	ld	de,OTHER
	ld	B,OTHER-PLAYER
..LP:	ld	a,(de)
	ld	c,(hl)
	ex de,hl
	ld	(de),a
	ld	(hl),c
	ex de,hl
	inc	hl
	inc	de
	djnz	..LP
	pop	hl
	ld	a,(hl)
	or	a
	ret
;---------------------------
; zero ram loop
; hl->start, bc=# of bytes
;---------------------------
Zap::	ld	a,c
	or	a
	ld	c,b
	ld	b,a
	jr z,	..sk
	inc	c
..sk:	xor	a
..zl:	ld	(hl),a
	inc	hl
	djnz	..zl
	dec	c
	jr nz,	..zl
	ret
;---------------------------------------------+
; Initialization data for players first round |
;---------------------------------------------+
Idata:	.byte	1	;PLAYER
	.byte	0,0	;RoomX
Manxi:	.byte	30	;ManX
	.byte	116	;MPY
	.byte	3	;DEATHS
	.byte	6	;PERCENT
	.byte	0	;Rbolts
	.byte	90	;Rwait
	.byte	0	;STIME
	.byte	0	;XtraMen

	.end

