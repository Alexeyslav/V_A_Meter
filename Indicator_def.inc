; В основной программе необходимо ввести определения(#define):
; lcd_data_port - имя порта для шины данных индикатора (будут заняты биты 4..7)
; lcd_enable - номер бита порта для сигнала "данные на шине" индикатора
; lcd_rs - номер бита порта для сигнала "команда/данные" индикатора

#define lcd_chip_sel	SBI lcd_data_port, lcd_enable
#define lcd_chip_desel	CBI lcd_data_port, lcd_enable
#define lcd_cmd			CBI lcd_data_port, lcd_rs
#define lcd_data		SBI lcd_data_port, lcd_rs


.EQU LCD_data_mask = 0b11110000
.EQU LCD_control_mask = lcd_enable|lcd_rs
.EQU LCD_1st = 0x00
.EQU LCD_2st = 0x40

.EQU LCD_cmd_clr	= 0b00000001 // 1.52ms
.EQU LCD_cmd_home	= 0b00000010 // 1.52ms
.EQU LCD_cmd_displayon	= 0b00001100 // 37us, without cursor
.EQU LCD_cmd_displayoff	= 0b00001000
.EQU LCD_cmd_func4b		= 0b00101000 // 37us, 2-line display

