.nolist
.include "m48def.inc"
.include "macros.inc" // ����� ����������������
.list

; ���������
.EQU CPUfreq = 8000000

; ��������� - ����������� ������� ��� 
.EQU Volt_input = 0
.EQU Amps_input = 1
.EQU AC_timeout = 5; 4 // ���������� �������� ������� timer1 �� �������������� ��������� ������ ��������� ����������. 

; ����������� ������
#define	lcd_data_port	PORTB // ���� 4..7 ����� �������� ��� ���� ������ ����������
#define	lcd_enable		PB0 
#define	lcd_rs			PB1
#define	lcd_light		PB2

#define  enable_lcd_light SBI lcd_data_port, lcd_light
#define disable_lcd_light CBI lcd_data_port, lcd_light

#define	zero_signal		PORTD, PD3


; ��������
.def temp 			=	R1
.def amps_samples_counter = R6	// Interrupt only! don`t use if timer2 enabled!
.def amps_summl		=	R7		// Interrupt only! don`t use if timer2 enabled!
.def amps_summh		=	R8		// Interrupt only! don`t use if timer2 enabled!
.def flags			=	R5 // ���������� �����
.equ	zero_level	=	0

.def last_period_start_time	=	R9 ; ����� ��������� � ���������� ������ �������, � ���������� �� 65��.

.def ACCUM  = R16
.def ACCUMH = R17
.def tempi  = R18
.def tempih = R19


; ###########################################################################################
;�� ����������� ����������, ������������� � RAM
.dseg

Volts_BCD:	.BYTE 3
Amps_BCD:	.BYTE 3




; ###########################################################################################
; ��������� ������� �������
.macro set_flag 
  set_bit flags, @0
.endmacro

.macro clear_flag 
  clear_bit flags, @0
.endmacro

.macro enable_timer
 set_io	TCNT2, 0x00 // ����� �������
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
 disable_timer // ���� ���������� ��������� = 16 �� �������������������.

Iam_continue_measure:

 rcall Amps_measure		// ��, ����� �� ����� ��� �������. ��� ��������� ��������� ������
 						// ������������� �������� - ACCUM, ACCUMH

; ����������� ���������. ������������ ���� �� ������.
 ADD amps_summl, ACCUM
 ADC amps_summh, ACCUMH

; ---------------------
 POP	ACCUMH
 POP	ACCUM
 OUT    SREG, ACCUM
 POP	ACCUM
RETI







;##############################################################################
Izero_detetctor: // ������ �������� �������� ���������� ����� ����, �� ������ 
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

// �������������
 set_io PORTB, 0 // ��� ��������� ��������� ������ - �� �����.
 set_io PORTC, 0
 set_io PORTD, 0
//If DDxn is written logic one , Pxn is configured as an output. 
//If DDxn is written logic zero, Pxn is configured as an input.
 set_io	DDRB,	0b11111111  //��� �� �����
 set_io	DDRC,	0b00111100  //������� ������� �� ����������� �� �����
							// PC0, PC1 - ����� ������� ���� � ����������
							// PC2 - ���� ������ �����������.
 set_io	DDRD,	0b11110111  //RX-TX ��������� ��� ��X���, ��� ��������� ����������������� �� ������� ����� ����� ��������� ��� ���������� �����.

 set_io	EICRA,	0b00001100  // INT1 configured to rising edge
 set_io EIMSK,	0b00000010  // ���������� INT1 ���������(���������� �� ������� ZERO_LEVEL)

  
 set_io TCCR1A, 0b00000000 // ����� ������ ������� - 0, Normal, Free running
 set_io TCCR1B, 0b00000010 // ��������� = 8. ������ ������������ - 65.536�� ��� �������� ������� 8���
 set_io TIMSK1, 0b00000001 // ���������� �� ������������

 set_io OCR2A,	77	// �� ������� 8��� ��������� ���� >16 ���������� �� 10�� 
 set_io TCCR2A, 0b00000010 // ����� ������ ������� - 2, CTC
 set_io TCCR2B, 0b00000000 // ��������� = 0, ������ ����������. ������ ������ ������� �� ���������� ZERO_LEVEL, �� ������.
 set_io TIMSK2, 0b00000010 // ���������� �� ��������� �

 rcall	ADC_init // ��������� ��� � ��� ���������

 rcall	LCD_init

