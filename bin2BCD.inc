#define		BCD16res0 R2
#define		BCD16res1 R3
#define		BCD16res2 R4
#define		bin16r0 ACCUM
#define		bin16r1 ACCUMH
#define		BB16_cnt1 tempi
#define		BB16_cnt2 tempih


// Input : ACCUMH:ACCUM - binary, X - pointer to 3 byte RAM for result
// Output: (X):(X+1):(X+2) - result of BCD conversion.

bin2BCD:
 push	BCD16res0
 push	BCD16res1
 push	BCD16res2

 ser	BB16_cnt2
 mov	BCD16res2,	BB16_cnt2

BB16p5_L10k:   
 inc	BCD16res2
 subi	bin16r0,	low(10000)
 sbci	bin16r1,	high(10000)
 brcc	BB16p5_L10k
 subi	bin16r0,	low(-10000)
 sbci	bin16r1,	high(-10000)
 ldi	BB16_cnt1,	(256-16)

BB16p5_L1k:
 subi	BB16_cnt1,	(-16)
 subi	bin16r0,	low(1000)
 sbci	bin16r1,	high(1000)
 brcc	BB16p5_L1k
 subi	bin16r0,	low(-1000)
 sbci	bin16r1,	high(-1000)
 mov	BCD16res1,	BB16_cnt2

BB16p5_L100:
 inc	BCD16res1
 subi	bin16r0,	low(100)
 sbci	bin16r1,	high(100)
 brcc	BB16p5_L100
 subi	bin16r0,	low(-100)
 or		BCD16res1,	BB16_cnt1
 ldi	BB16_cnt1,	(256-16)

BB16p5_L10:
 subi	BB16_cnt1,	-16
 subi	bin16r0,	 10
 brcc	BB16p5_L10
 subi	bin16r0,	-10
 mov	BCD16res0,	BB16_cnt1
 or		BCD16res0,	bin16r0

// выгрузка в RAM
 ST	X+, BCD16res0
 ST	X+, BCD16res1
 ST	X+, BCD16res2

 pop	BCD16res2
 pop	BCD16res1
 pop	BCD16res0

 ret 
