
MAX_SIGNALS	=	16

		RSRESET
Signals_state	rs.b	MAX_SIGNALS
Signals_waitingThread	rs.b	MAX_SIGNALS
Signals_SIZEOF	rs.b	0

		XREF	setSignal
		XREF	setSignalFromInterrupt
		XREF	waitAndClearSignal
