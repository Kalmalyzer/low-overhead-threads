
ConsumerThreadId = 0
ProducerThreadId = 1

ItemProducedSignalId = 0

		section	code,code

		
start:

		move.l	$4.w,ExecBase

; open DOS.library

		move.l	ExecBase,a6
		lea	DosName,a1
		moveq	#0,d0
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,DosBase


		moveq	#ConsumerThreadId,d0
		lea	consumerThreadFunc,a0
		lea	consumerStackBeginning,a1
		lea	consumerStackEnd,a2
		bsr	setupThread

		moveq	#ProducerThreadId,d0
		lea	producerThreadFunc,a0
		lea	producerStackBeginning,a1
		lea	producerStackEnd,a2
		bsr	setupThread

		bsr	runScheduler

; Close dos.library

		move.l	DosBase,a1
		move.l	$4.w,a6
		jsr	_LVOCloseLibrary(a6)

		moveq	#0,d0
		rts
		
		
producerThreadFunc

		moveq	#0,d7
.loop
		move.l	writePtr,a0
		moveq	#'0',d1
		add.b	d7,d1
		move.b	d1,(a0)+
		move.l	a0,writePtr
		
		moveq	#ItemProducedSignalId,d0
		bsr	setSignal

		addq.l	#1,d7
		cmp.l	#10,d7
		bne.s	.loop

		move.l	writePtr,a0
		clr.b	(a0)+
		move.l	a0,writePtr
		
		moveq	#ItemProducedSignalId,d0
		bsr	setSignal
		
		rts


consumerThreadFunc

.loop
		move.l	readPtr,a2
		move.l	writePtr,a3
		cmp.l	a2,a3
		bne.s	.itemsAvailable

		moveq	#ItemProducedSignalId,d0
		bsr	waitAndClearSignal
		bra.s	.loop
	
.itemsAvailable
		

.consumeItem
		move.b	(a2)+,d0
		move.l	a0,readPtr

		cmp.b	#0,d0
		beq.s	.done


		move.b	d0,ConsumerMessageEnd-2
		
		move.l	DosBase,a6
		jsr	_LVOOutput(a6)
		move.l	d0,d1
		move.l	#ConsumerMessage,d2
		move.l	#ConsumerMessageEnd-ConsumerMessage,d3
		jsr	_LVOWrite(a6)

		cmp.l	a2,a3
		beq.s	.loop

.done
		rts


		section	data,data

ConsumerMessage
		dc.b	"Consumed value: X",10
ConsumerMessageEnd

DosName		dc.b	"dos.library",0

		even
		
readOffset	dc.w	0
writeOffset	dc.w	0
		
		section	bss,bss

ExecBase	ds.l	1
DosBase		ds.l	1

items
		ds.b	1024
		
producerStackBeginning
		ds.b	4096
producerStackEnd

consumerStackBeginning
		ds.b	4096
consumerStackEnd
