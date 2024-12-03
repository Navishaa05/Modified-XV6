
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	f0e78793          	addi	a5,a5,-242 # 80005f70 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd587f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3d4080e7          	jalr	980(ra) # 800024fe <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	180080e7          	jalr	384(ra) # 80002348 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ebe080e7          	jalr	-322(ra) # 80002094 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	296080e7          	jalr	662(ra) # 800024a8 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	262080e7          	jalr	610(ra) # 80002554 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cb2080e7          	jalr	-846(ra) # 800020f8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00028797          	auipc	a5,0x28
    8000047c:	97078793          	addi	a5,a5,-1680 # 80027de8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	864080e7          	jalr	-1948(ra) # 800020f8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	776080e7          	jalr	1910(ra) # 80002094 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00028797          	auipc	a5,0x28
    80000a00:	58478793          	addi	a5,a5,1412 # 80028f80 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00028517          	auipc	a0,0x28
    80000ad2:	4b250513          	addi	a0,a0,1202 # 80028f80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd6081>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	982080e7          	jalr	-1662(ra) # 80002840 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	0ea080e7          	jalr	234(ra) # 80005fb0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	014080e7          	jalr	20(ra) # 80001ee2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8e2080e7          	jalr	-1822(ra) # 80002818 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	902080e7          	jalr	-1790(ra) # 80002840 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	054080e7          	jalr	84(ra) # 80005f9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	062080e7          	jalr	98(ra) # 80005fb0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1f4080e7          	jalr	500(ra) # 8000314a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	894080e7          	jalr	-1900(ra) # 800037f2 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	83a080e7          	jalr	-1990(ra) # 800047a0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	14a080e7          	jalr	330(ra) # 800060b8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d4e080e7          	jalr	-690(ra) # 80001cc4 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd6077>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd6080>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	0001ca17          	auipc	s4,0x1c
    8000186a:	33aa0a13          	addi	s4,s4,826 # 8001dba0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	33048493          	addi	s1,s1,816
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	0001c997          	auipc	s3,0x1c
    80001936:	26e98993          	addi	s3,s3,622 # 8001dba0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0fc                	sd	a5,192(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	33048493          	addi	s1,s1,816
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e52080e7          	jalr	-430(ra) # 80002858 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	d52080e7          	jalr	-686(ra) # 80003772 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	0d893683          	ld	a3,216(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d68                	ld	a0,216(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0c04bc23          	sd	zero,216(s1)
  if (p->pagetable)
    80001b7a:	68e8                	ld	a0,208(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ec                	ld	a1,200(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0c04b823          	sd	zero,208(s1)
  p->sz = 0;
    80001b8c:	0c04b423          	sd	zero,200(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	1c048c23          	sb	zero,472(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
  for (int i = 0; i <= 26; i++)
    80001bac:	04048793          	addi	a5,s1,64
    80001bb0:	0ac48713          	addi	a4,s1,172
    p->syscall_count[i] = 0;
    80001bb4:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i <= 26; i++)
    80001bb8:	0791                	addi	a5,a5,4
    80001bba:	fee79de3          	bne	a5,a4,80001bb4 <freeproc+0x56>
}
    80001bbe:	60e2                	ld	ra,24(sp)
    80001bc0:	6442                	ld	s0,16(sp)
    80001bc2:	64a2                	ld	s1,8(sp)
    80001bc4:	6105                	addi	sp,sp,32
    80001bc6:	8082                	ret

0000000080001bc8 <allocproc>:
{
    80001bc8:	7179                	addi	sp,sp,-48
    80001bca:	f406                	sd	ra,40(sp)
    80001bcc:	f022                	sd	s0,32(sp)
    80001bce:	ec26                	sd	s1,24(sp)
    80001bd0:	e84a                	sd	s2,16(sp)
    80001bd2:	e44e                	sd	s3,8(sp)
    80001bd4:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd6:	0000f497          	auipc	s1,0xf
    80001bda:	3ca48493          	addi	s1,s1,970 # 80010fa0 <proc>
    80001bde:	0001c997          	auipc	s3,0x1c
    80001be2:	fc298993          	addi	s3,s3,-62 # 8001dba0 <tickslock>
    acquire(&p->lock);
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	fee080e7          	jalr	-18(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bf0:	4c9c                	lw	a5,24(s1)
    80001bf2:	cf81                	beqz	a5,80001c0a <allocproc+0x42>
      release(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	094080e7          	jalr	148(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bfe:	33048493          	addi	s1,s1,816
    80001c02:	ff3492e3          	bne	s1,s3,80001be6 <allocproc+0x1e>
  return 0;
    80001c06:	4481                	li	s1,0
    80001c08:	a8b5                	j	80001c84 <allocproc+0xbc>
  p->pid = allocpid();
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e20080e7          	jalr	-480(ra) # 80001a2a <allocpid>
    80001c12:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c14:	4785                	li	a5,1
    80001c16:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	ece080e7          	jalr	-306(ra) # 80000ae6 <kalloc>
    80001c20:	89aa                	mv	s3,a0
    80001c22:	ece8                	sd	a0,216(s1)
    80001c24:	c925                	beqz	a0,80001c94 <allocproc+0xcc>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e48080e7          	jalr	-440(ra) # 80001a70 <proc_pagetable>
    80001c30:	89aa                	mv	s3,a0
    80001c32:	e8e8                	sd	a0,208(s1)
  if (p->pagetable == 0)
    80001c34:	cd25                	beqz	a0,80001cac <allocproc+0xe4>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	0e048513          	addi	a0,s1,224
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	092080e7          	jalr	146(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	d9c78793          	addi	a5,a5,-612 # 800019e4 <forkret>
    80001c50:	f0fc                	sd	a5,224(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60fc                	ld	a5,192(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4fc                	sd	a5,232(s1)
  p->rtime = 0;
    80001c5a:	1e04a423          	sw	zero,488(s1)
  p->etime = 0;
    80001c5e:	1e04a823          	sw	zero,496(s1)
  p->ctime = ticks;
    80001c62:	00007797          	auipc	a5,0x7
    80001c66:	c9e7a783          	lw	a5,-866(a5) # 80008900 <ticks>
    80001c6a:	1ef4a623          	sw	a5,492(s1)
  p->ticks = 0;
    80001c6e:	1e04aa23          	sw	zero,500(s1)
  for (int i = 0; i <= 26; i++)
    80001c72:	04048793          	addi	a5,s1,64
    80001c76:	0ac48713          	addi	a4,s1,172
    p->syscall_count[i] = 0;
    80001c7a:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i <= 26; i++)
    80001c7e:	0791                	addi	a5,a5,4
    80001c80:	fee79de3          	bne	a5,a4,80001c7a <allocproc+0xb2>
}
    80001c84:	8526                	mv	a0,s1
    80001c86:	70a2                	ld	ra,40(sp)
    80001c88:	7402                	ld	s0,32(sp)
    80001c8a:	64e2                	ld	s1,24(sp)
    80001c8c:	6942                	ld	s2,16(sp)
    80001c8e:	69a2                	ld	s3,8(sp)
    80001c90:	6145                	addi	sp,sp,48
    80001c92:	8082                	ret
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	ec8080e7          	jalr	-312(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	fea080e7          	jalr	-22(ra) # 80000c8a <release>
    return 0;
    80001ca8:	84ce                	mv	s1,s3
    80001caa:	bfe9                	j	80001c84 <allocproc+0xbc>
    freeproc(p);
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	eb0080e7          	jalr	-336(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fd2080e7          	jalr	-46(ra) # 80000c8a <release>
    return 0;
    80001cc0:	84ce                	mv	s1,s3
    80001cc2:	b7c9                	j	80001c84 <allocproc+0xbc>

0000000080001cc4 <userinit>:
{
    80001cc4:	1101                	addi	sp,sp,-32
    80001cc6:	ec06                	sd	ra,24(sp)
    80001cc8:	e822                	sd	s0,16(sp)
    80001cca:	e426                	sd	s1,8(sp)
    80001ccc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	efa080e7          	jalr	-262(ra) # 80001bc8 <allocproc>
    80001cd6:	84aa                	mv	s1,a0
  initproc = p;
    80001cd8:	00007797          	auipc	a5,0x7
    80001cdc:	c2a7b023          	sd	a0,-992(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ce0:	03400613          	li	a2,52
    80001ce4:	00007597          	auipc	a1,0x7
    80001ce8:	b8c58593          	addi	a1,a1,-1140 # 80008870 <initcode>
    80001cec:	6968                	ld	a0,208(a0)
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	668080e7          	jalr	1640(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cf6:	6785                	lui	a5,0x1
    80001cf8:	e4fc                	sd	a5,200(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cfa:	6cf8                	ld	a4,216(s1)
    80001cfc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d00:	6cf8                	ld	a4,216(s1)
    80001d02:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d04:	4641                	li	a2,16
    80001d06:	00006597          	auipc	a1,0x6
    80001d0a:	4fa58593          	addi	a1,a1,1274 # 80008200 <digits+0x1c0>
    80001d0e:	1d848513          	addi	a0,s1,472
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	10a080e7          	jalr	266(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d1a:	00006517          	auipc	a0,0x6
    80001d1e:	4f650513          	addi	a0,a0,1270 # 80008210 <digits+0x1d0>
    80001d22:	00002097          	auipc	ra,0x2
    80001d26:	47a080e7          	jalr	1146(ra) # 8000419c <namei>
    80001d2a:	1ca4b823          	sd	a0,464(s1)
  p->state = RUNNABLE;
    80001d2e:	478d                	li	a5,3
    80001d30:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	f56080e7          	jalr	-170(ra) # 80000c8a <release>
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret

0000000080001d46 <growproc>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	e04a                	sd	s2,0(sp)
    80001d50:	1000                	addi	s0,sp,32
    80001d52:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	c58080e7          	jalr	-936(ra) # 800019ac <myproc>
    80001d5c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d5e:	656c                	ld	a1,200(a0)
  if (n > 0)
    80001d60:	01204c63          	bgtz	s2,80001d78 <growproc+0x32>
  else if (n < 0)
    80001d64:	02094663          	bltz	s2,80001d90 <growproc+0x4a>
  p->sz = sz;
    80001d68:	e4ec                	sd	a1,200(s1)
  return 0;
    80001d6a:	4501                	li	a0,0
}
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d78:	4691                	li	a3,4
    80001d7a:	00b90633          	add	a2,s2,a1
    80001d7e:	6968                	ld	a0,208(a0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	690080e7          	jalr	1680(ra) # 80001410 <uvmalloc>
    80001d88:	85aa                	mv	a1,a0
    80001d8a:	fd79                	bnez	a0,80001d68 <growproc+0x22>
      return -1;
    80001d8c:	557d                	li	a0,-1
    80001d8e:	bff9                	j	80001d6c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d90:	00b90633          	add	a2,s2,a1
    80001d94:	6968                	ld	a0,208(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	632080e7          	jalr	1586(ra) # 800013c8 <uvmdealloc>
    80001d9e:	85aa                	mv	a1,a0
    80001da0:	b7e1                	j	80001d68 <growproc+0x22>

0000000080001da2 <fork>:
{
    80001da2:	7139                	addi	sp,sp,-64
    80001da4:	fc06                	sd	ra,56(sp)
    80001da6:	f822                	sd	s0,48(sp)
    80001da8:	f426                	sd	s1,40(sp)
    80001daa:	f04a                	sd	s2,32(sp)
    80001dac:	ec4e                	sd	s3,24(sp)
    80001dae:	e852                	sd	s4,16(sp)
    80001db0:	e456                	sd	s5,8(sp)
    80001db2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	bf8080e7          	jalr	-1032(ra) # 800019ac <myproc>
    80001dbc:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	e0a080e7          	jalr	-502(ra) # 80001bc8 <allocproc>
    80001dc6:	10050c63          	beqz	a0,80001ede <fork+0x13c>
    80001dca:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dcc:	0c8ab603          	ld	a2,200(s5)
    80001dd0:	696c                	ld	a1,208(a0)
    80001dd2:	0d0ab503          	ld	a0,208(s5)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	792080e7          	jalr	1938(ra) # 80001568 <uvmcopy>
    80001dde:	04054863          	bltz	a0,80001e2e <fork+0x8c>
  np->sz = p->sz;
    80001de2:	0c8ab783          	ld	a5,200(s5)
    80001de6:	0cfa3423          	sd	a5,200(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	0d8ab683          	ld	a3,216(s5)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	0d8a3703          	ld	a4,216(s4)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e18:	0d8a3783          	ld	a5,216(s4)
    80001e1c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e20:	150a8493          	addi	s1,s5,336
    80001e24:	150a0913          	addi	s2,s4,336
    80001e28:	1d0a8993          	addi	s3,s5,464
    80001e2c:	a00d                	j	80001e4e <fork+0xac>
    freeproc(np);
    80001e2e:	8552                	mv	a0,s4
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d2e080e7          	jalr	-722(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e38:	8552                	mv	a0,s4
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e50080e7          	jalr	-432(ra) # 80000c8a <release>
    return -1;
    80001e42:	597d                	li	s2,-1
    80001e44:	a059                	j	80001eca <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	0921                	addi	s2,s2,8
    80001e4a:	01348b63          	beq	s1,s3,80001e60 <fork+0xbe>
    if (p->ofile[i])
    80001e4e:	6088                	ld	a0,0(s1)
    80001e50:	d97d                	beqz	a0,80001e46 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	9e0080e7          	jalr	-1568(ra) # 80004832 <filedup>
    80001e5a:	00a93023          	sd	a0,0(s2)
    80001e5e:	b7e5                	j	80001e46 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e60:	1d0ab503          	ld	a0,464(s5)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	b4e080e7          	jalr	-1202(ra) # 800039b2 <idup>
    80001e6c:	1caa3823          	sd	a0,464(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	1d8a8593          	addi	a1,s5,472
    80001e76:	1d8a0513          	addi	a0,s4,472
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fa2080e7          	jalr	-94(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e82:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e90:	0000f497          	auipc	s1,0xf
    80001e94:	cf848493          	addi	s1,s1,-776 # 80010b88 <wait_lock>
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ea2:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	de2080e7          	jalr	-542(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d24080e7          	jalr	-732(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eba:	478d                	li	a5,3
    80001ebc:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec0:	8552                	mv	a0,s4
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc8080e7          	jalr	-568(ra) # 80000c8a <release>
}
    80001eca:	854a                	mv	a0,s2
    80001ecc:	70e2                	ld	ra,56(sp)
    80001ece:	7442                	ld	s0,48(sp)
    80001ed0:	74a2                	ld	s1,40(sp)
    80001ed2:	7902                	ld	s2,32(sp)
    80001ed4:	69e2                	ld	s3,24(sp)
    80001ed6:	6a42                	ld	s4,16(sp)
    80001ed8:	6aa2                	ld	s5,8(sp)
    80001eda:	6121                	addi	sp,sp,64
    80001edc:	8082                	ret
    return -1;
    80001ede:	597d                	li	s2,-1
    80001ee0:	b7ed                	j	80001eca <fork+0x128>

0000000080001ee2 <scheduler>:
{
    80001ee2:	7139                	addi	sp,sp,-64
    80001ee4:	fc06                	sd	ra,56(sp)
    80001ee6:	f822                	sd	s0,48(sp)
    80001ee8:	f426                	sd	s1,40(sp)
    80001eea:	f04a                	sd	s2,32(sp)
    80001eec:	ec4e                	sd	s3,24(sp)
    80001eee:	e852                	sd	s4,16(sp)
    80001ef0:	e456                	sd	s5,8(sp)
    80001ef2:	e05a                	sd	s6,0(sp)
    80001ef4:	0080                	addi	s0,sp,64
    80001ef6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efa:	00779a93          	slli	s5,a5,0x7
    80001efe:	0000f717          	auipc	a4,0xf
    80001f02:	c7270713          	addi	a4,a4,-910 # 80010b70 <pid_lock>
    80001f06:	9756                	add	a4,a4,s5
    80001f08:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f0c:	0000f717          	auipc	a4,0xf
    80001f10:	c9c70713          	addi	a4,a4,-868 # 80010ba8 <cpus+0x8>
    80001f14:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f16:	498d                	li	s3,3
        p->state = RUNNING;
    80001f18:	4b11                	li	s6,4
        c->proc = p;
    80001f1a:	079e                	slli	a5,a5,0x7
    80001f1c:	0000fa17          	auipc	s4,0xf
    80001f20:	c54a0a13          	addi	s4,s4,-940 # 80010b70 <pid_lock>
    80001f24:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f26:	0001c917          	auipc	s2,0x1c
    80001f2a:	c7a90913          	addi	s2,s2,-902 # 8001dba0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f32:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f36:	10079073          	csrw	sstatus,a5
    80001f3a:	0000f497          	auipc	s1,0xf
    80001f3e:	06648493          	addi	s1,s1,102 # 80010fa0 <proc>
    80001f42:	a811                	j	80001f56 <scheduler+0x74>
      release(&p->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d44080e7          	jalr	-700(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f4e:	33048493          	addi	s1,s1,816
    80001f52:	fd248ee3          	beq	s1,s2,80001f2e <scheduler+0x4c>
      acquire(&p->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	c7e080e7          	jalr	-898(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f60:	4c9c                	lw	a5,24(s1)
    80001f62:	ff3791e3          	bne	a5,s3,80001f44 <scheduler+0x62>
        p->state = RUNNING;
    80001f66:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f6a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f6e:	0e048593          	addi	a1,s1,224
    80001f72:	8556                	mv	a0,s5
    80001f74:	00001097          	auipc	ra,0x1
    80001f78:	83a080e7          	jalr	-1990(ra) # 800027ae <swtch>
        c->proc = 0;
    80001f7c:	020a3823          	sd	zero,48(s4)
    80001f80:	b7d1                	j	80001f44 <scheduler+0x62>

0000000080001f82 <sched>:
{
    80001f82:	7179                	addi	sp,sp,-48
    80001f84:	f406                	sd	ra,40(sp)
    80001f86:	f022                	sd	s0,32(sp)
    80001f88:	ec26                	sd	s1,24(sp)
    80001f8a:	e84a                	sd	s2,16(sp)
    80001f8c:	e44e                	sd	s3,8(sp)
    80001f8e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	a1c080e7          	jalr	-1508(ra) # 800019ac <myproc>
    80001f98:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	bc2080e7          	jalr	-1086(ra) # 80000b5c <holding>
    80001fa2:	c93d                	beqz	a0,80002018 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000f717          	auipc	a4,0xf
    80001fae:	bc670713          	addi	a4,a4,-1082 # 80010b70 <pid_lock>
    80001fb2:	97ba                	add	a5,a5,a4
    80001fb4:	0a87a703          	lw	a4,168(a5)
    80001fb8:	4785                	li	a5,1
    80001fba:	06f71763          	bne	a4,a5,80002028 <sched+0xa6>
  if (p->state == RUNNING)
    80001fbe:	4c98                	lw	a4,24(s1)
    80001fc0:	4791                	li	a5,4
    80001fc2:	06f70b63          	beq	a4,a5,80002038 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fca:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fcc:	efb5                	bnez	a5,80002048 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fce:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fd0:	0000f917          	auipc	s2,0xf
    80001fd4:	ba090913          	addi	s2,s2,-1120 # 80010b70 <pid_lock>
    80001fd8:	2781                	sext.w	a5,a5
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	97ca                	add	a5,a5,s2
    80001fde:	0ac7a983          	lw	s3,172(a5)
    80001fe2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	0000f597          	auipc	a1,0xf
    80001fec:	bc058593          	addi	a1,a1,-1088 # 80010ba8 <cpus+0x8>
    80001ff0:	95be                	add	a1,a1,a5
    80001ff2:	0e048513          	addi	a0,s1,224
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	7b8080e7          	jalr	1976(ra) # 800027ae <swtch>
    80001ffe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	993e                	add	s2,s2,a5
    80002006:	0b392623          	sw	s3,172(s2)
}
    8000200a:	70a2                	ld	ra,40(sp)
    8000200c:	7402                	ld	s0,32(sp)
    8000200e:	64e2                	ld	s1,24(sp)
    80002010:	6942                	ld	s2,16(sp)
    80002012:	69a2                	ld	s3,8(sp)
    80002014:	6145                	addi	sp,sp,48
    80002016:	8082                	ret
    panic("sched p->lock");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	20050513          	addi	a0,a0,512 # 80008218 <digits+0x1d8>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	520080e7          	jalr	1312(ra) # 80000540 <panic>
    panic("sched locks");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	20050513          	addi	a0,a0,512 # 80008228 <digits+0x1e8>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    panic("sched running");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	20050513          	addi	a0,a0,512 # 80008238 <digits+0x1f8>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	500080e7          	jalr	1280(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	20050513          	addi	a0,a0,512 # 80008248 <digits+0x208>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4f0080e7          	jalr	1264(ra) # 80000540 <panic>

0000000080002058 <yield>:
{
    80002058:	1101                	addi	sp,sp,-32
    8000205a:	ec06                	sd	ra,24(sp)
    8000205c:	e822                	sd	s0,16(sp)
    8000205e:	e426                	sd	s1,8(sp)
    80002060:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002062:	00000097          	auipc	ra,0x0
    80002066:	94a080e7          	jalr	-1718(ra) # 800019ac <myproc>
    8000206a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	b6a080e7          	jalr	-1174(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002074:	478d                	li	a5,3
    80002076:	cc9c                	sw	a5,24(s1)
  sched();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	f0a080e7          	jalr	-246(ra) # 80001f82 <sched>
  release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c08080e7          	jalr	-1016(ra) # 80000c8a <release>
}
    8000208a:	60e2                	ld	ra,24(sp)
    8000208c:	6442                	ld	s0,16(sp)
    8000208e:	64a2                	ld	s1,8(sp)
    80002090:	6105                	addi	sp,sp,32
    80002092:	8082                	ret

0000000080002094 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002094:	7179                	addi	sp,sp,-48
    80002096:	f406                	sd	ra,40(sp)
    80002098:	f022                	sd	s0,32(sp)
    8000209a:	ec26                	sd	s1,24(sp)
    8000209c:	e84a                	sd	s2,16(sp)
    8000209e:	e44e                	sd	s3,8(sp)
    800020a0:	1800                	addi	s0,sp,48
    800020a2:	89aa                	mv	s3,a0
    800020a4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	906080e7          	jalr	-1786(ra) # 800019ac <myproc>
    800020ae:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	b26080e7          	jalr	-1242(ra) # 80000bd6 <acquire>
  release(lk);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bd0080e7          	jalr	-1072(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020c2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020c6:	4789                	li	a5,2
    800020c8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	eb8080e7          	jalr	-328(ra) # 80001f82 <sched>

  // Tidy up.
  p->chan = 0;
    800020d2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bb2080e7          	jalr	-1102(ra) # 80000c8a <release>
  acquire(lk);
    800020e0:	854a                	mv	a0,s2
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	af4080e7          	jalr	-1292(ra) # 80000bd6 <acquire>
}
    800020ea:	70a2                	ld	ra,40(sp)
    800020ec:	7402                	ld	s0,32(sp)
    800020ee:	64e2                	ld	s1,24(sp)
    800020f0:	6942                	ld	s2,16(sp)
    800020f2:	69a2                	ld	s3,8(sp)
    800020f4:	6145                	addi	sp,sp,48
    800020f6:	8082                	ret

00000000800020f8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020f8:	7139                	addi	sp,sp,-64
    800020fa:	fc06                	sd	ra,56(sp)
    800020fc:	f822                	sd	s0,48(sp)
    800020fe:	f426                	sd	s1,40(sp)
    80002100:	f04a                	sd	s2,32(sp)
    80002102:	ec4e                	sd	s3,24(sp)
    80002104:	e852                	sd	s4,16(sp)
    80002106:	e456                	sd	s5,8(sp)
    80002108:	0080                	addi	s0,sp,64
    8000210a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000210c:	0000f497          	auipc	s1,0xf
    80002110:	e9448493          	addi	s1,s1,-364 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002114:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002116:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002118:	0001c917          	auipc	s2,0x1c
    8000211c:	a8890913          	addi	s2,s2,-1400 # 8001dba0 <tickslock>
    80002120:	a811                	j	80002134 <wakeup+0x3c>
      }
      release(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	b66080e7          	jalr	-1178(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000212c:	33048493          	addi	s1,s1,816
    80002130:	03248663          	beq	s1,s2,8000215c <wakeup+0x64>
    if (p != myproc())
    80002134:	00000097          	auipc	ra,0x0
    80002138:	878080e7          	jalr	-1928(ra) # 800019ac <myproc>
    8000213c:	fea488e3          	beq	s1,a0,8000212c <wakeup+0x34>
      acquire(&p->lock);
    80002140:	8526                	mv	a0,s1
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	a94080e7          	jalr	-1388(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000214a:	4c9c                	lw	a5,24(s1)
    8000214c:	fd379be3          	bne	a5,s3,80002122 <wakeup+0x2a>
    80002150:	709c                	ld	a5,32(s1)
    80002152:	fd4798e3          	bne	a5,s4,80002122 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002156:	0154ac23          	sw	s5,24(s1)
    8000215a:	b7e1                	j	80002122 <wakeup+0x2a>
    }
  }
}
    8000215c:	70e2                	ld	ra,56(sp)
    8000215e:	7442                	ld	s0,48(sp)
    80002160:	74a2                	ld	s1,40(sp)
    80002162:	7902                	ld	s2,32(sp)
    80002164:	69e2                	ld	s3,24(sp)
    80002166:	6a42                	ld	s4,16(sp)
    80002168:	6aa2                	ld	s5,8(sp)
    8000216a:	6121                	addi	sp,sp,64
    8000216c:	8082                	ret

000000008000216e <reparent>:
{
    8000216e:	7179                	addi	sp,sp,-48
    80002170:	f406                	sd	ra,40(sp)
    80002172:	f022                	sd	s0,32(sp)
    80002174:	ec26                	sd	s1,24(sp)
    80002176:	e84a                	sd	s2,16(sp)
    80002178:	e44e                	sd	s3,8(sp)
    8000217a:	e052                	sd	s4,0(sp)
    8000217c:	1800                	addi	s0,sp,48
    8000217e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002180:	0000f497          	auipc	s1,0xf
    80002184:	e2048493          	addi	s1,s1,-480 # 80010fa0 <proc>
      pp->parent = initproc;
    80002188:	00006a17          	auipc	s4,0x6
    8000218c:	770a0a13          	addi	s4,s4,1904 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002190:	0001c997          	auipc	s3,0x1c
    80002194:	a1098993          	addi	s3,s3,-1520 # 8001dba0 <tickslock>
    80002198:	a029                	j	800021a2 <reparent+0x34>
    8000219a:	33048493          	addi	s1,s1,816
    8000219e:	01348d63          	beq	s1,s3,800021b8 <reparent+0x4a>
    if (pp->parent == p)
    800021a2:	7c9c                	ld	a5,56(s1)
    800021a4:	ff279be3          	bne	a5,s2,8000219a <reparent+0x2c>
      pp->parent = initproc;
    800021a8:	000a3503          	ld	a0,0(s4)
    800021ac:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	f4a080e7          	jalr	-182(ra) # 800020f8 <wakeup>
    800021b6:	b7d5                	j	8000219a <reparent+0x2c>
}
    800021b8:	70a2                	ld	ra,40(sp)
    800021ba:	7402                	ld	s0,32(sp)
    800021bc:	64e2                	ld	s1,24(sp)
    800021be:	6942                	ld	s2,16(sp)
    800021c0:	69a2                	ld	s3,8(sp)
    800021c2:	6a02                	ld	s4,0(sp)
    800021c4:	6145                	addi	sp,sp,48
    800021c6:	8082                	ret

00000000800021c8 <exit>:
{
    800021c8:	7179                	addi	sp,sp,-48
    800021ca:	f406                	sd	ra,40(sp)
    800021cc:	f022                	sd	s0,32(sp)
    800021ce:	ec26                	sd	s1,24(sp)
    800021d0:	e84a                	sd	s2,16(sp)
    800021d2:	e44e                	sd	s3,8(sp)
    800021d4:	e052                	sd	s4,0(sp)
    800021d6:	1800                	addi	s0,sp,48
    800021d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	7d2080e7          	jalr	2002(ra) # 800019ac <myproc>
    800021e2:	89aa                	mv	s3,a0
  if (p == initproc)
    800021e4:	00006797          	auipc	a5,0x6
    800021e8:	7147b783          	ld	a5,1812(a5) # 800088f8 <initproc>
    800021ec:	15050493          	addi	s1,a0,336
    800021f0:	1d050913          	addi	s2,a0,464
    800021f4:	02a79363          	bne	a5,a0,8000221a <exit+0x52>
    panic("init exiting");
    800021f8:	00006517          	auipc	a0,0x6
    800021fc:	06850513          	addi	a0,a0,104 # 80008260 <digits+0x220>
    80002200:	ffffe097          	auipc	ra,0xffffe
    80002204:	340080e7          	jalr	832(ra) # 80000540 <panic>
      fileclose(f);
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	67c080e7          	jalr	1660(ra) # 80004884 <fileclose>
      p->ofile[fd] = 0;
    80002210:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002214:	04a1                	addi	s1,s1,8
    80002216:	01248563          	beq	s1,s2,80002220 <exit+0x58>
    if (p->ofile[fd])
    8000221a:	6088                	ld	a0,0(s1)
    8000221c:	f575                	bnez	a0,80002208 <exit+0x40>
    8000221e:	bfdd                	j	80002214 <exit+0x4c>
  begin_op();
    80002220:	00002097          	auipc	ra,0x2
    80002224:	19c080e7          	jalr	412(ra) # 800043bc <begin_op>
  iput(p->cwd);
    80002228:	1d09b503          	ld	a0,464(s3)
    8000222c:	00002097          	auipc	ra,0x2
    80002230:	97e080e7          	jalr	-1666(ra) # 80003baa <iput>
  end_op();
    80002234:	00002097          	auipc	ra,0x2
    80002238:	206080e7          	jalr	518(ra) # 8000443a <end_op>
  p->cwd = 0;
    8000223c:	1c09b823          	sd	zero,464(s3)
  acquire(&wait_lock);
    80002240:	0000f497          	auipc	s1,0xf
    80002244:	94848493          	addi	s1,s1,-1720 # 80010b88 <wait_lock>
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	98c080e7          	jalr	-1652(ra) # 80000bd6 <acquire>
  reparent(p);
    80002252:	854e                	mv	a0,s3
    80002254:	00000097          	auipc	ra,0x0
    80002258:	f1a080e7          	jalr	-230(ra) # 8000216e <reparent>
  wakeup(p->parent);
    8000225c:	0389b503          	ld	a0,56(s3)
    80002260:	00000097          	auipc	ra,0x0
    80002264:	e98080e7          	jalr	-360(ra) # 800020f8 <wakeup>
  acquire(&p->lock);
    80002268:	854e                	mv	a0,s3
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002272:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002276:	4795                	li	a5,5
    80002278:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000227c:	00006797          	auipc	a5,0x6
    80002280:	6847a783          	lw	a5,1668(a5) # 80008900 <ticks>
    80002284:	1ef9a823          	sw	a5,496(s3)
  release(&wait_lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a00080e7          	jalr	-1536(ra) # 80000c8a <release>
  sched();
    80002292:	00000097          	auipc	ra,0x0
    80002296:	cf0080e7          	jalr	-784(ra) # 80001f82 <sched>
  panic("zombie exit");
    8000229a:	00006517          	auipc	a0,0x6
    8000229e:	fd650513          	addi	a0,a0,-42 # 80008270 <digits+0x230>
    800022a2:	ffffe097          	auipc	ra,0xffffe
    800022a6:	29e080e7          	jalr	670(ra) # 80000540 <panic>

00000000800022aa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022aa:	7179                	addi	sp,sp,-48
    800022ac:	f406                	sd	ra,40(sp)
    800022ae:	f022                	sd	s0,32(sp)
    800022b0:	ec26                	sd	s1,24(sp)
    800022b2:	e84a                	sd	s2,16(sp)
    800022b4:	e44e                	sd	s3,8(sp)
    800022b6:	1800                	addi	s0,sp,48
    800022b8:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022ba:	0000f497          	auipc	s1,0xf
    800022be:	ce648493          	addi	s1,s1,-794 # 80010fa0 <proc>
    800022c2:	0001c997          	auipc	s3,0x1c
    800022c6:	8de98993          	addi	s3,s3,-1826 # 8001dba0 <tickslock>
  {
    acquire(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	90a080e7          	jalr	-1782(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022d4:	589c                	lw	a5,48(s1)
    800022d6:	01278d63          	beq	a5,s2,800022f0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9ae080e7          	jalr	-1618(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022e4:	33048493          	addi	s1,s1,816
    800022e8:	ff3491e3          	bne	s1,s3,800022ca <kill+0x20>
  }
  return -1;
    800022ec:	557d                	li	a0,-1
    800022ee:	a829                	j	80002308 <kill+0x5e>
      p->killed = 1;
    800022f0:	4785                	li	a5,1
    800022f2:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022f4:	4c98                	lw	a4,24(s1)
    800022f6:	4789                	li	a5,2
    800022f8:	00f70f63          	beq	a4,a5,80002316 <kill+0x6c>
      release(&p->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	98c080e7          	jalr	-1652(ra) # 80000c8a <release>
      return 0;
    80002306:	4501                	li	a0,0
}
    80002308:	70a2                	ld	ra,40(sp)
    8000230a:	7402                	ld	s0,32(sp)
    8000230c:	64e2                	ld	s1,24(sp)
    8000230e:	6942                	ld	s2,16(sp)
    80002310:	69a2                	ld	s3,8(sp)
    80002312:	6145                	addi	sp,sp,48
    80002314:	8082                	ret
        p->state = RUNNABLE;
    80002316:	478d                	li	a5,3
    80002318:	cc9c                	sw	a5,24(s1)
    8000231a:	b7cd                	j	800022fc <kill+0x52>

000000008000231c <setkilled>:

void setkilled(struct proc *p)
{
    8000231c:	1101                	addi	sp,sp,-32
    8000231e:	ec06                	sd	ra,24(sp)
    80002320:	e822                	sd	s0,16(sp)
    80002322:	e426                	sd	s1,8(sp)
    80002324:	1000                	addi	s0,sp,32
    80002326:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8ae080e7          	jalr	-1874(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002330:	4785                	li	a5,1
    80002332:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	954080e7          	jalr	-1708(ra) # 80000c8a <release>
}
    8000233e:	60e2                	ld	ra,24(sp)
    80002340:	6442                	ld	s0,16(sp)
    80002342:	64a2                	ld	s1,8(sp)
    80002344:	6105                	addi	sp,sp,32
    80002346:	8082                	ret

0000000080002348 <killed>:

int killed(struct proc *p)
{
    80002348:	1101                	addi	sp,sp,-32
    8000234a:	ec06                	sd	ra,24(sp)
    8000234c:	e822                	sd	s0,16(sp)
    8000234e:	e426                	sd	s1,8(sp)
    80002350:	e04a                	sd	s2,0(sp)
    80002352:	1000                	addi	s0,sp,32
    80002354:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000235e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	926080e7          	jalr	-1754(ra) # 80000c8a <release>
  return k;
}
    8000236c:	854a                	mv	a0,s2
    8000236e:	60e2                	ld	ra,24(sp)
    80002370:	6442                	ld	s0,16(sp)
    80002372:	64a2                	ld	s1,8(sp)
    80002374:	6902                	ld	s2,0(sp)
    80002376:	6105                	addi	sp,sp,32
    80002378:	8082                	ret

000000008000237a <wait>:
{
    8000237a:	715d                	addi	sp,sp,-80
    8000237c:	e486                	sd	ra,72(sp)
    8000237e:	e0a2                	sd	s0,64(sp)
    80002380:	fc26                	sd	s1,56(sp)
    80002382:	f84a                	sd	s2,48(sp)
    80002384:	f44e                	sd	s3,40(sp)
    80002386:	f052                	sd	s4,32(sp)
    80002388:	ec56                	sd	s5,24(sp)
    8000238a:	e85a                	sd	s6,16(sp)
    8000238c:	e45e                	sd	s7,8(sp)
    8000238e:	e062                	sd	s8,0(sp)
    80002390:	0880                	addi	s0,sp,80
    80002392:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	618080e7          	jalr	1560(ra) # 800019ac <myproc>
    8000239c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000239e:	0000e517          	auipc	a0,0xe
    800023a2:	7ea50513          	addi	a0,a0,2026 # 80010b88 <wait_lock>
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023ae:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023b0:	4a15                	li	s4,5
        havekids = 1;
    800023b2:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b4:	0001b997          	auipc	s3,0x1b
    800023b8:	7ec98993          	addi	s3,s3,2028 # 8001dba0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023bc:	0000ec17          	auipc	s8,0xe
    800023c0:	7ccc0c13          	addi	s8,s8,1996 # 80010b88 <wait_lock>
    havekids = 0;
    800023c4:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023c6:	0000f497          	auipc	s1,0xf
    800023ca:	bda48493          	addi	s1,s1,-1062 # 80010fa0 <proc>
    800023ce:	a0bd                	j	8000243c <wait+0xc2>
          pid = pp->pid;
    800023d0:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023d4:	000b0e63          	beqz	s6,800023f0 <wait+0x76>
    800023d8:	4691                	li	a3,4
    800023da:	02c48613          	addi	a2,s1,44
    800023de:	85da                	mv	a1,s6
    800023e0:	0d093503          	ld	a0,208(s2)
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	288080e7          	jalr	648(ra) # 8000166c <copyout>
    800023ec:	02054563          	bltz	a0,80002416 <wait+0x9c>
          freeproc(pp);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	76c080e7          	jalr	1900(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
          release(&wait_lock);
    80002404:	0000e517          	auipc	a0,0xe
    80002408:	78450513          	addi	a0,a0,1924 # 80010b88 <wait_lock>
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
          return pid;
    80002414:	a0b5                	j	80002480 <wait+0x106>
            release(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	872080e7          	jalr	-1934(ra) # 80000c8a <release>
            release(&wait_lock);
    80002420:	0000e517          	auipc	a0,0xe
    80002424:	76850513          	addi	a0,a0,1896 # 80010b88 <wait_lock>
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
            return -1;
    80002430:	59fd                	li	s3,-1
    80002432:	a0b9                	j	80002480 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002434:	33048493          	addi	s1,s1,816
    80002438:	03348463          	beq	s1,s3,80002460 <wait+0xe6>
      if (pp->parent == p)
    8000243c:	7c9c                	ld	a5,56(s1)
    8000243e:	ff279be3          	bne	a5,s2,80002434 <wait+0xba>
        acquire(&pp->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	792080e7          	jalr	1938(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000244c:	4c9c                	lw	a5,24(s1)
    8000244e:	f94781e3          	beq	a5,s4,800023d0 <wait+0x56>
        release(&pp->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	836080e7          	jalr	-1994(ra) # 80000c8a <release>
        havekids = 1;
    8000245c:	8756                	mv	a4,s5
    8000245e:	bfd9                	j	80002434 <wait+0xba>
    if (!havekids || killed(p))
    80002460:	c719                	beqz	a4,8000246e <wait+0xf4>
    80002462:	854a                	mv	a0,s2
    80002464:	00000097          	auipc	ra,0x0
    80002468:	ee4080e7          	jalr	-284(ra) # 80002348 <killed>
    8000246c:	c51d                	beqz	a0,8000249a <wait+0x120>
      release(&wait_lock);
    8000246e:	0000e517          	auipc	a0,0xe
    80002472:	71a50513          	addi	a0,a0,1818 # 80010b88 <wait_lock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	814080e7          	jalr	-2028(ra) # 80000c8a <release>
      return -1;
    8000247e:	59fd                	li	s3,-1
}
    80002480:	854e                	mv	a0,s3
    80002482:	60a6                	ld	ra,72(sp)
    80002484:	6406                	ld	s0,64(sp)
    80002486:	74e2                	ld	s1,56(sp)
    80002488:	7942                	ld	s2,48(sp)
    8000248a:	79a2                	ld	s3,40(sp)
    8000248c:	7a02                	ld	s4,32(sp)
    8000248e:	6ae2                	ld	s5,24(sp)
    80002490:	6b42                	ld	s6,16(sp)
    80002492:	6ba2                	ld	s7,8(sp)
    80002494:	6c02                	ld	s8,0(sp)
    80002496:	6161                	addi	sp,sp,80
    80002498:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000249a:	85e2                	mv	a1,s8
    8000249c:	854a                	mv	a0,s2
    8000249e:	00000097          	auipc	ra,0x0
    800024a2:	bf6080e7          	jalr	-1034(ra) # 80002094 <sleep>
    havekids = 0;
    800024a6:	bf39                	j	800023c4 <wait+0x4a>

00000000800024a8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a8:	7179                	addi	sp,sp,-48
    800024aa:	f406                	sd	ra,40(sp)
    800024ac:	f022                	sd	s0,32(sp)
    800024ae:	ec26                	sd	s1,24(sp)
    800024b0:	e84a                	sd	s2,16(sp)
    800024b2:	e44e                	sd	s3,8(sp)
    800024b4:	e052                	sd	s4,0(sp)
    800024b6:	1800                	addi	s0,sp,48
    800024b8:	84aa                	mv	s1,a0
    800024ba:	892e                	mv	s2,a1
    800024bc:	89b2                	mv	s3,a2
    800024be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	4ec080e7          	jalr	1260(ra) # 800019ac <myproc>
  if (user_dst)
    800024c8:	c08d                	beqz	s1,800024ea <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024ca:	86d2                	mv	a3,s4
    800024cc:	864e                	mv	a2,s3
    800024ce:	85ca                	mv	a1,s2
    800024d0:	6968                	ld	a0,208(a0)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	19a080e7          	jalr	410(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret
    memmove((char *)dst, src, len);
    800024ea:	000a061b          	sext.w	a2,s4
    800024ee:	85ce                	mv	a1,s3
    800024f0:	854a                	mv	a0,s2
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	83c080e7          	jalr	-1988(ra) # 80000d2e <memmove>
    return 0;
    800024fa:	8526                	mv	a0,s1
    800024fc:	bff9                	j	800024da <either_copyout+0x32>

00000000800024fe <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024fe:	7179                	addi	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	e052                	sd	s4,0(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	892a                	mv	s2,a0
    80002510:	84ae                	mv	s1,a1
    80002512:	89b2                	mv	s3,a2
    80002514:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	496080e7          	jalr	1174(ra) # 800019ac <myproc>
  if (user_src)
    8000251e:	c08d                	beqz	s1,80002540 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002520:	86d2                	mv	a3,s4
    80002522:	864e                	mv	a2,s3
    80002524:	85ca                	mv	a1,s2
    80002526:	6968                	ld	a0,208(a0)
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	1d0080e7          	jalr	464(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002530:	70a2                	ld	ra,40(sp)
    80002532:	7402                	ld	s0,32(sp)
    80002534:	64e2                	ld	s1,24(sp)
    80002536:	6942                	ld	s2,16(sp)
    80002538:	69a2                	ld	s3,8(sp)
    8000253a:	6a02                	ld	s4,0(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret
    memmove(dst, (char *)src, len);
    80002540:	000a061b          	sext.w	a2,s4
    80002544:	85ce                	mv	a1,s3
    80002546:	854a                	mv	a0,s2
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	7e6080e7          	jalr	2022(ra) # 80000d2e <memmove>
    return 0;
    80002550:	8526                	mv	a0,s1
    80002552:	bff9                	j	80002530 <either_copyin+0x32>

0000000080002554 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002554:	715d                	addi	sp,sp,-80
    80002556:	e486                	sd	ra,72(sp)
    80002558:	e0a2                	sd	s0,64(sp)
    8000255a:	fc26                	sd	s1,56(sp)
    8000255c:	f84a                	sd	s2,48(sp)
    8000255e:	f44e                	sd	s3,40(sp)
    80002560:	f052                	sd	s4,32(sp)
    80002562:	ec56                	sd	s5,24(sp)
    80002564:	e85a                	sd	s6,16(sp)
    80002566:	e45e                	sd	s7,8(sp)
    80002568:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000256a:	00006517          	auipc	a0,0x6
    8000256e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	0000f497          	auipc	s1,0xf
    8000257e:	bfe48493          	addi	s1,s1,-1026 # 80011178 <proc+0x1d8>
    80002582:	0001b917          	auipc	s2,0x1b
    80002586:	7f690913          	addi	s2,s2,2038 # 8001dd78 <bcache+0x1c0>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000258c:	00006997          	auipc	s3,0x6
    80002590:	cf498993          	addi	s3,s3,-780 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002594:	00006a97          	auipc	s5,0x6
    80002598:	cf4a8a93          	addi	s5,s5,-780 # 80008288 <digits+0x248>
    printf("\n");
    8000259c:	00006a17          	auipc	s4,0x6
    800025a0:	b2ca0a13          	addi	s4,s4,-1236 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a4:	00006b97          	auipc	s7,0x6
    800025a8:	d24b8b93          	addi	s7,s7,-732 # 800082c8 <states.0>
    800025ac:	a00d                	j	800025ce <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ae:	e586a583          	lw	a1,-424(a3)
    800025b2:	8556                	mv	a0,s5
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	fd6080e7          	jalr	-42(ra) # 8000058a <printf>
    printf("\n");
    800025bc:	8552                	mv	a0,s4
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fcc080e7          	jalr	-52(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025c6:	33048493          	addi	s1,s1,816
    800025ca:	03248263          	beq	s1,s2,800025ee <procdump+0x9a>
    if (p->state == UNUSED)
    800025ce:	86a6                	mv	a3,s1
    800025d0:	e404a783          	lw	a5,-448(s1)
    800025d4:	dbed                	beqz	a5,800025c6 <procdump+0x72>
      state = "???";
    800025d6:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d8:	fcfb6be3          	bltu	s6,a5,800025ae <procdump+0x5a>
    800025dc:	02079713          	slli	a4,a5,0x20
    800025e0:	01d75793          	srli	a5,a4,0x1d
    800025e4:	97de                	add	a5,a5,s7
    800025e6:	6390                	ld	a2,0(a5)
    800025e8:	f279                	bnez	a2,800025ae <procdump+0x5a>
      state = "???";
    800025ea:	864e                	mv	a2,s3
    800025ec:	b7c9                	j	800025ae <procdump+0x5a>
  }
}
    800025ee:	60a6                	ld	ra,72(sp)
    800025f0:	6406                	ld	s0,64(sp)
    800025f2:	74e2                	ld	s1,56(sp)
    800025f4:	7942                	ld	s2,48(sp)
    800025f6:	79a2                	ld	s3,40(sp)
    800025f8:	7a02                	ld	s4,32(sp)
    800025fa:	6ae2                	ld	s5,24(sp)
    800025fc:	6b42                	ld	s6,16(sp)
    800025fe:	6ba2                	ld	s7,8(sp)
    80002600:	6161                	addi	sp,sp,80
    80002602:	8082                	ret

0000000080002604 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002604:	711d                	addi	sp,sp,-96
    80002606:	ec86                	sd	ra,88(sp)
    80002608:	e8a2                	sd	s0,80(sp)
    8000260a:	e4a6                	sd	s1,72(sp)
    8000260c:	e0ca                	sd	s2,64(sp)
    8000260e:	fc4e                	sd	s3,56(sp)
    80002610:	f852                	sd	s4,48(sp)
    80002612:	f456                	sd	s5,40(sp)
    80002614:	f05a                	sd	s6,32(sp)
    80002616:	ec5e                	sd	s7,24(sp)
    80002618:	e862                	sd	s8,16(sp)
    8000261a:	e466                	sd	s9,8(sp)
    8000261c:	e06a                	sd	s10,0(sp)
    8000261e:	1080                	addi	s0,sp,96
    80002620:	8b2a                	mv	s6,a0
    80002622:	8bae                	mv	s7,a1
    80002624:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	386080e7          	jalr	902(ra) # 800019ac <myproc>
    8000262e:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002630:	0000e517          	auipc	a0,0xe
    80002634:	55850513          	addi	a0,a0,1368 # 80010b88 <wait_lock>
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	59e080e7          	jalr	1438(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002640:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002642:	4a15                	li	s4,5
        havekids = 1;
    80002644:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002646:	0001b997          	auipc	s3,0x1b
    8000264a:	55a98993          	addi	s3,s3,1370 # 8001dba0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000264e:	0000ed17          	auipc	s10,0xe
    80002652:	53ad0d13          	addi	s10,s10,1338 # 80010b88 <wait_lock>
    havekids = 0;
    80002656:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002658:	0000f497          	auipc	s1,0xf
    8000265c:	94848493          	addi	s1,s1,-1720 # 80010fa0 <proc>
    80002660:	a059                	j	800026e6 <waitx+0xe2>
          pid = np->pid;
    80002662:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002666:	1e84a783          	lw	a5,488(s1)
    8000266a:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000266e:	1ec4a703          	lw	a4,492(s1)
    80002672:	9f3d                	addw	a4,a4,a5
    80002674:	1f04a783          	lw	a5,496(s1)
    80002678:	9f99                	subw	a5,a5,a4
    8000267a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000267e:	000b0e63          	beqz	s6,8000269a <waitx+0x96>
    80002682:	4691                	li	a3,4
    80002684:	02c48613          	addi	a2,s1,44
    80002688:	85da                	mv	a1,s6
    8000268a:	0d093503          	ld	a0,208(s2)
    8000268e:	fffff097          	auipc	ra,0xfffff
    80002692:	fde080e7          	jalr	-34(ra) # 8000166c <copyout>
    80002696:	02054563          	bltz	a0,800026c0 <waitx+0xbc>
          freeproc(np);
    8000269a:	8526                	mv	a0,s1
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	4c2080e7          	jalr	1218(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800026a4:	8526                	mv	a0,s1
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	5e4080e7          	jalr	1508(ra) # 80000c8a <release>
          release(&wait_lock);
    800026ae:	0000e517          	auipc	a0,0xe
    800026b2:	4da50513          	addi	a0,a0,1242 # 80010b88 <wait_lock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	5d4080e7          	jalr	1492(ra) # 80000c8a <release>
          return pid;
    800026be:	a09d                	j	80002724 <waitx+0x120>
            release(&np->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5c8080e7          	jalr	1480(ra) # 80000c8a <release>
            release(&wait_lock);
    800026ca:	0000e517          	auipc	a0,0xe
    800026ce:	4be50513          	addi	a0,a0,1214 # 80010b88 <wait_lock>
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5b8080e7          	jalr	1464(ra) # 80000c8a <release>
            return -1;
    800026da:	59fd                	li	s3,-1
    800026dc:	a0a1                	j	80002724 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026de:	33048493          	addi	s1,s1,816
    800026e2:	03348463          	beq	s1,s3,8000270a <waitx+0x106>
      if (np->parent == p)
    800026e6:	7c9c                	ld	a5,56(s1)
    800026e8:	ff279be3          	bne	a5,s2,800026de <waitx+0xda>
        acquire(&np->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4e8080e7          	jalr	1256(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800026f6:	4c9c                	lw	a5,24(s1)
    800026f8:	f74785e3          	beq	a5,s4,80002662 <waitx+0x5e>
        release(&np->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
        havekids = 1;
    80002706:	8756                	mv	a4,s5
    80002708:	bfd9                	j	800026de <waitx+0xda>
    if (!havekids || p->killed)
    8000270a:	c701                	beqz	a4,80002712 <waitx+0x10e>
    8000270c:	02892783          	lw	a5,40(s2)
    80002710:	cb8d                	beqz	a5,80002742 <waitx+0x13e>
      release(&wait_lock);
    80002712:	0000e517          	auipc	a0,0xe
    80002716:	47650513          	addi	a0,a0,1142 # 80010b88 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	570080e7          	jalr	1392(ra) # 80000c8a <release>
      return -1;
    80002722:	59fd                	li	s3,-1
  }
}
    80002724:	854e                	mv	a0,s3
    80002726:	60e6                	ld	ra,88(sp)
    80002728:	6446                	ld	s0,80(sp)
    8000272a:	64a6                	ld	s1,72(sp)
    8000272c:	6906                	ld	s2,64(sp)
    8000272e:	79e2                	ld	s3,56(sp)
    80002730:	7a42                	ld	s4,48(sp)
    80002732:	7aa2                	ld	s5,40(sp)
    80002734:	7b02                	ld	s6,32(sp)
    80002736:	6be2                	ld	s7,24(sp)
    80002738:	6c42                	ld	s8,16(sp)
    8000273a:	6ca2                	ld	s9,8(sp)
    8000273c:	6d02                	ld	s10,0(sp)
    8000273e:	6125                	addi	sp,sp,96
    80002740:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002742:	85ea                	mv	a1,s10
    80002744:	854a                	mv	a0,s2
    80002746:	00000097          	auipc	ra,0x0
    8000274a:	94e080e7          	jalr	-1714(ra) # 80002094 <sleep>
    havekids = 0;
    8000274e:	b721                	j	80002656 <waitx+0x52>

0000000080002750 <update_time>:

void update_time()
{
    80002750:	7179                	addi	sp,sp,-48
    80002752:	f406                	sd	ra,40(sp)
    80002754:	f022                	sd	s0,32(sp)
    80002756:	ec26                	sd	s1,24(sp)
    80002758:	e84a                	sd	s2,16(sp)
    8000275a:	e44e                	sd	s3,8(sp)
    8000275c:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000275e:	0000f497          	auipc	s1,0xf
    80002762:	84248493          	addi	s1,s1,-1982 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002766:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002768:	0001b917          	auipc	s2,0x1b
    8000276c:	43890913          	addi	s2,s2,1080 # 8001dba0 <tickslock>
    80002770:	a811                	j	80002784 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002772:	8526                	mv	a0,s1
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	516080e7          	jalr	1302(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000277c:	33048493          	addi	s1,s1,816
    80002780:	03248063          	beq	s1,s2,800027a0 <update_time+0x50>
    acquire(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	450080e7          	jalr	1104(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000278e:	4c9c                	lw	a5,24(s1)
    80002790:	ff3791e3          	bne	a5,s3,80002772 <update_time+0x22>
      p->rtime++;
    80002794:	1e84a783          	lw	a5,488(s1)
    80002798:	2785                	addiw	a5,a5,1
    8000279a:	1ef4a423          	sw	a5,488(s1)
    8000279e:	bfd1                	j	80002772 <update_time+0x22>
  }
    800027a0:	70a2                	ld	ra,40(sp)
    800027a2:	7402                	ld	s0,32(sp)
    800027a4:	64e2                	ld	s1,24(sp)
    800027a6:	6942                	ld	s2,16(sp)
    800027a8:	69a2                	ld	s3,8(sp)
    800027aa:	6145                	addi	sp,sp,48
    800027ac:	8082                	ret

00000000800027ae <swtch>:
    800027ae:	00153023          	sd	ra,0(a0)
    800027b2:	00253423          	sd	sp,8(a0)
    800027b6:	e900                	sd	s0,16(a0)
    800027b8:	ed04                	sd	s1,24(a0)
    800027ba:	03253023          	sd	s2,32(a0)
    800027be:	03353423          	sd	s3,40(a0)
    800027c2:	03453823          	sd	s4,48(a0)
    800027c6:	03553c23          	sd	s5,56(a0)
    800027ca:	05653023          	sd	s6,64(a0)
    800027ce:	05753423          	sd	s7,72(a0)
    800027d2:	05853823          	sd	s8,80(a0)
    800027d6:	05953c23          	sd	s9,88(a0)
    800027da:	07a53023          	sd	s10,96(a0)
    800027de:	07b53423          	sd	s11,104(a0)
    800027e2:	0005b083          	ld	ra,0(a1)
    800027e6:	0085b103          	ld	sp,8(a1)
    800027ea:	6980                	ld	s0,16(a1)
    800027ec:	6d84                	ld	s1,24(a1)
    800027ee:	0205b903          	ld	s2,32(a1)
    800027f2:	0285b983          	ld	s3,40(a1)
    800027f6:	0305ba03          	ld	s4,48(a1)
    800027fa:	0385ba83          	ld	s5,56(a1)
    800027fe:	0405bb03          	ld	s6,64(a1)
    80002802:	0485bb83          	ld	s7,72(a1)
    80002806:	0505bc03          	ld	s8,80(a1)
    8000280a:	0585bc83          	ld	s9,88(a1)
    8000280e:	0605bd03          	ld	s10,96(a1)
    80002812:	0685bd83          	ld	s11,104(a1)
    80002816:	8082                	ret

0000000080002818 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002818:	1141                	addi	sp,sp,-16
    8000281a:	e406                	sd	ra,8(sp)
    8000281c:	e022                	sd	s0,0(sp)
    8000281e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002820:	00006597          	auipc	a1,0x6
    80002824:	ad858593          	addi	a1,a1,-1320 # 800082f8 <states.0+0x30>
    80002828:	0001b517          	auipc	a0,0x1b
    8000282c:	37850513          	addi	a0,a0,888 # 8001dba0 <tickslock>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	316080e7          	jalr	790(ra) # 80000b46 <initlock>
}
    80002838:	60a2                	ld	ra,8(sp)
    8000283a:	6402                	ld	s0,0(sp)
    8000283c:	0141                	addi	sp,sp,16
    8000283e:	8082                	ret

0000000080002840 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002840:	1141                	addi	sp,sp,-16
    80002842:	e422                	sd	s0,8(sp)
    80002844:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002846:	00003797          	auipc	a5,0x3
    8000284a:	69a78793          	addi	a5,a5,1690 # 80005ee0 <kernelvec>
    8000284e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002852:	6422                	ld	s0,8(sp)
    80002854:	0141                	addi	sp,sp,16
    80002856:	8082                	ret

0000000080002858 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002858:	1141                	addi	sp,sp,-16
    8000285a:	e406                	sd	ra,8(sp)
    8000285c:	e022                	sd	s0,0(sp)
    8000285e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002860:	fffff097          	auipc	ra,0xfffff
    80002864:	14c080e7          	jalr	332(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000286c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002872:	00004697          	auipc	a3,0x4
    80002876:	78e68693          	addi	a3,a3,1934 # 80007000 <_trampoline>
    8000287a:	00004717          	auipc	a4,0x4
    8000287e:	78670713          	addi	a4,a4,1926 # 80007000 <_trampoline>
    80002882:	8f15                	sub	a4,a4,a3
    80002884:	040007b7          	lui	a5,0x4000
    80002888:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000288a:	07b2                	slli	a5,a5,0xc
    8000288c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002892:	6d78                	ld	a4,216(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002894:	18002673          	csrr	a2,satp
    80002898:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000289a:	6d70                	ld	a2,216(a0)
    8000289c:	6178                	ld	a4,192(a0)
    8000289e:	6585                	lui	a1,0x1
    800028a0:	972e                	add	a4,a4,a1
    800028a2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a4:	6d78                	ld	a4,216(a0)
    800028a6:	00000617          	auipc	a2,0x0
    800028aa:	13e60613          	addi	a2,a2,318 # 800029e4 <usertrap>
    800028ae:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028b0:	6d78                	ld	a4,216(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b2:	8612                	mv	a2,tp
    800028b4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028ba:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028be:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c6:	6d78                	ld	a4,216(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c8:	6f18                	ld	a4,24(a4)
    800028ca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028ce:	6968                	ld	a0,208(a0)
    800028d0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028d2:	00004717          	auipc	a4,0x4
    800028d6:	7ca70713          	addi	a4,a4,1994 # 8000709c <userret>
    800028da:	8f15                	sub	a4,a4,a3
    800028dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028de:	577d                	li	a4,-1
    800028e0:	177e                	slli	a4,a4,0x3f
    800028e2:	8d59                	or	a0,a0,a4
    800028e4:	9782                	jalr	a5
}
    800028e6:	60a2                	ld	ra,8(sp)
    800028e8:	6402                	ld	s0,0(sp)
    800028ea:	0141                	addi	sp,sp,16
    800028ec:	8082                	ret

00000000800028ee <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028ee:	1101                	addi	sp,sp,-32
    800028f0:	ec06                	sd	ra,24(sp)
    800028f2:	e822                	sd	s0,16(sp)
    800028f4:	e426                	sd	s1,8(sp)
    800028f6:	e04a                	sd	s2,0(sp)
    800028f8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028fa:	0001b917          	auipc	s2,0x1b
    800028fe:	2a690913          	addi	s2,s2,678 # 8001dba0 <tickslock>
    80002902:	854a                	mv	a0,s2
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	2d2080e7          	jalr	722(ra) # 80000bd6 <acquire>
  ticks++;
    8000290c:	00006497          	auipc	s1,0x6
    80002910:	ff448493          	addi	s1,s1,-12 # 80008900 <ticks>
    80002914:	409c                	lw	a5,0(s1)
    80002916:	2785                	addiw	a5,a5,1
    80002918:	c09c                	sw	a5,0(s1)
  update_time();
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	e36080e7          	jalr	-458(ra) # 80002750 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002922:	8526                	mv	a0,s1
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	7d4080e7          	jalr	2004(ra) # 800020f8 <wakeup>
  release(&tickslock);
    8000292c:	854a                	mv	a0,s2
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	35c080e7          	jalr	860(ra) # 80000c8a <release>
}
    80002936:	60e2                	ld	ra,24(sp)
    80002938:	6442                	ld	s0,16(sp)
    8000293a:	64a2                	ld	s1,8(sp)
    8000293c:	6902                	ld	s2,0(sp)
    8000293e:	6105                	addi	sp,sp,32
    80002940:	8082                	ret

0000000080002942 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002942:	1101                	addi	sp,sp,-32
    80002944:	ec06                	sd	ra,24(sp)
    80002946:	e822                	sd	s0,16(sp)
    80002948:	e426                	sd	s1,8(sp)
    8000294a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002950:	00074d63          	bltz	a4,8000296a <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002954:	57fd                	li	a5,-1
    80002956:	17fe                	slli	a5,a5,0x3f
    80002958:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000295a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000295c:	06f70363          	beq	a4,a5,800029c2 <devintr+0x80>
  }
}
    80002960:	60e2                	ld	ra,24(sp)
    80002962:	6442                	ld	s0,16(sp)
    80002964:	64a2                	ld	s1,8(sp)
    80002966:	6105                	addi	sp,sp,32
    80002968:	8082                	ret
      (scause & 0xff) == 9)
    8000296a:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    8000296e:	46a5                	li	a3,9
    80002970:	fed792e3          	bne	a5,a3,80002954 <devintr+0x12>
    int irq = plic_claim();
    80002974:	00003097          	auipc	ra,0x3
    80002978:	674080e7          	jalr	1652(ra) # 80005fe8 <plic_claim>
    8000297c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000297e:	47a9                	li	a5,10
    80002980:	02f50763          	beq	a0,a5,800029ae <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002984:	4785                	li	a5,1
    80002986:	02f50963          	beq	a0,a5,800029b8 <devintr+0x76>
    return 1;
    8000298a:	4505                	li	a0,1
    else if (irq)
    8000298c:	d8f1                	beqz	s1,80002960 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000298e:	85a6                	mv	a1,s1
    80002990:	00006517          	auipc	a0,0x6
    80002994:	97050513          	addi	a0,a0,-1680 # 80008300 <states.0+0x38>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	bf2080e7          	jalr	-1038(ra) # 8000058a <printf>
      plic_complete(irq);
    800029a0:	8526                	mv	a0,s1
    800029a2:	00003097          	auipc	ra,0x3
    800029a6:	66a080e7          	jalr	1642(ra) # 8000600c <plic_complete>
    return 1;
    800029aa:	4505                	li	a0,1
    800029ac:	bf55                	j	80002960 <devintr+0x1e>
      uartintr();
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	fea080e7          	jalr	-22(ra) # 80000998 <uartintr>
    800029b6:	b7ed                	j	800029a0 <devintr+0x5e>
      virtio_disk_intr();
    800029b8:	00004097          	auipc	ra,0x4
    800029bc:	b1c080e7          	jalr	-1252(ra) # 800064d4 <virtio_disk_intr>
    800029c0:	b7c5                	j	800029a0 <devintr+0x5e>
    if (cpuid() == 0)
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	fbe080e7          	jalr	-66(ra) # 80001980 <cpuid>
    800029ca:	c901                	beqz	a0,800029da <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029cc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029d2:	14479073          	csrw	sip,a5
    return 2;
    800029d6:	4509                	li	a0,2
    800029d8:	b761                	j	80002960 <devintr+0x1e>
      clockintr();
    800029da:	00000097          	auipc	ra,0x0
    800029de:	f14080e7          	jalr	-236(ra) # 800028ee <clockintr>
    800029e2:	b7ed                	j	800029cc <devintr+0x8a>

00000000800029e4 <usertrap>:
{
    800029e4:	1101                	addi	sp,sp,-32
    800029e6:	ec06                	sd	ra,24(sp)
    800029e8:	e822                	sd	s0,16(sp)
    800029ea:	e426                	sd	s1,8(sp)
    800029ec:	e04a                	sd	s2,0(sp)
    800029ee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029f4:	1007f793          	andi	a5,a5,256
    800029f8:	ebad                	bnez	a5,80002a6a <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fa:	00003797          	auipc	a5,0x3
    800029fe:	4e678793          	addi	a5,a5,1254 # 80005ee0 <kernelvec>
    80002a02:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	fa6080e7          	jalr	-90(ra) # 800019ac <myproc>
    80002a0e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a10:	6d7c                	ld	a5,216(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a12:	14102773          	csrr	a4,sepc
    80002a16:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a18:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a1c:	47a1                	li	a5,8
    80002a1e:	04f70e63          	beq	a4,a5,80002a7a <usertrap+0x96>
  else if ((which_dev = devintr()) != 0)
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	f20080e7          	jalr	-224(ra) # 80002942 <devintr>
    80002a2a:	892a                	mv	s2,a0
    80002a2c:	c14d                	beqz	a0,80002ace <usertrap+0xea>
  if (which_dev == 2 && p->alarm_interval > 0)
    80002a2e:	4789                	li	a5,2
    80002a30:	06f51963          	bne	a0,a5,80002aa2 <usertrap+0xbe>
    80002a34:	1f84a703          	lw	a4,504(s1)
    80002a38:	00e05e63          	blez	a4,80002a54 <usertrap+0x70>
    p->ticks++;
    80002a3c:	1f44a783          	lw	a5,500(s1)
    80002a40:	2785                	addiw	a5,a5,1
    80002a42:	0007869b          	sext.w	a3,a5
    80002a46:	1ef4aa23          	sw	a5,500(s1)
    if (p->ticks >= p->alarm_interval && p->alarm_flag == 0)
    80002a4a:	00e6c563          	blt	a3,a4,80002a54 <usertrap+0x70>
    80002a4e:	3284a783          	lw	a5,808(s1)
    80002a52:	cbdd                	beqz	a5,80002b08 <usertrap+0x124>
  if (killed(p))
    80002a54:	8526                	mv	a0,s1
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	8f2080e7          	jalr	-1806(ra) # 80002348 <killed>
    80002a5e:	e16d                	bnez	a0,80002b40 <usertrap+0x15c>
    yield();
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	5f8080e7          	jalr	1528(ra) # 80002058 <yield>
    80002a68:	a099                	j	80002aae <usertrap+0xca>
    panic("usertrap: not from user mode");
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	8b650513          	addi	a0,a0,-1866 # 80008320 <states.0+0x58>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	ace080e7          	jalr	-1330(ra) # 80000540 <panic>
    if (killed(p))
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	8ce080e7          	jalr	-1842(ra) # 80002348 <killed>
    80002a82:	e121                	bnez	a0,80002ac2 <usertrap+0xde>
    p->trapframe->epc += 4;
    80002a84:	6cf8                	ld	a4,216(s1)
    80002a86:	6f1c                	ld	a5,24(a4)
    80002a88:	0791                	addi	a5,a5,4
    80002a8a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a94:	10079073          	csrw	sstatus,a5
    syscall();
    80002a98:	00000097          	auipc	ra,0x0
    80002a9c:	2fe080e7          	jalr	766(ra) # 80002d96 <syscall>
  int which_dev = 0;
    80002aa0:	4901                	li	s2,0
  if (killed(p))
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	8a4080e7          	jalr	-1884(ra) # 80002348 <killed>
    80002aac:	e149                	bnez	a0,80002b2e <usertrap+0x14a>
  usertrapret();
    80002aae:	00000097          	auipc	ra,0x0
    80002ab2:	daa080e7          	jalr	-598(ra) # 80002858 <usertrapret>
}
    80002ab6:	60e2                	ld	ra,24(sp)
    80002ab8:	6442                	ld	s0,16(sp)
    80002aba:	64a2                	ld	s1,8(sp)
    80002abc:	6902                	ld	s2,0(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret
      exit(-1);
    80002ac2:	557d                	li	a0,-1
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	704080e7          	jalr	1796(ra) # 800021c8 <exit>
    80002acc:	bf65                	j	80002a84 <usertrap+0xa0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ace:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ad2:	5890                	lw	a2,48(s1)
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	86c50513          	addi	a0,a0,-1940 # 80008340 <states.0+0x78>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	aae080e7          	jalr	-1362(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	88450513          	addi	a0,a0,-1916 # 80008370 <states.0+0xa8>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a96080e7          	jalr	-1386(ra) # 8000058a <printf>
    setkilled(p);
    80002afc:	8526                	mv	a0,s1
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	81e080e7          	jalr	-2018(ra) # 8000231c <setkilled>
  if (which_dev == 2 && p->alarm_interval > 0)
    80002b06:	bf71                	j	80002aa2 <usertrap+0xbe>
      p->ticks = 0;        // Reset the tick count
    80002b08:	1e04aa23          	sw	zero,500(s1)
      p->alarm_flag = 1; // Mark that handler is active to prevent re-entry
    80002b0c:	4785                	li	a5,1
    80002b0e:	32f4a423          	sw	a5,808(s1)
      memmove(&p->alarm_trapframe, p->trapframe, sizeof(struct trapframe));
    80002b12:	12000613          	li	a2,288
    80002b16:	6cec                	ld	a1,216(s1)
    80002b18:	20848513          	addi	a0,s1,520
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	212080e7          	jalr	530(ra) # 80000d2e <memmove>
      p->trapframe->epc = p->handler;
    80002b24:	6cfc                	ld	a5,216(s1)
    80002b26:	2004b703          	ld	a4,512(s1)
    80002b2a:	ef98                	sd	a4,24(a5)
    80002b2c:	b725                	j	80002a54 <usertrap+0x70>
    exit(-1);
    80002b2e:	557d                	li	a0,-1
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	698080e7          	jalr	1688(ra) # 800021c8 <exit>
  if (which_dev == 2)
    80002b38:	4789                	li	a5,2
    80002b3a:	f6f91ae3          	bne	s2,a5,80002aae <usertrap+0xca>
    80002b3e:	b70d                	j	80002a60 <usertrap+0x7c>
    exit(-1);
    80002b40:	557d                	li	a0,-1
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	686080e7          	jalr	1670(ra) # 800021c8 <exit>
  if (which_dev == 2)
    80002b4a:	bf19                	j	80002a60 <usertrap+0x7c>

0000000080002b4c <kerneltrap>:
{
    80002b4c:	7179                	addi	sp,sp,-48
    80002b4e:	f406                	sd	ra,40(sp)
    80002b50:	f022                	sd	s0,32(sp)
    80002b52:	ec26                	sd	s1,24(sp)
    80002b54:	e84a                	sd	s2,16(sp)
    80002b56:	e44e                	sd	s3,8(sp)
    80002b58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b62:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b66:	1004f793          	andi	a5,s1,256
    80002b6a:	cb85                	beqz	a5,80002b9a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b70:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b72:	ef85                	bnez	a5,80002baa <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	dce080e7          	jalr	-562(ra) # 80002942 <devintr>
    80002b7c:	cd1d                	beqz	a0,80002bba <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b7e:	4789                	li	a5,2
    80002b80:	06f50a63          	beq	a0,a5,80002bf4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b84:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b88:	10049073          	csrw	sstatus,s1
}
    80002b8c:	70a2                	ld	ra,40(sp)
    80002b8e:	7402                	ld	s0,32(sp)
    80002b90:	64e2                	ld	s1,24(sp)
    80002b92:	6942                	ld	s2,16(sp)
    80002b94:	69a2                	ld	s3,8(sp)
    80002b96:	6145                	addi	sp,sp,48
    80002b98:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b9a:	00005517          	auipc	a0,0x5
    80002b9e:	7f650513          	addi	a0,a0,2038 # 80008390 <states.0+0xc8>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	99e080e7          	jalr	-1634(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002baa:	00006517          	auipc	a0,0x6
    80002bae:	80e50513          	addi	a0,a0,-2034 # 800083b8 <states.0+0xf0>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	98e080e7          	jalr	-1650(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002bba:	85ce                	mv	a1,s3
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	81c50513          	addi	a0,a0,-2020 # 800083d8 <states.0+0x110>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	9c6080e7          	jalr	-1594(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bcc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bd4:	00006517          	auipc	a0,0x6
    80002bd8:	81450513          	addi	a0,a0,-2028 # 800083e8 <states.0+0x120>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	9ae080e7          	jalr	-1618(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002be4:	00006517          	auipc	a0,0x6
    80002be8:	81c50513          	addi	a0,a0,-2020 # 80008400 <states.0+0x138>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	954080e7          	jalr	-1708(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	db8080e7          	jalr	-584(ra) # 800019ac <myproc>
    80002bfc:	d541                	beqz	a0,80002b84 <kerneltrap+0x38>
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	dae080e7          	jalr	-594(ra) # 800019ac <myproc>
    80002c06:	4d18                	lw	a4,24(a0)
    80002c08:	4791                	li	a5,4
    80002c0a:	f6f71de3          	bne	a4,a5,80002b84 <kerneltrap+0x38>
    yield();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	44a080e7          	jalr	1098(ra) # 80002058 <yield>
    80002c16:	b7bd                	j	80002b84 <kerneltrap+0x38>

0000000080002c18 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c18:	1101                	addi	sp,sp,-32
    80002c1a:	ec06                	sd	ra,24(sp)
    80002c1c:	e822                	sd	s0,16(sp)
    80002c1e:	e426                	sd	s1,8(sp)
    80002c20:	1000                	addi	s0,sp,32
    80002c22:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	d88080e7          	jalr	-632(ra) # 800019ac <myproc>
  switch (n) {
    80002c2c:	4795                	li	a5,5
    80002c2e:	0497e163          	bltu	a5,s1,80002c70 <argraw+0x58>
    80002c32:	048a                	slli	s1,s1,0x2
    80002c34:	00006717          	auipc	a4,0x6
    80002c38:	80470713          	addi	a4,a4,-2044 # 80008438 <states.0+0x170>
    80002c3c:	94ba                	add	s1,s1,a4
    80002c3e:	409c                	lw	a5,0(s1)
    80002c40:	97ba                	add	a5,a5,a4
    80002c42:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c44:	6d7c                	ld	a5,216(a0)
    80002c46:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6105                	addi	sp,sp,32
    80002c50:	8082                	ret
    return p->trapframe->a1;
    80002c52:	6d7c                	ld	a5,216(a0)
    80002c54:	7fa8                	ld	a0,120(a5)
    80002c56:	bfcd                	j	80002c48 <argraw+0x30>
    return p->trapframe->a2;
    80002c58:	6d7c                	ld	a5,216(a0)
    80002c5a:	63c8                	ld	a0,128(a5)
    80002c5c:	b7f5                	j	80002c48 <argraw+0x30>
    return p->trapframe->a3;
    80002c5e:	6d7c                	ld	a5,216(a0)
    80002c60:	67c8                	ld	a0,136(a5)
    80002c62:	b7dd                	j	80002c48 <argraw+0x30>
    return p->trapframe->a4;
    80002c64:	6d7c                	ld	a5,216(a0)
    80002c66:	6bc8                	ld	a0,144(a5)
    80002c68:	b7c5                	j	80002c48 <argraw+0x30>
    return p->trapframe->a5;
    80002c6a:	6d7c                	ld	a5,216(a0)
    80002c6c:	6fc8                	ld	a0,152(a5)
    80002c6e:	bfe9                	j	80002c48 <argraw+0x30>
  panic("argraw");
    80002c70:	00005517          	auipc	a0,0x5
    80002c74:	7a050513          	addi	a0,a0,1952 # 80008410 <states.0+0x148>
    80002c78:	ffffe097          	auipc	ra,0xffffe
    80002c7c:	8c8080e7          	jalr	-1848(ra) # 80000540 <panic>

0000000080002c80 <fetchaddr>:
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	e04a                	sd	s2,0(sp)
    80002c8a:	1000                	addi	s0,sp,32
    80002c8c:	84aa                	mv	s1,a0
    80002c8e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d1c080e7          	jalr	-740(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c98:	657c                	ld	a5,200(a0)
    80002c9a:	02f4f863          	bgeu	s1,a5,80002cca <fetchaddr+0x4a>
    80002c9e:	00848713          	addi	a4,s1,8
    80002ca2:	02e7e663          	bltu	a5,a4,80002cce <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ca6:	46a1                	li	a3,8
    80002ca8:	8626                	mv	a2,s1
    80002caa:	85ca                	mv	a1,s2
    80002cac:	6968                	ld	a0,208(a0)
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	a4a080e7          	jalr	-1462(ra) # 800016f8 <copyin>
    80002cb6:	00a03533          	snez	a0,a0
    80002cba:	40a00533          	neg	a0,a0
}
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	64a2                	ld	s1,8(sp)
    80002cc4:	6902                	ld	s2,0(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret
    return -1;
    80002cca:	557d                	li	a0,-1
    80002ccc:	bfcd                	j	80002cbe <fetchaddr+0x3e>
    80002cce:	557d                	li	a0,-1
    80002cd0:	b7fd                	j	80002cbe <fetchaddr+0x3e>

0000000080002cd2 <fetchstr>:
{
    80002cd2:	7179                	addi	sp,sp,-48
    80002cd4:	f406                	sd	ra,40(sp)
    80002cd6:	f022                	sd	s0,32(sp)
    80002cd8:	ec26                	sd	s1,24(sp)
    80002cda:	e84a                	sd	s2,16(sp)
    80002cdc:	e44e                	sd	s3,8(sp)
    80002cde:	1800                	addi	s0,sp,48
    80002ce0:	892a                	mv	s2,a0
    80002ce2:	84ae                	mv	s1,a1
    80002ce4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	cc6080e7          	jalr	-826(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cee:	86ce                	mv	a3,s3
    80002cf0:	864a                	mv	a2,s2
    80002cf2:	85a6                	mv	a1,s1
    80002cf4:	6968                	ld	a0,208(a0)
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	a90080e7          	jalr	-1392(ra) # 80001786 <copyinstr>
    80002cfe:	00054e63          	bltz	a0,80002d1a <fetchstr+0x48>
  return strlen(buf);
    80002d02:	8526                	mv	a0,s1
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	14a080e7          	jalr	330(ra) # 80000e4e <strlen>
}
    80002d0c:	70a2                	ld	ra,40(sp)
    80002d0e:	7402                	ld	s0,32(sp)
    80002d10:	64e2                	ld	s1,24(sp)
    80002d12:	6942                	ld	s2,16(sp)
    80002d14:	69a2                	ld	s3,8(sp)
    80002d16:	6145                	addi	sp,sp,48
    80002d18:	8082                	ret
    return -1;
    80002d1a:	557d                	li	a0,-1
    80002d1c:	bfc5                	j	80002d0c <fetchstr+0x3a>

0000000080002d1e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d1e:	1101                	addi	sp,sp,-32
    80002d20:	ec06                	sd	ra,24(sp)
    80002d22:	e822                	sd	s0,16(sp)
    80002d24:	e426                	sd	s1,8(sp)
    80002d26:	1000                	addi	s0,sp,32
    80002d28:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	eee080e7          	jalr	-274(ra) # 80002c18 <argraw>
    80002d32:	c088                	sw	a0,0(s1)
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
    80002d48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	ece080e7          	jalr	-306(ra) # 80002c18 <argraw>
    80002d52:	e088                	sd	a0,0(s1)
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret

0000000080002d5e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d5e:	7179                	addi	sp,sp,-48
    80002d60:	f406                	sd	ra,40(sp)
    80002d62:	f022                	sd	s0,32(sp)
    80002d64:	ec26                	sd	s1,24(sp)
    80002d66:	e84a                	sd	s2,16(sp)
    80002d68:	1800                	addi	s0,sp,48
    80002d6a:	84ae                	mv	s1,a1
    80002d6c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d6e:	fd840593          	addi	a1,s0,-40
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	fcc080e7          	jalr	-52(ra) # 80002d3e <argaddr>
  return fetchstr(addr, buf, max);
    80002d7a:	864a                	mv	a2,s2
    80002d7c:	85a6                	mv	a1,s1
    80002d7e:	fd843503          	ld	a0,-40(s0)
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	f50080e7          	jalr	-176(ra) # 80002cd2 <fetchstr>
}
    80002d8a:	70a2                	ld	ra,40(sp)
    80002d8c:	7402                	ld	s0,32(sp)
    80002d8e:	64e2                	ld	s1,24(sp)
    80002d90:	6942                	ld	s2,16(sp)
    80002d92:	6145                	addi	sp,sp,48
    80002d94:	8082                	ret

0000000080002d96 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002d96:	7179                	addi	sp,sp,-48
    80002d98:	f406                	sd	ra,40(sp)
    80002d9a:	f022                	sd	s0,32(sp)
    80002d9c:	ec26                	sd	s1,24(sp)
    80002d9e:	e84a                	sd	s2,16(sp)
    80002da0:	e44e                	sd	s3,8(sp)
    80002da2:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	c08080e7          	jalr	-1016(ra) # 800019ac <myproc>
    80002dac:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dae:	0d853983          	ld	s3,216(a0)
    80002db2:	0a89b783          	ld	a5,168(s3)
    80002db6:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dba:	37fd                	addiw	a5,a5,-1
    80002dbc:	4761                	li	a4,24
    80002dbe:	02f76663          	bltu	a4,a5,80002dea <syscall+0x54>
    80002dc2:	00391713          	slli	a4,s2,0x3
    80002dc6:	00005797          	auipc	a5,0x5
    80002dca:	68a78793          	addi	a5,a5,1674 # 80008450 <syscalls>
    80002dce:	97ba                	add	a5,a5,a4
    80002dd0:	639c                	ld	a5,0(a5)
    80002dd2:	cf81                	beqz	a5,80002dea <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002dd4:	9782                	jalr	a5
    80002dd6:	06a9b823          	sd	a0,112(s3)
    if(num<26 && num>=0)
    {
      p->syscall_count[num]++;
    80002dda:	090a                	slli	s2,s2,0x2
    80002ddc:	9926                	add	s2,s2,s1
    80002dde:	04092783          	lw	a5,64(s2)
    80002de2:	2785                	addiw	a5,a5,1
    80002de4:	04f92023          	sw	a5,64(s2)
    80002de8:	a005                	j	80002e08 <syscall+0x72>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dea:	86ca                	mv	a3,s2
    80002dec:	1d848613          	addi	a2,s1,472
    80002df0:	588c                	lw	a1,48(s1)
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	62650513          	addi	a0,a0,1574 # 80008418 <states.0+0x150>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	790080e7          	jalr	1936(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e02:	6cfc                	ld	a5,216(s1)
    80002e04:	577d                	li	a4,-1
    80002e06:	fbb8                	sd	a4,112(a5)
  }
}
    80002e08:	70a2                	ld	ra,40(sp)
    80002e0a:	7402                	ld	s0,32(sp)
    80002e0c:	64e2                	ld	s1,24(sp)
    80002e0e:	6942                	ld	s2,16(sp)
    80002e10:	69a2                	ld	s3,8(sp)
    80002e12:	6145                	addi	sp,sp,48
    80002e14:	8082                	ret

0000000080002e16 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e1e:	fec40593          	addi	a1,s0,-20
    80002e22:	4501                	li	a0,0
    80002e24:	00000097          	auipc	ra,0x0
    80002e28:	efa080e7          	jalr	-262(ra) # 80002d1e <argint>
  exit(n);
    80002e2c:	fec42503          	lw	a0,-20(s0)
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	398080e7          	jalr	920(ra) # 800021c8 <exit>
  return 0; // not reached
}
    80002e38:	4501                	li	a0,0
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	6105                	addi	sp,sp,32
    80002e40:	8082                	ret

0000000080002e42 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e42:	1141                	addi	sp,sp,-16
    80002e44:	e406                	sd	ra,8(sp)
    80002e46:	e022                	sd	s0,0(sp)
    80002e48:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b62080e7          	jalr	-1182(ra) # 800019ac <myproc>
}
    80002e52:	5908                	lw	a0,48(a0)
    80002e54:	60a2                	ld	ra,8(sp)
    80002e56:	6402                	ld	s0,0(sp)
    80002e58:	0141                	addi	sp,sp,16
    80002e5a:	8082                	ret

0000000080002e5c <sys_fork>:

uint64
sys_fork(void)
{
    80002e5c:	1141                	addi	sp,sp,-16
    80002e5e:	e406                	sd	ra,8(sp)
    80002e60:	e022                	sd	s0,0(sp)
    80002e62:	0800                	addi	s0,sp,16
  return fork();
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	f3e080e7          	jalr	-194(ra) # 80001da2 <fork>
}
    80002e6c:	60a2                	ld	ra,8(sp)
    80002e6e:	6402                	ld	s0,0(sp)
    80002e70:	0141                	addi	sp,sp,16
    80002e72:	8082                	ret

0000000080002e74 <sys_wait>:

uint64
sys_wait(void)
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e7c:	fe840593          	addi	a1,s0,-24
    80002e80:	4501                	li	a0,0
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	ebc080e7          	jalr	-324(ra) # 80002d3e <argaddr>
  return wait(p);
    80002e8a:	fe843503          	ld	a0,-24(s0)
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	4ec080e7          	jalr	1260(ra) # 8000237a <wait>
}
    80002e96:	60e2                	ld	ra,24(sp)
    80002e98:	6442                	ld	s0,16(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e9e:	7179                	addi	sp,sp,-48
    80002ea0:	f406                	sd	ra,40(sp)
    80002ea2:	f022                	sd	s0,32(sp)
    80002ea4:	ec26                	sd	s1,24(sp)
    80002ea6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ea8:	fdc40593          	addi	a1,s0,-36
    80002eac:	4501                	li	a0,0
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	e70080e7          	jalr	-400(ra) # 80002d1e <argint>
  addr = myproc()->sz;
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	af6080e7          	jalr	-1290(ra) # 800019ac <myproc>
    80002ebe:	6564                	ld	s1,200(a0)
  if (growproc(n) < 0)
    80002ec0:	fdc42503          	lw	a0,-36(s0)
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	e82080e7          	jalr	-382(ra) # 80001d46 <growproc>
    80002ecc:	00054863          	bltz	a0,80002edc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	70a2                	ld	ra,40(sp)
    80002ed4:	7402                	ld	s0,32(sp)
    80002ed6:	64e2                	ld	s1,24(sp)
    80002ed8:	6145                	addi	sp,sp,48
    80002eda:	8082                	ret
    return -1;
    80002edc:	54fd                	li	s1,-1
    80002ede:	bfcd                	j	80002ed0 <sys_sbrk+0x32>

0000000080002ee0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ee0:	7139                	addi	sp,sp,-64
    80002ee2:	fc06                	sd	ra,56(sp)
    80002ee4:	f822                	sd	s0,48(sp)
    80002ee6:	f426                	sd	s1,40(sp)
    80002ee8:	f04a                	sd	s2,32(sp)
    80002eea:	ec4e                	sd	s3,24(sp)
    80002eec:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002eee:	fcc40593          	addi	a1,s0,-52
    80002ef2:	4501                	li	a0,0
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	e2a080e7          	jalr	-470(ra) # 80002d1e <argint>
  acquire(&tickslock);
    80002efc:	0001b517          	auipc	a0,0x1b
    80002f00:	ca450513          	addi	a0,a0,-860 # 8001dba0 <tickslock>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	cd2080e7          	jalr	-814(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002f0c:	00006917          	auipc	s2,0x6
    80002f10:	9f492903          	lw	s2,-1548(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002f14:	fcc42783          	lw	a5,-52(s0)
    80002f18:	cf9d                	beqz	a5,80002f56 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f1a:	0001b997          	auipc	s3,0x1b
    80002f1e:	c8698993          	addi	s3,s3,-890 # 8001dba0 <tickslock>
    80002f22:	00006497          	auipc	s1,0x6
    80002f26:	9de48493          	addi	s1,s1,-1570 # 80008900 <ticks>
    if (killed(myproc()))
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	a82080e7          	jalr	-1406(ra) # 800019ac <myproc>
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	416080e7          	jalr	1046(ra) # 80002348 <killed>
    80002f3a:	ed15                	bnez	a0,80002f76 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f3c:	85ce                	mv	a1,s3
    80002f3e:	8526                	mv	a0,s1
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	154080e7          	jalr	340(ra) # 80002094 <sleep>
  while (ticks - ticks0 < n)
    80002f48:	409c                	lw	a5,0(s1)
    80002f4a:	412787bb          	subw	a5,a5,s2
    80002f4e:	fcc42703          	lw	a4,-52(s0)
    80002f52:	fce7ece3          	bltu	a5,a4,80002f2a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f56:	0001b517          	auipc	a0,0x1b
    80002f5a:	c4a50513          	addi	a0,a0,-950 # 8001dba0 <tickslock>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	d2c080e7          	jalr	-724(ra) # 80000c8a <release>
  return 0;
    80002f66:	4501                	li	a0,0
}
    80002f68:	70e2                	ld	ra,56(sp)
    80002f6a:	7442                	ld	s0,48(sp)
    80002f6c:	74a2                	ld	s1,40(sp)
    80002f6e:	7902                	ld	s2,32(sp)
    80002f70:	69e2                	ld	s3,24(sp)
    80002f72:	6121                	addi	sp,sp,64
    80002f74:	8082                	ret
      release(&tickslock);
    80002f76:	0001b517          	auipc	a0,0x1b
    80002f7a:	c2a50513          	addi	a0,a0,-982 # 8001dba0 <tickslock>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	d0c080e7          	jalr	-756(ra) # 80000c8a <release>
      return -1;
    80002f86:	557d                	li	a0,-1
    80002f88:	b7c5                	j	80002f68 <sys_sleep+0x88>

0000000080002f8a <sys_kill>:

uint64
sys_kill(void)
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f92:	fec40593          	addi	a1,s0,-20
    80002f96:	4501                	li	a0,0
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	d86080e7          	jalr	-634(ra) # 80002d1e <argint>
  return kill(pid);
    80002fa0:	fec42503          	lw	a0,-20(s0)
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	306080e7          	jalr	774(ra) # 800022aa <kill>
}
    80002fac:	60e2                	ld	ra,24(sp)
    80002fae:	6442                	ld	s0,16(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret

0000000080002fb4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	e426                	sd	s1,8(sp)
    80002fbc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fbe:	0001b517          	auipc	a0,0x1b
    80002fc2:	be250513          	addi	a0,a0,-1054 # 8001dba0 <tickslock>
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fce:	00006497          	auipc	s1,0x6
    80002fd2:	9324a483          	lw	s1,-1742(s1) # 80008900 <ticks>
  release(&tickslock);
    80002fd6:	0001b517          	auipc	a0,0x1b
    80002fda:	bca50513          	addi	a0,a0,-1078 # 8001dba0 <tickslock>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	cac080e7          	jalr	-852(ra) # 80000c8a <release>
  return xticks;
}
    80002fe6:	02049513          	slli	a0,s1,0x20
    80002fea:	9101                	srli	a0,a0,0x20
    80002fec:	60e2                	ld	ra,24(sp)
    80002fee:	6442                	ld	s0,16(sp)
    80002ff0:	64a2                	ld	s1,8(sp)
    80002ff2:	6105                	addi	sp,sp,32
    80002ff4:	8082                	ret

0000000080002ff6 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002ff6:	7139                	addi	sp,sp,-64
    80002ff8:	fc06                	sd	ra,56(sp)
    80002ffa:	f822                	sd	s0,48(sp)
    80002ffc:	f426                	sd	s1,40(sp)
    80002ffe:	f04a                	sd	s2,32(sp)
    80003000:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003002:	fd840593          	addi	a1,s0,-40
    80003006:	4501                	li	a0,0
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	d36080e7          	jalr	-714(ra) # 80002d3e <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003010:	fd040593          	addi	a1,s0,-48
    80003014:	4505                	li	a0,1
    80003016:	00000097          	auipc	ra,0x0
    8000301a:	d28080e7          	jalr	-728(ra) # 80002d3e <argaddr>
  argaddr(2, &addr2);
    8000301e:	fc840593          	addi	a1,s0,-56
    80003022:	4509                	li	a0,2
    80003024:	00000097          	auipc	ra,0x0
    80003028:	d1a080e7          	jalr	-742(ra) # 80002d3e <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000302c:	fc040613          	addi	a2,s0,-64
    80003030:	fc440593          	addi	a1,s0,-60
    80003034:	fd843503          	ld	a0,-40(s0)
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	5cc080e7          	jalr	1484(ra) # 80002604 <waitx>
    80003040:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	96a080e7          	jalr	-1686(ra) # 800019ac <myproc>
    8000304a:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000304c:	4691                	li	a3,4
    8000304e:	fc440613          	addi	a2,s0,-60
    80003052:	fd043583          	ld	a1,-48(s0)
    80003056:	6968                	ld	a0,208(a0)
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	614080e7          	jalr	1556(ra) # 8000166c <copyout>
    return -1;
    80003060:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003062:	00054f63          	bltz	a0,80003080 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003066:	4691                	li	a3,4
    80003068:	fc040613          	addi	a2,s0,-64
    8000306c:	fc843583          	ld	a1,-56(s0)
    80003070:	68e8                	ld	a0,208(s1)
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	5fa080e7          	jalr	1530(ra) # 8000166c <copyout>
    8000307a:	00054a63          	bltz	a0,8000308e <sys_waitx+0x98>
    return -1;
  return ret;
    8000307e:	87ca                	mv	a5,s2
}
    80003080:	853e                	mv	a0,a5
    80003082:	70e2                	ld	ra,56(sp)
    80003084:	7442                	ld	s0,48(sp)
    80003086:	74a2                	ld	s1,40(sp)
    80003088:	7902                	ld	s2,32(sp)
    8000308a:	6121                	addi	sp,sp,64
    8000308c:	8082                	ret
    return -1;
    8000308e:	57fd                	li	a5,-1
    80003090:	bfc5                	j	80003080 <sys_waitx+0x8a>

0000000080003092 <sys_getSysCount>:


uint64
sys_getSysCount(void)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	1000                	addi	s0,sp,32
  int k;
  argint(0, &k);
    8000309a:	fec40593          	addi	a1,s0,-20
    8000309e:	4501                	li	a0,0
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	c7e080e7          	jalr	-898(ra) # 80002d1e <argint>
  struct proc *p = myproc();
    800030a8:	fffff097          	auipc	ra,0xfffff
    800030ac:	904080e7          	jalr	-1788(ra) # 800019ac <myproc>
  return p->syscall_count[k];
    800030b0:	fec42783          	lw	a5,-20(s0)
    800030b4:	07c1                	addi	a5,a5,16
    800030b6:	078a                	slli	a5,a5,0x2
    800030b8:	953e                	add	a0,a0,a5
}
    800030ba:	4108                	lw	a0,0(a0)
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	6105                	addi	sp,sp,32
    800030c2:	8082                	ret

00000000800030c4 <sys_sigalarm>:

// In sysproc.c
uint64 sys_sigalarm(void)
{
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	1000                	addi	s0,sp,32
  int time;
  uint64 handler;
  argaddr(1, &handler);
    800030cc:	fe040593          	addi	a1,s0,-32
    800030d0:	4505                	li	a0,1
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	c6c080e7          	jalr	-916(ra) # 80002d3e <argaddr>
  argint(0, &time);
    800030da:	fec40593          	addi	a1,s0,-20
    800030de:	4501                	li	a0,0
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	c3e080e7          	jalr	-962(ra) # 80002d1e <argint>

  struct proc *p = myproc();
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	8c4080e7          	jalr	-1852(ra) # 800019ac <myproc>
  p->alarm_interval = time;
    800030f0:	fec42783          	lw	a5,-20(s0)
    800030f4:	1ef52c23          	sw	a5,504(a0)
  p->handler = handler;
    800030f8:	fe043783          	ld	a5,-32(s0)
    800030fc:	20f53023          	sd	a5,512(a0)
  p->ticks = 0;
    80003100:	1e052a23          	sw	zero,500(a0)
  p->alarm_flag = 0; // Reset ticks
    80003104:	32052423          	sw	zero,808(a0)

  return 0; // Success
}
    80003108:	4501                	li	a0,0
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	890080e7          	jalr	-1904(ra) # 800019ac <myproc>
    80003124:	84aa                	mv	s1,a0
  memmove(p->trapframe, &p->alarm_trapframe, sizeof(struct trapframe));
    80003126:	12000613          	li	a2,288
    8000312a:	20850593          	addi	a1,a0,520
    8000312e:	6d68                	ld	a0,216(a0)
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	bfe080e7          	jalr	-1026(ra) # 80000d2e <memmove>
  p->alarm_flag = 0;
    80003138:	3204a423          	sw	zero,808(s1)
  return p->trapframe->a0;
    8000313c:	6cfc                	ld	a5,216(s1)
}
    8000313e:	7ba8                	ld	a0,112(a5)
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	64a2                	ld	s1,8(sp)
    80003146:	6105                	addi	sp,sp,32
    80003148:	8082                	ret

000000008000314a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	e84a                	sd	s2,16(sp)
    80003154:	e44e                	sd	s3,8(sp)
    80003156:	e052                	sd	s4,0(sp)
    80003158:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000315a:	00005597          	auipc	a1,0x5
    8000315e:	3c658593          	addi	a1,a1,966 # 80008520 <syscalls+0xd0>
    80003162:	0001b517          	auipc	a0,0x1b
    80003166:	a5650513          	addi	a0,a0,-1450 # 8001dbb8 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	9dc080e7          	jalr	-1572(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003172:	00023797          	auipc	a5,0x23
    80003176:	a4678793          	addi	a5,a5,-1466 # 80025bb8 <bcache+0x8000>
    8000317a:	00023717          	auipc	a4,0x23
    8000317e:	ca670713          	addi	a4,a4,-858 # 80025e20 <bcache+0x8268>
    80003182:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003186:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000318a:	0001b497          	auipc	s1,0x1b
    8000318e:	a4648493          	addi	s1,s1,-1466 # 8001dbd0 <bcache+0x18>
    b->next = bcache.head.next;
    80003192:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003194:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003196:	00005a17          	auipc	s4,0x5
    8000319a:	392a0a13          	addi	s4,s4,914 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000319e:	2b893783          	ld	a5,696(s2)
    800031a2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031a4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031a8:	85d2                	mv	a1,s4
    800031aa:	01048513          	addi	a0,s1,16
    800031ae:	00001097          	auipc	ra,0x1
    800031b2:	4c8080e7          	jalr	1224(ra) # 80004676 <initsleeplock>
    bcache.head.next->prev = b;
    800031b6:	2b893783          	ld	a5,696(s2)
    800031ba:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031bc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031c0:	45848493          	addi	s1,s1,1112
    800031c4:	fd349de3          	bne	s1,s3,8000319e <binit+0x54>
  }
}
    800031c8:	70a2                	ld	ra,40(sp)
    800031ca:	7402                	ld	s0,32(sp)
    800031cc:	64e2                	ld	s1,24(sp)
    800031ce:	6942                	ld	s2,16(sp)
    800031d0:	69a2                	ld	s3,8(sp)
    800031d2:	6a02                	ld	s4,0(sp)
    800031d4:	6145                	addi	sp,sp,48
    800031d6:	8082                	ret

00000000800031d8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031d8:	7179                	addi	sp,sp,-48
    800031da:	f406                	sd	ra,40(sp)
    800031dc:	f022                	sd	s0,32(sp)
    800031de:	ec26                	sd	s1,24(sp)
    800031e0:	e84a                	sd	s2,16(sp)
    800031e2:	e44e                	sd	s3,8(sp)
    800031e4:	1800                	addi	s0,sp,48
    800031e6:	892a                	mv	s2,a0
    800031e8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031ea:	0001b517          	auipc	a0,0x1b
    800031ee:	9ce50513          	addi	a0,a0,-1586 # 8001dbb8 <bcache>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	9e4080e7          	jalr	-1564(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031fa:	00023497          	auipc	s1,0x23
    800031fe:	c764b483          	ld	s1,-906(s1) # 80025e70 <bcache+0x82b8>
    80003202:	00023797          	auipc	a5,0x23
    80003206:	c1e78793          	addi	a5,a5,-994 # 80025e20 <bcache+0x8268>
    8000320a:	02f48f63          	beq	s1,a5,80003248 <bread+0x70>
    8000320e:	873e                	mv	a4,a5
    80003210:	a021                	j	80003218 <bread+0x40>
    80003212:	68a4                	ld	s1,80(s1)
    80003214:	02e48a63          	beq	s1,a4,80003248 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003218:	449c                	lw	a5,8(s1)
    8000321a:	ff279ce3          	bne	a5,s2,80003212 <bread+0x3a>
    8000321e:	44dc                	lw	a5,12(s1)
    80003220:	ff3799e3          	bne	a5,s3,80003212 <bread+0x3a>
      b->refcnt++;
    80003224:	40bc                	lw	a5,64(s1)
    80003226:	2785                	addiw	a5,a5,1
    80003228:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000322a:	0001b517          	auipc	a0,0x1b
    8000322e:	98e50513          	addi	a0,a0,-1650 # 8001dbb8 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	a58080e7          	jalr	-1448(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000323a:	01048513          	addi	a0,s1,16
    8000323e:	00001097          	auipc	ra,0x1
    80003242:	472080e7          	jalr	1138(ra) # 800046b0 <acquiresleep>
      return b;
    80003246:	a8b9                	j	800032a4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003248:	00023497          	auipc	s1,0x23
    8000324c:	c204b483          	ld	s1,-992(s1) # 80025e68 <bcache+0x82b0>
    80003250:	00023797          	auipc	a5,0x23
    80003254:	bd078793          	addi	a5,a5,-1072 # 80025e20 <bcache+0x8268>
    80003258:	00f48863          	beq	s1,a5,80003268 <bread+0x90>
    8000325c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000325e:	40bc                	lw	a5,64(s1)
    80003260:	cf81                	beqz	a5,80003278 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003262:	64a4                	ld	s1,72(s1)
    80003264:	fee49de3          	bne	s1,a4,8000325e <bread+0x86>
  panic("bget: no buffers");
    80003268:	00005517          	auipc	a0,0x5
    8000326c:	2c850513          	addi	a0,a0,712 # 80008530 <syscalls+0xe0>
    80003270:	ffffd097          	auipc	ra,0xffffd
    80003274:	2d0080e7          	jalr	720(ra) # 80000540 <panic>
      b->dev = dev;
    80003278:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000327c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003280:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003284:	4785                	li	a5,1
    80003286:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003288:	0001b517          	auipc	a0,0x1b
    8000328c:	93050513          	addi	a0,a0,-1744 # 8001dbb8 <bcache>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003298:	01048513          	addi	a0,s1,16
    8000329c:	00001097          	auipc	ra,0x1
    800032a0:	414080e7          	jalr	1044(ra) # 800046b0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032a4:	409c                	lw	a5,0(s1)
    800032a6:	cb89                	beqz	a5,800032b8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032a8:	8526                	mv	a0,s1
    800032aa:	70a2                	ld	ra,40(sp)
    800032ac:	7402                	ld	s0,32(sp)
    800032ae:	64e2                	ld	s1,24(sp)
    800032b0:	6942                	ld	s2,16(sp)
    800032b2:	69a2                	ld	s3,8(sp)
    800032b4:	6145                	addi	sp,sp,48
    800032b6:	8082                	ret
    virtio_disk_rw(b, 0);
    800032b8:	4581                	li	a1,0
    800032ba:	8526                	mv	a0,s1
    800032bc:	00003097          	auipc	ra,0x3
    800032c0:	fe6080e7          	jalr	-26(ra) # 800062a2 <virtio_disk_rw>
    b->valid = 1;
    800032c4:	4785                	li	a5,1
    800032c6:	c09c                	sw	a5,0(s1)
  return b;
    800032c8:	b7c5                	j	800032a8 <bread+0xd0>

00000000800032ca <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	1000                	addi	s0,sp,32
    800032d4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032d6:	0541                	addi	a0,a0,16
    800032d8:	00001097          	auipc	ra,0x1
    800032dc:	472080e7          	jalr	1138(ra) # 8000474a <holdingsleep>
    800032e0:	cd01                	beqz	a0,800032f8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032e2:	4585                	li	a1,1
    800032e4:	8526                	mv	a0,s1
    800032e6:	00003097          	auipc	ra,0x3
    800032ea:	fbc080e7          	jalr	-68(ra) # 800062a2 <virtio_disk_rw>
}
    800032ee:	60e2                	ld	ra,24(sp)
    800032f0:	6442                	ld	s0,16(sp)
    800032f2:	64a2                	ld	s1,8(sp)
    800032f4:	6105                	addi	sp,sp,32
    800032f6:	8082                	ret
    panic("bwrite");
    800032f8:	00005517          	auipc	a0,0x5
    800032fc:	25050513          	addi	a0,a0,592 # 80008548 <syscalls+0xf8>
    80003300:	ffffd097          	auipc	ra,0xffffd
    80003304:	240080e7          	jalr	576(ra) # 80000540 <panic>

0000000080003308 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003308:	1101                	addi	sp,sp,-32
    8000330a:	ec06                	sd	ra,24(sp)
    8000330c:	e822                	sd	s0,16(sp)
    8000330e:	e426                	sd	s1,8(sp)
    80003310:	e04a                	sd	s2,0(sp)
    80003312:	1000                	addi	s0,sp,32
    80003314:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003316:	01050913          	addi	s2,a0,16
    8000331a:	854a                	mv	a0,s2
    8000331c:	00001097          	auipc	ra,0x1
    80003320:	42e080e7          	jalr	1070(ra) # 8000474a <holdingsleep>
    80003324:	c92d                	beqz	a0,80003396 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003326:	854a                	mv	a0,s2
    80003328:	00001097          	auipc	ra,0x1
    8000332c:	3de080e7          	jalr	990(ra) # 80004706 <releasesleep>

  acquire(&bcache.lock);
    80003330:	0001b517          	auipc	a0,0x1b
    80003334:	88850513          	addi	a0,a0,-1912 # 8001dbb8 <bcache>
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	89e080e7          	jalr	-1890(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003340:	40bc                	lw	a5,64(s1)
    80003342:	37fd                	addiw	a5,a5,-1
    80003344:	0007871b          	sext.w	a4,a5
    80003348:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000334a:	eb05                	bnez	a4,8000337a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000334c:	68bc                	ld	a5,80(s1)
    8000334e:	64b8                	ld	a4,72(s1)
    80003350:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003352:	64bc                	ld	a5,72(s1)
    80003354:	68b8                	ld	a4,80(s1)
    80003356:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003358:	00023797          	auipc	a5,0x23
    8000335c:	86078793          	addi	a5,a5,-1952 # 80025bb8 <bcache+0x8000>
    80003360:	2b87b703          	ld	a4,696(a5)
    80003364:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003366:	00023717          	auipc	a4,0x23
    8000336a:	aba70713          	addi	a4,a4,-1350 # 80025e20 <bcache+0x8268>
    8000336e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003370:	2b87b703          	ld	a4,696(a5)
    80003374:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003376:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000337a:	0001b517          	auipc	a0,0x1b
    8000337e:	83e50513          	addi	a0,a0,-1986 # 8001dbb8 <bcache>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	908080e7          	jalr	-1784(ra) # 80000c8a <release>
}
    8000338a:	60e2                	ld	ra,24(sp)
    8000338c:	6442                	ld	s0,16(sp)
    8000338e:	64a2                	ld	s1,8(sp)
    80003390:	6902                	ld	s2,0(sp)
    80003392:	6105                	addi	sp,sp,32
    80003394:	8082                	ret
    panic("brelse");
    80003396:	00005517          	auipc	a0,0x5
    8000339a:	1ba50513          	addi	a0,a0,442 # 80008550 <syscalls+0x100>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	1a2080e7          	jalr	418(ra) # 80000540 <panic>

00000000800033a6 <bpin>:

void
bpin(struct buf *b) {
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	e426                	sd	s1,8(sp)
    800033ae:	1000                	addi	s0,sp,32
    800033b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033b2:	0001b517          	auipc	a0,0x1b
    800033b6:	80650513          	addi	a0,a0,-2042 # 8001dbb8 <bcache>
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	81c080e7          	jalr	-2020(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800033c2:	40bc                	lw	a5,64(s1)
    800033c4:	2785                	addiw	a5,a5,1
    800033c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033c8:	0001a517          	auipc	a0,0x1a
    800033cc:	7f050513          	addi	a0,a0,2032 # 8001dbb8 <bcache>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
}
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6105                	addi	sp,sp,32
    800033e0:	8082                	ret

00000000800033e2 <bunpin>:

void
bunpin(struct buf *b) {
    800033e2:	1101                	addi	sp,sp,-32
    800033e4:	ec06                	sd	ra,24(sp)
    800033e6:	e822                	sd	s0,16(sp)
    800033e8:	e426                	sd	s1,8(sp)
    800033ea:	1000                	addi	s0,sp,32
    800033ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ee:	0001a517          	auipc	a0,0x1a
    800033f2:	7ca50513          	addi	a0,a0,1994 # 8001dbb8 <bcache>
    800033f6:	ffffd097          	auipc	ra,0xffffd
    800033fa:	7e0080e7          	jalr	2016(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033fe:	40bc                	lw	a5,64(s1)
    80003400:	37fd                	addiw	a5,a5,-1
    80003402:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003404:	0001a517          	auipc	a0,0x1a
    80003408:	7b450513          	addi	a0,a0,1972 # 8001dbb8 <bcache>
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
}
    80003414:	60e2                	ld	ra,24(sp)
    80003416:	6442                	ld	s0,16(sp)
    80003418:	64a2                	ld	s1,8(sp)
    8000341a:	6105                	addi	sp,sp,32
    8000341c:	8082                	ret

000000008000341e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000341e:	1101                	addi	sp,sp,-32
    80003420:	ec06                	sd	ra,24(sp)
    80003422:	e822                	sd	s0,16(sp)
    80003424:	e426                	sd	s1,8(sp)
    80003426:	e04a                	sd	s2,0(sp)
    80003428:	1000                	addi	s0,sp,32
    8000342a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000342c:	00d5d59b          	srliw	a1,a1,0xd
    80003430:	00023797          	auipc	a5,0x23
    80003434:	e647a783          	lw	a5,-412(a5) # 80026294 <sb+0x1c>
    80003438:	9dbd                	addw	a1,a1,a5
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	d9e080e7          	jalr	-610(ra) # 800031d8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003442:	0074f713          	andi	a4,s1,7
    80003446:	4785                	li	a5,1
    80003448:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000344c:	14ce                	slli	s1,s1,0x33
    8000344e:	90d9                	srli	s1,s1,0x36
    80003450:	00950733          	add	a4,a0,s1
    80003454:	05874703          	lbu	a4,88(a4)
    80003458:	00e7f6b3          	and	a3,a5,a4
    8000345c:	c69d                	beqz	a3,8000348a <bfree+0x6c>
    8000345e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003460:	94aa                	add	s1,s1,a0
    80003462:	fff7c793          	not	a5,a5
    80003466:	8f7d                	and	a4,a4,a5
    80003468:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000346c:	00001097          	auipc	ra,0x1
    80003470:	126080e7          	jalr	294(ra) # 80004592 <log_write>
  brelse(bp);
    80003474:	854a                	mv	a0,s2
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	e92080e7          	jalr	-366(ra) # 80003308 <brelse>
}
    8000347e:	60e2                	ld	ra,24(sp)
    80003480:	6442                	ld	s0,16(sp)
    80003482:	64a2                	ld	s1,8(sp)
    80003484:	6902                	ld	s2,0(sp)
    80003486:	6105                	addi	sp,sp,32
    80003488:	8082                	ret
    panic("freeing free block");
    8000348a:	00005517          	auipc	a0,0x5
    8000348e:	0ce50513          	addi	a0,a0,206 # 80008558 <syscalls+0x108>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	0ae080e7          	jalr	174(ra) # 80000540 <panic>

000000008000349a <balloc>:
{
    8000349a:	711d                	addi	sp,sp,-96
    8000349c:	ec86                	sd	ra,88(sp)
    8000349e:	e8a2                	sd	s0,80(sp)
    800034a0:	e4a6                	sd	s1,72(sp)
    800034a2:	e0ca                	sd	s2,64(sp)
    800034a4:	fc4e                	sd	s3,56(sp)
    800034a6:	f852                	sd	s4,48(sp)
    800034a8:	f456                	sd	s5,40(sp)
    800034aa:	f05a                	sd	s6,32(sp)
    800034ac:	ec5e                	sd	s7,24(sp)
    800034ae:	e862                	sd	s8,16(sp)
    800034b0:	e466                	sd	s9,8(sp)
    800034b2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034b4:	00023797          	auipc	a5,0x23
    800034b8:	dc87a783          	lw	a5,-568(a5) # 8002627c <sb+0x4>
    800034bc:	cff5                	beqz	a5,800035b8 <balloc+0x11e>
    800034be:	8baa                	mv	s7,a0
    800034c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034c2:	00023b17          	auipc	s6,0x23
    800034c6:	db6b0b13          	addi	s6,s6,-586 # 80026278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034d0:	6c89                	lui	s9,0x2
    800034d2:	a061                	j	8000355a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034d4:	97ca                	add	a5,a5,s2
    800034d6:	8e55                	or	a2,a2,a3
    800034d8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034dc:	854a                	mv	a0,s2
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	0b4080e7          	jalr	180(ra) # 80004592 <log_write>
        brelse(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	e20080e7          	jalr	-480(ra) # 80003308 <brelse>
  bp = bread(dev, bno);
    800034f0:	85a6                	mv	a1,s1
    800034f2:	855e                	mv	a0,s7
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	ce4080e7          	jalr	-796(ra) # 800031d8 <bread>
    800034fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034fe:	40000613          	li	a2,1024
    80003502:	4581                	li	a1,0
    80003504:	05850513          	addi	a0,a0,88
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	7ca080e7          	jalr	1994(ra) # 80000cd2 <memset>
  log_write(bp);
    80003510:	854a                	mv	a0,s2
    80003512:	00001097          	auipc	ra,0x1
    80003516:	080080e7          	jalr	128(ra) # 80004592 <log_write>
  brelse(bp);
    8000351a:	854a                	mv	a0,s2
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	dec080e7          	jalr	-532(ra) # 80003308 <brelse>
}
    80003524:	8526                	mv	a0,s1
    80003526:	60e6                	ld	ra,88(sp)
    80003528:	6446                	ld	s0,80(sp)
    8000352a:	64a6                	ld	s1,72(sp)
    8000352c:	6906                	ld	s2,64(sp)
    8000352e:	79e2                	ld	s3,56(sp)
    80003530:	7a42                	ld	s4,48(sp)
    80003532:	7aa2                	ld	s5,40(sp)
    80003534:	7b02                	ld	s6,32(sp)
    80003536:	6be2                	ld	s7,24(sp)
    80003538:	6c42                	ld	s8,16(sp)
    8000353a:	6ca2                	ld	s9,8(sp)
    8000353c:	6125                	addi	sp,sp,96
    8000353e:	8082                	ret
    brelse(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00000097          	auipc	ra,0x0
    80003546:	dc6080e7          	jalr	-570(ra) # 80003308 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000354a:	015c87bb          	addw	a5,s9,s5
    8000354e:	00078a9b          	sext.w	s5,a5
    80003552:	004b2703          	lw	a4,4(s6)
    80003556:	06eaf163          	bgeu	s5,a4,800035b8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000355a:	41fad79b          	sraiw	a5,s5,0x1f
    8000355e:	0137d79b          	srliw	a5,a5,0x13
    80003562:	015787bb          	addw	a5,a5,s5
    80003566:	40d7d79b          	sraiw	a5,a5,0xd
    8000356a:	01cb2583          	lw	a1,28(s6)
    8000356e:	9dbd                	addw	a1,a1,a5
    80003570:	855e                	mv	a0,s7
    80003572:	00000097          	auipc	ra,0x0
    80003576:	c66080e7          	jalr	-922(ra) # 800031d8 <bread>
    8000357a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000357c:	004b2503          	lw	a0,4(s6)
    80003580:	000a849b          	sext.w	s1,s5
    80003584:	8762                	mv	a4,s8
    80003586:	faa4fde3          	bgeu	s1,a0,80003540 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000358a:	00777693          	andi	a3,a4,7
    8000358e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003592:	41f7579b          	sraiw	a5,a4,0x1f
    80003596:	01d7d79b          	srliw	a5,a5,0x1d
    8000359a:	9fb9                	addw	a5,a5,a4
    8000359c:	4037d79b          	sraiw	a5,a5,0x3
    800035a0:	00f90633          	add	a2,s2,a5
    800035a4:	05864603          	lbu	a2,88(a2)
    800035a8:	00c6f5b3          	and	a1,a3,a2
    800035ac:	d585                	beqz	a1,800034d4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ae:	2705                	addiw	a4,a4,1
    800035b0:	2485                	addiw	s1,s1,1
    800035b2:	fd471ae3          	bne	a4,s4,80003586 <balloc+0xec>
    800035b6:	b769                	j	80003540 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	fb850513          	addi	a0,a0,-72 # 80008570 <syscalls+0x120>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	fca080e7          	jalr	-54(ra) # 8000058a <printf>
  return 0;
    800035c8:	4481                	li	s1,0
    800035ca:	bfa9                	j	80003524 <balloc+0x8a>

00000000800035cc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035cc:	7179                	addi	sp,sp,-48
    800035ce:	f406                	sd	ra,40(sp)
    800035d0:	f022                	sd	s0,32(sp)
    800035d2:	ec26                	sd	s1,24(sp)
    800035d4:	e84a                	sd	s2,16(sp)
    800035d6:	e44e                	sd	s3,8(sp)
    800035d8:	e052                	sd	s4,0(sp)
    800035da:	1800                	addi	s0,sp,48
    800035dc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035de:	47ad                	li	a5,11
    800035e0:	02b7e863          	bltu	a5,a1,80003610 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035e4:	02059793          	slli	a5,a1,0x20
    800035e8:	01e7d593          	srli	a1,a5,0x1e
    800035ec:	00b504b3          	add	s1,a0,a1
    800035f0:	0504a903          	lw	s2,80(s1)
    800035f4:	06091e63          	bnez	s2,80003670 <bmap+0xa4>
      addr = balloc(ip->dev);
    800035f8:	4108                	lw	a0,0(a0)
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	ea0080e7          	jalr	-352(ra) # 8000349a <balloc>
    80003602:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003606:	06090563          	beqz	s2,80003670 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000360a:	0524a823          	sw	s2,80(s1)
    8000360e:	a08d                	j	80003670 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003610:	ff45849b          	addiw	s1,a1,-12
    80003614:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003618:	0ff00793          	li	a5,255
    8000361c:	08e7e563          	bltu	a5,a4,800036a6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003620:	08052903          	lw	s2,128(a0)
    80003624:	00091d63          	bnez	s2,8000363e <bmap+0x72>
      addr = balloc(ip->dev);
    80003628:	4108                	lw	a0,0(a0)
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	e70080e7          	jalr	-400(ra) # 8000349a <balloc>
    80003632:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003636:	02090d63          	beqz	s2,80003670 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000363a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000363e:	85ca                	mv	a1,s2
    80003640:	0009a503          	lw	a0,0(s3)
    80003644:	00000097          	auipc	ra,0x0
    80003648:	b94080e7          	jalr	-1132(ra) # 800031d8 <bread>
    8000364c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000364e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003652:	02049713          	slli	a4,s1,0x20
    80003656:	01e75593          	srli	a1,a4,0x1e
    8000365a:	00b784b3          	add	s1,a5,a1
    8000365e:	0004a903          	lw	s2,0(s1)
    80003662:	02090063          	beqz	s2,80003682 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003666:	8552                	mv	a0,s4
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	ca0080e7          	jalr	-864(ra) # 80003308 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003670:	854a                	mv	a0,s2
    80003672:	70a2                	ld	ra,40(sp)
    80003674:	7402                	ld	s0,32(sp)
    80003676:	64e2                	ld	s1,24(sp)
    80003678:	6942                	ld	s2,16(sp)
    8000367a:	69a2                	ld	s3,8(sp)
    8000367c:	6a02                	ld	s4,0(sp)
    8000367e:	6145                	addi	sp,sp,48
    80003680:	8082                	ret
      addr = balloc(ip->dev);
    80003682:	0009a503          	lw	a0,0(s3)
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	e14080e7          	jalr	-492(ra) # 8000349a <balloc>
    8000368e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003692:	fc090ae3          	beqz	s2,80003666 <bmap+0x9a>
        a[bn] = addr;
    80003696:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000369a:	8552                	mv	a0,s4
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	ef6080e7          	jalr	-266(ra) # 80004592 <log_write>
    800036a4:	b7c9                	j	80003666 <bmap+0x9a>
  panic("bmap: out of range");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	ee250513          	addi	a0,a0,-286 # 80008588 <syscalls+0x138>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	e92080e7          	jalr	-366(ra) # 80000540 <panic>

00000000800036b6 <iget>:
{
    800036b6:	7179                	addi	sp,sp,-48
    800036b8:	f406                	sd	ra,40(sp)
    800036ba:	f022                	sd	s0,32(sp)
    800036bc:	ec26                	sd	s1,24(sp)
    800036be:	e84a                	sd	s2,16(sp)
    800036c0:	e44e                	sd	s3,8(sp)
    800036c2:	e052                	sd	s4,0(sp)
    800036c4:	1800                	addi	s0,sp,48
    800036c6:	89aa                	mv	s3,a0
    800036c8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036ca:	00023517          	auipc	a0,0x23
    800036ce:	bce50513          	addi	a0,a0,-1074 # 80026298 <itable>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	504080e7          	jalr	1284(ra) # 80000bd6 <acquire>
  empty = 0;
    800036da:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036dc:	00023497          	auipc	s1,0x23
    800036e0:	bd448493          	addi	s1,s1,-1068 # 800262b0 <itable+0x18>
    800036e4:	00024697          	auipc	a3,0x24
    800036e8:	65c68693          	addi	a3,a3,1628 # 80027d40 <log>
    800036ec:	a039                	j	800036fa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ee:	02090b63          	beqz	s2,80003724 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036f2:	08848493          	addi	s1,s1,136
    800036f6:	02d48a63          	beq	s1,a3,8000372a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036fa:	449c                	lw	a5,8(s1)
    800036fc:	fef059e3          	blez	a5,800036ee <iget+0x38>
    80003700:	4098                	lw	a4,0(s1)
    80003702:	ff3716e3          	bne	a4,s3,800036ee <iget+0x38>
    80003706:	40d8                	lw	a4,4(s1)
    80003708:	ff4713e3          	bne	a4,s4,800036ee <iget+0x38>
      ip->ref++;
    8000370c:	2785                	addiw	a5,a5,1
    8000370e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003710:	00023517          	auipc	a0,0x23
    80003714:	b8850513          	addi	a0,a0,-1144 # 80026298 <itable>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	572080e7          	jalr	1394(ra) # 80000c8a <release>
      return ip;
    80003720:	8926                	mv	s2,s1
    80003722:	a03d                	j	80003750 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003724:	f7f9                	bnez	a5,800036f2 <iget+0x3c>
    80003726:	8926                	mv	s2,s1
    80003728:	b7e9                	j	800036f2 <iget+0x3c>
  if(empty == 0)
    8000372a:	02090c63          	beqz	s2,80003762 <iget+0xac>
  ip->dev = dev;
    8000372e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003732:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003736:	4785                	li	a5,1
    80003738:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000373c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003740:	00023517          	auipc	a0,0x23
    80003744:	b5850513          	addi	a0,a0,-1192 # 80026298 <itable>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	542080e7          	jalr	1346(ra) # 80000c8a <release>
}
    80003750:	854a                	mv	a0,s2
    80003752:	70a2                	ld	ra,40(sp)
    80003754:	7402                	ld	s0,32(sp)
    80003756:	64e2                	ld	s1,24(sp)
    80003758:	6942                	ld	s2,16(sp)
    8000375a:	69a2                	ld	s3,8(sp)
    8000375c:	6a02                	ld	s4,0(sp)
    8000375e:	6145                	addi	sp,sp,48
    80003760:	8082                	ret
    panic("iget: no inodes");
    80003762:	00005517          	auipc	a0,0x5
    80003766:	e3e50513          	addi	a0,a0,-450 # 800085a0 <syscalls+0x150>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	dd6080e7          	jalr	-554(ra) # 80000540 <panic>

0000000080003772 <fsinit>:
fsinit(int dev) {
    80003772:	7179                	addi	sp,sp,-48
    80003774:	f406                	sd	ra,40(sp)
    80003776:	f022                	sd	s0,32(sp)
    80003778:	ec26                	sd	s1,24(sp)
    8000377a:	e84a                	sd	s2,16(sp)
    8000377c:	e44e                	sd	s3,8(sp)
    8000377e:	1800                	addi	s0,sp,48
    80003780:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003782:	4585                	li	a1,1
    80003784:	00000097          	auipc	ra,0x0
    80003788:	a54080e7          	jalr	-1452(ra) # 800031d8 <bread>
    8000378c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000378e:	00023997          	auipc	s3,0x23
    80003792:	aea98993          	addi	s3,s3,-1302 # 80026278 <sb>
    80003796:	02000613          	li	a2,32
    8000379a:	05850593          	addi	a1,a0,88
    8000379e:	854e                	mv	a0,s3
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	58e080e7          	jalr	1422(ra) # 80000d2e <memmove>
  brelse(bp);
    800037a8:	8526                	mv	a0,s1
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	b5e080e7          	jalr	-1186(ra) # 80003308 <brelse>
  if(sb.magic != FSMAGIC)
    800037b2:	0009a703          	lw	a4,0(s3)
    800037b6:	102037b7          	lui	a5,0x10203
    800037ba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037be:	02f71263          	bne	a4,a5,800037e2 <fsinit+0x70>
  initlog(dev, &sb);
    800037c2:	00023597          	auipc	a1,0x23
    800037c6:	ab658593          	addi	a1,a1,-1354 # 80026278 <sb>
    800037ca:	854a                	mv	a0,s2
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	b4a080e7          	jalr	-1206(ra) # 80004316 <initlog>
}
    800037d4:	70a2                	ld	ra,40(sp)
    800037d6:	7402                	ld	s0,32(sp)
    800037d8:	64e2                	ld	s1,24(sp)
    800037da:	6942                	ld	s2,16(sp)
    800037dc:	69a2                	ld	s3,8(sp)
    800037de:	6145                	addi	sp,sp,48
    800037e0:	8082                	ret
    panic("invalid file system");
    800037e2:	00005517          	auipc	a0,0x5
    800037e6:	dce50513          	addi	a0,a0,-562 # 800085b0 <syscalls+0x160>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	d56080e7          	jalr	-682(ra) # 80000540 <panic>

00000000800037f2 <iinit>:
{
    800037f2:	7179                	addi	sp,sp,-48
    800037f4:	f406                	sd	ra,40(sp)
    800037f6:	f022                	sd	s0,32(sp)
    800037f8:	ec26                	sd	s1,24(sp)
    800037fa:	e84a                	sd	s2,16(sp)
    800037fc:	e44e                	sd	s3,8(sp)
    800037fe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003800:	00005597          	auipc	a1,0x5
    80003804:	dc858593          	addi	a1,a1,-568 # 800085c8 <syscalls+0x178>
    80003808:	00023517          	auipc	a0,0x23
    8000380c:	a9050513          	addi	a0,a0,-1392 # 80026298 <itable>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	336080e7          	jalr	822(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003818:	00023497          	auipc	s1,0x23
    8000381c:	aa848493          	addi	s1,s1,-1368 # 800262c0 <itable+0x28>
    80003820:	00024997          	auipc	s3,0x24
    80003824:	53098993          	addi	s3,s3,1328 # 80027d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003828:	00005917          	auipc	s2,0x5
    8000382c:	da890913          	addi	s2,s2,-600 # 800085d0 <syscalls+0x180>
    80003830:	85ca                	mv	a1,s2
    80003832:	8526                	mv	a0,s1
    80003834:	00001097          	auipc	ra,0x1
    80003838:	e42080e7          	jalr	-446(ra) # 80004676 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000383c:	08848493          	addi	s1,s1,136
    80003840:	ff3498e3          	bne	s1,s3,80003830 <iinit+0x3e>
}
    80003844:	70a2                	ld	ra,40(sp)
    80003846:	7402                	ld	s0,32(sp)
    80003848:	64e2                	ld	s1,24(sp)
    8000384a:	6942                	ld	s2,16(sp)
    8000384c:	69a2                	ld	s3,8(sp)
    8000384e:	6145                	addi	sp,sp,48
    80003850:	8082                	ret

0000000080003852 <ialloc>:
{
    80003852:	715d                	addi	sp,sp,-80
    80003854:	e486                	sd	ra,72(sp)
    80003856:	e0a2                	sd	s0,64(sp)
    80003858:	fc26                	sd	s1,56(sp)
    8000385a:	f84a                	sd	s2,48(sp)
    8000385c:	f44e                	sd	s3,40(sp)
    8000385e:	f052                	sd	s4,32(sp)
    80003860:	ec56                	sd	s5,24(sp)
    80003862:	e85a                	sd	s6,16(sp)
    80003864:	e45e                	sd	s7,8(sp)
    80003866:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003868:	00023717          	auipc	a4,0x23
    8000386c:	a1c72703          	lw	a4,-1508(a4) # 80026284 <sb+0xc>
    80003870:	4785                	li	a5,1
    80003872:	04e7fa63          	bgeu	a5,a4,800038c6 <ialloc+0x74>
    80003876:	8aaa                	mv	s5,a0
    80003878:	8bae                	mv	s7,a1
    8000387a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000387c:	00023a17          	auipc	s4,0x23
    80003880:	9fca0a13          	addi	s4,s4,-1540 # 80026278 <sb>
    80003884:	00048b1b          	sext.w	s6,s1
    80003888:	0044d593          	srli	a1,s1,0x4
    8000388c:	018a2783          	lw	a5,24(s4)
    80003890:	9dbd                	addw	a1,a1,a5
    80003892:	8556                	mv	a0,s5
    80003894:	00000097          	auipc	ra,0x0
    80003898:	944080e7          	jalr	-1724(ra) # 800031d8 <bread>
    8000389c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000389e:	05850993          	addi	s3,a0,88
    800038a2:	00f4f793          	andi	a5,s1,15
    800038a6:	079a                	slli	a5,a5,0x6
    800038a8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038aa:	00099783          	lh	a5,0(s3)
    800038ae:	c3a1                	beqz	a5,800038ee <ialloc+0x9c>
    brelse(bp);
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	a58080e7          	jalr	-1448(ra) # 80003308 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038b8:	0485                	addi	s1,s1,1
    800038ba:	00ca2703          	lw	a4,12(s4)
    800038be:	0004879b          	sext.w	a5,s1
    800038c2:	fce7e1e3          	bltu	a5,a4,80003884 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038c6:	00005517          	auipc	a0,0x5
    800038ca:	d1250513          	addi	a0,a0,-750 # 800085d8 <syscalls+0x188>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	cbc080e7          	jalr	-836(ra) # 8000058a <printf>
  return 0;
    800038d6:	4501                	li	a0,0
}
    800038d8:	60a6                	ld	ra,72(sp)
    800038da:	6406                	ld	s0,64(sp)
    800038dc:	74e2                	ld	s1,56(sp)
    800038de:	7942                	ld	s2,48(sp)
    800038e0:	79a2                	ld	s3,40(sp)
    800038e2:	7a02                	ld	s4,32(sp)
    800038e4:	6ae2                	ld	s5,24(sp)
    800038e6:	6b42                	ld	s6,16(sp)
    800038e8:	6ba2                	ld	s7,8(sp)
    800038ea:	6161                	addi	sp,sp,80
    800038ec:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038ee:	04000613          	li	a2,64
    800038f2:	4581                	li	a1,0
    800038f4:	854e                	mv	a0,s3
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	3dc080e7          	jalr	988(ra) # 80000cd2 <memset>
      dip->type = type;
    800038fe:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003902:	854a                	mv	a0,s2
    80003904:	00001097          	auipc	ra,0x1
    80003908:	c8e080e7          	jalr	-882(ra) # 80004592 <log_write>
      brelse(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	9fa080e7          	jalr	-1542(ra) # 80003308 <brelse>
      return iget(dev, inum);
    80003916:	85da                	mv	a1,s6
    80003918:	8556                	mv	a0,s5
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	d9c080e7          	jalr	-612(ra) # 800036b6 <iget>
    80003922:	bf5d                	j	800038d8 <ialloc+0x86>

0000000080003924 <iupdate>:
{
    80003924:	1101                	addi	sp,sp,-32
    80003926:	ec06                	sd	ra,24(sp)
    80003928:	e822                	sd	s0,16(sp)
    8000392a:	e426                	sd	s1,8(sp)
    8000392c:	e04a                	sd	s2,0(sp)
    8000392e:	1000                	addi	s0,sp,32
    80003930:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003932:	415c                	lw	a5,4(a0)
    80003934:	0047d79b          	srliw	a5,a5,0x4
    80003938:	00023597          	auipc	a1,0x23
    8000393c:	9585a583          	lw	a1,-1704(a1) # 80026290 <sb+0x18>
    80003940:	9dbd                	addw	a1,a1,a5
    80003942:	4108                	lw	a0,0(a0)
    80003944:	00000097          	auipc	ra,0x0
    80003948:	894080e7          	jalr	-1900(ra) # 800031d8 <bread>
    8000394c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000394e:	05850793          	addi	a5,a0,88
    80003952:	40d8                	lw	a4,4(s1)
    80003954:	8b3d                	andi	a4,a4,15
    80003956:	071a                	slli	a4,a4,0x6
    80003958:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000395a:	04449703          	lh	a4,68(s1)
    8000395e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003962:	04649703          	lh	a4,70(s1)
    80003966:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000396a:	04849703          	lh	a4,72(s1)
    8000396e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003972:	04a49703          	lh	a4,74(s1)
    80003976:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000397a:	44f8                	lw	a4,76(s1)
    8000397c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000397e:	03400613          	li	a2,52
    80003982:	05048593          	addi	a1,s1,80
    80003986:	00c78513          	addi	a0,a5,12
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	3a4080e7          	jalr	932(ra) # 80000d2e <memmove>
  log_write(bp);
    80003992:	854a                	mv	a0,s2
    80003994:	00001097          	auipc	ra,0x1
    80003998:	bfe080e7          	jalr	-1026(ra) # 80004592 <log_write>
  brelse(bp);
    8000399c:	854a                	mv	a0,s2
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	96a080e7          	jalr	-1686(ra) # 80003308 <brelse>
}
    800039a6:	60e2                	ld	ra,24(sp)
    800039a8:	6442                	ld	s0,16(sp)
    800039aa:	64a2                	ld	s1,8(sp)
    800039ac:	6902                	ld	s2,0(sp)
    800039ae:	6105                	addi	sp,sp,32
    800039b0:	8082                	ret

00000000800039b2 <idup>:
{
    800039b2:	1101                	addi	sp,sp,-32
    800039b4:	ec06                	sd	ra,24(sp)
    800039b6:	e822                	sd	s0,16(sp)
    800039b8:	e426                	sd	s1,8(sp)
    800039ba:	1000                	addi	s0,sp,32
    800039bc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039be:	00023517          	auipc	a0,0x23
    800039c2:	8da50513          	addi	a0,a0,-1830 # 80026298 <itable>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039ce:	449c                	lw	a5,8(s1)
    800039d0:	2785                	addiw	a5,a5,1
    800039d2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039d4:	00023517          	auipc	a0,0x23
    800039d8:	8c450513          	addi	a0,a0,-1852 # 80026298 <itable>
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	2ae080e7          	jalr	686(ra) # 80000c8a <release>
}
    800039e4:	8526                	mv	a0,s1
    800039e6:	60e2                	ld	ra,24(sp)
    800039e8:	6442                	ld	s0,16(sp)
    800039ea:	64a2                	ld	s1,8(sp)
    800039ec:	6105                	addi	sp,sp,32
    800039ee:	8082                	ret

00000000800039f0 <ilock>:
{
    800039f0:	1101                	addi	sp,sp,-32
    800039f2:	ec06                	sd	ra,24(sp)
    800039f4:	e822                	sd	s0,16(sp)
    800039f6:	e426                	sd	s1,8(sp)
    800039f8:	e04a                	sd	s2,0(sp)
    800039fa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039fc:	c115                	beqz	a0,80003a20 <ilock+0x30>
    800039fe:	84aa                	mv	s1,a0
    80003a00:	451c                	lw	a5,8(a0)
    80003a02:	00f05f63          	blez	a5,80003a20 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a06:	0541                	addi	a0,a0,16
    80003a08:	00001097          	auipc	ra,0x1
    80003a0c:	ca8080e7          	jalr	-856(ra) # 800046b0 <acquiresleep>
  if(ip->valid == 0){
    80003a10:	40bc                	lw	a5,64(s1)
    80003a12:	cf99                	beqz	a5,80003a30 <ilock+0x40>
}
    80003a14:	60e2                	ld	ra,24(sp)
    80003a16:	6442                	ld	s0,16(sp)
    80003a18:	64a2                	ld	s1,8(sp)
    80003a1a:	6902                	ld	s2,0(sp)
    80003a1c:	6105                	addi	sp,sp,32
    80003a1e:	8082                	ret
    panic("ilock");
    80003a20:	00005517          	auipc	a0,0x5
    80003a24:	bd050513          	addi	a0,a0,-1072 # 800085f0 <syscalls+0x1a0>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	b18080e7          	jalr	-1256(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a30:	40dc                	lw	a5,4(s1)
    80003a32:	0047d79b          	srliw	a5,a5,0x4
    80003a36:	00023597          	auipc	a1,0x23
    80003a3a:	85a5a583          	lw	a1,-1958(a1) # 80026290 <sb+0x18>
    80003a3e:	9dbd                	addw	a1,a1,a5
    80003a40:	4088                	lw	a0,0(s1)
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	796080e7          	jalr	1942(ra) # 800031d8 <bread>
    80003a4a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a4c:	05850593          	addi	a1,a0,88
    80003a50:	40dc                	lw	a5,4(s1)
    80003a52:	8bbd                	andi	a5,a5,15
    80003a54:	079a                	slli	a5,a5,0x6
    80003a56:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a58:	00059783          	lh	a5,0(a1)
    80003a5c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a60:	00259783          	lh	a5,2(a1)
    80003a64:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a68:	00459783          	lh	a5,4(a1)
    80003a6c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a70:	00659783          	lh	a5,6(a1)
    80003a74:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a78:	459c                	lw	a5,8(a1)
    80003a7a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a7c:	03400613          	li	a2,52
    80003a80:	05b1                	addi	a1,a1,12
    80003a82:	05048513          	addi	a0,s1,80
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	2a8080e7          	jalr	680(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	878080e7          	jalr	-1928(ra) # 80003308 <brelse>
    ip->valid = 1;
    80003a98:	4785                	li	a5,1
    80003a9a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a9c:	04449783          	lh	a5,68(s1)
    80003aa0:	fbb5                	bnez	a5,80003a14 <ilock+0x24>
      panic("ilock: no type");
    80003aa2:	00005517          	auipc	a0,0x5
    80003aa6:	b5650513          	addi	a0,a0,-1194 # 800085f8 <syscalls+0x1a8>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	a96080e7          	jalr	-1386(ra) # 80000540 <panic>

0000000080003ab2 <iunlock>:
{
    80003ab2:	1101                	addi	sp,sp,-32
    80003ab4:	ec06                	sd	ra,24(sp)
    80003ab6:	e822                	sd	s0,16(sp)
    80003ab8:	e426                	sd	s1,8(sp)
    80003aba:	e04a                	sd	s2,0(sp)
    80003abc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003abe:	c905                	beqz	a0,80003aee <iunlock+0x3c>
    80003ac0:	84aa                	mv	s1,a0
    80003ac2:	01050913          	addi	s2,a0,16
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	00001097          	auipc	ra,0x1
    80003acc:	c82080e7          	jalr	-894(ra) # 8000474a <holdingsleep>
    80003ad0:	cd19                	beqz	a0,80003aee <iunlock+0x3c>
    80003ad2:	449c                	lw	a5,8(s1)
    80003ad4:	00f05d63          	blez	a5,80003aee <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ad8:	854a                	mv	a0,s2
    80003ada:	00001097          	auipc	ra,0x1
    80003ade:	c2c080e7          	jalr	-980(ra) # 80004706 <releasesleep>
}
    80003ae2:	60e2                	ld	ra,24(sp)
    80003ae4:	6442                	ld	s0,16(sp)
    80003ae6:	64a2                	ld	s1,8(sp)
    80003ae8:	6902                	ld	s2,0(sp)
    80003aea:	6105                	addi	sp,sp,32
    80003aec:	8082                	ret
    panic("iunlock");
    80003aee:	00005517          	auipc	a0,0x5
    80003af2:	b1a50513          	addi	a0,a0,-1254 # 80008608 <syscalls+0x1b8>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	a4a080e7          	jalr	-1462(ra) # 80000540 <panic>

0000000080003afe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003afe:	7179                	addi	sp,sp,-48
    80003b00:	f406                	sd	ra,40(sp)
    80003b02:	f022                	sd	s0,32(sp)
    80003b04:	ec26                	sd	s1,24(sp)
    80003b06:	e84a                	sd	s2,16(sp)
    80003b08:	e44e                	sd	s3,8(sp)
    80003b0a:	e052                	sd	s4,0(sp)
    80003b0c:	1800                	addi	s0,sp,48
    80003b0e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b10:	05050493          	addi	s1,a0,80
    80003b14:	08050913          	addi	s2,a0,128
    80003b18:	a021                	j	80003b20 <itrunc+0x22>
    80003b1a:	0491                	addi	s1,s1,4
    80003b1c:	01248d63          	beq	s1,s2,80003b36 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b20:	408c                	lw	a1,0(s1)
    80003b22:	dde5                	beqz	a1,80003b1a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b24:	0009a503          	lw	a0,0(s3)
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	8f6080e7          	jalr	-1802(ra) # 8000341e <bfree>
      ip->addrs[i] = 0;
    80003b30:	0004a023          	sw	zero,0(s1)
    80003b34:	b7dd                	j	80003b1a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b36:	0809a583          	lw	a1,128(s3)
    80003b3a:	e185                	bnez	a1,80003b5a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b3c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b40:	854e                	mv	a0,s3
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	de2080e7          	jalr	-542(ra) # 80003924 <iupdate>
}
    80003b4a:	70a2                	ld	ra,40(sp)
    80003b4c:	7402                	ld	s0,32(sp)
    80003b4e:	64e2                	ld	s1,24(sp)
    80003b50:	6942                	ld	s2,16(sp)
    80003b52:	69a2                	ld	s3,8(sp)
    80003b54:	6a02                	ld	s4,0(sp)
    80003b56:	6145                	addi	sp,sp,48
    80003b58:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b5a:	0009a503          	lw	a0,0(s3)
    80003b5e:	fffff097          	auipc	ra,0xfffff
    80003b62:	67a080e7          	jalr	1658(ra) # 800031d8 <bread>
    80003b66:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b68:	05850493          	addi	s1,a0,88
    80003b6c:	45850913          	addi	s2,a0,1112
    80003b70:	a021                	j	80003b78 <itrunc+0x7a>
    80003b72:	0491                	addi	s1,s1,4
    80003b74:	01248b63          	beq	s1,s2,80003b8a <itrunc+0x8c>
      if(a[j])
    80003b78:	408c                	lw	a1,0(s1)
    80003b7a:	dde5                	beqz	a1,80003b72 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b7c:	0009a503          	lw	a0,0(s3)
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	89e080e7          	jalr	-1890(ra) # 8000341e <bfree>
    80003b88:	b7ed                	j	80003b72 <itrunc+0x74>
    brelse(bp);
    80003b8a:	8552                	mv	a0,s4
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	77c080e7          	jalr	1916(ra) # 80003308 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b94:	0809a583          	lw	a1,128(s3)
    80003b98:	0009a503          	lw	a0,0(s3)
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	882080e7          	jalr	-1918(ra) # 8000341e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ba4:	0809a023          	sw	zero,128(s3)
    80003ba8:	bf51                	j	80003b3c <itrunc+0x3e>

0000000080003baa <iput>:
{
    80003baa:	1101                	addi	sp,sp,-32
    80003bac:	ec06                	sd	ra,24(sp)
    80003bae:	e822                	sd	s0,16(sp)
    80003bb0:	e426                	sd	s1,8(sp)
    80003bb2:	e04a                	sd	s2,0(sp)
    80003bb4:	1000                	addi	s0,sp,32
    80003bb6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bb8:	00022517          	auipc	a0,0x22
    80003bbc:	6e050513          	addi	a0,a0,1760 # 80026298 <itable>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	016080e7          	jalr	22(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc8:	4498                	lw	a4,8(s1)
    80003bca:	4785                	li	a5,1
    80003bcc:	02f70363          	beq	a4,a5,80003bf2 <iput+0x48>
  ip->ref--;
    80003bd0:	449c                	lw	a5,8(s1)
    80003bd2:	37fd                	addiw	a5,a5,-1
    80003bd4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd6:	00022517          	auipc	a0,0x22
    80003bda:	6c250513          	addi	a0,a0,1730 # 80026298 <itable>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	0ac080e7          	jalr	172(ra) # 80000c8a <release>
}
    80003be6:	60e2                	ld	ra,24(sp)
    80003be8:	6442                	ld	s0,16(sp)
    80003bea:	64a2                	ld	s1,8(sp)
    80003bec:	6902                	ld	s2,0(sp)
    80003bee:	6105                	addi	sp,sp,32
    80003bf0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bf2:	40bc                	lw	a5,64(s1)
    80003bf4:	dff1                	beqz	a5,80003bd0 <iput+0x26>
    80003bf6:	04a49783          	lh	a5,74(s1)
    80003bfa:	fbf9                	bnez	a5,80003bd0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bfc:	01048913          	addi	s2,s1,16
    80003c00:	854a                	mv	a0,s2
    80003c02:	00001097          	auipc	ra,0x1
    80003c06:	aae080e7          	jalr	-1362(ra) # 800046b0 <acquiresleep>
    release(&itable.lock);
    80003c0a:	00022517          	auipc	a0,0x22
    80003c0e:	68e50513          	addi	a0,a0,1678 # 80026298 <itable>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	078080e7          	jalr	120(ra) # 80000c8a <release>
    itrunc(ip);
    80003c1a:	8526                	mv	a0,s1
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	ee2080e7          	jalr	-286(ra) # 80003afe <itrunc>
    ip->type = 0;
    80003c24:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c28:	8526                	mv	a0,s1
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	cfa080e7          	jalr	-774(ra) # 80003924 <iupdate>
    ip->valid = 0;
    80003c32:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c36:	854a                	mv	a0,s2
    80003c38:	00001097          	auipc	ra,0x1
    80003c3c:	ace080e7          	jalr	-1330(ra) # 80004706 <releasesleep>
    acquire(&itable.lock);
    80003c40:	00022517          	auipc	a0,0x22
    80003c44:	65850513          	addi	a0,a0,1624 # 80026298 <itable>
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	f8e080e7          	jalr	-114(ra) # 80000bd6 <acquire>
    80003c50:	b741                	j	80003bd0 <iput+0x26>

0000000080003c52 <iunlockput>:
{
    80003c52:	1101                	addi	sp,sp,-32
    80003c54:	ec06                	sd	ra,24(sp)
    80003c56:	e822                	sd	s0,16(sp)
    80003c58:	e426                	sd	s1,8(sp)
    80003c5a:	1000                	addi	s0,sp,32
    80003c5c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	e54080e7          	jalr	-428(ra) # 80003ab2 <iunlock>
  iput(ip);
    80003c66:	8526                	mv	a0,s1
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	f42080e7          	jalr	-190(ra) # 80003baa <iput>
}
    80003c70:	60e2                	ld	ra,24(sp)
    80003c72:	6442                	ld	s0,16(sp)
    80003c74:	64a2                	ld	s1,8(sp)
    80003c76:	6105                	addi	sp,sp,32
    80003c78:	8082                	ret

0000000080003c7a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c7a:	1141                	addi	sp,sp,-16
    80003c7c:	e422                	sd	s0,8(sp)
    80003c7e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c80:	411c                	lw	a5,0(a0)
    80003c82:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c84:	415c                	lw	a5,4(a0)
    80003c86:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c88:	04451783          	lh	a5,68(a0)
    80003c8c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c90:	04a51783          	lh	a5,74(a0)
    80003c94:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c98:	04c56783          	lwu	a5,76(a0)
    80003c9c:	e99c                	sd	a5,16(a1)
}
    80003c9e:	6422                	ld	s0,8(sp)
    80003ca0:	0141                	addi	sp,sp,16
    80003ca2:	8082                	ret

0000000080003ca4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ca4:	457c                	lw	a5,76(a0)
    80003ca6:	0ed7e963          	bltu	a5,a3,80003d98 <readi+0xf4>
{
    80003caa:	7159                	addi	sp,sp,-112
    80003cac:	f486                	sd	ra,104(sp)
    80003cae:	f0a2                	sd	s0,96(sp)
    80003cb0:	eca6                	sd	s1,88(sp)
    80003cb2:	e8ca                	sd	s2,80(sp)
    80003cb4:	e4ce                	sd	s3,72(sp)
    80003cb6:	e0d2                	sd	s4,64(sp)
    80003cb8:	fc56                	sd	s5,56(sp)
    80003cba:	f85a                	sd	s6,48(sp)
    80003cbc:	f45e                	sd	s7,40(sp)
    80003cbe:	f062                	sd	s8,32(sp)
    80003cc0:	ec66                	sd	s9,24(sp)
    80003cc2:	e86a                	sd	s10,16(sp)
    80003cc4:	e46e                	sd	s11,8(sp)
    80003cc6:	1880                	addi	s0,sp,112
    80003cc8:	8b2a                	mv	s6,a0
    80003cca:	8bae                	mv	s7,a1
    80003ccc:	8a32                	mv	s4,a2
    80003cce:	84b6                	mv	s1,a3
    80003cd0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003cd2:	9f35                	addw	a4,a4,a3
    return 0;
    80003cd4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cd6:	0ad76063          	bltu	a4,a3,80003d76 <readi+0xd2>
  if(off + n > ip->size)
    80003cda:	00e7f463          	bgeu	a5,a4,80003ce2 <readi+0x3e>
    n = ip->size - off;
    80003cde:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce2:	0a0a8963          	beqz	s5,80003d94 <readi+0xf0>
    80003ce6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cec:	5c7d                	li	s8,-1
    80003cee:	a82d                	j	80003d28 <readi+0x84>
    80003cf0:	020d1d93          	slli	s11,s10,0x20
    80003cf4:	020ddd93          	srli	s11,s11,0x20
    80003cf8:	05890613          	addi	a2,s2,88
    80003cfc:	86ee                	mv	a3,s11
    80003cfe:	963a                	add	a2,a2,a4
    80003d00:	85d2                	mv	a1,s4
    80003d02:	855e                	mv	a0,s7
    80003d04:	ffffe097          	auipc	ra,0xffffe
    80003d08:	7a4080e7          	jalr	1956(ra) # 800024a8 <either_copyout>
    80003d0c:	05850d63          	beq	a0,s8,80003d66 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d10:	854a                	mv	a0,s2
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	5f6080e7          	jalr	1526(ra) # 80003308 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d1a:	013d09bb          	addw	s3,s10,s3
    80003d1e:	009d04bb          	addw	s1,s10,s1
    80003d22:	9a6e                	add	s4,s4,s11
    80003d24:	0559f763          	bgeu	s3,s5,80003d72 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d28:	00a4d59b          	srliw	a1,s1,0xa
    80003d2c:	855a                	mv	a0,s6
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	89e080e7          	jalr	-1890(ra) # 800035cc <bmap>
    80003d36:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d3a:	cd85                	beqz	a1,80003d72 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d3c:	000b2503          	lw	a0,0(s6)
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	498080e7          	jalr	1176(ra) # 800031d8 <bread>
    80003d48:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4a:	3ff4f713          	andi	a4,s1,1023
    80003d4e:	40ec87bb          	subw	a5,s9,a4
    80003d52:	413a86bb          	subw	a3,s5,s3
    80003d56:	8d3e                	mv	s10,a5
    80003d58:	2781                	sext.w	a5,a5
    80003d5a:	0006861b          	sext.w	a2,a3
    80003d5e:	f8f679e3          	bgeu	a2,a5,80003cf0 <readi+0x4c>
    80003d62:	8d36                	mv	s10,a3
    80003d64:	b771                	j	80003cf0 <readi+0x4c>
      brelse(bp);
    80003d66:	854a                	mv	a0,s2
    80003d68:	fffff097          	auipc	ra,0xfffff
    80003d6c:	5a0080e7          	jalr	1440(ra) # 80003308 <brelse>
      tot = -1;
    80003d70:	59fd                	li	s3,-1
  }
  return tot;
    80003d72:	0009851b          	sext.w	a0,s3
}
    80003d76:	70a6                	ld	ra,104(sp)
    80003d78:	7406                	ld	s0,96(sp)
    80003d7a:	64e6                	ld	s1,88(sp)
    80003d7c:	6946                	ld	s2,80(sp)
    80003d7e:	69a6                	ld	s3,72(sp)
    80003d80:	6a06                	ld	s4,64(sp)
    80003d82:	7ae2                	ld	s5,56(sp)
    80003d84:	7b42                	ld	s6,48(sp)
    80003d86:	7ba2                	ld	s7,40(sp)
    80003d88:	7c02                	ld	s8,32(sp)
    80003d8a:	6ce2                	ld	s9,24(sp)
    80003d8c:	6d42                	ld	s10,16(sp)
    80003d8e:	6da2                	ld	s11,8(sp)
    80003d90:	6165                	addi	sp,sp,112
    80003d92:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d94:	89d6                	mv	s3,s5
    80003d96:	bff1                	j	80003d72 <readi+0xce>
    return 0;
    80003d98:	4501                	li	a0,0
}
    80003d9a:	8082                	ret

0000000080003d9c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d9c:	457c                	lw	a5,76(a0)
    80003d9e:	10d7e863          	bltu	a5,a3,80003eae <writei+0x112>
{
    80003da2:	7159                	addi	sp,sp,-112
    80003da4:	f486                	sd	ra,104(sp)
    80003da6:	f0a2                	sd	s0,96(sp)
    80003da8:	eca6                	sd	s1,88(sp)
    80003daa:	e8ca                	sd	s2,80(sp)
    80003dac:	e4ce                	sd	s3,72(sp)
    80003dae:	e0d2                	sd	s4,64(sp)
    80003db0:	fc56                	sd	s5,56(sp)
    80003db2:	f85a                	sd	s6,48(sp)
    80003db4:	f45e                	sd	s7,40(sp)
    80003db6:	f062                	sd	s8,32(sp)
    80003db8:	ec66                	sd	s9,24(sp)
    80003dba:	e86a                	sd	s10,16(sp)
    80003dbc:	e46e                	sd	s11,8(sp)
    80003dbe:	1880                	addi	s0,sp,112
    80003dc0:	8aaa                	mv	s5,a0
    80003dc2:	8bae                	mv	s7,a1
    80003dc4:	8a32                	mv	s4,a2
    80003dc6:	8936                	mv	s2,a3
    80003dc8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dca:	00e687bb          	addw	a5,a3,a4
    80003dce:	0ed7e263          	bltu	a5,a3,80003eb2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dd2:	00043737          	lui	a4,0x43
    80003dd6:	0ef76063          	bltu	a4,a5,80003eb6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dda:	0c0b0863          	beqz	s6,80003eaa <writei+0x10e>
    80003dde:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003de4:	5c7d                	li	s8,-1
    80003de6:	a091                	j	80003e2a <writei+0x8e>
    80003de8:	020d1d93          	slli	s11,s10,0x20
    80003dec:	020ddd93          	srli	s11,s11,0x20
    80003df0:	05848513          	addi	a0,s1,88
    80003df4:	86ee                	mv	a3,s11
    80003df6:	8652                	mv	a2,s4
    80003df8:	85de                	mv	a1,s7
    80003dfa:	953a                	add	a0,a0,a4
    80003dfc:	ffffe097          	auipc	ra,0xffffe
    80003e00:	702080e7          	jalr	1794(ra) # 800024fe <either_copyin>
    80003e04:	07850263          	beq	a0,s8,80003e68 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	788080e7          	jalr	1928(ra) # 80004592 <log_write>
    brelse(bp);
    80003e12:	8526                	mv	a0,s1
    80003e14:	fffff097          	auipc	ra,0xfffff
    80003e18:	4f4080e7          	jalr	1268(ra) # 80003308 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e1c:	013d09bb          	addw	s3,s10,s3
    80003e20:	012d093b          	addw	s2,s10,s2
    80003e24:	9a6e                	add	s4,s4,s11
    80003e26:	0569f663          	bgeu	s3,s6,80003e72 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e2a:	00a9559b          	srliw	a1,s2,0xa
    80003e2e:	8556                	mv	a0,s5
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	79c080e7          	jalr	1948(ra) # 800035cc <bmap>
    80003e38:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e3c:	c99d                	beqz	a1,80003e72 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e3e:	000aa503          	lw	a0,0(s5)
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	396080e7          	jalr	918(ra) # 800031d8 <bread>
    80003e4a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e4c:	3ff97713          	andi	a4,s2,1023
    80003e50:	40ec87bb          	subw	a5,s9,a4
    80003e54:	413b06bb          	subw	a3,s6,s3
    80003e58:	8d3e                	mv	s10,a5
    80003e5a:	2781                	sext.w	a5,a5
    80003e5c:	0006861b          	sext.w	a2,a3
    80003e60:	f8f674e3          	bgeu	a2,a5,80003de8 <writei+0x4c>
    80003e64:	8d36                	mv	s10,a3
    80003e66:	b749                	j	80003de8 <writei+0x4c>
      brelse(bp);
    80003e68:	8526                	mv	a0,s1
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	49e080e7          	jalr	1182(ra) # 80003308 <brelse>
  }

  if(off > ip->size)
    80003e72:	04caa783          	lw	a5,76(s5)
    80003e76:	0127f463          	bgeu	a5,s2,80003e7e <writei+0xe2>
    ip->size = off;
    80003e7a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e7e:	8556                	mv	a0,s5
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	aa4080e7          	jalr	-1372(ra) # 80003924 <iupdate>

  return tot;
    80003e88:	0009851b          	sext.w	a0,s3
}
    80003e8c:	70a6                	ld	ra,104(sp)
    80003e8e:	7406                	ld	s0,96(sp)
    80003e90:	64e6                	ld	s1,88(sp)
    80003e92:	6946                	ld	s2,80(sp)
    80003e94:	69a6                	ld	s3,72(sp)
    80003e96:	6a06                	ld	s4,64(sp)
    80003e98:	7ae2                	ld	s5,56(sp)
    80003e9a:	7b42                	ld	s6,48(sp)
    80003e9c:	7ba2                	ld	s7,40(sp)
    80003e9e:	7c02                	ld	s8,32(sp)
    80003ea0:	6ce2                	ld	s9,24(sp)
    80003ea2:	6d42                	ld	s10,16(sp)
    80003ea4:	6da2                	ld	s11,8(sp)
    80003ea6:	6165                	addi	sp,sp,112
    80003ea8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eaa:	89da                	mv	s3,s6
    80003eac:	bfc9                	j	80003e7e <writei+0xe2>
    return -1;
    80003eae:	557d                	li	a0,-1
}
    80003eb0:	8082                	ret
    return -1;
    80003eb2:	557d                	li	a0,-1
    80003eb4:	bfe1                	j	80003e8c <writei+0xf0>
    return -1;
    80003eb6:	557d                	li	a0,-1
    80003eb8:	bfd1                	j	80003e8c <writei+0xf0>

0000000080003eba <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003eba:	1141                	addi	sp,sp,-16
    80003ebc:	e406                	sd	ra,8(sp)
    80003ebe:	e022                	sd	s0,0(sp)
    80003ec0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ec2:	4639                	li	a2,14
    80003ec4:	ffffd097          	auipc	ra,0xffffd
    80003ec8:	ede080e7          	jalr	-290(ra) # 80000da2 <strncmp>
}
    80003ecc:	60a2                	ld	ra,8(sp)
    80003ece:	6402                	ld	s0,0(sp)
    80003ed0:	0141                	addi	sp,sp,16
    80003ed2:	8082                	ret

0000000080003ed4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ed4:	7139                	addi	sp,sp,-64
    80003ed6:	fc06                	sd	ra,56(sp)
    80003ed8:	f822                	sd	s0,48(sp)
    80003eda:	f426                	sd	s1,40(sp)
    80003edc:	f04a                	sd	s2,32(sp)
    80003ede:	ec4e                	sd	s3,24(sp)
    80003ee0:	e852                	sd	s4,16(sp)
    80003ee2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ee4:	04451703          	lh	a4,68(a0)
    80003ee8:	4785                	li	a5,1
    80003eea:	00f71a63          	bne	a4,a5,80003efe <dirlookup+0x2a>
    80003eee:	892a                	mv	s2,a0
    80003ef0:	89ae                	mv	s3,a1
    80003ef2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	457c                	lw	a5,76(a0)
    80003ef6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ef8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efa:	e79d                	bnez	a5,80003f28 <dirlookup+0x54>
    80003efc:	a8a5                	j	80003f74 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003efe:	00004517          	auipc	a0,0x4
    80003f02:	71250513          	addi	a0,a0,1810 # 80008610 <syscalls+0x1c0>
    80003f06:	ffffc097          	auipc	ra,0xffffc
    80003f0a:	63a080e7          	jalr	1594(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003f0e:	00004517          	auipc	a0,0x4
    80003f12:	71a50513          	addi	a0,a0,1818 # 80008628 <syscalls+0x1d8>
    80003f16:	ffffc097          	auipc	ra,0xffffc
    80003f1a:	62a080e7          	jalr	1578(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1e:	24c1                	addiw	s1,s1,16
    80003f20:	04c92783          	lw	a5,76(s2)
    80003f24:	04f4f763          	bgeu	s1,a5,80003f72 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f28:	4741                	li	a4,16
    80003f2a:	86a6                	mv	a3,s1
    80003f2c:	fc040613          	addi	a2,s0,-64
    80003f30:	4581                	li	a1,0
    80003f32:	854a                	mv	a0,s2
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	d70080e7          	jalr	-656(ra) # 80003ca4 <readi>
    80003f3c:	47c1                	li	a5,16
    80003f3e:	fcf518e3          	bne	a0,a5,80003f0e <dirlookup+0x3a>
    if(de.inum == 0)
    80003f42:	fc045783          	lhu	a5,-64(s0)
    80003f46:	dfe1                	beqz	a5,80003f1e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f48:	fc240593          	addi	a1,s0,-62
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	f6c080e7          	jalr	-148(ra) # 80003eba <namecmp>
    80003f56:	f561                	bnez	a0,80003f1e <dirlookup+0x4a>
      if(poff)
    80003f58:	000a0463          	beqz	s4,80003f60 <dirlookup+0x8c>
        *poff = off;
    80003f5c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f60:	fc045583          	lhu	a1,-64(s0)
    80003f64:	00092503          	lw	a0,0(s2)
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	74e080e7          	jalr	1870(ra) # 800036b6 <iget>
    80003f70:	a011                	j	80003f74 <dirlookup+0xa0>
  return 0;
    80003f72:	4501                	li	a0,0
}
    80003f74:	70e2                	ld	ra,56(sp)
    80003f76:	7442                	ld	s0,48(sp)
    80003f78:	74a2                	ld	s1,40(sp)
    80003f7a:	7902                	ld	s2,32(sp)
    80003f7c:	69e2                	ld	s3,24(sp)
    80003f7e:	6a42                	ld	s4,16(sp)
    80003f80:	6121                	addi	sp,sp,64
    80003f82:	8082                	ret

0000000080003f84 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f84:	711d                	addi	sp,sp,-96
    80003f86:	ec86                	sd	ra,88(sp)
    80003f88:	e8a2                	sd	s0,80(sp)
    80003f8a:	e4a6                	sd	s1,72(sp)
    80003f8c:	e0ca                	sd	s2,64(sp)
    80003f8e:	fc4e                	sd	s3,56(sp)
    80003f90:	f852                	sd	s4,48(sp)
    80003f92:	f456                	sd	s5,40(sp)
    80003f94:	f05a                	sd	s6,32(sp)
    80003f96:	ec5e                	sd	s7,24(sp)
    80003f98:	e862                	sd	s8,16(sp)
    80003f9a:	e466                	sd	s9,8(sp)
    80003f9c:	e06a                	sd	s10,0(sp)
    80003f9e:	1080                	addi	s0,sp,96
    80003fa0:	84aa                	mv	s1,a0
    80003fa2:	8b2e                	mv	s6,a1
    80003fa4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fa6:	00054703          	lbu	a4,0(a0)
    80003faa:	02f00793          	li	a5,47
    80003fae:	02f70363          	beq	a4,a5,80003fd4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fb2:	ffffe097          	auipc	ra,0xffffe
    80003fb6:	9fa080e7          	jalr	-1542(ra) # 800019ac <myproc>
    80003fba:	1d053503          	ld	a0,464(a0)
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	9f4080e7          	jalr	-1548(ra) # 800039b2 <idup>
    80003fc6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003fc8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003fcc:	4cb5                	li	s9,13
  len = path - s;
    80003fce:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fd0:	4c05                	li	s8,1
    80003fd2:	a87d                	j	80004090 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003fd4:	4585                	li	a1,1
    80003fd6:	4505                	li	a0,1
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	6de080e7          	jalr	1758(ra) # 800036b6 <iget>
    80003fe0:	8a2a                	mv	s4,a0
    80003fe2:	b7dd                	j	80003fc8 <namex+0x44>
      iunlockput(ip);
    80003fe4:	8552                	mv	a0,s4
    80003fe6:	00000097          	auipc	ra,0x0
    80003fea:	c6c080e7          	jalr	-916(ra) # 80003c52 <iunlockput>
      return 0;
    80003fee:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ff0:	8552                	mv	a0,s4
    80003ff2:	60e6                	ld	ra,88(sp)
    80003ff4:	6446                	ld	s0,80(sp)
    80003ff6:	64a6                	ld	s1,72(sp)
    80003ff8:	6906                	ld	s2,64(sp)
    80003ffa:	79e2                	ld	s3,56(sp)
    80003ffc:	7a42                	ld	s4,48(sp)
    80003ffe:	7aa2                	ld	s5,40(sp)
    80004000:	7b02                	ld	s6,32(sp)
    80004002:	6be2                	ld	s7,24(sp)
    80004004:	6c42                	ld	s8,16(sp)
    80004006:	6ca2                	ld	s9,8(sp)
    80004008:	6d02                	ld	s10,0(sp)
    8000400a:	6125                	addi	sp,sp,96
    8000400c:	8082                	ret
      iunlock(ip);
    8000400e:	8552                	mv	a0,s4
    80004010:	00000097          	auipc	ra,0x0
    80004014:	aa2080e7          	jalr	-1374(ra) # 80003ab2 <iunlock>
      return ip;
    80004018:	bfe1                	j	80003ff0 <namex+0x6c>
      iunlockput(ip);
    8000401a:	8552                	mv	a0,s4
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	c36080e7          	jalr	-970(ra) # 80003c52 <iunlockput>
      return 0;
    80004024:	8a4e                	mv	s4,s3
    80004026:	b7e9                	j	80003ff0 <namex+0x6c>
  len = path - s;
    80004028:	40998633          	sub	a2,s3,s1
    8000402c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004030:	09acd863          	bge	s9,s10,800040c0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004034:	4639                	li	a2,14
    80004036:	85a6                	mv	a1,s1
    80004038:	8556                	mv	a0,s5
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	cf4080e7          	jalr	-780(ra) # 80000d2e <memmove>
    80004042:	84ce                	mv	s1,s3
  while(*path == '/')
    80004044:	0004c783          	lbu	a5,0(s1)
    80004048:	01279763          	bne	a5,s2,80004056 <namex+0xd2>
    path++;
    8000404c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000404e:	0004c783          	lbu	a5,0(s1)
    80004052:	ff278de3          	beq	a5,s2,8000404c <namex+0xc8>
    ilock(ip);
    80004056:	8552                	mv	a0,s4
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	998080e7          	jalr	-1640(ra) # 800039f0 <ilock>
    if(ip->type != T_DIR){
    80004060:	044a1783          	lh	a5,68(s4)
    80004064:	f98790e3          	bne	a5,s8,80003fe4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004068:	000b0563          	beqz	s6,80004072 <namex+0xee>
    8000406c:	0004c783          	lbu	a5,0(s1)
    80004070:	dfd9                	beqz	a5,8000400e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004072:	865e                	mv	a2,s7
    80004074:	85d6                	mv	a1,s5
    80004076:	8552                	mv	a0,s4
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	e5c080e7          	jalr	-420(ra) # 80003ed4 <dirlookup>
    80004080:	89aa                	mv	s3,a0
    80004082:	dd41                	beqz	a0,8000401a <namex+0x96>
    iunlockput(ip);
    80004084:	8552                	mv	a0,s4
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	bcc080e7          	jalr	-1076(ra) # 80003c52 <iunlockput>
    ip = next;
    8000408e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004090:	0004c783          	lbu	a5,0(s1)
    80004094:	01279763          	bne	a5,s2,800040a2 <namex+0x11e>
    path++;
    80004098:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000409a:	0004c783          	lbu	a5,0(s1)
    8000409e:	ff278de3          	beq	a5,s2,80004098 <namex+0x114>
  if(*path == 0)
    800040a2:	cb9d                	beqz	a5,800040d8 <namex+0x154>
  while(*path != '/' && *path != 0)
    800040a4:	0004c783          	lbu	a5,0(s1)
    800040a8:	89a6                	mv	s3,s1
  len = path - s;
    800040aa:	8d5e                	mv	s10,s7
    800040ac:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040ae:	01278963          	beq	a5,s2,800040c0 <namex+0x13c>
    800040b2:	dbbd                	beqz	a5,80004028 <namex+0xa4>
    path++;
    800040b4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040b6:	0009c783          	lbu	a5,0(s3)
    800040ba:	ff279ce3          	bne	a5,s2,800040b2 <namex+0x12e>
    800040be:	b7ad                	j	80004028 <namex+0xa4>
    memmove(name, s, len);
    800040c0:	2601                	sext.w	a2,a2
    800040c2:	85a6                	mv	a1,s1
    800040c4:	8556                	mv	a0,s5
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	c68080e7          	jalr	-920(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040ce:	9d56                	add	s10,s10,s5
    800040d0:	000d0023          	sb	zero,0(s10)
    800040d4:	84ce                	mv	s1,s3
    800040d6:	b7bd                	j	80004044 <namex+0xc0>
  if(nameiparent){
    800040d8:	f00b0ce3          	beqz	s6,80003ff0 <namex+0x6c>
    iput(ip);
    800040dc:	8552                	mv	a0,s4
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	acc080e7          	jalr	-1332(ra) # 80003baa <iput>
    return 0;
    800040e6:	4a01                	li	s4,0
    800040e8:	b721                	j	80003ff0 <namex+0x6c>

00000000800040ea <dirlink>:
{
    800040ea:	7139                	addi	sp,sp,-64
    800040ec:	fc06                	sd	ra,56(sp)
    800040ee:	f822                	sd	s0,48(sp)
    800040f0:	f426                	sd	s1,40(sp)
    800040f2:	f04a                	sd	s2,32(sp)
    800040f4:	ec4e                	sd	s3,24(sp)
    800040f6:	e852                	sd	s4,16(sp)
    800040f8:	0080                	addi	s0,sp,64
    800040fa:	892a                	mv	s2,a0
    800040fc:	8a2e                	mv	s4,a1
    800040fe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004100:	4601                	li	a2,0
    80004102:	00000097          	auipc	ra,0x0
    80004106:	dd2080e7          	jalr	-558(ra) # 80003ed4 <dirlookup>
    8000410a:	e93d                	bnez	a0,80004180 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000410c:	04c92483          	lw	s1,76(s2)
    80004110:	c49d                	beqz	s1,8000413e <dirlink+0x54>
    80004112:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004114:	4741                	li	a4,16
    80004116:	86a6                	mv	a3,s1
    80004118:	fc040613          	addi	a2,s0,-64
    8000411c:	4581                	li	a1,0
    8000411e:	854a                	mv	a0,s2
    80004120:	00000097          	auipc	ra,0x0
    80004124:	b84080e7          	jalr	-1148(ra) # 80003ca4 <readi>
    80004128:	47c1                	li	a5,16
    8000412a:	06f51163          	bne	a0,a5,8000418c <dirlink+0xa2>
    if(de.inum == 0)
    8000412e:	fc045783          	lhu	a5,-64(s0)
    80004132:	c791                	beqz	a5,8000413e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004134:	24c1                	addiw	s1,s1,16
    80004136:	04c92783          	lw	a5,76(s2)
    8000413a:	fcf4ede3          	bltu	s1,a5,80004114 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000413e:	4639                	li	a2,14
    80004140:	85d2                	mv	a1,s4
    80004142:	fc240513          	addi	a0,s0,-62
    80004146:	ffffd097          	auipc	ra,0xffffd
    8000414a:	c98080e7          	jalr	-872(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000414e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004152:	4741                	li	a4,16
    80004154:	86a6                	mv	a3,s1
    80004156:	fc040613          	addi	a2,s0,-64
    8000415a:	4581                	li	a1,0
    8000415c:	854a                	mv	a0,s2
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	c3e080e7          	jalr	-962(ra) # 80003d9c <writei>
    80004166:	1541                	addi	a0,a0,-16
    80004168:	00a03533          	snez	a0,a0
    8000416c:	40a00533          	neg	a0,a0
}
    80004170:	70e2                	ld	ra,56(sp)
    80004172:	7442                	ld	s0,48(sp)
    80004174:	74a2                	ld	s1,40(sp)
    80004176:	7902                	ld	s2,32(sp)
    80004178:	69e2                	ld	s3,24(sp)
    8000417a:	6a42                	ld	s4,16(sp)
    8000417c:	6121                	addi	sp,sp,64
    8000417e:	8082                	ret
    iput(ip);
    80004180:	00000097          	auipc	ra,0x0
    80004184:	a2a080e7          	jalr	-1494(ra) # 80003baa <iput>
    return -1;
    80004188:	557d                	li	a0,-1
    8000418a:	b7dd                	j	80004170 <dirlink+0x86>
      panic("dirlink read");
    8000418c:	00004517          	auipc	a0,0x4
    80004190:	4ac50513          	addi	a0,a0,1196 # 80008638 <syscalls+0x1e8>
    80004194:	ffffc097          	auipc	ra,0xffffc
    80004198:	3ac080e7          	jalr	940(ra) # 80000540 <panic>

000000008000419c <namei>:

struct inode*
namei(char *path)
{
    8000419c:	1101                	addi	sp,sp,-32
    8000419e:	ec06                	sd	ra,24(sp)
    800041a0:	e822                	sd	s0,16(sp)
    800041a2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041a4:	fe040613          	addi	a2,s0,-32
    800041a8:	4581                	li	a1,0
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	dda080e7          	jalr	-550(ra) # 80003f84 <namex>
}
    800041b2:	60e2                	ld	ra,24(sp)
    800041b4:	6442                	ld	s0,16(sp)
    800041b6:	6105                	addi	sp,sp,32
    800041b8:	8082                	ret

00000000800041ba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041ba:	1141                	addi	sp,sp,-16
    800041bc:	e406                	sd	ra,8(sp)
    800041be:	e022                	sd	s0,0(sp)
    800041c0:	0800                	addi	s0,sp,16
    800041c2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041c4:	4585                	li	a1,1
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	dbe080e7          	jalr	-578(ra) # 80003f84 <namex>
}
    800041ce:	60a2                	ld	ra,8(sp)
    800041d0:	6402                	ld	s0,0(sp)
    800041d2:	0141                	addi	sp,sp,16
    800041d4:	8082                	ret

00000000800041d6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041d6:	1101                	addi	sp,sp,-32
    800041d8:	ec06                	sd	ra,24(sp)
    800041da:	e822                	sd	s0,16(sp)
    800041dc:	e426                	sd	s1,8(sp)
    800041de:	e04a                	sd	s2,0(sp)
    800041e0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041e2:	00024917          	auipc	s2,0x24
    800041e6:	b5e90913          	addi	s2,s2,-1186 # 80027d40 <log>
    800041ea:	01892583          	lw	a1,24(s2)
    800041ee:	02892503          	lw	a0,40(s2)
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	fe6080e7          	jalr	-26(ra) # 800031d8 <bread>
    800041fa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041fc:	02c92683          	lw	a3,44(s2)
    80004200:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004202:	02d05863          	blez	a3,80004232 <write_head+0x5c>
    80004206:	00024797          	auipc	a5,0x24
    8000420a:	b6a78793          	addi	a5,a5,-1174 # 80027d70 <log+0x30>
    8000420e:	05c50713          	addi	a4,a0,92
    80004212:	36fd                	addiw	a3,a3,-1
    80004214:	02069613          	slli	a2,a3,0x20
    80004218:	01e65693          	srli	a3,a2,0x1e
    8000421c:	00024617          	auipc	a2,0x24
    80004220:	b5860613          	addi	a2,a2,-1192 # 80027d74 <log+0x34>
    80004224:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004226:	4390                	lw	a2,0(a5)
    80004228:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000422a:	0791                	addi	a5,a5,4
    8000422c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000422e:	fed79ce3          	bne	a5,a3,80004226 <write_head+0x50>
  }
  bwrite(buf);
    80004232:	8526                	mv	a0,s1
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	096080e7          	jalr	150(ra) # 800032ca <bwrite>
  brelse(buf);
    8000423c:	8526                	mv	a0,s1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	0ca080e7          	jalr	202(ra) # 80003308 <brelse>
}
    80004246:	60e2                	ld	ra,24(sp)
    80004248:	6442                	ld	s0,16(sp)
    8000424a:	64a2                	ld	s1,8(sp)
    8000424c:	6902                	ld	s2,0(sp)
    8000424e:	6105                	addi	sp,sp,32
    80004250:	8082                	ret

0000000080004252 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004252:	00024797          	auipc	a5,0x24
    80004256:	b1a7a783          	lw	a5,-1254(a5) # 80027d6c <log+0x2c>
    8000425a:	0af05d63          	blez	a5,80004314 <install_trans+0xc2>
{
    8000425e:	7139                	addi	sp,sp,-64
    80004260:	fc06                	sd	ra,56(sp)
    80004262:	f822                	sd	s0,48(sp)
    80004264:	f426                	sd	s1,40(sp)
    80004266:	f04a                	sd	s2,32(sp)
    80004268:	ec4e                	sd	s3,24(sp)
    8000426a:	e852                	sd	s4,16(sp)
    8000426c:	e456                	sd	s5,8(sp)
    8000426e:	e05a                	sd	s6,0(sp)
    80004270:	0080                	addi	s0,sp,64
    80004272:	8b2a                	mv	s6,a0
    80004274:	00024a97          	auipc	s5,0x24
    80004278:	afca8a93          	addi	s5,s5,-1284 # 80027d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000427e:	00024997          	auipc	s3,0x24
    80004282:	ac298993          	addi	s3,s3,-1342 # 80027d40 <log>
    80004286:	a00d                	j	800042a8 <install_trans+0x56>
    brelse(lbuf);
    80004288:	854a                	mv	a0,s2
    8000428a:	fffff097          	auipc	ra,0xfffff
    8000428e:	07e080e7          	jalr	126(ra) # 80003308 <brelse>
    brelse(dbuf);
    80004292:	8526                	mv	a0,s1
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	074080e7          	jalr	116(ra) # 80003308 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429c:	2a05                	addiw	s4,s4,1
    8000429e:	0a91                	addi	s5,s5,4
    800042a0:	02c9a783          	lw	a5,44(s3)
    800042a4:	04fa5e63          	bge	s4,a5,80004300 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042a8:	0189a583          	lw	a1,24(s3)
    800042ac:	014585bb          	addw	a1,a1,s4
    800042b0:	2585                	addiw	a1,a1,1
    800042b2:	0289a503          	lw	a0,40(s3)
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	f22080e7          	jalr	-222(ra) # 800031d8 <bread>
    800042be:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042c0:	000aa583          	lw	a1,0(s5)
    800042c4:	0289a503          	lw	a0,40(s3)
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	f10080e7          	jalr	-240(ra) # 800031d8 <bread>
    800042d0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042d2:	40000613          	li	a2,1024
    800042d6:	05890593          	addi	a1,s2,88
    800042da:	05850513          	addi	a0,a0,88
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	a50080e7          	jalr	-1456(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042e6:	8526                	mv	a0,s1
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	fe2080e7          	jalr	-30(ra) # 800032ca <bwrite>
    if(recovering == 0)
    800042f0:	f80b1ce3          	bnez	s6,80004288 <install_trans+0x36>
      bunpin(dbuf);
    800042f4:	8526                	mv	a0,s1
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	0ec080e7          	jalr	236(ra) # 800033e2 <bunpin>
    800042fe:	b769                	j	80004288 <install_trans+0x36>
}
    80004300:	70e2                	ld	ra,56(sp)
    80004302:	7442                	ld	s0,48(sp)
    80004304:	74a2                	ld	s1,40(sp)
    80004306:	7902                	ld	s2,32(sp)
    80004308:	69e2                	ld	s3,24(sp)
    8000430a:	6a42                	ld	s4,16(sp)
    8000430c:	6aa2                	ld	s5,8(sp)
    8000430e:	6b02                	ld	s6,0(sp)
    80004310:	6121                	addi	sp,sp,64
    80004312:	8082                	ret
    80004314:	8082                	ret

0000000080004316 <initlog>:
{
    80004316:	7179                	addi	sp,sp,-48
    80004318:	f406                	sd	ra,40(sp)
    8000431a:	f022                	sd	s0,32(sp)
    8000431c:	ec26                	sd	s1,24(sp)
    8000431e:	e84a                	sd	s2,16(sp)
    80004320:	e44e                	sd	s3,8(sp)
    80004322:	1800                	addi	s0,sp,48
    80004324:	892a                	mv	s2,a0
    80004326:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004328:	00024497          	auipc	s1,0x24
    8000432c:	a1848493          	addi	s1,s1,-1512 # 80027d40 <log>
    80004330:	00004597          	auipc	a1,0x4
    80004334:	31858593          	addi	a1,a1,792 # 80008648 <syscalls+0x1f8>
    80004338:	8526                	mv	a0,s1
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	80c080e7          	jalr	-2036(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004342:	0149a583          	lw	a1,20(s3)
    80004346:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004348:	0109a783          	lw	a5,16(s3)
    8000434c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000434e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004352:	854a                	mv	a0,s2
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	e84080e7          	jalr	-380(ra) # 800031d8 <bread>
  log.lh.n = lh->n;
    8000435c:	4d34                	lw	a3,88(a0)
    8000435e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004360:	02d05663          	blez	a3,8000438c <initlog+0x76>
    80004364:	05c50793          	addi	a5,a0,92
    80004368:	00024717          	auipc	a4,0x24
    8000436c:	a0870713          	addi	a4,a4,-1528 # 80027d70 <log+0x30>
    80004370:	36fd                	addiw	a3,a3,-1
    80004372:	02069613          	slli	a2,a3,0x20
    80004376:	01e65693          	srli	a3,a2,0x1e
    8000437a:	06050613          	addi	a2,a0,96
    8000437e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004380:	4390                	lw	a2,0(a5)
    80004382:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004384:	0791                	addi	a5,a5,4
    80004386:	0711                	addi	a4,a4,4
    80004388:	fed79ce3          	bne	a5,a3,80004380 <initlog+0x6a>
  brelse(buf);
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	f7c080e7          	jalr	-132(ra) # 80003308 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004394:	4505                	li	a0,1
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	ebc080e7          	jalr	-324(ra) # 80004252 <install_trans>
  log.lh.n = 0;
    8000439e:	00024797          	auipc	a5,0x24
    800043a2:	9c07a723          	sw	zero,-1586(a5) # 80027d6c <log+0x2c>
  write_head(); // clear the log
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	e30080e7          	jalr	-464(ra) # 800041d6 <write_head>
}
    800043ae:	70a2                	ld	ra,40(sp)
    800043b0:	7402                	ld	s0,32(sp)
    800043b2:	64e2                	ld	s1,24(sp)
    800043b4:	6942                	ld	s2,16(sp)
    800043b6:	69a2                	ld	s3,8(sp)
    800043b8:	6145                	addi	sp,sp,48
    800043ba:	8082                	ret

00000000800043bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043bc:	1101                	addi	sp,sp,-32
    800043be:	ec06                	sd	ra,24(sp)
    800043c0:	e822                	sd	s0,16(sp)
    800043c2:	e426                	sd	s1,8(sp)
    800043c4:	e04a                	sd	s2,0(sp)
    800043c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043c8:	00024517          	auipc	a0,0x24
    800043cc:	97850513          	addi	a0,a0,-1672 # 80027d40 <log>
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043d8:	00024497          	auipc	s1,0x24
    800043dc:	96848493          	addi	s1,s1,-1688 # 80027d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043e0:	4979                	li	s2,30
    800043e2:	a039                	j	800043f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043e4:	85a6                	mv	a1,s1
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	cac080e7          	jalr	-852(ra) # 80002094 <sleep>
    if(log.committing){
    800043f0:	50dc                	lw	a5,36(s1)
    800043f2:	fbed                	bnez	a5,800043e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043f4:	5098                	lw	a4,32(s1)
    800043f6:	2705                	addiw	a4,a4,1
    800043f8:	0007069b          	sext.w	a3,a4
    800043fc:	0027179b          	slliw	a5,a4,0x2
    80004400:	9fb9                	addw	a5,a5,a4
    80004402:	0017979b          	slliw	a5,a5,0x1
    80004406:	54d8                	lw	a4,44(s1)
    80004408:	9fb9                	addw	a5,a5,a4
    8000440a:	00f95963          	bge	s2,a5,8000441c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000440e:	85a6                	mv	a1,s1
    80004410:	8526                	mv	a0,s1
    80004412:	ffffe097          	auipc	ra,0xffffe
    80004416:	c82080e7          	jalr	-894(ra) # 80002094 <sleep>
    8000441a:	bfd9                	j	800043f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000441c:	00024517          	auipc	a0,0x24
    80004420:	92450513          	addi	a0,a0,-1756 # 80027d40 <log>
    80004424:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	864080e7          	jalr	-1948(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6902                	ld	s2,0(sp)
    80004436:	6105                	addi	sp,sp,32
    80004438:	8082                	ret

000000008000443a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000443a:	7139                	addi	sp,sp,-64
    8000443c:	fc06                	sd	ra,56(sp)
    8000443e:	f822                	sd	s0,48(sp)
    80004440:	f426                	sd	s1,40(sp)
    80004442:	f04a                	sd	s2,32(sp)
    80004444:	ec4e                	sd	s3,24(sp)
    80004446:	e852                	sd	s4,16(sp)
    80004448:	e456                	sd	s5,8(sp)
    8000444a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000444c:	00024497          	auipc	s1,0x24
    80004450:	8f448493          	addi	s1,s1,-1804 # 80027d40 <log>
    80004454:	8526                	mv	a0,s1
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	780080e7          	jalr	1920(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000445e:	509c                	lw	a5,32(s1)
    80004460:	37fd                	addiw	a5,a5,-1
    80004462:	0007891b          	sext.w	s2,a5
    80004466:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004468:	50dc                	lw	a5,36(s1)
    8000446a:	e7b9                	bnez	a5,800044b8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000446c:	04091e63          	bnez	s2,800044c8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004470:	00024497          	auipc	s1,0x24
    80004474:	8d048493          	addi	s1,s1,-1840 # 80027d40 <log>
    80004478:	4785                	li	a5,1
    8000447a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000447c:	8526                	mv	a0,s1
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	80c080e7          	jalr	-2036(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004486:	54dc                	lw	a5,44(s1)
    80004488:	06f04763          	bgtz	a5,800044f6 <end_op+0xbc>
    acquire(&log.lock);
    8000448c:	00024497          	auipc	s1,0x24
    80004490:	8b448493          	addi	s1,s1,-1868 # 80027d40 <log>
    80004494:	8526                	mv	a0,s1
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	740080e7          	jalr	1856(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000449e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044a2:	8526                	mv	a0,s1
    800044a4:	ffffe097          	auipc	ra,0xffffe
    800044a8:	c54080e7          	jalr	-940(ra) # 800020f8 <wakeup>
    release(&log.lock);
    800044ac:	8526                	mv	a0,s1
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
}
    800044b6:	a03d                	j	800044e4 <end_op+0xaa>
    panic("log.committing");
    800044b8:	00004517          	auipc	a0,0x4
    800044bc:	19850513          	addi	a0,a0,408 # 80008650 <syscalls+0x200>
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	080080e7          	jalr	128(ra) # 80000540 <panic>
    wakeup(&log);
    800044c8:	00024497          	auipc	s1,0x24
    800044cc:	87848493          	addi	s1,s1,-1928 # 80027d40 <log>
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffe097          	auipc	ra,0xffffe
    800044d6:	c26080e7          	jalr	-986(ra) # 800020f8 <wakeup>
  release(&log.lock);
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7ae080e7          	jalr	1966(ra) # 80000c8a <release>
}
    800044e4:	70e2                	ld	ra,56(sp)
    800044e6:	7442                	ld	s0,48(sp)
    800044e8:	74a2                	ld	s1,40(sp)
    800044ea:	7902                	ld	s2,32(sp)
    800044ec:	69e2                	ld	s3,24(sp)
    800044ee:	6a42                	ld	s4,16(sp)
    800044f0:	6aa2                	ld	s5,8(sp)
    800044f2:	6121                	addi	sp,sp,64
    800044f4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f6:	00024a97          	auipc	s5,0x24
    800044fa:	87aa8a93          	addi	s5,s5,-1926 # 80027d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044fe:	00024a17          	auipc	s4,0x24
    80004502:	842a0a13          	addi	s4,s4,-1982 # 80027d40 <log>
    80004506:	018a2583          	lw	a1,24(s4)
    8000450a:	012585bb          	addw	a1,a1,s2
    8000450e:	2585                	addiw	a1,a1,1
    80004510:	028a2503          	lw	a0,40(s4)
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	cc4080e7          	jalr	-828(ra) # 800031d8 <bread>
    8000451c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000451e:	000aa583          	lw	a1,0(s5)
    80004522:	028a2503          	lw	a0,40(s4)
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	cb2080e7          	jalr	-846(ra) # 800031d8 <bread>
    8000452e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004530:	40000613          	li	a2,1024
    80004534:	05850593          	addi	a1,a0,88
    80004538:	05848513          	addi	a0,s1,88
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	7f2080e7          	jalr	2034(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004544:	8526                	mv	a0,s1
    80004546:	fffff097          	auipc	ra,0xfffff
    8000454a:	d84080e7          	jalr	-636(ra) # 800032ca <bwrite>
    brelse(from);
    8000454e:	854e                	mv	a0,s3
    80004550:	fffff097          	auipc	ra,0xfffff
    80004554:	db8080e7          	jalr	-584(ra) # 80003308 <brelse>
    brelse(to);
    80004558:	8526                	mv	a0,s1
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	dae080e7          	jalr	-594(ra) # 80003308 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004562:	2905                	addiw	s2,s2,1
    80004564:	0a91                	addi	s5,s5,4
    80004566:	02ca2783          	lw	a5,44(s4)
    8000456a:	f8f94ee3          	blt	s2,a5,80004506 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000456e:	00000097          	auipc	ra,0x0
    80004572:	c68080e7          	jalr	-920(ra) # 800041d6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004576:	4501                	li	a0,0
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	cda080e7          	jalr	-806(ra) # 80004252 <install_trans>
    log.lh.n = 0;
    80004580:	00023797          	auipc	a5,0x23
    80004584:	7e07a623          	sw	zero,2028(a5) # 80027d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	c4e080e7          	jalr	-946(ra) # 800041d6 <write_head>
    80004590:	bdf5                	j	8000448c <end_op+0x52>

0000000080004592 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004592:	1101                	addi	sp,sp,-32
    80004594:	ec06                	sd	ra,24(sp)
    80004596:	e822                	sd	s0,16(sp)
    80004598:	e426                	sd	s1,8(sp)
    8000459a:	e04a                	sd	s2,0(sp)
    8000459c:	1000                	addi	s0,sp,32
    8000459e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045a0:	00023917          	auipc	s2,0x23
    800045a4:	7a090913          	addi	s2,s2,1952 # 80027d40 <log>
    800045a8:	854a                	mv	a0,s2
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	62c080e7          	jalr	1580(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045b2:	02c92603          	lw	a2,44(s2)
    800045b6:	47f5                	li	a5,29
    800045b8:	06c7c563          	blt	a5,a2,80004622 <log_write+0x90>
    800045bc:	00023797          	auipc	a5,0x23
    800045c0:	7a07a783          	lw	a5,1952(a5) # 80027d5c <log+0x1c>
    800045c4:	37fd                	addiw	a5,a5,-1
    800045c6:	04f65e63          	bge	a2,a5,80004622 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045ca:	00023797          	auipc	a5,0x23
    800045ce:	7967a783          	lw	a5,1942(a5) # 80027d60 <log+0x20>
    800045d2:	06f05063          	blez	a5,80004632 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045d6:	4781                	li	a5,0
    800045d8:	06c05563          	blez	a2,80004642 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045dc:	44cc                	lw	a1,12(s1)
    800045de:	00023717          	auipc	a4,0x23
    800045e2:	79270713          	addi	a4,a4,1938 # 80027d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045e6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045e8:	4314                	lw	a3,0(a4)
    800045ea:	04b68c63          	beq	a3,a1,80004642 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045ee:	2785                	addiw	a5,a5,1
    800045f0:	0711                	addi	a4,a4,4
    800045f2:	fef61be3          	bne	a2,a5,800045e8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045f6:	0621                	addi	a2,a2,8
    800045f8:	060a                	slli	a2,a2,0x2
    800045fa:	00023797          	auipc	a5,0x23
    800045fe:	74678793          	addi	a5,a5,1862 # 80027d40 <log>
    80004602:	97b2                	add	a5,a5,a2
    80004604:	44d8                	lw	a4,12(s1)
    80004606:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004608:	8526                	mv	a0,s1
    8000460a:	fffff097          	auipc	ra,0xfffff
    8000460e:	d9c080e7          	jalr	-612(ra) # 800033a6 <bpin>
    log.lh.n++;
    80004612:	00023717          	auipc	a4,0x23
    80004616:	72e70713          	addi	a4,a4,1838 # 80027d40 <log>
    8000461a:	575c                	lw	a5,44(a4)
    8000461c:	2785                	addiw	a5,a5,1
    8000461e:	d75c                	sw	a5,44(a4)
    80004620:	a82d                	j	8000465a <log_write+0xc8>
    panic("too big a transaction");
    80004622:	00004517          	auipc	a0,0x4
    80004626:	03e50513          	addi	a0,a0,62 # 80008660 <syscalls+0x210>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	f16080e7          	jalr	-234(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004632:	00004517          	auipc	a0,0x4
    80004636:	04650513          	addi	a0,a0,70 # 80008678 <syscalls+0x228>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	f06080e7          	jalr	-250(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004642:	00878693          	addi	a3,a5,8
    80004646:	068a                	slli	a3,a3,0x2
    80004648:	00023717          	auipc	a4,0x23
    8000464c:	6f870713          	addi	a4,a4,1784 # 80027d40 <log>
    80004650:	9736                	add	a4,a4,a3
    80004652:	44d4                	lw	a3,12(s1)
    80004654:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004656:	faf609e3          	beq	a2,a5,80004608 <log_write+0x76>
  }
  release(&log.lock);
    8000465a:	00023517          	auipc	a0,0x23
    8000465e:	6e650513          	addi	a0,a0,1766 # 80027d40 <log>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	628080e7          	jalr	1576(ra) # 80000c8a <release>
}
    8000466a:	60e2                	ld	ra,24(sp)
    8000466c:	6442                	ld	s0,16(sp)
    8000466e:	64a2                	ld	s1,8(sp)
    80004670:	6902                	ld	s2,0(sp)
    80004672:	6105                	addi	sp,sp,32
    80004674:	8082                	ret

0000000080004676 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004676:	1101                	addi	sp,sp,-32
    80004678:	ec06                	sd	ra,24(sp)
    8000467a:	e822                	sd	s0,16(sp)
    8000467c:	e426                	sd	s1,8(sp)
    8000467e:	e04a                	sd	s2,0(sp)
    80004680:	1000                	addi	s0,sp,32
    80004682:	84aa                	mv	s1,a0
    80004684:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004686:	00004597          	auipc	a1,0x4
    8000468a:	01258593          	addi	a1,a1,18 # 80008698 <syscalls+0x248>
    8000468e:	0521                	addi	a0,a0,8
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	4b6080e7          	jalr	1206(ra) # 80000b46 <initlock>
  lk->name = name;
    80004698:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000469c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046a0:	0204a423          	sw	zero,40(s1)
}
    800046a4:	60e2                	ld	ra,24(sp)
    800046a6:	6442                	ld	s0,16(sp)
    800046a8:	64a2                	ld	s1,8(sp)
    800046aa:	6902                	ld	s2,0(sp)
    800046ac:	6105                	addi	sp,sp,32
    800046ae:	8082                	ret

00000000800046b0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046b0:	1101                	addi	sp,sp,-32
    800046b2:	ec06                	sd	ra,24(sp)
    800046b4:	e822                	sd	s0,16(sp)
    800046b6:	e426                	sd	s1,8(sp)
    800046b8:	e04a                	sd	s2,0(sp)
    800046ba:	1000                	addi	s0,sp,32
    800046bc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046be:	00850913          	addi	s2,a0,8
    800046c2:	854a                	mv	a0,s2
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	512080e7          	jalr	1298(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046cc:	409c                	lw	a5,0(s1)
    800046ce:	cb89                	beqz	a5,800046e0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046d0:	85ca                	mv	a1,s2
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffe097          	auipc	ra,0xffffe
    800046d8:	9c0080e7          	jalr	-1600(ra) # 80002094 <sleep>
  while (lk->locked) {
    800046dc:	409c                	lw	a5,0(s1)
    800046de:	fbed                	bnez	a5,800046d0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046e0:	4785                	li	a5,1
    800046e2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046e4:	ffffd097          	auipc	ra,0xffffd
    800046e8:	2c8080e7          	jalr	712(ra) # 800019ac <myproc>
    800046ec:	591c                	lw	a5,48(a0)
    800046ee:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046f0:	854a                	mv	a0,s2
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	598080e7          	jalr	1432(ra) # 80000c8a <release>
}
    800046fa:	60e2                	ld	ra,24(sp)
    800046fc:	6442                	ld	s0,16(sp)
    800046fe:	64a2                	ld	s1,8(sp)
    80004700:	6902                	ld	s2,0(sp)
    80004702:	6105                	addi	sp,sp,32
    80004704:	8082                	ret

0000000080004706 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004706:	1101                	addi	sp,sp,-32
    80004708:	ec06                	sd	ra,24(sp)
    8000470a:	e822                	sd	s0,16(sp)
    8000470c:	e426                	sd	s1,8(sp)
    8000470e:	e04a                	sd	s2,0(sp)
    80004710:	1000                	addi	s0,sp,32
    80004712:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004714:	00850913          	addi	s2,a0,8
    80004718:	854a                	mv	a0,s2
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	4bc080e7          	jalr	1212(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004722:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004726:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000472a:	8526                	mv	a0,s1
    8000472c:	ffffe097          	auipc	ra,0xffffe
    80004730:	9cc080e7          	jalr	-1588(ra) # 800020f8 <wakeup>
  release(&lk->lk);
    80004734:	854a                	mv	a0,s2
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	554080e7          	jalr	1364(ra) # 80000c8a <release>
}
    8000473e:	60e2                	ld	ra,24(sp)
    80004740:	6442                	ld	s0,16(sp)
    80004742:	64a2                	ld	s1,8(sp)
    80004744:	6902                	ld	s2,0(sp)
    80004746:	6105                	addi	sp,sp,32
    80004748:	8082                	ret

000000008000474a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000474a:	7179                	addi	sp,sp,-48
    8000474c:	f406                	sd	ra,40(sp)
    8000474e:	f022                	sd	s0,32(sp)
    80004750:	ec26                	sd	s1,24(sp)
    80004752:	e84a                	sd	s2,16(sp)
    80004754:	e44e                	sd	s3,8(sp)
    80004756:	1800                	addi	s0,sp,48
    80004758:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000475a:	00850913          	addi	s2,a0,8
    8000475e:	854a                	mv	a0,s2
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	476080e7          	jalr	1142(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004768:	409c                	lw	a5,0(s1)
    8000476a:	ef99                	bnez	a5,80004788 <holdingsleep+0x3e>
    8000476c:	4481                	li	s1,0
  release(&lk->lk);
    8000476e:	854a                	mv	a0,s2
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	51a080e7          	jalr	1306(ra) # 80000c8a <release>
  return r;
}
    80004778:	8526                	mv	a0,s1
    8000477a:	70a2                	ld	ra,40(sp)
    8000477c:	7402                	ld	s0,32(sp)
    8000477e:	64e2                	ld	s1,24(sp)
    80004780:	6942                	ld	s2,16(sp)
    80004782:	69a2                	ld	s3,8(sp)
    80004784:	6145                	addi	sp,sp,48
    80004786:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004788:	0284a983          	lw	s3,40(s1)
    8000478c:	ffffd097          	auipc	ra,0xffffd
    80004790:	220080e7          	jalr	544(ra) # 800019ac <myproc>
    80004794:	5904                	lw	s1,48(a0)
    80004796:	413484b3          	sub	s1,s1,s3
    8000479a:	0014b493          	seqz	s1,s1
    8000479e:	bfc1                	j	8000476e <holdingsleep+0x24>

00000000800047a0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047a0:	1141                	addi	sp,sp,-16
    800047a2:	e406                	sd	ra,8(sp)
    800047a4:	e022                	sd	s0,0(sp)
    800047a6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047a8:	00004597          	auipc	a1,0x4
    800047ac:	f0058593          	addi	a1,a1,-256 # 800086a8 <syscalls+0x258>
    800047b0:	00023517          	auipc	a0,0x23
    800047b4:	6d850513          	addi	a0,a0,1752 # 80027e88 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	38e080e7          	jalr	910(ra) # 80000b46 <initlock>
}
    800047c0:	60a2                	ld	ra,8(sp)
    800047c2:	6402                	ld	s0,0(sp)
    800047c4:	0141                	addi	sp,sp,16
    800047c6:	8082                	ret

00000000800047c8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047c8:	1101                	addi	sp,sp,-32
    800047ca:	ec06                	sd	ra,24(sp)
    800047cc:	e822                	sd	s0,16(sp)
    800047ce:	e426                	sd	s1,8(sp)
    800047d0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047d2:	00023517          	auipc	a0,0x23
    800047d6:	6b650513          	addi	a0,a0,1718 # 80027e88 <ftable>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	3fc080e7          	jalr	1020(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047e2:	00023497          	auipc	s1,0x23
    800047e6:	6be48493          	addi	s1,s1,1726 # 80027ea0 <ftable+0x18>
    800047ea:	00024717          	auipc	a4,0x24
    800047ee:	65670713          	addi	a4,a4,1622 # 80028e40 <disk>
    if(f->ref == 0){
    800047f2:	40dc                	lw	a5,4(s1)
    800047f4:	cf99                	beqz	a5,80004812 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047f6:	02848493          	addi	s1,s1,40
    800047fa:	fee49ce3          	bne	s1,a4,800047f2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047fe:	00023517          	auipc	a0,0x23
    80004802:	68a50513          	addi	a0,a0,1674 # 80027e88 <ftable>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	484080e7          	jalr	1156(ra) # 80000c8a <release>
  return 0;
    8000480e:	4481                	li	s1,0
    80004810:	a819                	j	80004826 <filealloc+0x5e>
      f->ref = 1;
    80004812:	4785                	li	a5,1
    80004814:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004816:	00023517          	auipc	a0,0x23
    8000481a:	67250513          	addi	a0,a0,1650 # 80027e88 <ftable>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	46c080e7          	jalr	1132(ra) # 80000c8a <release>
}
    80004826:	8526                	mv	a0,s1
    80004828:	60e2                	ld	ra,24(sp)
    8000482a:	6442                	ld	s0,16(sp)
    8000482c:	64a2                	ld	s1,8(sp)
    8000482e:	6105                	addi	sp,sp,32
    80004830:	8082                	ret

0000000080004832 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004832:	1101                	addi	sp,sp,-32
    80004834:	ec06                	sd	ra,24(sp)
    80004836:	e822                	sd	s0,16(sp)
    80004838:	e426                	sd	s1,8(sp)
    8000483a:	1000                	addi	s0,sp,32
    8000483c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000483e:	00023517          	auipc	a0,0x23
    80004842:	64a50513          	addi	a0,a0,1610 # 80027e88 <ftable>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	390080e7          	jalr	912(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000484e:	40dc                	lw	a5,4(s1)
    80004850:	02f05263          	blez	a5,80004874 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004854:	2785                	addiw	a5,a5,1
    80004856:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004858:	00023517          	auipc	a0,0x23
    8000485c:	63050513          	addi	a0,a0,1584 # 80027e88 <ftable>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	42a080e7          	jalr	1066(ra) # 80000c8a <release>
  return f;
}
    80004868:	8526                	mv	a0,s1
    8000486a:	60e2                	ld	ra,24(sp)
    8000486c:	6442                	ld	s0,16(sp)
    8000486e:	64a2                	ld	s1,8(sp)
    80004870:	6105                	addi	sp,sp,32
    80004872:	8082                	ret
    panic("filedup");
    80004874:	00004517          	auipc	a0,0x4
    80004878:	e3c50513          	addi	a0,a0,-452 # 800086b0 <syscalls+0x260>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	cc4080e7          	jalr	-828(ra) # 80000540 <panic>

0000000080004884 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004884:	7139                	addi	sp,sp,-64
    80004886:	fc06                	sd	ra,56(sp)
    80004888:	f822                	sd	s0,48(sp)
    8000488a:	f426                	sd	s1,40(sp)
    8000488c:	f04a                	sd	s2,32(sp)
    8000488e:	ec4e                	sd	s3,24(sp)
    80004890:	e852                	sd	s4,16(sp)
    80004892:	e456                	sd	s5,8(sp)
    80004894:	0080                	addi	s0,sp,64
    80004896:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004898:	00023517          	auipc	a0,0x23
    8000489c:	5f050513          	addi	a0,a0,1520 # 80027e88 <ftable>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	336080e7          	jalr	822(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048a8:	40dc                	lw	a5,4(s1)
    800048aa:	06f05163          	blez	a5,8000490c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048ae:	37fd                	addiw	a5,a5,-1
    800048b0:	0007871b          	sext.w	a4,a5
    800048b4:	c0dc                	sw	a5,4(s1)
    800048b6:	06e04363          	bgtz	a4,8000491c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048ba:	0004a903          	lw	s2,0(s1)
    800048be:	0094ca83          	lbu	s5,9(s1)
    800048c2:	0104ba03          	ld	s4,16(s1)
    800048c6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ca:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048ce:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048d2:	00023517          	auipc	a0,0x23
    800048d6:	5b650513          	addi	a0,a0,1462 # 80027e88 <ftable>
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	3b0080e7          	jalr	944(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048e2:	4785                	li	a5,1
    800048e4:	04f90d63          	beq	s2,a5,8000493e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048e8:	3979                	addiw	s2,s2,-2
    800048ea:	4785                	li	a5,1
    800048ec:	0527e063          	bltu	a5,s2,8000492c <fileclose+0xa8>
    begin_op();
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	acc080e7          	jalr	-1332(ra) # 800043bc <begin_op>
    iput(ff.ip);
    800048f8:	854e                	mv	a0,s3
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	2b0080e7          	jalr	688(ra) # 80003baa <iput>
    end_op();
    80004902:	00000097          	auipc	ra,0x0
    80004906:	b38080e7          	jalr	-1224(ra) # 8000443a <end_op>
    8000490a:	a00d                	j	8000492c <fileclose+0xa8>
    panic("fileclose");
    8000490c:	00004517          	auipc	a0,0x4
    80004910:	dac50513          	addi	a0,a0,-596 # 800086b8 <syscalls+0x268>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	c2c080e7          	jalr	-980(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000491c:	00023517          	auipc	a0,0x23
    80004920:	56c50513          	addi	a0,a0,1388 # 80027e88 <ftable>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	366080e7          	jalr	870(ra) # 80000c8a <release>
  }
}
    8000492c:	70e2                	ld	ra,56(sp)
    8000492e:	7442                	ld	s0,48(sp)
    80004930:	74a2                	ld	s1,40(sp)
    80004932:	7902                	ld	s2,32(sp)
    80004934:	69e2                	ld	s3,24(sp)
    80004936:	6a42                	ld	s4,16(sp)
    80004938:	6aa2                	ld	s5,8(sp)
    8000493a:	6121                	addi	sp,sp,64
    8000493c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000493e:	85d6                	mv	a1,s5
    80004940:	8552                	mv	a0,s4
    80004942:	00000097          	auipc	ra,0x0
    80004946:	34c080e7          	jalr	844(ra) # 80004c8e <pipeclose>
    8000494a:	b7cd                	j	8000492c <fileclose+0xa8>

000000008000494c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000494c:	715d                	addi	sp,sp,-80
    8000494e:	e486                	sd	ra,72(sp)
    80004950:	e0a2                	sd	s0,64(sp)
    80004952:	fc26                	sd	s1,56(sp)
    80004954:	f84a                	sd	s2,48(sp)
    80004956:	f44e                	sd	s3,40(sp)
    80004958:	0880                	addi	s0,sp,80
    8000495a:	84aa                	mv	s1,a0
    8000495c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000495e:	ffffd097          	auipc	ra,0xffffd
    80004962:	04e080e7          	jalr	78(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004966:	409c                	lw	a5,0(s1)
    80004968:	37f9                	addiw	a5,a5,-2
    8000496a:	4705                	li	a4,1
    8000496c:	04f76763          	bltu	a4,a5,800049ba <filestat+0x6e>
    80004970:	892a                	mv	s2,a0
    ilock(f->ip);
    80004972:	6c88                	ld	a0,24(s1)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	07c080e7          	jalr	124(ra) # 800039f0 <ilock>
    stati(f->ip, &st);
    8000497c:	fb840593          	addi	a1,s0,-72
    80004980:	6c88                	ld	a0,24(s1)
    80004982:	fffff097          	auipc	ra,0xfffff
    80004986:	2f8080e7          	jalr	760(ra) # 80003c7a <stati>
    iunlock(f->ip);
    8000498a:	6c88                	ld	a0,24(s1)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	126080e7          	jalr	294(ra) # 80003ab2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004994:	46e1                	li	a3,24
    80004996:	fb840613          	addi	a2,s0,-72
    8000499a:	85ce                	mv	a1,s3
    8000499c:	0d093503          	ld	a0,208(s2)
    800049a0:	ffffd097          	auipc	ra,0xffffd
    800049a4:	ccc080e7          	jalr	-820(ra) # 8000166c <copyout>
    800049a8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049ac:	60a6                	ld	ra,72(sp)
    800049ae:	6406                	ld	s0,64(sp)
    800049b0:	74e2                	ld	s1,56(sp)
    800049b2:	7942                	ld	s2,48(sp)
    800049b4:	79a2                	ld	s3,40(sp)
    800049b6:	6161                	addi	sp,sp,80
    800049b8:	8082                	ret
  return -1;
    800049ba:	557d                	li	a0,-1
    800049bc:	bfc5                	j	800049ac <filestat+0x60>

00000000800049be <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049be:	7179                	addi	sp,sp,-48
    800049c0:	f406                	sd	ra,40(sp)
    800049c2:	f022                	sd	s0,32(sp)
    800049c4:	ec26                	sd	s1,24(sp)
    800049c6:	e84a                	sd	s2,16(sp)
    800049c8:	e44e                	sd	s3,8(sp)
    800049ca:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049cc:	00854783          	lbu	a5,8(a0)
    800049d0:	c3d5                	beqz	a5,80004a74 <fileread+0xb6>
    800049d2:	84aa                	mv	s1,a0
    800049d4:	89ae                	mv	s3,a1
    800049d6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049d8:	411c                	lw	a5,0(a0)
    800049da:	4705                	li	a4,1
    800049dc:	04e78963          	beq	a5,a4,80004a2e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049e0:	470d                	li	a4,3
    800049e2:	04e78d63          	beq	a5,a4,80004a3c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049e6:	4709                	li	a4,2
    800049e8:	06e79e63          	bne	a5,a4,80004a64 <fileread+0xa6>
    ilock(f->ip);
    800049ec:	6d08                	ld	a0,24(a0)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	002080e7          	jalr	2(ra) # 800039f0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049f6:	874a                	mv	a4,s2
    800049f8:	5094                	lw	a3,32(s1)
    800049fa:	864e                	mv	a2,s3
    800049fc:	4585                	li	a1,1
    800049fe:	6c88                	ld	a0,24(s1)
    80004a00:	fffff097          	auipc	ra,0xfffff
    80004a04:	2a4080e7          	jalr	676(ra) # 80003ca4 <readi>
    80004a08:	892a                	mv	s2,a0
    80004a0a:	00a05563          	blez	a0,80004a14 <fileread+0x56>
      f->off += r;
    80004a0e:	509c                	lw	a5,32(s1)
    80004a10:	9fa9                	addw	a5,a5,a0
    80004a12:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a14:	6c88                	ld	a0,24(s1)
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	09c080e7          	jalr	156(ra) # 80003ab2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a1e:	854a                	mv	a0,s2
    80004a20:	70a2                	ld	ra,40(sp)
    80004a22:	7402                	ld	s0,32(sp)
    80004a24:	64e2                	ld	s1,24(sp)
    80004a26:	6942                	ld	s2,16(sp)
    80004a28:	69a2                	ld	s3,8(sp)
    80004a2a:	6145                	addi	sp,sp,48
    80004a2c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a2e:	6908                	ld	a0,16(a0)
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	3c6080e7          	jalr	966(ra) # 80004df6 <piperead>
    80004a38:	892a                	mv	s2,a0
    80004a3a:	b7d5                	j	80004a1e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a3c:	02451783          	lh	a5,36(a0)
    80004a40:	03079693          	slli	a3,a5,0x30
    80004a44:	92c1                	srli	a3,a3,0x30
    80004a46:	4725                	li	a4,9
    80004a48:	02d76863          	bltu	a4,a3,80004a78 <fileread+0xba>
    80004a4c:	0792                	slli	a5,a5,0x4
    80004a4e:	00023717          	auipc	a4,0x23
    80004a52:	39a70713          	addi	a4,a4,922 # 80027de8 <devsw>
    80004a56:	97ba                	add	a5,a5,a4
    80004a58:	639c                	ld	a5,0(a5)
    80004a5a:	c38d                	beqz	a5,80004a7c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a5c:	4505                	li	a0,1
    80004a5e:	9782                	jalr	a5
    80004a60:	892a                	mv	s2,a0
    80004a62:	bf75                	j	80004a1e <fileread+0x60>
    panic("fileread");
    80004a64:	00004517          	auipc	a0,0x4
    80004a68:	c6450513          	addi	a0,a0,-924 # 800086c8 <syscalls+0x278>
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	ad4080e7          	jalr	-1324(ra) # 80000540 <panic>
    return -1;
    80004a74:	597d                	li	s2,-1
    80004a76:	b765                	j	80004a1e <fileread+0x60>
      return -1;
    80004a78:	597d                	li	s2,-1
    80004a7a:	b755                	j	80004a1e <fileread+0x60>
    80004a7c:	597d                	li	s2,-1
    80004a7e:	b745                	j	80004a1e <fileread+0x60>

0000000080004a80 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a80:	715d                	addi	sp,sp,-80
    80004a82:	e486                	sd	ra,72(sp)
    80004a84:	e0a2                	sd	s0,64(sp)
    80004a86:	fc26                	sd	s1,56(sp)
    80004a88:	f84a                	sd	s2,48(sp)
    80004a8a:	f44e                	sd	s3,40(sp)
    80004a8c:	f052                	sd	s4,32(sp)
    80004a8e:	ec56                	sd	s5,24(sp)
    80004a90:	e85a                	sd	s6,16(sp)
    80004a92:	e45e                	sd	s7,8(sp)
    80004a94:	e062                	sd	s8,0(sp)
    80004a96:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a98:	00954783          	lbu	a5,9(a0)
    80004a9c:	10078663          	beqz	a5,80004ba8 <filewrite+0x128>
    80004aa0:	892a                	mv	s2,a0
    80004aa2:	8b2e                	mv	s6,a1
    80004aa4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aa6:	411c                	lw	a5,0(a0)
    80004aa8:	4705                	li	a4,1
    80004aaa:	02e78263          	beq	a5,a4,80004ace <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aae:	470d                	li	a4,3
    80004ab0:	02e78663          	beq	a5,a4,80004adc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ab4:	4709                	li	a4,2
    80004ab6:	0ee79163          	bne	a5,a4,80004b98 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004aba:	0ac05d63          	blez	a2,80004b74 <filewrite+0xf4>
    int i = 0;
    80004abe:	4981                	li	s3,0
    80004ac0:	6b85                	lui	s7,0x1
    80004ac2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ac6:	6c05                	lui	s8,0x1
    80004ac8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004acc:	a861                	j	80004b64 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ace:	6908                	ld	a0,16(a0)
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	22e080e7          	jalr	558(ra) # 80004cfe <pipewrite>
    80004ad8:	8a2a                	mv	s4,a0
    80004ada:	a045                	j	80004b7a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004adc:	02451783          	lh	a5,36(a0)
    80004ae0:	03079693          	slli	a3,a5,0x30
    80004ae4:	92c1                	srli	a3,a3,0x30
    80004ae6:	4725                	li	a4,9
    80004ae8:	0cd76263          	bltu	a4,a3,80004bac <filewrite+0x12c>
    80004aec:	0792                	slli	a5,a5,0x4
    80004aee:	00023717          	auipc	a4,0x23
    80004af2:	2fa70713          	addi	a4,a4,762 # 80027de8 <devsw>
    80004af6:	97ba                	add	a5,a5,a4
    80004af8:	679c                	ld	a5,8(a5)
    80004afa:	cbdd                	beqz	a5,80004bb0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004afc:	4505                	li	a0,1
    80004afe:	9782                	jalr	a5
    80004b00:	8a2a                	mv	s4,a0
    80004b02:	a8a5                	j	80004b7a <filewrite+0xfa>
    80004b04:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	8b4080e7          	jalr	-1868(ra) # 800043bc <begin_op>
      ilock(f->ip);
    80004b10:	01893503          	ld	a0,24(s2)
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	edc080e7          	jalr	-292(ra) # 800039f0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b1c:	8756                	mv	a4,s5
    80004b1e:	02092683          	lw	a3,32(s2)
    80004b22:	01698633          	add	a2,s3,s6
    80004b26:	4585                	li	a1,1
    80004b28:	01893503          	ld	a0,24(s2)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	270080e7          	jalr	624(ra) # 80003d9c <writei>
    80004b34:	84aa                	mv	s1,a0
    80004b36:	00a05763          	blez	a0,80004b44 <filewrite+0xc4>
        f->off += r;
    80004b3a:	02092783          	lw	a5,32(s2)
    80004b3e:	9fa9                	addw	a5,a5,a0
    80004b40:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b44:	01893503          	ld	a0,24(s2)
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	f6a080e7          	jalr	-150(ra) # 80003ab2 <iunlock>
      end_op();
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	8ea080e7          	jalr	-1814(ra) # 8000443a <end_op>

      if(r != n1){
    80004b58:	009a9f63          	bne	s5,s1,80004b76 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b5c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b60:	0149db63          	bge	s3,s4,80004b76 <filewrite+0xf6>
      int n1 = n - i;
    80004b64:	413a04bb          	subw	s1,s4,s3
    80004b68:	0004879b          	sext.w	a5,s1
    80004b6c:	f8fbdce3          	bge	s7,a5,80004b04 <filewrite+0x84>
    80004b70:	84e2                	mv	s1,s8
    80004b72:	bf49                	j	80004b04 <filewrite+0x84>
    int i = 0;
    80004b74:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b76:	013a1f63          	bne	s4,s3,80004b94 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b7a:	8552                	mv	a0,s4
    80004b7c:	60a6                	ld	ra,72(sp)
    80004b7e:	6406                	ld	s0,64(sp)
    80004b80:	74e2                	ld	s1,56(sp)
    80004b82:	7942                	ld	s2,48(sp)
    80004b84:	79a2                	ld	s3,40(sp)
    80004b86:	7a02                	ld	s4,32(sp)
    80004b88:	6ae2                	ld	s5,24(sp)
    80004b8a:	6b42                	ld	s6,16(sp)
    80004b8c:	6ba2                	ld	s7,8(sp)
    80004b8e:	6c02                	ld	s8,0(sp)
    80004b90:	6161                	addi	sp,sp,80
    80004b92:	8082                	ret
    ret = (i == n ? n : -1);
    80004b94:	5a7d                	li	s4,-1
    80004b96:	b7d5                	j	80004b7a <filewrite+0xfa>
    panic("filewrite");
    80004b98:	00004517          	auipc	a0,0x4
    80004b9c:	b4050513          	addi	a0,a0,-1216 # 800086d8 <syscalls+0x288>
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	9a0080e7          	jalr	-1632(ra) # 80000540 <panic>
    return -1;
    80004ba8:	5a7d                	li	s4,-1
    80004baa:	bfc1                	j	80004b7a <filewrite+0xfa>
      return -1;
    80004bac:	5a7d                	li	s4,-1
    80004bae:	b7f1                	j	80004b7a <filewrite+0xfa>
    80004bb0:	5a7d                	li	s4,-1
    80004bb2:	b7e1                	j	80004b7a <filewrite+0xfa>

0000000080004bb4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bb4:	7179                	addi	sp,sp,-48
    80004bb6:	f406                	sd	ra,40(sp)
    80004bb8:	f022                	sd	s0,32(sp)
    80004bba:	ec26                	sd	s1,24(sp)
    80004bbc:	e84a                	sd	s2,16(sp)
    80004bbe:	e44e                	sd	s3,8(sp)
    80004bc0:	e052                	sd	s4,0(sp)
    80004bc2:	1800                	addi	s0,sp,48
    80004bc4:	84aa                	mv	s1,a0
    80004bc6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bc8:	0005b023          	sd	zero,0(a1)
    80004bcc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bd0:	00000097          	auipc	ra,0x0
    80004bd4:	bf8080e7          	jalr	-1032(ra) # 800047c8 <filealloc>
    80004bd8:	e088                	sd	a0,0(s1)
    80004bda:	c551                	beqz	a0,80004c66 <pipealloc+0xb2>
    80004bdc:	00000097          	auipc	ra,0x0
    80004be0:	bec080e7          	jalr	-1044(ra) # 800047c8 <filealloc>
    80004be4:	00aa3023          	sd	a0,0(s4)
    80004be8:	c92d                	beqz	a0,80004c5a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	efc080e7          	jalr	-260(ra) # 80000ae6 <kalloc>
    80004bf2:	892a                	mv	s2,a0
    80004bf4:	c125                	beqz	a0,80004c54 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bf6:	4985                	li	s3,1
    80004bf8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bfc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c00:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c04:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c08:	00004597          	auipc	a1,0x4
    80004c0c:	ae058593          	addi	a1,a1,-1312 # 800086e8 <syscalls+0x298>
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	f36080e7          	jalr	-202(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c18:	609c                	ld	a5,0(s1)
    80004c1a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c1e:	609c                	ld	a5,0(s1)
    80004c20:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c24:	609c                	ld	a5,0(s1)
    80004c26:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c2a:	609c                	ld	a5,0(s1)
    80004c2c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c30:	000a3783          	ld	a5,0(s4)
    80004c34:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c38:	000a3783          	ld	a5,0(s4)
    80004c3c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c40:	000a3783          	ld	a5,0(s4)
    80004c44:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c48:	000a3783          	ld	a5,0(s4)
    80004c4c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c50:	4501                	li	a0,0
    80004c52:	a025                	j	80004c7a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c54:	6088                	ld	a0,0(s1)
    80004c56:	e501                	bnez	a0,80004c5e <pipealloc+0xaa>
    80004c58:	a039                	j	80004c66 <pipealloc+0xb2>
    80004c5a:	6088                	ld	a0,0(s1)
    80004c5c:	c51d                	beqz	a0,80004c8a <pipealloc+0xd6>
    fileclose(*f0);
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	c26080e7          	jalr	-986(ra) # 80004884 <fileclose>
  if(*f1)
    80004c66:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c6a:	557d                	li	a0,-1
  if(*f1)
    80004c6c:	c799                	beqz	a5,80004c7a <pipealloc+0xc6>
    fileclose(*f1);
    80004c6e:	853e                	mv	a0,a5
    80004c70:	00000097          	auipc	ra,0x0
    80004c74:	c14080e7          	jalr	-1004(ra) # 80004884 <fileclose>
  return -1;
    80004c78:	557d                	li	a0,-1
}
    80004c7a:	70a2                	ld	ra,40(sp)
    80004c7c:	7402                	ld	s0,32(sp)
    80004c7e:	64e2                	ld	s1,24(sp)
    80004c80:	6942                	ld	s2,16(sp)
    80004c82:	69a2                	ld	s3,8(sp)
    80004c84:	6a02                	ld	s4,0(sp)
    80004c86:	6145                	addi	sp,sp,48
    80004c88:	8082                	ret
  return -1;
    80004c8a:	557d                	li	a0,-1
    80004c8c:	b7fd                	j	80004c7a <pipealloc+0xc6>

0000000080004c8e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c8e:	1101                	addi	sp,sp,-32
    80004c90:	ec06                	sd	ra,24(sp)
    80004c92:	e822                	sd	s0,16(sp)
    80004c94:	e426                	sd	s1,8(sp)
    80004c96:	e04a                	sd	s2,0(sp)
    80004c98:	1000                	addi	s0,sp,32
    80004c9a:	84aa                	mv	s1,a0
    80004c9c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	f38080e7          	jalr	-200(ra) # 80000bd6 <acquire>
  if(writable){
    80004ca6:	02090d63          	beqz	s2,80004ce0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004caa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cae:	21848513          	addi	a0,s1,536
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	446080e7          	jalr	1094(ra) # 800020f8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cba:	2204b783          	ld	a5,544(s1)
    80004cbe:	eb95                	bnez	a5,80004cf2 <pipeclose+0x64>
    release(&pi->lock);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	fc8080e7          	jalr	-56(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	d1c080e7          	jalr	-740(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004cd4:	60e2                	ld	ra,24(sp)
    80004cd6:	6442                	ld	s0,16(sp)
    80004cd8:	64a2                	ld	s1,8(sp)
    80004cda:	6902                	ld	s2,0(sp)
    80004cdc:	6105                	addi	sp,sp,32
    80004cde:	8082                	ret
    pi->readopen = 0;
    80004ce0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ce4:	21c48513          	addi	a0,s1,540
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	410080e7          	jalr	1040(ra) # 800020f8 <wakeup>
    80004cf0:	b7e9                	j	80004cba <pipeclose+0x2c>
    release(&pi->lock);
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80004cfc:	bfe1                	j	80004cd4 <pipeclose+0x46>

0000000080004cfe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cfe:	711d                	addi	sp,sp,-96
    80004d00:	ec86                	sd	ra,88(sp)
    80004d02:	e8a2                	sd	s0,80(sp)
    80004d04:	e4a6                	sd	s1,72(sp)
    80004d06:	e0ca                	sd	s2,64(sp)
    80004d08:	fc4e                	sd	s3,56(sp)
    80004d0a:	f852                	sd	s4,48(sp)
    80004d0c:	f456                	sd	s5,40(sp)
    80004d0e:	f05a                	sd	s6,32(sp)
    80004d10:	ec5e                	sd	s7,24(sp)
    80004d12:	e862                	sd	s8,16(sp)
    80004d14:	1080                	addi	s0,sp,96
    80004d16:	84aa                	mv	s1,a0
    80004d18:	8aae                	mv	s5,a1
    80004d1a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	c90080e7          	jalr	-880(ra) # 800019ac <myproc>
    80004d24:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d26:	8526                	mv	a0,s1
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	eae080e7          	jalr	-338(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d30:	0b405663          	blez	s4,80004ddc <pipewrite+0xde>
  int i = 0;
    80004d34:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d36:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d38:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d3c:	21c48b93          	addi	s7,s1,540
    80004d40:	a089                	j	80004d82 <pipewrite+0x84>
      release(&pi->lock);
    80004d42:	8526                	mv	a0,s1
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	f46080e7          	jalr	-186(ra) # 80000c8a <release>
      return -1;
    80004d4c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d4e:	854a                	mv	a0,s2
    80004d50:	60e6                	ld	ra,88(sp)
    80004d52:	6446                	ld	s0,80(sp)
    80004d54:	64a6                	ld	s1,72(sp)
    80004d56:	6906                	ld	s2,64(sp)
    80004d58:	79e2                	ld	s3,56(sp)
    80004d5a:	7a42                	ld	s4,48(sp)
    80004d5c:	7aa2                	ld	s5,40(sp)
    80004d5e:	7b02                	ld	s6,32(sp)
    80004d60:	6be2                	ld	s7,24(sp)
    80004d62:	6c42                	ld	s8,16(sp)
    80004d64:	6125                	addi	sp,sp,96
    80004d66:	8082                	ret
      wakeup(&pi->nread);
    80004d68:	8562                	mv	a0,s8
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	38e080e7          	jalr	910(ra) # 800020f8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d72:	85a6                	mv	a1,s1
    80004d74:	855e                	mv	a0,s7
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	31e080e7          	jalr	798(ra) # 80002094 <sleep>
  while(i < n){
    80004d7e:	07495063          	bge	s2,s4,80004dde <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d82:	2204a783          	lw	a5,544(s1)
    80004d86:	dfd5                	beqz	a5,80004d42 <pipewrite+0x44>
    80004d88:	854e                	mv	a0,s3
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	5be080e7          	jalr	1470(ra) # 80002348 <killed>
    80004d92:	f945                	bnez	a0,80004d42 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d94:	2184a783          	lw	a5,536(s1)
    80004d98:	21c4a703          	lw	a4,540(s1)
    80004d9c:	2007879b          	addiw	a5,a5,512
    80004da0:	fcf704e3          	beq	a4,a5,80004d68 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da4:	4685                	li	a3,1
    80004da6:	01590633          	add	a2,s2,s5
    80004daa:	faf40593          	addi	a1,s0,-81
    80004dae:	0d09b503          	ld	a0,208(s3)
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	946080e7          	jalr	-1722(ra) # 800016f8 <copyin>
    80004dba:	03650263          	beq	a0,s6,80004dde <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dbe:	21c4a783          	lw	a5,540(s1)
    80004dc2:	0017871b          	addiw	a4,a5,1
    80004dc6:	20e4ae23          	sw	a4,540(s1)
    80004dca:	1ff7f793          	andi	a5,a5,511
    80004dce:	97a6                	add	a5,a5,s1
    80004dd0:	faf44703          	lbu	a4,-81(s0)
    80004dd4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dd8:	2905                	addiw	s2,s2,1
    80004dda:	b755                	j	80004d7e <pipewrite+0x80>
  int i = 0;
    80004ddc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dde:	21848513          	addi	a0,s1,536
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	316080e7          	jalr	790(ra) # 800020f8 <wakeup>
  release(&pi->lock);
    80004dea:	8526                	mv	a0,s1
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	e9e080e7          	jalr	-354(ra) # 80000c8a <release>
  return i;
    80004df4:	bfa9                	j	80004d4e <pipewrite+0x50>

0000000080004df6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004df6:	715d                	addi	sp,sp,-80
    80004df8:	e486                	sd	ra,72(sp)
    80004dfa:	e0a2                	sd	s0,64(sp)
    80004dfc:	fc26                	sd	s1,56(sp)
    80004dfe:	f84a                	sd	s2,48(sp)
    80004e00:	f44e                	sd	s3,40(sp)
    80004e02:	f052                	sd	s4,32(sp)
    80004e04:	ec56                	sd	s5,24(sp)
    80004e06:	e85a                	sd	s6,16(sp)
    80004e08:	0880                	addi	s0,sp,80
    80004e0a:	84aa                	mv	s1,a0
    80004e0c:	892e                	mv	s2,a1
    80004e0e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	b9c080e7          	jalr	-1124(ra) # 800019ac <myproc>
    80004e18:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	dba080e7          	jalr	-582(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e24:	2184a703          	lw	a4,536(s1)
    80004e28:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e2c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e30:	02f71763          	bne	a4,a5,80004e5e <piperead+0x68>
    80004e34:	2244a783          	lw	a5,548(s1)
    80004e38:	c39d                	beqz	a5,80004e5e <piperead+0x68>
    if(killed(pr)){
    80004e3a:	8552                	mv	a0,s4
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	50c080e7          	jalr	1292(ra) # 80002348 <killed>
    80004e44:	e949                	bnez	a0,80004ed6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e46:	85a6                	mv	a1,s1
    80004e48:	854e                	mv	a0,s3
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	24a080e7          	jalr	586(ra) # 80002094 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e52:	2184a703          	lw	a4,536(s1)
    80004e56:	21c4a783          	lw	a5,540(s1)
    80004e5a:	fcf70de3          	beq	a4,a5,80004e34 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e60:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e62:	05505463          	blez	s5,80004eaa <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e66:	2184a783          	lw	a5,536(s1)
    80004e6a:	21c4a703          	lw	a4,540(s1)
    80004e6e:	02f70e63          	beq	a4,a5,80004eaa <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e72:	0017871b          	addiw	a4,a5,1
    80004e76:	20e4ac23          	sw	a4,536(s1)
    80004e7a:	1ff7f793          	andi	a5,a5,511
    80004e7e:	97a6                	add	a5,a5,s1
    80004e80:	0187c783          	lbu	a5,24(a5)
    80004e84:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e88:	4685                	li	a3,1
    80004e8a:	fbf40613          	addi	a2,s0,-65
    80004e8e:	85ca                	mv	a1,s2
    80004e90:	0d0a3503          	ld	a0,208(s4)
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	7d8080e7          	jalr	2008(ra) # 8000166c <copyout>
    80004e9c:	01650763          	beq	a0,s6,80004eaa <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ea0:	2985                	addiw	s3,s3,1
    80004ea2:	0905                	addi	s2,s2,1
    80004ea4:	fd3a91e3          	bne	s5,s3,80004e66 <piperead+0x70>
    80004ea8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eaa:	21c48513          	addi	a0,s1,540
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	24a080e7          	jalr	586(ra) # 800020f8 <wakeup>
  release(&pi->lock);
    80004eb6:	8526                	mv	a0,s1
    80004eb8:	ffffc097          	auipc	ra,0xffffc
    80004ebc:	dd2080e7          	jalr	-558(ra) # 80000c8a <release>
  return i;
}
    80004ec0:	854e                	mv	a0,s3
    80004ec2:	60a6                	ld	ra,72(sp)
    80004ec4:	6406                	ld	s0,64(sp)
    80004ec6:	74e2                	ld	s1,56(sp)
    80004ec8:	7942                	ld	s2,48(sp)
    80004eca:	79a2                	ld	s3,40(sp)
    80004ecc:	7a02                	ld	s4,32(sp)
    80004ece:	6ae2                	ld	s5,24(sp)
    80004ed0:	6b42                	ld	s6,16(sp)
    80004ed2:	6161                	addi	sp,sp,80
    80004ed4:	8082                	ret
      release(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	db2080e7          	jalr	-590(ra) # 80000c8a <release>
      return -1;
    80004ee0:	59fd                	li	s3,-1
    80004ee2:	bff9                	j	80004ec0 <piperead+0xca>

0000000080004ee4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ee4:	1141                	addi	sp,sp,-16
    80004ee6:	e422                	sd	s0,8(sp)
    80004ee8:	0800                	addi	s0,sp,16
    80004eea:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004eec:	8905                	andi	a0,a0,1
    80004eee:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ef0:	8b89                	andi	a5,a5,2
    80004ef2:	c399                	beqz	a5,80004ef8 <flags2perm+0x14>
      perm |= PTE_W;
    80004ef4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ef8:	6422                	ld	s0,8(sp)
    80004efa:	0141                	addi	sp,sp,16
    80004efc:	8082                	ret

0000000080004efe <exec>:

int
exec(char *path, char **argv)
{
    80004efe:	de010113          	addi	sp,sp,-544
    80004f02:	20113c23          	sd	ra,536(sp)
    80004f06:	20813823          	sd	s0,528(sp)
    80004f0a:	20913423          	sd	s1,520(sp)
    80004f0e:	21213023          	sd	s2,512(sp)
    80004f12:	ffce                	sd	s3,504(sp)
    80004f14:	fbd2                	sd	s4,496(sp)
    80004f16:	f7d6                	sd	s5,488(sp)
    80004f18:	f3da                	sd	s6,480(sp)
    80004f1a:	efde                	sd	s7,472(sp)
    80004f1c:	ebe2                	sd	s8,464(sp)
    80004f1e:	e7e6                	sd	s9,456(sp)
    80004f20:	e3ea                	sd	s10,448(sp)
    80004f22:	ff6e                	sd	s11,440(sp)
    80004f24:	1400                	addi	s0,sp,544
    80004f26:	892a                	mv	s2,a0
    80004f28:	dea43423          	sd	a0,-536(s0)
    80004f2c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	a7c080e7          	jalr	-1412(ra) # 800019ac <myproc>
    80004f38:	84aa                	mv	s1,a0

  begin_op();
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	482080e7          	jalr	1154(ra) # 800043bc <begin_op>

  if((ip = namei(path)) == 0){
    80004f42:	854a                	mv	a0,s2
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	258080e7          	jalr	600(ra) # 8000419c <namei>
    80004f4c:	c93d                	beqz	a0,80004fc2 <exec+0xc4>
    80004f4e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	aa0080e7          	jalr	-1376(ra) # 800039f0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f58:	04000713          	li	a4,64
    80004f5c:	4681                	li	a3,0
    80004f5e:	e5040613          	addi	a2,s0,-432
    80004f62:	4581                	li	a1,0
    80004f64:	8556                	mv	a0,s5
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	d3e080e7          	jalr	-706(ra) # 80003ca4 <readi>
    80004f6e:	04000793          	li	a5,64
    80004f72:	00f51a63          	bne	a0,a5,80004f86 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f76:	e5042703          	lw	a4,-432(s0)
    80004f7a:	464c47b7          	lui	a5,0x464c4
    80004f7e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f82:	04f70663          	beq	a4,a5,80004fce <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f86:	8556                	mv	a0,s5
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	cca080e7          	jalr	-822(ra) # 80003c52 <iunlockput>
    end_op();
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	4aa080e7          	jalr	1194(ra) # 8000443a <end_op>
  }
  return -1;
    80004f98:	557d                	li	a0,-1
}
    80004f9a:	21813083          	ld	ra,536(sp)
    80004f9e:	21013403          	ld	s0,528(sp)
    80004fa2:	20813483          	ld	s1,520(sp)
    80004fa6:	20013903          	ld	s2,512(sp)
    80004faa:	79fe                	ld	s3,504(sp)
    80004fac:	7a5e                	ld	s4,496(sp)
    80004fae:	7abe                	ld	s5,488(sp)
    80004fb0:	7b1e                	ld	s6,480(sp)
    80004fb2:	6bfe                	ld	s7,472(sp)
    80004fb4:	6c5e                	ld	s8,464(sp)
    80004fb6:	6cbe                	ld	s9,456(sp)
    80004fb8:	6d1e                	ld	s10,448(sp)
    80004fba:	7dfa                	ld	s11,440(sp)
    80004fbc:	22010113          	addi	sp,sp,544
    80004fc0:	8082                	ret
    end_op();
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	478080e7          	jalr	1144(ra) # 8000443a <end_op>
    return -1;
    80004fca:	557d                	li	a0,-1
    80004fcc:	b7f9                	j	80004f9a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fce:	8526                	mv	a0,s1
    80004fd0:	ffffd097          	auipc	ra,0xffffd
    80004fd4:	aa0080e7          	jalr	-1376(ra) # 80001a70 <proc_pagetable>
    80004fd8:	8b2a                	mv	s6,a0
    80004fda:	d555                	beqz	a0,80004f86 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fdc:	e7042783          	lw	a5,-400(s0)
    80004fe0:	e8845703          	lhu	a4,-376(s0)
    80004fe4:	c735                	beqz	a4,80005050 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fe6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fec:	6a05                	lui	s4,0x1
    80004fee:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ff2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004ff6:	6d85                	lui	s11,0x1
    80004ff8:	7d7d                	lui	s10,0xfffff
    80004ffa:	ac3d                	j	80005238 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ffc:	00003517          	auipc	a0,0x3
    80005000:	6f450513          	addi	a0,a0,1780 # 800086f0 <syscalls+0x2a0>
    80005004:	ffffb097          	auipc	ra,0xffffb
    80005008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000500c:	874a                	mv	a4,s2
    8000500e:	009c86bb          	addw	a3,s9,s1
    80005012:	4581                	li	a1,0
    80005014:	8556                	mv	a0,s5
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	c8e080e7          	jalr	-882(ra) # 80003ca4 <readi>
    8000501e:	2501                	sext.w	a0,a0
    80005020:	1aa91963          	bne	s2,a0,800051d2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005024:	009d84bb          	addw	s1,s11,s1
    80005028:	013d09bb          	addw	s3,s10,s3
    8000502c:	1f74f663          	bgeu	s1,s7,80005218 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005030:	02049593          	slli	a1,s1,0x20
    80005034:	9181                	srli	a1,a1,0x20
    80005036:	95e2                	add	a1,a1,s8
    80005038:	855a                	mv	a0,s6
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	022080e7          	jalr	34(ra) # 8000105c <walkaddr>
    80005042:	862a                	mv	a2,a0
    if(pa == 0)
    80005044:	dd45                	beqz	a0,80004ffc <exec+0xfe>
      n = PGSIZE;
    80005046:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005048:	fd49f2e3          	bgeu	s3,s4,8000500c <exec+0x10e>
      n = sz - i;
    8000504c:	894e                	mv	s2,s3
    8000504e:	bf7d                	j	8000500c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005050:	4901                	li	s2,0
  iunlockput(ip);
    80005052:	8556                	mv	a0,s5
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	bfe080e7          	jalr	-1026(ra) # 80003c52 <iunlockput>
  end_op();
    8000505c:	fffff097          	auipc	ra,0xfffff
    80005060:	3de080e7          	jalr	990(ra) # 8000443a <end_op>
  p = myproc();
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	948080e7          	jalr	-1720(ra) # 800019ac <myproc>
    8000506c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000506e:	0c853d03          	ld	s10,200(a0)
  sz = PGROUNDUP(sz);
    80005072:	6785                	lui	a5,0x1
    80005074:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005076:	97ca                	add	a5,a5,s2
    80005078:	777d                	lui	a4,0xfffff
    8000507a:	8ff9                	and	a5,a5,a4
    8000507c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005080:	4691                	li	a3,4
    80005082:	6609                	lui	a2,0x2
    80005084:	963e                	add	a2,a2,a5
    80005086:	85be                	mv	a1,a5
    80005088:	855a                	mv	a0,s6
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	386080e7          	jalr	902(ra) # 80001410 <uvmalloc>
    80005092:	8c2a                	mv	s8,a0
  ip = 0;
    80005094:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005096:	12050e63          	beqz	a0,800051d2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000509a:	75f9                	lui	a1,0xffffe
    8000509c:	95aa                	add	a1,a1,a0
    8000509e:	855a                	mv	a0,s6
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	59a080e7          	jalr	1434(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800050a8:	7afd                	lui	s5,0xfffff
    800050aa:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ac:	df043783          	ld	a5,-528(s0)
    800050b0:	6388                	ld	a0,0(a5)
    800050b2:	c925                	beqz	a0,80005122 <exec+0x224>
    800050b4:	e9040993          	addi	s3,s0,-368
    800050b8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050bc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050be:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	d8e080e7          	jalr	-626(ra) # 80000e4e <strlen>
    800050c8:	0015079b          	addiw	a5,a0,1
    800050cc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050d0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050d4:	13596663          	bltu	s2,s5,80005200 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050d8:	df043d83          	ld	s11,-528(s0)
    800050dc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050e0:	8552                	mv	a0,s4
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	d6c080e7          	jalr	-660(ra) # 80000e4e <strlen>
    800050ea:	0015069b          	addiw	a3,a0,1
    800050ee:	8652                	mv	a2,s4
    800050f0:	85ca                	mv	a1,s2
    800050f2:	855a                	mv	a0,s6
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	578080e7          	jalr	1400(ra) # 8000166c <copyout>
    800050fc:	10054663          	bltz	a0,80005208 <exec+0x30a>
    ustack[argc] = sp;
    80005100:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005104:	0485                	addi	s1,s1,1
    80005106:	008d8793          	addi	a5,s11,8
    8000510a:	def43823          	sd	a5,-528(s0)
    8000510e:	008db503          	ld	a0,8(s11)
    80005112:	c911                	beqz	a0,80005126 <exec+0x228>
    if(argc >= MAXARG)
    80005114:	09a1                	addi	s3,s3,8
    80005116:	fb3c95e3          	bne	s9,s3,800050c0 <exec+0x1c2>
  sz = sz1;
    8000511a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511e:	4a81                	li	s5,0
    80005120:	a84d                	j	800051d2 <exec+0x2d4>
  sp = sz;
    80005122:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005124:	4481                	li	s1,0
  ustack[argc] = 0;
    80005126:	00349793          	slli	a5,s1,0x3
    8000512a:	f9078793          	addi	a5,a5,-112
    8000512e:	97a2                	add	a5,a5,s0
    80005130:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005134:	00148693          	addi	a3,s1,1
    80005138:	068e                	slli	a3,a3,0x3
    8000513a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000513e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005142:	01597663          	bgeu	s2,s5,8000514e <exec+0x250>
  sz = sz1;
    80005146:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000514a:	4a81                	li	s5,0
    8000514c:	a059                	j	800051d2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000514e:	e9040613          	addi	a2,s0,-368
    80005152:	85ca                	mv	a1,s2
    80005154:	855a                	mv	a0,s6
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	516080e7          	jalr	1302(ra) # 8000166c <copyout>
    8000515e:	0a054963          	bltz	a0,80005210 <exec+0x312>
  p->trapframe->a1 = sp;
    80005162:	0d8bb783          	ld	a5,216(s7)
    80005166:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000516a:	de843783          	ld	a5,-536(s0)
    8000516e:	0007c703          	lbu	a4,0(a5)
    80005172:	cf11                	beqz	a4,8000518e <exec+0x290>
    80005174:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005176:	02f00693          	li	a3,47
    8000517a:	a039                	j	80005188 <exec+0x28a>
      last = s+1;
    8000517c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005180:	0785                	addi	a5,a5,1
    80005182:	fff7c703          	lbu	a4,-1(a5)
    80005186:	c701                	beqz	a4,8000518e <exec+0x290>
    if(*s == '/')
    80005188:	fed71ce3          	bne	a4,a3,80005180 <exec+0x282>
    8000518c:	bfc5                	j	8000517c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000518e:	4641                	li	a2,16
    80005190:	de843583          	ld	a1,-536(s0)
    80005194:	1d8b8513          	addi	a0,s7,472
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	c84080e7          	jalr	-892(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051a0:	0d0bb503          	ld	a0,208(s7)
  p->pagetable = pagetable;
    800051a4:	0d6bb823          	sd	s6,208(s7)
  p->sz = sz;
    800051a8:	0d8bb423          	sd	s8,200(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051ac:	0d8bb783          	ld	a5,216(s7)
    800051b0:	e6843703          	ld	a4,-408(s0)
    800051b4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051b6:	0d8bb783          	ld	a5,216(s7)
    800051ba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051be:	85ea                	mv	a1,s10
    800051c0:	ffffd097          	auipc	ra,0xffffd
    800051c4:	94c080e7          	jalr	-1716(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051c8:	0004851b          	sext.w	a0,s1
    800051cc:	b3f9                	j	80004f9a <exec+0x9c>
    800051ce:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051d2:	df843583          	ld	a1,-520(s0)
    800051d6:	855a                	mv	a0,s6
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	934080e7          	jalr	-1740(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051e0:	da0a93e3          	bnez	s5,80004f86 <exec+0x88>
  return -1;
    800051e4:	557d                	li	a0,-1
    800051e6:	bb55                	j	80004f9a <exec+0x9c>
    800051e8:	df243c23          	sd	s2,-520(s0)
    800051ec:	b7dd                	j	800051d2 <exec+0x2d4>
    800051ee:	df243c23          	sd	s2,-520(s0)
    800051f2:	b7c5                	j	800051d2 <exec+0x2d4>
    800051f4:	df243c23          	sd	s2,-520(s0)
    800051f8:	bfe9                	j	800051d2 <exec+0x2d4>
    800051fa:	df243c23          	sd	s2,-520(s0)
    800051fe:	bfd1                	j	800051d2 <exec+0x2d4>
  sz = sz1;
    80005200:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005204:	4a81                	li	s5,0
    80005206:	b7f1                	j	800051d2 <exec+0x2d4>
  sz = sz1;
    80005208:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000520c:	4a81                	li	s5,0
    8000520e:	b7d1                	j	800051d2 <exec+0x2d4>
  sz = sz1;
    80005210:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005214:	4a81                	li	s5,0
    80005216:	bf75                	j	800051d2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005218:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000521c:	e0843783          	ld	a5,-504(s0)
    80005220:	0017869b          	addiw	a3,a5,1
    80005224:	e0d43423          	sd	a3,-504(s0)
    80005228:	e0043783          	ld	a5,-512(s0)
    8000522c:	0387879b          	addiw	a5,a5,56
    80005230:	e8845703          	lhu	a4,-376(s0)
    80005234:	e0e6dfe3          	bge	a3,a4,80005052 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005238:	2781                	sext.w	a5,a5
    8000523a:	e0f43023          	sd	a5,-512(s0)
    8000523e:	03800713          	li	a4,56
    80005242:	86be                	mv	a3,a5
    80005244:	e1840613          	addi	a2,s0,-488
    80005248:	4581                	li	a1,0
    8000524a:	8556                	mv	a0,s5
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	a58080e7          	jalr	-1448(ra) # 80003ca4 <readi>
    80005254:	03800793          	li	a5,56
    80005258:	f6f51be3          	bne	a0,a5,800051ce <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000525c:	e1842783          	lw	a5,-488(s0)
    80005260:	4705                	li	a4,1
    80005262:	fae79de3          	bne	a5,a4,8000521c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005266:	e4043483          	ld	s1,-448(s0)
    8000526a:	e3843783          	ld	a5,-456(s0)
    8000526e:	f6f4ede3          	bltu	s1,a5,800051e8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005272:	e2843783          	ld	a5,-472(s0)
    80005276:	94be                	add	s1,s1,a5
    80005278:	f6f4ebe3          	bltu	s1,a5,800051ee <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000527c:	de043703          	ld	a4,-544(s0)
    80005280:	8ff9                	and	a5,a5,a4
    80005282:	fbad                	bnez	a5,800051f4 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005284:	e1c42503          	lw	a0,-484(s0)
    80005288:	00000097          	auipc	ra,0x0
    8000528c:	c5c080e7          	jalr	-932(ra) # 80004ee4 <flags2perm>
    80005290:	86aa                	mv	a3,a0
    80005292:	8626                	mv	a2,s1
    80005294:	85ca                	mv	a1,s2
    80005296:	855a                	mv	a0,s6
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	178080e7          	jalr	376(ra) # 80001410 <uvmalloc>
    800052a0:	dea43c23          	sd	a0,-520(s0)
    800052a4:	d939                	beqz	a0,800051fa <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052a6:	e2843c03          	ld	s8,-472(s0)
    800052aa:	e2042c83          	lw	s9,-480(s0)
    800052ae:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052b2:	f60b83e3          	beqz	s7,80005218 <exec+0x31a>
    800052b6:	89de                	mv	s3,s7
    800052b8:	4481                	li	s1,0
    800052ba:	bb9d                	j	80005030 <exec+0x132>

00000000800052bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052bc:	7179                	addi	sp,sp,-48
    800052be:	f406                	sd	ra,40(sp)
    800052c0:	f022                	sd	s0,32(sp)
    800052c2:	ec26                	sd	s1,24(sp)
    800052c4:	e84a                	sd	s2,16(sp)
    800052c6:	1800                	addi	s0,sp,48
    800052c8:	892e                	mv	s2,a1
    800052ca:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052cc:	fdc40593          	addi	a1,s0,-36
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	a4e080e7          	jalr	-1458(ra) # 80002d1e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052d8:	fdc42703          	lw	a4,-36(s0)
    800052dc:	47bd                	li	a5,15
    800052de:	02e7eb63          	bltu	a5,a4,80005314 <argfd+0x58>
    800052e2:	ffffc097          	auipc	ra,0xffffc
    800052e6:	6ca080e7          	jalr	1738(ra) # 800019ac <myproc>
    800052ea:	fdc42703          	lw	a4,-36(s0)
    800052ee:	02a70793          	addi	a5,a4,42 # fffffffffffff02a <end+0xffffffff7ffd60aa>
    800052f2:	078e                	slli	a5,a5,0x3
    800052f4:	953e                	add	a0,a0,a5
    800052f6:	611c                	ld	a5,0(a0)
    800052f8:	c385                	beqz	a5,80005318 <argfd+0x5c>
    return -1;
  if(pfd)
    800052fa:	00090463          	beqz	s2,80005302 <argfd+0x46>
    *pfd = fd;
    800052fe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005302:	4501                	li	a0,0
  if(pf)
    80005304:	c091                	beqz	s1,80005308 <argfd+0x4c>
    *pf = f;
    80005306:	e09c                	sd	a5,0(s1)
}
    80005308:	70a2                	ld	ra,40(sp)
    8000530a:	7402                	ld	s0,32(sp)
    8000530c:	64e2                	ld	s1,24(sp)
    8000530e:	6942                	ld	s2,16(sp)
    80005310:	6145                	addi	sp,sp,48
    80005312:	8082                	ret
    return -1;
    80005314:	557d                	li	a0,-1
    80005316:	bfcd                	j	80005308 <argfd+0x4c>
    80005318:	557d                	li	a0,-1
    8000531a:	b7fd                	j	80005308 <argfd+0x4c>

000000008000531c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000531c:	1101                	addi	sp,sp,-32
    8000531e:	ec06                	sd	ra,24(sp)
    80005320:	e822                	sd	s0,16(sp)
    80005322:	e426                	sd	s1,8(sp)
    80005324:	1000                	addi	s0,sp,32
    80005326:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	684080e7          	jalr	1668(ra) # 800019ac <myproc>
    80005330:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005332:	15050793          	addi	a5,a0,336
    80005336:	4501                	li	a0,0
    80005338:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000533a:	6398                	ld	a4,0(a5)
    8000533c:	cb19                	beqz	a4,80005352 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000533e:	2505                	addiw	a0,a0,1
    80005340:	07a1                	addi	a5,a5,8
    80005342:	fed51ce3          	bne	a0,a3,8000533a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005346:	557d                	li	a0,-1
}
    80005348:	60e2                	ld	ra,24(sp)
    8000534a:	6442                	ld	s0,16(sp)
    8000534c:	64a2                	ld	s1,8(sp)
    8000534e:	6105                	addi	sp,sp,32
    80005350:	8082                	ret
      p->ofile[fd] = f;
    80005352:	02a50793          	addi	a5,a0,42
    80005356:	078e                	slli	a5,a5,0x3
    80005358:	963e                	add	a2,a2,a5
    8000535a:	e204                	sd	s1,0(a2)
      return fd;
    8000535c:	b7f5                	j	80005348 <fdalloc+0x2c>

000000008000535e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000535e:	715d                	addi	sp,sp,-80
    80005360:	e486                	sd	ra,72(sp)
    80005362:	e0a2                	sd	s0,64(sp)
    80005364:	fc26                	sd	s1,56(sp)
    80005366:	f84a                	sd	s2,48(sp)
    80005368:	f44e                	sd	s3,40(sp)
    8000536a:	f052                	sd	s4,32(sp)
    8000536c:	ec56                	sd	s5,24(sp)
    8000536e:	e85a                	sd	s6,16(sp)
    80005370:	0880                	addi	s0,sp,80
    80005372:	8b2e                	mv	s6,a1
    80005374:	89b2                	mv	s3,a2
    80005376:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005378:	fb040593          	addi	a1,s0,-80
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	e3e080e7          	jalr	-450(ra) # 800041ba <nameiparent>
    80005384:	84aa                	mv	s1,a0
    80005386:	14050f63          	beqz	a0,800054e4 <create+0x186>
    return 0;

  ilock(dp);
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	666080e7          	jalr	1638(ra) # 800039f0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005392:	4601                	li	a2,0
    80005394:	fb040593          	addi	a1,s0,-80
    80005398:	8526                	mv	a0,s1
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	b3a080e7          	jalr	-1222(ra) # 80003ed4 <dirlookup>
    800053a2:	8aaa                	mv	s5,a0
    800053a4:	c931                	beqz	a0,800053f8 <create+0x9a>
    iunlockput(dp);
    800053a6:	8526                	mv	a0,s1
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	8aa080e7          	jalr	-1878(ra) # 80003c52 <iunlockput>
    ilock(ip);
    800053b0:	8556                	mv	a0,s5
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	63e080e7          	jalr	1598(ra) # 800039f0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053ba:	000b059b          	sext.w	a1,s6
    800053be:	4789                	li	a5,2
    800053c0:	02f59563          	bne	a1,a5,800053ea <create+0x8c>
    800053c4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd60c4>
    800053c8:	37f9                	addiw	a5,a5,-2
    800053ca:	17c2                	slli	a5,a5,0x30
    800053cc:	93c1                	srli	a5,a5,0x30
    800053ce:	4705                	li	a4,1
    800053d0:	00f76d63          	bltu	a4,a5,800053ea <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053d4:	8556                	mv	a0,s5
    800053d6:	60a6                	ld	ra,72(sp)
    800053d8:	6406                	ld	s0,64(sp)
    800053da:	74e2                	ld	s1,56(sp)
    800053dc:	7942                	ld	s2,48(sp)
    800053de:	79a2                	ld	s3,40(sp)
    800053e0:	7a02                	ld	s4,32(sp)
    800053e2:	6ae2                	ld	s5,24(sp)
    800053e4:	6b42                	ld	s6,16(sp)
    800053e6:	6161                	addi	sp,sp,80
    800053e8:	8082                	ret
    iunlockput(ip);
    800053ea:	8556                	mv	a0,s5
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	866080e7          	jalr	-1946(ra) # 80003c52 <iunlockput>
    return 0;
    800053f4:	4a81                	li	s5,0
    800053f6:	bff9                	j	800053d4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053f8:	85da                	mv	a1,s6
    800053fa:	4088                	lw	a0,0(s1)
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	456080e7          	jalr	1110(ra) # 80003852 <ialloc>
    80005404:	8a2a                	mv	s4,a0
    80005406:	c539                	beqz	a0,80005454 <create+0xf6>
  ilock(ip);
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	5e8080e7          	jalr	1512(ra) # 800039f0 <ilock>
  ip->major = major;
    80005410:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005414:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005418:	4905                	li	s2,1
    8000541a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000541e:	8552                	mv	a0,s4
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	504080e7          	jalr	1284(ra) # 80003924 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005428:	000b059b          	sext.w	a1,s6
    8000542c:	03258b63          	beq	a1,s2,80005462 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005430:	004a2603          	lw	a2,4(s4)
    80005434:	fb040593          	addi	a1,s0,-80
    80005438:	8526                	mv	a0,s1
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	cb0080e7          	jalr	-848(ra) # 800040ea <dirlink>
    80005442:	06054f63          	bltz	a0,800054c0 <create+0x162>
  iunlockput(dp);
    80005446:	8526                	mv	a0,s1
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	80a080e7          	jalr	-2038(ra) # 80003c52 <iunlockput>
  return ip;
    80005450:	8ad2                	mv	s5,s4
    80005452:	b749                	j	800053d4 <create+0x76>
    iunlockput(dp);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	7fc080e7          	jalr	2044(ra) # 80003c52 <iunlockput>
    return 0;
    8000545e:	8ad2                	mv	s5,s4
    80005460:	bf95                	j	800053d4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005462:	004a2603          	lw	a2,4(s4)
    80005466:	00003597          	auipc	a1,0x3
    8000546a:	2aa58593          	addi	a1,a1,682 # 80008710 <syscalls+0x2c0>
    8000546e:	8552                	mv	a0,s4
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	c7a080e7          	jalr	-902(ra) # 800040ea <dirlink>
    80005478:	04054463          	bltz	a0,800054c0 <create+0x162>
    8000547c:	40d0                	lw	a2,4(s1)
    8000547e:	00003597          	auipc	a1,0x3
    80005482:	29a58593          	addi	a1,a1,666 # 80008718 <syscalls+0x2c8>
    80005486:	8552                	mv	a0,s4
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	c62080e7          	jalr	-926(ra) # 800040ea <dirlink>
    80005490:	02054863          	bltz	a0,800054c0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005494:	004a2603          	lw	a2,4(s4)
    80005498:	fb040593          	addi	a1,s0,-80
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	c4c080e7          	jalr	-948(ra) # 800040ea <dirlink>
    800054a6:	00054d63          	bltz	a0,800054c0 <create+0x162>
    dp->nlink++;  // for ".."
    800054aa:	04a4d783          	lhu	a5,74(s1)
    800054ae:	2785                	addiw	a5,a5,1
    800054b0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	46e080e7          	jalr	1134(ra) # 80003924 <iupdate>
    800054be:	b761                	j	80005446 <create+0xe8>
  ip->nlink = 0;
    800054c0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054c4:	8552                	mv	a0,s4
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	45e080e7          	jalr	1118(ra) # 80003924 <iupdate>
  iunlockput(ip);
    800054ce:	8552                	mv	a0,s4
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	782080e7          	jalr	1922(ra) # 80003c52 <iunlockput>
  iunlockput(dp);
    800054d8:	8526                	mv	a0,s1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	778080e7          	jalr	1912(ra) # 80003c52 <iunlockput>
  return 0;
    800054e2:	bdcd                	j	800053d4 <create+0x76>
    return 0;
    800054e4:	8aaa                	mv	s5,a0
    800054e6:	b5fd                	j	800053d4 <create+0x76>

00000000800054e8 <sys_dup>:
{
    800054e8:	7179                	addi	sp,sp,-48
    800054ea:	f406                	sd	ra,40(sp)
    800054ec:	f022                	sd	s0,32(sp)
    800054ee:	ec26                	sd	s1,24(sp)
    800054f0:	e84a                	sd	s2,16(sp)
    800054f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054f4:	fd840613          	addi	a2,s0,-40
    800054f8:	4581                	li	a1,0
    800054fa:	4501                	li	a0,0
    800054fc:	00000097          	auipc	ra,0x0
    80005500:	dc0080e7          	jalr	-576(ra) # 800052bc <argfd>
    return -1;
    80005504:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005506:	02054363          	bltz	a0,8000552c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000550a:	fd843903          	ld	s2,-40(s0)
    8000550e:	854a                	mv	a0,s2
    80005510:	00000097          	auipc	ra,0x0
    80005514:	e0c080e7          	jalr	-500(ra) # 8000531c <fdalloc>
    80005518:	84aa                	mv	s1,a0
    return -1;
    8000551a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000551c:	00054863          	bltz	a0,8000552c <sys_dup+0x44>
  filedup(f);
    80005520:	854a                	mv	a0,s2
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	310080e7          	jalr	784(ra) # 80004832 <filedup>
  return fd;
    8000552a:	87a6                	mv	a5,s1
}
    8000552c:	853e                	mv	a0,a5
    8000552e:	70a2                	ld	ra,40(sp)
    80005530:	7402                	ld	s0,32(sp)
    80005532:	64e2                	ld	s1,24(sp)
    80005534:	6942                	ld	s2,16(sp)
    80005536:	6145                	addi	sp,sp,48
    80005538:	8082                	ret

000000008000553a <sys_read>:
{
    8000553a:	7179                	addi	sp,sp,-48
    8000553c:	f406                	sd	ra,40(sp)
    8000553e:	f022                	sd	s0,32(sp)
    80005540:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005542:	fd840593          	addi	a1,s0,-40
    80005546:	4505                	li	a0,1
    80005548:	ffffd097          	auipc	ra,0xffffd
    8000554c:	7f6080e7          	jalr	2038(ra) # 80002d3e <argaddr>
  argint(2, &n);
    80005550:	fe440593          	addi	a1,s0,-28
    80005554:	4509                	li	a0,2
    80005556:	ffffd097          	auipc	ra,0xffffd
    8000555a:	7c8080e7          	jalr	1992(ra) # 80002d1e <argint>
  if(argfd(0, 0, &f) < 0)
    8000555e:	fe840613          	addi	a2,s0,-24
    80005562:	4581                	li	a1,0
    80005564:	4501                	li	a0,0
    80005566:	00000097          	auipc	ra,0x0
    8000556a:	d56080e7          	jalr	-682(ra) # 800052bc <argfd>
    8000556e:	87aa                	mv	a5,a0
    return -1;
    80005570:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005572:	0007cc63          	bltz	a5,8000558a <sys_read+0x50>
  return fileread(f, p, n);
    80005576:	fe442603          	lw	a2,-28(s0)
    8000557a:	fd843583          	ld	a1,-40(s0)
    8000557e:	fe843503          	ld	a0,-24(s0)
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	43c080e7          	jalr	1084(ra) # 800049be <fileread>
}
    8000558a:	70a2                	ld	ra,40(sp)
    8000558c:	7402                	ld	s0,32(sp)
    8000558e:	6145                	addi	sp,sp,48
    80005590:	8082                	ret

0000000080005592 <sys_write>:
{
    80005592:	7179                	addi	sp,sp,-48
    80005594:	f406                	sd	ra,40(sp)
    80005596:	f022                	sd	s0,32(sp)
    80005598:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000559a:	fd840593          	addi	a1,s0,-40
    8000559e:	4505                	li	a0,1
    800055a0:	ffffd097          	auipc	ra,0xffffd
    800055a4:	79e080e7          	jalr	1950(ra) # 80002d3e <argaddr>
  argint(2, &n);
    800055a8:	fe440593          	addi	a1,s0,-28
    800055ac:	4509                	li	a0,2
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	770080e7          	jalr	1904(ra) # 80002d1e <argint>
  if(argfd(0, 0, &f) < 0)
    800055b6:	fe840613          	addi	a2,s0,-24
    800055ba:	4581                	li	a1,0
    800055bc:	4501                	li	a0,0
    800055be:	00000097          	auipc	ra,0x0
    800055c2:	cfe080e7          	jalr	-770(ra) # 800052bc <argfd>
    800055c6:	87aa                	mv	a5,a0
    return -1;
    800055c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ca:	0007cc63          	bltz	a5,800055e2 <sys_write+0x50>
  return filewrite(f, p, n);
    800055ce:	fe442603          	lw	a2,-28(s0)
    800055d2:	fd843583          	ld	a1,-40(s0)
    800055d6:	fe843503          	ld	a0,-24(s0)
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	4a6080e7          	jalr	1190(ra) # 80004a80 <filewrite>
}
    800055e2:	70a2                	ld	ra,40(sp)
    800055e4:	7402                	ld	s0,32(sp)
    800055e6:	6145                	addi	sp,sp,48
    800055e8:	8082                	ret

00000000800055ea <sys_close>:
{
    800055ea:	1101                	addi	sp,sp,-32
    800055ec:	ec06                	sd	ra,24(sp)
    800055ee:	e822                	sd	s0,16(sp)
    800055f0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055f2:	fe040613          	addi	a2,s0,-32
    800055f6:	fec40593          	addi	a1,s0,-20
    800055fa:	4501                	li	a0,0
    800055fc:	00000097          	auipc	ra,0x0
    80005600:	cc0080e7          	jalr	-832(ra) # 800052bc <argfd>
    return -1;
    80005604:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005606:	02054563          	bltz	a0,80005630 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	3a2080e7          	jalr	930(ra) # 800019ac <myproc>
    80005612:	fec42783          	lw	a5,-20(s0)
    80005616:	02a78793          	addi	a5,a5,42
    8000561a:	078e                	slli	a5,a5,0x3
    8000561c:	953e                	add	a0,a0,a5
    8000561e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005622:	fe043503          	ld	a0,-32(s0)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	25e080e7          	jalr	606(ra) # 80004884 <fileclose>
  return 0;
    8000562e:	4781                	li	a5,0
}
    80005630:	853e                	mv	a0,a5
    80005632:	60e2                	ld	ra,24(sp)
    80005634:	6442                	ld	s0,16(sp)
    80005636:	6105                	addi	sp,sp,32
    80005638:	8082                	ret

000000008000563a <sys_fstat>:
{
    8000563a:	1101                	addi	sp,sp,-32
    8000563c:	ec06                	sd	ra,24(sp)
    8000563e:	e822                	sd	s0,16(sp)
    80005640:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005642:	fe040593          	addi	a1,s0,-32
    80005646:	4505                	li	a0,1
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	6f6080e7          	jalr	1782(ra) # 80002d3e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005650:	fe840613          	addi	a2,s0,-24
    80005654:	4581                	li	a1,0
    80005656:	4501                	li	a0,0
    80005658:	00000097          	auipc	ra,0x0
    8000565c:	c64080e7          	jalr	-924(ra) # 800052bc <argfd>
    80005660:	87aa                	mv	a5,a0
    return -1;
    80005662:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005664:	0007ca63          	bltz	a5,80005678 <sys_fstat+0x3e>
  return filestat(f, st);
    80005668:	fe043583          	ld	a1,-32(s0)
    8000566c:	fe843503          	ld	a0,-24(s0)
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	2dc080e7          	jalr	732(ra) # 8000494c <filestat>
}
    80005678:	60e2                	ld	ra,24(sp)
    8000567a:	6442                	ld	s0,16(sp)
    8000567c:	6105                	addi	sp,sp,32
    8000567e:	8082                	ret

0000000080005680 <sys_link>:
{
    80005680:	7169                	addi	sp,sp,-304
    80005682:	f606                	sd	ra,296(sp)
    80005684:	f222                	sd	s0,288(sp)
    80005686:	ee26                	sd	s1,280(sp)
    80005688:	ea4a                	sd	s2,272(sp)
    8000568a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000568c:	08000613          	li	a2,128
    80005690:	ed040593          	addi	a1,s0,-304
    80005694:	4501                	li	a0,0
    80005696:	ffffd097          	auipc	ra,0xffffd
    8000569a:	6c8080e7          	jalr	1736(ra) # 80002d5e <argstr>
    return -1;
    8000569e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a0:	10054e63          	bltz	a0,800057bc <sys_link+0x13c>
    800056a4:	08000613          	li	a2,128
    800056a8:	f5040593          	addi	a1,s0,-176
    800056ac:	4505                	li	a0,1
    800056ae:	ffffd097          	auipc	ra,0xffffd
    800056b2:	6b0080e7          	jalr	1712(ra) # 80002d5e <argstr>
    return -1;
    800056b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b8:	10054263          	bltz	a0,800057bc <sys_link+0x13c>
  begin_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	d00080e7          	jalr	-768(ra) # 800043bc <begin_op>
  if((ip = namei(old)) == 0){
    800056c4:	ed040513          	addi	a0,s0,-304
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	ad4080e7          	jalr	-1324(ra) # 8000419c <namei>
    800056d0:	84aa                	mv	s1,a0
    800056d2:	c551                	beqz	a0,8000575e <sys_link+0xde>
  ilock(ip);
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	31c080e7          	jalr	796(ra) # 800039f0 <ilock>
  if(ip->type == T_DIR){
    800056dc:	04449703          	lh	a4,68(s1)
    800056e0:	4785                	li	a5,1
    800056e2:	08f70463          	beq	a4,a5,8000576a <sys_link+0xea>
  ip->nlink++;
    800056e6:	04a4d783          	lhu	a5,74(s1)
    800056ea:	2785                	addiw	a5,a5,1
    800056ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	232080e7          	jalr	562(ra) # 80003924 <iupdate>
  iunlock(ip);
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	3b6080e7          	jalr	950(ra) # 80003ab2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005704:	fd040593          	addi	a1,s0,-48
    80005708:	f5040513          	addi	a0,s0,-176
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	aae080e7          	jalr	-1362(ra) # 800041ba <nameiparent>
    80005714:	892a                	mv	s2,a0
    80005716:	c935                	beqz	a0,8000578a <sys_link+0x10a>
  ilock(dp);
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	2d8080e7          	jalr	728(ra) # 800039f0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005720:	00092703          	lw	a4,0(s2)
    80005724:	409c                	lw	a5,0(s1)
    80005726:	04f71d63          	bne	a4,a5,80005780 <sys_link+0x100>
    8000572a:	40d0                	lw	a2,4(s1)
    8000572c:	fd040593          	addi	a1,s0,-48
    80005730:	854a                	mv	a0,s2
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	9b8080e7          	jalr	-1608(ra) # 800040ea <dirlink>
    8000573a:	04054363          	bltz	a0,80005780 <sys_link+0x100>
  iunlockput(dp);
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	512080e7          	jalr	1298(ra) # 80003c52 <iunlockput>
  iput(ip);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	460080e7          	jalr	1120(ra) # 80003baa <iput>
  end_op();
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	ce8080e7          	jalr	-792(ra) # 8000443a <end_op>
  return 0;
    8000575a:	4781                	li	a5,0
    8000575c:	a085                	j	800057bc <sys_link+0x13c>
    end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	cdc080e7          	jalr	-804(ra) # 8000443a <end_op>
    return -1;
    80005766:	57fd                	li	a5,-1
    80005768:	a891                	j	800057bc <sys_link+0x13c>
    iunlockput(ip);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	4e6080e7          	jalr	1254(ra) # 80003c52 <iunlockput>
    end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	cc6080e7          	jalr	-826(ra) # 8000443a <end_op>
    return -1;
    8000577c:	57fd                	li	a5,-1
    8000577e:	a83d                	j	800057bc <sys_link+0x13c>
    iunlockput(dp);
    80005780:	854a                	mv	a0,s2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	4d0080e7          	jalr	1232(ra) # 80003c52 <iunlockput>
  ilock(ip);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	264080e7          	jalr	612(ra) # 800039f0 <ilock>
  ip->nlink--;
    80005794:	04a4d783          	lhu	a5,74(s1)
    80005798:	37fd                	addiw	a5,a5,-1
    8000579a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	184080e7          	jalr	388(ra) # 80003924 <iupdate>
  iunlockput(ip);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	4a8080e7          	jalr	1192(ra) # 80003c52 <iunlockput>
  end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	c88080e7          	jalr	-888(ra) # 8000443a <end_op>
  return -1;
    800057ba:	57fd                	li	a5,-1
}
    800057bc:	853e                	mv	a0,a5
    800057be:	70b2                	ld	ra,296(sp)
    800057c0:	7412                	ld	s0,288(sp)
    800057c2:	64f2                	ld	s1,280(sp)
    800057c4:	6952                	ld	s2,272(sp)
    800057c6:	6155                	addi	sp,sp,304
    800057c8:	8082                	ret

00000000800057ca <sys_unlink>:
{
    800057ca:	7151                	addi	sp,sp,-240
    800057cc:	f586                	sd	ra,232(sp)
    800057ce:	f1a2                	sd	s0,224(sp)
    800057d0:	eda6                	sd	s1,216(sp)
    800057d2:	e9ca                	sd	s2,208(sp)
    800057d4:	e5ce                	sd	s3,200(sp)
    800057d6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057d8:	08000613          	li	a2,128
    800057dc:	f3040593          	addi	a1,s0,-208
    800057e0:	4501                	li	a0,0
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	57c080e7          	jalr	1404(ra) # 80002d5e <argstr>
    800057ea:	18054163          	bltz	a0,8000596c <sys_unlink+0x1a2>
  begin_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	bce080e7          	jalr	-1074(ra) # 800043bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057f6:	fb040593          	addi	a1,s0,-80
    800057fa:	f3040513          	addi	a0,s0,-208
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	9bc080e7          	jalr	-1604(ra) # 800041ba <nameiparent>
    80005806:	84aa                	mv	s1,a0
    80005808:	c979                	beqz	a0,800058de <sys_unlink+0x114>
  ilock(dp);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	1e6080e7          	jalr	486(ra) # 800039f0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005812:	00003597          	auipc	a1,0x3
    80005816:	efe58593          	addi	a1,a1,-258 # 80008710 <syscalls+0x2c0>
    8000581a:	fb040513          	addi	a0,s0,-80
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	69c080e7          	jalr	1692(ra) # 80003eba <namecmp>
    80005826:	14050a63          	beqz	a0,8000597a <sys_unlink+0x1b0>
    8000582a:	00003597          	auipc	a1,0x3
    8000582e:	eee58593          	addi	a1,a1,-274 # 80008718 <syscalls+0x2c8>
    80005832:	fb040513          	addi	a0,s0,-80
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	684080e7          	jalr	1668(ra) # 80003eba <namecmp>
    8000583e:	12050e63          	beqz	a0,8000597a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005842:	f2c40613          	addi	a2,s0,-212
    80005846:	fb040593          	addi	a1,s0,-80
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	688080e7          	jalr	1672(ra) # 80003ed4 <dirlookup>
    80005854:	892a                	mv	s2,a0
    80005856:	12050263          	beqz	a0,8000597a <sys_unlink+0x1b0>
  ilock(ip);
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	196080e7          	jalr	406(ra) # 800039f0 <ilock>
  if(ip->nlink < 1)
    80005862:	04a91783          	lh	a5,74(s2)
    80005866:	08f05263          	blez	a5,800058ea <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000586a:	04491703          	lh	a4,68(s2)
    8000586e:	4785                	li	a5,1
    80005870:	08f70563          	beq	a4,a5,800058fa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005874:	4641                	li	a2,16
    80005876:	4581                	li	a1,0
    80005878:	fc040513          	addi	a0,s0,-64
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	456080e7          	jalr	1110(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005884:	4741                	li	a4,16
    80005886:	f2c42683          	lw	a3,-212(s0)
    8000588a:	fc040613          	addi	a2,s0,-64
    8000588e:	4581                	li	a1,0
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	50a080e7          	jalr	1290(ra) # 80003d9c <writei>
    8000589a:	47c1                	li	a5,16
    8000589c:	0af51563          	bne	a0,a5,80005946 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058a0:	04491703          	lh	a4,68(s2)
    800058a4:	4785                	li	a5,1
    800058a6:	0af70863          	beq	a4,a5,80005956 <sys_unlink+0x18c>
  iunlockput(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	3a6080e7          	jalr	934(ra) # 80003c52 <iunlockput>
  ip->nlink--;
    800058b4:	04a95783          	lhu	a5,74(s2)
    800058b8:	37fd                	addiw	a5,a5,-1
    800058ba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	064080e7          	jalr	100(ra) # 80003924 <iupdate>
  iunlockput(ip);
    800058c8:	854a                	mv	a0,s2
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	388080e7          	jalr	904(ra) # 80003c52 <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	b68080e7          	jalr	-1176(ra) # 8000443a <end_op>
  return 0;
    800058da:	4501                	li	a0,0
    800058dc:	a84d                	j	8000598e <sys_unlink+0x1c4>
    end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	b5c080e7          	jalr	-1188(ra) # 8000443a <end_op>
    return -1;
    800058e6:	557d                	li	a0,-1
    800058e8:	a05d                	j	8000598e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058ea:	00003517          	auipc	a0,0x3
    800058ee:	e3650513          	addi	a0,a0,-458 # 80008720 <syscalls+0x2d0>
    800058f2:	ffffb097          	auipc	ra,0xffffb
    800058f6:	c4e080e7          	jalr	-946(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058fa:	04c92703          	lw	a4,76(s2)
    800058fe:	02000793          	li	a5,32
    80005902:	f6e7f9e3          	bgeu	a5,a4,80005874 <sys_unlink+0xaa>
    80005906:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000590a:	4741                	li	a4,16
    8000590c:	86ce                	mv	a3,s3
    8000590e:	f1840613          	addi	a2,s0,-232
    80005912:	4581                	li	a1,0
    80005914:	854a                	mv	a0,s2
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	38e080e7          	jalr	910(ra) # 80003ca4 <readi>
    8000591e:	47c1                	li	a5,16
    80005920:	00f51b63          	bne	a0,a5,80005936 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005924:	f1845783          	lhu	a5,-232(s0)
    80005928:	e7a1                	bnez	a5,80005970 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000592a:	29c1                	addiw	s3,s3,16
    8000592c:	04c92783          	lw	a5,76(s2)
    80005930:	fcf9ede3          	bltu	s3,a5,8000590a <sys_unlink+0x140>
    80005934:	b781                	j	80005874 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005936:	00003517          	auipc	a0,0x3
    8000593a:	e0250513          	addi	a0,a0,-510 # 80008738 <syscalls+0x2e8>
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	c02080e7          	jalr	-1022(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005946:	00003517          	auipc	a0,0x3
    8000594a:	e0a50513          	addi	a0,a0,-502 # 80008750 <syscalls+0x300>
    8000594e:	ffffb097          	auipc	ra,0xffffb
    80005952:	bf2080e7          	jalr	-1038(ra) # 80000540 <panic>
    dp->nlink--;
    80005956:	04a4d783          	lhu	a5,74(s1)
    8000595a:	37fd                	addiw	a5,a5,-1
    8000595c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	fc2080e7          	jalr	-62(ra) # 80003924 <iupdate>
    8000596a:	b781                	j	800058aa <sys_unlink+0xe0>
    return -1;
    8000596c:	557d                	li	a0,-1
    8000596e:	a005                	j	8000598e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005970:	854a                	mv	a0,s2
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	2e0080e7          	jalr	736(ra) # 80003c52 <iunlockput>
  iunlockput(dp);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	2d6080e7          	jalr	726(ra) # 80003c52 <iunlockput>
  end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	ab6080e7          	jalr	-1354(ra) # 8000443a <end_op>
  return -1;
    8000598c:	557d                	li	a0,-1
}
    8000598e:	70ae                	ld	ra,232(sp)
    80005990:	740e                	ld	s0,224(sp)
    80005992:	64ee                	ld	s1,216(sp)
    80005994:	694e                	ld	s2,208(sp)
    80005996:	69ae                	ld	s3,200(sp)
    80005998:	616d                	addi	sp,sp,240
    8000599a:	8082                	ret

000000008000599c <sys_open>:

uint64
sys_open(void)
{
    8000599c:	7131                	addi	sp,sp,-192
    8000599e:	fd06                	sd	ra,184(sp)
    800059a0:	f922                	sd	s0,176(sp)
    800059a2:	f526                	sd	s1,168(sp)
    800059a4:	f14a                	sd	s2,160(sp)
    800059a6:	ed4e                	sd	s3,152(sp)
    800059a8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059aa:	f4c40593          	addi	a1,s0,-180
    800059ae:	4505                	li	a0,1
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	36e080e7          	jalr	878(ra) # 80002d1e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059b8:	08000613          	li	a2,128
    800059bc:	f5040593          	addi	a1,s0,-176
    800059c0:	4501                	li	a0,0
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	39c080e7          	jalr	924(ra) # 80002d5e <argstr>
    800059ca:	87aa                	mv	a5,a0
    return -1;
    800059cc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059ce:	0a07c963          	bltz	a5,80005a80 <sys_open+0xe4>

  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	9ea080e7          	jalr	-1558(ra) # 800043bc <begin_op>

  if(omode & O_CREATE){
    800059da:	f4c42783          	lw	a5,-180(s0)
    800059de:	2007f793          	andi	a5,a5,512
    800059e2:	cfc5                	beqz	a5,80005a9a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059e4:	4681                	li	a3,0
    800059e6:	4601                	li	a2,0
    800059e8:	4589                	li	a1,2
    800059ea:	f5040513          	addi	a0,s0,-176
    800059ee:	00000097          	auipc	ra,0x0
    800059f2:	970080e7          	jalr	-1680(ra) # 8000535e <create>
    800059f6:	84aa                	mv	s1,a0
    if(ip == 0){
    800059f8:	c959                	beqz	a0,80005a8e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059fa:	04449703          	lh	a4,68(s1)
    800059fe:	478d                	li	a5,3
    80005a00:	00f71763          	bne	a4,a5,80005a0e <sys_open+0x72>
    80005a04:	0464d703          	lhu	a4,70(s1)
    80005a08:	47a5                	li	a5,9
    80005a0a:	0ce7ed63          	bltu	a5,a4,80005ae4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	dba080e7          	jalr	-582(ra) # 800047c8 <filealloc>
    80005a16:	89aa                	mv	s3,a0
    80005a18:	10050363          	beqz	a0,80005b1e <sys_open+0x182>
    80005a1c:	00000097          	auipc	ra,0x0
    80005a20:	900080e7          	jalr	-1792(ra) # 8000531c <fdalloc>
    80005a24:	892a                	mv	s2,a0
    80005a26:	0e054763          	bltz	a0,80005b14 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a2a:	04449703          	lh	a4,68(s1)
    80005a2e:	478d                	li	a5,3
    80005a30:	0cf70563          	beq	a4,a5,80005afa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a34:	4789                	li	a5,2
    80005a36:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a3a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a3e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a42:	f4c42783          	lw	a5,-180(s0)
    80005a46:	0017c713          	xori	a4,a5,1
    80005a4a:	8b05                	andi	a4,a4,1
    80005a4c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a50:	0037f713          	andi	a4,a5,3
    80005a54:	00e03733          	snez	a4,a4
    80005a58:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a5c:	4007f793          	andi	a5,a5,1024
    80005a60:	c791                	beqz	a5,80005a6c <sys_open+0xd0>
    80005a62:	04449703          	lh	a4,68(s1)
    80005a66:	4789                	li	a5,2
    80005a68:	0af70063          	beq	a4,a5,80005b08 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	044080e7          	jalr	68(ra) # 80003ab2 <iunlock>
  end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	9c4080e7          	jalr	-1596(ra) # 8000443a <end_op>

  return fd;
    80005a7e:	854a                	mv	a0,s2
}
    80005a80:	70ea                	ld	ra,184(sp)
    80005a82:	744a                	ld	s0,176(sp)
    80005a84:	74aa                	ld	s1,168(sp)
    80005a86:	790a                	ld	s2,160(sp)
    80005a88:	69ea                	ld	s3,152(sp)
    80005a8a:	6129                	addi	sp,sp,192
    80005a8c:	8082                	ret
      end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	9ac080e7          	jalr	-1620(ra) # 8000443a <end_op>
      return -1;
    80005a96:	557d                	li	a0,-1
    80005a98:	b7e5                	j	80005a80 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a9a:	f5040513          	addi	a0,s0,-176
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	6fe080e7          	jalr	1790(ra) # 8000419c <namei>
    80005aa6:	84aa                	mv	s1,a0
    80005aa8:	c905                	beqz	a0,80005ad8 <sys_open+0x13c>
    ilock(ip);
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	f46080e7          	jalr	-186(ra) # 800039f0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ab2:	04449703          	lh	a4,68(s1)
    80005ab6:	4785                	li	a5,1
    80005ab8:	f4f711e3          	bne	a4,a5,800059fa <sys_open+0x5e>
    80005abc:	f4c42783          	lw	a5,-180(s0)
    80005ac0:	d7b9                	beqz	a5,80005a0e <sys_open+0x72>
      iunlockput(ip);
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	18e080e7          	jalr	398(ra) # 80003c52 <iunlockput>
      end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	96e080e7          	jalr	-1682(ra) # 8000443a <end_op>
      return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	b76d                	j	80005a80 <sys_open+0xe4>
      end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	962080e7          	jalr	-1694(ra) # 8000443a <end_op>
      return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	bf79                	j	80005a80 <sys_open+0xe4>
    iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	16c080e7          	jalr	364(ra) # 80003c52 <iunlockput>
    end_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	94c080e7          	jalr	-1716(ra) # 8000443a <end_op>
    return -1;
    80005af6:	557d                	li	a0,-1
    80005af8:	b761                	j	80005a80 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005afa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005afe:	04649783          	lh	a5,70(s1)
    80005b02:	02f99223          	sh	a5,36(s3)
    80005b06:	bf25                	j	80005a3e <sys_open+0xa2>
    itrunc(ip);
    80005b08:	8526                	mv	a0,s1
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	ff4080e7          	jalr	-12(ra) # 80003afe <itrunc>
    80005b12:	bfa9                	j	80005a6c <sys_open+0xd0>
      fileclose(f);
    80005b14:	854e                	mv	a0,s3
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	d6e080e7          	jalr	-658(ra) # 80004884 <fileclose>
    iunlockput(ip);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	132080e7          	jalr	306(ra) # 80003c52 <iunlockput>
    end_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	912080e7          	jalr	-1774(ra) # 8000443a <end_op>
    return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	b7b9                	j	80005a80 <sys_open+0xe4>

0000000080005b34 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b34:	7175                	addi	sp,sp,-144
    80005b36:	e506                	sd	ra,136(sp)
    80005b38:	e122                	sd	s0,128(sp)
    80005b3a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	880080e7          	jalr	-1920(ra) # 800043bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b44:	08000613          	li	a2,128
    80005b48:	f7040593          	addi	a1,s0,-144
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	210080e7          	jalr	528(ra) # 80002d5e <argstr>
    80005b56:	02054963          	bltz	a0,80005b88 <sys_mkdir+0x54>
    80005b5a:	4681                	li	a3,0
    80005b5c:	4601                	li	a2,0
    80005b5e:	4585                	li	a1,1
    80005b60:	f7040513          	addi	a0,s0,-144
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	7fa080e7          	jalr	2042(ra) # 8000535e <create>
    80005b6c:	cd11                	beqz	a0,80005b88 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	0e4080e7          	jalr	228(ra) # 80003c52 <iunlockput>
  end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	8c4080e7          	jalr	-1852(ra) # 8000443a <end_op>
  return 0;
    80005b7e:	4501                	li	a0,0
}
    80005b80:	60aa                	ld	ra,136(sp)
    80005b82:	640a                	ld	s0,128(sp)
    80005b84:	6149                	addi	sp,sp,144
    80005b86:	8082                	ret
    end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	8b2080e7          	jalr	-1870(ra) # 8000443a <end_op>
    return -1;
    80005b90:	557d                	li	a0,-1
    80005b92:	b7fd                	j	80005b80 <sys_mkdir+0x4c>

0000000080005b94 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b94:	7135                	addi	sp,sp,-160
    80005b96:	ed06                	sd	ra,152(sp)
    80005b98:	e922                	sd	s0,144(sp)
    80005b9a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	820080e7          	jalr	-2016(ra) # 800043bc <begin_op>
  argint(1, &major);
    80005ba4:	f6c40593          	addi	a1,s0,-148
    80005ba8:	4505                	li	a0,1
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	174080e7          	jalr	372(ra) # 80002d1e <argint>
  argint(2, &minor);
    80005bb2:	f6840593          	addi	a1,s0,-152
    80005bb6:	4509                	li	a0,2
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	166080e7          	jalr	358(ra) # 80002d1e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bc0:	08000613          	li	a2,128
    80005bc4:	f7040593          	addi	a1,s0,-144
    80005bc8:	4501                	li	a0,0
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	194080e7          	jalr	404(ra) # 80002d5e <argstr>
    80005bd2:	02054b63          	bltz	a0,80005c08 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bd6:	f6841683          	lh	a3,-152(s0)
    80005bda:	f6c41603          	lh	a2,-148(s0)
    80005bde:	458d                	li	a1,3
    80005be0:	f7040513          	addi	a0,s0,-144
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	77a080e7          	jalr	1914(ra) # 8000535e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bec:	cd11                	beqz	a0,80005c08 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	064080e7          	jalr	100(ra) # 80003c52 <iunlockput>
  end_op();
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	844080e7          	jalr	-1980(ra) # 8000443a <end_op>
  return 0;
    80005bfe:	4501                	li	a0,0
}
    80005c00:	60ea                	ld	ra,152(sp)
    80005c02:	644a                	ld	s0,144(sp)
    80005c04:	610d                	addi	sp,sp,160
    80005c06:	8082                	ret
    end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	832080e7          	jalr	-1998(ra) # 8000443a <end_op>
    return -1;
    80005c10:	557d                	li	a0,-1
    80005c12:	b7fd                	j	80005c00 <sys_mknod+0x6c>

0000000080005c14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c14:	7135                	addi	sp,sp,-160
    80005c16:	ed06                	sd	ra,152(sp)
    80005c18:	e922                	sd	s0,144(sp)
    80005c1a:	e526                	sd	s1,136(sp)
    80005c1c:	e14a                	sd	s2,128(sp)
    80005c1e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	d8c080e7          	jalr	-628(ra) # 800019ac <myproc>
    80005c28:	892a                	mv	s2,a0
  
  begin_op();
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	792080e7          	jalr	1938(ra) # 800043bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c32:	08000613          	li	a2,128
    80005c36:	f6040593          	addi	a1,s0,-160
    80005c3a:	4501                	li	a0,0
    80005c3c:	ffffd097          	auipc	ra,0xffffd
    80005c40:	122080e7          	jalr	290(ra) # 80002d5e <argstr>
    80005c44:	04054b63          	bltz	a0,80005c9a <sys_chdir+0x86>
    80005c48:	f6040513          	addi	a0,s0,-160
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	550080e7          	jalr	1360(ra) # 8000419c <namei>
    80005c54:	84aa                	mv	s1,a0
    80005c56:	c131                	beqz	a0,80005c9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	d98080e7          	jalr	-616(ra) # 800039f0 <ilock>
  if(ip->type != T_DIR){
    80005c60:	04449703          	lh	a4,68(s1)
    80005c64:	4785                	li	a5,1
    80005c66:	04f71063          	bne	a4,a5,80005ca6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c6a:	8526                	mv	a0,s1
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	e46080e7          	jalr	-442(ra) # 80003ab2 <iunlock>
  iput(p->cwd);
    80005c74:	1d093503          	ld	a0,464(s2)
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	f32080e7          	jalr	-206(ra) # 80003baa <iput>
  end_op();
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	7ba080e7          	jalr	1978(ra) # 8000443a <end_op>
  p->cwd = ip;
    80005c88:	1c993823          	sd	s1,464(s2)
  return 0;
    80005c8c:	4501                	li	a0,0
}
    80005c8e:	60ea                	ld	ra,152(sp)
    80005c90:	644a                	ld	s0,144(sp)
    80005c92:	64aa                	ld	s1,136(sp)
    80005c94:	690a                	ld	s2,128(sp)
    80005c96:	610d                	addi	sp,sp,160
    80005c98:	8082                	ret
    end_op();
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	7a0080e7          	jalr	1952(ra) # 8000443a <end_op>
    return -1;
    80005ca2:	557d                	li	a0,-1
    80005ca4:	b7ed                	j	80005c8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	faa080e7          	jalr	-86(ra) # 80003c52 <iunlockput>
    end_op();
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	78a080e7          	jalr	1930(ra) # 8000443a <end_op>
    return -1;
    80005cb8:	557d                	li	a0,-1
    80005cba:	bfd1                	j	80005c8e <sys_chdir+0x7a>

0000000080005cbc <sys_exec>:

uint64
sys_exec(void)
{
    80005cbc:	7145                	addi	sp,sp,-464
    80005cbe:	e786                	sd	ra,456(sp)
    80005cc0:	e3a2                	sd	s0,448(sp)
    80005cc2:	ff26                	sd	s1,440(sp)
    80005cc4:	fb4a                	sd	s2,432(sp)
    80005cc6:	f74e                	sd	s3,424(sp)
    80005cc8:	f352                	sd	s4,416(sp)
    80005cca:	ef56                	sd	s5,408(sp)
    80005ccc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cce:	e3840593          	addi	a1,s0,-456
    80005cd2:	4505                	li	a0,1
    80005cd4:	ffffd097          	auipc	ra,0xffffd
    80005cd8:	06a080e7          	jalr	106(ra) # 80002d3e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cdc:	08000613          	li	a2,128
    80005ce0:	f4040593          	addi	a1,s0,-192
    80005ce4:	4501                	li	a0,0
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	078080e7          	jalr	120(ra) # 80002d5e <argstr>
    80005cee:	87aa                	mv	a5,a0
    return -1;
    80005cf0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cf2:	0c07c363          	bltz	a5,80005db8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005cf6:	10000613          	li	a2,256
    80005cfa:	4581                	li	a1,0
    80005cfc:	e4040513          	addi	a0,s0,-448
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	fd2080e7          	jalr	-46(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d08:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d0c:	89a6                	mv	s3,s1
    80005d0e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d10:	02000a13          	li	s4,32
    80005d14:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d18:	00391513          	slli	a0,s2,0x3
    80005d1c:	e3040593          	addi	a1,s0,-464
    80005d20:	e3843783          	ld	a5,-456(s0)
    80005d24:	953e                	add	a0,a0,a5
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	f5a080e7          	jalr	-166(ra) # 80002c80 <fetchaddr>
    80005d2e:	02054a63          	bltz	a0,80005d62 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d32:	e3043783          	ld	a5,-464(s0)
    80005d36:	c3b9                	beqz	a5,80005d7c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	dae080e7          	jalr	-594(ra) # 80000ae6 <kalloc>
    80005d40:	85aa                	mv	a1,a0
    80005d42:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d46:	cd11                	beqz	a0,80005d62 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d48:	6605                	lui	a2,0x1
    80005d4a:	e3043503          	ld	a0,-464(s0)
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	f84080e7          	jalr	-124(ra) # 80002cd2 <fetchstr>
    80005d56:	00054663          	bltz	a0,80005d62 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d5a:	0905                	addi	s2,s2,1
    80005d5c:	09a1                	addi	s3,s3,8
    80005d5e:	fb491be3          	bne	s2,s4,80005d14 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d62:	f4040913          	addi	s2,s0,-192
    80005d66:	6088                	ld	a0,0(s1)
    80005d68:	c539                	beqz	a0,80005db6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d6a:	ffffb097          	auipc	ra,0xffffb
    80005d6e:	c7e080e7          	jalr	-898(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d72:	04a1                	addi	s1,s1,8
    80005d74:	ff2499e3          	bne	s1,s2,80005d66 <sys_exec+0xaa>
  return -1;
    80005d78:	557d                	li	a0,-1
    80005d7a:	a83d                	j	80005db8 <sys_exec+0xfc>
      argv[i] = 0;
    80005d7c:	0a8e                	slli	s5,s5,0x3
    80005d7e:	fc0a8793          	addi	a5,s5,-64
    80005d82:	00878ab3          	add	s5,a5,s0
    80005d86:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d8a:	e4040593          	addi	a1,s0,-448
    80005d8e:	f4040513          	addi	a0,s0,-192
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	16c080e7          	jalr	364(ra) # 80004efe <exec>
    80005d9a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9c:	f4040993          	addi	s3,s0,-192
    80005da0:	6088                	ld	a0,0(s1)
    80005da2:	c901                	beqz	a0,80005db2 <sys_exec+0xf6>
    kfree(argv[i]);
    80005da4:	ffffb097          	auipc	ra,0xffffb
    80005da8:	c44080e7          	jalr	-956(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dac:	04a1                	addi	s1,s1,8
    80005dae:	ff3499e3          	bne	s1,s3,80005da0 <sys_exec+0xe4>
  return ret;
    80005db2:	854a                	mv	a0,s2
    80005db4:	a011                	j	80005db8 <sys_exec+0xfc>
  return -1;
    80005db6:	557d                	li	a0,-1
}
    80005db8:	60be                	ld	ra,456(sp)
    80005dba:	641e                	ld	s0,448(sp)
    80005dbc:	74fa                	ld	s1,440(sp)
    80005dbe:	795a                	ld	s2,432(sp)
    80005dc0:	79ba                	ld	s3,424(sp)
    80005dc2:	7a1a                	ld	s4,416(sp)
    80005dc4:	6afa                	ld	s5,408(sp)
    80005dc6:	6179                	addi	sp,sp,464
    80005dc8:	8082                	ret

0000000080005dca <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dca:	7139                	addi	sp,sp,-64
    80005dcc:	fc06                	sd	ra,56(sp)
    80005dce:	f822                	sd	s0,48(sp)
    80005dd0:	f426                	sd	s1,40(sp)
    80005dd2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dd4:	ffffc097          	auipc	ra,0xffffc
    80005dd8:	bd8080e7          	jalr	-1064(ra) # 800019ac <myproc>
    80005ddc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dde:	fd840593          	addi	a1,s0,-40
    80005de2:	4501                	li	a0,0
    80005de4:	ffffd097          	auipc	ra,0xffffd
    80005de8:	f5a080e7          	jalr	-166(ra) # 80002d3e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dec:	fc840593          	addi	a1,s0,-56
    80005df0:	fd040513          	addi	a0,s0,-48
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	dc0080e7          	jalr	-576(ra) # 80004bb4 <pipealloc>
    return -1;
    80005dfc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dfe:	0c054763          	bltz	a0,80005ecc <sys_pipe+0x102>
  fd0 = -1;
    80005e02:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e06:	fd043503          	ld	a0,-48(s0)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	512080e7          	jalr	1298(ra) # 8000531c <fdalloc>
    80005e12:	fca42223          	sw	a0,-60(s0)
    80005e16:	08054e63          	bltz	a0,80005eb2 <sys_pipe+0xe8>
    80005e1a:	fc843503          	ld	a0,-56(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	4fe080e7          	jalr	1278(ra) # 8000531c <fdalloc>
    80005e26:	fca42023          	sw	a0,-64(s0)
    80005e2a:	06054a63          	bltz	a0,80005e9e <sys_pipe+0xd4>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e2e:	4691                	li	a3,4
    80005e30:	fc440613          	addi	a2,s0,-60
    80005e34:	fd843583          	ld	a1,-40(s0)
    80005e38:	68e8                	ld	a0,208(s1)
    80005e3a:	ffffc097          	auipc	ra,0xffffc
    80005e3e:	832080e7          	jalr	-1998(ra) # 8000166c <copyout>
    80005e42:	02054063          	bltz	a0,80005e62 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e46:	4691                	li	a3,4
    80005e48:	fc040613          	addi	a2,s0,-64
    80005e4c:	fd843583          	ld	a1,-40(s0)
    80005e50:	0591                	addi	a1,a1,4
    80005e52:	68e8                	ld	a0,208(s1)
    80005e54:	ffffc097          	auipc	ra,0xffffc
    80005e58:	818080e7          	jalr	-2024(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e5c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5e:	06055763          	bgez	a0,80005ecc <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005e62:	fc442783          	lw	a5,-60(s0)
    80005e66:	02a78793          	addi	a5,a5,42
    80005e6a:	078e                	slli	a5,a5,0x3
    80005e6c:	97a6                	add	a5,a5,s1
    80005e6e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e72:	fc042783          	lw	a5,-64(s0)
    80005e76:	02a78793          	addi	a5,a5,42
    80005e7a:	078e                	slli	a5,a5,0x3
    80005e7c:	94be                	add	s1,s1,a5
    80005e7e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e82:	fd043503          	ld	a0,-48(s0)
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	9fe080e7          	jalr	-1538(ra) # 80004884 <fileclose>
    fileclose(wf);
    80005e8e:	fc843503          	ld	a0,-56(s0)
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	9f2080e7          	jalr	-1550(ra) # 80004884 <fileclose>
    return -1;
    80005e9a:	57fd                	li	a5,-1
    80005e9c:	a805                	j	80005ecc <sys_pipe+0x102>
    if(fd0 >= 0)
    80005e9e:	fc442783          	lw	a5,-60(s0)
    80005ea2:	0007c863          	bltz	a5,80005eb2 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005ea6:	02a78793          	addi	a5,a5,42
    80005eaa:	078e                	slli	a5,a5,0x3
    80005eac:	97a6                	add	a5,a5,s1
    80005eae:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005eb2:	fd043503          	ld	a0,-48(s0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	9ce080e7          	jalr	-1586(ra) # 80004884 <fileclose>
    fileclose(wf);
    80005ebe:	fc843503          	ld	a0,-56(s0)
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	9c2080e7          	jalr	-1598(ra) # 80004884 <fileclose>
    return -1;
    80005eca:	57fd                	li	a5,-1
}
    80005ecc:	853e                	mv	a0,a5
    80005ece:	70e2                	ld	ra,56(sp)
    80005ed0:	7442                	ld	s0,48(sp)
    80005ed2:	74a2                	ld	s1,40(sp)
    80005ed4:	6121                	addi	sp,sp,64
    80005ed6:	8082                	ret
	...

0000000080005ee0 <kernelvec>:
    80005ee0:	7111                	addi	sp,sp,-256
    80005ee2:	e006                	sd	ra,0(sp)
    80005ee4:	e40a                	sd	sp,8(sp)
    80005ee6:	e80e                	sd	gp,16(sp)
    80005ee8:	ec12                	sd	tp,24(sp)
    80005eea:	f016                	sd	t0,32(sp)
    80005eec:	f41a                	sd	t1,40(sp)
    80005eee:	f81e                	sd	t2,48(sp)
    80005ef0:	fc22                	sd	s0,56(sp)
    80005ef2:	e0a6                	sd	s1,64(sp)
    80005ef4:	e4aa                	sd	a0,72(sp)
    80005ef6:	e8ae                	sd	a1,80(sp)
    80005ef8:	ecb2                	sd	a2,88(sp)
    80005efa:	f0b6                	sd	a3,96(sp)
    80005efc:	f4ba                	sd	a4,104(sp)
    80005efe:	f8be                	sd	a5,112(sp)
    80005f00:	fcc2                	sd	a6,120(sp)
    80005f02:	e146                	sd	a7,128(sp)
    80005f04:	e54a                	sd	s2,136(sp)
    80005f06:	e94e                	sd	s3,144(sp)
    80005f08:	ed52                	sd	s4,152(sp)
    80005f0a:	f156                	sd	s5,160(sp)
    80005f0c:	f55a                	sd	s6,168(sp)
    80005f0e:	f95e                	sd	s7,176(sp)
    80005f10:	fd62                	sd	s8,184(sp)
    80005f12:	e1e6                	sd	s9,192(sp)
    80005f14:	e5ea                	sd	s10,200(sp)
    80005f16:	e9ee                	sd	s11,208(sp)
    80005f18:	edf2                	sd	t3,216(sp)
    80005f1a:	f1f6                	sd	t4,224(sp)
    80005f1c:	f5fa                	sd	t5,232(sp)
    80005f1e:	f9fe                	sd	t6,240(sp)
    80005f20:	c2dfc0ef          	jal	ra,80002b4c <kerneltrap>
    80005f24:	6082                	ld	ra,0(sp)
    80005f26:	6122                	ld	sp,8(sp)
    80005f28:	61c2                	ld	gp,16(sp)
    80005f2a:	7282                	ld	t0,32(sp)
    80005f2c:	7322                	ld	t1,40(sp)
    80005f2e:	73c2                	ld	t2,48(sp)
    80005f30:	7462                	ld	s0,56(sp)
    80005f32:	6486                	ld	s1,64(sp)
    80005f34:	6526                	ld	a0,72(sp)
    80005f36:	65c6                	ld	a1,80(sp)
    80005f38:	6666                	ld	a2,88(sp)
    80005f3a:	7686                	ld	a3,96(sp)
    80005f3c:	7726                	ld	a4,104(sp)
    80005f3e:	77c6                	ld	a5,112(sp)
    80005f40:	7866                	ld	a6,120(sp)
    80005f42:	688a                	ld	a7,128(sp)
    80005f44:	692a                	ld	s2,136(sp)
    80005f46:	69ca                	ld	s3,144(sp)
    80005f48:	6a6a                	ld	s4,152(sp)
    80005f4a:	7a8a                	ld	s5,160(sp)
    80005f4c:	7b2a                	ld	s6,168(sp)
    80005f4e:	7bca                	ld	s7,176(sp)
    80005f50:	7c6a                	ld	s8,184(sp)
    80005f52:	6c8e                	ld	s9,192(sp)
    80005f54:	6d2e                	ld	s10,200(sp)
    80005f56:	6dce                	ld	s11,208(sp)
    80005f58:	6e6e                	ld	t3,216(sp)
    80005f5a:	7e8e                	ld	t4,224(sp)
    80005f5c:	7f2e                	ld	t5,232(sp)
    80005f5e:	7fce                	ld	t6,240(sp)
    80005f60:	6111                	addi	sp,sp,256
    80005f62:	10200073          	sret
    80005f66:	00000013          	nop
    80005f6a:	00000013          	nop
    80005f6e:	0001                	nop

0000000080005f70 <timervec>:
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	e10c                	sd	a1,0(a0)
    80005f76:	e510                	sd	a2,8(a0)
    80005f78:	e914                	sd	a3,16(a0)
    80005f7a:	6d0c                	ld	a1,24(a0)
    80005f7c:	7110                	ld	a2,32(a0)
    80005f7e:	6194                	ld	a3,0(a1)
    80005f80:	96b2                	add	a3,a3,a2
    80005f82:	e194                	sd	a3,0(a1)
    80005f84:	4589                	li	a1,2
    80005f86:	14459073          	csrw	sip,a1
    80005f8a:	6914                	ld	a3,16(a0)
    80005f8c:	6510                	ld	a2,8(a0)
    80005f8e:	610c                	ld	a1,0(a0)
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	30200073          	mret
	...

0000000080005f9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f9a:	1141                	addi	sp,sp,-16
    80005f9c:	e422                	sd	s0,8(sp)
    80005f9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fa0:	0c0007b7          	lui	a5,0xc000
    80005fa4:	4705                	li	a4,1
    80005fa6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fa8:	c3d8                	sw	a4,4(a5)
}
    80005faa:	6422                	ld	s0,8(sp)
    80005fac:	0141                	addi	sp,sp,16
    80005fae:	8082                	ret

0000000080005fb0 <plicinithart>:

void
plicinithart(void)
{
    80005fb0:	1141                	addi	sp,sp,-16
    80005fb2:	e406                	sd	ra,8(sp)
    80005fb4:	e022                	sd	s0,0(sp)
    80005fb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	9c8080e7          	jalr	-1592(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fc0:	0085171b          	slliw	a4,a0,0x8
    80005fc4:	0c0027b7          	lui	a5,0xc002
    80005fc8:	97ba                	add	a5,a5,a4
    80005fca:	40200713          	li	a4,1026
    80005fce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fd2:	00d5151b          	slliw	a0,a0,0xd
    80005fd6:	0c2017b7          	lui	a5,0xc201
    80005fda:	97aa                	add	a5,a5,a0
    80005fdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fe0:	60a2                	ld	ra,8(sp)
    80005fe2:	6402                	ld	s0,0(sp)
    80005fe4:	0141                	addi	sp,sp,16
    80005fe6:	8082                	ret

0000000080005fe8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fe8:	1141                	addi	sp,sp,-16
    80005fea:	e406                	sd	ra,8(sp)
    80005fec:	e022                	sd	s0,0(sp)
    80005fee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ff0:	ffffc097          	auipc	ra,0xffffc
    80005ff4:	990080e7          	jalr	-1648(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ff8:	00d5151b          	slliw	a0,a0,0xd
    80005ffc:	0c2017b7          	lui	a5,0xc201
    80006000:	97aa                	add	a5,a5,a0
  return irq;
}
    80006002:	43c8                	lw	a0,4(a5)
    80006004:	60a2                	ld	ra,8(sp)
    80006006:	6402                	ld	s0,0(sp)
    80006008:	0141                	addi	sp,sp,16
    8000600a:	8082                	ret

000000008000600c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000600c:	1101                	addi	sp,sp,-32
    8000600e:	ec06                	sd	ra,24(sp)
    80006010:	e822                	sd	s0,16(sp)
    80006012:	e426                	sd	s1,8(sp)
    80006014:	1000                	addi	s0,sp,32
    80006016:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	968080e7          	jalr	-1688(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006020:	00d5151b          	slliw	a0,a0,0xd
    80006024:	0c2017b7          	lui	a5,0xc201
    80006028:	97aa                	add	a5,a5,a0
    8000602a:	c3c4                	sw	s1,4(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	addi	sp,sp,32
    80006034:	8082                	ret

0000000080006036 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006036:	1141                	addi	sp,sp,-16
    80006038:	e406                	sd	ra,8(sp)
    8000603a:	e022                	sd	s0,0(sp)
    8000603c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000603e:	479d                	li	a5,7
    80006040:	04a7cc63          	blt	a5,a0,80006098 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006044:	00023797          	auipc	a5,0x23
    80006048:	dfc78793          	addi	a5,a5,-516 # 80028e40 <disk>
    8000604c:	97aa                	add	a5,a5,a0
    8000604e:	0187c783          	lbu	a5,24(a5)
    80006052:	ebb9                	bnez	a5,800060a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006054:	00451693          	slli	a3,a0,0x4
    80006058:	00023797          	auipc	a5,0x23
    8000605c:	de878793          	addi	a5,a5,-536 # 80028e40 <disk>
    80006060:	6398                	ld	a4,0(a5)
    80006062:	9736                	add	a4,a4,a3
    80006064:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006068:	6398                	ld	a4,0(a5)
    8000606a:	9736                	add	a4,a4,a3
    8000606c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006070:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006074:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006078:	97aa                	add	a5,a5,a0
    8000607a:	4705                	li	a4,1
    8000607c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006080:	00023517          	auipc	a0,0x23
    80006084:	dd850513          	addi	a0,a0,-552 # 80028e58 <disk+0x18>
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	070080e7          	jalr	112(ra) # 800020f8 <wakeup>
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret
    panic("free_desc 1");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6c850513          	addi	a0,a0,1736 # 80008760 <syscalls+0x310>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a0080e7          	jalr	1184(ra) # 80000540 <panic>
    panic("free_desc 2");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	6c850513          	addi	a0,a0,1736 # 80008770 <syscalls+0x320>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	490080e7          	jalr	1168(ra) # 80000540 <panic>

00000000800060b8 <virtio_disk_init>:
{
    800060b8:	1101                	addi	sp,sp,-32
    800060ba:	ec06                	sd	ra,24(sp)
    800060bc:	e822                	sd	s0,16(sp)
    800060be:	e426                	sd	s1,8(sp)
    800060c0:	e04a                	sd	s2,0(sp)
    800060c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060c4:	00002597          	auipc	a1,0x2
    800060c8:	6bc58593          	addi	a1,a1,1724 # 80008780 <syscalls+0x330>
    800060cc:	00023517          	auipc	a0,0x23
    800060d0:	e9c50513          	addi	a0,a0,-356 # 80028f68 <disk+0x128>
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	a72080e7          	jalr	-1422(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060dc:	100017b7          	lui	a5,0x10001
    800060e0:	4398                	lw	a4,0(a5)
    800060e2:	2701                	sext.w	a4,a4
    800060e4:	747277b7          	lui	a5,0x74727
    800060e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ec:	14f71b63          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f0:	100017b7          	lui	a5,0x10001
    800060f4:	43dc                	lw	a5,4(a5)
    800060f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f8:	4709                	li	a4,2
    800060fa:	14e79463          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	479c                	lw	a5,8(a5)
    80006104:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006106:	12e79e63          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000610a:	100017b7          	lui	a5,0x10001
    8000610e:	47d8                	lw	a4,12(a5)
    80006110:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006112:	554d47b7          	lui	a5,0x554d4
    80006116:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000611a:	12f71463          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006126:	4705                	li	a4,1
    80006128:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612a:	470d                	li	a4,3
    8000612c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000612e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006130:	c7ffe6b7          	lui	a3,0xc7ffe
    80006134:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd57df>
    80006138:	8f75                	and	a4,a4,a3
    8000613a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613c:	472d                	li	a4,11
    8000613e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006140:	5bbc                	lw	a5,112(a5)
    80006142:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006146:	8ba1                	andi	a5,a5,8
    80006148:	10078563          	beqz	a5,80006252 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006154:	43fc                	lw	a5,68(a5)
    80006156:	2781                	sext.w	a5,a5
    80006158:	10079563          	bnez	a5,80006262 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	5bdc                	lw	a5,52(a5)
    80006162:	2781                	sext.w	a5,a5
  if(max == 0)
    80006164:	10078763          	beqz	a5,80006272 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006168:	471d                	li	a4,7
    8000616a:	10f77c63          	bgeu	a4,a5,80006282 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	978080e7          	jalr	-1672(ra) # 80000ae6 <kalloc>
    80006176:	00023497          	auipc	s1,0x23
    8000617a:	cca48493          	addi	s1,s1,-822 # 80028e40 <disk>
    8000617e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	966080e7          	jalr	-1690(ra) # 80000ae6 <kalloc>
    80006188:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	95c080e7          	jalr	-1700(ra) # 80000ae6 <kalloc>
    80006192:	87aa                	mv	a5,a0
    80006194:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006196:	6088                	ld	a0,0(s1)
    80006198:	cd6d                	beqz	a0,80006292 <virtio_disk_init+0x1da>
    8000619a:	00023717          	auipc	a4,0x23
    8000619e:	cae73703          	ld	a4,-850(a4) # 80028e48 <disk+0x8>
    800061a2:	cb65                	beqz	a4,80006292 <virtio_disk_init+0x1da>
    800061a4:	c7fd                	beqz	a5,80006292 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061a6:	6605                	lui	a2,0x1
    800061a8:	4581                	li	a1,0
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	b28080e7          	jalr	-1240(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061b2:	00023497          	auipc	s1,0x23
    800061b6:	c8e48493          	addi	s1,s1,-882 # 80028e40 <disk>
    800061ba:	6605                	lui	a2,0x1
    800061bc:	4581                	li	a1,0
    800061be:	6488                	ld	a0,8(s1)
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	b12080e7          	jalr	-1262(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061c8:	6605                	lui	a2,0x1
    800061ca:	4581                	li	a1,0
    800061cc:	6888                	ld	a0,16(s1)
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	b04080e7          	jalr	-1276(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061d6:	100017b7          	lui	a5,0x10001
    800061da:	4721                	li	a4,8
    800061dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061de:	4098                	lw	a4,0(s1)
    800061e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061e4:	40d8                	lw	a4,4(s1)
    800061e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ea:	6498                	ld	a4,8(s1)
    800061ec:	0007069b          	sext.w	a3,a4
    800061f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061f4:	9701                	srai	a4,a4,0x20
    800061f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061fa:	6898                	ld	a4,16(s1)
    800061fc:	0007069b          	sext.w	a3,a4
    80006200:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006204:	9701                	srai	a4,a4,0x20
    80006206:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000620a:	4705                	li	a4,1
    8000620c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000620e:	00e48c23          	sb	a4,24(s1)
    80006212:	00e48ca3          	sb	a4,25(s1)
    80006216:	00e48d23          	sb	a4,26(s1)
    8000621a:	00e48da3          	sb	a4,27(s1)
    8000621e:	00e48e23          	sb	a4,28(s1)
    80006222:	00e48ea3          	sb	a4,29(s1)
    80006226:	00e48f23          	sb	a4,30(s1)
    8000622a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000622e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006232:	0727a823          	sw	s2,112(a5)
}
    80006236:	60e2                	ld	ra,24(sp)
    80006238:	6442                	ld	s0,16(sp)
    8000623a:	64a2                	ld	s1,8(sp)
    8000623c:	6902                	ld	s2,0(sp)
    8000623e:	6105                	addi	sp,sp,32
    80006240:	8082                	ret
    panic("could not find virtio disk");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	54e50513          	addi	a0,a0,1358 # 80008790 <syscalls+0x340>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	55e50513          	addi	a0,a0,1374 # 800087b0 <syscalls+0x360>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	56e50513          	addi	a0,a0,1390 # 800087d0 <syscalls+0x380>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d6080e7          	jalr	726(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	57e50513          	addi	a0,a0,1406 # 800087f0 <syscalls+0x3a0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	58e50513          	addi	a0,a0,1422 # 80008810 <syscalls+0x3c0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b6080e7          	jalr	694(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	59e50513          	addi	a0,a0,1438 # 80008830 <syscalls+0x3e0>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a6080e7          	jalr	678(ra) # 80000540 <panic>

00000000800062a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062a2:	7119                	addi	sp,sp,-128
    800062a4:	fc86                	sd	ra,120(sp)
    800062a6:	f8a2                	sd	s0,112(sp)
    800062a8:	f4a6                	sd	s1,104(sp)
    800062aa:	f0ca                	sd	s2,96(sp)
    800062ac:	ecce                	sd	s3,88(sp)
    800062ae:	e8d2                	sd	s4,80(sp)
    800062b0:	e4d6                	sd	s5,72(sp)
    800062b2:	e0da                	sd	s6,64(sp)
    800062b4:	fc5e                	sd	s7,56(sp)
    800062b6:	f862                	sd	s8,48(sp)
    800062b8:	f466                	sd	s9,40(sp)
    800062ba:	f06a                	sd	s10,32(sp)
    800062bc:	ec6e                	sd	s11,24(sp)
    800062be:	0100                	addi	s0,sp,128
    800062c0:	8aaa                	mv	s5,a0
    800062c2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062c4:	00c52d03          	lw	s10,12(a0)
    800062c8:	001d1d1b          	slliw	s10,s10,0x1
    800062cc:	1d02                	slli	s10,s10,0x20
    800062ce:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800062d2:	00023517          	auipc	a0,0x23
    800062d6:	c9650513          	addi	a0,a0,-874 # 80028f68 <disk+0x128>
    800062da:	ffffb097          	auipc	ra,0xffffb
    800062de:	8fc080e7          	jalr	-1796(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062e2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062e6:	00023b97          	auipc	s7,0x23
    800062ea:	b5ab8b93          	addi	s7,s7,-1190 # 80028e40 <disk>
  for(int i = 0; i < 3; i++){
    800062ee:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062f0:	00023c97          	auipc	s9,0x23
    800062f4:	c78c8c93          	addi	s9,s9,-904 # 80028f68 <disk+0x128>
    800062f8:	a08d                	j	8000635a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062fa:	00fb8733          	add	a4,s7,a5
    800062fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006302:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006304:	0207c563          	bltz	a5,8000632e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006308:	2905                	addiw	s2,s2,1
    8000630a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000630c:	05690c63          	beq	s2,s6,80006364 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006310:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006312:	00023717          	auipc	a4,0x23
    80006316:	b2e70713          	addi	a4,a4,-1234 # 80028e40 <disk>
    8000631a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000631c:	01874683          	lbu	a3,24(a4)
    80006320:	fee9                	bnez	a3,800062fa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006322:	2785                	addiw	a5,a5,1
    80006324:	0705                	addi	a4,a4,1
    80006326:	fe979be3          	bne	a5,s1,8000631c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000632a:	57fd                	li	a5,-1
    8000632c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000632e:	01205d63          	blez	s2,80006348 <virtio_disk_rw+0xa6>
    80006332:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006334:	000a2503          	lw	a0,0(s4)
    80006338:	00000097          	auipc	ra,0x0
    8000633c:	cfe080e7          	jalr	-770(ra) # 80006036 <free_desc>
      for(int j = 0; j < i; j++)
    80006340:	2d85                	addiw	s11,s11,1
    80006342:	0a11                	addi	s4,s4,4
    80006344:	ff2d98e3          	bne	s11,s2,80006334 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006348:	85e6                	mv	a1,s9
    8000634a:	00023517          	auipc	a0,0x23
    8000634e:	b0e50513          	addi	a0,a0,-1266 # 80028e58 <disk+0x18>
    80006352:	ffffc097          	auipc	ra,0xffffc
    80006356:	d42080e7          	jalr	-702(ra) # 80002094 <sleep>
  for(int i = 0; i < 3; i++){
    8000635a:	f8040a13          	addi	s4,s0,-128
{
    8000635e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006360:	894e                	mv	s2,s3
    80006362:	b77d                	j	80006310 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006364:	f8042503          	lw	a0,-128(s0)
    80006368:	00a50713          	addi	a4,a0,10
    8000636c:	0712                	slli	a4,a4,0x4

  if(write)
    8000636e:	00023797          	auipc	a5,0x23
    80006372:	ad278793          	addi	a5,a5,-1326 # 80028e40 <disk>
    80006376:	00e786b3          	add	a3,a5,a4
    8000637a:	01803633          	snez	a2,s8
    8000637e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006380:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006384:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006388:	f6070613          	addi	a2,a4,-160
    8000638c:	6394                	ld	a3,0(a5)
    8000638e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006390:	00870593          	addi	a1,a4,8
    80006394:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006396:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006398:	0007b803          	ld	a6,0(a5)
    8000639c:	9642                	add	a2,a2,a6
    8000639e:	46c1                	li	a3,16
    800063a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063a2:	4585                	li	a1,1
    800063a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063a8:	f8442683          	lw	a3,-124(s0)
    800063ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063b0:	0692                	slli	a3,a3,0x4
    800063b2:	9836                	add	a6,a6,a3
    800063b4:	058a8613          	addi	a2,s5,88
    800063b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063bc:	0007b803          	ld	a6,0(a5)
    800063c0:	96c2                	add	a3,a3,a6
    800063c2:	40000613          	li	a2,1024
    800063c6:	c690                	sw	a2,8(a3)
  if(write)
    800063c8:	001c3613          	seqz	a2,s8
    800063cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063d0:	00166613          	ori	a2,a2,1
    800063d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063d8:	f8842603          	lw	a2,-120(s0)
    800063dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063e0:	00250693          	addi	a3,a0,2
    800063e4:	0692                	slli	a3,a3,0x4
    800063e6:	96be                	add	a3,a3,a5
    800063e8:	58fd                	li	a7,-1
    800063ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063ee:	0612                	slli	a2,a2,0x4
    800063f0:	9832                	add	a6,a6,a2
    800063f2:	f9070713          	addi	a4,a4,-112
    800063f6:	973e                	add	a4,a4,a5
    800063f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063fc:	6398                	ld	a4,0(a5)
    800063fe:	9732                	add	a4,a4,a2
    80006400:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006402:	4609                	li	a2,2
    80006404:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006408:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000640c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006410:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006414:	6794                	ld	a3,8(a5)
    80006416:	0026d703          	lhu	a4,2(a3)
    8000641a:	8b1d                	andi	a4,a4,7
    8000641c:	0706                	slli	a4,a4,0x1
    8000641e:	96ba                	add	a3,a3,a4
    80006420:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006428:	6798                	ld	a4,8(a5)
    8000642a:	00275783          	lhu	a5,2(a4)
    8000642e:	2785                	addiw	a5,a5,1
    80006430:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006434:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006438:	100017b7          	lui	a5,0x10001
    8000643c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006440:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006444:	00023917          	auipc	s2,0x23
    80006448:	b2490913          	addi	s2,s2,-1244 # 80028f68 <disk+0x128>
  while(b->disk == 1) {
    8000644c:	4485                	li	s1,1
    8000644e:	00b79c63          	bne	a5,a1,80006466 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006452:	85ca                	mv	a1,s2
    80006454:	8556                	mv	a0,s5
    80006456:	ffffc097          	auipc	ra,0xffffc
    8000645a:	c3e080e7          	jalr	-962(ra) # 80002094 <sleep>
  while(b->disk == 1) {
    8000645e:	004aa783          	lw	a5,4(s5)
    80006462:	fe9788e3          	beq	a5,s1,80006452 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006466:	f8042903          	lw	s2,-128(s0)
    8000646a:	00290713          	addi	a4,s2,2
    8000646e:	0712                	slli	a4,a4,0x4
    80006470:	00023797          	auipc	a5,0x23
    80006474:	9d078793          	addi	a5,a5,-1584 # 80028e40 <disk>
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000647e:	00023997          	auipc	s3,0x23
    80006482:	9c298993          	addi	s3,s3,-1598 # 80028e40 <disk>
    80006486:	00491713          	slli	a4,s2,0x4
    8000648a:	0009b783          	ld	a5,0(s3)
    8000648e:	97ba                	add	a5,a5,a4
    80006490:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006494:	854a                	mv	a0,s2
    80006496:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	b9c080e7          	jalr	-1124(ra) # 80006036 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064a2:	8885                	andi	s1,s1,1
    800064a4:	f0ed                	bnez	s1,80006486 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064a6:	00023517          	auipc	a0,0x23
    800064aa:	ac250513          	addi	a0,a0,-1342 # 80028f68 <disk+0x128>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
}
    800064b6:	70e6                	ld	ra,120(sp)
    800064b8:	7446                	ld	s0,112(sp)
    800064ba:	74a6                	ld	s1,104(sp)
    800064bc:	7906                	ld	s2,96(sp)
    800064be:	69e6                	ld	s3,88(sp)
    800064c0:	6a46                	ld	s4,80(sp)
    800064c2:	6aa6                	ld	s5,72(sp)
    800064c4:	6b06                	ld	s6,64(sp)
    800064c6:	7be2                	ld	s7,56(sp)
    800064c8:	7c42                	ld	s8,48(sp)
    800064ca:	7ca2                	ld	s9,40(sp)
    800064cc:	7d02                	ld	s10,32(sp)
    800064ce:	6de2                	ld	s11,24(sp)
    800064d0:	6109                	addi	sp,sp,128
    800064d2:	8082                	ret

00000000800064d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064d4:	1101                	addi	sp,sp,-32
    800064d6:	ec06                	sd	ra,24(sp)
    800064d8:	e822                	sd	s0,16(sp)
    800064da:	e426                	sd	s1,8(sp)
    800064dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064de:	00023497          	auipc	s1,0x23
    800064e2:	96248493          	addi	s1,s1,-1694 # 80028e40 <disk>
    800064e6:	00023517          	auipc	a0,0x23
    800064ea:	a8250513          	addi	a0,a0,-1406 # 80028f68 <disk+0x128>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	6e8080e7          	jalr	1768(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064f6:	10001737          	lui	a4,0x10001
    800064fa:	533c                	lw	a5,96(a4)
    800064fc:	8b8d                	andi	a5,a5,3
    800064fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006500:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006504:	689c                	ld	a5,16(s1)
    80006506:	0204d703          	lhu	a4,32(s1)
    8000650a:	0027d783          	lhu	a5,2(a5)
    8000650e:	04f70863          	beq	a4,a5,8000655e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006512:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006516:	6898                	ld	a4,16(s1)
    80006518:	0204d783          	lhu	a5,32(s1)
    8000651c:	8b9d                	andi	a5,a5,7
    8000651e:	078e                	slli	a5,a5,0x3
    80006520:	97ba                	add	a5,a5,a4
    80006522:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006524:	00278713          	addi	a4,a5,2
    80006528:	0712                	slli	a4,a4,0x4
    8000652a:	9726                	add	a4,a4,s1
    8000652c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006530:	e721                	bnez	a4,80006578 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006532:	0789                	addi	a5,a5,2
    80006534:	0792                	slli	a5,a5,0x4
    80006536:	97a6                	add	a5,a5,s1
    80006538:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000653a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000653e:	ffffc097          	auipc	ra,0xffffc
    80006542:	bba080e7          	jalr	-1094(ra) # 800020f8 <wakeup>

    disk.used_idx += 1;
    80006546:	0204d783          	lhu	a5,32(s1)
    8000654a:	2785                	addiw	a5,a5,1
    8000654c:	17c2                	slli	a5,a5,0x30
    8000654e:	93c1                	srli	a5,a5,0x30
    80006550:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006554:	6898                	ld	a4,16(s1)
    80006556:	00275703          	lhu	a4,2(a4)
    8000655a:	faf71ce3          	bne	a4,a5,80006512 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000655e:	00023517          	auipc	a0,0x23
    80006562:	a0a50513          	addi	a0,a0,-1526 # 80028f68 <disk+0x128>
    80006566:	ffffa097          	auipc	ra,0xffffa
    8000656a:	724080e7          	jalr	1828(ra) # 80000c8a <release>
}
    8000656e:	60e2                	ld	ra,24(sp)
    80006570:	6442                	ld	s0,16(sp)
    80006572:	64a2                	ld	s1,8(sp)
    80006574:	6105                	addi	sp,sp,32
    80006576:	8082                	ret
      panic("virtio_disk_intr status");
    80006578:	00002517          	auipc	a0,0x2
    8000657c:	2d050513          	addi	a0,a0,720 # 80008848 <syscalls+0x3f8>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	fc0080e7          	jalr	-64(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
