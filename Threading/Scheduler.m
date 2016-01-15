
		IFND	SCHEDULER_M
SCHEDULER_M	SET	1

		INCLUDE	"Threading/Scheduler.i"

;------------------------------------------------------------------------

M_chooseThreadToRun MACRO	Threads_runnableFlags,desiredThread
		lea	runnableFlagsToChosenThread,a0
		move.b	(a0,\1.w),\2
		bpl.s	.runnableThread\@
		LOG_ERROR_STR "No threads are in runnable state, including idle thread. The system has deadlocked."
.runnableThread\@
		ENDM
		
;------------------------------------------------------------------------

		ENDC
