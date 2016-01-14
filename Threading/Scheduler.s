
		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"
		include	"Threading/VBR.i"

		include	"hardware/custom.i"
		include	"hardware/intbits.i"
		
		section	code,code

;------------------------------------------------------------------------
; Run scheduler's dispatch
;
; The calling code should create at least one thread of its own before
;   calling this function.
; Calling this function will setup the current execution context as
;   the idle thread. Execution will then start on the idle thread.
; The function will return once all threads apart from the idle thread
;   have terminated.

runScheduler
		LOG_INFO_STR "Scheduler begins running threads"

		move.b	#IdleThreadId,currentThread
		move.b	#Thread_state_Runnable,Threads_state+IdleThreadId

		bsr	chooseThreadToRun
		move.b	d0,desiredThread

		bsr	installSchedulerInterruptHandler
		REQUEST_SCHEDULER_INTERRUPT

.loop
		DISABLE_INTERRUPTS
		bsr	anyThreadsAliveExceptIdleThread
		ENABLE_INTERRUPTS
		tst.b	d0
		bne.s	.loop
		
.done
		LOG_INFO_STR "No live threads - scheduler exiting"
		
		bsr	removeSchedulerInterruptHandler
		
		rts

;------------------------------------------------------------------------
; Install scheduler interrupt handler as a level-1 interrupt (SOFTINT)

installSchedulerInterruptHandler
		DISABLE_INTERRUPTS

		bsr	getVBR
		move.l	d0,a0
		move.l	$64(a0),oldLevel1InterruptHandler
		
		move.l	#schedulerInterruptHandler,$64(a0)
		
		ACKNOWLEDGE_SCHEDULER_INTERRUPT
		ENABLE_SCHEDULER_INTERRUPT

		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------
; Remove scheduler interrupt handler

removeSchedulerInterruptHandler
		DISABLE_INTERRUPTS

		ACKNOWLEDGE_SCHEDULER_INTERRUPT
		DISABLE_SCHEDULER_INTERRUPT

		bsr	getVBR
		move.l	d0,a0
		move.l	oldLevel1InterruptHandler,$64(a0)
		
		ENABLE_INTERRUPTS
		rts


;------------------------------------------------------------------------
; Are any threads except the idle thread still alive?
;
; out	d0.l	1 = threads alive, 0 = all threads dead

anyThreadsAliveExceptIdleThread
		lea	Threads_state,a0
		moveq	#MAX_THREADS-2,d0
.thread
		cmp.b	#Thread_state_Uninitialized,(a0)
		bne.s	.alive_thread_found
		addq.l	#1,a0
		dbf	d0,.thread

		moveq	#0,d0
		rts

.alive_thread_found
		moveq	#1,d0
		rts

;------------------------------------------------------------------------
; Identify the highest-priority thread that is currently runnable
;
; Interrupts are expected to be disabled when this function is called
;
; out	d0.w	thread to run (IdleThreadId will always be runnable)

chooseThreadToRun
		lea	Threads_state,a0
		moveq	#Thread_state_Runnable,d0
		REPT	MAX_THREADS
		cmp.b	(a0)+,d0
		beq.s	.found
		ENDR

		LOG_ERROR_STR "No threads are in runnable state, including idle thread. The system has deadlocked."
		
.found
		sub.l	#Threads_state+1,a0
		move.l	a0,d0
		rts

;------------------------------------------------------------------------
; Scheduler interrupt handler
;
; The interrupt handler will perform a context switch, if necessary.
; If no context switch is needed, it is a no-op.

schedulerInterruptHandler
		btst	#(INTB_SOFTINT&7),intreqr+(1-(INTB_SOFTINT/8))+$dff000
		beq.s	.nSoftInt

		; Scheduling interrupt is acknowledged before context switching
		;   begins. This ensures that if a higher-priority interrupt
		;   preempts this interrupt handler and requests another
		;   scheduling interrupt during context switch processing, the
		;   scheduler interrupt handler will re-run as soon as it has
		;   completed the current context switch.
		
		ACKNOWLEDGE_SCHEDULER_INTERRUPT

		movem.l	d0-d1/a0-a1,-(sp)

		moveq	#0,d0
		move.b	currentThread,d0

		; desiredThread is sampled exactly once during the handler.
		; It is sampled using an operation that is atomic on the A500.
		; This ensures that desiredThread can be changed by
		;   higher-priority interrupts during the execution of this
		;   thread without any negative effects.
		;
		; It is sampled after the scheduler interrupt has been
		;   acknowledged. This ensures that if a high-priority
		;   interrupt performs an action which results in a change
		;   of the desired thread, the scheduler will eventually
		;   switch to that thread. It may require re-running the
		;   scheduler interrupt handler an extra time.
		
		moveq	#0,d1
		move.b	desiredThread,d1
		
		cmp.b	d0,d1
		beq.s	.nSwitch

		move.b	d1,currentThread
		
		lea	Threads_regs+Thread_regs_switchAtTaskSwitch_end,a0
		lea	Threads_regs+Thread_regs_switchAtTaskSwitch_start,a1
		lsl.w	#Thread_regs_SIZEOF_Shift,d0
		lsl.w	#Thread_regs_SIZEOF_Shift,d1
		add.w	d0,a0
		add.w	d1,a1

		movem.l	a2-a6,-(a0)	; Save a2-a6
		movem.l	d2-d7,-(a0)	; Save d2-d7
		movem.l	(sp)+,d4-d7
		movem.l	d4-d7,-(a0)	; Save d0-d1/a0-a1
		
		move	usp,a2
		move.l	a2,-(a0)	; Save USP
		
		move.w	(sp)+,-(a0)	; Save SR
		move.l	(sp)+,-(a0)	; Save PC
		
		move.l	(a1)+,-(sp)	; Load PC
		move.w	(a1)+,-(sp)	; Load SR

		move.l	(a1)+,a2	; Load USP
		move	a2,usp

		movem.l	(a1)+,d4-d7	; Load d0-d1/a0-a1
		movem.l	d4-d7,-(sp)
		movem.l	(a1)+,d2-d7	; Load d2-d7
		movem.l	(a1)+,a2-a6	; Load a2-a6
		
.nSwitch
		movem.l	(sp)+,d0-d1/a0-a1
		
		rte
		
.nSoftInt
		move.l	oldLevel1InterruptHandler,-(sp)
		rts

;------------------------------------------------------------------------
; Disable scheduler interrupt, with reentrancy count
;
; The scheduler interrupt is enabled by default.
; The scheduler interrupt will be disabled as long as disable has been
;   called more times than enable.

disableSchedulerInterrupt
		subq.b	#1,schedulerInterruptEnableCount
		bmi.s	.done
		DISABLE_SCHEDULER_INTERRUPT
.done
		rts
		
;------------------------------------------------------------------------
; Enable scheduler interrupt, with reentrancy count
;
; The scheduler interrupt is enabled by default.
; The scheduler interrupt will be disabled as long as disable has been
;   called more times than enable.

enableSchedulerInterrupt
		addq.b	#1,schedulerInterruptEnableCount
		ble.s	.done
		ENABLE_SCHEDULER_INTERRUPT
.done
		rts
		
;------------------------------------------------------------------------


		section	data,data

currentThread	dc.b	-1
desiredThread	dc.b	-1

schedulerInterruptEnableCount dc.b	1

		cnop	0,4

oldLevel1InterruptHandler dc.l	0
