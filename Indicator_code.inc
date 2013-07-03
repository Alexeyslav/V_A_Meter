; LCD is 4 bit mode operation
; в 4-битном режиме передача данных идет старшие 4 бита, затем младшие.
; CGRAM - паттерны символов определенных пользователем.
; DDRAM - память отображаемых на индикаторе кодов символов.(видеопамять)
.EQU LCD_wf_delayus		= 100	; длительность выполнения быстрых операций на LCD в микросекундах
								; по даташиту - не менее 42мкс(запись в память)
.EQU LCD_slow_delayus	= 1600  ; время выполнения операции очистки индикатора в микросекундах, даташит рекомендует >1520мкс
.EQU LCD_start_delayms	= 20	; задержка на этапе инициализации индикатора милисекунд, даташит рекомендует >14мс

LCD_send_cmd: ; ACCUM = command
 lcd_cmd
 rjmp LCD_send_data4b

LCD_send_char: ; ACCUM = символ для вывода на экран/байт для загрузки в CGRAM
 lcd_data
 rjmp LCD_send_data4b

LCD_goto_line1: ; Курсор - в начало первой строки
 LDI ACCUM, 0x80	; адрес DDRAM = 0x00
 rjmp	LCD_send_cmd

LCD_goto_line2: ; Курсор - в начало второй строки
 LDI ACCUM, 0xC0	; адрес DDRAM = 0x40
 rjmp	LCD_send_cmd

LCD_goto_CGRAM: ; ACCUM - номер символа в CGRAM для загрузки (0..8)
; На описание символа отводится 8 байт(первый - сверху) - младшие 5 бит(младший - справа) описывают развертку символа сверху-вниз матрицей 5x8
; Последняя строка - линия курсора и должна быть чистой, иначе курсор не будет видно.
; Всего можно определить 8 пользовательских символов, которые соответствуют кодам символов основной таблицы 0..8(9..15 - повтор)
 LSL	ACCUM
 LSL	ACCUM
 LSL	ACCUM
 ANDI	ACCUM, 0x3F
 ORI	ACCUM, 0x40 ; команда SET CGRAM
 rjmp	LCD_send_cmd

.MACRO LCD_WAITUS 
 
 LDI XH, high(@0/LCD_wf_delayus)
 LDI XL,  low(@0/LCD_wf_delayus)

 rcall LCD_wait_X
 
.ENDMACRO

.MACRO LCD_cmd8b
 LDI ACCUM, @0
 rcall LCD_send_cmd8b
.ENDMACRO

LCD_send_cmd8b:
 out lcd_data_port, ACCUM  ; команда - переключение в 4-битный режим.
 lcd_cmd	; режим ввода команд(по-большому можно было просто учесть в константе выше...)
rjmp lcd_strobe





; #############################################################################

;    LCD_INIT

; #############################################################################






LCD_init:
 rcall LCD_wait_init ; гарантированная задержка перед инициализацией дисплея

 LCD_cmd8b 0x30
 LCD_WAITUS 5000 ; 5ms > 4.1ms
 
 LCD_cmd8b 0x30
 LCD_WAITUS 300 ; 300us > 100us
 
 LCD_cmd8b 0x30
 rcall LCD_wait_fast

 LCD_cmd8b 0x20 ; переключение в 4-битный режим.
 rcall LCD_wait_fast


 ; команда - повторное переключение в 4-битный режим, с указанием доп. параметров т.к. выше они были недоступны.
           ; 0x28 = 2 lines, 5*7 font, 4-BIT MODE!
 LDI	ACCUM, 0x28
 rcall	LCD_send_cmd

 LDI	ACCUM, 0x08 ; выключить дисплей!
 rcall	LCD_send_cmd
 
 LDI	ACCUM, 0x01 ; очистить дисплей
 rcall	LCD_send_cmd
 rcall	LCD_wait_slow

 LDI	ACCUM, 0x06		; auto-inc cursor, display not shift. 
 rcall	LCD_send_cmd  	; cmd = Entry mode set
 rcall	LCD_wait_slow 

 LDI	ACCUM, 0x0C ; включить дисплей!
 rcall	LCD_send_cmd
 rcall	LCD_wait_slow
RET

LCD_strobe:
 lcd_chip_sel
 nop
 nop
 nop
 lcd_chip_desel
RET

LCD_send_data4b:   ; передача данных/команд индикатору в 4-битном режиме
; Передаём старшую часть данных
 push	ACCUM ; параметр испортится, надо его сохранить

 ANDI	ACCUM, 0b11110000 ; обнуляем часть регистра не принадлежащем битам данных.
 IN		tempi, lcd_data_port
 CBR	tempi, 0b11110000 ; обнуляем биты порта где должны быть данные.
 OR		ACCUM, tempi
 OUT	lcd_data_port, ACCUM
 rcall	LCD_strobe
 
 pop	ACCUM
 swap	ACCUM ; исходное значение восстановлено, и в старшей части находится младшая тетрада.

; Передаём младшую часть
 ANDI	ACCUM, 0b11110000 ; обнуляем часть регистра не принадлежащем битам данных.
 IN		tempi, lcd_data_port
 CBR	tempi, 0b11110000 ; обнуляем биты порта где должны быть данные.
 OR		ACCUM, tempi
 OUT	lcd_data_port, ACCUM
 rcall	LCD_strobe
 rcall	LCD_wait_fast
RET









; ========================= Варианты задержек =================================
; =============================================================================


LCD_wait_fast: ; T = 37us = 37/1000000
; N(количество тактов) = T/t = T(us)*CPUfreq/1000000 = 37*8 = 296 
; n(количество итераций) = N/N(1итер)
; N(1итер) = 5
.EQU lwf_oneiteration = 5
.EQU LCD_wf_iterations = (LCD_wf_delayus * CPUfreq / 1000000) / lwf_oneiteration
;-----------------------------------------
.if (LCD_wf_iterations > 255)||(LCD_wf_iterations < 3)
.error "LCD_wait_fast: - overflow iteration counter, correct algorithm!"
.endif
;-----------------------------------------
 push	tempi
 ldi	tempi, LCD_wf_iterations - 2 ; учесть 12 тактов накладных расходов.
lwf_loop:
 nop
 nop
 dec	tempi
 brne	lwf_loop
 pop	tempi
RET

LCD_wait_X: ; Выполняет задержку равную XH:XL раз больше чем LCD_wait_fast

; Цикл на XH:XL итераций
lwx_loop:
 SUBI XL, 1
 SBCI XH, 0
 BRCS lwx_exit ; Если X = 0 - выходим.
 rcall LCD_wait_fast
 rjmp lwx_loop
  ; возник заем для старшего разряда, но занимать не у кого - признак окончания цикла.

lwx_exit:
RET

.EQU LCD_ws_iterations = LCD_slow_delayus / LCD_wf_delayus ; about 1.5ms

LCD_wait_slow:
 push XH
 push XL
 LDI XH, high(LCD_ws_iterations)
 LDI XL,  low(LCD_ws_iterations)

  rcall LCD_wait_X

 pop XL
 pop XH 
RET

.EQU LCD_wi_iterations = LCD_start_delayms * 1000 / LCD_wf_delayus

LCD_wait_init: ; about 20ms
 push XH
 push XL
 LDI XH, high(LCD_wi_iterations)
 LDI XL,  low(LCD_wi_iterations)

 rcall LCD_wait_X

 pop XL
 pop XH 
RET




