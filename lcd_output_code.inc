
.macro number_output // Input: ACCUM = 0..9 other number is malfunction
  ANDI	ACCUM, 0x0F  // mask unused part
  SUBI	ACCUM, -48   // convert to ASCII char number CHAR = INT + 48
  rcall	LCD_send_char
.endmacro

.macro char_output
  LDI	ACCUM, @0
  rcall	LCD_send_char
.endmacro

// --------------------------------------------------------------------
LCD_output_volts: //ACCUMH:ACCUM - ���������� � �������� �����

 LDI	XL, low(Volts_BCD)
 LDI	XH, high(Volts_BCD)

 rcall bin2bcd

 rcall LCD_goto_line1
// �� �������� ������� � �������� ����� Bin2BCD X ��������� �� ������� ������ �����

// ������ ������
 LD		ACCUM, -X
 number_output

// ������ ������
 LD		ACCUM, -X
 push	ACCUM
 swap	ACCUM // ������� ���� ������� ������� ������!
 number_output
// ����������� ������� ����� 
 char_output '.'
 
// ������ ������� ������
 pop	ACCUM
 number_output 
// ������ ������� ������
 LD		ACCUM, -X
 swap	ACCUM // ������� ������� ������!
 number_output

 char_output ' '
 char_output 'V'

// � ���������� �� ��������� ��������: "12.34 V"

RET













// -------------------------------------------------------------
LCD_output_amps: //ACCUMH:ACCUM - ��� � �������� �����

LDI	XL, low(Amps_BCD)
LDI	XH, high(Amps_BCD)

rcall bin2bcd

rcall LCD_goto_line2

// �� �������� ������� � �������� ����� Bin2BCD X ��������� �� ������� ������ �����

// ������� ���� ����������
 LD		ACCUM, -X

// ������ ������
 LD		ACCUM, -X
 push	ACCUM
 swap	ACCUM // ������� ���� ������� ������� ������!
 number_output

// ����������� ������� ����� 
 char_output '.' 

// ������ ������� ������
 pop	ACCUM
 number_output 

// ������ ������� ������
 LD		ACCUM, -X
 push	ACCUM
 swap	ACCUM // ������� ������� ������� �������� �����
 number_output
// ������ ������� ������ 
 POP	ACCUM
 number_output

 char_output ' '
 char_output 'A'

// � ���������� �� ��������� ��������: "1.024 A"

RET


LCD_output_acfail:
 rcall LCD_goto_line2
 char_output 'A'
 char_output 'C'
 char_output ' '
 char_output 'F'
 char_output 'a'
 char_output 'i'
 char_output 'l'
RET
