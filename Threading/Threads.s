
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
		illegal

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
		illegal
		
		section	bss,bss

Threads		ds.b	Thread_SIZEOF*MAX_THREADS
