

MAX_SIGNALS	= 16 ; Max number of signals supported by system; increase as necessary


;----------------------------------------------------------------------------------
; The Signals struct represent the current state of all signals in the system.
;
; state is initially $00 for all signals.
; A state value of $ff means that the signal has been set, but no thread has yet waited on that signal.
; state will remain $00 in all other situations.
;
; waitingThread is initially -1 for all signals.
; A waitingThread value of something else than -1 means that the thread with id <waitingThread> is
;   currently waiting on the signal, and the signal has not yet been set.
; waitingThread will remain -1 in all other situations.

		RSRESET
Signals_state	rs.b	MAX_SIGNALS
Signals_waitingThread	rs.b	MAX_SIGNALS
Signals_SIZEOF	rs.b	0

		XREF	setSignal
		XREF	setSignalFromInterrupt
		XREF	waitAndClearSignal
