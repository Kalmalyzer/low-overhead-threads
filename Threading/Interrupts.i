
;----------------------------------------------------------
; Clear the global "disable all interrupts" flag in INTENA

ENABLE_INTERRUPTS	MACRO

intena_\@	EQU	$9a
INTF_SETCLR_\@	EQU	(1<<15)
INTF_INTEN_\@	EQU	(1<<14)

		move.w	#INTF_SETCLR_\@|INTF_INTEN_\@,intena_\@+$dff000
			ENDM
			
;---------------------------------------------------------
; Set the global "disable all interrupts" flag in INTENA

DISABLE_INTERRUPTS	MACRO

intena_\@	EQU	$9a
INTF_INTEN_\@	EQU	(1<<14)

		move.w	#INTF_INTEN_\@,intena_\@+$dff000
			ENDM

;----------------------------------------------------------
; Enable SOFTINT in INTENA; no reentrancy count

ENABLE_SCHEDULER_INTERRUPT	MACRO

intena_\@	EQU	$9a
INTF_SETCLR_\@	EQU	(1<<15)
INTF_SOFTINT_\@	EQU	(1<<2)

		move.w	#INTF_SETCLR_\@|INTF_SOFTINT_\@,intena_\@+$dff000
			ENDM
			
;---------------------------------------------------------
; Disable SOFTINT in INTENA; no reentrancy count

DISABLE_SCHEDULER_INTERRUPT	MACRO

intena_\@	EQU	$9a
INTF_SOFTINT_\@	EQU	(1<<2)

		move.w	#INTF_SOFTINT_\@,intena_\@+$dff000
			ENDM

;---------------------------------------------------------
; Request a scheduler interrupt

REQUEST_SCHEDULER_INTERRUPT	MACRO

intreq_\@	EQU	$9c
INTF_SETCLR_\@	EQU	(1<<15)
INTF_SOFTINT_\@	EQU	(1<<2)

		move.w	#INTF_SETCLR_\@|INTF_SOFTINT_\@,intreq_\@+$dff000
			ENDM

;---------------------------------------------------------
; Acknowledge scheduler interrupt

ACKNOWLEDGE_SCHEDULER_INTERRUPT	MACRO

intreq_\@	EQU	$9c
INTF_SOFTINT_\@	EQU	(1<<2)

		move.w	#INTF_SOFTINT_\@,intreq_\@+$dff000
			ENDM
