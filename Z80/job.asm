B>type job.asm

.title	"Job Scheduling"
.sbttl	"FRENZY"
.ident JOBS
;~~~~~~~~~~~~~~~~~~~~
; multi-job System
;____________________
.insert EQUS
.extern Zap
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Job System Initialization
;____________________________
JobInit::
	xor	a		;reset man alternator
	ld	(Man.Alt),a
	ld	hl,J.Used
	ld	bc,(MaxJob*JobLength)+2
	jp	Zap
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Pass Control to next job
;____________________________
Next.J::
	push	y		;pc is on stack
	push	x		;save all registers
	push	hl
	push	de
	push	bc
	push	af		;->job store area
	call	JobPtr		;returns in de
	ld	hl,0
	add	hl,sp		;hl->top of stack(the register set)
	ld	bc,JobLength	;move stack to store
	LDIR
	ld	hl,J.Used	;move to next job
	ld	b,(hl)		;# in use
	inc	hl		;->J.Index
..loop: ld	a,(hl)
	inc	(hl)		;++J.Index
	cp	b		;see if we're last job
	jr nz,	..ok
	ld	(hl),0
..ok:	ld	a,(hl)		;is it man job
	cp	1		;if so skip it
	jr z,	..loop
	ld	hl,Man.Alt	;check if time for man job
	ld	a,(hl)
	or	a
	jr nz,	OK1
	ld	(hl),1b		;reset alternator
	ld a,	J.Used		;check number of jobs used
	or	a
	jr z,	OK1		;no man job yet so skip
	call	MJPtr		;->man job
	jr	GOJ
OK1:	call	JobPtr
GOJ:	ld	hl,SPos-JobLength
	ld sp,hl			;->stack area
	ex de,hl
	ld	bc,JobLength	;move store to stack
	LDIR
	pop	af		;get this job's registers
	pop	bc
	pop	de
	pop	hl
	pop	x
	pop	y
	ret			;and pc register too
;~~~~~~~~~~~~~~~~~~~~~~
; Return from man job
;______________________
Man.Next::
	push	y		;pc is on stack
	push	x		;save all registers
	push	hl
	push	de
	push	bc
	push	af		;->job store area
	call	MJPtr		;returns -> man job in de
	ld	hl,0
	add	hl,sp		;hl->top of stack(the register set)
	ld	bc,JobLength	;move stack to store
	LDIR
	jp	OK1		;go do next job
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Split off new job
;____________________________
J.FORK::
	push	bc		;bc=starting PC for new job
	push	y		;also get set of input
	push	x		;registers for parms
	push	hl
	push	de
	push	bc
	push	af
; check if possible to start a new job
	ld	hl,J.Used	;-># of jobs in use (0 is 1)
	ld	a,(hl)
	cp	MaxJob-1
	jr c,	..ok
	ld	hl,7*2		;sorry no room
	add	hl,sp		;get rid of registers
	ld sp,hl
	scf			;aborto
	ret
;ok to add a job
..ok:	inc	(hl)		;++J.Used
	call	JLPtr		;get pointer to last job in de
	ld	hl,0
	add	hl,sp		;top ot stack frame
	ld	bc,JobLength
	LDIR
	pop	af		;restore mother registers
	pop	bc
	pop	de
	pop	hl
	pop	x
	pop	y
	pop	bc		;was copy of bc=daughter pc
	or	a		;nc means no problem
	ret			;return to mother
;~~~~~~~~~~~~~~~~~~~~
; Delete Current Job
;____________________
JobDel::
	ld	hl,J.Used
	ld	a,(hl)		;save
	dec	(hl)		;one less job active
	inc	hl		;->J.Index
	sub	(hl)		;J.Used-J.Index
	jr nz,	..move		;if = then this is last job
	ld	(hl),0		;reset J.Index
..go:	call	JobPtr		;de->frame
	jr	GOJ
..move:			;move jobs up j.index stays same
	call	JobPtr		;de->frame
	ld	hl,JobLength
	add	hl,de		;hl->next frame
	ex de,hl
	push	hl
	ld	hl,Jobs+(MaxJob*JobLength) ;->end of job area
	or	a
	dsbc	d		;hl=#of bytes to end of job area
	ld	b,h
	ld	c,l
	pop	hl
	ex de,hl
	LDIR
	jr	..go
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Point to Job[J.Index] Storage Area
;_____________________________________
MJPtr:	ld	c,1
	.byte	(3eh)		;mvi a,(mov c,(hl))
JLPtr:	ld	c,(hl)
	ld	hl,Jobs
	jr	JP2
JobPtr: ld	hl,J.Index
	ld	c,(hl)		;current index
	inc	hl		;->Jobs
JP2:	ld	b,0
	ex de,hl
	ld	hl,0		;hl=14*bc (J.Index*JobLength)
	MULT	JobLength
	add	hl,de		;Jobs[Jindex*JobLength]
	ex de,hl			;return de->job area
	ret
;~~~~~~~~~~~~~~~~~~~~~~~
; Initialize the Timers
;_______________________
TimerInit::
	ld	hl,Talloc	;timer allocation area
	ld	bc,MaxTimer+(Maxtimer/8)
	jp	Zap
;~~~~~~~~~~~~~~~~~~
; Allocate a Timer
;__________________
; returns hl->a timer byte
GetTimer::
	push	de
	push	bc
	push	af
	ld	hl,Talloc
	ld	bc,(MaxTimer/8)<8 ;#of timers:timer0
..alp:	ld	a,(hl)		;get alloc bits
	cp	-1		;if not all 1's
	jr nz,	..get		;then find a zero bit
	ld	a,8		;move index up 8
	add	a,c
	ld	c,a
	inc	hl		;->talloc group
	djnz	..alp		
..bad:	pop	af
	scf			;no timer available
	jr	..ret
..get:	ld	b,1		;bit 0 mask
..blp:	ld	d,a		;save Talloc
	and	b		;check bit
	ld	a,d		;restore Talloc
	jr z,	..ok
	inc	c		;up the index
	rlc	b		;move bit left
	jr	..blp
..ok:	or	b		;set alloc bit
	ld	(hl),a		;set Talloc
	ld	b,0		;bc=timer #
	ld	hl,Timer0
	add	hl,bc		;hl->special timer
	pop	af
	or	a
..ret:	pop	bc
	pop	de
	ret
;~~~~~~~~~~~~~~~
; Free a Timer
;_______________
; input hl->timer byte
FreeTimer::
	push	bc
	push	af
	ld	(hl),0
	ld	bc,Timer0	;find the offset
	or	a
	dsbc	b		;hl=timer number
	ld	a,l
	cp	24
	jr nc,	..ret
	ld	hl,Talloc	;->talloc[0..7]
..idx:	cp	8		;check index 0..7
	jr c,	..ok
	inc	hl		;->talloc[+8]
	sub	8		;index-=8
	jr	..idx
..ok:	ld	b,#1		;FEh bit 0 negitive mask
	or	a		;index=0?
	jr z,	..fr
..blp:	rlc	b		;move bit mask up
	dec	a		;dec index
	jr nz,	..blp
..fr:	ld	a,b
	and	(hl)
	ld	(hl),a	
..ret:	pop	af
	pop	bc
	ret
;~~~~~~~~~~~~~~~~~~
; Put job to sleep
;__________________
; input A=number of 60ths to wait
J.WAIT::
	pop	y
	call	GetTimer
	ld	(hl),a
..lp:	call	NEXT.J
	ld	a,(hl)
	or	a
	jr nz,	..lp
	call	FreeTimer
	pciy

	.end
