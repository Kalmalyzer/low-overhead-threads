
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

		section	code,code


;------------------------------------------------------------------------
; in	d0.w	thread index
;	a0	thread entry point
;	a1	stack low address
;	a2	stack high address

setupThread
		movem.l	d0/a0-a2/a4,-(sp)

		mulu.w	#Thread_SIZEOF,d0
		lea	Threads,a4
		add.l	d0,a4
		move.b	Thread_state(a4),d1
		cmp.b	#Thread_state_Uninitialized,d1
		beq.s	.threadAvailable

		LOG_ERROR_STR "The application has attempted to setup a thread which is already in-use"

.threadAvailable
		move.l	a1,Thread_stackLow(a4)
		move.l	a2,Thread_stackHigh(a4)

		move.l	a0,Thread_PC(a4)
		move.l	#terminateCurrentThread,-(a2)
		move.l	a2,Thread_USP(a4)
		
		move.b	#Thread_state_Runnable,Thread_state(a4)

		movem.l	(sp)+,d1/a0-a2/a4
		rts

;------------------------------------------------------------------------

terminateCurrentThread
		move.b	currentThread,d0
		mulu.w	#Thread_SIZEOF,d0
		lea	Threads,a0
		add.w	d0,a0
		move.b	#Thread_state_Uninitialized,Thread_state(a0)
		
		move.b	#IdleThreadId,desiredThread
		bsr	switchToDesiredThread		; This call will never return

		LOG_ERROR_STR "An already-terminated thread continued running after it had terminated itself"

;------------------------------------------------------------------------
; in	d0.w	thread

setThreadRunnable
		move.w	d0,d1
		mulu.w	#Thread_SIZEOF,d1
		lea	Threads,a0
		add.w	d1,a0
		move.b	#Thread_state_Runnable,Thread_state(a0)

		move.b	desiredThread,d1
		cmp.b	d0,d1
		bls.s	.noThreadSwitch

		move.b	d0,desiredThread
		bsr	switchToDesiredThread

.noThreadSwitch
		rts

;------------------------------------------------------------------------

waitCurrentThread
		moveq	#0,d0
		move.b	currentThread,d0
		mulu.w	#Thread_SIZEOF,d0
		lea	Threads,a0
		add.w	d0,a0
		move.b	#Thread_state_Waiting,Thread_state(a0)

		bsr	chooseThreadToRun
		move.b	d0,desiredThread
		bsr	switchToDesiredThread

		rts

		section	data,data

Threads
		REPT	MAX_THREADS
		dc.b	Thread_state_Uninitialized	; Thread_state
		dcb.b	3,0
		dc.l	0				; Thread_stackPtr
		dc.l	0				; Thread_stackLow
		dc.l	0				; Thread_stackHigh
		dcb.l	8,0				; Thread_Dn
		dcb.l	7,0				; Thread_An
		dc.l	0				; Thread_USP
		dc.l	0				; Thread_PC
		dc.b	0				; Thread_CCR
		dcb.b	3,0
		ENDR
