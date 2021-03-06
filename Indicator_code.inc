; LCD is 4 bit mode operation
; � 4-������ ������ �������� ������ ���� ������� 4 ����, ����� �������.
; CGRAM - �������� �������� ������������ �������������.
; DDRAM - ������ ������������ �� ���������� ����� ��������.(�����������)
.EQU LCD_wf_delayus		= 100	; ������������ ���������� ������� �������� �� LCD � �������������
								; �� �������� - �� ����� 42���(������ � ������)
.EQU LCD_slow_delayus	= 1600  ; ����� ���������� �������� ������� ���������� � �������������, ������� ����������� >1520���
.EQU LCD_start_delayms	= 20	; �������� �� ����� ������������� ���������� ����������, ������� ����������� >14��

LCD_send_cmd: ; ACCUM = command
 lcd_cmd
 rjmp LCD_send_data4b

LCD_send_char: ; ACCUM = ������ ��� ������ �� �����/���� ��� �������� � CGRAM
 lcd_data
 rjmp LCD_send_data4b

LCD_goto_line1: ; ������ - � ������ ������ ������
 LDI ACCUM, 0x80	; ����� DDRAM = 0x00
 rjmp	LCD_send_cmd

LCD_goto_line2: ; ������ - � ������ ������ ������
 LDI ACCUM, 0xC0	; ����� DDRAM = 0x40
 rjmp	LCD_send_cmd

LCD_goto_CGRAM: ; ACCUM - ����� ������� � CGRAM ��� �������� (0..8)
; �� �������� ������� ��������� 8 ����(������ - ������) - ������� 5 ���(������� - ������) ��������� ��������� ������� ������-���� �������� 5x8
; ��������� ������ - ����� ������� � ������ ���� ������, ����� ������ �� ����� �����.
; ����� ����� ���������� 8 ���������������� ��������, ������� ������������� ����� �������� �������� ������� 0..8(9..15 - ������)
 LSL	ACCUM
 LSL	ACCUM
 LSL	ACCUM
 ANDI	ACCUM, 0x3F
 ORI	ACCUM, 0x40 ; ������� SET CGRAM
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
 out lcd_data_port, ACCUM  ; ������� - ������������ � 4-������ �����.
 lcd_cmd	; ����� ����� ������(��-�������� ����� ���� ������ ������ � ��������� ����...)
rjmp lcd_strobe





; #############################################################################

;    LCD_INIT

; #############################################################################






LCD_init:
 rcall LCD_wait_init ; ��������������� �������� ����� �������������� �������

 LCD_cmd8b 0x30
 LCD_WAITUS 5000 ; 5ms > 4.1ms
 
 LCD_cmd8b 0x30
 LCD_WAITUS 300 ; 300us > 100us
 
 LCD_cmd8b 0x30
 rcall LCD_wait_fast

 LCD_cmd8b 0x20 ; ������������ � 4-������ �����.
 rcall LCD_wait_fast


 ; ������� - ��������� ������������ � 4-������ �����, � ��������� ���. ���������� �.�. ���� ��� ���� ����������.
           ; 0x28 = 2 lines, 5*7 font, 4-BIT MODE!
 LDI	ACCUM, 0x28
 rcall	LCD_send_cmd

 LDI	ACCUM, 0x08 ; ��������� �������!
 rcall	LCD_send_cmd
 
 LDI	ACCUM, 0x01 ; �������� �������
 rcall	LCD_send_cmd
 rcall	LCD_wait_slow

 LDI	ACCUM, 0x06		; auto-inc cursor, display not shift. 
 rcall	LCD_send_cmd  	; cmd = Entry mode set
 rcall	LCD_wait_slow 

 LDI	ACCUM, 0x0C ; �������� �������!
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

LCD_send_data4b:   ; �������� ������/������ ���������� � 4-������ ������
; ������� ������� ����� ������
 push	ACCUM ; �������� ����������, ���� ��� ���������

 ANDI	ACCUM, 0b11110000 ; �������� ����� �������� �� ������������� ����� ������.
 IN		tempi, lcd_data_port
 CBR	tempi, 0b11110000 ; �������� ���� ����� ��� ������ ���� ������.
 OR		ACCUM, tempi
 OUT	lcd_data_port, ACCUM
 rcall	LCD_strobe
 
 pop	ACCUM
 swap	ACCUM ; �������� �������� �������������, � � ������� ����� ��������� ������� �������.

; ������� ������� �����
 ANDI	ACCUM, 0b11110000 ; �������� ����� �������� �� ������������� ����� ������.
 IN		tempi, lcd_data_port
 CBR	tempi, 0b11110000 ; �������� ���� ����� ��� ������ ���� ������.
 OR		ACCUM, tempi
 OUT	lcd_data_port, ACCUM
 rcall	LCD_strobe
 rcall	LCD_wait_fast
RET









; ========================= �������� �������� =================================
; =============================================================================


LCD_wait_fast: ; T = 37us = 37/1000000
; N(���������� ������) = T/t = T(us)*CPUfreq/1000000 = 37*8 = 296 
; n(���������� ��������) = N/N(1����)
; N(1����) = 5
.EQU lwf_oneiteration = 5
.EQU LCD_wf_iterations = (LCD_wf_delayus * CPUfreq / 1000000) / lwf_oneiteration
;-----------------------------------------
.if (LCD_wf_iterations > 255)||(LCD_wf_iterations < 3)
.error "LCD_wait_fast: - overflow iteration counter, correct algorithm!"
.endif
;-----------------------------------------
 push	tempi
 ldi	tempi, LCD_wf_iterations - 2 ; ������ 12 ������ ��������� ��������.
lwf_loop:
 nop
 nop
 dec	tempi
 brne	lwf_loop
 pop	tempi
RET

LCD_wait_X: ; ��������� �������� ������ XH:XL ��� ������ ��� LCD_wait_fast

; ���� �� XH:XL ��������
lwx_loop:
 SUBI XL, 1
 SBCI XH, 0
 BRCS lwx_exit ; ���� X = 0 - �������.
 rcall LCD_wait_fast
 rjmp lwx_loop
  ; ������ ���� ��� �������� �������, �� �������� �� � ���� - ������� ��������� �����.

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




