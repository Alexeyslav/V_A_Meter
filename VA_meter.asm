.nolist
.include "m48def.inc"
.include "macros.inc" // общие макроопределения
.list

; Константы
.EQU CPUfreq = 8000000

; Константы - определение каналов АЦП 
.EQU Volt_input = 0
.EQU Amps_input = 1
.EQU AC_timeout = 5; 4 // Количество периодов таймера timer1 до детектирования состояния потери питающего напряжения. 

; Определения портов
#define	lcd_data_port	PORTB // биты 4..7 порта отведены под шину данных индикатора
#define	lcd_enable		PB0 
#define	lcd_rs			PB1
#define	lcd_light		PB2

#define  enable_lcd_light SBI lcd_data_port, lcd_light
#define disable_lcd_light CBI lcd_data_port, lcd_light

#define	zero_signal		PORTD, PD3


; Регистры
.def temp 			=	R1
.def amps_samples_counter = R6	// Interrupt only! don`t use if timer2 enabled!
.def amps_summl		=	R7		// Interrupt only! don`t use if timer2 enabled!
.def amps_summh		=	R8		// Interrupt only! don`t use if timer2 enabled!
.def flags			=	R5 // глобальные флаги
.equ	zero_level	=	0

.def last_period_start_time	=	R9 ; Время прошедшее с последнего начала периода, в интервалах по 65мс.

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
; Локальные макросы проекта
.macro set_flag 
  set_bit flags, @0
.endmacro

.macro clear_flag 
  clear_bit flags, @0
.endmacro

.macro enable_timer
 set_io	TCNT2, 0x00 // Сброс таймера
 set_io TCCR2B, 0b00000100
.endmacro

.macro disable_timer
 set_io TCCR2B, 0b00000000
.endmacro



; ###########################################################################################
; ###########################################################################################
; ###########################################################################################
; ###########################################################################################
.cseg
.org 0
rjmp RESET ; Reset Handler
RETI ;rjmp EXT_INT0 ; IRQ0 Handler
rjmp Izero_detetctor ; IRQ1 Handler
RETI ;rjmp PCINT0 ; PCINT0 Handler
RETI ;rjmp PCINT1 ; PCINT1 Handler
RETI ;rjmp PCINT2 ; PCINT2 Handler
RETI ;rjmp WDT ; Watchdog Timer Handler
rjmp Iamps_measure ; Timer2 Compare A Handler
RETI ;rjmp TIM2_COMPB ; Timer2 Compare B Handler
RETI ;rjmp TIM2_OVF ; Timer2 Overflow Handler
RETI ;rjmp TIM1_CAPT ; Timer1 Capture Handler
RETI ;rjmp TIM1_COMPA ; Timer1 Compare A Handler
RETI ;rjmp TIM1_COMPB ; Timer1 Compare B Handler
rjmp IAC_detector ; Timer1 Overflow Handler
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







;##############################################################################
Iamps_measure: ; <timer2>
 PUSH	ACCUM
 PUSH	ACCUMH
 IN		ACCUM, SREG
 PUSH	ACCUM
; ---------------------
 inc	amps_samples_counter
 mov	ACCUM, amps_samples_counter

 CPI	ACCUM, 16
 BRNE	Iam_continue_measure
 disable_timer // Если количество измерений = 16 то самоостанавливаемся.

Iam_continue_measure:

 rcall Amps_measure		// Да, здесь мы можем это сделать. для упрощения обработки данных
 						// Затрагиваемые регистры - ACCUM, ACCUMH

; Накапливаем результат. переполнения быть не должно.
 ADD amps_summl, ACCUM
 ADC amps_summh, ACCUMH

; ---------------------
 POP	ACCUMH
 POP	ACCUM
 OUT    SREG, ACCUM
 POP	ACCUM
RETI







;##############################################################################
Izero_detetctor: // момент перехода сетевого напряжения через ноль, на выводе 
 PUSH	ACCUM
 IN		ACCUM, SREG
 PUSH	ACCUM

 set_flag zero_level

 POP	ACCUM
 OUT    SREG, ACCUM
 POP	ACCUM
RETI







;##############################################################################
IAC_detector:

 PUSH	ACCUM
 IN		ACCUM, SREG
 PUSH	ACCUM

 inc last_period_start_time

 POP	ACCUM
 OUT    SREG, ACCUM
 POP	ACCUM

RETI








