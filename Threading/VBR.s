
		include	"Threading/VBR.i"

		include	<lvo/exec_lib.i>
		include	<exec/execbase.i>
		
		section	code,code

;------------------------------------------------------------------------
; out	d0	VBR

getVBR
		movem.l	a5-a6,-(sp)

		move.l	$4.w,a6
		moveq	#0,d0
		btst	#0,AttnFlags+1(a6)
		beq.s	.vectorBaseZero
		
		lea	.readVBRSupervisorRoutine,a5
		jsr	_LVOSupervisor(a6)
.vectorBaseZero

		movem.l	(sp)+,a5-a6
		rts

.readVBRSupervisorRoutine
;		movec	vbr,d0
		dc.l	$4e7a0801
		rte
