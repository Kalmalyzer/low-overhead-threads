
		include	"Threading/Threads.i"
		include	"Threading/Scheduler.i"

		include	<lvo/exec_lib.i>
		include	<lvo/dos_lib.i>

HelloWorldThreadId = 0

		section	code,code
		
;------------------------------------------------------------------------------		

start:

		move.l	$4.w,ExecBase

; open DOS.library

		move.l	ExecBase,a6
		lea	DosName,a1
		moveq	#0,d0
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,DosBase

; Setup a single "Hello world" thread
		
		moveq	#HelloWorldThreadId,d0
		lea	HelloWorldThreadFunc,a0
		lea	HelloWorldStackBegin,a1
		lea	HelloWorldStackEnd,a2
		bsr	setupThread

; Run thread
		bsr	runScheduler

; Close dos.library

		move.l	DosBase,a1
		move.l	$4.w,a6
		jsr	_LVOCloseLibrary(a6)

		moveq	#0,d0
		rts

;------------------------------------------------------------------------------		
		
HelloWorldThreadFunc

; Print string to standard output

		move.l	DosBase,a6
		jsr	_LVOOutput(a6)
		move.l	d0,d1
		move.l	#HelloWorldMessage,d2
		move.l	#HelloWorldMessageEnd-HelloWorldMessage,d3
		jsr	_LVOWrite(a6)

		rts


		section	data,data

HelloWorldMessage
		dc.b	"Hello World!",10
HelloWorldMessageEnd

DosName		dc.b	"dos.library",0

		even
		
		section	bss,bss

ExecBase	ds.l	1
DosBase		ds.l	1

HelloWorldStackBegin
		ds.b	4096
HelloWorldStackEnd
