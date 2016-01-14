

MAX_THREADS	= 4	; Max number of threads supported by system; increase as necessary

IdleThreadId	= MAX_THREADS-1

;----------------------------------------------------------------------------------
; Thread_state represent the possible states which a thread can be in.
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

Thread_state_Uninitialized = 0
Thread_state_Runnable = 1
Thread_state_Waiting = 2

;----------------------------------------------------------------------------------
; Thread_regs represent the context of a thread.
; The register content is only valid for those threads that are not currently
;   running.
; Switching currently-executing thread involves dumping the currently-executing
;   thread's register set into one instance of this struct, and then loading 
;   all registers from another instance of the struct.

		RSRESET
Thread_regs_switchAtTaskSwitch_start rs.b 0
Thread_regs_PC	rs.l	1
Thread_regs_SR	rs.w	1
Thread_regs_USP	rs.l	1
Thread_regs_D0	rs.l	1
Thread_regs_D1	rs.l	1
Thread_regs_A0	rs.l	1
Thread_regs_A1	rs.l	1
Thread_regs_D2	rs.l	1
Thread_regs_D3	rs.l	1
Thread_regs_D4	rs.l	1
Thread_regs_D5	rs.l	1
Thread_regs_D6	rs.l	1
Thread_regs_D7	rs.l	1
Thread_regs_A2	rs.l	1
Thread_regs_A3	rs.l	1
Thread_regs_A4	rs.l	1
Thread_regs_A5	rs.l	1
Thread_regs_A6	rs.l	1
Thread_regs_switchAtTaskSwitch_end rs.b 0
Thread_regs_stackLow	rs.l	1
Thread_regs_stackHigh rs.l	1
Thread_regs_dataEnd	rs.b	0

Thread_regs_SIZEOF_Shift = 	(2+5)
Thread_regs_SIZEOF	=	1<<(Thread_regs_SIZEOF_Shift)

		IFLT	Thread_regs_SIZEOF-Thread_regs_dataEnd
		ERROR	"Thread_regs structure contains more data than Thread_regs_SIZEOF_shift allows for. Please change the two to match."
		ENDC

		XREF	setupThread
		XREF	Threads_state
		XREF	Threads_regs

		XREF	setThreadRunnable
		XREF	waitCurrentThread
