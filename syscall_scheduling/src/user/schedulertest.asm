
user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

#define NFORK 10
#define IO 5

int main()
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	addi	s0,sp,64
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
   e:	4481                	li	s1,0
  10:	4929                	li	s2,10
  {
    pid = fork();
  12:	00000097          	auipc	ra,0x0
  16:	33a080e7          	jalr	826(ra) # 34c <fork>
    if (pid < 0)
  1a:	00054963          	bltz	a0,2c <main+0x2c>
      break;
    if (pid == 0)
  1e:	cd0d                	beqz	a0,58 <main+0x58>
  for (n = 0; n < NFORK; n++)
  20:	2485                	addiw	s1,s1,1
  22:	ff2498e3          	bne	s1,s2,12 <main+0x12>
  26:	4901                	li	s2,0
  28:	4981                	li	s3,0
  2a:	a8b5                	j	a6 <main+0xa6>
      }
      // printf("Process %d finished\n", n);
      exit(0);
    }
  }
  for (; n > 0; n--)
  2c:	fe904de3          	bgtz	s1,26 <main+0x26>
  30:	4901                	li	s2,0
  32:	4981                	li	s3,0
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  34:	45a9                	li	a1,10
  36:	02b9c63b          	divw	a2,s3,a1
  3a:	02b945bb          	divw	a1,s2,a1
  3e:	00001517          	auipc	a0,0x1
  42:	86250513          	addi	a0,a0,-1950 # 8a0 <malloc+0x104>
  46:	00000097          	auipc	ra,0x0
  4a:	69e080e7          	jalr	1694(ra) # 6e4 <printf>
  exit(0);
  4e:	4501                	li	a0,0
  50:	00000097          	auipc	ra,0x0
  54:	304080e7          	jalr	772(ra) # 354 <exit>
      if (n < IO)
  58:	4791                	li	a5,4
  5a:	0297dd63          	bge	a5,s1,94 <main+0x94>
        for (volatile int i = 0; i < 1000000000; i++)
  5e:	fc042223          	sw	zero,-60(s0)
  62:	fc442703          	lw	a4,-60(s0)
  66:	2701                	sext.w	a4,a4
  68:	3b9ad7b7          	lui	a5,0x3b9ad
  6c:	9ff78793          	addi	a5,a5,-1537 # 3b9ac9ff <base+0x3b9ab9ef>
  70:	00e7cd63          	blt	a5,a4,8a <main+0x8a>
  74:	873e                	mv	a4,a5
  76:	fc442783          	lw	a5,-60(s0)
  7a:	2785                	addiw	a5,a5,1
  7c:	fcf42223          	sw	a5,-60(s0)
  80:	fc442783          	lw	a5,-60(s0)
  84:	2781                	sext.w	a5,a5
  86:	fef758e3          	bge	a4,a5,76 <main+0x76>
      exit(0);
  8a:	4501                	li	a0,0
  8c:	00000097          	auipc	ra,0x0
  90:	2c8080e7          	jalr	712(ra) # 354 <exit>
        sleep(200); // IO bound processes
  94:	0c800513          	li	a0,200
  98:	00000097          	auipc	ra,0x0
  9c:	34c080e7          	jalr	844(ra) # 3e4 <sleep>
  a0:	b7ed                	j	8a <main+0x8a>
  for (; n > 0; n--)
  a2:	34fd                	addiw	s1,s1,-1
  a4:	d8c1                	beqz	s1,34 <main+0x34>
    if (waitx(0, &wtime, &rtime) >= 0)
  a6:	fc840613          	addi	a2,s0,-56
  aa:	fcc40593          	addi	a1,s0,-52
  ae:	4501                	li	a0,0
  b0:	00000097          	auipc	ra,0x0
  b4:	344080e7          	jalr	836(ra) # 3f4 <waitx>
  b8:	fe0545e3          	bltz	a0,a2 <main+0xa2>
      trtime += rtime;
  bc:	fc842783          	lw	a5,-56(s0)
  c0:	0127893b          	addw	s2,a5,s2
      twtime += wtime;
  c4:	fcc42783          	lw	a5,-52(s0)
  c8:	013789bb          	addw	s3,a5,s3
  cc:	bfd9                	j	a2 <main+0xa2>

00000000000000ce <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  ce:	1141                	addi	sp,sp,-16
  d0:	e406                	sd	ra,8(sp)
  d2:	e022                	sd	s0,0(sp)
  d4:	0800                	addi	s0,sp,16
  extern int main();
  main();
  d6:	00000097          	auipc	ra,0x0
  da:	f2a080e7          	jalr	-214(ra) # 0 <main>
  exit(0);
  de:	4501                	li	a0,0
  e0:	00000097          	auipc	ra,0x0
  e4:	274080e7          	jalr	628(ra) # 354 <exit>

00000000000000e8 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  e8:	1141                	addi	sp,sp,-16
  ea:	e422                	sd	s0,8(sp)
  ec:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  ee:	87aa                	mv	a5,a0
  f0:	0585                	addi	a1,a1,1
  f2:	0785                	addi	a5,a5,1
  f4:	fff5c703          	lbu	a4,-1(a1)
  f8:	fee78fa3          	sb	a4,-1(a5)
  fc:	fb75                	bnez	a4,f0 <strcpy+0x8>
    ;
  return os;
}
  fe:	6422                	ld	s0,8(sp)
 100:	0141                	addi	sp,sp,16
 102:	8082                	ret

