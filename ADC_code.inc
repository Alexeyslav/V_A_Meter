// Подпрограммы работы с АЦП.

.macro ADC_start 
// SBI ADCSRA, ADSC // START conversion - writing a logical one to the ADSC bit in ADCSRA
 LDI	ACCUM, 0b11000110 // Такой же код как в INIT, + 6-й бит =1
 STS	ADCSRA, ACCUM
.endmacro

ADC_init:
  set_io	ADMUX,	0b00000000 // Внешний источник опорного напряжения, правое выравнивание результата.
  set_io	ADCSRA,	0b10000110 // Включаем АЦП, прескалер... =64, при тактовой частоте 8Мгц, частота АЦП = 125кГц
//  set_io	DIDR0,	0b00000011 // отключение цифровых входов чтобы не мешали работе АЦП.
ret

ADC_measure: // ACCUM = № канала

 ANDI	ACCUM,	0b00000111 // номер канала только 0..7
 STS	ADMUX,	ACCUM
 ADC_start

adcm_wait:
 LDS	ACCUM,	ADCSRA // The ADSC bit will be read as one during a conversion
 SBRC ACCUM, ADSC
 rjmp adcm_wait

 

 LDS	ACCUM,	ADCL
 LDS	ACCUMH,	ADCH


RET

Volt_measure:
 LDI	ACCUM,	Volt_input
 rcall	ADC_measure

 lsl	ACCUM     // 4-х кратный сдвиг влево, = умножение на 16
 rol	ACCUMH
 lsl	ACCUM
 rol	ACCUMH
 lsl	ACCUM
 rol	ACCUMH
 lsl	ACCUM
 rol	ACCUMH
RET

Amps_measure:
 LDI ACCUM, Amps_input
 rcall ADC_measure
RET


