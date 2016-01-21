
		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

		section	code,code


;------------------------------------------------------------------------
; Initialize a thread
;
; This function sets up initial register content and makes a thread
;   runnable.
; You need to provide both a starting execution point and a stack area
;   for the thread.
; The thread can terminate itself either by calling
;   terminateCurrentThread or by returning from the entry point.
;
; in	d0.w	thread index
;	a0	thread entry point
;	a1	userstack end
;	a2	superstack end

setupThread
		DISABLE_INTERRUPTS
		movem.l	d0/a0-a2/a4,-(sp)

		btst	d0,Threads_initializedFlags
		beq.s	.threadAvailable

		LOG_ERROR_STR "The application has attempted to setup a thread which is already in-use"

.threadAvailable
		bset	d0,Threads_initializedFlags
		bset	d0,Threads_runnableFlags

		move.l	#terminateCurrentThread,-(a1)
		
		lea	Threads_ssps,a4
		lsl.w	#2,d0
		add.w	d0,a4
		
		; Construct exception stack frame on supervisor stack
		; TODO: construct appropriate stack frame for 68010+ CPUs
		move.l	a0,-(a2)	; Initial PC
		clr.w	-(a2)		; Initial SR

		; Push initial d0-a6 + USP to supervisor stack
		REPT	15		; Initial d0-a6
		clr.l	-(a2)
		ENDR
		move.l	a1,-(a2)	; Initial USP

		; Store SSP for task
		move.l	a2,(a4)		; Initial SSP

		movem.l	(sp)+,d1/a0-a2/a4
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------
; Terminate current thread.
;
; There is no way to terminate another thread -- you must make each
;   thread terminate itself.

terminateCurrentThread
		DISABLE_INTERRUPTS
		move.b	currentThread,d0
		bclr	d0,Threads_runnableFlags
		bclr	d0,Threads_initializedFlags
		
		bsr	chooseThreadToRun
		move.b	d0,desiredThread
		REQUEST_SCHEDULER_INTERRUPT		; This will result in the thread yielding within a few clock cycles, never returning
		ENABLE_INTERRUPTS
.loop		bra.s	.loop

;------------------------------------------------------------------------
; Change thread state to runnable - helper function used by scheduler
;
; This will ensure that a thread is in Runnable state. If it has higher
;   priority than the currently-running thread, the scheduler will also
;   switch to that thread.
; 
; Interrupts are expected to be disabled when this function is called
;
; in	d0.w	thread

setThreadRunnable
		bset	d0,Threads_runnableFlags

		cmp.b	desiredThread,d0
		bhs.s	.noThreadSwitch

		move.b	d0,desiredThread
		REQUEST_SCHEDULER_INTERRUPT

.noThreadSwitch
		rts

;------------------------------------------------------------------------
; Change current thread state to waiting - helper function used by signals
;
; The current thread will be changed to waiting state. The scheduler will
;  determine which thread to switch to. The actual thread switch will
;  occur once interrupts are re-enabled outside this function.
;
; Interrupts are expected to be disabled when this function is called

waitCurrentThread
		tst.b	schedulerInterruptEnableCount
		bhi.s	.schedulerInterruptEnabled

		LOG_ERROR_STR "Attempted to wait with current thread while scheduler interrupt is disabled; the system has deadlocked"
		
.schedulerInterruptEnabled

		bclr	d0,Threads_runnableFlags

		bsr	chooseThreadToRun
		move.b	d0,desiredThread
		REQUEST_SCHEDULER_INTERRUPT
		; Current thread will (potentially) go to sleep once the calling code re-enables interrupts
		rts

;------------------------------------------------------------------------

		section	data,data

;------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; Threads_*flags represent the possible states which a thread can be in.
; If a thread with a given ID has not been setup, or it has terminated,
;  it will be in state Uninitialized. This means that it is not part of 
;  scheduling.
; A thread which has been setup, and is not currently waiting for any signal,
;  will be in state Runnable.
; A thread which is currently waiting for a signal will be in state Waiting.
;
; There is no distinction in thread state between the currently running thread,
;  and any other threads which are ready to run but waiting for their share of
;  CPU -- the scheduler tracks this internally.
;
; Uninitialized: initialized = 0, runnable = 0
; Runnable: initialized = 1, runnable = 1
; Waiting: initialized = 1, runnable = 0

Threads_initializedFlags
		dc.b	0

		even
		
Threads_runnableFlags_word
		dc.b	0
Threads_runnableFlags
		dc.b	0

Threads_ssps	dcb.l	MAX_THREADS,0
		