0000000000000104 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 104:	1141                	addi	sp,sp,-16
 106:	e422                	sd	s0,8(sp)
 108:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 10a:	00054783          	lbu	a5,0(a0)
 10e:	cb91                	beqz	a5,122 <strcmp+0x1e>
 110:	0005c703          	lbu	a4,0(a1)
 114:	00f71763          	bne	a4,a5,122 <strcmp+0x1e>
    p++, q++;
 118:	0505                	addi	a0,a0,1
 11a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 11c:	00054783          	lbu	a5,0(a0)
 120:	fbe5                	bnez	a5,110 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 122:	0005c503          	lbu	a0,0(a1)
}
 126:	40a7853b          	subw	a0,a5,a0
 12a:	6422                	ld	s0,8(sp)
 12c:	0141                	addi	sp,sp,16
 12e:	8082                	ret

0000000000000130 <strlen>:

uint
strlen(const char *s)
{
 130:	1141                	addi	sp,sp,-16
 132:	e422                	sd	s0,8(sp)
 134:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 136:	00054783          	lbu	a5,0(a0)
 13a:	cf91                	beqz	a5,156 <strlen+0x26>
 13c:	0505                	addi	a0,a0,1
 13e:	87aa                	mv	a5,a0
 140:	86be                	mv	a3,a5
 142:	0785                	addi	a5,a5,1
 144:	fff7c703          	lbu	a4,-1(a5)
 148:	ff65                	bnez	a4,140 <strlen+0x10>
 14a:	40a6853b          	subw	a0,a3,a0
 14e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 150:	6422                	ld	s0,8(sp)
 152:	0141                	addi	sp,sp,16
 154:	8082                	ret
  for(n = 0; s[n]; n++)
 156:	4501                	li	a0,0
 158:	bfe5                	j	150 <strlen+0x20>

000000000000015a <memset>:

void*
memset(void *dst, int c, uint n)
{
 15a:	1141                	addi	sp,sp,-16
 15c:	e422                	sd	s0,8(sp)
 15e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 160:	ca19                	beqz	a2,176 <memset+0x1c>
 162:	87aa                	mv	a5,a0
 164:	1602                	slli	a2,a2,0x20
 166:	9201                	srli	a2,a2,0x20
 168:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 16c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 170:	0785                	addi	a5,a5,1
 172:	fee79de3          	bne	a5,a4,16c <memset+0x12>
  }
  return dst;
}
 176:	6422                	ld	s0,8(sp)
 178:	0141                	addi	sp,sp,16
 17a:	8082                	ret

000000000000017c <strchr>:

char*
strchr(const char *s, char c)
{
 17c:	1141                	addi	sp,sp,-16
 17e:	e422                	sd	s0,8(sp)
 180:	0800                	addi	s0,sp,16
  for(; *s; s++)
 182:	00054783          	lbu	a5,0(a0)
 186:	cb99                	beqz	a5,19c <strchr+0x20>
    if(*s == c)
 188:	00f58763          	beq	a1,a5,196 <strchr+0x1a>
  for(; *s; s++)
 18c:	0505                	addi	a0,a0,1
 18e:	00054783          	lbu	a5,0(a0)
 192:	fbfd                	bnez	a5,188 <strchr+0xc>
      return (char*)s;
  return 0;
 194:	4501                	li	a0,0
}
 196:	6422                	ld	s0,8(sp)
 198:	0141                	addi	sp,sp,16
 19a:	8082                	ret
  return 0;
 19c:	4501                	li	a0,0
 19e:	bfe5                	j	196 <strchr+0x1a>

00000000000001a0 <gets>:

char*
gets(char *buf, int max)
{
 1a0:	711d                	addi	sp,sp,-96
 1a2:	ec86                	sd	ra,88(sp)
 1a4:	e8a2                	sd	s0,80(sp)
 1a6:	e4a6                	sd	s1,72(sp)
 1a8:	e0ca                	sd	s2,64(sp)
 1aa:	fc4e                	sd	s3,56(sp)
 1ac:	f852                	sd	s4,48(sp)
 1ae:	f456                	sd	s5,40(sp)
 1b0:	f05a                	sd	s6,32(sp)
 1b2:	ec5e                	sd	s7,24(sp)
 1b4:	1080                	addi	s0,sp,96
 1b6:	8baa                	mv	s7,a0
 1b8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ba:	892a                	mv	s2,a0
 1bc:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1be:	4aa9                	li	s5,10
 1c0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1c2:	89a6                	mv	s3,s1
 1c4:	2485                	addiw	s1,s1,1
 1c6:	0344d863          	bge	s1,s4,1f6 <gets+0x56>
    cc = read(0, &c, 1);
 1ca:	4605                	li	a2,1
 1cc:	faf40593          	addi	a1,s0,-81
 1d0:	4501                	li	a0,0
 1d2:	00000097          	auipc	ra,0x0
 1d6:	19a080e7          	jalr	410(ra) # 36c <read>
    if(cc < 1)
 1da:	00a05e63          	blez	a0,1f6 <gets+0x56>
    buf[i++] = c;
 1de:	faf44783          	lbu	a5,-81(s0)
 1e2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1e6:	01578763          	beq	a5,s5,1f4 <gets+0x54>
 1ea:	0905                	addi	s2,s2,1
 1ec:	fd679be3          	bne	a5,s6,1c2 <gets+0x22>
    buf[i++] = c;
 1f0:	89a6                	mv	s3,s1
 1f2:	a011                	j	1f6 <gets+0x56>
 1f4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1f6:	99de                	add	s3,s3,s7
 1f8:	00098023          	sb	zero,0(s3)
  return buf;
}
 1fc:	855e                	mv	a0,s7
 1fe:	60e6                	ld	ra,88(sp)
 200:	6446                	ld	s0,80(sp)
 202:	64a6                	ld	s1,72(sp)
 204:	6906                	ld	s2,64(sp)
 206:	79e2                	ld	s3,56(sp)
 208:	7a42                	ld	s4,48(sp)
 20a:	7aa2                	ld	s5,40(sp)
 20c:	7b02                	ld	s6,32(sp)
 20e:	6be2                	ld	s7,24(sp)
 210:	6125                	addi	sp,sp,96
 212:	8082                	ret

