
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

HelloWorldThreadId = 0

		section	code,code
		
;------------------------------------------------------------------------------		

start:

; Setup a single "Hello world" thread
		
		moveq	#HelloWorldThreadId,d0
		lea	HelloWorldThreadFunc,a0
		lea	HelloWorldStackBegin,a1
		lea	HelloWorldStackEnd,a2
		bsr	setupThread

; Run thread
		bsr	runScheduler

		moveq	#0,d0
		rts

;------------------------------------------------------------------------------		
		
HelloWorldThreadFunc

; Print string to standard output

		LOG_INFO_STR "Hello world"

		rts
		
		section	bss,bss

HelloWorldStackBegin
		ds.b	4096
HelloWorldStackEnd
