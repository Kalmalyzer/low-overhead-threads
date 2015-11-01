

;------------------------------------------------------------------------
; Print message to standard output
;
; Argument:	pointer to string start (ASCIIZ)
; 

LOG_MESSAGE_BASE_PTR	MACRO	\1

; from lvo/exec_lib.i
_LVOOpenLibrary_\@	EQU	-408
_LVOCloseLibrary_\@	EQU	-414

; from lvo/dos_lib.i
_LVOOutput_\@		EQU	-60
_LVOWrite_\@		EQU	-48

		movem.l	d0-d3/a0-a1/a6,-(sp)

		move.l	\1,-(sp)
		
		; Compute length of string
		move.l	\1,a0
		moveq	#-1,d0
.checkCharacter_\@
		addq.l	#1,d0
		tst.b	(a0)+
		bne.s	.checkCharacter_\@
		move.l	d0,-(sp)

		; Open dos.library
		
		move.l	$4.w,a6
		lea	.dosName_\@,a1
		moveq	#0,d0
		jsr	_LVOOpenLibrary_\@(a6)
		move.l	d0,a6

		; Print string to standard output
		
		jsr	_LVOOutput_\@(a6)
		move.l	d0,d1
		move.l	(sp)+,d3
		move.l	(sp)+,d2
		jsr	_LVOWrite_\@(a6)

		; Close dos.library
		
		move.l	a6,a1
		move.l	$4.w,a6
		jsr	_LVOCloseLibrary_\@(a6)

		movem.l	(sp)+,d0-d3/a0-a1/a6

		; Skip over strings embedded in code segment
		
		bra.w	.dosNameSkip_\@

.dosName_\@	dc.b	"dos.library",0

		even
.dosNameSkip_\@
		ENDM

;------------------------------------------------------------------------
; Print message to standard output
;
; Arguments:	"string1",pointer1
; 

LOG_MESSAGE_PTR	MACRO	\1,\2
		move.l	\2,-(sp)
		move.l	a0,-(sp)
		LOG_MESSAGE_BASE_PTR	#.prefix_\@
		move.l	4(sp),a0
		LOG_MESSAGE_BASE_PTR	a0
		LOG_MESSAGE_BASE_PTR	#.text_\@
		move.l	(sp)+,a0
		addq.l	#4,sp
		
		bra.w	.textSkip_\@
.prefix_\@	dc.b	\1,0
.text_\@	dc.b	10,0
		even
.textSkip_\@
		ENDM

;------------------------------------------------------------------------
; Print message to standard output
;
; Arguments:	"string1","string2"
; 

LOG_MESSAGE_STR	MACRO	\1,\2
		LOG_MESSAGE_BASE_PTR #.prefix_\@
		LOG_MESSAGE_BASE_PTR #.text_\@
		
		bra.w	.textSkip_\@
.prefix_\@	dc.b	\1,0
.text_\@	dc.b	\2,10,0
		even
.textSkip_\@
		ENDM
		
		
;------------------------------------------------------------------------
; Print a constant string to standard output
;
; Usage: LOG_INFO_PTR #StartOfString (or address register)
;

LOG_INFO_PTR	MACRO	\1
		LOG_MESSAGE_PTR	"Info: ",\1
		ENDM

;------------------------------------------------------------------------
; Print a constant string to standard output
;
; Usage: LOG_INFO_STR "Hi everyone"
;

LOG_INFO_STR	MACRO	\1
		LOG_MESSAGE_STR	"Info: ",\1
		ENDM

;------------------------------------------------------------------------
; Print a constant string to standard output, then stop
;
; Usage: LOG_ERROR_PTR #StartOfString (or address register)
;

LOG_ERROR_PTR	MACRO	\1
		LOG_MESSAGE_PTR	"Error: ",\1
		illegal
		ENDM

;------------------------------------------------------------------------
; Print a constant string to standard output, then stop
;
; Usage: LOG_ERROR_STR "Something terrible just happened"
;

LOG_ERROR_STR	MACRO	\1
		LOG_MESSAGE_STR	"Error: ",\1
		illegal
		ENDM
