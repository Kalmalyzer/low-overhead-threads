
		include	"Threading/Interrupts.i"
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
		DISABLE_INTERRUPTS
		movem.l	d0/a0-a2/a4,-(sp)

		lea	Threads_state,a4
		
		cmp.b	#Thread_state_Uninitialized,(a4,d0.w)
		beq.s	.threadAvailable

		LOG_ERROR_STR "The application has attempted to setup a thread which is already in-use"

.threadAvailable
		move.b	#Thread_state_Runnable,(a4,d0.w)
		mulu.w	#Thread_regs_SIZEOF,d0
		lea	Threads_regs,a4
		add.l	d0,a4

		move.l	a1,Thread_regs_stackLow(a4)
		move.l	a2,Thread_regs_stackHigh(a4)

		move.l	a0,Thread_regs_PC(a4)
		move.l	#terminateCurrentThread,-(a2)
		move.l	a2,Thread_regs_USP(a4)

		movem.l	(sp)+,d1/a0-a2/a4
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------

terminateCurrentThread
		DISABLE_INTERRUPTS
		moveq	#0,d0
		move.b	currentThread,d0
		lea	Threads_state,a0
		move.b	#Thread_state_Uninitialized,(a0,d0.w)
		
		bsr	chooseThreadToRun
		move.b	d0,desiredThread
		REQUEST_SCHEDULER_INTERRUPT		; This will result in the thread yielding within a few clock cycles, never returning
		ENABLE_INTERRUPTS
.loop		bra.s	.loop

;------------------------------------------------------------------------
; Interrupts are expected to be disabled when this function is called
; in	d0.w	thread

setThreadRunnable
		move.w	d0,d1
		lea	Threads_state,a0
		move.b	#Thread_state_Runnable,(a0,d0.w)

		move.b	desiredThread,d1
		cmp.b	d0,d1
		bls.s	.noThreadSwitch

		move.b	d0,desiredThread
		REQUEST_SCHEDULER_INTERRUPT

.noThreadSwitch
		rts

;------------------------------------------------------------------------
; Interrupts are expected to be disabled when this function is called

waitCurrentThread
		tst.b	schedulerInterruptEnableCount
		bhi.s	.schedulerInterruptEnabled

		LOG_ERROR_STR "Attempted to wait with current thread while scheduler interrupt is disabled; the system has deadlocked"
		
.schedulerInterruptEnabled
		
		moveq	#0,d0
		move.b	currentThread,d0
		lea	Threads_state,a0
		move.b	#Thread_state_Waiting,(a0,d0.w)

		bsr	chooseThreadToRun
		move.b	d0,desiredThread
		REQUEST_SCHEDULER_INTERRUPT
		; Current thread will (potentially) go to sleep once the calling code re-enables interrupts
		rts

		section	data,data

Threads_state
		dcb.b	MAX_THREADS,Thread_state_Uninitialized
		
Threads_regs
		dcb.b	MAX_THREADS*Thread_regs_SIZEOF,0
