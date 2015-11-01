
MAX_SIGNALS	=	16

		RSRESET
Signal_state	rs.b	1
Signal_waitingThread	rs.b	1
Signal_SIZEOF	rs.b	0

		XREF	setSignal
		XREF	waitAndClearSignal