//  rcall Volt_measure      	**** DEBUG ****
//  rcall	LCD_output_volts	**** DEBUG ****
  

//  rcall Amps_measure			;**** DEBUG ****
//  rcall	LCD_output_amps		;**** DEBUG ****
  
// llll:  rjmp llll				;**** DEBUG ****

 SEI

// �������� ���������.
// ##############################

MAIN_LOOP:

 mov	ACCUM, last_period_start_time
 CPI	ACCUM, AC_timeout
 BRLO 	no_AC_timeout

; ������� �������� > 2 ���
; [ 
   ;��������� �����					***** TODO *****
   ;��������� ���������
  disable_lcd_light
   ;�������� ����������
  rcall	Volt_measure
   ;������� ���������� �� ��������� 
  rcall	LCD_output_volts
   ;�� ������ ������ ������� "AC fail"
  rcall	LCD_output_acfail
   ;����� 200 ����
   
  
  ldi	XL,  low(1000) ; x100us
  ldi	XH, high(1000) ; 2000 = 200ms
  rcall LCD_wait_X
   

 ;���������� ���� ��������
  set_reg last_period_start_time, AC_timeout

   ;��������� �������� ����         ***** TODO *****
   ;���� ������� ���� & 0x0F = 0	***** TODO *****
     ;[������ �������� ������]		***** TODO *****
 ;]
;
  rjmp AC_timeout_check_end

no_AC_timeout:
;�������� ���������
  enable_lcd_light
;����� �������� ����				***** TODO *****

AC_timeout_check_end:

 go_if_clear flags, zero_level, no_zero_int ; <������� ������ ���������>
  // ������ ������ ������ �������
  CLI 
  disable_timer
  
; �������� ������� ��������
  CLR last_period_start_time

; +���� �������: 
; + [ ���������� ������ ��������� ����, ��������� ����������
; +   amps_summh:amps_summl - ����� �������� ����� �� ������

;    ��������� �� ����� ���������� �������� ������� �������� ����(��������� �� 16) � ��������� ��� ������� �������� ����
  lsr	amps_summh     // 4-� ������� ����� ������, = ������� �� 16
  ror	amps_summl

  lsr	amps_summh
  ror	amps_summl

  lsr	amps_summh
  ror	amps_summl

  lsr	amps_summh
  ror	amps_summl
; ������� �������� ���� �� ������ ��������� ���: amps_summh:amps_summl

  rcall Volt_measure

;   ����������� ���������� ����������
;	����������� ������� �������� ����
;	���������� ���������������� ��������� >= 16
;	 [ �������� ������� ���������
;	   ����� ���� � ���������� ��������� �� 16 � ������� �� ��������� 
;	   ������� ��� ������ 20�� - �������� ��������� "�����"
;       [������� BCD-�������� ���������� � ���� � UART ��� SPI, �����������]
;	 ]
  rcall	LCD_output_volts

  mov	ACCUM , amps_summl
  mov	ACCUMH, amps_summh
  
  rcall	LCD_output_amps
  
; ���������� � ���������� ��������� �������� ���� �� ������.  
  CLR	amps_summh
  CLR	amps_summl
  CLR	amps_samples_counter

  clear_flag zero_level // ���������� ������� ������ �������, ��� ���������� ���������.

  enable_timer // ������ ������� ���������� ��������� ����
  
  rcall Iamps_measure // ���� �� �������� ������ ��������� ���� � ������������ ��������� ����������.
; *********** TODO ***********
;����� ��� amps_summl ��� amps_summh ������ ������������ ������ ����, ��� �������� ��������� ��������� - ��� ���� � ���� ����� ��� �� ������ ����.
  
no_zero_int: // ���������� �������� ������...

SLEEP // ��������� �������� ������, ���� ���������� ���������� ���� ��������� ������ ������� ���� ��������� AC, ���� ���������� ��������� ����.
RJMP MAIN_LOOP

.include "Indicator_def.inc"
.include "Indicator_code.inc"	// ������������ ������ � ��-����������� �� ������ KS7066
.include "bin2BCD.inc"			// ������������ �������������� ����� BIN-BCD ��� ������������ ������ �� ���������
.include "ADC_code.inc"
.include "lcd_output_code.inc"
