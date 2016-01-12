

MAX_THREADS	= 4

IdleThreadId	= MAX_THREADS-1


Thread_state_Uninitialized = 0
Thread_state_Runnable = 1
Thread_state_Waiting = 2


		RSRESET
Thread_stackPtr	rs.l	1
Thread_stackLow	rs.l	1
Thread_stackHigh rs.l	1
Thread_Dn	rs.l	8
Thread_An	rs.l	7
Thread_USP	rs.l	1
Thread_PC	rs.l	1
Thread_SR	rs.w	1
		rs.b	2
Thread_SIZEOF	rs.b	0

		XREF	setupThread
		XREF	Threads_state
		XREF	Threads_regs

		XREF	setThreadRunnable
		XREF	waitCurrentThread
