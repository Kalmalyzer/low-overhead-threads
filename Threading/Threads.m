
		IFND	THREADS_M
THREADS_M	SET	1

		INCLUDE	"Threading/Threads.i"
		INCLUDE	"Threading/Scheduler.m"

;------------------------------------------------------------------------

M_setThreadRunnable	MACRO	threadId
		bset	\1,Threads_runnableFlags

		cmp.b	desiredThread,\1
		bhs.s	.noThreadSwitch\@

		move.b	\1,desiredThread
		REQUEST_SCHEDULER_INTERRUPT

.noThreadSwitch\@
		ENDM

;------------------------------------------------------------------------

M_waitCurrentThread	MACRO	currentThreadId,scratchRegister
		tst.b	schedulerInterruptEnableCount
		bhi.s	.schedulerInterruptEnabled\@

		LOG_ERROR_STR "Attempted to wait with current thread while scheduler interrupt is disabled; the system has deadlocked"
		
.schedulerInterruptEnabled\@

		bclr	\1,Threads_runnableFlags
		move.w	Threads_runnableFlags_word,\2

		M_chooseThreadToRun	\2,desiredThread
		REQUEST_SCHEDULER_INTERRUPT
		; Current thread will (potentially) go to sleep once the calling code re-enables interrupts
		ENDM

		
;------------------------------------------------------------------------

		ENDC