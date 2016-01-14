

MAX_THREADS	= 4

IdleThreadId	= MAX_THREADS-1


Thread_state_Uninitialized = 0
Thread_state_Runnable = 1
Thread_state_Waiting = 2


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
