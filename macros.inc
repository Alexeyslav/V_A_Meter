.macro set_bit
  SET
  BLD   @0,@1
.endmacro

.macro clear_bit
  CLT
  BLD   @0,@1
.endmacro

.macro test_bit
  BST   @0,@1
.endmacro

.macro go_if_set
 BST    @0,@1
 BRTS   @2
.endmacro

.macro go_if_clear
 BST    @0,@1
 BRTC   @2
.endmacro

.macro set_io  ; ������������ ������� ACCUM ��� �������� ��������� � ����
  LDI   ACCUM,  @1
  .If @0<=0x3F
  OUT   @0, ACCUM
  .else
  STS	@0,	ACCUM
  .endif
.endmacro

.macro set_reg
  LDI   ACCUM,  @1
  MOV   @0,     ACCUM
.endmacro

; =============== ������������� ������� ===================

.macro summ_to_ram ; �������� @0 - ����� ������ ���������� � RAM, @1, @2 - �������� H � L

 LDS	tempi, @0
 ADD	tempi, @2
 STS	@0, tempi
 
 LDS	tempi, @0+1
 ADC	tempi, @1
 STS	@0+1, tempi

.endmacro

.macro clr_to_ram ; �������� ������� � RAM, @0 - ����� ������ ���������� � RAM

 clr	tempi
 STS	@0, tempi
 STS	@0+1, tempi

.endmacro
