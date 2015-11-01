
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

		section	code,code

runScheduler
		LOG_INFO_STR "Scheduler begins running threads"

		move.b	#IdleThreadId,currentThread
		move.b	#Thread_state_Runnable,Threads+IdleThreadId*Thread_SIZEOF+Thread_state
		
.loop
		bsr	anyThreadsAliveExceptIdleThread
		tst.l	d0
		beq.s	.done

		bsr	chooseThreadToRun
		cmp.b	#IdleThreadId,d0
		bne.s	.foundThreadToRun

		LOG_ERROR_STR "Only the idle thread is in runnable state. The system has deadlocked."

.foundThreadToRun
		move.b	d0,desiredThread

		bsr	switchToDesiredThread
		
		bra.s	.loop
		
.done
		LOG_INFO_STR "No live threads - scheduler exiting"
		rts

;------------------------------------------------------------------------
; out	d0.l	1 = threads alive, 0 = all threads dead

anyThreadsAliveExceptIdleThread
		lea	Threads,a0
		moveq	#MAX_THREADS-2,d0
.thread
		cmp.b	#Thread_state_Uninitialized,Thread_state(a0)
		bne.s	.alive_thread_found
		add.w	#Thread_SIZEOF,a0
		dbf	d0,.thread

		moveq	#0,d0
		rts

.alive_thread_found
		moveq	#1,d0
		rts

;------------------------------------------------------------------------
; out	d0.w	thread to run (IdleThreadId will always be runnable)

chooseThreadToRun
		lea	Threads,a0
		moveq	#0,d0
.thread
		cmp.b	#Thread_state_Runnable,Thread_state(a0)
		beq.s	.suitable_thread_found

		add.w	#Thread_SIZEOF,a0
		addq.w	#1,d0
		cmp.w	#MAX_THREADS,d0
		bne.s	.thread

		LOG_ERROR_STR "No threads are in runnable state. The system has deadlocked."

.suitable_thread_found
		rts

;------------------------------------------------------------------------

switchToDesiredThread
		move.l	d0,oldD0
		move.l	d1,oldD1
		move.l	a0,oldA0
		move.l	a1,oldA1

		moveq	#0,d0
		move.b	currentThread,d0

		moveq	#0,d1
		move.b	desiredThread,d1
		
		cmp.b	d0,d1
		beq.s	.nSwitch

		mulu.w	#Thread_SIZEOF,d0
		lea	Threads,a0
		add.w	d0,a0
		move.l	oldD0,Thread_Dn+0*4(a0)
		move.l	oldD1,Thread_Dn+1*4(a0)
		movem.l	d2-d7,Thread_Dn+2*4(a0)
		move.l	oldA0,Thread_An+0*4(a0)
		move.l	oldA1,Thread_An+1*4(a0)
		movem.l	a2-a6,Thread_An+2*4(a0)
		
		move.l	#.functionExit,Thread_PC(a0)
		clr.b	Thread_CCR(a0)		; not needed - the calling code does not care about preserving CCR
		
		move.l	a7,Thread_USP(a0)

		
		move.b	d1,currentThread
		
		mulu.w	#Thread_SIZEOF,d1
		lea	Threads,a1
		add.w	d1,a1

		move.l	Thread_Dn+0*4(a1),oldD0
		move.l	Thread_Dn+1*4(a1),oldD1
		movem.l	Thread_Dn+2*4(a1),d2-d7
		move.l	Thread_An+0*4(a1),oldA0
		move.l	Thread_An+1*4(a1),oldA1
		movem.l	Thread_An+2*4(a1),a2-a6
		
		move.l	Thread_USP(a1),a7
		
		move.l	Thread_PC(a1),-(sp)
		move.b	Thread_CCR(a1),-(sp)

		move.l	oldD0,d0
		move.l	oldD1,d1
		move.l	oldA0,a0
		move.l	oldA1,a1
		
		rtr
		
.nSwitch
		rts

.functionExit
		rts
		
		section	data,data

currentThread	dc.b	0
desiredThread	dc.b	0

		section	bss,bss

oldD0		ds.l	1
oldD1		ds.l	1
oldA0		ds.l	1
oldA1		ds.l	1
