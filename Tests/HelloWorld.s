
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

HelloWorldThreadId = 1

		section	code,code
		
;------------------------------------------------------------------------------		

start:

; Setup a single "Hello world" thread
		
		moveq	#HelloWorldThreadId,d0
		lea	HelloWorldThreadFunc,a0
		lea	HelloWorldUserStackEnd,a1
		lea	HelloWorldSuperStackEnd,a2
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

HelloWorldUserStackBegin
		ds.b	4096
HelloWorldUserStackEnd

HelloWorldSuperStackBegin
		ds.b	4096
HelloWorldSuperStackEnd
