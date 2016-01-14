
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"

		include <lvo/exec_lib.i>
		include <lvo/dos_lib.i>

		section	code,code

;------------------------------------------------------------------------
; Print string to standard output
; The scheduler interrupt will temporarily be disabled during printing
; All registers are preserved by this function
;
; in	(sp)	pointer to string start (ASCIIZ)

logMessageBasePtr
		movem.l	d0-d3/a0-a1/a6,-(sp)
		
		bsr	disableSchedulerInterrupt

		; Compute length of string
		move.l	8*4(sp),a0
		moveq	#-1,d0
.checkCharacter
		addq.l	#1,d0
		tst.b	(a0)+
		bne.s	.checkCharacter
		move.l	d0,-(sp)

		; Open dos.library
		
		move.l	$4.w,a6
		lea	dosName,a1
		moveq	#0,d0
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,a6

		; Print string to standard output
		
		jsr	_LVOOutput(a6)
		move.l	d0,d1
		move.l	(sp)+,d3
		move.l	8*4(sp),d2
		jsr	_LVOWrite(a6)

		; Close dos.library
		
		move.l	a6,a1
		move.l	$4.w,a6
		jsr	_LVOCloseLibrary(a6)

		bsr	enableSchedulerInterrupt

		movem.l	(sp)+,d0-d3/a0-a1/a6

		rts


		section	data,data

dosName		dc.b	"dos.library",0
		cnop	0,4
