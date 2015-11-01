
		include	"Threading/Log.i"
		include	"Threading/Signals.i"
		include	"Threading/Threads.i"

		section	code,code

;------------------------------------------------------------------------
; in	d0.w	signal

setSignal
		lea	Signals,a0
		mulu.w	#Signal_SIZEOF,d0
		add.w	d0,a0

		tst.b	Signal_state(a0)
		bne.s	.signalAlreadySet
		
		st	Signal_state(a0)

		move.b	Signal_waitingThread(a0),d0
		bmi.s	.noThreadWaitingOnsignal

		LOG_INFO_STR "A thread is waiting on signal; setting that thread to runnable"
		bsr	setThreadRunnable
		rts

.noThreadWaitingOnsignal
		LOG_INFO_STR "No thread is currently waiting on signal"
		rts

.signalAlreadySet
		LOG_INFO_STR "Signal is already set"
		rts

;------------------------------------------------------------------------
; in	d0.w	signal

clearSignal
		lea	Signals,a0
		mulu.w	#Signal_SIZEOF,d0
		add.w	d0,a0
		
		sf	Signal_state(a0)

		rts

;------------------------------------------------------------------------
; in	d0.w	signal

waitAndClearSignal
		move.w	d0,d1
		lea	Signals,a0
		mulu.w	#Signal_SIZEOF,d0
		add.w	d0,a0

		tst.b	Signal_state(a0)
		bne.s	.alreadySignalled

		tst.b	Signal_waitingThread(a0)
		bmi.s	.availableForWaiting

		LOG_ERROR_STR "The application has attempted to wait on the same signal from multiple threads; the signal system only supports a single waiter"
.availableForWaiting

		moveq	#0,d0
		move.b	currentThread,d0
		move.b	d0,Signal_waitingThread(a0)
		lea	Threads,a1
		mulu.w	#Thread_SIZEOF,d0
		add.w	d0,a1
		move.b	d1,Thread_waitingSignal(a1)

		movem.l	a0-a1,-(sp)
		bsr	waitCurrentThread
		movem.l	(sp)+,a0-a1

		st	Signal_waitingThread(a0)
		st	Thread_waitingSignal(a1)

		sf	Signal_state(a0)

		rts

.alreadySignalled
		sf	Signal_state(a0)
		rts

		
		section	data,data

Signals
		REPT	MAX_SIGNALS
		dc.b	0		; Signal_state
		dc.b	-1		; Signal_waitingThread
		ENDR

