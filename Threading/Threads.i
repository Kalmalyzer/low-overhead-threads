
		IFND	THREADS_I
THREADS_I	SET	1

MAX_THREADS	= 4	; Max number of threads supported by system; caps at 8

		IFGT	MAX_THREADS-8
		ERROR	"Current implementation supports no more than 8 threads"
		ENDC

IdleThreadId	= MAX_THREADS-1


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
		XREF	Threads_initializedFlags
		XREF	Threads_runnableFlags
		XREF	Threads_runnableFlags_word
		XREF	Threads_ssps

		XREF	setThreadRunnable
		XREF	waitCurrentThread

		ENDC
