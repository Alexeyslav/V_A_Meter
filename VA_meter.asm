.nolist
.include "m48def.inc"
.include "macros.inc" // общие макроопределения
.list

.def temp 			= R1


.def ACCUM = R16
.def tempi = R17


; ###########################################################################################
;Не оперативные переменные, располагаются в RAM
.dseg

; ###########################################################################################
; ###########################################################################################
; ###########################################################################################
; ###########################################################################################
.cseg
.org 0
rjmp RESET ; Reset Handler
RETI ;rjmp EXT_INT0 ; IRQ0 Handler
RETI ;rjmp EXT_INT1 ; IRQ1 Handler
RETI ;rjmp PCINT0 ; PCINT0 Handler
RETI ;rjmp PCINT1 ; PCINT1 Handler
RETI ;rjmp PCINT2 ; PCINT2 Handler
RETI ;rjmp WDT ; Watchdog Timer Handler
RETI ;rjmp TIM2_COMPA ; Timer2 Compare A Handler
RETI ;rjmp TIM2_COMPB ; Timer2 Compare B Handler
RETI ;rjmp TIM2_OVF ; Timer2 Overflow Handler
RETI ;rjmp TIM1_CAPT ; Timer1 Capture Handler
RETI ;rjmp TIM1_COMPA ; Timer1 Compare A Handler
RETI ;rjmp TIM1_COMPB ; Timer1 Compare B Handler
RETI ;rjmp TIM1_OVF ; Timer1 Overflow Handler
RETI ;rjmp TIM0_COMPA ; Timer0 Compare A Handler
RETI ;rjmp TIM0_COMPB ; Timer0 Compare B Handler
RETI ;rjmp TIM0_OVF ; Timer0 Overflow Handler
RETI ;rjmp SPI_STC ; SPI Transfer Complete Handler
RETI ;rjmp USART_RXC ; USART, RX Complete Handler
RETI ;rjmp USART_UDRE ; USART, UDR Empty Handler
RETI ;rjmp USART_TXC ; USART, TX Complete Handler
RETI ;rjmp ADC ; ADC Conversion Complete Handler
RETI ;rjmp EE_RDY ; EEPROM Ready Handler
RETI ;rjmp ANA_COMP ; Analog Comparator Handler
RETI ;rjmp TWI ; 2-wire Serial Interface Handler
RETI ;rjmp SPM_RDY ; Store Program Memory Ready Handler

RESET: 
 ldi	ACCUM,	high(RAMEND)
 out	SPH,	ACCUM        ; Set Stack Pointer to top of RAM
 ldi	ACCUM,	low(RAMEND)
 out	SPL,	ACCUM

// Инициализация
set_io PORTB, 0 // все начальные состояния портов - по нулям.
set_io PORTC, 0
set_io PORTD, 0
//If DDxn is written logic one , Pxn is configured as an output. 
//If DDxn is written logic zero, Pxn is configured as an input.
set_io DDRB, 0b11111111  //Все на вывод
set_io DDRC, 0b00111111  //старшие разряды не реализованы на выход
set_io DDRD, 0b11111111  //RX-TX настроены как ВыXОДЫ, при включении приемопередатчика их функция будет иметь приоритет над настройкой порта.


MAIN_LOOP:


RJMP MAIN_LOOP