0000000000000214 <stat>:

int
stat(const char *n, struct stat *st)
{
 214:	1101                	addi	sp,sp,-32
 216:	ec06                	sd	ra,24(sp)
 218:	e822                	sd	s0,16(sp)
 21a:	e04a                	sd	s2,0(sp)
 21c:	1000                	addi	s0,sp,32
 21e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 220:	4581                	li	a1,0
 222:	00000097          	auipc	ra,0x0
 226:	172080e7          	jalr	370(ra) # 394 <open>
  if(fd < 0)
 22a:	02054663          	bltz	a0,256 <stat+0x42>
 22e:	e426                	sd	s1,8(sp)
 230:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 232:	85ca                	mv	a1,s2
 234:	00000097          	auipc	ra,0x0
 238:	178080e7          	jalr	376(ra) # 3ac <fstat>
 23c:	892a                	mv	s2,a0
  close(fd);
 23e:	8526                	mv	a0,s1
 240:	00000097          	auipc	ra,0x0
 244:	13c080e7          	jalr	316(ra) # 37c <close>
  return r;
 248:	64a2                	ld	s1,8(sp)
}
 24a:	854a                	mv	a0,s2
 24c:	60e2                	ld	ra,24(sp)
 24e:	6442                	ld	s0,16(sp)
 250:	6902                	ld	s2,0(sp)
 252:	6105                	addi	sp,sp,32
 254:	8082                	ret
    return -1;
 256:	597d                	li	s2,-1
 258:	bfcd                	j	24a <stat+0x36>

000000000000025a <atoi>:

int
atoi(const char *s)
{
 25a:	1141                	addi	sp,sp,-16
 25c:	e422                	sd	s0,8(sp)
 25e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 260:	00054683          	lbu	a3,0(a0)
 264:	fd06879b          	addiw	a5,a3,-48
 268:	0ff7f793          	zext.b	a5,a5
 26c:	4625                	li	a2,9
 26e:	02f66863          	bltu	a2,a5,29e <atoi+0x44>
 272:	872a                	mv	a4,a0
  n = 0;
 274:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 276:	0705                	addi	a4,a4,1
 278:	0025179b          	slliw	a5,a0,0x2
 27c:	9fa9                	addw	a5,a5,a0
 27e:	0017979b          	slliw	a5,a5,0x1
 282:	9fb5                	addw	a5,a5,a3
 284:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 288:	00074683          	lbu	a3,0(a4)
 28c:	fd06879b          	addiw	a5,a3,-48
 290:	0ff7f793          	zext.b	a5,a5
 294:	fef671e3          	bgeu	a2,a5,276 <atoi+0x1c>
  return n;
}
 298:	6422                	ld	s0,8(sp)
 29a:	0141                	addi	sp,sp,16
 29c:	8082                	ret
  n = 0;
 29e:	4501                	li	a0,0
 2a0:	bfe5                	j	298 <atoi+0x3e>

00000000000002a2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2a2:	1141                	addi	sp,sp,-16
 2a4:	e422                	sd	s0,8(sp)
 2a6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2a8:	02b57463          	bgeu	a0,a1,2d0 <memmove+0x2e>
    while(n-- > 0)
 2ac:	00c05f63          	blez	a2,2ca <memmove+0x28>
 2b0:	1602                	slli	a2,a2,0x20
 2b2:	9201                	srli	a2,a2,0x20
 2b4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2b8:	872a                	mv	a4,a0
      *dst++ = *src++;
 2ba:	0585                	addi	a1,a1,1
 2bc:	0705                	addi	a4,a4,1
 2be:	fff5c683          	lbu	a3,-1(a1)
 2c2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2c6:	fef71ae3          	bne	a4,a5,2ba <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2ca:	6422                	ld	s0,8(sp)
 2cc:	0141                	addi	sp,sp,16
 2ce:	8082                	ret
    dst += n;
 2d0:	00c50733          	add	a4,a0,a2
    src += n;
 2d4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2d6:	fec05ae3          	blez	a2,2ca <memmove+0x28>
 2da:	fff6079b          	addiw	a5,a2,-1
 2de:	1782                	slli	a5,a5,0x20
 2e0:	9381                	srli	a5,a5,0x20
 2e2:	fff7c793          	not	a5,a5
 2e6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2e8:	15fd                	addi	a1,a1,-1
 2ea:	177d                	addi	a4,a4,-1
 2ec:	0005c683          	lbu	a3,0(a1)
 2f0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2f4:	fee79ae3          	bne	a5,a4,2e8 <memmove+0x46>
 2f8:	bfc9                	j	2ca <memmove+0x28>

