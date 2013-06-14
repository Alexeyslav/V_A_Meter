#define	 lcd_data_port PORTB
#define  lcd_enable PB0 
#define  lcd_rs PB1
 
 
#define lcd_chip_sel	SBI PORTB, lcd_enable
#define lcd_chip_desel	CBI PORTB, lcd_enable
#define lcd_cmd			CBI PORTB, lcd_rs
#define lcd_data		SBI PORTB, lcd_rs


.EQU LCD_data_mask = 0b11110000
.EQU LCD_control_mask = lcd_enable|lcd_rs
.EQU LCD_1st = 0x00
.EQU LCD_2st = 0x40

.EQU LCD_cmd_clr	= 0b00000001 // 1.52ms
.EQU LCD_cmd_home	= 0b00000010 // 1.52ms
.EQU LCD_cmd_displayon	= 0b00001100 // 37us, without cursor
.EQU LCD_cmd_displayoff	= 0b00001000
.EQU LCD_cmd_func4b		= 0b00101000 // 37us, 2-line display
 
; PB0 - E
; PB1 - RS
; PB2 - BEEP
; PB3 - emergency_stop
; PB4 - D0
; PB5 - D1
; PB6 - D2
; PB7 - D3
