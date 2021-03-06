// ������������ ������ � ���.

.macro ADC_start 
// SBI ADCSRA, ADSC // START conversion - writing a logical one to the ADSC bit in ADCSRA
 LDI	ACCUM, 0b11000110 // ����� �� ��� ��� � INIT, + 6-� ��� =1
 STS	ADCSRA, ACCUM
.endmacro

ADC_init:
  set_io	ADMUX,	0b00000000 // ������� �������� �������� ����������, ������ ������������ ����������.
  set_io	ADCSRA,	0b10000110 // �������� ���, ���������... =64, ��� �������� ������� 8���, ������� ��� = 125���
  set_io	DIDR0,	0b00000011 // ���������� �������� ������ ����� �� ������ ������ ���.
ret

ADC_measure: // ACCUM = � ������

 ANDI	ACCUM,	0b00000111 // ����� ������ ������ 0..7
 STS	ADMUX,	ACCUM
 ADC_start

adcm_wait:
 LDS	ACCUM,	ADCSRA // The ADSC bit will be read as one during a conversion
 SBRC	ACCUM, ADSC
 rjmp	adcm_wait

 LDS	ACCUM,	ADCL
 LDS	ACCUMH,	ADCH


RET

Volt_measure:
 LDI	ACCUM,	Volt_input
 rcall	ADC_measure

; lsl	ACCUM     // 4-� ������� ����� �����, = ��������� �� 16
; rol	ACCUMH
; lsl	ACCUM
; rol	ACCUMH
; lsl	ACCUM
; rol	ACCUMH
; lsl	ACCUM
; rol	ACCUMH
RET

Amps_measure:
 LDI ACCUM, Amps_input
 rcall ADC_measure
RET


