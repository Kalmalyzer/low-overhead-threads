

		XREF	logMessageBasePtr

;------------------------------------------------------------------------
; Print message to standard output
;
; Argument:	pointer to string start (ASCIIZ)
; 

LOG_MESSAGE_BASE_PTR	MACRO	\1

		move.l	\1,-(sp)
		bsr	logMessageBasePtr
		addq.l	#4,sp

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
