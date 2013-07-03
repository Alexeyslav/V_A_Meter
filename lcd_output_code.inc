
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
LCD_output_volts: //ACCUMH:ACCUM - напряжение в двоичной форме

 LDI	XL, low(Volts_BCD)
 LDI	XH, high(Volts_BCD)

 rcall bin2bcd

 rcall LCD_goto_line1
// от младшего разряда к старшему после Bin2BCD X указывает на старший разряд числа

// первый разряд
 LD		ACCUM, -X
 number_output

// второй разряд
 LD		ACCUM, -X
 push	ACCUM
 swap	ACCUM // Сначала надо вывести старший разряд!
 number_output
// разделитель дробной части 
 char_output '.'
 
// первый дробный разряд
 pop	ACCUM
 number_output 
// второй дробный разряд
 LD		ACCUM, -X
 swap	ACCUM // вывести старший разряд!
 number_output

 char_output ' '
 char_output 'V'

// В результате на индикатор выведено: "12.34 V"

RET













// -------------------------------------------------------------
LCD_output_amps: //ACCUMH:ACCUM - ток в двоичной форме

LDI	XL, low(Amps_BCD)
LDI	XH, high(Amps_BCD)

rcall bin2bcd

rcall LCD_goto_line2

// от младшего разряда к старшему после Bin2BCD X указывает на старший разряд числа

// Старший байт пропускаем
 LD		ACCUM, -X

// первый разряд
 LD		ACCUM, -X
 push	ACCUM
 swap	ACCUM // Сначала надо вывести старший разряд!
 number_output

// разделитель дробной части 
 char_output '.' 

// первый дробный разряд
 pop	ACCUM
 number_output 

// второй дробный разряд
 LD		ACCUM, -X
 push	ACCUM
 swap	ACCUM // вывести сначала старшую половину байта
 number_output
// третий дробный разряд 
 POP	ACCUM
 number_output

 char_output ' '
 char_output 'A'

// В результате на индикатор выведено: "1.024 A"

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
