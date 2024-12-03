
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

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
    80000038:	1761                	addi	a4,a4,-8 # 200bff8 <_entry-0x7dff4008>
    8000003a:	6318                	ld	a4,0(a4)
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
    80000054:	8a070713          	addi	a4,a4,-1888 # 800088f0 <timer_scratch>
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
    80000066:	33e78793          	addi	a5,a5,830 # 800063a0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd989f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e2678793          	addi	a5,a5,-474 # 80000ed2 <main>
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
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    8000010a:	04c05663          	blez	a2,80000156 <consolewrite+0x56>
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	f44e                	sd	s3,40(sp)
    80000112:	f052                	sd	s4,32(sp)
    80000114:	ec56                	sd	s5,24(sp)
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
    8000012e:	4ec080e7          	jalr	1260(ra) # 80002616 <either_copyin>
    80000132:	03550463          	beq	a0,s5,8000015a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	7e4080e7          	jalr	2020(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    8000014c:	74e2                	ld	s1,56(sp)
    8000014e:	79a2                	ld	s3,40(sp)
    80000150:	7a02                	ld	s4,32(sp)
    80000152:	6ae2                	ld	s5,24(sp)
    80000154:	a039                	j	80000162 <consolewrite+0x62>
    80000156:	4901                	li	s2,0
    80000158:	a029                	j	80000162 <consolewrite+0x62>
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	79a2                	ld	s3,40(sp)
    8000015e:	7a02                	ld	s4,32(sp)
    80000160:	6ae2                	ld	s5,24(sp)
  }

  return i;
}
    80000162:	854a                	mv	a0,s2
    80000164:	60a6                	ld	ra,72(sp)
    80000166:	6406                	ld	s0,64(sp)
    80000168:	7942                	ld	s2,48(sp)
    8000016a:	6161                	addi	sp,sp,80
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8a450513          	addi	a0,a0,-1884 # 80010a30 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aa4080e7          	jalr	-1372(ra) # 80000c38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	89448493          	addi	s1,s1,-1900 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00011917          	auipc	s2,0x11
    800001a8:	92490913          	addi	s2,s2,-1756 # 80010ac8 <cons+0x98>
  while(n > 0){
    800001ac:	0d305763          	blez	s3,8000027a <consoleread+0x10c>
    while(cons.r == cons.w){
    800001b0:	0984a783          	lw	a5,152(s1)
    800001b4:	09c4a703          	lw	a4,156(s1)
    800001b8:	0af71c63          	bne	a4,a5,80000270 <consoleread+0x102>
      if(killed(myproc())){
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	88e080e7          	jalr	-1906(ra) # 80001a4a <myproc>
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	29a080e7          	jalr	666(ra) # 8000245e <killed>
    800001cc:	e52d                	bnez	a0,80000236 <consoleread+0xc8>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	fb6080e7          	jalr	-74(ra) # 80002188 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70de3          	beq	a4,a5,800001bc <consoleread+0x4e>
    800001e6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e8:	00011717          	auipc	a4,0x11
    800001ec:	84870713          	addi	a4,a4,-1976 # 80010a30 <cons>
    800001f0:	0017869b          	addiw	a3,a5,1
    800001f4:	08d72c23          	sw	a3,152(a4)
    800001f8:	07f7f693          	andi	a3,a5,127
    800001fc:	9736                	add	a4,a4,a3
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000206:	4691                	li	a3,4
    80000208:	04db8a63          	beq	s7,a3,8000025c <consoleread+0xee>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000020c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	faf40613          	addi	a2,s0,-81
    80000216:	85d2                	mv	a1,s4
    80000218:	8556                	mv	a0,s5
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	3a4080e7          	jalr	932(ra) # 800025be <either_copyout>
    80000222:	57fd                	li	a5,-1
    80000224:	04f50a63          	beq	a0,a5,80000278 <consoleread+0x10a>
      break;

    dst++;
    80000228:	0a05                	addi	s4,s4,1
    --n;
    8000022a:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000022c:	47a9                	li	a5,10
    8000022e:	06fb8163          	beq	s7,a5,80000290 <consoleread+0x122>
    80000232:	6be2                	ld	s7,24(sp)
    80000234:	bfa5                	j	800001ac <consoleread+0x3e>
        release(&cons.lock);
    80000236:	00010517          	auipc	a0,0x10
    8000023a:	7fa50513          	addi	a0,a0,2042 # 80010a30 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	aae080e7          	jalr	-1362(ra) # 80000cec <release>
        return -1;
    80000246:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000248:	60e6                	ld	ra,88(sp)
    8000024a:	6446                	ld	s0,80(sp)
    8000024c:	64a6                	ld	s1,72(sp)
    8000024e:	6906                	ld	s2,64(sp)
    80000250:	79e2                	ld	s3,56(sp)
    80000252:	7a42                	ld	s4,48(sp)
    80000254:	7aa2                	ld	s5,40(sp)
    80000256:	7b02                	ld	s6,32(sp)
    80000258:	6125                	addi	sp,sp,96
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	0009871b          	sext.w	a4,s3
    80000260:	01677a63          	bgeu	a4,s6,80000274 <consoleread+0x106>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	86f72223          	sw	a5,-1948(a4) # 80010ac8 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00010517          	auipc	a0,0x10
    8000027e:	7b650513          	addi	a0,a0,1974 # 80010a30 <cons>
    80000282:	00001097          	auipc	ra,0x1
    80000286:	a6a080e7          	jalr	-1430(ra) # 80000cec <release>
  return target - n;
    8000028a:	413b053b          	subw	a0,s6,s3
    8000028e:	bf6d                	j	80000248 <consoleread+0xda>
    80000290:	6be2                	ld	s7,24(sp)
    80000292:	b7e5                	j	8000027a <consoleread+0x10c>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	59c080e7          	jalr	1436(ra) # 80000840 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	58a080e7          	jalr	1418(ra) # 80000840 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	574080e7          	jalr	1396(ra) # 80000840 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	1000                	addi	s0,sp,32
    800002e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e2:	00010517          	auipc	a0,0x10
    800002e6:	74e50513          	addi	a0,a0,1870 # 80010a30 <cons>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	94e080e7          	jalr	-1714(ra) # 80000c38 <acquire>

  switch(c){
    800002f2:	47d5                	li	a5,21
    800002f4:	0af48563          	beq	s1,a5,8000039e <consoleintr+0xc8>
    800002f8:	0297c963          	blt	a5,s1,8000032a <consoleintr+0x54>
    800002fc:	47a1                	li	a5,8
    800002fe:	0ef48c63          	beq	s1,a5,800003f6 <consoleintr+0x120>
    80000302:	47c1                	li	a5,16
    80000304:	10f49f63          	bne	s1,a5,80000422 <consoleintr+0x14c>
  case C('P'):  // Print process list.
    procdump();
    80000308:	00002097          	auipc	ra,0x2
    8000030c:	366080e7          	jalr	870(ra) # 8000266e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000310:	00010517          	auipc	a0,0x10
    80000314:	72050513          	addi	a0,a0,1824 # 80010a30 <cons>
    80000318:	00001097          	auipc	ra,0x1
    8000031c:	9d4080e7          	jalr	-1580(ra) # 80000cec <release>
}
    80000320:	60e2                	ld	ra,24(sp)
    80000322:	6442                	ld	s0,16(sp)
    80000324:	64a2                	ld	s1,8(sp)
    80000326:	6105                	addi	sp,sp,32
    80000328:	8082                	ret
  switch(c){
    8000032a:	07f00793          	li	a5,127
    8000032e:	0cf48463          	beq	s1,a5,800003f6 <consoleintr+0x120>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000332:	00010717          	auipc	a4,0x10
    80000336:	6fe70713          	addi	a4,a4,1790 # 80010a30 <cons>
    8000033a:	0a072783          	lw	a5,160(a4)
    8000033e:	09872703          	lw	a4,152(a4)
    80000342:	9f99                	subw	a5,a5,a4
    80000344:	07f00713          	li	a4,127
    80000348:	fcf764e3          	bltu	a4,a5,80000310 <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    8000034c:	47b5                	li	a5,13
    8000034e:	0cf48d63          	beq	s1,a5,80000428 <consoleintr+0x152>
      consputc(c);
    80000352:	8526                	mv	a0,s1
    80000354:	00000097          	auipc	ra,0x0
    80000358:	f40080e7          	jalr	-192(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000035c:	00010797          	auipc	a5,0x10
    80000360:	6d478793          	addi	a5,a5,1748 # 80010a30 <cons>
    80000364:	0a07a683          	lw	a3,160(a5)
    80000368:	0016871b          	addiw	a4,a3,1
    8000036c:	0007061b          	sext.w	a2,a4
    80000370:	0ae7a023          	sw	a4,160(a5)
    80000374:	07f6f693          	andi	a3,a3,127
    80000378:	97b6                	add	a5,a5,a3
    8000037a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000037e:	47a9                	li	a5,10
    80000380:	0cf48b63          	beq	s1,a5,80000456 <consoleintr+0x180>
    80000384:	4791                	li	a5,4
    80000386:	0cf48863          	beq	s1,a5,80000456 <consoleintr+0x180>
    8000038a:	00010797          	auipc	a5,0x10
    8000038e:	73e7a783          	lw	a5,1854(a5) # 80010ac8 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00010717          	auipc	a4,0x10
    800003a4:	69070713          	addi	a4,a4,1680 # 80010a30 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00010497          	auipc	s1,0x10
    800003b4:	68048493          	addi	s1,s1,1664 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003b8:	4929                	li	s2,10
    800003ba:	02f70a63          	beq	a4,a5,800003ee <consoleintr+0x118>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003be:	37fd                	addiw	a5,a5,-1
    800003c0:	07f7f713          	andi	a4,a5,127
    800003c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c6:	01874703          	lbu	a4,24(a4)
    800003ca:	03270463          	beq	a4,s2,800003f2 <consoleintr+0x11c>
      cons.e--;
    800003ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d2:	10000513          	li	a0,256
    800003d6:	00000097          	auipc	ra,0x0
    800003da:	ebe080e7          	jalr	-322(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003de:	0a04a783          	lw	a5,160(s1)
    800003e2:	09c4a703          	lw	a4,156(s1)
    800003e6:	fcf71ce3          	bne	a4,a5,800003be <consoleintr+0xe8>
    800003ea:	6902                	ld	s2,0(sp)
    800003ec:	b715                	j	80000310 <consoleintr+0x3a>
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	b705                	j	80000310 <consoleintr+0x3a>
    800003f2:	6902                	ld	s2,0(sp)
    800003f4:	bf31                	j	80000310 <consoleintr+0x3a>
    if(cons.e != cons.w){
    800003f6:	00010717          	auipc	a4,0x10
    800003fa:	63a70713          	addi	a4,a4,1594 # 80010a30 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addiw	a5,a5,-1
    8000040c:	00010717          	auipc	a4,0x10
    80000410:	6cf72223          	sw	a5,1732(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    80000414:	10000513          	li	a0,256
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	e7c080e7          	jalr	-388(ra) # 80000294 <consputc>
    80000420:	bdc5                	j	80000310 <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000422:	ee0487e3          	beqz	s1,80000310 <consoleintr+0x3a>
    80000426:	b731                	j	80000332 <consoleintr+0x5c>
      consputc(c);
    80000428:	4529                	li	a0,10
    8000042a:	00000097          	auipc	ra,0x0
    8000042e:	e6a080e7          	jalr	-406(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	5fe78793          	addi	a5,a5,1534 # 80010a30 <cons>
    8000043a:	0a07a703          	lw	a4,160(a5)
    8000043e:	0017069b          	addiw	a3,a4,1
    80000442:	0006861b          	sext.w	a2,a3
    80000446:	0ad7a023          	sw	a3,160(a5)
    8000044a:	07f77713          	andi	a4,a4,127
    8000044e:	97ba                	add	a5,a5,a4
    80000450:	4729                	li	a4,10
    80000452:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000456:	00010797          	auipc	a5,0x10
    8000045a:	66c7ab23          	sw	a2,1654(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00010517          	auipc	a0,0x10
    80000462:	66a50513          	addi	a0,a0,1642 # 80010ac8 <cons+0x98>
    80000466:	00002097          	auipc	ra,0x2
    8000046a:	d86080e7          	jalr	-634(ra) # 800021ec <wakeup>
    8000046e:	b54d                	j	80000310 <consoleintr+0x3a>

0000000080000470 <consoleinit>:

void
consoleinit(void)
{
    80000470:	1141                	addi	sp,sp,-16
    80000472:	e406                	sd	ra,8(sp)
    80000474:	e022                	sd	s0,0(sp)
    80000476:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000478:	00008597          	auipc	a1,0x8
    8000047c:	b8858593          	addi	a1,a1,-1144 # 80008000 <etext>
    80000480:	00010517          	auipc	a0,0x10
    80000484:	5b050513          	addi	a0,a0,1456 # 80010a30 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	720080e7          	jalr	1824(ra) # 80000ba8 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	00024797          	auipc	a5,0x24
    8000049c:	93078793          	addi	a5,a5,-1744 # 80023dc8 <devsw>
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	cce70713          	addi	a4,a4,-818 # 8000016e <consoleread>
    800004a8:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004aa:	00000717          	auipc	a4,0x0
    800004ae:	c5670713          	addi	a4,a4,-938 # 80000100 <consolewrite>
    800004b2:	ef98                	sd	a4,24(a5)
}
    800004b4:	60a2                	ld	ra,8(sp)
    800004b6:	6402                	ld	s0,0(sp)
    800004b8:	0141                	addi	sp,sp,16
    800004ba:	8082                	ret

00000000800004bc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004bc:	7179                	addi	sp,sp,-48
    800004be:	f406                	sd	ra,40(sp)
    800004c0:	f022                	sd	s0,32(sp)
    800004c2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c4:	c219                	beqz	a2,800004ca <printint+0xe>
    800004c6:	08054963          	bltz	a0,80000558 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ca:	2501                	sext.w	a0,a0
    800004cc:	4881                	li	a7,0
    800004ce:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004d2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d4:	2581                	sext.w	a1,a1
    800004d6:	00008617          	auipc	a2,0x8
    800004da:	25260613          	addi	a2,a2,594 # 80008728 <digits>
    800004de:	883a                	mv	a6,a4
    800004e0:	2705                	addiw	a4,a4,1
    800004e2:	02b577bb          	remuw	a5,a0,a1
    800004e6:	1782                	slli	a5,a5,0x20
    800004e8:	9381                	srli	a5,a5,0x20
    800004ea:	97b2                	add	a5,a5,a2
    800004ec:	0007c783          	lbu	a5,0(a5)
    800004f0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f4:	0005079b          	sext.w	a5,a0
    800004f8:	02b5553b          	divuw	a0,a0,a1
    800004fc:	0685                	addi	a3,a3,1
    800004fe:	feb7f0e3          	bgeu	a5,a1,800004de <printint+0x22>

  if(sign)
    80000502:	00088c63          	beqz	a7,8000051a <printint+0x5e>
    buf[i++] = '-';
    80000506:	fe070793          	addi	a5,a4,-32
    8000050a:	00878733          	add	a4,a5,s0
    8000050e:	02d00793          	li	a5,45
    80000512:	fef70823          	sb	a5,-16(a4)
    80000516:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000051a:	02e05b63          	blez	a4,80000550 <printint+0x94>
    8000051e:	ec26                	sd	s1,24(sp)
    80000520:	e84a                	sd	s2,16(sp)
    80000522:	fd040793          	addi	a5,s0,-48
    80000526:	00e784b3          	add	s1,a5,a4
    8000052a:	fff78913          	addi	s2,a5,-1
    8000052e:	993a                	add	s2,s2,a4
    80000530:	377d                	addiw	a4,a4,-1
    80000532:	1702                	slli	a4,a4,0x20
    80000534:	9301                	srli	a4,a4,0x20
    80000536:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d56080e7          	jalr	-682(ra) # 80000294 <consputc>
  while(--i >= 0)
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x7e>
    8000054c:	64e2                	ld	s1,24(sp)
    8000054e:	6942                	ld	s2,16(sp)
}
    80000550:	70a2                	ld	ra,40(sp)
    80000552:	7402                	ld	s0,32(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4885                	li	a7,1
    x = -xx;
    8000055e:	bf85                	j	800004ce <printint+0x12>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	addi	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	addi	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00010797          	auipc	a5,0x10
    80000570:	5807a223          	sw	zero,1412(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	a9450513          	addi	a0,a0,-1388 # 80008008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00008517          	auipc	a0,0x8
    80000592:	a8250513          	addi	a0,a0,-1406 # 80008010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	00008717          	auipc	a4,0x8
    800005a4:	30f72823          	sw	a5,784(a4) # 800088b0 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	addi	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00010d17          	auipc	s10,0x10
    800005ce:	526d2d03          	lw	s10,1318(s10) # 80010af0 <pr+0x18>
  if(locking)
    800005d2:	040d1463          	bnez	s10,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050b63          	beqz	a0,8000077c <printf+0x1d2>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	ec6e                	sd	s11,24(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	4cc1                	li	s9,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000608:	00008a97          	auipc	s5,0x8
    8000060c:	120a8a93          	addi	s5,s5,288 # 80008728 <digits>
    switch(c){
    80000610:	07300c13          	li	s8,115
    80000614:	06400d93          	li	s11,100
    80000618:	a0b1                	j	80000664 <printf+0xba>
    acquire(&pr.lock);
    8000061a:	00010517          	auipc	a0,0x10
    8000061e:	4be50513          	addi	a0,a0,1214 # 80010ad8 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	616080e7          	jalr	1558(ra) # 80000c38 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	9e250513          	addi	a0,a0,-1566 # 80008020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c46080e7          	jalr	-954(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2985                	addiw	s3,s3,1
    80000658:	013a07b3          	add	a5,s4,s3
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050563          	beqz	a0,8000076a <printf+0x1c0>
    if(c != '%'){
    80000664:	ff6515e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    80000668:	2985                	addiw	s3,s3,1
    8000066a:	013a07b3          	add	a5,s4,s3
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000676:	10078b63          	beqz	a5,8000078c <printf+0x1e2>
    switch(c){
    8000067a:	05778a63          	beq	a5,s7,800006ce <printf+0x124>
    8000067e:	02fbf663          	bgeu	s7,a5,800006aa <printf+0x100>
    80000682:	09878863          	beq	a5,s8,80000712 <printf+0x168>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79563          	bne	a5,a4,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85e6                	mv	a1,s9
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e1c080e7          	jalr	-484(ra) # 800004bc <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	09678f63          	beq	a5,s6,80000748 <printf+0x19e>
    800006ae:	0bb79363          	bne	a5,s11,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	df8080e7          	jalr	-520(ra) # 800004bc <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	bb2080e7          	jalr	-1102(ra) # 80000294 <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	ba6080e7          	jalr	-1114(ra) # 80000294 <consputc>
    800006f6:	84e6                	mv	s1,s9
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c95793          	srli	a5,s2,0x3c
    800006fc:	97d6                	add	a5,a5,s5
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b92080e7          	jalr	-1134(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0912                	slli	s2,s2,0x4
    8000070c:	34fd                	addiw	s1,s1,-1
    8000070e:	f4ed                	bnez	s1,800006f8 <printf+0x14e>
    80000710:	b799                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000712:	f8843783          	ld	a5,-120(s0)
    80000716:	00878713          	addi	a4,a5,8
    8000071a:	f8e43423          	sd	a4,-120(s0)
    8000071e:	6384                	ld	s1,0(a5)
    80000720:	cc89                	beqz	s1,8000073a <printf+0x190>
      for(; *s; s++)
    80000722:	0004c503          	lbu	a0,0(s1)
    80000726:	d905                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b6c080e7          	jalr	-1172(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000730:	0485                	addi	s1,s1,1
    80000732:	0004c503          	lbu	a0,0(s1)
    80000736:	f96d                	bnez	a0,80000728 <printf+0x17e>
    80000738:	bf39                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073a:	00008497          	auipc	s1,0x8
    8000073e:	8de48493          	addi	s1,s1,-1826 # 80008018 <etext+0x18>
      for(; *s; s++)
    80000742:	02800513          	li	a0,40
    80000746:	b7cd                	j	80000728 <printf+0x17e>
      consputc('%');
    80000748:	855a                	mv	a0,s6
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b4a080e7          	jalr	-1206(ra) # 80000294 <consputc>
      break;
    80000752:	b711                	j	80000656 <printf+0xac>
      consputc('%');
    80000754:	855a                	mv	a0,s6
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b3e080e7          	jalr	-1218(ra) # 80000294 <consputc>
      consputc(c);
    8000075e:	8526                	mv	a0,s1
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b34080e7          	jalr	-1228(ra) # 80000294 <consputc>
      break;
    80000768:	b5fd                	j	80000656 <printf+0xac>
    8000076a:	74a6                	ld	s1,104(sp)
    8000076c:	7906                	ld	s2,96(sp)
    8000076e:	69e6                	ld	s3,88(sp)
    80000770:	6aa6                	ld	s5,72(sp)
    80000772:	6b06                	ld	s6,64(sp)
    80000774:	7be2                	ld	s7,56(sp)
    80000776:	7c42                	ld	s8,48(sp)
    80000778:	7ca2                	ld	s9,40(sp)
    8000077a:	6de2                	ld	s11,24(sp)
  if(locking)
    8000077c:	020d1263          	bnez	s10,800007a0 <printf+0x1f6>
}
    80000780:	70e6                	ld	ra,120(sp)
    80000782:	7446                	ld	s0,112(sp)
    80000784:	6a46                	ld	s4,80(sp)
    80000786:	7d02                	ld	s10,32(sp)
    80000788:	6129                	addi	sp,sp,192
    8000078a:	8082                	ret
    8000078c:	74a6                	ld	s1,104(sp)
    8000078e:	7906                	ld	s2,96(sp)
    80000790:	69e6                	ld	s3,88(sp)
    80000792:	6aa6                	ld	s5,72(sp)
    80000794:	6b06                	ld	s6,64(sp)
    80000796:	7be2                	ld	s7,56(sp)
    80000798:	7c42                	ld	s8,48(sp)
    8000079a:	7ca2                	ld	s9,40(sp)
    8000079c:	6de2                	ld	s11,24(sp)
    8000079e:	bff9                	j	8000077c <printf+0x1d2>
    release(&pr.lock);
    800007a0:	00010517          	auipc	a0,0x10
    800007a4:	33850513          	addi	a0,a0,824 # 80010ad8 <pr>
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	544080e7          	jalr	1348(ra) # 80000cec <release>
}
    800007b0:	bfc1                	j	80000780 <printf+0x1d6>

00000000800007b2 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b2:	1101                	addi	sp,sp,-32
    800007b4:	ec06                	sd	ra,24(sp)
    800007b6:	e822                	sd	s0,16(sp)
    800007b8:	e426                	sd	s1,8(sp)
    800007ba:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007bc:	00010497          	auipc	s1,0x10
    800007c0:	31c48493          	addi	s1,s1,796 # 80010ad8 <pr>
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	86c58593          	addi	a1,a1,-1940 # 80008030 <etext+0x30>
    800007cc:	8526                	mv	a0,s1
    800007ce:	00000097          	auipc	ra,0x0
    800007d2:	3da080e7          	jalr	986(ra) # 80000ba8 <initlock>
  pr.locking = 1;
    800007d6:	4785                	li	a5,1
    800007d8:	cc9c                	sw	a5,24(s1)
}
    800007da:	60e2                	ld	ra,24(sp)
    800007dc:	6442                	ld	s0,16(sp)
    800007de:	64a2                	ld	s1,8(sp)
    800007e0:	6105                	addi	sp,sp,32
    800007e2:	8082                	ret

00000000800007e4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e4:	1141                	addi	sp,sp,-16
    800007e6:	e406                	sd	ra,8(sp)
    800007e8:	e022                	sd	s0,0(sp)
    800007ea:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ec:	100007b7          	lui	a5,0x10000
    800007f0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f4:	10000737          	lui	a4,0x10000
    800007f8:	f8000693          	li	a3,-128
    800007fc:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000800:	468d                	li	a3,3
    80000802:	10000637          	lui	a2,0x10000
    80000806:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080e:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000812:	10000737          	lui	a4,0x10000
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00008597          	auipc	a1,0x8
    80000824:	81858593          	addi	a1,a1,-2024 # 80008038 <etext+0x38>
    80000828:	00010517          	auipc	a0,0x10
    8000082c:	2d050513          	addi	a0,a0,720 # 80010af8 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	378080e7          	jalr	888(ra) # 80000ba8 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	addi	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	addi	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3a0080e7          	jalr	928(ra) # 80000bec <push_off>

  if(panicked){
    80000854:	00008797          	auipc	a5,0x8
    80000858:	05c7a783          	lw	a5,92(a5) # 800088b0 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	andi	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	412080e7          	jalr	1042(ra) # 80000c8c <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	addi	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	00008797          	auipc	a5,0x8
    80000892:	02a7b783          	ld	a5,42(a5) # 800088b8 <uart_tx_r>
    80000896:	00008717          	auipc	a4,0x8
    8000089a:	02a73703          	ld	a4,42(a4) # 800088c0 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	addi	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	addi	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00010a97          	auipc	s5,0x10
    800008c0:	23ca8a93          	addi	s5,s5,572 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	00008497          	auipc	s1,0x8
    800008c8:	ff448493          	addi	s1,s1,-12 # 800088b8 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	00008997          	auipc	s3,0x8
    800008d4:	ff098993          	addi	s3,s3,-16 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	andi	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	addi	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	8fa080e7          	jalr	-1798(ra) # 800021ec <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3)
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	addi	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	addi	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	addi	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00010517          	auipc	a0,0x10
    80000934:	1c850513          	addi	a0,a0,456 # 80010af8 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	300080e7          	jalr	768(ra) # 80000c38 <acquire>
  if(panicked){
    80000940:	00008797          	auipc	a5,0x8
    80000944:	f707a783          	lw	a5,-144(a5) # 800088b0 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	00008717          	auipc	a4,0x8
    8000094e:	f7673703          	ld	a4,-138(a4) # 800088c0 <uart_tx_w>
    80000952:	00008797          	auipc	a5,0x8
    80000956:	f667b783          	ld	a5,-154(a5) # 800088b8 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00010997          	auipc	s3,0x10
    80000962:	19a98993          	addi	s3,s3,410 # 80010af8 <uart_tx_lock>
    80000966:	00008497          	auipc	s1,0x8
    8000096a:	f5248493          	addi	s1,s1,-174 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	00008917          	auipc	s2,0x8
    80000972:	f5290913          	addi	s2,s2,-174 # 800088c0 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	80a080e7          	jalr	-2038(ra) # 80002188 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	addi	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00010497          	auipc	s1,0x10
    80000998:	16448493          	addi	s1,s1,356 # 80010af8 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	00008797          	auipc	a5,0x8
    800009ac:	f0e7bc23          	sd	a4,-232(a5) # 800088c0 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	332080e7          	jalr	818(ra) # 80000cec <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	addi	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	addi	sp,sp,-16
    800009d6:	e422                	sd	s0,8(sp)
    800009d8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009da:	100007b7          	lui	a5,0x10000
    800009de:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009e0:	0007c783          	lbu	a5,0(a5)
    800009e4:	8b85                	andi	a5,a5,1
    800009e6:	cb81                	beqz	a5,800009f6 <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	addi	sp,sp,16
    800009f4:	8082                	ret
    return -1;
    800009f6:	557d                	li	a0,-1
    800009f8:	bfe5                	j	800009f0 <uartgetc+0x1c>

00000000800009fa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a04:	54fd                	li	s1,-1
    80000a06:	a029                	j	80000a10 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	8ce080e7          	jalr	-1842(ra) # 800002d6 <consoleintr>
    int c = uartgetc();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	fc4080e7          	jalr	-60(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a18:	fe9518e3          	bne	a0,s1,80000a08 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1c:	00010497          	auipc	s1,0x10
    80000a20:	0dc48493          	addi	s1,s1,220 # 80010af8 <uart_tx_lock>
    80000a24:	8526                	mv	a0,s1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	212080e7          	jalr	530(ra) # 80000c38 <acquire>
  uartstart();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	e60080e7          	jalr	-416(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a36:	8526                	mv	a0,s1
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2b4080e7          	jalr	692(ra) # 80000cec <release>
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret

0000000080000a4a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4a:	1101                	addi	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	e04a                	sd	s2,0(sp)
    80000a54:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a56:	03451793          	slli	a5,a0,0x34
    80000a5a:	ebb9                	bnez	a5,80000ab0 <kfree+0x66>
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	00024797          	auipc	a5,0x24
    80000a62:	50278793          	addi	a5,a5,1282 # 80024f60 <end>
    80000a66:	04f56563          	bltu	a0,a5,80000ab0 <kfree+0x66>
    80000a6a:	47c5                	li	a5,17
    80000a6c:	07ee                	slli	a5,a5,0x1b
    80000a6e:	04f57163          	bgeu	a0,a5,80000ab0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2be080e7          	jalr	702(ra) # 80000d34 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	00010917          	auipc	s2,0x10
    80000a82:	0b290913          	addi	s2,s2,178 # 80010b30 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1b0080e7          	jalr	432(ra) # 80000c38 <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	250080e7          	jalr	592(ra) # 80000cec <release>
}
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6902                	ld	s2,0(sp)
    80000aac:	6105                	addi	sp,sp,32
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	59050513          	addi	a0,a0,1424 # 80008040 <etext+0x40>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	addi	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aca:	6785                	lui	a5,0x1
    80000acc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad0:	00e504b3          	add	s1,a0,a4
    80000ad4:	777d                	lui	a4,0xfffff
    80000ad6:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0295e463          	bltu	a1,s1,80000b02 <freerange+0x42>
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f5c080e7          	jalr	-164(ra) # 80000a4a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{
    80000b0c:	1141                	addi	sp,sp,-16
    80000b0e:	e406                	sd	ra,8(sp)
    80000b10:	e022                	sd	s0,0(sp)
    80000b12:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b14:	00007597          	auipc	a1,0x7
    80000b18:	53458593          	addi	a1,a1,1332 # 80008048 <etext+0x48>
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	01450513          	addi	a0,a0,20 # 80010b30 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	084080e7          	jalr	132(ra) # 80000ba8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	slli	a1,a1,0x1b
    80000b30:	00024517          	auipc	a0,0x24
    80000b34:	43050513          	addi	a0,a0,1072 # 80024f60 <end>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f88080e7          	jalr	-120(ra) # 80000ac0 <freerange>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b48:	1101                	addi	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b52:	00010497          	auipc	s1,0x10
    80000b56:	fde48493          	addi	s1,s1,-34 # 80010b30 <kmem>
    80000b5a:	8526                	mv	a0,s1
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0dc080e7          	jalr	220(ra) # 80000c38 <acquire>
  r = kmem.freelist;
    80000b64:	6c84                	ld	s1,24(s1)
  if(r)
    80000b66:	c885                	beqz	s1,80000b96 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b68:	609c                	ld	a5,0(s1)
    80000b6a:	00010517          	auipc	a0,0x10
    80000b6e:	fc650513          	addi	a0,a0,-58 # 80010b30 <kmem>
    80000b72:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	178080e7          	jalr	376(ra) # 80000cec <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7c:	6605                	lui	a2,0x1
    80000b7e:	4595                	li	a1,5
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	1b2080e7          	jalr	434(ra) # 80000d34 <memset>
  return (void*)r;
}
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	60e2                	ld	ra,24(sp)
    80000b8e:	6442                	ld	s0,16(sp)
    80000b90:	64a2                	ld	s1,8(sp)
    80000b92:	6105                	addi	sp,sp,32
    80000b94:	8082                	ret
  release(&kmem.lock);
    80000b96:	00010517          	auipc	a0,0x10
    80000b9a:	f9a50513          	addi	a0,a0,-102 # 80010b30 <kmem>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	14e080e7          	jalr	334(ra) # 80000cec <release>
  if(r)
    80000ba6:	b7d5                	j	80000b8a <kalloc+0x42>

0000000080000ba8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e422                	sd	s0,8(sp)
    80000bac:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bae:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb4:	00053823          	sd	zero,16(a0)
}
    80000bb8:	6422                	ld	s0,8(sp)
    80000bba:	0141                	addi	sp,sp,16
    80000bbc:	8082                	ret

0000000080000bbe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bbe:	411c                	lw	a5,0(a0)
    80000bc0:	e399                	bnez	a5,80000bc6 <holding+0x8>
    80000bc2:	4501                	li	a0,0
  return r;
}
    80000bc4:	8082                	ret
{
    80000bc6:	1101                	addi	sp,sp,-32
    80000bc8:	ec06                	sd	ra,24(sp)
    80000bca:	e822                	sd	s0,16(sp)
    80000bcc:	e426                	sd	s1,8(sp)
    80000bce:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd0:	6904                	ld	s1,16(a0)
    80000bd2:	00001097          	auipc	ra,0x1
    80000bd6:	e5c080e7          	jalr	-420(ra) # 80001a2e <mycpu>
    80000bda:	40a48533          	sub	a0,s1,a0
    80000bde:	00153513          	seqz	a0,a0
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret

0000000080000bec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bec:	1101                	addi	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf6:	100024f3          	csrr	s1,sstatus
    80000bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c04:	00001097          	auipc	ra,0x1
    80000c08:	e2a080e7          	jalr	-470(ra) # 80001a2e <mycpu>
    80000c0c:	5d3c                	lw	a5,120(a0)
    80000c0e:	cf89                	beqz	a5,80000c28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	e1e080e7          	jalr	-482(ra) # 80001a2e <mycpu>
    80000c18:	5d3c                	lw	a5,120(a0)
    80000c1a:	2785                	addiw	a5,a5,1
    80000c1c:	dd3c                	sw	a5,120(a0)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    mycpu()->intena = old;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	e06080e7          	jalr	-506(ra) # 80001a2e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c30:	8085                	srli	s1,s1,0x1
    80000c32:	8885                	andi	s1,s1,1
    80000c34:	dd64                	sw	s1,124(a0)
    80000c36:	bfe9                	j	80000c10 <push_off+0x24>

0000000080000c38 <acquire>:
{
    80000c38:	1101                	addi	sp,sp,-32
    80000c3a:	ec06                	sd	ra,24(sp)
    80000c3c:	e822                	sd	s0,16(sp)
    80000c3e:	e426                	sd	s1,8(sp)
    80000c40:	1000                	addi	s0,sp,32
    80000c42:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	fa8080e7          	jalr	-88(ra) # 80000bec <push_off>
  if(holding(lk))
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	f70080e7          	jalr	-144(ra) # 80000bbe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	4705                	li	a4,1
  if(holding(lk))
    80000c58:	e115                	bnez	a0,80000c7c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5a:	87ba                	mv	a5,a4
    80000c5c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c60:	2781                	sext.w	a5,a5
    80000c62:	ffe5                	bnez	a5,80000c5a <acquire+0x22>
  __sync_synchronize();
    80000c64:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	dc6080e7          	jalr	-570(ra) # 80001a2e <mycpu>
    80000c70:	e888                	sd	a0,16(s1)
}
    80000c72:	60e2                	ld	ra,24(sp)
    80000c74:	6442                	ld	s0,16(sp)
    80000c76:	64a2                	ld	s1,8(sp)
    80000c78:	6105                	addi	sp,sp,32
    80000c7a:	8082                	ret
    panic("acquire");
    80000c7c:	00007517          	auipc	a0,0x7
    80000c80:	3d450513          	addi	a0,a0,980 # 80008050 <etext+0x50>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	8dc080e7          	jalr	-1828(ra) # 80000560 <panic>

0000000080000c8c <pop_off>:

void
pop_off(void)
{
    80000c8c:	1141                	addi	sp,sp,-16
    80000c8e:	e406                	sd	ra,8(sp)
    80000c90:	e022                	sd	s0,0(sp)
    80000c92:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c94:	00001097          	auipc	ra,0x1
    80000c98:	d9a080e7          	jalr	-614(ra) # 80001a2e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ca2:	e78d                	bnez	a5,80000ccc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca4:	5d3c                	lw	a5,120(a0)
    80000ca6:	02f05b63          	blez	a5,80000cdc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000caa:	37fd                	addiw	a5,a5,-1
    80000cac:	0007871b          	sext.w	a4,a5
    80000cb0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb2:	eb09                	bnez	a4,80000cc4 <pop_off+0x38>
    80000cb4:	5d7c                	lw	a5,124(a0)
    80000cb6:	c799                	beqz	a5,80000cc4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc4:	60a2                	ld	ra,8(sp)
    80000cc6:	6402                	ld	s0,0(sp)
    80000cc8:	0141                	addi	sp,sp,16
    80000cca:	8082                	ret
    panic("pop_off - interruptible");
    80000ccc:	00007517          	auipc	a0,0x7
    80000cd0:	38c50513          	addi	a0,a0,908 # 80008058 <etext+0x58>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	88c080e7          	jalr	-1908(ra) # 80000560 <panic>
    panic("pop_off");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39450513          	addi	a0,a0,916 # 80008070 <etext+0x70>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	87c080e7          	jalr	-1924(ra) # 80000560 <panic>

0000000080000cec <release>:
{
    80000cec:	1101                	addi	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	addi	s0,sp,32
    80000cf6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	ec6080e7          	jalr	-314(ra) # 80000bbe <holding>
    80000d00:	c115                	beqz	a0,80000d24 <release+0x38>
  lk->cpu = 0;
    80000d02:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d06:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d0a:	0f50000f          	fence	iorw,ow
    80000d0e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	f7a080e7          	jalr	-134(ra) # 80000c8c <pop_off>
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	addi	sp,sp,32
    80000d22:	8082                	ret
    panic("release");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	35450513          	addi	a0,a0,852 # 80008078 <etext+0x78>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	834080e7          	jalr	-1996(ra) # 80000560 <panic>

0000000080000d34 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d34:	1141                	addi	sp,sp,-16
    80000d36:	e422                	sd	s0,8(sp)
    80000d38:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d3a:	ca19                	beqz	a2,80000d50 <memset+0x1c>
    80000d3c:	87aa                	mv	a5,a0
    80000d3e:	1602                	slli	a2,a2,0x20
    80000d40:	9201                	srli	a2,a2,0x20
    80000d42:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	addi	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x12>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d62:	1682                	slli	a3,a3,0x20
    80000d64:	9281                	srli	a3,a3,0x20
    80000d66:	0685                	addi	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	addi	a0,a0,1
    80000d78:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d96:	c205                	beqz	a2,80000db6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d98:	02a5e263          	bltu	a1,a0,80000dbc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d9c:	1602                	slli	a2,a2,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	00c587b3          	add	a5,a1,a2
{
    80000da4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000da6:	0585                	addi	a1,a1,1
    80000da8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda0a1>
    80000daa:	fff5c683          	lbu	a3,-1(a1)
    80000dae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000db2:	feb79ae3          	bne	a5,a1,80000da6 <memmove+0x16>

  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	addi	sp,sp,16
    80000dba:	8082                	ret
  if(s < d && s + n > d){
    80000dbc:	02061693          	slli	a3,a2,0x20
    80000dc0:	9281                	srli	a3,a3,0x20
    80000dc2:	00d58733          	add	a4,a1,a3
    80000dc6:	fce57be3          	bgeu	a0,a4,80000d9c <memmove+0xc>
    d += n;
    80000dca:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dcc:	fff6079b          	addiw	a5,a2,-1
    80000dd0:	1782                	slli	a5,a5,0x20
    80000dd2:	9381                	srli	a5,a5,0x20
    80000dd4:	fff7c793          	not	a5,a5
    80000dd8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dda:	177d                	addi	a4,a4,-1
    80000ddc:	16fd                	addi	a3,a3,-1
    80000dde:	00074603          	lbu	a2,0(a4)
    80000de2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de6:	fef71ae3          	bne	a4,a5,80000dda <memmove+0x4a>
    80000dea:	b7f1                	j	80000db6 <memmove+0x26>

0000000080000dec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e406                	sd	ra,8(sp)
    80000df0:	e022                	sd	s0,0(sp)
    80000df2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df4:	00000097          	auipc	ra,0x0
    80000df8:	f9c080e7          	jalr	-100(ra) # 80000d90 <memmove>
}
    80000dfc:	60a2                	ld	ra,8(sp)
    80000dfe:	6402                	ld	s0,0(sp)
    80000e00:	0141                	addi	sp,sp,16
    80000e02:	8082                	ret

0000000080000e04 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e04:	1141                	addi	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0a:	ce11                	beqz	a2,80000e26 <strncmp+0x22>
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	cf89                	beqz	a5,80000e2a <strncmp+0x26>
    80000e12:	0005c703          	lbu	a4,0(a1)
    80000e16:	00f71a63          	bne	a4,a5,80000e2a <strncmp+0x26>
    n--, p++, q++;
    80000e1a:	367d                	addiw	a2,a2,-1
    80000e1c:	0505                	addi	a0,a0,1
    80000e1e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e20:	f675                	bnez	a2,80000e0c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e22:	4501                	li	a0,0
    80000e24:	a801                	j	80000e34 <strncmp+0x30>
    80000e26:	4501                	li	a0,0
    80000e28:	a031                	j	80000e34 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000e2a:	00054503          	lbu	a0,0(a0)
    80000e2e:	0005c783          	lbu	a5,0(a1)
    80000e32:	9d1d                	subw	a0,a0,a5
}
    80000e34:	6422                	ld	s0,8(sp)
    80000e36:	0141                	addi	sp,sp,16
    80000e38:	8082                	ret

0000000080000e3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e40:	87aa                	mv	a5,a0
    80000e42:	86b2                	mv	a3,a2
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	02d05563          	blez	a3,80000e70 <strncpy+0x36>
    80000e4a:	0785                	addi	a5,a5,1
    80000e4c:	0005c703          	lbu	a4,0(a1)
    80000e50:	fee78fa3          	sb	a4,-1(a5)
    80000e54:	0585                	addi	a1,a1,1
    80000e56:	f775                	bnez	a4,80000e42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e58:	873e                	mv	a4,a5
    80000e5a:	9fb5                	addw	a5,a5,a3
    80000e5c:	37fd                	addiw	a5,a5,-1
    80000e5e:	00c05963          	blez	a2,80000e70 <strncpy+0x36>
    *s++ = 0;
    80000e62:	0705                	addi	a4,a4,1
    80000e64:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e68:	40e786bb          	subw	a3,a5,a4
    80000e6c:	fed04be3          	bgtz	a3,80000e62 <strncpy+0x28>
  return os;
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	addi	sp,sp,16
    80000e74:	8082                	ret

0000000080000e76 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e7c:	02c05363          	blez	a2,80000ea2 <safestrcpy+0x2c>
    80000e80:	fff6069b          	addiw	a3,a2,-1
    80000e84:	1682                	slli	a3,a3,0x20
    80000e86:	9281                	srli	a3,a3,0x20
    80000e88:	96ae                	add	a3,a3,a1
    80000e8a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e8c:	00d58963          	beq	a1,a3,80000e9e <safestrcpy+0x28>
    80000e90:	0585                	addi	a1,a1,1
    80000e92:	0785                	addi	a5,a5,1
    80000e94:	fff5c703          	lbu	a4,-1(a1)
    80000e98:	fee78fa3          	sb	a4,-1(a5)
    80000e9c:	fb65                	bnez	a4,80000e8c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e9e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <strlen>:

int
strlen(const char *s)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eae:	00054783          	lbu	a5,0(a0)
    80000eb2:	cf91                	beqz	a5,80000ece <strlen+0x26>
    80000eb4:	0505                	addi	a0,a0,1
    80000eb6:	87aa                	mv	a5,a0
    80000eb8:	86be                	mv	a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	ff65                	bnez	a4,80000eb8 <strlen+0x10>
    80000ec2:	40a6853b          	subw	a0,a3,a0
    80000ec6:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <strlen+0x20>

0000000080000ed2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e406                	sd	ra,8(sp)
    80000ed6:	e022                	sd	s0,0(sp)
    80000ed8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	b44080e7          	jalr	-1212(ra) # 80001a1e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ee2:	00008717          	auipc	a4,0x8
    80000ee6:	9e670713          	addi	a4,a4,-1562 # 800088c8 <started>
  if(cpuid() == 0){
    80000eea:	c139                	beqz	a0,80000f30 <main+0x5e>
    while(started == 0)
    80000eec:	431c                	lw	a5,0(a4)
    80000eee:	2781                	sext.w	a5,a5
    80000ef0:	dff5                	beqz	a5,80000eec <main+0x1a>
      ;
    __sync_synchronize();
    80000ef2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	b28080e7          	jalr	-1240(ra) # 80001a1e <cpuid>
    80000efe:	85aa                	mv	a1,a0
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	19850513          	addi	a0,a0,408 # 80008098 <etext+0x98>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	6a2080e7          	jalr	1698(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	0d8080e7          	jalr	216(ra) # 80000fe8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f18:	00002097          	auipc	ra,0x2
    80000f1c:	a86080e7          	jalr	-1402(ra) # 8000299e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f20:	00005097          	auipc	ra,0x5
    80000f24:	4c4080e7          	jalr	1220(ra) # 800063e4 <plicinithart>
  }

  scheduler();        
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	0ae080e7          	jalr	174(ra) # 80001fd6 <scheduler>
    consoleinit();
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	540080e7          	jalr	1344(ra) # 80000470 <consoleinit>
    printfinit();
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	87a080e7          	jalr	-1926(ra) # 800007b2 <printfinit>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	0d050513          	addi	a0,a0,208 # 80008010 <etext+0x10>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	662080e7          	jalr	1634(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	13050513          	addi	a0,a0,304 # 80008080 <etext+0x80>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	652080e7          	jalr	1618(ra) # 800005aa <printf>
    printf("\n");
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	0b050513          	addi	a0,a0,176 # 80008010 <etext+0x10>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	642080e7          	jalr	1602(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	b9c080e7          	jalr	-1124(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	326080e7          	jalr	806(ra) # 8000129e <kvminit>
    kvminithart();   // turn on paging
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	068080e7          	jalr	104(ra) # 80000fe8 <kvminithart>
    procinit();      // process table
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	9d4080e7          	jalr	-1580(ra) # 8000195c <procinit>
    trapinit();      // trap vectors
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	9e6080e7          	jalr	-1562(ra) # 80002976 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	a06080e7          	jalr	-1530(ra) # 8000299e <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	42a080e7          	jalr	1066(ra) # 800063ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	43c080e7          	jalr	1084(ra) # 800063e4 <plicinithart>
    binit();         // buffer cache
    80000fb0:	00002097          	auipc	ra,0x2
    80000fb4:	4fc080e7          	jalr	1276(ra) # 800034ac <binit>
    iinit();         // inode table
    80000fb8:	00003097          	auipc	ra,0x3
    80000fbc:	bb2080e7          	jalr	-1102(ra) # 80003b6a <iinit>
    fileinit();      // file table
    80000fc0:	00004097          	auipc	ra,0x4
    80000fc4:	b62080e7          	jalr	-1182(ra) # 80004b22 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc8:	00005097          	auipc	ra,0x5
    80000fcc:	524080e7          	jalr	1316(ra) # 800064ec <virtio_disk_init>
    userinit();      // first user process
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	dcc080e7          	jalr	-564(ra) # 80001d9c <userinit>
    __sync_synchronize();
    80000fd8:	0ff0000f          	fence
    started = 1;
    80000fdc:	4785                	li	a5,1
    80000fde:	00008717          	auipc	a4,0x8
    80000fe2:	8ef72523          	sw	a5,-1814(a4) # 800088c8 <started>
    80000fe6:	b789                	j	80000f28 <main+0x56>

0000000080000fe8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe8:	1141                	addi	sp,sp,-16
    80000fea:	e422                	sd	s0,8(sp)
    80000fec:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ff2:	00008797          	auipc	a5,0x8
    80000ff6:	8de7b783          	ld	a5,-1826(a5) # 800088d0 <kernel_pagetable>
    80000ffa:	83b1                	srli	a5,a5,0xc
    80000ffc:	577d                	li	a4,-1
    80000ffe:	177e                	slli	a4,a4,0x3f
    80001000:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001002:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001006:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000100a:	6422                	ld	s0,8(sp)
    8000100c:	0141                	addi	sp,sp,16
    8000100e:	8082                	ret

0000000080001010 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001010:	7139                	addi	sp,sp,-64
    80001012:	fc06                	sd	ra,56(sp)
    80001014:	f822                	sd	s0,48(sp)
    80001016:	f426                	sd	s1,40(sp)
    80001018:	f04a                	sd	s2,32(sp)
    8000101a:	ec4e                	sd	s3,24(sp)
    8000101c:	e852                	sd	s4,16(sp)
    8000101e:	e456                	sd	s5,8(sp)
    80001020:	e05a                	sd	s6,0(sp)
    80001022:	0080                	addi	s0,sp,64
    80001024:	84aa                	mv	s1,a0
    80001026:	89ae                	mv	s3,a1
    80001028:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000102a:	57fd                	li	a5,-1
    8000102c:	83e9                	srli	a5,a5,0x1a
    8000102e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001030:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001032:	04b7f263          	bgeu	a5,a1,80001076 <walk+0x66>
    panic("walk");
    80001036:	00007517          	auipc	a0,0x7
    8000103a:	07a50513          	addi	a0,a0,122 # 800080b0 <etext+0xb0>
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	522080e7          	jalr	1314(ra) # 80000560 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001046:	060a8663          	beqz	s5,800010b2 <walk+0xa2>
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	afe080e7          	jalr	-1282(ra) # 80000b48 <kalloc>
    80001052:	84aa                	mv	s1,a0
    80001054:	c529                	beqz	a0,8000109e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001056:	6605                	lui	a2,0x1
    80001058:	4581                	li	a1,0
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	cda080e7          	jalr	-806(ra) # 80000d34 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001062:	00c4d793          	srli	a5,s1,0xc
    80001066:	07aa                	slli	a5,a5,0xa
    80001068:	0017e793          	ori	a5,a5,1
    8000106c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001070:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda097>
    80001072:	036a0063          	beq	s4,s6,80001092 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001076:	0149d933          	srl	s2,s3,s4
    8000107a:	1ff97913          	andi	s2,s2,511
    8000107e:	090e                	slli	s2,s2,0x3
    80001080:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001082:	00093483          	ld	s1,0(s2)
    80001086:	0014f793          	andi	a5,s1,1
    8000108a:	dfd5                	beqz	a5,80001046 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000108c:	80a9                	srli	s1,s1,0xa
    8000108e:	04b2                	slli	s1,s1,0xc
    80001090:	b7c5                	j	80001070 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001092:	00c9d513          	srli	a0,s3,0xc
    80001096:	1ff57513          	andi	a0,a0,511
    8000109a:	050e                	slli	a0,a0,0x3
    8000109c:	9526                	add	a0,a0,s1
}
    8000109e:	70e2                	ld	ra,56(sp)
    800010a0:	7442                	ld	s0,48(sp)
    800010a2:	74a2                	ld	s1,40(sp)
    800010a4:	7902                	ld	s2,32(sp)
    800010a6:	69e2                	ld	s3,24(sp)
    800010a8:	6a42                	ld	s4,16(sp)
    800010aa:	6aa2                	ld	s5,8(sp)
    800010ac:	6b02                	ld	s6,0(sp)
    800010ae:	6121                	addi	sp,sp,64
    800010b0:	8082                	ret
        return 0;
    800010b2:	4501                	li	a0,0
    800010b4:	b7ed                	j	8000109e <walk+0x8e>

00000000800010b6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010b6:	57fd                	li	a5,-1
    800010b8:	83e9                	srli	a5,a5,0x1a
    800010ba:	00b7f463          	bgeu	a5,a1,800010c2 <walkaddr+0xc>
    return 0;
    800010be:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c0:	8082                	ret
{
    800010c2:	1141                	addi	sp,sp,-16
    800010c4:	e406                	sd	ra,8(sp)
    800010c6:	e022                	sd	s0,0(sp)
    800010c8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00000097          	auipc	ra,0x0
    800010d0:	f44080e7          	jalr	-188(ra) # 80001010 <walk>
  if(pte == 0)
    800010d4:	c105                	beqz	a0,800010f4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010d6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010d8:	0117f693          	andi	a3,a5,17
    800010dc:	4745                	li	a4,17
    return 0;
    800010de:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e0:	00e68663          	beq	a3,a4,800010ec <walkaddr+0x36>
}
    800010e4:	60a2                	ld	ra,8(sp)
    800010e6:	6402                	ld	s0,0(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret
  pa = PTE2PA(*pte);
    800010ec:	83a9                	srli	a5,a5,0xa
    800010ee:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010f2:	bfcd                	j	800010e4 <walkaddr+0x2e>
    return 0;
    800010f4:	4501                	li	a0,0
    800010f6:	b7fd                	j	800010e4 <walkaddr+0x2e>

00000000800010f8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010f8:	715d                	addi	sp,sp,-80
    800010fa:	e486                	sd	ra,72(sp)
    800010fc:	e0a2                	sd	s0,64(sp)
    800010fe:	fc26                	sd	s1,56(sp)
    80001100:	f84a                	sd	s2,48(sp)
    80001102:	f44e                	sd	s3,40(sp)
    80001104:	f052                	sd	s4,32(sp)
    80001106:	ec56                	sd	s5,24(sp)
    80001108:	e85a                	sd	s6,16(sp)
    8000110a:	e45e                	sd	s7,8(sp)
    8000110c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000110e:	c639                	beqz	a2,8000115c <mappages+0x64>
    80001110:	8aaa                	mv	s5,a0
    80001112:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001114:	777d                	lui	a4,0xfffff
    80001116:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000111a:	fff58993          	addi	s3,a1,-1
    8000111e:	99b2                	add	s3,s3,a2
    80001120:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001124:	893e                	mv	s2,a5
    80001126:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112a:	6b85                	lui	s7,0x1
    8000112c:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eda080e7          	jalr	-294(ra) # 80001010 <walk>
    8000113e:	cd1d                	beqz	a0,8000117c <mappages+0x84>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	e785                	bnez	a5,8000116c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	05390063          	beq	s2,s3,80001194 <mappages+0x9c>
    a += PGSIZE;
    80001158:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115a:	bfc9                	j	8000112c <mappages+0x34>
    panic("mappages: size");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f5c50513          	addi	a0,a0,-164 # 800080b8 <etext+0xb8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3fc080e7          	jalr	1020(ra) # 80000560 <panic>
      panic("mappages: remap");
    8000116c:	00007517          	auipc	a0,0x7
    80001170:	f5c50513          	addi	a0,a0,-164 # 800080c8 <etext+0xc8>
    80001174:	fffff097          	auipc	ra,0xfffff
    80001178:	3ec080e7          	jalr	1004(ra) # 80000560 <panic>
      return -1;
    8000117c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000117e:	60a6                	ld	ra,72(sp)
    80001180:	6406                	ld	s0,64(sp)
    80001182:	74e2                	ld	s1,56(sp)
    80001184:	7942                	ld	s2,48(sp)
    80001186:	79a2                	ld	s3,40(sp)
    80001188:	7a02                	ld	s4,32(sp)
    8000118a:	6ae2                	ld	s5,24(sp)
    8000118c:	6b42                	ld	s6,16(sp)
    8000118e:	6ba2                	ld	s7,8(sp)
    80001190:	6161                	addi	sp,sp,80
    80001192:	8082                	ret
  return 0;
    80001194:	4501                	li	a0,0
    80001196:	b7e5                	j	8000117e <mappages+0x86>

0000000080001198 <kvmmap>:
{
    80001198:	1141                	addi	sp,sp,-16
    8000119a:	e406                	sd	ra,8(sp)
    8000119c:	e022                	sd	s0,0(sp)
    8000119e:	0800                	addi	s0,sp,16
    800011a0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011a2:	86b2                	mv	a3,a2
    800011a4:	863e                	mv	a2,a5
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	f52080e7          	jalr	-174(ra) # 800010f8 <mappages>
    800011ae:	e509                	bnez	a0,800011b8 <kvmmap+0x20>
}
    800011b0:	60a2                	ld	ra,8(sp)
    800011b2:	6402                	ld	s0,0(sp)
    800011b4:	0141                	addi	sp,sp,16
    800011b6:	8082                	ret
    panic("kvmmap");
    800011b8:	00007517          	auipc	a0,0x7
    800011bc:	f2050513          	addi	a0,a0,-224 # 800080d8 <etext+0xd8>
    800011c0:	fffff097          	auipc	ra,0xfffff
    800011c4:	3a0080e7          	jalr	928(ra) # 80000560 <panic>

00000000800011c8 <kvmmake>:
{
    800011c8:	1101                	addi	sp,sp,-32
    800011ca:	ec06                	sd	ra,24(sp)
    800011cc:	e822                	sd	s0,16(sp)
    800011ce:	e426                	sd	s1,8(sp)
    800011d0:	e04a                	sd	s2,0(sp)
    800011d2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	974080e7          	jalr	-1676(ra) # 80000b48 <kalloc>
    800011dc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011de:	6605                	lui	a2,0x1
    800011e0:	4581                	li	a1,0
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	b52080e7          	jalr	-1198(ra) # 80000d34 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ea:	4719                	li	a4,6
    800011ec:	6685                	lui	a3,0x1
    800011ee:	10000637          	lui	a2,0x10000
    800011f2:	100005b7          	lui	a1,0x10000
    800011f6:	8526                	mv	a0,s1
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	fa0080e7          	jalr	-96(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001200:	4719                	li	a4,6
    80001202:	6685                	lui	a3,0x1
    80001204:	10001637          	lui	a2,0x10001
    80001208:	100015b7          	lui	a1,0x10001
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f8a080e7          	jalr	-118(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	004006b7          	lui	a3,0x400
    8000121c:	0c000637          	lui	a2,0xc000
    80001220:	0c0005b7          	lui	a1,0xc000
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f72080e7          	jalr	-142(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000122e:	00007917          	auipc	s2,0x7
    80001232:	dd290913          	addi	s2,s2,-558 # 80008000 <etext>
    80001236:	4729                	li	a4,10
    80001238:	80007697          	auipc	a3,0x80007
    8000123c:	dc868693          	addi	a3,a3,-568 # 8000 <_entry-0x7fff8000>
    80001240:	4605                	li	a2,1
    80001242:	067e                	slli	a2,a2,0x1f
    80001244:	85b2                	mv	a1,a2
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f50080e7          	jalr	-176(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001250:	46c5                	li	a3,17
    80001252:	06ee                	slli	a3,a3,0x1b
    80001254:	4719                	li	a4,6
    80001256:	412686b3          	sub	a3,a3,s2
    8000125a:	864a                	mv	a2,s2
    8000125c:	85ca                	mv	a1,s2
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f38080e7          	jalr	-200(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001268:	4729                	li	a4,10
    8000126a:	6685                	lui	a3,0x1
    8000126c:	00006617          	auipc	a2,0x6
    80001270:	d9460613          	addi	a2,a2,-620 # 80007000 <_trampoline>
    80001274:	040005b7          	lui	a1,0x4000
    80001278:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000127a:	05b2                	slli	a1,a1,0xc
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f1a080e7          	jalr	-230(ra) # 80001198 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001286:	8526                	mv	a0,s1
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	630080e7          	jalr	1584(ra) # 800018b8 <proc_mapstacks>
}
    80001290:	8526                	mv	a0,s1
    80001292:	60e2                	ld	ra,24(sp)
    80001294:	6442                	ld	s0,16(sp)
    80001296:	64a2                	ld	s1,8(sp)
    80001298:	6902                	ld	s2,0(sp)
    8000129a:	6105                	addi	sp,sp,32
    8000129c:	8082                	ret

000000008000129e <kvminit>:
{
    8000129e:	1141                	addi	sp,sp,-16
    800012a0:	e406                	sd	ra,8(sp)
    800012a2:	e022                	sd	s0,0(sp)
    800012a4:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f22080e7          	jalr	-222(ra) # 800011c8 <kvmmake>
    800012ae:	00007797          	auipc	a5,0x7
    800012b2:	62a7b123          	sd	a0,1570(a5) # 800088d0 <kernel_pagetable>
}
    800012b6:	60a2                	ld	ra,8(sp)
    800012b8:	6402                	ld	s0,0(sp)
    800012ba:	0141                	addi	sp,sp,16
    800012bc:	8082                	ret

00000000800012be <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012be:	715d                	addi	sp,sp,-80
    800012c0:	e486                	sd	ra,72(sp)
    800012c2:	e0a2                	sd	s0,64(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e39d                	bnez	a5,800012f0 <uvmunmap+0x32>
    800012cc:	f84a                	sd	s2,48(sp)
    800012ce:	f44e                	sd	s3,40(sp)
    800012d0:	f052                	sd	s4,32(sp)
    800012d2:	ec56                	sd	s5,24(sp)
    800012d4:	e85a                	sd	s6,16(sp)
    800012d6:	e45e                	sd	s7,8(sp)
    800012d8:	8a2a                	mv	s4,a0
    800012da:	892e                	mv	s2,a1
    800012dc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012de:	0632                	slli	a2,a2,0xc
    800012e0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	6b05                	lui	s6,0x1
    800012e8:	0935fb63          	bgeu	a1,s3,8000137e <uvmunmap+0xc0>
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	a8a9                	j	80001348 <uvmunmap+0x8a>
    800012f0:	fc26                	sd	s1,56(sp)
    800012f2:	f84a                	sd	s2,48(sp)
    800012f4:	f44e                	sd	s3,40(sp)
    800012f6:	f052                	sd	s4,32(sp)
    800012f8:	ec56                	sd	s5,24(sp)
    800012fa:	e85a                	sd	s6,16(sp)
    800012fc:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	de250513          	addi	a0,a0,-542 # 800080e0 <etext+0xe0>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	25a080e7          	jalr	602(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	dea50513          	addi	a0,a0,-534 # 800080f8 <etext+0xf8>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	24a080e7          	jalr	586(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	dea50513          	addi	a0,a0,-534 # 80008108 <etext+0x108>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	23a080e7          	jalr	570(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	df250513          	addi	a0,a0,-526 # 80008120 <etext+0x120>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	22a080e7          	jalr	554(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    8000133e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	995a                	add	s2,s2,s6
    80001344:	03397c63          	bgeu	s2,s3,8000137c <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001348:	4601                	li	a2,0
    8000134a:	85ca                	mv	a1,s2
    8000134c:	8552                	mv	a0,s4
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	cc2080e7          	jalr	-830(ra) # 80001010 <walk>
    80001356:	84aa                	mv	s1,a0
    80001358:	d95d                	beqz	a0,8000130e <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    8000135a:	6108                	ld	a0,0(a0)
    8000135c:	00157793          	andi	a5,a0,1
    80001360:	dfdd                	beqz	a5,8000131e <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001362:	3ff57793          	andi	a5,a0,1023
    80001366:	fd7784e3          	beq	a5,s7,8000132e <uvmunmap+0x70>
    if(do_free){
    8000136a:	fc0a8ae3          	beqz	s5,8000133e <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    8000136e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001370:	0532                	slli	a0,a0,0xc
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	6d8080e7          	jalr	1752(ra) # 80000a4a <kfree>
    8000137a:	b7d1                	j	8000133e <uvmunmap+0x80>
    8000137c:	74e2                	ld	s1,56(sp)
    8000137e:	7942                	ld	s2,48(sp)
    80001380:	79a2                	ld	s3,40(sp)
    80001382:	7a02                	ld	s4,32(sp)
    80001384:	6ae2                	ld	s5,24(sp)
    80001386:	6b42                	ld	s6,16(sp)
    80001388:	6ba2                	ld	s7,8(sp)
  }
}
    8000138a:	60a6                	ld	ra,72(sp)
    8000138c:	6406                	ld	s0,64(sp)
    8000138e:	6161                	addi	sp,sp,80
    80001390:	8082                	ret

0000000080001392 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001392:	1101                	addi	sp,sp,-32
    80001394:	ec06                	sd	ra,24(sp)
    80001396:	e822                	sd	s0,16(sp)
    80001398:	e426                	sd	s1,8(sp)
    8000139a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	7ac080e7          	jalr	1964(ra) # 80000b48 <kalloc>
    800013a4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a6:	c519                	beqz	a0,800013b4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	988080e7          	jalr	-1656(ra) # 80000d34 <memset>
  return pagetable;
}
    800013b4:	8526                	mv	a0,s1
    800013b6:	60e2                	ld	ra,24(sp)
    800013b8:	6442                	ld	s0,16(sp)
    800013ba:	64a2                	ld	s1,8(sp)
    800013bc:	6105                	addi	sp,sp,32
    800013be:	8082                	ret

00000000800013c0 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c0:	7179                	addi	sp,sp,-48
    800013c2:	f406                	sd	ra,40(sp)
    800013c4:	f022                	sd	s0,32(sp)
    800013c6:	ec26                	sd	s1,24(sp)
    800013c8:	e84a                	sd	s2,16(sp)
    800013ca:	e44e                	sd	s3,8(sp)
    800013cc:	e052                	sd	s4,0(sp)
    800013ce:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d0:	6785                	lui	a5,0x1
    800013d2:	04f67863          	bgeu	a2,a5,80001422 <uvmfirst+0x62>
    800013d6:	8a2a                	mv	s4,a0
    800013d8:	89ae                	mv	s3,a1
    800013da:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	76c080e7          	jalr	1900(ra) # 80000b48 <kalloc>
    800013e4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e6:	6605                	lui	a2,0x1
    800013e8:	4581                	li	a1,0
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	94a080e7          	jalr	-1718(ra) # 80000d34 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013f2:	4779                	li	a4,30
    800013f4:	86ca                	mv	a3,s2
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	cfc080e7          	jalr	-772(ra) # 800010f8 <mappages>
  memmove(mem, src, sz);
    80001404:	8626                	mv	a2,s1
    80001406:	85ce                	mv	a1,s3
    80001408:	854a                	mv	a0,s2
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	986080e7          	jalr	-1658(ra) # 80000d90 <memmove>
}
    80001412:	70a2                	ld	ra,40(sp)
    80001414:	7402                	ld	s0,32(sp)
    80001416:	64e2                	ld	s1,24(sp)
    80001418:	6942                	ld	s2,16(sp)
    8000141a:	69a2                	ld	s3,8(sp)
    8000141c:	6a02                	ld	s4,0(sp)
    8000141e:	6145                	addi	sp,sp,48
    80001420:	8082                	ret
    panic("uvmfirst: more than a page");
    80001422:	00007517          	auipc	a0,0x7
    80001426:	d1650513          	addi	a0,a0,-746 # 80008138 <etext+0x138>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	136080e7          	jalr	310(ra) # 80000560 <panic>

0000000080001432 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000143c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143e:	00b67d63          	bgeu	a2,a1,80001458 <uvmdealloc+0x26>
    80001442:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001444:	6785                	lui	a5,0x1
    80001446:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001448:	00f60733          	add	a4,a2,a5
    8000144c:	76fd                	lui	a3,0xfffff
    8000144e:	8f75                	and	a4,a4,a3
    80001450:	97ae                	add	a5,a5,a1
    80001452:	8ff5                	and	a5,a5,a3
    80001454:	00f76863          	bltu	a4,a5,80001464 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001464:	8f99                	sub	a5,a5,a4
    80001466:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001468:	4685                	li	a3,1
    8000146a:	0007861b          	sext.w	a2,a5
    8000146e:	85ba                	mv	a1,a4
    80001470:	00000097          	auipc	ra,0x0
    80001474:	e4e080e7          	jalr	-434(ra) # 800012be <uvmunmap>
    80001478:	b7c5                	j	80001458 <uvmdealloc+0x26>

000000008000147a <uvmalloc>:
  if(newsz < oldsz)
    8000147a:	0ab66b63          	bltu	a2,a1,80001530 <uvmalloc+0xb6>
{
    8000147e:	7139                	addi	sp,sp,-64
    80001480:	fc06                	sd	ra,56(sp)
    80001482:	f822                	sd	s0,48(sp)
    80001484:	ec4e                	sd	s3,24(sp)
    80001486:	e852                	sd	s4,16(sp)
    80001488:	e456                	sd	s5,8(sp)
    8000148a:	0080                	addi	s0,sp,64
    8000148c:	8aaa                	mv	s5,a0
    8000148e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001490:	6785                	lui	a5,0x1
    80001492:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001494:	95be                	add	a1,a1,a5
    80001496:	77fd                	lui	a5,0xfffff
    80001498:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	08c9fc63          	bgeu	s3,a2,80001534 <uvmalloc+0xba>
    800014a0:	f426                	sd	s1,40(sp)
    800014a2:	f04a                	sd	s2,32(sp)
    800014a4:	e05a                	sd	s6,0(sp)
    800014a6:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a8:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	69c080e7          	jalr	1692(ra) # 80000b48 <kalloc>
    800014b4:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b6:	c915                	beqz	a0,800014ea <uvmalloc+0x70>
    memset(mem, 0, PGSIZE);
    800014b8:	6605                	lui	a2,0x1
    800014ba:	4581                	li	a1,0
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	878080e7          	jalr	-1928(ra) # 80000d34 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014c4:	875a                	mv	a4,s6
    800014c6:	86a6                	mv	a3,s1
    800014c8:	6605                	lui	a2,0x1
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	c2a080e7          	jalr	-982(ra) # 800010f8 <mappages>
    800014d6:	ed05                	bnez	a0,8000150e <uvmalloc+0x94>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d8:	6785                	lui	a5,0x1
    800014da:	993e                	add	s2,s2,a5
    800014dc:	fd4968e3          	bltu	s2,s4,800014ac <uvmalloc+0x32>
  return newsz;
    800014e0:	8552                	mv	a0,s4
    800014e2:	74a2                	ld	s1,40(sp)
    800014e4:	7902                	ld	s2,32(sp)
    800014e6:	6b02                	ld	s6,0(sp)
    800014e8:	a821                	j	80001500 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f42080e7          	jalr	-190(ra) # 80001432 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	6b02                	ld	s6,0(sp)
}
    80001500:	70e2                	ld	ra,56(sp)
    80001502:	7442                	ld	s0,48(sp)
    80001504:	69e2                	ld	s3,24(sp)
    80001506:	6a42                	ld	s4,16(sp)
    80001508:	6aa2                	ld	s5,8(sp)
    8000150a:	6121                	addi	sp,sp,64
    8000150c:	8082                	ret
      kfree(mem);
    8000150e:	8526                	mv	a0,s1
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	53a080e7          	jalr	1338(ra) # 80000a4a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001518:	864e                	mv	a2,s3
    8000151a:	85ca                	mv	a1,s2
    8000151c:	8556                	mv	a0,s5
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	f14080e7          	jalr	-236(ra) # 80001432 <uvmdealloc>
      return 0;
    80001526:	4501                	li	a0,0
    80001528:	74a2                	ld	s1,40(sp)
    8000152a:	7902                	ld	s2,32(sp)
    8000152c:	6b02                	ld	s6,0(sp)
    8000152e:	bfc9                	j	80001500 <uvmalloc+0x86>
    return oldsz;
    80001530:	852e                	mv	a0,a1
}
    80001532:	8082                	ret
  return newsz;
    80001534:	8532                	mv	a0,a2
    80001536:	b7e9                	j	80001500 <uvmalloc+0x86>

0000000080001538 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001538:	7179                	addi	sp,sp,-48
    8000153a:	f406                	sd	ra,40(sp)
    8000153c:	f022                	sd	s0,32(sp)
    8000153e:	ec26                	sd	s1,24(sp)
    80001540:	e84a                	sd	s2,16(sp)
    80001542:	e44e                	sd	s3,8(sp)
    80001544:	e052                	sd	s4,0(sp)
    80001546:	1800                	addi	s0,sp,48
    80001548:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154a:	84aa                	mv	s1,a0
    8000154c:	6905                	lui	s2,0x1
    8000154e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001550:	4985                	li	s3,1
    80001552:	a829                	j	8000156c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001554:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001556:	00c79513          	slli	a0,a5,0xc
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	fde080e7          	jalr	-34(ra) # 80001538 <freewalk>
      pagetable[i] = 0;
    80001562:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001566:	04a1                	addi	s1,s1,8
    80001568:	03248163          	beq	s1,s2,8000158a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000156e:	00f7f713          	andi	a4,a5,15
    80001572:	ff3701e3          	beq	a4,s3,80001554 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001576:	8b85                	andi	a5,a5,1
    80001578:	d7fd                	beqz	a5,80001566 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157a:	00007517          	auipc	a0,0x7
    8000157e:	bde50513          	addi	a0,a0,-1058 # 80008158 <etext+0x158>
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	fde080e7          	jalr	-34(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158a:	8552                	mv	a0,s4
    8000158c:	fffff097          	auipc	ra,0xfffff
    80001590:	4be080e7          	jalr	1214(ra) # 80000a4a <kfree>
}
    80001594:	70a2                	ld	ra,40(sp)
    80001596:	7402                	ld	s0,32(sp)
    80001598:	64e2                	ld	s1,24(sp)
    8000159a:	6942                	ld	s2,16(sp)
    8000159c:	69a2                	ld	s3,8(sp)
    8000159e:	6a02                	ld	s4,0(sp)
    800015a0:	6145                	addi	sp,sp,48
    800015a2:	8082                	ret

00000000800015a4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a4:	1101                	addi	sp,sp,-32
    800015a6:	ec06                	sd	ra,24(sp)
    800015a8:	e822                	sd	s0,16(sp)
    800015aa:	e426                	sd	s1,8(sp)
    800015ac:	1000                	addi	s0,sp,32
    800015ae:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b0:	e999                	bnez	a1,800015c6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b2:	8526                	mv	a0,s1
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f84080e7          	jalr	-124(ra) # 80001538 <freewalk>
}
    800015bc:	60e2                	ld	ra,24(sp)
    800015be:	6442                	ld	s0,16(sp)
    800015c0:	64a2                	ld	s1,8(sp)
    800015c2:	6105                	addi	sp,sp,32
    800015c4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c6:	6785                	lui	a5,0x1
    800015c8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015ca:	95be                	add	a1,a1,a5
    800015cc:	4685                	li	a3,1
    800015ce:	00c5d613          	srli	a2,a1,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	cea080e7          	jalr	-790(ra) # 800012be <uvmunmap>
    800015dc:	bfd9                	j	800015b2 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	c679                	beqz	a2,800016ac <uvmcopy+0xce>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8b2a                	mv	s6,a0
    800015f8:	8aae                	mv	s5,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fe:	4601                	li	a2,0
    80001600:	85ce                	mv	a1,s3
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	a0c080e7          	jalr	-1524(ra) # 80001010 <walk>
    8000160c:	c531                	beqz	a0,80001658 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160e:	6118                	ld	a4,0(a0)
    80001610:	00177793          	andi	a5,a4,1
    80001614:	cbb1                	beqz	a5,80001668 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001616:	00a75593          	srli	a1,a4,0xa
    8000161a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	526080e7          	jalr	1318(ra) # 80000b48 <kalloc>
    8000162a:	892a                	mv	s2,a0
    8000162c:	c939                	beqz	a0,80001682 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	85de                	mv	a1,s7
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	75e080e7          	jalr	1886(ra) # 80000d90 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163a:	8726                	mv	a4,s1
    8000163c:	86ca                	mv	a3,s2
    8000163e:	6605                	lui	a2,0x1
    80001640:	85ce                	mv	a1,s3
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	ab4080e7          	jalr	-1356(ra) # 800010f8 <mappages>
    8000164c:	e515                	bnez	a0,80001678 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	6785                	lui	a5,0x1
    80001650:	99be                	add	s3,s3,a5
    80001652:	fb49e6e3          	bltu	s3,s4,800015fe <uvmcopy+0x20>
    80001656:	a081                	j	80001696 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b1050513          	addi	a0,a0,-1264 # 80008168 <etext+0x168>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	f00080e7          	jalr	-256(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b2050513          	addi	a0,a0,-1248 # 80008188 <etext+0x188>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ef0080e7          	jalr	-272(ra) # 80000560 <panic>
      kfree(mem);
    80001678:	854a                	mv	a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	3d0080e7          	jalr	976(ra) # 80000a4a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c9d613          	srli	a2,s3,0xc
    80001688:	4581                	li	a1,0
    8000168a:	8556                	mv	a0,s5
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c32080e7          	jalr	-974(ra) # 800012be <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	60a6                	ld	ra,72(sp)
    80001698:	6406                	ld	s0,64(sp)
    8000169a:	74e2                	ld	s1,56(sp)
    8000169c:	7942                	ld	s2,48(sp)
    8000169e:	79a2                	ld	s3,40(sp)
    800016a0:	7a02                	ld	s4,32(sp)
    800016a2:	6ae2                	ld	s5,24(sp)
    800016a4:	6b42                	ld	s6,16(sp)
    800016a6:	6ba2                	ld	s7,8(sp)
    800016a8:	6161                	addi	sp,sp,80
    800016aa:	8082                	ret
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret

00000000800016b0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b0:	1141                	addi	sp,sp,-16
    800016b2:	e406                	sd	ra,8(sp)
    800016b4:	e022                	sd	s0,0(sp)
    800016b6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b8:	4601                	li	a2,0
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	956080e7          	jalr	-1706(ra) # 80001010 <walk>
  if(pte == 0)
    800016c2:	c901                	beqz	a0,800016d2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c4:	611c                	ld	a5,0(a0)
    800016c6:	9bbd                	andi	a5,a5,-17
    800016c8:	e11c                	sd	a5,0(a0)
}
    800016ca:	60a2                	ld	ra,8(sp)
    800016cc:	6402                	ld	s0,0(sp)
    800016ce:	0141                	addi	sp,sp,16
    800016d0:	8082                	ret
    panic("uvmclear");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ad650513          	addi	a0,a0,-1322 # 800081a8 <etext+0x1a8>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e86080e7          	jalr	-378(ra) # 80000560 <panic>

00000000800016e2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyout+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8c2e                	mv	s8,a1
    80001700:	8a32                	mv	s4,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	85d2                	mv	a1,s4
    80001712:	41250533          	sub	a0,a0,s2
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	67a080e7          	jalr	1658(ra) # 80000d90 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001722:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	982080e7          	jalr	-1662(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyout+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyout+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyout+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176e:	caa5                	beqz	a3,800017de <copyin+0x70>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	e062                	sd	s8,0(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8b2a                	mv	s6,a0
    8000178a:	8a2e                	mv	s4,a1
    8000178c:	8c32                	mv	s8,a2
    8000178e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6a85                	lui	s5,0x1
    80001794:	a01d                	j	800017ba <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001796:	018505b3          	add	a1,a0,s8
    8000179a:	0004861b          	sext.w	a2,s1
    8000179e:	412585b3          	sub	a1,a1,s2
    800017a2:	8552                	mv	a0,s4
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	5ec080e7          	jalr	1516(ra) # 80000d90 <memmove>

    len -= n;
    800017ac:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b6:	02098263          	beqz	s3,800017da <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017be:	85ca                	mv	a1,s2
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	8f4080e7          	jalr	-1804(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    800017ca:	cd01                	beqz	a0,800017e2 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017cc:	418904b3          	sub	s1,s2,s8
    800017d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d2:	fc99f2e3          	bgeu	s3,s1,80001796 <copyin+0x28>
    800017d6:	84ce                	mv	s1,s3
    800017d8:	bf7d                	j	80001796 <copyin+0x28>
  }
  return 0;
    800017da:	4501                	li	a0,0
    800017dc:	a021                	j	800017e4 <copyin+0x76>
    800017de:	4501                	li	a0,0
}
    800017e0:	8082                	ret
      return -1;
    800017e2:	557d                	li	a0,-1
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6c02                	ld	s8,0(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret

00000000800017fc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fc:	cacd                	beqz	a3,800018ae <copyinstr+0xb2>
{
    800017fe:	715d                	addi	sp,sp,-80
    80001800:	e486                	sd	ra,72(sp)
    80001802:	e0a2                	sd	s0,64(sp)
    80001804:	fc26                	sd	s1,56(sp)
    80001806:	f84a                	sd	s2,48(sp)
    80001808:	f44e                	sd	s3,40(sp)
    8000180a:	f052                	sd	s4,32(sp)
    8000180c:	ec56                	sd	s5,24(sp)
    8000180e:	e85a                	sd	s6,16(sp)
    80001810:	e45e                	sd	s7,8(sp)
    80001812:	0880                	addi	s0,sp,80
    80001814:	8a2a                	mv	s4,a0
    80001816:	8b2e                	mv	s6,a1
    80001818:	8bb2                	mv	s7,a2
    8000181a:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    8000181c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181e:	6985                	lui	s3,0x1
    80001820:	a825                	j	80001858 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001822:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001826:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret
    80001844:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    80001848:	9742                	add	a4,a4,a6
      --max;
    8000184a:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    8000184e:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001852:	04e58663          	beq	a1,a4,8000189e <copyinstr+0xa2>
{
    80001856:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    80001858:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000185c:	85a6                	mv	a1,s1
    8000185e:	8552                	mv	a0,s4
    80001860:	00000097          	auipc	ra,0x0
    80001864:	856080e7          	jalr	-1962(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    80001868:	cd0d                	beqz	a0,800018a2 <copyinstr+0xa6>
    n = PGSIZE - (srcva - va0);
    8000186a:	417486b3          	sub	a3,s1,s7
    8000186e:	96ce                	add	a3,a3,s3
    if(n > max)
    80001870:	00d97363          	bgeu	s2,a3,80001876 <copyinstr+0x7a>
    80001874:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001876:	955e                	add	a0,a0,s7
    80001878:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000187a:	c695                	beqz	a3,800018a6 <copyinstr+0xaa>
    8000187c:	87da                	mv	a5,s6
    8000187e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001880:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001884:	96da                	add	a3,a3,s6
    80001886:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001888:	00f60733          	add	a4,a2,a5
    8000188c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda0a0>
    80001890:	db49                	beqz	a4,80001822 <copyinstr+0x26>
        *dst = *p;
    80001892:	00e78023          	sb	a4,0(a5)
      dst++;
    80001896:	0785                	addi	a5,a5,1
    while(n > 0){
    80001898:	fed797e3          	bne	a5,a3,80001886 <copyinstr+0x8a>
    8000189c:	b765                	j	80001844 <copyinstr+0x48>
    8000189e:	4781                	li	a5,0
    800018a0:	b761                	j	80001828 <copyinstr+0x2c>
      return -1;
    800018a2:	557d                	li	a0,-1
    800018a4:	b769                	j	8000182e <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    800018a6:	6b85                	lui	s7,0x1
    800018a8:	9ba6                	add	s7,s7,s1
    800018aa:	87da                	mv	a5,s6
    800018ac:	b76d                	j	80001856 <copyinstr+0x5a>
  int got_null = 0;
    800018ae:	4781                	li	a5,0
  if(got_null){
    800018b0:	37fd                	addiw	a5,a5,-1
    800018b2:	0007851b          	sext.w	a0,a5
}
    800018b6:	8082                	ret

00000000800018b8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800018b8:	7139                	addi	sp,sp,-64
    800018ba:	fc06                	sd	ra,56(sp)
    800018bc:	f822                	sd	s0,48(sp)
    800018be:	f426                	sd	s1,40(sp)
    800018c0:	f04a                	sd	s2,32(sp)
    800018c2:	ec4e                	sd	s3,24(sp)
    800018c4:	e852                	sd	s4,16(sp)
    800018c6:	e456                	sd	s5,8(sp)
    800018c8:	e05a                	sd	s6,0(sp)
    800018ca:	0080                	addi	s0,sp,64
    800018cc:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018ce:	0000f497          	auipc	s1,0xf
    800018d2:	6b248493          	addi	s1,s1,1714 # 80010f80 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018d6:	8b26                	mv	s6,s1
    800018d8:	faf8b937          	lui	s2,0xfaf8b
    800018dc:	f8b90913          	addi	s2,s2,-117 # fffffffffaf8af8b <end+0xffffffff7af6602b>
    800018e0:	0932                	slli	s2,s2,0xc
    800018e2:	f8b90913          	addi	s2,s2,-117
    800018e6:	0932                	slli	s2,s2,0xc
    800018e8:	f8b90913          	addi	s2,s2,-117
    800018ec:	0932                	slli	s2,s2,0xc
    800018ee:	f8b90913          	addi	s2,s2,-117
    800018f2:	040009b7          	lui	s3,0x4000
    800018f6:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800018f8:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018fa:	00018a97          	auipc	s5,0x18
    800018fe:	286a8a93          	addi	s5,s5,646 # 80019b80 <tickslock>
    char *pa = kalloc();
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	246080e7          	jalr	582(ra) # 80000b48 <kalloc>
    8000190a:	862a                	mv	a2,a0
    if (pa == 0)
    8000190c:	c121                	beqz	a0,8000194c <proc_mapstacks+0x94>
    uint64 va = KSTACK((int)(p - proc));
    8000190e:	416485b3          	sub	a1,s1,s6
    80001912:	8591                	srai	a1,a1,0x4
    80001914:	032585b3          	mul	a1,a1,s2
    80001918:	2585                	addiw	a1,a1,1
    8000191a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000191e:	4719                	li	a4,6
    80001920:	6685                	lui	a3,0x1
    80001922:	40b985b3          	sub	a1,s3,a1
    80001926:	8552                	mv	a0,s4
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	870080e7          	jalr	-1936(ra) # 80001198 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001930:	23048493          	addi	s1,s1,560
    80001934:	fd5497e3          	bne	s1,s5,80001902 <proc_mapstacks+0x4a>
  }
}
    80001938:	70e2                	ld	ra,56(sp)
    8000193a:	7442                	ld	s0,48(sp)
    8000193c:	74a2                	ld	s1,40(sp)
    8000193e:	7902                	ld	s2,32(sp)
    80001940:	69e2                	ld	s3,24(sp)
    80001942:	6a42                	ld	s4,16(sp)
    80001944:	6aa2                	ld	s5,8(sp)
    80001946:	6b02                	ld	s6,0(sp)
    80001948:	6121                	addi	sp,sp,64
    8000194a:	8082                	ret
      panic("kalloc");
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	86c50513          	addi	a0,a0,-1940 # 800081b8 <etext+0x1b8>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	c0c080e7          	jalr	-1012(ra) # 80000560 <panic>

000000008000195c <procinit>:

// initialize the proc table.
void procinit(void)
{
    8000195c:	7139                	addi	sp,sp,-64
    8000195e:	fc06                	sd	ra,56(sp)
    80001960:	f822                	sd	s0,48(sp)
    80001962:	f426                	sd	s1,40(sp)
    80001964:	f04a                	sd	s2,32(sp)
    80001966:	ec4e                	sd	s3,24(sp)
    80001968:	e852                	sd	s4,16(sp)
    8000196a:	e456                	sd	s5,8(sp)
    8000196c:	e05a                	sd	s6,0(sp)
    8000196e:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	85058593          	addi	a1,a1,-1968 # 800081c0 <etext+0x1c0>
    80001978:	0000f517          	auipc	a0,0xf
    8000197c:	1d850513          	addi	a0,a0,472 # 80010b50 <pid_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	228080e7          	jalr	552(ra) # 80000ba8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001988:	00007597          	auipc	a1,0x7
    8000198c:	84058593          	addi	a1,a1,-1984 # 800081c8 <etext+0x1c8>
    80001990:	0000f517          	auipc	a0,0xf
    80001994:	1d850513          	addi	a0,a0,472 # 80010b68 <wait_lock>
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	210080e7          	jalr	528(ra) # 80000ba8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019a0:	0000f497          	auipc	s1,0xf
    800019a4:	5e048493          	addi	s1,s1,1504 # 80010f80 <proc>
  {
    initlock(&p->lock, "proc");
    800019a8:	00007b17          	auipc	s6,0x7
    800019ac:	830b0b13          	addi	s6,s6,-2000 # 800081d8 <etext+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019b0:	8aa6                	mv	s5,s1
    800019b2:	faf8b937          	lui	s2,0xfaf8b
    800019b6:	f8b90913          	addi	s2,s2,-117 # fffffffffaf8af8b <end+0xffffffff7af6602b>
    800019ba:	0932                	slli	s2,s2,0xc
    800019bc:	f8b90913          	addi	s2,s2,-117
    800019c0:	0932                	slli	s2,s2,0xc
    800019c2:	f8b90913          	addi	s2,s2,-117
    800019c6:	0932                	slli	s2,s2,0xc
    800019c8:	f8b90913          	addi	s2,s2,-117
    800019cc:	040009b7          	lui	s3,0x4000
    800019d0:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800019d2:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019d4:	00018a17          	auipc	s4,0x18
    800019d8:	1aca0a13          	addi	s4,s4,428 # 80019b80 <tickslock>
    initlock(&p->lock, "proc");
    800019dc:	85da                	mv	a1,s6
    800019de:	8526                	mv	a0,s1
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	1c8080e7          	jalr	456(ra) # 80000ba8 <initlock>
    p->state = UNUSED;
    800019e8:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800019ec:	415487b3          	sub	a5,s1,s5
    800019f0:	8791                	srai	a5,a5,0x4
    800019f2:	032787b3          	mul	a5,a5,s2
    800019f6:	2785                	addiw	a5,a5,1
    800019f8:	00d7979b          	slliw	a5,a5,0xd
    800019fc:	40f987b3          	sub	a5,s3,a5
    80001a00:	fcfc                	sd	a5,248(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a02:	23048493          	addi	s1,s1,560
    80001a06:	fd449be3          	bne	s1,s4,800019dc <procinit+0x80>
    mlfq[i].size = 0;
    mlfq[i].head = 0;
    mlfq[i].tail = 0;
  }
#endif
}
    80001a0a:	70e2                	ld	ra,56(sp)
    80001a0c:	7442                	ld	s0,48(sp)
    80001a0e:	74a2                	ld	s1,40(sp)
    80001a10:	7902                	ld	s2,32(sp)
    80001a12:	69e2                	ld	s3,24(sp)
    80001a14:	6a42                	ld	s4,16(sp)
    80001a16:	6aa2                	ld	s5,8(sp)
    80001a18:	6b02                	ld	s6,0(sp)
    80001a1a:	6121                	addi	sp,sp,64
    80001a1c:	8082                	ret

0000000080001a1e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e422                	sd	s0,8(sp)
    80001a22:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a24:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a26:	2501                	sext.w	a0,a0
    80001a28:	6422                	ld	s0,8(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e422                	sd	s0,8(sp)
    80001a32:	0800                	addi	s0,sp,16
    80001a34:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a36:	2781                	sext.w	a5,a5
    80001a38:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a3a:	0000f517          	auipc	a0,0xf
    80001a3e:	14650513          	addi	a0,a0,326 # 80010b80 <cpus>
    80001a42:	953e                	add	a0,a0,a5
    80001a44:	6422                	ld	s0,8(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret

0000000080001a4a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	1000                	addi	s0,sp,32
  push_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	198080e7          	jalr	408(ra) # 80000bec <push_off>
    80001a5c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	079e                	slli	a5,a5,0x7
    80001a62:	0000f717          	auipc	a4,0xf
    80001a66:	0ee70713          	addi	a4,a4,238 # 80010b50 <pid_lock>
    80001a6a:	97ba                	add	a5,a5,a4
    80001a6c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	21e080e7          	jalr	542(ra) # 80000c8c <pop_off>
  return p;
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6105                	addi	sp,sp,32
    80001a80:	8082                	ret

0000000080001a82 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a82:	1141                	addi	sp,sp,-16
    80001a84:	e406                	sd	ra,8(sp)
    80001a86:	e022                	sd	s0,0(sp)
    80001a88:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	fc0080e7          	jalr	-64(ra) # 80001a4a <myproc>
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	25a080e7          	jalr	602(ra) # 80000cec <release>

  if (first)
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	dc67a783          	lw	a5,-570(a5) # 80008860 <first.1>
    80001aa2:	eb89                	bnez	a5,80001ab4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aa4:	00001097          	auipc	ra,0x1
    80001aa8:	f12080e7          	jalr	-238(ra) # 800029b6 <usertrapret>
}
    80001aac:	60a2                	ld	ra,8(sp)
    80001aae:	6402                	ld	s0,0(sp)
    80001ab0:	0141                	addi	sp,sp,16
    80001ab2:	8082                	ret
    first = 0;
    80001ab4:	00007797          	auipc	a5,0x7
    80001ab8:	da07a623          	sw	zero,-596(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001abc:	4505                	li	a0,1
    80001abe:	00002097          	auipc	ra,0x2
    80001ac2:	02c080e7          	jalr	44(ra) # 80003aea <fsinit>
    80001ac6:	bff9                	j	80001aa4 <forkret+0x22>

0000000080001ac8 <allocpid>:
{
    80001ac8:	1101                	addi	sp,sp,-32
    80001aca:	ec06                	sd	ra,24(sp)
    80001acc:	e822                	sd	s0,16(sp)
    80001ace:	e426                	sd	s1,8(sp)
    80001ad0:	e04a                	sd	s2,0(sp)
    80001ad2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad4:	0000f917          	auipc	s2,0xf
    80001ad8:	07c90913          	addi	s2,s2,124 # 80010b50 <pid_lock>
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	15a080e7          	jalr	346(ra) # 80000c38 <acquire>
  pid = nextpid;
    80001ae6:	00007797          	auipc	a5,0x7
    80001aea:	d7e78793          	addi	a5,a5,-642 # 80008864 <nextpid>
    80001aee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af0:	0014871b          	addiw	a4,s1,1
    80001af4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af6:	854a                	mv	a0,s2
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	1f4080e7          	jalr	500(ra) # 80000cec <release>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6902                	ld	s2,0(sp)
    80001b0a:	6105                	addi	sp,sp,32
    80001b0c:	8082                	ret

0000000080001b0e <proc_pagetable>:
{
    80001b0e:	1101                	addi	sp,sp,-32
    80001b10:	ec06                	sd	ra,24(sp)
    80001b12:	e822                	sd	s0,16(sp)
    80001b14:	e426                	sd	s1,8(sp)
    80001b16:	e04a                	sd	s2,0(sp)
    80001b18:	1000                	addi	s0,sp,32
    80001b1a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	876080e7          	jalr	-1930(ra) # 80001392 <uvmcreate>
    80001b24:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b26:	c121                	beqz	a0,80001b66 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b28:	4729                	li	a4,10
    80001b2a:	00005697          	auipc	a3,0x5
    80001b2e:	4d668693          	addi	a3,a3,1238 # 80007000 <_trampoline>
    80001b32:	6605                	lui	a2,0x1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	5bc080e7          	jalr	1468(ra) # 800010f8 <mappages>
    80001b44:	02054863          	bltz	a0,80001b74 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b48:	4719                	li	a4,6
    80001b4a:	11093683          	ld	a3,272(s2)
    80001b4e:	6605                	lui	a2,0x1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	59e080e7          	jalr	1438(ra) # 800010f8 <mappages>
    80001b62:	02054163          	bltz	a0,80001b84 <proc_pagetable+0x76>
}
    80001b66:	8526                	mv	a0,s1
    80001b68:	60e2                	ld	ra,24(sp)
    80001b6a:	6442                	ld	s0,16(sp)
    80001b6c:	64a2                	ld	s1,8(sp)
    80001b6e:	6902                	ld	s2,0(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2c080e7          	jalr	-1492(ra) # 800015a4 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	b7d5                	j	80001b66 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b84:	4681                	li	a3,0
    80001b86:	4605                	li	a2,1
    80001b88:	040005b7          	lui	a1,0x4000
    80001b8c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b8e:	05b2                	slli	a1,a1,0xc
    80001b90:	8526                	mv	a0,s1
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	72c080e7          	jalr	1836(ra) # 800012be <uvmunmap>
    uvmfree(pagetable, 0);
    80001b9a:	4581                	li	a1,0
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	a06080e7          	jalr	-1530(ra) # 800015a4 <uvmfree>
    return 0;
    80001ba6:	4481                	li	s1,0
    80001ba8:	bf7d                	j	80001b66 <proc_pagetable+0x58>

0000000080001baa <proc_freepagetable>:
{
    80001baa:	1101                	addi	sp,sp,-32
    80001bac:	ec06                	sd	ra,24(sp)
    80001bae:	e822                	sd	s0,16(sp)
    80001bb0:	e426                	sd	s1,8(sp)
    80001bb2:	e04a                	sd	s2,0(sp)
    80001bb4:	1000                	addi	s0,sp,32
    80001bb6:	84aa                	mv	s1,a0
    80001bb8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bba:	4681                	li	a3,0
    80001bbc:	4605                	li	a2,1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	6f8080e7          	jalr	1784(ra) # 800012be <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bce:	4681                	li	a3,0
    80001bd0:	4605                	li	a2,1
    80001bd2:	020005b7          	lui	a1,0x2000
    80001bd6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd8:	05b6                	slli	a1,a1,0xd
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	6e2080e7          	jalr	1762(ra) # 800012be <uvmunmap>
  uvmfree(pagetable, sz);
    80001be4:	85ca                	mv	a1,s2
    80001be6:	8526                	mv	a0,s1
    80001be8:	00000097          	auipc	ra,0x0
    80001bec:	9bc080e7          	jalr	-1604(ra) # 800015a4 <uvmfree>
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6902                	ld	s2,0(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <freeproc>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	1000                	addi	s0,sp,32
    80001c06:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c08:	11053503          	ld	a0,272(a0)
    80001c0c:	c509                	beqz	a0,80001c16 <freeproc+0x1a>
    kfree((void *)p->trapframe);
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	e3c080e7          	jalr	-452(ra) # 80000a4a <kfree>
  if (p->new_trapframe)
    80001c16:	6ce8                	ld	a0,216(s1)
    80001c18:	c509                	beqz	a0,80001c22 <freeproc+0x26>
    kfree((void *)p->new_trapframe);
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	e30080e7          	jalr	-464(ra) # 80000a4a <kfree>
  p->trapframe = 0;
    80001c22:	1004b823          	sd	zero,272(s1)
  if (p->pagetable)
    80001c26:	1084b503          	ld	a0,264(s1)
    80001c2a:	c519                	beqz	a0,80001c38 <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80001c2c:	1004b583          	ld	a1,256(s1)
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	f7a080e7          	jalr	-134(ra) # 80001baa <proc_freepagetable>
  p->pagetable = 0;
    80001c38:	1004b423          	sd	zero,264(s1)
  p->sz = 0;
    80001c3c:	1004b023          	sd	zero,256(s1)
  p->pid = 0;
    80001c40:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c44:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c48:	20048823          	sb	zero,528(s1)
  p->chan = 0;
    80001c4c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c50:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c54:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c58:	0004ac23          	sw	zero,24(s1)
}
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret

0000000080001c66 <allocproc>:
{
    80001c66:	1101                	addi	sp,sp,-32
    80001c68:	ec06                	sd	ra,24(sp)
    80001c6a:	e822                	sd	s0,16(sp)
    80001c6c:	e426                	sd	s1,8(sp)
    80001c6e:	e04a                	sd	s2,0(sp)
    80001c70:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c72:	0000f497          	auipc	s1,0xf
    80001c76:	30e48493          	addi	s1,s1,782 # 80010f80 <proc>
    80001c7a:	00018917          	auipc	s2,0x18
    80001c7e:	f0690913          	addi	s2,s2,-250 # 80019b80 <tickslock>
    acquire(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	fb4080e7          	jalr	-76(ra) # 80000c38 <acquire>
    if (p->state == UNUSED)
    80001c8c:	4c9c                	lw	a5,24(s1)
    80001c8e:	cf81                	beqz	a5,80001ca6 <allocproc+0x40>
      release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	05a080e7          	jalr	90(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c9a:	23048493          	addi	s1,s1,560
    80001c9e:	ff2492e3          	bne	s1,s2,80001c82 <allocproc+0x1c>
  return 0;
    80001ca2:	4481                	li	s1,0
    80001ca4:	a075                	j	80001d50 <allocproc+0xea>
  p->pid = allocpid();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e22080e7          	jalr	-478(ra) # 80001ac8 <allocpid>
    80001cae:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cb0:	4785                	li	a5,1
    80001cb2:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	e94080e7          	jalr	-364(ra) # 80000b48 <kalloc>
    80001cbc:	892a                	mv	s2,a0
    80001cbe:	10a4b823          	sd	a0,272(s1)
    80001cc2:	cd51                	beqz	a0,80001d5e <allocproc+0xf8>
  p->pagetable = proc_pagetable(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	e48080e7          	jalr	-440(ra) # 80001b0e <proc_pagetable>
    80001cce:	892a                	mv	s2,a0
    80001cd0:	10a4b423          	sd	a0,264(s1)
  if (p->pagetable == 0)
    80001cd4:	04048793          	addi	a5,s1,64
    80001cd8:	0c048713          	addi	a4,s1,192
    80001cdc:	cd49                	beqz	a0,80001d76 <allocproc+0x110>
    p->syscall_count[i] = 0;
    80001cde:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < 32; i++)
    80001ce2:	0791                	addi	a5,a5,4
    80001ce4:	fee79de3          	bne	a5,a4,80001cde <allocproc+0x78>
  memset(&p->context, 0, sizeof(p->context));
    80001ce8:	07000613          	li	a2,112
    80001cec:	4581                	li	a1,0
    80001cee:	11848513          	addi	a0,s1,280
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	042080e7          	jalr	66(ra) # 80000d34 <memset>
  p->context.ra = (uint64)forkret;
    80001cfa:	00000797          	auipc	a5,0x0
    80001cfe:	d8878793          	addi	a5,a5,-632 # 80001a82 <forkret>
    80001d02:	10f4bc23          	sd	a5,280(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d06:	7cfc                	ld	a5,248(s1)
    80001d08:	6705                	lui	a4,0x1
    80001d0a:	97ba                	add	a5,a5,a4
    80001d0c:	12f4b023          	sd	a5,288(s1)
  p->new_trapframe = (struct trapframe *)kalloc();
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	e38080e7          	jalr	-456(ra) # 80000b48 <kalloc>
    80001d18:	892a                	mv	s2,a0
    80001d1a:	ece8                	sd	a0,216(s1)
  if (p->new_trapframe)
    80001d1c:	c92d                	beqz	a0,80001d8e <allocproc+0x128>
    p->bool_sigalarm = 0;
    80001d1e:	0c04a423          	sw	zero,200(s1)
    p->interval = 0;
    80001d22:	0c04a023          	sw	zero,192(s1)
    p->till_tick = 0;
    80001d26:	0c04a223          	sw	zero,196(s1)
    p->handler = 0;
    80001d2a:	0c04b823          	sd	zero,208(s1)
  p->rtime = 0;
    80001d2e:	2204a023          	sw	zero,544(s1)
  p->etime = 0;
    80001d32:	2204a423          	sw	zero,552(s1)
  p->ctime = ticks;
    80001d36:	00007797          	auipc	a5,0x7
    80001d3a:	baa7a783          	lw	a5,-1110(a5) # 800088e0 <ticks>
    80001d3e:	22f4a223          	sw	a5,548(s1)
  p->state = USED;
    80001d42:	4705                	li	a4,1
    80001d44:	cc98                	sw	a4,24(s1)
  p->arrival_time = ticks; // Set arrival time to current ticks
    80001d46:	1782                	slli	a5,a5,0x20
    80001d48:	9381                	srli	a5,a5,0x20
    80001d4a:	f4fc                	sd	a5,232(s1)
  p->time_slice = 0;
    80001d4c:	0e04a823          	sw	zero,240(s1)
}
    80001d50:	8526                	mv	a0,s1
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6902                	ld	s2,0(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret
    freeproc(p);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	e9c080e7          	jalr	-356(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	f82080e7          	jalr	-126(ra) # 80000cec <release>
    return 0;
    80001d72:	84ca                	mv	s1,s2
    80001d74:	bff1                	j	80001d50 <allocproc+0xea>
    freeproc(p);
    80001d76:	8526                	mv	a0,s1
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	e84080e7          	jalr	-380(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d80:	8526                	mv	a0,s1
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	f6a080e7          	jalr	-150(ra) # 80000cec <release>
    return 0;
    80001d8a:	84ca                	mv	s1,s2
    80001d8c:	b7d1                	j	80001d50 <allocproc+0xea>
    release(&p->lock);
    80001d8e:	8526                	mv	a0,s1
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	f5c080e7          	jalr	-164(ra) # 80000cec <release>
    return 0;
    80001d98:	84ca                	mv	s1,s2
    80001d9a:	bf5d                	j	80001d50 <allocproc+0xea>

0000000080001d9c <userinit>:
{
    80001d9c:	1101                	addi	sp,sp,-32
    80001d9e:	ec06                	sd	ra,24(sp)
    80001da0:	e822                	sd	s0,16(sp)
    80001da2:	e426                	sd	s1,8(sp)
    80001da4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	ec0080e7          	jalr	-320(ra) # 80001c66 <allocproc>
    80001dae:	84aa                	mv	s1,a0
  initproc = p;
    80001db0:	00007797          	auipc	a5,0x7
    80001db4:	b2a7b423          	sd	a0,-1240(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001db8:	03400613          	li	a2,52
    80001dbc:	00007597          	auipc	a1,0x7
    80001dc0:	ab458593          	addi	a1,a1,-1356 # 80008870 <initcode>
    80001dc4:	10853503          	ld	a0,264(a0)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	5f8080e7          	jalr	1528(ra) # 800013c0 <uvmfirst>
  p->sz = PGSIZE;
    80001dd0:	6785                	lui	a5,0x1
    80001dd2:	10f4b023          	sd	a5,256(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dd6:	1104b703          	ld	a4,272(s1)
    80001dda:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001dde:	1104b703          	ld	a4,272(s1)
    80001de2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001de4:	4641                	li	a2,16
    80001de6:	00006597          	auipc	a1,0x6
    80001dea:	3fa58593          	addi	a1,a1,1018 # 800081e0 <etext+0x1e0>
    80001dee:	21048513          	addi	a0,s1,528
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	084080e7          	jalr	132(ra) # 80000e76 <safestrcpy>
  p->cwd = namei("/");
    80001dfa:	00006517          	auipc	a0,0x6
    80001dfe:	3f650513          	addi	a0,a0,1014 # 800081f0 <etext+0x1f0>
    80001e02:	00002097          	auipc	ra,0x2
    80001e06:	73a080e7          	jalr	1850(ra) # 8000453c <namei>
    80001e0a:	20a4b423          	sd	a0,520(s1)
  p->state = RUNNABLE;
    80001e0e:	478d                	li	a5,3
    80001e10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e12:	8526                	mv	a0,s1
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	ed8080e7          	jalr	-296(ra) # 80000cec <release>
}
    80001e1c:	60e2                	ld	ra,24(sp)
    80001e1e:	6442                	ld	s0,16(sp)
    80001e20:	64a2                	ld	s1,8(sp)
    80001e22:	6105                	addi	sp,sp,32
    80001e24:	8082                	ret

0000000080001e26 <growproc>:
{
    80001e26:	1101                	addi	sp,sp,-32
    80001e28:	ec06                	sd	ra,24(sp)
    80001e2a:	e822                	sd	s0,16(sp)
    80001e2c:	e426                	sd	s1,8(sp)
    80001e2e:	e04a                	sd	s2,0(sp)
    80001e30:	1000                	addi	s0,sp,32
    80001e32:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	c16080e7          	jalr	-1002(ra) # 80001a4a <myproc>
    80001e3c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e3e:	10053583          	ld	a1,256(a0)
  if (n > 0)
    80001e42:	01204d63          	bgtz	s2,80001e5c <growproc+0x36>
  else if (n < 0)
    80001e46:	02094863          	bltz	s2,80001e76 <growproc+0x50>
  p->sz = sz;
    80001e4a:	10b4b023          	sd	a1,256(s1)
  return 0;
    80001e4e:	4501                	li	a0,0
}
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6902                	ld	s2,0(sp)
    80001e58:	6105                	addi	sp,sp,32
    80001e5a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e5c:	4691                	li	a3,4
    80001e5e:	00b90633          	add	a2,s2,a1
    80001e62:	10853503          	ld	a0,264(a0)
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	614080e7          	jalr	1556(ra) # 8000147a <uvmalloc>
    80001e6e:	85aa                	mv	a1,a0
    80001e70:	fd69                	bnez	a0,80001e4a <growproc+0x24>
      return -1;
    80001e72:	557d                	li	a0,-1
    80001e74:	bff1                	j	80001e50 <growproc+0x2a>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e76:	00b90633          	add	a2,s2,a1
    80001e7a:	10853503          	ld	a0,264(a0)
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	5b4080e7          	jalr	1460(ra) # 80001432 <uvmdealloc>
    80001e86:	85aa                	mv	a1,a0
    80001e88:	b7c9                	j	80001e4a <growproc+0x24>

0000000080001e8a <fork>:
{
    80001e8a:	7139                	addi	sp,sp,-64
    80001e8c:	fc06                	sd	ra,56(sp)
    80001e8e:	f822                	sd	s0,48(sp)
    80001e90:	f04a                	sd	s2,32(sp)
    80001e92:	e456                	sd	s5,8(sp)
    80001e94:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	bb4080e7          	jalr	-1100(ra) # 80001a4a <myproc>
    80001e9e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	dc6080e7          	jalr	-570(ra) # 80001c66 <allocproc>
    80001ea8:	12050563          	beqz	a0,80001fd2 <fork+0x148>
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001eb0:	100ab603          	ld	a2,256(s5)
    80001eb4:	10853583          	ld	a1,264(a0)
    80001eb8:	108ab503          	ld	a0,264(s5)
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	722080e7          	jalr	1826(ra) # 800015de <uvmcopy>
    80001ec4:	04054e63          	bltz	a0,80001f20 <fork+0x96>
    80001ec8:	f426                	sd	s1,40(sp)
    80001eca:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001ecc:	100ab783          	ld	a5,256(s5)
    80001ed0:	10f9b023          	sd	a5,256(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ed4:	110ab683          	ld	a3,272(s5)
    80001ed8:	87b6                	mv	a5,a3
    80001eda:	1109b703          	ld	a4,272(s3)
    80001ede:	12068693          	addi	a3,a3,288
    80001ee2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ee6:	6788                	ld	a0,8(a5)
    80001ee8:	6b8c                	ld	a1,16(a5)
    80001eea:	6f90                	ld	a2,24(a5)
    80001eec:	01073023          	sd	a6,0(a4)
    80001ef0:	e708                	sd	a0,8(a4)
    80001ef2:	eb0c                	sd	a1,16(a4)
    80001ef4:	ef10                	sd	a2,24(a4)
    80001ef6:	02078793          	addi	a5,a5,32
    80001efa:	02070713          	addi	a4,a4,32
    80001efe:	fed792e3          	bne	a5,a3,80001ee2 <fork+0x58>
  np->trapframe->a0 = 0;
    80001f02:	1109b783          	ld	a5,272(s3)
    80001f06:	0607b823          	sd	zero,112(a5)
  np->tickets = p->tickets;
    80001f0a:	0e0aa783          	lw	a5,224(s5)
    80001f0e:	0ef9a023          	sw	a5,224(s3)
  for (i = 0; i < NOFILE; i++)
    80001f12:	188a8493          	addi	s1,s5,392
    80001f16:	18898913          	addi	s2,s3,392
    80001f1a:	208a8a13          	addi	s4,s5,520
    80001f1e:	a015                	j	80001f42 <fork+0xb8>
    freeproc(np);
    80001f20:	854e                	mv	a0,s3
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	cda080e7          	jalr	-806(ra) # 80001bfc <freeproc>
    release(&np->lock);
    80001f2a:	854e                	mv	a0,s3
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	dc0080e7          	jalr	-576(ra) # 80000cec <release>
    return -1;
    80001f34:	597d                	li	s2,-1
    80001f36:	69e2                	ld	s3,24(sp)
    80001f38:	a071                	j	80001fc4 <fork+0x13a>
  for (i = 0; i < NOFILE; i++)
    80001f3a:	04a1                	addi	s1,s1,8
    80001f3c:	0921                	addi	s2,s2,8
    80001f3e:	01448b63          	beq	s1,s4,80001f54 <fork+0xca>
    if (p->ofile[i])
    80001f42:	6088                	ld	a0,0(s1)
    80001f44:	d97d                	beqz	a0,80001f3a <fork+0xb0>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f46:	00003097          	auipc	ra,0x3
    80001f4a:	c6e080e7          	jalr	-914(ra) # 80004bb4 <filedup>
    80001f4e:	00a93023          	sd	a0,0(s2)
    80001f52:	b7e5                	j	80001f3a <fork+0xb0>
  np->cwd = idup(p->cwd);
    80001f54:	208ab503          	ld	a0,520(s5)
    80001f58:	00002097          	auipc	ra,0x2
    80001f5c:	dd8080e7          	jalr	-552(ra) # 80003d30 <idup>
    80001f60:	20a9b423          	sd	a0,520(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f64:	4641                	li	a2,16
    80001f66:	210a8593          	addi	a1,s5,528
    80001f6a:	21098513          	addi	a0,s3,528
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	f08080e7          	jalr	-248(ra) # 80000e76 <safestrcpy>
  pid = np->pid;
    80001f76:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f7a:	854e                	mv	a0,s3
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	d70080e7          	jalr	-656(ra) # 80000cec <release>
  acquire(&wait_lock);
    80001f84:	0000f497          	auipc	s1,0xf
    80001f88:	be448493          	addi	s1,s1,-1052 # 80010b68 <wait_lock>
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	caa080e7          	jalr	-854(ra) # 80000c38 <acquire>
  np->parent = p;
    80001f96:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	d50080e7          	jalr	-688(ra) # 80000cec <release>
  acquire(&np->lock);
    80001fa4:	854e                	mv	a0,s3
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c92080e7          	jalr	-878(ra) # 80000c38 <acquire>
  np->state = RUNNABLE;
    80001fae:	478d                	li	a5,3
    80001fb0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fb4:	854e                	mv	a0,s3
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	d36080e7          	jalr	-714(ra) # 80000cec <release>
  return pid;
    80001fbe:	74a2                	ld	s1,40(sp)
    80001fc0:	69e2                	ld	s3,24(sp)
    80001fc2:	6a42                	ld	s4,16(sp)
}
    80001fc4:	854a                	mv	a0,s2
    80001fc6:	70e2                	ld	ra,56(sp)
    80001fc8:	7442                	ld	s0,48(sp)
    80001fca:	7902                	ld	s2,32(sp)
    80001fcc:	6aa2                	ld	s5,8(sp)
    80001fce:	6121                	addi	sp,sp,64
    80001fd0:	8082                	ret
    return -1;
    80001fd2:	597d                	li	s2,-1
    80001fd4:	bfc5                	j	80001fc4 <fork+0x13a>

0000000080001fd6 <scheduler>:
{
    80001fd6:	7139                	addi	sp,sp,-64
    80001fd8:	fc06                	sd	ra,56(sp)
    80001fda:	f822                	sd	s0,48(sp)
    80001fdc:	f426                	sd	s1,40(sp)
    80001fde:	f04a                	sd	s2,32(sp)
    80001fe0:	ec4e                	sd	s3,24(sp)
    80001fe2:	e852                	sd	s4,16(sp)
    80001fe4:	e456                	sd	s5,8(sp)
    80001fe6:	e05a                	sd	s6,0(sp)
    80001fe8:	0080                	addi	s0,sp,64
    80001fea:	8792                	mv	a5,tp
  int id = r_tp();
    80001fec:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fee:	00779a93          	slli	s5,a5,0x7
    80001ff2:	0000f717          	auipc	a4,0xf
    80001ff6:	b5e70713          	addi	a4,a4,-1186 # 80010b50 <pid_lock>
    80001ffa:	9756                	add	a4,a4,s5
    80001ffc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002000:	0000f717          	auipc	a4,0xf
    80002004:	b8870713          	addi	a4,a4,-1144 # 80010b88 <cpus+0x8>
    80002008:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000200a:	498d                	li	s3,3
        p->state = RUNNING;
    8000200c:	4b11                	li	s6,4
        c->proc = p;
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000fa17          	auipc	s4,0xf
    80002014:	b40a0a13          	addi	s4,s4,-1216 # 80010b50 <pid_lock>
    80002018:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000201a:	00018917          	auipc	s2,0x18
    8000201e:	b6690913          	addi	s2,s2,-1178 # 80019b80 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002022:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002026:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000202a:	10079073          	csrw	sstatus,a5
    8000202e:	0000f497          	auipc	s1,0xf
    80002032:	f5248493          	addi	s1,s1,-174 # 80010f80 <proc>
    80002036:	a811                	j	8000204a <scheduler+0x74>
      release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	cb2080e7          	jalr	-846(ra) # 80000cec <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002042:	23048493          	addi	s1,s1,560
    80002046:	fd248ee3          	beq	s1,s2,80002022 <scheduler+0x4c>
      acquire(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	bec080e7          	jalr	-1044(ra) # 80000c38 <acquire>
      if (p->state == RUNNABLE)
    80002054:	4c9c                	lw	a5,24(s1)
    80002056:	ff3791e3          	bne	a5,s3,80002038 <scheduler+0x62>
        p->state = RUNNING;
    8000205a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000205e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002062:	11848593          	addi	a1,s1,280
    80002066:	8556                	mv	a0,s5
    80002068:	00001097          	auipc	ra,0x1
    8000206c:	8a4080e7          	jalr	-1884(ra) # 8000290c <swtch>
        c->proc = 0;
    80002070:	020a3823          	sd	zero,48(s4)
    80002074:	b7d1                	j	80002038 <scheduler+0x62>

0000000080002076 <sched>:
{
    80002076:	7179                	addi	sp,sp,-48
    80002078:	f406                	sd	ra,40(sp)
    8000207a:	f022                	sd	s0,32(sp)
    8000207c:	ec26                	sd	s1,24(sp)
    8000207e:	e84a                	sd	s2,16(sp)
    80002080:	e44e                	sd	s3,8(sp)
    80002082:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	9c6080e7          	jalr	-1594(ra) # 80001a4a <myproc>
    8000208c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b30080e7          	jalr	-1232(ra) # 80000bbe <holding>
    80002096:	c93d                	beqz	a0,8000210c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002098:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	0000f717          	auipc	a4,0xf
    800020a2:	ab270713          	addi	a4,a4,-1358 # 80010b50 <pid_lock>
    800020a6:	97ba                	add	a5,a5,a4
    800020a8:	0a87a703          	lw	a4,168(a5)
    800020ac:	4785                	li	a5,1
    800020ae:	06f71763          	bne	a4,a5,8000211c <sched+0xa6>
  if (p->state == RUNNING)
    800020b2:	4c98                	lw	a4,24(s1)
    800020b4:	4791                	li	a5,4
    800020b6:	06f70b63          	beq	a4,a5,8000212c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020be:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020c0:	efb5                	bnez	a5,8000213c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020c2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020c4:	0000f917          	auipc	s2,0xf
    800020c8:	a8c90913          	addi	s2,s2,-1396 # 80010b50 <pid_lock>
    800020cc:	2781                	sext.w	a5,a5
    800020ce:	079e                	slli	a5,a5,0x7
    800020d0:	97ca                	add	a5,a5,s2
    800020d2:	0ac7a983          	lw	s3,172(a5)
    800020d6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d8:	2781                	sext.w	a5,a5
    800020da:	079e                	slli	a5,a5,0x7
    800020dc:	0000f597          	auipc	a1,0xf
    800020e0:	aac58593          	addi	a1,a1,-1364 # 80010b88 <cpus+0x8>
    800020e4:	95be                	add	a1,a1,a5
    800020e6:	11848513          	addi	a0,s1,280
    800020ea:	00001097          	auipc	ra,0x1
    800020ee:	822080e7          	jalr	-2014(ra) # 8000290c <swtch>
    800020f2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020f4:	2781                	sext.w	a5,a5
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	993e                	add	s2,s2,a5
    800020fa:	0b392623          	sw	s3,172(s2)
}
    800020fe:	70a2                	ld	ra,40(sp)
    80002100:	7402                	ld	s0,32(sp)
    80002102:	64e2                	ld	s1,24(sp)
    80002104:	6942                	ld	s2,16(sp)
    80002106:	69a2                	ld	s3,8(sp)
    80002108:	6145                	addi	sp,sp,48
    8000210a:	8082                	ret
    panic("sched p->lock");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	0ec50513          	addi	a0,a0,236 # 800081f8 <etext+0x1f8>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	44c080e7          	jalr	1100(ra) # 80000560 <panic>
    panic("sched locks");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	0ec50513          	addi	a0,a0,236 # 80008208 <etext+0x208>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	43c080e7          	jalr	1084(ra) # 80000560 <panic>
    panic("sched running");
    8000212c:	00006517          	auipc	a0,0x6
    80002130:	0ec50513          	addi	a0,a0,236 # 80008218 <etext+0x218>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	42c080e7          	jalr	1068(ra) # 80000560 <panic>
    panic("sched interruptible");
    8000213c:	00006517          	auipc	a0,0x6
    80002140:	0ec50513          	addi	a0,a0,236 # 80008228 <etext+0x228>
    80002144:	ffffe097          	auipc	ra,0xffffe
    80002148:	41c080e7          	jalr	1052(ra) # 80000560 <panic>

000000008000214c <yield>:
{
    8000214c:	1101                	addi	sp,sp,-32
    8000214e:	ec06                	sd	ra,24(sp)
    80002150:	e822                	sd	s0,16(sp)
    80002152:	e426                	sd	s1,8(sp)
    80002154:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	8f4080e7          	jalr	-1804(ra) # 80001a4a <myproc>
    8000215e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	ad8080e7          	jalr	-1320(ra) # 80000c38 <acquire>
  p->state = RUNNABLE;
    80002168:	478d                	li	a5,3
    8000216a:	cc9c                	sw	a5,24(s1)
  sched();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	f0a080e7          	jalr	-246(ra) # 80002076 <sched>
  release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b76080e7          	jalr	-1162(ra) # 80000cec <release>
}
    8000217e:	60e2                	ld	ra,24(sp)
    80002180:	6442                	ld	s0,16(sp)
    80002182:	64a2                	ld	s1,8(sp)
    80002184:	6105                	addi	sp,sp,32
    80002186:	8082                	ret

0000000080002188 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	1800                	addi	s0,sp,48
    80002196:	89aa                	mv	s3,a0
    80002198:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	8b0080e7          	jalr	-1872(ra) # 80001a4a <myproc>
    800021a2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	a94080e7          	jalr	-1388(ra) # 80000c38 <acquire>
  release(lk);
    800021ac:	854a                	mv	a0,s2
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	b3e080e7          	jalr	-1218(ra) # 80000cec <release>

  // Go to sleep.
  p->chan = chan;
    800021b6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021ba:	4789                	li	a5,2
    800021bc:	cc9c                	sw	a5,24(s1)

  sched();
    800021be:	00000097          	auipc	ra,0x0
    800021c2:	eb8080e7          	jalr	-328(ra) # 80002076 <sched>

  // Tidy up.
  p->chan = 0;
    800021c6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	b20080e7          	jalr	-1248(ra) # 80000cec <release>
  acquire(lk);
    800021d4:	854a                	mv	a0,s2
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	a62080e7          	jalr	-1438(ra) # 80000c38 <acquire>
}
    800021de:	70a2                	ld	ra,40(sp)
    800021e0:	7402                	ld	s0,32(sp)
    800021e2:	64e2                	ld	s1,24(sp)
    800021e4:	6942                	ld	s2,16(sp)
    800021e6:	69a2                	ld	s3,8(sp)
    800021e8:	6145                	addi	sp,sp,48
    800021ea:	8082                	ret

00000000800021ec <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800021ec:	7139                	addi	sp,sp,-64
    800021ee:	fc06                	sd	ra,56(sp)
    800021f0:	f822                	sd	s0,48(sp)
    800021f2:	f426                	sd	s1,40(sp)
    800021f4:	f04a                	sd	s2,32(sp)
    800021f6:	ec4e                	sd	s3,24(sp)
    800021f8:	e852                	sd	s4,16(sp)
    800021fa:	e456                	sd	s5,8(sp)
    800021fc:	0080                	addi	s0,sp,64
    800021fe:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	d8048493          	addi	s1,s1,-640 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002208:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000220a:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000220c:	00018917          	auipc	s2,0x18
    80002210:	97490913          	addi	s2,s2,-1676 # 80019b80 <tickslock>
    80002214:	a811                	j	80002228 <wakeup+0x3c>
      }
      release(&p->lock);
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	ad4080e7          	jalr	-1324(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002220:	23048493          	addi	s1,s1,560
    80002224:	03248663          	beq	s1,s2,80002250 <wakeup+0x64>
    if (p != myproc())
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	822080e7          	jalr	-2014(ra) # 80001a4a <myproc>
    80002230:	fea488e3          	beq	s1,a0,80002220 <wakeup+0x34>
      acquire(&p->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a02080e7          	jalr	-1534(ra) # 80000c38 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000223e:	4c9c                	lw	a5,24(s1)
    80002240:	fd379be3          	bne	a5,s3,80002216 <wakeup+0x2a>
    80002244:	709c                	ld	a5,32(s1)
    80002246:	fd4798e3          	bne	a5,s4,80002216 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000224a:	0154ac23          	sw	s5,24(s1)
    8000224e:	b7e1                	j	80002216 <wakeup+0x2a>
    }
  }
}
    80002250:	70e2                	ld	ra,56(sp)
    80002252:	7442                	ld	s0,48(sp)
    80002254:	74a2                	ld	s1,40(sp)
    80002256:	7902                	ld	s2,32(sp)
    80002258:	69e2                	ld	s3,24(sp)
    8000225a:	6a42                	ld	s4,16(sp)
    8000225c:	6aa2                	ld	s5,8(sp)
    8000225e:	6121                	addi	sp,sp,64
    80002260:	8082                	ret

0000000080002262 <reparent>:
{
    80002262:	7179                	addi	sp,sp,-48
    80002264:	f406                	sd	ra,40(sp)
    80002266:	f022                	sd	s0,32(sp)
    80002268:	ec26                	sd	s1,24(sp)
    8000226a:	e84a                	sd	s2,16(sp)
    8000226c:	e44e                	sd	s3,8(sp)
    8000226e:	e052                	sd	s4,0(sp)
    80002270:	1800                	addi	s0,sp,48
    80002272:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002274:	0000f497          	auipc	s1,0xf
    80002278:	d0c48493          	addi	s1,s1,-756 # 80010f80 <proc>
      pp->parent = initproc;
    8000227c:	00006a17          	auipc	s4,0x6
    80002280:	65ca0a13          	addi	s4,s4,1628 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002284:	00018997          	auipc	s3,0x18
    80002288:	8fc98993          	addi	s3,s3,-1796 # 80019b80 <tickslock>
    8000228c:	a029                	j	80002296 <reparent+0x34>
    8000228e:	23048493          	addi	s1,s1,560
    80002292:	01348d63          	beq	s1,s3,800022ac <reparent+0x4a>
    if (pp->parent == p)
    80002296:	7c9c                	ld	a5,56(s1)
    80002298:	ff279be3          	bne	a5,s2,8000228e <reparent+0x2c>
      pp->parent = initproc;
    8000229c:	000a3503          	ld	a0,0(s4)
    800022a0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022a2:	00000097          	auipc	ra,0x0
    800022a6:	f4a080e7          	jalr	-182(ra) # 800021ec <wakeup>
    800022aa:	b7d5                	j	8000228e <reparent+0x2c>
}
    800022ac:	70a2                	ld	ra,40(sp)
    800022ae:	7402                	ld	s0,32(sp)
    800022b0:	64e2                	ld	s1,24(sp)
    800022b2:	6942                	ld	s2,16(sp)
    800022b4:	69a2                	ld	s3,8(sp)
    800022b6:	6a02                	ld	s4,0(sp)
    800022b8:	6145                	addi	sp,sp,48
    800022ba:	8082                	ret

00000000800022bc <exit>:
{
    800022bc:	7139                	addi	sp,sp,-64
    800022be:	fc06                	sd	ra,56(sp)
    800022c0:	f822                	sd	s0,48(sp)
    800022c2:	f426                	sd	s1,40(sp)
    800022c4:	f04a                	sd	s2,32(sp)
    800022c6:	ec4e                	sd	s3,24(sp)
    800022c8:	e852                	sd	s4,16(sp)
    800022ca:	e456                	sd	s5,8(sp)
    800022cc:	0080                	addi	s0,sp,64
    800022ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	77a080e7          	jalr	1914(ra) # 80001a4a <myproc>
    800022d8:	89aa                	mv	s3,a0
  struct proc *par = p->parent;
    800022da:	03853903          	ld	s2,56(a0)
  if (p == initproc)
    800022de:	00006797          	auipc	a5,0x6
    800022e2:	5fa7b783          	ld	a5,1530(a5) # 800088d8 <initproc>
    800022e6:	18850493          	addi	s1,a0,392
    800022ea:	20850a93          	addi	s5,a0,520
    800022ee:	00a79d63          	bne	a5,a0,80002308 <exit+0x4c>
    panic("init exiting");
    800022f2:	00006517          	auipc	a0,0x6
    800022f6:	f4e50513          	addi	a0,a0,-178 # 80008240 <etext+0x240>
    800022fa:	ffffe097          	auipc	ra,0xffffe
    800022fe:	266080e7          	jalr	614(ra) # 80000560 <panic>
  for (int fd = 0; fd < NOFILE; fd++)
    80002302:	04a1                	addi	s1,s1,8
    80002304:	01548b63          	beq	s1,s5,8000231a <exit+0x5e>
    if (p->ofile[fd])
    80002308:	6088                	ld	a0,0(s1)
    8000230a:	dd65                	beqz	a0,80002302 <exit+0x46>
      fileclose(f);
    8000230c:	00003097          	auipc	ra,0x3
    80002310:	8fa080e7          	jalr	-1798(ra) # 80004c06 <fileclose>
      p->ofile[fd] = 0;
    80002314:	0004b023          	sd	zero,0(s1)
    80002318:	b7ed                	j	80002302 <exit+0x46>
    8000231a:	04090793          	addi	a5,s2,64
    8000231e:	04098693          	addi	a3,s3,64
    80002322:	0c090593          	addi	a1,s2,192
    par->syscall_count[i] += p->syscall_count[i];
    80002326:	4390                	lw	a2,0(a5)
    80002328:	4298                	lw	a4,0(a3)
    8000232a:	9f31                	addw	a4,a4,a2
    8000232c:	c398                	sw	a4,0(a5)
  for (int i = 0; i < 32; i++)
    8000232e:	0791                	addi	a5,a5,4
    80002330:	0691                	addi	a3,a3,4
    80002332:	feb79ae3          	bne	a5,a1,80002326 <exit+0x6a>
  begin_op();
    80002336:	00002097          	auipc	ra,0x2
    8000233a:	406080e7          	jalr	1030(ra) # 8000473c <begin_op>
  iput(p->cwd);
    8000233e:	2089b503          	ld	a0,520(s3)
    80002342:	00002097          	auipc	ra,0x2
    80002346:	bea080e7          	jalr	-1046(ra) # 80003f2c <iput>
  end_op();
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	46c080e7          	jalr	1132(ra) # 800047b6 <end_op>
  p->cwd = 0;
    80002352:	2009b423          	sd	zero,520(s3)
  acquire(&wait_lock);
    80002356:	0000f497          	auipc	s1,0xf
    8000235a:	81248493          	addi	s1,s1,-2030 # 80010b68 <wait_lock>
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	8d8080e7          	jalr	-1832(ra) # 80000c38 <acquire>
  reparent(p);
    80002368:	854e                	mv	a0,s3
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	ef8080e7          	jalr	-264(ra) # 80002262 <reparent>
  wakeup(p->parent);
    80002372:	0389b503          	ld	a0,56(s3)
    80002376:	00000097          	auipc	ra,0x0
    8000237a:	e76080e7          	jalr	-394(ra) # 800021ec <wakeup>
  acquire(&p->lock);
    8000237e:	854e                	mv	a0,s3
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	8b8080e7          	jalr	-1864(ra) # 80000c38 <acquire>
  p->xstate = status;
    80002388:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000238c:	4795                	li	a5,5
    8000238e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002392:	00006797          	auipc	a5,0x6
    80002396:	54e7a783          	lw	a5,1358(a5) # 800088e0 <ticks>
    8000239a:	22f9a423          	sw	a5,552(s3)
  release(&wait_lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	94c080e7          	jalr	-1716(ra) # 80000cec <release>
  sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	cce080e7          	jalr	-818(ra) # 80002076 <sched>
  panic("zombie exit");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	ea050513          	addi	a0,a0,-352 # 80008250 <etext+0x250>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	1a8080e7          	jalr	424(ra) # 80000560 <panic>

00000000800023c0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023c0:	7179                	addi	sp,sp,-48
    800023c2:	f406                	sd	ra,40(sp)
    800023c4:	f022                	sd	s0,32(sp)
    800023c6:	ec26                	sd	s1,24(sp)
    800023c8:	e84a                	sd	s2,16(sp)
    800023ca:	e44e                	sd	s3,8(sp)
    800023cc:	1800                	addi	s0,sp,48
    800023ce:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023d0:	0000f497          	auipc	s1,0xf
    800023d4:	bb048493          	addi	s1,s1,-1104 # 80010f80 <proc>
    800023d8:	00017997          	auipc	s3,0x17
    800023dc:	7a898993          	addi	s3,s3,1960 # 80019b80 <tickslock>
  {
    acquire(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	856080e7          	jalr	-1962(ra) # 80000c38 <acquire>
    if (p->pid == pid)
    800023ea:	589c                	lw	a5,48(s1)
    800023ec:	01278d63          	beq	a5,s2,80002406 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8fa080e7          	jalr	-1798(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023fa:	23048493          	addi	s1,s1,560
    800023fe:	ff3491e3          	bne	s1,s3,800023e0 <kill+0x20>
  }
  return -1;
    80002402:	557d                	li	a0,-1
    80002404:	a829                	j	8000241e <kill+0x5e>
      p->killed = 1;
    80002406:	4785                	li	a5,1
    80002408:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000240a:	4c98                	lw	a4,24(s1)
    8000240c:	4789                	li	a5,2
    8000240e:	00f70f63          	beq	a4,a5,8000242c <kill+0x6c>
      release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	8d8080e7          	jalr	-1832(ra) # 80000cec <release>
      return 0;
    8000241c:	4501                	li	a0,0
}
    8000241e:	70a2                	ld	ra,40(sp)
    80002420:	7402                	ld	s0,32(sp)
    80002422:	64e2                	ld	s1,24(sp)
    80002424:	6942                	ld	s2,16(sp)
    80002426:	69a2                	ld	s3,8(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret
        p->state = RUNNABLE;
    8000242c:	478d                	li	a5,3
    8000242e:	cc9c                	sw	a5,24(s1)
    80002430:	b7cd                	j	80002412 <kill+0x52>

0000000080002432 <setkilled>:

void setkilled(struct proc *p)
{
    80002432:	1101                	addi	sp,sp,-32
    80002434:	ec06                	sd	ra,24(sp)
    80002436:	e822                	sd	s0,16(sp)
    80002438:	e426                	sd	s1,8(sp)
    8000243a:	1000                	addi	s0,sp,32
    8000243c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	7fa080e7          	jalr	2042(ra) # 80000c38 <acquire>
  p->killed = 1;
    80002446:	4785                	li	a5,1
    80002448:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8a0080e7          	jalr	-1888(ra) # 80000cec <release>
}
    80002454:	60e2                	ld	ra,24(sp)
    80002456:	6442                	ld	s0,16(sp)
    80002458:	64a2                	ld	s1,8(sp)
    8000245a:	6105                	addi	sp,sp,32
    8000245c:	8082                	ret

000000008000245e <killed>:

int killed(struct proc *p)
{
    8000245e:	1101                	addi	sp,sp,-32
    80002460:	ec06                	sd	ra,24(sp)
    80002462:	e822                	sd	s0,16(sp)
    80002464:	e426                	sd	s1,8(sp)
    80002466:	e04a                	sd	s2,0(sp)
    80002468:	1000                	addi	s0,sp,32
    8000246a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	7cc080e7          	jalr	1996(ra) # 80000c38 <acquire>
  k = p->killed;
    80002474:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	872080e7          	jalr	-1934(ra) # 80000cec <release>
  return k;
}
    80002482:	854a                	mv	a0,s2
    80002484:	60e2                	ld	ra,24(sp)
    80002486:	6442                	ld	s0,16(sp)
    80002488:	64a2                	ld	s1,8(sp)
    8000248a:	6902                	ld	s2,0(sp)
    8000248c:	6105                	addi	sp,sp,32
    8000248e:	8082                	ret

0000000080002490 <wait>:
{
    80002490:	715d                	addi	sp,sp,-80
    80002492:	e486                	sd	ra,72(sp)
    80002494:	e0a2                	sd	s0,64(sp)
    80002496:	fc26                	sd	s1,56(sp)
    80002498:	f84a                	sd	s2,48(sp)
    8000249a:	f44e                	sd	s3,40(sp)
    8000249c:	f052                	sd	s4,32(sp)
    8000249e:	ec56                	sd	s5,24(sp)
    800024a0:	e85a                	sd	s6,16(sp)
    800024a2:	e45e                	sd	s7,8(sp)
    800024a4:	e062                	sd	s8,0(sp)
    800024a6:	0880                	addi	s0,sp,80
    800024a8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	5a0080e7          	jalr	1440(ra) # 80001a4a <myproc>
    800024b2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024b4:	0000e517          	auipc	a0,0xe
    800024b8:	6b450513          	addi	a0,a0,1716 # 80010b68 <wait_lock>
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	77c080e7          	jalr	1916(ra) # 80000c38 <acquire>
    havekids = 0;
    800024c4:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024c6:	4a15                	li	s4,5
        havekids = 1;
    800024c8:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024ca:	00017997          	auipc	s3,0x17
    800024ce:	6b698993          	addi	s3,s3,1718 # 80019b80 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024d2:	0000ec17          	auipc	s8,0xe
    800024d6:	696c0c13          	addi	s8,s8,1686 # 80010b68 <wait_lock>
    800024da:	a0d1                	j	8000259e <wait+0x10e>
          pid = pp->pid;
    800024dc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024e0:	000b0e63          	beqz	s6,800024fc <wait+0x6c>
    800024e4:	4691                	li	a3,4
    800024e6:	02c48613          	addi	a2,s1,44
    800024ea:	85da                	mv	a1,s6
    800024ec:	10893503          	ld	a0,264(s2)
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	1f2080e7          	jalr	498(ra) # 800016e2 <copyout>
    800024f8:	04054163          	bltz	a0,8000253a <wait+0xaa>
          freeproc(pp);
    800024fc:	8526                	mv	a0,s1
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	6fe080e7          	jalr	1790(ra) # 80001bfc <freeproc>
          release(&pp->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	7e4080e7          	jalr	2020(ra) # 80000cec <release>
          release(&wait_lock);
    80002510:	0000e517          	auipc	a0,0xe
    80002514:	65850513          	addi	a0,a0,1624 # 80010b68 <wait_lock>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	7d4080e7          	jalr	2004(ra) # 80000cec <release>
}
    80002520:	854e                	mv	a0,s3
    80002522:	60a6                	ld	ra,72(sp)
    80002524:	6406                	ld	s0,64(sp)
    80002526:	74e2                	ld	s1,56(sp)
    80002528:	7942                	ld	s2,48(sp)
    8000252a:	79a2                	ld	s3,40(sp)
    8000252c:	7a02                	ld	s4,32(sp)
    8000252e:	6ae2                	ld	s5,24(sp)
    80002530:	6b42                	ld	s6,16(sp)
    80002532:	6ba2                	ld	s7,8(sp)
    80002534:	6c02                	ld	s8,0(sp)
    80002536:	6161                	addi	sp,sp,80
    80002538:	8082                	ret
            release(&pp->lock);
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	7b0080e7          	jalr	1968(ra) # 80000cec <release>
            release(&wait_lock);
    80002544:	0000e517          	auipc	a0,0xe
    80002548:	62450513          	addi	a0,a0,1572 # 80010b68 <wait_lock>
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	7a0080e7          	jalr	1952(ra) # 80000cec <release>
            return -1;
    80002554:	59fd                	li	s3,-1
    80002556:	b7e9                	j	80002520 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002558:	23048493          	addi	s1,s1,560
    8000255c:	03348463          	beq	s1,s3,80002584 <wait+0xf4>
      if (pp->parent == p)
    80002560:	7c9c                	ld	a5,56(s1)
    80002562:	ff279be3          	bne	a5,s2,80002558 <wait+0xc8>
        acquire(&pp->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	6d0080e7          	jalr	1744(ra) # 80000c38 <acquire>
        if (pp->state == ZOMBIE)
    80002570:	4c9c                	lw	a5,24(s1)
    80002572:	f74785e3          	beq	a5,s4,800024dc <wait+0x4c>
        release(&pp->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	774080e7          	jalr	1908(ra) # 80000cec <release>
        havekids = 1;
    80002580:	8756                	mv	a4,s5
    80002582:	bfd9                	j	80002558 <wait+0xc8>
    if (!havekids || killed(p))
    80002584:	c31d                	beqz	a4,800025aa <wait+0x11a>
    80002586:	854a                	mv	a0,s2
    80002588:	00000097          	auipc	ra,0x0
    8000258c:	ed6080e7          	jalr	-298(ra) # 8000245e <killed>
    80002590:	ed09                	bnez	a0,800025aa <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002592:	85e2                	mv	a1,s8
    80002594:	854a                	mv	a0,s2
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	bf2080e7          	jalr	-1038(ra) # 80002188 <sleep>
    havekids = 0;
    8000259e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025a0:	0000f497          	auipc	s1,0xf
    800025a4:	9e048493          	addi	s1,s1,-1568 # 80010f80 <proc>
    800025a8:	bf65                	j	80002560 <wait+0xd0>
      release(&wait_lock);
    800025aa:	0000e517          	auipc	a0,0xe
    800025ae:	5be50513          	addi	a0,a0,1470 # 80010b68 <wait_lock>
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	73a080e7          	jalr	1850(ra) # 80000cec <release>
      return -1;
    800025ba:	59fd                	li	s3,-1
    800025bc:	b795                	j	80002520 <wait+0x90>

00000000800025be <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	84aa                	mv	s1,a0
    800025d0:	892e                	mv	s2,a1
    800025d2:	89b2                	mv	s3,a2
    800025d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	474080e7          	jalr	1140(ra) # 80001a4a <myproc>
  if (user_dst)
    800025de:	c095                	beqz	s1,80002602 <either_copyout+0x44>
  {
    return copyout(p->pagetable, dst, src, len);
    800025e0:	86d2                	mv	a3,s4
    800025e2:	864e                	mv	a2,s3
    800025e4:	85ca                	mv	a1,s2
    800025e6:	10853503          	ld	a0,264(a0)
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	0f8080e7          	jalr	248(ra) # 800016e2 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025f2:	70a2                	ld	ra,40(sp)
    800025f4:	7402                	ld	s0,32(sp)
    800025f6:	64e2                	ld	s1,24(sp)
    800025f8:	6942                	ld	s2,16(sp)
    800025fa:	69a2                	ld	s3,8(sp)
    800025fc:	6a02                	ld	s4,0(sp)
    800025fe:	6145                	addi	sp,sp,48
    80002600:	8082                	ret
    memmove((char *)dst, src, len);
    80002602:	000a061b          	sext.w	a2,s4
    80002606:	85ce                	mv	a1,s3
    80002608:	854a                	mv	a0,s2
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	786080e7          	jalr	1926(ra) # 80000d90 <memmove>
    return 0;
    80002612:	8526                	mv	a0,s1
    80002614:	bff9                	j	800025f2 <either_copyout+0x34>

0000000080002616 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002616:	7179                	addi	sp,sp,-48
    80002618:	f406                	sd	ra,40(sp)
    8000261a:	f022                	sd	s0,32(sp)
    8000261c:	ec26                	sd	s1,24(sp)
    8000261e:	e84a                	sd	s2,16(sp)
    80002620:	e44e                	sd	s3,8(sp)
    80002622:	e052                	sd	s4,0(sp)
    80002624:	1800                	addi	s0,sp,48
    80002626:	892a                	mv	s2,a0
    80002628:	84ae                	mv	s1,a1
    8000262a:	89b2                	mv	s3,a2
    8000262c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	41c080e7          	jalr	1052(ra) # 80001a4a <myproc>
  if (user_src)
    80002636:	c095                	beqz	s1,8000265a <either_copyin+0x44>
  {
    return copyin(p->pagetable, dst, src, len);
    80002638:	86d2                	mv	a3,s4
    8000263a:	864e                	mv	a2,s3
    8000263c:	85ca                	mv	a1,s2
    8000263e:	10853503          	ld	a0,264(a0)
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	12c080e7          	jalr	300(ra) # 8000176e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000264a:	70a2                	ld	ra,40(sp)
    8000264c:	7402                	ld	s0,32(sp)
    8000264e:	64e2                	ld	s1,24(sp)
    80002650:	6942                	ld	s2,16(sp)
    80002652:	69a2                	ld	s3,8(sp)
    80002654:	6a02                	ld	s4,0(sp)
    80002656:	6145                	addi	sp,sp,48
    80002658:	8082                	ret
    memmove(dst, (char *)src, len);
    8000265a:	000a061b          	sext.w	a2,s4
    8000265e:	85ce                	mv	a1,s3
    80002660:	854a                	mv	a0,s2
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	72e080e7          	jalr	1838(ra) # 80000d90 <memmove>
    return 0;
    8000266a:	8526                	mv	a0,s1
    8000266c:	bff9                	j	8000264a <either_copyin+0x34>

000000008000266e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000266e:	715d                	addi	sp,sp,-80
    80002670:	e486                	sd	ra,72(sp)
    80002672:	e0a2                	sd	s0,64(sp)
    80002674:	fc26                	sd	s1,56(sp)
    80002676:	f84a                	sd	s2,48(sp)
    80002678:	f44e                	sd	s3,40(sp)
    8000267a:	f052                	sd	s4,32(sp)
    8000267c:	ec56                	sd	s5,24(sp)
    8000267e:	e85a                	sd	s6,16(sp)
    80002680:	e45e                	sd	s7,8(sp)
    80002682:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	98c50513          	addi	a0,a0,-1652 # 80008010 <etext+0x10>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	f1e080e7          	jalr	-226(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002694:	0000f497          	auipc	s1,0xf
    80002698:	afc48493          	addi	s1,s1,-1284 # 80011190 <proc+0x210>
    8000269c:	00017917          	auipc	s2,0x17
    800026a0:	6f490913          	addi	s2,s2,1780 # 80019d90 <bcache+0x1f8>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026a6:	00006997          	auipc	s3,0x6
    800026aa:	bba98993          	addi	s3,s3,-1094 # 80008260 <etext+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    800026ae:	00006a97          	auipc	s5,0x6
    800026b2:	bbaa8a93          	addi	s5,s5,-1094 # 80008268 <etext+0x268>
    printf("\n");
    800026b6:	00006a17          	auipc	s4,0x6
    800026ba:	95aa0a13          	addi	s4,s4,-1702 # 80008010 <etext+0x10>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026be:	00006b97          	auipc	s7,0x6
    800026c2:	082b8b93          	addi	s7,s7,130 # 80008740 <states.0>
    800026c6:	a00d                	j	800026e8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026c8:	e206a583          	lw	a1,-480(a3)
    800026cc:	8556                	mv	a0,s5
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	edc080e7          	jalr	-292(ra) # 800005aa <printf>
    printf("\n");
    800026d6:	8552                	mv	a0,s4
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	ed2080e7          	jalr	-302(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026e0:	23048493          	addi	s1,s1,560
    800026e4:	03248263          	beq	s1,s2,80002708 <procdump+0x9a>
    if (p->state == UNUSED)
    800026e8:	86a6                	mv	a3,s1
    800026ea:	e084a783          	lw	a5,-504(s1)
    800026ee:	dbed                	beqz	a5,800026e0 <procdump+0x72>
      state = "???";
    800026f0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f2:	fcfb6be3          	bltu	s6,a5,800026c8 <procdump+0x5a>
    800026f6:	02079713          	slli	a4,a5,0x20
    800026fa:	01d75793          	srli	a5,a4,0x1d
    800026fe:	97de                	add	a5,a5,s7
    80002700:	6390                	ld	a2,0(a5)
    80002702:	f279                	bnez	a2,800026c8 <procdump+0x5a>
      state = "???";
    80002704:	864e                	mv	a2,s3
    80002706:	b7c9                	j	800026c8 <procdump+0x5a>
  }
}
    80002708:	60a6                	ld	ra,72(sp)
    8000270a:	6406                	ld	s0,64(sp)
    8000270c:	74e2                	ld	s1,56(sp)
    8000270e:	7942                	ld	s2,48(sp)
    80002710:	79a2                	ld	s3,40(sp)
    80002712:	7a02                	ld	s4,32(sp)
    80002714:	6ae2                	ld	s5,24(sp)
    80002716:	6b42                	ld	s6,16(sp)
    80002718:	6ba2                	ld	s7,8(sp)
    8000271a:	6161                	addi	sp,sp,80
    8000271c:	8082                	ret

000000008000271e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000271e:	711d                	addi	sp,sp,-96
    80002720:	ec86                	sd	ra,88(sp)
    80002722:	e8a2                	sd	s0,80(sp)
    80002724:	e4a6                	sd	s1,72(sp)
    80002726:	e0ca                	sd	s2,64(sp)
    80002728:	fc4e                	sd	s3,56(sp)
    8000272a:	f852                	sd	s4,48(sp)
    8000272c:	f456                	sd	s5,40(sp)
    8000272e:	f05a                	sd	s6,32(sp)
    80002730:	ec5e                	sd	s7,24(sp)
    80002732:	e862                	sd	s8,16(sp)
    80002734:	e466                	sd	s9,8(sp)
    80002736:	e06a                	sd	s10,0(sp)
    80002738:	1080                	addi	s0,sp,96
    8000273a:	8b2a                	mv	s6,a0
    8000273c:	8bae                	mv	s7,a1
    8000273e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	30a080e7          	jalr	778(ra) # 80001a4a <myproc>
    80002748:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000274a:	0000e517          	auipc	a0,0xe
    8000274e:	41e50513          	addi	a0,a0,1054 # 80010b68 <wait_lock>
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	4e6080e7          	jalr	1254(ra) # 80000c38 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000275a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000275c:	4a15                	li	s4,5
        havekids = 1;
    8000275e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002760:	00017997          	auipc	s3,0x17
    80002764:	42098993          	addi	s3,s3,1056 # 80019b80 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002768:	0000ed17          	auipc	s10,0xe
    8000276c:	400d0d13          	addi	s10,s10,1024 # 80010b68 <wait_lock>
    80002770:	a8e9                	j	8000284a <waitx+0x12c>
          pid = np->pid;
    80002772:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002776:	2204a783          	lw	a5,544(s1)
    8000277a:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000277e:	2244a703          	lw	a4,548(s1)
    80002782:	9f3d                	addw	a4,a4,a5
    80002784:	2284a783          	lw	a5,552(s1)
    80002788:	9f99                	subw	a5,a5,a4
    8000278a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000278e:	000b0e63          	beqz	s6,800027aa <waitx+0x8c>
    80002792:	4691                	li	a3,4
    80002794:	02c48613          	addi	a2,s1,44
    80002798:	85da                	mv	a1,s6
    8000279a:	10893503          	ld	a0,264(s2)
    8000279e:	fffff097          	auipc	ra,0xfffff
    800027a2:	f44080e7          	jalr	-188(ra) # 800016e2 <copyout>
    800027a6:	04054363          	bltz	a0,800027ec <waitx+0xce>
          freeproc(np);
    800027aa:	8526                	mv	a0,s1
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	450080e7          	jalr	1104(ra) # 80001bfc <freeproc>
          release(&np->lock);
    800027b4:	8526                	mv	a0,s1
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	536080e7          	jalr	1334(ra) # 80000cec <release>
          release(&wait_lock);
    800027be:	0000e517          	auipc	a0,0xe
    800027c2:	3aa50513          	addi	a0,a0,938 # 80010b68 <wait_lock>
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	526080e7          	jalr	1318(ra) # 80000cec <release>
  }
}
    800027ce:	854e                	mv	a0,s3
    800027d0:	60e6                	ld	ra,88(sp)
    800027d2:	6446                	ld	s0,80(sp)
    800027d4:	64a6                	ld	s1,72(sp)
    800027d6:	6906                	ld	s2,64(sp)
    800027d8:	79e2                	ld	s3,56(sp)
    800027da:	7a42                	ld	s4,48(sp)
    800027dc:	7aa2                	ld	s5,40(sp)
    800027de:	7b02                	ld	s6,32(sp)
    800027e0:	6be2                	ld	s7,24(sp)
    800027e2:	6c42                	ld	s8,16(sp)
    800027e4:	6ca2                	ld	s9,8(sp)
    800027e6:	6d02                	ld	s10,0(sp)
    800027e8:	6125                	addi	sp,sp,96
    800027ea:	8082                	ret
            release(&np->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	4fe080e7          	jalr	1278(ra) # 80000cec <release>
            release(&wait_lock);
    800027f6:	0000e517          	auipc	a0,0xe
    800027fa:	37250513          	addi	a0,a0,882 # 80010b68 <wait_lock>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	4ee080e7          	jalr	1262(ra) # 80000cec <release>
            return -1;
    80002806:	59fd                	li	s3,-1
    80002808:	b7d9                	j	800027ce <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    8000280a:	23048493          	addi	s1,s1,560
    8000280e:	03348463          	beq	s1,s3,80002836 <waitx+0x118>
      if (np->parent == p)
    80002812:	7c9c                	ld	a5,56(s1)
    80002814:	ff279be3          	bne	a5,s2,8000280a <waitx+0xec>
        acquire(&np->lock);
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	41e080e7          	jalr	1054(ra) # 80000c38 <acquire>
        if (np->state == ZOMBIE)
    80002822:	4c9c                	lw	a5,24(s1)
    80002824:	f54787e3          	beq	a5,s4,80002772 <waitx+0x54>
        release(&np->lock);
    80002828:	8526                	mv	a0,s1
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	4c2080e7          	jalr	1218(ra) # 80000cec <release>
        havekids = 1;
    80002832:	8756                	mv	a4,s5
    80002834:	bfd9                	j	8000280a <waitx+0xec>
    if (!havekids || p->killed)
    80002836:	c305                	beqz	a4,80002856 <waitx+0x138>
    80002838:	02892783          	lw	a5,40(s2)
    8000283c:	ef89                	bnez	a5,80002856 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000283e:	85ea                	mv	a1,s10
    80002840:	854a                	mv	a0,s2
    80002842:	00000097          	auipc	ra,0x0
    80002846:	946080e7          	jalr	-1722(ra) # 80002188 <sleep>
    havekids = 0;
    8000284a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000284c:	0000e497          	auipc	s1,0xe
    80002850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
    80002854:	bf7d                	j	80002812 <waitx+0xf4>
      release(&wait_lock);
    80002856:	0000e517          	auipc	a0,0xe
    8000285a:	31250513          	addi	a0,a0,786 # 80010b68 <wait_lock>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	48e080e7          	jalr	1166(ra) # 80000cec <release>
      return -1;
    80002866:	59fd                	li	s3,-1
    80002868:	b79d                	j	800027ce <waitx+0xb0>

000000008000286a <update_time>:

void update_time()
{
    8000286a:	7179                	addi	sp,sp,-48
    8000286c:	f406                	sd	ra,40(sp)
    8000286e:	f022                	sd	s0,32(sp)
    80002870:	ec26                	sd	s1,24(sp)
    80002872:	e84a                	sd	s2,16(sp)
    80002874:	e44e                	sd	s3,8(sp)
    80002876:	1800                	addi	s0,sp,48

  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002878:	0000e497          	auipc	s1,0xe
    8000287c:	70848493          	addi	s1,s1,1800 # 80010f80 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002880:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002882:	00017917          	auipc	s2,0x17
    80002886:	2fe90913          	addi	s2,s2,766 # 80019b80 <tickslock>
    8000288a:	a811                	j	8000289e <update_time+0x34>
#ifdef MLFQ
      p->qrtime[p->priority]++;
      p->timeslice--;
#endif
    }
    release(&p->lock);
    8000288c:	8526                	mv	a0,s1
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	45e080e7          	jalr	1118(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002896:	23048493          	addi	s1,s1,560
    8000289a:	03248063          	beq	s1,s2,800028ba <update_time+0x50>
    acquire(&p->lock);
    8000289e:	8526                	mv	a0,s1
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	398080e7          	jalr	920(ra) # 80000c38 <acquire>
    if (p->state == RUNNING)
    800028a8:	4c9c                	lw	a5,24(s1)
    800028aa:	ff3791e3          	bne	a5,s3,8000288c <update_time+0x22>
      p->rtime++;
    800028ae:	2204a783          	lw	a5,544(s1)
    800028b2:	2785                	addiw	a5,a5,1
    800028b4:	22f4a023          	sw	a5,544(s1)
    800028b8:	bfd1                	j	8000288c <update_time+0x22>
  }
}
    800028ba:	70a2                	ld	ra,40(sp)
    800028bc:	7402                	ld	s0,32(sp)
    800028be:	64e2                	ld	s1,24(sp)
    800028c0:	6942                	ld	s2,16(sp)
    800028c2:	69a2                	ld	s3,8(sp)
    800028c4:	6145                	addi	sp,sp,48
    800028c6:	8082                	ret

00000000800028c8 <settickets>:

uint64 settickets(int number)
{
    800028c8:	1101                	addi	sp,sp,-32
    800028ca:	ec06                	sd	ra,24(sp)
    800028cc:	e822                	sd	s0,16(sp)
    800028ce:	e426                	sd	s1,8(sp)
    800028d0:	1000                	addi	s0,sp,32
    800028d2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028d4:	fffff097          	auipc	ra,0xfffff
    800028d8:	176080e7          	jalr	374(ra) # 80001a4a <myproc>
  if (number <= 0)
    800028dc:	02905663          	blez	s1,80002908 <settickets+0x40>
    800028e0:	e04a                	sd	s2,0(sp)
    800028e2:	892a                	mv	s2,a0
    return -1;
  acquire(&p->lock);
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	354080e7          	jalr	852(ra) # 80000c38 <acquire>
  p->tickets = number;
    800028ec:	0e992023          	sw	s1,224(s2)
  release(&p->lock);
    800028f0:	854a                	mv	a0,s2
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	3fa080e7          	jalr	1018(ra) # 80000cec <release>
  return number;
    800028fa:	8526                	mv	a0,s1
    800028fc:	6902                	ld	s2,0(sp)
}
    800028fe:	60e2                	ld	ra,24(sp)
    80002900:	6442                	ld	s0,16(sp)
    80002902:	64a2                	ld	s1,8(sp)
    80002904:	6105                	addi	sp,sp,32
    80002906:	8082                	ret
    return -1;
    80002908:	557d                	li	a0,-1
    8000290a:	bfd5                	j	800028fe <settickets+0x36>

000000008000290c <swtch>:
    8000290c:	00153023          	sd	ra,0(a0)
    80002910:	00253423          	sd	sp,8(a0)
    80002914:	e900                	sd	s0,16(a0)
    80002916:	ed04                	sd	s1,24(a0)
    80002918:	03253023          	sd	s2,32(a0)
    8000291c:	03353423          	sd	s3,40(a0)
    80002920:	03453823          	sd	s4,48(a0)
    80002924:	03553c23          	sd	s5,56(a0)
    80002928:	05653023          	sd	s6,64(a0)
    8000292c:	05753423          	sd	s7,72(a0)
    80002930:	05853823          	sd	s8,80(a0)
    80002934:	05953c23          	sd	s9,88(a0)
    80002938:	07a53023          	sd	s10,96(a0)
    8000293c:	07b53423          	sd	s11,104(a0)
    80002940:	0005b083          	ld	ra,0(a1)
    80002944:	0085b103          	ld	sp,8(a1)
    80002948:	6980                	ld	s0,16(a1)
    8000294a:	6d84                	ld	s1,24(a1)
    8000294c:	0205b903          	ld	s2,32(a1)
    80002950:	0285b983          	ld	s3,40(a1)
    80002954:	0305ba03          	ld	s4,48(a1)
    80002958:	0385ba83          	ld	s5,56(a1)
    8000295c:	0405bb03          	ld	s6,64(a1)
    80002960:	0485bb83          	ld	s7,72(a1)
    80002964:	0505bc03          	ld	s8,80(a1)
    80002968:	0585bc83          	ld	s9,88(a1)
    8000296c:	0605bd03          	ld	s10,96(a1)
    80002970:	0685bd83          	ld	s11,104(a1)
    80002974:	8082                	ret

0000000080002976 <trapinit>:
#ifdef MLFQ
extern struct Queue mlfq[NMLFQ];
#endif

void trapinit(void)
{
    80002976:	1141                	addi	sp,sp,-16
    80002978:	e406                	sd	ra,8(sp)
    8000297a:	e022                	sd	s0,0(sp)
    8000297c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000297e:	00006597          	auipc	a1,0x6
    80002982:	92a58593          	addi	a1,a1,-1750 # 800082a8 <etext+0x2a8>
    80002986:	00017517          	auipc	a0,0x17
    8000298a:	1fa50513          	addi	a0,a0,506 # 80019b80 <tickslock>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	21a080e7          	jalr	538(ra) # 80000ba8 <initlock>
}
    80002996:	60a2                	ld	ra,8(sp)
    80002998:	6402                	ld	s0,0(sp)
    8000299a:	0141                	addi	sp,sp,16
    8000299c:	8082                	ret

000000008000299e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000299e:	1141                	addi	sp,sp,-16
    800029a0:	e422                	sd	s0,8(sp)
    800029a2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a4:	00004797          	auipc	a5,0x4
    800029a8:	96c78793          	addi	a5,a5,-1684 # 80006310 <kernelvec>
    800029ac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b0:	6422                	ld	s0,8(sp)
    800029b2:	0141                	addi	sp,sp,16
    800029b4:	8082                	ret

00000000800029b6 <usertrapret>:

  usertrapret();
}

void usertrapret(void)
{
    800029b6:	1141                	addi	sp,sp,-16
    800029b8:	e406                	sd	ra,8(sp)
    800029ba:	e022                	sd	s0,0(sp)
    800029bc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	08c080e7          	jalr	140(ra) # 80001a4a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029cc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029d0:	00004697          	auipc	a3,0x4
    800029d4:	63068693          	addi	a3,a3,1584 # 80007000 <_trampoline>
    800029d8:	00004717          	auipc	a4,0x4
    800029dc:	62870713          	addi	a4,a4,1576 # 80007000 <_trampoline>
    800029e0:	8f15                	sub	a4,a4,a3
    800029e2:	040007b7          	lui	a5,0x4000
    800029e6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029e8:	07b2                	slli	a5,a5,0xc
    800029ea:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ec:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f0:	11053703          	ld	a4,272(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f4:	18002673          	csrr	a2,satp
    800029f8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029fa:	11053603          	ld	a2,272(a0)
    800029fe:	7d78                	ld	a4,248(a0)
    80002a00:	6585                	lui	a1,0x1
    80002a02:	972e                	add	a4,a4,a1
    80002a04:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a06:	11053703          	ld	a4,272(a0)
    80002a0a:	00000617          	auipc	a2,0x0
    80002a0e:	14c60613          	addi	a2,a2,332 # 80002b56 <usertrap>
    80002a12:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a14:	11053703          	ld	a4,272(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a18:	8612                	mv	a2,tp
    80002a1a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a20:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a24:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a28:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a2c:	11053703          	ld	a4,272(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a30:	6f18                	ld	a4,24(a4)
    80002a32:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a36:	10853503          	ld	a0,264(a0)
    80002a3a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a3c:	00004717          	auipc	a4,0x4
    80002a40:	66070713          	addi	a4,a4,1632 # 8000709c <userret>
    80002a44:	8f15                	sub	a4,a4,a3
    80002a46:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a48:	577d                	li	a4,-1
    80002a4a:	177e                	slli	a4,a4,0x3f
    80002a4c:	8d59                	or	a0,a0,a4
    80002a4e:	9782                	jalr	a5
}
    80002a50:	60a2                	ld	ra,8(sp)
    80002a52:	6402                	ld	s0,0(sp)
    80002a54:	0141                	addi	sp,sp,16
    80002a56:	8082                	ret

0000000080002a58 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a58:	1101                	addi	sp,sp,-32
    80002a5a:	ec06                	sd	ra,24(sp)
    80002a5c:	e822                	sd	s0,16(sp)
    80002a5e:	e426                	sd	s1,8(sp)
    80002a60:	e04a                	sd	s2,0(sp)
    80002a62:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a64:	00017917          	auipc	s2,0x17
    80002a68:	11c90913          	addi	s2,s2,284 # 80019b80 <tickslock>
    80002a6c:	854a                	mv	a0,s2
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	1ca080e7          	jalr	458(ra) # 80000c38 <acquire>
  ticks++;
    80002a76:	00006497          	auipc	s1,0x6
    80002a7a:	e6a48493          	addi	s1,s1,-406 # 800088e0 <ticks>
    80002a7e:	409c                	lw	a5,0(s1)
    80002a80:	2785                	addiw	a5,a5,1
    80002a82:	c09c                	sw	a5,0(s1)
  update_time();
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	de6080e7          	jalr	-538(ra) # 8000286a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002a8c:	8526                	mv	a0,s1
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	75e080e7          	jalr	1886(ra) # 800021ec <wakeup>
  release(&tickslock);
    80002a96:	854a                	mv	a0,s2
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	254080e7          	jalr	596(ra) # 80000cec <release>
}
    80002aa0:	60e2                	ld	ra,24(sp)
    80002aa2:	6442                	ld	s0,16(sp)
    80002aa4:	64a2                	ld	s1,8(sp)
    80002aa6:	6902                	ld	s2,0(sp)
    80002aa8:	6105                	addi	sp,sp,32
    80002aaa:	8082                	ret

0000000080002aac <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aac:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002ab0:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002ab2:	0a07d163          	bgez	a5,80002b54 <devintr+0xa8>
{
    80002ab6:	1101                	addi	sp,sp,-32
    80002ab8:	ec06                	sd	ra,24(sp)
    80002aba:	e822                	sd	s0,16(sp)
    80002abc:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002abe:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002ac2:	46a5                	li	a3,9
    80002ac4:	00d70c63          	beq	a4,a3,80002adc <devintr+0x30>
  else if (scause == 0x8000000000000001L)
    80002ac8:	577d                	li	a4,-1
    80002aca:	177e                	slli	a4,a4,0x3f
    80002acc:	0705                	addi	a4,a4,1
    return 0;
    80002ace:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002ad0:	06e78163          	beq	a5,a4,80002b32 <devintr+0x86>
  }
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	6105                	addi	sp,sp,32
    80002ada:	8082                	ret
    80002adc:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002ade:	00004097          	auipc	ra,0x4
    80002ae2:	93e080e7          	jalr	-1730(ra) # 8000641c <plic_claim>
    80002ae6:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ae8:	47a9                	li	a5,10
    80002aea:	00f50963          	beq	a0,a5,80002afc <devintr+0x50>
    else if (irq == VIRTIO0_IRQ)
    80002aee:	4785                	li	a5,1
    80002af0:	00f50b63          	beq	a0,a5,80002b06 <devintr+0x5a>
    return 1;
    80002af4:	4505                	li	a0,1
    else if (irq)
    80002af6:	ec89                	bnez	s1,80002b10 <devintr+0x64>
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	bfe9                	j	80002ad4 <devintr+0x28>
      uartintr();
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	efe080e7          	jalr	-258(ra) # 800009fa <uartintr>
    if (irq)
    80002b04:	a839                	j	80002b22 <devintr+0x76>
      virtio_disk_intr();
    80002b06:	00004097          	auipc	ra,0x4
    80002b0a:	e40080e7          	jalr	-448(ra) # 80006946 <virtio_disk_intr>
    if (irq)
    80002b0e:	a811                	j	80002b22 <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b10:	85a6                	mv	a1,s1
    80002b12:	00005517          	auipc	a0,0x5
    80002b16:	79e50513          	addi	a0,a0,1950 # 800082b0 <etext+0x2b0>
    80002b1a:	ffffe097          	auipc	ra,0xffffe
    80002b1e:	a90080e7          	jalr	-1392(ra) # 800005aa <printf>
      plic_complete(irq);
    80002b22:	8526                	mv	a0,s1
    80002b24:	00004097          	auipc	ra,0x4
    80002b28:	91c080e7          	jalr	-1764(ra) # 80006440 <plic_complete>
    return 1;
    80002b2c:	4505                	li	a0,1
    80002b2e:	64a2                	ld	s1,8(sp)
    80002b30:	b755                	j	80002ad4 <devintr+0x28>
    if (cpuid() == 0)
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	eec080e7          	jalr	-276(ra) # 80001a1e <cpuid>
    80002b3a:	c901                	beqz	a0,80002b4a <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b3c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b42:	14479073          	csrw	sip,a5
    return 2;
    80002b46:	4509                	li	a0,2
    80002b48:	b771                	j	80002ad4 <devintr+0x28>
      clockintr();
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	f0e080e7          	jalr	-242(ra) # 80002a58 <clockintr>
    80002b52:	b7ed                	j	80002b3c <devintr+0x90>
}
    80002b54:	8082                	ret

0000000080002b56 <usertrap>:
{
    80002b56:	1101                	addi	sp,sp,-32
    80002b58:	ec06                	sd	ra,24(sp)
    80002b5a:	e822                	sd	s0,16(sp)
    80002b5c:	e426                	sd	s1,8(sp)
    80002b5e:	e04a                	sd	s2,0(sp)
    80002b60:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b62:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b66:	1007f793          	andi	a5,a5,256
    80002b6a:	e3b9                	bnez	a5,80002bb0 <usertrap+0x5a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b6c:	00003797          	auipc	a5,0x3
    80002b70:	7a478793          	addi	a5,a5,1956 # 80006310 <kernelvec>
    80002b74:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	ed2080e7          	jalr	-302(ra) # 80001a4a <myproc>
    80002b80:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b82:	11053783          	ld	a5,272(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b86:	14102773          	csrr	a4,sepc
    80002b8a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b90:	47a1                	li	a5,8
    80002b92:	02f70763          	beq	a4,a5,80002bc0 <usertrap+0x6a>
  else if ((which_dev = devintr()) != 0)
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	f16080e7          	jalr	-234(ra) # 80002aac <devintr>
    80002b9e:	892a                	mv	s2,a0
    80002ba0:	c935                	beqz	a0,80002c14 <usertrap+0xbe>
  if (killed(p))
    80002ba2:	8526                	mv	a0,s1
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	8ba080e7          	jalr	-1862(ra) # 8000245e <killed>
    80002bac:	c55d                	beqz	a0,80002c5a <usertrap+0x104>
    80002bae:	a04d                	j	80002c50 <usertrap+0xfa>
    panic("usertrap: not from user mode");
    80002bb0:	00005517          	auipc	a0,0x5
    80002bb4:	72050513          	addi	a0,a0,1824 # 800082d0 <etext+0x2d0>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9a8080e7          	jalr	-1624(ra) # 80000560 <panic>
    if (killed(p))
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	89e080e7          	jalr	-1890(ra) # 8000245e <killed>
    80002bc8:	e121                	bnez	a0,80002c08 <usertrap+0xb2>
    p->trapframe->epc += 4;
    80002bca:	1104b703          	ld	a4,272(s1)
    80002bce:	6f1c                	ld	a5,24(a4)
    80002bd0:	0791                	addi	a5,a5,4
    80002bd2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bd8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bdc:	10079073          	csrw	sstatus,a5
    syscall();
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	492080e7          	jalr	1170(ra) # 80003072 <syscall>
  if (killed(p))
    80002be8:	8526                	mv	a0,s1
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	874080e7          	jalr	-1932(ra) # 8000245e <killed>
    80002bf2:	ed31                	bnez	a0,80002c4e <usertrap+0xf8>
  usertrapret();
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	dc2080e7          	jalr	-574(ra) # 800029b6 <usertrapret>
}
    80002bfc:	60e2                	ld	ra,24(sp)
    80002bfe:	6442                	ld	s0,16(sp)
    80002c00:	64a2                	ld	s1,8(sp)
    80002c02:	6902                	ld	s2,0(sp)
    80002c04:	6105                	addi	sp,sp,32
    80002c06:	8082                	ret
      exit(-1);
    80002c08:	557d                	li	a0,-1
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	6b2080e7          	jalr	1714(ra) # 800022bc <exit>
    80002c12:	bf65                	j	80002bca <usertrap+0x74>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c14:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c18:	5890                	lw	a2,48(s1)
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	6d650513          	addi	a0,a0,1750 # 800082f0 <etext+0x2f0>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	988080e7          	jalr	-1656(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c2e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c32:	00005517          	auipc	a0,0x5
    80002c36:	6ee50513          	addi	a0,a0,1774 # 80008320 <etext+0x320>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	970080e7          	jalr	-1680(ra) # 800005aa <printf>
    setkilled(p);
    80002c42:	8526                	mv	a0,s1
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	7ee080e7          	jalr	2030(ra) # 80002432 <setkilled>
    80002c4c:	bf71                	j	80002be8 <usertrap+0x92>
  if (killed(p))
    80002c4e:	4901                	li	s2,0
    exit(-1);
    80002c50:	557d                	li	a0,-1
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	66a080e7          	jalr	1642(ra) # 800022bc <exit>
  if (which_dev == 2)
    80002c5a:	4789                	li	a5,2
    80002c5c:	f8f91ce3          	bne	s2,a5,80002bf4 <usertrap+0x9e>
    p->till_tick++;
    80002c60:	0c44a783          	lw	a5,196(s1)
    80002c64:	2785                	addiw	a5,a5,1
    80002c66:	0007871b          	sext.w	a4,a5
    80002c6a:	0cf4a223          	sw	a5,196(s1)
    if (p->bool_sigalarm == 0 && p->interval > 0 && p->till_tick >= p->interval)
    80002c6e:	0c84a783          	lw	a5,200(s1)
    80002c72:	18079d63          	bnez	a5,80002e0c <usertrap+0x2b6>
    80002c76:	0c04a783          	lw	a5,192(s1)
    80002c7a:	18f05963          	blez	a5,80002e0c <usertrap+0x2b6>
    80002c7e:	18f74763          	blt	a4,a5,80002e0c <usertrap+0x2b6>
      p->bool_sigalarm = 1;
    80002c82:	4785                	li	a5,1
    80002c84:	0cf4a423          	sw	a5,200(s1)
      p->till_tick = 0;
    80002c88:	0c04a223          	sw	zero,196(s1)
      p->new_trapframe->kernel_sp = p->trapframe->kernel_sp;
    80002c8c:	6cfc                	ld	a5,216(s1)
    80002c8e:	1104b703          	ld	a4,272(s1)
    80002c92:	6718                	ld	a4,8(a4)
    80002c94:	e798                	sd	a4,8(a5)
      p->new_trapframe->kernel_trap = p->trapframe->kernel_trap;
    80002c96:	6cfc                	ld	a5,216(s1)
    80002c98:	1104b703          	ld	a4,272(s1)
    80002c9c:	6b18                	ld	a4,16(a4)
    80002c9e:	eb98                	sd	a4,16(a5)
      p->new_trapframe->kernel_satp = p->trapframe->kernel_satp;
    80002ca0:	6cfc                	ld	a5,216(s1)
    80002ca2:	1104b703          	ld	a4,272(s1)
    80002ca6:	6318                	ld	a4,0(a4)
    80002ca8:	e398                	sd	a4,0(a5)
      p->new_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    80002caa:	6cfc                	ld	a5,216(s1)
    80002cac:	1104b703          	ld	a4,272(s1)
    80002cb0:	7318                	ld	a4,32(a4)
    80002cb2:	f398                	sd	a4,32(a5)
      p->new_trapframe->epc = p->trapframe->epc;
    80002cb4:	6cfc                	ld	a5,216(s1)
    80002cb6:	1104b703          	ld	a4,272(s1)
    80002cba:	6f18                	ld	a4,24(a4)
    80002cbc:	ef98                	sd	a4,24(a5)
      p->new_trapframe->ra = p->trapframe->ra;
    80002cbe:	6cfc                	ld	a5,216(s1)
    80002cc0:	1104b703          	ld	a4,272(s1)
    80002cc4:	7718                	ld	a4,40(a4)
    80002cc6:	f798                	sd	a4,40(a5)
      p->new_trapframe->sp = p->trapframe->sp;
    80002cc8:	6cfc                	ld	a5,216(s1)
    80002cca:	1104b703          	ld	a4,272(s1)
    80002cce:	7b18                	ld	a4,48(a4)
    80002cd0:	fb98                	sd	a4,48(a5)
      p->new_trapframe->gp = p->trapframe->gp;
    80002cd2:	6cfc                	ld	a5,216(s1)
    80002cd4:	1104b703          	ld	a4,272(s1)
    80002cd8:	7f18                	ld	a4,56(a4)
    80002cda:	ff98                	sd	a4,56(a5)
      p->new_trapframe->tp = p->trapframe->tp;
    80002cdc:	6cfc                	ld	a5,216(s1)
    80002cde:	1104b703          	ld	a4,272(s1)
    80002ce2:	6338                	ld	a4,64(a4)
    80002ce4:	e3b8                	sd	a4,64(a5)
      p->new_trapframe->t0 = p->trapframe->t0;
    80002ce6:	6cfc                	ld	a5,216(s1)
    80002ce8:	1104b703          	ld	a4,272(s1)
    80002cec:	6738                	ld	a4,72(a4)
    80002cee:	e7b8                	sd	a4,72(a5)
      p->new_trapframe->t1 = p->trapframe->t1;
    80002cf0:	6cfc                	ld	a5,216(s1)
    80002cf2:	1104b703          	ld	a4,272(s1)
    80002cf6:	6b38                	ld	a4,80(a4)
    80002cf8:	ebb8                	sd	a4,80(a5)
      p->new_trapframe->t2 = p->trapframe->t2;
    80002cfa:	6cfc                	ld	a5,216(s1)
    80002cfc:	1104b703          	ld	a4,272(s1)
    80002d00:	6f38                	ld	a4,88(a4)
    80002d02:	efb8                	sd	a4,88(a5)
      p->new_trapframe->s0 = p->trapframe->s0;
    80002d04:	6cfc                	ld	a5,216(s1)
    80002d06:	1104b703          	ld	a4,272(s1)
    80002d0a:	7338                	ld	a4,96(a4)
    80002d0c:	f3b8                	sd	a4,96(a5)
      p->new_trapframe->s1 = p->trapframe->s1;
    80002d0e:	6cfc                	ld	a5,216(s1)
    80002d10:	1104b703          	ld	a4,272(s1)
    80002d14:	7738                	ld	a4,104(a4)
    80002d16:	f7b8                	sd	a4,104(a5)
      p->new_trapframe->a0 = p->trapframe->a0;
    80002d18:	6cfc                	ld	a5,216(s1)
    80002d1a:	1104b703          	ld	a4,272(s1)
    80002d1e:	7b38                	ld	a4,112(a4)
    80002d20:	fbb8                	sd	a4,112(a5)
      p->new_trapframe->a1 = p->trapframe->a1;
    80002d22:	6cfc                	ld	a5,216(s1)
    80002d24:	1104b703          	ld	a4,272(s1)
    80002d28:	7f38                	ld	a4,120(a4)
    80002d2a:	ffb8                	sd	a4,120(a5)
      p->new_trapframe->a2 = p->trapframe->a2;
    80002d2c:	6cfc                	ld	a5,216(s1)
    80002d2e:	1104b703          	ld	a4,272(s1)
    80002d32:	6358                	ld	a4,128(a4)
    80002d34:	e3d8                	sd	a4,128(a5)
      p->new_trapframe->a3 = p->trapframe->a3;
    80002d36:	6cfc                	ld	a5,216(s1)
    80002d38:	1104b703          	ld	a4,272(s1)
    80002d3c:	6758                	ld	a4,136(a4)
    80002d3e:	e7d8                	sd	a4,136(a5)
      p->new_trapframe->a4 = p->trapframe->a4;
    80002d40:	6cfc                	ld	a5,216(s1)
    80002d42:	1104b703          	ld	a4,272(s1)
    80002d46:	6b58                	ld	a4,144(a4)
    80002d48:	ebd8                	sd	a4,144(a5)
      p->new_trapframe->a5 = p->trapframe->a5;
    80002d4a:	6cfc                	ld	a5,216(s1)
    80002d4c:	1104b703          	ld	a4,272(s1)
    80002d50:	6f58                	ld	a4,152(a4)
    80002d52:	efd8                	sd	a4,152(a5)
      p->new_trapframe->a6 = p->trapframe->a6;
    80002d54:	6cfc                	ld	a5,216(s1)
    80002d56:	1104b703          	ld	a4,272(s1)
    80002d5a:	7358                	ld	a4,160(a4)
    80002d5c:	f3d8                	sd	a4,160(a5)
      p->new_trapframe->a7 = p->trapframe->a7;
    80002d5e:	6cfc                	ld	a5,216(s1)
    80002d60:	1104b703          	ld	a4,272(s1)
    80002d64:	7758                	ld	a4,168(a4)
    80002d66:	f7d8                	sd	a4,168(a5)
      p->new_trapframe->s2 = p->trapframe->s2;
    80002d68:	6cfc                	ld	a5,216(s1)
    80002d6a:	1104b703          	ld	a4,272(s1)
    80002d6e:	7b58                	ld	a4,176(a4)
    80002d70:	fbd8                	sd	a4,176(a5)
      p->new_trapframe->s3 = p->trapframe->s3;
    80002d72:	6cfc                	ld	a5,216(s1)
    80002d74:	1104b703          	ld	a4,272(s1)
    80002d78:	7f58                	ld	a4,184(a4)
    80002d7a:	ffd8                	sd	a4,184(a5)
      p->new_trapframe->s4 = p->trapframe->s4;
    80002d7c:	6cfc                	ld	a5,216(s1)
    80002d7e:	1104b703          	ld	a4,272(s1)
    80002d82:	6378                	ld	a4,192(a4)
    80002d84:	e3f8                	sd	a4,192(a5)
      p->new_trapframe->s5 = p->trapframe->s5;
    80002d86:	6cfc                	ld	a5,216(s1)
    80002d88:	1104b703          	ld	a4,272(s1)
    80002d8c:	6778                	ld	a4,200(a4)
    80002d8e:	e7f8                	sd	a4,200(a5)
      p->new_trapframe->s6 = p->trapframe->s6;
    80002d90:	6cfc                	ld	a5,216(s1)
    80002d92:	1104b703          	ld	a4,272(s1)
    80002d96:	6b78                	ld	a4,208(a4)
    80002d98:	ebf8                	sd	a4,208(a5)
      p->new_trapframe->s7 = p->trapframe->s7;
    80002d9a:	6cfc                	ld	a5,216(s1)
    80002d9c:	1104b703          	ld	a4,272(s1)
    80002da0:	6f78                	ld	a4,216(a4)
    80002da2:	eff8                	sd	a4,216(a5)
      p->new_trapframe->s8 = p->trapframe->s8;
    80002da4:	6cfc                	ld	a5,216(s1)
    80002da6:	1104b703          	ld	a4,272(s1)
    80002daa:	7378                	ld	a4,224(a4)
    80002dac:	f3f8                	sd	a4,224(a5)
      p->new_trapframe->s9 = p->trapframe->s9;
    80002dae:	6cfc                	ld	a5,216(s1)
    80002db0:	1104b703          	ld	a4,272(s1)
    80002db4:	7778                	ld	a4,232(a4)
    80002db6:	f7f8                	sd	a4,232(a5)
      p->new_trapframe->s10 = p->trapframe->s10;
    80002db8:	6cfc                	ld	a5,216(s1)
    80002dba:	1104b703          	ld	a4,272(s1)
    80002dbe:	7b78                	ld	a4,240(a4)
    80002dc0:	fbf8                	sd	a4,240(a5)
      p->new_trapframe->s11 = p->trapframe->s11;
    80002dc2:	6cfc                	ld	a5,216(s1)
    80002dc4:	1104b703          	ld	a4,272(s1)
    80002dc8:	7f78                	ld	a4,248(a4)
    80002dca:	fff8                	sd	a4,248(a5)
      p->new_trapframe->t3 = p->trapframe->t3;
    80002dcc:	6cfc                	ld	a5,216(s1)
    80002dce:	1104b703          	ld	a4,272(s1)
    80002dd2:	10073703          	ld	a4,256(a4)
    80002dd6:	10e7b023          	sd	a4,256(a5)
      p->new_trapframe->t4 = p->trapframe->t4;
    80002dda:	6cfc                	ld	a5,216(s1)
    80002ddc:	1104b703          	ld	a4,272(s1)
    80002de0:	10873703          	ld	a4,264(a4)
    80002de4:	10e7b423          	sd	a4,264(a5)
      p->new_trapframe->t5 = p->trapframe->t5;
    80002de8:	6cfc                	ld	a5,216(s1)
    80002dea:	1104b703          	ld	a4,272(s1)
    80002dee:	11073703          	ld	a4,272(a4)
    80002df2:	10e7b823          	sd	a4,272(a5)
      p->new_trapframe->t6 = p->trapframe->t6;
    80002df6:	6cfc                	ld	a5,216(s1)
    80002df8:	1104b703          	ld	a4,272(s1)
    80002dfc:	11873703          	ld	a4,280(a4)
    80002e00:	10e7bc23          	sd	a4,280(a5)
      p->trapframe->epc = p->handler;
    80002e04:	1104b783          	ld	a5,272(s1)
    80002e08:	68f8                	ld	a4,208(s1)
    80002e0a:	ef98                	sd	a4,24(a5)
    yield();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	340080e7          	jalr	832(ra) # 8000214c <yield>
    80002e14:	b3c5                	j	80002bf4 <usertrap+0x9e>

0000000080002e16 <kerneltrap>:
{
    80002e16:	7179                	addi	sp,sp,-48
    80002e18:	f406                	sd	ra,40(sp)
    80002e1a:	f022                	sd	s0,32(sp)
    80002e1c:	ec26                	sd	s1,24(sp)
    80002e1e:	e84a                	sd	s2,16(sp)
    80002e20:	e44e                	sd	s3,8(sp)
    80002e22:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e24:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e28:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2c:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002e30:	1004f793          	andi	a5,s1,256
    80002e34:	cb85                	beqz	a5,80002e64 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e3a:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002e3c:	ef85                	bnez	a5,80002e74 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	c6e080e7          	jalr	-914(ra) # 80002aac <devintr>
    80002e46:	cd1d                	beqz	a0,80002e84 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e48:	4789                	li	a5,2
    80002e4a:	06f50a63          	beq	a0,a5,80002ebe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e4e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e52:	10049073          	csrw	sstatus,s1
}
    80002e56:	70a2                	ld	ra,40(sp)
    80002e58:	7402                	ld	s0,32(sp)
    80002e5a:	64e2                	ld	s1,24(sp)
    80002e5c:	6942                	ld	s2,16(sp)
    80002e5e:	69a2                	ld	s3,8(sp)
    80002e60:	6145                	addi	sp,sp,48
    80002e62:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e64:	00005517          	auipc	a0,0x5
    80002e68:	4dc50513          	addi	a0,a0,1244 # 80008340 <etext+0x340>
    80002e6c:	ffffd097          	auipc	ra,0xffffd
    80002e70:	6f4080e7          	jalr	1780(ra) # 80000560 <panic>
    panic("kerneltrap: interrupts enabled");
    80002e74:	00005517          	auipc	a0,0x5
    80002e78:	4f450513          	addi	a0,a0,1268 # 80008368 <etext+0x368>
    80002e7c:	ffffd097          	auipc	ra,0xffffd
    80002e80:	6e4080e7          	jalr	1764(ra) # 80000560 <panic>
    printf("scause %p\n", scause);
    80002e84:	85ce                	mv	a1,s3
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	50250513          	addi	a0,a0,1282 # 80008388 <etext+0x388>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	71c080e7          	jalr	1820(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e96:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e9a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e9e:	00005517          	auipc	a0,0x5
    80002ea2:	4fa50513          	addi	a0,a0,1274 # 80008398 <etext+0x398>
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	704080e7          	jalr	1796(ra) # 800005aa <printf>
    panic("kerneltrap");
    80002eae:	00005517          	auipc	a0,0x5
    80002eb2:	50250513          	addi	a0,a0,1282 # 800083b0 <etext+0x3b0>
    80002eb6:	ffffd097          	auipc	ra,0xffffd
    80002eba:	6aa080e7          	jalr	1706(ra) # 80000560 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	b8c080e7          	jalr	-1140(ra) # 80001a4a <myproc>
    80002ec6:	d541                	beqz	a0,80002e4e <kerneltrap+0x38>
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	b82080e7          	jalr	-1150(ra) # 80001a4a <myproc>
    80002ed0:	4d18                	lw	a4,24(a0)
    80002ed2:	4791                	li	a5,4
    80002ed4:	f6f71de3          	bne	a4,a5,80002e4e <kerneltrap+0x38>
    yield();
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	274080e7          	jalr	628(ra) # 8000214c <yield>
    80002ee0:	b7bd                	j	80002e4e <kerneltrap+0x38>

0000000080002ee2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	e426                	sd	s1,8(sp)
    80002eea:	1000                	addi	s0,sp,32
    80002eec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	b5c080e7          	jalr	-1188(ra) # 80001a4a <myproc>
  switch (n)
    80002ef6:	4795                	li	a5,5
    80002ef8:	0497e763          	bltu	a5,s1,80002f46 <argraw+0x64>
    80002efc:	048a                	slli	s1,s1,0x2
    80002efe:	00006717          	auipc	a4,0x6
    80002f02:	87270713          	addi	a4,a4,-1934 # 80008770 <states.0+0x30>
    80002f06:	94ba                	add	s1,s1,a4
    80002f08:	409c                	lw	a5,0(s1)
    80002f0a:	97ba                	add	a5,a5,a4
    80002f0c:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002f0e:	11053783          	ld	a5,272(a0)
    80002f12:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f14:	60e2                	ld	ra,24(sp)
    80002f16:	6442                	ld	s0,16(sp)
    80002f18:	64a2                	ld	s1,8(sp)
    80002f1a:	6105                	addi	sp,sp,32
    80002f1c:	8082                	ret
    return p->trapframe->a1;
    80002f1e:	11053783          	ld	a5,272(a0)
    80002f22:	7fa8                	ld	a0,120(a5)
    80002f24:	bfc5                	j	80002f14 <argraw+0x32>
    return p->trapframe->a2;
    80002f26:	11053783          	ld	a5,272(a0)
    80002f2a:	63c8                	ld	a0,128(a5)
    80002f2c:	b7e5                	j	80002f14 <argraw+0x32>
    return p->trapframe->a3;
    80002f2e:	11053783          	ld	a5,272(a0)
    80002f32:	67c8                	ld	a0,136(a5)
    80002f34:	b7c5                	j	80002f14 <argraw+0x32>
    return p->trapframe->a4;
    80002f36:	11053783          	ld	a5,272(a0)
    80002f3a:	6bc8                	ld	a0,144(a5)
    80002f3c:	bfe1                	j	80002f14 <argraw+0x32>
    return p->trapframe->a5;
    80002f3e:	11053783          	ld	a5,272(a0)
    80002f42:	6fc8                	ld	a0,152(a5)
    80002f44:	bfc1                	j	80002f14 <argraw+0x32>
  panic("argraw");
    80002f46:	00005517          	auipc	a0,0x5
    80002f4a:	47a50513          	addi	a0,a0,1146 # 800083c0 <etext+0x3c0>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	612080e7          	jalr	1554(ra) # 80000560 <panic>

0000000080002f56 <fetchaddr>:
{
    80002f56:	1101                	addi	sp,sp,-32
    80002f58:	ec06                	sd	ra,24(sp)
    80002f5a:	e822                	sd	s0,16(sp)
    80002f5c:	e426                	sd	s1,8(sp)
    80002f5e:	e04a                	sd	s2,0(sp)
    80002f60:	1000                	addi	s0,sp,32
    80002f62:	84aa                	mv	s1,a0
    80002f64:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	ae4080e7          	jalr	-1308(ra) # 80001a4a <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f6e:	10053783          	ld	a5,256(a0)
    80002f72:	02f4f963          	bgeu	s1,a5,80002fa4 <fetchaddr+0x4e>
    80002f76:	00848713          	addi	a4,s1,8
    80002f7a:	02e7e763          	bltu	a5,a4,80002fa8 <fetchaddr+0x52>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f7e:	46a1                	li	a3,8
    80002f80:	8626                	mv	a2,s1
    80002f82:	85ca                	mv	a1,s2
    80002f84:	10853503          	ld	a0,264(a0)
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	7e6080e7          	jalr	2022(ra) # 8000176e <copyin>
    80002f90:	00a03533          	snez	a0,a0
    80002f94:	40a00533          	neg	a0,a0
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6902                	ld	s2,0(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret
    return -1;
    80002fa4:	557d                	li	a0,-1
    80002fa6:	bfcd                	j	80002f98 <fetchaddr+0x42>
    80002fa8:	557d                	li	a0,-1
    80002faa:	b7fd                	j	80002f98 <fetchaddr+0x42>

0000000080002fac <fetchstr>:
{
    80002fac:	7179                	addi	sp,sp,-48
    80002fae:	f406                	sd	ra,40(sp)
    80002fb0:	f022                	sd	s0,32(sp)
    80002fb2:	ec26                	sd	s1,24(sp)
    80002fb4:	e84a                	sd	s2,16(sp)
    80002fb6:	e44e                	sd	s3,8(sp)
    80002fb8:	1800                	addi	s0,sp,48
    80002fba:	892a                	mv	s2,a0
    80002fbc:	84ae                	mv	s1,a1
    80002fbe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	a8a080e7          	jalr	-1398(ra) # 80001a4a <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fc8:	86ce                	mv	a3,s3
    80002fca:	864a                	mv	a2,s2
    80002fcc:	85a6                	mv	a1,s1
    80002fce:	10853503          	ld	a0,264(a0)
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	82a080e7          	jalr	-2006(ra) # 800017fc <copyinstr>
    80002fda:	00054e63          	bltz	a0,80002ff6 <fetchstr+0x4a>
  return strlen(buf);
    80002fde:	8526                	mv	a0,s1
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	ec8080e7          	jalr	-312(ra) # 80000ea8 <strlen>
}
    80002fe8:	70a2                	ld	ra,40(sp)
    80002fea:	7402                	ld	s0,32(sp)
    80002fec:	64e2                	ld	s1,24(sp)
    80002fee:	6942                	ld	s2,16(sp)
    80002ff0:	69a2                	ld	s3,8(sp)
    80002ff2:	6145                	addi	sp,sp,48
    80002ff4:	8082                	ret
    return -1;
    80002ff6:	557d                	li	a0,-1
    80002ff8:	bfc5                	j	80002fe8 <fetchstr+0x3c>

0000000080002ffa <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	e426                	sd	s1,8(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	edc080e7          	jalr	-292(ra) # 80002ee2 <argraw>
    8000300e:	c088                	sw	a0,0(s1)
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	e426                	sd	s1,8(sp)
    80003022:	1000                	addi	s0,sp,32
    80003024:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	ebc080e7          	jalr	-324(ra) # 80002ee2 <argraw>
    8000302e:	e088                	sd	a0,0(s1)
}
    80003030:	60e2                	ld	ra,24(sp)
    80003032:	6442                	ld	s0,16(sp)
    80003034:	64a2                	ld	s1,8(sp)
    80003036:	6105                	addi	sp,sp,32
    80003038:	8082                	ret

000000008000303a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000303a:	7179                	addi	sp,sp,-48
    8000303c:	f406                	sd	ra,40(sp)
    8000303e:	f022                	sd	s0,32(sp)
    80003040:	ec26                	sd	s1,24(sp)
    80003042:	e84a                	sd	s2,16(sp)
    80003044:	1800                	addi	s0,sp,48
    80003046:	84ae                	mv	s1,a1
    80003048:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000304a:	fd840593          	addi	a1,s0,-40
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	fcc080e7          	jalr	-52(ra) # 8000301a <argaddr>
  return fetchstr(addr, buf, max);
    80003056:	864a                	mv	a2,s2
    80003058:	85a6                	mv	a1,s1
    8000305a:	fd843503          	ld	a0,-40(s0)
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	f4e080e7          	jalr	-178(ra) # 80002fac <fetchstr>
}
    80003066:	70a2                	ld	ra,40(sp)
    80003068:	7402                	ld	s0,32(sp)
    8000306a:	64e2                	ld	s1,24(sp)
    8000306c:	6942                	ld	s2,16(sp)
    8000306e:	6145                	addi	sp,sp,48
    80003070:	8082                	ret

0000000080003072 <syscall>:
    [SYS_settickets] sys_settickets,
   
};

void syscall(void)
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	e04a                	sd	s2,0(sp)
    8000307c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	9cc080e7          	jalr	-1588(ra) # 80001a4a <myproc>
    80003086:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003088:	11053903          	ld	s2,272(a0)
    8000308c:	0a893783          	ld	a5,168(s2)
    80003090:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003094:	37fd                	addiw	a5,a5,-1
    80003096:	4765                	li	a4,25
    80003098:	02f76563          	bltu	a4,a5,800030c2 <syscall+0x50>
    8000309c:	00369713          	slli	a4,a3,0x3
    800030a0:	00005797          	auipc	a5,0x5
    800030a4:	6e878793          	addi	a5,a5,1768 # 80008788 <syscalls>
    800030a8:	97ba                	add	a5,a5,a4
    800030aa:	6398                	ld	a4,0(a5)
    800030ac:	cb19                	beqz	a4,800030c2 <syscall+0x50>
  {
    p->syscall_count[num]++;
    800030ae:	068a                	slli	a3,a3,0x2
    800030b0:	00d504b3          	add	s1,a0,a3
    800030b4:	40bc                	lw	a5,64(s1)
    800030b6:	2785                	addiw	a5,a5,1
    800030b8:	c0bc                	sw	a5,64(s1)

    p->trapframe->a0 = syscalls[num]();
    800030ba:	9702                	jalr	a4
    800030bc:	06a93823          	sd	a0,112(s2)
    800030c0:	a005                	j	800030e0 <syscall+0x6e>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    800030c2:	21048613          	addi	a2,s1,528
    800030c6:	588c                	lw	a1,48(s1)
    800030c8:	00005517          	auipc	a0,0x5
    800030cc:	30050513          	addi	a0,a0,768 # 800083c8 <etext+0x3c8>
    800030d0:	ffffd097          	auipc	ra,0xffffd
    800030d4:	4da080e7          	jalr	1242(ra) # 800005aa <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030d8:	1104b783          	ld	a5,272(s1)
    800030dc:	577d                	li	a4,-1
    800030de:	fbb8                	sd	a4,112(a5)
  }
}
    800030e0:	60e2                	ld	ra,24(sp)
    800030e2:	6442                	ld	s0,16(sp)
    800030e4:	64a2                	ld	s1,8(sp)
    800030e6:	6902                	ld	s2,0(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800030f4:	fec40593          	addi	a1,s0,-20
    800030f8:	4501                	li	a0,0
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	f00080e7          	jalr	-256(ra) # 80002ffa <argint>
  exit(n);
    80003102:	fec42503          	lw	a0,-20(s0)
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	1b6080e7          	jalr	438(ra) # 800022bc <exit>
  return 0; // not reached
}
    8000310e:	4501                	li	a0,0
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret

0000000080003118 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003118:	1141                	addi	sp,sp,-16
    8000311a:	e406                	sd	ra,8(sp)
    8000311c:	e022                	sd	s0,0(sp)
    8000311e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	92a080e7          	jalr	-1750(ra) # 80001a4a <myproc>
}
    80003128:	5908                	lw	a0,48(a0)
    8000312a:	60a2                	ld	ra,8(sp)
    8000312c:	6402                	ld	s0,0(sp)
    8000312e:	0141                	addi	sp,sp,16
    80003130:	8082                	ret

0000000080003132 <sys_fork>:

uint64
sys_fork(void)
{
    80003132:	1141                	addi	sp,sp,-16
    80003134:	e406                	sd	ra,8(sp)
    80003136:	e022                	sd	s0,0(sp)
    80003138:	0800                	addi	s0,sp,16
  return fork();
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	d50080e7          	jalr	-688(ra) # 80001e8a <fork>
}
    80003142:	60a2                	ld	ra,8(sp)
    80003144:	6402                	ld	s0,0(sp)
    80003146:	0141                	addi	sp,sp,16
    80003148:	8082                	ret

000000008000314a <sys_wait>:

uint64
sys_wait(void)
{
    8000314a:	1101                	addi	sp,sp,-32
    8000314c:	ec06                	sd	ra,24(sp)
    8000314e:	e822                	sd	s0,16(sp)
    80003150:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003152:	fe840593          	addi	a1,s0,-24
    80003156:	4501                	li	a0,0
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	ec2080e7          	jalr	-318(ra) # 8000301a <argaddr>
  return wait(p);
    80003160:	fe843503          	ld	a0,-24(s0)
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	32c080e7          	jalr	812(ra) # 80002490 <wait>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	6105                	addi	sp,sp,32
    80003172:	8082                	ret

0000000080003174 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003174:	7179                	addi	sp,sp,-48
    80003176:	f406                	sd	ra,40(sp)
    80003178:	f022                	sd	s0,32(sp)
    8000317a:	ec26                	sd	s1,24(sp)
    8000317c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000317e:	fdc40593          	addi	a1,s0,-36
    80003182:	4501                	li	a0,0
    80003184:	00000097          	auipc	ra,0x0
    80003188:	e76080e7          	jalr	-394(ra) # 80002ffa <argint>
  addr = myproc()->sz;
    8000318c:	fffff097          	auipc	ra,0xfffff
    80003190:	8be080e7          	jalr	-1858(ra) # 80001a4a <myproc>
    80003194:	10053483          	ld	s1,256(a0)
  if (growproc(n) < 0)
    80003198:	fdc42503          	lw	a0,-36(s0)
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	c8a080e7          	jalr	-886(ra) # 80001e26 <growproc>
    800031a4:	00054863          	bltz	a0,800031b4 <sys_sbrk+0x40>
    return -1;
  return addr;
}
    800031a8:	8526                	mv	a0,s1
    800031aa:	70a2                	ld	ra,40(sp)
    800031ac:	7402                	ld	s0,32(sp)
    800031ae:	64e2                	ld	s1,24(sp)
    800031b0:	6145                	addi	sp,sp,48
    800031b2:	8082                	ret
    return -1;
    800031b4:	54fd                	li	s1,-1
    800031b6:	bfcd                	j	800031a8 <sys_sbrk+0x34>

00000000800031b8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031b8:	7139                	addi	sp,sp,-64
    800031ba:	fc06                	sd	ra,56(sp)
    800031bc:	f822                	sd	s0,48(sp)
    800031be:	f04a                	sd	s2,32(sp)
    800031c0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800031c2:	fcc40593          	addi	a1,s0,-52
    800031c6:	4501                	li	a0,0
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	e32080e7          	jalr	-462(ra) # 80002ffa <argint>
  acquire(&tickslock);
    800031d0:	00017517          	auipc	a0,0x17
    800031d4:	9b050513          	addi	a0,a0,-1616 # 80019b80 <tickslock>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	a60080e7          	jalr	-1440(ra) # 80000c38 <acquire>
  ticks0 = ticks;
    800031e0:	00005917          	auipc	s2,0x5
    800031e4:	70092903          	lw	s2,1792(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    800031e8:	fcc42783          	lw	a5,-52(s0)
    800031ec:	c3b9                	beqz	a5,80003232 <sys_sleep+0x7a>
    800031ee:	f426                	sd	s1,40(sp)
    800031f0:	ec4e                	sd	s3,24(sp)
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031f2:	00017997          	auipc	s3,0x17
    800031f6:	98e98993          	addi	s3,s3,-1650 # 80019b80 <tickslock>
    800031fa:	00005497          	auipc	s1,0x5
    800031fe:	6e648493          	addi	s1,s1,1766 # 800088e0 <ticks>
    if (killed(myproc()))
    80003202:	fffff097          	auipc	ra,0xfffff
    80003206:	848080e7          	jalr	-1976(ra) # 80001a4a <myproc>
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	254080e7          	jalr	596(ra) # 8000245e <killed>
    80003212:	ed15                	bnez	a0,8000324e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003214:	85ce                	mv	a1,s3
    80003216:	8526                	mv	a0,s1
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	f70080e7          	jalr	-144(ra) # 80002188 <sleep>
  while (ticks - ticks0 < n)
    80003220:	409c                	lw	a5,0(s1)
    80003222:	412787bb          	subw	a5,a5,s2
    80003226:	fcc42703          	lw	a4,-52(s0)
    8000322a:	fce7ece3          	bltu	a5,a4,80003202 <sys_sleep+0x4a>
    8000322e:	74a2                	ld	s1,40(sp)
    80003230:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80003232:	00017517          	auipc	a0,0x17
    80003236:	94e50513          	addi	a0,a0,-1714 # 80019b80 <tickslock>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	ab2080e7          	jalr	-1358(ra) # 80000cec <release>
  return 0;
    80003242:	4501                	li	a0,0
}
    80003244:	70e2                	ld	ra,56(sp)
    80003246:	7442                	ld	s0,48(sp)
    80003248:	7902                	ld	s2,32(sp)
    8000324a:	6121                	addi	sp,sp,64
    8000324c:	8082                	ret
      release(&tickslock);
    8000324e:	00017517          	auipc	a0,0x17
    80003252:	93250513          	addi	a0,a0,-1742 # 80019b80 <tickslock>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	a96080e7          	jalr	-1386(ra) # 80000cec <release>
      return -1;
    8000325e:	557d                	li	a0,-1
    80003260:	74a2                	ld	s1,40(sp)
    80003262:	69e2                	ld	s3,24(sp)
    80003264:	b7c5                	j	80003244 <sys_sleep+0x8c>

0000000080003266 <sys_kill>:

uint64
sys_kill(void)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000326e:	fec40593          	addi	a1,s0,-20
    80003272:	4501                	li	a0,0
    80003274:	00000097          	auipc	ra,0x0
    80003278:	d86080e7          	jalr	-634(ra) # 80002ffa <argint>
  return kill(pid);
    8000327c:	fec42503          	lw	a0,-20(s0)
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	140080e7          	jalr	320(ra) # 800023c0 <kill>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret

0000000080003290 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	e426                	sd	s1,8(sp)
    80003298:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000329a:	00017517          	auipc	a0,0x17
    8000329e:	8e650513          	addi	a0,a0,-1818 # 80019b80 <tickslock>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	996080e7          	jalr	-1642(ra) # 80000c38 <acquire>
  xticks = ticks;
    800032aa:	00005497          	auipc	s1,0x5
    800032ae:	6364a483          	lw	s1,1590(s1) # 800088e0 <ticks>
  release(&tickslock);
    800032b2:	00017517          	auipc	a0,0x17
    800032b6:	8ce50513          	addi	a0,a0,-1842 # 80019b80 <tickslock>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	a32080e7          	jalr	-1486(ra) # 80000cec <release>
  return xticks;
}
    800032c2:	02049513          	slli	a0,s1,0x20
    800032c6:	9101                	srli	a0,a0,0x20
    800032c8:	60e2                	ld	ra,24(sp)
    800032ca:	6442                	ld	s0,16(sp)
    800032cc:	64a2                	ld	s1,8(sp)
    800032ce:	6105                	addi	sp,sp,32
    800032d0:	8082                	ret

00000000800032d2 <sys_waitx>:

uint64
sys_waitx(void)
{
    800032d2:	7139                	addi	sp,sp,-64
    800032d4:	fc06                	sd	ra,56(sp)
    800032d6:	f822                	sd	s0,48(sp)
    800032d8:	f426                	sd	s1,40(sp)
    800032da:	f04a                	sd	s2,32(sp)
    800032dc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800032de:	fd840593          	addi	a1,s0,-40
    800032e2:	4501                	li	a0,0
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	d36080e7          	jalr	-714(ra) # 8000301a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800032ec:	fd040593          	addi	a1,s0,-48
    800032f0:	4505                	li	a0,1
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	d28080e7          	jalr	-728(ra) # 8000301a <argaddr>
  argaddr(2, &addr2);
    800032fa:	fc840593          	addi	a1,s0,-56
    800032fe:	4509                	li	a0,2
    80003300:	00000097          	auipc	ra,0x0
    80003304:	d1a080e7          	jalr	-742(ra) # 8000301a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003308:	fc040613          	addi	a2,s0,-64
    8000330c:	fc440593          	addi	a1,s0,-60
    80003310:	fd843503          	ld	a0,-40(s0)
    80003314:	fffff097          	auipc	ra,0xfffff
    80003318:	40a080e7          	jalr	1034(ra) # 8000271e <waitx>
    8000331c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	72c080e7          	jalr	1836(ra) # 80001a4a <myproc>
    80003326:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003328:	4691                	li	a3,4
    8000332a:	fc440613          	addi	a2,s0,-60
    8000332e:	fd043583          	ld	a1,-48(s0)
    80003332:	10853503          	ld	a0,264(a0)
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	3ac080e7          	jalr	940(ra) # 800016e2 <copyout>
    return -1;
    8000333e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003340:	02054063          	bltz	a0,80003360 <sys_waitx+0x8e>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003344:	4691                	li	a3,4
    80003346:	fc040613          	addi	a2,s0,-64
    8000334a:	fc843583          	ld	a1,-56(s0)
    8000334e:	1084b503          	ld	a0,264(s1)
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	390080e7          	jalr	912(ra) # 800016e2 <copyout>
    8000335a:	00054a63          	bltz	a0,8000336e <sys_waitx+0x9c>
    return -1;
  return ret;
    8000335e:	87ca                	mv	a5,s2
}
    80003360:	853e                	mv	a0,a5
    80003362:	70e2                	ld	ra,56(sp)
    80003364:	7442                	ld	s0,48(sp)
    80003366:	74a2                	ld	s1,40(sp)
    80003368:	7902                	ld	s2,32(sp)
    8000336a:	6121                	addi	sp,sp,64
    8000336c:	8082                	ret
    return -1;
    8000336e:	57fd                	li	a5,-1
    80003370:	bfc5                	j	80003360 <sys_waitx+0x8e>

0000000080003372 <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	1000                	addi	s0,sp,32

  int mask;
  argint(0, &mask);
    8000337a:	fec40593          	addi	a1,s0,-20
    8000337e:	4501                	li	a0,0
    80003380:	00000097          	auipc	ra,0x0
    80003384:	c7a080e7          	jalr	-902(ra) # 80002ffa <argint>

  struct proc *p = myproc();
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	6c2080e7          	jalr	1730(ra) # 80001a4a <myproc>
  int syscall_num = 0;
  uint64 count = 0;

  while ((mask & 1) == 0 && syscall_num < 32)
    80003390:	fec42703          	lw	a4,-20(s0)
    80003394:	00177793          	andi	a5,a4,1
    80003398:	e785                	bnez	a5,800033c0 <sys_getSysCount+0x4e>
    8000339a:	02000613          	li	a2,32
  {
    mask >>= 1;
    8000339e:	4017571b          	sraiw	a4,a4,0x1
    syscall_num++;
    800033a2:	2785                	addiw	a5,a5,1
  while ((mask & 1) == 0 && syscall_num < 32)
    800033a4:	00177693          	andi	a3,a4,1
    800033a8:	e299                	bnez	a3,800033ae <sys_getSysCount+0x3c>
    800033aa:	fec79ae3          	bne	a5,a2,8000339e <sys_getSysCount+0x2c>
  }

  count = p->syscall_count[syscall_num];
    800033ae:	07c1                	addi	a5,a5,16
    800033b0:	078a                	slli	a5,a5,0x2
    800033b2:	953e                	add	a0,a0,a5

  return count;
}
    800033b4:	00056503          	lwu	a0,0(a0)
    800033b8:	60e2                	ld	ra,24(sp)
    800033ba:	6442                	ld	s0,16(sp)
    800033bc:	6105                	addi	sp,sp,32
    800033be:	8082                	ret
  int syscall_num = 0;
    800033c0:	4781                	li	a5,0
    800033c2:	b7f5                	j	800033ae <sys_getSysCount+0x3c>

00000000800033c4 <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    800033c4:	1141                	addi	sp,sp,-16
    800033c6:	e406                	sd	ra,8(sp)
    800033c8:	e022                	sd	s0,0(sp)
    800033ca:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800033cc:	ffffe097          	auipc	ra,0xffffe
    800033d0:	67e080e7          	jalr	1662(ra) # 80001a4a <myproc>
  struct trapframe *old_tf = p->trapframe;
    800033d4:	11053683          	ld	a3,272(a0)
  struct trapframe *new_tf = p->new_trapframe;
    800033d8:	6d7c                	ld	a5,216(a0)
  old_tf->kernel_sp = new_tf->kernel_sp;
    800033da:	6798                	ld	a4,8(a5)
    800033dc:	e698                	sd	a4,8(a3)
  old_tf->kernel_trap = new_tf->kernel_trap;
    800033de:	6b98                	ld	a4,16(a5)
    800033e0:	ea98                	sd	a4,16(a3)
  old_tf->kernel_satp = new_tf->kernel_satp;
    800033e2:	6398                	ld	a4,0(a5)
    800033e4:	e298                	sd	a4,0(a3)
  old_tf->kernel_hartid = new_tf->kernel_hartid;
    800033e6:	7398                	ld	a4,32(a5)
    800033e8:	f298                	sd	a4,32(a3)
  *old_tf = *new_tf;
    800033ea:	873e                	mv	a4,a5
    800033ec:	8636                	mv	a2,a3
    800033ee:	12078793          	addi	a5,a5,288
    800033f2:	00073303          	ld	t1,0(a4)
    800033f6:	00873883          	ld	a7,8(a4)
    800033fa:	01073803          	ld	a6,16(a4)
    800033fe:	6f0c                	ld	a1,24(a4)
    80003400:	00663023          	sd	t1,0(a2)
    80003404:	01163423          	sd	a7,8(a2)
    80003408:	01063823          	sd	a6,16(a2)
    8000340c:	ee0c                	sd	a1,24(a2)
    8000340e:	02070713          	addi	a4,a4,32
    80003412:	02060613          	addi	a2,a2,32
    80003416:	fcf71ee3          	bne	a4,a5,800033f2 <sys_sigreturn+0x2e>
  p->bool_sigalarm = 0;
    8000341a:	0c052423          	sw	zero,200(a0)
  return old_tf->a0;
}
    8000341e:	7aa8                	ld	a0,112(a3)
    80003420:	60a2                	ld	ra,8(sp)
    80003422:	6402                	ld	s0,0(sp)
    80003424:	0141                	addi	sp,sp,16
    80003426:	8082                	ret

0000000080003428 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80003428:	7179                	addi	sp,sp,-48
    8000342a:	f406                	sd	ra,40(sp)
    8000342c:	f022                	sd	s0,32(sp)
    8000342e:	ec26                	sd	s1,24(sp)
    80003430:	1800                	addi	s0,sp,48
  uint64 handle;
  int ticks;
  struct proc *pa = myproc();
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	618080e7          	jalr	1560(ra) # 80001a4a <myproc>
    8000343a:	84aa                	mv	s1,a0
  argaddr(1, &handle);
    8000343c:	fd840593          	addi	a1,s0,-40
    80003440:	4505                	li	a0,1
    80003442:	00000097          	auipc	ra,0x0
    80003446:	bd8080e7          	jalr	-1064(ra) # 8000301a <argaddr>
  argint(0, &ticks);
    8000344a:	fd440593          	addi	a1,s0,-44
    8000344e:	4501                	li	a0,0
    80003450:	00000097          	auipc	ra,0x0
    80003454:	baa080e7          	jalr	-1110(ra) # 80002ffa <argint>
  if (handle < 0 || ticks < 0)
    80003458:	fd442783          	lw	a5,-44(s0)
    8000345c:	0207c163          	bltz	a5,8000347e <sys_sigalarm+0x56>
  {
    return -1;
  }
  pa->interval = ticks;
    80003460:	0cf4a023          	sw	a5,192(s1)
  pa->handler = handle;
    80003464:	fd843783          	ld	a5,-40(s0)
    80003468:	e8fc                	sd	a5,208(s1)
  pa->bool_sigalarm = 0;
    8000346a:	0c04a423          	sw	zero,200(s1)
  pa->till_tick = 0;
    8000346e:	0c04a223          	sw	zero,196(s1)

  return 0;
    80003472:	4501                	li	a0,0
}
    80003474:	70a2                	ld	ra,40(sp)
    80003476:	7402                	ld	s0,32(sp)
    80003478:	64e2                	ld	s1,24(sp)
    8000347a:	6145                	addi	sp,sp,48
    8000347c:	8082                	ret
    return -1;
    8000347e:	557d                	li	a0,-1
    80003480:	bfd5                	j	80003474 <sys_sigalarm+0x4c>

0000000080003482 <sys_settickets>:

uint64
sys_settickets(void)
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	1000                	addi	s0,sp,32
  int number;
  argint(0, &number);
    8000348a:	fec40593          	addi	a1,s0,-20
    8000348e:	4501                	li	a0,0
    80003490:	00000097          	auipc	ra,0x0
    80003494:	b6a080e7          	jalr	-1174(ra) # 80002ffa <argint>

  return settickets(number);
    80003498:	fec42503          	lw	a0,-20(s0)
    8000349c:	fffff097          	auipc	ra,0xfffff
    800034a0:	42c080e7          	jalr	1068(ra) # 800028c8 <settickets>
}
    800034a4:	60e2                	ld	ra,24(sp)
    800034a6:	6442                	ld	s0,16(sp)
    800034a8:	6105                	addi	sp,sp,32
    800034aa:	8082                	ret

00000000800034ac <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034ac:	7179                	addi	sp,sp,-48
    800034ae:	f406                	sd	ra,40(sp)
    800034b0:	f022                	sd	s0,32(sp)
    800034b2:	ec26                	sd	s1,24(sp)
    800034b4:	e84a                	sd	s2,16(sp)
    800034b6:	e44e                	sd	s3,8(sp)
    800034b8:	e052                	sd	s4,0(sp)
    800034ba:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034bc:	00005597          	auipc	a1,0x5
    800034c0:	f2c58593          	addi	a1,a1,-212 # 800083e8 <etext+0x3e8>
    800034c4:	00016517          	auipc	a0,0x16
    800034c8:	6d450513          	addi	a0,a0,1748 # 80019b98 <bcache>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	6dc080e7          	jalr	1756(ra) # 80000ba8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034d4:	0001e797          	auipc	a5,0x1e
    800034d8:	6c478793          	addi	a5,a5,1732 # 80021b98 <bcache+0x8000>
    800034dc:	0001f717          	auipc	a4,0x1f
    800034e0:	92470713          	addi	a4,a4,-1756 # 80021e00 <bcache+0x8268>
    800034e4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034e8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ec:	00016497          	auipc	s1,0x16
    800034f0:	6c448493          	addi	s1,s1,1732 # 80019bb0 <bcache+0x18>
    b->next = bcache.head.next;
    800034f4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034f6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034f8:	00005a17          	auipc	s4,0x5
    800034fc:	ef8a0a13          	addi	s4,s4,-264 # 800083f0 <etext+0x3f0>
    b->next = bcache.head.next;
    80003500:	2b893783          	ld	a5,696(s2)
    80003504:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003506:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000350a:	85d2                	mv	a1,s4
    8000350c:	01048513          	addi	a0,s1,16
    80003510:	00001097          	auipc	ra,0x1
    80003514:	4e8080e7          	jalr	1256(ra) # 800049f8 <initsleeplock>
    bcache.head.next->prev = b;
    80003518:	2b893783          	ld	a5,696(s2)
    8000351c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000351e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003522:	45848493          	addi	s1,s1,1112
    80003526:	fd349de3          	bne	s1,s3,80003500 <binit+0x54>
  }
}
    8000352a:	70a2                	ld	ra,40(sp)
    8000352c:	7402                	ld	s0,32(sp)
    8000352e:	64e2                	ld	s1,24(sp)
    80003530:	6942                	ld	s2,16(sp)
    80003532:	69a2                	ld	s3,8(sp)
    80003534:	6a02                	ld	s4,0(sp)
    80003536:	6145                	addi	sp,sp,48
    80003538:	8082                	ret

000000008000353a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000353a:	7179                	addi	sp,sp,-48
    8000353c:	f406                	sd	ra,40(sp)
    8000353e:	f022                	sd	s0,32(sp)
    80003540:	ec26                	sd	s1,24(sp)
    80003542:	e84a                	sd	s2,16(sp)
    80003544:	e44e                	sd	s3,8(sp)
    80003546:	1800                	addi	s0,sp,48
    80003548:	892a                	mv	s2,a0
    8000354a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000354c:	00016517          	auipc	a0,0x16
    80003550:	64c50513          	addi	a0,a0,1612 # 80019b98 <bcache>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	6e4080e7          	jalr	1764(ra) # 80000c38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000355c:	0001f497          	auipc	s1,0x1f
    80003560:	8f44b483          	ld	s1,-1804(s1) # 80021e50 <bcache+0x82b8>
    80003564:	0001f797          	auipc	a5,0x1f
    80003568:	89c78793          	addi	a5,a5,-1892 # 80021e00 <bcache+0x8268>
    8000356c:	02f48f63          	beq	s1,a5,800035aa <bread+0x70>
    80003570:	873e                	mv	a4,a5
    80003572:	a021                	j	8000357a <bread+0x40>
    80003574:	68a4                	ld	s1,80(s1)
    80003576:	02e48a63          	beq	s1,a4,800035aa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000357a:	449c                	lw	a5,8(s1)
    8000357c:	ff279ce3          	bne	a5,s2,80003574 <bread+0x3a>
    80003580:	44dc                	lw	a5,12(s1)
    80003582:	ff3799e3          	bne	a5,s3,80003574 <bread+0x3a>
      b->refcnt++;
    80003586:	40bc                	lw	a5,64(s1)
    80003588:	2785                	addiw	a5,a5,1
    8000358a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000358c:	00016517          	auipc	a0,0x16
    80003590:	60c50513          	addi	a0,a0,1548 # 80019b98 <bcache>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	758080e7          	jalr	1880(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    8000359c:	01048513          	addi	a0,s1,16
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	492080e7          	jalr	1170(ra) # 80004a32 <acquiresleep>
      return b;
    800035a8:	a8b9                	j	80003606 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035aa:	0001f497          	auipc	s1,0x1f
    800035ae:	89e4b483          	ld	s1,-1890(s1) # 80021e48 <bcache+0x82b0>
    800035b2:	0001f797          	auipc	a5,0x1f
    800035b6:	84e78793          	addi	a5,a5,-1970 # 80021e00 <bcache+0x8268>
    800035ba:	00f48863          	beq	s1,a5,800035ca <bread+0x90>
    800035be:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035c0:	40bc                	lw	a5,64(s1)
    800035c2:	cf81                	beqz	a5,800035da <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035c4:	64a4                	ld	s1,72(s1)
    800035c6:	fee49de3          	bne	s1,a4,800035c0 <bread+0x86>
  panic("bget: no buffers");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	e2e50513          	addi	a0,a0,-466 # 800083f8 <etext+0x3f8>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f8e080e7          	jalr	-114(ra) # 80000560 <panic>
      b->dev = dev;
    800035da:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035de:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035e2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035e6:	4785                	li	a5,1
    800035e8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035ea:	00016517          	auipc	a0,0x16
    800035ee:	5ae50513          	addi	a0,a0,1454 # 80019b98 <bcache>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	6fa080e7          	jalr	1786(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    800035fa:	01048513          	addi	a0,s1,16
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	434080e7          	jalr	1076(ra) # 80004a32 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003606:	409c                	lw	a5,0(s1)
    80003608:	cb89                	beqz	a5,8000361a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000360a:	8526                	mv	a0,s1
    8000360c:	70a2                	ld	ra,40(sp)
    8000360e:	7402                	ld	s0,32(sp)
    80003610:	64e2                	ld	s1,24(sp)
    80003612:	6942                	ld	s2,16(sp)
    80003614:	69a2                	ld	s3,8(sp)
    80003616:	6145                	addi	sp,sp,48
    80003618:	8082                	ret
    virtio_disk_rw(b, 0);
    8000361a:	4581                	li	a1,0
    8000361c:	8526                	mv	a0,s1
    8000361e:	00003097          	auipc	ra,0x3
    80003622:	0fa080e7          	jalr	250(ra) # 80006718 <virtio_disk_rw>
    b->valid = 1;
    80003626:	4785                	li	a5,1
    80003628:	c09c                	sw	a5,0(s1)
  return b;
    8000362a:	b7c5                	j	8000360a <bread+0xd0>

000000008000362c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	1000                	addi	s0,sp,32
    80003636:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003638:	0541                	addi	a0,a0,16
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	492080e7          	jalr	1170(ra) # 80004acc <holdingsleep>
    80003642:	cd01                	beqz	a0,8000365a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003644:	4585                	li	a1,1
    80003646:	8526                	mv	a0,s1
    80003648:	00003097          	auipc	ra,0x3
    8000364c:	0d0080e7          	jalr	208(ra) # 80006718 <virtio_disk_rw>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6105                	addi	sp,sp,32
    80003658:	8082                	ret
    panic("bwrite");
    8000365a:	00005517          	auipc	a0,0x5
    8000365e:	db650513          	addi	a0,a0,-586 # 80008410 <etext+0x410>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	efe080e7          	jalr	-258(ra) # 80000560 <panic>

000000008000366a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000366a:	1101                	addi	sp,sp,-32
    8000366c:	ec06                	sd	ra,24(sp)
    8000366e:	e822                	sd	s0,16(sp)
    80003670:	e426                	sd	s1,8(sp)
    80003672:	e04a                	sd	s2,0(sp)
    80003674:	1000                	addi	s0,sp,32
    80003676:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003678:	01050913          	addi	s2,a0,16
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	44e080e7          	jalr	1102(ra) # 80004acc <holdingsleep>
    80003686:	c925                	beqz	a0,800036f6 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003688:	854a                	mv	a0,s2
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	3fe080e7          	jalr	1022(ra) # 80004a88 <releasesleep>

  acquire(&bcache.lock);
    80003692:	00016517          	auipc	a0,0x16
    80003696:	50650513          	addi	a0,a0,1286 # 80019b98 <bcache>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	59e080e7          	jalr	1438(ra) # 80000c38 <acquire>
  b->refcnt--;
    800036a2:	40bc                	lw	a5,64(s1)
    800036a4:	37fd                	addiw	a5,a5,-1
    800036a6:	0007871b          	sext.w	a4,a5
    800036aa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036ac:	e71d                	bnez	a4,800036da <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036ae:	68b8                	ld	a4,80(s1)
    800036b0:	64bc                	ld	a5,72(s1)
    800036b2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800036b4:	68b8                	ld	a4,80(s1)
    800036b6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036b8:	0001e797          	auipc	a5,0x1e
    800036bc:	4e078793          	addi	a5,a5,1248 # 80021b98 <bcache+0x8000>
    800036c0:	2b87b703          	ld	a4,696(a5)
    800036c4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036c6:	0001e717          	auipc	a4,0x1e
    800036ca:	73a70713          	addi	a4,a4,1850 # 80021e00 <bcache+0x8268>
    800036ce:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036d0:	2b87b703          	ld	a4,696(a5)
    800036d4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036d6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036da:	00016517          	auipc	a0,0x16
    800036de:	4be50513          	addi	a0,a0,1214 # 80019b98 <bcache>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	60a080e7          	jalr	1546(ra) # 80000cec <release>
}
    800036ea:	60e2                	ld	ra,24(sp)
    800036ec:	6442                	ld	s0,16(sp)
    800036ee:	64a2                	ld	s1,8(sp)
    800036f0:	6902                	ld	s2,0(sp)
    800036f2:	6105                	addi	sp,sp,32
    800036f4:	8082                	ret
    panic("brelse");
    800036f6:	00005517          	auipc	a0,0x5
    800036fa:	d2250513          	addi	a0,a0,-734 # 80008418 <etext+0x418>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	e62080e7          	jalr	-414(ra) # 80000560 <panic>

0000000080003706 <bpin>:

void
bpin(struct buf *b) {
    80003706:	1101                	addi	sp,sp,-32
    80003708:	ec06                	sd	ra,24(sp)
    8000370a:	e822                	sd	s0,16(sp)
    8000370c:	e426                	sd	s1,8(sp)
    8000370e:	1000                	addi	s0,sp,32
    80003710:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003712:	00016517          	auipc	a0,0x16
    80003716:	48650513          	addi	a0,a0,1158 # 80019b98 <bcache>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	51e080e7          	jalr	1310(ra) # 80000c38 <acquire>
  b->refcnt++;
    80003722:	40bc                	lw	a5,64(s1)
    80003724:	2785                	addiw	a5,a5,1
    80003726:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003728:	00016517          	auipc	a0,0x16
    8000372c:	47050513          	addi	a0,a0,1136 # 80019b98 <bcache>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	5bc080e7          	jalr	1468(ra) # 80000cec <release>
}
    80003738:	60e2                	ld	ra,24(sp)
    8000373a:	6442                	ld	s0,16(sp)
    8000373c:	64a2                	ld	s1,8(sp)
    8000373e:	6105                	addi	sp,sp,32
    80003740:	8082                	ret

0000000080003742 <bunpin>:

void
bunpin(struct buf *b) {
    80003742:	1101                	addi	sp,sp,-32
    80003744:	ec06                	sd	ra,24(sp)
    80003746:	e822                	sd	s0,16(sp)
    80003748:	e426                	sd	s1,8(sp)
    8000374a:	1000                	addi	s0,sp,32
    8000374c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000374e:	00016517          	auipc	a0,0x16
    80003752:	44a50513          	addi	a0,a0,1098 # 80019b98 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	4e2080e7          	jalr	1250(ra) # 80000c38 <acquire>
  b->refcnt--;
    8000375e:	40bc                	lw	a5,64(s1)
    80003760:	37fd                	addiw	a5,a5,-1
    80003762:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003764:	00016517          	auipc	a0,0x16
    80003768:	43450513          	addi	a0,a0,1076 # 80019b98 <bcache>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	580080e7          	jalr	1408(ra) # 80000cec <release>
}
    80003774:	60e2                	ld	ra,24(sp)
    80003776:	6442                	ld	s0,16(sp)
    80003778:	64a2                	ld	s1,8(sp)
    8000377a:	6105                	addi	sp,sp,32
    8000377c:	8082                	ret

000000008000377e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	e04a                	sd	s2,0(sp)
    80003788:	1000                	addi	s0,sp,32
    8000378a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000378c:	00d5d59b          	srliw	a1,a1,0xd
    80003790:	0001f797          	auipc	a5,0x1f
    80003794:	ae47a783          	lw	a5,-1308(a5) # 80022274 <sb+0x1c>
    80003798:	9dbd                	addw	a1,a1,a5
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	da0080e7          	jalr	-608(ra) # 8000353a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037a2:	0074f713          	andi	a4,s1,7
    800037a6:	4785                	li	a5,1
    800037a8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037ac:	14ce                	slli	s1,s1,0x33
    800037ae:	90d9                	srli	s1,s1,0x36
    800037b0:	00950733          	add	a4,a0,s1
    800037b4:	05874703          	lbu	a4,88(a4)
    800037b8:	00e7f6b3          	and	a3,a5,a4
    800037bc:	c69d                	beqz	a3,800037ea <bfree+0x6c>
    800037be:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037c0:	94aa                	add	s1,s1,a0
    800037c2:	fff7c793          	not	a5,a5
    800037c6:	8f7d                	and	a4,a4,a5
    800037c8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	148080e7          	jalr	328(ra) # 80004914 <log_write>
  brelse(bp);
    800037d4:	854a                	mv	a0,s2
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	e94080e7          	jalr	-364(ra) # 8000366a <brelse>
}
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6902                	ld	s2,0(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret
    panic("freeing free block");
    800037ea:	00005517          	auipc	a0,0x5
    800037ee:	c3650513          	addi	a0,a0,-970 # 80008420 <etext+0x420>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d6e080e7          	jalr	-658(ra) # 80000560 <panic>

00000000800037fa <balloc>:
{
    800037fa:	711d                	addi	sp,sp,-96
    800037fc:	ec86                	sd	ra,88(sp)
    800037fe:	e8a2                	sd	s0,80(sp)
    80003800:	e4a6                	sd	s1,72(sp)
    80003802:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003804:	0001f797          	auipc	a5,0x1f
    80003808:	a587a783          	lw	a5,-1448(a5) # 8002225c <sb+0x4>
    8000380c:	10078f63          	beqz	a5,8000392a <balloc+0x130>
    80003810:	e0ca                	sd	s2,64(sp)
    80003812:	fc4e                	sd	s3,56(sp)
    80003814:	f852                	sd	s4,48(sp)
    80003816:	f456                	sd	s5,40(sp)
    80003818:	f05a                	sd	s6,32(sp)
    8000381a:	ec5e                	sd	s7,24(sp)
    8000381c:	e862                	sd	s8,16(sp)
    8000381e:	e466                	sd	s9,8(sp)
    80003820:	8baa                	mv	s7,a0
    80003822:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003824:	0001fb17          	auipc	s6,0x1f
    80003828:	a34b0b13          	addi	s6,s6,-1484 # 80022258 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000382c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000382e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003830:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003832:	6c89                	lui	s9,0x2
    80003834:	a061                	j	800038bc <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003836:	97ca                	add	a5,a5,s2
    80003838:	8e55                	or	a2,a2,a3
    8000383a:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	0d4080e7          	jalr	212(ra) # 80004914 <log_write>
        brelse(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	e20080e7          	jalr	-480(ra) # 8000366a <brelse>
  bp = bread(dev, bno);
    80003852:	85a6                	mv	a1,s1
    80003854:	855e                	mv	a0,s7
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	ce4080e7          	jalr	-796(ra) # 8000353a <bread>
    8000385e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003860:	40000613          	li	a2,1024
    80003864:	4581                	li	a1,0
    80003866:	05850513          	addi	a0,a0,88
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	4ca080e7          	jalr	1226(ra) # 80000d34 <memset>
  log_write(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	0a0080e7          	jalr	160(ra) # 80004914 <log_write>
  brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	dec080e7          	jalr	-532(ra) # 8000366a <brelse>
}
    80003886:	6906                	ld	s2,64(sp)
    80003888:	79e2                	ld	s3,56(sp)
    8000388a:	7a42                	ld	s4,48(sp)
    8000388c:	7aa2                	ld	s5,40(sp)
    8000388e:	7b02                	ld	s6,32(sp)
    80003890:	6be2                	ld	s7,24(sp)
    80003892:	6c42                	ld	s8,16(sp)
    80003894:	6ca2                	ld	s9,8(sp)
}
    80003896:	8526                	mv	a0,s1
    80003898:	60e6                	ld	ra,88(sp)
    8000389a:	6446                	ld	s0,80(sp)
    8000389c:	64a6                	ld	s1,72(sp)
    8000389e:	6125                	addi	sp,sp,96
    800038a0:	8082                	ret
    brelse(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	dc6080e7          	jalr	-570(ra) # 8000366a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038ac:	015c87bb          	addw	a5,s9,s5
    800038b0:	00078a9b          	sext.w	s5,a5
    800038b4:	004b2703          	lw	a4,4(s6)
    800038b8:	06eaf163          	bgeu	s5,a4,8000391a <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    800038bc:	41fad79b          	sraiw	a5,s5,0x1f
    800038c0:	0137d79b          	srliw	a5,a5,0x13
    800038c4:	015787bb          	addw	a5,a5,s5
    800038c8:	40d7d79b          	sraiw	a5,a5,0xd
    800038cc:	01cb2583          	lw	a1,28(s6)
    800038d0:	9dbd                	addw	a1,a1,a5
    800038d2:	855e                	mv	a0,s7
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	c66080e7          	jalr	-922(ra) # 8000353a <bread>
    800038dc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038de:	004b2503          	lw	a0,4(s6)
    800038e2:	000a849b          	sext.w	s1,s5
    800038e6:	8762                	mv	a4,s8
    800038e8:	faa4fde3          	bgeu	s1,a0,800038a2 <balloc+0xa8>
      m = 1 << (bi % 8);
    800038ec:	00777693          	andi	a3,a4,7
    800038f0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038f4:	41f7579b          	sraiw	a5,a4,0x1f
    800038f8:	01d7d79b          	srliw	a5,a5,0x1d
    800038fc:	9fb9                	addw	a5,a5,a4
    800038fe:	4037d79b          	sraiw	a5,a5,0x3
    80003902:	00f90633          	add	a2,s2,a5
    80003906:	05864603          	lbu	a2,88(a2)
    8000390a:	00c6f5b3          	and	a1,a3,a2
    8000390e:	d585                	beqz	a1,80003836 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003910:	2705                	addiw	a4,a4,1
    80003912:	2485                	addiw	s1,s1,1
    80003914:	fd471ae3          	bne	a4,s4,800038e8 <balloc+0xee>
    80003918:	b769                	j	800038a2 <balloc+0xa8>
    8000391a:	6906                	ld	s2,64(sp)
    8000391c:	79e2                	ld	s3,56(sp)
    8000391e:	7a42                	ld	s4,48(sp)
    80003920:	7aa2                	ld	s5,40(sp)
    80003922:	7b02                	ld	s6,32(sp)
    80003924:	6be2                	ld	s7,24(sp)
    80003926:	6c42                	ld	s8,16(sp)
    80003928:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    8000392a:	00005517          	auipc	a0,0x5
    8000392e:	b0e50513          	addi	a0,a0,-1266 # 80008438 <etext+0x438>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	c78080e7          	jalr	-904(ra) # 800005aa <printf>
  return 0;
    8000393a:	4481                	li	s1,0
    8000393c:	bfa9                	j	80003896 <balloc+0x9c>

000000008000393e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000393e:	7179                	addi	sp,sp,-48
    80003940:	f406                	sd	ra,40(sp)
    80003942:	f022                	sd	s0,32(sp)
    80003944:	ec26                	sd	s1,24(sp)
    80003946:	e84a                	sd	s2,16(sp)
    80003948:	e44e                	sd	s3,8(sp)
    8000394a:	1800                	addi	s0,sp,48
    8000394c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000394e:	47ad                	li	a5,11
    80003950:	02b7e863          	bltu	a5,a1,80003980 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003954:	02059793          	slli	a5,a1,0x20
    80003958:	01e7d593          	srli	a1,a5,0x1e
    8000395c:	00b504b3          	add	s1,a0,a1
    80003960:	0504a903          	lw	s2,80(s1)
    80003964:	08091263          	bnez	s2,800039e8 <bmap+0xaa>
      addr = balloc(ip->dev);
    80003968:	4108                	lw	a0,0(a0)
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	e90080e7          	jalr	-368(ra) # 800037fa <balloc>
    80003972:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003976:	06090963          	beqz	s2,800039e8 <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    8000397a:	0524a823          	sw	s2,80(s1)
    8000397e:	a0ad                	j	800039e8 <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003980:	ff45849b          	addiw	s1,a1,-12
    80003984:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003988:	0ff00793          	li	a5,255
    8000398c:	08e7e863          	bltu	a5,a4,80003a1c <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003990:	08052903          	lw	s2,128(a0)
    80003994:	00091f63          	bnez	s2,800039b2 <bmap+0x74>
      addr = balloc(ip->dev);
    80003998:	4108                	lw	a0,0(a0)
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	e60080e7          	jalr	-416(ra) # 800037fa <balloc>
    800039a2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039a6:	04090163          	beqz	s2,800039e8 <bmap+0xaa>
    800039aa:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039ac:	0929a023          	sw	s2,128(s3)
    800039b0:	a011                	j	800039b4 <bmap+0x76>
    800039b2:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    800039b4:	85ca                	mv	a1,s2
    800039b6:	0009a503          	lw	a0,0(s3)
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	b80080e7          	jalr	-1152(ra) # 8000353a <bread>
    800039c2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039c4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039c8:	02049713          	slli	a4,s1,0x20
    800039cc:	01e75593          	srli	a1,a4,0x1e
    800039d0:	00b784b3          	add	s1,a5,a1
    800039d4:	0004a903          	lw	s2,0(s1)
    800039d8:	02090063          	beqz	s2,800039f8 <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039dc:	8552                	mv	a0,s4
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	c8c080e7          	jalr	-884(ra) # 8000366a <brelse>
    return addr;
    800039e6:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800039e8:	854a                	mv	a0,s2
    800039ea:	70a2                	ld	ra,40(sp)
    800039ec:	7402                	ld	s0,32(sp)
    800039ee:	64e2                	ld	s1,24(sp)
    800039f0:	6942                	ld	s2,16(sp)
    800039f2:	69a2                	ld	s3,8(sp)
    800039f4:	6145                	addi	sp,sp,48
    800039f6:	8082                	ret
      addr = balloc(ip->dev);
    800039f8:	0009a503          	lw	a0,0(s3)
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	dfe080e7          	jalr	-514(ra) # 800037fa <balloc>
    80003a04:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a08:	fc090ae3          	beqz	s2,800039dc <bmap+0x9e>
        a[bn] = addr;
    80003a0c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a10:	8552                	mv	a0,s4
    80003a12:	00001097          	auipc	ra,0x1
    80003a16:	f02080e7          	jalr	-254(ra) # 80004914 <log_write>
    80003a1a:	b7c9                	j	800039dc <bmap+0x9e>
    80003a1c:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003a1e:	00005517          	auipc	a0,0x5
    80003a22:	a3250513          	addi	a0,a0,-1486 # 80008450 <etext+0x450>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	b3a080e7          	jalr	-1222(ra) # 80000560 <panic>

0000000080003a2e <iget>:
{
    80003a2e:	7179                	addi	sp,sp,-48
    80003a30:	f406                	sd	ra,40(sp)
    80003a32:	f022                	sd	s0,32(sp)
    80003a34:	ec26                	sd	s1,24(sp)
    80003a36:	e84a                	sd	s2,16(sp)
    80003a38:	e44e                	sd	s3,8(sp)
    80003a3a:	e052                	sd	s4,0(sp)
    80003a3c:	1800                	addi	s0,sp,48
    80003a3e:	89aa                	mv	s3,a0
    80003a40:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a42:	0001f517          	auipc	a0,0x1f
    80003a46:	83650513          	addi	a0,a0,-1994 # 80022278 <itable>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	1ee080e7          	jalr	494(ra) # 80000c38 <acquire>
  empty = 0;
    80003a52:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a54:	0001f497          	auipc	s1,0x1f
    80003a58:	83c48493          	addi	s1,s1,-1988 # 80022290 <itable+0x18>
    80003a5c:	00020697          	auipc	a3,0x20
    80003a60:	2c468693          	addi	a3,a3,708 # 80023d20 <log>
    80003a64:	a039                	j	80003a72 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a66:	02090b63          	beqz	s2,80003a9c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a6a:	08848493          	addi	s1,s1,136
    80003a6e:	02d48a63          	beq	s1,a3,80003aa2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a72:	449c                	lw	a5,8(s1)
    80003a74:	fef059e3          	blez	a5,80003a66 <iget+0x38>
    80003a78:	4098                	lw	a4,0(s1)
    80003a7a:	ff3716e3          	bne	a4,s3,80003a66 <iget+0x38>
    80003a7e:	40d8                	lw	a4,4(s1)
    80003a80:	ff4713e3          	bne	a4,s4,80003a66 <iget+0x38>
      ip->ref++;
    80003a84:	2785                	addiw	a5,a5,1
    80003a86:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a88:	0001e517          	auipc	a0,0x1e
    80003a8c:	7f050513          	addi	a0,a0,2032 # 80022278 <itable>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	25c080e7          	jalr	604(ra) # 80000cec <release>
      return ip;
    80003a98:	8926                	mv	s2,s1
    80003a9a:	a03d                	j	80003ac8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a9c:	f7f9                	bnez	a5,80003a6a <iget+0x3c>
      empty = ip;
    80003a9e:	8926                	mv	s2,s1
    80003aa0:	b7e9                	j	80003a6a <iget+0x3c>
  if(empty == 0)
    80003aa2:	02090c63          	beqz	s2,80003ada <iget+0xac>
  ip->dev = dev;
    80003aa6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003aaa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003aae:	4785                	li	a5,1
    80003ab0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ab4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ab8:	0001e517          	auipc	a0,0x1e
    80003abc:	7c050513          	addi	a0,a0,1984 # 80022278 <itable>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	22c080e7          	jalr	556(ra) # 80000cec <release>
}
    80003ac8:	854a                	mv	a0,s2
    80003aca:	70a2                	ld	ra,40(sp)
    80003acc:	7402                	ld	s0,32(sp)
    80003ace:	64e2                	ld	s1,24(sp)
    80003ad0:	6942                	ld	s2,16(sp)
    80003ad2:	69a2                	ld	s3,8(sp)
    80003ad4:	6a02                	ld	s4,0(sp)
    80003ad6:	6145                	addi	sp,sp,48
    80003ad8:	8082                	ret
    panic("iget: no inodes");
    80003ada:	00005517          	auipc	a0,0x5
    80003ade:	98e50513          	addi	a0,a0,-1650 # 80008468 <etext+0x468>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	a7e080e7          	jalr	-1410(ra) # 80000560 <panic>

0000000080003aea <fsinit>:
fsinit(int dev) {
    80003aea:	7179                	addi	sp,sp,-48
    80003aec:	f406                	sd	ra,40(sp)
    80003aee:	f022                	sd	s0,32(sp)
    80003af0:	ec26                	sd	s1,24(sp)
    80003af2:	e84a                	sd	s2,16(sp)
    80003af4:	e44e                	sd	s3,8(sp)
    80003af6:	1800                	addi	s0,sp,48
    80003af8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003afa:	4585                	li	a1,1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	a3e080e7          	jalr	-1474(ra) # 8000353a <bread>
    80003b04:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b06:	0001e997          	auipc	s3,0x1e
    80003b0a:	75298993          	addi	s3,s3,1874 # 80022258 <sb>
    80003b0e:	02000613          	li	a2,32
    80003b12:	05850593          	addi	a1,a0,88
    80003b16:	854e                	mv	a0,s3
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	278080e7          	jalr	632(ra) # 80000d90 <memmove>
  brelse(bp);
    80003b20:	8526                	mv	a0,s1
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	b48080e7          	jalr	-1208(ra) # 8000366a <brelse>
  if(sb.magic != FSMAGIC)
    80003b2a:	0009a703          	lw	a4,0(s3)
    80003b2e:	102037b7          	lui	a5,0x10203
    80003b32:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b36:	02f71263          	bne	a4,a5,80003b5a <fsinit+0x70>
  initlog(dev, &sb);
    80003b3a:	0001e597          	auipc	a1,0x1e
    80003b3e:	71e58593          	addi	a1,a1,1822 # 80022258 <sb>
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	b60080e7          	jalr	-1184(ra) # 800046a4 <initlog>
}
    80003b4c:	70a2                	ld	ra,40(sp)
    80003b4e:	7402                	ld	s0,32(sp)
    80003b50:	64e2                	ld	s1,24(sp)
    80003b52:	6942                	ld	s2,16(sp)
    80003b54:	69a2                	ld	s3,8(sp)
    80003b56:	6145                	addi	sp,sp,48
    80003b58:	8082                	ret
    panic("invalid file system");
    80003b5a:	00005517          	auipc	a0,0x5
    80003b5e:	91e50513          	addi	a0,a0,-1762 # 80008478 <etext+0x478>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	9fe080e7          	jalr	-1538(ra) # 80000560 <panic>

0000000080003b6a <iinit>:
{
    80003b6a:	7179                	addi	sp,sp,-48
    80003b6c:	f406                	sd	ra,40(sp)
    80003b6e:	f022                	sd	s0,32(sp)
    80003b70:	ec26                	sd	s1,24(sp)
    80003b72:	e84a                	sd	s2,16(sp)
    80003b74:	e44e                	sd	s3,8(sp)
    80003b76:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b78:	00005597          	auipc	a1,0x5
    80003b7c:	91858593          	addi	a1,a1,-1768 # 80008490 <etext+0x490>
    80003b80:	0001e517          	auipc	a0,0x1e
    80003b84:	6f850513          	addi	a0,a0,1784 # 80022278 <itable>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	020080e7          	jalr	32(ra) # 80000ba8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b90:	0001e497          	auipc	s1,0x1e
    80003b94:	71048493          	addi	s1,s1,1808 # 800222a0 <itable+0x28>
    80003b98:	00020997          	auipc	s3,0x20
    80003b9c:	19898993          	addi	s3,s3,408 # 80023d30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ba0:	00005917          	auipc	s2,0x5
    80003ba4:	8f890913          	addi	s2,s2,-1800 # 80008498 <etext+0x498>
    80003ba8:	85ca                	mv	a1,s2
    80003baa:	8526                	mv	a0,s1
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	e4c080e7          	jalr	-436(ra) # 800049f8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003bb4:	08848493          	addi	s1,s1,136
    80003bb8:	ff3498e3          	bne	s1,s3,80003ba8 <iinit+0x3e>
}
    80003bbc:	70a2                	ld	ra,40(sp)
    80003bbe:	7402                	ld	s0,32(sp)
    80003bc0:	64e2                	ld	s1,24(sp)
    80003bc2:	6942                	ld	s2,16(sp)
    80003bc4:	69a2                	ld	s3,8(sp)
    80003bc6:	6145                	addi	sp,sp,48
    80003bc8:	8082                	ret

0000000080003bca <ialloc>:
{
    80003bca:	7139                	addi	sp,sp,-64
    80003bcc:	fc06                	sd	ra,56(sp)
    80003bce:	f822                	sd	s0,48(sp)
    80003bd0:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bd2:	0001e717          	auipc	a4,0x1e
    80003bd6:	69272703          	lw	a4,1682(a4) # 80022264 <sb+0xc>
    80003bda:	4785                	li	a5,1
    80003bdc:	06e7f463          	bgeu	a5,a4,80003c44 <ialloc+0x7a>
    80003be0:	f426                	sd	s1,40(sp)
    80003be2:	f04a                	sd	s2,32(sp)
    80003be4:	ec4e                	sd	s3,24(sp)
    80003be6:	e852                	sd	s4,16(sp)
    80003be8:	e456                	sd	s5,8(sp)
    80003bea:	e05a                	sd	s6,0(sp)
    80003bec:	8aaa                	mv	s5,a0
    80003bee:	8b2e                	mv	s6,a1
    80003bf0:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bf2:	0001ea17          	auipc	s4,0x1e
    80003bf6:	666a0a13          	addi	s4,s4,1638 # 80022258 <sb>
    80003bfa:	00495593          	srli	a1,s2,0x4
    80003bfe:	018a2783          	lw	a5,24(s4)
    80003c02:	9dbd                	addw	a1,a1,a5
    80003c04:	8556                	mv	a0,s5
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	934080e7          	jalr	-1740(ra) # 8000353a <bread>
    80003c0e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c10:	05850993          	addi	s3,a0,88
    80003c14:	00f97793          	andi	a5,s2,15
    80003c18:	079a                	slli	a5,a5,0x6
    80003c1a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c1c:	00099783          	lh	a5,0(s3)
    80003c20:	cf9d                	beqz	a5,80003c5e <ialloc+0x94>
    brelse(bp);
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	a48080e7          	jalr	-1464(ra) # 8000366a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c2a:	0905                	addi	s2,s2,1
    80003c2c:	00ca2703          	lw	a4,12(s4)
    80003c30:	0009079b          	sext.w	a5,s2
    80003c34:	fce7e3e3          	bltu	a5,a4,80003bfa <ialloc+0x30>
    80003c38:	74a2                	ld	s1,40(sp)
    80003c3a:	7902                	ld	s2,32(sp)
    80003c3c:	69e2                	ld	s3,24(sp)
    80003c3e:	6a42                	ld	s4,16(sp)
    80003c40:	6aa2                	ld	s5,8(sp)
    80003c42:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003c44:	00005517          	auipc	a0,0x5
    80003c48:	85c50513          	addi	a0,a0,-1956 # 800084a0 <etext+0x4a0>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	95e080e7          	jalr	-1698(ra) # 800005aa <printf>
  return 0;
    80003c54:	4501                	li	a0,0
}
    80003c56:	70e2                	ld	ra,56(sp)
    80003c58:	7442                	ld	s0,48(sp)
    80003c5a:	6121                	addi	sp,sp,64
    80003c5c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c5e:	04000613          	li	a2,64
    80003c62:	4581                	li	a1,0
    80003c64:	854e                	mv	a0,s3
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	0ce080e7          	jalr	206(ra) # 80000d34 <memset>
      dip->type = type;
    80003c6e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c72:	8526                	mv	a0,s1
    80003c74:	00001097          	auipc	ra,0x1
    80003c78:	ca0080e7          	jalr	-864(ra) # 80004914 <log_write>
      brelse(bp);
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	9ec080e7          	jalr	-1556(ra) # 8000366a <brelse>
      return iget(dev, inum);
    80003c86:	0009059b          	sext.w	a1,s2
    80003c8a:	8556                	mv	a0,s5
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	da2080e7          	jalr	-606(ra) # 80003a2e <iget>
    80003c94:	74a2                	ld	s1,40(sp)
    80003c96:	7902                	ld	s2,32(sp)
    80003c98:	69e2                	ld	s3,24(sp)
    80003c9a:	6a42                	ld	s4,16(sp)
    80003c9c:	6aa2                	ld	s5,8(sp)
    80003c9e:	6b02                	ld	s6,0(sp)
    80003ca0:	bf5d                	j	80003c56 <ialloc+0x8c>

0000000080003ca2 <iupdate>:
{
    80003ca2:	1101                	addi	sp,sp,-32
    80003ca4:	ec06                	sd	ra,24(sp)
    80003ca6:	e822                	sd	s0,16(sp)
    80003ca8:	e426                	sd	s1,8(sp)
    80003caa:	e04a                	sd	s2,0(sp)
    80003cac:	1000                	addi	s0,sp,32
    80003cae:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cb0:	415c                	lw	a5,4(a0)
    80003cb2:	0047d79b          	srliw	a5,a5,0x4
    80003cb6:	0001e597          	auipc	a1,0x1e
    80003cba:	5ba5a583          	lw	a1,1466(a1) # 80022270 <sb+0x18>
    80003cbe:	9dbd                	addw	a1,a1,a5
    80003cc0:	4108                	lw	a0,0(a0)
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	878080e7          	jalr	-1928(ra) # 8000353a <bread>
    80003cca:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ccc:	05850793          	addi	a5,a0,88
    80003cd0:	40d8                	lw	a4,4(s1)
    80003cd2:	8b3d                	andi	a4,a4,15
    80003cd4:	071a                	slli	a4,a4,0x6
    80003cd6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003cd8:	04449703          	lh	a4,68(s1)
    80003cdc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003ce0:	04649703          	lh	a4,70(s1)
    80003ce4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003ce8:	04849703          	lh	a4,72(s1)
    80003cec:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003cf0:	04a49703          	lh	a4,74(s1)
    80003cf4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003cf8:	44f8                	lw	a4,76(s1)
    80003cfa:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cfc:	03400613          	li	a2,52
    80003d00:	05048593          	addi	a1,s1,80
    80003d04:	00c78513          	addi	a0,a5,12
    80003d08:	ffffd097          	auipc	ra,0xffffd
    80003d0c:	088080e7          	jalr	136(ra) # 80000d90 <memmove>
  log_write(bp);
    80003d10:	854a                	mv	a0,s2
    80003d12:	00001097          	auipc	ra,0x1
    80003d16:	c02080e7          	jalr	-1022(ra) # 80004914 <log_write>
  brelse(bp);
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	94e080e7          	jalr	-1714(ra) # 8000366a <brelse>
}
    80003d24:	60e2                	ld	ra,24(sp)
    80003d26:	6442                	ld	s0,16(sp)
    80003d28:	64a2                	ld	s1,8(sp)
    80003d2a:	6902                	ld	s2,0(sp)
    80003d2c:	6105                	addi	sp,sp,32
    80003d2e:	8082                	ret

0000000080003d30 <idup>:
{
    80003d30:	1101                	addi	sp,sp,-32
    80003d32:	ec06                	sd	ra,24(sp)
    80003d34:	e822                	sd	s0,16(sp)
    80003d36:	e426                	sd	s1,8(sp)
    80003d38:	1000                	addi	s0,sp,32
    80003d3a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d3c:	0001e517          	auipc	a0,0x1e
    80003d40:	53c50513          	addi	a0,a0,1340 # 80022278 <itable>
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	ef4080e7          	jalr	-268(ra) # 80000c38 <acquire>
  ip->ref++;
    80003d4c:	449c                	lw	a5,8(s1)
    80003d4e:	2785                	addiw	a5,a5,1
    80003d50:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d52:	0001e517          	auipc	a0,0x1e
    80003d56:	52650513          	addi	a0,a0,1318 # 80022278 <itable>
    80003d5a:	ffffd097          	auipc	ra,0xffffd
    80003d5e:	f92080e7          	jalr	-110(ra) # 80000cec <release>
}
    80003d62:	8526                	mv	a0,s1
    80003d64:	60e2                	ld	ra,24(sp)
    80003d66:	6442                	ld	s0,16(sp)
    80003d68:	64a2                	ld	s1,8(sp)
    80003d6a:	6105                	addi	sp,sp,32
    80003d6c:	8082                	ret

0000000080003d6e <ilock>:
{
    80003d6e:	1101                	addi	sp,sp,-32
    80003d70:	ec06                	sd	ra,24(sp)
    80003d72:	e822                	sd	s0,16(sp)
    80003d74:	e426                	sd	s1,8(sp)
    80003d76:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d78:	c10d                	beqz	a0,80003d9a <ilock+0x2c>
    80003d7a:	84aa                	mv	s1,a0
    80003d7c:	451c                	lw	a5,8(a0)
    80003d7e:	00f05e63          	blez	a5,80003d9a <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003d82:	0541                	addi	a0,a0,16
    80003d84:	00001097          	auipc	ra,0x1
    80003d88:	cae080e7          	jalr	-850(ra) # 80004a32 <acquiresleep>
  if(ip->valid == 0){
    80003d8c:	40bc                	lw	a5,64(s1)
    80003d8e:	cf99                	beqz	a5,80003dac <ilock+0x3e>
}
    80003d90:	60e2                	ld	ra,24(sp)
    80003d92:	6442                	ld	s0,16(sp)
    80003d94:	64a2                	ld	s1,8(sp)
    80003d96:	6105                	addi	sp,sp,32
    80003d98:	8082                	ret
    80003d9a:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003d9c:	00004517          	auipc	a0,0x4
    80003da0:	71c50513          	addi	a0,a0,1820 # 800084b8 <etext+0x4b8>
    80003da4:	ffffc097          	auipc	ra,0xffffc
    80003da8:	7bc080e7          	jalr	1980(ra) # 80000560 <panic>
    80003dac:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dae:	40dc                	lw	a5,4(s1)
    80003db0:	0047d79b          	srliw	a5,a5,0x4
    80003db4:	0001e597          	auipc	a1,0x1e
    80003db8:	4bc5a583          	lw	a1,1212(a1) # 80022270 <sb+0x18>
    80003dbc:	9dbd                	addw	a1,a1,a5
    80003dbe:	4088                	lw	a0,0(s1)
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	77a080e7          	jalr	1914(ra) # 8000353a <bread>
    80003dc8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dca:	05850593          	addi	a1,a0,88
    80003dce:	40dc                	lw	a5,4(s1)
    80003dd0:	8bbd                	andi	a5,a5,15
    80003dd2:	079a                	slli	a5,a5,0x6
    80003dd4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003dd6:	00059783          	lh	a5,0(a1)
    80003dda:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dde:	00259783          	lh	a5,2(a1)
    80003de2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003de6:	00459783          	lh	a5,4(a1)
    80003dea:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dee:	00659783          	lh	a5,6(a1)
    80003df2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003df6:	459c                	lw	a5,8(a1)
    80003df8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dfa:	03400613          	li	a2,52
    80003dfe:	05b1                	addi	a1,a1,12
    80003e00:	05048513          	addi	a0,s1,80
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	f8c080e7          	jalr	-116(ra) # 80000d90 <memmove>
    brelse(bp);
    80003e0c:	854a                	mv	a0,s2
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	85c080e7          	jalr	-1956(ra) # 8000366a <brelse>
    ip->valid = 1;
    80003e16:	4785                	li	a5,1
    80003e18:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e1a:	04449783          	lh	a5,68(s1)
    80003e1e:	c399                	beqz	a5,80003e24 <ilock+0xb6>
    80003e20:	6902                	ld	s2,0(sp)
    80003e22:	b7bd                	j	80003d90 <ilock+0x22>
      panic("ilock: no type");
    80003e24:	00004517          	auipc	a0,0x4
    80003e28:	69c50513          	addi	a0,a0,1692 # 800084c0 <etext+0x4c0>
    80003e2c:	ffffc097          	auipc	ra,0xffffc
    80003e30:	734080e7          	jalr	1844(ra) # 80000560 <panic>

0000000080003e34 <iunlock>:
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	e426                	sd	s1,8(sp)
    80003e3c:	e04a                	sd	s2,0(sp)
    80003e3e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e40:	c905                	beqz	a0,80003e70 <iunlock+0x3c>
    80003e42:	84aa                	mv	s1,a0
    80003e44:	01050913          	addi	s2,a0,16
    80003e48:	854a                	mv	a0,s2
    80003e4a:	00001097          	auipc	ra,0x1
    80003e4e:	c82080e7          	jalr	-894(ra) # 80004acc <holdingsleep>
    80003e52:	cd19                	beqz	a0,80003e70 <iunlock+0x3c>
    80003e54:	449c                	lw	a5,8(s1)
    80003e56:	00f05d63          	blez	a5,80003e70 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	00001097          	auipc	ra,0x1
    80003e60:	c2c080e7          	jalr	-980(ra) # 80004a88 <releasesleep>
}
    80003e64:	60e2                	ld	ra,24(sp)
    80003e66:	6442                	ld	s0,16(sp)
    80003e68:	64a2                	ld	s1,8(sp)
    80003e6a:	6902                	ld	s2,0(sp)
    80003e6c:	6105                	addi	sp,sp,32
    80003e6e:	8082                	ret
    panic("iunlock");
    80003e70:	00004517          	auipc	a0,0x4
    80003e74:	66050513          	addi	a0,a0,1632 # 800084d0 <etext+0x4d0>
    80003e78:	ffffc097          	auipc	ra,0xffffc
    80003e7c:	6e8080e7          	jalr	1768(ra) # 80000560 <panic>

0000000080003e80 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e80:	7179                	addi	sp,sp,-48
    80003e82:	f406                	sd	ra,40(sp)
    80003e84:	f022                	sd	s0,32(sp)
    80003e86:	ec26                	sd	s1,24(sp)
    80003e88:	e84a                	sd	s2,16(sp)
    80003e8a:	e44e                	sd	s3,8(sp)
    80003e8c:	1800                	addi	s0,sp,48
    80003e8e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e90:	05050493          	addi	s1,a0,80
    80003e94:	08050913          	addi	s2,a0,128
    80003e98:	a021                	j	80003ea0 <itrunc+0x20>
    80003e9a:	0491                	addi	s1,s1,4
    80003e9c:	01248d63          	beq	s1,s2,80003eb6 <itrunc+0x36>
    if(ip->addrs[i]){
    80003ea0:	408c                	lw	a1,0(s1)
    80003ea2:	dde5                	beqz	a1,80003e9a <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003ea4:	0009a503          	lw	a0,0(s3)
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	8d6080e7          	jalr	-1834(ra) # 8000377e <bfree>
      ip->addrs[i] = 0;
    80003eb0:	0004a023          	sw	zero,0(s1)
    80003eb4:	b7dd                	j	80003e9a <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003eb6:	0809a583          	lw	a1,128(s3)
    80003eba:	ed99                	bnez	a1,80003ed8 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ebc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	de0080e7          	jalr	-544(ra) # 80003ca2 <iupdate>
}
    80003eca:	70a2                	ld	ra,40(sp)
    80003ecc:	7402                	ld	s0,32(sp)
    80003ece:	64e2                	ld	s1,24(sp)
    80003ed0:	6942                	ld	s2,16(sp)
    80003ed2:	69a2                	ld	s3,8(sp)
    80003ed4:	6145                	addi	sp,sp,48
    80003ed6:	8082                	ret
    80003ed8:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003eda:	0009a503          	lw	a0,0(s3)
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	65c080e7          	jalr	1628(ra) # 8000353a <bread>
    80003ee6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ee8:	05850493          	addi	s1,a0,88
    80003eec:	45850913          	addi	s2,a0,1112
    80003ef0:	a021                	j	80003ef8 <itrunc+0x78>
    80003ef2:	0491                	addi	s1,s1,4
    80003ef4:	01248b63          	beq	s1,s2,80003f0a <itrunc+0x8a>
      if(a[j])
    80003ef8:	408c                	lw	a1,0(s1)
    80003efa:	dde5                	beqz	a1,80003ef2 <itrunc+0x72>
        bfree(ip->dev, a[j]);
    80003efc:	0009a503          	lw	a0,0(s3)
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	87e080e7          	jalr	-1922(ra) # 8000377e <bfree>
    80003f08:	b7ed                	j	80003ef2 <itrunc+0x72>
    brelse(bp);
    80003f0a:	8552                	mv	a0,s4
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	75e080e7          	jalr	1886(ra) # 8000366a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f14:	0809a583          	lw	a1,128(s3)
    80003f18:	0009a503          	lw	a0,0(s3)
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	862080e7          	jalr	-1950(ra) # 8000377e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f24:	0809a023          	sw	zero,128(s3)
    80003f28:	6a02                	ld	s4,0(sp)
    80003f2a:	bf49                	j	80003ebc <itrunc+0x3c>

0000000080003f2c <iput>:
{
    80003f2c:	1101                	addi	sp,sp,-32
    80003f2e:	ec06                	sd	ra,24(sp)
    80003f30:	e822                	sd	s0,16(sp)
    80003f32:	e426                	sd	s1,8(sp)
    80003f34:	1000                	addi	s0,sp,32
    80003f36:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f38:	0001e517          	auipc	a0,0x1e
    80003f3c:	34050513          	addi	a0,a0,832 # 80022278 <itable>
    80003f40:	ffffd097          	auipc	ra,0xffffd
    80003f44:	cf8080e7          	jalr	-776(ra) # 80000c38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f48:	4498                	lw	a4,8(s1)
    80003f4a:	4785                	li	a5,1
    80003f4c:	02f70263          	beq	a4,a5,80003f70 <iput+0x44>
  ip->ref--;
    80003f50:	449c                	lw	a5,8(s1)
    80003f52:	37fd                	addiw	a5,a5,-1
    80003f54:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f56:	0001e517          	auipc	a0,0x1e
    80003f5a:	32250513          	addi	a0,a0,802 # 80022278 <itable>
    80003f5e:	ffffd097          	auipc	ra,0xffffd
    80003f62:	d8e080e7          	jalr	-626(ra) # 80000cec <release>
}
    80003f66:	60e2                	ld	ra,24(sp)
    80003f68:	6442                	ld	s0,16(sp)
    80003f6a:	64a2                	ld	s1,8(sp)
    80003f6c:	6105                	addi	sp,sp,32
    80003f6e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f70:	40bc                	lw	a5,64(s1)
    80003f72:	dff9                	beqz	a5,80003f50 <iput+0x24>
    80003f74:	04a49783          	lh	a5,74(s1)
    80003f78:	ffe1                	bnez	a5,80003f50 <iput+0x24>
    80003f7a:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003f7c:	01048913          	addi	s2,s1,16
    80003f80:	854a                	mv	a0,s2
    80003f82:	00001097          	auipc	ra,0x1
    80003f86:	ab0080e7          	jalr	-1360(ra) # 80004a32 <acquiresleep>
    release(&itable.lock);
    80003f8a:	0001e517          	auipc	a0,0x1e
    80003f8e:	2ee50513          	addi	a0,a0,750 # 80022278 <itable>
    80003f92:	ffffd097          	auipc	ra,0xffffd
    80003f96:	d5a080e7          	jalr	-678(ra) # 80000cec <release>
    itrunc(ip);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	ee4080e7          	jalr	-284(ra) # 80003e80 <itrunc>
    ip->type = 0;
    80003fa4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fa8:	8526                	mv	a0,s1
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	cf8080e7          	jalr	-776(ra) # 80003ca2 <iupdate>
    ip->valid = 0;
    80003fb2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	00001097          	auipc	ra,0x1
    80003fbc:	ad0080e7          	jalr	-1328(ra) # 80004a88 <releasesleep>
    acquire(&itable.lock);
    80003fc0:	0001e517          	auipc	a0,0x1e
    80003fc4:	2b850513          	addi	a0,a0,696 # 80022278 <itable>
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	c70080e7          	jalr	-912(ra) # 80000c38 <acquire>
    80003fd0:	6902                	ld	s2,0(sp)
    80003fd2:	bfbd                	j	80003f50 <iput+0x24>

0000000080003fd4 <iunlockput>:
{
    80003fd4:	1101                	addi	sp,sp,-32
    80003fd6:	ec06                	sd	ra,24(sp)
    80003fd8:	e822                	sd	s0,16(sp)
    80003fda:	e426                	sd	s1,8(sp)
    80003fdc:	1000                	addi	s0,sp,32
    80003fde:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	e54080e7          	jalr	-428(ra) # 80003e34 <iunlock>
  iput(ip);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	f42080e7          	jalr	-190(ra) # 80003f2c <iput>
}
    80003ff2:	60e2                	ld	ra,24(sp)
    80003ff4:	6442                	ld	s0,16(sp)
    80003ff6:	64a2                	ld	s1,8(sp)
    80003ff8:	6105                	addi	sp,sp,32
    80003ffa:	8082                	ret

0000000080003ffc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ffc:	1141                	addi	sp,sp,-16
    80003ffe:	e422                	sd	s0,8(sp)
    80004000:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004002:	411c                	lw	a5,0(a0)
    80004004:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004006:	415c                	lw	a5,4(a0)
    80004008:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000400a:	04451783          	lh	a5,68(a0)
    8000400e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004012:	04a51783          	lh	a5,74(a0)
    80004016:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000401a:	04c56783          	lwu	a5,76(a0)
    8000401e:	e99c                	sd	a5,16(a1)
}
    80004020:	6422                	ld	s0,8(sp)
    80004022:	0141                	addi	sp,sp,16
    80004024:	8082                	ret

0000000080004026 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004026:	457c                	lw	a5,76(a0)
    80004028:	10d7e563          	bltu	a5,a3,80004132 <readi+0x10c>
{
    8000402c:	7159                	addi	sp,sp,-112
    8000402e:	f486                	sd	ra,104(sp)
    80004030:	f0a2                	sd	s0,96(sp)
    80004032:	eca6                	sd	s1,88(sp)
    80004034:	e0d2                	sd	s4,64(sp)
    80004036:	fc56                	sd	s5,56(sp)
    80004038:	f85a                	sd	s6,48(sp)
    8000403a:	f45e                	sd	s7,40(sp)
    8000403c:	1880                	addi	s0,sp,112
    8000403e:	8b2a                	mv	s6,a0
    80004040:	8bae                	mv	s7,a1
    80004042:	8a32                	mv	s4,a2
    80004044:	84b6                	mv	s1,a3
    80004046:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004048:	9f35                	addw	a4,a4,a3
    return 0;
    8000404a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000404c:	0cd76a63          	bltu	a4,a3,80004120 <readi+0xfa>
    80004050:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80004052:	00e7f463          	bgeu	a5,a4,8000405a <readi+0x34>
    n = ip->size - off;
    80004056:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000405a:	0a0a8963          	beqz	s5,8000410c <readi+0xe6>
    8000405e:	e8ca                	sd	s2,80(sp)
    80004060:	f062                	sd	s8,32(sp)
    80004062:	ec66                	sd	s9,24(sp)
    80004064:	e86a                	sd	s10,16(sp)
    80004066:	e46e                	sd	s11,8(sp)
    80004068:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000406e:	5c7d                	li	s8,-1
    80004070:	a82d                	j	800040aa <readi+0x84>
    80004072:	020d1d93          	slli	s11,s10,0x20
    80004076:	020ddd93          	srli	s11,s11,0x20
    8000407a:	05890613          	addi	a2,s2,88
    8000407e:	86ee                	mv	a3,s11
    80004080:	963a                	add	a2,a2,a4
    80004082:	85d2                	mv	a1,s4
    80004084:	855e                	mv	a0,s7
    80004086:	ffffe097          	auipc	ra,0xffffe
    8000408a:	538080e7          	jalr	1336(ra) # 800025be <either_copyout>
    8000408e:	05850d63          	beq	a0,s8,800040e8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004092:	854a                	mv	a0,s2
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	5d6080e7          	jalr	1494(ra) # 8000366a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000409c:	013d09bb          	addw	s3,s10,s3
    800040a0:	009d04bb          	addw	s1,s10,s1
    800040a4:	9a6e                	add	s4,s4,s11
    800040a6:	0559fd63          	bgeu	s3,s5,80004100 <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    800040aa:	00a4d59b          	srliw	a1,s1,0xa
    800040ae:	855a                	mv	a0,s6
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	88e080e7          	jalr	-1906(ra) # 8000393e <bmap>
    800040b8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040bc:	c9b1                	beqz	a1,80004110 <readi+0xea>
    bp = bread(ip->dev, addr);
    800040be:	000b2503          	lw	a0,0(s6)
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	478080e7          	jalr	1144(ra) # 8000353a <bread>
    800040ca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040cc:	3ff4f713          	andi	a4,s1,1023
    800040d0:	40ec87bb          	subw	a5,s9,a4
    800040d4:	413a86bb          	subw	a3,s5,s3
    800040d8:	8d3e                	mv	s10,a5
    800040da:	2781                	sext.w	a5,a5
    800040dc:	0006861b          	sext.w	a2,a3
    800040e0:	f8f679e3          	bgeu	a2,a5,80004072 <readi+0x4c>
    800040e4:	8d36                	mv	s10,a3
    800040e6:	b771                	j	80004072 <readi+0x4c>
      brelse(bp);
    800040e8:	854a                	mv	a0,s2
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	580080e7          	jalr	1408(ra) # 8000366a <brelse>
      tot = -1;
    800040f2:	59fd                	li	s3,-1
      break;
    800040f4:	6946                	ld	s2,80(sp)
    800040f6:	7c02                	ld	s8,32(sp)
    800040f8:	6ce2                	ld	s9,24(sp)
    800040fa:	6d42                	ld	s10,16(sp)
    800040fc:	6da2                	ld	s11,8(sp)
    800040fe:	a831                	j	8000411a <readi+0xf4>
    80004100:	6946                	ld	s2,80(sp)
    80004102:	7c02                	ld	s8,32(sp)
    80004104:	6ce2                	ld	s9,24(sp)
    80004106:	6d42                	ld	s10,16(sp)
    80004108:	6da2                	ld	s11,8(sp)
    8000410a:	a801                	j	8000411a <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000410c:	89d6                	mv	s3,s5
    8000410e:	a031                	j	8000411a <readi+0xf4>
    80004110:	6946                	ld	s2,80(sp)
    80004112:	7c02                	ld	s8,32(sp)
    80004114:	6ce2                	ld	s9,24(sp)
    80004116:	6d42                	ld	s10,16(sp)
    80004118:	6da2                	ld	s11,8(sp)
  }
  return tot;
    8000411a:	0009851b          	sext.w	a0,s3
    8000411e:	69a6                	ld	s3,72(sp)
}
    80004120:	70a6                	ld	ra,104(sp)
    80004122:	7406                	ld	s0,96(sp)
    80004124:	64e6                	ld	s1,88(sp)
    80004126:	6a06                	ld	s4,64(sp)
    80004128:	7ae2                	ld	s5,56(sp)
    8000412a:	7b42                	ld	s6,48(sp)
    8000412c:	7ba2                	ld	s7,40(sp)
    8000412e:	6165                	addi	sp,sp,112
    80004130:	8082                	ret
    return 0;
    80004132:	4501                	li	a0,0
}
    80004134:	8082                	ret

0000000080004136 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004136:	457c                	lw	a5,76(a0)
    80004138:	10d7ee63          	bltu	a5,a3,80004254 <writei+0x11e>
{
    8000413c:	7159                	addi	sp,sp,-112
    8000413e:	f486                	sd	ra,104(sp)
    80004140:	f0a2                	sd	s0,96(sp)
    80004142:	e8ca                	sd	s2,80(sp)
    80004144:	e0d2                	sd	s4,64(sp)
    80004146:	fc56                	sd	s5,56(sp)
    80004148:	f85a                	sd	s6,48(sp)
    8000414a:	f45e                	sd	s7,40(sp)
    8000414c:	1880                	addi	s0,sp,112
    8000414e:	8aaa                	mv	s5,a0
    80004150:	8bae                	mv	s7,a1
    80004152:	8a32                	mv	s4,a2
    80004154:	8936                	mv	s2,a3
    80004156:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004158:	00e687bb          	addw	a5,a3,a4
    8000415c:	0ed7ee63          	bltu	a5,a3,80004258 <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004160:	00043737          	lui	a4,0x43
    80004164:	0ef76c63          	bltu	a4,a5,8000425c <writei+0x126>
    80004168:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000416a:	0c0b0d63          	beqz	s6,80004244 <writei+0x10e>
    8000416e:	eca6                	sd	s1,88(sp)
    80004170:	f062                	sd	s8,32(sp)
    80004172:	ec66                	sd	s9,24(sp)
    80004174:	e86a                	sd	s10,16(sp)
    80004176:	e46e                	sd	s11,8(sp)
    80004178:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000417a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000417e:	5c7d                	li	s8,-1
    80004180:	a091                	j	800041c4 <writei+0x8e>
    80004182:	020d1d93          	slli	s11,s10,0x20
    80004186:	020ddd93          	srli	s11,s11,0x20
    8000418a:	05848513          	addi	a0,s1,88
    8000418e:	86ee                	mv	a3,s11
    80004190:	8652                	mv	a2,s4
    80004192:	85de                	mv	a1,s7
    80004194:	953a                	add	a0,a0,a4
    80004196:	ffffe097          	auipc	ra,0xffffe
    8000419a:	480080e7          	jalr	1152(ra) # 80002616 <either_copyin>
    8000419e:	07850263          	beq	a0,s8,80004202 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041a2:	8526                	mv	a0,s1
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	770080e7          	jalr	1904(ra) # 80004914 <log_write>
    brelse(bp);
    800041ac:	8526                	mv	a0,s1
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	4bc080e7          	jalr	1212(ra) # 8000366a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041b6:	013d09bb          	addw	s3,s10,s3
    800041ba:	012d093b          	addw	s2,s10,s2
    800041be:	9a6e                	add	s4,s4,s11
    800041c0:	0569f663          	bgeu	s3,s6,8000420c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041c4:	00a9559b          	srliw	a1,s2,0xa
    800041c8:	8556                	mv	a0,s5
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	774080e7          	jalr	1908(ra) # 8000393e <bmap>
    800041d2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041d6:	c99d                	beqz	a1,8000420c <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041d8:	000aa503          	lw	a0,0(s5)
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	35e080e7          	jalr	862(ra) # 8000353a <bread>
    800041e4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e6:	3ff97713          	andi	a4,s2,1023
    800041ea:	40ec87bb          	subw	a5,s9,a4
    800041ee:	413b06bb          	subw	a3,s6,s3
    800041f2:	8d3e                	mv	s10,a5
    800041f4:	2781                	sext.w	a5,a5
    800041f6:	0006861b          	sext.w	a2,a3
    800041fa:	f8f674e3          	bgeu	a2,a5,80004182 <writei+0x4c>
    800041fe:	8d36                	mv	s10,a3
    80004200:	b749                	j	80004182 <writei+0x4c>
      brelse(bp);
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	466080e7          	jalr	1126(ra) # 8000366a <brelse>
  }

  if(off > ip->size)
    8000420c:	04caa783          	lw	a5,76(s5)
    80004210:	0327fc63          	bgeu	a5,s2,80004248 <writei+0x112>
    ip->size = off;
    80004214:	052aa623          	sw	s2,76(s5)
    80004218:	64e6                	ld	s1,88(sp)
    8000421a:	7c02                	ld	s8,32(sp)
    8000421c:	6ce2                	ld	s9,24(sp)
    8000421e:	6d42                	ld	s10,16(sp)
    80004220:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004222:	8556                	mv	a0,s5
    80004224:	00000097          	auipc	ra,0x0
    80004228:	a7e080e7          	jalr	-1410(ra) # 80003ca2 <iupdate>

  return tot;
    8000422c:	0009851b          	sext.w	a0,s3
    80004230:	69a6                	ld	s3,72(sp)
}
    80004232:	70a6                	ld	ra,104(sp)
    80004234:	7406                	ld	s0,96(sp)
    80004236:	6946                	ld	s2,80(sp)
    80004238:	6a06                	ld	s4,64(sp)
    8000423a:	7ae2                	ld	s5,56(sp)
    8000423c:	7b42                	ld	s6,48(sp)
    8000423e:	7ba2                	ld	s7,40(sp)
    80004240:	6165                	addi	sp,sp,112
    80004242:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004244:	89da                	mv	s3,s6
    80004246:	bff1                	j	80004222 <writei+0xec>
    80004248:	64e6                	ld	s1,88(sp)
    8000424a:	7c02                	ld	s8,32(sp)
    8000424c:	6ce2                	ld	s9,24(sp)
    8000424e:	6d42                	ld	s10,16(sp)
    80004250:	6da2                	ld	s11,8(sp)
    80004252:	bfc1                	j	80004222 <writei+0xec>
    return -1;
    80004254:	557d                	li	a0,-1
}
    80004256:	8082                	ret
    return -1;
    80004258:	557d                	li	a0,-1
    8000425a:	bfe1                	j	80004232 <writei+0xfc>
    return -1;
    8000425c:	557d                	li	a0,-1
    8000425e:	bfd1                	j	80004232 <writei+0xfc>

0000000080004260 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004260:	1141                	addi	sp,sp,-16
    80004262:	e406                	sd	ra,8(sp)
    80004264:	e022                	sd	s0,0(sp)
    80004266:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004268:	4639                	li	a2,14
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	b9a080e7          	jalr	-1126(ra) # 80000e04 <strncmp>
}
    80004272:	60a2                	ld	ra,8(sp)
    80004274:	6402                	ld	s0,0(sp)
    80004276:	0141                	addi	sp,sp,16
    80004278:	8082                	ret

000000008000427a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000427a:	7139                	addi	sp,sp,-64
    8000427c:	fc06                	sd	ra,56(sp)
    8000427e:	f822                	sd	s0,48(sp)
    80004280:	f426                	sd	s1,40(sp)
    80004282:	f04a                	sd	s2,32(sp)
    80004284:	ec4e                	sd	s3,24(sp)
    80004286:	e852                	sd	s4,16(sp)
    80004288:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000428a:	04451703          	lh	a4,68(a0)
    8000428e:	4785                	li	a5,1
    80004290:	00f71a63          	bne	a4,a5,800042a4 <dirlookup+0x2a>
    80004294:	892a                	mv	s2,a0
    80004296:	89ae                	mv	s3,a1
    80004298:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000429a:	457c                	lw	a5,76(a0)
    8000429c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000429e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a0:	e79d                	bnez	a5,800042ce <dirlookup+0x54>
    800042a2:	a8a5                	j	8000431a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042a4:	00004517          	auipc	a0,0x4
    800042a8:	23450513          	addi	a0,a0,564 # 800084d8 <etext+0x4d8>
    800042ac:	ffffc097          	auipc	ra,0xffffc
    800042b0:	2b4080e7          	jalr	692(ra) # 80000560 <panic>
      panic("dirlookup read");
    800042b4:	00004517          	auipc	a0,0x4
    800042b8:	23c50513          	addi	a0,a0,572 # 800084f0 <etext+0x4f0>
    800042bc:	ffffc097          	auipc	ra,0xffffc
    800042c0:	2a4080e7          	jalr	676(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c4:	24c1                	addiw	s1,s1,16
    800042c6:	04c92783          	lw	a5,76(s2)
    800042ca:	04f4f763          	bgeu	s1,a5,80004318 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ce:	4741                	li	a4,16
    800042d0:	86a6                	mv	a3,s1
    800042d2:	fc040613          	addi	a2,s0,-64
    800042d6:	4581                	li	a1,0
    800042d8:	854a                	mv	a0,s2
    800042da:	00000097          	auipc	ra,0x0
    800042de:	d4c080e7          	jalr	-692(ra) # 80004026 <readi>
    800042e2:	47c1                	li	a5,16
    800042e4:	fcf518e3          	bne	a0,a5,800042b4 <dirlookup+0x3a>
    if(de.inum == 0)
    800042e8:	fc045783          	lhu	a5,-64(s0)
    800042ec:	dfe1                	beqz	a5,800042c4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042ee:	fc240593          	addi	a1,s0,-62
    800042f2:	854e                	mv	a0,s3
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	f6c080e7          	jalr	-148(ra) # 80004260 <namecmp>
    800042fc:	f561                	bnez	a0,800042c4 <dirlookup+0x4a>
      if(poff)
    800042fe:	000a0463          	beqz	s4,80004306 <dirlookup+0x8c>
        *poff = off;
    80004302:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004306:	fc045583          	lhu	a1,-64(s0)
    8000430a:	00092503          	lw	a0,0(s2)
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	720080e7          	jalr	1824(ra) # 80003a2e <iget>
    80004316:	a011                	j	8000431a <dirlookup+0xa0>
  return 0;
    80004318:	4501                	li	a0,0
}
    8000431a:	70e2                	ld	ra,56(sp)
    8000431c:	7442                	ld	s0,48(sp)
    8000431e:	74a2                	ld	s1,40(sp)
    80004320:	7902                	ld	s2,32(sp)
    80004322:	69e2                	ld	s3,24(sp)
    80004324:	6a42                	ld	s4,16(sp)
    80004326:	6121                	addi	sp,sp,64
    80004328:	8082                	ret

000000008000432a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000432a:	711d                	addi	sp,sp,-96
    8000432c:	ec86                	sd	ra,88(sp)
    8000432e:	e8a2                	sd	s0,80(sp)
    80004330:	e4a6                	sd	s1,72(sp)
    80004332:	e0ca                	sd	s2,64(sp)
    80004334:	fc4e                	sd	s3,56(sp)
    80004336:	f852                	sd	s4,48(sp)
    80004338:	f456                	sd	s5,40(sp)
    8000433a:	f05a                	sd	s6,32(sp)
    8000433c:	ec5e                	sd	s7,24(sp)
    8000433e:	e862                	sd	s8,16(sp)
    80004340:	e466                	sd	s9,8(sp)
    80004342:	1080                	addi	s0,sp,96
    80004344:	84aa                	mv	s1,a0
    80004346:	8b2e                	mv	s6,a1
    80004348:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000434a:	00054703          	lbu	a4,0(a0)
    8000434e:	02f00793          	li	a5,47
    80004352:	02f70263          	beq	a4,a5,80004376 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	6f4080e7          	jalr	1780(ra) # 80001a4a <myproc>
    8000435e:	20853503          	ld	a0,520(a0)
    80004362:	00000097          	auipc	ra,0x0
    80004366:	9ce080e7          	jalr	-1586(ra) # 80003d30 <idup>
    8000436a:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000436c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004370:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004372:	4b85                	li	s7,1
    80004374:	a875                	j	80004430 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004376:	4585                	li	a1,1
    80004378:	4505                	li	a0,1
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	6b4080e7          	jalr	1716(ra) # 80003a2e <iget>
    80004382:	8a2a                	mv	s4,a0
    80004384:	b7e5                	j	8000436c <namex+0x42>
      iunlockput(ip);
    80004386:	8552                	mv	a0,s4
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	c4c080e7          	jalr	-948(ra) # 80003fd4 <iunlockput>
      return 0;
    80004390:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004392:	8552                	mv	a0,s4
    80004394:	60e6                	ld	ra,88(sp)
    80004396:	6446                	ld	s0,80(sp)
    80004398:	64a6                	ld	s1,72(sp)
    8000439a:	6906                	ld	s2,64(sp)
    8000439c:	79e2                	ld	s3,56(sp)
    8000439e:	7a42                	ld	s4,48(sp)
    800043a0:	7aa2                	ld	s5,40(sp)
    800043a2:	7b02                	ld	s6,32(sp)
    800043a4:	6be2                	ld	s7,24(sp)
    800043a6:	6c42                	ld	s8,16(sp)
    800043a8:	6ca2                	ld	s9,8(sp)
    800043aa:	6125                	addi	sp,sp,96
    800043ac:	8082                	ret
      iunlock(ip);
    800043ae:	8552                	mv	a0,s4
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	a84080e7          	jalr	-1404(ra) # 80003e34 <iunlock>
      return ip;
    800043b8:	bfe9                	j	80004392 <namex+0x68>
      iunlockput(ip);
    800043ba:	8552                	mv	a0,s4
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	c18080e7          	jalr	-1000(ra) # 80003fd4 <iunlockput>
      return 0;
    800043c4:	8a4e                	mv	s4,s3
    800043c6:	b7f1                	j	80004392 <namex+0x68>
  len = path - s;
    800043c8:	40998633          	sub	a2,s3,s1
    800043cc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043d0:	099c5863          	bge	s8,s9,80004460 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800043d4:	4639                	li	a2,14
    800043d6:	85a6                	mv	a1,s1
    800043d8:	8556                	mv	a0,s5
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	9b6080e7          	jalr	-1610(ra) # 80000d90 <memmove>
    800043e2:	84ce                	mv	s1,s3
  while(*path == '/')
    800043e4:	0004c783          	lbu	a5,0(s1)
    800043e8:	01279763          	bne	a5,s2,800043f6 <namex+0xcc>
    path++;
    800043ec:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043ee:	0004c783          	lbu	a5,0(s1)
    800043f2:	ff278de3          	beq	a5,s2,800043ec <namex+0xc2>
    ilock(ip);
    800043f6:	8552                	mv	a0,s4
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	976080e7          	jalr	-1674(ra) # 80003d6e <ilock>
    if(ip->type != T_DIR){
    80004400:	044a1783          	lh	a5,68(s4)
    80004404:	f97791e3          	bne	a5,s7,80004386 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004408:	000b0563          	beqz	s6,80004412 <namex+0xe8>
    8000440c:	0004c783          	lbu	a5,0(s1)
    80004410:	dfd9                	beqz	a5,800043ae <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004412:	4601                	li	a2,0
    80004414:	85d6                	mv	a1,s5
    80004416:	8552                	mv	a0,s4
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	e62080e7          	jalr	-414(ra) # 8000427a <dirlookup>
    80004420:	89aa                	mv	s3,a0
    80004422:	dd41                	beqz	a0,800043ba <namex+0x90>
    iunlockput(ip);
    80004424:	8552                	mv	a0,s4
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	bae080e7          	jalr	-1106(ra) # 80003fd4 <iunlockput>
    ip = next;
    8000442e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004430:	0004c783          	lbu	a5,0(s1)
    80004434:	01279763          	bne	a5,s2,80004442 <namex+0x118>
    path++;
    80004438:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000443a:	0004c783          	lbu	a5,0(s1)
    8000443e:	ff278de3          	beq	a5,s2,80004438 <namex+0x10e>
  if(*path == 0)
    80004442:	cb9d                	beqz	a5,80004478 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004444:	0004c783          	lbu	a5,0(s1)
    80004448:	89a6                	mv	s3,s1
  len = path - s;
    8000444a:	4c81                	li	s9,0
    8000444c:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000444e:	01278963          	beq	a5,s2,80004460 <namex+0x136>
    80004452:	dbbd                	beqz	a5,800043c8 <namex+0x9e>
    path++;
    80004454:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004456:	0009c783          	lbu	a5,0(s3)
    8000445a:	ff279ce3          	bne	a5,s2,80004452 <namex+0x128>
    8000445e:	b7ad                	j	800043c8 <namex+0x9e>
    memmove(name, s, len);
    80004460:	2601                	sext.w	a2,a2
    80004462:	85a6                	mv	a1,s1
    80004464:	8556                	mv	a0,s5
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	92a080e7          	jalr	-1750(ra) # 80000d90 <memmove>
    name[len] = 0;
    8000446e:	9cd6                	add	s9,s9,s5
    80004470:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004474:	84ce                	mv	s1,s3
    80004476:	b7bd                	j	800043e4 <namex+0xba>
  if(nameiparent){
    80004478:	f00b0de3          	beqz	s6,80004392 <namex+0x68>
    iput(ip);
    8000447c:	8552                	mv	a0,s4
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	aae080e7          	jalr	-1362(ra) # 80003f2c <iput>
    return 0;
    80004486:	4a01                	li	s4,0
    80004488:	b729                	j	80004392 <namex+0x68>

000000008000448a <dirlink>:
{
    8000448a:	7139                	addi	sp,sp,-64
    8000448c:	fc06                	sd	ra,56(sp)
    8000448e:	f822                	sd	s0,48(sp)
    80004490:	f04a                	sd	s2,32(sp)
    80004492:	ec4e                	sd	s3,24(sp)
    80004494:	e852                	sd	s4,16(sp)
    80004496:	0080                	addi	s0,sp,64
    80004498:	892a                	mv	s2,a0
    8000449a:	8a2e                	mv	s4,a1
    8000449c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000449e:	4601                	li	a2,0
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	dda080e7          	jalr	-550(ra) # 8000427a <dirlookup>
    800044a8:	ed25                	bnez	a0,80004520 <dirlink+0x96>
    800044aa:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ac:	04c92483          	lw	s1,76(s2)
    800044b0:	c49d                	beqz	s1,800044de <dirlink+0x54>
    800044b2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044b4:	4741                	li	a4,16
    800044b6:	86a6                	mv	a3,s1
    800044b8:	fc040613          	addi	a2,s0,-64
    800044bc:	4581                	li	a1,0
    800044be:	854a                	mv	a0,s2
    800044c0:	00000097          	auipc	ra,0x0
    800044c4:	b66080e7          	jalr	-1178(ra) # 80004026 <readi>
    800044c8:	47c1                	li	a5,16
    800044ca:	06f51163          	bne	a0,a5,8000452c <dirlink+0xa2>
    if(de.inum == 0)
    800044ce:	fc045783          	lhu	a5,-64(s0)
    800044d2:	c791                	beqz	a5,800044de <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d4:	24c1                	addiw	s1,s1,16
    800044d6:	04c92783          	lw	a5,76(s2)
    800044da:	fcf4ede3          	bltu	s1,a5,800044b4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044de:	4639                	li	a2,14
    800044e0:	85d2                	mv	a1,s4
    800044e2:	fc240513          	addi	a0,s0,-62
    800044e6:	ffffd097          	auipc	ra,0xffffd
    800044ea:	954080e7          	jalr	-1708(ra) # 80000e3a <strncpy>
  de.inum = inum;
    800044ee:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044f2:	4741                	li	a4,16
    800044f4:	86a6                	mv	a3,s1
    800044f6:	fc040613          	addi	a2,s0,-64
    800044fa:	4581                	li	a1,0
    800044fc:	854a                	mv	a0,s2
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	c38080e7          	jalr	-968(ra) # 80004136 <writei>
    80004506:	1541                	addi	a0,a0,-16
    80004508:	00a03533          	snez	a0,a0
    8000450c:	40a00533          	neg	a0,a0
    80004510:	74a2                	ld	s1,40(sp)
}
    80004512:	70e2                	ld	ra,56(sp)
    80004514:	7442                	ld	s0,48(sp)
    80004516:	7902                	ld	s2,32(sp)
    80004518:	69e2                	ld	s3,24(sp)
    8000451a:	6a42                	ld	s4,16(sp)
    8000451c:	6121                	addi	sp,sp,64
    8000451e:	8082                	ret
    iput(ip);
    80004520:	00000097          	auipc	ra,0x0
    80004524:	a0c080e7          	jalr	-1524(ra) # 80003f2c <iput>
    return -1;
    80004528:	557d                	li	a0,-1
    8000452a:	b7e5                	j	80004512 <dirlink+0x88>
      panic("dirlink read");
    8000452c:	00004517          	auipc	a0,0x4
    80004530:	fd450513          	addi	a0,a0,-44 # 80008500 <etext+0x500>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	02c080e7          	jalr	44(ra) # 80000560 <panic>

000000008000453c <namei>:

struct inode*
namei(char *path)
{
    8000453c:	1101                	addi	sp,sp,-32
    8000453e:	ec06                	sd	ra,24(sp)
    80004540:	e822                	sd	s0,16(sp)
    80004542:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004544:	fe040613          	addi	a2,s0,-32
    80004548:	4581                	li	a1,0
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	de0080e7          	jalr	-544(ra) # 8000432a <namex>
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	6105                	addi	sp,sp,32
    80004558:	8082                	ret

000000008000455a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000455a:	1141                	addi	sp,sp,-16
    8000455c:	e406                	sd	ra,8(sp)
    8000455e:	e022                	sd	s0,0(sp)
    80004560:	0800                	addi	s0,sp,16
    80004562:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004564:	4585                	li	a1,1
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	dc4080e7          	jalr	-572(ra) # 8000432a <namex>
}
    8000456e:	60a2                	ld	ra,8(sp)
    80004570:	6402                	ld	s0,0(sp)
    80004572:	0141                	addi	sp,sp,16
    80004574:	8082                	ret

0000000080004576 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004576:	1101                	addi	sp,sp,-32
    80004578:	ec06                	sd	ra,24(sp)
    8000457a:	e822                	sd	s0,16(sp)
    8000457c:	e426                	sd	s1,8(sp)
    8000457e:	e04a                	sd	s2,0(sp)
    80004580:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004582:	0001f917          	auipc	s2,0x1f
    80004586:	79e90913          	addi	s2,s2,1950 # 80023d20 <log>
    8000458a:	01892583          	lw	a1,24(s2)
    8000458e:	02892503          	lw	a0,40(s2)
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	fa8080e7          	jalr	-88(ra) # 8000353a <bread>
    8000459a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000459c:	02c92603          	lw	a2,44(s2)
    800045a0:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045a2:	00c05f63          	blez	a2,800045c0 <write_head+0x4a>
    800045a6:	0001f717          	auipc	a4,0x1f
    800045aa:	7aa70713          	addi	a4,a4,1962 # 80023d50 <log+0x30>
    800045ae:	87aa                	mv	a5,a0
    800045b0:	060a                	slli	a2,a2,0x2
    800045b2:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800045b4:	4314                	lw	a3,0(a4)
    800045b6:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800045b8:	0711                	addi	a4,a4,4
    800045ba:	0791                	addi	a5,a5,4
    800045bc:	fec79ce3          	bne	a5,a2,800045b4 <write_head+0x3e>
  }
  bwrite(buf);
    800045c0:	8526                	mv	a0,s1
    800045c2:	fffff097          	auipc	ra,0xfffff
    800045c6:	06a080e7          	jalr	106(ra) # 8000362c <bwrite>
  brelse(buf);
    800045ca:	8526                	mv	a0,s1
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	09e080e7          	jalr	158(ra) # 8000366a <brelse>
}
    800045d4:	60e2                	ld	ra,24(sp)
    800045d6:	6442                	ld	s0,16(sp)
    800045d8:	64a2                	ld	s1,8(sp)
    800045da:	6902                	ld	s2,0(sp)
    800045dc:	6105                	addi	sp,sp,32
    800045de:	8082                	ret

00000000800045e0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e0:	0001f797          	auipc	a5,0x1f
    800045e4:	76c7a783          	lw	a5,1900(a5) # 80023d4c <log+0x2c>
    800045e8:	0af05d63          	blez	a5,800046a2 <install_trans+0xc2>
{
    800045ec:	7139                	addi	sp,sp,-64
    800045ee:	fc06                	sd	ra,56(sp)
    800045f0:	f822                	sd	s0,48(sp)
    800045f2:	f426                	sd	s1,40(sp)
    800045f4:	f04a                	sd	s2,32(sp)
    800045f6:	ec4e                	sd	s3,24(sp)
    800045f8:	e852                	sd	s4,16(sp)
    800045fa:	e456                	sd	s5,8(sp)
    800045fc:	e05a                	sd	s6,0(sp)
    800045fe:	0080                	addi	s0,sp,64
    80004600:	8b2a                	mv	s6,a0
    80004602:	0001fa97          	auipc	s5,0x1f
    80004606:	74ea8a93          	addi	s5,s5,1870 # 80023d50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000460a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000460c:	0001f997          	auipc	s3,0x1f
    80004610:	71498993          	addi	s3,s3,1812 # 80023d20 <log>
    80004614:	a00d                	j	80004636 <install_trans+0x56>
    brelse(lbuf);
    80004616:	854a                	mv	a0,s2
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	052080e7          	jalr	82(ra) # 8000366a <brelse>
    brelse(dbuf);
    80004620:	8526                	mv	a0,s1
    80004622:	fffff097          	auipc	ra,0xfffff
    80004626:	048080e7          	jalr	72(ra) # 8000366a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000462a:	2a05                	addiw	s4,s4,1
    8000462c:	0a91                	addi	s5,s5,4
    8000462e:	02c9a783          	lw	a5,44(s3)
    80004632:	04fa5e63          	bge	s4,a5,8000468e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004636:	0189a583          	lw	a1,24(s3)
    8000463a:	014585bb          	addw	a1,a1,s4
    8000463e:	2585                	addiw	a1,a1,1
    80004640:	0289a503          	lw	a0,40(s3)
    80004644:	fffff097          	auipc	ra,0xfffff
    80004648:	ef6080e7          	jalr	-266(ra) # 8000353a <bread>
    8000464c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000464e:	000aa583          	lw	a1,0(s5)
    80004652:	0289a503          	lw	a0,40(s3)
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	ee4080e7          	jalr	-284(ra) # 8000353a <bread>
    8000465e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004660:	40000613          	li	a2,1024
    80004664:	05890593          	addi	a1,s2,88
    80004668:	05850513          	addi	a0,a0,88
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	724080e7          	jalr	1828(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004674:	8526                	mv	a0,s1
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	fb6080e7          	jalr	-74(ra) # 8000362c <bwrite>
    if(recovering == 0)
    8000467e:	f80b1ce3          	bnez	s6,80004616 <install_trans+0x36>
      bunpin(dbuf);
    80004682:	8526                	mv	a0,s1
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	0be080e7          	jalr	190(ra) # 80003742 <bunpin>
    8000468c:	b769                	j	80004616 <install_trans+0x36>
}
    8000468e:	70e2                	ld	ra,56(sp)
    80004690:	7442                	ld	s0,48(sp)
    80004692:	74a2                	ld	s1,40(sp)
    80004694:	7902                	ld	s2,32(sp)
    80004696:	69e2                	ld	s3,24(sp)
    80004698:	6a42                	ld	s4,16(sp)
    8000469a:	6aa2                	ld	s5,8(sp)
    8000469c:	6b02                	ld	s6,0(sp)
    8000469e:	6121                	addi	sp,sp,64
    800046a0:	8082                	ret
    800046a2:	8082                	ret

00000000800046a4 <initlog>:
{
    800046a4:	7179                	addi	sp,sp,-48
    800046a6:	f406                	sd	ra,40(sp)
    800046a8:	f022                	sd	s0,32(sp)
    800046aa:	ec26                	sd	s1,24(sp)
    800046ac:	e84a                	sd	s2,16(sp)
    800046ae:	e44e                	sd	s3,8(sp)
    800046b0:	1800                	addi	s0,sp,48
    800046b2:	892a                	mv	s2,a0
    800046b4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046b6:	0001f497          	auipc	s1,0x1f
    800046ba:	66a48493          	addi	s1,s1,1642 # 80023d20 <log>
    800046be:	00004597          	auipc	a1,0x4
    800046c2:	e5258593          	addi	a1,a1,-430 # 80008510 <etext+0x510>
    800046c6:	8526                	mv	a0,s1
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	4e0080e7          	jalr	1248(ra) # 80000ba8 <initlock>
  log.start = sb->logstart;
    800046d0:	0149a583          	lw	a1,20(s3)
    800046d4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046d6:	0109a783          	lw	a5,16(s3)
    800046da:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046dc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046e0:	854a                	mv	a0,s2
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	e58080e7          	jalr	-424(ra) # 8000353a <bread>
  log.lh.n = lh->n;
    800046ea:	4d30                	lw	a2,88(a0)
    800046ec:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046ee:	00c05f63          	blez	a2,8000470c <initlog+0x68>
    800046f2:	87aa                	mv	a5,a0
    800046f4:	0001f717          	auipc	a4,0x1f
    800046f8:	65c70713          	addi	a4,a4,1628 # 80023d50 <log+0x30>
    800046fc:	060a                	slli	a2,a2,0x2
    800046fe:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004700:	4ff4                	lw	a3,92(a5)
    80004702:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004704:	0791                	addi	a5,a5,4
    80004706:	0711                	addi	a4,a4,4
    80004708:	fec79ce3          	bne	a5,a2,80004700 <initlog+0x5c>
  brelse(buf);
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	f5e080e7          	jalr	-162(ra) # 8000366a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004714:	4505                	li	a0,1
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	eca080e7          	jalr	-310(ra) # 800045e0 <install_trans>
  log.lh.n = 0;
    8000471e:	0001f797          	auipc	a5,0x1f
    80004722:	6207a723          	sw	zero,1582(a5) # 80023d4c <log+0x2c>
  write_head(); // clear the log
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	e50080e7          	jalr	-432(ra) # 80004576 <write_head>
}
    8000472e:	70a2                	ld	ra,40(sp)
    80004730:	7402                	ld	s0,32(sp)
    80004732:	64e2                	ld	s1,24(sp)
    80004734:	6942                	ld	s2,16(sp)
    80004736:	69a2                	ld	s3,8(sp)
    80004738:	6145                	addi	sp,sp,48
    8000473a:	8082                	ret

000000008000473c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000473c:	1101                	addi	sp,sp,-32
    8000473e:	ec06                	sd	ra,24(sp)
    80004740:	e822                	sd	s0,16(sp)
    80004742:	e426                	sd	s1,8(sp)
    80004744:	e04a                	sd	s2,0(sp)
    80004746:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004748:	0001f517          	auipc	a0,0x1f
    8000474c:	5d850513          	addi	a0,a0,1496 # 80023d20 <log>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	4e8080e7          	jalr	1256(ra) # 80000c38 <acquire>
  while(1){
    if(log.committing){
    80004758:	0001f497          	auipc	s1,0x1f
    8000475c:	5c848493          	addi	s1,s1,1480 # 80023d20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004760:	4979                	li	s2,30
    80004762:	a039                	j	80004770 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004764:	85a6                	mv	a1,s1
    80004766:	8526                	mv	a0,s1
    80004768:	ffffe097          	auipc	ra,0xffffe
    8000476c:	a20080e7          	jalr	-1504(ra) # 80002188 <sleep>
    if(log.committing){
    80004770:	50dc                	lw	a5,36(s1)
    80004772:	fbed                	bnez	a5,80004764 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004774:	5098                	lw	a4,32(s1)
    80004776:	2705                	addiw	a4,a4,1
    80004778:	0027179b          	slliw	a5,a4,0x2
    8000477c:	9fb9                	addw	a5,a5,a4
    8000477e:	0017979b          	slliw	a5,a5,0x1
    80004782:	54d4                	lw	a3,44(s1)
    80004784:	9fb5                	addw	a5,a5,a3
    80004786:	00f95963          	bge	s2,a5,80004798 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000478a:	85a6                	mv	a1,s1
    8000478c:	8526                	mv	a0,s1
    8000478e:	ffffe097          	auipc	ra,0xffffe
    80004792:	9fa080e7          	jalr	-1542(ra) # 80002188 <sleep>
    80004796:	bfe9                	j	80004770 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004798:	0001f517          	auipc	a0,0x1f
    8000479c:	58850513          	addi	a0,a0,1416 # 80023d20 <log>
    800047a0:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	54a080e7          	jalr	1354(ra) # 80000cec <release>
      break;
    }
  }
}
    800047aa:	60e2                	ld	ra,24(sp)
    800047ac:	6442                	ld	s0,16(sp)
    800047ae:	64a2                	ld	s1,8(sp)
    800047b0:	6902                	ld	s2,0(sp)
    800047b2:	6105                	addi	sp,sp,32
    800047b4:	8082                	ret

00000000800047b6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047b6:	7139                	addi	sp,sp,-64
    800047b8:	fc06                	sd	ra,56(sp)
    800047ba:	f822                	sd	s0,48(sp)
    800047bc:	f426                	sd	s1,40(sp)
    800047be:	f04a                	sd	s2,32(sp)
    800047c0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047c2:	0001f497          	auipc	s1,0x1f
    800047c6:	55e48493          	addi	s1,s1,1374 # 80023d20 <log>
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	46c080e7          	jalr	1132(ra) # 80000c38 <acquire>
  log.outstanding -= 1;
    800047d4:	509c                	lw	a5,32(s1)
    800047d6:	37fd                	addiw	a5,a5,-1
    800047d8:	0007891b          	sext.w	s2,a5
    800047dc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047de:	50dc                	lw	a5,36(s1)
    800047e0:	e7b9                	bnez	a5,8000482e <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    800047e2:	06091163          	bnez	s2,80004844 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047e6:	0001f497          	auipc	s1,0x1f
    800047ea:	53a48493          	addi	s1,s1,1338 # 80023d20 <log>
    800047ee:	4785                	li	a5,1
    800047f0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047f2:	8526                	mv	a0,s1
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	4f8080e7          	jalr	1272(ra) # 80000cec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047fc:	54dc                	lw	a5,44(s1)
    800047fe:	06f04763          	bgtz	a5,8000486c <end_op+0xb6>
    acquire(&log.lock);
    80004802:	0001f497          	auipc	s1,0x1f
    80004806:	51e48493          	addi	s1,s1,1310 # 80023d20 <log>
    8000480a:	8526                	mv	a0,s1
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	42c080e7          	jalr	1068(ra) # 80000c38 <acquire>
    log.committing = 0;
    80004814:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004818:	8526                	mv	a0,s1
    8000481a:	ffffe097          	auipc	ra,0xffffe
    8000481e:	9d2080e7          	jalr	-1582(ra) # 800021ec <wakeup>
    release(&log.lock);
    80004822:	8526                	mv	a0,s1
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	4c8080e7          	jalr	1224(ra) # 80000cec <release>
}
    8000482c:	a815                	j	80004860 <end_op+0xaa>
    8000482e:	ec4e                	sd	s3,24(sp)
    80004830:	e852                	sd	s4,16(sp)
    80004832:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	ce450513          	addi	a0,a0,-796 # 80008518 <etext+0x518>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	d24080e7          	jalr	-732(ra) # 80000560 <panic>
    wakeup(&log);
    80004844:	0001f497          	auipc	s1,0x1f
    80004848:	4dc48493          	addi	s1,s1,1244 # 80023d20 <log>
    8000484c:	8526                	mv	a0,s1
    8000484e:	ffffe097          	auipc	ra,0xffffe
    80004852:	99e080e7          	jalr	-1634(ra) # 800021ec <wakeup>
  release(&log.lock);
    80004856:	8526                	mv	a0,s1
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	494080e7          	jalr	1172(ra) # 80000cec <release>
}
    80004860:	70e2                	ld	ra,56(sp)
    80004862:	7442                	ld	s0,48(sp)
    80004864:	74a2                	ld	s1,40(sp)
    80004866:	7902                	ld	s2,32(sp)
    80004868:	6121                	addi	sp,sp,64
    8000486a:	8082                	ret
    8000486c:	ec4e                	sd	s3,24(sp)
    8000486e:	e852                	sd	s4,16(sp)
    80004870:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004872:	0001fa97          	auipc	s5,0x1f
    80004876:	4dea8a93          	addi	s5,s5,1246 # 80023d50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000487a:	0001fa17          	auipc	s4,0x1f
    8000487e:	4a6a0a13          	addi	s4,s4,1190 # 80023d20 <log>
    80004882:	018a2583          	lw	a1,24(s4)
    80004886:	012585bb          	addw	a1,a1,s2
    8000488a:	2585                	addiw	a1,a1,1
    8000488c:	028a2503          	lw	a0,40(s4)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	caa080e7          	jalr	-854(ra) # 8000353a <bread>
    80004898:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000489a:	000aa583          	lw	a1,0(s5)
    8000489e:	028a2503          	lw	a0,40(s4)
    800048a2:	fffff097          	auipc	ra,0xfffff
    800048a6:	c98080e7          	jalr	-872(ra) # 8000353a <bread>
    800048aa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048ac:	40000613          	li	a2,1024
    800048b0:	05850593          	addi	a1,a0,88
    800048b4:	05848513          	addi	a0,s1,88
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	4d8080e7          	jalr	1240(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    800048c0:	8526                	mv	a0,s1
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	d6a080e7          	jalr	-662(ra) # 8000362c <bwrite>
    brelse(from);
    800048ca:	854e                	mv	a0,s3
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	d9e080e7          	jalr	-610(ra) # 8000366a <brelse>
    brelse(to);
    800048d4:	8526                	mv	a0,s1
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	d94080e7          	jalr	-620(ra) # 8000366a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048de:	2905                	addiw	s2,s2,1
    800048e0:	0a91                	addi	s5,s5,4
    800048e2:	02ca2783          	lw	a5,44(s4)
    800048e6:	f8f94ee3          	blt	s2,a5,80004882 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	c8c080e7          	jalr	-884(ra) # 80004576 <write_head>
    install_trans(0); // Now install writes to home locations
    800048f2:	4501                	li	a0,0
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	cec080e7          	jalr	-788(ra) # 800045e0 <install_trans>
    log.lh.n = 0;
    800048fc:	0001f797          	auipc	a5,0x1f
    80004900:	4407a823          	sw	zero,1104(a5) # 80023d4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004904:	00000097          	auipc	ra,0x0
    80004908:	c72080e7          	jalr	-910(ra) # 80004576 <write_head>
    8000490c:	69e2                	ld	s3,24(sp)
    8000490e:	6a42                	ld	s4,16(sp)
    80004910:	6aa2                	ld	s5,8(sp)
    80004912:	bdc5                	j	80004802 <end_op+0x4c>

0000000080004914 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004914:	1101                	addi	sp,sp,-32
    80004916:	ec06                	sd	ra,24(sp)
    80004918:	e822                	sd	s0,16(sp)
    8000491a:	e426                	sd	s1,8(sp)
    8000491c:	e04a                	sd	s2,0(sp)
    8000491e:	1000                	addi	s0,sp,32
    80004920:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004922:	0001f917          	auipc	s2,0x1f
    80004926:	3fe90913          	addi	s2,s2,1022 # 80023d20 <log>
    8000492a:	854a                	mv	a0,s2
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	30c080e7          	jalr	780(ra) # 80000c38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004934:	02c92603          	lw	a2,44(s2)
    80004938:	47f5                	li	a5,29
    8000493a:	06c7c563          	blt	a5,a2,800049a4 <log_write+0x90>
    8000493e:	0001f797          	auipc	a5,0x1f
    80004942:	3fe7a783          	lw	a5,1022(a5) # 80023d3c <log+0x1c>
    80004946:	37fd                	addiw	a5,a5,-1
    80004948:	04f65e63          	bge	a2,a5,800049a4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000494c:	0001f797          	auipc	a5,0x1f
    80004950:	3f47a783          	lw	a5,1012(a5) # 80023d40 <log+0x20>
    80004954:	06f05063          	blez	a5,800049b4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004958:	4781                	li	a5,0
    8000495a:	06c05563          	blez	a2,800049c4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000495e:	44cc                	lw	a1,12(s1)
    80004960:	0001f717          	auipc	a4,0x1f
    80004964:	3f070713          	addi	a4,a4,1008 # 80023d50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004968:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000496a:	4314                	lw	a3,0(a4)
    8000496c:	04b68c63          	beq	a3,a1,800049c4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004970:	2785                	addiw	a5,a5,1
    80004972:	0711                	addi	a4,a4,4
    80004974:	fef61be3          	bne	a2,a5,8000496a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004978:	0621                	addi	a2,a2,8
    8000497a:	060a                	slli	a2,a2,0x2
    8000497c:	0001f797          	auipc	a5,0x1f
    80004980:	3a478793          	addi	a5,a5,932 # 80023d20 <log>
    80004984:	97b2                	add	a5,a5,a2
    80004986:	44d8                	lw	a4,12(s1)
    80004988:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000498a:	8526                	mv	a0,s1
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	d7a080e7          	jalr	-646(ra) # 80003706 <bpin>
    log.lh.n++;
    80004994:	0001f717          	auipc	a4,0x1f
    80004998:	38c70713          	addi	a4,a4,908 # 80023d20 <log>
    8000499c:	575c                	lw	a5,44(a4)
    8000499e:	2785                	addiw	a5,a5,1
    800049a0:	d75c                	sw	a5,44(a4)
    800049a2:	a82d                	j	800049dc <log_write+0xc8>
    panic("too big a transaction");
    800049a4:	00004517          	auipc	a0,0x4
    800049a8:	b8450513          	addi	a0,a0,-1148 # 80008528 <etext+0x528>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	bb4080e7          	jalr	-1100(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    800049b4:	00004517          	auipc	a0,0x4
    800049b8:	b8c50513          	addi	a0,a0,-1140 # 80008540 <etext+0x540>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	ba4080e7          	jalr	-1116(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    800049c4:	00878693          	addi	a3,a5,8
    800049c8:	068a                	slli	a3,a3,0x2
    800049ca:	0001f717          	auipc	a4,0x1f
    800049ce:	35670713          	addi	a4,a4,854 # 80023d20 <log>
    800049d2:	9736                	add	a4,a4,a3
    800049d4:	44d4                	lw	a3,12(s1)
    800049d6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049d8:	faf609e3          	beq	a2,a5,8000498a <log_write+0x76>
  }
  release(&log.lock);
    800049dc:	0001f517          	auipc	a0,0x1f
    800049e0:	34450513          	addi	a0,a0,836 # 80023d20 <log>
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	308080e7          	jalr	776(ra) # 80000cec <release>
}
    800049ec:	60e2                	ld	ra,24(sp)
    800049ee:	6442                	ld	s0,16(sp)
    800049f0:	64a2                	ld	s1,8(sp)
    800049f2:	6902                	ld	s2,0(sp)
    800049f4:	6105                	addi	sp,sp,32
    800049f6:	8082                	ret

00000000800049f8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049f8:	1101                	addi	sp,sp,-32
    800049fa:	ec06                	sd	ra,24(sp)
    800049fc:	e822                	sd	s0,16(sp)
    800049fe:	e426                	sd	s1,8(sp)
    80004a00:	e04a                	sd	s2,0(sp)
    80004a02:	1000                	addi	s0,sp,32
    80004a04:	84aa                	mv	s1,a0
    80004a06:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a08:	00004597          	auipc	a1,0x4
    80004a0c:	b5858593          	addi	a1,a1,-1192 # 80008560 <etext+0x560>
    80004a10:	0521                	addi	a0,a0,8
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	196080e7          	jalr	406(ra) # 80000ba8 <initlock>
  lk->name = name;
    80004a1a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a1e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a22:	0204a423          	sw	zero,40(s1)
}
    80004a26:	60e2                	ld	ra,24(sp)
    80004a28:	6442                	ld	s0,16(sp)
    80004a2a:	64a2                	ld	s1,8(sp)
    80004a2c:	6902                	ld	s2,0(sp)
    80004a2e:	6105                	addi	sp,sp,32
    80004a30:	8082                	ret

0000000080004a32 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a32:	1101                	addi	sp,sp,-32
    80004a34:	ec06                	sd	ra,24(sp)
    80004a36:	e822                	sd	s0,16(sp)
    80004a38:	e426                	sd	s1,8(sp)
    80004a3a:	e04a                	sd	s2,0(sp)
    80004a3c:	1000                	addi	s0,sp,32
    80004a3e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a40:	00850913          	addi	s2,a0,8
    80004a44:	854a                	mv	a0,s2
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	1f2080e7          	jalr	498(ra) # 80000c38 <acquire>
  while (lk->locked) {
    80004a4e:	409c                	lw	a5,0(s1)
    80004a50:	cb89                	beqz	a5,80004a62 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a52:	85ca                	mv	a1,s2
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffd097          	auipc	ra,0xffffd
    80004a5a:	732080e7          	jalr	1842(ra) # 80002188 <sleep>
  while (lk->locked) {
    80004a5e:	409c                	lw	a5,0(s1)
    80004a60:	fbed                	bnez	a5,80004a52 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a62:	4785                	li	a5,1
    80004a64:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	fe4080e7          	jalr	-28(ra) # 80001a4a <myproc>
    80004a6e:	591c                	lw	a5,48(a0)
    80004a70:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a72:	854a                	mv	a0,s2
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	278080e7          	jalr	632(ra) # 80000cec <release>
}
    80004a7c:	60e2                	ld	ra,24(sp)
    80004a7e:	6442                	ld	s0,16(sp)
    80004a80:	64a2                	ld	s1,8(sp)
    80004a82:	6902                	ld	s2,0(sp)
    80004a84:	6105                	addi	sp,sp,32
    80004a86:	8082                	ret

0000000080004a88 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a88:	1101                	addi	sp,sp,-32
    80004a8a:	ec06                	sd	ra,24(sp)
    80004a8c:	e822                	sd	s0,16(sp)
    80004a8e:	e426                	sd	s1,8(sp)
    80004a90:	e04a                	sd	s2,0(sp)
    80004a92:	1000                	addi	s0,sp,32
    80004a94:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a96:	00850913          	addi	s2,a0,8
    80004a9a:	854a                	mv	a0,s2
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	19c080e7          	jalr	412(ra) # 80000c38 <acquire>
  lk->locked = 0;
    80004aa4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	73e080e7          	jalr	1854(ra) # 800021ec <wakeup>
  release(&lk->lk);
    80004ab6:	854a                	mv	a0,s2
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	234080e7          	jalr	564(ra) # 80000cec <release>
}
    80004ac0:	60e2                	ld	ra,24(sp)
    80004ac2:	6442                	ld	s0,16(sp)
    80004ac4:	64a2                	ld	s1,8(sp)
    80004ac6:	6902                	ld	s2,0(sp)
    80004ac8:	6105                	addi	sp,sp,32
    80004aca:	8082                	ret

0000000080004acc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004acc:	7179                	addi	sp,sp,-48
    80004ace:	f406                	sd	ra,40(sp)
    80004ad0:	f022                	sd	s0,32(sp)
    80004ad2:	ec26                	sd	s1,24(sp)
    80004ad4:	e84a                	sd	s2,16(sp)
    80004ad6:	1800                	addi	s0,sp,48
    80004ad8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ada:	00850913          	addi	s2,a0,8
    80004ade:	854a                	mv	a0,s2
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	158080e7          	jalr	344(ra) # 80000c38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ae8:	409c                	lw	a5,0(s1)
    80004aea:	ef91                	bnez	a5,80004b06 <holdingsleep+0x3a>
    80004aec:	4481                	li	s1,0
  release(&lk->lk);
    80004aee:	854a                	mv	a0,s2
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	1fc080e7          	jalr	508(ra) # 80000cec <release>
  return r;
}
    80004af8:	8526                	mv	a0,s1
    80004afa:	70a2                	ld	ra,40(sp)
    80004afc:	7402                	ld	s0,32(sp)
    80004afe:	64e2                	ld	s1,24(sp)
    80004b00:	6942                	ld	s2,16(sp)
    80004b02:	6145                	addi	sp,sp,48
    80004b04:	8082                	ret
    80004b06:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b08:	0284a983          	lw	s3,40(s1)
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	f3e080e7          	jalr	-194(ra) # 80001a4a <myproc>
    80004b14:	5904                	lw	s1,48(a0)
    80004b16:	413484b3          	sub	s1,s1,s3
    80004b1a:	0014b493          	seqz	s1,s1
    80004b1e:	69a2                	ld	s3,8(sp)
    80004b20:	b7f9                	j	80004aee <holdingsleep+0x22>

0000000080004b22 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b22:	1141                	addi	sp,sp,-16
    80004b24:	e406                	sd	ra,8(sp)
    80004b26:	e022                	sd	s0,0(sp)
    80004b28:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b2a:	00004597          	auipc	a1,0x4
    80004b2e:	a4658593          	addi	a1,a1,-1466 # 80008570 <etext+0x570>
    80004b32:	0001f517          	auipc	a0,0x1f
    80004b36:	33650513          	addi	a0,a0,822 # 80023e68 <ftable>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	06e080e7          	jalr	110(ra) # 80000ba8 <initlock>
}
    80004b42:	60a2                	ld	ra,8(sp)
    80004b44:	6402                	ld	s0,0(sp)
    80004b46:	0141                	addi	sp,sp,16
    80004b48:	8082                	ret

0000000080004b4a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b4a:	1101                	addi	sp,sp,-32
    80004b4c:	ec06                	sd	ra,24(sp)
    80004b4e:	e822                	sd	s0,16(sp)
    80004b50:	e426                	sd	s1,8(sp)
    80004b52:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b54:	0001f517          	auipc	a0,0x1f
    80004b58:	31450513          	addi	a0,a0,788 # 80023e68 <ftable>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	0dc080e7          	jalr	220(ra) # 80000c38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b64:	0001f497          	auipc	s1,0x1f
    80004b68:	31c48493          	addi	s1,s1,796 # 80023e80 <ftable+0x18>
    80004b6c:	00020717          	auipc	a4,0x20
    80004b70:	2b470713          	addi	a4,a4,692 # 80024e20 <disk>
    if(f->ref == 0){
    80004b74:	40dc                	lw	a5,4(s1)
    80004b76:	cf99                	beqz	a5,80004b94 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b78:	02848493          	addi	s1,s1,40
    80004b7c:	fee49ce3          	bne	s1,a4,80004b74 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b80:	0001f517          	auipc	a0,0x1f
    80004b84:	2e850513          	addi	a0,a0,744 # 80023e68 <ftable>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	164080e7          	jalr	356(ra) # 80000cec <release>
  return 0;
    80004b90:	4481                	li	s1,0
    80004b92:	a819                	j	80004ba8 <filealloc+0x5e>
      f->ref = 1;
    80004b94:	4785                	li	a5,1
    80004b96:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b98:	0001f517          	auipc	a0,0x1f
    80004b9c:	2d050513          	addi	a0,a0,720 # 80023e68 <ftable>
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	14c080e7          	jalr	332(ra) # 80000cec <release>
}
    80004ba8:	8526                	mv	a0,s1
    80004baa:	60e2                	ld	ra,24(sp)
    80004bac:	6442                	ld	s0,16(sp)
    80004bae:	64a2                	ld	s1,8(sp)
    80004bb0:	6105                	addi	sp,sp,32
    80004bb2:	8082                	ret

0000000080004bb4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bb4:	1101                	addi	sp,sp,-32
    80004bb6:	ec06                	sd	ra,24(sp)
    80004bb8:	e822                	sd	s0,16(sp)
    80004bba:	e426                	sd	s1,8(sp)
    80004bbc:	1000                	addi	s0,sp,32
    80004bbe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bc0:	0001f517          	auipc	a0,0x1f
    80004bc4:	2a850513          	addi	a0,a0,680 # 80023e68 <ftable>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	070080e7          	jalr	112(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004bd0:	40dc                	lw	a5,4(s1)
    80004bd2:	02f05263          	blez	a5,80004bf6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bd6:	2785                	addiw	a5,a5,1
    80004bd8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bda:	0001f517          	auipc	a0,0x1f
    80004bde:	28e50513          	addi	a0,a0,654 # 80023e68 <ftable>
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	10a080e7          	jalr	266(ra) # 80000cec <release>
  return f;
}
    80004bea:	8526                	mv	a0,s1
    80004bec:	60e2                	ld	ra,24(sp)
    80004bee:	6442                	ld	s0,16(sp)
    80004bf0:	64a2                	ld	s1,8(sp)
    80004bf2:	6105                	addi	sp,sp,32
    80004bf4:	8082                	ret
    panic("filedup");
    80004bf6:	00004517          	auipc	a0,0x4
    80004bfa:	98250513          	addi	a0,a0,-1662 # 80008578 <etext+0x578>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	962080e7          	jalr	-1694(ra) # 80000560 <panic>

0000000080004c06 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c06:	7139                	addi	sp,sp,-64
    80004c08:	fc06                	sd	ra,56(sp)
    80004c0a:	f822                	sd	s0,48(sp)
    80004c0c:	f426                	sd	s1,40(sp)
    80004c0e:	0080                	addi	s0,sp,64
    80004c10:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c12:	0001f517          	auipc	a0,0x1f
    80004c16:	25650513          	addi	a0,a0,598 # 80023e68 <ftable>
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	01e080e7          	jalr	30(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004c22:	40dc                	lw	a5,4(s1)
    80004c24:	04f05c63          	blez	a5,80004c7c <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80004c28:	37fd                	addiw	a5,a5,-1
    80004c2a:	0007871b          	sext.w	a4,a5
    80004c2e:	c0dc                	sw	a5,4(s1)
    80004c30:	06e04263          	bgtz	a4,80004c94 <fileclose+0x8e>
    80004c34:	f04a                	sd	s2,32(sp)
    80004c36:	ec4e                	sd	s3,24(sp)
    80004c38:	e852                	sd	s4,16(sp)
    80004c3a:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c3c:	0004a903          	lw	s2,0(s1)
    80004c40:	0094ca83          	lbu	s5,9(s1)
    80004c44:	0104ba03          	ld	s4,16(s1)
    80004c48:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c4c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c50:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c54:	0001f517          	auipc	a0,0x1f
    80004c58:	21450513          	addi	a0,a0,532 # 80023e68 <ftable>
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	090080e7          	jalr	144(ra) # 80000cec <release>

  if(ff.type == FD_PIPE){
    80004c64:	4785                	li	a5,1
    80004c66:	04f90463          	beq	s2,a5,80004cae <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c6a:	3979                	addiw	s2,s2,-2
    80004c6c:	4785                	li	a5,1
    80004c6e:	0527fb63          	bgeu	a5,s2,80004cc4 <fileclose+0xbe>
    80004c72:	7902                	ld	s2,32(sp)
    80004c74:	69e2                	ld	s3,24(sp)
    80004c76:	6a42                	ld	s4,16(sp)
    80004c78:	6aa2                	ld	s5,8(sp)
    80004c7a:	a02d                	j	80004ca4 <fileclose+0x9e>
    80004c7c:	f04a                	sd	s2,32(sp)
    80004c7e:	ec4e                	sd	s3,24(sp)
    80004c80:	e852                	sd	s4,16(sp)
    80004c82:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004c84:	00004517          	auipc	a0,0x4
    80004c88:	8fc50513          	addi	a0,a0,-1796 # 80008580 <etext+0x580>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	8d4080e7          	jalr	-1836(ra) # 80000560 <panic>
    release(&ftable.lock);
    80004c94:	0001f517          	auipc	a0,0x1f
    80004c98:	1d450513          	addi	a0,a0,468 # 80023e68 <ftable>
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	050080e7          	jalr	80(ra) # 80000cec <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004ca4:	70e2                	ld	ra,56(sp)
    80004ca6:	7442                	ld	s0,48(sp)
    80004ca8:	74a2                	ld	s1,40(sp)
    80004caa:	6121                	addi	sp,sp,64
    80004cac:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cae:	85d6                	mv	a1,s5
    80004cb0:	8552                	mv	a0,s4
    80004cb2:	00000097          	auipc	ra,0x0
    80004cb6:	3a2080e7          	jalr	930(ra) # 80005054 <pipeclose>
    80004cba:	7902                	ld	s2,32(sp)
    80004cbc:	69e2                	ld	s3,24(sp)
    80004cbe:	6a42                	ld	s4,16(sp)
    80004cc0:	6aa2                	ld	s5,8(sp)
    80004cc2:	b7cd                	j	80004ca4 <fileclose+0x9e>
    begin_op();
    80004cc4:	00000097          	auipc	ra,0x0
    80004cc8:	a78080e7          	jalr	-1416(ra) # 8000473c <begin_op>
    iput(ff.ip);
    80004ccc:	854e                	mv	a0,s3
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	25e080e7          	jalr	606(ra) # 80003f2c <iput>
    end_op();
    80004cd6:	00000097          	auipc	ra,0x0
    80004cda:	ae0080e7          	jalr	-1312(ra) # 800047b6 <end_op>
    80004cde:	7902                	ld	s2,32(sp)
    80004ce0:	69e2                	ld	s3,24(sp)
    80004ce2:	6a42                	ld	s4,16(sp)
    80004ce4:	6aa2                	ld	s5,8(sp)
    80004ce6:	bf7d                	j	80004ca4 <fileclose+0x9e>

0000000080004ce8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ce8:	715d                	addi	sp,sp,-80
    80004cea:	e486                	sd	ra,72(sp)
    80004cec:	e0a2                	sd	s0,64(sp)
    80004cee:	fc26                	sd	s1,56(sp)
    80004cf0:	f44e                	sd	s3,40(sp)
    80004cf2:	0880                	addi	s0,sp,80
    80004cf4:	84aa                	mv	s1,a0
    80004cf6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	d52080e7          	jalr	-686(ra) # 80001a4a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d00:	409c                	lw	a5,0(s1)
    80004d02:	37f9                	addiw	a5,a5,-2
    80004d04:	4705                	li	a4,1
    80004d06:	04f76863          	bltu	a4,a5,80004d56 <filestat+0x6e>
    80004d0a:	f84a                	sd	s2,48(sp)
    80004d0c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d0e:	6c88                	ld	a0,24(s1)
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	05e080e7          	jalr	94(ra) # 80003d6e <ilock>
    stati(f->ip, &st);
    80004d18:	fb840593          	addi	a1,s0,-72
    80004d1c:	6c88                	ld	a0,24(s1)
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	2de080e7          	jalr	734(ra) # 80003ffc <stati>
    iunlock(f->ip);
    80004d26:	6c88                	ld	a0,24(s1)
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	10c080e7          	jalr	268(ra) # 80003e34 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d30:	46e1                	li	a3,24
    80004d32:	fb840613          	addi	a2,s0,-72
    80004d36:	85ce                	mv	a1,s3
    80004d38:	10893503          	ld	a0,264(s2)
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	9a6080e7          	jalr	-1626(ra) # 800016e2 <copyout>
    80004d44:	41f5551b          	sraiw	a0,a0,0x1f
    80004d48:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004d4a:	60a6                	ld	ra,72(sp)
    80004d4c:	6406                	ld	s0,64(sp)
    80004d4e:	74e2                	ld	s1,56(sp)
    80004d50:	79a2                	ld	s3,40(sp)
    80004d52:	6161                	addi	sp,sp,80
    80004d54:	8082                	ret
  return -1;
    80004d56:	557d                	li	a0,-1
    80004d58:	bfcd                	j	80004d4a <filestat+0x62>

0000000080004d5a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d5a:	7179                	addi	sp,sp,-48
    80004d5c:	f406                	sd	ra,40(sp)
    80004d5e:	f022                	sd	s0,32(sp)
    80004d60:	e84a                	sd	s2,16(sp)
    80004d62:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d64:	00854783          	lbu	a5,8(a0)
    80004d68:	cbc5                	beqz	a5,80004e18 <fileread+0xbe>
    80004d6a:	ec26                	sd	s1,24(sp)
    80004d6c:	e44e                	sd	s3,8(sp)
    80004d6e:	84aa                	mv	s1,a0
    80004d70:	89ae                	mv	s3,a1
    80004d72:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d74:	411c                	lw	a5,0(a0)
    80004d76:	4705                	li	a4,1
    80004d78:	04e78963          	beq	a5,a4,80004dca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d7c:	470d                	li	a4,3
    80004d7e:	04e78f63          	beq	a5,a4,80004ddc <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d82:	4709                	li	a4,2
    80004d84:	08e79263          	bne	a5,a4,80004e08 <fileread+0xae>
    ilock(f->ip);
    80004d88:	6d08                	ld	a0,24(a0)
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	fe4080e7          	jalr	-28(ra) # 80003d6e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d92:	874a                	mv	a4,s2
    80004d94:	5094                	lw	a3,32(s1)
    80004d96:	864e                	mv	a2,s3
    80004d98:	4585                	li	a1,1
    80004d9a:	6c88                	ld	a0,24(s1)
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	28a080e7          	jalr	650(ra) # 80004026 <readi>
    80004da4:	892a                	mv	s2,a0
    80004da6:	00a05563          	blez	a0,80004db0 <fileread+0x56>
      f->off += r;
    80004daa:	509c                	lw	a5,32(s1)
    80004dac:	9fa9                	addw	a5,a5,a0
    80004dae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004db0:	6c88                	ld	a0,24(s1)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	082080e7          	jalr	130(ra) # 80003e34 <iunlock>
    80004dba:	64e2                	ld	s1,24(sp)
    80004dbc:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004dbe:	854a                	mv	a0,s2
    80004dc0:	70a2                	ld	ra,40(sp)
    80004dc2:	7402                	ld	s0,32(sp)
    80004dc4:	6942                	ld	s2,16(sp)
    80004dc6:	6145                	addi	sp,sp,48
    80004dc8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dca:	6908                	ld	a0,16(a0)
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	400080e7          	jalr	1024(ra) # 800051cc <piperead>
    80004dd4:	892a                	mv	s2,a0
    80004dd6:	64e2                	ld	s1,24(sp)
    80004dd8:	69a2                	ld	s3,8(sp)
    80004dda:	b7d5                	j	80004dbe <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ddc:	02451783          	lh	a5,36(a0)
    80004de0:	03079693          	slli	a3,a5,0x30
    80004de4:	92c1                	srli	a3,a3,0x30
    80004de6:	4725                	li	a4,9
    80004de8:	02d76a63          	bltu	a4,a3,80004e1c <fileread+0xc2>
    80004dec:	0792                	slli	a5,a5,0x4
    80004dee:	0001f717          	auipc	a4,0x1f
    80004df2:	fda70713          	addi	a4,a4,-38 # 80023dc8 <devsw>
    80004df6:	97ba                	add	a5,a5,a4
    80004df8:	639c                	ld	a5,0(a5)
    80004dfa:	c78d                	beqz	a5,80004e24 <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    80004dfc:	4505                	li	a0,1
    80004dfe:	9782                	jalr	a5
    80004e00:	892a                	mv	s2,a0
    80004e02:	64e2                	ld	s1,24(sp)
    80004e04:	69a2                	ld	s3,8(sp)
    80004e06:	bf65                	j	80004dbe <fileread+0x64>
    panic("fileread");
    80004e08:	00003517          	auipc	a0,0x3
    80004e0c:	78850513          	addi	a0,a0,1928 # 80008590 <etext+0x590>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	750080e7          	jalr	1872(ra) # 80000560 <panic>
    return -1;
    80004e18:	597d                	li	s2,-1
    80004e1a:	b755                	j	80004dbe <fileread+0x64>
      return -1;
    80004e1c:	597d                	li	s2,-1
    80004e1e:	64e2                	ld	s1,24(sp)
    80004e20:	69a2                	ld	s3,8(sp)
    80004e22:	bf71                	j	80004dbe <fileread+0x64>
    80004e24:	597d                	li	s2,-1
    80004e26:	64e2                	ld	s1,24(sp)
    80004e28:	69a2                	ld	s3,8(sp)
    80004e2a:	bf51                	j	80004dbe <fileread+0x64>

0000000080004e2c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004e2c:	00954783          	lbu	a5,9(a0)
    80004e30:	12078963          	beqz	a5,80004f62 <filewrite+0x136>
{
    80004e34:	715d                	addi	sp,sp,-80
    80004e36:	e486                	sd	ra,72(sp)
    80004e38:	e0a2                	sd	s0,64(sp)
    80004e3a:	f84a                	sd	s2,48(sp)
    80004e3c:	f052                	sd	s4,32(sp)
    80004e3e:	e85a                	sd	s6,16(sp)
    80004e40:	0880                	addi	s0,sp,80
    80004e42:	892a                	mv	s2,a0
    80004e44:	8b2e                	mv	s6,a1
    80004e46:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e48:	411c                	lw	a5,0(a0)
    80004e4a:	4705                	li	a4,1
    80004e4c:	02e78763          	beq	a5,a4,80004e7a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e50:	470d                	li	a4,3
    80004e52:	02e78a63          	beq	a5,a4,80004e86 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e56:	4709                	li	a4,2
    80004e58:	0ee79863          	bne	a5,a4,80004f48 <filewrite+0x11c>
    80004e5c:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e5e:	0cc05463          	blez	a2,80004f26 <filewrite+0xfa>
    80004e62:	fc26                	sd	s1,56(sp)
    80004e64:	ec56                	sd	s5,24(sp)
    80004e66:	e45e                	sd	s7,8(sp)
    80004e68:	e062                	sd	s8,0(sp)
    int i = 0;
    80004e6a:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e6c:	6b85                	lui	s7,0x1
    80004e6e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e72:	6c05                	lui	s8,0x1
    80004e74:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e78:	a851                	j	80004f0c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e7a:	6908                	ld	a0,16(a0)
    80004e7c:	00000097          	auipc	ra,0x0
    80004e80:	248080e7          	jalr	584(ra) # 800050c4 <pipewrite>
    80004e84:	a85d                	j	80004f3a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e86:	02451783          	lh	a5,36(a0)
    80004e8a:	03079693          	slli	a3,a5,0x30
    80004e8e:	92c1                	srli	a3,a3,0x30
    80004e90:	4725                	li	a4,9
    80004e92:	0cd76a63          	bltu	a4,a3,80004f66 <filewrite+0x13a>
    80004e96:	0792                	slli	a5,a5,0x4
    80004e98:	0001f717          	auipc	a4,0x1f
    80004e9c:	f3070713          	addi	a4,a4,-208 # 80023dc8 <devsw>
    80004ea0:	97ba                	add	a5,a5,a4
    80004ea2:	679c                	ld	a5,8(a5)
    80004ea4:	c3f9                	beqz	a5,80004f6a <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    80004ea6:	4505                	li	a0,1
    80004ea8:	9782                	jalr	a5
    80004eaa:	a841                	j	80004f3a <filewrite+0x10e>
      if(n1 > max)
    80004eac:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004eb0:	00000097          	auipc	ra,0x0
    80004eb4:	88c080e7          	jalr	-1908(ra) # 8000473c <begin_op>
      ilock(f->ip);
    80004eb8:	01893503          	ld	a0,24(s2)
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	eb2080e7          	jalr	-334(ra) # 80003d6e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ec4:	8756                	mv	a4,s5
    80004ec6:	02092683          	lw	a3,32(s2)
    80004eca:	01698633          	add	a2,s3,s6
    80004ece:	4585                	li	a1,1
    80004ed0:	01893503          	ld	a0,24(s2)
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	262080e7          	jalr	610(ra) # 80004136 <writei>
    80004edc:	84aa                	mv	s1,a0
    80004ede:	00a05763          	blez	a0,80004eec <filewrite+0xc0>
        f->off += r;
    80004ee2:	02092783          	lw	a5,32(s2)
    80004ee6:	9fa9                	addw	a5,a5,a0
    80004ee8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004eec:	01893503          	ld	a0,24(s2)
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	f44080e7          	jalr	-188(ra) # 80003e34 <iunlock>
      end_op();
    80004ef8:	00000097          	auipc	ra,0x0
    80004efc:	8be080e7          	jalr	-1858(ra) # 800047b6 <end_op>

      if(r != n1){
    80004f00:	029a9563          	bne	s5,s1,80004f2a <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    80004f04:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f08:	0149da63          	bge	s3,s4,80004f1c <filewrite+0xf0>
      int n1 = n - i;
    80004f0c:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004f10:	0004879b          	sext.w	a5,s1
    80004f14:	f8fbdce3          	bge	s7,a5,80004eac <filewrite+0x80>
    80004f18:	84e2                	mv	s1,s8
    80004f1a:	bf49                	j	80004eac <filewrite+0x80>
    80004f1c:	74e2                	ld	s1,56(sp)
    80004f1e:	6ae2                	ld	s5,24(sp)
    80004f20:	6ba2                	ld	s7,8(sp)
    80004f22:	6c02                	ld	s8,0(sp)
    80004f24:	a039                	j	80004f32 <filewrite+0x106>
    int i = 0;
    80004f26:	4981                	li	s3,0
    80004f28:	a029                	j	80004f32 <filewrite+0x106>
    80004f2a:	74e2                	ld	s1,56(sp)
    80004f2c:	6ae2                	ld	s5,24(sp)
    80004f2e:	6ba2                	ld	s7,8(sp)
    80004f30:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    80004f32:	033a1e63          	bne	s4,s3,80004f6e <filewrite+0x142>
    80004f36:	8552                	mv	a0,s4
    80004f38:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f3a:	60a6                	ld	ra,72(sp)
    80004f3c:	6406                	ld	s0,64(sp)
    80004f3e:	7942                	ld	s2,48(sp)
    80004f40:	7a02                	ld	s4,32(sp)
    80004f42:	6b42                	ld	s6,16(sp)
    80004f44:	6161                	addi	sp,sp,80
    80004f46:	8082                	ret
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f44e                	sd	s3,40(sp)
    80004f4c:	ec56                	sd	s5,24(sp)
    80004f4e:	e45e                	sd	s7,8(sp)
    80004f50:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80004f52:	00003517          	auipc	a0,0x3
    80004f56:	64e50513          	addi	a0,a0,1614 # 800085a0 <etext+0x5a0>
    80004f5a:	ffffb097          	auipc	ra,0xffffb
    80004f5e:	606080e7          	jalr	1542(ra) # 80000560 <panic>
    return -1;
    80004f62:	557d                	li	a0,-1
}
    80004f64:	8082                	ret
      return -1;
    80004f66:	557d                	li	a0,-1
    80004f68:	bfc9                	j	80004f3a <filewrite+0x10e>
    80004f6a:	557d                	li	a0,-1
    80004f6c:	b7f9                	j	80004f3a <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80004f6e:	557d                	li	a0,-1
    80004f70:	79a2                	ld	s3,40(sp)
    80004f72:	b7e1                	j	80004f3a <filewrite+0x10e>

0000000080004f74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f74:	7179                	addi	sp,sp,-48
    80004f76:	f406                	sd	ra,40(sp)
    80004f78:	f022                	sd	s0,32(sp)
    80004f7a:	ec26                	sd	s1,24(sp)
    80004f7c:	e052                	sd	s4,0(sp)
    80004f7e:	1800                	addi	s0,sp,48
    80004f80:	84aa                	mv	s1,a0
    80004f82:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f84:	0005b023          	sd	zero,0(a1)
    80004f88:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f8c:	00000097          	auipc	ra,0x0
    80004f90:	bbe080e7          	jalr	-1090(ra) # 80004b4a <filealloc>
    80004f94:	e088                	sd	a0,0(s1)
    80004f96:	cd49                	beqz	a0,80005030 <pipealloc+0xbc>
    80004f98:	00000097          	auipc	ra,0x0
    80004f9c:	bb2080e7          	jalr	-1102(ra) # 80004b4a <filealloc>
    80004fa0:	00aa3023          	sd	a0,0(s4)
    80004fa4:	c141                	beqz	a0,80005024 <pipealloc+0xb0>
    80004fa6:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	ba0080e7          	jalr	-1120(ra) # 80000b48 <kalloc>
    80004fb0:	892a                	mv	s2,a0
    80004fb2:	c13d                	beqz	a0,80005018 <pipealloc+0xa4>
    80004fb4:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004fb6:	4985                	li	s3,1
    80004fb8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fbc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fc0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fc4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fc8:	00003597          	auipc	a1,0x3
    80004fcc:	5e858593          	addi	a1,a1,1512 # 800085b0 <etext+0x5b0>
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	bd8080e7          	jalr	-1064(ra) # 80000ba8 <initlock>
  (*f0)->type = FD_PIPE;
    80004fd8:	609c                	ld	a5,0(s1)
    80004fda:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fde:	609c                	ld	a5,0(s1)
    80004fe0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fe4:	609c                	ld	a5,0(s1)
    80004fe6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004fea:	609c                	ld	a5,0(s1)
    80004fec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ff0:	000a3783          	ld	a5,0(s4)
    80004ff4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ff8:	000a3783          	ld	a5,0(s4)
    80004ffc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005000:	000a3783          	ld	a5,0(s4)
    80005004:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005008:	000a3783          	ld	a5,0(s4)
    8000500c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005010:	4501                	li	a0,0
    80005012:	6942                	ld	s2,16(sp)
    80005014:	69a2                	ld	s3,8(sp)
    80005016:	a03d                	j	80005044 <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005018:	6088                	ld	a0,0(s1)
    8000501a:	c119                	beqz	a0,80005020 <pipealloc+0xac>
    8000501c:	6942                	ld	s2,16(sp)
    8000501e:	a029                	j	80005028 <pipealloc+0xb4>
    80005020:	6942                	ld	s2,16(sp)
    80005022:	a039                	j	80005030 <pipealloc+0xbc>
    80005024:	6088                	ld	a0,0(s1)
    80005026:	c50d                	beqz	a0,80005050 <pipealloc+0xdc>
    fileclose(*f0);
    80005028:	00000097          	auipc	ra,0x0
    8000502c:	bde080e7          	jalr	-1058(ra) # 80004c06 <fileclose>
  if(*f1)
    80005030:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005034:	557d                	li	a0,-1
  if(*f1)
    80005036:	c799                	beqz	a5,80005044 <pipealloc+0xd0>
    fileclose(*f1);
    80005038:	853e                	mv	a0,a5
    8000503a:	00000097          	auipc	ra,0x0
    8000503e:	bcc080e7          	jalr	-1076(ra) # 80004c06 <fileclose>
  return -1;
    80005042:	557d                	li	a0,-1
}
    80005044:	70a2                	ld	ra,40(sp)
    80005046:	7402                	ld	s0,32(sp)
    80005048:	64e2                	ld	s1,24(sp)
    8000504a:	6a02                	ld	s4,0(sp)
    8000504c:	6145                	addi	sp,sp,48
    8000504e:	8082                	ret
  return -1;
    80005050:	557d                	li	a0,-1
    80005052:	bfcd                	j	80005044 <pipealloc+0xd0>

0000000080005054 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005054:	1101                	addi	sp,sp,-32
    80005056:	ec06                	sd	ra,24(sp)
    80005058:	e822                	sd	s0,16(sp)
    8000505a:	e426                	sd	s1,8(sp)
    8000505c:	e04a                	sd	s2,0(sp)
    8000505e:	1000                	addi	s0,sp,32
    80005060:	84aa                	mv	s1,a0
    80005062:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	bd4080e7          	jalr	-1068(ra) # 80000c38 <acquire>
  if(writable){
    8000506c:	02090d63          	beqz	s2,800050a6 <pipeclose+0x52>
    pi->writeopen = 0;
    80005070:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005074:	21848513          	addi	a0,s1,536
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	174080e7          	jalr	372(ra) # 800021ec <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005080:	2204b783          	ld	a5,544(s1)
    80005084:	eb95                	bnez	a5,800050b8 <pipeclose+0x64>
    release(&pi->lock);
    80005086:	8526                	mv	a0,s1
    80005088:	ffffc097          	auipc	ra,0xffffc
    8000508c:	c64080e7          	jalr	-924(ra) # 80000cec <release>
    kfree((char*)pi);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	9b8080e7          	jalr	-1608(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    8000509a:	60e2                	ld	ra,24(sp)
    8000509c:	6442                	ld	s0,16(sp)
    8000509e:	64a2                	ld	s1,8(sp)
    800050a0:	6902                	ld	s2,0(sp)
    800050a2:	6105                	addi	sp,sp,32
    800050a4:	8082                	ret
    pi->readopen = 0;
    800050a6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050aa:	21c48513          	addi	a0,s1,540
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	13e080e7          	jalr	318(ra) # 800021ec <wakeup>
    800050b6:	b7e9                	j	80005080 <pipeclose+0x2c>
    release(&pi->lock);
    800050b8:	8526                	mv	a0,s1
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	c32080e7          	jalr	-974(ra) # 80000cec <release>
}
    800050c2:	bfe1                	j	8000509a <pipeclose+0x46>

00000000800050c4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050c4:	711d                	addi	sp,sp,-96
    800050c6:	ec86                	sd	ra,88(sp)
    800050c8:	e8a2                	sd	s0,80(sp)
    800050ca:	e4a6                	sd	s1,72(sp)
    800050cc:	e0ca                	sd	s2,64(sp)
    800050ce:	fc4e                	sd	s3,56(sp)
    800050d0:	f852                	sd	s4,48(sp)
    800050d2:	f456                	sd	s5,40(sp)
    800050d4:	1080                	addi	s0,sp,96
    800050d6:	84aa                	mv	s1,a0
    800050d8:	8aae                	mv	s5,a1
    800050da:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	96e080e7          	jalr	-1682(ra) # 80001a4a <myproc>
    800050e4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050e6:	8526                	mv	a0,s1
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	b50080e7          	jalr	-1200(ra) # 80000c38 <acquire>
  while(i < n){
    800050f0:	0d405863          	blez	s4,800051c0 <pipewrite+0xfc>
    800050f4:	f05a                	sd	s6,32(sp)
    800050f6:	ec5e                	sd	s7,24(sp)
    800050f8:	e862                	sd	s8,16(sp)
  int i = 0;
    800050fa:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050fc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050fe:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005102:	21c48b93          	addi	s7,s1,540
    80005106:	a089                	j	80005148 <pipewrite+0x84>
      release(&pi->lock);
    80005108:	8526                	mv	a0,s1
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	be2080e7          	jalr	-1054(ra) # 80000cec <release>
      return -1;
    80005112:	597d                	li	s2,-1
    80005114:	7b02                	ld	s6,32(sp)
    80005116:	6be2                	ld	s7,24(sp)
    80005118:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000511a:	854a                	mv	a0,s2
    8000511c:	60e6                	ld	ra,88(sp)
    8000511e:	6446                	ld	s0,80(sp)
    80005120:	64a6                	ld	s1,72(sp)
    80005122:	6906                	ld	s2,64(sp)
    80005124:	79e2                	ld	s3,56(sp)
    80005126:	7a42                	ld	s4,48(sp)
    80005128:	7aa2                	ld	s5,40(sp)
    8000512a:	6125                	addi	sp,sp,96
    8000512c:	8082                	ret
      wakeup(&pi->nread);
    8000512e:	8562                	mv	a0,s8
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	0bc080e7          	jalr	188(ra) # 800021ec <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005138:	85a6                	mv	a1,s1
    8000513a:	855e                	mv	a0,s7
    8000513c:	ffffd097          	auipc	ra,0xffffd
    80005140:	04c080e7          	jalr	76(ra) # 80002188 <sleep>
  while(i < n){
    80005144:	05495f63          	bge	s2,s4,800051a2 <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    80005148:	2204a783          	lw	a5,544(s1)
    8000514c:	dfd5                	beqz	a5,80005108 <pipewrite+0x44>
    8000514e:	854e                	mv	a0,s3
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	30e080e7          	jalr	782(ra) # 8000245e <killed>
    80005158:	f945                	bnez	a0,80005108 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000515a:	2184a783          	lw	a5,536(s1)
    8000515e:	21c4a703          	lw	a4,540(s1)
    80005162:	2007879b          	addiw	a5,a5,512
    80005166:	fcf704e3          	beq	a4,a5,8000512e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000516a:	4685                	li	a3,1
    8000516c:	01590633          	add	a2,s2,s5
    80005170:	faf40593          	addi	a1,s0,-81
    80005174:	1089b503          	ld	a0,264(s3)
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	5f6080e7          	jalr	1526(ra) # 8000176e <copyin>
    80005180:	05650263          	beq	a0,s6,800051c4 <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005184:	21c4a783          	lw	a5,540(s1)
    80005188:	0017871b          	addiw	a4,a5,1
    8000518c:	20e4ae23          	sw	a4,540(s1)
    80005190:	1ff7f793          	andi	a5,a5,511
    80005194:	97a6                	add	a5,a5,s1
    80005196:	faf44703          	lbu	a4,-81(s0)
    8000519a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000519e:	2905                	addiw	s2,s2,1
    800051a0:	b755                	j	80005144 <pipewrite+0x80>
    800051a2:	7b02                	ld	s6,32(sp)
    800051a4:	6be2                	ld	s7,24(sp)
    800051a6:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    800051a8:	21848513          	addi	a0,s1,536
    800051ac:	ffffd097          	auipc	ra,0xffffd
    800051b0:	040080e7          	jalr	64(ra) # 800021ec <wakeup>
  release(&pi->lock);
    800051b4:	8526                	mv	a0,s1
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	b36080e7          	jalr	-1226(ra) # 80000cec <release>
  return i;
    800051be:	bfb1                	j	8000511a <pipewrite+0x56>
  int i = 0;
    800051c0:	4901                	li	s2,0
    800051c2:	b7dd                	j	800051a8 <pipewrite+0xe4>
    800051c4:	7b02                	ld	s6,32(sp)
    800051c6:	6be2                	ld	s7,24(sp)
    800051c8:	6c42                	ld	s8,16(sp)
    800051ca:	bff9                	j	800051a8 <pipewrite+0xe4>

00000000800051cc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051cc:	715d                	addi	sp,sp,-80
    800051ce:	e486                	sd	ra,72(sp)
    800051d0:	e0a2                	sd	s0,64(sp)
    800051d2:	fc26                	sd	s1,56(sp)
    800051d4:	f84a                	sd	s2,48(sp)
    800051d6:	f44e                	sd	s3,40(sp)
    800051d8:	f052                	sd	s4,32(sp)
    800051da:	ec56                	sd	s5,24(sp)
    800051dc:	0880                	addi	s0,sp,80
    800051de:	84aa                	mv	s1,a0
    800051e0:	892e                	mv	s2,a1
    800051e2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	866080e7          	jalr	-1946(ra) # 80001a4a <myproc>
    800051ec:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051ee:	8526                	mv	a0,s1
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	a48080e7          	jalr	-1464(ra) # 80000c38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051f8:	2184a703          	lw	a4,536(s1)
    800051fc:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005200:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005204:	02f71963          	bne	a4,a5,80005236 <piperead+0x6a>
    80005208:	2244a783          	lw	a5,548(s1)
    8000520c:	cf95                	beqz	a5,80005248 <piperead+0x7c>
    if(killed(pr)){
    8000520e:	8552                	mv	a0,s4
    80005210:	ffffd097          	auipc	ra,0xffffd
    80005214:	24e080e7          	jalr	590(ra) # 8000245e <killed>
    80005218:	e10d                	bnez	a0,8000523a <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000521a:	85a6                	mv	a1,s1
    8000521c:	854e                	mv	a0,s3
    8000521e:	ffffd097          	auipc	ra,0xffffd
    80005222:	f6a080e7          	jalr	-150(ra) # 80002188 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005226:	2184a703          	lw	a4,536(s1)
    8000522a:	21c4a783          	lw	a5,540(s1)
    8000522e:	fcf70de3          	beq	a4,a5,80005208 <piperead+0x3c>
    80005232:	e85a                	sd	s6,16(sp)
    80005234:	a819                	j	8000524a <piperead+0x7e>
    80005236:	e85a                	sd	s6,16(sp)
    80005238:	a809                	j	8000524a <piperead+0x7e>
      release(&pi->lock);
    8000523a:	8526                	mv	a0,s1
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	ab0080e7          	jalr	-1360(ra) # 80000cec <release>
      return -1;
    80005244:	59fd                	li	s3,-1
    80005246:	a0a5                	j	800052ae <piperead+0xe2>
    80005248:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000524a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000524c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000524e:	05505463          	blez	s5,80005296 <piperead+0xca>
    if(pi->nread == pi->nwrite)
    80005252:	2184a783          	lw	a5,536(s1)
    80005256:	21c4a703          	lw	a4,540(s1)
    8000525a:	02f70e63          	beq	a4,a5,80005296 <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000525e:	0017871b          	addiw	a4,a5,1
    80005262:	20e4ac23          	sw	a4,536(s1)
    80005266:	1ff7f793          	andi	a5,a5,511
    8000526a:	97a6                	add	a5,a5,s1
    8000526c:	0187c783          	lbu	a5,24(a5)
    80005270:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005274:	4685                	li	a3,1
    80005276:	fbf40613          	addi	a2,s0,-65
    8000527a:	85ca                	mv	a1,s2
    8000527c:	108a3503          	ld	a0,264(s4)
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	462080e7          	jalr	1122(ra) # 800016e2 <copyout>
    80005288:	01650763          	beq	a0,s6,80005296 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000528c:	2985                	addiw	s3,s3,1
    8000528e:	0905                	addi	s2,s2,1
    80005290:	fd3a91e3          	bne	s5,s3,80005252 <piperead+0x86>
    80005294:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005296:	21c48513          	addi	a0,s1,540
    8000529a:	ffffd097          	auipc	ra,0xffffd
    8000529e:	f52080e7          	jalr	-174(ra) # 800021ec <wakeup>
  release(&pi->lock);
    800052a2:	8526                	mv	a0,s1
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	a48080e7          	jalr	-1464(ra) # 80000cec <release>
    800052ac:	6b42                	ld	s6,16(sp)
  return i;
}
    800052ae:	854e                	mv	a0,s3
    800052b0:	60a6                	ld	ra,72(sp)
    800052b2:	6406                	ld	s0,64(sp)
    800052b4:	74e2                	ld	s1,56(sp)
    800052b6:	7942                	ld	s2,48(sp)
    800052b8:	79a2                	ld	s3,40(sp)
    800052ba:	7a02                	ld	s4,32(sp)
    800052bc:	6ae2                	ld	s5,24(sp)
    800052be:	6161                	addi	sp,sp,80
    800052c0:	8082                	ret

00000000800052c2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052c2:	1141                	addi	sp,sp,-16
    800052c4:	e422                	sd	s0,8(sp)
    800052c6:	0800                	addi	s0,sp,16
    800052c8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052ca:	8905                	andi	a0,a0,1
    800052cc:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800052ce:	8b89                	andi	a5,a5,2
    800052d0:	c399                	beqz	a5,800052d6 <flags2perm+0x14>
      perm |= PTE_W;
    800052d2:	00456513          	ori	a0,a0,4
    return perm;
}
    800052d6:	6422                	ld	s0,8(sp)
    800052d8:	0141                	addi	sp,sp,16
    800052da:	8082                	ret

00000000800052dc <exec>:

int
exec(char *path, char **argv)
{
    800052dc:	df010113          	addi	sp,sp,-528
    800052e0:	20113423          	sd	ra,520(sp)
    800052e4:	20813023          	sd	s0,512(sp)
    800052e8:	ffa6                	sd	s1,504(sp)
    800052ea:	fbca                	sd	s2,496(sp)
    800052ec:	0c00                	addi	s0,sp,528
    800052ee:	892a                	mv	s2,a0
    800052f0:	dea43c23          	sd	a0,-520(s0)
    800052f4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052f8:	ffffc097          	auipc	ra,0xffffc
    800052fc:	752080e7          	jalr	1874(ra) # 80001a4a <myproc>
    80005300:	84aa                	mv	s1,a0

  begin_op();
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	43a080e7          	jalr	1082(ra) # 8000473c <begin_op>

  if((ip = namei(path)) == 0){
    8000530a:	854a                	mv	a0,s2
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	230080e7          	jalr	560(ra) # 8000453c <namei>
    80005314:	c135                	beqz	a0,80005378 <exec+0x9c>
    80005316:	f3d2                	sd	s4,480(sp)
    80005318:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	a54080e7          	jalr	-1452(ra) # 80003d6e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005322:	04000713          	li	a4,64
    80005326:	4681                	li	a3,0
    80005328:	e5040613          	addi	a2,s0,-432
    8000532c:	4581                	li	a1,0
    8000532e:	8552                	mv	a0,s4
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	cf6080e7          	jalr	-778(ra) # 80004026 <readi>
    80005338:	04000793          	li	a5,64
    8000533c:	00f51a63          	bne	a0,a5,80005350 <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005340:	e5042703          	lw	a4,-432(s0)
    80005344:	464c47b7          	lui	a5,0x464c4
    80005348:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000534c:	02f70c63          	beq	a4,a5,80005384 <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005350:	8552                	mv	a0,s4
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	c82080e7          	jalr	-894(ra) # 80003fd4 <iunlockput>
    end_op();
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	45c080e7          	jalr	1116(ra) # 800047b6 <end_op>
  }
  return -1;
    80005362:	557d                	li	a0,-1
    80005364:	7a1e                	ld	s4,480(sp)
}
    80005366:	20813083          	ld	ra,520(sp)
    8000536a:	20013403          	ld	s0,512(sp)
    8000536e:	74fe                	ld	s1,504(sp)
    80005370:	795e                	ld	s2,496(sp)
    80005372:	21010113          	addi	sp,sp,528
    80005376:	8082                	ret
    end_op();
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	43e080e7          	jalr	1086(ra) # 800047b6 <end_op>
    return -1;
    80005380:	557d                	li	a0,-1
    80005382:	b7d5                	j	80005366 <exec+0x8a>
    80005384:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80005386:	8526                	mv	a0,s1
    80005388:	ffffc097          	auipc	ra,0xffffc
    8000538c:	786080e7          	jalr	1926(ra) # 80001b0e <proc_pagetable>
    80005390:	8b2a                	mv	s6,a0
    80005392:	30050f63          	beqz	a0,800056b0 <exec+0x3d4>
    80005396:	f7ce                	sd	s3,488(sp)
    80005398:	efd6                	sd	s5,472(sp)
    8000539a:	e7de                	sd	s7,456(sp)
    8000539c:	e3e2                	sd	s8,448(sp)
    8000539e:	ff66                	sd	s9,440(sp)
    800053a0:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a2:	e7042d03          	lw	s10,-400(s0)
    800053a6:	e8845783          	lhu	a5,-376(s0)
    800053aa:	14078d63          	beqz	a5,80005504 <exec+0x228>
    800053ae:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053b0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053b2:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800053b4:	6c85                	lui	s9,0x1
    800053b6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053ba:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800053be:	6a85                	lui	s5,0x1
    800053c0:	a0b5                	j	8000542c <exec+0x150>
      panic("loadseg: address should exist");
    800053c2:	00003517          	auipc	a0,0x3
    800053c6:	1f650513          	addi	a0,a0,502 # 800085b8 <etext+0x5b8>
    800053ca:	ffffb097          	auipc	ra,0xffffb
    800053ce:	196080e7          	jalr	406(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    800053d2:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053d4:	8726                	mv	a4,s1
    800053d6:	012c06bb          	addw	a3,s8,s2
    800053da:	4581                	li	a1,0
    800053dc:	8552                	mv	a0,s4
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	c48080e7          	jalr	-952(ra) # 80004026 <readi>
    800053e6:	2501                	sext.w	a0,a0
    800053e8:	28a49863          	bne	s1,a0,80005678 <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    800053ec:	012a893b          	addw	s2,s5,s2
    800053f0:	03397563          	bgeu	s2,s3,8000541a <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    800053f4:	02091593          	slli	a1,s2,0x20
    800053f8:	9181                	srli	a1,a1,0x20
    800053fa:	95de                	add	a1,a1,s7
    800053fc:	855a                	mv	a0,s6
    800053fe:	ffffc097          	auipc	ra,0xffffc
    80005402:	cb8080e7          	jalr	-840(ra) # 800010b6 <walkaddr>
    80005406:	862a                	mv	a2,a0
    if(pa == 0)
    80005408:	dd4d                	beqz	a0,800053c2 <exec+0xe6>
    if(sz - i < PGSIZE)
    8000540a:	412984bb          	subw	s1,s3,s2
    8000540e:	0004879b          	sext.w	a5,s1
    80005412:	fcfcf0e3          	bgeu	s9,a5,800053d2 <exec+0xf6>
    80005416:	84d6                	mv	s1,s5
    80005418:	bf6d                	j	800053d2 <exec+0xf6>
    sz = sz1;
    8000541a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000541e:	2d85                	addiw	s11,s11,1
    80005420:	038d0d1b          	addiw	s10,s10,56
    80005424:	e8845783          	lhu	a5,-376(s0)
    80005428:	08fdd663          	bge	s11,a5,800054b4 <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000542c:	2d01                	sext.w	s10,s10
    8000542e:	03800713          	li	a4,56
    80005432:	86ea                	mv	a3,s10
    80005434:	e1840613          	addi	a2,s0,-488
    80005438:	4581                	li	a1,0
    8000543a:	8552                	mv	a0,s4
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	bea080e7          	jalr	-1046(ra) # 80004026 <readi>
    80005444:	03800793          	li	a5,56
    80005448:	20f51063          	bne	a0,a5,80005648 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    8000544c:	e1842783          	lw	a5,-488(s0)
    80005450:	4705                	li	a4,1
    80005452:	fce796e3          	bne	a5,a4,8000541e <exec+0x142>
    if(ph.memsz < ph.filesz)
    80005456:	e4043483          	ld	s1,-448(s0)
    8000545a:	e3843783          	ld	a5,-456(s0)
    8000545e:	1ef4e963          	bltu	s1,a5,80005650 <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005462:	e2843783          	ld	a5,-472(s0)
    80005466:	94be                	add	s1,s1,a5
    80005468:	1ef4e863          	bltu	s1,a5,80005658 <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    8000546c:	df043703          	ld	a4,-528(s0)
    80005470:	8ff9                	and	a5,a5,a4
    80005472:	1e079763          	bnez	a5,80005660 <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005476:	e1c42503          	lw	a0,-484(s0)
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	e48080e7          	jalr	-440(ra) # 800052c2 <flags2perm>
    80005482:	86aa                	mv	a3,a0
    80005484:	8626                	mv	a2,s1
    80005486:	85ca                	mv	a1,s2
    80005488:	855a                	mv	a0,s6
    8000548a:	ffffc097          	auipc	ra,0xffffc
    8000548e:	ff0080e7          	jalr	-16(ra) # 8000147a <uvmalloc>
    80005492:	e0a43423          	sd	a0,-504(s0)
    80005496:	1c050963          	beqz	a0,80005668 <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000549a:	e2843b83          	ld	s7,-472(s0)
    8000549e:	e2042c03          	lw	s8,-480(s0)
    800054a2:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054a6:	00098463          	beqz	s3,800054ae <exec+0x1d2>
    800054aa:	4901                	li	s2,0
    800054ac:	b7a1                	j	800053f4 <exec+0x118>
    sz = sz1;
    800054ae:	e0843903          	ld	s2,-504(s0)
    800054b2:	b7b5                	j	8000541e <exec+0x142>
    800054b4:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    800054b6:	8552                	mv	a0,s4
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	b1c080e7          	jalr	-1252(ra) # 80003fd4 <iunlockput>
  end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	2f6080e7          	jalr	758(ra) # 800047b6 <end_op>
  p = myproc();
    800054c8:	ffffc097          	auipc	ra,0xffffc
    800054cc:	582080e7          	jalr	1410(ra) # 80001a4a <myproc>
    800054d0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054d2:	10053c83          	ld	s9,256(a0)
  sz = PGROUNDUP(sz);
    800054d6:	6985                	lui	s3,0x1
    800054d8:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800054da:	99ca                	add	s3,s3,s2
    800054dc:	77fd                	lui	a5,0xfffff
    800054de:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054e2:	4691                	li	a3,4
    800054e4:	6609                	lui	a2,0x2
    800054e6:	964e                	add	a2,a2,s3
    800054e8:	85ce                	mv	a1,s3
    800054ea:	855a                	mv	a0,s6
    800054ec:	ffffc097          	auipc	ra,0xffffc
    800054f0:	f8e080e7          	jalr	-114(ra) # 8000147a <uvmalloc>
    800054f4:	892a                	mv	s2,a0
    800054f6:	e0a43423          	sd	a0,-504(s0)
    800054fa:	e519                	bnez	a0,80005508 <exec+0x22c>
  if(pagetable)
    800054fc:	e1343423          	sd	s3,-504(s0)
    80005500:	4a01                	li	s4,0
    80005502:	aaa5                	j	8000567a <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005504:	4901                	li	s2,0
    80005506:	bf45                	j	800054b6 <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005508:	75f9                	lui	a1,0xffffe
    8000550a:	95aa                	add	a1,a1,a0
    8000550c:	855a                	mv	a0,s6
    8000550e:	ffffc097          	auipc	ra,0xffffc
    80005512:	1a2080e7          	jalr	418(ra) # 800016b0 <uvmclear>
  stackbase = sp - PGSIZE;
    80005516:	7bfd                	lui	s7,0xfffff
    80005518:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000551a:	e0043783          	ld	a5,-512(s0)
    8000551e:	6388                	ld	a0,0(a5)
    80005520:	c52d                	beqz	a0,8000558a <exec+0x2ae>
    80005522:	e9040993          	addi	s3,s0,-368
    80005526:	f9040c13          	addi	s8,s0,-112
    8000552a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000552c:	ffffc097          	auipc	ra,0xffffc
    80005530:	97c080e7          	jalr	-1668(ra) # 80000ea8 <strlen>
    80005534:	0015079b          	addiw	a5,a0,1
    80005538:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000553c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005540:	13796863          	bltu	s2,s7,80005670 <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005544:	e0043d03          	ld	s10,-512(s0)
    80005548:	000d3a03          	ld	s4,0(s10)
    8000554c:	8552                	mv	a0,s4
    8000554e:	ffffc097          	auipc	ra,0xffffc
    80005552:	95a080e7          	jalr	-1702(ra) # 80000ea8 <strlen>
    80005556:	0015069b          	addiw	a3,a0,1
    8000555a:	8652                	mv	a2,s4
    8000555c:	85ca                	mv	a1,s2
    8000555e:	855a                	mv	a0,s6
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	182080e7          	jalr	386(ra) # 800016e2 <copyout>
    80005568:	10054663          	bltz	a0,80005674 <exec+0x398>
    ustack[argc] = sp;
    8000556c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005570:	0485                	addi	s1,s1,1
    80005572:	008d0793          	addi	a5,s10,8
    80005576:	e0f43023          	sd	a5,-512(s0)
    8000557a:	008d3503          	ld	a0,8(s10)
    8000557e:	c909                	beqz	a0,80005590 <exec+0x2b4>
    if(argc >= MAXARG)
    80005580:	09a1                	addi	s3,s3,8
    80005582:	fb8995e3          	bne	s3,s8,8000552c <exec+0x250>
  ip = 0;
    80005586:	4a01                	li	s4,0
    80005588:	a8cd                	j	8000567a <exec+0x39e>
  sp = sz;
    8000558a:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000558e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005590:	00349793          	slli	a5,s1,0x3
    80005594:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffda030>
    80005598:	97a2                	add	a5,a5,s0
    8000559a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000559e:	00148693          	addi	a3,s1,1
    800055a2:	068e                	slli	a3,a3,0x3
    800055a4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055a8:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800055ac:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800055b0:	f57966e3          	bltu	s2,s7,800054fc <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055b4:	e9040613          	addi	a2,s0,-368
    800055b8:	85ca                	mv	a1,s2
    800055ba:	855a                	mv	a0,s6
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	126080e7          	jalr	294(ra) # 800016e2 <copyout>
    800055c4:	0e054863          	bltz	a0,800056b4 <exec+0x3d8>
  p->trapframe->a1 = sp;
    800055c8:	110ab783          	ld	a5,272(s5) # 1110 <_entry-0x7fffeef0>
    800055cc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055d0:	df843783          	ld	a5,-520(s0)
    800055d4:	0007c703          	lbu	a4,0(a5)
    800055d8:	cf11                	beqz	a4,800055f4 <exec+0x318>
    800055da:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055dc:	02f00693          	li	a3,47
    800055e0:	a039                	j	800055ee <exec+0x312>
      last = s+1;
    800055e2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055e6:	0785                	addi	a5,a5,1
    800055e8:	fff7c703          	lbu	a4,-1(a5)
    800055ec:	c701                	beqz	a4,800055f4 <exec+0x318>
    if(*s == '/')
    800055ee:	fed71ce3          	bne	a4,a3,800055e6 <exec+0x30a>
    800055f2:	bfc5                	j	800055e2 <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    800055f4:	4641                	li	a2,16
    800055f6:	df843583          	ld	a1,-520(s0)
    800055fa:	210a8513          	addi	a0,s5,528
    800055fe:	ffffc097          	auipc	ra,0xffffc
    80005602:	878080e7          	jalr	-1928(ra) # 80000e76 <safestrcpy>
  oldpagetable = p->pagetable;
    80005606:	108ab503          	ld	a0,264(s5)
  p->pagetable = pagetable;
    8000560a:	116ab423          	sd	s6,264(s5)
  p->sz = sz;
    8000560e:	e0843783          	ld	a5,-504(s0)
    80005612:	10fab023          	sd	a5,256(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005616:	110ab783          	ld	a5,272(s5)
    8000561a:	e6843703          	ld	a4,-408(s0)
    8000561e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005620:	110ab783          	ld	a5,272(s5)
    80005624:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005628:	85e6                	mv	a1,s9
    8000562a:	ffffc097          	auipc	ra,0xffffc
    8000562e:	580080e7          	jalr	1408(ra) # 80001baa <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005632:	0004851b          	sext.w	a0,s1
    80005636:	79be                	ld	s3,488(sp)
    80005638:	7a1e                	ld	s4,480(sp)
    8000563a:	6afe                	ld	s5,472(sp)
    8000563c:	6b5e                	ld	s6,464(sp)
    8000563e:	6bbe                	ld	s7,456(sp)
    80005640:	6c1e                	ld	s8,448(sp)
    80005642:	7cfa                	ld	s9,440(sp)
    80005644:	7d5a                	ld	s10,432(sp)
    80005646:	b305                	j	80005366 <exec+0x8a>
    80005648:	e1243423          	sd	s2,-504(s0)
    8000564c:	7dba                	ld	s11,424(sp)
    8000564e:	a035                	j	8000567a <exec+0x39e>
    80005650:	e1243423          	sd	s2,-504(s0)
    80005654:	7dba                	ld	s11,424(sp)
    80005656:	a015                	j	8000567a <exec+0x39e>
    80005658:	e1243423          	sd	s2,-504(s0)
    8000565c:	7dba                	ld	s11,424(sp)
    8000565e:	a831                	j	8000567a <exec+0x39e>
    80005660:	e1243423          	sd	s2,-504(s0)
    80005664:	7dba                	ld	s11,424(sp)
    80005666:	a811                	j	8000567a <exec+0x39e>
    80005668:	e1243423          	sd	s2,-504(s0)
    8000566c:	7dba                	ld	s11,424(sp)
    8000566e:	a031                	j	8000567a <exec+0x39e>
  ip = 0;
    80005670:	4a01                	li	s4,0
    80005672:	a021                	j	8000567a <exec+0x39e>
    80005674:	4a01                	li	s4,0
  if(pagetable)
    80005676:	a011                	j	8000567a <exec+0x39e>
    80005678:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    8000567a:	e0843583          	ld	a1,-504(s0)
    8000567e:	855a                	mv	a0,s6
    80005680:	ffffc097          	auipc	ra,0xffffc
    80005684:	52a080e7          	jalr	1322(ra) # 80001baa <proc_freepagetable>
  return -1;
    80005688:	557d                	li	a0,-1
  if(ip){
    8000568a:	000a1b63          	bnez	s4,800056a0 <exec+0x3c4>
    8000568e:	79be                	ld	s3,488(sp)
    80005690:	7a1e                	ld	s4,480(sp)
    80005692:	6afe                	ld	s5,472(sp)
    80005694:	6b5e                	ld	s6,464(sp)
    80005696:	6bbe                	ld	s7,456(sp)
    80005698:	6c1e                	ld	s8,448(sp)
    8000569a:	7cfa                	ld	s9,440(sp)
    8000569c:	7d5a                	ld	s10,432(sp)
    8000569e:	b1e1                	j	80005366 <exec+0x8a>
    800056a0:	79be                	ld	s3,488(sp)
    800056a2:	6afe                	ld	s5,472(sp)
    800056a4:	6b5e                	ld	s6,464(sp)
    800056a6:	6bbe                	ld	s7,456(sp)
    800056a8:	6c1e                	ld	s8,448(sp)
    800056aa:	7cfa                	ld	s9,440(sp)
    800056ac:	7d5a                	ld	s10,432(sp)
    800056ae:	b14d                	j	80005350 <exec+0x74>
    800056b0:	6b5e                	ld	s6,464(sp)
    800056b2:	b979                	j	80005350 <exec+0x74>
  sz = sz1;
    800056b4:	e0843983          	ld	s3,-504(s0)
    800056b8:	b591                	j	800054fc <exec+0x220>

00000000800056ba <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056ba:	7179                	addi	sp,sp,-48
    800056bc:	f406                	sd	ra,40(sp)
    800056be:	f022                	sd	s0,32(sp)
    800056c0:	ec26                	sd	s1,24(sp)
    800056c2:	e84a                	sd	s2,16(sp)
    800056c4:	1800                	addi	s0,sp,48
    800056c6:	892e                	mv	s2,a1
    800056c8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800056ca:	fdc40593          	addi	a1,s0,-36
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	92c080e7          	jalr	-1748(ra) # 80002ffa <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056d6:	fdc42703          	lw	a4,-36(s0)
    800056da:	47bd                	li	a5,15
    800056dc:	02e7eb63          	bltu	a5,a4,80005712 <argfd+0x58>
    800056e0:	ffffc097          	auipc	ra,0xffffc
    800056e4:	36a080e7          	jalr	874(ra) # 80001a4a <myproc>
    800056e8:	fdc42703          	lw	a4,-36(s0)
    800056ec:	03070793          	addi	a5,a4,48
    800056f0:	078e                	slli	a5,a5,0x3
    800056f2:	953e                	add	a0,a0,a5
    800056f4:	651c                	ld	a5,8(a0)
    800056f6:	c385                	beqz	a5,80005716 <argfd+0x5c>
    return -1;
  if(pfd)
    800056f8:	00090463          	beqz	s2,80005700 <argfd+0x46>
    *pfd = fd;
    800056fc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005700:	4501                	li	a0,0
  if(pf)
    80005702:	c091                	beqz	s1,80005706 <argfd+0x4c>
    *pf = f;
    80005704:	e09c                	sd	a5,0(s1)
}
    80005706:	70a2                	ld	ra,40(sp)
    80005708:	7402                	ld	s0,32(sp)
    8000570a:	64e2                	ld	s1,24(sp)
    8000570c:	6942                	ld	s2,16(sp)
    8000570e:	6145                	addi	sp,sp,48
    80005710:	8082                	ret
    return -1;
    80005712:	557d                	li	a0,-1
    80005714:	bfcd                	j	80005706 <argfd+0x4c>
    80005716:	557d                	li	a0,-1
    80005718:	b7fd                	j	80005706 <argfd+0x4c>

000000008000571a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000571a:	1101                	addi	sp,sp,-32
    8000571c:	ec06                	sd	ra,24(sp)
    8000571e:	e822                	sd	s0,16(sp)
    80005720:	e426                	sd	s1,8(sp)
    80005722:	1000                	addi	s0,sp,32
    80005724:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005726:	ffffc097          	auipc	ra,0xffffc
    8000572a:	324080e7          	jalr	804(ra) # 80001a4a <myproc>
    8000572e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005730:	18850793          	addi	a5,a0,392
    80005734:	4501                	li	a0,0
    80005736:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005738:	6398                	ld	a4,0(a5)
    8000573a:	cb19                	beqz	a4,80005750 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000573c:	2505                	addiw	a0,a0,1
    8000573e:	07a1                	addi	a5,a5,8
    80005740:	fed51ce3          	bne	a0,a3,80005738 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005744:	557d                	li	a0,-1
}
    80005746:	60e2                	ld	ra,24(sp)
    80005748:	6442                	ld	s0,16(sp)
    8000574a:	64a2                	ld	s1,8(sp)
    8000574c:	6105                	addi	sp,sp,32
    8000574e:	8082                	ret
      p->ofile[fd] = f;
    80005750:	03050793          	addi	a5,a0,48
    80005754:	078e                	slli	a5,a5,0x3
    80005756:	963e                	add	a2,a2,a5
    80005758:	e604                	sd	s1,8(a2)
      return fd;
    8000575a:	b7f5                	j	80005746 <fdalloc+0x2c>

000000008000575c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000575c:	715d                	addi	sp,sp,-80
    8000575e:	e486                	sd	ra,72(sp)
    80005760:	e0a2                	sd	s0,64(sp)
    80005762:	fc26                	sd	s1,56(sp)
    80005764:	f84a                	sd	s2,48(sp)
    80005766:	f44e                	sd	s3,40(sp)
    80005768:	ec56                	sd	s5,24(sp)
    8000576a:	e85a                	sd	s6,16(sp)
    8000576c:	0880                	addi	s0,sp,80
    8000576e:	8b2e                	mv	s6,a1
    80005770:	89b2                	mv	s3,a2
    80005772:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005774:	fb040593          	addi	a1,s0,-80
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	de2080e7          	jalr	-542(ra) # 8000455a <nameiparent>
    80005780:	84aa                	mv	s1,a0
    80005782:	14050e63          	beqz	a0,800058de <create+0x182>
    return 0;

  ilock(dp);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	5e8080e7          	jalr	1512(ra) # 80003d6e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000578e:	4601                	li	a2,0
    80005790:	fb040593          	addi	a1,s0,-80
    80005794:	8526                	mv	a0,s1
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	ae4080e7          	jalr	-1308(ra) # 8000427a <dirlookup>
    8000579e:	8aaa                	mv	s5,a0
    800057a0:	c539                	beqz	a0,800057ee <create+0x92>
    iunlockput(dp);
    800057a2:	8526                	mv	a0,s1
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	830080e7          	jalr	-2000(ra) # 80003fd4 <iunlockput>
    ilock(ip);
    800057ac:	8556                	mv	a0,s5
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	5c0080e7          	jalr	1472(ra) # 80003d6e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057b6:	4789                	li	a5,2
    800057b8:	02fb1463          	bne	s6,a5,800057e0 <create+0x84>
    800057bc:	044ad783          	lhu	a5,68(s5)
    800057c0:	37f9                	addiw	a5,a5,-2
    800057c2:	17c2                	slli	a5,a5,0x30
    800057c4:	93c1                	srli	a5,a5,0x30
    800057c6:	4705                	li	a4,1
    800057c8:	00f76c63          	bltu	a4,a5,800057e0 <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800057cc:	8556                	mv	a0,s5
    800057ce:	60a6                	ld	ra,72(sp)
    800057d0:	6406                	ld	s0,64(sp)
    800057d2:	74e2                	ld	s1,56(sp)
    800057d4:	7942                	ld	s2,48(sp)
    800057d6:	79a2                	ld	s3,40(sp)
    800057d8:	6ae2                	ld	s5,24(sp)
    800057da:	6b42                	ld	s6,16(sp)
    800057dc:	6161                	addi	sp,sp,80
    800057de:	8082                	ret
    iunlockput(ip);
    800057e0:	8556                	mv	a0,s5
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	7f2080e7          	jalr	2034(ra) # 80003fd4 <iunlockput>
    return 0;
    800057ea:	4a81                	li	s5,0
    800057ec:	b7c5                	j	800057cc <create+0x70>
    800057ee:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    800057f0:	85da                	mv	a1,s6
    800057f2:	4088                	lw	a0,0(s1)
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	3d6080e7          	jalr	982(ra) # 80003bca <ialloc>
    800057fc:	8a2a                	mv	s4,a0
    800057fe:	c531                	beqz	a0,8000584a <create+0xee>
  ilock(ip);
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	56e080e7          	jalr	1390(ra) # 80003d6e <ilock>
  ip->major = major;
    80005808:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000580c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005810:	4905                	li	s2,1
    80005812:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005816:	8552                	mv	a0,s4
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	48a080e7          	jalr	1162(ra) # 80003ca2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005820:	032b0d63          	beq	s6,s2,8000585a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005824:	004a2603          	lw	a2,4(s4)
    80005828:	fb040593          	addi	a1,s0,-80
    8000582c:	8526                	mv	a0,s1
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	c5c080e7          	jalr	-932(ra) # 8000448a <dirlink>
    80005836:	08054163          	bltz	a0,800058b8 <create+0x15c>
  iunlockput(dp);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	798080e7          	jalr	1944(ra) # 80003fd4 <iunlockput>
  return ip;
    80005844:	8ad2                	mv	s5,s4
    80005846:	7a02                	ld	s4,32(sp)
    80005848:	b751                	j	800057cc <create+0x70>
    iunlockput(dp);
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	788080e7          	jalr	1928(ra) # 80003fd4 <iunlockput>
    return 0;
    80005854:	8ad2                	mv	s5,s4
    80005856:	7a02                	ld	s4,32(sp)
    80005858:	bf95                	j	800057cc <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000585a:	004a2603          	lw	a2,4(s4)
    8000585e:	00003597          	auipc	a1,0x3
    80005862:	d7a58593          	addi	a1,a1,-646 # 800085d8 <etext+0x5d8>
    80005866:	8552                	mv	a0,s4
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	c22080e7          	jalr	-990(ra) # 8000448a <dirlink>
    80005870:	04054463          	bltz	a0,800058b8 <create+0x15c>
    80005874:	40d0                	lw	a2,4(s1)
    80005876:	00003597          	auipc	a1,0x3
    8000587a:	d6a58593          	addi	a1,a1,-662 # 800085e0 <etext+0x5e0>
    8000587e:	8552                	mv	a0,s4
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	c0a080e7          	jalr	-1014(ra) # 8000448a <dirlink>
    80005888:	02054863          	bltz	a0,800058b8 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    8000588c:	004a2603          	lw	a2,4(s4)
    80005890:	fb040593          	addi	a1,s0,-80
    80005894:	8526                	mv	a0,s1
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	bf4080e7          	jalr	-1036(ra) # 8000448a <dirlink>
    8000589e:	00054d63          	bltz	a0,800058b8 <create+0x15c>
    dp->nlink++;  // for ".."
    800058a2:	04a4d783          	lhu	a5,74(s1)
    800058a6:	2785                	addiw	a5,a5,1
    800058a8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	3f4080e7          	jalr	1012(ra) # 80003ca2 <iupdate>
    800058b6:	b751                	j	8000583a <create+0xde>
  ip->nlink = 0;
    800058b8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800058bc:	8552                	mv	a0,s4
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	3e4080e7          	jalr	996(ra) # 80003ca2 <iupdate>
  iunlockput(ip);
    800058c6:	8552                	mv	a0,s4
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	70c080e7          	jalr	1804(ra) # 80003fd4 <iunlockput>
  iunlockput(dp);
    800058d0:	8526                	mv	a0,s1
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	702080e7          	jalr	1794(ra) # 80003fd4 <iunlockput>
  return 0;
    800058da:	7a02                	ld	s4,32(sp)
    800058dc:	bdc5                	j	800057cc <create+0x70>
    return 0;
    800058de:	8aaa                	mv	s5,a0
    800058e0:	b5f5                	j	800057cc <create+0x70>

00000000800058e2 <sys_dup>:
{
    800058e2:	7179                	addi	sp,sp,-48
    800058e4:	f406                	sd	ra,40(sp)
    800058e6:	f022                	sd	s0,32(sp)
    800058e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058ea:	fd840613          	addi	a2,s0,-40
    800058ee:	4581                	li	a1,0
    800058f0:	4501                	li	a0,0
    800058f2:	00000097          	auipc	ra,0x0
    800058f6:	dc8080e7          	jalr	-568(ra) # 800056ba <argfd>
    return -1;
    800058fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058fc:	02054763          	bltz	a0,8000592a <sys_dup+0x48>
    80005900:	ec26                	sd	s1,24(sp)
    80005902:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005904:	fd843903          	ld	s2,-40(s0)
    80005908:	854a                	mv	a0,s2
    8000590a:	00000097          	auipc	ra,0x0
    8000590e:	e10080e7          	jalr	-496(ra) # 8000571a <fdalloc>
    80005912:	84aa                	mv	s1,a0
    return -1;
    80005914:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005916:	00054f63          	bltz	a0,80005934 <sys_dup+0x52>
  filedup(f);
    8000591a:	854a                	mv	a0,s2
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	298080e7          	jalr	664(ra) # 80004bb4 <filedup>
  return fd;
    80005924:	87a6                	mv	a5,s1
    80005926:	64e2                	ld	s1,24(sp)
    80005928:	6942                	ld	s2,16(sp)
}
    8000592a:	853e                	mv	a0,a5
    8000592c:	70a2                	ld	ra,40(sp)
    8000592e:	7402                	ld	s0,32(sp)
    80005930:	6145                	addi	sp,sp,48
    80005932:	8082                	ret
    80005934:	64e2                	ld	s1,24(sp)
    80005936:	6942                	ld	s2,16(sp)
    80005938:	bfcd                	j	8000592a <sys_dup+0x48>

000000008000593a <sys_read>:
{
    8000593a:	7179                	addi	sp,sp,-48
    8000593c:	f406                	sd	ra,40(sp)
    8000593e:	f022                	sd	s0,32(sp)
    80005940:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005942:	fd840593          	addi	a1,s0,-40
    80005946:	4505                	li	a0,1
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	6d2080e7          	jalr	1746(ra) # 8000301a <argaddr>
  argint(2, &n);
    80005950:	fe440593          	addi	a1,s0,-28
    80005954:	4509                	li	a0,2
    80005956:	ffffd097          	auipc	ra,0xffffd
    8000595a:	6a4080e7          	jalr	1700(ra) # 80002ffa <argint>
  if(argfd(0, 0, &f) < 0)
    8000595e:	fe840613          	addi	a2,s0,-24
    80005962:	4581                	li	a1,0
    80005964:	4501                	li	a0,0
    80005966:	00000097          	auipc	ra,0x0
    8000596a:	d54080e7          	jalr	-684(ra) # 800056ba <argfd>
    8000596e:	87aa                	mv	a5,a0
    return -1;
    80005970:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005972:	0007cc63          	bltz	a5,8000598a <sys_read+0x50>
  return fileread(f, p, n);
    80005976:	fe442603          	lw	a2,-28(s0)
    8000597a:	fd843583          	ld	a1,-40(s0)
    8000597e:	fe843503          	ld	a0,-24(s0)
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	3d8080e7          	jalr	984(ra) # 80004d5a <fileread>
}
    8000598a:	70a2                	ld	ra,40(sp)
    8000598c:	7402                	ld	s0,32(sp)
    8000598e:	6145                	addi	sp,sp,48
    80005990:	8082                	ret

0000000080005992 <sys_write>:
{
    80005992:	7179                	addi	sp,sp,-48
    80005994:	f406                	sd	ra,40(sp)
    80005996:	f022                	sd	s0,32(sp)
    80005998:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000599a:	fd840593          	addi	a1,s0,-40
    8000599e:	4505                	li	a0,1
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	67a080e7          	jalr	1658(ra) # 8000301a <argaddr>
  argint(2, &n);
    800059a8:	fe440593          	addi	a1,s0,-28
    800059ac:	4509                	li	a0,2
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	64c080e7          	jalr	1612(ra) # 80002ffa <argint>
  if(argfd(0, 0, &f) < 0)
    800059b6:	fe840613          	addi	a2,s0,-24
    800059ba:	4581                	li	a1,0
    800059bc:	4501                	li	a0,0
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	cfc080e7          	jalr	-772(ra) # 800056ba <argfd>
    800059c6:	87aa                	mv	a5,a0
    return -1;
    800059c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059ca:	0007cc63          	bltz	a5,800059e2 <sys_write+0x50>
  return filewrite(f, p, n);
    800059ce:	fe442603          	lw	a2,-28(s0)
    800059d2:	fd843583          	ld	a1,-40(s0)
    800059d6:	fe843503          	ld	a0,-24(s0)
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	452080e7          	jalr	1106(ra) # 80004e2c <filewrite>
}
    800059e2:	70a2                	ld	ra,40(sp)
    800059e4:	7402                	ld	s0,32(sp)
    800059e6:	6145                	addi	sp,sp,48
    800059e8:	8082                	ret

00000000800059ea <sys_close>:
{
    800059ea:	1101                	addi	sp,sp,-32
    800059ec:	ec06                	sd	ra,24(sp)
    800059ee:	e822                	sd	s0,16(sp)
    800059f0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059f2:	fe040613          	addi	a2,s0,-32
    800059f6:	fec40593          	addi	a1,s0,-20
    800059fa:	4501                	li	a0,0
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	cbe080e7          	jalr	-834(ra) # 800056ba <argfd>
    return -1;
    80005a04:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a06:	02054563          	bltz	a0,80005a30 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005a0a:	ffffc097          	auipc	ra,0xffffc
    80005a0e:	040080e7          	jalr	64(ra) # 80001a4a <myproc>
    80005a12:	fec42783          	lw	a5,-20(s0)
    80005a16:	03078793          	addi	a5,a5,48
    80005a1a:	078e                	slli	a5,a5,0x3
    80005a1c:	953e                	add	a0,a0,a5
    80005a1e:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005a22:	fe043503          	ld	a0,-32(s0)
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	1e0080e7          	jalr	480(ra) # 80004c06 <fileclose>
  return 0;
    80005a2e:	4781                	li	a5,0
}
    80005a30:	853e                	mv	a0,a5
    80005a32:	60e2                	ld	ra,24(sp)
    80005a34:	6442                	ld	s0,16(sp)
    80005a36:	6105                	addi	sp,sp,32
    80005a38:	8082                	ret

0000000080005a3a <sys_fstat>:
{
    80005a3a:	1101                	addi	sp,sp,-32
    80005a3c:	ec06                	sd	ra,24(sp)
    80005a3e:	e822                	sd	s0,16(sp)
    80005a40:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a42:	fe040593          	addi	a1,s0,-32
    80005a46:	4505                	li	a0,1
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	5d2080e7          	jalr	1490(ra) # 8000301a <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a50:	fe840613          	addi	a2,s0,-24
    80005a54:	4581                	li	a1,0
    80005a56:	4501                	li	a0,0
    80005a58:	00000097          	auipc	ra,0x0
    80005a5c:	c62080e7          	jalr	-926(ra) # 800056ba <argfd>
    80005a60:	87aa                	mv	a5,a0
    return -1;
    80005a62:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a64:	0007ca63          	bltz	a5,80005a78 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a68:	fe043583          	ld	a1,-32(s0)
    80005a6c:	fe843503          	ld	a0,-24(s0)
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	278080e7          	jalr	632(ra) # 80004ce8 <filestat>
}
    80005a78:	60e2                	ld	ra,24(sp)
    80005a7a:	6442                	ld	s0,16(sp)
    80005a7c:	6105                	addi	sp,sp,32
    80005a7e:	8082                	ret

0000000080005a80 <sys_link>:
{
    80005a80:	7169                	addi	sp,sp,-304
    80005a82:	f606                	sd	ra,296(sp)
    80005a84:	f222                	sd	s0,288(sp)
    80005a86:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a88:	08000613          	li	a2,128
    80005a8c:	ed040593          	addi	a1,s0,-304
    80005a90:	4501                	li	a0,0
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	5a8080e7          	jalr	1448(ra) # 8000303a <argstr>
    return -1;
    80005a9a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a9c:	12054663          	bltz	a0,80005bc8 <sys_link+0x148>
    80005aa0:	08000613          	li	a2,128
    80005aa4:	f5040593          	addi	a1,s0,-176
    80005aa8:	4505                	li	a0,1
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	590080e7          	jalr	1424(ra) # 8000303a <argstr>
    return -1;
    80005ab2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ab4:	10054a63          	bltz	a0,80005bc8 <sys_link+0x148>
    80005ab8:	ee26                	sd	s1,280(sp)
  begin_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	c82080e7          	jalr	-894(ra) # 8000473c <begin_op>
  if((ip = namei(old)) == 0){
    80005ac2:	ed040513          	addi	a0,s0,-304
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	a76080e7          	jalr	-1418(ra) # 8000453c <namei>
    80005ace:	84aa                	mv	s1,a0
    80005ad0:	c949                	beqz	a0,80005b62 <sys_link+0xe2>
  ilock(ip);
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	29c080e7          	jalr	668(ra) # 80003d6e <ilock>
  if(ip->type == T_DIR){
    80005ada:	04449703          	lh	a4,68(s1)
    80005ade:	4785                	li	a5,1
    80005ae0:	08f70863          	beq	a4,a5,80005b70 <sys_link+0xf0>
    80005ae4:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005ae6:	04a4d783          	lhu	a5,74(s1)
    80005aea:	2785                	addiw	a5,a5,1
    80005aec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005af0:	8526                	mv	a0,s1
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	1b0080e7          	jalr	432(ra) # 80003ca2 <iupdate>
  iunlock(ip);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	338080e7          	jalr	824(ra) # 80003e34 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b04:	fd040593          	addi	a1,s0,-48
    80005b08:	f5040513          	addi	a0,s0,-176
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	a4e080e7          	jalr	-1458(ra) # 8000455a <nameiparent>
    80005b14:	892a                	mv	s2,a0
    80005b16:	cd35                	beqz	a0,80005b92 <sys_link+0x112>
  ilock(dp);
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	256080e7          	jalr	598(ra) # 80003d6e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b20:	00092703          	lw	a4,0(s2)
    80005b24:	409c                	lw	a5,0(s1)
    80005b26:	06f71163          	bne	a4,a5,80005b88 <sys_link+0x108>
    80005b2a:	40d0                	lw	a2,4(s1)
    80005b2c:	fd040593          	addi	a1,s0,-48
    80005b30:	854a                	mv	a0,s2
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	958080e7          	jalr	-1704(ra) # 8000448a <dirlink>
    80005b3a:	04054763          	bltz	a0,80005b88 <sys_link+0x108>
  iunlockput(dp);
    80005b3e:	854a                	mv	a0,s2
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	494080e7          	jalr	1172(ra) # 80003fd4 <iunlockput>
  iput(ip);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	3e2080e7          	jalr	994(ra) # 80003f2c <iput>
  end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	c64080e7          	jalr	-924(ra) # 800047b6 <end_op>
  return 0;
    80005b5a:	4781                	li	a5,0
    80005b5c:	64f2                	ld	s1,280(sp)
    80005b5e:	6952                	ld	s2,272(sp)
    80005b60:	a0a5                	j	80005bc8 <sys_link+0x148>
    end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	c54080e7          	jalr	-940(ra) # 800047b6 <end_op>
    return -1;
    80005b6a:	57fd                	li	a5,-1
    80005b6c:	64f2                	ld	s1,280(sp)
    80005b6e:	a8a9                	j	80005bc8 <sys_link+0x148>
    iunlockput(ip);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	462080e7          	jalr	1122(ra) # 80003fd4 <iunlockput>
    end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	c3c080e7          	jalr	-964(ra) # 800047b6 <end_op>
    return -1;
    80005b82:	57fd                	li	a5,-1
    80005b84:	64f2                	ld	s1,280(sp)
    80005b86:	a089                	j	80005bc8 <sys_link+0x148>
    iunlockput(dp);
    80005b88:	854a                	mv	a0,s2
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	44a080e7          	jalr	1098(ra) # 80003fd4 <iunlockput>
  ilock(ip);
    80005b92:	8526                	mv	a0,s1
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	1da080e7          	jalr	474(ra) # 80003d6e <ilock>
  ip->nlink--;
    80005b9c:	04a4d783          	lhu	a5,74(s1)
    80005ba0:	37fd                	addiw	a5,a5,-1
    80005ba2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	0fa080e7          	jalr	250(ra) # 80003ca2 <iupdate>
  iunlockput(ip);
    80005bb0:	8526                	mv	a0,s1
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	422080e7          	jalr	1058(ra) # 80003fd4 <iunlockput>
  end_op();
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	bfc080e7          	jalr	-1028(ra) # 800047b6 <end_op>
  return -1;
    80005bc2:	57fd                	li	a5,-1
    80005bc4:	64f2                	ld	s1,280(sp)
    80005bc6:	6952                	ld	s2,272(sp)
}
    80005bc8:	853e                	mv	a0,a5
    80005bca:	70b2                	ld	ra,296(sp)
    80005bcc:	7412                	ld	s0,288(sp)
    80005bce:	6155                	addi	sp,sp,304
    80005bd0:	8082                	ret

0000000080005bd2 <sys_unlink>:
{
    80005bd2:	7151                	addi	sp,sp,-240
    80005bd4:	f586                	sd	ra,232(sp)
    80005bd6:	f1a2                	sd	s0,224(sp)
    80005bd8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bda:	08000613          	li	a2,128
    80005bde:	f3040593          	addi	a1,s0,-208
    80005be2:	4501                	li	a0,0
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	456080e7          	jalr	1110(ra) # 8000303a <argstr>
    80005bec:	1a054a63          	bltz	a0,80005da0 <sys_unlink+0x1ce>
    80005bf0:	eda6                	sd	s1,216(sp)
  begin_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	b4a080e7          	jalr	-1206(ra) # 8000473c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bfa:	fb040593          	addi	a1,s0,-80
    80005bfe:	f3040513          	addi	a0,s0,-208
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	958080e7          	jalr	-1704(ra) # 8000455a <nameiparent>
    80005c0a:	84aa                	mv	s1,a0
    80005c0c:	cd71                	beqz	a0,80005ce8 <sys_unlink+0x116>
  ilock(dp);
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	160080e7          	jalr	352(ra) # 80003d6e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c16:	00003597          	auipc	a1,0x3
    80005c1a:	9c258593          	addi	a1,a1,-1598 # 800085d8 <etext+0x5d8>
    80005c1e:	fb040513          	addi	a0,s0,-80
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	63e080e7          	jalr	1598(ra) # 80004260 <namecmp>
    80005c2a:	14050c63          	beqz	a0,80005d82 <sys_unlink+0x1b0>
    80005c2e:	00003597          	auipc	a1,0x3
    80005c32:	9b258593          	addi	a1,a1,-1614 # 800085e0 <etext+0x5e0>
    80005c36:	fb040513          	addi	a0,s0,-80
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	626080e7          	jalr	1574(ra) # 80004260 <namecmp>
    80005c42:	14050063          	beqz	a0,80005d82 <sys_unlink+0x1b0>
    80005c46:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c48:	f2c40613          	addi	a2,s0,-212
    80005c4c:	fb040593          	addi	a1,s0,-80
    80005c50:	8526                	mv	a0,s1
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	628080e7          	jalr	1576(ra) # 8000427a <dirlookup>
    80005c5a:	892a                	mv	s2,a0
    80005c5c:	12050263          	beqz	a0,80005d80 <sys_unlink+0x1ae>
  ilock(ip);
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	10e080e7          	jalr	270(ra) # 80003d6e <ilock>
  if(ip->nlink < 1)
    80005c68:	04a91783          	lh	a5,74(s2)
    80005c6c:	08f05563          	blez	a5,80005cf6 <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c70:	04491703          	lh	a4,68(s2)
    80005c74:	4785                	li	a5,1
    80005c76:	08f70963          	beq	a4,a5,80005d08 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80005c7a:	4641                	li	a2,16
    80005c7c:	4581                	li	a1,0
    80005c7e:	fc040513          	addi	a0,s0,-64
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	0b2080e7          	jalr	178(ra) # 80000d34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c8a:	4741                	li	a4,16
    80005c8c:	f2c42683          	lw	a3,-212(s0)
    80005c90:	fc040613          	addi	a2,s0,-64
    80005c94:	4581                	li	a1,0
    80005c96:	8526                	mv	a0,s1
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	49e080e7          	jalr	1182(ra) # 80004136 <writei>
    80005ca0:	47c1                	li	a5,16
    80005ca2:	0af51b63          	bne	a0,a5,80005d58 <sys_unlink+0x186>
  if(ip->type == T_DIR){
    80005ca6:	04491703          	lh	a4,68(s2)
    80005caa:	4785                	li	a5,1
    80005cac:	0af70f63          	beq	a4,a5,80005d6a <sys_unlink+0x198>
  iunlockput(dp);
    80005cb0:	8526                	mv	a0,s1
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	322080e7          	jalr	802(ra) # 80003fd4 <iunlockput>
  ip->nlink--;
    80005cba:	04a95783          	lhu	a5,74(s2)
    80005cbe:	37fd                	addiw	a5,a5,-1
    80005cc0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	fdc080e7          	jalr	-36(ra) # 80003ca2 <iupdate>
  iunlockput(ip);
    80005cce:	854a                	mv	a0,s2
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	304080e7          	jalr	772(ra) # 80003fd4 <iunlockput>
  end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	ade080e7          	jalr	-1314(ra) # 800047b6 <end_op>
  return 0;
    80005ce0:	4501                	li	a0,0
    80005ce2:	64ee                	ld	s1,216(sp)
    80005ce4:	694e                	ld	s2,208(sp)
    80005ce6:	a84d                	j	80005d98 <sys_unlink+0x1c6>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	ace080e7          	jalr	-1330(ra) # 800047b6 <end_op>
    return -1;
    80005cf0:	557d                	li	a0,-1
    80005cf2:	64ee                	ld	s1,216(sp)
    80005cf4:	a055                	j	80005d98 <sys_unlink+0x1c6>
    80005cf6:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005cf8:	00003517          	auipc	a0,0x3
    80005cfc:	8f050513          	addi	a0,a0,-1808 # 800085e8 <etext+0x5e8>
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	860080e7          	jalr	-1952(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d08:	04c92703          	lw	a4,76(s2)
    80005d0c:	02000793          	li	a5,32
    80005d10:	f6e7f5e3          	bgeu	a5,a4,80005c7a <sys_unlink+0xa8>
    80005d14:	e5ce                	sd	s3,200(sp)
    80005d16:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d1a:	4741                	li	a4,16
    80005d1c:	86ce                	mv	a3,s3
    80005d1e:	f1840613          	addi	a2,s0,-232
    80005d22:	4581                	li	a1,0
    80005d24:	854a                	mv	a0,s2
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	300080e7          	jalr	768(ra) # 80004026 <readi>
    80005d2e:	47c1                	li	a5,16
    80005d30:	00f51c63          	bne	a0,a5,80005d48 <sys_unlink+0x176>
    if(de.inum != 0)
    80005d34:	f1845783          	lhu	a5,-232(s0)
    80005d38:	e7b5                	bnez	a5,80005da4 <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d3a:	29c1                	addiw	s3,s3,16
    80005d3c:	04c92783          	lw	a5,76(s2)
    80005d40:	fcf9ede3          	bltu	s3,a5,80005d1a <sys_unlink+0x148>
    80005d44:	69ae                	ld	s3,200(sp)
    80005d46:	bf15                	j	80005c7a <sys_unlink+0xa8>
      panic("isdirempty: readi");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	8b850513          	addi	a0,a0,-1864 # 80008600 <etext+0x600>
    80005d50:	ffffb097          	auipc	ra,0xffffb
    80005d54:	810080e7          	jalr	-2032(ra) # 80000560 <panic>
    80005d58:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005d5a:	00003517          	auipc	a0,0x3
    80005d5e:	8be50513          	addi	a0,a0,-1858 # 80008618 <etext+0x618>
    80005d62:	ffffa097          	auipc	ra,0xffffa
    80005d66:	7fe080e7          	jalr	2046(ra) # 80000560 <panic>
    dp->nlink--;
    80005d6a:	04a4d783          	lhu	a5,74(s1)
    80005d6e:	37fd                	addiw	a5,a5,-1
    80005d70:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d74:	8526                	mv	a0,s1
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	f2c080e7          	jalr	-212(ra) # 80003ca2 <iupdate>
    80005d7e:	bf0d                	j	80005cb0 <sys_unlink+0xde>
    80005d80:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005d82:	8526                	mv	a0,s1
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	250080e7          	jalr	592(ra) # 80003fd4 <iunlockput>
  end_op();
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	a2a080e7          	jalr	-1494(ra) # 800047b6 <end_op>
  return -1;
    80005d94:	557d                	li	a0,-1
    80005d96:	64ee                	ld	s1,216(sp)
}
    80005d98:	70ae                	ld	ra,232(sp)
    80005d9a:	740e                	ld	s0,224(sp)
    80005d9c:	616d                	addi	sp,sp,240
    80005d9e:	8082                	ret
    return -1;
    80005da0:	557d                	li	a0,-1
    80005da2:	bfdd                	j	80005d98 <sys_unlink+0x1c6>
    iunlockput(ip);
    80005da4:	854a                	mv	a0,s2
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	22e080e7          	jalr	558(ra) # 80003fd4 <iunlockput>
    goto bad;
    80005dae:	694e                	ld	s2,208(sp)
    80005db0:	69ae                	ld	s3,200(sp)
    80005db2:	bfc1                	j	80005d82 <sys_unlink+0x1b0>

0000000080005db4 <sys_open>:

uint64
sys_open(void)
{
    80005db4:	7131                	addi	sp,sp,-192
    80005db6:	fd06                	sd	ra,184(sp)
    80005db8:	f922                	sd	s0,176(sp)
    80005dba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005dbc:	f4c40593          	addi	a1,s0,-180
    80005dc0:	4505                	li	a0,1
    80005dc2:	ffffd097          	auipc	ra,0xffffd
    80005dc6:	238080e7          	jalr	568(ra) # 80002ffa <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005dca:	08000613          	li	a2,128
    80005dce:	f5040593          	addi	a1,s0,-176
    80005dd2:	4501                	li	a0,0
    80005dd4:	ffffd097          	auipc	ra,0xffffd
    80005dd8:	266080e7          	jalr	614(ra) # 8000303a <argstr>
    80005ddc:	87aa                	mv	a5,a0
    return -1;
    80005dde:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005de0:	0a07ce63          	bltz	a5,80005e9c <sys_open+0xe8>
    80005de4:	f526                	sd	s1,168(sp)

  begin_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	956080e7          	jalr	-1706(ra) # 8000473c <begin_op>

  if(omode & O_CREATE){
    80005dee:	f4c42783          	lw	a5,-180(s0)
    80005df2:	2007f793          	andi	a5,a5,512
    80005df6:	cfd5                	beqz	a5,80005eb2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005df8:	4681                	li	a3,0
    80005dfa:	4601                	li	a2,0
    80005dfc:	4589                	li	a1,2
    80005dfe:	f5040513          	addi	a0,s0,-176
    80005e02:	00000097          	auipc	ra,0x0
    80005e06:	95a080e7          	jalr	-1702(ra) # 8000575c <create>
    80005e0a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e0c:	cd41                	beqz	a0,80005ea4 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e0e:	04449703          	lh	a4,68(s1)
    80005e12:	478d                	li	a5,3
    80005e14:	00f71763          	bne	a4,a5,80005e22 <sys_open+0x6e>
    80005e18:	0464d703          	lhu	a4,70(s1)
    80005e1c:	47a5                	li	a5,9
    80005e1e:	0ee7e163          	bltu	a5,a4,80005f00 <sys_open+0x14c>
    80005e22:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	d26080e7          	jalr	-730(ra) # 80004b4a <filealloc>
    80005e2c:	892a                	mv	s2,a0
    80005e2e:	c97d                	beqz	a0,80005f24 <sys_open+0x170>
    80005e30:	ed4e                	sd	s3,152(sp)
    80005e32:	00000097          	auipc	ra,0x0
    80005e36:	8e8080e7          	jalr	-1816(ra) # 8000571a <fdalloc>
    80005e3a:	89aa                	mv	s3,a0
    80005e3c:	0c054e63          	bltz	a0,80005f18 <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e40:	04449703          	lh	a4,68(s1)
    80005e44:	478d                	li	a5,3
    80005e46:	0ef70c63          	beq	a4,a5,80005f3e <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e4a:	4789                	li	a5,2
    80005e4c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005e50:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005e54:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005e58:	f4c42783          	lw	a5,-180(s0)
    80005e5c:	0017c713          	xori	a4,a5,1
    80005e60:	8b05                	andi	a4,a4,1
    80005e62:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e66:	0037f713          	andi	a4,a5,3
    80005e6a:	00e03733          	snez	a4,a4
    80005e6e:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e72:	4007f793          	andi	a5,a5,1024
    80005e76:	c791                	beqz	a5,80005e82 <sys_open+0xce>
    80005e78:	04449703          	lh	a4,68(s1)
    80005e7c:	4789                	li	a5,2
    80005e7e:	0cf70763          	beq	a4,a5,80005f4c <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    80005e82:	8526                	mv	a0,s1
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	fb0080e7          	jalr	-80(ra) # 80003e34 <iunlock>
  end_op();
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	92a080e7          	jalr	-1750(ra) # 800047b6 <end_op>

  return fd;
    80005e94:	854e                	mv	a0,s3
    80005e96:	74aa                	ld	s1,168(sp)
    80005e98:	790a                	ld	s2,160(sp)
    80005e9a:	69ea                	ld	s3,152(sp)
}
    80005e9c:	70ea                	ld	ra,184(sp)
    80005e9e:	744a                	ld	s0,176(sp)
    80005ea0:	6129                	addi	sp,sp,192
    80005ea2:	8082                	ret
      end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	912080e7          	jalr	-1774(ra) # 800047b6 <end_op>
      return -1;
    80005eac:	557d                	li	a0,-1
    80005eae:	74aa                	ld	s1,168(sp)
    80005eb0:	b7f5                	j	80005e9c <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    80005eb2:	f5040513          	addi	a0,s0,-176
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	686080e7          	jalr	1670(ra) # 8000453c <namei>
    80005ebe:	84aa                	mv	s1,a0
    80005ec0:	c90d                	beqz	a0,80005ef2 <sys_open+0x13e>
    ilock(ip);
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	eac080e7          	jalr	-340(ra) # 80003d6e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005eca:	04449703          	lh	a4,68(s1)
    80005ece:	4785                	li	a5,1
    80005ed0:	f2f71fe3          	bne	a4,a5,80005e0e <sys_open+0x5a>
    80005ed4:	f4c42783          	lw	a5,-180(s0)
    80005ed8:	d7a9                	beqz	a5,80005e22 <sys_open+0x6e>
      iunlockput(ip);
    80005eda:	8526                	mv	a0,s1
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	0f8080e7          	jalr	248(ra) # 80003fd4 <iunlockput>
      end_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	8d2080e7          	jalr	-1838(ra) # 800047b6 <end_op>
      return -1;
    80005eec:	557d                	li	a0,-1
    80005eee:	74aa                	ld	s1,168(sp)
    80005ef0:	b775                	j	80005e9c <sys_open+0xe8>
      end_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	8c4080e7          	jalr	-1852(ra) # 800047b6 <end_op>
      return -1;
    80005efa:	557d                	li	a0,-1
    80005efc:	74aa                	ld	s1,168(sp)
    80005efe:	bf79                	j	80005e9c <sys_open+0xe8>
    iunlockput(ip);
    80005f00:	8526                	mv	a0,s1
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	0d2080e7          	jalr	210(ra) # 80003fd4 <iunlockput>
    end_op();
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	8ac080e7          	jalr	-1876(ra) # 800047b6 <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
    80005f14:	74aa                	ld	s1,168(sp)
    80005f16:	b759                	j	80005e9c <sys_open+0xe8>
      fileclose(f);
    80005f18:	854a                	mv	a0,s2
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	cec080e7          	jalr	-788(ra) # 80004c06 <fileclose>
    80005f22:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80005f24:	8526                	mv	a0,s1
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	0ae080e7          	jalr	174(ra) # 80003fd4 <iunlockput>
    end_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	888080e7          	jalr	-1912(ra) # 800047b6 <end_op>
    return -1;
    80005f36:	557d                	li	a0,-1
    80005f38:	74aa                	ld	s1,168(sp)
    80005f3a:	790a                	ld	s2,160(sp)
    80005f3c:	b785                	j	80005e9c <sys_open+0xe8>
    f->type = FD_DEVICE;
    80005f3e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005f42:	04649783          	lh	a5,70(s1)
    80005f46:	02f91223          	sh	a5,36(s2)
    80005f4a:	b729                	j	80005e54 <sys_open+0xa0>
    itrunc(ip);
    80005f4c:	8526                	mv	a0,s1
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	f32080e7          	jalr	-206(ra) # 80003e80 <itrunc>
    80005f56:	b735                	j	80005e82 <sys_open+0xce>

0000000080005f58 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f58:	7175                	addi	sp,sp,-144
    80005f5a:	e506                	sd	ra,136(sp)
    80005f5c:	e122                	sd	s0,128(sp)
    80005f5e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	7dc080e7          	jalr	2012(ra) # 8000473c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f68:	08000613          	li	a2,128
    80005f6c:	f7040593          	addi	a1,s0,-144
    80005f70:	4501                	li	a0,0
    80005f72:	ffffd097          	auipc	ra,0xffffd
    80005f76:	0c8080e7          	jalr	200(ra) # 8000303a <argstr>
    80005f7a:	02054963          	bltz	a0,80005fac <sys_mkdir+0x54>
    80005f7e:	4681                	li	a3,0
    80005f80:	4601                	li	a2,0
    80005f82:	4585                	li	a1,1
    80005f84:	f7040513          	addi	a0,s0,-144
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	7d4080e7          	jalr	2004(ra) # 8000575c <create>
    80005f90:	cd11                	beqz	a0,80005fac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	042080e7          	jalr	66(ra) # 80003fd4 <iunlockput>
  end_op();
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	81c080e7          	jalr	-2020(ra) # 800047b6 <end_op>
  return 0;
    80005fa2:	4501                	li	a0,0
}
    80005fa4:	60aa                	ld	ra,136(sp)
    80005fa6:	640a                	ld	s0,128(sp)
    80005fa8:	6149                	addi	sp,sp,144
    80005faa:	8082                	ret
    end_op();
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	80a080e7          	jalr	-2038(ra) # 800047b6 <end_op>
    return -1;
    80005fb4:	557d                	li	a0,-1
    80005fb6:	b7fd                	j	80005fa4 <sys_mkdir+0x4c>

0000000080005fb8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fb8:	7135                	addi	sp,sp,-160
    80005fba:	ed06                	sd	ra,152(sp)
    80005fbc:	e922                	sd	s0,144(sp)
    80005fbe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fc0:	ffffe097          	auipc	ra,0xffffe
    80005fc4:	77c080e7          	jalr	1916(ra) # 8000473c <begin_op>
  argint(1, &major);
    80005fc8:	f6c40593          	addi	a1,s0,-148
    80005fcc:	4505                	li	a0,1
    80005fce:	ffffd097          	auipc	ra,0xffffd
    80005fd2:	02c080e7          	jalr	44(ra) # 80002ffa <argint>
  argint(2, &minor);
    80005fd6:	f6840593          	addi	a1,s0,-152
    80005fda:	4509                	li	a0,2
    80005fdc:	ffffd097          	auipc	ra,0xffffd
    80005fe0:	01e080e7          	jalr	30(ra) # 80002ffa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fe4:	08000613          	li	a2,128
    80005fe8:	f7040593          	addi	a1,s0,-144
    80005fec:	4501                	li	a0,0
    80005fee:	ffffd097          	auipc	ra,0xffffd
    80005ff2:	04c080e7          	jalr	76(ra) # 8000303a <argstr>
    80005ff6:	02054b63          	bltz	a0,8000602c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ffa:	f6841683          	lh	a3,-152(s0)
    80005ffe:	f6c41603          	lh	a2,-148(s0)
    80006002:	458d                	li	a1,3
    80006004:	f7040513          	addi	a0,s0,-144
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	754080e7          	jalr	1876(ra) # 8000575c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006010:	cd11                	beqz	a0,8000602c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006012:	ffffe097          	auipc	ra,0xffffe
    80006016:	fc2080e7          	jalr	-62(ra) # 80003fd4 <iunlockput>
  end_op();
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	79c080e7          	jalr	1948(ra) # 800047b6 <end_op>
  return 0;
    80006022:	4501                	li	a0,0
}
    80006024:	60ea                	ld	ra,152(sp)
    80006026:	644a                	ld	s0,144(sp)
    80006028:	610d                	addi	sp,sp,160
    8000602a:	8082                	ret
    end_op();
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	78a080e7          	jalr	1930(ra) # 800047b6 <end_op>
    return -1;
    80006034:	557d                	li	a0,-1
    80006036:	b7fd                	j	80006024 <sys_mknod+0x6c>

0000000080006038 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006038:	7135                	addi	sp,sp,-160
    8000603a:	ed06                	sd	ra,152(sp)
    8000603c:	e922                	sd	s0,144(sp)
    8000603e:	e14a                	sd	s2,128(sp)
    80006040:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006042:	ffffc097          	auipc	ra,0xffffc
    80006046:	a08080e7          	jalr	-1528(ra) # 80001a4a <myproc>
    8000604a:	892a                	mv	s2,a0
  
  begin_op();
    8000604c:	ffffe097          	auipc	ra,0xffffe
    80006050:	6f0080e7          	jalr	1776(ra) # 8000473c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006054:	08000613          	li	a2,128
    80006058:	f6040593          	addi	a1,s0,-160
    8000605c:	4501                	li	a0,0
    8000605e:	ffffd097          	auipc	ra,0xffffd
    80006062:	fdc080e7          	jalr	-36(ra) # 8000303a <argstr>
    80006066:	04054d63          	bltz	a0,800060c0 <sys_chdir+0x88>
    8000606a:	e526                	sd	s1,136(sp)
    8000606c:	f6040513          	addi	a0,s0,-160
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	4cc080e7          	jalr	1228(ra) # 8000453c <namei>
    80006078:	84aa                	mv	s1,a0
    8000607a:	c131                	beqz	a0,800060be <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	cf2080e7          	jalr	-782(ra) # 80003d6e <ilock>
  if(ip->type != T_DIR){
    80006084:	04449703          	lh	a4,68(s1)
    80006088:	4785                	li	a5,1
    8000608a:	04f71163          	bne	a4,a5,800060cc <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000608e:	8526                	mv	a0,s1
    80006090:	ffffe097          	auipc	ra,0xffffe
    80006094:	da4080e7          	jalr	-604(ra) # 80003e34 <iunlock>
  iput(p->cwd);
    80006098:	20893503          	ld	a0,520(s2)
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	e90080e7          	jalr	-368(ra) # 80003f2c <iput>
  end_op();
    800060a4:	ffffe097          	auipc	ra,0xffffe
    800060a8:	712080e7          	jalr	1810(ra) # 800047b6 <end_op>
  p->cwd = ip;
    800060ac:	20993423          	sd	s1,520(s2)
  return 0;
    800060b0:	4501                	li	a0,0
    800060b2:	64aa                	ld	s1,136(sp)
}
    800060b4:	60ea                	ld	ra,152(sp)
    800060b6:	644a                	ld	s0,144(sp)
    800060b8:	690a                	ld	s2,128(sp)
    800060ba:	610d                	addi	sp,sp,160
    800060bc:	8082                	ret
    800060be:	64aa                	ld	s1,136(sp)
    end_op();
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	6f6080e7          	jalr	1782(ra) # 800047b6 <end_op>
    return -1;
    800060c8:	557d                	li	a0,-1
    800060ca:	b7ed                	j	800060b4 <sys_chdir+0x7c>
    iunlockput(ip);
    800060cc:	8526                	mv	a0,s1
    800060ce:	ffffe097          	auipc	ra,0xffffe
    800060d2:	f06080e7          	jalr	-250(ra) # 80003fd4 <iunlockput>
    end_op();
    800060d6:	ffffe097          	auipc	ra,0xffffe
    800060da:	6e0080e7          	jalr	1760(ra) # 800047b6 <end_op>
    return -1;
    800060de:	557d                	li	a0,-1
    800060e0:	64aa                	ld	s1,136(sp)
    800060e2:	bfc9                	j	800060b4 <sys_chdir+0x7c>

00000000800060e4 <sys_exec>:

uint64
sys_exec(void)
{
    800060e4:	7121                	addi	sp,sp,-448
    800060e6:	ff06                	sd	ra,440(sp)
    800060e8:	fb22                	sd	s0,432(sp)
    800060ea:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800060ec:	e4840593          	addi	a1,s0,-440
    800060f0:	4505                	li	a0,1
    800060f2:	ffffd097          	auipc	ra,0xffffd
    800060f6:	f28080e7          	jalr	-216(ra) # 8000301a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800060fa:	08000613          	li	a2,128
    800060fe:	f5040593          	addi	a1,s0,-176
    80006102:	4501                	li	a0,0
    80006104:	ffffd097          	auipc	ra,0xffffd
    80006108:	f36080e7          	jalr	-202(ra) # 8000303a <argstr>
    8000610c:	87aa                	mv	a5,a0
    return -1;
    8000610e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006110:	0e07c263          	bltz	a5,800061f4 <sys_exec+0x110>
    80006114:	f726                	sd	s1,424(sp)
    80006116:	f34a                	sd	s2,416(sp)
    80006118:	ef4e                	sd	s3,408(sp)
    8000611a:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    8000611c:	10000613          	li	a2,256
    80006120:	4581                	li	a1,0
    80006122:	e5040513          	addi	a0,s0,-432
    80006126:	ffffb097          	auipc	ra,0xffffb
    8000612a:	c0e080e7          	jalr	-1010(ra) # 80000d34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000612e:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006132:	89a6                	mv	s3,s1
    80006134:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006136:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000613a:	00391513          	slli	a0,s2,0x3
    8000613e:	e4040593          	addi	a1,s0,-448
    80006142:	e4843783          	ld	a5,-440(s0)
    80006146:	953e                	add	a0,a0,a5
    80006148:	ffffd097          	auipc	ra,0xffffd
    8000614c:	e0e080e7          	jalr	-498(ra) # 80002f56 <fetchaddr>
    80006150:	02054a63          	bltz	a0,80006184 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006154:	e4043783          	ld	a5,-448(s0)
    80006158:	c7b9                	beqz	a5,800061a6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	9ee080e7          	jalr	-1554(ra) # 80000b48 <kalloc>
    80006162:	85aa                	mv	a1,a0
    80006164:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006168:	cd11                	beqz	a0,80006184 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000616a:	6605                	lui	a2,0x1
    8000616c:	e4043503          	ld	a0,-448(s0)
    80006170:	ffffd097          	auipc	ra,0xffffd
    80006174:	e3c080e7          	jalr	-452(ra) # 80002fac <fetchstr>
    80006178:	00054663          	bltz	a0,80006184 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    8000617c:	0905                	addi	s2,s2,1
    8000617e:	09a1                	addi	s3,s3,8
    80006180:	fb491de3          	bne	s2,s4,8000613a <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006184:	f5040913          	addi	s2,s0,-176
    80006188:	6088                	ld	a0,0(s1)
    8000618a:	c125                	beqz	a0,800061ea <sys_exec+0x106>
    kfree(argv[i]);
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	8be080e7          	jalr	-1858(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006194:	04a1                	addi	s1,s1,8
    80006196:	ff2499e3          	bne	s1,s2,80006188 <sys_exec+0xa4>
  return -1;
    8000619a:	557d                	li	a0,-1
    8000619c:	74ba                	ld	s1,424(sp)
    8000619e:	791a                	ld	s2,416(sp)
    800061a0:	69fa                	ld	s3,408(sp)
    800061a2:	6a5a                	ld	s4,400(sp)
    800061a4:	a881                	j	800061f4 <sys_exec+0x110>
      argv[i] = 0;
    800061a6:	0009079b          	sext.w	a5,s2
    800061aa:	078e                	slli	a5,a5,0x3
    800061ac:	fd078793          	addi	a5,a5,-48
    800061b0:	97a2                	add	a5,a5,s0
    800061b2:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800061b6:	e5040593          	addi	a1,s0,-432
    800061ba:	f5040513          	addi	a0,s0,-176
    800061be:	fffff097          	auipc	ra,0xfffff
    800061c2:	11e080e7          	jalr	286(ra) # 800052dc <exec>
    800061c6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061c8:	f5040993          	addi	s3,s0,-176
    800061cc:	6088                	ld	a0,0(s1)
    800061ce:	c901                	beqz	a0,800061de <sys_exec+0xfa>
    kfree(argv[i]);
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	87a080e7          	jalr	-1926(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061d8:	04a1                	addi	s1,s1,8
    800061da:	ff3499e3          	bne	s1,s3,800061cc <sys_exec+0xe8>
  return ret;
    800061de:	854a                	mv	a0,s2
    800061e0:	74ba                	ld	s1,424(sp)
    800061e2:	791a                	ld	s2,416(sp)
    800061e4:	69fa                	ld	s3,408(sp)
    800061e6:	6a5a                	ld	s4,400(sp)
    800061e8:	a031                	j	800061f4 <sys_exec+0x110>
  return -1;
    800061ea:	557d                	li	a0,-1
    800061ec:	74ba                	ld	s1,424(sp)
    800061ee:	791a                	ld	s2,416(sp)
    800061f0:	69fa                	ld	s3,408(sp)
    800061f2:	6a5a                	ld	s4,400(sp)
}
    800061f4:	70fa                	ld	ra,440(sp)
    800061f6:	745a                	ld	s0,432(sp)
    800061f8:	6139                	addi	sp,sp,448
    800061fa:	8082                	ret

00000000800061fc <sys_pipe>:

uint64
sys_pipe(void)
{
    800061fc:	7139                	addi	sp,sp,-64
    800061fe:	fc06                	sd	ra,56(sp)
    80006200:	f822                	sd	s0,48(sp)
    80006202:	f426                	sd	s1,40(sp)
    80006204:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	844080e7          	jalr	-1980(ra) # 80001a4a <myproc>
    8000620e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006210:	fd840593          	addi	a1,s0,-40
    80006214:	4501                	li	a0,0
    80006216:	ffffd097          	auipc	ra,0xffffd
    8000621a:	e04080e7          	jalr	-508(ra) # 8000301a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000621e:	fc840593          	addi	a1,s0,-56
    80006222:	fd040513          	addi	a0,s0,-48
    80006226:	fffff097          	auipc	ra,0xfffff
    8000622a:	d4e080e7          	jalr	-690(ra) # 80004f74 <pipealloc>
    return -1;
    8000622e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006230:	0c054963          	bltz	a0,80006302 <sys_pipe+0x106>
  fd0 = -1;
    80006234:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006238:	fd043503          	ld	a0,-48(s0)
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	4de080e7          	jalr	1246(ra) # 8000571a <fdalloc>
    80006244:	fca42223          	sw	a0,-60(s0)
    80006248:	0a054063          	bltz	a0,800062e8 <sys_pipe+0xec>
    8000624c:	fc843503          	ld	a0,-56(s0)
    80006250:	fffff097          	auipc	ra,0xfffff
    80006254:	4ca080e7          	jalr	1226(ra) # 8000571a <fdalloc>
    80006258:	fca42023          	sw	a0,-64(s0)
    8000625c:	06054c63          	bltz	a0,800062d4 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006260:	4691                	li	a3,4
    80006262:	fc440613          	addi	a2,s0,-60
    80006266:	fd843583          	ld	a1,-40(s0)
    8000626a:	1084b503          	ld	a0,264(s1)
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	474080e7          	jalr	1140(ra) # 800016e2 <copyout>
    80006276:	02054163          	bltz	a0,80006298 <sys_pipe+0x9c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000627a:	4691                	li	a3,4
    8000627c:	fc040613          	addi	a2,s0,-64
    80006280:	fd843583          	ld	a1,-40(s0)
    80006284:	0591                	addi	a1,a1,4
    80006286:	1084b503          	ld	a0,264(s1)
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	458080e7          	jalr	1112(ra) # 800016e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006292:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006294:	06055763          	bgez	a0,80006302 <sys_pipe+0x106>
    p->ofile[fd0] = 0;
    80006298:	fc442783          	lw	a5,-60(s0)
    8000629c:	03078793          	addi	a5,a5,48
    800062a0:	078e                	slli	a5,a5,0x3
    800062a2:	97a6                	add	a5,a5,s1
    800062a4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800062a8:	fc042783          	lw	a5,-64(s0)
    800062ac:	03078793          	addi	a5,a5,48
    800062b0:	078e                	slli	a5,a5,0x3
    800062b2:	94be                	add	s1,s1,a5
    800062b4:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800062b8:	fd043503          	ld	a0,-48(s0)
    800062bc:	fffff097          	auipc	ra,0xfffff
    800062c0:	94a080e7          	jalr	-1718(ra) # 80004c06 <fileclose>
    fileclose(wf);
    800062c4:	fc843503          	ld	a0,-56(s0)
    800062c8:	fffff097          	auipc	ra,0xfffff
    800062cc:	93e080e7          	jalr	-1730(ra) # 80004c06 <fileclose>
    return -1;
    800062d0:	57fd                	li	a5,-1
    800062d2:	a805                	j	80006302 <sys_pipe+0x106>
    if(fd0 >= 0)
    800062d4:	fc442783          	lw	a5,-60(s0)
    800062d8:	0007c863          	bltz	a5,800062e8 <sys_pipe+0xec>
      p->ofile[fd0] = 0;
    800062dc:	03078793          	addi	a5,a5,48
    800062e0:	078e                	slli	a5,a5,0x3
    800062e2:	97a6                	add	a5,a5,s1
    800062e4:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    800062e8:	fd043503          	ld	a0,-48(s0)
    800062ec:	fffff097          	auipc	ra,0xfffff
    800062f0:	91a080e7          	jalr	-1766(ra) # 80004c06 <fileclose>
    fileclose(wf);
    800062f4:	fc843503          	ld	a0,-56(s0)
    800062f8:	fffff097          	auipc	ra,0xfffff
    800062fc:	90e080e7          	jalr	-1778(ra) # 80004c06 <fileclose>
    return -1;
    80006300:	57fd                	li	a5,-1
}
    80006302:	853e                	mv	a0,a5
    80006304:	70e2                	ld	ra,56(sp)
    80006306:	7442                	ld	s0,48(sp)
    80006308:	74a2                	ld	s1,40(sp)
    8000630a:	6121                	addi	sp,sp,64
    8000630c:	8082                	ret
	...

0000000080006310 <kernelvec>:
    80006310:	7111                	addi	sp,sp,-256
    80006312:	e006                	sd	ra,0(sp)
    80006314:	e40a                	sd	sp,8(sp)
    80006316:	e80e                	sd	gp,16(sp)
    80006318:	ec12                	sd	tp,24(sp)
    8000631a:	f016                	sd	t0,32(sp)
    8000631c:	f41a                	sd	t1,40(sp)
    8000631e:	f81e                	sd	t2,48(sp)
    80006320:	fc22                	sd	s0,56(sp)
    80006322:	e0a6                	sd	s1,64(sp)
    80006324:	e4aa                	sd	a0,72(sp)
    80006326:	e8ae                	sd	a1,80(sp)
    80006328:	ecb2                	sd	a2,88(sp)
    8000632a:	f0b6                	sd	a3,96(sp)
    8000632c:	f4ba                	sd	a4,104(sp)
    8000632e:	f8be                	sd	a5,112(sp)
    80006330:	fcc2                	sd	a6,120(sp)
    80006332:	e146                	sd	a7,128(sp)
    80006334:	e54a                	sd	s2,136(sp)
    80006336:	e94e                	sd	s3,144(sp)
    80006338:	ed52                	sd	s4,152(sp)
    8000633a:	f156                	sd	s5,160(sp)
    8000633c:	f55a                	sd	s6,168(sp)
    8000633e:	f95e                	sd	s7,176(sp)
    80006340:	fd62                	sd	s8,184(sp)
    80006342:	e1e6                	sd	s9,192(sp)
    80006344:	e5ea                	sd	s10,200(sp)
    80006346:	e9ee                	sd	s11,208(sp)
    80006348:	edf2                	sd	t3,216(sp)
    8000634a:	f1f6                	sd	t4,224(sp)
    8000634c:	f5fa                	sd	t5,232(sp)
    8000634e:	f9fe                	sd	t6,240(sp)
    80006350:	ac7fc0ef          	jal	80002e16 <kerneltrap>
    80006354:	6082                	ld	ra,0(sp)
    80006356:	6122                	ld	sp,8(sp)
    80006358:	61c2                	ld	gp,16(sp)
    8000635a:	7282                	ld	t0,32(sp)
    8000635c:	7322                	ld	t1,40(sp)
    8000635e:	73c2                	ld	t2,48(sp)
    80006360:	7462                	ld	s0,56(sp)
    80006362:	6486                	ld	s1,64(sp)
    80006364:	6526                	ld	a0,72(sp)
    80006366:	65c6                	ld	a1,80(sp)
    80006368:	6666                	ld	a2,88(sp)
    8000636a:	7686                	ld	a3,96(sp)
    8000636c:	7726                	ld	a4,104(sp)
    8000636e:	77c6                	ld	a5,112(sp)
    80006370:	7866                	ld	a6,120(sp)
    80006372:	688a                	ld	a7,128(sp)
    80006374:	692a                	ld	s2,136(sp)
    80006376:	69ca                	ld	s3,144(sp)
    80006378:	6a6a                	ld	s4,152(sp)
    8000637a:	7a8a                	ld	s5,160(sp)
    8000637c:	7b2a                	ld	s6,168(sp)
    8000637e:	7bca                	ld	s7,176(sp)
    80006380:	7c6a                	ld	s8,184(sp)
    80006382:	6c8e                	ld	s9,192(sp)
    80006384:	6d2e                	ld	s10,200(sp)
    80006386:	6dce                	ld	s11,208(sp)
    80006388:	6e6e                	ld	t3,216(sp)
    8000638a:	7e8e                	ld	t4,224(sp)
    8000638c:	7f2e                	ld	t5,232(sp)
    8000638e:	7fce                	ld	t6,240(sp)
    80006390:	6111                	addi	sp,sp,256
    80006392:	10200073          	sret
    80006396:	00000013          	nop
    8000639a:	00000013          	nop
    8000639e:	0001                	nop

00000000800063a0 <timervec>:
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	e10c                	sd	a1,0(a0)
    800063a6:	e510                	sd	a2,8(a0)
    800063a8:	e914                	sd	a3,16(a0)
    800063aa:	6d0c                	ld	a1,24(a0)
    800063ac:	7110                	ld	a2,32(a0)
    800063ae:	6194                	ld	a3,0(a1)
    800063b0:	96b2                	add	a3,a3,a2
    800063b2:	e194                	sd	a3,0(a1)
    800063b4:	4589                	li	a1,2
    800063b6:	14459073          	csrw	sip,a1
    800063ba:	6914                	ld	a3,16(a0)
    800063bc:	6510                	ld	a2,8(a0)
    800063be:	610c                	ld	a1,0(a0)
    800063c0:	34051573          	csrrw	a0,mscratch,a0
    800063c4:	30200073          	mret
	...

00000000800063ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ca:	1141                	addi	sp,sp,-16
    800063cc:	e422                	sd	s0,8(sp)
    800063ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063d0:	0c0007b7          	lui	a5,0xc000
    800063d4:	4705                	li	a4,1
    800063d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063d8:	0c0007b7          	lui	a5,0xc000
    800063dc:	c3d8                	sw	a4,4(a5)
}
    800063de:	6422                	ld	s0,8(sp)
    800063e0:	0141                	addi	sp,sp,16
    800063e2:	8082                	ret

00000000800063e4 <plicinithart>:

void
plicinithart(void)
{
    800063e4:	1141                	addi	sp,sp,-16
    800063e6:	e406                	sd	ra,8(sp)
    800063e8:	e022                	sd	s0,0(sp)
    800063ea:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063ec:	ffffb097          	auipc	ra,0xffffb
    800063f0:	632080e7          	jalr	1586(ra) # 80001a1e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063f4:	0085171b          	slliw	a4,a0,0x8
    800063f8:	0c0027b7          	lui	a5,0xc002
    800063fc:	97ba                	add	a5,a5,a4
    800063fe:	40200713          	li	a4,1026
    80006402:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006406:	00d5151b          	slliw	a0,a0,0xd
    8000640a:	0c2017b7          	lui	a5,0xc201
    8000640e:	97aa                	add	a5,a5,a0
    80006410:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006414:	60a2                	ld	ra,8(sp)
    80006416:	6402                	ld	s0,0(sp)
    80006418:	0141                	addi	sp,sp,16
    8000641a:	8082                	ret

000000008000641c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000641c:	1141                	addi	sp,sp,-16
    8000641e:	e406                	sd	ra,8(sp)
    80006420:	e022                	sd	s0,0(sp)
    80006422:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006424:	ffffb097          	auipc	ra,0xffffb
    80006428:	5fa080e7          	jalr	1530(ra) # 80001a1e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    8000642c:	00d5151b          	slliw	a0,a0,0xd
    80006430:	0c2017b7          	lui	a5,0xc201
    80006434:	97aa                	add	a5,a5,a0
  return irq;
}
    80006436:	43c8                	lw	a0,4(a5)
    80006438:	60a2                	ld	ra,8(sp)
    8000643a:	6402                	ld	s0,0(sp)
    8000643c:	0141                	addi	sp,sp,16
    8000643e:	8082                	ret

0000000080006440 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006440:	1101                	addi	sp,sp,-32
    80006442:	ec06                	sd	ra,24(sp)
    80006444:	e822                	sd	s0,16(sp)
    80006446:	e426                	sd	s1,8(sp)
    80006448:	1000                	addi	s0,sp,32
    8000644a:	84aa                	mv	s1,a0
  int hart = cpuid();
    8000644c:	ffffb097          	auipc	ra,0xffffb
    80006450:	5d2080e7          	jalr	1490(ra) # 80001a1e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006454:	00d5151b          	slliw	a0,a0,0xd
    80006458:	0c2017b7          	lui	a5,0xc201
    8000645c:	97aa                	add	a5,a5,a0
    8000645e:	c3c4                	sw	s1,4(a5)
}
    80006460:	60e2                	ld	ra,24(sp)
    80006462:	6442                	ld	s0,16(sp)
    80006464:	64a2                	ld	s1,8(sp)
    80006466:	6105                	addi	sp,sp,32
    80006468:	8082                	ret

000000008000646a <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000646a:	1141                	addi	sp,sp,-16
    8000646c:	e406                	sd	ra,8(sp)
    8000646e:	e022                	sd	s0,0(sp)
    80006470:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006472:	479d                	li	a5,7
    80006474:	04a7cc63          	blt	a5,a0,800064cc <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006478:	0001f797          	auipc	a5,0x1f
    8000647c:	9a878793          	addi	a5,a5,-1624 # 80024e20 <disk>
    80006480:	97aa                	add	a5,a5,a0
    80006482:	0187c783          	lbu	a5,24(a5)
    80006486:	ebb9                	bnez	a5,800064dc <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006488:	00451693          	slli	a3,a0,0x4
    8000648c:	0001f797          	auipc	a5,0x1f
    80006490:	99478793          	addi	a5,a5,-1644 # 80024e20 <disk>
    80006494:	6398                	ld	a4,0(a5)
    80006496:	9736                	add	a4,a4,a3
    80006498:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    8000649c:	6398                	ld	a4,0(a5)
    8000649e:	9736                	add	a4,a4,a3
    800064a0:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800064a4:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800064a8:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800064ac:	97aa                	add	a5,a5,a0
    800064ae:	4705                	li	a4,1
    800064b0:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800064b4:	0001f517          	auipc	a0,0x1f
    800064b8:	98450513          	addi	a0,a0,-1660 # 80024e38 <disk+0x18>
    800064bc:	ffffc097          	auipc	ra,0xffffc
    800064c0:	d30080e7          	jalr	-720(ra) # 800021ec <wakeup>
}
    800064c4:	60a2                	ld	ra,8(sp)
    800064c6:	6402                	ld	s0,0(sp)
    800064c8:	0141                	addi	sp,sp,16
    800064ca:	8082                	ret
    panic("free_desc 1");
    800064cc:	00002517          	auipc	a0,0x2
    800064d0:	15c50513          	addi	a0,a0,348 # 80008628 <etext+0x628>
    800064d4:	ffffa097          	auipc	ra,0xffffa
    800064d8:	08c080e7          	jalr	140(ra) # 80000560 <panic>
    panic("free_desc 2");
    800064dc:	00002517          	auipc	a0,0x2
    800064e0:	15c50513          	addi	a0,a0,348 # 80008638 <etext+0x638>
    800064e4:	ffffa097          	auipc	ra,0xffffa
    800064e8:	07c080e7          	jalr	124(ra) # 80000560 <panic>

00000000800064ec <virtio_disk_init>:
{
    800064ec:	1101                	addi	sp,sp,-32
    800064ee:	ec06                	sd	ra,24(sp)
    800064f0:	e822                	sd	s0,16(sp)
    800064f2:	e426                	sd	s1,8(sp)
    800064f4:	e04a                	sd	s2,0(sp)
    800064f6:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064f8:	00002597          	auipc	a1,0x2
    800064fc:	15058593          	addi	a1,a1,336 # 80008648 <etext+0x648>
    80006500:	0001f517          	auipc	a0,0x1f
    80006504:	a4850513          	addi	a0,a0,-1464 # 80024f48 <disk+0x128>
    80006508:	ffffa097          	auipc	ra,0xffffa
    8000650c:	6a0080e7          	jalr	1696(ra) # 80000ba8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006510:	100017b7          	lui	a5,0x10001
    80006514:	4398                	lw	a4,0(a5)
    80006516:	2701                	sext.w	a4,a4
    80006518:	747277b7          	lui	a5,0x74727
    8000651c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006520:	18f71c63          	bne	a4,a5,800066b8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006524:	100017b7          	lui	a5,0x10001
    80006528:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    8000652a:	439c                	lw	a5,0(a5)
    8000652c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000652e:	4709                	li	a4,2
    80006530:	18e79463          	bne	a5,a4,800066b8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006534:	100017b7          	lui	a5,0x10001
    80006538:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    8000653a:	439c                	lw	a5,0(a5)
    8000653c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000653e:	16e79d63          	bne	a5,a4,800066b8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006542:	100017b7          	lui	a5,0x10001
    80006546:	47d8                	lw	a4,12(a5)
    80006548:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000654a:	554d47b7          	lui	a5,0x554d4
    8000654e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006552:	16f71363          	bne	a4,a5,800066b8 <virtio_disk_init+0x1cc>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006556:	100017b7          	lui	a5,0x10001
    8000655a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000655e:	4705                	li	a4,1
    80006560:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006562:	470d                	li	a4,3
    80006564:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006566:	10001737          	lui	a4,0x10001
    8000656a:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000656c:	c7ffe737          	lui	a4,0xc7ffe
    80006570:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd97ff>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006574:	8ef9                	and	a3,a3,a4
    80006576:	10001737          	lui	a4,0x10001
    8000657a:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000657c:	472d                	li	a4,11
    8000657e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006580:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80006584:	439c                	lw	a5,0(a5)
    80006586:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    8000658a:	8ba1                	andi	a5,a5,8
    8000658c:	12078e63          	beqz	a5,800066c8 <virtio_disk_init+0x1dc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006590:	100017b7          	lui	a5,0x10001
    80006594:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006598:	100017b7          	lui	a5,0x10001
    8000659c:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800065a0:	439c                	lw	a5,0(a5)
    800065a2:	2781                	sext.w	a5,a5
    800065a4:	12079a63          	bnez	a5,800066d8 <virtio_disk_init+0x1ec>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065a8:	100017b7          	lui	a5,0x10001
    800065ac:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800065b0:	439c                	lw	a5,0(a5)
    800065b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800065b4:	12078a63          	beqz	a5,800066e8 <virtio_disk_init+0x1fc>
  if(max < NUM)
    800065b8:	471d                	li	a4,7
    800065ba:	12f77f63          	bgeu	a4,a5,800066f8 <virtio_disk_init+0x20c>
  disk.desc = kalloc();
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	58a080e7          	jalr	1418(ra) # 80000b48 <kalloc>
    800065c6:	0001f497          	auipc	s1,0x1f
    800065ca:	85a48493          	addi	s1,s1,-1958 # 80024e20 <disk>
    800065ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	578080e7          	jalr	1400(ra) # 80000b48 <kalloc>
    800065d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	56e080e7          	jalr	1390(ra) # 80000b48 <kalloc>
    800065e2:	87aa                	mv	a5,a0
    800065e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800065e6:	6088                	ld	a0,0(s1)
    800065e8:	12050063          	beqz	a0,80006708 <virtio_disk_init+0x21c>
    800065ec:	0001f717          	auipc	a4,0x1f
    800065f0:	83c73703          	ld	a4,-1988(a4) # 80024e28 <disk+0x8>
    800065f4:	10070a63          	beqz	a4,80006708 <virtio_disk_init+0x21c>
    800065f8:	10078863          	beqz	a5,80006708 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    800065fc:	6605                	lui	a2,0x1
    800065fe:	4581                	li	a1,0
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	734080e7          	jalr	1844(ra) # 80000d34 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006608:	0001f497          	auipc	s1,0x1f
    8000660c:	81848493          	addi	s1,s1,-2024 # 80024e20 <disk>
    80006610:	6605                	lui	a2,0x1
    80006612:	4581                	li	a1,0
    80006614:	6488                	ld	a0,8(s1)
    80006616:	ffffa097          	auipc	ra,0xffffa
    8000661a:	71e080e7          	jalr	1822(ra) # 80000d34 <memset>
  memset(disk.used, 0, PGSIZE);
    8000661e:	6605                	lui	a2,0x1
    80006620:	4581                	li	a1,0
    80006622:	6888                	ld	a0,16(s1)
    80006624:	ffffa097          	auipc	ra,0xffffa
    80006628:	710080e7          	jalr	1808(ra) # 80000d34 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000662c:	100017b7          	lui	a5,0x10001
    80006630:	4721                	li	a4,8
    80006632:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006634:	4098                	lw	a4,0(s1)
    80006636:	100017b7          	lui	a5,0x10001
    8000663a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000663e:	40d8                	lw	a4,4(s1)
    80006640:	100017b7          	lui	a5,0x10001
    80006644:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006648:	649c                	ld	a5,8(s1)
    8000664a:	0007869b          	sext.w	a3,a5
    8000664e:	10001737          	lui	a4,0x10001
    80006652:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006656:	9781                	srai	a5,a5,0x20
    80006658:	10001737          	lui	a4,0x10001
    8000665c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006660:	689c                	ld	a5,16(s1)
    80006662:	0007869b          	sext.w	a3,a5
    80006666:	10001737          	lui	a4,0x10001
    8000666a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000666e:	9781                	srai	a5,a5,0x20
    80006670:	10001737          	lui	a4,0x10001
    80006674:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006678:	10001737          	lui	a4,0x10001
    8000667c:	4785                	li	a5,1
    8000667e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006680:	00f48c23          	sb	a5,24(s1)
    80006684:	00f48ca3          	sb	a5,25(s1)
    80006688:	00f48d23          	sb	a5,26(s1)
    8000668c:	00f48da3          	sb	a5,27(s1)
    80006690:	00f48e23          	sb	a5,28(s1)
    80006694:	00f48ea3          	sb	a5,29(s1)
    80006698:	00f48f23          	sb	a5,30(s1)
    8000669c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800066a0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800066a4:	100017b7          	lui	a5,0x10001
    800066a8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800066ac:	60e2                	ld	ra,24(sp)
    800066ae:	6442                	ld	s0,16(sp)
    800066b0:	64a2                	ld	s1,8(sp)
    800066b2:	6902                	ld	s2,0(sp)
    800066b4:	6105                	addi	sp,sp,32
    800066b6:	8082                	ret
    panic("could not find virtio disk");
    800066b8:	00002517          	auipc	a0,0x2
    800066bc:	fa050513          	addi	a0,a0,-96 # 80008658 <etext+0x658>
    800066c0:	ffffa097          	auipc	ra,0xffffa
    800066c4:	ea0080e7          	jalr	-352(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    800066c8:	00002517          	auipc	a0,0x2
    800066cc:	fb050513          	addi	a0,a0,-80 # 80008678 <etext+0x678>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	e90080e7          	jalr	-368(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    800066d8:	00002517          	auipc	a0,0x2
    800066dc:	fc050513          	addi	a0,a0,-64 # 80008698 <etext+0x698>
    800066e0:	ffffa097          	auipc	ra,0xffffa
    800066e4:	e80080e7          	jalr	-384(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    800066e8:	00002517          	auipc	a0,0x2
    800066ec:	fd050513          	addi	a0,a0,-48 # 800086b8 <etext+0x6b8>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	e70080e7          	jalr	-400(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    800066f8:	00002517          	auipc	a0,0x2
    800066fc:	fe050513          	addi	a0,a0,-32 # 800086d8 <etext+0x6d8>
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	e60080e7          	jalr	-416(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    80006708:	00002517          	auipc	a0,0x2
    8000670c:	ff050513          	addi	a0,a0,-16 # 800086f8 <etext+0x6f8>
    80006710:	ffffa097          	auipc	ra,0xffffa
    80006714:	e50080e7          	jalr	-432(ra) # 80000560 <panic>

0000000080006718 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006718:	7159                	addi	sp,sp,-112
    8000671a:	f486                	sd	ra,104(sp)
    8000671c:	f0a2                	sd	s0,96(sp)
    8000671e:	eca6                	sd	s1,88(sp)
    80006720:	e8ca                	sd	s2,80(sp)
    80006722:	e4ce                	sd	s3,72(sp)
    80006724:	e0d2                	sd	s4,64(sp)
    80006726:	fc56                	sd	s5,56(sp)
    80006728:	f85a                	sd	s6,48(sp)
    8000672a:	f45e                	sd	s7,40(sp)
    8000672c:	f062                	sd	s8,32(sp)
    8000672e:	ec66                	sd	s9,24(sp)
    80006730:	1880                	addi	s0,sp,112
    80006732:	8a2a                	mv	s4,a0
    80006734:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006736:	00c52c83          	lw	s9,12(a0)
    8000673a:	001c9c9b          	slliw	s9,s9,0x1
    8000673e:	1c82                	slli	s9,s9,0x20
    80006740:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006744:	0001f517          	auipc	a0,0x1f
    80006748:	80450513          	addi	a0,a0,-2044 # 80024f48 <disk+0x128>
    8000674c:	ffffa097          	auipc	ra,0xffffa
    80006750:	4ec080e7          	jalr	1260(ra) # 80000c38 <acquire>
  for(int i = 0; i < 3; i++){
    80006754:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006756:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006758:	0001eb17          	auipc	s6,0x1e
    8000675c:	6c8b0b13          	addi	s6,s6,1736 # 80024e20 <disk>
  for(int i = 0; i < 3; i++){
    80006760:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006762:	0001ec17          	auipc	s8,0x1e
    80006766:	7e6c0c13          	addi	s8,s8,2022 # 80024f48 <disk+0x128>
    8000676a:	a0ad                	j	800067d4 <virtio_disk_rw+0xbc>
      disk.free[i] = 0;
    8000676c:	00fb0733          	add	a4,s6,a5
    80006770:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006774:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006776:	0207c563          	bltz	a5,800067a0 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000677a:	2905                	addiw	s2,s2,1
    8000677c:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000677e:	05590f63          	beq	s2,s5,800067dc <virtio_disk_rw+0xc4>
    idx[i] = alloc_desc();
    80006782:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006784:	0001e717          	auipc	a4,0x1e
    80006788:	69c70713          	addi	a4,a4,1692 # 80024e20 <disk>
    8000678c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000678e:	01874683          	lbu	a3,24(a4)
    80006792:	fee9                	bnez	a3,8000676c <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80006794:	2785                	addiw	a5,a5,1
    80006796:	0705                	addi	a4,a4,1
    80006798:	fe979be3          	bne	a5,s1,8000678e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000679c:	57fd                	li	a5,-1
    8000679e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800067a0:	03205163          	blez	s2,800067c2 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    800067a4:	f9042503          	lw	a0,-112(s0)
    800067a8:	00000097          	auipc	ra,0x0
    800067ac:	cc2080e7          	jalr	-830(ra) # 8000646a <free_desc>
      for(int j = 0; j < i; j++)
    800067b0:	4785                	li	a5,1
    800067b2:	0127d863          	bge	a5,s2,800067c2 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    800067b6:	f9442503          	lw	a0,-108(s0)
    800067ba:	00000097          	auipc	ra,0x0
    800067be:	cb0080e7          	jalr	-848(ra) # 8000646a <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067c2:	85e2                	mv	a1,s8
    800067c4:	0001e517          	auipc	a0,0x1e
    800067c8:	67450513          	addi	a0,a0,1652 # 80024e38 <disk+0x18>
    800067cc:	ffffc097          	auipc	ra,0xffffc
    800067d0:	9bc080e7          	jalr	-1604(ra) # 80002188 <sleep>
  for(int i = 0; i < 3; i++){
    800067d4:	f9040613          	addi	a2,s0,-112
    800067d8:	894e                	mv	s2,s3
    800067da:	b765                	j	80006782 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067dc:	f9042503          	lw	a0,-112(s0)
    800067e0:	00451693          	slli	a3,a0,0x4

  if(write)
    800067e4:	0001e797          	auipc	a5,0x1e
    800067e8:	63c78793          	addi	a5,a5,1596 # 80024e20 <disk>
    800067ec:	00a50713          	addi	a4,a0,10
    800067f0:	0712                	slli	a4,a4,0x4
    800067f2:	973e                	add	a4,a4,a5
    800067f4:	01703633          	snez	a2,s7
    800067f8:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067fa:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800067fe:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006802:	6398                	ld	a4,0(a5)
    80006804:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006806:	0a868613          	addi	a2,a3,168
    8000680a:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000680c:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000680e:	6390                	ld	a2,0(a5)
    80006810:	00d605b3          	add	a1,a2,a3
    80006814:	4741                	li	a4,16
    80006816:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006818:	4805                	li	a6,1
    8000681a:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    8000681e:	f9442703          	lw	a4,-108(s0)
    80006822:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006826:	0712                	slli	a4,a4,0x4
    80006828:	963a                	add	a2,a2,a4
    8000682a:	058a0593          	addi	a1,s4,88
    8000682e:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006830:	0007b883          	ld	a7,0(a5)
    80006834:	9746                	add	a4,a4,a7
    80006836:	40000613          	li	a2,1024
    8000683a:	c710                	sw	a2,8(a4)
  if(write)
    8000683c:	001bb613          	seqz	a2,s7
    80006840:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006844:	00166613          	ori	a2,a2,1
    80006848:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    8000684c:	f9842583          	lw	a1,-104(s0)
    80006850:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006854:	00250613          	addi	a2,a0,2
    80006858:	0612                	slli	a2,a2,0x4
    8000685a:	963e                	add	a2,a2,a5
    8000685c:	577d                	li	a4,-1
    8000685e:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006862:	0592                	slli	a1,a1,0x4
    80006864:	98ae                	add	a7,a7,a1
    80006866:	03068713          	addi	a4,a3,48
    8000686a:	973e                	add	a4,a4,a5
    8000686c:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006870:	6398                	ld	a4,0(a5)
    80006872:	972e                	add	a4,a4,a1
    80006874:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006878:	4689                	li	a3,2
    8000687a:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    8000687e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006882:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006886:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000688a:	6794                	ld	a3,8(a5)
    8000688c:	0026d703          	lhu	a4,2(a3)
    80006890:	8b1d                	andi	a4,a4,7
    80006892:	0706                	slli	a4,a4,0x1
    80006894:	96ba                	add	a3,a3,a4
    80006896:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    8000689a:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000689e:	6798                	ld	a4,8(a5)
    800068a0:	00275783          	lhu	a5,2(a4)
    800068a4:	2785                	addiw	a5,a5,1
    800068a6:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068aa:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068ae:	100017b7          	lui	a5,0x10001
    800068b2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068b6:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800068ba:	0001e917          	auipc	s2,0x1e
    800068be:	68e90913          	addi	s2,s2,1678 # 80024f48 <disk+0x128>
  while(b->disk == 1) {
    800068c2:	4485                	li	s1,1
    800068c4:	01079c63          	bne	a5,a6,800068dc <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800068c8:	85ca                	mv	a1,s2
    800068ca:	8552                	mv	a0,s4
    800068cc:	ffffc097          	auipc	ra,0xffffc
    800068d0:	8bc080e7          	jalr	-1860(ra) # 80002188 <sleep>
  while(b->disk == 1) {
    800068d4:	004a2783          	lw	a5,4(s4)
    800068d8:	fe9788e3          	beq	a5,s1,800068c8 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800068dc:	f9042903          	lw	s2,-112(s0)
    800068e0:	00290713          	addi	a4,s2,2
    800068e4:	0712                	slli	a4,a4,0x4
    800068e6:	0001e797          	auipc	a5,0x1e
    800068ea:	53a78793          	addi	a5,a5,1338 # 80024e20 <disk>
    800068ee:	97ba                	add	a5,a5,a4
    800068f0:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800068f4:	0001e997          	auipc	s3,0x1e
    800068f8:	52c98993          	addi	s3,s3,1324 # 80024e20 <disk>
    800068fc:	00491713          	slli	a4,s2,0x4
    80006900:	0009b783          	ld	a5,0(s3)
    80006904:	97ba                	add	a5,a5,a4
    80006906:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000690a:	854a                	mv	a0,s2
    8000690c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006910:	00000097          	auipc	ra,0x0
    80006914:	b5a080e7          	jalr	-1190(ra) # 8000646a <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006918:	8885                	andi	s1,s1,1
    8000691a:	f0ed                	bnez	s1,800068fc <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000691c:	0001e517          	auipc	a0,0x1e
    80006920:	62c50513          	addi	a0,a0,1580 # 80024f48 <disk+0x128>
    80006924:	ffffa097          	auipc	ra,0xffffa
    80006928:	3c8080e7          	jalr	968(ra) # 80000cec <release>
}
    8000692c:	70a6                	ld	ra,104(sp)
    8000692e:	7406                	ld	s0,96(sp)
    80006930:	64e6                	ld	s1,88(sp)
    80006932:	6946                	ld	s2,80(sp)
    80006934:	69a6                	ld	s3,72(sp)
    80006936:	6a06                	ld	s4,64(sp)
    80006938:	7ae2                	ld	s5,56(sp)
    8000693a:	7b42                	ld	s6,48(sp)
    8000693c:	7ba2                	ld	s7,40(sp)
    8000693e:	7c02                	ld	s8,32(sp)
    80006940:	6ce2                	ld	s9,24(sp)
    80006942:	6165                	addi	sp,sp,112
    80006944:	8082                	ret

0000000080006946 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006946:	1101                	addi	sp,sp,-32
    80006948:	ec06                	sd	ra,24(sp)
    8000694a:	e822                	sd	s0,16(sp)
    8000694c:	e426                	sd	s1,8(sp)
    8000694e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006950:	0001e497          	auipc	s1,0x1e
    80006954:	4d048493          	addi	s1,s1,1232 # 80024e20 <disk>
    80006958:	0001e517          	auipc	a0,0x1e
    8000695c:	5f050513          	addi	a0,a0,1520 # 80024f48 <disk+0x128>
    80006960:	ffffa097          	auipc	ra,0xffffa
    80006964:	2d8080e7          	jalr	728(ra) # 80000c38 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006968:	100017b7          	lui	a5,0x10001
    8000696c:	53b8                	lw	a4,96(a5)
    8000696e:	8b0d                	andi	a4,a4,3
    80006970:	100017b7          	lui	a5,0x10001
    80006974:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006976:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000697a:	689c                	ld	a5,16(s1)
    8000697c:	0204d703          	lhu	a4,32(s1)
    80006980:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006984:	04f70863          	beq	a4,a5,800069d4 <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006988:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000698c:	6898                	ld	a4,16(s1)
    8000698e:	0204d783          	lhu	a5,32(s1)
    80006992:	8b9d                	andi	a5,a5,7
    80006994:	078e                	slli	a5,a5,0x3
    80006996:	97ba                	add	a5,a5,a4
    80006998:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000699a:	00278713          	addi	a4,a5,2
    8000699e:	0712                	slli	a4,a4,0x4
    800069a0:	9726                	add	a4,a4,s1
    800069a2:	01074703          	lbu	a4,16(a4)
    800069a6:	e721                	bnez	a4,800069ee <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069a8:	0789                	addi	a5,a5,2
    800069aa:	0792                	slli	a5,a5,0x4
    800069ac:	97a6                	add	a5,a5,s1
    800069ae:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800069b0:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069b4:	ffffc097          	auipc	ra,0xffffc
    800069b8:	838080e7          	jalr	-1992(ra) # 800021ec <wakeup>

    disk.used_idx += 1;
    800069bc:	0204d783          	lhu	a5,32(s1)
    800069c0:	2785                	addiw	a5,a5,1
    800069c2:	17c2                	slli	a5,a5,0x30
    800069c4:	93c1                	srli	a5,a5,0x30
    800069c6:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069ca:	6898                	ld	a4,16(s1)
    800069cc:	00275703          	lhu	a4,2(a4)
    800069d0:	faf71ce3          	bne	a4,a5,80006988 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    800069d4:	0001e517          	auipc	a0,0x1e
    800069d8:	57450513          	addi	a0,a0,1396 # 80024f48 <disk+0x128>
    800069dc:	ffffa097          	auipc	ra,0xffffa
    800069e0:	310080e7          	jalr	784(ra) # 80000cec <release>
}
    800069e4:	60e2                	ld	ra,24(sp)
    800069e6:	6442                	ld	s0,16(sp)
    800069e8:	64a2                	ld	s1,8(sp)
    800069ea:	6105                	addi	sp,sp,32
    800069ec:	8082                	ret
      panic("virtio_disk_intr status");
    800069ee:	00002517          	auipc	a0,0x2
    800069f2:	d2250513          	addi	a0,a0,-734 # 80008710 <etext+0x710>
    800069f6:	ffffa097          	auipc	ra,0xffffa
    800069fa:	b6a080e7          	jalr	-1174(ra) # 80000560 <panic>
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