00000000000002fa <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2fa:	1141                	addi	sp,sp,-16
 2fc:	e422                	sd	s0,8(sp)
 2fe:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 300:	ca05                	beqz	a2,330 <memcmp+0x36>
 302:	fff6069b          	addiw	a3,a2,-1
 306:	1682                	slli	a3,a3,0x20
 308:	9281                	srli	a3,a3,0x20
 30a:	0685                	addi	a3,a3,1
 30c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 30e:	00054783          	lbu	a5,0(a0)
 312:	0005c703          	lbu	a4,0(a1)
 316:	00e79863          	bne	a5,a4,326 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 31a:	0505                	addi	a0,a0,1
    p2++;
 31c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 31e:	fed518e3          	bne	a0,a3,30e <memcmp+0x14>
  }
  return 0;
 322:	4501                	li	a0,0
 324:	a019                	j	32a <memcmp+0x30>
      return *p1 - *p2;
 326:	40e7853b          	subw	a0,a5,a4
}
 32a:	6422                	ld	s0,8(sp)
 32c:	0141                	addi	sp,sp,16
 32e:	8082                	ret
  return 0;
 330:	4501                	li	a0,0
 332:	bfe5                	j	32a <memcmp+0x30>

0000000000000334 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 334:	1141                	addi	sp,sp,-16
 336:	e406                	sd	ra,8(sp)
 338:	e022                	sd	s0,0(sp)
 33a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 33c:	00000097          	auipc	ra,0x0
 340:	f66080e7          	jalr	-154(ra) # 2a2 <memmove>
}
 344:	60a2                	ld	ra,8(sp)
 346:	6402                	ld	s0,0(sp)
 348:	0141                	addi	sp,sp,16
 34a:	8082                	ret

000000000000034c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 34c:	4885                	li	a7,1
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <exit>:
.global exit
exit:
 li a7, SYS_exit
 354:	4889                	li	a7,2
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <wait>:
.global wait
wait:
 li a7, SYS_wait
 35c:	488d                	li	a7,3
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 364:	4891                	li	a7,4
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <read>:
.global read
read:
 li a7, SYS_read
 36c:	4895                	li	a7,5
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <write>:
.global write
write:
 li a7, SYS_write
 374:	48c1                	li	a7,16
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <close>:
.global close
close:
 li a7, SYS_close
 37c:	48d5                	li	a7,21
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <kill>:
.global kill
kill:
 li a7, SYS_kill
 384:	4899                	li	a7,6
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <exec>:
.global exec
exec:
 li a7, SYS_exec
 38c:	489d                	li	a7,7
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <open>:
.global open
open:
 li a7, SYS_open
 394:	48bd                	li	a7,15
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 39c:	48c5                	li	a7,17
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3a4:	48c9                	li	a7,18
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3ac:	48a1                	li	a7,8
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <link>:
.global link
link:
 li a7, SYS_link
 3b4:	48cd                	li	a7,19
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3bc:	48d1                	li	a7,20
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3c4:	48a5                	li	a7,9
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <dup>:
.global dup
dup:
 li a7, SYS_dup
 3cc:	48a9                	li	a7,10
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3d4:	48ad                	li	a7,11
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3dc:	48b1                	li	a7,12
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3e4:	48b5                	li	a7,13
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3ec:	48b9                	li	a7,14
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3f4:	48d9                	li	a7,22
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 3fc:	48dd                	li	a7,23
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 404:	48e1                	li	a7,24
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 40c:	48e5                	li	a7,25
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 414:	48e9                	li	a7,26
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 41c:	1101                	addi	sp,sp,-32
 41e:	ec06                	sd	ra,24(sp)
 420:	e822                	sd	s0,16(sp)
 422:	1000                	addi	s0,sp,32
 424:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 428:	4605                	li	a2,1
 42a:	fef40593          	addi	a1,s0,-17
 42e:	00000097          	auipc	ra,0x0
 432:	f46080e7          	jalr	-186(ra) # 374 <write>
}
 436:	60e2                	ld	ra,24(sp)
 438:	6442                	ld	s0,16(sp)
 43a:	6105                	addi	sp,sp,32
 43c:	8082                	ret

