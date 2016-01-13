

MAX_THREADS	= 4

IdleThreadId	= MAX_THREADS-1


Thread_state_Uninitialized = 0
Thread_state_Runnable = 1
Thread_state_Waiting = 2


		RSRESET
Thread_regsToSwitchAtTaskSwitch_start rs.b 0
Thread_PC	rs.l	1
Thread_SR	rs.w	1
Thread_USP	rs.l	1
Thread_D0	rs.l	1
Thread_D1	rs.l	1
Thread_A0	rs.l	1
Thread_A1	rs.l	1
Thread_D2	rs.l	1
Thread_D3	rs.l	1
Thread_D4	rs.l	1
Thread_D5	rs.l	1
Thread_D6	rs.l	1
Thread_D7	rs.l	1
Thread_A2	rs.l	1
Thread_A3	rs.l	1
Thread_A4	rs.l	1
Thread_A5	rs.l	1
Thread_A6	rs.l	1
Thread_regsToSwitchAtTaskSwitch_end rs.b 0
Thread_stackLow	rs.l	1
Thread_stackHigh rs.l	1
; Thread struct is expected to contain at most 32 longwords

Thread_SIZEOF_Shift = 	(2+5)
Thread_SIZEOF	=	1<<(Thread_SIZEOF_Shift)

		XREF	setupThread
		XREF	Threads_state
		XREF	Threads_regs

		XREF	setThreadRunnable
		XREF	waitCurrentThread
