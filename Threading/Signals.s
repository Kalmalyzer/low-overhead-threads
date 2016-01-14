
		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Signals.i"
		include	"Threading/Threads.i"

		section	code,code

;------------------------------------------------------------------------
; Set signal
;
; in	d0.w	signal

setSignal
		DISABLE_INTERRUPTS
		lea	Signals,a0
		add.w	d0,a0

		tst.b	Signals_state(a0)
		bne.s	.signalAlreadySet
		
		move.b	Signals_waitingThread(a0),d0
		bmi.s	.noThreadWaitingOnsignal

		LOG_INFO_STR "A thread is waiting on signal; setting that thread to runnable"

		st	Signals_waitingThread(a0)
		bsr	setThreadRunnable
		ENABLE_INTERRUPTS
		rts

.noThreadWaitingOnsignal
		LOG_INFO_STR "No thread is currently waiting on signal"

		st	Signals_state(a0)
		ENABLE_INTERRUPTS
		rts

.signalAlreadySet
		LOG_INFO_STR "Signal is already set"
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------
; Set signal - callable from within interrupt
;
; This function must only be called from a context where interrupts
;   are disabled; either inside of an interrupt handler,
;   or a section of code which has manually disabled interrupts.
;
; in	d0.w	signal

setSignalFromInterrupt
		lea	Signals,a0
		add.w	d0,a0

		tst.b	Signals_state(a0)
		bne.s	.signalAlreadySet
		
		move.b	Signals_waitingThread(a0),d0
		bmi.s	.noThreadWaitingOnsignal

;		LOG_INFO_STR "A thread is waiting on signal; setting that thread to runnable"

		st	Signals_waitingThread(a0)
		bsr	setThreadRunnable
		rts

.noThreadWaitingOnsignal
;		LOG_INFO_STR "No thread is currently waiting on signal"

		st	Signals_state(a0)
		rts

.signalAlreadySet
;		LOG_INFO_STR "Signal is already set"
		rts

;------------------------------------------------------------------------
; Clear signal
;
; in	d0.w	signal

clearSignal
		DISABLE_INTERRUPTS
		lea	Signals,a0
		
		LOG_INFO_STR "Clearing signal"

		sf	Signals_state(a0,d0.w)
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------
; Wait for signal, and clear it.
;
; If the signal is not currently set, the calling thread will switch to
;   waiting state. It will switch back to being runnable once the signal
;   is set by some other thread or interrupt handler.
; 
; If the signal is currently set, this function will immediately return
;   without triggering any context switches or interrupts.
;
; in	d0.w	signal

waitAndClearSignal
		DISABLE_INTERRUPTS
		lea	Signals,a0
		add.w	d0,a0

		tst.b	Signals_state(a0)
		bne.s	.alreadySignalled

		tst.b	Signals_waitingThread(a0)
		bmi.s	.availableForWaiting

		LOG_ERROR_STR "The application has attempted to wait on the same signal from multiple threads; the signal system only supports a single waiter"
.availableForWaiting

		LOG_INFO_STR "Thread is waiting on signal that has not yet been signalled; goes into waiting state"

		moveq	#0,d0
		move.b	currentThread,d0
		move.b	d0,Signals_waitingThread(a0)

		move.l	a0,-(sp)
		bsr	waitCurrentThread
		move.l	(sp)+,a0
		ENABLE_INTERRUPTS
		rts

.alreadySignalled

		LOG_INFO_STR "Thread waited on signal that was already signalled; will immediately continue executing"

		sf	Signals_state(a0)
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------
		
		section	data,data

;------------------------------------------------------------------------

Signals
		dcb.b	MAX_SIGNALS,0		; Signals_state
		dcb.b	MAX_SIGNALS,-1		; Signals_waitingThread