000000000000043e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 43e:	7139                	addi	sp,sp,-64
 440:	fc06                	sd	ra,56(sp)
 442:	f822                	sd	s0,48(sp)
 444:	f426                	sd	s1,40(sp)
 446:	0080                	addi	s0,sp,64
 448:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 44a:	c299                	beqz	a3,450 <printint+0x12>
 44c:	0805cb63          	bltz	a1,4e2 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 450:	2581                	sext.w	a1,a1
  neg = 0;
 452:	4881                	li	a7,0
 454:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 458:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 45a:	2601                	sext.w	a2,a2
 45c:	00000517          	auipc	a0,0x0
 460:	4c450513          	addi	a0,a0,1220 # 920 <digits>
 464:	883a                	mv	a6,a4
 466:	2705                	addiw	a4,a4,1
 468:	02c5f7bb          	remuw	a5,a1,a2
 46c:	1782                	slli	a5,a5,0x20
 46e:	9381                	srli	a5,a5,0x20
 470:	97aa                	add	a5,a5,a0
 472:	0007c783          	lbu	a5,0(a5)
 476:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 47a:	0005879b          	sext.w	a5,a1
 47e:	02c5d5bb          	divuw	a1,a1,a2
 482:	0685                	addi	a3,a3,1
 484:	fec7f0e3          	bgeu	a5,a2,464 <printint+0x26>
  if(neg)
 488:	00088c63          	beqz	a7,4a0 <printint+0x62>
    buf[i++] = '-';
 48c:	fd070793          	addi	a5,a4,-48
 490:	00878733          	add	a4,a5,s0
 494:	02d00793          	li	a5,45
 498:	fef70823          	sb	a5,-16(a4)
 49c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4a0:	02e05c63          	blez	a4,4d8 <printint+0x9a>
 4a4:	f04a                	sd	s2,32(sp)
 4a6:	ec4e                	sd	s3,24(sp)
 4a8:	fc040793          	addi	a5,s0,-64
 4ac:	00e78933          	add	s2,a5,a4
 4b0:	fff78993          	addi	s3,a5,-1
 4b4:	99ba                	add	s3,s3,a4
 4b6:	377d                	addiw	a4,a4,-1
 4b8:	1702                	slli	a4,a4,0x20
 4ba:	9301                	srli	a4,a4,0x20
 4bc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4c0:	fff94583          	lbu	a1,-1(s2)
 4c4:	8526                	mv	a0,s1
 4c6:	00000097          	auipc	ra,0x0
 4ca:	f56080e7          	jalr	-170(ra) # 41c <putc>
  while(--i >= 0)
 4ce:	197d                	addi	s2,s2,-1
 4d0:	ff3918e3          	bne	s2,s3,4c0 <printint+0x82>
 4d4:	7902                	ld	s2,32(sp)
 4d6:	69e2                	ld	s3,24(sp)
}
 4d8:	70e2                	ld	ra,56(sp)
 4da:	7442                	ld	s0,48(sp)
 4dc:	74a2                	ld	s1,40(sp)
 4de:	6121                	addi	sp,sp,64
 4e0:	8082                	ret
    x = -xx;
 4e2:	40b005bb          	negw	a1,a1
    neg = 1;
 4e6:	4885                	li	a7,1
    x = -xx;
 4e8:	b7b5                	j	454 <printint+0x16>

