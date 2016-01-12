
VBLANKS_BETWEEN_EACH_PRODUCTION	=	2*50

		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Signals.i"
		include	"Threading/Threads.i"
		include	"Threading/VBR.i"

		include	<lvo/exec_lib.i>
		include	<lvo/dos_lib.i>

		include <hardware/custom.i>
		include <hardware/intbits.i>
		
ConsumerThreadId = 0
ProducerThreadId = 1

ItemProducedSignalId = 0
TimeToProduceItemSignalId = 1

		section	code,code

start:
		bsr	installLevel3Handler

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

		
		bsr	removeLevel3Handler
		
		moveq	#0,d0
		rts

;------------------------------------------------------------------------

installLevel3Handler
		DISABLE_INTERRUPTS
		bsr	getVBR
		move.l	d0,a0
		move.l	$6c(a0),oldLevel3InterruptHandler
		move.l	#level3InterruptHandler,$6c(a0)
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------

removeLevel3Handler
		DISABLE_INTERRUPTS
		bsr	getVBR
		move.l	d0,a0
		move.l	oldLevel3InterruptHandler,$6c(a0)
		ENABLE_INTERRUPTS
		rts
		
;------------------------------------------------------------------------

level3InterruptHandler
		btst	#INTB_VERTB,intreqr+(1-(INTB_VERTB/8))+$dff000
		beq.s	.nVertB
		
		addq.w	#1,TriggerVBlankCounter
		cmp.w	#VBLANKS_BETWEEN_EACH_PRODUCTION,TriggerVBlankCounter
		bne.s	.nTriggerProduction
		clr.w	TriggerVBlankCounter

		movem.l	d0-d1/a0-a1,-(sp)
		moveq	#TimeToProduceItemSignalId,d0
		bsr	setSignalFromInterrupt
		movem.l	(sp)+,d0-d1/a0-a1
		
.nTriggerProduction
		
.nVertB
		move.l	oldLevel3InterruptHandler,-(sp)
		rts

;------------------------------------------------------------------------
		
producerThreadFunc
		LOG_INFO_STR "Producer starts"

		moveq	#0,d7
.loop
		moveq	#TimeToProduceItemSignalId,d0
		bsr	waitAndClearSignal

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

oldLevel3InterruptHandler
		dc.l	0

TriggerVBlankCounter
		dc.w	0

		section	bss,bss

items
		ds.b	1024
		
producerStackBeginning
		ds.b	4096
producerStackEnd

consumerStackBeginning
		ds.b	4096
consumerStackEnd
