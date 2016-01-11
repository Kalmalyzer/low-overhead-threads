
		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

		include	"hardware/custom.i"
		include	"hardware/intbits.i"
		
		section	code,code

runScheduler
		LOG_INFO_STR "Scheduler begins running threads"

		move.b	#IdleThreadId,currentThread
		move.b	#Thread_state_Runnable,Threads+IdleThreadId*Thread_SIZEOF+Thread_state

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
; out	d0	VBR

getVBR
		moveq	#0,d0	; TODO fetch VBR
		rts

;------------------------------------------------------------------------

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
; Interrupts are expected to be disabled when this function is called
;
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

		LOG_ERROR_STR "No threads are in runnable state, including idle thread. The system has deadlocked."

.suitable_thread_found
		rts

;------------------------------------------------------------------------

schedulerInterruptHandler
		btst	#(INTB_SOFTINT&7),intreqr+(1-(INTB_SOFTINT/8))+$dff000
		beq.s	.nSoftInt

		ACKNOWLEDGE_SCHEDULER_INTERRUPT

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
		
		move	usp,a1
		move.l	a1,Thread_USP(a0)
		
		move.l	2(sp),Thread_PC(a0)
		move.w	(sp),Thread_SR(a0)
		
		move.b	d1,currentThread
		
		mulu.w	#Thread_SIZEOF,d1
		lea	Threads,a1
		add.w	d1,a1

		move.l	Thread_USP(a1),a2
		move	a2,usp

		move.l	Thread_Dn+0*4(a1),oldD0
		move.l	Thread_Dn+1*4(a1),oldD1
		movem.l	Thread_Dn+2*4(a1),d2-d7
		move.l	Thread_An+0*4(a1),oldA0
		move.l	Thread_An+1*4(a1),oldA1
		movem.l	Thread_An+2*4(a1),a2-a6
		
		move.l	Thread_PC(a1),2(sp)
		move.w	Thread_SR(a1),(sp)

		move.l	oldD0,d0
		move.l	oldD1,d1
		move.l	oldA0,a0
		move.l	oldA1,a1
		
.nSwitch
		rte
		
.nSoftInt
		move.l	oldLevel1InterruptHandler,-(sp)
		rts

;------------------------------------------------------------------------

disableSchedulerInterrupt
		subq.b	#1,schedulerInterruptEnableCount
		bmi.s	.done
		DISABLE_SCHEDULER_INTERRUPT
.done
		rts
		
;------------------------------------------------------------------------

enableSchedulerInterrupt
		addq.b	#1,schedulerInterruptEnableCount
		ble.s	.done
		ENABLE_SCHEDULER_INTERRUPT
.done
		rts
		
;------------------------------------------------------------------------


		section	data,data

currentThread	dc.b	0
desiredThread	dc.b	0

schedulerInterruptEnableCount dc.b	1

		cnop	0,4

oldLevel1InterruptHandler dc.l	0

		section	bss,bss

oldD0		ds.l	1
oldD1		ds.l	1
oldA0		ds.l	1
oldA1		ds.l	1
