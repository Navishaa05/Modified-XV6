
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	87070713          	addi	a4,a4,-1936 # 800088c0 <timer_scratch>
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
    80000066:	00e78793          	addi	a5,a5,14 # 80006070 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbc6b7>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f5278793          	addi	a5,a5,-174 # 80000ffe <main>
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
    8000012e:	586080e7          	jalr	1414(ra) # 800026b0 <either_copyin>
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
    8000018e:	87650513          	addi	a0,a0,-1930 # 80010a00 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	bca080e7          	jalr	-1078(ra) # 80000d5c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	86648493          	addi	s1,s1,-1946 # 80010a00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	8f690913          	addi	s2,s2,-1802 # 80010a98 <cons+0x98>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9b0080e7          	jalr	-1616(ra) # 80001b70 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	332080e7          	jalr	818(ra) # 800024fa <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	070080e7          	jalr	112(ra) # 80002246 <sleep>
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
    80000216:	448080e7          	jalr	1096(ra) # 8000265a <either_copyout>
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
    80000226:	00010517          	auipc	a0,0x10
    8000022a:	7da50513          	addi	a0,a0,2010 # 80010a00 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	be2080e7          	jalr	-1054(ra) # 80000e10 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7c450513          	addi	a0,a0,1988 # 80010a00 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bcc080e7          	jalr	-1076(ra) # 80000e10 <release>
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
    80000276:	82f72323          	sw	a5,-2010(a4) # 80010a98 <cons+0x98>
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
    800002d0:	73450513          	addi	a0,a0,1844 # 80010a00 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a88080e7          	jalr	-1400(ra) # 80000d5c <acquire>

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
    800002f6:	414080e7          	jalr	1044(ra) # 80002706 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	70650513          	addi	a0,a0,1798 # 80010a00 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b0e080e7          	jalr	-1266(ra) # 80000e10 <release>
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
    80000322:	6e270713          	addi	a4,a4,1762 # 80010a00 <cons>
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
    8000034c:	6b878793          	addi	a5,a5,1720 # 80010a00 <cons>
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
    8000037a:	7227a783          	lw	a5,1826(a5) # 80010a98 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	67670713          	addi	a4,a4,1654 # 80010a00 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	66648493          	addi	s1,s1,1638 # 80010a00 <cons>
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
    800003da:	62a70713          	addi	a4,a4,1578 # 80010a00 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6af72a23          	sw	a5,1716(a4) # 80010aa0 <cons+0xa0>
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
    80000416:	5ee78793          	addi	a5,a5,1518 # 80010a00 <cons>
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
    8000043a:	66c7a323          	sw	a2,1638(a5) # 80010a9c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	65a50513          	addi	a0,a0,1626 # 80010a98 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e64080e7          	jalr	-412(ra) # 800022aa <wakeup>
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
    80000464:	5a050513          	addi	a0,a0,1440 # 80010a00 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	864080e7          	jalr	-1948(ra) # 80000ccc <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00041797          	auipc	a5,0x41
    8000047c:	b3878793          	addi	a5,a5,-1224 # 80040fb0 <devsw>
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
    80000550:	5607aa23          	sw	zero,1396(a5) # 80010ac0 <pr+0x18>
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
    80000572:	b6a50513          	addi	a0,a0,-1174 # 800080d8 <digits+0x98>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	30f72023          	sw	a5,768(a4) # 80008880 <panicked>
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
    800005c0:	504dad83          	lw	s11,1284(s11) # 80010ac0 <pr+0x18>
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
    800005fe:	4ae50513          	addi	a0,a0,1198 # 80010aa8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	75a080e7          	jalr	1882(ra) # 80000d5c <acquire>
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
    8000075c:	35050513          	addi	a0,a0,848 # 80010aa8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	6b0080e7          	jalr	1712(ra) # 80000e10 <release>
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
    80000778:	33448493          	addi	s1,s1,820 # 80010aa8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	546080e7          	jalr	1350(ra) # 80000ccc <initlock>
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
    800007d8:	2f450513          	addi	a0,a0,756 # 80010ac8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	4f0080e7          	jalr	1264(ra) # 80000ccc <initlock>
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
    800007fc:	518080e7          	jalr	1304(ra) # 80000d10 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0807a783          	lw	a5,128(a5) # 80008880 <panicked>
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
    8000082a:	58a080e7          	jalr	1418(ra) # 80000db0 <pop_off>
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
    8000083c:	0507b783          	ld	a5,80(a5) # 80008888 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	05073703          	ld	a4,80(a4) # 80008890 <uart_tx_w>
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
    80000866:	266a0a13          	addi	s4,s4,614 # 80010ac8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	01e48493          	addi	s1,s1,30 # 80008888 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	01e98993          	addi	s3,s3,30 # 80008890 <uart_tx_w>
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
    80000898:	a16080e7          	jalr	-1514(ra) # 800022aa <wakeup>
    
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
    800008d4:	1f850513          	addi	a0,a0,504 # 80010ac8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	484080e7          	jalr	1156(ra) # 80000d5c <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	fa07a783          	lw	a5,-96(a5) # 80008880 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	fa673703          	ld	a4,-90(a4) # 80008890 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	f967b783          	ld	a5,-106(a5) # 80008888 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	1ca98993          	addi	s3,s3,458 # 80010ac8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	f8248493          	addi	s1,s1,-126 # 80008888 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	f8290913          	addi	s2,s2,-126 # 80008890 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	928080e7          	jalr	-1752(ra) # 80002246 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	19448493          	addi	s1,s1,404 # 80010ac8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f4e7b423          	sd	a4,-184(a5) # 80008890 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	4b6080e7          	jalr	1206(ra) # 80000e10 <release>
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
    800009be:	10e48493          	addi	s1,s1,270 # 80010ac8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	398080e7          	jalr	920(ra) # 80000d5c <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	43a080e7          	jalr	1082(ra) # 80000e10 <release>
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
    800009e8:	7179                	addi	sp,sp,-48
    800009ea:	f406                	sd	ra,40(sp)
    800009ec:	f022                	sd	s0,32(sp)
    800009ee:	ec26                	sd	s1,24(sp)
    800009f0:	e84a                	sd	s2,16(sp)
    800009f2:	e44e                	sd	s3,8(sp)
    800009f4:	1800                	addi	s0,sp,48
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	e7d5                	bnez	a5,80000aa6 <kfree+0xbe>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00041797          	auipc	a5,0x41
    80000a02:	74a78793          	addi	a5,a5,1866 # 80042148 <end>
    80000a06:	0af56063          	bltu	a0,a5,80000aa6 <kfree+0xbe>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	08f57c63          	bgeu	a0,a5,80000aa6 <kfree+0xbe>
    panic("kfree");

  acquire(&ref_lock);
    80000a12:	00010517          	auipc	a0,0x10
    80000a16:	0ee50513          	addi	a0,a0,238 # 80010b00 <ref_lock>
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	342080e7          	jalr	834(ra) # 80000d5c <acquire>
  int idx = ((uint64)pa - KERNBASE) / PGSIZE;
    80000a22:	800007b7          	lui	a5,0x80000
    80000a26:	97a6                	add	a5,a5,s1
    80000a28:	83b1                	srli	a5,a5,0xc
    80000a2a:	2781                	sext.w	a5,a5
  if(ref_count[idx] > 1) {
    80000a2c:	00279693          	slli	a3,a5,0x2
    80000a30:	00010717          	auipc	a4,0x10
    80000a34:	10870713          	addi	a4,a4,264 # 80010b38 <ref_count>
    80000a38:	9736                	add	a4,a4,a3
    80000a3a:	4318                	lw	a4,0(a4)
    80000a3c:	4685                	li	a3,1
    80000a3e:	06e6cc63          	blt	a3,a4,80000ab6 <kfree+0xce>
    ref_count[idx]--;
    release(&ref_lock);
    return;
  }
  ref_count[idx] = 0;
    80000a42:	078a                	slli	a5,a5,0x2
    80000a44:	00010717          	auipc	a4,0x10
    80000a48:	0f470713          	addi	a4,a4,244 # 80010b38 <ref_count>
    80000a4c:	97ba                	add	a5,a5,a4
    80000a4e:	0007a023          	sw	zero,0(a5) # ffffffff80000000 <end+0xfffffffefffbdeb8>
  release(&ref_lock);
    80000a52:	00010917          	auipc	s2,0x10
    80000a56:	0ae90913          	addi	s2,s2,174 # 80010b00 <ref_lock>
    80000a5a:	854a                	mv	a0,s2
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	3b4080e7          	jalr	948(ra) # 80000e10 <release>

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a64:	6605                	lui	a2,0x1
    80000a66:	4585                	li	a1,1
    80000a68:	8526                	mv	a0,s1
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	3ee080e7          	jalr	1006(ra) # 80000e58 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a72:	00010997          	auipc	s3,0x10
    80000a76:	0a698993          	addi	s3,s3,166 # 80010b18 <kmem>
    80000a7a:	854e                	mv	a0,s3
    80000a7c:	00000097          	auipc	ra,0x0
    80000a80:	2e0080e7          	jalr	736(ra) # 80000d5c <acquire>
  r->next = kmem.freelist;
    80000a84:	03093783          	ld	a5,48(s2)
    80000a88:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a8a:	02993823          	sd	s1,48(s2)
  release(&kmem.lock);
    80000a8e:	854e                	mv	a0,s3
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	380080e7          	jalr	896(ra) # 80000e10 <release>
}
    80000a98:	70a2                	ld	ra,40(sp)
    80000a9a:	7402                	ld	s0,32(sp)
    80000a9c:	64e2                	ld	s1,24(sp)
    80000a9e:	6942                	ld	s2,16(sp)
    80000aa0:	69a2                	ld	s3,8(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret
    panic("kfree");
    80000aa6:	00007517          	auipc	a0,0x7
    80000aaa:	5ba50513          	addi	a0,a0,1466 # 80008060 <digits+0x20>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	a92080e7          	jalr	-1390(ra) # 80000540 <panic>
    ref_count[idx]--;
    80000ab6:	078a                	slli	a5,a5,0x2
    80000ab8:	00010697          	auipc	a3,0x10
    80000abc:	08068693          	addi	a3,a3,128 # 80010b38 <ref_count>
    80000ac0:	97b6                	add	a5,a5,a3
    80000ac2:	377d                	addiw	a4,a4,-1
    80000ac4:	c398                	sw	a4,0(a5)
    release(&ref_lock);
    80000ac6:	00010517          	auipc	a0,0x10
    80000aca:	03a50513          	addi	a0,a0,58 # 80010b00 <ref_lock>
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	342080e7          	jalr	834(ra) # 80000e10 <release>
    return;
    80000ad6:	b7c9                	j	80000a98 <kfree+0xb0>

0000000080000ad8 <freerange>:
{
    80000ad8:	7179                	addi	sp,sp,-48
    80000ada:	f406                	sd	ra,40(sp)
    80000adc:	f022                	sd	s0,32(sp)
    80000ade:	ec26                	sd	s1,24(sp)
    80000ae0:	e84a                	sd	s2,16(sp)
    80000ae2:	e44e                	sd	s3,8(sp)
    80000ae4:	e052                	sd	s4,0(sp)
    80000ae6:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae8:	6785                	lui	a5,0x1
    80000aea:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000aee:	00e504b3          	add	s1,a0,a4
    80000af2:	777d                	lui	a4,0xfffff
    80000af4:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94be                	add	s1,s1,a5
    80000af8:	0095ee63          	bltu	a1,s1,80000b14 <freerange+0x3c>
    80000afc:	892e                	mv	s2,a1
    kfree(p);
    80000afe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b00:	6985                	lui	s3,0x1
    kfree(p);
    80000b02:	01448533          	add	a0,s1,s4
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	ee2080e7          	jalr	-286(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b0e:	94ce                	add	s1,s1,s3
    80000b10:	fe9979e3          	bgeu	s2,s1,80000b02 <freerange+0x2a>
}
    80000b14:	70a2                	ld	ra,40(sp)
    80000b16:	7402                	ld	s0,32(sp)
    80000b18:	64e2                	ld	s1,24(sp)
    80000b1a:	6942                	ld	s2,16(sp)
    80000b1c:	69a2                	ld	s3,8(sp)
    80000b1e:	6a02                	ld	s4,0(sp)
    80000b20:	6145                	addi	sp,sp,48
    80000b22:	8082                	ret

0000000080000b24 <kinit>:
{
    80000b24:	1141                	addi	sp,sp,-16
    80000b26:	e406                	sd	ra,8(sp)
    80000b28:	e022                	sd	s0,0(sp)
    80000b2a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b2c:	00007597          	auipc	a1,0x7
    80000b30:	53c58593          	addi	a1,a1,1340 # 80008068 <digits+0x28>
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	fe450513          	addi	a0,a0,-28 # 80010b18 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	190080e7          	jalr	400(ra) # 80000ccc <initlock>
  initlock(&ref_lock, "ref_count");
    80000b44:	00007597          	auipc	a1,0x7
    80000b48:	52c58593          	addi	a1,a1,1324 # 80008070 <digits+0x30>
    80000b4c:	00010517          	auipc	a0,0x10
    80000b50:	fb450513          	addi	a0,a0,-76 # 80010b00 <ref_lock>
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	178080e7          	jalr	376(ra) # 80000ccc <initlock>
  memset(ref_count, 0, sizeof(ref_count));
    80000b5c:	00020637          	lui	a2,0x20
    80000b60:	4581                	li	a1,0
    80000b62:	00010517          	auipc	a0,0x10
    80000b66:	fd650513          	addi	a0,a0,-42 # 80010b38 <ref_count>
    80000b6a:	00000097          	auipc	ra,0x0
    80000b6e:	2ee080e7          	jalr	750(ra) # 80000e58 <memset>
  freerange(end, (void*)PHYSTOP);
    80000b72:	45c5                	li	a1,17
    80000b74:	05ee                	slli	a1,a1,0x1b
    80000b76:	00041517          	auipc	a0,0x41
    80000b7a:	5d250513          	addi	a0,a0,1490 # 80042148 <end>
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	f5a080e7          	jalr	-166(ra) # 80000ad8 <freerange>
}
    80000b86:	60a2                	ld	ra,8(sp)
    80000b88:	6402                	ld	s0,0(sp)
    80000b8a:	0141                	addi	sp,sp,16
    80000b8c:	8082                	ret

0000000080000b8e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	e04a                	sd	s2,0(sp)
    80000b98:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b9a:	00010517          	auipc	a0,0x10
    80000b9e:	f7e50513          	addi	a0,a0,-130 # 80010b18 <kmem>
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	1ba080e7          	jalr	442(ra) # 80000d5c <acquire>
  r = kmem.freelist;
    80000baa:	00010497          	auipc	s1,0x10
    80000bae:	f864b483          	ld	s1,-122(s1) # 80010b30 <kmem+0x18>
  if(r)
    80000bb2:	c4a5                	beqz	s1,80000c1a <kalloc+0x8c>
    kmem.freelist = r->next;
    80000bb4:	609c                	ld	a5,0(s1)
    80000bb6:	00010917          	auipc	s2,0x10
    80000bba:	f4a90913          	addi	s2,s2,-182 # 80010b00 <ref_lock>
    80000bbe:	02f93823          	sd	a5,48(s2)
  release(&kmem.lock);
    80000bc2:	00010517          	auipc	a0,0x10
    80000bc6:	f5650513          	addi	a0,a0,-170 # 80010b18 <kmem>
    80000bca:	00000097          	auipc	ra,0x0
    80000bce:	246080e7          	jalr	582(ra) # 80000e10 <release>

  if(r) {
    memset((char*)r, 5, PGSIZE);
    80000bd2:	6605                	lui	a2,0x1
    80000bd4:	4595                	li	a1,5
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	280080e7          	jalr	640(ra) # 80000e58 <memset>
    acquire(&ref_lock);
    80000be0:	854a                	mv	a0,s2
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	17a080e7          	jalr	378(ra) # 80000d5c <acquire>
    ref_count[((uint64)r - KERNBASE) / PGSIZE] = 1;
    80000bea:	800007b7          	lui	a5,0x80000
    80000bee:	97a6                	add	a5,a5,s1
    80000bf0:	83b1                	srli	a5,a5,0xc
    80000bf2:	078a                	slli	a5,a5,0x2
    80000bf4:	00010717          	auipc	a4,0x10
    80000bf8:	f4470713          	addi	a4,a4,-188 # 80010b38 <ref_count>
    80000bfc:	97ba                	add	a5,a5,a4
    80000bfe:	4705                	li	a4,1
    80000c00:	c398                	sw	a4,0(a5)
    release(&ref_lock);
    80000c02:	854a                	mv	a0,s2
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	20c080e7          	jalr	524(ra) # 80000e10 <release>
  }
  return (void*)r;
}
    80000c0c:	8526                	mv	a0,s1
    80000c0e:	60e2                	ld	ra,24(sp)
    80000c10:	6442                	ld	s0,16(sp)
    80000c12:	64a2                	ld	s1,8(sp)
    80000c14:	6902                	ld	s2,0(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
  release(&kmem.lock);
    80000c1a:	00010517          	auipc	a0,0x10
    80000c1e:	efe50513          	addi	a0,a0,-258 # 80010b18 <kmem>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	1ee080e7          	jalr	494(ra) # 80000e10 <release>
  if(r) {
    80000c2a:	b7cd                	j	80000c0c <kalloc+0x7e>

0000000080000c2c <incref>:

void
incref(uint64 pa)
{
    80000c2c:	1101                	addi	sp,sp,-32
    80000c2e:	ec06                	sd	ra,24(sp)
    80000c30:	e822                	sd	s0,16(sp)
    80000c32:	e426                	sd	s1,8(sp)
    80000c34:	e04a                	sd	s2,0(sp)
    80000c36:	1000                	addi	s0,sp,32
    80000c38:	84aa                	mv	s1,a0
  acquire(&ref_lock);
    80000c3a:	00010917          	auipc	s2,0x10
    80000c3e:	ec690913          	addi	s2,s2,-314 # 80010b00 <ref_lock>
    80000c42:	854a                	mv	a0,s2
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	118080e7          	jalr	280(ra) # 80000d5c <acquire>
  ref_count[(pa - KERNBASE) / PGSIZE]++;
    80000c4c:	800007b7          	lui	a5,0x80000
    80000c50:	94be                	add	s1,s1,a5
    80000c52:	80b1                	srli	s1,s1,0xc
    80000c54:	048a                	slli	s1,s1,0x2
    80000c56:	00010797          	auipc	a5,0x10
    80000c5a:	ee278793          	addi	a5,a5,-286 # 80010b38 <ref_count>
    80000c5e:	97a6                	add	a5,a5,s1
    80000c60:	4398                	lw	a4,0(a5)
    80000c62:	2705                	addiw	a4,a4,1
    80000c64:	c398                	sw	a4,0(a5)
  release(&ref_lock);
    80000c66:	854a                	mv	a0,s2
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	1a8080e7          	jalr	424(ra) # 80000e10 <release>
}
    80000c70:	60e2                	ld	ra,24(sp)
    80000c72:	6442                	ld	s0,16(sp)
    80000c74:	64a2                	ld	s1,8(sp)
    80000c76:	6902                	ld	s2,0(sp)
    80000c78:	6105                	addi	sp,sp,32
    80000c7a:	8082                	ret

0000000080000c7c <getref>:

int
getref(uint64 pa)
{
    80000c7c:	1101                	addi	sp,sp,-32
    80000c7e:	ec06                	sd	ra,24(sp)
    80000c80:	e822                	sd	s0,16(sp)
    80000c82:	e426                	sd	s1,8(sp)
    80000c84:	e04a                	sd	s2,0(sp)
    80000c86:	1000                	addi	s0,sp,32
    80000c88:	84aa                	mv	s1,a0
  int idx = (pa - KERNBASE) / PGSIZE;
  acquire(&ref_lock);
    80000c8a:	00010917          	auipc	s2,0x10
    80000c8e:	e7690913          	addi	s2,s2,-394 # 80010b00 <ref_lock>
    80000c92:	854a                	mv	a0,s2
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	0c8080e7          	jalr	200(ra) # 80000d5c <acquire>
  int idx = (pa - KERNBASE) / PGSIZE;
    80000c9c:	800007b7          	lui	a5,0x80000
    80000ca0:	94be                	add	s1,s1,a5
    80000ca2:	80b1                	srli	s1,s1,0xc
  int ref = ref_count[idx];
    80000ca4:	2481                	sext.w	s1,s1
    80000ca6:	048a                	slli	s1,s1,0x2
    80000ca8:	00010797          	auipc	a5,0x10
    80000cac:	e9078793          	addi	a5,a5,-368 # 80010b38 <ref_count>
    80000cb0:	97a6                	add	a5,a5,s1
    80000cb2:	4384                	lw	s1,0(a5)
  release(&ref_lock);
    80000cb4:	854a                	mv	a0,s2
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	15a080e7          	jalr	346(ra) # 80000e10 <release>
  return ref;
}
    80000cbe:	8526                	mv	a0,s1
    80000cc0:	60e2                	ld	ra,24(sp)
    80000cc2:	6442                	ld	s0,16(sp)
    80000cc4:	64a2                	ld	s1,8(sp)
    80000cc6:	6902                	ld	s2,0(sp)
    80000cc8:	6105                	addi	sp,sp,32
    80000cca:	8082                	ret

0000000080000ccc <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cd2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cd4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cd8:	00053823          	sd	zero,16(a0)
}
    80000cdc:	6422                	ld	s0,8(sp)
    80000cde:	0141                	addi	sp,sp,16
    80000ce0:	8082                	ret

0000000080000ce2 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ce2:	411c                	lw	a5,0(a0)
    80000ce4:	e399                	bnez	a5,80000cea <holding+0x8>
    80000ce6:	4501                	li	a0,0
  return r;
}
    80000ce8:	8082                	ret
{
    80000cea:	1101                	addi	sp,sp,-32
    80000cec:	ec06                	sd	ra,24(sp)
    80000cee:	e822                	sd	s0,16(sp)
    80000cf0:	e426                	sd	s1,8(sp)
    80000cf2:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cf4:	6904                	ld	s1,16(a0)
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	e5e080e7          	jalr	-418(ra) # 80001b54 <mycpu>
    80000cfe:	40a48533          	sub	a0,s1,a0
    80000d02:	00153513          	seqz	a0,a0
}
    80000d06:	60e2                	ld	ra,24(sp)
    80000d08:	6442                	ld	s0,16(sp)
    80000d0a:	64a2                	ld	s1,8(sp)
    80000d0c:	6105                	addi	sp,sp,32
    80000d0e:	8082                	ret

0000000080000d10 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d10:	1101                	addi	sp,sp,-32
    80000d12:	ec06                	sd	ra,24(sp)
    80000d14:	e822                	sd	s0,16(sp)
    80000d16:	e426                	sd	s1,8(sp)
    80000d18:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1a:	100024f3          	csrr	s1,sstatus
    80000d1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d24:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d28:	00001097          	auipc	ra,0x1
    80000d2c:	e2c080e7          	jalr	-468(ra) # 80001b54 <mycpu>
    80000d30:	5d3c                	lw	a5,120(a0)
    80000d32:	cf89                	beqz	a5,80000d4c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d34:	00001097          	auipc	ra,0x1
    80000d38:	e20080e7          	jalr	-480(ra) # 80001b54 <mycpu>
    80000d3c:	5d3c                	lw	a5,120(a0)
    80000d3e:	2785                	addiw	a5,a5,1
    80000d40:	dd3c                	sw	a5,120(a0)
}
    80000d42:	60e2                	ld	ra,24(sp)
    80000d44:	6442                	ld	s0,16(sp)
    80000d46:	64a2                	ld	s1,8(sp)
    80000d48:	6105                	addi	sp,sp,32
    80000d4a:	8082                	ret
    mycpu()->intena = old;
    80000d4c:	00001097          	auipc	ra,0x1
    80000d50:	e08080e7          	jalr	-504(ra) # 80001b54 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d54:	8085                	srli	s1,s1,0x1
    80000d56:	8885                	andi	s1,s1,1
    80000d58:	dd64                	sw	s1,124(a0)
    80000d5a:	bfe9                	j	80000d34 <push_off+0x24>

0000000080000d5c <acquire>:
{
    80000d5c:	1101                	addi	sp,sp,-32
    80000d5e:	ec06                	sd	ra,24(sp)
    80000d60:	e822                	sd	s0,16(sp)
    80000d62:	e426                	sd	s1,8(sp)
    80000d64:	1000                	addi	s0,sp,32
    80000d66:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d68:	00000097          	auipc	ra,0x0
    80000d6c:	fa8080e7          	jalr	-88(ra) # 80000d10 <push_off>
  if(holding(lk))
    80000d70:	8526                	mv	a0,s1
    80000d72:	00000097          	auipc	ra,0x0
    80000d76:	f70080e7          	jalr	-144(ra) # 80000ce2 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d7a:	4705                	li	a4,1
  if(holding(lk))
    80000d7c:	e115                	bnez	a0,80000da0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d7e:	87ba                	mv	a5,a4
    80000d80:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d84:	2781                	sext.w	a5,a5
    80000d86:	ffe5                	bnez	a5,80000d7e <acquire+0x22>
  __sync_synchronize();
    80000d88:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d8c:	00001097          	auipc	ra,0x1
    80000d90:	dc8080e7          	jalr	-568(ra) # 80001b54 <mycpu>
    80000d94:	e888                	sd	a0,16(s1)
}
    80000d96:	60e2                	ld	ra,24(sp)
    80000d98:	6442                	ld	s0,16(sp)
    80000d9a:	64a2                	ld	s1,8(sp)
    80000d9c:	6105                	addi	sp,sp,32
    80000d9e:	8082                	ret
    panic("acquire");
    80000da0:	00007517          	auipc	a0,0x7
    80000da4:	2e050513          	addi	a0,a0,736 # 80008080 <digits+0x40>
    80000da8:	fffff097          	auipc	ra,0xfffff
    80000dac:	798080e7          	jalr	1944(ra) # 80000540 <panic>

0000000080000db0 <pop_off>:

void
pop_off(void)
{
    80000db0:	1141                	addi	sp,sp,-16
    80000db2:	e406                	sd	ra,8(sp)
    80000db4:	e022                	sd	s0,0(sp)
    80000db6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000db8:	00001097          	auipc	ra,0x1
    80000dbc:	d9c080e7          	jalr	-612(ra) # 80001b54 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dc0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dc4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dc6:	e78d                	bnez	a5,80000df0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dc8:	5d3c                	lw	a5,120(a0)
    80000dca:	02f05b63          	blez	a5,80000e00 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dce:	37fd                	addiw	a5,a5,-1
    80000dd0:	0007871b          	sext.w	a4,a5
    80000dd4:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dd6:	eb09                	bnez	a4,80000de8 <pop_off+0x38>
    80000dd8:	5d7c                	lw	a5,124(a0)
    80000dda:	c799                	beqz	a5,80000de8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ddc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000de0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000de4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000de8:	60a2                	ld	ra,8(sp)
    80000dea:	6402                	ld	s0,0(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    panic("pop_off - interruptible");
    80000df0:	00007517          	auipc	a0,0x7
    80000df4:	29850513          	addi	a0,a0,664 # 80008088 <digits+0x48>
    80000df8:	fffff097          	auipc	ra,0xfffff
    80000dfc:	748080e7          	jalr	1864(ra) # 80000540 <panic>
    panic("pop_off");
    80000e00:	00007517          	auipc	a0,0x7
    80000e04:	2a050513          	addi	a0,a0,672 # 800080a0 <digits+0x60>
    80000e08:	fffff097          	auipc	ra,0xfffff
    80000e0c:	738080e7          	jalr	1848(ra) # 80000540 <panic>

0000000080000e10 <release>:
{
    80000e10:	1101                	addi	sp,sp,-32
    80000e12:	ec06                	sd	ra,24(sp)
    80000e14:	e822                	sd	s0,16(sp)
    80000e16:	e426                	sd	s1,8(sp)
    80000e18:	1000                	addi	s0,sp,32
    80000e1a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e1c:	00000097          	auipc	ra,0x0
    80000e20:	ec6080e7          	jalr	-314(ra) # 80000ce2 <holding>
    80000e24:	c115                	beqz	a0,80000e48 <release+0x38>
  lk->cpu = 0;
    80000e26:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e2a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e2e:	0f50000f          	fence	iorw,ow
    80000e32:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e36:	00000097          	auipc	ra,0x0
    80000e3a:	f7a080e7          	jalr	-134(ra) # 80000db0 <pop_off>
}
    80000e3e:	60e2                	ld	ra,24(sp)
    80000e40:	6442                	ld	s0,16(sp)
    80000e42:	64a2                	ld	s1,8(sp)
    80000e44:	6105                	addi	sp,sp,32
    80000e46:	8082                	ret
    panic("release");
    80000e48:	00007517          	auipc	a0,0x7
    80000e4c:	26050513          	addi	a0,a0,608 # 800080a8 <digits+0x68>
    80000e50:	fffff097          	auipc	ra,0xfffff
    80000e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>

0000000080000e58 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e58:	1141                	addi	sp,sp,-16
    80000e5a:	e422                	sd	s0,8(sp)
    80000e5c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e5e:	ca19                	beqz	a2,80000e74 <memset+0x1c>
    80000e60:	87aa                	mv	a5,a0
    80000e62:	1602                	slli	a2,a2,0x20
    80000e64:	9201                	srli	a2,a2,0x20
    80000e66:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e6a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e6e:	0785                	addi	a5,a5,1
    80000e70:	fee79de3          	bne	a5,a4,80000e6a <memset+0x12>
  }
  return dst;
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	addi	sp,sp,16
    80000e78:	8082                	ret

0000000080000e7a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e7a:	1141                	addi	sp,sp,-16
    80000e7c:	e422                	sd	s0,8(sp)
    80000e7e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e80:	ca05                	beqz	a2,80000eb0 <memcmp+0x36>
    80000e82:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e86:	1682                	slli	a3,a3,0x20
    80000e88:	9281                	srli	a3,a3,0x20
    80000e8a:	0685                	addi	a3,a3,1
    80000e8c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e8e:	00054783          	lbu	a5,0(a0)
    80000e92:	0005c703          	lbu	a4,0(a1)
    80000e96:	00e79863          	bne	a5,a4,80000ea6 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e9a:	0505                	addi	a0,a0,1
    80000e9c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e9e:	fed518e3          	bne	a0,a3,80000e8e <memcmp+0x14>
  }

  return 0;
    80000ea2:	4501                	li	a0,0
    80000ea4:	a019                	j	80000eaa <memcmp+0x30>
      return *s1 - *s2;
    80000ea6:	40e7853b          	subw	a0,a5,a4
}
    80000eaa:	6422                	ld	s0,8(sp)
    80000eac:	0141                	addi	sp,sp,16
    80000eae:	8082                	ret
  return 0;
    80000eb0:	4501                	li	a0,0
    80000eb2:	bfe5                	j	80000eaa <memcmp+0x30>

0000000080000eb4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eb4:	1141                	addi	sp,sp,-16
    80000eb6:	e422                	sd	s0,8(sp)
    80000eb8:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000eba:	c205                	beqz	a2,80000eda <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ebc:	02a5e263          	bltu	a1,a0,80000ee0 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ec0:	1602                	slli	a2,a2,0x20
    80000ec2:	9201                	srli	a2,a2,0x20
    80000ec4:	00c587b3          	add	a5,a1,a2
{
    80000ec8:	872a                	mv	a4,a0
      *d++ = *s++;
    80000eca:	0585                	addi	a1,a1,1
    80000ecc:	0705                	addi	a4,a4,1
    80000ece:	fff5c683          	lbu	a3,-1(a1)
    80000ed2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ed6:	fef59ae3          	bne	a1,a5,80000eca <memmove+0x16>

  return dst;
}
    80000eda:	6422                	ld	s0,8(sp)
    80000edc:	0141                	addi	sp,sp,16
    80000ede:	8082                	ret
  if(s < d && s + n > d){
    80000ee0:	02061693          	slli	a3,a2,0x20
    80000ee4:	9281                	srli	a3,a3,0x20
    80000ee6:	00d58733          	add	a4,a1,a3
    80000eea:	fce57be3          	bgeu	a0,a4,80000ec0 <memmove+0xc>
    d += n;
    80000eee:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ef0:	fff6079b          	addiw	a5,a2,-1
    80000ef4:	1782                	slli	a5,a5,0x20
    80000ef6:	9381                	srli	a5,a5,0x20
    80000ef8:	fff7c793          	not	a5,a5
    80000efc:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000efe:	177d                	addi	a4,a4,-1
    80000f00:	16fd                	addi	a3,a3,-1
    80000f02:	00074603          	lbu	a2,0(a4)
    80000f06:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f0a:	fee79ae3          	bne	a5,a4,80000efe <memmove+0x4a>
    80000f0e:	b7f1                	j	80000eda <memmove+0x26>

0000000080000f10 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e406                	sd	ra,8(sp)
    80000f14:	e022                	sd	s0,0(sp)
    80000f16:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	f9c080e7          	jalr	-100(ra) # 80000eb4 <memmove>
}
    80000f20:	60a2                	ld	ra,8(sp)
    80000f22:	6402                	ld	s0,0(sp)
    80000f24:	0141                	addi	sp,sp,16
    80000f26:	8082                	ret

0000000080000f28 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f28:	1141                	addi	sp,sp,-16
    80000f2a:	e422                	sd	s0,8(sp)
    80000f2c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f2e:	ce11                	beqz	a2,80000f4a <strncmp+0x22>
    80000f30:	00054783          	lbu	a5,0(a0)
    80000f34:	cf89                	beqz	a5,80000f4e <strncmp+0x26>
    80000f36:	0005c703          	lbu	a4,0(a1)
    80000f3a:	00f71a63          	bne	a4,a5,80000f4e <strncmp+0x26>
    n--, p++, q++;
    80000f3e:	367d                	addiw	a2,a2,-1
    80000f40:	0505                	addi	a0,a0,1
    80000f42:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f44:	f675                	bnez	a2,80000f30 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f46:	4501                	li	a0,0
    80000f48:	a809                	j	80000f5a <strncmp+0x32>
    80000f4a:	4501                	li	a0,0
    80000f4c:	a039                	j	80000f5a <strncmp+0x32>
  if(n == 0)
    80000f4e:	ca09                	beqz	a2,80000f60 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f50:	00054503          	lbu	a0,0(a0)
    80000f54:	0005c783          	lbu	a5,0(a1)
    80000f58:	9d1d                	subw	a0,a0,a5
}
    80000f5a:	6422                	ld	s0,8(sp)
    80000f5c:	0141                	addi	sp,sp,16
    80000f5e:	8082                	ret
    return 0;
    80000f60:	4501                	li	a0,0
    80000f62:	bfe5                	j	80000f5a <strncmp+0x32>

0000000080000f64 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f64:	1141                	addi	sp,sp,-16
    80000f66:	e422                	sd	s0,8(sp)
    80000f68:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f6a:	872a                	mv	a4,a0
    80000f6c:	8832                	mv	a6,a2
    80000f6e:	367d                	addiw	a2,a2,-1
    80000f70:	01005963          	blez	a6,80000f82 <strncpy+0x1e>
    80000f74:	0705                	addi	a4,a4,1
    80000f76:	0005c783          	lbu	a5,0(a1)
    80000f7a:	fef70fa3          	sb	a5,-1(a4)
    80000f7e:	0585                	addi	a1,a1,1
    80000f80:	f7f5                	bnez	a5,80000f6c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f82:	86ba                	mv	a3,a4
    80000f84:	00c05c63          	blez	a2,80000f9c <strncpy+0x38>
    *s++ = 0;
    80000f88:	0685                	addi	a3,a3,1
    80000f8a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f8e:	40d707bb          	subw	a5,a4,a3
    80000f92:	37fd                	addiw	a5,a5,-1
    80000f94:	010787bb          	addw	a5,a5,a6
    80000f98:	fef048e3          	bgtz	a5,80000f88 <strncpy+0x24>
  return os;
}
    80000f9c:	6422                	ld	s0,8(sp)
    80000f9e:	0141                	addi	sp,sp,16
    80000fa0:	8082                	ret

0000000080000fa2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fa2:	1141                	addi	sp,sp,-16
    80000fa4:	e422                	sd	s0,8(sp)
    80000fa6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fa8:	02c05363          	blez	a2,80000fce <safestrcpy+0x2c>
    80000fac:	fff6069b          	addiw	a3,a2,-1
    80000fb0:	1682                	slli	a3,a3,0x20
    80000fb2:	9281                	srli	a3,a3,0x20
    80000fb4:	96ae                	add	a3,a3,a1
    80000fb6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fb8:	00d58963          	beq	a1,a3,80000fca <safestrcpy+0x28>
    80000fbc:	0585                	addi	a1,a1,1
    80000fbe:	0785                	addi	a5,a5,1
    80000fc0:	fff5c703          	lbu	a4,-1(a1)
    80000fc4:	fee78fa3          	sb	a4,-1(a5)
    80000fc8:	fb65                	bnez	a4,80000fb8 <safestrcpy+0x16>
    ;
  *s = 0;
    80000fca:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fce:	6422                	ld	s0,8(sp)
    80000fd0:	0141                	addi	sp,sp,16
    80000fd2:	8082                	ret

0000000080000fd4 <strlen>:

int
strlen(const char *s)
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fda:	00054783          	lbu	a5,0(a0)
    80000fde:	cf91                	beqz	a5,80000ffa <strlen+0x26>
    80000fe0:	0505                	addi	a0,a0,1
    80000fe2:	87aa                	mv	a5,a0
    80000fe4:	4685                	li	a3,1
    80000fe6:	9e89                	subw	a3,a3,a0
    80000fe8:	00f6853b          	addw	a0,a3,a5
    80000fec:	0785                	addi	a5,a5,1
    80000fee:	fff7c703          	lbu	a4,-1(a5)
    80000ff2:	fb7d                	bnez	a4,80000fe8 <strlen+0x14>
    ;
  return n;
}
    80000ff4:	6422                	ld	s0,8(sp)
    80000ff6:	0141                	addi	sp,sp,16
    80000ff8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ffa:	4501                	li	a0,0
    80000ffc:	bfe5                	j	80000ff4 <strlen+0x20>

0000000080000ffe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ffe:	1141                	addi	sp,sp,-16
    80001000:	e406                	sd	ra,8(sp)
    80001002:	e022                	sd	s0,0(sp)
    80001004:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	b3e080e7          	jalr	-1218(ra) # 80001b44 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000100e:	00008717          	auipc	a4,0x8
    80001012:	88a70713          	addi	a4,a4,-1910 # 80008898 <started>
  if(cpuid() == 0){
    80001016:	c139                	beqz	a0,8000105c <main+0x5e>
    while(started == 0)
    80001018:	431c                	lw	a5,0(a4)
    8000101a:	2781                	sext.w	a5,a5
    8000101c:	dff5                	beqz	a5,80001018 <main+0x1a>
      ;
    __sync_synchronize();
    8000101e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001022:	00001097          	auipc	ra,0x1
    80001026:	b22080e7          	jalr	-1246(ra) # 80001b44 <cpuid>
    8000102a:	85aa                	mv	a1,a0
    8000102c:	00007517          	auipc	a0,0x7
    80001030:	09c50513          	addi	a0,a0,156 # 800080c8 <digits+0x88>
    80001034:	fffff097          	auipc	ra,0xfffff
    80001038:	556080e7          	jalr	1366(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    8000103c:	00000097          	auipc	ra,0x0
    80001040:	0d8080e7          	jalr	216(ra) # 80001114 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001044:	00002097          	auipc	ra,0x2
    80001048:	9ae080e7          	jalr	-1618(ra) # 800029f2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000104c:	00005097          	auipc	ra,0x5
    80001050:	064080e7          	jalr	100(ra) # 800060b0 <plicinithart>
  }

  scheduler();        
    80001054:	00001097          	auipc	ra,0x1
    80001058:	040080e7          	jalr	64(ra) # 80002094 <scheduler>
    consoleinit();
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	3f4080e7          	jalr	1012(ra) # 80000450 <consoleinit>
    printfinit();
    80001064:	fffff097          	auipc	ra,0xfffff
    80001068:	706080e7          	jalr	1798(ra) # 8000076a <printfinit>
    printf("\n");
    8000106c:	00007517          	auipc	a0,0x7
    80001070:	06c50513          	addi	a0,a0,108 # 800080d8 <digits+0x98>
    80001074:	fffff097          	auipc	ra,0xfffff
    80001078:	516080e7          	jalr	1302(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    8000107c:	00007517          	auipc	a0,0x7
    80001080:	03450513          	addi	a0,a0,52 # 800080b0 <digits+0x70>
    80001084:	fffff097          	auipc	ra,0xfffff
    80001088:	506080e7          	jalr	1286(ra) # 8000058a <printf>
    printf("\n");
    8000108c:	00007517          	auipc	a0,0x7
    80001090:	04c50513          	addi	a0,a0,76 # 800080d8 <digits+0x98>
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	4f6080e7          	jalr	1270(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    8000109c:	00000097          	auipc	ra,0x0
    800010a0:	a88080e7          	jalr	-1400(ra) # 80000b24 <kinit>
    kvminit();       // create kernel page table
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	326080e7          	jalr	806(ra) # 800013ca <kvminit>
    kvminithart();   // turn on paging
    800010ac:	00000097          	auipc	ra,0x0
    800010b0:	068080e7          	jalr	104(ra) # 80001114 <kvminithart>
    procinit();      // process table
    800010b4:	00001097          	auipc	ra,0x1
    800010b8:	9dc080e7          	jalr	-1572(ra) # 80001a90 <procinit>
    trapinit();      // trap vectors
    800010bc:	00002097          	auipc	ra,0x2
    800010c0:	90e080e7          	jalr	-1778(ra) # 800029ca <trapinit>
    trapinithart();  // install kernel trap vector
    800010c4:	00002097          	auipc	ra,0x2
    800010c8:	92e080e7          	jalr	-1746(ra) # 800029f2 <trapinithart>
    plicinit();      // set up interrupt controller
    800010cc:	00005097          	auipc	ra,0x5
    800010d0:	fce080e7          	jalr	-50(ra) # 8000609a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010d4:	00005097          	auipc	ra,0x5
    800010d8:	fdc080e7          	jalr	-36(ra) # 800060b0 <plicinithart>
    binit();         // buffer cache
    800010dc:	00002097          	auipc	ra,0x2
    800010e0:	17e080e7          	jalr	382(ra) # 8000325a <binit>
    iinit();         // inode table
    800010e4:	00003097          	auipc	ra,0x3
    800010e8:	81e080e7          	jalr	-2018(ra) # 80003902 <iinit>
    fileinit();      // file table
    800010ec:	00003097          	auipc	ra,0x3
    800010f0:	7c4080e7          	jalr	1988(ra) # 800048b0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010f4:	00005097          	auipc	ra,0x5
    800010f8:	0c4080e7          	jalr	196(ra) # 800061b8 <virtio_disk_init>
    userinit();      // first user process
    800010fc:	00001097          	auipc	ra,0x1
    80001100:	d7a080e7          	jalr	-646(ra) # 80001e76 <userinit>
    __sync_synchronize();
    80001104:	0ff0000f          	fence
    started = 1;
    80001108:	4785                	li	a5,1
    8000110a:	00007717          	auipc	a4,0x7
    8000110e:	78f72723          	sw	a5,1934(a4) # 80008898 <started>
    80001112:	b789                	j	80001054 <main+0x56>

0000000080001114 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001114:	1141                	addi	sp,sp,-16
    80001116:	e422                	sd	s0,8(sp)
    80001118:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000111a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000111e:	00007797          	auipc	a5,0x7
    80001122:	7827b783          	ld	a5,1922(a5) # 800088a0 <kernel_pagetable>
    80001126:	83b1                	srli	a5,a5,0xc
    80001128:	577d                	li	a4,-1
    8000112a:	177e                	slli	a4,a4,0x3f
    8000112c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000112e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001132:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001136:	6422                	ld	s0,8(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret

000000008000113c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000113c:	7139                	addi	sp,sp,-64
    8000113e:	fc06                	sd	ra,56(sp)
    80001140:	f822                	sd	s0,48(sp)
    80001142:	f426                	sd	s1,40(sp)
    80001144:	f04a                	sd	s2,32(sp)
    80001146:	ec4e                	sd	s3,24(sp)
    80001148:	e852                	sd	s4,16(sp)
    8000114a:	e456                	sd	s5,8(sp)
    8000114c:	e05a                	sd	s6,0(sp)
    8000114e:	0080                	addi	s0,sp,64
    80001150:	84aa                	mv	s1,a0
    80001152:	89ae                	mv	s3,a1
    80001154:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001156:	57fd                	li	a5,-1
    80001158:	83e9                	srli	a5,a5,0x1a
    8000115a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000115c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000115e:	04b7f263          	bgeu	a5,a1,800011a2 <walk+0x66>
    panic("walk");
    80001162:	00007517          	auipc	a0,0x7
    80001166:	f7e50513          	addi	a0,a0,-130 # 800080e0 <digits+0xa0>
    8000116a:	fffff097          	auipc	ra,0xfffff
    8000116e:	3d6080e7          	jalr	982(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001172:	060a8663          	beqz	s5,800011de <walk+0xa2>
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	a18080e7          	jalr	-1512(ra) # 80000b8e <kalloc>
    8000117e:	84aa                	mv	s1,a0
    80001180:	c529                	beqz	a0,800011ca <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001182:	6605                	lui	a2,0x1
    80001184:	4581                	li	a1,0
    80001186:	00000097          	auipc	ra,0x0
    8000118a:	cd2080e7          	jalr	-814(ra) # 80000e58 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000118e:	00c4d793          	srli	a5,s1,0xc
    80001192:	07aa                	slli	a5,a5,0xa
    80001194:	0017e793          	ori	a5,a5,1
    80001198:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000119c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffbceaf>
    8000119e:	036a0063          	beq	s4,s6,800011be <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011a2:	0149d933          	srl	s2,s3,s4
    800011a6:	1ff97913          	andi	s2,s2,511
    800011aa:	090e                	slli	s2,s2,0x3
    800011ac:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011ae:	00093483          	ld	s1,0(s2)
    800011b2:	0014f793          	andi	a5,s1,1
    800011b6:	dfd5                	beqz	a5,80001172 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011b8:	80a9                	srli	s1,s1,0xa
    800011ba:	04b2                	slli	s1,s1,0xc
    800011bc:	b7c5                	j	8000119c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011be:	00c9d513          	srli	a0,s3,0xc
    800011c2:	1ff57513          	andi	a0,a0,511
    800011c6:	050e                	slli	a0,a0,0x3
    800011c8:	9526                	add	a0,a0,s1
}
    800011ca:	70e2                	ld	ra,56(sp)
    800011cc:	7442                	ld	s0,48(sp)
    800011ce:	74a2                	ld	s1,40(sp)
    800011d0:	7902                	ld	s2,32(sp)
    800011d2:	69e2                	ld	s3,24(sp)
    800011d4:	6a42                	ld	s4,16(sp)
    800011d6:	6aa2                	ld	s5,8(sp)
    800011d8:	6b02                	ld	s6,0(sp)
    800011da:	6121                	addi	sp,sp,64
    800011dc:	8082                	ret
        return 0;
    800011de:	4501                	li	a0,0
    800011e0:	b7ed                	j	800011ca <walk+0x8e>

00000000800011e2 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011e2:	57fd                	li	a5,-1
    800011e4:	83e9                	srli	a5,a5,0x1a
    800011e6:	00b7f463          	bgeu	a5,a1,800011ee <walkaddr+0xc>
    return 0;
    800011ea:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011ec:	8082                	ret
{
    800011ee:	1141                	addi	sp,sp,-16
    800011f0:	e406                	sd	ra,8(sp)
    800011f2:	e022                	sd	s0,0(sp)
    800011f4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011f6:	4601                	li	a2,0
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	f44080e7          	jalr	-188(ra) # 8000113c <walk>
  if(pte == 0)
    80001200:	c105                	beqz	a0,80001220 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001202:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001204:	0117f693          	andi	a3,a5,17
    80001208:	4745                	li	a4,17
    return 0;
    8000120a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000120c:	00e68663          	beq	a3,a4,80001218 <walkaddr+0x36>
}
    80001210:	60a2                	ld	ra,8(sp)
    80001212:	6402                	ld	s0,0(sp)
    80001214:	0141                	addi	sp,sp,16
    80001216:	8082                	ret
  pa = PTE2PA(*pte);
    80001218:	83a9                	srli	a5,a5,0xa
    8000121a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000121e:	bfcd                	j	80001210 <walkaddr+0x2e>
    return 0;
    80001220:	4501                	li	a0,0
    80001222:	b7fd                	j	80001210 <walkaddr+0x2e>

0000000080001224 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001224:	715d                	addi	sp,sp,-80
    80001226:	e486                	sd	ra,72(sp)
    80001228:	e0a2                	sd	s0,64(sp)
    8000122a:	fc26                	sd	s1,56(sp)
    8000122c:	f84a                	sd	s2,48(sp)
    8000122e:	f44e                	sd	s3,40(sp)
    80001230:	f052                	sd	s4,32(sp)
    80001232:	ec56                	sd	s5,24(sp)
    80001234:	e85a                	sd	s6,16(sp)
    80001236:	e45e                	sd	s7,8(sp)
    80001238:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000123a:	c639                	beqz	a2,80001288 <mappages+0x64>
    8000123c:	8aaa                	mv	s5,a0
    8000123e:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001240:	777d                	lui	a4,0xfffff
    80001242:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001246:	fff58993          	addi	s3,a1,-1
    8000124a:	99b2                	add	s3,s3,a2
    8000124c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001250:	893e                	mv	s2,a5
    80001252:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001256:	6b85                	lui	s7,0x1
    80001258:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000125c:	4605                	li	a2,1
    8000125e:	85ca                	mv	a1,s2
    80001260:	8556                	mv	a0,s5
    80001262:	00000097          	auipc	ra,0x0
    80001266:	eda080e7          	jalr	-294(ra) # 8000113c <walk>
    8000126a:	cd1d                	beqz	a0,800012a8 <mappages+0x84>
    if(*pte & PTE_V)
    8000126c:	611c                	ld	a5,0(a0)
    8000126e:	8b85                	andi	a5,a5,1
    80001270:	e785                	bnez	a5,80001298 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001272:	80b1                	srli	s1,s1,0xc
    80001274:	04aa                	slli	s1,s1,0xa
    80001276:	0164e4b3          	or	s1,s1,s6
    8000127a:	0014e493          	ori	s1,s1,1
    8000127e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001280:	05390063          	beq	s2,s3,800012c0 <mappages+0x9c>
    a += PGSIZE;
    80001284:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001286:	bfc9                	j	80001258 <mappages+0x34>
    panic("mappages: size");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	2b0080e7          	jalr	688(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6050513          	addi	a0,a0,-416 # 800080f8 <digits+0xb8>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	2a0080e7          	jalr	672(ra) # 80000540 <panic>
      return -1;
    800012a8:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012aa:	60a6                	ld	ra,72(sp)
    800012ac:	6406                	ld	s0,64(sp)
    800012ae:	74e2                	ld	s1,56(sp)
    800012b0:	7942                	ld	s2,48(sp)
    800012b2:	79a2                	ld	s3,40(sp)
    800012b4:	7a02                	ld	s4,32(sp)
    800012b6:	6ae2                	ld	s5,24(sp)
    800012b8:	6b42                	ld	s6,16(sp)
    800012ba:	6ba2                	ld	s7,8(sp)
    800012bc:	6161                	addi	sp,sp,80
    800012be:	8082                	ret
  return 0;
    800012c0:	4501                	li	a0,0
    800012c2:	b7e5                	j	800012aa <mappages+0x86>

00000000800012c4 <kvmmap>:
{
    800012c4:	1141                	addi	sp,sp,-16
    800012c6:	e406                	sd	ra,8(sp)
    800012c8:	e022                	sd	s0,0(sp)
    800012ca:	0800                	addi	s0,sp,16
    800012cc:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012ce:	86b2                	mv	a3,a2
    800012d0:	863e                	mv	a2,a5
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f52080e7          	jalr	-174(ra) # 80001224 <mappages>
    800012da:	e509                	bnez	a0,800012e4 <kvmmap+0x20>
}
    800012dc:	60a2                	ld	ra,8(sp)
    800012de:	6402                	ld	s0,0(sp)
    800012e0:	0141                	addi	sp,sp,16
    800012e2:	8082                	ret
    panic("kvmmap");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e2450513          	addi	a0,a0,-476 # 80008108 <digits+0xc8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	254080e7          	jalr	596(ra) # 80000540 <panic>

00000000800012f4 <kvmmake>:
{
    800012f4:	1101                	addi	sp,sp,-32
    800012f6:	ec06                	sd	ra,24(sp)
    800012f8:	e822                	sd	s0,16(sp)
    800012fa:	e426                	sd	s1,8(sp)
    800012fc:	e04a                	sd	s2,0(sp)
    800012fe:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001300:	00000097          	auipc	ra,0x0
    80001304:	88e080e7          	jalr	-1906(ra) # 80000b8e <kalloc>
    80001308:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000130a:	6605                	lui	a2,0x1
    8000130c:	4581                	li	a1,0
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	b4a080e7          	jalr	-1206(ra) # 80000e58 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001316:	4719                	li	a4,6
    80001318:	6685                	lui	a3,0x1
    8000131a:	10000637          	lui	a2,0x10000
    8000131e:	100005b7          	lui	a1,0x10000
    80001322:	8526                	mv	a0,s1
    80001324:	00000097          	auipc	ra,0x0
    80001328:	fa0080e7          	jalr	-96(ra) # 800012c4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000132c:	4719                	li	a4,6
    8000132e:	6685                	lui	a3,0x1
    80001330:	10001637          	lui	a2,0x10001
    80001334:	100015b7          	lui	a1,0x10001
    80001338:	8526                	mv	a0,s1
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f8a080e7          	jalr	-118(ra) # 800012c4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001342:	4719                	li	a4,6
    80001344:	004006b7          	lui	a3,0x400
    80001348:	0c000637          	lui	a2,0xc000
    8000134c:	0c0005b7          	lui	a1,0xc000
    80001350:	8526                	mv	a0,s1
    80001352:	00000097          	auipc	ra,0x0
    80001356:	f72080e7          	jalr	-142(ra) # 800012c4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000135a:	00007917          	auipc	s2,0x7
    8000135e:	ca690913          	addi	s2,s2,-858 # 80008000 <etext>
    80001362:	4729                	li	a4,10
    80001364:	80007697          	auipc	a3,0x80007
    80001368:	c9c68693          	addi	a3,a3,-868 # 8000 <_entry-0x7fff8000>
    8000136c:	4605                	li	a2,1
    8000136e:	067e                	slli	a2,a2,0x1f
    80001370:	85b2                	mv	a1,a2
    80001372:	8526                	mv	a0,s1
    80001374:	00000097          	auipc	ra,0x0
    80001378:	f50080e7          	jalr	-176(ra) # 800012c4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000137c:	4719                	li	a4,6
    8000137e:	46c5                	li	a3,17
    80001380:	06ee                	slli	a3,a3,0x1b
    80001382:	412686b3          	sub	a3,a3,s2
    80001386:	864a                	mv	a2,s2
    80001388:	85ca                	mv	a1,s2
    8000138a:	8526                	mv	a0,s1
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	f38080e7          	jalr	-200(ra) # 800012c4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001394:	4729                	li	a4,10
    80001396:	6685                	lui	a3,0x1
    80001398:	00006617          	auipc	a2,0x6
    8000139c:	c6860613          	addi	a2,a2,-920 # 80007000 <_trampoline>
    800013a0:	040005b7          	lui	a1,0x4000
    800013a4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013a6:	05b2                	slli	a1,a1,0xc
    800013a8:	8526                	mv	a0,s1
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	f1a080e7          	jalr	-230(ra) # 800012c4 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013b2:	8526                	mv	a0,s1
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	646080e7          	jalr	1606(ra) # 800019fa <proc_mapstacks>
}
    800013bc:	8526                	mv	a0,s1
    800013be:	60e2                	ld	ra,24(sp)
    800013c0:	6442                	ld	s0,16(sp)
    800013c2:	64a2                	ld	s1,8(sp)
    800013c4:	6902                	ld	s2,0(sp)
    800013c6:	6105                	addi	sp,sp,32
    800013c8:	8082                	ret

00000000800013ca <kvminit>:
{
    800013ca:	1141                	addi	sp,sp,-16
    800013cc:	e406                	sd	ra,8(sp)
    800013ce:	e022                	sd	s0,0(sp)
    800013d0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013d2:	00000097          	auipc	ra,0x0
    800013d6:	f22080e7          	jalr	-222(ra) # 800012f4 <kvmmake>
    800013da:	00007797          	auipc	a5,0x7
    800013de:	4ca7b323          	sd	a0,1222(a5) # 800088a0 <kernel_pagetable>
}
    800013e2:	60a2                	ld	ra,8(sp)
    800013e4:	6402                	ld	s0,0(sp)
    800013e6:	0141                	addi	sp,sp,16
    800013e8:	8082                	ret

00000000800013ea <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013ea:	715d                	addi	sp,sp,-80
    800013ec:	e486                	sd	ra,72(sp)
    800013ee:	e0a2                	sd	s0,64(sp)
    800013f0:	fc26                	sd	s1,56(sp)
    800013f2:	f84a                	sd	s2,48(sp)
    800013f4:	f44e                	sd	s3,40(sp)
    800013f6:	f052                	sd	s4,32(sp)
    800013f8:	ec56                	sd	s5,24(sp)
    800013fa:	e85a                	sd	s6,16(sp)
    800013fc:	e45e                	sd	s7,8(sp)
    800013fe:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001400:	03459793          	slli	a5,a1,0x34
    80001404:	e795                	bnez	a5,80001430 <uvmunmap+0x46>
    80001406:	8a2a                	mv	s4,a0
    80001408:	892e                	mv	s2,a1
    8000140a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000140c:	0632                	slli	a2,a2,0xc
    8000140e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001412:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001414:	6b05                	lui	s6,0x1
    80001416:	0735e263          	bltu	a1,s3,8000147a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000141a:	60a6                	ld	ra,72(sp)
    8000141c:	6406                	ld	s0,64(sp)
    8000141e:	74e2                	ld	s1,56(sp)
    80001420:	7942                	ld	s2,48(sp)
    80001422:	79a2                	ld	s3,40(sp)
    80001424:	7a02                	ld	s4,32(sp)
    80001426:	6ae2                	ld	s5,24(sp)
    80001428:	6b42                	ld	s6,16(sp)
    8000142a:	6ba2                	ld	s7,8(sp)
    8000142c:	6161                	addi	sp,sp,80
    8000142e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	ce050513          	addi	a0,a0,-800 # 80008110 <digits+0xd0>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001440:	00007517          	auipc	a0,0x7
    80001444:	ce850513          	addi	a0,a0,-792 # 80008128 <digits+0xe8>
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	0f8080e7          	jalr	248(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001450:	00007517          	auipc	a0,0x7
    80001454:	ce850513          	addi	a0,a0,-792 # 80008138 <digits+0xf8>
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	0e8080e7          	jalr	232(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001460:	00007517          	auipc	a0,0x7
    80001464:	cf050513          	addi	a0,a0,-784 # 80008150 <digits+0x110>
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	0d8080e7          	jalr	216(ra) # 80000540 <panic>
    *pte = 0;
    80001470:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001474:	995a                	add	s2,s2,s6
    80001476:	fb3972e3          	bgeu	s2,s3,8000141a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000147a:	4601                	li	a2,0
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8552                	mv	a0,s4
    80001480:	00000097          	auipc	ra,0x0
    80001484:	cbc080e7          	jalr	-836(ra) # 8000113c <walk>
    80001488:	84aa                	mv	s1,a0
    8000148a:	d95d                	beqz	a0,80001440 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000148c:	6108                	ld	a0,0(a0)
    8000148e:	00157793          	andi	a5,a0,1
    80001492:	dfdd                	beqz	a5,80001450 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001494:	3ff57793          	andi	a5,a0,1023
    80001498:	fd7784e3          	beq	a5,s7,80001460 <uvmunmap+0x76>
    if(do_free){
    8000149c:	fc0a8ae3          	beqz	s5,80001470 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014a0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014a2:	0532                	slli	a0,a0,0xc
    800014a4:	fffff097          	auipc	ra,0xfffff
    800014a8:	544080e7          	jalr	1348(ra) # 800009e8 <kfree>
    800014ac:	b7d1                	j	80001470 <uvmunmap+0x86>

00000000800014ae <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014ae:	1101                	addi	sp,sp,-32
    800014b0:	ec06                	sd	ra,24(sp)
    800014b2:	e822                	sd	s0,16(sp)
    800014b4:	e426                	sd	s1,8(sp)
    800014b6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	6d6080e7          	jalr	1750(ra) # 80000b8e <kalloc>
    800014c0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014c2:	c519                	beqz	a0,800014d0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014c4:	6605                	lui	a2,0x1
    800014c6:	4581                	li	a1,0
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	990080e7          	jalr	-1648(ra) # 80000e58 <memset>
  return pagetable;
}
    800014d0:	8526                	mv	a0,s1
    800014d2:	60e2                	ld	ra,24(sp)
    800014d4:	6442                	ld	s0,16(sp)
    800014d6:	64a2                	ld	s1,8(sp)
    800014d8:	6105                	addi	sp,sp,32
    800014da:	8082                	ret

00000000800014dc <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014dc:	7179                	addi	sp,sp,-48
    800014de:	f406                	sd	ra,40(sp)
    800014e0:	f022                	sd	s0,32(sp)
    800014e2:	ec26                	sd	s1,24(sp)
    800014e4:	e84a                	sd	s2,16(sp)
    800014e6:	e44e                	sd	s3,8(sp)
    800014e8:	e052                	sd	s4,0(sp)
    800014ea:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014ec:	6785                	lui	a5,0x1
    800014ee:	04f67863          	bgeu	a2,a5,8000153e <uvmfirst+0x62>
    800014f2:	8a2a                	mv	s4,a0
    800014f4:	89ae                	mv	s3,a1
    800014f6:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	696080e7          	jalr	1686(ra) # 80000b8e <kalloc>
    80001500:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001502:	6605                	lui	a2,0x1
    80001504:	4581                	li	a1,0
    80001506:	00000097          	auipc	ra,0x0
    8000150a:	952080e7          	jalr	-1710(ra) # 80000e58 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000150e:	4779                	li	a4,30
    80001510:	86ca                	mv	a3,s2
    80001512:	6605                	lui	a2,0x1
    80001514:	4581                	li	a1,0
    80001516:	8552                	mv	a0,s4
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	d0c080e7          	jalr	-756(ra) # 80001224 <mappages>
  memmove(mem, src, sz);
    80001520:	8626                	mv	a2,s1
    80001522:	85ce                	mv	a1,s3
    80001524:	854a                	mv	a0,s2
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	98e080e7          	jalr	-1650(ra) # 80000eb4 <memmove>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret
    panic("uvmfirst: more than a page");
    8000153e:	00007517          	auipc	a0,0x7
    80001542:	c2a50513          	addi	a0,a0,-982 # 80008168 <digits+0x128>
    80001546:	fffff097          	auipc	ra,0xfffff
    8000154a:	ffa080e7          	jalr	-6(ra) # 80000540 <panic>

000000008000154e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000154e:	1101                	addi	sp,sp,-32
    80001550:	ec06                	sd	ra,24(sp)
    80001552:	e822                	sd	s0,16(sp)
    80001554:	e426                	sd	s1,8(sp)
    80001556:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001558:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000155a:	00b67d63          	bgeu	a2,a1,80001574 <uvmdealloc+0x26>
    8000155e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001560:	6785                	lui	a5,0x1
    80001562:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001564:	00f60733          	add	a4,a2,a5
    80001568:	76fd                	lui	a3,0xfffff
    8000156a:	8f75                	and	a4,a4,a3
    8000156c:	97ae                	add	a5,a5,a1
    8000156e:	8ff5                	and	a5,a5,a3
    80001570:	00f76863          	bltu	a4,a5,80001580 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001574:	8526                	mv	a0,s1
    80001576:	60e2                	ld	ra,24(sp)
    80001578:	6442                	ld	s0,16(sp)
    8000157a:	64a2                	ld	s1,8(sp)
    8000157c:	6105                	addi	sp,sp,32
    8000157e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001580:	8f99                	sub	a5,a5,a4
    80001582:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001584:	4685                	li	a3,1
    80001586:	0007861b          	sext.w	a2,a5
    8000158a:	85ba                	mv	a1,a4
    8000158c:	00000097          	auipc	ra,0x0
    80001590:	e5e080e7          	jalr	-418(ra) # 800013ea <uvmunmap>
    80001594:	b7c5                	j	80001574 <uvmdealloc+0x26>

0000000080001596 <uvmalloc>:
  if(newsz < oldsz)
    80001596:	0ab66563          	bltu	a2,a1,80001640 <uvmalloc+0xaa>
{
    8000159a:	7139                	addi	sp,sp,-64
    8000159c:	fc06                	sd	ra,56(sp)
    8000159e:	f822                	sd	s0,48(sp)
    800015a0:	f426                	sd	s1,40(sp)
    800015a2:	f04a                	sd	s2,32(sp)
    800015a4:	ec4e                	sd	s3,24(sp)
    800015a6:	e852                	sd	s4,16(sp)
    800015a8:	e456                	sd	s5,8(sp)
    800015aa:	e05a                	sd	s6,0(sp)
    800015ac:	0080                	addi	s0,sp,64
    800015ae:	8aaa                	mv	s5,a0
    800015b0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015b2:	6785                	lui	a5,0x1
    800015b4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015b6:	95be                	add	a1,a1,a5
    800015b8:	77fd                	lui	a5,0xfffff
    800015ba:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015be:	08c9f363          	bgeu	s3,a2,80001644 <uvmalloc+0xae>
    800015c2:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015c4:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	5c6080e7          	jalr	1478(ra) # 80000b8e <kalloc>
    800015d0:	84aa                	mv	s1,a0
    if(mem == 0){
    800015d2:	c51d                	beqz	a0,80001600 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015d4:	6605                	lui	a2,0x1
    800015d6:	4581                	li	a1,0
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	880080e7          	jalr	-1920(ra) # 80000e58 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015e0:	875a                	mv	a4,s6
    800015e2:	86a6                	mv	a3,s1
    800015e4:	6605                	lui	a2,0x1
    800015e6:	85ca                	mv	a1,s2
    800015e8:	8556                	mv	a0,s5
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	c3a080e7          	jalr	-966(ra) # 80001224 <mappages>
    800015f2:	e90d                	bnez	a0,80001624 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015f4:	6785                	lui	a5,0x1
    800015f6:	993e                	add	s2,s2,a5
    800015f8:	fd4968e3          	bltu	s2,s4,800015c8 <uvmalloc+0x32>
  return newsz;
    800015fc:	8552                	mv	a0,s4
    800015fe:	a809                	j	80001610 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001600:	864e                	mv	a2,s3
    80001602:	85ca                	mv	a1,s2
    80001604:	8556                	mv	a0,s5
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	f48080e7          	jalr	-184(ra) # 8000154e <uvmdealloc>
      return 0;
    8000160e:	4501                	li	a0,0
}
    80001610:	70e2                	ld	ra,56(sp)
    80001612:	7442                	ld	s0,48(sp)
    80001614:	74a2                	ld	s1,40(sp)
    80001616:	7902                	ld	s2,32(sp)
    80001618:	69e2                	ld	s3,24(sp)
    8000161a:	6a42                	ld	s4,16(sp)
    8000161c:	6aa2                	ld	s5,8(sp)
    8000161e:	6b02                	ld	s6,0(sp)
    80001620:	6121                	addi	sp,sp,64
    80001622:	8082                	ret
      kfree(mem);
    80001624:	8526                	mv	a0,s1
    80001626:	fffff097          	auipc	ra,0xfffff
    8000162a:	3c2080e7          	jalr	962(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000162e:	864e                	mv	a2,s3
    80001630:	85ca                	mv	a1,s2
    80001632:	8556                	mv	a0,s5
    80001634:	00000097          	auipc	ra,0x0
    80001638:	f1a080e7          	jalr	-230(ra) # 8000154e <uvmdealloc>
      return 0;
    8000163c:	4501                	li	a0,0
    8000163e:	bfc9                	j	80001610 <uvmalloc+0x7a>
    return oldsz;
    80001640:	852e                	mv	a0,a1
}
    80001642:	8082                	ret
  return newsz;
    80001644:	8532                	mv	a0,a2
    80001646:	b7e9                	j	80001610 <uvmalloc+0x7a>

0000000080001648 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001648:	7179                	addi	sp,sp,-48
    8000164a:	f406                	sd	ra,40(sp)
    8000164c:	f022                	sd	s0,32(sp)
    8000164e:	ec26                	sd	s1,24(sp)
    80001650:	e84a                	sd	s2,16(sp)
    80001652:	e44e                	sd	s3,8(sp)
    80001654:	e052                	sd	s4,0(sp)
    80001656:	1800                	addi	s0,sp,48
    80001658:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000165a:	84aa                	mv	s1,a0
    8000165c:	6905                	lui	s2,0x1
    8000165e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001660:	4985                	li	s3,1
    80001662:	a829                	j	8000167c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001664:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001666:	00c79513          	slli	a0,a5,0xc
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	fde080e7          	jalr	-34(ra) # 80001648 <freewalk>
      pagetable[i] = 0;
    80001672:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001676:	04a1                	addi	s1,s1,8
    80001678:	03248163          	beq	s1,s2,8000169a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000167c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000167e:	00f7f713          	andi	a4,a5,15
    80001682:	ff3701e3          	beq	a4,s3,80001664 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001686:	8b85                	andi	a5,a5,1
    80001688:	d7fd                	beqz	a5,80001676 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000168a:	00007517          	auipc	a0,0x7
    8000168e:	afe50513          	addi	a0,a0,-1282 # 80008188 <digits+0x148>
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	eae080e7          	jalr	-338(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000169a:	8552                	mv	a0,s4
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	34c080e7          	jalr	844(ra) # 800009e8 <kfree>
}
    800016a4:	70a2                	ld	ra,40(sp)
    800016a6:	7402                	ld	s0,32(sp)
    800016a8:	64e2                	ld	s1,24(sp)
    800016aa:	6942                	ld	s2,16(sp)
    800016ac:	69a2                	ld	s3,8(sp)
    800016ae:	6a02                	ld	s4,0(sp)
    800016b0:	6145                	addi	sp,sp,48
    800016b2:	8082                	ret

00000000800016b4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016b4:	1101                	addi	sp,sp,-32
    800016b6:	ec06                	sd	ra,24(sp)
    800016b8:	e822                	sd	s0,16(sp)
    800016ba:	e426                	sd	s1,8(sp)
    800016bc:	1000                	addi	s0,sp,32
    800016be:	84aa                	mv	s1,a0
  if(sz > 0)
    800016c0:	e999                	bnez	a1,800016d6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016c2:	8526                	mv	a0,s1
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	f84080e7          	jalr	-124(ra) # 80001648 <freewalk>
}
    800016cc:	60e2                	ld	ra,24(sp)
    800016ce:	6442                	ld	s0,16(sp)
    800016d0:	64a2                	ld	s1,8(sp)
    800016d2:	6105                	addi	sp,sp,32
    800016d4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016d6:	6785                	lui	a5,0x1
    800016d8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016da:	95be                	add	a1,a1,a5
    800016dc:	4685                	li	a3,1
    800016de:	00c5d613          	srli	a2,a1,0xc
    800016e2:	4581                	li	a1,0
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	d06080e7          	jalr	-762(ra) # 800013ea <uvmunmap>
    800016ec:	bfd9                	j	800016c2 <uvmfree+0xe>

00000000800016ee <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800016ee:	715d                	addi	sp,sp,-80
    800016f0:	e486                	sd	ra,72(sp)
    800016f2:	e0a2                	sd	s0,64(sp)
    800016f4:	fc26                	sd	s1,56(sp)
    800016f6:	f84a                	sd	s2,48(sp)
    800016f8:	f44e                	sd	s3,40(sp)
    800016fa:	f052                	sd	s4,32(sp)
    800016fc:	ec56                	sd	s5,24(sp)
    800016fe:	e85a                	sd	s6,16(sp)
    80001700:	e45e                	sd	s7,8(sp)
    80001702:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001704:	ce5d                	beqz	a2,800017c2 <uvmcopy+0xd4>
    80001706:	8aaa                	mv	s5,a0
    80001708:	8a2e                	mv	s4,a1
    8000170a:	89b2                	mv	s3,a2
    8000170c:	4481                	li	s1,0
    pa = PTE2PA(*pte);

    // Only make writable pages COW
    if(*pte & PTE_W) {
      flags = (PTE_FLAGS(*pte) & ~PTE_W) | PTE_COW;
      *pte = PA2PTE(pa) | flags;
    8000170e:	7b7d                	lui	s6,0xfffff
    80001710:	002b5b13          	srli	s6,s6,0x2
    80001714:	a0a1                	j	8000175c <uvmcopy+0x6e>
      panic("uvmcopy: pte should exist");
    80001716:	00007517          	auipc	a0,0x7
    8000171a:	a8250513          	addi	a0,a0,-1406 # 80008198 <digits+0x158>
    8000171e:	fffff097          	auipc	ra,0xfffff
    80001722:	e22080e7          	jalr	-478(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001726:	00007517          	auipc	a0,0x7
    8000172a:	a9250513          	addi	a0,a0,-1390 # 800081b8 <digits+0x178>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	e12080e7          	jalr	-494(ra) # 80000540 <panic>
    } else {
      flags = PTE_FLAGS(*pte);
    }

    if(mappages(new, i, PGSIZE, pa, flags) != 0)
    80001736:	86ca                	mv	a3,s2
    80001738:	6605                	lui	a2,0x1
    8000173a:	85a6                	mv	a1,s1
    8000173c:	8552                	mv	a0,s4
    8000173e:	00000097          	auipc	ra,0x0
    80001742:	ae6080e7          	jalr	-1306(ra) # 80001224 <mappages>
    80001746:	8baa                	mv	s7,a0
    80001748:	e539                	bnez	a0,80001796 <uvmcopy+0xa8>
      goto err;
    
    incref(pa);
    8000174a:	854a                	mv	a0,s2
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	4e0080e7          	jalr	1248(ra) # 80000c2c <incref>
  for(i = 0; i < sz; i += PGSIZE){
    80001754:	6785                	lui	a5,0x1
    80001756:	94be                	add	s1,s1,a5
    80001758:	0534f963          	bgeu	s1,s3,800017aa <uvmcopy+0xbc>
    if((pte = walk(old, i, 0)) == 0)
    8000175c:	4601                	li	a2,0
    8000175e:	85a6                	mv	a1,s1
    80001760:	8556                	mv	a0,s5
    80001762:	00000097          	auipc	ra,0x0
    80001766:	9da080e7          	jalr	-1574(ra) # 8000113c <walk>
    8000176a:	d555                	beqz	a0,80001716 <uvmcopy+0x28>
    if((*pte & PTE_V) == 0)
    8000176c:	611c                	ld	a5,0(a0)
    8000176e:	0017f713          	andi	a4,a5,1
    80001772:	db55                	beqz	a4,80001726 <uvmcopy+0x38>
    pa = PTE2PA(*pte);
    80001774:	00a7d913          	srli	s2,a5,0xa
    80001778:	0932                	slli	s2,s2,0xc
    if(*pte & PTE_W) {
    8000177a:	0047f693          	andi	a3,a5,4
      flags = PTE_FLAGS(*pte);
    8000177e:	3ff7f713          	andi	a4,a5,1023
    if(*pte & PTE_W) {
    80001782:	dad5                	beqz	a3,80001736 <uvmcopy+0x48>
      flags = (PTE_FLAGS(*pte) & ~PTE_W) | PTE_COW;
    80001784:	2fb7f693          	andi	a3,a5,763
    80001788:	1006e713          	ori	a4,a3,256
      *pte = PA2PTE(pa) | flags;
    8000178c:	0167f7b3          	and	a5,a5,s6
    80001790:	8fd9                	or	a5,a5,a4
    80001792:	e11c                	sd	a5,0(a0)
    80001794:	b74d                	j	80001736 <uvmcopy+0x48>
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001796:	4685                	li	a3,1
    80001798:	00c4d613          	srli	a2,s1,0xc
    8000179c:	4581                	li	a1,0
    8000179e:	8552                	mv	a0,s4
    800017a0:	00000097          	auipc	ra,0x0
    800017a4:	c4a080e7          	jalr	-950(ra) # 800013ea <uvmunmap>
  return -1;
    800017a8:	5bfd                	li	s7,-1
}
    800017aa:	855e                	mv	a0,s7
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6161                	addi	sp,sp,80
    800017c0:	8082                	ret
  return 0;
    800017c2:	4b81                	li	s7,0
    800017c4:	b7dd                	j	800017aa <uvmcopy+0xbc>

00000000800017c6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017c6:	1141                	addi	sp,sp,-16
    800017c8:	e406                	sd	ra,8(sp)
    800017ca:	e022                	sd	s0,0(sp)
    800017cc:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017ce:	4601                	li	a2,0
    800017d0:	00000097          	auipc	ra,0x0
    800017d4:	96c080e7          	jalr	-1684(ra) # 8000113c <walk>
  if(pte == 0)
    800017d8:	c901                	beqz	a0,800017e8 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017da:	611c                	ld	a5,0(a0)
    800017dc:	9bbd                	andi	a5,a5,-17
    800017de:	e11c                	sd	a5,0(a0)
}
    800017e0:	60a2                	ld	ra,8(sp)
    800017e2:	6402                	ld	s0,0(sp)
    800017e4:	0141                	addi	sp,sp,16
    800017e6:	8082                	ret
    panic("uvmclear");
    800017e8:	00007517          	auipc	a0,0x7
    800017ec:	9f050513          	addi	a0,a0,-1552 # 800081d8 <digits+0x198>
    800017f0:	fffff097          	auipc	ra,0xfffff
    800017f4:	d50080e7          	jalr	-688(ra) # 80000540 <panic>

00000000800017f8 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017f8:	c2d5                	beqz	a3,8000189c <copyout+0xa4>
{
    800017fa:	711d                	addi	sp,sp,-96
    800017fc:	ec86                	sd	ra,88(sp)
    800017fe:	e8a2                	sd	s0,80(sp)
    80001800:	e4a6                	sd	s1,72(sp)
    80001802:	e0ca                	sd	s2,64(sp)
    80001804:	fc4e                	sd	s3,56(sp)
    80001806:	f852                	sd	s4,48(sp)
    80001808:	f456                	sd	s5,40(sp)
    8000180a:	f05a                	sd	s6,32(sp)
    8000180c:	ec5e                	sd	s7,24(sp)
    8000180e:	e862                	sd	s8,16(sp)
    80001810:	e466                	sd	s9,8(sp)
    80001812:	1080                	addi	s0,sp,96
    80001814:	8baa                	mv	s7,a0
    80001816:	89ae                	mv	s3,a1
    80001818:	8b32                	mv	s6,a2
    8000181a:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    8000181c:	7cfd                	lui	s9,0xfffff
    if (PTE_FLAGS(*(walk(pagetable, va0, 0))) & PTE_COW)
    {
      cow_handler( pagetable,va0);
      pa0 = walkaddr(pagetable, va0);
    }
    n = PGSIZE - (dstva - va0);
    8000181e:	6c05                	lui	s8,0x1
    80001820:	a081                	j	80001860 <copyout+0x68>
      cow_handler( pagetable,va0);
    80001822:	85ca                	mv	a1,s2
    80001824:	855e                	mv	a0,s7
    80001826:	00001097          	auipc	ra,0x1
    8000182a:	43c080e7          	jalr	1084(ra) # 80002c62 <cow_handler>
      pa0 = walkaddr(pagetable, va0);
    8000182e:	85ca                	mv	a1,s2
    80001830:	855e                	mv	a0,s7
    80001832:	00000097          	auipc	ra,0x0
    80001836:	9b0080e7          	jalr	-1616(ra) # 800011e2 <walkaddr>
    8000183a:	8a2a                	mv	s4,a0
    8000183c:	a0b9                	j	8000188a <copyout+0x92>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000183e:	41298533          	sub	a0,s3,s2
    80001842:	0004861b          	sext.w	a2,s1
    80001846:	85da                	mv	a1,s6
    80001848:	9552                	add	a0,a0,s4
    8000184a:	fffff097          	auipc	ra,0xfffff
    8000184e:	66a080e7          	jalr	1642(ra) # 80000eb4 <memmove>

    len -= n;
    80001852:	409a8ab3          	sub	s5,s5,s1
    src += n;
    80001856:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    80001858:	018909b3          	add	s3,s2,s8
  while(len > 0){
    8000185c:	020a8e63          	beqz	s5,80001898 <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    80001860:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    80001864:	85ca                	mv	a1,s2
    80001866:	855e                	mv	a0,s7
    80001868:	00000097          	auipc	ra,0x0
    8000186c:	97a080e7          	jalr	-1670(ra) # 800011e2 <walkaddr>
    80001870:	8a2a                	mv	s4,a0
    if(pa0 == 0)
    80001872:	c51d                	beqz	a0,800018a0 <copyout+0xa8>
    if (PTE_FLAGS(*(walk(pagetable, va0, 0))) & PTE_COW)
    80001874:	4601                	li	a2,0
    80001876:	85ca                	mv	a1,s2
    80001878:	855e                	mv	a0,s7
    8000187a:	00000097          	auipc	ra,0x0
    8000187e:	8c2080e7          	jalr	-1854(ra) # 8000113c <walk>
    80001882:	611c                	ld	a5,0(a0)
    80001884:	1007f793          	andi	a5,a5,256
    80001888:	ffc9                	bnez	a5,80001822 <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    8000188a:	413904b3          	sub	s1,s2,s3
    8000188e:	94e2                	add	s1,s1,s8
    80001890:	fa9af7e3          	bgeu	s5,s1,8000183e <copyout+0x46>
    80001894:	84d6                	mv	s1,s5
    80001896:	b765                	j	8000183e <copyout+0x46>
  }
  return 0;
    80001898:	4501                	li	a0,0
    8000189a:	a021                	j	800018a2 <copyout+0xaa>
    8000189c:	4501                	li	a0,0
}
    8000189e:	8082                	ret
      return -1;
    800018a0:	557d                	li	a0,-1
}
    800018a2:	60e6                	ld	ra,88(sp)
    800018a4:	6446                	ld	s0,80(sp)
    800018a6:	64a6                	ld	s1,72(sp)
    800018a8:	6906                	ld	s2,64(sp)
    800018aa:	79e2                	ld	s3,56(sp)
    800018ac:	7a42                	ld	s4,48(sp)
    800018ae:	7aa2                	ld	s5,40(sp)
    800018b0:	7b02                	ld	s6,32(sp)
    800018b2:	6be2                	ld	s7,24(sp)
    800018b4:	6c42                	ld	s8,16(sp)
    800018b6:	6ca2                	ld	s9,8(sp)
    800018b8:	6125                	addi	sp,sp,96
    800018ba:	8082                	ret

00000000800018bc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018bc:	caa5                	beqz	a3,8000192c <copyin+0x70>
{
    800018be:	715d                	addi	sp,sp,-80
    800018c0:	e486                	sd	ra,72(sp)
    800018c2:	e0a2                	sd	s0,64(sp)
    800018c4:	fc26                	sd	s1,56(sp)
    800018c6:	f84a                	sd	s2,48(sp)
    800018c8:	f44e                	sd	s3,40(sp)
    800018ca:	f052                	sd	s4,32(sp)
    800018cc:	ec56                	sd	s5,24(sp)
    800018ce:	e85a                	sd	s6,16(sp)
    800018d0:	e45e                	sd	s7,8(sp)
    800018d2:	e062                	sd	s8,0(sp)
    800018d4:	0880                	addi	s0,sp,80
    800018d6:	8b2a                	mv	s6,a0
    800018d8:	8a2e                	mv	s4,a1
    800018da:	8c32                	mv	s8,a2
    800018dc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018de:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018e0:	6a85                	lui	s5,0x1
    800018e2:	a01d                	j	80001908 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018e4:	018505b3          	add	a1,a0,s8
    800018e8:	0004861b          	sext.w	a2,s1
    800018ec:	412585b3          	sub	a1,a1,s2
    800018f0:	8552                	mv	a0,s4
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	5c2080e7          	jalr	1474(ra) # 80000eb4 <memmove>

    len -= n;
    800018fa:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018fe:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001900:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001904:	02098263          	beqz	s3,80001928 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001908:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000190c:	85ca                	mv	a1,s2
    8000190e:	855a                	mv	a0,s6
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8d2080e7          	jalr	-1838(ra) # 800011e2 <walkaddr>
    if(pa0 == 0)
    80001918:	cd01                	beqz	a0,80001930 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000191a:	418904b3          	sub	s1,s2,s8
    8000191e:	94d6                	add	s1,s1,s5
    80001920:	fc99f2e3          	bgeu	s3,s1,800018e4 <copyin+0x28>
    80001924:	84ce                	mv	s1,s3
    80001926:	bf7d                	j	800018e4 <copyin+0x28>
  }
  return 0;
    80001928:	4501                	li	a0,0
    8000192a:	a021                	j	80001932 <copyin+0x76>
    8000192c:	4501                	li	a0,0
}
    8000192e:	8082                	ret
      return -1;
    80001930:	557d                	li	a0,-1
}
    80001932:	60a6                	ld	ra,72(sp)
    80001934:	6406                	ld	s0,64(sp)
    80001936:	74e2                	ld	s1,56(sp)
    80001938:	7942                	ld	s2,48(sp)
    8000193a:	79a2                	ld	s3,40(sp)
    8000193c:	7a02                	ld	s4,32(sp)
    8000193e:	6ae2                	ld	s5,24(sp)
    80001940:	6b42                	ld	s6,16(sp)
    80001942:	6ba2                	ld	s7,8(sp)
    80001944:	6c02                	ld	s8,0(sp)
    80001946:	6161                	addi	sp,sp,80
    80001948:	8082                	ret

000000008000194a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000194a:	c2dd                	beqz	a3,800019f0 <copyinstr+0xa6>
{
    8000194c:	715d                	addi	sp,sp,-80
    8000194e:	e486                	sd	ra,72(sp)
    80001950:	e0a2                	sd	s0,64(sp)
    80001952:	fc26                	sd	s1,56(sp)
    80001954:	f84a                	sd	s2,48(sp)
    80001956:	f44e                	sd	s3,40(sp)
    80001958:	f052                	sd	s4,32(sp)
    8000195a:	ec56                	sd	s5,24(sp)
    8000195c:	e85a                	sd	s6,16(sp)
    8000195e:	e45e                	sd	s7,8(sp)
    80001960:	0880                	addi	s0,sp,80
    80001962:	8a2a                	mv	s4,a0
    80001964:	8b2e                	mv	s6,a1
    80001966:	8bb2                	mv	s7,a2
    80001968:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000196a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000196c:	6985                	lui	s3,0x1
    8000196e:	a02d                	j	80001998 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001970:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001974:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001976:	37fd                	addiw	a5,a5,-1
    80001978:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000197c:	60a6                	ld	ra,72(sp)
    8000197e:	6406                	ld	s0,64(sp)
    80001980:	74e2                	ld	s1,56(sp)
    80001982:	7942                	ld	s2,48(sp)
    80001984:	79a2                	ld	s3,40(sp)
    80001986:	7a02                	ld	s4,32(sp)
    80001988:	6ae2                	ld	s5,24(sp)
    8000198a:	6b42                	ld	s6,16(sp)
    8000198c:	6ba2                	ld	s7,8(sp)
    8000198e:	6161                	addi	sp,sp,80
    80001990:	8082                	ret
    srcva = va0 + PGSIZE;
    80001992:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001996:	c8a9                	beqz	s1,800019e8 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001998:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000199c:	85ca                	mv	a1,s2
    8000199e:	8552                	mv	a0,s4
    800019a0:	00000097          	auipc	ra,0x0
    800019a4:	842080e7          	jalr	-1982(ra) # 800011e2 <walkaddr>
    if(pa0 == 0)
    800019a8:	c131                	beqz	a0,800019ec <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800019aa:	417906b3          	sub	a3,s2,s7
    800019ae:	96ce                	add	a3,a3,s3
    800019b0:	00d4f363          	bgeu	s1,a3,800019b6 <copyinstr+0x6c>
    800019b4:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019b6:	955e                	add	a0,a0,s7
    800019b8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019bc:	daf9                	beqz	a3,80001992 <copyinstr+0x48>
    800019be:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019c0:	41650633          	sub	a2,a0,s6
    800019c4:	fff48593          	addi	a1,s1,-1
    800019c8:	95da                	add	a1,a1,s6
    while(n > 0){
    800019ca:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800019cc:	00f60733          	add	a4,a2,a5
    800019d0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbceb8>
    800019d4:	df51                	beqz	a4,80001970 <copyinstr+0x26>
        *dst = *p;
    800019d6:	00e78023          	sb	a4,0(a5)
      --max;
    800019da:	40f584b3          	sub	s1,a1,a5
      dst++;
    800019de:	0785                	addi	a5,a5,1
    while(n > 0){
    800019e0:	fed796e3          	bne	a5,a3,800019cc <copyinstr+0x82>
      dst++;
    800019e4:	8b3e                	mv	s6,a5
    800019e6:	b775                	j	80001992 <copyinstr+0x48>
    800019e8:	4781                	li	a5,0
    800019ea:	b771                	j	80001976 <copyinstr+0x2c>
      return -1;
    800019ec:	557d                	li	a0,-1
    800019ee:	b779                	j	8000197c <copyinstr+0x32>
  int got_null = 0;
    800019f0:	4781                	li	a5,0
  if(got_null){
    800019f2:	37fd                	addiw	a5,a5,-1
    800019f4:	0007851b          	sext.w	a0,a5
}
    800019f8:	8082                	ret

00000000800019fa <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800019fa:	7139                	addi	sp,sp,-64
    800019fc:	fc06                	sd	ra,56(sp)
    800019fe:	f822                	sd	s0,48(sp)
    80001a00:	f426                	sd	s1,40(sp)
    80001a02:	f04a                	sd	s2,32(sp)
    80001a04:	ec4e                	sd	s3,24(sp)
    80001a06:	e852                	sd	s4,16(sp)
    80001a08:	e456                	sd	s5,8(sp)
    80001a0a:	e05a                	sd	s6,0(sp)
    80001a0c:	0080                	addi	s0,sp,64
    80001a0e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a10:	0002f497          	auipc	s1,0x2f
    80001a14:	55848493          	addi	s1,s1,1368 # 80030f68 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a18:	8b26                	mv	s6,s1
    80001a1a:	00006a97          	auipc	s5,0x6
    80001a1e:	5e6a8a93          	addi	s5,s5,1510 # 80008000 <etext>
    80001a22:	04000937          	lui	s2,0x4000
    80001a26:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a28:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a2a:	00035a17          	auipc	s4,0x35
    80001a2e:	33ea0a13          	addi	s4,s4,830 # 80036d68 <tickslock>
    char *pa = kalloc();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	15c080e7          	jalr	348(ra) # 80000b8e <kalloc>
    80001a3a:	862a                	mv	a2,a0
    if (pa == 0)
    80001a3c:	c131                	beqz	a0,80001a80 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a3e:	416485b3          	sub	a1,s1,s6
    80001a42:	858d                	srai	a1,a1,0x3
    80001a44:	000ab783          	ld	a5,0(s5)
    80001a48:	02f585b3          	mul	a1,a1,a5
    80001a4c:	2585                	addiw	a1,a1,1
    80001a4e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a52:	4719                	li	a4,6
    80001a54:	6685                	lui	a3,0x1
    80001a56:	40b905b3          	sub	a1,s2,a1
    80001a5a:	854e                	mv	a0,s3
    80001a5c:	00000097          	auipc	ra,0x0
    80001a60:	868080e7          	jalr	-1944(ra) # 800012c4 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a64:	17848493          	addi	s1,s1,376
    80001a68:	fd4495e3          	bne	s1,s4,80001a32 <proc_mapstacks+0x38>
  }
}
    80001a6c:	70e2                	ld	ra,56(sp)
    80001a6e:	7442                	ld	s0,48(sp)
    80001a70:	74a2                	ld	s1,40(sp)
    80001a72:	7902                	ld	s2,32(sp)
    80001a74:	69e2                	ld	s3,24(sp)
    80001a76:	6a42                	ld	s4,16(sp)
    80001a78:	6aa2                	ld	s5,8(sp)
    80001a7a:	6b02                	ld	s6,0(sp)
    80001a7c:	6121                	addi	sp,sp,64
    80001a7e:	8082                	ret
      panic("kalloc");
    80001a80:	00006517          	auipc	a0,0x6
    80001a84:	76850513          	addi	a0,a0,1896 # 800081e8 <digits+0x1a8>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	ab8080e7          	jalr	-1352(ra) # 80000540 <panic>

0000000080001a90 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a90:	7139                	addi	sp,sp,-64
    80001a92:	fc06                	sd	ra,56(sp)
    80001a94:	f822                	sd	s0,48(sp)
    80001a96:	f426                	sd	s1,40(sp)
    80001a98:	f04a                	sd	s2,32(sp)
    80001a9a:	ec4e                	sd	s3,24(sp)
    80001a9c:	e852                	sd	s4,16(sp)
    80001a9e:	e456                	sd	s5,8(sp)
    80001aa0:	e05a                	sd	s6,0(sp)
    80001aa2:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001aa4:	00006597          	auipc	a1,0x6
    80001aa8:	74c58593          	addi	a1,a1,1868 # 800081f0 <digits+0x1b0>
    80001aac:	0002f517          	auipc	a0,0x2f
    80001ab0:	08c50513          	addi	a0,a0,140 # 80030b38 <pid_lock>
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	218080e7          	jalr	536(ra) # 80000ccc <initlock>
  initlock(&wait_lock, "wait_lock");
    80001abc:	00006597          	auipc	a1,0x6
    80001ac0:	73c58593          	addi	a1,a1,1852 # 800081f8 <digits+0x1b8>
    80001ac4:	0002f517          	auipc	a0,0x2f
    80001ac8:	08c50513          	addi	a0,a0,140 # 80030b50 <wait_lock>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	200080e7          	jalr	512(ra) # 80000ccc <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ad4:	0002f497          	auipc	s1,0x2f
    80001ad8:	49448493          	addi	s1,s1,1172 # 80030f68 <proc>
  {
    initlock(&p->lock, "proc");
    80001adc:	00006b17          	auipc	s6,0x6
    80001ae0:	72cb0b13          	addi	s6,s6,1836 # 80008208 <digits+0x1c8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001ae4:	8aa6                	mv	s5,s1
    80001ae6:	00006a17          	auipc	s4,0x6
    80001aea:	51aa0a13          	addi	s4,s4,1306 # 80008000 <etext>
    80001aee:	04000937          	lui	s2,0x4000
    80001af2:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001af4:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	00035997          	auipc	s3,0x35
    80001afa:	27298993          	addi	s3,s3,626 # 80036d68 <tickslock>
    initlock(&p->lock, "proc");
    80001afe:	85da                	mv	a1,s6
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	1ca080e7          	jalr	458(ra) # 80000ccc <initlock>
    p->state = UNUSED;
    80001b0a:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b0e:	415487b3          	sub	a5,s1,s5
    80001b12:	878d                	srai	a5,a5,0x3
    80001b14:	000a3703          	ld	a4,0(s4)
    80001b18:	02e787b3          	mul	a5,a5,a4
    80001b1c:	2785                	addiw	a5,a5,1
    80001b1e:	00d7979b          	slliw	a5,a5,0xd
    80001b22:	40f907b3          	sub	a5,s2,a5
    80001b26:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b28:	17848493          	addi	s1,s1,376
    80001b2c:	fd3499e3          	bne	s1,s3,80001afe <procinit+0x6e>
  }
}
    80001b30:	70e2                	ld	ra,56(sp)
    80001b32:	7442                	ld	s0,48(sp)
    80001b34:	74a2                	ld	s1,40(sp)
    80001b36:	7902                	ld	s2,32(sp)
    80001b38:	69e2                	ld	s3,24(sp)
    80001b3a:	6a42                	ld	s4,16(sp)
    80001b3c:	6aa2                	ld	s5,8(sp)
    80001b3e:	6b02                	ld	s6,0(sp)
    80001b40:	6121                	addi	sp,sp,64
    80001b42:	8082                	ret

0000000080001b44 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b44:	1141                	addi	sp,sp,-16
    80001b46:	e422                	sd	s0,8(sp)
    80001b48:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b4a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b4c:	2501                	sext.w	a0,a0
    80001b4e:	6422                	ld	s0,8(sp)
    80001b50:	0141                	addi	sp,sp,16
    80001b52:	8082                	ret

0000000080001b54 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b54:	1141                	addi	sp,sp,-16
    80001b56:	e422                	sd	s0,8(sp)
    80001b58:	0800                	addi	s0,sp,16
    80001b5a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b5c:	2781                	sext.w	a5,a5
    80001b5e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b60:	0002f517          	auipc	a0,0x2f
    80001b64:	00850513          	addi	a0,a0,8 # 80030b68 <cpus>
    80001b68:	953e                	add	a0,a0,a5
    80001b6a:	6422                	ld	s0,8(sp)
    80001b6c:	0141                	addi	sp,sp,16
    80001b6e:	8082                	ret

0000000080001b70 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b70:	1101                	addi	sp,sp,-32
    80001b72:	ec06                	sd	ra,24(sp)
    80001b74:	e822                	sd	s0,16(sp)
    80001b76:	e426                	sd	s1,8(sp)
    80001b78:	1000                	addi	s0,sp,32
  push_off();
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	196080e7          	jalr	406(ra) # 80000d10 <push_off>
    80001b82:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b84:	2781                	sext.w	a5,a5
    80001b86:	079e                	slli	a5,a5,0x7
    80001b88:	0002f717          	auipc	a4,0x2f
    80001b8c:	fb070713          	addi	a4,a4,-80 # 80030b38 <pid_lock>
    80001b90:	97ba                	add	a5,a5,a4
    80001b92:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	21c080e7          	jalr	540(ra) # 80000db0 <pop_off>
  return p;
}
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	60e2                	ld	ra,24(sp)
    80001ba0:	6442                	ld	s0,16(sp)
    80001ba2:	64a2                	ld	s1,8(sp)
    80001ba4:	6105                	addi	sp,sp,32
    80001ba6:	8082                	ret

0000000080001ba8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ba8:	1141                	addi	sp,sp,-16
    80001baa:	e406                	sd	ra,8(sp)
    80001bac:	e022                	sd	s0,0(sp)
    80001bae:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	fc0080e7          	jalr	-64(ra) # 80001b70 <myproc>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	258080e7          	jalr	600(ra) # 80000e10 <release>

  if (first)
    80001bc0:	00007797          	auipc	a5,0x7
    80001bc4:	c507a783          	lw	a5,-944(a5) # 80008810 <first.1>
    80001bc8:	eb89                	bnez	a5,80001bda <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bca:	00001097          	auipc	ra,0x1
    80001bce:	e40080e7          	jalr	-448(ra) # 80002a0a <usertrapret>
}
    80001bd2:	60a2                	ld	ra,8(sp)
    80001bd4:	6402                	ld	s0,0(sp)
    80001bd6:	0141                	addi	sp,sp,16
    80001bd8:	8082                	ret
    first = 0;
    80001bda:	00007797          	auipc	a5,0x7
    80001bde:	c207ab23          	sw	zero,-970(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    80001be2:	4505                	li	a0,1
    80001be4:	00002097          	auipc	ra,0x2
    80001be8:	c9e080e7          	jalr	-866(ra) # 80003882 <fsinit>
    80001bec:	bff9                	j	80001bca <forkret+0x22>

0000000080001bee <allocpid>:
{
    80001bee:	1101                	addi	sp,sp,-32
    80001bf0:	ec06                	sd	ra,24(sp)
    80001bf2:	e822                	sd	s0,16(sp)
    80001bf4:	e426                	sd	s1,8(sp)
    80001bf6:	e04a                	sd	s2,0(sp)
    80001bf8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bfa:	0002f917          	auipc	s2,0x2f
    80001bfe:	f3e90913          	addi	s2,s2,-194 # 80030b38 <pid_lock>
    80001c02:	854a                	mv	a0,s2
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	158080e7          	jalr	344(ra) # 80000d5c <acquire>
  pid = nextpid;
    80001c0c:	00007797          	auipc	a5,0x7
    80001c10:	c0878793          	addi	a5,a5,-1016 # 80008814 <nextpid>
    80001c14:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c16:	0014871b          	addiw	a4,s1,1
    80001c1a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c1c:	854a                	mv	a0,s2
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	1f2080e7          	jalr	498(ra) # 80000e10 <release>
}
    80001c26:	8526                	mv	a0,s1
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6902                	ld	s2,0(sp)
    80001c30:	6105                	addi	sp,sp,32
    80001c32:	8082                	ret

0000000080001c34 <proc_pagetable>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	86c080e7          	jalr	-1940(ra) # 800014ae <uvmcreate>
    80001c4a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c4c:	c121                	beqz	a0,80001c8c <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c4e:	4729                	li	a4,10
    80001c50:	00005697          	auipc	a3,0x5
    80001c54:	3b068693          	addi	a3,a3,944 # 80007000 <_trampoline>
    80001c58:	6605                	lui	a2,0x1
    80001c5a:	040005b7          	lui	a1,0x4000
    80001c5e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c60:	05b2                	slli	a1,a1,0xc
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	5c2080e7          	jalr	1474(ra) # 80001224 <mappages>
    80001c6a:	02054863          	bltz	a0,80001c9a <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c6e:	4719                	li	a4,6
    80001c70:	05893683          	ld	a3,88(s2)
    80001c74:	6605                	lui	a2,0x1
    80001c76:	020005b7          	lui	a1,0x2000
    80001c7a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c7c:	05b6                	slli	a1,a1,0xd
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	5a4080e7          	jalr	1444(ra) # 80001224 <mappages>
    80001c88:	02054163          	bltz	a0,80001caa <proc_pagetable+0x76>
}
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	60e2                	ld	ra,24(sp)
    80001c90:	6442                	ld	s0,16(sp)
    80001c92:	64a2                	ld	s1,8(sp)
    80001c94:	6902                	ld	s2,0(sp)
    80001c96:	6105                	addi	sp,sp,32
    80001c98:	8082                	ret
    uvmfree(pagetable, 0);
    80001c9a:	4581                	li	a1,0
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	a16080e7          	jalr	-1514(ra) # 800016b4 <uvmfree>
    return 0;
    80001ca6:	4481                	li	s1,0
    80001ca8:	b7d5                	j	80001c8c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001caa:	4681                	li	a3,0
    80001cac:	4605                	li	a2,1
    80001cae:	040005b7          	lui	a1,0x4000
    80001cb2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cb4:	05b2                	slli	a1,a1,0xc
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	732080e7          	jalr	1842(ra) # 800013ea <uvmunmap>
    uvmfree(pagetable, 0);
    80001cc0:	4581                	li	a1,0
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	9f0080e7          	jalr	-1552(ra) # 800016b4 <uvmfree>
    return 0;
    80001ccc:	4481                	li	s1,0
    80001cce:	bf7d                	j	80001c8c <proc_pagetable+0x58>

0000000080001cd0 <proc_freepagetable>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	e04a                	sd	s2,0(sp)
    80001cda:	1000                	addi	s0,sp,32
    80001cdc:	84aa                	mv	s1,a0
    80001cde:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce0:	4681                	li	a3,0
    80001ce2:	4605                	li	a2,1
    80001ce4:	040005b7          	lui	a1,0x4000
    80001ce8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cea:	05b2                	slli	a1,a1,0xc
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	6fe080e7          	jalr	1790(ra) # 800013ea <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cf4:	4681                	li	a3,0
    80001cf6:	4605                	li	a2,1
    80001cf8:	020005b7          	lui	a1,0x2000
    80001cfc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cfe:	05b6                	slli	a1,a1,0xd
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	6e8080e7          	jalr	1768(ra) # 800013ea <uvmunmap>
  uvmfree(pagetable, sz);
    80001d0a:	85ca                	mv	a1,s2
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	9a6080e7          	jalr	-1626(ra) # 800016b4 <uvmfree>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6902                	ld	s2,0(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret

0000000080001d22 <freeproc>:
{
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d2e:	6d28                	ld	a0,88(a0)
    80001d30:	c509                	beqz	a0,80001d3a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	cb6080e7          	jalr	-842(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001d3a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d3e:	68a8                	ld	a0,80(s1)
    80001d40:	c511                	beqz	a0,80001d4c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d42:	64ac                	ld	a1,72(s1)
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	f8c080e7          	jalr	-116(ra) # 80001cd0 <proc_freepagetable>
  p->pagetable = 0;
    80001d4c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d50:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d54:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d58:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d5c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d60:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d64:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d68:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d6c:	0004ac23          	sw	zero,24(s1)
  printf("%d %d\n", p->test, p->pid);
    80001d70:	4601                	li	a2,0
    80001d72:	1744a583          	lw	a1,372(s1)
    80001d76:	00006517          	auipc	a0,0x6
    80001d7a:	49a50513          	addi	a0,a0,1178 # 80008210 <digits+0x1d0>
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	80c080e7          	jalr	-2036(ra) # 8000058a <printf>
}
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret

0000000080001d90 <allocproc>:
{
    80001d90:	1101                	addi	sp,sp,-32
    80001d92:	ec06                	sd	ra,24(sp)
    80001d94:	e822                	sd	s0,16(sp)
    80001d96:	e426                	sd	s1,8(sp)
    80001d98:	e04a                	sd	s2,0(sp)
    80001d9a:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d9c:	0002f497          	auipc	s1,0x2f
    80001da0:	1cc48493          	addi	s1,s1,460 # 80030f68 <proc>
    80001da4:	00035917          	auipc	s2,0x35
    80001da8:	fc490913          	addi	s2,s2,-60 # 80036d68 <tickslock>
    acquire(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	fae080e7          	jalr	-82(ra) # 80000d5c <acquire>
    if (p->state == UNUSED)
    80001db6:	4c9c                	lw	a5,24(s1)
    80001db8:	cf81                	beqz	a5,80001dd0 <allocproc+0x40>
      release(&p->lock);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	054080e7          	jalr	84(ra) # 80000e10 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dc4:	17848493          	addi	s1,s1,376
    80001dc8:	ff2492e3          	bne	s1,s2,80001dac <allocproc+0x1c>
  return 0;
    80001dcc:	4481                	li	s1,0
    80001dce:	a0ad                	j	80001e38 <allocproc+0xa8>
  p->pid = allocpid();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e1e080e7          	jalr	-482(ra) # 80001bee <allocpid>
    80001dd8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dda:	4785                	li	a5,1
    80001ddc:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	db0080e7          	jalr	-592(ra) # 80000b8e <kalloc>
    80001de6:	892a                	mv	s2,a0
    80001de8:	eca8                	sd	a0,88(s1)
    80001dea:	cd31                	beqz	a0,80001e46 <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80001dec:	8526                	mv	a0,s1
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e46080e7          	jalr	-442(ra) # 80001c34 <proc_pagetable>
    80001df6:	892a                	mv	s2,a0
    80001df8:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001dfa:	c135                	beqz	a0,80001e5e <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    80001dfc:	07000613          	li	a2,112
    80001e00:	4581                	li	a1,0
    80001e02:	06048513          	addi	a0,s1,96
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	052080e7          	jalr	82(ra) # 80000e58 <memset>
  p->context.ra = (uint64)forkret;
    80001e0e:	00000797          	auipc	a5,0x0
    80001e12:	d9a78793          	addi	a5,a5,-614 # 80001ba8 <forkret>
    80001e16:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e18:	60bc                	ld	a5,64(s1)
    80001e1a:	6705                	lui	a4,0x1
    80001e1c:	97ba                	add	a5,a5,a4
    80001e1e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e20:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e24:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e28:	00007797          	auipc	a5,0x7
    80001e2c:	a887a783          	lw	a5,-1400(a5) # 800088b0 <ticks>
    80001e30:	16f4a623          	sw	a5,364(s1)
  p->test = 0;
    80001e34:	1604aa23          	sw	zero,372(s1)
}
    80001e38:	8526                	mv	a0,s1
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
    freeproc(p);
    80001e46:	8526                	mv	a0,s1
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	eda080e7          	jalr	-294(ra) # 80001d22 <freeproc>
    release(&p->lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fbe080e7          	jalr	-66(ra) # 80000e10 <release>
    return 0;
    80001e5a:	84ca                	mv	s1,s2
    80001e5c:	bff1                	j	80001e38 <allocproc+0xa8>
    freeproc(p);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	ec2080e7          	jalr	-318(ra) # 80001d22 <freeproc>
    release(&p->lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	fa6080e7          	jalr	-90(ra) # 80000e10 <release>
    return 0;
    80001e72:	84ca                	mv	s1,s2
    80001e74:	b7d1                	j	80001e38 <allocproc+0xa8>

0000000080001e76 <userinit>:
{
    80001e76:	1101                	addi	sp,sp,-32
    80001e78:	ec06                	sd	ra,24(sp)
    80001e7a:	e822                	sd	s0,16(sp)
    80001e7c:	e426                	sd	s1,8(sp)
    80001e7e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	f10080e7          	jalr	-240(ra) # 80001d90 <allocproc>
    80001e88:	84aa                	mv	s1,a0
  initproc = p;
    80001e8a:	00007797          	auipc	a5,0x7
    80001e8e:	a0a7bf23          	sd	a0,-1506(a5) # 800088a8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e92:	03400613          	li	a2,52
    80001e96:	00007597          	auipc	a1,0x7
    80001e9a:	98a58593          	addi	a1,a1,-1654 # 80008820 <initcode>
    80001e9e:	6928                	ld	a0,80(a0)
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	63c080e7          	jalr	1596(ra) # 800014dc <uvmfirst>
  p->sz = PGSIZE;
    80001ea8:	6785                	lui	a5,0x1
    80001eaa:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001eac:	6cb8                	ld	a4,88(s1)
    80001eae:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001eb2:	6cb8                	ld	a4,88(s1)
    80001eb4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eb6:	4641                	li	a2,16
    80001eb8:	00006597          	auipc	a1,0x6
    80001ebc:	36058593          	addi	a1,a1,864 # 80008218 <digits+0x1d8>
    80001ec0:	15848513          	addi	a0,s1,344
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	0de080e7          	jalr	222(ra) # 80000fa2 <safestrcpy>
  p->cwd = namei("/");
    80001ecc:	00006517          	auipc	a0,0x6
    80001ed0:	35c50513          	addi	a0,a0,860 # 80008228 <digits+0x1e8>
    80001ed4:	00002097          	auipc	ra,0x2
    80001ed8:	3d8080e7          	jalr	984(ra) # 800042ac <namei>
    80001edc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ee0:	478d                	li	a5,3
    80001ee2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	f2a080e7          	jalr	-214(ra) # 80000e10 <release>
}
    80001eee:	60e2                	ld	ra,24(sp)
    80001ef0:	6442                	ld	s0,16(sp)
    80001ef2:	64a2                	ld	s1,8(sp)
    80001ef4:	6105                	addi	sp,sp,32
    80001ef6:	8082                	ret

0000000080001ef8 <growproc>:
{
    80001ef8:	1101                	addi	sp,sp,-32
    80001efa:	ec06                	sd	ra,24(sp)
    80001efc:	e822                	sd	s0,16(sp)
    80001efe:	e426                	sd	s1,8(sp)
    80001f00:	e04a                	sd	s2,0(sp)
    80001f02:	1000                	addi	s0,sp,32
    80001f04:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	c6a080e7          	jalr	-918(ra) # 80001b70 <myproc>
    80001f0e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f10:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f12:	01204c63          	bgtz	s2,80001f2a <growproc+0x32>
  else if (n < 0)
    80001f16:	02094663          	bltz	s2,80001f42 <growproc+0x4a>
  p->sz = sz;
    80001f1a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f1c:	4501                	li	a0,0
}
    80001f1e:	60e2                	ld	ra,24(sp)
    80001f20:	6442                	ld	s0,16(sp)
    80001f22:	64a2                	ld	s1,8(sp)
    80001f24:	6902                	ld	s2,0(sp)
    80001f26:	6105                	addi	sp,sp,32
    80001f28:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f2a:	4691                	li	a3,4
    80001f2c:	00b90633          	add	a2,s2,a1
    80001f30:	6928                	ld	a0,80(a0)
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	664080e7          	jalr	1636(ra) # 80001596 <uvmalloc>
    80001f3a:	85aa                	mv	a1,a0
    80001f3c:	fd79                	bnez	a0,80001f1a <growproc+0x22>
      return -1;
    80001f3e:	557d                	li	a0,-1
    80001f40:	bff9                	j	80001f1e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f42:	00b90633          	add	a2,s2,a1
    80001f46:	6928                	ld	a0,80(a0)
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	606080e7          	jalr	1542(ra) # 8000154e <uvmdealloc>
    80001f50:	85aa                	mv	a1,a0
    80001f52:	b7e1                	j	80001f1a <growproc+0x22>

0000000080001f54 <fork>:
{
    80001f54:	7139                	addi	sp,sp,-64
    80001f56:	fc06                	sd	ra,56(sp)
    80001f58:	f822                	sd	s0,48(sp)
    80001f5a:	f426                	sd	s1,40(sp)
    80001f5c:	f04a                	sd	s2,32(sp)
    80001f5e:	ec4e                	sd	s3,24(sp)
    80001f60:	e852                	sd	s4,16(sp)
    80001f62:	e456                	sd	s5,8(sp)
    80001f64:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	c0a080e7          	jalr	-1014(ra) # 80001b70 <myproc>
    80001f6e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	e20080e7          	jalr	-480(ra) # 80001d90 <allocproc>
    80001f78:	10050c63          	beqz	a0,80002090 <fork+0x13c>
    80001f7c:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f7e:	048ab603          	ld	a2,72(s5)
    80001f82:	692c                	ld	a1,80(a0)
    80001f84:	050ab503          	ld	a0,80(s5)
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	766080e7          	jalr	1894(ra) # 800016ee <uvmcopy>
    80001f90:	04054863          	bltz	a0,80001fe0 <fork+0x8c>
  np->sz = p->sz;
    80001f94:	048ab783          	ld	a5,72(s5)
    80001f98:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f9c:	058ab683          	ld	a3,88(s5)
    80001fa0:	87b6                	mv	a5,a3
    80001fa2:	058a3703          	ld	a4,88(s4)
    80001fa6:	12068693          	addi	a3,a3,288
    80001faa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fae:	6788                	ld	a0,8(a5)
    80001fb0:	6b8c                	ld	a1,16(a5)
    80001fb2:	6f90                	ld	a2,24(a5)
    80001fb4:	01073023          	sd	a6,0(a4)
    80001fb8:	e708                	sd	a0,8(a4)
    80001fba:	eb0c                	sd	a1,16(a4)
    80001fbc:	ef10                	sd	a2,24(a4)
    80001fbe:	02078793          	addi	a5,a5,32
    80001fc2:	02070713          	addi	a4,a4,32
    80001fc6:	fed792e3          	bne	a5,a3,80001faa <fork+0x56>
  np->trapframe->a0 = 0;
    80001fca:	058a3783          	ld	a5,88(s4)
    80001fce:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fd2:	0d0a8493          	addi	s1,s5,208
    80001fd6:	0d0a0913          	addi	s2,s4,208
    80001fda:	150a8993          	addi	s3,s5,336
    80001fde:	a00d                	j	80002000 <fork+0xac>
    freeproc(np);
    80001fe0:	8552                	mv	a0,s4
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	d40080e7          	jalr	-704(ra) # 80001d22 <freeproc>
    release(&np->lock);
    80001fea:	8552                	mv	a0,s4
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	e24080e7          	jalr	-476(ra) # 80000e10 <release>
    return -1;
    80001ff4:	597d                	li	s2,-1
    80001ff6:	a059                	j	8000207c <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001ff8:	04a1                	addi	s1,s1,8
    80001ffa:	0921                	addi	s2,s2,8
    80001ffc:	01348b63          	beq	s1,s3,80002012 <fork+0xbe>
    if (p->ofile[i])
    80002000:	6088                	ld	a0,0(s1)
    80002002:	d97d                	beqz	a0,80001ff8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002004:	00003097          	auipc	ra,0x3
    80002008:	93e080e7          	jalr	-1730(ra) # 80004942 <filedup>
    8000200c:	00a93023          	sd	a0,0(s2)
    80002010:	b7e5                	j	80001ff8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002012:	150ab503          	ld	a0,336(s5)
    80002016:	00002097          	auipc	ra,0x2
    8000201a:	aac080e7          	jalr	-1364(ra) # 80003ac2 <idup>
    8000201e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002022:	4641                	li	a2,16
    80002024:	158a8593          	addi	a1,s5,344
    80002028:	158a0513          	addi	a0,s4,344
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	f76080e7          	jalr	-138(ra) # 80000fa2 <safestrcpy>
  pid = np->pid;
    80002034:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002038:	8552                	mv	a0,s4
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	dd6080e7          	jalr	-554(ra) # 80000e10 <release>
  acquire(&wait_lock);
    80002042:	0002f497          	auipc	s1,0x2f
    80002046:	b0e48493          	addi	s1,s1,-1266 # 80030b50 <wait_lock>
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	d10080e7          	jalr	-752(ra) # 80000d5c <acquire>
  np->parent = p;
    80002054:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	db6080e7          	jalr	-586(ra) # 80000e10 <release>
  acquire(&np->lock);
    80002062:	8552                	mv	a0,s4
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	cf8080e7          	jalr	-776(ra) # 80000d5c <acquire>
  np->state = RUNNABLE;
    8000206c:	478d                	li	a5,3
    8000206e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002072:	8552                	mv	a0,s4
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	d9c080e7          	jalr	-612(ra) # 80000e10 <release>
}
    8000207c:	854a                	mv	a0,s2
    8000207e:	70e2                	ld	ra,56(sp)
    80002080:	7442                	ld	s0,48(sp)
    80002082:	74a2                	ld	s1,40(sp)
    80002084:	7902                	ld	s2,32(sp)
    80002086:	69e2                	ld	s3,24(sp)
    80002088:	6a42                	ld	s4,16(sp)
    8000208a:	6aa2                	ld	s5,8(sp)
    8000208c:	6121                	addi	sp,sp,64
    8000208e:	8082                	ret
    return -1;
    80002090:	597d                	li	s2,-1
    80002092:	b7ed                	j	8000207c <fork+0x128>

0000000080002094 <scheduler>:
{
    80002094:	7139                	addi	sp,sp,-64
    80002096:	fc06                	sd	ra,56(sp)
    80002098:	f822                	sd	s0,48(sp)
    8000209a:	f426                	sd	s1,40(sp)
    8000209c:	f04a                	sd	s2,32(sp)
    8000209e:	ec4e                	sd	s3,24(sp)
    800020a0:	e852                	sd	s4,16(sp)
    800020a2:	e456                	sd	s5,8(sp)
    800020a4:	e05a                	sd	s6,0(sp)
    800020a6:	0080                	addi	s0,sp,64
    800020a8:	8792                	mv	a5,tp
  int id = r_tp();
    800020aa:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020ac:	00779a93          	slli	s5,a5,0x7
    800020b0:	0002f717          	auipc	a4,0x2f
    800020b4:	a8870713          	addi	a4,a4,-1400 # 80030b38 <pid_lock>
    800020b8:	9756                	add	a4,a4,s5
    800020ba:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020be:	0002f717          	auipc	a4,0x2f
    800020c2:	ab270713          	addi	a4,a4,-1358 # 80030b70 <cpus+0x8>
    800020c6:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800020c8:	498d                	li	s3,3
        p->state = RUNNING;
    800020ca:	4b11                	li	s6,4
        c->proc = p;
    800020cc:	079e                	slli	a5,a5,0x7
    800020ce:	0002fa17          	auipc	s4,0x2f
    800020d2:	a6aa0a13          	addi	s4,s4,-1430 # 80030b38 <pid_lock>
    800020d6:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800020d8:	00035917          	auipc	s2,0x35
    800020dc:	c9090913          	addi	s2,s2,-880 # 80036d68 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e8:	10079073          	csrw	sstatus,a5
    800020ec:	0002f497          	auipc	s1,0x2f
    800020f0:	e7c48493          	addi	s1,s1,-388 # 80030f68 <proc>
    800020f4:	a811                	j	80002108 <scheduler+0x74>
      release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	d18080e7          	jalr	-744(ra) # 80000e10 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002100:	17848493          	addi	s1,s1,376
    80002104:	fd248ee3          	beq	s1,s2,800020e0 <scheduler+0x4c>
      acquire(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	c52080e7          	jalr	-942(ra) # 80000d5c <acquire>
      if (p->state == RUNNABLE)
    80002112:	4c9c                	lw	a5,24(s1)
    80002114:	ff3791e3          	bne	a5,s3,800020f6 <scheduler+0x62>
        p->state = RUNNING;
    80002118:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000211c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002120:	06048593          	addi	a1,s1,96
    80002124:	8556                	mv	a0,s5
    80002126:	00001097          	auipc	ra,0x1
    8000212a:	83a080e7          	jalr	-1990(ra) # 80002960 <swtch>
        c->proc = 0;
    8000212e:	020a3823          	sd	zero,48(s4)
    80002132:	b7d1                	j	800020f6 <scheduler+0x62>

0000000080002134 <sched>:
{
    80002134:	7179                	addi	sp,sp,-48
    80002136:	f406                	sd	ra,40(sp)
    80002138:	f022                	sd	s0,32(sp)
    8000213a:	ec26                	sd	s1,24(sp)
    8000213c:	e84a                	sd	s2,16(sp)
    8000213e:	e44e                	sd	s3,8(sp)
    80002140:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002142:	00000097          	auipc	ra,0x0
    80002146:	a2e080e7          	jalr	-1490(ra) # 80001b70 <myproc>
    8000214a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b96080e7          	jalr	-1130(ra) # 80000ce2 <holding>
    80002154:	c93d                	beqz	a0,800021ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002156:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002158:	2781                	sext.w	a5,a5
    8000215a:	079e                	slli	a5,a5,0x7
    8000215c:	0002f717          	auipc	a4,0x2f
    80002160:	9dc70713          	addi	a4,a4,-1572 # 80030b38 <pid_lock>
    80002164:	97ba                	add	a5,a5,a4
    80002166:	0a87a703          	lw	a4,168(a5)
    8000216a:	4785                	li	a5,1
    8000216c:	06f71763          	bne	a4,a5,800021da <sched+0xa6>
  if (p->state == RUNNING)
    80002170:	4c98                	lw	a4,24(s1)
    80002172:	4791                	li	a5,4
    80002174:	06f70b63          	beq	a4,a5,800021ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002178:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000217c:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000217e:	efb5                	bnez	a5,800021fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002180:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002182:	0002f917          	auipc	s2,0x2f
    80002186:	9b690913          	addi	s2,s2,-1610 # 80030b38 <pid_lock>
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	97ca                	add	a5,a5,s2
    80002190:	0ac7a983          	lw	s3,172(a5)
    80002194:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	0002f597          	auipc	a1,0x2f
    8000219e:	9d658593          	addi	a1,a1,-1578 # 80030b70 <cpus+0x8>
    800021a2:	95be                	add	a1,a1,a5
    800021a4:	06048513          	addi	a0,s1,96
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	7b8080e7          	jalr	1976(ra) # 80002960 <swtch>
    800021b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021b2:	2781                	sext.w	a5,a5
    800021b4:	079e                	slli	a5,a5,0x7
    800021b6:	993e                	add	s2,s2,a5
    800021b8:	0b392623          	sw	s3,172(s2)
}
    800021bc:	70a2                	ld	ra,40(sp)
    800021be:	7402                	ld	s0,32(sp)
    800021c0:	64e2                	ld	s1,24(sp)
    800021c2:	6942                	ld	s2,16(sp)
    800021c4:	69a2                	ld	s3,8(sp)
    800021c6:	6145                	addi	sp,sp,48
    800021c8:	8082                	ret
    panic("sched p->lock");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	06650513          	addi	a0,a0,102 # 80008230 <digits+0x1f0>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	36e080e7          	jalr	878(ra) # 80000540 <panic>
    panic("sched locks");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	06650513          	addi	a0,a0,102 # 80008240 <digits+0x200>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	35e080e7          	jalr	862(ra) # 80000540 <panic>
    panic("sched running");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	06650513          	addi	a0,a0,102 # 80008250 <digits+0x210>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	34e080e7          	jalr	846(ra) # 80000540 <panic>
    panic("sched interruptible");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	06650513          	addi	a0,a0,102 # 80008260 <digits+0x220>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	33e080e7          	jalr	830(ra) # 80000540 <panic>

000000008000220a <yield>:
{
    8000220a:	1101                	addi	sp,sp,-32
    8000220c:	ec06                	sd	ra,24(sp)
    8000220e:	e822                	sd	s0,16(sp)
    80002210:	e426                	sd	s1,8(sp)
    80002212:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002214:	00000097          	auipc	ra,0x0
    80002218:	95c080e7          	jalr	-1700(ra) # 80001b70 <myproc>
    8000221c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	b3e080e7          	jalr	-1218(ra) # 80000d5c <acquire>
  p->state = RUNNABLE;
    80002226:	478d                	li	a5,3
    80002228:	cc9c                	sw	a5,24(s1)
  sched();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f0a080e7          	jalr	-246(ra) # 80002134 <sched>
  release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	bdc080e7          	jalr	-1060(ra) # 80000e10 <release>
}
    8000223c:	60e2                	ld	ra,24(sp)
    8000223e:	6442                	ld	s0,16(sp)
    80002240:	64a2                	ld	s1,8(sp)
    80002242:	6105                	addi	sp,sp,32
    80002244:	8082                	ret

0000000080002246 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	1800                	addi	s0,sp,48
    80002254:	89aa                	mv	s3,a0
    80002256:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	918080e7          	jalr	-1768(ra) # 80001b70 <myproc>
    80002260:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	afa080e7          	jalr	-1286(ra) # 80000d5c <acquire>
  release(lk);
    8000226a:	854a                	mv	a0,s2
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	ba4080e7          	jalr	-1116(ra) # 80000e10 <release>

  // Go to sleep.
  p->chan = chan;
    80002274:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002278:	4789                	li	a5,2
    8000227a:	cc9c                	sw	a5,24(s1)

  sched();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	eb8080e7          	jalr	-328(ra) # 80002134 <sched>

  // Tidy up.
  p->chan = 0;
    80002284:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	b86080e7          	jalr	-1146(ra) # 80000e10 <release>
  acquire(lk);
    80002292:	854a                	mv	a0,s2
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	ac8080e7          	jalr	-1336(ra) # 80000d5c <acquire>
}
    8000229c:	70a2                	ld	ra,40(sp)
    8000229e:	7402                	ld	s0,32(sp)
    800022a0:	64e2                	ld	s1,24(sp)
    800022a2:	6942                	ld	s2,16(sp)
    800022a4:	69a2                	ld	s3,8(sp)
    800022a6:	6145                	addi	sp,sp,48
    800022a8:	8082                	ret

00000000800022aa <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800022aa:	7139                	addi	sp,sp,-64
    800022ac:	fc06                	sd	ra,56(sp)
    800022ae:	f822                	sd	s0,48(sp)
    800022b0:	f426                	sd	s1,40(sp)
    800022b2:	f04a                	sd	s2,32(sp)
    800022b4:	ec4e                	sd	s3,24(sp)
    800022b6:	e852                	sd	s4,16(sp)
    800022b8:	e456                	sd	s5,8(sp)
    800022ba:	0080                	addi	s0,sp,64
    800022bc:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022be:	0002f497          	auipc	s1,0x2f
    800022c2:	caa48493          	addi	s1,s1,-854 # 80030f68 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800022c6:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800022c8:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800022ca:	00035917          	auipc	s2,0x35
    800022ce:	a9e90913          	addi	s2,s2,-1378 # 80036d68 <tickslock>
    800022d2:	a811                	j	800022e6 <wakeup+0x3c>
      }
      release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	b3a080e7          	jalr	-1222(ra) # 80000e10 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022de:	17848493          	addi	s1,s1,376
    800022e2:	03248663          	beq	s1,s2,8000230e <wakeup+0x64>
    if (p != myproc())
    800022e6:	00000097          	auipc	ra,0x0
    800022ea:	88a080e7          	jalr	-1910(ra) # 80001b70 <myproc>
    800022ee:	fea488e3          	beq	s1,a0,800022de <wakeup+0x34>
      acquire(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	a68080e7          	jalr	-1432(ra) # 80000d5c <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022fc:	4c9c                	lw	a5,24(s1)
    800022fe:	fd379be3          	bne	a5,s3,800022d4 <wakeup+0x2a>
    80002302:	709c                	ld	a5,32(s1)
    80002304:	fd4798e3          	bne	a5,s4,800022d4 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002308:	0154ac23          	sw	s5,24(s1)
    8000230c:	b7e1                	j	800022d4 <wakeup+0x2a>
    }
  }
}
    8000230e:	70e2                	ld	ra,56(sp)
    80002310:	7442                	ld	s0,48(sp)
    80002312:	74a2                	ld	s1,40(sp)
    80002314:	7902                	ld	s2,32(sp)
    80002316:	69e2                	ld	s3,24(sp)
    80002318:	6a42                	ld	s4,16(sp)
    8000231a:	6aa2                	ld	s5,8(sp)
    8000231c:	6121                	addi	sp,sp,64
    8000231e:	8082                	ret

0000000080002320 <reparent>:
{
    80002320:	7179                	addi	sp,sp,-48
    80002322:	f406                	sd	ra,40(sp)
    80002324:	f022                	sd	s0,32(sp)
    80002326:	ec26                	sd	s1,24(sp)
    80002328:	e84a                	sd	s2,16(sp)
    8000232a:	e44e                	sd	s3,8(sp)
    8000232c:	e052                	sd	s4,0(sp)
    8000232e:	1800                	addi	s0,sp,48
    80002330:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002332:	0002f497          	auipc	s1,0x2f
    80002336:	c3648493          	addi	s1,s1,-970 # 80030f68 <proc>
      pp->parent = initproc;
    8000233a:	00006a17          	auipc	s4,0x6
    8000233e:	56ea0a13          	addi	s4,s4,1390 # 800088a8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002342:	00035997          	auipc	s3,0x35
    80002346:	a2698993          	addi	s3,s3,-1498 # 80036d68 <tickslock>
    8000234a:	a029                	j	80002354 <reparent+0x34>
    8000234c:	17848493          	addi	s1,s1,376
    80002350:	01348d63          	beq	s1,s3,8000236a <reparent+0x4a>
    if (pp->parent == p)
    80002354:	7c9c                	ld	a5,56(s1)
    80002356:	ff279be3          	bne	a5,s2,8000234c <reparent+0x2c>
      pp->parent = initproc;
    8000235a:	000a3503          	ld	a0,0(s4)
    8000235e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002360:	00000097          	auipc	ra,0x0
    80002364:	f4a080e7          	jalr	-182(ra) # 800022aa <wakeup>
    80002368:	b7d5                	j	8000234c <reparent+0x2c>
}
    8000236a:	70a2                	ld	ra,40(sp)
    8000236c:	7402                	ld	s0,32(sp)
    8000236e:	64e2                	ld	s1,24(sp)
    80002370:	6942                	ld	s2,16(sp)
    80002372:	69a2                	ld	s3,8(sp)
    80002374:	6a02                	ld	s4,0(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret

000000008000237a <exit>:
{
    8000237a:	7179                	addi	sp,sp,-48
    8000237c:	f406                	sd	ra,40(sp)
    8000237e:	f022                	sd	s0,32(sp)
    80002380:	ec26                	sd	s1,24(sp)
    80002382:	e84a                	sd	s2,16(sp)
    80002384:	e44e                	sd	s3,8(sp)
    80002386:	e052                	sd	s4,0(sp)
    80002388:	1800                	addi	s0,sp,48
    8000238a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	7e4080e7          	jalr	2020(ra) # 80001b70 <myproc>
    80002394:	89aa                	mv	s3,a0
  if (p == initproc)
    80002396:	00006797          	auipc	a5,0x6
    8000239a:	5127b783          	ld	a5,1298(a5) # 800088a8 <initproc>
    8000239e:	0d050493          	addi	s1,a0,208
    800023a2:	15050913          	addi	s2,a0,336
    800023a6:	02a79363          	bne	a5,a0,800023cc <exit+0x52>
    panic("init exiting");
    800023aa:	00006517          	auipc	a0,0x6
    800023ae:	ece50513          	addi	a0,a0,-306 # 80008278 <digits+0x238>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	18e080e7          	jalr	398(ra) # 80000540 <panic>
      fileclose(f);
    800023ba:	00002097          	auipc	ra,0x2
    800023be:	5da080e7          	jalr	1498(ra) # 80004994 <fileclose>
      p->ofile[fd] = 0;
    800023c2:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023c6:	04a1                	addi	s1,s1,8
    800023c8:	01248563          	beq	s1,s2,800023d2 <exit+0x58>
    if (p->ofile[fd])
    800023cc:	6088                	ld	a0,0(s1)
    800023ce:	f575                	bnez	a0,800023ba <exit+0x40>
    800023d0:	bfdd                	j	800023c6 <exit+0x4c>
  begin_op();
    800023d2:	00002097          	auipc	ra,0x2
    800023d6:	0fa080e7          	jalr	250(ra) # 800044cc <begin_op>
  iput(p->cwd);
    800023da:	1509b503          	ld	a0,336(s3)
    800023de:	00002097          	auipc	ra,0x2
    800023e2:	8dc080e7          	jalr	-1828(ra) # 80003cba <iput>
  end_op();
    800023e6:	00002097          	auipc	ra,0x2
    800023ea:	164080e7          	jalr	356(ra) # 8000454a <end_op>
  p->cwd = 0;
    800023ee:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023f2:	0002e497          	auipc	s1,0x2e
    800023f6:	75e48493          	addi	s1,s1,1886 # 80030b50 <wait_lock>
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	960080e7          	jalr	-1696(ra) # 80000d5c <acquire>
  reparent(p);
    80002404:	854e                	mv	a0,s3
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	f1a080e7          	jalr	-230(ra) # 80002320 <reparent>
  wakeup(p->parent);
    8000240e:	0389b503          	ld	a0,56(s3)
    80002412:	00000097          	auipc	ra,0x0
    80002416:	e98080e7          	jalr	-360(ra) # 800022aa <wakeup>
  acquire(&p->lock);
    8000241a:	854e                	mv	a0,s3
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	940080e7          	jalr	-1728(ra) # 80000d5c <acquire>
  p->xstate = status;
    80002424:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002428:	4795                	li	a5,5
    8000242a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000242e:	00006797          	auipc	a5,0x6
    80002432:	4827a783          	lw	a5,1154(a5) # 800088b0 <ticks>
    80002436:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	9d4080e7          	jalr	-1580(ra) # 80000e10 <release>
  sched();
    80002444:	00000097          	auipc	ra,0x0
    80002448:	cf0080e7          	jalr	-784(ra) # 80002134 <sched>
  panic("zombie exit");
    8000244c:	00006517          	auipc	a0,0x6
    80002450:	e3c50513          	addi	a0,a0,-452 # 80008288 <digits+0x248>
    80002454:	ffffe097          	auipc	ra,0xffffe
    80002458:	0ec080e7          	jalr	236(ra) # 80000540 <panic>

000000008000245c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	1800                	addi	s0,sp,48
    8000246a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000246c:	0002f497          	auipc	s1,0x2f
    80002470:	afc48493          	addi	s1,s1,-1284 # 80030f68 <proc>
    80002474:	00035997          	auipc	s3,0x35
    80002478:	8f498993          	addi	s3,s3,-1804 # 80036d68 <tickslock>
  {
    acquire(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	8de080e7          	jalr	-1826(ra) # 80000d5c <acquire>
    if (p->pid == pid)
    80002486:	589c                	lw	a5,48(s1)
    80002488:	01278d63          	beq	a5,s2,800024a2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	982080e7          	jalr	-1662(ra) # 80000e10 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002496:	17848493          	addi	s1,s1,376
    8000249a:	ff3491e3          	bne	s1,s3,8000247c <kill+0x20>
  }
  return -1;
    8000249e:	557d                	li	a0,-1
    800024a0:	a829                	j	800024ba <kill+0x5e>
      p->killed = 1;
    800024a2:	4785                	li	a5,1
    800024a4:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800024a6:	4c98                	lw	a4,24(s1)
    800024a8:	4789                	li	a5,2
    800024aa:	00f70f63          	beq	a4,a5,800024c8 <kill+0x6c>
      release(&p->lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	960080e7          	jalr	-1696(ra) # 80000e10 <release>
      return 0;
    800024b8:	4501                	li	a0,0
}
    800024ba:	70a2                	ld	ra,40(sp)
    800024bc:	7402                	ld	s0,32(sp)
    800024be:	64e2                	ld	s1,24(sp)
    800024c0:	6942                	ld	s2,16(sp)
    800024c2:	69a2                	ld	s3,8(sp)
    800024c4:	6145                	addi	sp,sp,48
    800024c6:	8082                	ret
        p->state = RUNNABLE;
    800024c8:	478d                	li	a5,3
    800024ca:	cc9c                	sw	a5,24(s1)
    800024cc:	b7cd                	j	800024ae <kill+0x52>

00000000800024ce <setkilled>:

void setkilled(struct proc *p)
{
    800024ce:	1101                	addi	sp,sp,-32
    800024d0:	ec06                	sd	ra,24(sp)
    800024d2:	e822                	sd	s0,16(sp)
    800024d4:	e426                	sd	s1,8(sp)
    800024d6:	1000                	addi	s0,sp,32
    800024d8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	882080e7          	jalr	-1918(ra) # 80000d5c <acquire>
  p->killed = 1;
    800024e2:	4785                	li	a5,1
    800024e4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	928080e7          	jalr	-1752(ra) # 80000e10 <release>
}
    800024f0:	60e2                	ld	ra,24(sp)
    800024f2:	6442                	ld	s0,16(sp)
    800024f4:	64a2                	ld	s1,8(sp)
    800024f6:	6105                	addi	sp,sp,32
    800024f8:	8082                	ret

00000000800024fa <killed>:

int killed(struct proc *p)
{
    800024fa:	1101                	addi	sp,sp,-32
    800024fc:	ec06                	sd	ra,24(sp)
    800024fe:	e822                	sd	s0,16(sp)
    80002500:	e426                	sd	s1,8(sp)
    80002502:	e04a                	sd	s2,0(sp)
    80002504:	1000                	addi	s0,sp,32
    80002506:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	854080e7          	jalr	-1964(ra) # 80000d5c <acquire>
  k = p->killed;
    80002510:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	8fa080e7          	jalr	-1798(ra) # 80000e10 <release>
  return k;
}
    8000251e:	854a                	mv	a0,s2
    80002520:	60e2                	ld	ra,24(sp)
    80002522:	6442                	ld	s0,16(sp)
    80002524:	64a2                	ld	s1,8(sp)
    80002526:	6902                	ld	s2,0(sp)
    80002528:	6105                	addi	sp,sp,32
    8000252a:	8082                	ret

000000008000252c <wait>:
{
    8000252c:	715d                	addi	sp,sp,-80
    8000252e:	e486                	sd	ra,72(sp)
    80002530:	e0a2                	sd	s0,64(sp)
    80002532:	fc26                	sd	s1,56(sp)
    80002534:	f84a                	sd	s2,48(sp)
    80002536:	f44e                	sd	s3,40(sp)
    80002538:	f052                	sd	s4,32(sp)
    8000253a:	ec56                	sd	s5,24(sp)
    8000253c:	e85a                	sd	s6,16(sp)
    8000253e:	e45e                	sd	s7,8(sp)
    80002540:	e062                	sd	s8,0(sp)
    80002542:	0880                	addi	s0,sp,80
    80002544:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	62a080e7          	jalr	1578(ra) # 80001b70 <myproc>
    8000254e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002550:	0002e517          	auipc	a0,0x2e
    80002554:	60050513          	addi	a0,a0,1536 # 80030b50 <wait_lock>
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	804080e7          	jalr	-2044(ra) # 80000d5c <acquire>
    havekids = 0;
    80002560:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002562:	4a15                	li	s4,5
        havekids = 1;
    80002564:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002566:	00035997          	auipc	s3,0x35
    8000256a:	80298993          	addi	s3,s3,-2046 # 80036d68 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000256e:	0002ec17          	auipc	s8,0x2e
    80002572:	5e2c0c13          	addi	s8,s8,1506 # 80030b50 <wait_lock>
    havekids = 0;
    80002576:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002578:	0002f497          	auipc	s1,0x2f
    8000257c:	9f048493          	addi	s1,s1,-1552 # 80030f68 <proc>
    80002580:	a0bd                	j	800025ee <wait+0xc2>
          pid = pp->pid;
    80002582:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002586:	000b0e63          	beqz	s6,800025a2 <wait+0x76>
    8000258a:	4691                	li	a3,4
    8000258c:	02c48613          	addi	a2,s1,44
    80002590:	85da                	mv	a1,s6
    80002592:	05093503          	ld	a0,80(s2)
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	262080e7          	jalr	610(ra) # 800017f8 <copyout>
    8000259e:	02054563          	bltz	a0,800025c8 <wait+0x9c>
          freeproc(pp);
    800025a2:	8526                	mv	a0,s1
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	77e080e7          	jalr	1918(ra) # 80001d22 <freeproc>
          release(&pp->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	fffff097          	auipc	ra,0xfffff
    800025b2:	862080e7          	jalr	-1950(ra) # 80000e10 <release>
          release(&wait_lock);
    800025b6:	0002e517          	auipc	a0,0x2e
    800025ba:	59a50513          	addi	a0,a0,1434 # 80030b50 <wait_lock>
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	852080e7          	jalr	-1966(ra) # 80000e10 <release>
          return pid;
    800025c6:	a0b5                	j	80002632 <wait+0x106>
            release(&pp->lock);
    800025c8:	8526                	mv	a0,s1
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	846080e7          	jalr	-1978(ra) # 80000e10 <release>
            release(&wait_lock);
    800025d2:	0002e517          	auipc	a0,0x2e
    800025d6:	57e50513          	addi	a0,a0,1406 # 80030b50 <wait_lock>
    800025da:	fffff097          	auipc	ra,0xfffff
    800025de:	836080e7          	jalr	-1994(ra) # 80000e10 <release>
            return -1;
    800025e2:	59fd                	li	s3,-1
    800025e4:	a0b9                	j	80002632 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e6:	17848493          	addi	s1,s1,376
    800025ea:	03348463          	beq	s1,s3,80002612 <wait+0xe6>
      if (pp->parent == p)
    800025ee:	7c9c                	ld	a5,56(s1)
    800025f0:	ff279be3          	bne	a5,s2,800025e6 <wait+0xba>
        acquire(&pp->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	766080e7          	jalr	1894(ra) # 80000d5c <acquire>
        if (pp->state == ZOMBIE)
    800025fe:	4c9c                	lw	a5,24(s1)
    80002600:	f94781e3          	beq	a5,s4,80002582 <wait+0x56>
        release(&pp->lock);
    80002604:	8526                	mv	a0,s1
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	80a080e7          	jalr	-2038(ra) # 80000e10 <release>
        havekids = 1;
    8000260e:	8756                	mv	a4,s5
    80002610:	bfd9                	j	800025e6 <wait+0xba>
    if (!havekids || killed(p))
    80002612:	c719                	beqz	a4,80002620 <wait+0xf4>
    80002614:	854a                	mv	a0,s2
    80002616:	00000097          	auipc	ra,0x0
    8000261a:	ee4080e7          	jalr	-284(ra) # 800024fa <killed>
    8000261e:	c51d                	beqz	a0,8000264c <wait+0x120>
      release(&wait_lock);
    80002620:	0002e517          	auipc	a0,0x2e
    80002624:	53050513          	addi	a0,a0,1328 # 80030b50 <wait_lock>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	7e8080e7          	jalr	2024(ra) # 80000e10 <release>
      return -1;
    80002630:	59fd                	li	s3,-1
}
    80002632:	854e                	mv	a0,s3
    80002634:	60a6                	ld	ra,72(sp)
    80002636:	6406                	ld	s0,64(sp)
    80002638:	74e2                	ld	s1,56(sp)
    8000263a:	7942                	ld	s2,48(sp)
    8000263c:	79a2                	ld	s3,40(sp)
    8000263e:	7a02                	ld	s4,32(sp)
    80002640:	6ae2                	ld	s5,24(sp)
    80002642:	6b42                	ld	s6,16(sp)
    80002644:	6ba2                	ld	s7,8(sp)
    80002646:	6c02                	ld	s8,0(sp)
    80002648:	6161                	addi	sp,sp,80
    8000264a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000264c:	85e2                	mv	a1,s8
    8000264e:	854a                	mv	a0,s2
    80002650:	00000097          	auipc	ra,0x0
    80002654:	bf6080e7          	jalr	-1034(ra) # 80002246 <sleep>
    havekids = 0;
    80002658:	bf39                	j	80002576 <wait+0x4a>

000000008000265a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000265a:	7179                	addi	sp,sp,-48
    8000265c:	f406                	sd	ra,40(sp)
    8000265e:	f022                	sd	s0,32(sp)
    80002660:	ec26                	sd	s1,24(sp)
    80002662:	e84a                	sd	s2,16(sp)
    80002664:	e44e                	sd	s3,8(sp)
    80002666:	e052                	sd	s4,0(sp)
    80002668:	1800                	addi	s0,sp,48
    8000266a:	84aa                	mv	s1,a0
    8000266c:	892e                	mv	s2,a1
    8000266e:	89b2                	mv	s3,a2
    80002670:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	4fe080e7          	jalr	1278(ra) # 80001b70 <myproc>
  if (user_dst)
    8000267a:	c08d                	beqz	s1,8000269c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000267c:	86d2                	mv	a3,s4
    8000267e:	864e                	mv	a2,s3
    80002680:	85ca                	mv	a1,s2
    80002682:	6928                	ld	a0,80(a0)
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	174080e7          	jalr	372(ra) # 800017f8 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000268c:	70a2                	ld	ra,40(sp)
    8000268e:	7402                	ld	s0,32(sp)
    80002690:	64e2                	ld	s1,24(sp)
    80002692:	6942                	ld	s2,16(sp)
    80002694:	69a2                	ld	s3,8(sp)
    80002696:	6a02                	ld	s4,0(sp)
    80002698:	6145                	addi	sp,sp,48
    8000269a:	8082                	ret
    memmove((char *)dst, src, len);
    8000269c:	000a061b          	sext.w	a2,s4
    800026a0:	85ce                	mv	a1,s3
    800026a2:	854a                	mv	a0,s2
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	810080e7          	jalr	-2032(ra) # 80000eb4 <memmove>
    return 0;
    800026ac:	8526                	mv	a0,s1
    800026ae:	bff9                	j	8000268c <either_copyout+0x32>

00000000800026b0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026b0:	7179                	addi	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	e052                	sd	s4,0(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	892a                	mv	s2,a0
    800026c2:	84ae                	mv	s1,a1
    800026c4:	89b2                	mv	s3,a2
    800026c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	4a8080e7          	jalr	1192(ra) # 80001b70 <myproc>
  if (user_src)
    800026d0:	c08d                	beqz	s1,800026f2 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026d2:	86d2                	mv	a3,s4
    800026d4:	864e                	mv	a2,s3
    800026d6:	85ca                	mv	a1,s2
    800026d8:	6928                	ld	a0,80(a0)
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	1e2080e7          	jalr	482(ra) # 800018bc <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026e2:	70a2                	ld	ra,40(sp)
    800026e4:	7402                	ld	s0,32(sp)
    800026e6:	64e2                	ld	s1,24(sp)
    800026e8:	6942                	ld	s2,16(sp)
    800026ea:	69a2                	ld	s3,8(sp)
    800026ec:	6a02                	ld	s4,0(sp)
    800026ee:	6145                	addi	sp,sp,48
    800026f0:	8082                	ret
    memmove(dst, (char *)src, len);
    800026f2:	000a061b          	sext.w	a2,s4
    800026f6:	85ce                	mv	a1,s3
    800026f8:	854a                	mv	a0,s2
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	7ba080e7          	jalr	1978(ra) # 80000eb4 <memmove>
    return 0;
    80002702:	8526                	mv	a0,s1
    80002704:	bff9                	j	800026e2 <either_copyin+0x32>

0000000080002706 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002706:	715d                	addi	sp,sp,-80
    80002708:	e486                	sd	ra,72(sp)
    8000270a:	e0a2                	sd	s0,64(sp)
    8000270c:	fc26                	sd	s1,56(sp)
    8000270e:	f84a                	sd	s2,48(sp)
    80002710:	f44e                	sd	s3,40(sp)
    80002712:	f052                	sd	s4,32(sp)
    80002714:	ec56                	sd	s5,24(sp)
    80002716:	e85a                	sd	s6,16(sp)
    80002718:	e45e                	sd	s7,8(sp)
    8000271a:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000271c:	00006517          	auipc	a0,0x6
    80002720:	9bc50513          	addi	a0,a0,-1604 # 800080d8 <digits+0x98>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	e66080e7          	jalr	-410(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000272c:	0002f497          	auipc	s1,0x2f
    80002730:	99448493          	addi	s1,s1,-1644 # 800310c0 <proc+0x158>
    80002734:	00034917          	auipc	s2,0x34
    80002738:	78c90913          	addi	s2,s2,1932 # 80036ec0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000273c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000273e:	00006997          	auipc	s3,0x6
    80002742:	b5a98993          	addi	s3,s3,-1190 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002746:	00006a97          	auipc	s5,0x6
    8000274a:	b5aa8a93          	addi	s5,s5,-1190 # 800082a0 <digits+0x260>
    printf("\n");
    8000274e:	00006a17          	auipc	s4,0x6
    80002752:	98aa0a13          	addi	s4,s4,-1654 # 800080d8 <digits+0x98>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002756:	00006b97          	auipc	s7,0x6
    8000275a:	b8ab8b93          	addi	s7,s7,-1142 # 800082e0 <states.0>
    8000275e:	a00d                	j	80002780 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002760:	ed86a583          	lw	a1,-296(a3)
    80002764:	8556                	mv	a0,s5
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	e24080e7          	jalr	-476(ra) # 8000058a <printf>
    printf("\n");
    8000276e:	8552                	mv	a0,s4
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	e1a080e7          	jalr	-486(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002778:	17848493          	addi	s1,s1,376
    8000277c:	03248263          	beq	s1,s2,800027a0 <procdump+0x9a>
    if (p->state == UNUSED)
    80002780:	86a6                	mv	a3,s1
    80002782:	ec04a783          	lw	a5,-320(s1)
    80002786:	dbed                	beqz	a5,80002778 <procdump+0x72>
      state = "???";
    80002788:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278a:	fcfb6be3          	bltu	s6,a5,80002760 <procdump+0x5a>
    8000278e:	02079713          	slli	a4,a5,0x20
    80002792:	01d75793          	srli	a5,a4,0x1d
    80002796:	97de                	add	a5,a5,s7
    80002798:	6390                	ld	a2,0(a5)
    8000279a:	f279                	bnez	a2,80002760 <procdump+0x5a>
      state = "???";
    8000279c:	864e                	mv	a2,s3
    8000279e:	b7c9                	j	80002760 <procdump+0x5a>
  }
}
    800027a0:	60a6                	ld	ra,72(sp)
    800027a2:	6406                	ld	s0,64(sp)
    800027a4:	74e2                	ld	s1,56(sp)
    800027a6:	7942                	ld	s2,48(sp)
    800027a8:	79a2                	ld	s3,40(sp)
    800027aa:	7a02                	ld	s4,32(sp)
    800027ac:	6ae2                	ld	s5,24(sp)
    800027ae:	6b42                	ld	s6,16(sp)
    800027b0:	6ba2                	ld	s7,8(sp)
    800027b2:	6161                	addi	sp,sp,80
    800027b4:	8082                	ret

00000000800027b6 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800027b6:	711d                	addi	sp,sp,-96
    800027b8:	ec86                	sd	ra,88(sp)
    800027ba:	e8a2                	sd	s0,80(sp)
    800027bc:	e4a6                	sd	s1,72(sp)
    800027be:	e0ca                	sd	s2,64(sp)
    800027c0:	fc4e                	sd	s3,56(sp)
    800027c2:	f852                	sd	s4,48(sp)
    800027c4:	f456                	sd	s5,40(sp)
    800027c6:	f05a                	sd	s6,32(sp)
    800027c8:	ec5e                	sd	s7,24(sp)
    800027ca:	e862                	sd	s8,16(sp)
    800027cc:	e466                	sd	s9,8(sp)
    800027ce:	e06a                	sd	s10,0(sp)
    800027d0:	1080                	addi	s0,sp,96
    800027d2:	8b2a                	mv	s6,a0
    800027d4:	8bae                	mv	s7,a1
    800027d6:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	398080e7          	jalr	920(ra) # 80001b70 <myproc>
    800027e0:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800027e2:	0002e517          	auipc	a0,0x2e
    800027e6:	36e50513          	addi	a0,a0,878 # 80030b50 <wait_lock>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	572080e7          	jalr	1394(ra) # 80000d5c <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800027f2:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800027f4:	4a15                	li	s4,5
        havekids = 1;
    800027f6:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800027f8:	00034997          	auipc	s3,0x34
    800027fc:	57098993          	addi	s3,s3,1392 # 80036d68 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002800:	0002ed17          	auipc	s10,0x2e
    80002804:	350d0d13          	addi	s10,s10,848 # 80030b50 <wait_lock>
    havekids = 0;
    80002808:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000280a:	0002e497          	auipc	s1,0x2e
    8000280e:	75e48493          	addi	s1,s1,1886 # 80030f68 <proc>
    80002812:	a059                	j	80002898 <waitx+0xe2>
          pid = np->pid;
    80002814:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002818:	1684a783          	lw	a5,360(s1)
    8000281c:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002820:	16c4a703          	lw	a4,364(s1)
    80002824:	9f3d                	addw	a4,a4,a5
    80002826:	1704a783          	lw	a5,368(s1)
    8000282a:	9f99                	subw	a5,a5,a4
    8000282c:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002830:	000b0e63          	beqz	s6,8000284c <waitx+0x96>
    80002834:	4691                	li	a3,4
    80002836:	02c48613          	addi	a2,s1,44
    8000283a:	85da                	mv	a1,s6
    8000283c:	05093503          	ld	a0,80(s2)
    80002840:	fffff097          	auipc	ra,0xfffff
    80002844:	fb8080e7          	jalr	-72(ra) # 800017f8 <copyout>
    80002848:	02054563          	bltz	a0,80002872 <waitx+0xbc>
          freeproc(np);
    8000284c:	8526                	mv	a0,s1
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	4d4080e7          	jalr	1236(ra) # 80001d22 <freeproc>
          release(&np->lock);
    80002856:	8526                	mv	a0,s1
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	5b8080e7          	jalr	1464(ra) # 80000e10 <release>
          release(&wait_lock);
    80002860:	0002e517          	auipc	a0,0x2e
    80002864:	2f050513          	addi	a0,a0,752 # 80030b50 <wait_lock>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	5a8080e7          	jalr	1448(ra) # 80000e10 <release>
          return pid;
    80002870:	a09d                	j	800028d6 <waitx+0x120>
            release(&np->lock);
    80002872:	8526                	mv	a0,s1
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	59c080e7          	jalr	1436(ra) # 80000e10 <release>
            release(&wait_lock);
    8000287c:	0002e517          	auipc	a0,0x2e
    80002880:	2d450513          	addi	a0,a0,724 # 80030b50 <wait_lock>
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	58c080e7          	jalr	1420(ra) # 80000e10 <release>
            return -1;
    8000288c:	59fd                	li	s3,-1
    8000288e:	a0a1                	j	800028d6 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002890:	17848493          	addi	s1,s1,376
    80002894:	03348463          	beq	s1,s3,800028bc <waitx+0x106>
      if (np->parent == p)
    80002898:	7c9c                	ld	a5,56(s1)
    8000289a:	ff279be3          	bne	a5,s2,80002890 <waitx+0xda>
        acquire(&np->lock);
    8000289e:	8526                	mv	a0,s1
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	4bc080e7          	jalr	1212(ra) # 80000d5c <acquire>
        if (np->state == ZOMBIE)
    800028a8:	4c9c                	lw	a5,24(s1)
    800028aa:	f74785e3          	beq	a5,s4,80002814 <waitx+0x5e>
        release(&np->lock);
    800028ae:	8526                	mv	a0,s1
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	560080e7          	jalr	1376(ra) # 80000e10 <release>
        havekids = 1;
    800028b8:	8756                	mv	a4,s5
    800028ba:	bfd9                	j	80002890 <waitx+0xda>
    if (!havekids || p->killed)
    800028bc:	c701                	beqz	a4,800028c4 <waitx+0x10e>
    800028be:	02892783          	lw	a5,40(s2)
    800028c2:	cb8d                	beqz	a5,800028f4 <waitx+0x13e>
      release(&wait_lock);
    800028c4:	0002e517          	auipc	a0,0x2e
    800028c8:	28c50513          	addi	a0,a0,652 # 80030b50 <wait_lock>
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	544080e7          	jalr	1348(ra) # 80000e10 <release>
      return -1;
    800028d4:	59fd                	li	s3,-1
  }
}
    800028d6:	854e                	mv	a0,s3
    800028d8:	60e6                	ld	ra,88(sp)
    800028da:	6446                	ld	s0,80(sp)
    800028dc:	64a6                	ld	s1,72(sp)
    800028de:	6906                	ld	s2,64(sp)
    800028e0:	79e2                	ld	s3,56(sp)
    800028e2:	7a42                	ld	s4,48(sp)
    800028e4:	7aa2                	ld	s5,40(sp)
    800028e6:	7b02                	ld	s6,32(sp)
    800028e8:	6be2                	ld	s7,24(sp)
    800028ea:	6c42                	ld	s8,16(sp)
    800028ec:	6ca2                	ld	s9,8(sp)
    800028ee:	6d02                	ld	s10,0(sp)
    800028f0:	6125                	addi	sp,sp,96
    800028f2:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028f4:	85ea                	mv	a1,s10
    800028f6:	854a                	mv	a0,s2
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	94e080e7          	jalr	-1714(ra) # 80002246 <sleep>
    havekids = 0;
    80002900:	b721                	j	80002808 <waitx+0x52>

0000000080002902 <update_time>:

void update_time()
{
    80002902:	7179                	addi	sp,sp,-48
    80002904:	f406                	sd	ra,40(sp)
    80002906:	f022                	sd	s0,32(sp)
    80002908:	ec26                	sd	s1,24(sp)
    8000290a:	e84a                	sd	s2,16(sp)
    8000290c:	e44e                	sd	s3,8(sp)
    8000290e:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002910:	0002e497          	auipc	s1,0x2e
    80002914:	65848493          	addi	s1,s1,1624 # 80030f68 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002918:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000291a:	00034917          	auipc	s2,0x34
    8000291e:	44e90913          	addi	s2,s2,1102 # 80036d68 <tickslock>
    80002922:	a811                	j	80002936 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	4ea080e7          	jalr	1258(ra) # 80000e10 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000292e:	17848493          	addi	s1,s1,376
    80002932:	03248063          	beq	s1,s2,80002952 <update_time+0x50>
    acquire(&p->lock);
    80002936:	8526                	mv	a0,s1
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	424080e7          	jalr	1060(ra) # 80000d5c <acquire>
    if (p->state == RUNNING)
    80002940:	4c9c                	lw	a5,24(s1)
    80002942:	ff3791e3          	bne	a5,s3,80002924 <update_time+0x22>
      p->rtime++;
    80002946:	1684a783          	lw	a5,360(s1)
    8000294a:	2785                	addiw	a5,a5,1
    8000294c:	16f4a423          	sw	a5,360(s1)
    80002950:	bfd1                	j	80002924 <update_time+0x22>
  }
    80002952:	70a2                	ld	ra,40(sp)
    80002954:	7402                	ld	s0,32(sp)
    80002956:	64e2                	ld	s1,24(sp)
    80002958:	6942                	ld	s2,16(sp)
    8000295a:	69a2                	ld	s3,8(sp)
    8000295c:	6145                	addi	sp,sp,48
    8000295e:	8082                	ret

0000000080002960 <swtch>:
    80002960:	00153023          	sd	ra,0(a0)
    80002964:	00253423          	sd	sp,8(a0)
    80002968:	e900                	sd	s0,16(a0)
    8000296a:	ed04                	sd	s1,24(a0)
    8000296c:	03253023          	sd	s2,32(a0)
    80002970:	03353423          	sd	s3,40(a0)
    80002974:	03453823          	sd	s4,48(a0)
    80002978:	03553c23          	sd	s5,56(a0)
    8000297c:	05653023          	sd	s6,64(a0)
    80002980:	05753423          	sd	s7,72(a0)
    80002984:	05853823          	sd	s8,80(a0)
    80002988:	05953c23          	sd	s9,88(a0)
    8000298c:	07a53023          	sd	s10,96(a0)
    80002990:	07b53423          	sd	s11,104(a0)
    80002994:	0005b083          	ld	ra,0(a1)
    80002998:	0085b103          	ld	sp,8(a1)
    8000299c:	6980                	ld	s0,16(a1)
    8000299e:	6d84                	ld	s1,24(a1)
    800029a0:	0205b903          	ld	s2,32(a1)
    800029a4:	0285b983          	ld	s3,40(a1)
    800029a8:	0305ba03          	ld	s4,48(a1)
    800029ac:	0385ba83          	ld	s5,56(a1)
    800029b0:	0405bb03          	ld	s6,64(a1)
    800029b4:	0485bb83          	ld	s7,72(a1)
    800029b8:	0505bc03          	ld	s8,80(a1)
    800029bc:	0585bc83          	ld	s9,88(a1)
    800029c0:	0605bd03          	ld	s10,96(a1)
    800029c4:	0685bd83          	ld	s11,104(a1)
    800029c8:	8082                	ret

00000000800029ca <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800029ca:	1141                	addi	sp,sp,-16
    800029cc:	e406                	sd	ra,8(sp)
    800029ce:	e022                	sd	s0,0(sp)
    800029d0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029d2:	00006597          	auipc	a1,0x6
    800029d6:	93e58593          	addi	a1,a1,-1730 # 80008310 <states.0+0x30>
    800029da:	00034517          	auipc	a0,0x34
    800029de:	38e50513          	addi	a0,a0,910 # 80036d68 <tickslock>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	2ea080e7          	jalr	746(ra) # 80000ccc <initlock>
}
    800029ea:	60a2                	ld	ra,8(sp)
    800029ec:	6402                	ld	s0,0(sp)
    800029ee:	0141                	addi	sp,sp,16
    800029f0:	8082                	ret

00000000800029f2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029f2:	1141                	addi	sp,sp,-16
    800029f4:	e422                	sd	s0,8(sp)
    800029f6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f8:	00003797          	auipc	a5,0x3
    800029fc:	5e878793          	addi	a5,a5,1512 # 80005fe0 <kernelvec>
    80002a00:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a04:	6422                	ld	s0,8(sp)
    80002a06:	0141                	addi	sp,sp,16
    80002a08:	8082                	ret

0000000080002a0a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a0a:	1141                	addi	sp,sp,-16
    80002a0c:	e406                	sd	ra,8(sp)
    80002a0e:	e022                	sd	s0,0(sp)
    80002a10:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	15e080e7          	jalr	350(ra) # 80001b70 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a20:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a24:	00004697          	auipc	a3,0x4
    80002a28:	5dc68693          	addi	a3,a3,1500 # 80007000 <_trampoline>
    80002a2c:	00004717          	auipc	a4,0x4
    80002a30:	5d470713          	addi	a4,a4,1492 # 80007000 <_trampoline>
    80002a34:	8f15                	sub	a4,a4,a3
    80002a36:	040007b7          	lui	a5,0x4000
    80002a3a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a3c:	07b2                	slli	a5,a5,0xc
    80002a3e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a40:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a44:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a46:	18002673          	csrr	a2,satp
    80002a4a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a4c:	6d30                	ld	a2,88(a0)
    80002a4e:	6138                	ld	a4,64(a0)
    80002a50:	6585                	lui	a1,0x1
    80002a52:	972e                	add	a4,a4,a1
    80002a54:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a56:	6d38                	ld	a4,88(a0)
    80002a58:	00000617          	auipc	a2,0x0
    80002a5c:	2ac60613          	addi	a2,a2,684 # 80002d04 <usertrap>
    80002a60:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a62:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a64:	8612                	mv	a2,tp
    80002a66:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a68:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a6c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a70:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a74:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a78:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a7a:	6f18                	ld	a4,24(a4)
    80002a7c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a80:	6928                	ld	a0,80(a0)
    80002a82:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a84:	00004717          	auipc	a4,0x4
    80002a88:	61870713          	addi	a4,a4,1560 # 8000709c <userret>
    80002a8c:	8f15                	sub	a4,a4,a3
    80002a8e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a90:	577d                	li	a4,-1
    80002a92:	177e                	slli	a4,a4,0x3f
    80002a94:	8d59                	or	a0,a0,a4
    80002a96:	9782                	jalr	a5
}
    80002a98:	60a2                	ld	ra,8(sp)
    80002a9a:	6402                	ld	s0,0(sp)
    80002a9c:	0141                	addi	sp,sp,16
    80002a9e:	8082                	ret

0000000080002aa0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	e04a                	sd	s2,0(sp)
    80002aaa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002aac:	00034917          	auipc	s2,0x34
    80002ab0:	2bc90913          	addi	s2,s2,700 # 80036d68 <tickslock>
    80002ab4:	854a                	mv	a0,s2
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	2a6080e7          	jalr	678(ra) # 80000d5c <acquire>
  ticks++;
    80002abe:	00006497          	auipc	s1,0x6
    80002ac2:	df248493          	addi	s1,s1,-526 # 800088b0 <ticks>
    80002ac6:	409c                	lw	a5,0(s1)
    80002ac8:	2785                	addiw	a5,a5,1
    80002aca:	c09c                	sw	a5,0(s1)
  update_time();
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	e36080e7          	jalr	-458(ra) # 80002902 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002ad4:	8526                	mv	a0,s1
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	7d4080e7          	jalr	2004(ra) # 800022aa <wakeup>
  release(&tickslock);
    80002ade:	854a                	mv	a0,s2
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	330080e7          	jalr	816(ra) # 80000e10 <release>
}
    80002ae8:	60e2                	ld	ra,24(sp)
    80002aea:	6442                	ld	s0,16(sp)
    80002aec:	64a2                	ld	s1,8(sp)
    80002aee:	6902                	ld	s2,0(sp)
    80002af0:	6105                	addi	sp,sp,32
    80002af2:	8082                	ret

0000000080002af4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002af4:	1101                	addi	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	e426                	sd	s1,8(sp)
    80002afc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b02:	00074d63          	bltz	a4,80002b1c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b06:	57fd                	li	a5,-1
    80002b08:	17fe                	slli	a5,a5,0x3f
    80002b0a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002b0c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b0e:	06f70363          	beq	a4,a5,80002b74 <devintr+0x80>
  }
}
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
      (scause & 0xff) == 9)
    80002b1c:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002b20:	46a5                	li	a3,9
    80002b22:	fed792e3          	bne	a5,a3,80002b06 <devintr+0x12>
    int irq = plic_claim();
    80002b26:	00003097          	auipc	ra,0x3
    80002b2a:	5c2080e7          	jalr	1474(ra) # 800060e8 <plic_claim>
    80002b2e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002b30:	47a9                	li	a5,10
    80002b32:	02f50763          	beq	a0,a5,80002b60 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002b36:	4785                	li	a5,1
    80002b38:	02f50963          	beq	a0,a5,80002b6a <devintr+0x76>
    return 1;
    80002b3c:	4505                	li	a0,1
    else if (irq)
    80002b3e:	d8f1                	beqz	s1,80002b12 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b40:	85a6                	mv	a1,s1
    80002b42:	00005517          	auipc	a0,0x5
    80002b46:	7d650513          	addi	a0,a0,2006 # 80008318 <states.0+0x38>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	a40080e7          	jalr	-1472(ra) # 8000058a <printf>
      plic_complete(irq);
    80002b52:	8526                	mv	a0,s1
    80002b54:	00003097          	auipc	ra,0x3
    80002b58:	5b8080e7          	jalr	1464(ra) # 8000610c <plic_complete>
    return 1;
    80002b5c:	4505                	li	a0,1
    80002b5e:	bf55                	j	80002b12 <devintr+0x1e>
      uartintr();
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	e38080e7          	jalr	-456(ra) # 80000998 <uartintr>
    80002b68:	b7ed                	j	80002b52 <devintr+0x5e>
      virtio_disk_intr();
    80002b6a:	00004097          	auipc	ra,0x4
    80002b6e:	a6a080e7          	jalr	-1430(ra) # 800065d4 <virtio_disk_intr>
    80002b72:	b7c5                	j	80002b52 <devintr+0x5e>
    if (cpuid() == 0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	fd0080e7          	jalr	-48(ra) # 80001b44 <cpuid>
    80002b7c:	c901                	beqz	a0,80002b8c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b7e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b82:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b84:	14479073          	csrw	sip,a5
    return 2;
    80002b88:	4509                	li	a0,2
    80002b8a:	b761                	j	80002b12 <devintr+0x1e>
      clockintr();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	f14080e7          	jalr	-236(ra) # 80002aa0 <clockintr>
    80002b94:	b7ed                	j	80002b7e <devintr+0x8a>

0000000080002b96 <kerneltrap>:
{
    80002b96:	7179                	addi	sp,sp,-48
    80002b98:	f406                	sd	ra,40(sp)
    80002b9a:	f022                	sd	s0,32(sp)
    80002b9c:	ec26                	sd	s1,24(sp)
    80002b9e:	e84a                	sd	s2,16(sp)
    80002ba0:	e44e                	sd	s3,8(sp)
    80002ba2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bac:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002bb0:	1004f793          	andi	a5,s1,256
    80002bb4:	cb85                	beqz	a5,80002be4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bba:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002bbc:	ef85                	bnez	a5,80002bf4 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002bbe:	00000097          	auipc	ra,0x0
    80002bc2:	f36080e7          	jalr	-202(ra) # 80002af4 <devintr>
    80002bc6:	cd1d                	beqz	a0,80002c04 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bc8:	4789                	li	a5,2
    80002bca:	06f50a63          	beq	a0,a5,80002c3e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bce:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd2:	10049073          	csrw	sstatus,s1
}
    80002bd6:	70a2                	ld	ra,40(sp)
    80002bd8:	7402                	ld	s0,32(sp)
    80002bda:	64e2                	ld	s1,24(sp)
    80002bdc:	6942                	ld	s2,16(sp)
    80002bde:	69a2                	ld	s3,8(sp)
    80002be0:	6145                	addi	sp,sp,48
    80002be2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002be4:	00005517          	auipc	a0,0x5
    80002be8:	75450513          	addi	a0,a0,1876 # 80008338 <states.0+0x58>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	954080e7          	jalr	-1708(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bf4:	00005517          	auipc	a0,0x5
    80002bf8:	76c50513          	addi	a0,a0,1900 # 80008360 <states.0+0x80>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	944080e7          	jalr	-1724(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002c04:	85ce                	mv	a1,s3
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	77a50513          	addi	a0,a0,1914 # 80008380 <states.0+0xa0>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	97c080e7          	jalr	-1668(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c16:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c1a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	77250513          	addi	a0,a0,1906 # 80008390 <states.0+0xb0>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	964080e7          	jalr	-1692(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	77a50513          	addi	a0,a0,1914 # 800083a8 <states.0+0xc8>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	90a080e7          	jalr	-1782(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	f32080e7          	jalr	-206(ra) # 80001b70 <myproc>
    80002c46:	d541                	beqz	a0,80002bce <kerneltrap+0x38>
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	f28080e7          	jalr	-216(ra) # 80001b70 <myproc>
    80002c50:	4d18                	lw	a4,24(a0)
    80002c52:	4791                	li	a5,4
    80002c54:	f6f71de3          	bne	a4,a5,80002bce <kerneltrap+0x38>
    yield();
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	5b2080e7          	jalr	1458(ra) # 8000220a <yield>
    80002c60:	b7bd                	j	80002bce <kerneltrap+0x38>

0000000080002c62 <cow_handler>:

int
cow_handler(pagetable_t pagetable, uint64 va)
{
    80002c62:	7179                	addi	sp,sp,-48
    80002c64:	f406                	sd	ra,40(sp)
    80002c66:	f022                	sd	s0,32(sp)
    80002c68:	ec26                	sd	s1,24(sp)
    80002c6a:	e84a                	sd	s2,16(sp)
    80002c6c:	e44e                	sd	s3,8(sp)
    80002c6e:	1800                	addi	s0,sp,48
  uint64 pa;
  char *mem;

  va = PGROUNDDOWN(va);

  if((pte = walk(pagetable, va, 0)) == 0)
    80002c70:	4601                	li	a2,0
    80002c72:	77fd                	lui	a5,0xfffff
    80002c74:	8dfd                	and	a1,a1,a5
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	4c6080e7          	jalr	1222(ra) # 8000113c <walk>
    80002c7e:	c93d                	beqz	a0,80002cf4 <cow_handler+0x92>
    80002c80:	89aa                	mv	s3,a0
    return -1;

  if((*pte & PTE_V) == 0 || (*pte & PTE_U) == 0)
    80002c82:	610c                	ld	a1,0(a0)
    80002c84:	0115f713          	andi	a4,a1,17
    80002c88:	47c5                	li	a5,17
    80002c8a:	06f71763          	bne	a4,a5,80002cf8 <cow_handler+0x96>
    return -1;

  if(!(*pte & PTE_COW))
    80002c8e:	1005f793          	andi	a5,a1,256
    80002c92:	c7ad                	beqz	a5,80002cfc <cow_handler+0x9a>
    return -1;

  pa = PTE2PA(*pte);
    80002c94:	81a9                	srli	a1,a1,0xa
    80002c96:	00c59913          	slli	s2,a1,0xc

  // Allocate a new page and copy the content
  if((mem = kalloc()) == 0)
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	ef4080e7          	jalr	-268(ra) # 80000b8e <kalloc>
    80002ca2:	84aa                	mv	s1,a0
    80002ca4:	cd31                	beqz	a0,80002d00 <cow_handler+0x9e>
    return -1;

  memmove(mem, (char*)pa, PGSIZE);
    80002ca6:	6605                	lui	a2,0x1
    80002ca8:	85ca                	mv	a1,s2
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	20a080e7          	jalr	522(ra) # 80000eb4 <memmove>

  // Update the PTE with the new physical address and remove the COW flag
  uint flags = (PTE_FLAGS(*pte) | PTE_W) & ~PTE_COW;
    80002cb2:	0009b783          	ld	a5,0(s3)
    80002cb6:	2fb7f793          	andi	a5,a5,763
  *pte = PA2PTE((uint64)mem) | flags;
    80002cba:	0047e793          	ori	a5,a5,4
    80002cbe:	80b1                	srli	s1,s1,0xc
    80002cc0:	04aa                	slli	s1,s1,0xa
    80002cc2:	8fc5                	or	a5,a5,s1
    80002cc4:	00f9b023          	sd	a5,0(s3)

  // Free the old physical page
  kfree((void*)pa);
    80002cc8:	854a                	mv	a0,s2
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	d1e080e7          	jalr	-738(ra) # 800009e8 <kfree>
  struct proc *p = myproc();
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	e9e080e7          	jalr	-354(ra) # 80001b70 <myproc>
  p->test++;
    80002cda:	17452783          	lw	a5,372(a0)
    80002cde:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffbceb9>
    80002ce0:	16f52a23          	sw	a5,372(a0)

  return 0;
    80002ce4:	4501                	li	a0,0
}
    80002ce6:	70a2                	ld	ra,40(sp)
    80002ce8:	7402                	ld	s0,32(sp)
    80002cea:	64e2                	ld	s1,24(sp)
    80002cec:	6942                	ld	s2,16(sp)
    80002cee:	69a2                	ld	s3,8(sp)
    80002cf0:	6145                	addi	sp,sp,48
    80002cf2:	8082                	ret
    return -1;
    80002cf4:	557d                	li	a0,-1
    80002cf6:	bfc5                	j	80002ce6 <cow_handler+0x84>
    return -1;
    80002cf8:	557d                	li	a0,-1
    80002cfa:	b7f5                	j	80002ce6 <cow_handler+0x84>
    return -1;
    80002cfc:	557d                	li	a0,-1
    80002cfe:	b7e5                	j	80002ce6 <cow_handler+0x84>
    return -1;
    80002d00:	557d                	li	a0,-1
    80002d02:	b7d5                	j	80002ce6 <cow_handler+0x84>

0000000080002d04 <usertrap>:
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	e426                	sd	s1,8(sp)
    80002d0c:	e04a                	sd	s2,0(sp)
    80002d0e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d10:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d14:	1007f793          	andi	a5,a5,256
    80002d18:	e7a5                	bnez	a5,80002d80 <usertrap+0x7c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d1a:	00003797          	auipc	a5,0x3
    80002d1e:	2c678793          	addi	a5,a5,710 # 80005fe0 <kernelvec>
    80002d22:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	e4a080e7          	jalr	-438(ra) # 80001b70 <myproc>
    80002d2e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d30:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d32:	14102773          	csrr	a4,sepc
    80002d36:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d38:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d3c:	47a1                	li	a5,8
    80002d3e:	04f70963          	beq	a4,a5,80002d90 <usertrap+0x8c>
  else if ((which_dev = devintr()) != 0)
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	db2080e7          	jalr	-590(ra) # 80002af4 <devintr>
    80002d4a:	892a                	mv	s2,a0
    80002d4c:	ed41                	bnez	a0,80002de4 <usertrap+0xe0>
    80002d4e:	14202773          	csrr	a4,scause
  else if (r_scause() == 15) { // Store page fault
    80002d52:	47bd                	li	a5,15
    80002d54:	06f70b63          	beq	a4,a5,80002dca <usertrap+0xc6>
    p->killed = 1;
    80002d58:	4785                	li	a5,1
    80002d5a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d5c:	557d                	li	a0,-1
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	61c080e7          	jalr	1564(ra) # 8000237a <exit>
  if (which_dev == 2)
    80002d66:	4789                	li	a5,2
    80002d68:	08f90163          	beq	s2,a5,80002dea <usertrap+0xe6>
  usertrapret();
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	c9e080e7          	jalr	-866(ra) # 80002a0a <usertrapret>
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6902                	ld	s2,0(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret
    panic("usertrap: not from user mode");
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	63850513          	addi	a0,a0,1592 # 800083b8 <states.0+0xd8>
    80002d88:	ffffd097          	auipc	ra,0xffffd
    80002d8c:	7b8080e7          	jalr	1976(ra) # 80000540 <panic>
    if (killed(p))
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	76a080e7          	jalr	1898(ra) # 800024fa <killed>
    80002d98:	e11d                	bnez	a0,80002dbe <usertrap+0xba>
    p->trapframe->epc += 4;
    80002d9a:	6cb8                	ld	a4,88(s1)
    80002d9c:	6f1c                	ld	a5,24(a4)
    80002d9e:	0791                	addi	a5,a5,4
    80002da0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002da6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002daa:	10079073          	csrw	sstatus,a5
    syscall();
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	1c4080e7          	jalr	452(ra) # 80002f72 <syscall>
  if (p->killed)
    80002db6:	549c                	lw	a5,40(s1)
    80002db8:	dbd5                	beqz	a5,80002d6c <usertrap+0x68>
    80002dba:	4901                	li	s2,0
    80002dbc:	b745                	j	80002d5c <usertrap+0x58>
      exit(-1);
    80002dbe:	557d                	li	a0,-1
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	5ba080e7          	jalr	1466(ra) # 8000237a <exit>
    80002dc8:	bfc9                	j	80002d9a <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dca:	143025f3          	csrr	a1,stval
    if(va >= p->sz || cow_handler(p->pagetable, va) < 0)
    80002dce:	64bc                	ld	a5,72(s1)
    80002dd0:	f8f5f4e3          	bgeu	a1,a5,80002d58 <usertrap+0x54>
    80002dd4:	68a8                	ld	a0,80(s1)
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	e8c080e7          	jalr	-372(ra) # 80002c62 <cow_handler>
    80002dde:	fc055ce3          	bgez	a0,80002db6 <usertrap+0xb2>
    80002de2:	bf9d                	j	80002d58 <usertrap+0x54>
  if (p->killed)
    80002de4:	549c                	lw	a5,40(s1)
    80002de6:	d3c1                	beqz	a5,80002d66 <usertrap+0x62>
    80002de8:	bf95                	j	80002d5c <usertrap+0x58>
    yield();
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	420080e7          	jalr	1056(ra) # 8000220a <yield>
    80002df2:	bfad                	j	80002d6c <usertrap+0x68>

0000000080002df4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	e426                	sd	s1,8(sp)
    80002dfc:	1000                	addi	s0,sp,32
    80002dfe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	d70080e7          	jalr	-656(ra) # 80001b70 <myproc>
  switch (n) {
    80002e08:	4795                	li	a5,5
    80002e0a:	0497e163          	bltu	a5,s1,80002e4c <argraw+0x58>
    80002e0e:	048a                	slli	s1,s1,0x2
    80002e10:	00005717          	auipc	a4,0x5
    80002e14:	5f070713          	addi	a4,a4,1520 # 80008400 <states.0+0x120>
    80002e18:	94ba                	add	s1,s1,a4
    80002e1a:	409c                	lw	a5,0(s1)
    80002e1c:	97ba                	add	a5,a5,a4
    80002e1e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e20:	6d3c                	ld	a5,88(a0)
    80002e22:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret
    return p->trapframe->a1;
    80002e2e:	6d3c                	ld	a5,88(a0)
    80002e30:	7fa8                	ld	a0,120(a5)
    80002e32:	bfcd                	j	80002e24 <argraw+0x30>
    return p->trapframe->a2;
    80002e34:	6d3c                	ld	a5,88(a0)
    80002e36:	63c8                	ld	a0,128(a5)
    80002e38:	b7f5                	j	80002e24 <argraw+0x30>
    return p->trapframe->a3;
    80002e3a:	6d3c                	ld	a5,88(a0)
    80002e3c:	67c8                	ld	a0,136(a5)
    80002e3e:	b7dd                	j	80002e24 <argraw+0x30>
    return p->trapframe->a4;
    80002e40:	6d3c                	ld	a5,88(a0)
    80002e42:	6bc8                	ld	a0,144(a5)
    80002e44:	b7c5                	j	80002e24 <argraw+0x30>
    return p->trapframe->a5;
    80002e46:	6d3c                	ld	a5,88(a0)
    80002e48:	6fc8                	ld	a0,152(a5)
    80002e4a:	bfe9                	j	80002e24 <argraw+0x30>
  panic("argraw");
    80002e4c:	00005517          	auipc	a0,0x5
    80002e50:	58c50513          	addi	a0,a0,1420 # 800083d8 <states.0+0xf8>
    80002e54:	ffffd097          	auipc	ra,0xffffd
    80002e58:	6ec080e7          	jalr	1772(ra) # 80000540 <panic>

0000000080002e5c <fetchaddr>:
{
    80002e5c:	1101                	addi	sp,sp,-32
    80002e5e:	ec06                	sd	ra,24(sp)
    80002e60:	e822                	sd	s0,16(sp)
    80002e62:	e426                	sd	s1,8(sp)
    80002e64:	e04a                	sd	s2,0(sp)
    80002e66:	1000                	addi	s0,sp,32
    80002e68:	84aa                	mv	s1,a0
    80002e6a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	d04080e7          	jalr	-764(ra) # 80001b70 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e74:	653c                	ld	a5,72(a0)
    80002e76:	02f4f863          	bgeu	s1,a5,80002ea6 <fetchaddr+0x4a>
    80002e7a:	00848713          	addi	a4,s1,8
    80002e7e:	02e7e663          	bltu	a5,a4,80002eaa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e82:	46a1                	li	a3,8
    80002e84:	8626                	mv	a2,s1
    80002e86:	85ca                	mv	a1,s2
    80002e88:	6928                	ld	a0,80(a0)
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	a32080e7          	jalr	-1486(ra) # 800018bc <copyin>
    80002e92:	00a03533          	snez	a0,a0
    80002e96:	40a00533          	neg	a0,a0
}
    80002e9a:	60e2                	ld	ra,24(sp)
    80002e9c:	6442                	ld	s0,16(sp)
    80002e9e:	64a2                	ld	s1,8(sp)
    80002ea0:	6902                	ld	s2,0(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret
    return -1;
    80002ea6:	557d                	li	a0,-1
    80002ea8:	bfcd                	j	80002e9a <fetchaddr+0x3e>
    80002eaa:	557d                	li	a0,-1
    80002eac:	b7fd                	j	80002e9a <fetchaddr+0x3e>

0000000080002eae <fetchstr>:
{
    80002eae:	7179                	addi	sp,sp,-48
    80002eb0:	f406                	sd	ra,40(sp)
    80002eb2:	f022                	sd	s0,32(sp)
    80002eb4:	ec26                	sd	s1,24(sp)
    80002eb6:	e84a                	sd	s2,16(sp)
    80002eb8:	e44e                	sd	s3,8(sp)
    80002eba:	1800                	addi	s0,sp,48
    80002ebc:	892a                	mv	s2,a0
    80002ebe:	84ae                	mv	s1,a1
    80002ec0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	cae080e7          	jalr	-850(ra) # 80001b70 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002eca:	86ce                	mv	a3,s3
    80002ecc:	864a                	mv	a2,s2
    80002ece:	85a6                	mv	a1,s1
    80002ed0:	6928                	ld	a0,80(a0)
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	a78080e7          	jalr	-1416(ra) # 8000194a <copyinstr>
    80002eda:	00054e63          	bltz	a0,80002ef6 <fetchstr+0x48>
  return strlen(buf);
    80002ede:	8526                	mv	a0,s1
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	0f4080e7          	jalr	244(ra) # 80000fd4 <strlen>
}
    80002ee8:	70a2                	ld	ra,40(sp)
    80002eea:	7402                	ld	s0,32(sp)
    80002eec:	64e2                	ld	s1,24(sp)
    80002eee:	6942                	ld	s2,16(sp)
    80002ef0:	69a2                	ld	s3,8(sp)
    80002ef2:	6145                	addi	sp,sp,48
    80002ef4:	8082                	ret
    return -1;
    80002ef6:	557d                	li	a0,-1
    80002ef8:	bfc5                	j	80002ee8 <fetchstr+0x3a>

0000000080002efa <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	e426                	sd	s1,8(sp)
    80002f02:	1000                	addi	s0,sp,32
    80002f04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f06:	00000097          	auipc	ra,0x0
    80002f0a:	eee080e7          	jalr	-274(ra) # 80002df4 <argraw>
    80002f0e:	c088                	sw	a0,0(s1)
}
    80002f10:	60e2                	ld	ra,24(sp)
    80002f12:	6442                	ld	s0,16(sp)
    80002f14:	64a2                	ld	s1,8(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret

0000000080002f1a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	1000                	addi	s0,sp,32
    80002f24:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	ece080e7          	jalr	-306(ra) # 80002df4 <argraw>
    80002f2e:	e088                	sd	a0,0(s1)
}
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	64a2                	ld	s1,8(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f3a:	7179                	addi	sp,sp,-48
    80002f3c:	f406                	sd	ra,40(sp)
    80002f3e:	f022                	sd	s0,32(sp)
    80002f40:	ec26                	sd	s1,24(sp)
    80002f42:	e84a                	sd	s2,16(sp)
    80002f44:	1800                	addi	s0,sp,48
    80002f46:	84ae                	mv	s1,a1
    80002f48:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f4a:	fd840593          	addi	a1,s0,-40
    80002f4e:	00000097          	auipc	ra,0x0
    80002f52:	fcc080e7          	jalr	-52(ra) # 80002f1a <argaddr>
  return fetchstr(addr, buf, max);
    80002f56:	864a                	mv	a2,s2
    80002f58:	85a6                	mv	a1,s1
    80002f5a:	fd843503          	ld	a0,-40(s0)
    80002f5e:	00000097          	auipc	ra,0x0
    80002f62:	f50080e7          	jalr	-176(ra) # 80002eae <fetchstr>
}
    80002f66:	70a2                	ld	ra,40(sp)
    80002f68:	7402                	ld	s0,32(sp)
    80002f6a:	64e2                	ld	s1,24(sp)
    80002f6c:	6942                	ld	s2,16(sp)
    80002f6e:	6145                	addi	sp,sp,48
    80002f70:	8082                	ret

0000000080002f72 <syscall>:
[SYS_waitx]   sys_waitx,
};

void
syscall(void)
{
    80002f72:	1101                	addi	sp,sp,-32
    80002f74:	ec06                	sd	ra,24(sp)
    80002f76:	e822                	sd	s0,16(sp)
    80002f78:	e426                	sd	s1,8(sp)
    80002f7a:	e04a                	sd	s2,0(sp)
    80002f7c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	bf2080e7          	jalr	-1038(ra) # 80001b70 <myproc>
    80002f86:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f88:	05853903          	ld	s2,88(a0)
    80002f8c:	0a893783          	ld	a5,168(s2)
    80002f90:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f94:	37fd                	addiw	a5,a5,-1
    80002f96:	4755                	li	a4,21
    80002f98:	00f76f63          	bltu	a4,a5,80002fb6 <syscall+0x44>
    80002f9c:	00369713          	slli	a4,a3,0x3
    80002fa0:	00005797          	auipc	a5,0x5
    80002fa4:	47878793          	addi	a5,a5,1144 # 80008418 <syscalls>
    80002fa8:	97ba                	add	a5,a5,a4
    80002faa:	639c                	ld	a5,0(a5)
    80002fac:	c789                	beqz	a5,80002fb6 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fae:	9782                	jalr	a5
    80002fb0:	06a93823          	sd	a0,112(s2)
    80002fb4:	a839                	j	80002fd2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fb6:	15848613          	addi	a2,s1,344
    80002fba:	588c                	lw	a1,48(s1)
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	42450513          	addi	a0,a0,1060 # 800083e0 <states.0+0x100>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	5c6080e7          	jalr	1478(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fcc:	6cbc                	ld	a5,88(s1)
    80002fce:	577d                	li	a4,-1
    80002fd0:	fbb8                	sd	a4,112(a5)
  }
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6902                	ld	s2,0(sp)
    80002fda:	6105                	addi	sp,sp,32
    80002fdc:	8082                	ret

0000000080002fde <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fde:	1101                	addi	sp,sp,-32
    80002fe0:	ec06                	sd	ra,24(sp)
    80002fe2:	e822                	sd	s0,16(sp)
    80002fe4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002fe6:	fec40593          	addi	a1,s0,-20
    80002fea:	4501                	li	a0,0
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	f0e080e7          	jalr	-242(ra) # 80002efa <argint>
  exit(n);
    80002ff4:	fec42503          	lw	a0,-20(s0)
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	382080e7          	jalr	898(ra) # 8000237a <exit>
  return 0; // not reached
}
    80003000:	4501                	li	a0,0
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	6105                	addi	sp,sp,32
    80003008:	8082                	ret

000000008000300a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000300a:	1141                	addi	sp,sp,-16
    8000300c:	e406                	sd	ra,8(sp)
    8000300e:	e022                	sd	s0,0(sp)
    80003010:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	b5e080e7          	jalr	-1186(ra) # 80001b70 <myproc>
}
    8000301a:	5908                	lw	a0,48(a0)
    8000301c:	60a2                	ld	ra,8(sp)
    8000301e:	6402                	ld	s0,0(sp)
    80003020:	0141                	addi	sp,sp,16
    80003022:	8082                	ret

0000000080003024 <sys_fork>:

uint64
sys_fork(void)
{
    80003024:	1141                	addi	sp,sp,-16
    80003026:	e406                	sd	ra,8(sp)
    80003028:	e022                	sd	s0,0(sp)
    8000302a:	0800                	addi	s0,sp,16
  return fork();
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	f28080e7          	jalr	-216(ra) # 80001f54 <fork>
}
    80003034:	60a2                	ld	ra,8(sp)
    80003036:	6402                	ld	s0,0(sp)
    80003038:	0141                	addi	sp,sp,16
    8000303a:	8082                	ret

000000008000303c <sys_wait>:

uint64
sys_wait(void)
{
    8000303c:	1101                	addi	sp,sp,-32
    8000303e:	ec06                	sd	ra,24(sp)
    80003040:	e822                	sd	s0,16(sp)
    80003042:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003044:	fe840593          	addi	a1,s0,-24
    80003048:	4501                	li	a0,0
    8000304a:	00000097          	auipc	ra,0x0
    8000304e:	ed0080e7          	jalr	-304(ra) # 80002f1a <argaddr>
  return wait(p);
    80003052:	fe843503          	ld	a0,-24(s0)
    80003056:	fffff097          	auipc	ra,0xfffff
    8000305a:	4d6080e7          	jalr	1238(ra) # 8000252c <wait>
}
    8000305e:	60e2                	ld	ra,24(sp)
    80003060:	6442                	ld	s0,16(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret

0000000080003066 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003066:	7179                	addi	sp,sp,-48
    80003068:	f406                	sd	ra,40(sp)
    8000306a:	f022                	sd	s0,32(sp)
    8000306c:	ec26                	sd	s1,24(sp)
    8000306e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003070:	fdc40593          	addi	a1,s0,-36
    80003074:	4501                	li	a0,0
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	e84080e7          	jalr	-380(ra) # 80002efa <argint>
  addr = myproc()->sz;
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	af2080e7          	jalr	-1294(ra) # 80001b70 <myproc>
    80003086:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003088:	fdc42503          	lw	a0,-36(s0)
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	e6c080e7          	jalr	-404(ra) # 80001ef8 <growproc>
    80003094:	00054863          	bltz	a0,800030a4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003098:	8526                	mv	a0,s1
    8000309a:	70a2                	ld	ra,40(sp)
    8000309c:	7402                	ld	s0,32(sp)
    8000309e:	64e2                	ld	s1,24(sp)
    800030a0:	6145                	addi	sp,sp,48
    800030a2:	8082                	ret
    return -1;
    800030a4:	54fd                	li	s1,-1
    800030a6:	bfcd                	j	80003098 <sys_sbrk+0x32>

00000000800030a8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030a8:	7139                	addi	sp,sp,-64
    800030aa:	fc06                	sd	ra,56(sp)
    800030ac:	f822                	sd	s0,48(sp)
    800030ae:	f426                	sd	s1,40(sp)
    800030b0:	f04a                	sd	s2,32(sp)
    800030b2:	ec4e                	sd	s3,24(sp)
    800030b4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030b6:	fcc40593          	addi	a1,s0,-52
    800030ba:	4501                	li	a0,0
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	e3e080e7          	jalr	-450(ra) # 80002efa <argint>
  acquire(&tickslock);
    800030c4:	00034517          	auipc	a0,0x34
    800030c8:	ca450513          	addi	a0,a0,-860 # 80036d68 <tickslock>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	c90080e7          	jalr	-880(ra) # 80000d5c <acquire>
  ticks0 = ticks;
    800030d4:	00005917          	auipc	s2,0x5
    800030d8:	7dc92903          	lw	s2,2012(s2) # 800088b0 <ticks>
  while (ticks - ticks0 < n)
    800030dc:	fcc42783          	lw	a5,-52(s0)
    800030e0:	cf9d                	beqz	a5,8000311e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030e2:	00034997          	auipc	s3,0x34
    800030e6:	c8698993          	addi	s3,s3,-890 # 80036d68 <tickslock>
    800030ea:	00005497          	auipc	s1,0x5
    800030ee:	7c648493          	addi	s1,s1,1990 # 800088b0 <ticks>
    if (killed(myproc()))
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	a7e080e7          	jalr	-1410(ra) # 80001b70 <myproc>
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	400080e7          	jalr	1024(ra) # 800024fa <killed>
    80003102:	ed15                	bnez	a0,8000313e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003104:	85ce                	mv	a1,s3
    80003106:	8526                	mv	a0,s1
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	13e080e7          	jalr	318(ra) # 80002246 <sleep>
  while (ticks - ticks0 < n)
    80003110:	409c                	lw	a5,0(s1)
    80003112:	412787bb          	subw	a5,a5,s2
    80003116:	fcc42703          	lw	a4,-52(s0)
    8000311a:	fce7ece3          	bltu	a5,a4,800030f2 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000311e:	00034517          	auipc	a0,0x34
    80003122:	c4a50513          	addi	a0,a0,-950 # 80036d68 <tickslock>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	cea080e7          	jalr	-790(ra) # 80000e10 <release>
  return 0;
    8000312e:	4501                	li	a0,0
}
    80003130:	70e2                	ld	ra,56(sp)
    80003132:	7442                	ld	s0,48(sp)
    80003134:	74a2                	ld	s1,40(sp)
    80003136:	7902                	ld	s2,32(sp)
    80003138:	69e2                	ld	s3,24(sp)
    8000313a:	6121                	addi	sp,sp,64
    8000313c:	8082                	ret
      release(&tickslock);
    8000313e:	00034517          	auipc	a0,0x34
    80003142:	c2a50513          	addi	a0,a0,-982 # 80036d68 <tickslock>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	cca080e7          	jalr	-822(ra) # 80000e10 <release>
      return -1;
    8000314e:	557d                	li	a0,-1
    80003150:	b7c5                	j	80003130 <sys_sleep+0x88>

0000000080003152 <sys_kill>:

uint64
sys_kill(void)
{
    80003152:	1101                	addi	sp,sp,-32
    80003154:	ec06                	sd	ra,24(sp)
    80003156:	e822                	sd	s0,16(sp)
    80003158:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000315a:	fec40593          	addi	a1,s0,-20
    8000315e:	4501                	li	a0,0
    80003160:	00000097          	auipc	ra,0x0
    80003164:	d9a080e7          	jalr	-614(ra) # 80002efa <argint>
  return kill(pid);
    80003168:	fec42503          	lw	a0,-20(s0)
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	2f0080e7          	jalr	752(ra) # 8000245c <kill>
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	6105                	addi	sp,sp,32
    8000317a:	8082                	ret

000000008000317c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000317c:	1101                	addi	sp,sp,-32
    8000317e:	ec06                	sd	ra,24(sp)
    80003180:	e822                	sd	s0,16(sp)
    80003182:	e426                	sd	s1,8(sp)
    80003184:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003186:	00034517          	auipc	a0,0x34
    8000318a:	be250513          	addi	a0,a0,-1054 # 80036d68 <tickslock>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	bce080e7          	jalr	-1074(ra) # 80000d5c <acquire>
  xticks = ticks;
    80003196:	00005497          	auipc	s1,0x5
    8000319a:	71a4a483          	lw	s1,1818(s1) # 800088b0 <ticks>
  release(&tickslock);
    8000319e:	00034517          	auipc	a0,0x34
    800031a2:	bca50513          	addi	a0,a0,-1078 # 80036d68 <tickslock>
    800031a6:	ffffe097          	auipc	ra,0xffffe
    800031aa:	c6a080e7          	jalr	-918(ra) # 80000e10 <release>
  return xticks;
}
    800031ae:	02049513          	slli	a0,s1,0x20
    800031b2:	9101                	srli	a0,a0,0x20
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret

00000000800031be <sys_waitx>:

uint64
sys_waitx(void)
{
    800031be:	7139                	addi	sp,sp,-64
    800031c0:	fc06                	sd	ra,56(sp)
    800031c2:	f822                	sd	s0,48(sp)
    800031c4:	f426                	sd	s1,40(sp)
    800031c6:	f04a                	sd	s2,32(sp)
    800031c8:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800031ca:	fd840593          	addi	a1,s0,-40
    800031ce:	4501                	li	a0,0
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	d4a080e7          	jalr	-694(ra) # 80002f1a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800031d8:	fd040593          	addi	a1,s0,-48
    800031dc:	4505                	li	a0,1
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	d3c080e7          	jalr	-708(ra) # 80002f1a <argaddr>
  argaddr(2, &addr2);
    800031e6:	fc840593          	addi	a1,s0,-56
    800031ea:	4509                	li	a0,2
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	d2e080e7          	jalr	-722(ra) # 80002f1a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800031f4:	fc040613          	addi	a2,s0,-64
    800031f8:	fc440593          	addi	a1,s0,-60
    800031fc:	fd843503          	ld	a0,-40(s0)
    80003200:	fffff097          	auipc	ra,0xfffff
    80003204:	5b6080e7          	jalr	1462(ra) # 800027b6 <waitx>
    80003208:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	966080e7          	jalr	-1690(ra) # 80001b70 <myproc>
    80003212:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003214:	4691                	li	a3,4
    80003216:	fc440613          	addi	a2,s0,-60
    8000321a:	fd043583          	ld	a1,-48(s0)
    8000321e:	6928                	ld	a0,80(a0)
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	5d8080e7          	jalr	1496(ra) # 800017f8 <copyout>
    return -1;
    80003228:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000322a:	00054f63          	bltz	a0,80003248 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000322e:	4691                	li	a3,4
    80003230:	fc040613          	addi	a2,s0,-64
    80003234:	fc843583          	ld	a1,-56(s0)
    80003238:	68a8                	ld	a0,80(s1)
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	5be080e7          	jalr	1470(ra) # 800017f8 <copyout>
    80003242:	00054a63          	bltz	a0,80003256 <sys_waitx+0x98>
    return -1;
  return ret;
    80003246:	87ca                	mv	a5,s2
    80003248:	853e                	mv	a0,a5
    8000324a:	70e2                	ld	ra,56(sp)
    8000324c:	7442                	ld	s0,48(sp)
    8000324e:	74a2                	ld	s1,40(sp)
    80003250:	7902                	ld	s2,32(sp)
    80003252:	6121                	addi	sp,sp,64
    80003254:	8082                	ret
    return -1;
    80003256:	57fd                	li	a5,-1
    80003258:	bfc5                	j	80003248 <sys_waitx+0x8a>

000000008000325a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000325a:	7179                	addi	sp,sp,-48
    8000325c:	f406                	sd	ra,40(sp)
    8000325e:	f022                	sd	s0,32(sp)
    80003260:	ec26                	sd	s1,24(sp)
    80003262:	e84a                	sd	s2,16(sp)
    80003264:	e44e                	sd	s3,8(sp)
    80003266:	e052                	sd	s4,0(sp)
    80003268:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000326a:	00005597          	auipc	a1,0x5
    8000326e:	26658593          	addi	a1,a1,614 # 800084d0 <syscalls+0xb8>
    80003272:	00034517          	auipc	a0,0x34
    80003276:	b0e50513          	addi	a0,a0,-1266 # 80036d80 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a52080e7          	jalr	-1454(ra) # 80000ccc <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003282:	0003c797          	auipc	a5,0x3c
    80003286:	afe78793          	addi	a5,a5,-1282 # 8003ed80 <bcache+0x8000>
    8000328a:	0003c717          	auipc	a4,0x3c
    8000328e:	d5e70713          	addi	a4,a4,-674 # 8003efe8 <bcache+0x8268>
    80003292:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003296:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000329a:	00034497          	auipc	s1,0x34
    8000329e:	afe48493          	addi	s1,s1,-1282 # 80036d98 <bcache+0x18>
    b->next = bcache.head.next;
    800032a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032a6:	00005a17          	auipc	s4,0x5
    800032aa:	232a0a13          	addi	s4,s4,562 # 800084d8 <syscalls+0xc0>
    b->next = bcache.head.next;
    800032ae:	2b893783          	ld	a5,696(s2)
    800032b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032b8:	85d2                	mv	a1,s4
    800032ba:	01048513          	addi	a0,s1,16
    800032be:	00001097          	auipc	ra,0x1
    800032c2:	4c8080e7          	jalr	1224(ra) # 80004786 <initsleeplock>
    bcache.head.next->prev = b;
    800032c6:	2b893783          	ld	a5,696(s2)
    800032ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032d0:	45848493          	addi	s1,s1,1112
    800032d4:	fd349de3          	bne	s1,s3,800032ae <binit+0x54>
  }
}
    800032d8:	70a2                	ld	ra,40(sp)
    800032da:	7402                	ld	s0,32(sp)
    800032dc:	64e2                	ld	s1,24(sp)
    800032de:	6942                	ld	s2,16(sp)
    800032e0:	69a2                	ld	s3,8(sp)
    800032e2:	6a02                	ld	s4,0(sp)
    800032e4:	6145                	addi	sp,sp,48
    800032e6:	8082                	ret

00000000800032e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032e8:	7179                	addi	sp,sp,-48
    800032ea:	f406                	sd	ra,40(sp)
    800032ec:	f022                	sd	s0,32(sp)
    800032ee:	ec26                	sd	s1,24(sp)
    800032f0:	e84a                	sd	s2,16(sp)
    800032f2:	e44e                	sd	s3,8(sp)
    800032f4:	1800                	addi	s0,sp,48
    800032f6:	892a                	mv	s2,a0
    800032f8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032fa:	00034517          	auipc	a0,0x34
    800032fe:	a8650513          	addi	a0,a0,-1402 # 80036d80 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	a5a080e7          	jalr	-1446(ra) # 80000d5c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000330a:	0003c497          	auipc	s1,0x3c
    8000330e:	d2e4b483          	ld	s1,-722(s1) # 8003f038 <bcache+0x82b8>
    80003312:	0003c797          	auipc	a5,0x3c
    80003316:	cd678793          	addi	a5,a5,-810 # 8003efe8 <bcache+0x8268>
    8000331a:	02f48f63          	beq	s1,a5,80003358 <bread+0x70>
    8000331e:	873e                	mv	a4,a5
    80003320:	a021                	j	80003328 <bread+0x40>
    80003322:	68a4                	ld	s1,80(s1)
    80003324:	02e48a63          	beq	s1,a4,80003358 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003328:	449c                	lw	a5,8(s1)
    8000332a:	ff279ce3          	bne	a5,s2,80003322 <bread+0x3a>
    8000332e:	44dc                	lw	a5,12(s1)
    80003330:	ff3799e3          	bne	a5,s3,80003322 <bread+0x3a>
      b->refcnt++;
    80003334:	40bc                	lw	a5,64(s1)
    80003336:	2785                	addiw	a5,a5,1
    80003338:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000333a:	00034517          	auipc	a0,0x34
    8000333e:	a4650513          	addi	a0,a0,-1466 # 80036d80 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	ace080e7          	jalr	-1330(ra) # 80000e10 <release>
      acquiresleep(&b->lock);
    8000334a:	01048513          	addi	a0,s1,16
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	472080e7          	jalr	1138(ra) # 800047c0 <acquiresleep>
      return b;
    80003356:	a8b9                	j	800033b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003358:	0003c497          	auipc	s1,0x3c
    8000335c:	cd84b483          	ld	s1,-808(s1) # 8003f030 <bcache+0x82b0>
    80003360:	0003c797          	auipc	a5,0x3c
    80003364:	c8878793          	addi	a5,a5,-888 # 8003efe8 <bcache+0x8268>
    80003368:	00f48863          	beq	s1,a5,80003378 <bread+0x90>
    8000336c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000336e:	40bc                	lw	a5,64(s1)
    80003370:	cf81                	beqz	a5,80003388 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003372:	64a4                	ld	s1,72(s1)
    80003374:	fee49de3          	bne	s1,a4,8000336e <bread+0x86>
  panic("bget: no buffers");
    80003378:	00005517          	auipc	a0,0x5
    8000337c:	16850513          	addi	a0,a0,360 # 800084e0 <syscalls+0xc8>
    80003380:	ffffd097          	auipc	ra,0xffffd
    80003384:	1c0080e7          	jalr	448(ra) # 80000540 <panic>
      b->dev = dev;
    80003388:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000338c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003390:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003394:	4785                	li	a5,1
    80003396:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003398:	00034517          	auipc	a0,0x34
    8000339c:	9e850513          	addi	a0,a0,-1560 # 80036d80 <bcache>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	a70080e7          	jalr	-1424(ra) # 80000e10 <release>
      acquiresleep(&b->lock);
    800033a8:	01048513          	addi	a0,s1,16
    800033ac:	00001097          	auipc	ra,0x1
    800033b0:	414080e7          	jalr	1044(ra) # 800047c0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033b4:	409c                	lw	a5,0(s1)
    800033b6:	cb89                	beqz	a5,800033c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033b8:	8526                	mv	a0,s1
    800033ba:	70a2                	ld	ra,40(sp)
    800033bc:	7402                	ld	s0,32(sp)
    800033be:	64e2                	ld	s1,24(sp)
    800033c0:	6942                	ld	s2,16(sp)
    800033c2:	69a2                	ld	s3,8(sp)
    800033c4:	6145                	addi	sp,sp,48
    800033c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800033c8:	4581                	li	a1,0
    800033ca:	8526                	mv	a0,s1
    800033cc:	00003097          	auipc	ra,0x3
    800033d0:	fd6080e7          	jalr	-42(ra) # 800063a2 <virtio_disk_rw>
    b->valid = 1;
    800033d4:	4785                	li	a5,1
    800033d6:	c09c                	sw	a5,0(s1)
  return b;
    800033d8:	b7c5                	j	800033b8 <bread+0xd0>

00000000800033da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033da:	1101                	addi	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	e426                	sd	s1,8(sp)
    800033e2:	1000                	addi	s0,sp,32
    800033e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e6:	0541                	addi	a0,a0,16
    800033e8:	00001097          	auipc	ra,0x1
    800033ec:	472080e7          	jalr	1138(ra) # 8000485a <holdingsleep>
    800033f0:	cd01                	beqz	a0,80003408 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033f2:	4585                	li	a1,1
    800033f4:	8526                	mv	a0,s1
    800033f6:	00003097          	auipc	ra,0x3
    800033fa:	fac080e7          	jalr	-84(ra) # 800063a2 <virtio_disk_rw>
}
    800033fe:	60e2                	ld	ra,24(sp)
    80003400:	6442                	ld	s0,16(sp)
    80003402:	64a2                	ld	s1,8(sp)
    80003404:	6105                	addi	sp,sp,32
    80003406:	8082                	ret
    panic("bwrite");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	0f050513          	addi	a0,a0,240 # 800084f8 <syscalls+0xe0>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	130080e7          	jalr	304(ra) # 80000540 <panic>

0000000080003418 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	e04a                	sd	s2,0(sp)
    80003422:	1000                	addi	s0,sp,32
    80003424:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003426:	01050913          	addi	s2,a0,16
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	42e080e7          	jalr	1070(ra) # 8000485a <holdingsleep>
    80003434:	c92d                	beqz	a0,800034a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003436:	854a                	mv	a0,s2
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	3de080e7          	jalr	990(ra) # 80004816 <releasesleep>

  acquire(&bcache.lock);
    80003440:	00034517          	auipc	a0,0x34
    80003444:	94050513          	addi	a0,a0,-1728 # 80036d80 <bcache>
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	914080e7          	jalr	-1772(ra) # 80000d5c <acquire>
  b->refcnt--;
    80003450:	40bc                	lw	a5,64(s1)
    80003452:	37fd                	addiw	a5,a5,-1
    80003454:	0007871b          	sext.w	a4,a5
    80003458:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000345a:	eb05                	bnez	a4,8000348a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000345c:	68bc                	ld	a5,80(s1)
    8000345e:	64b8                	ld	a4,72(s1)
    80003460:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003462:	64bc                	ld	a5,72(s1)
    80003464:	68b8                	ld	a4,80(s1)
    80003466:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003468:	0003c797          	auipc	a5,0x3c
    8000346c:	91878793          	addi	a5,a5,-1768 # 8003ed80 <bcache+0x8000>
    80003470:	2b87b703          	ld	a4,696(a5)
    80003474:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003476:	0003c717          	auipc	a4,0x3c
    8000347a:	b7270713          	addi	a4,a4,-1166 # 8003efe8 <bcache+0x8268>
    8000347e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003480:	2b87b703          	ld	a4,696(a5)
    80003484:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003486:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000348a:	00034517          	auipc	a0,0x34
    8000348e:	8f650513          	addi	a0,a0,-1802 # 80036d80 <bcache>
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	97e080e7          	jalr	-1666(ra) # 80000e10 <release>
}
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	64a2                	ld	s1,8(sp)
    800034a0:	6902                	ld	s2,0(sp)
    800034a2:	6105                	addi	sp,sp,32
    800034a4:	8082                	ret
    panic("brelse");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	05a50513          	addi	a0,a0,90 # 80008500 <syscalls+0xe8>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	092080e7          	jalr	146(ra) # 80000540 <panic>

00000000800034b6 <bpin>:

void
bpin(struct buf *b) {
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c2:	00034517          	auipc	a0,0x34
    800034c6:	8be50513          	addi	a0,a0,-1858 # 80036d80 <bcache>
    800034ca:	ffffe097          	auipc	ra,0xffffe
    800034ce:	892080e7          	jalr	-1902(ra) # 80000d5c <acquire>
  b->refcnt++;
    800034d2:	40bc                	lw	a5,64(s1)
    800034d4:	2785                	addiw	a5,a5,1
    800034d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d8:	00034517          	auipc	a0,0x34
    800034dc:	8a850513          	addi	a0,a0,-1880 # 80036d80 <bcache>
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	930080e7          	jalr	-1744(ra) # 80000e10 <release>
}
    800034e8:	60e2                	ld	ra,24(sp)
    800034ea:	6442                	ld	s0,16(sp)
    800034ec:	64a2                	ld	s1,8(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret

00000000800034f2 <bunpin>:

void
bunpin(struct buf *b) {
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	e426                	sd	s1,8(sp)
    800034fa:	1000                	addi	s0,sp,32
    800034fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034fe:	00034517          	auipc	a0,0x34
    80003502:	88250513          	addi	a0,a0,-1918 # 80036d80 <bcache>
    80003506:	ffffe097          	auipc	ra,0xffffe
    8000350a:	856080e7          	jalr	-1962(ra) # 80000d5c <acquire>
  b->refcnt--;
    8000350e:	40bc                	lw	a5,64(s1)
    80003510:	37fd                	addiw	a5,a5,-1
    80003512:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003514:	00034517          	auipc	a0,0x34
    80003518:	86c50513          	addi	a0,a0,-1940 # 80036d80 <bcache>
    8000351c:	ffffe097          	auipc	ra,0xffffe
    80003520:	8f4080e7          	jalr	-1804(ra) # 80000e10 <release>
}
    80003524:	60e2                	ld	ra,24(sp)
    80003526:	6442                	ld	s0,16(sp)
    80003528:	64a2                	ld	s1,8(sp)
    8000352a:	6105                	addi	sp,sp,32
    8000352c:	8082                	ret

000000008000352e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	e426                	sd	s1,8(sp)
    80003536:	e04a                	sd	s2,0(sp)
    80003538:	1000                	addi	s0,sp,32
    8000353a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000353c:	00d5d59b          	srliw	a1,a1,0xd
    80003540:	0003c797          	auipc	a5,0x3c
    80003544:	f1c7a783          	lw	a5,-228(a5) # 8003f45c <sb+0x1c>
    80003548:	9dbd                	addw	a1,a1,a5
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	d9e080e7          	jalr	-610(ra) # 800032e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003552:	0074f713          	andi	a4,s1,7
    80003556:	4785                	li	a5,1
    80003558:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000355c:	14ce                	slli	s1,s1,0x33
    8000355e:	90d9                	srli	s1,s1,0x36
    80003560:	00950733          	add	a4,a0,s1
    80003564:	05874703          	lbu	a4,88(a4)
    80003568:	00e7f6b3          	and	a3,a5,a4
    8000356c:	c69d                	beqz	a3,8000359a <bfree+0x6c>
    8000356e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003570:	94aa                	add	s1,s1,a0
    80003572:	fff7c793          	not	a5,a5
    80003576:	8f7d                	and	a4,a4,a5
    80003578:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	126080e7          	jalr	294(ra) # 800046a2 <log_write>
  brelse(bp);
    80003584:	854a                	mv	a0,s2
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	e92080e7          	jalr	-366(ra) # 80003418 <brelse>
}
    8000358e:	60e2                	ld	ra,24(sp)
    80003590:	6442                	ld	s0,16(sp)
    80003592:	64a2                	ld	s1,8(sp)
    80003594:	6902                	ld	s2,0(sp)
    80003596:	6105                	addi	sp,sp,32
    80003598:	8082                	ret
    panic("freeing free block");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	f6e50513          	addi	a0,a0,-146 # 80008508 <syscalls+0xf0>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9e080e7          	jalr	-98(ra) # 80000540 <panic>

00000000800035aa <balloc>:
{
    800035aa:	711d                	addi	sp,sp,-96
    800035ac:	ec86                	sd	ra,88(sp)
    800035ae:	e8a2                	sd	s0,80(sp)
    800035b0:	e4a6                	sd	s1,72(sp)
    800035b2:	e0ca                	sd	s2,64(sp)
    800035b4:	fc4e                	sd	s3,56(sp)
    800035b6:	f852                	sd	s4,48(sp)
    800035b8:	f456                	sd	s5,40(sp)
    800035ba:	f05a                	sd	s6,32(sp)
    800035bc:	ec5e                	sd	s7,24(sp)
    800035be:	e862                	sd	s8,16(sp)
    800035c0:	e466                	sd	s9,8(sp)
    800035c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035c4:	0003c797          	auipc	a5,0x3c
    800035c8:	e807a783          	lw	a5,-384(a5) # 8003f444 <sb+0x4>
    800035cc:	cff5                	beqz	a5,800036c8 <balloc+0x11e>
    800035ce:	8baa                	mv	s7,a0
    800035d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035d2:	0003cb17          	auipc	s6,0x3c
    800035d6:	e6eb0b13          	addi	s6,s6,-402 # 8003f440 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035e0:	6c89                	lui	s9,0x2
    800035e2:	a061                	j	8000366a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035e4:	97ca                	add	a5,a5,s2
    800035e6:	8e55                	or	a2,a2,a3
    800035e8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035ec:	854a                	mv	a0,s2
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	0b4080e7          	jalr	180(ra) # 800046a2 <log_write>
        brelse(bp);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	e20080e7          	jalr	-480(ra) # 80003418 <brelse>
  bp = bread(dev, bno);
    80003600:	85a6                	mv	a1,s1
    80003602:	855e                	mv	a0,s7
    80003604:	00000097          	auipc	ra,0x0
    80003608:	ce4080e7          	jalr	-796(ra) # 800032e8 <bread>
    8000360c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000360e:	40000613          	li	a2,1024
    80003612:	4581                	li	a1,0
    80003614:	05850513          	addi	a0,a0,88
    80003618:	ffffe097          	auipc	ra,0xffffe
    8000361c:	840080e7          	jalr	-1984(ra) # 80000e58 <memset>
  log_write(bp);
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	080080e7          	jalr	128(ra) # 800046a2 <log_write>
  brelse(bp);
    8000362a:	854a                	mv	a0,s2
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	dec080e7          	jalr	-532(ra) # 80003418 <brelse>
}
    80003634:	8526                	mv	a0,s1
    80003636:	60e6                	ld	ra,88(sp)
    80003638:	6446                	ld	s0,80(sp)
    8000363a:	64a6                	ld	s1,72(sp)
    8000363c:	6906                	ld	s2,64(sp)
    8000363e:	79e2                	ld	s3,56(sp)
    80003640:	7a42                	ld	s4,48(sp)
    80003642:	7aa2                	ld	s5,40(sp)
    80003644:	7b02                	ld	s6,32(sp)
    80003646:	6be2                	ld	s7,24(sp)
    80003648:	6c42                	ld	s8,16(sp)
    8000364a:	6ca2                	ld	s9,8(sp)
    8000364c:	6125                	addi	sp,sp,96
    8000364e:	8082                	ret
    brelse(bp);
    80003650:	854a                	mv	a0,s2
    80003652:	00000097          	auipc	ra,0x0
    80003656:	dc6080e7          	jalr	-570(ra) # 80003418 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000365a:	015c87bb          	addw	a5,s9,s5
    8000365e:	00078a9b          	sext.w	s5,a5
    80003662:	004b2703          	lw	a4,4(s6)
    80003666:	06eaf163          	bgeu	s5,a4,800036c8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000366a:	41fad79b          	sraiw	a5,s5,0x1f
    8000366e:	0137d79b          	srliw	a5,a5,0x13
    80003672:	015787bb          	addw	a5,a5,s5
    80003676:	40d7d79b          	sraiw	a5,a5,0xd
    8000367a:	01cb2583          	lw	a1,28(s6)
    8000367e:	9dbd                	addw	a1,a1,a5
    80003680:	855e                	mv	a0,s7
    80003682:	00000097          	auipc	ra,0x0
    80003686:	c66080e7          	jalr	-922(ra) # 800032e8 <bread>
    8000368a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000368c:	004b2503          	lw	a0,4(s6)
    80003690:	000a849b          	sext.w	s1,s5
    80003694:	8762                	mv	a4,s8
    80003696:	faa4fde3          	bgeu	s1,a0,80003650 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000369a:	00777693          	andi	a3,a4,7
    8000369e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036a2:	41f7579b          	sraiw	a5,a4,0x1f
    800036a6:	01d7d79b          	srliw	a5,a5,0x1d
    800036aa:	9fb9                	addw	a5,a5,a4
    800036ac:	4037d79b          	sraiw	a5,a5,0x3
    800036b0:	00f90633          	add	a2,s2,a5
    800036b4:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800036b8:	00c6f5b3          	and	a1,a3,a2
    800036bc:	d585                	beqz	a1,800035e4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036be:	2705                	addiw	a4,a4,1
    800036c0:	2485                	addiw	s1,s1,1
    800036c2:	fd471ae3          	bne	a4,s4,80003696 <balloc+0xec>
    800036c6:	b769                	j	80003650 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	e5850513          	addi	a0,a0,-424 # 80008520 <syscalls+0x108>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	eba080e7          	jalr	-326(ra) # 8000058a <printf>
  return 0;
    800036d8:	4481                	li	s1,0
    800036da:	bfa9                	j	80003634 <balloc+0x8a>

00000000800036dc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036dc:	7179                	addi	sp,sp,-48
    800036de:	f406                	sd	ra,40(sp)
    800036e0:	f022                	sd	s0,32(sp)
    800036e2:	ec26                	sd	s1,24(sp)
    800036e4:	e84a                	sd	s2,16(sp)
    800036e6:	e44e                	sd	s3,8(sp)
    800036e8:	e052                	sd	s4,0(sp)
    800036ea:	1800                	addi	s0,sp,48
    800036ec:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ee:	47ad                	li	a5,11
    800036f0:	02b7e863          	bltu	a5,a1,80003720 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800036f4:	02059793          	slli	a5,a1,0x20
    800036f8:	01e7d593          	srli	a1,a5,0x1e
    800036fc:	00b504b3          	add	s1,a0,a1
    80003700:	0504a903          	lw	s2,80(s1)
    80003704:	06091e63          	bnez	s2,80003780 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003708:	4108                	lw	a0,0(a0)
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	ea0080e7          	jalr	-352(ra) # 800035aa <balloc>
    80003712:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003716:	06090563          	beqz	s2,80003780 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000371a:	0524a823          	sw	s2,80(s1)
    8000371e:	a08d                	j	80003780 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003720:	ff45849b          	addiw	s1,a1,-12
    80003724:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003728:	0ff00793          	li	a5,255
    8000372c:	08e7e563          	bltu	a5,a4,800037b6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003730:	08052903          	lw	s2,128(a0)
    80003734:	00091d63          	bnez	s2,8000374e <bmap+0x72>
      addr = balloc(ip->dev);
    80003738:	4108                	lw	a0,0(a0)
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	e70080e7          	jalr	-400(ra) # 800035aa <balloc>
    80003742:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003746:	02090d63          	beqz	s2,80003780 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000374a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000374e:	85ca                	mv	a1,s2
    80003750:	0009a503          	lw	a0,0(s3)
    80003754:	00000097          	auipc	ra,0x0
    80003758:	b94080e7          	jalr	-1132(ra) # 800032e8 <bread>
    8000375c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000375e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003762:	02049713          	slli	a4,s1,0x20
    80003766:	01e75593          	srli	a1,a4,0x1e
    8000376a:	00b784b3          	add	s1,a5,a1
    8000376e:	0004a903          	lw	s2,0(s1)
    80003772:	02090063          	beqz	s2,80003792 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003776:	8552                	mv	a0,s4
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	ca0080e7          	jalr	-864(ra) # 80003418 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003780:	854a                	mv	a0,s2
    80003782:	70a2                	ld	ra,40(sp)
    80003784:	7402                	ld	s0,32(sp)
    80003786:	64e2                	ld	s1,24(sp)
    80003788:	6942                	ld	s2,16(sp)
    8000378a:	69a2                	ld	s3,8(sp)
    8000378c:	6a02                	ld	s4,0(sp)
    8000378e:	6145                	addi	sp,sp,48
    80003790:	8082                	ret
      addr = balloc(ip->dev);
    80003792:	0009a503          	lw	a0,0(s3)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	e14080e7          	jalr	-492(ra) # 800035aa <balloc>
    8000379e:	0005091b          	sext.w	s2,a0
      if(addr){
    800037a2:	fc090ae3          	beqz	s2,80003776 <bmap+0x9a>
        a[bn] = addr;
    800037a6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037aa:	8552                	mv	a0,s4
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	ef6080e7          	jalr	-266(ra) # 800046a2 <log_write>
    800037b4:	b7c9                	j	80003776 <bmap+0x9a>
  panic("bmap: out of range");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	d8250513          	addi	a0,a0,-638 # 80008538 <syscalls+0x120>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	d82080e7          	jalr	-638(ra) # 80000540 <panic>

00000000800037c6 <iget>:
{
    800037c6:	7179                	addi	sp,sp,-48
    800037c8:	f406                	sd	ra,40(sp)
    800037ca:	f022                	sd	s0,32(sp)
    800037cc:	ec26                	sd	s1,24(sp)
    800037ce:	e84a                	sd	s2,16(sp)
    800037d0:	e44e                	sd	s3,8(sp)
    800037d2:	e052                	sd	s4,0(sp)
    800037d4:	1800                	addi	s0,sp,48
    800037d6:	89aa                	mv	s3,a0
    800037d8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037da:	0003c517          	auipc	a0,0x3c
    800037de:	c8650513          	addi	a0,a0,-890 # 8003f460 <itable>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	57a080e7          	jalr	1402(ra) # 80000d5c <acquire>
  empty = 0;
    800037ea:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ec:	0003c497          	auipc	s1,0x3c
    800037f0:	c8c48493          	addi	s1,s1,-884 # 8003f478 <itable+0x18>
    800037f4:	0003d697          	auipc	a3,0x3d
    800037f8:	71468693          	addi	a3,a3,1812 # 80040f08 <log>
    800037fc:	a039                	j	8000380a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037fe:	02090b63          	beqz	s2,80003834 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003802:	08848493          	addi	s1,s1,136
    80003806:	02d48a63          	beq	s1,a3,8000383a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000380a:	449c                	lw	a5,8(s1)
    8000380c:	fef059e3          	blez	a5,800037fe <iget+0x38>
    80003810:	4098                	lw	a4,0(s1)
    80003812:	ff3716e3          	bne	a4,s3,800037fe <iget+0x38>
    80003816:	40d8                	lw	a4,4(s1)
    80003818:	ff4713e3          	bne	a4,s4,800037fe <iget+0x38>
      ip->ref++;
    8000381c:	2785                	addiw	a5,a5,1
    8000381e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003820:	0003c517          	auipc	a0,0x3c
    80003824:	c4050513          	addi	a0,a0,-960 # 8003f460 <itable>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	5e8080e7          	jalr	1512(ra) # 80000e10 <release>
      return ip;
    80003830:	8926                	mv	s2,s1
    80003832:	a03d                	j	80003860 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003834:	f7f9                	bnez	a5,80003802 <iget+0x3c>
    80003836:	8926                	mv	s2,s1
    80003838:	b7e9                	j	80003802 <iget+0x3c>
  if(empty == 0)
    8000383a:	02090c63          	beqz	s2,80003872 <iget+0xac>
  ip->dev = dev;
    8000383e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003842:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003846:	4785                	li	a5,1
    80003848:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000384c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003850:	0003c517          	auipc	a0,0x3c
    80003854:	c1050513          	addi	a0,a0,-1008 # 8003f460 <itable>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	5b8080e7          	jalr	1464(ra) # 80000e10 <release>
}
    80003860:	854a                	mv	a0,s2
    80003862:	70a2                	ld	ra,40(sp)
    80003864:	7402                	ld	s0,32(sp)
    80003866:	64e2                	ld	s1,24(sp)
    80003868:	6942                	ld	s2,16(sp)
    8000386a:	69a2                	ld	s3,8(sp)
    8000386c:	6a02                	ld	s4,0(sp)
    8000386e:	6145                	addi	sp,sp,48
    80003870:	8082                	ret
    panic("iget: no inodes");
    80003872:	00005517          	auipc	a0,0x5
    80003876:	cde50513          	addi	a0,a0,-802 # 80008550 <syscalls+0x138>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc6080e7          	jalr	-826(ra) # 80000540 <panic>

0000000080003882 <fsinit>:
fsinit(int dev) {
    80003882:	7179                	addi	sp,sp,-48
    80003884:	f406                	sd	ra,40(sp)
    80003886:	f022                	sd	s0,32(sp)
    80003888:	ec26                	sd	s1,24(sp)
    8000388a:	e84a                	sd	s2,16(sp)
    8000388c:	e44e                	sd	s3,8(sp)
    8000388e:	1800                	addi	s0,sp,48
    80003890:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003892:	4585                	li	a1,1
    80003894:	00000097          	auipc	ra,0x0
    80003898:	a54080e7          	jalr	-1452(ra) # 800032e8 <bread>
    8000389c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000389e:	0003c997          	auipc	s3,0x3c
    800038a2:	ba298993          	addi	s3,s3,-1118 # 8003f440 <sb>
    800038a6:	02000613          	li	a2,32
    800038aa:	05850593          	addi	a1,a0,88
    800038ae:	854e                	mv	a0,s3
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	604080e7          	jalr	1540(ra) # 80000eb4 <memmove>
  brelse(bp);
    800038b8:	8526                	mv	a0,s1
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	b5e080e7          	jalr	-1186(ra) # 80003418 <brelse>
  if(sb.magic != FSMAGIC)
    800038c2:	0009a703          	lw	a4,0(s3)
    800038c6:	102037b7          	lui	a5,0x10203
    800038ca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038ce:	02f71263          	bne	a4,a5,800038f2 <fsinit+0x70>
  initlog(dev, &sb);
    800038d2:	0003c597          	auipc	a1,0x3c
    800038d6:	b6e58593          	addi	a1,a1,-1170 # 8003f440 <sb>
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	b4a080e7          	jalr	-1206(ra) # 80004426 <initlog>
}
    800038e4:	70a2                	ld	ra,40(sp)
    800038e6:	7402                	ld	s0,32(sp)
    800038e8:	64e2                	ld	s1,24(sp)
    800038ea:	6942                	ld	s2,16(sp)
    800038ec:	69a2                	ld	s3,8(sp)
    800038ee:	6145                	addi	sp,sp,48
    800038f0:	8082                	ret
    panic("invalid file system");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	c6e50513          	addi	a0,a0,-914 # 80008560 <syscalls+0x148>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c46080e7          	jalr	-954(ra) # 80000540 <panic>

0000000080003902 <iinit>:
{
    80003902:	7179                	addi	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003910:	00005597          	auipc	a1,0x5
    80003914:	c6858593          	addi	a1,a1,-920 # 80008578 <syscalls+0x160>
    80003918:	0003c517          	auipc	a0,0x3c
    8000391c:	b4850513          	addi	a0,a0,-1208 # 8003f460 <itable>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	3ac080e7          	jalr	940(ra) # 80000ccc <initlock>
  for(i = 0; i < NINODE; i++) {
    80003928:	0003c497          	auipc	s1,0x3c
    8000392c:	b6048493          	addi	s1,s1,-1184 # 8003f488 <itable+0x28>
    80003930:	0003d997          	auipc	s3,0x3d
    80003934:	5e898993          	addi	s3,s3,1512 # 80040f18 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003938:	00005917          	auipc	s2,0x5
    8000393c:	c4890913          	addi	s2,s2,-952 # 80008580 <syscalls+0x168>
    80003940:	85ca                	mv	a1,s2
    80003942:	8526                	mv	a0,s1
    80003944:	00001097          	auipc	ra,0x1
    80003948:	e42080e7          	jalr	-446(ra) # 80004786 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000394c:	08848493          	addi	s1,s1,136
    80003950:	ff3498e3          	bne	s1,s3,80003940 <iinit+0x3e>
}
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6145                	addi	sp,sp,48
    80003960:	8082                	ret

0000000080003962 <ialloc>:
{
    80003962:	715d                	addi	sp,sp,-80
    80003964:	e486                	sd	ra,72(sp)
    80003966:	e0a2                	sd	s0,64(sp)
    80003968:	fc26                	sd	s1,56(sp)
    8000396a:	f84a                	sd	s2,48(sp)
    8000396c:	f44e                	sd	s3,40(sp)
    8000396e:	f052                	sd	s4,32(sp)
    80003970:	ec56                	sd	s5,24(sp)
    80003972:	e85a                	sd	s6,16(sp)
    80003974:	e45e                	sd	s7,8(sp)
    80003976:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003978:	0003c717          	auipc	a4,0x3c
    8000397c:	ad472703          	lw	a4,-1324(a4) # 8003f44c <sb+0xc>
    80003980:	4785                	li	a5,1
    80003982:	04e7fa63          	bgeu	a5,a4,800039d6 <ialloc+0x74>
    80003986:	8aaa                	mv	s5,a0
    80003988:	8bae                	mv	s7,a1
    8000398a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000398c:	0003ca17          	auipc	s4,0x3c
    80003990:	ab4a0a13          	addi	s4,s4,-1356 # 8003f440 <sb>
    80003994:	00048b1b          	sext.w	s6,s1
    80003998:	0044d593          	srli	a1,s1,0x4
    8000399c:	018a2783          	lw	a5,24(s4)
    800039a0:	9dbd                	addw	a1,a1,a5
    800039a2:	8556                	mv	a0,s5
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	944080e7          	jalr	-1724(ra) # 800032e8 <bread>
    800039ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039ae:	05850993          	addi	s3,a0,88
    800039b2:	00f4f793          	andi	a5,s1,15
    800039b6:	079a                	slli	a5,a5,0x6
    800039b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039ba:	00099783          	lh	a5,0(s3)
    800039be:	c3a1                	beqz	a5,800039fe <ialloc+0x9c>
    brelse(bp);
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	a58080e7          	jalr	-1448(ra) # 80003418 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039c8:	0485                	addi	s1,s1,1
    800039ca:	00ca2703          	lw	a4,12(s4)
    800039ce:	0004879b          	sext.w	a5,s1
    800039d2:	fce7e1e3          	bltu	a5,a4,80003994 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039d6:	00005517          	auipc	a0,0x5
    800039da:	bb250513          	addi	a0,a0,-1102 # 80008588 <syscalls+0x170>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	bac080e7          	jalr	-1108(ra) # 8000058a <printf>
  return 0;
    800039e6:	4501                	li	a0,0
}
    800039e8:	60a6                	ld	ra,72(sp)
    800039ea:	6406                	ld	s0,64(sp)
    800039ec:	74e2                	ld	s1,56(sp)
    800039ee:	7942                	ld	s2,48(sp)
    800039f0:	79a2                	ld	s3,40(sp)
    800039f2:	7a02                	ld	s4,32(sp)
    800039f4:	6ae2                	ld	s5,24(sp)
    800039f6:	6b42                	ld	s6,16(sp)
    800039f8:	6ba2                	ld	s7,8(sp)
    800039fa:	6161                	addi	sp,sp,80
    800039fc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039fe:	04000613          	li	a2,64
    80003a02:	4581                	li	a1,0
    80003a04:	854e                	mv	a0,s3
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	452080e7          	jalr	1106(ra) # 80000e58 <memset>
      dip->type = type;
    80003a0e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	c8e080e7          	jalr	-882(ra) # 800046a2 <log_write>
      brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	9fa080e7          	jalr	-1542(ra) # 80003418 <brelse>
      return iget(dev, inum);
    80003a26:	85da                	mv	a1,s6
    80003a28:	8556                	mv	a0,s5
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	d9c080e7          	jalr	-612(ra) # 800037c6 <iget>
    80003a32:	bf5d                	j	800039e8 <ialloc+0x86>

0000000080003a34 <iupdate>:
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	e426                	sd	s1,8(sp)
    80003a3c:	e04a                	sd	s2,0(sp)
    80003a3e:	1000                	addi	s0,sp,32
    80003a40:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a42:	415c                	lw	a5,4(a0)
    80003a44:	0047d79b          	srliw	a5,a5,0x4
    80003a48:	0003c597          	auipc	a1,0x3c
    80003a4c:	a105a583          	lw	a1,-1520(a1) # 8003f458 <sb+0x18>
    80003a50:	9dbd                	addw	a1,a1,a5
    80003a52:	4108                	lw	a0,0(a0)
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	894080e7          	jalr	-1900(ra) # 800032e8 <bread>
    80003a5c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a5e:	05850793          	addi	a5,a0,88
    80003a62:	40d8                	lw	a4,4(s1)
    80003a64:	8b3d                	andi	a4,a4,15
    80003a66:	071a                	slli	a4,a4,0x6
    80003a68:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a6a:	04449703          	lh	a4,68(s1)
    80003a6e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a72:	04649703          	lh	a4,70(s1)
    80003a76:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a7a:	04849703          	lh	a4,72(s1)
    80003a7e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a82:	04a49703          	lh	a4,74(s1)
    80003a86:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a8a:	44f8                	lw	a4,76(s1)
    80003a8c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a8e:	03400613          	li	a2,52
    80003a92:	05048593          	addi	a1,s1,80
    80003a96:	00c78513          	addi	a0,a5,12
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	41a080e7          	jalr	1050(ra) # 80000eb4 <memmove>
  log_write(bp);
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	00001097          	auipc	ra,0x1
    80003aa8:	bfe080e7          	jalr	-1026(ra) # 800046a2 <log_write>
  brelse(bp);
    80003aac:	854a                	mv	a0,s2
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	96a080e7          	jalr	-1686(ra) # 80003418 <brelse>
}
    80003ab6:	60e2                	ld	ra,24(sp)
    80003ab8:	6442                	ld	s0,16(sp)
    80003aba:	64a2                	ld	s1,8(sp)
    80003abc:	6902                	ld	s2,0(sp)
    80003abe:	6105                	addi	sp,sp,32
    80003ac0:	8082                	ret

0000000080003ac2 <idup>:
{
    80003ac2:	1101                	addi	sp,sp,-32
    80003ac4:	ec06                	sd	ra,24(sp)
    80003ac6:	e822                	sd	s0,16(sp)
    80003ac8:	e426                	sd	s1,8(sp)
    80003aca:	1000                	addi	s0,sp,32
    80003acc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ace:	0003c517          	auipc	a0,0x3c
    80003ad2:	99250513          	addi	a0,a0,-1646 # 8003f460 <itable>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	286080e7          	jalr	646(ra) # 80000d5c <acquire>
  ip->ref++;
    80003ade:	449c                	lw	a5,8(s1)
    80003ae0:	2785                	addiw	a5,a5,1
    80003ae2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ae4:	0003c517          	auipc	a0,0x3c
    80003ae8:	97c50513          	addi	a0,a0,-1668 # 8003f460 <itable>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	324080e7          	jalr	804(ra) # 80000e10 <release>
}
    80003af4:	8526                	mv	a0,s1
    80003af6:	60e2                	ld	ra,24(sp)
    80003af8:	6442                	ld	s0,16(sp)
    80003afa:	64a2                	ld	s1,8(sp)
    80003afc:	6105                	addi	sp,sp,32
    80003afe:	8082                	ret

0000000080003b00 <ilock>:
{
    80003b00:	1101                	addi	sp,sp,-32
    80003b02:	ec06                	sd	ra,24(sp)
    80003b04:	e822                	sd	s0,16(sp)
    80003b06:	e426                	sd	s1,8(sp)
    80003b08:	e04a                	sd	s2,0(sp)
    80003b0a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b0c:	c115                	beqz	a0,80003b30 <ilock+0x30>
    80003b0e:	84aa                	mv	s1,a0
    80003b10:	451c                	lw	a5,8(a0)
    80003b12:	00f05f63          	blez	a5,80003b30 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b16:	0541                	addi	a0,a0,16
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	ca8080e7          	jalr	-856(ra) # 800047c0 <acquiresleep>
  if(ip->valid == 0){
    80003b20:	40bc                	lw	a5,64(s1)
    80003b22:	cf99                	beqz	a5,80003b40 <ilock+0x40>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6902                	ld	s2,0(sp)
    80003b2c:	6105                	addi	sp,sp,32
    80003b2e:	8082                	ret
    panic("ilock");
    80003b30:	00005517          	auipc	a0,0x5
    80003b34:	a7050513          	addi	a0,a0,-1424 # 800085a0 <syscalls+0x188>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	a08080e7          	jalr	-1528(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b40:	40dc                	lw	a5,4(s1)
    80003b42:	0047d79b          	srliw	a5,a5,0x4
    80003b46:	0003c597          	auipc	a1,0x3c
    80003b4a:	9125a583          	lw	a1,-1774(a1) # 8003f458 <sb+0x18>
    80003b4e:	9dbd                	addw	a1,a1,a5
    80003b50:	4088                	lw	a0,0(s1)
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	796080e7          	jalr	1942(ra) # 800032e8 <bread>
    80003b5a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b5c:	05850593          	addi	a1,a0,88
    80003b60:	40dc                	lw	a5,4(s1)
    80003b62:	8bbd                	andi	a5,a5,15
    80003b64:	079a                	slli	a5,a5,0x6
    80003b66:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b68:	00059783          	lh	a5,0(a1)
    80003b6c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b70:	00259783          	lh	a5,2(a1)
    80003b74:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b78:	00459783          	lh	a5,4(a1)
    80003b7c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b80:	00659783          	lh	a5,6(a1)
    80003b84:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b88:	459c                	lw	a5,8(a1)
    80003b8a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b8c:	03400613          	li	a2,52
    80003b90:	05b1                	addi	a1,a1,12
    80003b92:	05048513          	addi	a0,s1,80
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	31e080e7          	jalr	798(ra) # 80000eb4 <memmove>
    brelse(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	878080e7          	jalr	-1928(ra) # 80003418 <brelse>
    ip->valid = 1;
    80003ba8:	4785                	li	a5,1
    80003baa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bac:	04449783          	lh	a5,68(s1)
    80003bb0:	fbb5                	bnez	a5,80003b24 <ilock+0x24>
      panic("ilock: no type");
    80003bb2:	00005517          	auipc	a0,0x5
    80003bb6:	9f650513          	addi	a0,a0,-1546 # 800085a8 <syscalls+0x190>
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	986080e7          	jalr	-1658(ra) # 80000540 <panic>

0000000080003bc2 <iunlock>:
{
    80003bc2:	1101                	addi	sp,sp,-32
    80003bc4:	ec06                	sd	ra,24(sp)
    80003bc6:	e822                	sd	s0,16(sp)
    80003bc8:	e426                	sd	s1,8(sp)
    80003bca:	e04a                	sd	s2,0(sp)
    80003bcc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bce:	c905                	beqz	a0,80003bfe <iunlock+0x3c>
    80003bd0:	84aa                	mv	s1,a0
    80003bd2:	01050913          	addi	s2,a0,16
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	c82080e7          	jalr	-894(ra) # 8000485a <holdingsleep>
    80003be0:	cd19                	beqz	a0,80003bfe <iunlock+0x3c>
    80003be2:	449c                	lw	a5,8(s1)
    80003be4:	00f05d63          	blez	a5,80003bfe <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003be8:	854a                	mv	a0,s2
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	c2c080e7          	jalr	-980(ra) # 80004816 <releasesleep>
}
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	64a2                	ld	s1,8(sp)
    80003bf8:	6902                	ld	s2,0(sp)
    80003bfa:	6105                	addi	sp,sp,32
    80003bfc:	8082                	ret
    panic("iunlock");
    80003bfe:	00005517          	auipc	a0,0x5
    80003c02:	9ba50513          	addi	a0,a0,-1606 # 800085b8 <syscalls+0x1a0>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	93a080e7          	jalr	-1734(ra) # 80000540 <panic>

0000000080003c0e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c0e:	7179                	addi	sp,sp,-48
    80003c10:	f406                	sd	ra,40(sp)
    80003c12:	f022                	sd	s0,32(sp)
    80003c14:	ec26                	sd	s1,24(sp)
    80003c16:	e84a                	sd	s2,16(sp)
    80003c18:	e44e                	sd	s3,8(sp)
    80003c1a:	e052                	sd	s4,0(sp)
    80003c1c:	1800                	addi	s0,sp,48
    80003c1e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c20:	05050493          	addi	s1,a0,80
    80003c24:	08050913          	addi	s2,a0,128
    80003c28:	a021                	j	80003c30 <itrunc+0x22>
    80003c2a:	0491                	addi	s1,s1,4
    80003c2c:	01248d63          	beq	s1,s2,80003c46 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c30:	408c                	lw	a1,0(s1)
    80003c32:	dde5                	beqz	a1,80003c2a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c34:	0009a503          	lw	a0,0(s3)
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	8f6080e7          	jalr	-1802(ra) # 8000352e <bfree>
      ip->addrs[i] = 0;
    80003c40:	0004a023          	sw	zero,0(s1)
    80003c44:	b7dd                	j	80003c2a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c46:	0809a583          	lw	a1,128(s3)
    80003c4a:	e185                	bnez	a1,80003c6a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c4c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c50:	854e                	mv	a0,s3
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	de2080e7          	jalr	-542(ra) # 80003a34 <iupdate>
}
    80003c5a:	70a2                	ld	ra,40(sp)
    80003c5c:	7402                	ld	s0,32(sp)
    80003c5e:	64e2                	ld	s1,24(sp)
    80003c60:	6942                	ld	s2,16(sp)
    80003c62:	69a2                	ld	s3,8(sp)
    80003c64:	6a02                	ld	s4,0(sp)
    80003c66:	6145                	addi	sp,sp,48
    80003c68:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c6a:	0009a503          	lw	a0,0(s3)
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	67a080e7          	jalr	1658(ra) # 800032e8 <bread>
    80003c76:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c78:	05850493          	addi	s1,a0,88
    80003c7c:	45850913          	addi	s2,a0,1112
    80003c80:	a021                	j	80003c88 <itrunc+0x7a>
    80003c82:	0491                	addi	s1,s1,4
    80003c84:	01248b63          	beq	s1,s2,80003c9a <itrunc+0x8c>
      if(a[j])
    80003c88:	408c                	lw	a1,0(s1)
    80003c8a:	dde5                	beqz	a1,80003c82 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c8c:	0009a503          	lw	a0,0(s3)
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	89e080e7          	jalr	-1890(ra) # 8000352e <bfree>
    80003c98:	b7ed                	j	80003c82 <itrunc+0x74>
    brelse(bp);
    80003c9a:	8552                	mv	a0,s4
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	77c080e7          	jalr	1916(ra) # 80003418 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ca4:	0809a583          	lw	a1,128(s3)
    80003ca8:	0009a503          	lw	a0,0(s3)
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	882080e7          	jalr	-1918(ra) # 8000352e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cb4:	0809a023          	sw	zero,128(s3)
    80003cb8:	bf51                	j	80003c4c <itrunc+0x3e>

0000000080003cba <iput>:
{
    80003cba:	1101                	addi	sp,sp,-32
    80003cbc:	ec06                	sd	ra,24(sp)
    80003cbe:	e822                	sd	s0,16(sp)
    80003cc0:	e426                	sd	s1,8(sp)
    80003cc2:	e04a                	sd	s2,0(sp)
    80003cc4:	1000                	addi	s0,sp,32
    80003cc6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cc8:	0003b517          	auipc	a0,0x3b
    80003ccc:	79850513          	addi	a0,a0,1944 # 8003f460 <itable>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	08c080e7          	jalr	140(ra) # 80000d5c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cd8:	4498                	lw	a4,8(s1)
    80003cda:	4785                	li	a5,1
    80003cdc:	02f70363          	beq	a4,a5,80003d02 <iput+0x48>
  ip->ref--;
    80003ce0:	449c                	lw	a5,8(s1)
    80003ce2:	37fd                	addiw	a5,a5,-1
    80003ce4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ce6:	0003b517          	auipc	a0,0x3b
    80003cea:	77a50513          	addi	a0,a0,1914 # 8003f460 <itable>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	122080e7          	jalr	290(ra) # 80000e10 <release>
}
    80003cf6:	60e2                	ld	ra,24(sp)
    80003cf8:	6442                	ld	s0,16(sp)
    80003cfa:	64a2                	ld	s1,8(sp)
    80003cfc:	6902                	ld	s2,0(sp)
    80003cfe:	6105                	addi	sp,sp,32
    80003d00:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d02:	40bc                	lw	a5,64(s1)
    80003d04:	dff1                	beqz	a5,80003ce0 <iput+0x26>
    80003d06:	04a49783          	lh	a5,74(s1)
    80003d0a:	fbf9                	bnez	a5,80003ce0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d0c:	01048913          	addi	s2,s1,16
    80003d10:	854a                	mv	a0,s2
    80003d12:	00001097          	auipc	ra,0x1
    80003d16:	aae080e7          	jalr	-1362(ra) # 800047c0 <acquiresleep>
    release(&itable.lock);
    80003d1a:	0003b517          	auipc	a0,0x3b
    80003d1e:	74650513          	addi	a0,a0,1862 # 8003f460 <itable>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	0ee080e7          	jalr	238(ra) # 80000e10 <release>
    itrunc(ip);
    80003d2a:	8526                	mv	a0,s1
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	ee2080e7          	jalr	-286(ra) # 80003c0e <itrunc>
    ip->type = 0;
    80003d34:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d38:	8526                	mv	a0,s1
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	cfa080e7          	jalr	-774(ra) # 80003a34 <iupdate>
    ip->valid = 0;
    80003d42:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d46:	854a                	mv	a0,s2
    80003d48:	00001097          	auipc	ra,0x1
    80003d4c:	ace080e7          	jalr	-1330(ra) # 80004816 <releasesleep>
    acquire(&itable.lock);
    80003d50:	0003b517          	auipc	a0,0x3b
    80003d54:	71050513          	addi	a0,a0,1808 # 8003f460 <itable>
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	004080e7          	jalr	4(ra) # 80000d5c <acquire>
    80003d60:	b741                	j	80003ce0 <iput+0x26>

0000000080003d62 <iunlockput>:
{
    80003d62:	1101                	addi	sp,sp,-32
    80003d64:	ec06                	sd	ra,24(sp)
    80003d66:	e822                	sd	s0,16(sp)
    80003d68:	e426                	sd	s1,8(sp)
    80003d6a:	1000                	addi	s0,sp,32
    80003d6c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	e54080e7          	jalr	-428(ra) # 80003bc2 <iunlock>
  iput(ip);
    80003d76:	8526                	mv	a0,s1
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	f42080e7          	jalr	-190(ra) # 80003cba <iput>
}
    80003d80:	60e2                	ld	ra,24(sp)
    80003d82:	6442                	ld	s0,16(sp)
    80003d84:	64a2                	ld	s1,8(sp)
    80003d86:	6105                	addi	sp,sp,32
    80003d88:	8082                	ret

0000000080003d8a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d8a:	1141                	addi	sp,sp,-16
    80003d8c:	e422                	sd	s0,8(sp)
    80003d8e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d90:	411c                	lw	a5,0(a0)
    80003d92:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d94:	415c                	lw	a5,4(a0)
    80003d96:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d98:	04451783          	lh	a5,68(a0)
    80003d9c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003da0:	04a51783          	lh	a5,74(a0)
    80003da4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003da8:	04c56783          	lwu	a5,76(a0)
    80003dac:	e99c                	sd	a5,16(a1)
}
    80003dae:	6422                	ld	s0,8(sp)
    80003db0:	0141                	addi	sp,sp,16
    80003db2:	8082                	ret

0000000080003db4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003db4:	457c                	lw	a5,76(a0)
    80003db6:	0ed7e963          	bltu	a5,a3,80003ea8 <readi+0xf4>
{
    80003dba:	7159                	addi	sp,sp,-112
    80003dbc:	f486                	sd	ra,104(sp)
    80003dbe:	f0a2                	sd	s0,96(sp)
    80003dc0:	eca6                	sd	s1,88(sp)
    80003dc2:	e8ca                	sd	s2,80(sp)
    80003dc4:	e4ce                	sd	s3,72(sp)
    80003dc6:	e0d2                	sd	s4,64(sp)
    80003dc8:	fc56                	sd	s5,56(sp)
    80003dca:	f85a                	sd	s6,48(sp)
    80003dcc:	f45e                	sd	s7,40(sp)
    80003dce:	f062                	sd	s8,32(sp)
    80003dd0:	ec66                	sd	s9,24(sp)
    80003dd2:	e86a                	sd	s10,16(sp)
    80003dd4:	e46e                	sd	s11,8(sp)
    80003dd6:	1880                	addi	s0,sp,112
    80003dd8:	8b2a                	mv	s6,a0
    80003dda:	8bae                	mv	s7,a1
    80003ddc:	8a32                	mv	s4,a2
    80003dde:	84b6                	mv	s1,a3
    80003de0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003de2:	9f35                	addw	a4,a4,a3
    return 0;
    80003de4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003de6:	0ad76063          	bltu	a4,a3,80003e86 <readi+0xd2>
  if(off + n > ip->size)
    80003dea:	00e7f463          	bgeu	a5,a4,80003df2 <readi+0x3e>
    n = ip->size - off;
    80003dee:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df2:	0a0a8963          	beqz	s5,80003ea4 <readi+0xf0>
    80003df6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003df8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dfc:	5c7d                	li	s8,-1
    80003dfe:	a82d                	j	80003e38 <readi+0x84>
    80003e00:	020d1d93          	slli	s11,s10,0x20
    80003e04:	020ddd93          	srli	s11,s11,0x20
    80003e08:	05890613          	addi	a2,s2,88
    80003e0c:	86ee                	mv	a3,s11
    80003e0e:	963a                	add	a2,a2,a4
    80003e10:	85d2                	mv	a1,s4
    80003e12:	855e                	mv	a0,s7
    80003e14:	fffff097          	auipc	ra,0xfffff
    80003e18:	846080e7          	jalr	-1978(ra) # 8000265a <either_copyout>
    80003e1c:	05850d63          	beq	a0,s8,80003e76 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e20:	854a                	mv	a0,s2
    80003e22:	fffff097          	auipc	ra,0xfffff
    80003e26:	5f6080e7          	jalr	1526(ra) # 80003418 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e2a:	013d09bb          	addw	s3,s10,s3
    80003e2e:	009d04bb          	addw	s1,s10,s1
    80003e32:	9a6e                	add	s4,s4,s11
    80003e34:	0559f763          	bgeu	s3,s5,80003e82 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e38:	00a4d59b          	srliw	a1,s1,0xa
    80003e3c:	855a                	mv	a0,s6
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	89e080e7          	jalr	-1890(ra) # 800036dc <bmap>
    80003e46:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e4a:	cd85                	beqz	a1,80003e82 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e4c:	000b2503          	lw	a0,0(s6)
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	498080e7          	jalr	1176(ra) # 800032e8 <bread>
    80003e58:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5a:	3ff4f713          	andi	a4,s1,1023
    80003e5e:	40ec87bb          	subw	a5,s9,a4
    80003e62:	413a86bb          	subw	a3,s5,s3
    80003e66:	8d3e                	mv	s10,a5
    80003e68:	2781                	sext.w	a5,a5
    80003e6a:	0006861b          	sext.w	a2,a3
    80003e6e:	f8f679e3          	bgeu	a2,a5,80003e00 <readi+0x4c>
    80003e72:	8d36                	mv	s10,a3
    80003e74:	b771                	j	80003e00 <readi+0x4c>
      brelse(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	5a0080e7          	jalr	1440(ra) # 80003418 <brelse>
      tot = -1;
    80003e80:	59fd                	li	s3,-1
  }
  return tot;
    80003e82:	0009851b          	sext.w	a0,s3
}
    80003e86:	70a6                	ld	ra,104(sp)
    80003e88:	7406                	ld	s0,96(sp)
    80003e8a:	64e6                	ld	s1,88(sp)
    80003e8c:	6946                	ld	s2,80(sp)
    80003e8e:	69a6                	ld	s3,72(sp)
    80003e90:	6a06                	ld	s4,64(sp)
    80003e92:	7ae2                	ld	s5,56(sp)
    80003e94:	7b42                	ld	s6,48(sp)
    80003e96:	7ba2                	ld	s7,40(sp)
    80003e98:	7c02                	ld	s8,32(sp)
    80003e9a:	6ce2                	ld	s9,24(sp)
    80003e9c:	6d42                	ld	s10,16(sp)
    80003e9e:	6da2                	ld	s11,8(sp)
    80003ea0:	6165                	addi	sp,sp,112
    80003ea2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ea4:	89d6                	mv	s3,s5
    80003ea6:	bff1                	j	80003e82 <readi+0xce>
    return 0;
    80003ea8:	4501                	li	a0,0
}
    80003eaa:	8082                	ret

0000000080003eac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eac:	457c                	lw	a5,76(a0)
    80003eae:	10d7e863          	bltu	a5,a3,80003fbe <writei+0x112>
{
    80003eb2:	7159                	addi	sp,sp,-112
    80003eb4:	f486                	sd	ra,104(sp)
    80003eb6:	f0a2                	sd	s0,96(sp)
    80003eb8:	eca6                	sd	s1,88(sp)
    80003eba:	e8ca                	sd	s2,80(sp)
    80003ebc:	e4ce                	sd	s3,72(sp)
    80003ebe:	e0d2                	sd	s4,64(sp)
    80003ec0:	fc56                	sd	s5,56(sp)
    80003ec2:	f85a                	sd	s6,48(sp)
    80003ec4:	f45e                	sd	s7,40(sp)
    80003ec6:	f062                	sd	s8,32(sp)
    80003ec8:	ec66                	sd	s9,24(sp)
    80003eca:	e86a                	sd	s10,16(sp)
    80003ecc:	e46e                	sd	s11,8(sp)
    80003ece:	1880                	addi	s0,sp,112
    80003ed0:	8aaa                	mv	s5,a0
    80003ed2:	8bae                	mv	s7,a1
    80003ed4:	8a32                	mv	s4,a2
    80003ed6:	8936                	mv	s2,a3
    80003ed8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003eda:	00e687bb          	addw	a5,a3,a4
    80003ede:	0ed7e263          	bltu	a5,a3,80003fc2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ee2:	00043737          	lui	a4,0x43
    80003ee6:	0ef76063          	bltu	a4,a5,80003fc6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eea:	0c0b0863          	beqz	s6,80003fba <writei+0x10e>
    80003eee:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ef4:	5c7d                	li	s8,-1
    80003ef6:	a091                	j	80003f3a <writei+0x8e>
    80003ef8:	020d1d93          	slli	s11,s10,0x20
    80003efc:	020ddd93          	srli	s11,s11,0x20
    80003f00:	05848513          	addi	a0,s1,88
    80003f04:	86ee                	mv	a3,s11
    80003f06:	8652                	mv	a2,s4
    80003f08:	85de                	mv	a1,s7
    80003f0a:	953a                	add	a0,a0,a4
    80003f0c:	ffffe097          	auipc	ra,0xffffe
    80003f10:	7a4080e7          	jalr	1956(ra) # 800026b0 <either_copyin>
    80003f14:	07850263          	beq	a0,s8,80003f78 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f18:	8526                	mv	a0,s1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	788080e7          	jalr	1928(ra) # 800046a2 <log_write>
    brelse(bp);
    80003f22:	8526                	mv	a0,s1
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	4f4080e7          	jalr	1268(ra) # 80003418 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f2c:	013d09bb          	addw	s3,s10,s3
    80003f30:	012d093b          	addw	s2,s10,s2
    80003f34:	9a6e                	add	s4,s4,s11
    80003f36:	0569f663          	bgeu	s3,s6,80003f82 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f3a:	00a9559b          	srliw	a1,s2,0xa
    80003f3e:	8556                	mv	a0,s5
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	79c080e7          	jalr	1948(ra) # 800036dc <bmap>
    80003f48:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f4c:	c99d                	beqz	a1,80003f82 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f4e:	000aa503          	lw	a0,0(s5)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	396080e7          	jalr	918(ra) # 800032e8 <bread>
    80003f5a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f5c:	3ff97713          	andi	a4,s2,1023
    80003f60:	40ec87bb          	subw	a5,s9,a4
    80003f64:	413b06bb          	subw	a3,s6,s3
    80003f68:	8d3e                	mv	s10,a5
    80003f6a:	2781                	sext.w	a5,a5
    80003f6c:	0006861b          	sext.w	a2,a3
    80003f70:	f8f674e3          	bgeu	a2,a5,80003ef8 <writei+0x4c>
    80003f74:	8d36                	mv	s10,a3
    80003f76:	b749                	j	80003ef8 <writei+0x4c>
      brelse(bp);
    80003f78:	8526                	mv	a0,s1
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	49e080e7          	jalr	1182(ra) # 80003418 <brelse>
  }

  if(off > ip->size)
    80003f82:	04caa783          	lw	a5,76(s5)
    80003f86:	0127f463          	bgeu	a5,s2,80003f8e <writei+0xe2>
    ip->size = off;
    80003f8a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f8e:	8556                	mv	a0,s5
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	aa4080e7          	jalr	-1372(ra) # 80003a34 <iupdate>

  return tot;
    80003f98:	0009851b          	sext.w	a0,s3
}
    80003f9c:	70a6                	ld	ra,104(sp)
    80003f9e:	7406                	ld	s0,96(sp)
    80003fa0:	64e6                	ld	s1,88(sp)
    80003fa2:	6946                	ld	s2,80(sp)
    80003fa4:	69a6                	ld	s3,72(sp)
    80003fa6:	6a06                	ld	s4,64(sp)
    80003fa8:	7ae2                	ld	s5,56(sp)
    80003faa:	7b42                	ld	s6,48(sp)
    80003fac:	7ba2                	ld	s7,40(sp)
    80003fae:	7c02                	ld	s8,32(sp)
    80003fb0:	6ce2                	ld	s9,24(sp)
    80003fb2:	6d42                	ld	s10,16(sp)
    80003fb4:	6da2                	ld	s11,8(sp)
    80003fb6:	6165                	addi	sp,sp,112
    80003fb8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fba:	89da                	mv	s3,s6
    80003fbc:	bfc9                	j	80003f8e <writei+0xe2>
    return -1;
    80003fbe:	557d                	li	a0,-1
}
    80003fc0:	8082                	ret
    return -1;
    80003fc2:	557d                	li	a0,-1
    80003fc4:	bfe1                	j	80003f9c <writei+0xf0>
    return -1;
    80003fc6:	557d                	li	a0,-1
    80003fc8:	bfd1                	j	80003f9c <writei+0xf0>

0000000080003fca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fca:	1141                	addi	sp,sp,-16
    80003fcc:	e406                	sd	ra,8(sp)
    80003fce:	e022                	sd	s0,0(sp)
    80003fd0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fd2:	4639                	li	a2,14
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	f54080e7          	jalr	-172(ra) # 80000f28 <strncmp>
}
    80003fdc:	60a2                	ld	ra,8(sp)
    80003fde:	6402                	ld	s0,0(sp)
    80003fe0:	0141                	addi	sp,sp,16
    80003fe2:	8082                	ret

0000000080003fe4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fe4:	7139                	addi	sp,sp,-64
    80003fe6:	fc06                	sd	ra,56(sp)
    80003fe8:	f822                	sd	s0,48(sp)
    80003fea:	f426                	sd	s1,40(sp)
    80003fec:	f04a                	sd	s2,32(sp)
    80003fee:	ec4e                	sd	s3,24(sp)
    80003ff0:	e852                	sd	s4,16(sp)
    80003ff2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ff4:	04451703          	lh	a4,68(a0)
    80003ff8:	4785                	li	a5,1
    80003ffa:	00f71a63          	bne	a4,a5,8000400e <dirlookup+0x2a>
    80003ffe:	892a                	mv	s2,a0
    80004000:	89ae                	mv	s3,a1
    80004002:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004004:	457c                	lw	a5,76(a0)
    80004006:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004008:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400a:	e79d                	bnez	a5,80004038 <dirlookup+0x54>
    8000400c:	a8a5                	j	80004084 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000400e:	00004517          	auipc	a0,0x4
    80004012:	5b250513          	addi	a0,a0,1458 # 800085c0 <syscalls+0x1a8>
    80004016:	ffffc097          	auipc	ra,0xffffc
    8000401a:	52a080e7          	jalr	1322(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000401e:	00004517          	auipc	a0,0x4
    80004022:	5ba50513          	addi	a0,a0,1466 # 800085d8 <syscalls+0x1c0>
    80004026:	ffffc097          	auipc	ra,0xffffc
    8000402a:	51a080e7          	jalr	1306(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000402e:	24c1                	addiw	s1,s1,16
    80004030:	04c92783          	lw	a5,76(s2)
    80004034:	04f4f763          	bgeu	s1,a5,80004082 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004038:	4741                	li	a4,16
    8000403a:	86a6                	mv	a3,s1
    8000403c:	fc040613          	addi	a2,s0,-64
    80004040:	4581                	li	a1,0
    80004042:	854a                	mv	a0,s2
    80004044:	00000097          	auipc	ra,0x0
    80004048:	d70080e7          	jalr	-656(ra) # 80003db4 <readi>
    8000404c:	47c1                	li	a5,16
    8000404e:	fcf518e3          	bne	a0,a5,8000401e <dirlookup+0x3a>
    if(de.inum == 0)
    80004052:	fc045783          	lhu	a5,-64(s0)
    80004056:	dfe1                	beqz	a5,8000402e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004058:	fc240593          	addi	a1,s0,-62
    8000405c:	854e                	mv	a0,s3
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	f6c080e7          	jalr	-148(ra) # 80003fca <namecmp>
    80004066:	f561                	bnez	a0,8000402e <dirlookup+0x4a>
      if(poff)
    80004068:	000a0463          	beqz	s4,80004070 <dirlookup+0x8c>
        *poff = off;
    8000406c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004070:	fc045583          	lhu	a1,-64(s0)
    80004074:	00092503          	lw	a0,0(s2)
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	74e080e7          	jalr	1870(ra) # 800037c6 <iget>
    80004080:	a011                	j	80004084 <dirlookup+0xa0>
  return 0;
    80004082:	4501                	li	a0,0
}
    80004084:	70e2                	ld	ra,56(sp)
    80004086:	7442                	ld	s0,48(sp)
    80004088:	74a2                	ld	s1,40(sp)
    8000408a:	7902                	ld	s2,32(sp)
    8000408c:	69e2                	ld	s3,24(sp)
    8000408e:	6a42                	ld	s4,16(sp)
    80004090:	6121                	addi	sp,sp,64
    80004092:	8082                	ret

0000000080004094 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004094:	711d                	addi	sp,sp,-96
    80004096:	ec86                	sd	ra,88(sp)
    80004098:	e8a2                	sd	s0,80(sp)
    8000409a:	e4a6                	sd	s1,72(sp)
    8000409c:	e0ca                	sd	s2,64(sp)
    8000409e:	fc4e                	sd	s3,56(sp)
    800040a0:	f852                	sd	s4,48(sp)
    800040a2:	f456                	sd	s5,40(sp)
    800040a4:	f05a                	sd	s6,32(sp)
    800040a6:	ec5e                	sd	s7,24(sp)
    800040a8:	e862                	sd	s8,16(sp)
    800040aa:	e466                	sd	s9,8(sp)
    800040ac:	e06a                	sd	s10,0(sp)
    800040ae:	1080                	addi	s0,sp,96
    800040b0:	84aa                	mv	s1,a0
    800040b2:	8b2e                	mv	s6,a1
    800040b4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040b6:	00054703          	lbu	a4,0(a0)
    800040ba:	02f00793          	li	a5,47
    800040be:	02f70363          	beq	a4,a5,800040e4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040c2:	ffffe097          	auipc	ra,0xffffe
    800040c6:	aae080e7          	jalr	-1362(ra) # 80001b70 <myproc>
    800040ca:	15053503          	ld	a0,336(a0)
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	9f4080e7          	jalr	-1548(ra) # 80003ac2 <idup>
    800040d6:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040d8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040dc:	4cb5                	li	s9,13
  len = path - s;
    800040de:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040e0:	4c05                	li	s8,1
    800040e2:	a87d                	j	800041a0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040e4:	4585                	li	a1,1
    800040e6:	4505                	li	a0,1
    800040e8:	fffff097          	auipc	ra,0xfffff
    800040ec:	6de080e7          	jalr	1758(ra) # 800037c6 <iget>
    800040f0:	8a2a                	mv	s4,a0
    800040f2:	b7dd                	j	800040d8 <namex+0x44>
      iunlockput(ip);
    800040f4:	8552                	mv	a0,s4
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	c6c080e7          	jalr	-916(ra) # 80003d62 <iunlockput>
      return 0;
    800040fe:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004100:	8552                	mv	a0,s4
    80004102:	60e6                	ld	ra,88(sp)
    80004104:	6446                	ld	s0,80(sp)
    80004106:	64a6                	ld	s1,72(sp)
    80004108:	6906                	ld	s2,64(sp)
    8000410a:	79e2                	ld	s3,56(sp)
    8000410c:	7a42                	ld	s4,48(sp)
    8000410e:	7aa2                	ld	s5,40(sp)
    80004110:	7b02                	ld	s6,32(sp)
    80004112:	6be2                	ld	s7,24(sp)
    80004114:	6c42                	ld	s8,16(sp)
    80004116:	6ca2                	ld	s9,8(sp)
    80004118:	6d02                	ld	s10,0(sp)
    8000411a:	6125                	addi	sp,sp,96
    8000411c:	8082                	ret
      iunlock(ip);
    8000411e:	8552                	mv	a0,s4
    80004120:	00000097          	auipc	ra,0x0
    80004124:	aa2080e7          	jalr	-1374(ra) # 80003bc2 <iunlock>
      return ip;
    80004128:	bfe1                	j	80004100 <namex+0x6c>
      iunlockput(ip);
    8000412a:	8552                	mv	a0,s4
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	c36080e7          	jalr	-970(ra) # 80003d62 <iunlockput>
      return 0;
    80004134:	8a4e                	mv	s4,s3
    80004136:	b7e9                	j	80004100 <namex+0x6c>
  len = path - s;
    80004138:	40998633          	sub	a2,s3,s1
    8000413c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004140:	09acd863          	bge	s9,s10,800041d0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004144:	4639                	li	a2,14
    80004146:	85a6                	mv	a1,s1
    80004148:	8556                	mv	a0,s5
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	d6a080e7          	jalr	-662(ra) # 80000eb4 <memmove>
    80004152:	84ce                	mv	s1,s3
  while(*path == '/')
    80004154:	0004c783          	lbu	a5,0(s1)
    80004158:	01279763          	bne	a5,s2,80004166 <namex+0xd2>
    path++;
    8000415c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000415e:	0004c783          	lbu	a5,0(s1)
    80004162:	ff278de3          	beq	a5,s2,8000415c <namex+0xc8>
    ilock(ip);
    80004166:	8552                	mv	a0,s4
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	998080e7          	jalr	-1640(ra) # 80003b00 <ilock>
    if(ip->type != T_DIR){
    80004170:	044a1783          	lh	a5,68(s4)
    80004174:	f98790e3          	bne	a5,s8,800040f4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004178:	000b0563          	beqz	s6,80004182 <namex+0xee>
    8000417c:	0004c783          	lbu	a5,0(s1)
    80004180:	dfd9                	beqz	a5,8000411e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004182:	865e                	mv	a2,s7
    80004184:	85d6                	mv	a1,s5
    80004186:	8552                	mv	a0,s4
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	e5c080e7          	jalr	-420(ra) # 80003fe4 <dirlookup>
    80004190:	89aa                	mv	s3,a0
    80004192:	dd41                	beqz	a0,8000412a <namex+0x96>
    iunlockput(ip);
    80004194:	8552                	mv	a0,s4
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	bcc080e7          	jalr	-1076(ra) # 80003d62 <iunlockput>
    ip = next;
    8000419e:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041a0:	0004c783          	lbu	a5,0(s1)
    800041a4:	01279763          	bne	a5,s2,800041b2 <namex+0x11e>
    path++;
    800041a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041aa:	0004c783          	lbu	a5,0(s1)
    800041ae:	ff278de3          	beq	a5,s2,800041a8 <namex+0x114>
  if(*path == 0)
    800041b2:	cb9d                	beqz	a5,800041e8 <namex+0x154>
  while(*path != '/' && *path != 0)
    800041b4:	0004c783          	lbu	a5,0(s1)
    800041b8:	89a6                	mv	s3,s1
  len = path - s;
    800041ba:	8d5e                	mv	s10,s7
    800041bc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041be:	01278963          	beq	a5,s2,800041d0 <namex+0x13c>
    800041c2:	dbbd                	beqz	a5,80004138 <namex+0xa4>
    path++;
    800041c4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041c6:	0009c783          	lbu	a5,0(s3)
    800041ca:	ff279ce3          	bne	a5,s2,800041c2 <namex+0x12e>
    800041ce:	b7ad                	j	80004138 <namex+0xa4>
    memmove(name, s, len);
    800041d0:	2601                	sext.w	a2,a2
    800041d2:	85a6                	mv	a1,s1
    800041d4:	8556                	mv	a0,s5
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	cde080e7          	jalr	-802(ra) # 80000eb4 <memmove>
    name[len] = 0;
    800041de:	9d56                	add	s10,s10,s5
    800041e0:	000d0023          	sb	zero,0(s10)
    800041e4:	84ce                	mv	s1,s3
    800041e6:	b7bd                	j	80004154 <namex+0xc0>
  if(nameiparent){
    800041e8:	f00b0ce3          	beqz	s6,80004100 <namex+0x6c>
    iput(ip);
    800041ec:	8552                	mv	a0,s4
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	acc080e7          	jalr	-1332(ra) # 80003cba <iput>
    return 0;
    800041f6:	4a01                	li	s4,0
    800041f8:	b721                	j	80004100 <namex+0x6c>

00000000800041fa <dirlink>:
{
    800041fa:	7139                	addi	sp,sp,-64
    800041fc:	fc06                	sd	ra,56(sp)
    800041fe:	f822                	sd	s0,48(sp)
    80004200:	f426                	sd	s1,40(sp)
    80004202:	f04a                	sd	s2,32(sp)
    80004204:	ec4e                	sd	s3,24(sp)
    80004206:	e852                	sd	s4,16(sp)
    80004208:	0080                	addi	s0,sp,64
    8000420a:	892a                	mv	s2,a0
    8000420c:	8a2e                	mv	s4,a1
    8000420e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004210:	4601                	li	a2,0
    80004212:	00000097          	auipc	ra,0x0
    80004216:	dd2080e7          	jalr	-558(ra) # 80003fe4 <dirlookup>
    8000421a:	e93d                	bnez	a0,80004290 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421c:	04c92483          	lw	s1,76(s2)
    80004220:	c49d                	beqz	s1,8000424e <dirlink+0x54>
    80004222:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004224:	4741                	li	a4,16
    80004226:	86a6                	mv	a3,s1
    80004228:	fc040613          	addi	a2,s0,-64
    8000422c:	4581                	li	a1,0
    8000422e:	854a                	mv	a0,s2
    80004230:	00000097          	auipc	ra,0x0
    80004234:	b84080e7          	jalr	-1148(ra) # 80003db4 <readi>
    80004238:	47c1                	li	a5,16
    8000423a:	06f51163          	bne	a0,a5,8000429c <dirlink+0xa2>
    if(de.inum == 0)
    8000423e:	fc045783          	lhu	a5,-64(s0)
    80004242:	c791                	beqz	a5,8000424e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004244:	24c1                	addiw	s1,s1,16
    80004246:	04c92783          	lw	a5,76(s2)
    8000424a:	fcf4ede3          	bltu	s1,a5,80004224 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000424e:	4639                	li	a2,14
    80004250:	85d2                	mv	a1,s4
    80004252:	fc240513          	addi	a0,s0,-62
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	d0e080e7          	jalr	-754(ra) # 80000f64 <strncpy>
  de.inum = inum;
    8000425e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004262:	4741                	li	a4,16
    80004264:	86a6                	mv	a3,s1
    80004266:	fc040613          	addi	a2,s0,-64
    8000426a:	4581                	li	a1,0
    8000426c:	854a                	mv	a0,s2
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	c3e080e7          	jalr	-962(ra) # 80003eac <writei>
    80004276:	1541                	addi	a0,a0,-16
    80004278:	00a03533          	snez	a0,a0
    8000427c:	40a00533          	neg	a0,a0
}
    80004280:	70e2                	ld	ra,56(sp)
    80004282:	7442                	ld	s0,48(sp)
    80004284:	74a2                	ld	s1,40(sp)
    80004286:	7902                	ld	s2,32(sp)
    80004288:	69e2                	ld	s3,24(sp)
    8000428a:	6a42                	ld	s4,16(sp)
    8000428c:	6121                	addi	sp,sp,64
    8000428e:	8082                	ret
    iput(ip);
    80004290:	00000097          	auipc	ra,0x0
    80004294:	a2a080e7          	jalr	-1494(ra) # 80003cba <iput>
    return -1;
    80004298:	557d                	li	a0,-1
    8000429a:	b7dd                	j	80004280 <dirlink+0x86>
      panic("dirlink read");
    8000429c:	00004517          	auipc	a0,0x4
    800042a0:	34c50513          	addi	a0,a0,844 # 800085e8 <syscalls+0x1d0>
    800042a4:	ffffc097          	auipc	ra,0xffffc
    800042a8:	29c080e7          	jalr	668(ra) # 80000540 <panic>

00000000800042ac <namei>:

struct inode*
namei(char *path)
{
    800042ac:	1101                	addi	sp,sp,-32
    800042ae:	ec06                	sd	ra,24(sp)
    800042b0:	e822                	sd	s0,16(sp)
    800042b2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042b4:	fe040613          	addi	a2,s0,-32
    800042b8:	4581                	li	a1,0
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	dda080e7          	jalr	-550(ra) # 80004094 <namex>
}
    800042c2:	60e2                	ld	ra,24(sp)
    800042c4:	6442                	ld	s0,16(sp)
    800042c6:	6105                	addi	sp,sp,32
    800042c8:	8082                	ret

00000000800042ca <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042ca:	1141                	addi	sp,sp,-16
    800042cc:	e406                	sd	ra,8(sp)
    800042ce:	e022                	sd	s0,0(sp)
    800042d0:	0800                	addi	s0,sp,16
    800042d2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042d4:	4585                	li	a1,1
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	dbe080e7          	jalr	-578(ra) # 80004094 <namex>
}
    800042de:	60a2                	ld	ra,8(sp)
    800042e0:	6402                	ld	s0,0(sp)
    800042e2:	0141                	addi	sp,sp,16
    800042e4:	8082                	ret

00000000800042e6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	e426                	sd	s1,8(sp)
    800042ee:	e04a                	sd	s2,0(sp)
    800042f0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042f2:	0003d917          	auipc	s2,0x3d
    800042f6:	c1690913          	addi	s2,s2,-1002 # 80040f08 <log>
    800042fa:	01892583          	lw	a1,24(s2)
    800042fe:	02892503          	lw	a0,40(s2)
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	fe6080e7          	jalr	-26(ra) # 800032e8 <bread>
    8000430a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000430c:	02c92683          	lw	a3,44(s2)
    80004310:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004312:	02d05863          	blez	a3,80004342 <write_head+0x5c>
    80004316:	0003d797          	auipc	a5,0x3d
    8000431a:	c2278793          	addi	a5,a5,-990 # 80040f38 <log+0x30>
    8000431e:	05c50713          	addi	a4,a0,92
    80004322:	36fd                	addiw	a3,a3,-1
    80004324:	02069613          	slli	a2,a3,0x20
    80004328:	01e65693          	srli	a3,a2,0x1e
    8000432c:	0003d617          	auipc	a2,0x3d
    80004330:	c1060613          	addi	a2,a2,-1008 # 80040f3c <log+0x34>
    80004334:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004336:	4390                	lw	a2,0(a5)
    80004338:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000433a:	0791                	addi	a5,a5,4
    8000433c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000433e:	fed79ce3          	bne	a5,a3,80004336 <write_head+0x50>
  }
  bwrite(buf);
    80004342:	8526                	mv	a0,s1
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	096080e7          	jalr	150(ra) # 800033da <bwrite>
  brelse(buf);
    8000434c:	8526                	mv	a0,s1
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	0ca080e7          	jalr	202(ra) # 80003418 <brelse>
}
    80004356:	60e2                	ld	ra,24(sp)
    80004358:	6442                	ld	s0,16(sp)
    8000435a:	64a2                	ld	s1,8(sp)
    8000435c:	6902                	ld	s2,0(sp)
    8000435e:	6105                	addi	sp,sp,32
    80004360:	8082                	ret

0000000080004362 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004362:	0003d797          	auipc	a5,0x3d
    80004366:	bd27a783          	lw	a5,-1070(a5) # 80040f34 <log+0x2c>
    8000436a:	0af05d63          	blez	a5,80004424 <install_trans+0xc2>
{
    8000436e:	7139                	addi	sp,sp,-64
    80004370:	fc06                	sd	ra,56(sp)
    80004372:	f822                	sd	s0,48(sp)
    80004374:	f426                	sd	s1,40(sp)
    80004376:	f04a                	sd	s2,32(sp)
    80004378:	ec4e                	sd	s3,24(sp)
    8000437a:	e852                	sd	s4,16(sp)
    8000437c:	e456                	sd	s5,8(sp)
    8000437e:	e05a                	sd	s6,0(sp)
    80004380:	0080                	addi	s0,sp,64
    80004382:	8b2a                	mv	s6,a0
    80004384:	0003da97          	auipc	s5,0x3d
    80004388:	bb4a8a93          	addi	s5,s5,-1100 # 80040f38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438e:	0003d997          	auipc	s3,0x3d
    80004392:	b7a98993          	addi	s3,s3,-1158 # 80040f08 <log>
    80004396:	a00d                	j	800043b8 <install_trans+0x56>
    brelse(lbuf);
    80004398:	854a                	mv	a0,s2
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	07e080e7          	jalr	126(ra) # 80003418 <brelse>
    brelse(dbuf);
    800043a2:	8526                	mv	a0,s1
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	074080e7          	jalr	116(ra) # 80003418 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ac:	2a05                	addiw	s4,s4,1
    800043ae:	0a91                	addi	s5,s5,4
    800043b0:	02c9a783          	lw	a5,44(s3)
    800043b4:	04fa5e63          	bge	s4,a5,80004410 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043b8:	0189a583          	lw	a1,24(s3)
    800043bc:	014585bb          	addw	a1,a1,s4
    800043c0:	2585                	addiw	a1,a1,1
    800043c2:	0289a503          	lw	a0,40(s3)
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	f22080e7          	jalr	-222(ra) # 800032e8 <bread>
    800043ce:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043d0:	000aa583          	lw	a1,0(s5)
    800043d4:	0289a503          	lw	a0,40(s3)
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	f10080e7          	jalr	-240(ra) # 800032e8 <bread>
    800043e0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043e2:	40000613          	li	a2,1024
    800043e6:	05890593          	addi	a1,s2,88
    800043ea:	05850513          	addi	a0,a0,88
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	ac6080e7          	jalr	-1338(ra) # 80000eb4 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043f6:	8526                	mv	a0,s1
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	fe2080e7          	jalr	-30(ra) # 800033da <bwrite>
    if(recovering == 0)
    80004400:	f80b1ce3          	bnez	s6,80004398 <install_trans+0x36>
      bunpin(dbuf);
    80004404:	8526                	mv	a0,s1
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	0ec080e7          	jalr	236(ra) # 800034f2 <bunpin>
    8000440e:	b769                	j	80004398 <install_trans+0x36>
}
    80004410:	70e2                	ld	ra,56(sp)
    80004412:	7442                	ld	s0,48(sp)
    80004414:	74a2                	ld	s1,40(sp)
    80004416:	7902                	ld	s2,32(sp)
    80004418:	69e2                	ld	s3,24(sp)
    8000441a:	6a42                	ld	s4,16(sp)
    8000441c:	6aa2                	ld	s5,8(sp)
    8000441e:	6b02                	ld	s6,0(sp)
    80004420:	6121                	addi	sp,sp,64
    80004422:	8082                	ret
    80004424:	8082                	ret

0000000080004426 <initlog>:
{
    80004426:	7179                	addi	sp,sp,-48
    80004428:	f406                	sd	ra,40(sp)
    8000442a:	f022                	sd	s0,32(sp)
    8000442c:	ec26                	sd	s1,24(sp)
    8000442e:	e84a                	sd	s2,16(sp)
    80004430:	e44e                	sd	s3,8(sp)
    80004432:	1800                	addi	s0,sp,48
    80004434:	892a                	mv	s2,a0
    80004436:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004438:	0003d497          	auipc	s1,0x3d
    8000443c:	ad048493          	addi	s1,s1,-1328 # 80040f08 <log>
    80004440:	00004597          	auipc	a1,0x4
    80004444:	1b858593          	addi	a1,a1,440 # 800085f8 <syscalls+0x1e0>
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	882080e7          	jalr	-1918(ra) # 80000ccc <initlock>
  log.start = sb->logstart;
    80004452:	0149a583          	lw	a1,20(s3)
    80004456:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004458:	0109a783          	lw	a5,16(s3)
    8000445c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000445e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004462:	854a                	mv	a0,s2
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	e84080e7          	jalr	-380(ra) # 800032e8 <bread>
  log.lh.n = lh->n;
    8000446c:	4d34                	lw	a3,88(a0)
    8000446e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004470:	02d05663          	blez	a3,8000449c <initlog+0x76>
    80004474:	05c50793          	addi	a5,a0,92
    80004478:	0003d717          	auipc	a4,0x3d
    8000447c:	ac070713          	addi	a4,a4,-1344 # 80040f38 <log+0x30>
    80004480:	36fd                	addiw	a3,a3,-1
    80004482:	02069613          	slli	a2,a3,0x20
    80004486:	01e65693          	srli	a3,a2,0x1e
    8000448a:	06050613          	addi	a2,a0,96
    8000448e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004490:	4390                	lw	a2,0(a5)
    80004492:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004494:	0791                	addi	a5,a5,4
    80004496:	0711                	addi	a4,a4,4
    80004498:	fed79ce3          	bne	a5,a3,80004490 <initlog+0x6a>
  brelse(buf);
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	f7c080e7          	jalr	-132(ra) # 80003418 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044a4:	4505                	li	a0,1
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	ebc080e7          	jalr	-324(ra) # 80004362 <install_trans>
  log.lh.n = 0;
    800044ae:	0003d797          	auipc	a5,0x3d
    800044b2:	a807a323          	sw	zero,-1402(a5) # 80040f34 <log+0x2c>
  write_head(); // clear the log
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	e30080e7          	jalr	-464(ra) # 800042e6 <write_head>
}
    800044be:	70a2                	ld	ra,40(sp)
    800044c0:	7402                	ld	s0,32(sp)
    800044c2:	64e2                	ld	s1,24(sp)
    800044c4:	6942                	ld	s2,16(sp)
    800044c6:	69a2                	ld	s3,8(sp)
    800044c8:	6145                	addi	sp,sp,48
    800044ca:	8082                	ret

00000000800044cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044cc:	1101                	addi	sp,sp,-32
    800044ce:	ec06                	sd	ra,24(sp)
    800044d0:	e822                	sd	s0,16(sp)
    800044d2:	e426                	sd	s1,8(sp)
    800044d4:	e04a                	sd	s2,0(sp)
    800044d6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044d8:	0003d517          	auipc	a0,0x3d
    800044dc:	a3050513          	addi	a0,a0,-1488 # 80040f08 <log>
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	87c080e7          	jalr	-1924(ra) # 80000d5c <acquire>
  while(1){
    if(log.committing){
    800044e8:	0003d497          	auipc	s1,0x3d
    800044ec:	a2048493          	addi	s1,s1,-1504 # 80040f08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044f0:	4979                	li	s2,30
    800044f2:	a039                	j	80004500 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044f4:	85a6                	mv	a1,s1
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffe097          	auipc	ra,0xffffe
    800044fc:	d4e080e7          	jalr	-690(ra) # 80002246 <sleep>
    if(log.committing){
    80004500:	50dc                	lw	a5,36(s1)
    80004502:	fbed                	bnez	a5,800044f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004504:	5098                	lw	a4,32(s1)
    80004506:	2705                	addiw	a4,a4,1
    80004508:	0007069b          	sext.w	a3,a4
    8000450c:	0027179b          	slliw	a5,a4,0x2
    80004510:	9fb9                	addw	a5,a5,a4
    80004512:	0017979b          	slliw	a5,a5,0x1
    80004516:	54d8                	lw	a4,44(s1)
    80004518:	9fb9                	addw	a5,a5,a4
    8000451a:	00f95963          	bge	s2,a5,8000452c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000451e:	85a6                	mv	a1,s1
    80004520:	8526                	mv	a0,s1
    80004522:	ffffe097          	auipc	ra,0xffffe
    80004526:	d24080e7          	jalr	-732(ra) # 80002246 <sleep>
    8000452a:	bfd9                	j	80004500 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000452c:	0003d517          	auipc	a0,0x3d
    80004530:	9dc50513          	addi	a0,a0,-1572 # 80040f08 <log>
    80004534:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004536:	ffffd097          	auipc	ra,0xffffd
    8000453a:	8da080e7          	jalr	-1830(ra) # 80000e10 <release>
      break;
    }
  }
}
    8000453e:	60e2                	ld	ra,24(sp)
    80004540:	6442                	ld	s0,16(sp)
    80004542:	64a2                	ld	s1,8(sp)
    80004544:	6902                	ld	s2,0(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000454a:	7139                	addi	sp,sp,-64
    8000454c:	fc06                	sd	ra,56(sp)
    8000454e:	f822                	sd	s0,48(sp)
    80004550:	f426                	sd	s1,40(sp)
    80004552:	f04a                	sd	s2,32(sp)
    80004554:	ec4e                	sd	s3,24(sp)
    80004556:	e852                	sd	s4,16(sp)
    80004558:	e456                	sd	s5,8(sp)
    8000455a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000455c:	0003d497          	auipc	s1,0x3d
    80004560:	9ac48493          	addi	s1,s1,-1620 # 80040f08 <log>
    80004564:	8526                	mv	a0,s1
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	7f6080e7          	jalr	2038(ra) # 80000d5c <acquire>
  log.outstanding -= 1;
    8000456e:	509c                	lw	a5,32(s1)
    80004570:	37fd                	addiw	a5,a5,-1
    80004572:	0007891b          	sext.w	s2,a5
    80004576:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004578:	50dc                	lw	a5,36(s1)
    8000457a:	e7b9                	bnez	a5,800045c8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000457c:	04091e63          	bnez	s2,800045d8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004580:	0003d497          	auipc	s1,0x3d
    80004584:	98848493          	addi	s1,s1,-1656 # 80040f08 <log>
    80004588:	4785                	li	a5,1
    8000458a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000458c:	8526                	mv	a0,s1
    8000458e:	ffffd097          	auipc	ra,0xffffd
    80004592:	882080e7          	jalr	-1918(ra) # 80000e10 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004596:	54dc                	lw	a5,44(s1)
    80004598:	06f04763          	bgtz	a5,80004606 <end_op+0xbc>
    acquire(&log.lock);
    8000459c:	0003d497          	auipc	s1,0x3d
    800045a0:	96c48493          	addi	s1,s1,-1684 # 80040f08 <log>
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	7b6080e7          	jalr	1974(ra) # 80000d5c <acquire>
    log.committing = 0;
    800045ae:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045b2:	8526                	mv	a0,s1
    800045b4:	ffffe097          	auipc	ra,0xffffe
    800045b8:	cf6080e7          	jalr	-778(ra) # 800022aa <wakeup>
    release(&log.lock);
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffd097          	auipc	ra,0xffffd
    800045c2:	852080e7          	jalr	-1966(ra) # 80000e10 <release>
}
    800045c6:	a03d                	j	800045f4 <end_op+0xaa>
    panic("log.committing");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	03850513          	addi	a0,a0,56 # 80008600 <syscalls+0x1e8>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f70080e7          	jalr	-144(ra) # 80000540 <panic>
    wakeup(&log);
    800045d8:	0003d497          	auipc	s1,0x3d
    800045dc:	93048493          	addi	s1,s1,-1744 # 80040f08 <log>
    800045e0:	8526                	mv	a0,s1
    800045e2:	ffffe097          	auipc	ra,0xffffe
    800045e6:	cc8080e7          	jalr	-824(ra) # 800022aa <wakeup>
  release(&log.lock);
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffd097          	auipc	ra,0xffffd
    800045f0:	824080e7          	jalr	-2012(ra) # 80000e10 <release>
}
    800045f4:	70e2                	ld	ra,56(sp)
    800045f6:	7442                	ld	s0,48(sp)
    800045f8:	74a2                	ld	s1,40(sp)
    800045fa:	7902                	ld	s2,32(sp)
    800045fc:	69e2                	ld	s3,24(sp)
    800045fe:	6a42                	ld	s4,16(sp)
    80004600:	6aa2                	ld	s5,8(sp)
    80004602:	6121                	addi	sp,sp,64
    80004604:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004606:	0003da97          	auipc	s5,0x3d
    8000460a:	932a8a93          	addi	s5,s5,-1742 # 80040f38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000460e:	0003da17          	auipc	s4,0x3d
    80004612:	8faa0a13          	addi	s4,s4,-1798 # 80040f08 <log>
    80004616:	018a2583          	lw	a1,24(s4)
    8000461a:	012585bb          	addw	a1,a1,s2
    8000461e:	2585                	addiw	a1,a1,1
    80004620:	028a2503          	lw	a0,40(s4)
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	cc4080e7          	jalr	-828(ra) # 800032e8 <bread>
    8000462c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000462e:	000aa583          	lw	a1,0(s5)
    80004632:	028a2503          	lw	a0,40(s4)
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	cb2080e7          	jalr	-846(ra) # 800032e8 <bread>
    8000463e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004640:	40000613          	li	a2,1024
    80004644:	05850593          	addi	a1,a0,88
    80004648:	05848513          	addi	a0,s1,88
    8000464c:	ffffd097          	auipc	ra,0xffffd
    80004650:	868080e7          	jalr	-1944(ra) # 80000eb4 <memmove>
    bwrite(to);  // write the log
    80004654:	8526                	mv	a0,s1
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	d84080e7          	jalr	-636(ra) # 800033da <bwrite>
    brelse(from);
    8000465e:	854e                	mv	a0,s3
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	db8080e7          	jalr	-584(ra) # 80003418 <brelse>
    brelse(to);
    80004668:	8526                	mv	a0,s1
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	dae080e7          	jalr	-594(ra) # 80003418 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004672:	2905                	addiw	s2,s2,1
    80004674:	0a91                	addi	s5,s5,4
    80004676:	02ca2783          	lw	a5,44(s4)
    8000467a:	f8f94ee3          	blt	s2,a5,80004616 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000467e:	00000097          	auipc	ra,0x0
    80004682:	c68080e7          	jalr	-920(ra) # 800042e6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004686:	4501                	li	a0,0
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	cda080e7          	jalr	-806(ra) # 80004362 <install_trans>
    log.lh.n = 0;
    80004690:	0003d797          	auipc	a5,0x3d
    80004694:	8a07a223          	sw	zero,-1884(a5) # 80040f34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	c4e080e7          	jalr	-946(ra) # 800042e6 <write_head>
    800046a0:	bdf5                	j	8000459c <end_op+0x52>

00000000800046a2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046a2:	1101                	addi	sp,sp,-32
    800046a4:	ec06                	sd	ra,24(sp)
    800046a6:	e822                	sd	s0,16(sp)
    800046a8:	e426                	sd	s1,8(sp)
    800046aa:	e04a                	sd	s2,0(sp)
    800046ac:	1000                	addi	s0,sp,32
    800046ae:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046b0:	0003d917          	auipc	s2,0x3d
    800046b4:	85890913          	addi	s2,s2,-1960 # 80040f08 <log>
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	6a2080e7          	jalr	1698(ra) # 80000d5c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046c2:	02c92603          	lw	a2,44(s2)
    800046c6:	47f5                	li	a5,29
    800046c8:	06c7c563          	blt	a5,a2,80004732 <log_write+0x90>
    800046cc:	0003d797          	auipc	a5,0x3d
    800046d0:	8587a783          	lw	a5,-1960(a5) # 80040f24 <log+0x1c>
    800046d4:	37fd                	addiw	a5,a5,-1
    800046d6:	04f65e63          	bge	a2,a5,80004732 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046da:	0003d797          	auipc	a5,0x3d
    800046de:	84e7a783          	lw	a5,-1970(a5) # 80040f28 <log+0x20>
    800046e2:	06f05063          	blez	a5,80004742 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046e6:	4781                	li	a5,0
    800046e8:	06c05563          	blez	a2,80004752 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ec:	44cc                	lw	a1,12(s1)
    800046ee:	0003d717          	auipc	a4,0x3d
    800046f2:	84a70713          	addi	a4,a4,-1974 # 80040f38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046f6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046f8:	4314                	lw	a3,0(a4)
    800046fa:	04b68c63          	beq	a3,a1,80004752 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046fe:	2785                	addiw	a5,a5,1
    80004700:	0711                	addi	a4,a4,4
    80004702:	fef61be3          	bne	a2,a5,800046f8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004706:	0621                	addi	a2,a2,8
    80004708:	060a                	slli	a2,a2,0x2
    8000470a:	0003c797          	auipc	a5,0x3c
    8000470e:	7fe78793          	addi	a5,a5,2046 # 80040f08 <log>
    80004712:	97b2                	add	a5,a5,a2
    80004714:	44d8                	lw	a4,12(s1)
    80004716:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004718:	8526                	mv	a0,s1
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	d9c080e7          	jalr	-612(ra) # 800034b6 <bpin>
    log.lh.n++;
    80004722:	0003c717          	auipc	a4,0x3c
    80004726:	7e670713          	addi	a4,a4,2022 # 80040f08 <log>
    8000472a:	575c                	lw	a5,44(a4)
    8000472c:	2785                	addiw	a5,a5,1
    8000472e:	d75c                	sw	a5,44(a4)
    80004730:	a82d                	j	8000476a <log_write+0xc8>
    panic("too big a transaction");
    80004732:	00004517          	auipc	a0,0x4
    80004736:	ede50513          	addi	a0,a0,-290 # 80008610 <syscalls+0x1f8>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	e06080e7          	jalr	-506(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004742:	00004517          	auipc	a0,0x4
    80004746:	ee650513          	addi	a0,a0,-282 # 80008628 <syscalls+0x210>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	df6080e7          	jalr	-522(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004752:	00878693          	addi	a3,a5,8
    80004756:	068a                	slli	a3,a3,0x2
    80004758:	0003c717          	auipc	a4,0x3c
    8000475c:	7b070713          	addi	a4,a4,1968 # 80040f08 <log>
    80004760:	9736                	add	a4,a4,a3
    80004762:	44d4                	lw	a3,12(s1)
    80004764:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004766:	faf609e3          	beq	a2,a5,80004718 <log_write+0x76>
  }
  release(&log.lock);
    8000476a:	0003c517          	auipc	a0,0x3c
    8000476e:	79e50513          	addi	a0,a0,1950 # 80040f08 <log>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	69e080e7          	jalr	1694(ra) # 80000e10 <release>
}
    8000477a:	60e2                	ld	ra,24(sp)
    8000477c:	6442                	ld	s0,16(sp)
    8000477e:	64a2                	ld	s1,8(sp)
    80004780:	6902                	ld	s2,0(sp)
    80004782:	6105                	addi	sp,sp,32
    80004784:	8082                	ret

0000000080004786 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004786:	1101                	addi	sp,sp,-32
    80004788:	ec06                	sd	ra,24(sp)
    8000478a:	e822                	sd	s0,16(sp)
    8000478c:	e426                	sd	s1,8(sp)
    8000478e:	e04a                	sd	s2,0(sp)
    80004790:	1000                	addi	s0,sp,32
    80004792:	84aa                	mv	s1,a0
    80004794:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004796:	00004597          	auipc	a1,0x4
    8000479a:	eb258593          	addi	a1,a1,-334 # 80008648 <syscalls+0x230>
    8000479e:	0521                	addi	a0,a0,8
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	52c080e7          	jalr	1324(ra) # 80000ccc <initlock>
  lk->name = name;
    800047a8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047b0:	0204a423          	sw	zero,40(s1)
}
    800047b4:	60e2                	ld	ra,24(sp)
    800047b6:	6442                	ld	s0,16(sp)
    800047b8:	64a2                	ld	s1,8(sp)
    800047ba:	6902                	ld	s2,0(sp)
    800047bc:	6105                	addi	sp,sp,32
    800047be:	8082                	ret

00000000800047c0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047c0:	1101                	addi	sp,sp,-32
    800047c2:	ec06                	sd	ra,24(sp)
    800047c4:	e822                	sd	s0,16(sp)
    800047c6:	e426                	sd	s1,8(sp)
    800047c8:	e04a                	sd	s2,0(sp)
    800047ca:	1000                	addi	s0,sp,32
    800047cc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ce:	00850913          	addi	s2,a0,8
    800047d2:	854a                	mv	a0,s2
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	588080e7          	jalr	1416(ra) # 80000d5c <acquire>
  while (lk->locked) {
    800047dc:	409c                	lw	a5,0(s1)
    800047de:	cb89                	beqz	a5,800047f0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047e0:	85ca                	mv	a1,s2
    800047e2:	8526                	mv	a0,s1
    800047e4:	ffffe097          	auipc	ra,0xffffe
    800047e8:	a62080e7          	jalr	-1438(ra) # 80002246 <sleep>
  while (lk->locked) {
    800047ec:	409c                	lw	a5,0(s1)
    800047ee:	fbed                	bnez	a5,800047e0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047f0:	4785                	li	a5,1
    800047f2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047f4:	ffffd097          	auipc	ra,0xffffd
    800047f8:	37c080e7          	jalr	892(ra) # 80001b70 <myproc>
    800047fc:	591c                	lw	a5,48(a0)
    800047fe:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004800:	854a                	mv	a0,s2
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	60e080e7          	jalr	1550(ra) # 80000e10 <release>
}
    8000480a:	60e2                	ld	ra,24(sp)
    8000480c:	6442                	ld	s0,16(sp)
    8000480e:	64a2                	ld	s1,8(sp)
    80004810:	6902                	ld	s2,0(sp)
    80004812:	6105                	addi	sp,sp,32
    80004814:	8082                	ret

0000000080004816 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004816:	1101                	addi	sp,sp,-32
    80004818:	ec06                	sd	ra,24(sp)
    8000481a:	e822                	sd	s0,16(sp)
    8000481c:	e426                	sd	s1,8(sp)
    8000481e:	e04a                	sd	s2,0(sp)
    80004820:	1000                	addi	s0,sp,32
    80004822:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004824:	00850913          	addi	s2,a0,8
    80004828:	854a                	mv	a0,s2
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	532080e7          	jalr	1330(ra) # 80000d5c <acquire>
  lk->locked = 0;
    80004832:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004836:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffe097          	auipc	ra,0xffffe
    80004840:	a6e080e7          	jalr	-1426(ra) # 800022aa <wakeup>
  release(&lk->lk);
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	5ca080e7          	jalr	1482(ra) # 80000e10 <release>
}
    8000484e:	60e2                	ld	ra,24(sp)
    80004850:	6442                	ld	s0,16(sp)
    80004852:	64a2                	ld	s1,8(sp)
    80004854:	6902                	ld	s2,0(sp)
    80004856:	6105                	addi	sp,sp,32
    80004858:	8082                	ret

000000008000485a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000485a:	7179                	addi	sp,sp,-48
    8000485c:	f406                	sd	ra,40(sp)
    8000485e:	f022                	sd	s0,32(sp)
    80004860:	ec26                	sd	s1,24(sp)
    80004862:	e84a                	sd	s2,16(sp)
    80004864:	e44e                	sd	s3,8(sp)
    80004866:	1800                	addi	s0,sp,48
    80004868:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000486a:	00850913          	addi	s2,a0,8
    8000486e:	854a                	mv	a0,s2
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	4ec080e7          	jalr	1260(ra) # 80000d5c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004878:	409c                	lw	a5,0(s1)
    8000487a:	ef99                	bnez	a5,80004898 <holdingsleep+0x3e>
    8000487c:	4481                	li	s1,0
  release(&lk->lk);
    8000487e:	854a                	mv	a0,s2
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	590080e7          	jalr	1424(ra) # 80000e10 <release>
  return r;
}
    80004888:	8526                	mv	a0,s1
    8000488a:	70a2                	ld	ra,40(sp)
    8000488c:	7402                	ld	s0,32(sp)
    8000488e:	64e2                	ld	s1,24(sp)
    80004890:	6942                	ld	s2,16(sp)
    80004892:	69a2                	ld	s3,8(sp)
    80004894:	6145                	addi	sp,sp,48
    80004896:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004898:	0284a983          	lw	s3,40(s1)
    8000489c:	ffffd097          	auipc	ra,0xffffd
    800048a0:	2d4080e7          	jalr	724(ra) # 80001b70 <myproc>
    800048a4:	5904                	lw	s1,48(a0)
    800048a6:	413484b3          	sub	s1,s1,s3
    800048aa:	0014b493          	seqz	s1,s1
    800048ae:	bfc1                	j	8000487e <holdingsleep+0x24>

00000000800048b0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048b0:	1141                	addi	sp,sp,-16
    800048b2:	e406                	sd	ra,8(sp)
    800048b4:	e022                	sd	s0,0(sp)
    800048b6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048b8:	00004597          	auipc	a1,0x4
    800048bc:	da058593          	addi	a1,a1,-608 # 80008658 <syscalls+0x240>
    800048c0:	0003c517          	auipc	a0,0x3c
    800048c4:	79050513          	addi	a0,a0,1936 # 80041050 <ftable>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	404080e7          	jalr	1028(ra) # 80000ccc <initlock>
}
    800048d0:	60a2                	ld	ra,8(sp)
    800048d2:	6402                	ld	s0,0(sp)
    800048d4:	0141                	addi	sp,sp,16
    800048d6:	8082                	ret

00000000800048d8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048d8:	1101                	addi	sp,sp,-32
    800048da:	ec06                	sd	ra,24(sp)
    800048dc:	e822                	sd	s0,16(sp)
    800048de:	e426                	sd	s1,8(sp)
    800048e0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048e2:	0003c517          	auipc	a0,0x3c
    800048e6:	76e50513          	addi	a0,a0,1902 # 80041050 <ftable>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	472080e7          	jalr	1138(ra) # 80000d5c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048f2:	0003c497          	auipc	s1,0x3c
    800048f6:	77648493          	addi	s1,s1,1910 # 80041068 <ftable+0x18>
    800048fa:	0003d717          	auipc	a4,0x3d
    800048fe:	70e70713          	addi	a4,a4,1806 # 80042008 <disk>
    if(f->ref == 0){
    80004902:	40dc                	lw	a5,4(s1)
    80004904:	cf99                	beqz	a5,80004922 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004906:	02848493          	addi	s1,s1,40
    8000490a:	fee49ce3          	bne	s1,a4,80004902 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000490e:	0003c517          	auipc	a0,0x3c
    80004912:	74250513          	addi	a0,a0,1858 # 80041050 <ftable>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	4fa080e7          	jalr	1274(ra) # 80000e10 <release>
  return 0;
    8000491e:	4481                	li	s1,0
    80004920:	a819                	j	80004936 <filealloc+0x5e>
      f->ref = 1;
    80004922:	4785                	li	a5,1
    80004924:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004926:	0003c517          	auipc	a0,0x3c
    8000492a:	72a50513          	addi	a0,a0,1834 # 80041050 <ftable>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	4e2080e7          	jalr	1250(ra) # 80000e10 <release>
}
    80004936:	8526                	mv	a0,s1
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6105                	addi	sp,sp,32
    80004940:	8082                	ret

0000000080004942 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004942:	1101                	addi	sp,sp,-32
    80004944:	ec06                	sd	ra,24(sp)
    80004946:	e822                	sd	s0,16(sp)
    80004948:	e426                	sd	s1,8(sp)
    8000494a:	1000                	addi	s0,sp,32
    8000494c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000494e:	0003c517          	auipc	a0,0x3c
    80004952:	70250513          	addi	a0,a0,1794 # 80041050 <ftable>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	406080e7          	jalr	1030(ra) # 80000d5c <acquire>
  if(f->ref < 1)
    8000495e:	40dc                	lw	a5,4(s1)
    80004960:	02f05263          	blez	a5,80004984 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004964:	2785                	addiw	a5,a5,1
    80004966:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004968:	0003c517          	auipc	a0,0x3c
    8000496c:	6e850513          	addi	a0,a0,1768 # 80041050 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	4a0080e7          	jalr	1184(ra) # 80000e10 <release>
  return f;
}
    80004978:	8526                	mv	a0,s1
    8000497a:	60e2                	ld	ra,24(sp)
    8000497c:	6442                	ld	s0,16(sp)
    8000497e:	64a2                	ld	s1,8(sp)
    80004980:	6105                	addi	sp,sp,32
    80004982:	8082                	ret
    panic("filedup");
    80004984:	00004517          	auipc	a0,0x4
    80004988:	cdc50513          	addi	a0,a0,-804 # 80008660 <syscalls+0x248>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	bb4080e7          	jalr	-1100(ra) # 80000540 <panic>

0000000080004994 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004994:	7139                	addi	sp,sp,-64
    80004996:	fc06                	sd	ra,56(sp)
    80004998:	f822                	sd	s0,48(sp)
    8000499a:	f426                	sd	s1,40(sp)
    8000499c:	f04a                	sd	s2,32(sp)
    8000499e:	ec4e                	sd	s3,24(sp)
    800049a0:	e852                	sd	s4,16(sp)
    800049a2:	e456                	sd	s5,8(sp)
    800049a4:	0080                	addi	s0,sp,64
    800049a6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049a8:	0003c517          	auipc	a0,0x3c
    800049ac:	6a850513          	addi	a0,a0,1704 # 80041050 <ftable>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	3ac080e7          	jalr	940(ra) # 80000d5c <acquire>
  if(f->ref < 1)
    800049b8:	40dc                	lw	a5,4(s1)
    800049ba:	06f05163          	blez	a5,80004a1c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049be:	37fd                	addiw	a5,a5,-1
    800049c0:	0007871b          	sext.w	a4,a5
    800049c4:	c0dc                	sw	a5,4(s1)
    800049c6:	06e04363          	bgtz	a4,80004a2c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049ca:	0004a903          	lw	s2,0(s1)
    800049ce:	0094ca83          	lbu	s5,9(s1)
    800049d2:	0104ba03          	ld	s4,16(s1)
    800049d6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049da:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049de:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049e2:	0003c517          	auipc	a0,0x3c
    800049e6:	66e50513          	addi	a0,a0,1646 # 80041050 <ftable>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	426080e7          	jalr	1062(ra) # 80000e10 <release>

  if(ff.type == FD_PIPE){
    800049f2:	4785                	li	a5,1
    800049f4:	04f90d63          	beq	s2,a5,80004a4e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049f8:	3979                	addiw	s2,s2,-2
    800049fa:	4785                	li	a5,1
    800049fc:	0527e063          	bltu	a5,s2,80004a3c <fileclose+0xa8>
    begin_op();
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	acc080e7          	jalr	-1332(ra) # 800044cc <begin_op>
    iput(ff.ip);
    80004a08:	854e                	mv	a0,s3
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	2b0080e7          	jalr	688(ra) # 80003cba <iput>
    end_op();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	b38080e7          	jalr	-1224(ra) # 8000454a <end_op>
    80004a1a:	a00d                	j	80004a3c <fileclose+0xa8>
    panic("fileclose");
    80004a1c:	00004517          	auipc	a0,0x4
    80004a20:	c4c50513          	addi	a0,a0,-948 # 80008668 <syscalls+0x250>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	b1c080e7          	jalr	-1252(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a2c:	0003c517          	auipc	a0,0x3c
    80004a30:	62450513          	addi	a0,a0,1572 # 80041050 <ftable>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	3dc080e7          	jalr	988(ra) # 80000e10 <release>
  }
}
    80004a3c:	70e2                	ld	ra,56(sp)
    80004a3e:	7442                	ld	s0,48(sp)
    80004a40:	74a2                	ld	s1,40(sp)
    80004a42:	7902                	ld	s2,32(sp)
    80004a44:	69e2                	ld	s3,24(sp)
    80004a46:	6a42                	ld	s4,16(sp)
    80004a48:	6aa2                	ld	s5,8(sp)
    80004a4a:	6121                	addi	sp,sp,64
    80004a4c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a4e:	85d6                	mv	a1,s5
    80004a50:	8552                	mv	a0,s4
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	34c080e7          	jalr	844(ra) # 80004d9e <pipeclose>
    80004a5a:	b7cd                	j	80004a3c <fileclose+0xa8>

0000000080004a5c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a5c:	715d                	addi	sp,sp,-80
    80004a5e:	e486                	sd	ra,72(sp)
    80004a60:	e0a2                	sd	s0,64(sp)
    80004a62:	fc26                	sd	s1,56(sp)
    80004a64:	f84a                	sd	s2,48(sp)
    80004a66:	f44e                	sd	s3,40(sp)
    80004a68:	0880                	addi	s0,sp,80
    80004a6a:	84aa                	mv	s1,a0
    80004a6c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a6e:	ffffd097          	auipc	ra,0xffffd
    80004a72:	102080e7          	jalr	258(ra) # 80001b70 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a76:	409c                	lw	a5,0(s1)
    80004a78:	37f9                	addiw	a5,a5,-2
    80004a7a:	4705                	li	a4,1
    80004a7c:	04f76763          	bltu	a4,a5,80004aca <filestat+0x6e>
    80004a80:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a82:	6c88                	ld	a0,24(s1)
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	07c080e7          	jalr	124(ra) # 80003b00 <ilock>
    stati(f->ip, &st);
    80004a8c:	fb840593          	addi	a1,s0,-72
    80004a90:	6c88                	ld	a0,24(s1)
    80004a92:	fffff097          	auipc	ra,0xfffff
    80004a96:	2f8080e7          	jalr	760(ra) # 80003d8a <stati>
    iunlock(f->ip);
    80004a9a:	6c88                	ld	a0,24(s1)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	126080e7          	jalr	294(ra) # 80003bc2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aa4:	46e1                	li	a3,24
    80004aa6:	fb840613          	addi	a2,s0,-72
    80004aaa:	85ce                	mv	a1,s3
    80004aac:	05093503          	ld	a0,80(s2)
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	d48080e7          	jalr	-696(ra) # 800017f8 <copyout>
    80004ab8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004abc:	60a6                	ld	ra,72(sp)
    80004abe:	6406                	ld	s0,64(sp)
    80004ac0:	74e2                	ld	s1,56(sp)
    80004ac2:	7942                	ld	s2,48(sp)
    80004ac4:	79a2                	ld	s3,40(sp)
    80004ac6:	6161                	addi	sp,sp,80
    80004ac8:	8082                	ret
  return -1;
    80004aca:	557d                	li	a0,-1
    80004acc:	bfc5                	j	80004abc <filestat+0x60>

0000000080004ace <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ace:	7179                	addi	sp,sp,-48
    80004ad0:	f406                	sd	ra,40(sp)
    80004ad2:	f022                	sd	s0,32(sp)
    80004ad4:	ec26                	sd	s1,24(sp)
    80004ad6:	e84a                	sd	s2,16(sp)
    80004ad8:	e44e                	sd	s3,8(sp)
    80004ada:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004adc:	00854783          	lbu	a5,8(a0)
    80004ae0:	c3d5                	beqz	a5,80004b84 <fileread+0xb6>
    80004ae2:	84aa                	mv	s1,a0
    80004ae4:	89ae                	mv	s3,a1
    80004ae6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae8:	411c                	lw	a5,0(a0)
    80004aea:	4705                	li	a4,1
    80004aec:	04e78963          	beq	a5,a4,80004b3e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004af0:	470d                	li	a4,3
    80004af2:	04e78d63          	beq	a5,a4,80004b4c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004af6:	4709                	li	a4,2
    80004af8:	06e79e63          	bne	a5,a4,80004b74 <fileread+0xa6>
    ilock(f->ip);
    80004afc:	6d08                	ld	a0,24(a0)
    80004afe:	fffff097          	auipc	ra,0xfffff
    80004b02:	002080e7          	jalr	2(ra) # 80003b00 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b06:	874a                	mv	a4,s2
    80004b08:	5094                	lw	a3,32(s1)
    80004b0a:	864e                	mv	a2,s3
    80004b0c:	4585                	li	a1,1
    80004b0e:	6c88                	ld	a0,24(s1)
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	2a4080e7          	jalr	676(ra) # 80003db4 <readi>
    80004b18:	892a                	mv	s2,a0
    80004b1a:	00a05563          	blez	a0,80004b24 <fileread+0x56>
      f->off += r;
    80004b1e:	509c                	lw	a5,32(s1)
    80004b20:	9fa9                	addw	a5,a5,a0
    80004b22:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	09c080e7          	jalr	156(ra) # 80003bc2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b2e:	854a                	mv	a0,s2
    80004b30:	70a2                	ld	ra,40(sp)
    80004b32:	7402                	ld	s0,32(sp)
    80004b34:	64e2                	ld	s1,24(sp)
    80004b36:	6942                	ld	s2,16(sp)
    80004b38:	69a2                	ld	s3,8(sp)
    80004b3a:	6145                	addi	sp,sp,48
    80004b3c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b3e:	6908                	ld	a0,16(a0)
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	3c6080e7          	jalr	966(ra) # 80004f06 <piperead>
    80004b48:	892a                	mv	s2,a0
    80004b4a:	b7d5                	j	80004b2e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b4c:	02451783          	lh	a5,36(a0)
    80004b50:	03079693          	slli	a3,a5,0x30
    80004b54:	92c1                	srli	a3,a3,0x30
    80004b56:	4725                	li	a4,9
    80004b58:	02d76863          	bltu	a4,a3,80004b88 <fileread+0xba>
    80004b5c:	0792                	slli	a5,a5,0x4
    80004b5e:	0003c717          	auipc	a4,0x3c
    80004b62:	45270713          	addi	a4,a4,1106 # 80040fb0 <devsw>
    80004b66:	97ba                	add	a5,a5,a4
    80004b68:	639c                	ld	a5,0(a5)
    80004b6a:	c38d                	beqz	a5,80004b8c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b6c:	4505                	li	a0,1
    80004b6e:	9782                	jalr	a5
    80004b70:	892a                	mv	s2,a0
    80004b72:	bf75                	j	80004b2e <fileread+0x60>
    panic("fileread");
    80004b74:	00004517          	auipc	a0,0x4
    80004b78:	b0450513          	addi	a0,a0,-1276 # 80008678 <syscalls+0x260>
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	9c4080e7          	jalr	-1596(ra) # 80000540 <panic>
    return -1;
    80004b84:	597d                	li	s2,-1
    80004b86:	b765                	j	80004b2e <fileread+0x60>
      return -1;
    80004b88:	597d                	li	s2,-1
    80004b8a:	b755                	j	80004b2e <fileread+0x60>
    80004b8c:	597d                	li	s2,-1
    80004b8e:	b745                	j	80004b2e <fileread+0x60>

0000000080004b90 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b90:	715d                	addi	sp,sp,-80
    80004b92:	e486                	sd	ra,72(sp)
    80004b94:	e0a2                	sd	s0,64(sp)
    80004b96:	fc26                	sd	s1,56(sp)
    80004b98:	f84a                	sd	s2,48(sp)
    80004b9a:	f44e                	sd	s3,40(sp)
    80004b9c:	f052                	sd	s4,32(sp)
    80004b9e:	ec56                	sd	s5,24(sp)
    80004ba0:	e85a                	sd	s6,16(sp)
    80004ba2:	e45e                	sd	s7,8(sp)
    80004ba4:	e062                	sd	s8,0(sp)
    80004ba6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ba8:	00954783          	lbu	a5,9(a0)
    80004bac:	10078663          	beqz	a5,80004cb8 <filewrite+0x128>
    80004bb0:	892a                	mv	s2,a0
    80004bb2:	8b2e                	mv	s6,a1
    80004bb4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bb6:	411c                	lw	a5,0(a0)
    80004bb8:	4705                	li	a4,1
    80004bba:	02e78263          	beq	a5,a4,80004bde <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bbe:	470d                	li	a4,3
    80004bc0:	02e78663          	beq	a5,a4,80004bec <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc4:	4709                	li	a4,2
    80004bc6:	0ee79163          	bne	a5,a4,80004ca8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bca:	0ac05d63          	blez	a2,80004c84 <filewrite+0xf4>
    int i = 0;
    80004bce:	4981                	li	s3,0
    80004bd0:	6b85                	lui	s7,0x1
    80004bd2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bd6:	6c05                	lui	s8,0x1
    80004bd8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bdc:	a861                	j	80004c74 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bde:	6908                	ld	a0,16(a0)
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	22e080e7          	jalr	558(ra) # 80004e0e <pipewrite>
    80004be8:	8a2a                	mv	s4,a0
    80004bea:	a045                	j	80004c8a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bec:	02451783          	lh	a5,36(a0)
    80004bf0:	03079693          	slli	a3,a5,0x30
    80004bf4:	92c1                	srli	a3,a3,0x30
    80004bf6:	4725                	li	a4,9
    80004bf8:	0cd76263          	bltu	a4,a3,80004cbc <filewrite+0x12c>
    80004bfc:	0792                	slli	a5,a5,0x4
    80004bfe:	0003c717          	auipc	a4,0x3c
    80004c02:	3b270713          	addi	a4,a4,946 # 80040fb0 <devsw>
    80004c06:	97ba                	add	a5,a5,a4
    80004c08:	679c                	ld	a5,8(a5)
    80004c0a:	cbdd                	beqz	a5,80004cc0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c0c:	4505                	li	a0,1
    80004c0e:	9782                	jalr	a5
    80004c10:	8a2a                	mv	s4,a0
    80004c12:	a8a5                	j	80004c8a <filewrite+0xfa>
    80004c14:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	8b4080e7          	jalr	-1868(ra) # 800044cc <begin_op>
      ilock(f->ip);
    80004c20:	01893503          	ld	a0,24(s2)
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	edc080e7          	jalr	-292(ra) # 80003b00 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c2c:	8756                	mv	a4,s5
    80004c2e:	02092683          	lw	a3,32(s2)
    80004c32:	01698633          	add	a2,s3,s6
    80004c36:	4585                	li	a1,1
    80004c38:	01893503          	ld	a0,24(s2)
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	270080e7          	jalr	624(ra) # 80003eac <writei>
    80004c44:	84aa                	mv	s1,a0
    80004c46:	00a05763          	blez	a0,80004c54 <filewrite+0xc4>
        f->off += r;
    80004c4a:	02092783          	lw	a5,32(s2)
    80004c4e:	9fa9                	addw	a5,a5,a0
    80004c50:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c54:	01893503          	ld	a0,24(s2)
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	f6a080e7          	jalr	-150(ra) # 80003bc2 <iunlock>
      end_op();
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	8ea080e7          	jalr	-1814(ra) # 8000454a <end_op>

      if(r != n1){
    80004c68:	009a9f63          	bne	s5,s1,80004c86 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c6c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c70:	0149db63          	bge	s3,s4,80004c86 <filewrite+0xf6>
      int n1 = n - i;
    80004c74:	413a04bb          	subw	s1,s4,s3
    80004c78:	0004879b          	sext.w	a5,s1
    80004c7c:	f8fbdce3          	bge	s7,a5,80004c14 <filewrite+0x84>
    80004c80:	84e2                	mv	s1,s8
    80004c82:	bf49                	j	80004c14 <filewrite+0x84>
    int i = 0;
    80004c84:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c86:	013a1f63          	bne	s4,s3,80004ca4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c8a:	8552                	mv	a0,s4
    80004c8c:	60a6                	ld	ra,72(sp)
    80004c8e:	6406                	ld	s0,64(sp)
    80004c90:	74e2                	ld	s1,56(sp)
    80004c92:	7942                	ld	s2,48(sp)
    80004c94:	79a2                	ld	s3,40(sp)
    80004c96:	7a02                	ld	s4,32(sp)
    80004c98:	6ae2                	ld	s5,24(sp)
    80004c9a:	6b42                	ld	s6,16(sp)
    80004c9c:	6ba2                	ld	s7,8(sp)
    80004c9e:	6c02                	ld	s8,0(sp)
    80004ca0:	6161                	addi	sp,sp,80
    80004ca2:	8082                	ret
    ret = (i == n ? n : -1);
    80004ca4:	5a7d                	li	s4,-1
    80004ca6:	b7d5                	j	80004c8a <filewrite+0xfa>
    panic("filewrite");
    80004ca8:	00004517          	auipc	a0,0x4
    80004cac:	9e050513          	addi	a0,a0,-1568 # 80008688 <syscalls+0x270>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	890080e7          	jalr	-1904(ra) # 80000540 <panic>
    return -1;
    80004cb8:	5a7d                	li	s4,-1
    80004cba:	bfc1                	j	80004c8a <filewrite+0xfa>
      return -1;
    80004cbc:	5a7d                	li	s4,-1
    80004cbe:	b7f1                	j	80004c8a <filewrite+0xfa>
    80004cc0:	5a7d                	li	s4,-1
    80004cc2:	b7e1                	j	80004c8a <filewrite+0xfa>

0000000080004cc4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cc4:	7179                	addi	sp,sp,-48
    80004cc6:	f406                	sd	ra,40(sp)
    80004cc8:	f022                	sd	s0,32(sp)
    80004cca:	ec26                	sd	s1,24(sp)
    80004ccc:	e84a                	sd	s2,16(sp)
    80004cce:	e44e                	sd	s3,8(sp)
    80004cd0:	e052                	sd	s4,0(sp)
    80004cd2:	1800                	addi	s0,sp,48
    80004cd4:	84aa                	mv	s1,a0
    80004cd6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cd8:	0005b023          	sd	zero,0(a1)
    80004cdc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	bf8080e7          	jalr	-1032(ra) # 800048d8 <filealloc>
    80004ce8:	e088                	sd	a0,0(s1)
    80004cea:	c551                	beqz	a0,80004d76 <pipealloc+0xb2>
    80004cec:	00000097          	auipc	ra,0x0
    80004cf0:	bec080e7          	jalr	-1044(ra) # 800048d8 <filealloc>
    80004cf4:	00aa3023          	sd	a0,0(s4)
    80004cf8:	c92d                	beqz	a0,80004d6a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	e94080e7          	jalr	-364(ra) # 80000b8e <kalloc>
    80004d02:	892a                	mv	s2,a0
    80004d04:	c125                	beqz	a0,80004d64 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d06:	4985                	li	s3,1
    80004d08:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d0c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d10:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d14:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d18:	00004597          	auipc	a1,0x4
    80004d1c:	98058593          	addi	a1,a1,-1664 # 80008698 <syscalls+0x280>
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	fac080e7          	jalr	-84(ra) # 80000ccc <initlock>
  (*f0)->type = FD_PIPE;
    80004d28:	609c                	ld	a5,0(s1)
    80004d2a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d2e:	609c                	ld	a5,0(s1)
    80004d30:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d34:	609c                	ld	a5,0(s1)
    80004d36:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d3a:	609c                	ld	a5,0(s1)
    80004d3c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d40:	000a3783          	ld	a5,0(s4)
    80004d44:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d48:	000a3783          	ld	a5,0(s4)
    80004d4c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d50:	000a3783          	ld	a5,0(s4)
    80004d54:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d58:	000a3783          	ld	a5,0(s4)
    80004d5c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d60:	4501                	li	a0,0
    80004d62:	a025                	j	80004d8a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d64:	6088                	ld	a0,0(s1)
    80004d66:	e501                	bnez	a0,80004d6e <pipealloc+0xaa>
    80004d68:	a039                	j	80004d76 <pipealloc+0xb2>
    80004d6a:	6088                	ld	a0,0(s1)
    80004d6c:	c51d                	beqz	a0,80004d9a <pipealloc+0xd6>
    fileclose(*f0);
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	c26080e7          	jalr	-986(ra) # 80004994 <fileclose>
  if(*f1)
    80004d76:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d7a:	557d                	li	a0,-1
  if(*f1)
    80004d7c:	c799                	beqz	a5,80004d8a <pipealloc+0xc6>
    fileclose(*f1);
    80004d7e:	853e                	mv	a0,a5
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	c14080e7          	jalr	-1004(ra) # 80004994 <fileclose>
  return -1;
    80004d88:	557d                	li	a0,-1
}
    80004d8a:	70a2                	ld	ra,40(sp)
    80004d8c:	7402                	ld	s0,32(sp)
    80004d8e:	64e2                	ld	s1,24(sp)
    80004d90:	6942                	ld	s2,16(sp)
    80004d92:	69a2                	ld	s3,8(sp)
    80004d94:	6a02                	ld	s4,0(sp)
    80004d96:	6145                	addi	sp,sp,48
    80004d98:	8082                	ret
  return -1;
    80004d9a:	557d                	li	a0,-1
    80004d9c:	b7fd                	j	80004d8a <pipealloc+0xc6>

0000000080004d9e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d9e:	1101                	addi	sp,sp,-32
    80004da0:	ec06                	sd	ra,24(sp)
    80004da2:	e822                	sd	s0,16(sp)
    80004da4:	e426                	sd	s1,8(sp)
    80004da6:	e04a                	sd	s2,0(sp)
    80004da8:	1000                	addi	s0,sp,32
    80004daa:	84aa                	mv	s1,a0
    80004dac:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	fae080e7          	jalr	-82(ra) # 80000d5c <acquire>
  if(writable){
    80004db6:	02090d63          	beqz	s2,80004df0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dba:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dbe:	21848513          	addi	a0,s1,536
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	4e8080e7          	jalr	1256(ra) # 800022aa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dca:	2204b783          	ld	a5,544(s1)
    80004dce:	eb95                	bnez	a5,80004e02 <pipeclose+0x64>
    release(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	03e080e7          	jalr	62(ra) # 80000e10 <release>
    kfree((char*)pi);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	c0c080e7          	jalr	-1012(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004de4:	60e2                	ld	ra,24(sp)
    80004de6:	6442                	ld	s0,16(sp)
    80004de8:	64a2                	ld	s1,8(sp)
    80004dea:	6902                	ld	s2,0(sp)
    80004dec:	6105                	addi	sp,sp,32
    80004dee:	8082                	ret
    pi->readopen = 0;
    80004df0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004df4:	21c48513          	addi	a0,s1,540
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	4b2080e7          	jalr	1202(ra) # 800022aa <wakeup>
    80004e00:	b7e9                	j	80004dca <pipeclose+0x2c>
    release(&pi->lock);
    80004e02:	8526                	mv	a0,s1
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	00c080e7          	jalr	12(ra) # 80000e10 <release>
}
    80004e0c:	bfe1                	j	80004de4 <pipeclose+0x46>

0000000080004e0e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e0e:	711d                	addi	sp,sp,-96
    80004e10:	ec86                	sd	ra,88(sp)
    80004e12:	e8a2                	sd	s0,80(sp)
    80004e14:	e4a6                	sd	s1,72(sp)
    80004e16:	e0ca                	sd	s2,64(sp)
    80004e18:	fc4e                	sd	s3,56(sp)
    80004e1a:	f852                	sd	s4,48(sp)
    80004e1c:	f456                	sd	s5,40(sp)
    80004e1e:	f05a                	sd	s6,32(sp)
    80004e20:	ec5e                	sd	s7,24(sp)
    80004e22:	e862                	sd	s8,16(sp)
    80004e24:	1080                	addi	s0,sp,96
    80004e26:	84aa                	mv	s1,a0
    80004e28:	8aae                	mv	s5,a1
    80004e2a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	d44080e7          	jalr	-700(ra) # 80001b70 <myproc>
    80004e34:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	f24080e7          	jalr	-220(ra) # 80000d5c <acquire>
  while(i < n){
    80004e40:	0b405663          	blez	s4,80004eec <pipewrite+0xde>
  int i = 0;
    80004e44:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e46:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e48:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e4c:	21c48b93          	addi	s7,s1,540
    80004e50:	a089                	j	80004e92 <pipewrite+0x84>
      release(&pi->lock);
    80004e52:	8526                	mv	a0,s1
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	fbc080e7          	jalr	-68(ra) # 80000e10 <release>
      return -1;
    80004e5c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e5e:	854a                	mv	a0,s2
    80004e60:	60e6                	ld	ra,88(sp)
    80004e62:	6446                	ld	s0,80(sp)
    80004e64:	64a6                	ld	s1,72(sp)
    80004e66:	6906                	ld	s2,64(sp)
    80004e68:	79e2                	ld	s3,56(sp)
    80004e6a:	7a42                	ld	s4,48(sp)
    80004e6c:	7aa2                	ld	s5,40(sp)
    80004e6e:	7b02                	ld	s6,32(sp)
    80004e70:	6be2                	ld	s7,24(sp)
    80004e72:	6c42                	ld	s8,16(sp)
    80004e74:	6125                	addi	sp,sp,96
    80004e76:	8082                	ret
      wakeup(&pi->nread);
    80004e78:	8562                	mv	a0,s8
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	430080e7          	jalr	1072(ra) # 800022aa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e82:	85a6                	mv	a1,s1
    80004e84:	855e                	mv	a0,s7
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	3c0080e7          	jalr	960(ra) # 80002246 <sleep>
  while(i < n){
    80004e8e:	07495063          	bge	s2,s4,80004eee <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e92:	2204a783          	lw	a5,544(s1)
    80004e96:	dfd5                	beqz	a5,80004e52 <pipewrite+0x44>
    80004e98:	854e                	mv	a0,s3
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	660080e7          	jalr	1632(ra) # 800024fa <killed>
    80004ea2:	f945                	bnez	a0,80004e52 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ea4:	2184a783          	lw	a5,536(s1)
    80004ea8:	21c4a703          	lw	a4,540(s1)
    80004eac:	2007879b          	addiw	a5,a5,512
    80004eb0:	fcf704e3          	beq	a4,a5,80004e78 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eb4:	4685                	li	a3,1
    80004eb6:	01590633          	add	a2,s2,s5
    80004eba:	faf40593          	addi	a1,s0,-81
    80004ebe:	0509b503          	ld	a0,80(s3)
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	9fa080e7          	jalr	-1542(ra) # 800018bc <copyin>
    80004eca:	03650263          	beq	a0,s6,80004eee <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ece:	21c4a783          	lw	a5,540(s1)
    80004ed2:	0017871b          	addiw	a4,a5,1
    80004ed6:	20e4ae23          	sw	a4,540(s1)
    80004eda:	1ff7f793          	andi	a5,a5,511
    80004ede:	97a6                	add	a5,a5,s1
    80004ee0:	faf44703          	lbu	a4,-81(s0)
    80004ee4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ee8:	2905                	addiw	s2,s2,1
    80004eea:	b755                	j	80004e8e <pipewrite+0x80>
  int i = 0;
    80004eec:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004eee:	21848513          	addi	a0,s1,536
    80004ef2:	ffffd097          	auipc	ra,0xffffd
    80004ef6:	3b8080e7          	jalr	952(ra) # 800022aa <wakeup>
  release(&pi->lock);
    80004efa:	8526                	mv	a0,s1
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	f14080e7          	jalr	-236(ra) # 80000e10 <release>
  return i;
    80004f04:	bfa9                	j	80004e5e <pipewrite+0x50>

0000000080004f06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f06:	715d                	addi	sp,sp,-80
    80004f08:	e486                	sd	ra,72(sp)
    80004f0a:	e0a2                	sd	s0,64(sp)
    80004f0c:	fc26                	sd	s1,56(sp)
    80004f0e:	f84a                	sd	s2,48(sp)
    80004f10:	f44e                	sd	s3,40(sp)
    80004f12:	f052                	sd	s4,32(sp)
    80004f14:	ec56                	sd	s5,24(sp)
    80004f16:	e85a                	sd	s6,16(sp)
    80004f18:	0880                	addi	s0,sp,80
    80004f1a:	84aa                	mv	s1,a0
    80004f1c:	892e                	mv	s2,a1
    80004f1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	c50080e7          	jalr	-944(ra) # 80001b70 <myproc>
    80004f28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f2a:	8526                	mv	a0,s1
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	e30080e7          	jalr	-464(ra) # 80000d5c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f34:	2184a703          	lw	a4,536(s1)
    80004f38:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f3c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f40:	02f71763          	bne	a4,a5,80004f6e <piperead+0x68>
    80004f44:	2244a783          	lw	a5,548(s1)
    80004f48:	c39d                	beqz	a5,80004f6e <piperead+0x68>
    if(killed(pr)){
    80004f4a:	8552                	mv	a0,s4
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	5ae080e7          	jalr	1454(ra) # 800024fa <killed>
    80004f54:	e949                	bnez	a0,80004fe6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f56:	85a6                	mv	a1,s1
    80004f58:	854e                	mv	a0,s3
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	2ec080e7          	jalr	748(ra) # 80002246 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f62:	2184a703          	lw	a4,536(s1)
    80004f66:	21c4a783          	lw	a5,540(s1)
    80004f6a:	fcf70de3          	beq	a4,a5,80004f44 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f70:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f72:	05505463          	blez	s5,80004fba <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f76:	2184a783          	lw	a5,536(s1)
    80004f7a:	21c4a703          	lw	a4,540(s1)
    80004f7e:	02f70e63          	beq	a4,a5,80004fba <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f82:	0017871b          	addiw	a4,a5,1
    80004f86:	20e4ac23          	sw	a4,536(s1)
    80004f8a:	1ff7f793          	andi	a5,a5,511
    80004f8e:	97a6                	add	a5,a5,s1
    80004f90:	0187c783          	lbu	a5,24(a5)
    80004f94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f98:	4685                	li	a3,1
    80004f9a:	fbf40613          	addi	a2,s0,-65
    80004f9e:	85ca                	mv	a1,s2
    80004fa0:	050a3503          	ld	a0,80(s4)
    80004fa4:	ffffd097          	auipc	ra,0xffffd
    80004fa8:	854080e7          	jalr	-1964(ra) # 800017f8 <copyout>
    80004fac:	01650763          	beq	a0,s6,80004fba <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fb0:	2985                	addiw	s3,s3,1
    80004fb2:	0905                	addi	s2,s2,1
    80004fb4:	fd3a91e3          	bne	s5,s3,80004f76 <piperead+0x70>
    80004fb8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fba:	21c48513          	addi	a0,s1,540
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	2ec080e7          	jalr	748(ra) # 800022aa <wakeup>
  release(&pi->lock);
    80004fc6:	8526                	mv	a0,s1
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	e48080e7          	jalr	-440(ra) # 80000e10 <release>
  return i;
}
    80004fd0:	854e                	mv	a0,s3
    80004fd2:	60a6                	ld	ra,72(sp)
    80004fd4:	6406                	ld	s0,64(sp)
    80004fd6:	74e2                	ld	s1,56(sp)
    80004fd8:	7942                	ld	s2,48(sp)
    80004fda:	79a2                	ld	s3,40(sp)
    80004fdc:	7a02                	ld	s4,32(sp)
    80004fde:	6ae2                	ld	s5,24(sp)
    80004fe0:	6b42                	ld	s6,16(sp)
    80004fe2:	6161                	addi	sp,sp,80
    80004fe4:	8082                	ret
      release(&pi->lock);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	e28080e7          	jalr	-472(ra) # 80000e10 <release>
      return -1;
    80004ff0:	59fd                	li	s3,-1
    80004ff2:	bff9                	j	80004fd0 <piperead+0xca>

0000000080004ff4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ff4:	1141                	addi	sp,sp,-16
    80004ff6:	e422                	sd	s0,8(sp)
    80004ff8:	0800                	addi	s0,sp,16
    80004ffa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ffc:	8905                	andi	a0,a0,1
    80004ffe:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005000:	8b89                	andi	a5,a5,2
    80005002:	c399                	beqz	a5,80005008 <flags2perm+0x14>
      perm |= PTE_W;
    80005004:	00456513          	ori	a0,a0,4
    return perm;
}
    80005008:	6422                	ld	s0,8(sp)
    8000500a:	0141                	addi	sp,sp,16
    8000500c:	8082                	ret

000000008000500e <exec>:

int
exec(char *path, char **argv)
{
    8000500e:	de010113          	addi	sp,sp,-544
    80005012:	20113c23          	sd	ra,536(sp)
    80005016:	20813823          	sd	s0,528(sp)
    8000501a:	20913423          	sd	s1,520(sp)
    8000501e:	21213023          	sd	s2,512(sp)
    80005022:	ffce                	sd	s3,504(sp)
    80005024:	fbd2                	sd	s4,496(sp)
    80005026:	f7d6                	sd	s5,488(sp)
    80005028:	f3da                	sd	s6,480(sp)
    8000502a:	efde                	sd	s7,472(sp)
    8000502c:	ebe2                	sd	s8,464(sp)
    8000502e:	e7e6                	sd	s9,456(sp)
    80005030:	e3ea                	sd	s10,448(sp)
    80005032:	ff6e                	sd	s11,440(sp)
    80005034:	1400                	addi	s0,sp,544
    80005036:	892a                	mv	s2,a0
    80005038:	dea43423          	sd	a0,-536(s0)
    8000503c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	b30080e7          	jalr	-1232(ra) # 80001b70 <myproc>
    80005048:	84aa                	mv	s1,a0

  begin_op();
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	482080e7          	jalr	1154(ra) # 800044cc <begin_op>

  if((ip = namei(path)) == 0){
    80005052:	854a                	mv	a0,s2
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	258080e7          	jalr	600(ra) # 800042ac <namei>
    8000505c:	c93d                	beqz	a0,800050d2 <exec+0xc4>
    8000505e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	aa0080e7          	jalr	-1376(ra) # 80003b00 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005068:	04000713          	li	a4,64
    8000506c:	4681                	li	a3,0
    8000506e:	e5040613          	addi	a2,s0,-432
    80005072:	4581                	li	a1,0
    80005074:	8556                	mv	a0,s5
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	d3e080e7          	jalr	-706(ra) # 80003db4 <readi>
    8000507e:	04000793          	li	a5,64
    80005082:	00f51a63          	bne	a0,a5,80005096 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005086:	e5042703          	lw	a4,-432(s0)
    8000508a:	464c47b7          	lui	a5,0x464c4
    8000508e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005092:	04f70663          	beq	a4,a5,800050de <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005096:	8556                	mv	a0,s5
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	cca080e7          	jalr	-822(ra) # 80003d62 <iunlockput>
    end_op();
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	4aa080e7          	jalr	1194(ra) # 8000454a <end_op>
  }
  return -1;
    800050a8:	557d                	li	a0,-1
}
    800050aa:	21813083          	ld	ra,536(sp)
    800050ae:	21013403          	ld	s0,528(sp)
    800050b2:	20813483          	ld	s1,520(sp)
    800050b6:	20013903          	ld	s2,512(sp)
    800050ba:	79fe                	ld	s3,504(sp)
    800050bc:	7a5e                	ld	s4,496(sp)
    800050be:	7abe                	ld	s5,488(sp)
    800050c0:	7b1e                	ld	s6,480(sp)
    800050c2:	6bfe                	ld	s7,472(sp)
    800050c4:	6c5e                	ld	s8,464(sp)
    800050c6:	6cbe                	ld	s9,456(sp)
    800050c8:	6d1e                	ld	s10,448(sp)
    800050ca:	7dfa                	ld	s11,440(sp)
    800050cc:	22010113          	addi	sp,sp,544
    800050d0:	8082                	ret
    end_op();
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	478080e7          	jalr	1144(ra) # 8000454a <end_op>
    return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	b7f9                	j	800050aa <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	b54080e7          	jalr	-1196(ra) # 80001c34 <proc_pagetable>
    800050e8:	8b2a                	mv	s6,a0
    800050ea:	d555                	beqz	a0,80005096 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ec:	e7042783          	lw	a5,-400(s0)
    800050f0:	e8845703          	lhu	a4,-376(s0)
    800050f4:	c735                	beqz	a4,80005160 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050f6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050fc:	6a05                	lui	s4,0x1
    800050fe:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005102:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005106:	6d85                	lui	s11,0x1
    80005108:	7d7d                	lui	s10,0xfffff
    8000510a:	ac3d                	j	80005348 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000510c:	00003517          	auipc	a0,0x3
    80005110:	59450513          	addi	a0,a0,1428 # 800086a0 <syscalls+0x288>
    80005114:	ffffb097          	auipc	ra,0xffffb
    80005118:	42c080e7          	jalr	1068(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000511c:	874a                	mv	a4,s2
    8000511e:	009c86bb          	addw	a3,s9,s1
    80005122:	4581                	li	a1,0
    80005124:	8556                	mv	a0,s5
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	c8e080e7          	jalr	-882(ra) # 80003db4 <readi>
    8000512e:	2501                	sext.w	a0,a0
    80005130:	1aa91963          	bne	s2,a0,800052e2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005134:	009d84bb          	addw	s1,s11,s1
    80005138:	013d09bb          	addw	s3,s10,s3
    8000513c:	1f74f663          	bgeu	s1,s7,80005328 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005140:	02049593          	slli	a1,s1,0x20
    80005144:	9181                	srli	a1,a1,0x20
    80005146:	95e2                	add	a1,a1,s8
    80005148:	855a                	mv	a0,s6
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	098080e7          	jalr	152(ra) # 800011e2 <walkaddr>
    80005152:	862a                	mv	a2,a0
    if(pa == 0)
    80005154:	dd45                	beqz	a0,8000510c <exec+0xfe>
      n = PGSIZE;
    80005156:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005158:	fd49f2e3          	bgeu	s3,s4,8000511c <exec+0x10e>
      n = sz - i;
    8000515c:	894e                	mv	s2,s3
    8000515e:	bf7d                	j	8000511c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005160:	4901                	li	s2,0
  iunlockput(ip);
    80005162:	8556                	mv	a0,s5
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	bfe080e7          	jalr	-1026(ra) # 80003d62 <iunlockput>
  end_op();
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	3de080e7          	jalr	990(ra) # 8000454a <end_op>
  p = myproc();
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	9fc080e7          	jalr	-1540(ra) # 80001b70 <myproc>
    8000517c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000517e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005182:	6785                	lui	a5,0x1
    80005184:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005186:	97ca                	add	a5,a5,s2
    80005188:	777d                	lui	a4,0xfffff
    8000518a:	8ff9                	and	a5,a5,a4
    8000518c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005190:	4691                	li	a3,4
    80005192:	6609                	lui	a2,0x2
    80005194:	963e                	add	a2,a2,a5
    80005196:	85be                	mv	a1,a5
    80005198:	855a                	mv	a0,s6
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	3fc080e7          	jalr	1020(ra) # 80001596 <uvmalloc>
    800051a2:	8c2a                	mv	s8,a0
  ip = 0;
    800051a4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051a6:	12050e63          	beqz	a0,800052e2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051aa:	75f9                	lui	a1,0xffffe
    800051ac:	95aa                	add	a1,a1,a0
    800051ae:	855a                	mv	a0,s6
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	616080e7          	jalr	1558(ra) # 800017c6 <uvmclear>
  stackbase = sp - PGSIZE;
    800051b8:	7afd                	lui	s5,0xfffff
    800051ba:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051bc:	df043783          	ld	a5,-528(s0)
    800051c0:	6388                	ld	a0,0(a5)
    800051c2:	c925                	beqz	a0,80005232 <exec+0x224>
    800051c4:	e9040993          	addi	s3,s0,-368
    800051c8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051cc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ce:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	e04080e7          	jalr	-508(ra) # 80000fd4 <strlen>
    800051d8:	0015079b          	addiw	a5,a0,1
    800051dc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051e0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051e4:	13596663          	bltu	s2,s5,80005310 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051e8:	df043d83          	ld	s11,-528(s0)
    800051ec:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051f0:	8552                	mv	a0,s4
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	de2080e7          	jalr	-542(ra) # 80000fd4 <strlen>
    800051fa:	0015069b          	addiw	a3,a0,1
    800051fe:	8652                	mv	a2,s4
    80005200:	85ca                	mv	a1,s2
    80005202:	855a                	mv	a0,s6
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	5f4080e7          	jalr	1524(ra) # 800017f8 <copyout>
    8000520c:	10054663          	bltz	a0,80005318 <exec+0x30a>
    ustack[argc] = sp;
    80005210:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005214:	0485                	addi	s1,s1,1
    80005216:	008d8793          	addi	a5,s11,8
    8000521a:	def43823          	sd	a5,-528(s0)
    8000521e:	008db503          	ld	a0,8(s11)
    80005222:	c911                	beqz	a0,80005236 <exec+0x228>
    if(argc >= MAXARG)
    80005224:	09a1                	addi	s3,s3,8
    80005226:	fb3c95e3          	bne	s9,s3,800051d0 <exec+0x1c2>
  sz = sz1;
    8000522a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000522e:	4a81                	li	s5,0
    80005230:	a84d                	j	800052e2 <exec+0x2d4>
  sp = sz;
    80005232:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005234:	4481                	li	s1,0
  ustack[argc] = 0;
    80005236:	00349793          	slli	a5,s1,0x3
    8000523a:	f9078793          	addi	a5,a5,-112
    8000523e:	97a2                	add	a5,a5,s0
    80005240:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005244:	00148693          	addi	a3,s1,1
    80005248:	068e                	slli	a3,a3,0x3
    8000524a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000524e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005252:	01597663          	bgeu	s2,s5,8000525e <exec+0x250>
  sz = sz1;
    80005256:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000525a:	4a81                	li	s5,0
    8000525c:	a059                	j	800052e2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000525e:	e9040613          	addi	a2,s0,-368
    80005262:	85ca                	mv	a1,s2
    80005264:	855a                	mv	a0,s6
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	592080e7          	jalr	1426(ra) # 800017f8 <copyout>
    8000526e:	0a054963          	bltz	a0,80005320 <exec+0x312>
  p->trapframe->a1 = sp;
    80005272:	058bb783          	ld	a5,88(s7)
    80005276:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000527a:	de843783          	ld	a5,-536(s0)
    8000527e:	0007c703          	lbu	a4,0(a5)
    80005282:	cf11                	beqz	a4,8000529e <exec+0x290>
    80005284:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005286:	02f00693          	li	a3,47
    8000528a:	a039                	j	80005298 <exec+0x28a>
      last = s+1;
    8000528c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005290:	0785                	addi	a5,a5,1
    80005292:	fff7c703          	lbu	a4,-1(a5)
    80005296:	c701                	beqz	a4,8000529e <exec+0x290>
    if(*s == '/')
    80005298:	fed71ce3          	bne	a4,a3,80005290 <exec+0x282>
    8000529c:	bfc5                	j	8000528c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000529e:	4641                	li	a2,16
    800052a0:	de843583          	ld	a1,-536(s0)
    800052a4:	158b8513          	addi	a0,s7,344
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	cfa080e7          	jalr	-774(ra) # 80000fa2 <safestrcpy>
  oldpagetable = p->pagetable;
    800052b0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800052b4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800052b8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052bc:	058bb783          	ld	a5,88(s7)
    800052c0:	e6843703          	ld	a4,-408(s0)
    800052c4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052c6:	058bb783          	ld	a5,88(s7)
    800052ca:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052ce:	85ea                	mv	a1,s10
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	a00080e7          	jalr	-1536(ra) # 80001cd0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052d8:	0004851b          	sext.w	a0,s1
    800052dc:	b3f9                	j	800050aa <exec+0x9c>
    800052de:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052e2:	df843583          	ld	a1,-520(s0)
    800052e6:	855a                	mv	a0,s6
    800052e8:	ffffd097          	auipc	ra,0xffffd
    800052ec:	9e8080e7          	jalr	-1560(ra) # 80001cd0 <proc_freepagetable>
  if(ip){
    800052f0:	da0a93e3          	bnez	s5,80005096 <exec+0x88>
  return -1;
    800052f4:	557d                	li	a0,-1
    800052f6:	bb55                	j	800050aa <exec+0x9c>
    800052f8:	df243c23          	sd	s2,-520(s0)
    800052fc:	b7dd                	j	800052e2 <exec+0x2d4>
    800052fe:	df243c23          	sd	s2,-520(s0)
    80005302:	b7c5                	j	800052e2 <exec+0x2d4>
    80005304:	df243c23          	sd	s2,-520(s0)
    80005308:	bfe9                	j	800052e2 <exec+0x2d4>
    8000530a:	df243c23          	sd	s2,-520(s0)
    8000530e:	bfd1                	j	800052e2 <exec+0x2d4>
  sz = sz1;
    80005310:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005314:	4a81                	li	s5,0
    80005316:	b7f1                	j	800052e2 <exec+0x2d4>
  sz = sz1;
    80005318:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000531c:	4a81                	li	s5,0
    8000531e:	b7d1                	j	800052e2 <exec+0x2d4>
  sz = sz1;
    80005320:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005324:	4a81                	li	s5,0
    80005326:	bf75                	j	800052e2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005328:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000532c:	e0843783          	ld	a5,-504(s0)
    80005330:	0017869b          	addiw	a3,a5,1
    80005334:	e0d43423          	sd	a3,-504(s0)
    80005338:	e0043783          	ld	a5,-512(s0)
    8000533c:	0387879b          	addiw	a5,a5,56
    80005340:	e8845703          	lhu	a4,-376(s0)
    80005344:	e0e6dfe3          	bge	a3,a4,80005162 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005348:	2781                	sext.w	a5,a5
    8000534a:	e0f43023          	sd	a5,-512(s0)
    8000534e:	03800713          	li	a4,56
    80005352:	86be                	mv	a3,a5
    80005354:	e1840613          	addi	a2,s0,-488
    80005358:	4581                	li	a1,0
    8000535a:	8556                	mv	a0,s5
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	a58080e7          	jalr	-1448(ra) # 80003db4 <readi>
    80005364:	03800793          	li	a5,56
    80005368:	f6f51be3          	bne	a0,a5,800052de <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000536c:	e1842783          	lw	a5,-488(s0)
    80005370:	4705                	li	a4,1
    80005372:	fae79de3          	bne	a5,a4,8000532c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005376:	e4043483          	ld	s1,-448(s0)
    8000537a:	e3843783          	ld	a5,-456(s0)
    8000537e:	f6f4ede3          	bltu	s1,a5,800052f8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005382:	e2843783          	ld	a5,-472(s0)
    80005386:	94be                	add	s1,s1,a5
    80005388:	f6f4ebe3          	bltu	s1,a5,800052fe <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000538c:	de043703          	ld	a4,-544(s0)
    80005390:	8ff9                	and	a5,a5,a4
    80005392:	fbad                	bnez	a5,80005304 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005394:	e1c42503          	lw	a0,-484(s0)
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	c5c080e7          	jalr	-932(ra) # 80004ff4 <flags2perm>
    800053a0:	86aa                	mv	a3,a0
    800053a2:	8626                	mv	a2,s1
    800053a4:	85ca                	mv	a1,s2
    800053a6:	855a                	mv	a0,s6
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	1ee080e7          	jalr	494(ra) # 80001596 <uvmalloc>
    800053b0:	dea43c23          	sd	a0,-520(s0)
    800053b4:	d939                	beqz	a0,8000530a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053b6:	e2843c03          	ld	s8,-472(s0)
    800053ba:	e2042c83          	lw	s9,-480(s0)
    800053be:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053c2:	f60b83e3          	beqz	s7,80005328 <exec+0x31a>
    800053c6:	89de                	mv	s3,s7
    800053c8:	4481                	li	s1,0
    800053ca:	bb9d                	j	80005140 <exec+0x132>

00000000800053cc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053cc:	7179                	addi	sp,sp,-48
    800053ce:	f406                	sd	ra,40(sp)
    800053d0:	f022                	sd	s0,32(sp)
    800053d2:	ec26                	sd	s1,24(sp)
    800053d4:	e84a                	sd	s2,16(sp)
    800053d6:	1800                	addi	s0,sp,48
    800053d8:	892e                	mv	s2,a1
    800053da:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053dc:	fdc40593          	addi	a1,s0,-36
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	b1a080e7          	jalr	-1254(ra) # 80002efa <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053e8:	fdc42703          	lw	a4,-36(s0)
    800053ec:	47bd                	li	a5,15
    800053ee:	02e7eb63          	bltu	a5,a4,80005424 <argfd+0x58>
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	77e080e7          	jalr	1918(ra) # 80001b70 <myproc>
    800053fa:	fdc42703          	lw	a4,-36(s0)
    800053fe:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffbced2>
    80005402:	078e                	slli	a5,a5,0x3
    80005404:	953e                	add	a0,a0,a5
    80005406:	611c                	ld	a5,0(a0)
    80005408:	c385                	beqz	a5,80005428 <argfd+0x5c>
    return -1;
  if(pfd)
    8000540a:	00090463          	beqz	s2,80005412 <argfd+0x46>
    *pfd = fd;
    8000540e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005412:	4501                	li	a0,0
  if(pf)
    80005414:	c091                	beqz	s1,80005418 <argfd+0x4c>
    *pf = f;
    80005416:	e09c                	sd	a5,0(s1)
}
    80005418:	70a2                	ld	ra,40(sp)
    8000541a:	7402                	ld	s0,32(sp)
    8000541c:	64e2                	ld	s1,24(sp)
    8000541e:	6942                	ld	s2,16(sp)
    80005420:	6145                	addi	sp,sp,48
    80005422:	8082                	ret
    return -1;
    80005424:	557d                	li	a0,-1
    80005426:	bfcd                	j	80005418 <argfd+0x4c>
    80005428:	557d                	li	a0,-1
    8000542a:	b7fd                	j	80005418 <argfd+0x4c>

000000008000542c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000542c:	1101                	addi	sp,sp,-32
    8000542e:	ec06                	sd	ra,24(sp)
    80005430:	e822                	sd	s0,16(sp)
    80005432:	e426                	sd	s1,8(sp)
    80005434:	1000                	addi	s0,sp,32
    80005436:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	738080e7          	jalr	1848(ra) # 80001b70 <myproc>
    80005440:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005442:	0d050793          	addi	a5,a0,208
    80005446:	4501                	li	a0,0
    80005448:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000544a:	6398                	ld	a4,0(a5)
    8000544c:	cb19                	beqz	a4,80005462 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000544e:	2505                	addiw	a0,a0,1
    80005450:	07a1                	addi	a5,a5,8
    80005452:	fed51ce3          	bne	a0,a3,8000544a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005456:	557d                	li	a0,-1
}
    80005458:	60e2                	ld	ra,24(sp)
    8000545a:	6442                	ld	s0,16(sp)
    8000545c:	64a2                	ld	s1,8(sp)
    8000545e:	6105                	addi	sp,sp,32
    80005460:	8082                	ret
      p->ofile[fd] = f;
    80005462:	01a50793          	addi	a5,a0,26
    80005466:	078e                	slli	a5,a5,0x3
    80005468:	963e                	add	a2,a2,a5
    8000546a:	e204                	sd	s1,0(a2)
      return fd;
    8000546c:	b7f5                	j	80005458 <fdalloc+0x2c>

000000008000546e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000546e:	715d                	addi	sp,sp,-80
    80005470:	e486                	sd	ra,72(sp)
    80005472:	e0a2                	sd	s0,64(sp)
    80005474:	fc26                	sd	s1,56(sp)
    80005476:	f84a                	sd	s2,48(sp)
    80005478:	f44e                	sd	s3,40(sp)
    8000547a:	f052                	sd	s4,32(sp)
    8000547c:	ec56                	sd	s5,24(sp)
    8000547e:	e85a                	sd	s6,16(sp)
    80005480:	0880                	addi	s0,sp,80
    80005482:	8b2e                	mv	s6,a1
    80005484:	89b2                	mv	s3,a2
    80005486:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005488:	fb040593          	addi	a1,s0,-80
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	e3e080e7          	jalr	-450(ra) # 800042ca <nameiparent>
    80005494:	84aa                	mv	s1,a0
    80005496:	14050f63          	beqz	a0,800055f4 <create+0x186>
    return 0;

  ilock(dp);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	666080e7          	jalr	1638(ra) # 80003b00 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054a2:	4601                	li	a2,0
    800054a4:	fb040593          	addi	a1,s0,-80
    800054a8:	8526                	mv	a0,s1
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	b3a080e7          	jalr	-1222(ra) # 80003fe4 <dirlookup>
    800054b2:	8aaa                	mv	s5,a0
    800054b4:	c931                	beqz	a0,80005508 <create+0x9a>
    iunlockput(dp);
    800054b6:	8526                	mv	a0,s1
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	8aa080e7          	jalr	-1878(ra) # 80003d62 <iunlockput>
    ilock(ip);
    800054c0:	8556                	mv	a0,s5
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	63e080e7          	jalr	1598(ra) # 80003b00 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054ca:	000b059b          	sext.w	a1,s6
    800054ce:	4789                	li	a5,2
    800054d0:	02f59563          	bne	a1,a5,800054fa <create+0x8c>
    800054d4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffbcefc>
    800054d8:	37f9                	addiw	a5,a5,-2
    800054da:	17c2                	slli	a5,a5,0x30
    800054dc:	93c1                	srli	a5,a5,0x30
    800054de:	4705                	li	a4,1
    800054e0:	00f76d63          	bltu	a4,a5,800054fa <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054e4:	8556                	mv	a0,s5
    800054e6:	60a6                	ld	ra,72(sp)
    800054e8:	6406                	ld	s0,64(sp)
    800054ea:	74e2                	ld	s1,56(sp)
    800054ec:	7942                	ld	s2,48(sp)
    800054ee:	79a2                	ld	s3,40(sp)
    800054f0:	7a02                	ld	s4,32(sp)
    800054f2:	6ae2                	ld	s5,24(sp)
    800054f4:	6b42                	ld	s6,16(sp)
    800054f6:	6161                	addi	sp,sp,80
    800054f8:	8082                	ret
    iunlockput(ip);
    800054fa:	8556                	mv	a0,s5
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	866080e7          	jalr	-1946(ra) # 80003d62 <iunlockput>
    return 0;
    80005504:	4a81                	li	s5,0
    80005506:	bff9                	j	800054e4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005508:	85da                	mv	a1,s6
    8000550a:	4088                	lw	a0,0(s1)
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	456080e7          	jalr	1110(ra) # 80003962 <ialloc>
    80005514:	8a2a                	mv	s4,a0
    80005516:	c539                	beqz	a0,80005564 <create+0xf6>
  ilock(ip);
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	5e8080e7          	jalr	1512(ra) # 80003b00 <ilock>
  ip->major = major;
    80005520:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005524:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005528:	4905                	li	s2,1
    8000552a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000552e:	8552                	mv	a0,s4
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	504080e7          	jalr	1284(ra) # 80003a34 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005538:	000b059b          	sext.w	a1,s6
    8000553c:	03258b63          	beq	a1,s2,80005572 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005540:	004a2603          	lw	a2,4(s4)
    80005544:	fb040593          	addi	a1,s0,-80
    80005548:	8526                	mv	a0,s1
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	cb0080e7          	jalr	-848(ra) # 800041fa <dirlink>
    80005552:	06054f63          	bltz	a0,800055d0 <create+0x162>
  iunlockput(dp);
    80005556:	8526                	mv	a0,s1
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	80a080e7          	jalr	-2038(ra) # 80003d62 <iunlockput>
  return ip;
    80005560:	8ad2                	mv	s5,s4
    80005562:	b749                	j	800054e4 <create+0x76>
    iunlockput(dp);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	7fc080e7          	jalr	2044(ra) # 80003d62 <iunlockput>
    return 0;
    8000556e:	8ad2                	mv	s5,s4
    80005570:	bf95                	j	800054e4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005572:	004a2603          	lw	a2,4(s4)
    80005576:	00003597          	auipc	a1,0x3
    8000557a:	14a58593          	addi	a1,a1,330 # 800086c0 <syscalls+0x2a8>
    8000557e:	8552                	mv	a0,s4
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	c7a080e7          	jalr	-902(ra) # 800041fa <dirlink>
    80005588:	04054463          	bltz	a0,800055d0 <create+0x162>
    8000558c:	40d0                	lw	a2,4(s1)
    8000558e:	00003597          	auipc	a1,0x3
    80005592:	13a58593          	addi	a1,a1,314 # 800086c8 <syscalls+0x2b0>
    80005596:	8552                	mv	a0,s4
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	c62080e7          	jalr	-926(ra) # 800041fa <dirlink>
    800055a0:	02054863          	bltz	a0,800055d0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800055a4:	004a2603          	lw	a2,4(s4)
    800055a8:	fb040593          	addi	a1,s0,-80
    800055ac:	8526                	mv	a0,s1
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	c4c080e7          	jalr	-948(ra) # 800041fa <dirlink>
    800055b6:	00054d63          	bltz	a0,800055d0 <create+0x162>
    dp->nlink++;  // for ".."
    800055ba:	04a4d783          	lhu	a5,74(s1)
    800055be:	2785                	addiw	a5,a5,1
    800055c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	46e080e7          	jalr	1134(ra) # 80003a34 <iupdate>
    800055ce:	b761                	j	80005556 <create+0xe8>
  ip->nlink = 0;
    800055d0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055d4:	8552                	mv	a0,s4
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	45e080e7          	jalr	1118(ra) # 80003a34 <iupdate>
  iunlockput(ip);
    800055de:	8552                	mv	a0,s4
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	782080e7          	jalr	1922(ra) # 80003d62 <iunlockput>
  iunlockput(dp);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	778080e7          	jalr	1912(ra) # 80003d62 <iunlockput>
  return 0;
    800055f2:	bdcd                	j	800054e4 <create+0x76>
    return 0;
    800055f4:	8aaa                	mv	s5,a0
    800055f6:	b5fd                	j	800054e4 <create+0x76>

00000000800055f8 <sys_dup>:
{
    800055f8:	7179                	addi	sp,sp,-48
    800055fa:	f406                	sd	ra,40(sp)
    800055fc:	f022                	sd	s0,32(sp)
    800055fe:	ec26                	sd	s1,24(sp)
    80005600:	e84a                	sd	s2,16(sp)
    80005602:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005604:	fd840613          	addi	a2,s0,-40
    80005608:	4581                	li	a1,0
    8000560a:	4501                	li	a0,0
    8000560c:	00000097          	auipc	ra,0x0
    80005610:	dc0080e7          	jalr	-576(ra) # 800053cc <argfd>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005616:	02054363          	bltz	a0,8000563c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000561a:	fd843903          	ld	s2,-40(s0)
    8000561e:	854a                	mv	a0,s2
    80005620:	00000097          	auipc	ra,0x0
    80005624:	e0c080e7          	jalr	-500(ra) # 8000542c <fdalloc>
    80005628:	84aa                	mv	s1,a0
    return -1;
    8000562a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000562c:	00054863          	bltz	a0,8000563c <sys_dup+0x44>
  filedup(f);
    80005630:	854a                	mv	a0,s2
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	310080e7          	jalr	784(ra) # 80004942 <filedup>
  return fd;
    8000563a:	87a6                	mv	a5,s1
}
    8000563c:	853e                	mv	a0,a5
    8000563e:	70a2                	ld	ra,40(sp)
    80005640:	7402                	ld	s0,32(sp)
    80005642:	64e2                	ld	s1,24(sp)
    80005644:	6942                	ld	s2,16(sp)
    80005646:	6145                	addi	sp,sp,48
    80005648:	8082                	ret

000000008000564a <sys_read>:
{
    8000564a:	7179                	addi	sp,sp,-48
    8000564c:	f406                	sd	ra,40(sp)
    8000564e:	f022                	sd	s0,32(sp)
    80005650:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005652:	fd840593          	addi	a1,s0,-40
    80005656:	4505                	li	a0,1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	8c2080e7          	jalr	-1854(ra) # 80002f1a <argaddr>
  argint(2, &n);
    80005660:	fe440593          	addi	a1,s0,-28
    80005664:	4509                	li	a0,2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	894080e7          	jalr	-1900(ra) # 80002efa <argint>
  if(argfd(0, 0, &f) < 0)
    8000566e:	fe840613          	addi	a2,s0,-24
    80005672:	4581                	li	a1,0
    80005674:	4501                	li	a0,0
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	d56080e7          	jalr	-682(ra) # 800053cc <argfd>
    8000567e:	87aa                	mv	a5,a0
    return -1;
    80005680:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005682:	0007cc63          	bltz	a5,8000569a <sys_read+0x50>
  return fileread(f, p, n);
    80005686:	fe442603          	lw	a2,-28(s0)
    8000568a:	fd843583          	ld	a1,-40(s0)
    8000568e:	fe843503          	ld	a0,-24(s0)
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	43c080e7          	jalr	1084(ra) # 80004ace <fileread>
}
    8000569a:	70a2                	ld	ra,40(sp)
    8000569c:	7402                	ld	s0,32(sp)
    8000569e:	6145                	addi	sp,sp,48
    800056a0:	8082                	ret

00000000800056a2 <sys_write>:
{
    800056a2:	7179                	addi	sp,sp,-48
    800056a4:	f406                	sd	ra,40(sp)
    800056a6:	f022                	sd	s0,32(sp)
    800056a8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056aa:	fd840593          	addi	a1,s0,-40
    800056ae:	4505                	li	a0,1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	86a080e7          	jalr	-1942(ra) # 80002f1a <argaddr>
  argint(2, &n);
    800056b8:	fe440593          	addi	a1,s0,-28
    800056bc:	4509                	li	a0,2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	83c080e7          	jalr	-1988(ra) # 80002efa <argint>
  if(argfd(0, 0, &f) < 0)
    800056c6:	fe840613          	addi	a2,s0,-24
    800056ca:	4581                	li	a1,0
    800056cc:	4501                	li	a0,0
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	cfe080e7          	jalr	-770(ra) # 800053cc <argfd>
    800056d6:	87aa                	mv	a5,a0
    return -1;
    800056d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056da:	0007cc63          	bltz	a5,800056f2 <sys_write+0x50>
  return filewrite(f, p, n);
    800056de:	fe442603          	lw	a2,-28(s0)
    800056e2:	fd843583          	ld	a1,-40(s0)
    800056e6:	fe843503          	ld	a0,-24(s0)
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	4a6080e7          	jalr	1190(ra) # 80004b90 <filewrite>
}
    800056f2:	70a2                	ld	ra,40(sp)
    800056f4:	7402                	ld	s0,32(sp)
    800056f6:	6145                	addi	sp,sp,48
    800056f8:	8082                	ret

00000000800056fa <sys_close>:
{
    800056fa:	1101                	addi	sp,sp,-32
    800056fc:	ec06                	sd	ra,24(sp)
    800056fe:	e822                	sd	s0,16(sp)
    80005700:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005702:	fe040613          	addi	a2,s0,-32
    80005706:	fec40593          	addi	a1,s0,-20
    8000570a:	4501                	li	a0,0
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	cc0080e7          	jalr	-832(ra) # 800053cc <argfd>
    return -1;
    80005714:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005716:	02054463          	bltz	a0,8000573e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000571a:	ffffc097          	auipc	ra,0xffffc
    8000571e:	456080e7          	jalr	1110(ra) # 80001b70 <myproc>
    80005722:	fec42783          	lw	a5,-20(s0)
    80005726:	07e9                	addi	a5,a5,26
    80005728:	078e                	slli	a5,a5,0x3
    8000572a:	953e                	add	a0,a0,a5
    8000572c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005730:	fe043503          	ld	a0,-32(s0)
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	260080e7          	jalr	608(ra) # 80004994 <fileclose>
  return 0;
    8000573c:	4781                	li	a5,0
}
    8000573e:	853e                	mv	a0,a5
    80005740:	60e2                	ld	ra,24(sp)
    80005742:	6442                	ld	s0,16(sp)
    80005744:	6105                	addi	sp,sp,32
    80005746:	8082                	ret

0000000080005748 <sys_fstat>:
{
    80005748:	1101                	addi	sp,sp,-32
    8000574a:	ec06                	sd	ra,24(sp)
    8000574c:	e822                	sd	s0,16(sp)
    8000574e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005750:	fe040593          	addi	a1,s0,-32
    80005754:	4505                	li	a0,1
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	7c4080e7          	jalr	1988(ra) # 80002f1a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000575e:	fe840613          	addi	a2,s0,-24
    80005762:	4581                	li	a1,0
    80005764:	4501                	li	a0,0
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	c66080e7          	jalr	-922(ra) # 800053cc <argfd>
    8000576e:	87aa                	mv	a5,a0
    return -1;
    80005770:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005772:	0007ca63          	bltz	a5,80005786 <sys_fstat+0x3e>
  return filestat(f, st);
    80005776:	fe043583          	ld	a1,-32(s0)
    8000577a:	fe843503          	ld	a0,-24(s0)
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	2de080e7          	jalr	734(ra) # 80004a5c <filestat>
}
    80005786:	60e2                	ld	ra,24(sp)
    80005788:	6442                	ld	s0,16(sp)
    8000578a:	6105                	addi	sp,sp,32
    8000578c:	8082                	ret

000000008000578e <sys_link>:
{
    8000578e:	7169                	addi	sp,sp,-304
    80005790:	f606                	sd	ra,296(sp)
    80005792:	f222                	sd	s0,288(sp)
    80005794:	ee26                	sd	s1,280(sp)
    80005796:	ea4a                	sd	s2,272(sp)
    80005798:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000579a:	08000613          	li	a2,128
    8000579e:	ed040593          	addi	a1,s0,-304
    800057a2:	4501                	li	a0,0
    800057a4:	ffffd097          	auipc	ra,0xffffd
    800057a8:	796080e7          	jalr	1942(ra) # 80002f3a <argstr>
    return -1;
    800057ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ae:	10054e63          	bltz	a0,800058ca <sys_link+0x13c>
    800057b2:	08000613          	li	a2,128
    800057b6:	f5040593          	addi	a1,s0,-176
    800057ba:	4505                	li	a0,1
    800057bc:	ffffd097          	auipc	ra,0xffffd
    800057c0:	77e080e7          	jalr	1918(ra) # 80002f3a <argstr>
    return -1;
    800057c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c6:	10054263          	bltz	a0,800058ca <sys_link+0x13c>
  begin_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	d02080e7          	jalr	-766(ra) # 800044cc <begin_op>
  if((ip = namei(old)) == 0){
    800057d2:	ed040513          	addi	a0,s0,-304
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	ad6080e7          	jalr	-1322(ra) # 800042ac <namei>
    800057de:	84aa                	mv	s1,a0
    800057e0:	c551                	beqz	a0,8000586c <sys_link+0xde>
  ilock(ip);
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	31e080e7          	jalr	798(ra) # 80003b00 <ilock>
  if(ip->type == T_DIR){
    800057ea:	04449703          	lh	a4,68(s1)
    800057ee:	4785                	li	a5,1
    800057f0:	08f70463          	beq	a4,a5,80005878 <sys_link+0xea>
  ip->nlink++;
    800057f4:	04a4d783          	lhu	a5,74(s1)
    800057f8:	2785                	addiw	a5,a5,1
    800057fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	234080e7          	jalr	564(ra) # 80003a34 <iupdate>
  iunlock(ip);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	3b8080e7          	jalr	952(ra) # 80003bc2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005812:	fd040593          	addi	a1,s0,-48
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	ab0080e7          	jalr	-1360(ra) # 800042ca <nameiparent>
    80005822:	892a                	mv	s2,a0
    80005824:	c935                	beqz	a0,80005898 <sys_link+0x10a>
  ilock(dp);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	2da080e7          	jalr	730(ra) # 80003b00 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000582e:	00092703          	lw	a4,0(s2)
    80005832:	409c                	lw	a5,0(s1)
    80005834:	04f71d63          	bne	a4,a5,8000588e <sys_link+0x100>
    80005838:	40d0                	lw	a2,4(s1)
    8000583a:	fd040593          	addi	a1,s0,-48
    8000583e:	854a                	mv	a0,s2
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	9ba080e7          	jalr	-1606(ra) # 800041fa <dirlink>
    80005848:	04054363          	bltz	a0,8000588e <sys_link+0x100>
  iunlockput(dp);
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	514080e7          	jalr	1300(ra) # 80003d62 <iunlockput>
  iput(ip);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	462080e7          	jalr	1122(ra) # 80003cba <iput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	cea080e7          	jalr	-790(ra) # 8000454a <end_op>
  return 0;
    80005868:	4781                	li	a5,0
    8000586a:	a085                	j	800058ca <sys_link+0x13c>
    end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	cde080e7          	jalr	-802(ra) # 8000454a <end_op>
    return -1;
    80005874:	57fd                	li	a5,-1
    80005876:	a891                	j	800058ca <sys_link+0x13c>
    iunlockput(ip);
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	4e8080e7          	jalr	1256(ra) # 80003d62 <iunlockput>
    end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	cc8080e7          	jalr	-824(ra) # 8000454a <end_op>
    return -1;
    8000588a:	57fd                	li	a5,-1
    8000588c:	a83d                	j	800058ca <sys_link+0x13c>
    iunlockput(dp);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	4d2080e7          	jalr	1234(ra) # 80003d62 <iunlockput>
  ilock(ip);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	266080e7          	jalr	614(ra) # 80003b00 <ilock>
  ip->nlink--;
    800058a2:	04a4d783          	lhu	a5,74(s1)
    800058a6:	37fd                	addiw	a5,a5,-1
    800058a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	186080e7          	jalr	390(ra) # 80003a34 <iupdate>
  iunlockput(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	4aa080e7          	jalr	1194(ra) # 80003d62 <iunlockput>
  end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	c8a080e7          	jalr	-886(ra) # 8000454a <end_op>
  return -1;
    800058c8:	57fd                	li	a5,-1
}
    800058ca:	853e                	mv	a0,a5
    800058cc:	70b2                	ld	ra,296(sp)
    800058ce:	7412                	ld	s0,288(sp)
    800058d0:	64f2                	ld	s1,280(sp)
    800058d2:	6952                	ld	s2,272(sp)
    800058d4:	6155                	addi	sp,sp,304
    800058d6:	8082                	ret

00000000800058d8 <sys_unlink>:
{
    800058d8:	7151                	addi	sp,sp,-240
    800058da:	f586                	sd	ra,232(sp)
    800058dc:	f1a2                	sd	s0,224(sp)
    800058de:	eda6                	sd	s1,216(sp)
    800058e0:	e9ca                	sd	s2,208(sp)
    800058e2:	e5ce                	sd	s3,200(sp)
    800058e4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058e6:	08000613          	li	a2,128
    800058ea:	f3040593          	addi	a1,s0,-208
    800058ee:	4501                	li	a0,0
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	64a080e7          	jalr	1610(ra) # 80002f3a <argstr>
    800058f8:	18054163          	bltz	a0,80005a7a <sys_unlink+0x1a2>
  begin_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	bd0080e7          	jalr	-1072(ra) # 800044cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005904:	fb040593          	addi	a1,s0,-80
    80005908:	f3040513          	addi	a0,s0,-208
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	9be080e7          	jalr	-1602(ra) # 800042ca <nameiparent>
    80005914:	84aa                	mv	s1,a0
    80005916:	c979                	beqz	a0,800059ec <sys_unlink+0x114>
  ilock(dp);
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	1e8080e7          	jalr	488(ra) # 80003b00 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005920:	00003597          	auipc	a1,0x3
    80005924:	da058593          	addi	a1,a1,-608 # 800086c0 <syscalls+0x2a8>
    80005928:	fb040513          	addi	a0,s0,-80
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	69e080e7          	jalr	1694(ra) # 80003fca <namecmp>
    80005934:	14050a63          	beqz	a0,80005a88 <sys_unlink+0x1b0>
    80005938:	00003597          	auipc	a1,0x3
    8000593c:	d9058593          	addi	a1,a1,-624 # 800086c8 <syscalls+0x2b0>
    80005940:	fb040513          	addi	a0,s0,-80
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	686080e7          	jalr	1670(ra) # 80003fca <namecmp>
    8000594c:	12050e63          	beqz	a0,80005a88 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005950:	f2c40613          	addi	a2,s0,-212
    80005954:	fb040593          	addi	a1,s0,-80
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	68a080e7          	jalr	1674(ra) # 80003fe4 <dirlookup>
    80005962:	892a                	mv	s2,a0
    80005964:	12050263          	beqz	a0,80005a88 <sys_unlink+0x1b0>
  ilock(ip);
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	198080e7          	jalr	408(ra) # 80003b00 <ilock>
  if(ip->nlink < 1)
    80005970:	04a91783          	lh	a5,74(s2)
    80005974:	08f05263          	blez	a5,800059f8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005978:	04491703          	lh	a4,68(s2)
    8000597c:	4785                	li	a5,1
    8000597e:	08f70563          	beq	a4,a5,80005a08 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005982:	4641                	li	a2,16
    80005984:	4581                	li	a1,0
    80005986:	fc040513          	addi	a0,s0,-64
    8000598a:	ffffb097          	auipc	ra,0xffffb
    8000598e:	4ce080e7          	jalr	1230(ra) # 80000e58 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005992:	4741                	li	a4,16
    80005994:	f2c42683          	lw	a3,-212(s0)
    80005998:	fc040613          	addi	a2,s0,-64
    8000599c:	4581                	li	a1,0
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	50c080e7          	jalr	1292(ra) # 80003eac <writei>
    800059a8:	47c1                	li	a5,16
    800059aa:	0af51563          	bne	a0,a5,80005a54 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059ae:	04491703          	lh	a4,68(s2)
    800059b2:	4785                	li	a5,1
    800059b4:	0af70863          	beq	a4,a5,80005a64 <sys_unlink+0x18c>
  iunlockput(dp);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	3a8080e7          	jalr	936(ra) # 80003d62 <iunlockput>
  ip->nlink--;
    800059c2:	04a95783          	lhu	a5,74(s2)
    800059c6:	37fd                	addiw	a5,a5,-1
    800059c8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	066080e7          	jalr	102(ra) # 80003a34 <iupdate>
  iunlockput(ip);
    800059d6:	854a                	mv	a0,s2
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	38a080e7          	jalr	906(ra) # 80003d62 <iunlockput>
  end_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	b6a080e7          	jalr	-1174(ra) # 8000454a <end_op>
  return 0;
    800059e8:	4501                	li	a0,0
    800059ea:	a84d                	j	80005a9c <sys_unlink+0x1c4>
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	b5e080e7          	jalr	-1186(ra) # 8000454a <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	a05d                	j	80005a9c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059f8:	00003517          	auipc	a0,0x3
    800059fc:	cd850513          	addi	a0,a0,-808 # 800086d0 <syscalls+0x2b8>
    80005a00:	ffffb097          	auipc	ra,0xffffb
    80005a04:	b40080e7          	jalr	-1216(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a08:	04c92703          	lw	a4,76(s2)
    80005a0c:	02000793          	li	a5,32
    80005a10:	f6e7f9e3          	bgeu	a5,a4,80005982 <sys_unlink+0xaa>
    80005a14:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a18:	4741                	li	a4,16
    80005a1a:	86ce                	mv	a3,s3
    80005a1c:	f1840613          	addi	a2,s0,-232
    80005a20:	4581                	li	a1,0
    80005a22:	854a                	mv	a0,s2
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	390080e7          	jalr	912(ra) # 80003db4 <readi>
    80005a2c:	47c1                	li	a5,16
    80005a2e:	00f51b63          	bne	a0,a5,80005a44 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a32:	f1845783          	lhu	a5,-232(s0)
    80005a36:	e7a1                	bnez	a5,80005a7e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a38:	29c1                	addiw	s3,s3,16
    80005a3a:	04c92783          	lw	a5,76(s2)
    80005a3e:	fcf9ede3          	bltu	s3,a5,80005a18 <sys_unlink+0x140>
    80005a42:	b781                	j	80005982 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a44:	00003517          	auipc	a0,0x3
    80005a48:	ca450513          	addi	a0,a0,-860 # 800086e8 <syscalls+0x2d0>
    80005a4c:	ffffb097          	auipc	ra,0xffffb
    80005a50:	af4080e7          	jalr	-1292(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a54:	00003517          	auipc	a0,0x3
    80005a58:	cac50513          	addi	a0,a0,-852 # 80008700 <syscalls+0x2e8>
    80005a5c:	ffffb097          	auipc	ra,0xffffb
    80005a60:	ae4080e7          	jalr	-1308(ra) # 80000540 <panic>
    dp->nlink--;
    80005a64:	04a4d783          	lhu	a5,74(s1)
    80005a68:	37fd                	addiw	a5,a5,-1
    80005a6a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	fc4080e7          	jalr	-60(ra) # 80003a34 <iupdate>
    80005a78:	b781                	j	800059b8 <sys_unlink+0xe0>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	a005                	j	80005a9c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	2e2080e7          	jalr	738(ra) # 80003d62 <iunlockput>
  iunlockput(dp);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	2d8080e7          	jalr	728(ra) # 80003d62 <iunlockput>
  end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	ab8080e7          	jalr	-1352(ra) # 8000454a <end_op>
  return -1;
    80005a9a:	557d                	li	a0,-1
}
    80005a9c:	70ae                	ld	ra,232(sp)
    80005a9e:	740e                	ld	s0,224(sp)
    80005aa0:	64ee                	ld	s1,216(sp)
    80005aa2:	694e                	ld	s2,208(sp)
    80005aa4:	69ae                	ld	s3,200(sp)
    80005aa6:	616d                	addi	sp,sp,240
    80005aa8:	8082                	ret

0000000080005aaa <sys_open>:

uint64
sys_open(void)
{
    80005aaa:	7131                	addi	sp,sp,-192
    80005aac:	fd06                	sd	ra,184(sp)
    80005aae:	f922                	sd	s0,176(sp)
    80005ab0:	f526                	sd	s1,168(sp)
    80005ab2:	f14a                	sd	s2,160(sp)
    80005ab4:	ed4e                	sd	s3,152(sp)
    80005ab6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ab8:	f4c40593          	addi	a1,s0,-180
    80005abc:	4505                	li	a0,1
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	43c080e7          	jalr	1084(ra) # 80002efa <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ac6:	08000613          	li	a2,128
    80005aca:	f5040593          	addi	a1,s0,-176
    80005ace:	4501                	li	a0,0
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	46a080e7          	jalr	1130(ra) # 80002f3a <argstr>
    80005ad8:	87aa                	mv	a5,a0
    return -1;
    80005ada:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005adc:	0a07c963          	bltz	a5,80005b8e <sys_open+0xe4>

  begin_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	9ec080e7          	jalr	-1556(ra) # 800044cc <begin_op>

  if(omode & O_CREATE){
    80005ae8:	f4c42783          	lw	a5,-180(s0)
    80005aec:	2007f793          	andi	a5,a5,512
    80005af0:	cfc5                	beqz	a5,80005ba8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005af2:	4681                	li	a3,0
    80005af4:	4601                	li	a2,0
    80005af6:	4589                	li	a1,2
    80005af8:	f5040513          	addi	a0,s0,-176
    80005afc:	00000097          	auipc	ra,0x0
    80005b00:	972080e7          	jalr	-1678(ra) # 8000546e <create>
    80005b04:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b06:	c959                	beqz	a0,80005b9c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	478d                	li	a5,3
    80005b0e:	00f71763          	bne	a4,a5,80005b1c <sys_open+0x72>
    80005b12:	0464d703          	lhu	a4,70(s1)
    80005b16:	47a5                	li	a5,9
    80005b18:	0ce7ed63          	bltu	a5,a4,80005bf2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	dbc080e7          	jalr	-580(ra) # 800048d8 <filealloc>
    80005b24:	89aa                	mv	s3,a0
    80005b26:	10050363          	beqz	a0,80005c2c <sys_open+0x182>
    80005b2a:	00000097          	auipc	ra,0x0
    80005b2e:	902080e7          	jalr	-1790(ra) # 8000542c <fdalloc>
    80005b32:	892a                	mv	s2,a0
    80005b34:	0e054763          	bltz	a0,80005c22 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b38:	04449703          	lh	a4,68(s1)
    80005b3c:	478d                	li	a5,3
    80005b3e:	0cf70563          	beq	a4,a5,80005c08 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b42:	4789                	li	a5,2
    80005b44:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b48:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b4c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b50:	f4c42783          	lw	a5,-180(s0)
    80005b54:	0017c713          	xori	a4,a5,1
    80005b58:	8b05                	andi	a4,a4,1
    80005b5a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b5e:	0037f713          	andi	a4,a5,3
    80005b62:	00e03733          	snez	a4,a4
    80005b66:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b6a:	4007f793          	andi	a5,a5,1024
    80005b6e:	c791                	beqz	a5,80005b7a <sys_open+0xd0>
    80005b70:	04449703          	lh	a4,68(s1)
    80005b74:	4789                	li	a5,2
    80005b76:	0af70063          	beq	a4,a5,80005c16 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	046080e7          	jalr	70(ra) # 80003bc2 <iunlock>
  end_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	9c6080e7          	jalr	-1594(ra) # 8000454a <end_op>

  return fd;
    80005b8c:	854a                	mv	a0,s2
}
    80005b8e:	70ea                	ld	ra,184(sp)
    80005b90:	744a                	ld	s0,176(sp)
    80005b92:	74aa                	ld	s1,168(sp)
    80005b94:	790a                	ld	s2,160(sp)
    80005b96:	69ea                	ld	s3,152(sp)
    80005b98:	6129                	addi	sp,sp,192
    80005b9a:	8082                	ret
      end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	9ae080e7          	jalr	-1618(ra) # 8000454a <end_op>
      return -1;
    80005ba4:	557d                	li	a0,-1
    80005ba6:	b7e5                	j	80005b8e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ba8:	f5040513          	addi	a0,s0,-176
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	700080e7          	jalr	1792(ra) # 800042ac <namei>
    80005bb4:	84aa                	mv	s1,a0
    80005bb6:	c905                	beqz	a0,80005be6 <sys_open+0x13c>
    ilock(ip);
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	f48080e7          	jalr	-184(ra) # 80003b00 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bc0:	04449703          	lh	a4,68(s1)
    80005bc4:	4785                	li	a5,1
    80005bc6:	f4f711e3          	bne	a4,a5,80005b08 <sys_open+0x5e>
    80005bca:	f4c42783          	lw	a5,-180(s0)
    80005bce:	d7b9                	beqz	a5,80005b1c <sys_open+0x72>
      iunlockput(ip);
    80005bd0:	8526                	mv	a0,s1
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	190080e7          	jalr	400(ra) # 80003d62 <iunlockput>
      end_op();
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	970080e7          	jalr	-1680(ra) # 8000454a <end_op>
      return -1;
    80005be2:	557d                	li	a0,-1
    80005be4:	b76d                	j	80005b8e <sys_open+0xe4>
      end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	964080e7          	jalr	-1692(ra) # 8000454a <end_op>
      return -1;
    80005bee:	557d                	li	a0,-1
    80005bf0:	bf79                	j	80005b8e <sys_open+0xe4>
    iunlockput(ip);
    80005bf2:	8526                	mv	a0,s1
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	16e080e7          	jalr	366(ra) # 80003d62 <iunlockput>
    end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	94e080e7          	jalr	-1714(ra) # 8000454a <end_op>
    return -1;
    80005c04:	557d                	li	a0,-1
    80005c06:	b761                	j	80005b8e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c08:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c0c:	04649783          	lh	a5,70(s1)
    80005c10:	02f99223          	sh	a5,36(s3)
    80005c14:	bf25                	j	80005b4c <sys_open+0xa2>
    itrunc(ip);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	ff6080e7          	jalr	-10(ra) # 80003c0e <itrunc>
    80005c20:	bfa9                	j	80005b7a <sys_open+0xd0>
      fileclose(f);
    80005c22:	854e                	mv	a0,s3
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	d70080e7          	jalr	-656(ra) # 80004994 <fileclose>
    iunlockput(ip);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	134080e7          	jalr	308(ra) # 80003d62 <iunlockput>
    end_op();
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	914080e7          	jalr	-1772(ra) # 8000454a <end_op>
    return -1;
    80005c3e:	557d                	li	a0,-1
    80005c40:	b7b9                	j	80005b8e <sys_open+0xe4>

0000000080005c42 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c42:	7175                	addi	sp,sp,-144
    80005c44:	e506                	sd	ra,136(sp)
    80005c46:	e122                	sd	s0,128(sp)
    80005c48:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	882080e7          	jalr	-1918(ra) # 800044cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c52:	08000613          	li	a2,128
    80005c56:	f7040593          	addi	a1,s0,-144
    80005c5a:	4501                	li	a0,0
    80005c5c:	ffffd097          	auipc	ra,0xffffd
    80005c60:	2de080e7          	jalr	734(ra) # 80002f3a <argstr>
    80005c64:	02054963          	bltz	a0,80005c96 <sys_mkdir+0x54>
    80005c68:	4681                	li	a3,0
    80005c6a:	4601                	li	a2,0
    80005c6c:	4585                	li	a1,1
    80005c6e:	f7040513          	addi	a0,s0,-144
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	7fc080e7          	jalr	2044(ra) # 8000546e <create>
    80005c7a:	cd11                	beqz	a0,80005c96 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	0e6080e7          	jalr	230(ra) # 80003d62 <iunlockput>
  end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	8c6080e7          	jalr	-1850(ra) # 8000454a <end_op>
  return 0;
    80005c8c:	4501                	li	a0,0
}
    80005c8e:	60aa                	ld	ra,136(sp)
    80005c90:	640a                	ld	s0,128(sp)
    80005c92:	6149                	addi	sp,sp,144
    80005c94:	8082                	ret
    end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	8b4080e7          	jalr	-1868(ra) # 8000454a <end_op>
    return -1;
    80005c9e:	557d                	li	a0,-1
    80005ca0:	b7fd                	j	80005c8e <sys_mkdir+0x4c>

0000000080005ca2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ca2:	7135                	addi	sp,sp,-160
    80005ca4:	ed06                	sd	ra,152(sp)
    80005ca6:	e922                	sd	s0,144(sp)
    80005ca8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	822080e7          	jalr	-2014(ra) # 800044cc <begin_op>
  argint(1, &major);
    80005cb2:	f6c40593          	addi	a1,s0,-148
    80005cb6:	4505                	li	a0,1
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	242080e7          	jalr	578(ra) # 80002efa <argint>
  argint(2, &minor);
    80005cc0:	f6840593          	addi	a1,s0,-152
    80005cc4:	4509                	li	a0,2
    80005cc6:	ffffd097          	auipc	ra,0xffffd
    80005cca:	234080e7          	jalr	564(ra) # 80002efa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cce:	08000613          	li	a2,128
    80005cd2:	f7040593          	addi	a1,s0,-144
    80005cd6:	4501                	li	a0,0
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	262080e7          	jalr	610(ra) # 80002f3a <argstr>
    80005ce0:	02054b63          	bltz	a0,80005d16 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ce4:	f6841683          	lh	a3,-152(s0)
    80005ce8:	f6c41603          	lh	a2,-148(s0)
    80005cec:	458d                	li	a1,3
    80005cee:	f7040513          	addi	a0,s0,-144
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	77c080e7          	jalr	1916(ra) # 8000546e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cfa:	cd11                	beqz	a0,80005d16 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	066080e7          	jalr	102(ra) # 80003d62 <iunlockput>
  end_op();
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	846080e7          	jalr	-1978(ra) # 8000454a <end_op>
  return 0;
    80005d0c:	4501                	li	a0,0
}
    80005d0e:	60ea                	ld	ra,152(sp)
    80005d10:	644a                	ld	s0,144(sp)
    80005d12:	610d                	addi	sp,sp,160
    80005d14:	8082                	ret
    end_op();
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	834080e7          	jalr	-1996(ra) # 8000454a <end_op>
    return -1;
    80005d1e:	557d                	li	a0,-1
    80005d20:	b7fd                	j	80005d0e <sys_mknod+0x6c>

0000000080005d22 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d22:	7135                	addi	sp,sp,-160
    80005d24:	ed06                	sd	ra,152(sp)
    80005d26:	e922                	sd	s0,144(sp)
    80005d28:	e526                	sd	s1,136(sp)
    80005d2a:	e14a                	sd	s2,128(sp)
    80005d2c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d2e:	ffffc097          	auipc	ra,0xffffc
    80005d32:	e42080e7          	jalr	-446(ra) # 80001b70 <myproc>
    80005d36:	892a                	mv	s2,a0
  
  begin_op();
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	794080e7          	jalr	1940(ra) # 800044cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d40:	08000613          	li	a2,128
    80005d44:	f6040593          	addi	a1,s0,-160
    80005d48:	4501                	li	a0,0
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	1f0080e7          	jalr	496(ra) # 80002f3a <argstr>
    80005d52:	04054b63          	bltz	a0,80005da8 <sys_chdir+0x86>
    80005d56:	f6040513          	addi	a0,s0,-160
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	552080e7          	jalr	1362(ra) # 800042ac <namei>
    80005d62:	84aa                	mv	s1,a0
    80005d64:	c131                	beqz	a0,80005da8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	d9a080e7          	jalr	-614(ra) # 80003b00 <ilock>
  if(ip->type != T_DIR){
    80005d6e:	04449703          	lh	a4,68(s1)
    80005d72:	4785                	li	a5,1
    80005d74:	04f71063          	bne	a4,a5,80005db4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d78:	8526                	mv	a0,s1
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	e48080e7          	jalr	-440(ra) # 80003bc2 <iunlock>
  iput(p->cwd);
    80005d82:	15093503          	ld	a0,336(s2)
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	f34080e7          	jalr	-204(ra) # 80003cba <iput>
  end_op();
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	7bc080e7          	jalr	1980(ra) # 8000454a <end_op>
  p->cwd = ip;
    80005d96:	14993823          	sd	s1,336(s2)
  return 0;
    80005d9a:	4501                	li	a0,0
}
    80005d9c:	60ea                	ld	ra,152(sp)
    80005d9e:	644a                	ld	s0,144(sp)
    80005da0:	64aa                	ld	s1,136(sp)
    80005da2:	690a                	ld	s2,128(sp)
    80005da4:	610d                	addi	sp,sp,160
    80005da6:	8082                	ret
    end_op();
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	7a2080e7          	jalr	1954(ra) # 8000454a <end_op>
    return -1;
    80005db0:	557d                	li	a0,-1
    80005db2:	b7ed                	j	80005d9c <sys_chdir+0x7a>
    iunlockput(ip);
    80005db4:	8526                	mv	a0,s1
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	fac080e7          	jalr	-84(ra) # 80003d62 <iunlockput>
    end_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	78c080e7          	jalr	1932(ra) # 8000454a <end_op>
    return -1;
    80005dc6:	557d                	li	a0,-1
    80005dc8:	bfd1                	j	80005d9c <sys_chdir+0x7a>

0000000080005dca <sys_exec>:

uint64
sys_exec(void)
{
    80005dca:	7145                	addi	sp,sp,-464
    80005dcc:	e786                	sd	ra,456(sp)
    80005dce:	e3a2                	sd	s0,448(sp)
    80005dd0:	ff26                	sd	s1,440(sp)
    80005dd2:	fb4a                	sd	s2,432(sp)
    80005dd4:	f74e                	sd	s3,424(sp)
    80005dd6:	f352                	sd	s4,416(sp)
    80005dd8:	ef56                	sd	s5,408(sp)
    80005dda:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ddc:	e3840593          	addi	a1,s0,-456
    80005de0:	4505                	li	a0,1
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	138080e7          	jalr	312(ra) # 80002f1a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005dea:	08000613          	li	a2,128
    80005dee:	f4040593          	addi	a1,s0,-192
    80005df2:	4501                	li	a0,0
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	146080e7          	jalr	326(ra) # 80002f3a <argstr>
    80005dfc:	87aa                	mv	a5,a0
    return -1;
    80005dfe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e00:	0c07c363          	bltz	a5,80005ec6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e04:	10000613          	li	a2,256
    80005e08:	4581                	li	a1,0
    80005e0a:	e4040513          	addi	a0,s0,-448
    80005e0e:	ffffb097          	auipc	ra,0xffffb
    80005e12:	04a080e7          	jalr	74(ra) # 80000e58 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e16:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e1a:	89a6                	mv	s3,s1
    80005e1c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e1e:	02000a13          	li	s4,32
    80005e22:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e26:	00391513          	slli	a0,s2,0x3
    80005e2a:	e3040593          	addi	a1,s0,-464
    80005e2e:	e3843783          	ld	a5,-456(s0)
    80005e32:	953e                	add	a0,a0,a5
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	028080e7          	jalr	40(ra) # 80002e5c <fetchaddr>
    80005e3c:	02054a63          	bltz	a0,80005e70 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e40:	e3043783          	ld	a5,-464(s0)
    80005e44:	c3b9                	beqz	a5,80005e8a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e46:	ffffb097          	auipc	ra,0xffffb
    80005e4a:	d48080e7          	jalr	-696(ra) # 80000b8e <kalloc>
    80005e4e:	85aa                	mv	a1,a0
    80005e50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e54:	cd11                	beqz	a0,80005e70 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e56:	6605                	lui	a2,0x1
    80005e58:	e3043503          	ld	a0,-464(s0)
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	052080e7          	jalr	82(ra) # 80002eae <fetchstr>
    80005e64:	00054663          	bltz	a0,80005e70 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e68:	0905                	addi	s2,s2,1
    80005e6a:	09a1                	addi	s3,s3,8
    80005e6c:	fb491be3          	bne	s2,s4,80005e22 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e70:	f4040913          	addi	s2,s0,-192
    80005e74:	6088                	ld	a0,0(s1)
    80005e76:	c539                	beqz	a0,80005ec4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e78:	ffffb097          	auipc	ra,0xffffb
    80005e7c:	b70080e7          	jalr	-1168(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e80:	04a1                	addi	s1,s1,8
    80005e82:	ff2499e3          	bne	s1,s2,80005e74 <sys_exec+0xaa>
  return -1;
    80005e86:	557d                	li	a0,-1
    80005e88:	a83d                	j	80005ec6 <sys_exec+0xfc>
      argv[i] = 0;
    80005e8a:	0a8e                	slli	s5,s5,0x3
    80005e8c:	fc0a8793          	addi	a5,s5,-64
    80005e90:	00878ab3          	add	s5,a5,s0
    80005e94:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e98:	e4040593          	addi	a1,s0,-448
    80005e9c:	f4040513          	addi	a0,s0,-192
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	16e080e7          	jalr	366(ra) # 8000500e <exec>
    80005ea8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eaa:	f4040993          	addi	s3,s0,-192
    80005eae:	6088                	ld	a0,0(s1)
    80005eb0:	c901                	beqz	a0,80005ec0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	b36080e7          	jalr	-1226(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eba:	04a1                	addi	s1,s1,8
    80005ebc:	ff3499e3          	bne	s1,s3,80005eae <sys_exec+0xe4>
  return ret;
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	a011                	j	80005ec6 <sys_exec+0xfc>
  return -1;
    80005ec4:	557d                	li	a0,-1
}
    80005ec6:	60be                	ld	ra,456(sp)
    80005ec8:	641e                	ld	s0,448(sp)
    80005eca:	74fa                	ld	s1,440(sp)
    80005ecc:	795a                	ld	s2,432(sp)
    80005ece:	79ba                	ld	s3,424(sp)
    80005ed0:	7a1a                	ld	s4,416(sp)
    80005ed2:	6afa                	ld	s5,408(sp)
    80005ed4:	6179                	addi	sp,sp,464
    80005ed6:	8082                	ret

0000000080005ed8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ed8:	7139                	addi	sp,sp,-64
    80005eda:	fc06                	sd	ra,56(sp)
    80005edc:	f822                	sd	s0,48(sp)
    80005ede:	f426                	sd	s1,40(sp)
    80005ee0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ee2:	ffffc097          	auipc	ra,0xffffc
    80005ee6:	c8e080e7          	jalr	-882(ra) # 80001b70 <myproc>
    80005eea:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005eec:	fd840593          	addi	a1,s0,-40
    80005ef0:	4501                	li	a0,0
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	028080e7          	jalr	40(ra) # 80002f1a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005efa:	fc840593          	addi	a1,s0,-56
    80005efe:	fd040513          	addi	a0,s0,-48
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	dc2080e7          	jalr	-574(ra) # 80004cc4 <pipealloc>
    return -1;
    80005f0a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f0c:	0c054463          	bltz	a0,80005fd4 <sys_pipe+0xfc>
  fd0 = -1;
    80005f10:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f14:	fd043503          	ld	a0,-48(s0)
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	514080e7          	jalr	1300(ra) # 8000542c <fdalloc>
    80005f20:	fca42223          	sw	a0,-60(s0)
    80005f24:	08054b63          	bltz	a0,80005fba <sys_pipe+0xe2>
    80005f28:	fc843503          	ld	a0,-56(s0)
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	500080e7          	jalr	1280(ra) # 8000542c <fdalloc>
    80005f34:	fca42023          	sw	a0,-64(s0)
    80005f38:	06054863          	bltz	a0,80005fa8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f3c:	4691                	li	a3,4
    80005f3e:	fc440613          	addi	a2,s0,-60
    80005f42:	fd843583          	ld	a1,-40(s0)
    80005f46:	68a8                	ld	a0,80(s1)
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	8b0080e7          	jalr	-1872(ra) # 800017f8 <copyout>
    80005f50:	02054063          	bltz	a0,80005f70 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f54:	4691                	li	a3,4
    80005f56:	fc040613          	addi	a2,s0,-64
    80005f5a:	fd843583          	ld	a1,-40(s0)
    80005f5e:	0591                	addi	a1,a1,4
    80005f60:	68a8                	ld	a0,80(s1)
    80005f62:	ffffc097          	auipc	ra,0xffffc
    80005f66:	896080e7          	jalr	-1898(ra) # 800017f8 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f6a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f6c:	06055463          	bgez	a0,80005fd4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f70:	fc442783          	lw	a5,-60(s0)
    80005f74:	07e9                	addi	a5,a5,26
    80005f76:	078e                	slli	a5,a5,0x3
    80005f78:	97a6                	add	a5,a5,s1
    80005f7a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f7e:	fc042783          	lw	a5,-64(s0)
    80005f82:	07e9                	addi	a5,a5,26
    80005f84:	078e                	slli	a5,a5,0x3
    80005f86:	94be                	add	s1,s1,a5
    80005f88:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f8c:	fd043503          	ld	a0,-48(s0)
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	a04080e7          	jalr	-1532(ra) # 80004994 <fileclose>
    fileclose(wf);
    80005f98:	fc843503          	ld	a0,-56(s0)
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	9f8080e7          	jalr	-1544(ra) # 80004994 <fileclose>
    return -1;
    80005fa4:	57fd                	li	a5,-1
    80005fa6:	a03d                	j	80005fd4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fa8:	fc442783          	lw	a5,-60(s0)
    80005fac:	0007c763          	bltz	a5,80005fba <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fb0:	07e9                	addi	a5,a5,26
    80005fb2:	078e                	slli	a5,a5,0x3
    80005fb4:	97a6                	add	a5,a5,s1
    80005fb6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005fba:	fd043503          	ld	a0,-48(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	9d6080e7          	jalr	-1578(ra) # 80004994 <fileclose>
    fileclose(wf);
    80005fc6:	fc843503          	ld	a0,-56(s0)
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	9ca080e7          	jalr	-1590(ra) # 80004994 <fileclose>
    return -1;
    80005fd2:	57fd                	li	a5,-1
}
    80005fd4:	853e                	mv	a0,a5
    80005fd6:	70e2                	ld	ra,56(sp)
    80005fd8:	7442                	ld	s0,48(sp)
    80005fda:	74a2                	ld	s1,40(sp)
    80005fdc:	6121                	addi	sp,sp,64
    80005fde:	8082                	ret

0000000080005fe0 <kernelvec>:
    80005fe0:	7111                	addi	sp,sp,-256
    80005fe2:	e006                	sd	ra,0(sp)
    80005fe4:	e40a                	sd	sp,8(sp)
    80005fe6:	e80e                	sd	gp,16(sp)
    80005fe8:	ec12                	sd	tp,24(sp)
    80005fea:	f016                	sd	t0,32(sp)
    80005fec:	f41a                	sd	t1,40(sp)
    80005fee:	f81e                	sd	t2,48(sp)
    80005ff0:	fc22                	sd	s0,56(sp)
    80005ff2:	e0a6                	sd	s1,64(sp)
    80005ff4:	e4aa                	sd	a0,72(sp)
    80005ff6:	e8ae                	sd	a1,80(sp)
    80005ff8:	ecb2                	sd	a2,88(sp)
    80005ffa:	f0b6                	sd	a3,96(sp)
    80005ffc:	f4ba                	sd	a4,104(sp)
    80005ffe:	f8be                	sd	a5,112(sp)
    80006000:	fcc2                	sd	a6,120(sp)
    80006002:	e146                	sd	a7,128(sp)
    80006004:	e54a                	sd	s2,136(sp)
    80006006:	e94e                	sd	s3,144(sp)
    80006008:	ed52                	sd	s4,152(sp)
    8000600a:	f156                	sd	s5,160(sp)
    8000600c:	f55a                	sd	s6,168(sp)
    8000600e:	f95e                	sd	s7,176(sp)
    80006010:	fd62                	sd	s8,184(sp)
    80006012:	e1e6                	sd	s9,192(sp)
    80006014:	e5ea                	sd	s10,200(sp)
    80006016:	e9ee                	sd	s11,208(sp)
    80006018:	edf2                	sd	t3,216(sp)
    8000601a:	f1f6                	sd	t4,224(sp)
    8000601c:	f5fa                	sd	t5,232(sp)
    8000601e:	f9fe                	sd	t6,240(sp)
    80006020:	b77fc0ef          	jal	ra,80002b96 <kerneltrap>
    80006024:	6082                	ld	ra,0(sp)
    80006026:	6122                	ld	sp,8(sp)
    80006028:	61c2                	ld	gp,16(sp)
    8000602a:	7282                	ld	t0,32(sp)
    8000602c:	7322                	ld	t1,40(sp)
    8000602e:	73c2                	ld	t2,48(sp)
    80006030:	7462                	ld	s0,56(sp)
    80006032:	6486                	ld	s1,64(sp)
    80006034:	6526                	ld	a0,72(sp)
    80006036:	65c6                	ld	a1,80(sp)
    80006038:	6666                	ld	a2,88(sp)
    8000603a:	7686                	ld	a3,96(sp)
    8000603c:	7726                	ld	a4,104(sp)
    8000603e:	77c6                	ld	a5,112(sp)
    80006040:	7866                	ld	a6,120(sp)
    80006042:	688a                	ld	a7,128(sp)
    80006044:	692a                	ld	s2,136(sp)
    80006046:	69ca                	ld	s3,144(sp)
    80006048:	6a6a                	ld	s4,152(sp)
    8000604a:	7a8a                	ld	s5,160(sp)
    8000604c:	7b2a                	ld	s6,168(sp)
    8000604e:	7bca                	ld	s7,176(sp)
    80006050:	7c6a                	ld	s8,184(sp)
    80006052:	6c8e                	ld	s9,192(sp)
    80006054:	6d2e                	ld	s10,200(sp)
    80006056:	6dce                	ld	s11,208(sp)
    80006058:	6e6e                	ld	t3,216(sp)
    8000605a:	7e8e                	ld	t4,224(sp)
    8000605c:	7f2e                	ld	t5,232(sp)
    8000605e:	7fce                	ld	t6,240(sp)
    80006060:	6111                	addi	sp,sp,256
    80006062:	10200073          	sret
    80006066:	00000013          	nop
    8000606a:	00000013          	nop
    8000606e:	0001                	nop

0000000080006070 <timervec>:
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	e10c                	sd	a1,0(a0)
    80006076:	e510                	sd	a2,8(a0)
    80006078:	e914                	sd	a3,16(a0)
    8000607a:	6d0c                	ld	a1,24(a0)
    8000607c:	7110                	ld	a2,32(a0)
    8000607e:	6194                	ld	a3,0(a1)
    80006080:	96b2                	add	a3,a3,a2
    80006082:	e194                	sd	a3,0(a1)
    80006084:	4589                	li	a1,2
    80006086:	14459073          	csrw	sip,a1
    8000608a:	6914                	ld	a3,16(a0)
    8000608c:	6510                	ld	a2,8(a0)
    8000608e:	610c                	ld	a1,0(a0)
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	30200073          	mret
	...

000000008000609a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000609a:	1141                	addi	sp,sp,-16
    8000609c:	e422                	sd	s0,8(sp)
    8000609e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060a0:	0c0007b7          	lui	a5,0xc000
    800060a4:	4705                	li	a4,1
    800060a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060a8:	c3d8                	sw	a4,4(a5)
}
    800060aa:	6422                	ld	s0,8(sp)
    800060ac:	0141                	addi	sp,sp,16
    800060ae:	8082                	ret

00000000800060b0 <plicinithart>:

void
plicinithart(void)
{
    800060b0:	1141                	addi	sp,sp,-16
    800060b2:	e406                	sd	ra,8(sp)
    800060b4:	e022                	sd	s0,0(sp)
    800060b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	a8c080e7          	jalr	-1396(ra) # 80001b44 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060c0:	0085171b          	slliw	a4,a0,0x8
    800060c4:	0c0027b7          	lui	a5,0xc002
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	40200713          	li	a4,1026
    800060ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060d2:	00d5151b          	slliw	a0,a0,0xd
    800060d6:	0c2017b7          	lui	a5,0xc201
    800060da:	97aa                	add	a5,a5,a0
    800060dc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060e0:	60a2                	ld	ra,8(sp)
    800060e2:	6402                	ld	s0,0(sp)
    800060e4:	0141                	addi	sp,sp,16
    800060e6:	8082                	ret

00000000800060e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060e8:	1141                	addi	sp,sp,-16
    800060ea:	e406                	sd	ra,8(sp)
    800060ec:	e022                	sd	s0,0(sp)
    800060ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f0:	ffffc097          	auipc	ra,0xffffc
    800060f4:	a54080e7          	jalr	-1452(ra) # 80001b44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060f8:	00d5151b          	slliw	a0,a0,0xd
    800060fc:	0c2017b7          	lui	a5,0xc201
    80006100:	97aa                	add	a5,a5,a0
  return irq;
}
    80006102:	43c8                	lw	a0,4(a5)
    80006104:	60a2                	ld	ra,8(sp)
    80006106:	6402                	ld	s0,0(sp)
    80006108:	0141                	addi	sp,sp,16
    8000610a:	8082                	ret

000000008000610c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000610c:	1101                	addi	sp,sp,-32
    8000610e:	ec06                	sd	ra,24(sp)
    80006110:	e822                	sd	s0,16(sp)
    80006112:	e426                	sd	s1,8(sp)
    80006114:	1000                	addi	s0,sp,32
    80006116:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	a2c080e7          	jalr	-1492(ra) # 80001b44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006120:	00d5151b          	slliw	a0,a0,0xd
    80006124:	0c2017b7          	lui	a5,0xc201
    80006128:	97aa                	add	a5,a5,a0
    8000612a:	c3c4                	sw	s1,4(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret

0000000080006136 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006136:	1141                	addi	sp,sp,-16
    80006138:	e406                	sd	ra,8(sp)
    8000613a:	e022                	sd	s0,0(sp)
    8000613c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000613e:	479d                	li	a5,7
    80006140:	04a7cc63          	blt	a5,a0,80006198 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006144:	0003c797          	auipc	a5,0x3c
    80006148:	ec478793          	addi	a5,a5,-316 # 80042008 <disk>
    8000614c:	97aa                	add	a5,a5,a0
    8000614e:	0187c783          	lbu	a5,24(a5)
    80006152:	ebb9                	bnez	a5,800061a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006154:	00451693          	slli	a3,a0,0x4
    80006158:	0003c797          	auipc	a5,0x3c
    8000615c:	eb078793          	addi	a5,a5,-336 # 80042008 <disk>
    80006160:	6398                	ld	a4,0(a5)
    80006162:	9736                	add	a4,a4,a3
    80006164:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006168:	6398                	ld	a4,0(a5)
    8000616a:	9736                	add	a4,a4,a3
    8000616c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006170:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006174:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	4705                	li	a4,1
    8000617c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006180:	0003c517          	auipc	a0,0x3c
    80006184:	ea050513          	addi	a0,a0,-352 # 80042020 <disk+0x18>
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	122080e7          	jalr	290(ra) # 800022aa <wakeup>
}
    80006190:	60a2                	ld	ra,8(sp)
    80006192:	6402                	ld	s0,0(sp)
    80006194:	0141                	addi	sp,sp,16
    80006196:	8082                	ret
    panic("free_desc 1");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	57850513          	addi	a0,a0,1400 # 80008710 <syscalls+0x2f8>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	3a0080e7          	jalr	928(ra) # 80000540 <panic>
    panic("free_desc 2");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	57850513          	addi	a0,a0,1400 # 80008720 <syscalls+0x308>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	390080e7          	jalr	912(ra) # 80000540 <panic>

00000000800061b8 <virtio_disk_init>:
{
    800061b8:	1101                	addi	sp,sp,-32
    800061ba:	ec06                	sd	ra,24(sp)
    800061bc:	e822                	sd	s0,16(sp)
    800061be:	e426                	sd	s1,8(sp)
    800061c0:	e04a                	sd	s2,0(sp)
    800061c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061c4:	00002597          	auipc	a1,0x2
    800061c8:	56c58593          	addi	a1,a1,1388 # 80008730 <syscalls+0x318>
    800061cc:	0003c517          	auipc	a0,0x3c
    800061d0:	f6450513          	addi	a0,a0,-156 # 80042130 <disk+0x128>
    800061d4:	ffffb097          	auipc	ra,0xffffb
    800061d8:	af8080e7          	jalr	-1288(ra) # 80000ccc <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061dc:	100017b7          	lui	a5,0x10001
    800061e0:	4398                	lw	a4,0(a5)
    800061e2:	2701                	sext.w	a4,a4
    800061e4:	747277b7          	lui	a5,0x74727
    800061e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061ec:	14f71b63          	bne	a4,a5,80006342 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061f0:	100017b7          	lui	a5,0x10001
    800061f4:	43dc                	lw	a5,4(a5)
    800061f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f8:	4709                	li	a4,2
    800061fa:	14e79463          	bne	a5,a4,80006342 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061fe:	100017b7          	lui	a5,0x10001
    80006202:	479c                	lw	a5,8(a5)
    80006204:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006206:	12e79e63          	bne	a5,a4,80006342 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000620a:	100017b7          	lui	a5,0x10001
    8000620e:	47d8                	lw	a4,12(a5)
    80006210:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006212:	554d47b7          	lui	a5,0x554d4
    80006216:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000621a:	12f71463          	bne	a4,a5,80006342 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006226:	4705                	li	a4,1
    80006228:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000622a:	470d                	li	a4,3
    8000622c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000622e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006230:	c7ffe6b7          	lui	a3,0xc7ffe
    80006234:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc617>
    80006238:	8f75                	and	a4,a4,a3
    8000623a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000623c:	472d                	li	a4,11
    8000623e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006240:	5bbc                	lw	a5,112(a5)
    80006242:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006246:	8ba1                	andi	a5,a5,8
    80006248:	10078563          	beqz	a5,80006352 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000624c:	100017b7          	lui	a5,0x10001
    80006250:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006254:	43fc                	lw	a5,68(a5)
    80006256:	2781                	sext.w	a5,a5
    80006258:	10079563          	bnez	a5,80006362 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	5bdc                	lw	a5,52(a5)
    80006262:	2781                	sext.w	a5,a5
  if(max == 0)
    80006264:	10078763          	beqz	a5,80006372 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006268:	471d                	li	a4,7
    8000626a:	10f77c63          	bgeu	a4,a5,80006382 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	920080e7          	jalr	-1760(ra) # 80000b8e <kalloc>
    80006276:	0003c497          	auipc	s1,0x3c
    8000627a:	d9248493          	addi	s1,s1,-622 # 80042008 <disk>
    8000627e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	90e080e7          	jalr	-1778(ra) # 80000b8e <kalloc>
    80006288:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	904080e7          	jalr	-1788(ra) # 80000b8e <kalloc>
    80006292:	87aa                	mv	a5,a0
    80006294:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006296:	6088                	ld	a0,0(s1)
    80006298:	cd6d                	beqz	a0,80006392 <virtio_disk_init+0x1da>
    8000629a:	0003c717          	auipc	a4,0x3c
    8000629e:	d7673703          	ld	a4,-650(a4) # 80042010 <disk+0x8>
    800062a2:	cb65                	beqz	a4,80006392 <virtio_disk_init+0x1da>
    800062a4:	c7fd                	beqz	a5,80006392 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062a6:	6605                	lui	a2,0x1
    800062a8:	4581                	li	a1,0
    800062aa:	ffffb097          	auipc	ra,0xffffb
    800062ae:	bae080e7          	jalr	-1106(ra) # 80000e58 <memset>
  memset(disk.avail, 0, PGSIZE);
    800062b2:	0003c497          	auipc	s1,0x3c
    800062b6:	d5648493          	addi	s1,s1,-682 # 80042008 <disk>
    800062ba:	6605                	lui	a2,0x1
    800062bc:	4581                	li	a1,0
    800062be:	6488                	ld	a0,8(s1)
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	b98080e7          	jalr	-1128(ra) # 80000e58 <memset>
  memset(disk.used, 0, PGSIZE);
    800062c8:	6605                	lui	a2,0x1
    800062ca:	4581                	li	a1,0
    800062cc:	6888                	ld	a0,16(s1)
    800062ce:	ffffb097          	auipc	ra,0xffffb
    800062d2:	b8a080e7          	jalr	-1142(ra) # 80000e58 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062d6:	100017b7          	lui	a5,0x10001
    800062da:	4721                	li	a4,8
    800062dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062de:	4098                	lw	a4,0(s1)
    800062e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062e4:	40d8                	lw	a4,4(s1)
    800062e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062ea:	6498                	ld	a4,8(s1)
    800062ec:	0007069b          	sext.w	a3,a4
    800062f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062f4:	9701                	srai	a4,a4,0x20
    800062f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062fa:	6898                	ld	a4,16(s1)
    800062fc:	0007069b          	sext.w	a3,a4
    80006300:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006304:	9701                	srai	a4,a4,0x20
    80006306:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000630a:	4705                	li	a4,1
    8000630c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000630e:	00e48c23          	sb	a4,24(s1)
    80006312:	00e48ca3          	sb	a4,25(s1)
    80006316:	00e48d23          	sb	a4,26(s1)
    8000631a:	00e48da3          	sb	a4,27(s1)
    8000631e:	00e48e23          	sb	a4,28(s1)
    80006322:	00e48ea3          	sb	a4,29(s1)
    80006326:	00e48f23          	sb	a4,30(s1)
    8000632a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000632e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006332:	0727a823          	sw	s2,112(a5)
}
    80006336:	60e2                	ld	ra,24(sp)
    80006338:	6442                	ld	s0,16(sp)
    8000633a:	64a2                	ld	s1,8(sp)
    8000633c:	6902                	ld	s2,0(sp)
    8000633e:	6105                	addi	sp,sp,32
    80006340:	8082                	ret
    panic("could not find virtio disk");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	3fe50513          	addi	a0,a0,1022 # 80008740 <syscalls+0x328>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	40e50513          	addi	a0,a0,1038 # 80008760 <syscalls+0x348>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	41e50513          	addi	a0,a0,1054 # 80008780 <syscalls+0x368>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	42e50513          	addi	a0,a0,1070 # 800087a0 <syscalls+0x388>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	43e50513          	addi	a0,a0,1086 # 800087c0 <syscalls+0x3a8>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	44e50513          	addi	a0,a0,1102 # 800087e0 <syscalls+0x3c8>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>

00000000800063a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063a2:	7119                	addi	sp,sp,-128
    800063a4:	fc86                	sd	ra,120(sp)
    800063a6:	f8a2                	sd	s0,112(sp)
    800063a8:	f4a6                	sd	s1,104(sp)
    800063aa:	f0ca                	sd	s2,96(sp)
    800063ac:	ecce                	sd	s3,88(sp)
    800063ae:	e8d2                	sd	s4,80(sp)
    800063b0:	e4d6                	sd	s5,72(sp)
    800063b2:	e0da                	sd	s6,64(sp)
    800063b4:	fc5e                	sd	s7,56(sp)
    800063b6:	f862                	sd	s8,48(sp)
    800063b8:	f466                	sd	s9,40(sp)
    800063ba:	f06a                	sd	s10,32(sp)
    800063bc:	ec6e                	sd	s11,24(sp)
    800063be:	0100                	addi	s0,sp,128
    800063c0:	8aaa                	mv	s5,a0
    800063c2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063c4:	00c52d03          	lw	s10,12(a0)
    800063c8:	001d1d1b          	slliw	s10,s10,0x1
    800063cc:	1d02                	slli	s10,s10,0x20
    800063ce:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800063d2:	0003c517          	auipc	a0,0x3c
    800063d6:	d5e50513          	addi	a0,a0,-674 # 80042130 <disk+0x128>
    800063da:	ffffb097          	auipc	ra,0xffffb
    800063de:	982080e7          	jalr	-1662(ra) # 80000d5c <acquire>
  for(int i = 0; i < 3; i++){
    800063e2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063e6:	0003cb97          	auipc	s7,0x3c
    800063ea:	c22b8b93          	addi	s7,s7,-990 # 80042008 <disk>
  for(int i = 0; i < 3; i++){
    800063ee:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063f0:	0003cc97          	auipc	s9,0x3c
    800063f4:	d40c8c93          	addi	s9,s9,-704 # 80042130 <disk+0x128>
    800063f8:	a08d                	j	8000645a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063fa:	00fb8733          	add	a4,s7,a5
    800063fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006402:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006404:	0207c563          	bltz	a5,8000642e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006408:	2905                	addiw	s2,s2,1
    8000640a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000640c:	05690c63          	beq	s2,s6,80006464 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006410:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006412:	0003c717          	auipc	a4,0x3c
    80006416:	bf670713          	addi	a4,a4,-1034 # 80042008 <disk>
    8000641a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000641c:	01874683          	lbu	a3,24(a4)
    80006420:	fee9                	bnez	a3,800063fa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006422:	2785                	addiw	a5,a5,1
    80006424:	0705                	addi	a4,a4,1
    80006426:	fe979be3          	bne	a5,s1,8000641c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000642a:	57fd                	li	a5,-1
    8000642c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000642e:	01205d63          	blez	s2,80006448 <virtio_disk_rw+0xa6>
    80006432:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006434:	000a2503          	lw	a0,0(s4)
    80006438:	00000097          	auipc	ra,0x0
    8000643c:	cfe080e7          	jalr	-770(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    80006440:	2d85                	addiw	s11,s11,1
    80006442:	0a11                	addi	s4,s4,4
    80006444:	ff2d98e3          	bne	s11,s2,80006434 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006448:	85e6                	mv	a1,s9
    8000644a:	0003c517          	auipc	a0,0x3c
    8000644e:	bd650513          	addi	a0,a0,-1066 # 80042020 <disk+0x18>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	df4080e7          	jalr	-524(ra) # 80002246 <sleep>
  for(int i = 0; i < 3; i++){
    8000645a:	f8040a13          	addi	s4,s0,-128
{
    8000645e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006460:	894e                	mv	s2,s3
    80006462:	b77d                	j	80006410 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006464:	f8042503          	lw	a0,-128(s0)
    80006468:	00a50713          	addi	a4,a0,10
    8000646c:	0712                	slli	a4,a4,0x4

  if(write)
    8000646e:	0003c797          	auipc	a5,0x3c
    80006472:	b9a78793          	addi	a5,a5,-1126 # 80042008 <disk>
    80006476:	00e786b3          	add	a3,a5,a4
    8000647a:	01803633          	snez	a2,s8
    8000647e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006480:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006484:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006488:	f6070613          	addi	a2,a4,-160
    8000648c:	6394                	ld	a3,0(a5)
    8000648e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006490:	00870593          	addi	a1,a4,8
    80006494:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006496:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006498:	0007b803          	ld	a6,0(a5)
    8000649c:	9642                	add	a2,a2,a6
    8000649e:	46c1                	li	a3,16
    800064a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064a2:	4585                	li	a1,1
    800064a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064a8:	f8442683          	lw	a3,-124(s0)
    800064ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064b0:	0692                	slli	a3,a3,0x4
    800064b2:	9836                	add	a6,a6,a3
    800064b4:	058a8613          	addi	a2,s5,88
    800064b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064bc:	0007b803          	ld	a6,0(a5)
    800064c0:	96c2                	add	a3,a3,a6
    800064c2:	40000613          	li	a2,1024
    800064c6:	c690                	sw	a2,8(a3)
  if(write)
    800064c8:	001c3613          	seqz	a2,s8
    800064cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064d0:	00166613          	ori	a2,a2,1
    800064d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064d8:	f8842603          	lw	a2,-120(s0)
    800064dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064e0:	00250693          	addi	a3,a0,2
    800064e4:	0692                	slli	a3,a3,0x4
    800064e6:	96be                	add	a3,a3,a5
    800064e8:	58fd                	li	a7,-1
    800064ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064ee:	0612                	slli	a2,a2,0x4
    800064f0:	9832                	add	a6,a6,a2
    800064f2:	f9070713          	addi	a4,a4,-112
    800064f6:	973e                	add	a4,a4,a5
    800064f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800064fc:	6398                	ld	a4,0(a5)
    800064fe:	9732                	add	a4,a4,a2
    80006500:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006502:	4609                	li	a2,2
    80006504:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006508:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000650c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006510:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006514:	6794                	ld	a3,8(a5)
    80006516:	0026d703          	lhu	a4,2(a3)
    8000651a:	8b1d                	andi	a4,a4,7
    8000651c:	0706                	slli	a4,a4,0x1
    8000651e:	96ba                	add	a3,a3,a4
    80006520:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006524:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006528:	6798                	ld	a4,8(a5)
    8000652a:	00275783          	lhu	a5,2(a4)
    8000652e:	2785                	addiw	a5,a5,1
    80006530:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006534:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006538:	100017b7          	lui	a5,0x10001
    8000653c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006540:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006544:	0003c917          	auipc	s2,0x3c
    80006548:	bec90913          	addi	s2,s2,-1044 # 80042130 <disk+0x128>
  while(b->disk == 1) {
    8000654c:	4485                	li	s1,1
    8000654e:	00b79c63          	bne	a5,a1,80006566 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006552:	85ca                	mv	a1,s2
    80006554:	8556                	mv	a0,s5
    80006556:	ffffc097          	auipc	ra,0xffffc
    8000655a:	cf0080e7          	jalr	-784(ra) # 80002246 <sleep>
  while(b->disk == 1) {
    8000655e:	004aa783          	lw	a5,4(s5)
    80006562:	fe9788e3          	beq	a5,s1,80006552 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006566:	f8042903          	lw	s2,-128(s0)
    8000656a:	00290713          	addi	a4,s2,2
    8000656e:	0712                	slli	a4,a4,0x4
    80006570:	0003c797          	auipc	a5,0x3c
    80006574:	a9878793          	addi	a5,a5,-1384 # 80042008 <disk>
    80006578:	97ba                	add	a5,a5,a4
    8000657a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000657e:	0003c997          	auipc	s3,0x3c
    80006582:	a8a98993          	addi	s3,s3,-1398 # 80042008 <disk>
    80006586:	00491713          	slli	a4,s2,0x4
    8000658a:	0009b783          	ld	a5,0(s3)
    8000658e:	97ba                	add	a5,a5,a4
    80006590:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006594:	854a                	mv	a0,s2
    80006596:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000659a:	00000097          	auipc	ra,0x0
    8000659e:	b9c080e7          	jalr	-1124(ra) # 80006136 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065a2:	8885                	andi	s1,s1,1
    800065a4:	f0ed                	bnez	s1,80006586 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065a6:	0003c517          	auipc	a0,0x3c
    800065aa:	b8a50513          	addi	a0,a0,-1142 # 80042130 <disk+0x128>
    800065ae:	ffffb097          	auipc	ra,0xffffb
    800065b2:	862080e7          	jalr	-1950(ra) # 80000e10 <release>
}
    800065b6:	70e6                	ld	ra,120(sp)
    800065b8:	7446                	ld	s0,112(sp)
    800065ba:	74a6                	ld	s1,104(sp)
    800065bc:	7906                	ld	s2,96(sp)
    800065be:	69e6                	ld	s3,88(sp)
    800065c0:	6a46                	ld	s4,80(sp)
    800065c2:	6aa6                	ld	s5,72(sp)
    800065c4:	6b06                	ld	s6,64(sp)
    800065c6:	7be2                	ld	s7,56(sp)
    800065c8:	7c42                	ld	s8,48(sp)
    800065ca:	7ca2                	ld	s9,40(sp)
    800065cc:	7d02                	ld	s10,32(sp)
    800065ce:	6de2                	ld	s11,24(sp)
    800065d0:	6109                	addi	sp,sp,128
    800065d2:	8082                	ret

00000000800065d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065d4:	1101                	addi	sp,sp,-32
    800065d6:	ec06                	sd	ra,24(sp)
    800065d8:	e822                	sd	s0,16(sp)
    800065da:	e426                	sd	s1,8(sp)
    800065dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065de:	0003c497          	auipc	s1,0x3c
    800065e2:	a2a48493          	addi	s1,s1,-1494 # 80042008 <disk>
    800065e6:	0003c517          	auipc	a0,0x3c
    800065ea:	b4a50513          	addi	a0,a0,-1206 # 80042130 <disk+0x128>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	76e080e7          	jalr	1902(ra) # 80000d5c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065f6:	10001737          	lui	a4,0x10001
    800065fa:	533c                	lw	a5,96(a4)
    800065fc:	8b8d                	andi	a5,a5,3
    800065fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006600:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006604:	689c                	ld	a5,16(s1)
    80006606:	0204d703          	lhu	a4,32(s1)
    8000660a:	0027d783          	lhu	a5,2(a5)
    8000660e:	04f70863          	beq	a4,a5,8000665e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006612:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006616:	6898                	ld	a4,16(s1)
    80006618:	0204d783          	lhu	a5,32(s1)
    8000661c:	8b9d                	andi	a5,a5,7
    8000661e:	078e                	slli	a5,a5,0x3
    80006620:	97ba                	add	a5,a5,a4
    80006622:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006624:	00278713          	addi	a4,a5,2
    80006628:	0712                	slli	a4,a4,0x4
    8000662a:	9726                	add	a4,a4,s1
    8000662c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006630:	e721                	bnez	a4,80006678 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006632:	0789                	addi	a5,a5,2
    80006634:	0792                	slli	a5,a5,0x4
    80006636:	97a6                	add	a5,a5,s1
    80006638:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000663a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000663e:	ffffc097          	auipc	ra,0xffffc
    80006642:	c6c080e7          	jalr	-916(ra) # 800022aa <wakeup>

    disk.used_idx += 1;
    80006646:	0204d783          	lhu	a5,32(s1)
    8000664a:	2785                	addiw	a5,a5,1
    8000664c:	17c2                	slli	a5,a5,0x30
    8000664e:	93c1                	srli	a5,a5,0x30
    80006650:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006654:	6898                	ld	a4,16(s1)
    80006656:	00275703          	lhu	a4,2(a4)
    8000665a:	faf71ce3          	bne	a4,a5,80006612 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000665e:	0003c517          	auipc	a0,0x3c
    80006662:	ad250513          	addi	a0,a0,-1326 # 80042130 <disk+0x128>
    80006666:	ffffa097          	auipc	ra,0xffffa
    8000666a:	7aa080e7          	jalr	1962(ra) # 80000e10 <release>
}
    8000666e:	60e2                	ld	ra,24(sp)
    80006670:	6442                	ld	s0,16(sp)
    80006672:	64a2                	ld	s1,8(sp)
    80006674:	6105                	addi	sp,sp,32
    80006676:	8082                	ret
      panic("virtio_disk_intr status");
    80006678:	00002517          	auipc	a0,0x2
    8000667c:	18050513          	addi	a0,a0,384 # 800087f8 <syscalls+0x3e0>
    80006680:	ffffa097          	auipc	ra,0xffffa
    80006684:	ec0080e7          	jalr	-320(ra) # 80000540 <panic>
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