00000000000004ea <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ea:	715d                	addi	sp,sp,-80
 4ec:	e486                	sd	ra,72(sp)
 4ee:	e0a2                	sd	s0,64(sp)
 4f0:	f84a                	sd	s2,48(sp)
 4f2:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4f4:	0005c903          	lbu	s2,0(a1)
 4f8:	1a090a63          	beqz	s2,6ac <vprintf+0x1c2>
 4fc:	fc26                	sd	s1,56(sp)
 4fe:	f44e                	sd	s3,40(sp)
 500:	f052                	sd	s4,32(sp)
 502:	ec56                	sd	s5,24(sp)
 504:	e85a                	sd	s6,16(sp)
 506:	e45e                	sd	s7,8(sp)
 508:	8aaa                	mv	s5,a0
 50a:	8bb2                	mv	s7,a2
 50c:	00158493          	addi	s1,a1,1
  state = 0;
 510:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 512:	02500a13          	li	s4,37
 516:	4b55                	li	s6,21
 518:	a839                	j	536 <vprintf+0x4c>
        putc(fd, c);
 51a:	85ca                	mv	a1,s2
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	efe080e7          	jalr	-258(ra) # 41c <putc>
 526:	a019                	j	52c <vprintf+0x42>
    } else if(state == '%'){
 528:	01498d63          	beq	s3,s4,542 <vprintf+0x58>
  for(i = 0; fmt[i]; i++){
 52c:	0485                	addi	s1,s1,1
 52e:	fff4c903          	lbu	s2,-1(s1)
 532:	16090763          	beqz	s2,6a0 <vprintf+0x1b6>
    if(state == 0){
 536:	fe0999e3          	bnez	s3,528 <vprintf+0x3e>
      if(c == '%'){
 53a:	ff4910e3          	bne	s2,s4,51a <vprintf+0x30>
        state = '%';
 53e:	89d2                	mv	s3,s4
 540:	b7f5                	j	52c <vprintf+0x42>
      if(c == 'd'){
 542:	13490463          	beq	s2,s4,66a <vprintf+0x180>
 546:	f9d9079b          	addiw	a5,s2,-99
 54a:	0ff7f793          	zext.b	a5,a5
 54e:	12fb6763          	bltu	s6,a5,67c <vprintf+0x192>
 552:	f9d9079b          	addiw	a5,s2,-99
 556:	0ff7f713          	zext.b	a4,a5
 55a:	12eb6163          	bltu	s6,a4,67c <vprintf+0x192>
 55e:	00271793          	slli	a5,a4,0x2
 562:	00000717          	auipc	a4,0x0
 566:	36670713          	addi	a4,a4,870 # 8c8 <malloc+0x12c>
 56a:	97ba                	add	a5,a5,a4
 56c:	439c                	lw	a5,0(a5)
 56e:	97ba                	add	a5,a5,a4
 570:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 572:	008b8913          	addi	s2,s7,8
 576:	4685                	li	a3,1
 578:	4629                	li	a2,10
 57a:	000ba583          	lw	a1,0(s7)
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	ebe080e7          	jalr	-322(ra) # 43e <printint>
 588:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 58a:	4981                	li	s3,0
 58c:	b745                	j	52c <vprintf+0x42>
        printint(fd, va_arg(ap, uint64), 10, 0);
 58e:	008b8913          	addi	s2,s7,8
 592:	4681                	li	a3,0
 594:	4629                	li	a2,10
 596:	000ba583          	lw	a1,0(s7)
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	ea2080e7          	jalr	-350(ra) # 43e <printint>
 5a4:	8bca                	mv	s7,s2
      state = 0;
 5a6:	4981                	li	s3,0
 5a8:	b751                	j	52c <vprintf+0x42>
        printint(fd, va_arg(ap, int), 16, 0);
 5aa:	008b8913          	addi	s2,s7,8
 5ae:	4681                	li	a3,0
 5b0:	4641                	li	a2,16
 5b2:	000ba583          	lw	a1,0(s7)
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	e86080e7          	jalr	-378(ra) # 43e <printint>
 5c0:	8bca                	mv	s7,s2
      state = 0;
 5c2:	4981                	li	s3,0
 5c4:	b7a5                	j	52c <vprintf+0x42>
 5c6:	e062                	sd	s8,0(sp)
        printptr(fd, va_arg(ap, uint64));
 5c8:	008b8c13          	addi	s8,s7,8
 5cc:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 5d0:	03000593          	li	a1,48
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e46080e7          	jalr	-442(ra) # 41c <putc>
  putc(fd, 'x');
 5de:	07800593          	li	a1,120
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	e38080e7          	jalr	-456(ra) # 41c <putc>
 5ec:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ee:	00000b97          	auipc	s7,0x0
 5f2:	332b8b93          	addi	s7,s7,818 # 920 <digits>
 5f6:	03c9d793          	srli	a5,s3,0x3c
 5fa:	97de                	add	a5,a5,s7
 5fc:	0007c583          	lbu	a1,0(a5)
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	e1a080e7          	jalr	-486(ra) # 41c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 60a:	0992                	slli	s3,s3,0x4
 60c:	397d                	addiw	s2,s2,-1
 60e:	fe0914e3          	bnez	s2,5f6 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 612:	8be2                	mv	s7,s8
      state = 0;
 614:	4981                	li	s3,0
 616:	6c02                	ld	s8,0(sp)
 618:	bf11                	j	52c <vprintf+0x42>
        s = va_arg(ap, char*);
 61a:	008b8993          	addi	s3,s7,8
 61e:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 622:	02090163          	beqz	s2,644 <vprintf+0x15a>
        while(*s != 0){
 626:	00094583          	lbu	a1,0(s2)
 62a:	c9a5                	beqz	a1,69a <vprintf+0x1b0>
          putc(fd, *s);
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	dee080e7          	jalr	-530(ra) # 41c <putc>
          s++;
 636:	0905                	addi	s2,s2,1
        while(*s != 0){
 638:	00094583          	lbu	a1,0(s2)
 63c:	f9e5                	bnez	a1,62c <vprintf+0x142>
        s = va_arg(ap, char*);
 63e:	8bce                	mv	s7,s3
      state = 0;
 640:	4981                	li	s3,0
 642:	b5ed                	j	52c <vprintf+0x42>
          s = "(null)";
 644:	00000917          	auipc	s2,0x0
 648:	27c90913          	addi	s2,s2,636 # 8c0 <malloc+0x124>
        while(*s != 0){
 64c:	02800593          	li	a1,40
 650:	bff1                	j	62c <vprintf+0x142>
        putc(fd, va_arg(ap, uint));
 652:	008b8913          	addi	s2,s7,8
 656:	000bc583          	lbu	a1,0(s7)
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	dc0080e7          	jalr	-576(ra) # 41c <putc>
 664:	8bca                	mv	s7,s2
      state = 0;
 666:	4981                	li	s3,0
 668:	b5d1                	j	52c <vprintf+0x42>
        putc(fd, c);
 66a:	02500593          	li	a1,37
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	dac080e7          	jalr	-596(ra) # 41c <putc>
      state = 0;
 678:	4981                	li	s3,0
 67a:	bd4d                	j	52c <vprintf+0x42>
        putc(fd, '%');
 67c:	02500593          	li	a1,37
 680:	8556                	mv	a0,s5
 682:	00000097          	auipc	ra,0x0
 686:	d9a080e7          	jalr	-614(ra) # 41c <putc>
        putc(fd, c);
 68a:	85ca                	mv	a1,s2
 68c:	8556                	mv	a0,s5
 68e:	00000097          	auipc	ra,0x0
 692:	d8e080e7          	jalr	-626(ra) # 41c <putc>
      state = 0;
 696:	4981                	li	s3,0
 698:	bd51                	j	52c <vprintf+0x42>
        s = va_arg(ap, char*);
 69a:	8bce                	mv	s7,s3
      state = 0;
 69c:	4981                	li	s3,0
 69e:	b579                	j	52c <vprintf+0x42>
 6a0:	74e2                	ld	s1,56(sp)
 6a2:	79a2                	ld	s3,40(sp)
 6a4:	7a02                	ld	s4,32(sp)
 6a6:	6ae2                	ld	s5,24(sp)
 6a8:	6b42                	ld	s6,16(sp)
 6aa:	6ba2                	ld	s7,8(sp)
    }
  }
}
 6ac:	60a6                	ld	ra,72(sp)
 6ae:	6406                	ld	s0,64(sp)
 6b0:	7942                	ld	s2,48(sp)
 6b2:	6161                	addi	sp,sp,80
 6b4:	8082                	ret

00000000000006b6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6b6:	715d                	addi	sp,sp,-80
 6b8:	ec06                	sd	ra,24(sp)
 6ba:	e822                	sd	s0,16(sp)
 6bc:	1000                	addi	s0,sp,32
 6be:	e010                	sd	a2,0(s0)
 6c0:	e414                	sd	a3,8(s0)
 6c2:	e818                	sd	a4,16(s0)
 6c4:	ec1c                	sd	a5,24(s0)
 6c6:	03043023          	sd	a6,32(s0)
 6ca:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6ce:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6d2:	8622                	mv	a2,s0
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e16080e7          	jalr	-490(ra) # 4ea <vprintf>
}
 6dc:	60e2                	ld	ra,24(sp)
 6de:	6442                	ld	s0,16(sp)
 6e0:	6161                	addi	sp,sp,80
 6e2:	8082                	ret

00000000000006e4 <printf>:

void
printf(const char *fmt, ...)
{
 6e4:	711d                	addi	sp,sp,-96
 6e6:	ec06                	sd	ra,24(sp)
 6e8:	e822                	sd	s0,16(sp)
 6ea:	1000                	addi	s0,sp,32
 6ec:	e40c                	sd	a1,8(s0)
 6ee:	e810                	sd	a2,16(s0)
 6f0:	ec14                	sd	a3,24(s0)
 6f2:	f018                	sd	a4,32(s0)
 6f4:	f41c                	sd	a5,40(s0)
 6f6:	03043823          	sd	a6,48(s0)
 6fa:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6fe:	00840613          	addi	a2,s0,8
 702:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 706:	85aa                	mv	a1,a0
 708:	4505                	li	a0,1
 70a:	00000097          	auipc	ra,0x0
 70e:	de0080e7          	jalr	-544(ra) # 4ea <vprintf>
}
 712:	60e2                	ld	ra,24(sp)
 714:	6442                	ld	s0,16(sp)
 716:	6125                	addi	sp,sp,96
 718:	8082                	ret

000000000000071a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 71a:	1141                	addi	sp,sp,-16
 71c:	e422                	sd	s0,8(sp)
 71e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 720:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 724:	00001797          	auipc	a5,0x1
 728:	8dc7b783          	ld	a5,-1828(a5) # 1000 <freep>
 72c:	a02d                	j	756 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 72e:	4618                	lw	a4,8(a2)
 730:	9f2d                	addw	a4,a4,a1
 732:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 736:	6398                	ld	a4,0(a5)
 738:	6310                	ld	a2,0(a4)
 73a:	a83d                	j	778 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 73c:	ff852703          	lw	a4,-8(a0)
 740:	9f31                	addw	a4,a4,a2
 742:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 744:	ff053683          	ld	a3,-16(a0)
 748:	a091                	j	78c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74a:	6398                	ld	a4,0(a5)
 74c:	00e7e463          	bltu	a5,a4,754 <free+0x3a>
 750:	00e6ea63          	bltu	a3,a4,764 <free+0x4a>
{
 754:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 756:	fed7fae3          	bgeu	a5,a3,74a <free+0x30>
 75a:	6398                	ld	a4,0(a5)
 75c:	00e6e463          	bltu	a3,a4,764 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 760:	fee7eae3          	bltu	a5,a4,754 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 764:	ff852583          	lw	a1,-8(a0)
 768:	6390                	ld	a2,0(a5)
 76a:	02059813          	slli	a6,a1,0x20
 76e:	01c85713          	srli	a4,a6,0x1c
 772:	9736                	add	a4,a4,a3
 774:	fae60de3          	beq	a2,a4,72e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 778:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 77c:	4790                	lw	a2,8(a5)
 77e:	02061593          	slli	a1,a2,0x20
 782:	01c5d713          	srli	a4,a1,0x1c
 786:	973e                	add	a4,a4,a5
 788:	fae68ae3          	beq	a3,a4,73c <free+0x22>
    p->s.ptr = bp->s.ptr;
 78c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 78e:	00001717          	auipc	a4,0x1
 792:	86f73923          	sd	a5,-1934(a4) # 1000 <freep>
}
 796:	6422                	ld	s0,8(sp)
 798:	0141                	addi	sp,sp,16
 79a:	8082                	ret

000000000000079c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 79c:	7139                	addi	sp,sp,-64
 79e:	fc06                	sd	ra,56(sp)
 7a0:	f822                	sd	s0,48(sp)
 7a2:	f426                	sd	s1,40(sp)
 7a4:	ec4e                	sd	s3,24(sp)
 7a6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7a8:	02051493          	slli	s1,a0,0x20
 7ac:	9081                	srli	s1,s1,0x20
 7ae:	04bd                	addi	s1,s1,15
 7b0:	8091                	srli	s1,s1,0x4
 7b2:	0014899b          	addiw	s3,s1,1
 7b6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7b8:	00001517          	auipc	a0,0x1
 7bc:	84853503          	ld	a0,-1976(a0) # 1000 <freep>
 7c0:	c915                	beqz	a0,7f4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7c2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7c4:	4798                	lw	a4,8(a5)
 7c6:	08977e63          	bgeu	a4,s1,862 <malloc+0xc6>
 7ca:	f04a                	sd	s2,32(sp)
 7cc:	e852                	sd	s4,16(sp)
 7ce:	e456                	sd	s5,8(sp)
 7d0:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 7d2:	8a4e                	mv	s4,s3
 7d4:	0009871b          	sext.w	a4,s3
 7d8:	6685                	lui	a3,0x1
 7da:	00d77363          	bgeu	a4,a3,7e0 <malloc+0x44>
 7de:	6a05                	lui	s4,0x1
 7e0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7e4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7e8:	00001917          	auipc	s2,0x1
 7ec:	81890913          	addi	s2,s2,-2024 # 1000 <freep>
  if(p == (char*)-1)
 7f0:	5afd                	li	s5,-1
 7f2:	a091                	j	836 <malloc+0x9a>
 7f4:	f04a                	sd	s2,32(sp)
 7f6:	e852                	sd	s4,16(sp)
 7f8:	e456                	sd	s5,8(sp)
 7fa:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 7fc:	00001797          	auipc	a5,0x1
 800:	81478793          	addi	a5,a5,-2028 # 1010 <base>
 804:	00000717          	auipc	a4,0x0
 808:	7ef73e23          	sd	a5,2044(a4) # 1000 <freep>
 80c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 80e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 812:	b7c1                	j	7d2 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 814:	6398                	ld	a4,0(a5)
 816:	e118                	sd	a4,0(a0)
 818:	a08d                	j	87a <malloc+0xde>
  hp->s.size = nu;
 81a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 81e:	0541                	addi	a0,a0,16
 820:	00000097          	auipc	ra,0x0
 824:	efa080e7          	jalr	-262(ra) # 71a <free>
  return freep;
 828:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 82c:	c13d                	beqz	a0,892 <malloc+0xf6>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 830:	4798                	lw	a4,8(a5)
 832:	02977463          	bgeu	a4,s1,85a <malloc+0xbe>
    if(p == freep)
 836:	00093703          	ld	a4,0(s2)
 83a:	853e                	mv	a0,a5
 83c:	fef719e3          	bne	a4,a5,82e <malloc+0x92>
  p = sbrk(nu * sizeof(Header));
 840:	8552                	mv	a0,s4
 842:	00000097          	auipc	ra,0x0
 846:	b9a080e7          	jalr	-1126(ra) # 3dc <sbrk>
  if(p == (char*)-1)
 84a:	fd5518e3          	bne	a0,s5,81a <malloc+0x7e>
        return 0;
 84e:	4501                	li	a0,0
 850:	7902                	ld	s2,32(sp)
 852:	6a42                	ld	s4,16(sp)
 854:	6aa2                	ld	s5,8(sp)
 856:	6b02                	ld	s6,0(sp)
 858:	a03d                	j	886 <malloc+0xea>
 85a:	7902                	ld	s2,32(sp)
 85c:	6a42                	ld	s4,16(sp)
 85e:	6aa2                	ld	s5,8(sp)
 860:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 862:	fae489e3          	beq	s1,a4,814 <malloc+0x78>
        p->s.size -= nunits;
 866:	4137073b          	subw	a4,a4,s3
 86a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 86c:	02071693          	slli	a3,a4,0x20
 870:	01c6d713          	srli	a4,a3,0x1c
 874:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 876:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 87a:	00000717          	auipc	a4,0x0
 87e:	78a73323          	sd	a0,1926(a4) # 1000 <freep>
      return (void*)(p + 1);
 882:	01078513          	addi	a0,a5,16
  }
}
 886:	70e2                	ld	ra,56(sp)
 888:	7442                	ld	s0,48(sp)
 88a:	74a2                	ld	s1,40(sp)
 88c:	69e2                	ld	s3,24(sp)
 88e:	6121                	addi	sp,sp,64
 890:	8082                	ret
 892:	7902                	ld	s2,32(sp)
 894:	6a42                	ld	s4,16(sp)
 896:	6aa2                	ld	s5,8(sp)
 898:	6b02                	ld	s6,0(sp)
 89a:	b7f5                	j	886 <malloc+0xea>
