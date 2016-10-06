	list      p=10F200            ; list directive to define processor
	#include <p10f200.inc>        ; processor specific variable definitions

    __CONFIG _WDT_OFF & _CP_OFF & _MCLRE_OFF


    ; GP0 - LED output
    ; GP1 - SIG output
    ; GP2 - SIG input
    ; GP3 - LED config input
#define LED_OUT 0
#define SIG_OUT 1
#define SIG_IN  2
#define LED_CNF 3

#define TMRMAX .125             ; .125 in TMR0 register equal 500 us @ 4MHz clock and 1:4 pre-scaler

;***** VARIABLE DEFINITIONS
TEMP_VAR    UDATA
tmrActive   RES     1           ; bit 0 = timer is running
tmrExpired  RES     1           ; bit 0 = timer is expired

;***** RESET VECTOR
RESET_VECTOR	CODE   0xFF

; Internal RC calibration value is placed at location 0xFF by Microchip
; as a movlw k, where the k is a literal value.

MAIN	CODE    0x000
	movwf   OSCCAL              ; update register with factory cal value

    movlw   b'11000001'         ; pre-scaler 1:4
                                ; pre-scaler assigned to TMR0
                                ; increment to low-to-high transition on the T0CLK pin
                                ; transition on internal instruction clock, Fosc/4
                                ; weak pull-ups disabled
                                ; disable wake-up on pin change
    OPTION    

;***** MAIN PROGRAM    
    movlw   b'00001100'         ; set GPIO 2 & 3 inputs, other -- outputs
    TRIS    GPIO
    clrf    GPIO                ; set all GPIO pins low

    clrf    tmrActive
    clrf    tmrExpired

;***** MAIN LOOP
START   
    btfsc   GPIO, SIG_IN
    goto    $+3
    call    INPUT_LOW
    goto    $+2
    call    INPUT_HIGH

    call    SETLED

    goto START

;***** INPUT LOW func
INPUT_LOW
    clrf    tmrExpired
    clrf    tmrActive    
    bcf     GPIO, SIG_OUT
    retlw   0x00

;***** INPUT HIGH func
INPUT_HIGH
    btfsc   tmrExpired, 0
    goto    TIMER_EXPIRED

    btfsc   tmrActive, 0
    goto    TIMER_RUNNING

    clrf    TMR0
    bsf     tmrActive, 0

    retlw   0x00

TIMER_EXPIRED
    bsf     GPIO, SIG_OUT
    retlw   0x00

TIMER_RUNNING
    movlw   TMRMAX
    subwf   TMR0, w
    btfsc   STATUS, C           ; if TMR0 >= TMRMAX
    bsf     tmrExpired, 0
    retlw   0x00


;***** SET LED_OUT STATE
SETLED
    btfss   GPIO, LED_CNF
    goto    SETLEDNORM
    goto    SETLEDINV

SETLEDNORM
    btfsc   GPIO, SIG_IN
    goto    $+3
    bcf     GPIO, LED_OUT
    goto    $+2
    bsf     GPIO, LED_OUT
    retlw   0x00

SETLEDINV
    btfss   GPIO, SIG_IN
    goto    $+3
    bcf     GPIO, LED_OUT
    goto    $+2
    bsf     GPIO, LED_OUT
    retlw   0x00

	END                       ; directive 'end of program'