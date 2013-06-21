.nolist
.include "m48def.inc"
.include "macros.inc" // общие макроопределения
.list

.EQU CPUfreq = 8000000


.def temp 			= R1


.def ACCUM  = R16
.def ACCUMH = R17
.def tempi  = R18
.def tempih = R19


; ###########################################################################################
;Не оперативные переменные, располагаются в RAM
.dseg

Volts_BCD:	.BYTE 3
Amps_BCD:	.BYTE 3

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

 rcall	LCD_init

 rcall	LCD_goto_line1

 LDI	ACCUM, 0x20
 rcall	LCD_send_char
 

 LDI	ACCUM, low(12345)
 LDI	ACCUMH, high(12345)

 LDI	XL, low(Volts_BCD)
 LDI	XH, high(Volts_BCD)

 rcall bin2bcd

 LD		ACCUM, -X
 ANDI	ACCUM, 0x0F
 SUBI	ACCUM, -48
 rcall	LCD_send_char

 LD		ACCUM, -X
 ANDI	ACCUM, 0x0F
 SUBI	ACCUM, -48
 rcall	LCD_send_char

 LD		ACCUM, -X
 ANDI	ACCUM, 0x0F
 SUBI	ACCUM, -48
 rcall	LCD_send_char

MAIN_LOOP:


RJMP MAIN_LOOP

.include "Indicator_def.inc"
.include "Indicator_code.inc"	// Подпрограммы работы с ЖК-индикатором на основе KS7066
.include "bin2BCD.inc"			// Подпрограмма преобразования числа BIN-BCD для последующего вывода на индикатор
