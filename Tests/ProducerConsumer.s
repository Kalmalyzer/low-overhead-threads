
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Signals.i"
		include	"Threading/Threads.i"

		include	<lvo/exec_lib.i>
		include	<lvo/dos_lib.i>

ConsumerThreadId = 0
ProducerThreadId = 1

ItemProducedSignalId = 0

		section	code,code

start:
		moveq	#ConsumerThreadId,d0
		lea	consumerThreadFunc,a0
		lea	consumerUserStackEnd,a1
		lea	consumerSuperStackEnd,a2
		bsr	setupThread

		moveq	#ProducerThreadId,d0
		lea	producerThreadFunc,a0
		lea	producerUserStackEnd,a1
		lea	producerSuperStackEnd,a2
		bsr	setupThread

		bsr	runScheduler

		moveq	#0,d0
		rts
		
		
producerThreadFunc
		LOG_INFO_STR "Producer starts"

		moveq	#0,d7
.loop
		move.l	writePtr,a0
		moveq	#'0',d1
		add.b	d7,d1
		move.b	d1,(a0)+
		move.l	a0,writePtr

		move.b	d1,ProducerMessageEnd-2
		
		LOG_INFO_PTR #ProducerMessage

		moveq	#ItemProducedSignalId,d0
		bsr	setSignal

		addq.l	#1,d7
		cmp.l	#10,d7
		bne.s	.loop

		move.l	writePtr,a0
		move.b	#$ff,(a0)+
		move.l	a0,writePtr
		
		moveq	#ItemProducedSignalId,d0
		bsr	setSignal
		
		LOG_INFO_STR "Producer done"

		rts


consumerThreadFunc
		LOG_INFO_STR "Consumer starts"

.loop
		move.l	readPtr,a2
		move.l	writePtr,a3
		cmp.l	a2,a3
		bne.s	.itemsAvailable

		LOG_INFO_STR "Consumer has no items available, waits for signal from producer"

		moveq	#ItemProducedSignalId,d0
		bsr	waitAndClearSignal

		LOG_INFO_STR "Consumer receives signal from producer, and looks for items again"
		bra.s	.loop
	
.itemsAvailable
		
		LOG_INFO_STR "Consumer has items available"

.consumeItem
		move.l	readPtr,a2
		move.b	(a2)+,d0
		move.l	a2,readPtr

		cmp.b	#$ff,d0
		beq.s	.done

		move.b	d0,ConsumerMessageEnd-2
		
		LOG_INFO_PTR #ConsumerMessage

		bra.s	.loop

.done
		LOG_INFO_STR "Consumer done"

		rts


		section	data,data

ProducerMessage
		dc.b	"Produced value: X",0
ProducerMessageEnd

ConsumerMessage
		dc.b	"Consumed value: X",0
ConsumerMessageEnd

		even
		
readPtr		dc.l	items
writePtr	dc.l	items
		
		section	bss,bss

items
		ds.b	1024
		
producerUserStackBeginning
		ds.b	4096
producerUserStackEnd

producerSuperStackBeginning
		ds.b	4096
producerSuperStackEnd

consumerUserStackBeginning
		ds.b	4096
consumerUserStackEnd

consumerSuperStackBeginning
		ds.b	4096
consumerSuperStackEnd