;##############################################################################
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
 set_io	DDRB,	0b11111111  //Все на вывод
 set_io	DDRC,	0b00111100  //старшие разряды не реализованы на выход
							// PC0, PC1 - входы каналов тока и напряжения
							// PC2 - вход канала температуры.
 set_io	DDRD,	0b11110111  //RX-TX настроены как ВыXОДЫ, при включении приемопередатчика их функция будет иметь приоритет над настройкой порта.

 set_io	EICRA,	0b00001100  // INT1 configured to rising edge
 set_io EIMSK,	0b00000010  // Прерывание INT1 разрешено(прерывание по сигналу ZERO_LEVEL)

  
 set_io TCCR1A, 0b00000000 // режим работы таймера - 0, Normal, Free running
 set_io TCCR1B, 0b00000010 // Прескалер = 8. период переполнения - 65.536мс при тактовой частоте 8Мгц
 set_io TIMSK1, 0b00000001 // прерывание по переполнению

 set_io OCR2A,	77	// на частоте 8Мгц константа дает >16 прерываний за 10мс 
 set_io TCCR2A, 0b00000010 // режим работы таймера - 2, CTC
 set_io TCCR2B, 0b00000000 // Прескалер = 0, таймер остановлен. Отсчет должен начатся по прерыванию ZERO_LEVEL, не раньше.
 set_io TIMSK2, 0b00000010 // прерывание по сравнению А

 rcall	ADC_init // Включение АЦП и его настройка

 rcall	LCD_init

//  rcall Volt_measure      	**** DEBUG ****
//  rcall	LCD_output_volts	**** DEBUG ****
  

//  rcall Amps_measure			;**** DEBUG ****
//  rcall	LCD_output_amps		;**** DEBUG ****
  
// llll:  rjmp llll				;**** DEBUG ****

 SEI

// Основная программа.
// ##############################

MAIN_LOOP:

 mov	ACCUM, last_period_start_time
 CPI	ACCUM, AC_timeout
 BRLO 	no_AC_timeout

; Счетчик таймаута > 2 сек
; [ 
   ;отключить заряд					***** TODO *****
   ;выключить подсветку
  disable_lcd_light
   ;измерить напряжение
  rcall	Volt_measure
   ;вывести напряжение на индикатор 
  rcall	LCD_output_volts
   ;во втроую строку вывести "AC fail"
  rcall	LCD_output_acfail
   ;пауза 200 мсек
   
  
  ldi	XL,  low(1000) ; x100us
  ldi	XH, high(1000) ; 2000 = 200ms
  rcall LCD_wait_X
   

 ;ограничить счет таймаута
  set_reg last_period_start_time, AC_timeout

   ;инкремент счетчика пауз         ***** TODO *****
   ;если счетчик пауз & 0x0F = 0	***** TODO *****
     ;[подать короткий сигнал]		***** TODO *****
 ;]
;
  rjmp AC_timeout_check_end

no_AC_timeout:
;включить подсветку
  enable_lcd_light
;сброс счетчика пауз				***** TODO *****

AC_timeout_check_end:

 go_if_clear flags, zero_level, no_zero_int ; <признак начала измерения>
  // Пришел сигнал начала периода
  CLI 
  disable_timer
  
; сбросить счетчик таймаута
  CLR last_period_start_time

; +есть признак: 
; + [ остановить таймер измерения тока, запретить прерывания
; +   amps_summh:amps_summl - сумма значений токов за период

;    посчитать из суммы мгновенных значений среднее значение тока(разделить на 16) и сохранить как среднее значение тока
  lsr	amps_summh     // 4-х кратный сдвиг вправо, = деление на 16
  ror	amps_summl

  lsr	amps_summh
  ror	amps_summl

  lsr	amps_summh
  ror	amps_summl

  lsr	amps_summh
  ror	amps_summl
; среднее значение тока за период находится тут: amps_summh:amps_summl

  rcall Volt_measure

;   суммировать измеренное напряжение
;	суммировать среднее значение тока
;	количество просуммированных элементов >= 16
;	 [ сбросить счетчик элементов
;	   сумму тока и напряжения разделить на 16 и вывести на индикатор 
;	   средний ток больше 20мА - включить светодиод "заряд"
;       [вывести BCD-значения напряжения и тока в UART или SPI, опционально]
;	 ]
  rcall	LCD_output_volts

  mov	ACCUM , amps_summl
  mov	ACCUMH, amps_summh
  
  rcall	LCD_output_amps
  
; Подготовка к следующему измерению среднего тока за период.  
  CLR	amps_summh
  CLR	amps_summl
  CLR	amps_samples_counter

  clear_flag zero_level // сбрасываем признак начала периода, для дальнейшей обработки.

  enable_timer // запуск таймера интервалов измерения тока
  
  rcall Iamps_measure // Этим мы начинаем первое измерение тока и одновременно разрешаем прерывание.
; *********** TODO ***********
;Еслит тут amps_summl или amps_summh больше минимального порога шума, это означает аварийное состояние - ток идет в цепи когда его НЕ ДОЛЖНО БЫТЬ.
  
no_zero_int: // продолжаем проверки дальше...

SLEEP // безцельно крутится нечего, ждем следующего прерывания либо детектора начала периода либо детектора AC, либо прерывания измерения тока.
RJMP MAIN_LOOP

.include "Indicator_def.inc"
.include "Indicator_code.inc"	// Подпрограммы работы с ЖК-индикатором на основе KS7066
.include "bin2BCD.inc"			// Подпрограмма преобразования числа BIN-BCD для последующего вывода на индикатор
.include "ADC_code.inc"
.include "lcd_output_code.inc"
