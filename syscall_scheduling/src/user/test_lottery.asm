
user/_test_lottery:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <perform_work>:

#define NPROCS  3  // Number of child processes
#define WORK    10000000  // Amount of work each process does

// Function to perform some work
void perform_work(int n, int pid, int tickets) {
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	1000                	addi	s0,sp,32
  volatile int i;
  for (i = 0; i < n; i++) {
   8:	fe042623          	sw	zero,-20(s0)
   c:	fec42783          	lw	a5,-20(s0)
  10:	872a                	mv	a4,a0
  12:	00a7de63          	bge	a5,a0,2e <perform_work+0x2e>
    if (i % (n / 10) == 0) {
  16:	fec42783          	lw	a5,-20(s0)
  for (i = 0; i < n; i++) {
  1a:	fec42783          	lw	a5,-20(s0)
  1e:	2785                	addiw	a5,a5,1
  20:	fef42623          	sw	a5,-20(s0)
  24:	fec42783          	lw	a5,-20(s0)
  28:	2781                	sext.w	a5,a5
  2a:	fee7c6e3          	blt	a5,a4,16 <perform_work+0x16>
      // Print in a single statement to avoid jumbled output
    //   printf("Process %d with %d tickets is working...\n", pid, tickets);
    }
  }
  exit(0);
  2e:	4501                	li	a0,0
  30:	00000097          	auipc	ra,0x0
  34:	354080e7          	jalr	852(ra) # 384 <exit>

0000000000000038 <main>:
}

int main() {
  38:	7179                	addi	sp,sp,-48
  3a:	f406                	sd	ra,40(sp)
  3c:	f022                	sd	s0,32(sp)
  3e:	ec26                	sd	s1,24(sp)
  40:	e84a                	sd	s2,16(sp)
  42:	1800                	addi	s0,sp,48
  int pid;
  int tickets[NPROCS] = {4, 5, 6};  // Tickets for each child process
  44:	4791                	li	a5,4
  46:	fcf42823          	sw	a5,-48(s0)
  4a:	4795                	li	a5,5
  4c:	fcf42a23          	sw	a5,-44(s0)
  50:	4799                	li	a5,6
  52:	fcf42c23          	sw	a5,-40(s0)
  int i;

  // Set tickets for parent process (lower priority)
  settickets(1);
  56:	4505                	li	a0,1
  58:	00000097          	auipc	ra,0x0
  5c:	3ec080e7          	jalr	1004(ra) # 444 <settickets>

  // Fork child processes
  for (i = 0; i < NPROCS; i++) {
  60:	4481                	li	s1,0
  62:	490d                	li	s2,3
    pid = fork();
  64:	00000097          	auipc	ra,0x0
  68:	318080e7          	jalr	792(ra) # 37c <fork>
    if (pid < 0) {
  6c:	04054263          	bltz	a0,b0 <main+0x78>
      printf("Fork failed!\n");
      exit(1);
    }
    if (pid == 0) {
  70:	cd29                	beqz	a0,ca <main+0x92>
  for (i = 0; i < NPROCS; i++) {
  72:	2485                	addiw	s1,s1,1
  74:	ff2498e3          	bne	s1,s2,64 <main+0x2c>
    // Parent continues to fork more children
  }

  // Parent waits for all child processes to finish
  for (i = 0; i < NPROCS; i++) {
    wait(0);
  78:	4501                	li	a0,0
  7a:	00000097          	auipc	ra,0x0
  7e:	312080e7          	jalr	786(ra) # 38c <wait>
  82:	4501                	li	a0,0
  84:	00000097          	auipc	ra,0x0
  88:	308080e7          	jalr	776(ra) # 38c <wait>
  8c:	4501                	li	a0,0
  8e:	00000097          	auipc	ra,0x0
  92:	2fe080e7          	jalr	766(ra) # 38c <wait>
  }

  printf("All child processes finished.\n");
  96:	00001517          	auipc	a0,0x1
  9a:	84a50513          	addi	a0,a0,-1974 # 8e0 <malloc+0x114>
  9e:	00000097          	auipc	ra,0x0
  a2:	676080e7          	jalr	1654(ra) # 714 <printf>
  exit(0);
  a6:	4501                	li	a0,0
  a8:	00000097          	auipc	ra,0x0
  ac:	2dc080e7          	jalr	732(ra) # 384 <exit>
      printf("Fork failed!\n");
  b0:	00001517          	auipc	a0,0x1
  b4:	82050513          	addi	a0,a0,-2016 # 8d0 <malloc+0x104>
  b8:	00000097          	auipc	ra,0x0
  bc:	65c080e7          	jalr	1628(ra) # 714 <printf>
      exit(1);
  c0:	4505                	li	a0,1
  c2:	00000097          	auipc	ra,0x0
  c6:	2c2080e7          	jalr	706(ra) # 384 <exit>
      settickets(tickets[i]);
  ca:	048a                	slli	s1,s1,0x2
  cc:	fe048793          	addi	a5,s1,-32
  d0:	008784b3          	add	s1,a5,s0
  d4:	ff04a483          	lw	s1,-16(s1)
  d8:	8526                	mv	a0,s1
  da:	00000097          	auipc	ra,0x0
  de:	36a080e7          	jalr	874(ra) # 444 <settickets>
      perform_work(WORK, getpid(), tickets[i]);
  e2:	00000097          	auipc	ra,0x0
  e6:	322080e7          	jalr	802(ra) # 404 <getpid>
  ea:	85aa                	mv	a1,a0
  ec:	8626                	mv	a2,s1
  ee:	00989537          	lui	a0,0x989
  f2:	68050513          	addi	a0,a0,1664 # 989680 <base+0x988670>
  f6:	00000097          	auipc	ra,0x0
  fa:	f0a080e7          	jalr	-246(ra) # 0 <perform_work>

00000000000000fe <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  fe:	1141                	addi	sp,sp,-16
 100:	e406                	sd	ra,8(sp)
 102:	e022                	sd	s0,0(sp)
 104:	0800                	addi	s0,sp,16
  extern int main();
  main();
 106:	00000097          	auipc	ra,0x0
 10a:	f32080e7          	jalr	-206(ra) # 38 <main>
  exit(0);
 10e:	4501                	li	a0,0
 110:	00000097          	auipc	ra,0x0
 114:	274080e7          	jalr	628(ra) # 384 <exit>

0000000000000118 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 118:	1141                	addi	sp,sp,-16
 11a:	e422                	sd	s0,8(sp)
 11c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 11e:	87aa                	mv	a5,a0
 120:	0585                	addi	a1,a1,1
 122:	0785                	addi	a5,a5,1
 124:	fff5c703          	lbu	a4,-1(a1)
 128:	fee78fa3          	sb	a4,-1(a5)
 12c:	fb75                	bnez	a4,120 <strcpy+0x8>
    ;
  return os;
}
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret

0000000000000134 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 134:	1141                	addi	sp,sp,-16
 136:	e422                	sd	s0,8(sp)
 138:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 13a:	00054783          	lbu	a5,0(a0)
 13e:	cb91                	beqz	a5,152 <strcmp+0x1e>
 140:	0005c703          	lbu	a4,0(a1)
 144:	00f71763          	bne	a4,a5,152 <strcmp+0x1e>
    p++, q++;
 148:	0505                	addi	a0,a0,1
 14a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 14c:	00054783          	lbu	a5,0(a0)
 150:	fbe5                	bnez	a5,140 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 152:	0005c503          	lbu	a0,0(a1)
}
 156:	40a7853b          	subw	a0,a5,a0
 15a:	6422                	ld	s0,8(sp)
 15c:	0141                	addi	sp,sp,16
 15e:	8082                	ret

0000000000000160 <strlen>:

uint
strlen(const char *s)
{
 160:	1141                	addi	sp,sp,-16
 162:	e422                	sd	s0,8(sp)
 164:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 166:	00054783          	lbu	a5,0(a0)
 16a:	cf91                	beqz	a5,186 <strlen+0x26>
 16c:	0505                	addi	a0,a0,1
 16e:	87aa                	mv	a5,a0
 170:	86be                	mv	a3,a5
 172:	0785                	addi	a5,a5,1
 174:	fff7c703          	lbu	a4,-1(a5)
 178:	ff65                	bnez	a4,170 <strlen+0x10>
 17a:	40a6853b          	subw	a0,a3,a0
 17e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 180:	6422                	ld	s0,8(sp)
 182:	0141                	addi	sp,sp,16
 184:	8082                	ret
  for(n = 0; s[n]; n++)
 186:	4501                	li	a0,0
 188:	bfe5                	j	180 <strlen+0x20>

000000000000018a <memset>:

void*
memset(void *dst, int c, uint n)
{
 18a:	1141                	addi	sp,sp,-16
 18c:	e422                	sd	s0,8(sp)
 18e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 190:	ca19                	beqz	a2,1a6 <memset+0x1c>
 192:	87aa                	mv	a5,a0
 194:	1602                	slli	a2,a2,0x20
 196:	9201                	srli	a2,a2,0x20
 198:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 19c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1a0:	0785                	addi	a5,a5,1
 1a2:	fee79de3          	bne	a5,a4,19c <memset+0x12>
  }
  return dst;
}
 1a6:	6422                	ld	s0,8(sp)
 1a8:	0141                	addi	sp,sp,16
 1aa:	8082                	ret

00000000000001ac <strchr>:

char*
strchr(const char *s, char c)
{
 1ac:	1141                	addi	sp,sp,-16
 1ae:	e422                	sd	s0,8(sp)
 1b0:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1b2:	00054783          	lbu	a5,0(a0)
 1b6:	cb99                	beqz	a5,1cc <strchr+0x20>
    if(*s == c)
 1b8:	00f58763          	beq	a1,a5,1c6 <strchr+0x1a>
  for(; *s; s++)
 1bc:	0505                	addi	a0,a0,1
 1be:	00054783          	lbu	a5,0(a0)
 1c2:	fbfd                	bnez	a5,1b8 <strchr+0xc>
      return (char*)s;
  return 0;
 1c4:	4501                	li	a0,0
}
 1c6:	6422                	ld	s0,8(sp)
 1c8:	0141                	addi	sp,sp,16
 1ca:	8082                	ret
  return 0;
 1cc:	4501                	li	a0,0
 1ce:	bfe5                	j	1c6 <strchr+0x1a>

00000000000001d0 <gets>:

char*
gets(char *buf, int max)
{
 1d0:	711d                	addi	sp,sp,-96
 1d2:	ec86                	sd	ra,88(sp)
 1d4:	e8a2                	sd	s0,80(sp)
 1d6:	e4a6                	sd	s1,72(sp)
 1d8:	e0ca                	sd	s2,64(sp)
 1da:	fc4e                	sd	s3,56(sp)
 1dc:	f852                	sd	s4,48(sp)
 1de:	f456                	sd	s5,40(sp)
 1e0:	f05a                	sd	s6,32(sp)
 1e2:	ec5e                	sd	s7,24(sp)
 1e4:	1080                	addi	s0,sp,96
 1e6:	8baa                	mv	s7,a0
 1e8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ea:	892a                	mv	s2,a0
 1ec:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1ee:	4aa9                	li	s5,10
 1f0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1f2:	89a6                	mv	s3,s1
 1f4:	2485                	addiw	s1,s1,1
 1f6:	0344d863          	bge	s1,s4,226 <gets+0x56>
    cc = read(0, &c, 1);
 1fa:	4605                	li	a2,1
 1fc:	faf40593          	addi	a1,s0,-81
 200:	4501                	li	a0,0
 202:	00000097          	auipc	ra,0x0
 206:	19a080e7          	jalr	410(ra) # 39c <read>
    if(cc < 1)
 20a:	00a05e63          	blez	a0,226 <gets+0x56>
    buf[i++] = c;
 20e:	faf44783          	lbu	a5,-81(s0)
 212:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 216:	01578763          	beq	a5,s5,224 <gets+0x54>
 21a:	0905                	addi	s2,s2,1
 21c:	fd679be3          	bne	a5,s6,1f2 <gets+0x22>
    buf[i++] = c;
 220:	89a6                	mv	s3,s1
 222:	a011                	j	226 <gets+0x56>
 224:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 226:	99de                	add	s3,s3,s7
 228:	00098023          	sb	zero,0(s3)
  return buf;
}
 22c:	855e                	mv	a0,s7
 22e:	60e6                	ld	ra,88(sp)
 230:	6446                	ld	s0,80(sp)
 232:	64a6                	ld	s1,72(sp)
 234:	6906                	ld	s2,64(sp)
 236:	79e2                	ld	s3,56(sp)
 238:	7a42                	ld	s4,48(sp)
 23a:	7aa2                	ld	s5,40(sp)
 23c:	7b02                	ld	s6,32(sp)
 23e:	6be2                	ld	s7,24(sp)
 240:	6125                	addi	sp,sp,96
 242:	8082                	ret

0000000000000244 <stat>:

int
stat(const char *n, struct stat *st)
{
 244:	1101                	addi	sp,sp,-32
 246:	ec06                	sd	ra,24(sp)
 248:	e822                	sd	s0,16(sp)
 24a:	e04a                	sd	s2,0(sp)
 24c:	1000                	addi	s0,sp,32
 24e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 250:	4581                	li	a1,0
 252:	00000097          	auipc	ra,0x0
 256:	172080e7          	jalr	370(ra) # 3c4 <open>
  if(fd < 0)
 25a:	02054663          	bltz	a0,286 <stat+0x42>
 25e:	e426                	sd	s1,8(sp)
 260:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 262:	85ca                	mv	a1,s2
 264:	00000097          	auipc	ra,0x0
 268:	178080e7          	jalr	376(ra) # 3dc <fstat>
 26c:	892a                	mv	s2,a0
  close(fd);
 26e:	8526                	mv	a0,s1
 270:	00000097          	auipc	ra,0x0
 274:	13c080e7          	jalr	316(ra) # 3ac <close>
  return r;
 278:	64a2                	ld	s1,8(sp)
}
 27a:	854a                	mv	a0,s2
 27c:	60e2                	ld	ra,24(sp)
 27e:	6442                	ld	s0,16(sp)
 280:	6902                	ld	s2,0(sp)
 282:	6105                	addi	sp,sp,32
 284:	8082                	ret
    return -1;
 286:	597d                	li	s2,-1
 288:	bfcd                	j	27a <stat+0x36>

000000000000028a <atoi>:

int
atoi(const char *s)
{
 28a:	1141                	addi	sp,sp,-16
 28c:	e422                	sd	s0,8(sp)
 28e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 290:	00054683          	lbu	a3,0(a0)
 294:	fd06879b          	addiw	a5,a3,-48
 298:	0ff7f793          	zext.b	a5,a5
 29c:	4625                	li	a2,9
 29e:	02f66863          	bltu	a2,a5,2ce <atoi+0x44>
 2a2:	872a                	mv	a4,a0
  n = 0;
 2a4:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 2a6:	0705                	addi	a4,a4,1
 2a8:	0025179b          	slliw	a5,a0,0x2
 2ac:	9fa9                	addw	a5,a5,a0
 2ae:	0017979b          	slliw	a5,a5,0x1
 2b2:	9fb5                	addw	a5,a5,a3
 2b4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2b8:	00074683          	lbu	a3,0(a4)
 2bc:	fd06879b          	addiw	a5,a3,-48
 2c0:	0ff7f793          	zext.b	a5,a5
 2c4:	fef671e3          	bgeu	a2,a5,2a6 <atoi+0x1c>
  return n;
}
 2c8:	6422                	ld	s0,8(sp)
 2ca:	0141                	addi	sp,sp,16
 2cc:	8082                	ret
  n = 0;
 2ce:	4501                	li	a0,0
 2d0:	bfe5                	j	2c8 <atoi+0x3e>

00000000000002d2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2d2:	1141                	addi	sp,sp,-16
 2d4:	e422                	sd	s0,8(sp)
 2d6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2d8:	02b57463          	bgeu	a0,a1,300 <memmove+0x2e>
    while(n-- > 0)
 2dc:	00c05f63          	blez	a2,2fa <memmove+0x28>
 2e0:	1602                	slli	a2,a2,0x20
 2e2:	9201                	srli	a2,a2,0x20
 2e4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2e8:	872a                	mv	a4,a0
      *dst++ = *src++;
 2ea:	0585                	addi	a1,a1,1
 2ec:	0705                	addi	a4,a4,1
 2ee:	fff5c683          	lbu	a3,-1(a1)
 2f2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2f6:	fef71ae3          	bne	a4,a5,2ea <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2fa:	6422                	ld	s0,8(sp)
 2fc:	0141                	addi	sp,sp,16
 2fe:	8082                	ret
    dst += n;
 300:	00c50733          	add	a4,a0,a2
    src += n;
 304:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 306:	fec05ae3          	blez	a2,2fa <memmove+0x28>
 30a:	fff6079b          	addiw	a5,a2,-1
 30e:	1782                	slli	a5,a5,0x20
 310:	9381                	srli	a5,a5,0x20
 312:	fff7c793          	not	a5,a5
 316:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 318:	15fd                	addi	a1,a1,-1
 31a:	177d                	addi	a4,a4,-1
 31c:	0005c683          	lbu	a3,0(a1)
 320:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 324:	fee79ae3          	bne	a5,a4,318 <memmove+0x46>
 328:	bfc9                	j	2fa <memmove+0x28>

000000000000032a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 32a:	1141                	addi	sp,sp,-16
 32c:	e422                	sd	s0,8(sp)
 32e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 330:	ca05                	beqz	a2,360 <memcmp+0x36>
 332:	fff6069b          	addiw	a3,a2,-1
 336:	1682                	slli	a3,a3,0x20
 338:	9281                	srli	a3,a3,0x20
 33a:	0685                	addi	a3,a3,1
 33c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 33e:	00054783          	lbu	a5,0(a0)
 342:	0005c703          	lbu	a4,0(a1)
 346:	00e79863          	bne	a5,a4,356 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 34a:	0505                	addi	a0,a0,1
    p2++;
 34c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 34e:	fed518e3          	bne	a0,a3,33e <memcmp+0x14>
  }
  return 0;
 352:	4501                	li	a0,0
 354:	a019                	j	35a <memcmp+0x30>
      return *p1 - *p2;
 356:	40e7853b          	subw	a0,a5,a4
}
 35a:	6422                	ld	s0,8(sp)
 35c:	0141                	addi	sp,sp,16
 35e:	8082                	ret
  return 0;
 360:	4501                	li	a0,0
 362:	bfe5                	j	35a <memcmp+0x30>

0000000000000364 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 364:	1141                	addi	sp,sp,-16
 366:	e406                	sd	ra,8(sp)
 368:	e022                	sd	s0,0(sp)
 36a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 36c:	00000097          	auipc	ra,0x0
 370:	f66080e7          	jalr	-154(ra) # 2d2 <memmove>
}
 374:	60a2                	ld	ra,8(sp)
 376:	6402                	ld	s0,0(sp)
 378:	0141                	addi	sp,sp,16
 37a:	8082                	ret

000000000000037c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 37c:	4885                	li	a7,1
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <exit>:
.global exit
exit:
 li a7, SYS_exit
 384:	4889                	li	a7,2
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <wait>:
.global wait
wait:
 li a7, SYS_wait
 38c:	488d                	li	a7,3
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 394:	4891                	li	a7,4
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <read>:
.global read
read:
 li a7, SYS_read
 39c:	4895                	li	a7,5
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <write>:
.global write
write:
 li a7, SYS_write
 3a4:	48c1                	li	a7,16
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <close>:
.global close
close:
 li a7, SYS_close
 3ac:	48d5                	li	a7,21
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3b4:	4899                	li	a7,6
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <exec>:
.global exec
exec:
 li a7, SYS_exec
 3bc:	489d                	li	a7,7
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <open>:
.global open
open:
 li a7, SYS_open
 3c4:	48bd                	li	a7,15
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3cc:	48c5                	li	a7,17
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3d4:	48c9                	li	a7,18
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3dc:	48a1                	li	a7,8
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <link>:
.global link
link:
 li a7, SYS_link
 3e4:	48cd                	li	a7,19
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3ec:	48d1                	li	a7,20
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3f4:	48a5                	li	a7,9
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <dup>:
.global dup
dup:
 li a7, SYS_dup
 3fc:	48a9                	li	a7,10
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 404:	48ad                	li	a7,11
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 40c:	48b1                	li	a7,12
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 414:	48b5                	li	a7,13
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 41c:	48b9                	li	a7,14
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 424:	48d9                	li	a7,22
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 42c:	48dd                	li	a7,23
 ecall
 42e:	00000073          	ecall
 ret
 432:	8082                	ret

0000000000000434 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 434:	48e1                	li	a7,24
 ecall
 436:	00000073          	ecall
 ret
 43a:	8082                	ret

000000000000043c <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 43c:	48e5                	li	a7,25
 ecall
 43e:	00000073          	ecall
 ret
 442:	8082                	ret

0000000000000444 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 444:	48e9                	li	a7,26
 ecall
 446:	00000073          	ecall
 ret
 44a:	8082                	ret

000000000000044c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 44c:	1101                	addi	sp,sp,-32
 44e:	ec06                	sd	ra,24(sp)
 450:	e822                	sd	s0,16(sp)
 452:	1000                	addi	s0,sp,32
 454:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 458:	4605                	li	a2,1
 45a:	fef40593          	addi	a1,s0,-17
 45e:	00000097          	auipc	ra,0x0
 462:	f46080e7          	jalr	-186(ra) # 3a4 <write>
}
 466:	60e2                	ld	ra,24(sp)
 468:	6442                	ld	s0,16(sp)
 46a:	6105                	addi	sp,sp,32
 46c:	8082                	ret

000000000000046e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 46e:	7139                	addi	sp,sp,-64
 470:	fc06                	sd	ra,56(sp)
 472:	f822                	sd	s0,48(sp)
 474:	f426                	sd	s1,40(sp)
 476:	0080                	addi	s0,sp,64
 478:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 47a:	c299                	beqz	a3,480 <printint+0x12>
 47c:	0805cb63          	bltz	a1,512 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 480:	2581                	sext.w	a1,a1
  neg = 0;
 482:	4881                	li	a7,0
 484:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 488:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 48a:	2601                	sext.w	a2,a2
 48c:	00000517          	auipc	a0,0x0
 490:	4d450513          	addi	a0,a0,1236 # 960 <digits>
 494:	883a                	mv	a6,a4
 496:	2705                	addiw	a4,a4,1
 498:	02c5f7bb          	remuw	a5,a1,a2
 49c:	1782                	slli	a5,a5,0x20
 49e:	9381                	srli	a5,a5,0x20
 4a0:	97aa                	add	a5,a5,a0
 4a2:	0007c783          	lbu	a5,0(a5)
 4a6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4aa:	0005879b          	sext.w	a5,a1
 4ae:	02c5d5bb          	divuw	a1,a1,a2
 4b2:	0685                	addi	a3,a3,1
 4b4:	fec7f0e3          	bgeu	a5,a2,494 <printint+0x26>
  if(neg)
 4b8:	00088c63          	beqz	a7,4d0 <printint+0x62>
    buf[i++] = '-';
 4bc:	fd070793          	addi	a5,a4,-48
 4c0:	00878733          	add	a4,a5,s0
 4c4:	02d00793          	li	a5,45
 4c8:	fef70823          	sb	a5,-16(a4)
 4cc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4d0:	02e05c63          	blez	a4,508 <printint+0x9a>
 4d4:	f04a                	sd	s2,32(sp)
 4d6:	ec4e                	sd	s3,24(sp)
 4d8:	fc040793          	addi	a5,s0,-64
 4dc:	00e78933          	add	s2,a5,a4
 4e0:	fff78993          	addi	s3,a5,-1
 4e4:	99ba                	add	s3,s3,a4
 4e6:	377d                	addiw	a4,a4,-1
 4e8:	1702                	slli	a4,a4,0x20
 4ea:	9301                	srli	a4,a4,0x20
 4ec:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4f0:	fff94583          	lbu	a1,-1(s2)
 4f4:	8526                	mv	a0,s1
 4f6:	00000097          	auipc	ra,0x0
 4fa:	f56080e7          	jalr	-170(ra) # 44c <putc>
  while(--i >= 0)
 4fe:	197d                	addi	s2,s2,-1
 500:	ff3918e3          	bne	s2,s3,4f0 <printint+0x82>
 504:	7902                	ld	s2,32(sp)
 506:	69e2                	ld	s3,24(sp)
}
 508:	70e2                	ld	ra,56(sp)
 50a:	7442                	ld	s0,48(sp)
 50c:	74a2                	ld	s1,40(sp)
 50e:	6121                	addi	sp,sp,64
 510:	8082                	ret
    x = -xx;
 512:	40b005bb          	negw	a1,a1
    neg = 1;
 516:	4885                	li	a7,1
    x = -xx;
 518:	b7b5                	j	484 <printint+0x16>

000000000000051a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 51a:	715d                	addi	sp,sp,-80
 51c:	e486                	sd	ra,72(sp)
 51e:	e0a2                	sd	s0,64(sp)
 520:	f84a                	sd	s2,48(sp)
 522:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 524:	0005c903          	lbu	s2,0(a1)
 528:	1a090a63          	beqz	s2,6dc <vprintf+0x1c2>
 52c:	fc26                	sd	s1,56(sp)
 52e:	f44e                	sd	s3,40(sp)
 530:	f052                	sd	s4,32(sp)
 532:	ec56                	sd	s5,24(sp)
 534:	e85a                	sd	s6,16(sp)
 536:	e45e                	sd	s7,8(sp)
 538:	8aaa                	mv	s5,a0
 53a:	8bb2                	mv	s7,a2
 53c:	00158493          	addi	s1,a1,1
  state = 0;
 540:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 542:	02500a13          	li	s4,37
 546:	4b55                	li	s6,21
 548:	a839                	j	566 <vprintf+0x4c>
        putc(fd, c);
 54a:	85ca                	mv	a1,s2
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	efe080e7          	jalr	-258(ra) # 44c <putc>
 556:	a019                	j	55c <vprintf+0x42>
    } else if(state == '%'){
 558:	01498d63          	beq	s3,s4,572 <vprintf+0x58>
  for(i = 0; fmt[i]; i++){
 55c:	0485                	addi	s1,s1,1
 55e:	fff4c903          	lbu	s2,-1(s1)
 562:	16090763          	beqz	s2,6d0 <vprintf+0x1b6>
    if(state == 0){
 566:	fe0999e3          	bnez	s3,558 <vprintf+0x3e>
      if(c == '%'){
 56a:	ff4910e3          	bne	s2,s4,54a <vprintf+0x30>
        state = '%';
 56e:	89d2                	mv	s3,s4
 570:	b7f5                	j	55c <vprintf+0x42>
      if(c == 'd'){
 572:	13490463          	beq	s2,s4,69a <vprintf+0x180>
 576:	f9d9079b          	addiw	a5,s2,-99
 57a:	0ff7f793          	zext.b	a5,a5
 57e:	12fb6763          	bltu	s6,a5,6ac <vprintf+0x192>
 582:	f9d9079b          	addiw	a5,s2,-99
 586:	0ff7f713          	zext.b	a4,a5
 58a:	12eb6163          	bltu	s6,a4,6ac <vprintf+0x192>
 58e:	00271793          	slli	a5,a4,0x2
 592:	00000717          	auipc	a4,0x0
 596:	37670713          	addi	a4,a4,886 # 908 <malloc+0x13c>
 59a:	97ba                	add	a5,a5,a4
 59c:	439c                	lw	a5,0(a5)
 59e:	97ba                	add	a5,a5,a4
 5a0:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 5a2:	008b8913          	addi	s2,s7,8
 5a6:	4685                	li	a3,1
 5a8:	4629                	li	a2,10
 5aa:	000ba583          	lw	a1,0(s7)
 5ae:	8556                	mv	a0,s5
 5b0:	00000097          	auipc	ra,0x0
 5b4:	ebe080e7          	jalr	-322(ra) # 46e <printint>
 5b8:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	b745                	j	55c <vprintf+0x42>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5be:	008b8913          	addi	s2,s7,8
 5c2:	4681                	li	a3,0
 5c4:	4629                	li	a2,10
 5c6:	000ba583          	lw	a1,0(s7)
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	ea2080e7          	jalr	-350(ra) # 46e <printint>
 5d4:	8bca                	mv	s7,s2
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	b751                	j	55c <vprintf+0x42>
        printint(fd, va_arg(ap, int), 16, 0);
 5da:	008b8913          	addi	s2,s7,8
 5de:	4681                	li	a3,0
 5e0:	4641                	li	a2,16
 5e2:	000ba583          	lw	a1,0(s7)
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	e86080e7          	jalr	-378(ra) # 46e <printint>
 5f0:	8bca                	mv	s7,s2
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	b7a5                	j	55c <vprintf+0x42>
 5f6:	e062                	sd	s8,0(sp)
        printptr(fd, va_arg(ap, uint64));
 5f8:	008b8c13          	addi	s8,s7,8
 5fc:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 600:	03000593          	li	a1,48
 604:	8556                	mv	a0,s5
 606:	00000097          	auipc	ra,0x0
 60a:	e46080e7          	jalr	-442(ra) # 44c <putc>
  putc(fd, 'x');
 60e:	07800593          	li	a1,120
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	e38080e7          	jalr	-456(ra) # 44c <putc>
 61c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 61e:	00000b97          	auipc	s7,0x0
 622:	342b8b93          	addi	s7,s7,834 # 960 <digits>
 626:	03c9d793          	srli	a5,s3,0x3c
 62a:	97de                	add	a5,a5,s7
 62c:	0007c583          	lbu	a1,0(a5)
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e1a080e7          	jalr	-486(ra) # 44c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 63a:	0992                	slli	s3,s3,0x4
 63c:	397d                	addiw	s2,s2,-1
 63e:	fe0914e3          	bnez	s2,626 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 642:	8be2                	mv	s7,s8
      state = 0;
 644:	4981                	li	s3,0
 646:	6c02                	ld	s8,0(sp)
 648:	bf11                	j	55c <vprintf+0x42>
        s = va_arg(ap, char*);
 64a:	008b8993          	addi	s3,s7,8
 64e:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 652:	02090163          	beqz	s2,674 <vprintf+0x15a>
        while(*s != 0){
 656:	00094583          	lbu	a1,0(s2)
 65a:	c9a5                	beqz	a1,6ca <vprintf+0x1b0>
          putc(fd, *s);
 65c:	8556                	mv	a0,s5
 65e:	00000097          	auipc	ra,0x0
 662:	dee080e7          	jalr	-530(ra) # 44c <putc>
          s++;
 666:	0905                	addi	s2,s2,1
        while(*s != 0){
 668:	00094583          	lbu	a1,0(s2)
 66c:	f9e5                	bnez	a1,65c <vprintf+0x142>
        s = va_arg(ap, char*);
 66e:	8bce                	mv	s7,s3
      state = 0;
 670:	4981                	li	s3,0
 672:	b5ed                	j	55c <vprintf+0x42>
          s = "(null)";
 674:	00000917          	auipc	s2,0x0
 678:	28c90913          	addi	s2,s2,652 # 900 <malloc+0x134>
        while(*s != 0){
 67c:	02800593          	li	a1,40
 680:	bff1                	j	65c <vprintf+0x142>
        putc(fd, va_arg(ap, uint));
 682:	008b8913          	addi	s2,s7,8
 686:	000bc583          	lbu	a1,0(s7)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	dc0080e7          	jalr	-576(ra) # 44c <putc>
 694:	8bca                	mv	s7,s2
      state = 0;
 696:	4981                	li	s3,0
 698:	b5d1                	j	55c <vprintf+0x42>
        putc(fd, c);
 69a:	02500593          	li	a1,37
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	dac080e7          	jalr	-596(ra) # 44c <putc>
      state = 0;
 6a8:	4981                	li	s3,0
 6aa:	bd4d                	j	55c <vprintf+0x42>
        putc(fd, '%');
 6ac:	02500593          	li	a1,37
 6b0:	8556                	mv	a0,s5
 6b2:	00000097          	auipc	ra,0x0
 6b6:	d9a080e7          	jalr	-614(ra) # 44c <putc>
        putc(fd, c);
 6ba:	85ca                	mv	a1,s2
 6bc:	8556                	mv	a0,s5
 6be:	00000097          	auipc	ra,0x0
 6c2:	d8e080e7          	jalr	-626(ra) # 44c <putc>
      state = 0;
 6c6:	4981                	li	s3,0
 6c8:	bd51                	j	55c <vprintf+0x42>
        s = va_arg(ap, char*);
 6ca:	8bce                	mv	s7,s3
      state = 0;
 6cc:	4981                	li	s3,0
 6ce:	b579                	j	55c <vprintf+0x42>
 6d0:	74e2                	ld	s1,56(sp)
 6d2:	79a2                	ld	s3,40(sp)
 6d4:	7a02                	ld	s4,32(sp)
 6d6:	6ae2                	ld	s5,24(sp)
 6d8:	6b42                	ld	s6,16(sp)
 6da:	6ba2                	ld	s7,8(sp)
    }
  }
}
 6dc:	60a6                	ld	ra,72(sp)
 6de:	6406                	ld	s0,64(sp)
 6e0:	7942                	ld	s2,48(sp)
 6e2:	6161                	addi	sp,sp,80
 6e4:	8082                	ret

00000000000006e6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6e6:	715d                	addi	sp,sp,-80
 6e8:	ec06                	sd	ra,24(sp)
 6ea:	e822                	sd	s0,16(sp)
 6ec:	1000                	addi	s0,sp,32
 6ee:	e010                	sd	a2,0(s0)
 6f0:	e414                	sd	a3,8(s0)
 6f2:	e818                	sd	a4,16(s0)
 6f4:	ec1c                	sd	a5,24(s0)
 6f6:	03043023          	sd	a6,32(s0)
 6fa:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6fe:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 702:	8622                	mv	a2,s0
 704:	00000097          	auipc	ra,0x0
 708:	e16080e7          	jalr	-490(ra) # 51a <vprintf>
}
 70c:	60e2                	ld	ra,24(sp)
 70e:	6442                	ld	s0,16(sp)
 710:	6161                	addi	sp,sp,80
 712:	8082                	ret

0000000000000714 <printf>:

void
printf(const char *fmt, ...)
{
 714:	711d                	addi	sp,sp,-96
 716:	ec06                	sd	ra,24(sp)
 718:	e822                	sd	s0,16(sp)
 71a:	1000                	addi	s0,sp,32
 71c:	e40c                	sd	a1,8(s0)
 71e:	e810                	sd	a2,16(s0)
 720:	ec14                	sd	a3,24(s0)
 722:	f018                	sd	a4,32(s0)
 724:	f41c                	sd	a5,40(s0)
 726:	03043823          	sd	a6,48(s0)
 72a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 72e:	00840613          	addi	a2,s0,8
 732:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 736:	85aa                	mv	a1,a0
 738:	4505                	li	a0,1
 73a:	00000097          	auipc	ra,0x0
 73e:	de0080e7          	jalr	-544(ra) # 51a <vprintf>
}
 742:	60e2                	ld	ra,24(sp)
 744:	6442                	ld	s0,16(sp)
 746:	6125                	addi	sp,sp,96
 748:	8082                	ret

000000000000074a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 74a:	1141                	addi	sp,sp,-16
 74c:	e422                	sd	s0,8(sp)
 74e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 750:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 754:	00001797          	auipc	a5,0x1
 758:	8ac7b783          	ld	a5,-1876(a5) # 1000 <freep>
 75c:	a02d                	j	786 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 75e:	4618                	lw	a4,8(a2)
 760:	9f2d                	addw	a4,a4,a1
 762:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 766:	6398                	ld	a4,0(a5)
 768:	6310                	ld	a2,0(a4)
 76a:	a83d                	j	7a8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 76c:	ff852703          	lw	a4,-8(a0)
 770:	9f31                	addw	a4,a4,a2
 772:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 774:	ff053683          	ld	a3,-16(a0)
 778:	a091                	j	7bc <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 77a:	6398                	ld	a4,0(a5)
 77c:	00e7e463          	bltu	a5,a4,784 <free+0x3a>
 780:	00e6ea63          	bltu	a3,a4,794 <free+0x4a>
{
 784:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 786:	fed7fae3          	bgeu	a5,a3,77a <free+0x30>
 78a:	6398                	ld	a4,0(a5)
 78c:	00e6e463          	bltu	a3,a4,794 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 790:	fee7eae3          	bltu	a5,a4,784 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 794:	ff852583          	lw	a1,-8(a0)
 798:	6390                	ld	a2,0(a5)
 79a:	02059813          	slli	a6,a1,0x20
 79e:	01c85713          	srli	a4,a6,0x1c
 7a2:	9736                	add	a4,a4,a3
 7a4:	fae60de3          	beq	a2,a4,75e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 7a8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7ac:	4790                	lw	a2,8(a5)
 7ae:	02061593          	slli	a1,a2,0x20
 7b2:	01c5d713          	srli	a4,a1,0x1c
 7b6:	973e                	add	a4,a4,a5
 7b8:	fae68ae3          	beq	a3,a4,76c <free+0x22>
    p->s.ptr = bp->s.ptr;
 7bc:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7be:	00001717          	auipc	a4,0x1
 7c2:	84f73123          	sd	a5,-1982(a4) # 1000 <freep>
}
 7c6:	6422                	ld	s0,8(sp)
 7c8:	0141                	addi	sp,sp,16
 7ca:	8082                	ret

00000000000007cc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7cc:	7139                	addi	sp,sp,-64
 7ce:	fc06                	sd	ra,56(sp)
 7d0:	f822                	sd	s0,48(sp)
 7d2:	f426                	sd	s1,40(sp)
 7d4:	ec4e                	sd	s3,24(sp)
 7d6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7d8:	02051493          	slli	s1,a0,0x20
 7dc:	9081                	srli	s1,s1,0x20
 7de:	04bd                	addi	s1,s1,15
 7e0:	8091                	srli	s1,s1,0x4
 7e2:	0014899b          	addiw	s3,s1,1
 7e6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7e8:	00001517          	auipc	a0,0x1
 7ec:	81853503          	ld	a0,-2024(a0) # 1000 <freep>
 7f0:	c915                	beqz	a0,824 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7f4:	4798                	lw	a4,8(a5)
 7f6:	08977e63          	bgeu	a4,s1,892 <malloc+0xc6>
 7fa:	f04a                	sd	s2,32(sp)
 7fc:	e852                	sd	s4,16(sp)
 7fe:	e456                	sd	s5,8(sp)
 800:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 802:	8a4e                	mv	s4,s3
 804:	0009871b          	sext.w	a4,s3
 808:	6685                	lui	a3,0x1
 80a:	00d77363          	bgeu	a4,a3,810 <malloc+0x44>
 80e:	6a05                	lui	s4,0x1
 810:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 814:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 818:	00000917          	auipc	s2,0x0
 81c:	7e890913          	addi	s2,s2,2024 # 1000 <freep>
  if(p == (char*)-1)
 820:	5afd                	li	s5,-1
 822:	a091                	j	866 <malloc+0x9a>
 824:	f04a                	sd	s2,32(sp)
 826:	e852                	sd	s4,16(sp)
 828:	e456                	sd	s5,8(sp)
 82a:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 82c:	00000797          	auipc	a5,0x0
 830:	7e478793          	addi	a5,a5,2020 # 1010 <base>
 834:	00000717          	auipc	a4,0x0
 838:	7cf73623          	sd	a5,1996(a4) # 1000 <freep>
 83c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 83e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 842:	b7c1                	j	802 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 844:	6398                	ld	a4,0(a5)
 846:	e118                	sd	a4,0(a0)
 848:	a08d                	j	8aa <malloc+0xde>
  hp->s.size = nu;
 84a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 84e:	0541                	addi	a0,a0,16
 850:	00000097          	auipc	ra,0x0
 854:	efa080e7          	jalr	-262(ra) # 74a <free>
  return freep;
 858:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 85c:	c13d                	beqz	a0,8c2 <malloc+0xf6>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 85e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 860:	4798                	lw	a4,8(a5)
 862:	02977463          	bgeu	a4,s1,88a <malloc+0xbe>
    if(p == freep)
 866:	00093703          	ld	a4,0(s2)
 86a:	853e                	mv	a0,a5
 86c:	fef719e3          	bne	a4,a5,85e <malloc+0x92>
  p = sbrk(nu * sizeof(Header));
 870:	8552                	mv	a0,s4
 872:	00000097          	auipc	ra,0x0
 876:	b9a080e7          	jalr	-1126(ra) # 40c <sbrk>
  if(p == (char*)-1)
 87a:	fd5518e3          	bne	a0,s5,84a <malloc+0x7e>
        return 0;
 87e:	4501                	li	a0,0
 880:	7902                	ld	s2,32(sp)
 882:	6a42                	ld	s4,16(sp)
 884:	6aa2                	ld	s5,8(sp)
 886:	6b02                	ld	s6,0(sp)
 888:	a03d                	j	8b6 <malloc+0xea>
 88a:	7902                	ld	s2,32(sp)
 88c:	6a42                	ld	s4,16(sp)
 88e:	6aa2                	ld	s5,8(sp)
 890:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 892:	fae489e3          	beq	s1,a4,844 <malloc+0x78>
        p->s.size -= nunits;
 896:	4137073b          	subw	a4,a4,s3
 89a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 89c:	02071693          	slli	a3,a4,0x20
 8a0:	01c6d713          	srli	a4,a3,0x1c
 8a4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8a6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8aa:	00000717          	auipc	a4,0x0
 8ae:	74a73b23          	sd	a0,1878(a4) # 1000 <freep>
      return (void*)(p + 1);
 8b2:	01078513          	addi	a0,a5,16
  }
}
 8b6:	70e2                	ld	ra,56(sp)
 8b8:	7442                	ld	s0,48(sp)
 8ba:	74a2                	ld	s1,40(sp)
 8bc:	69e2                	ld	s3,24(sp)
 8be:	6121                	addi	sp,sp,64
 8c0:	8082                	ret
 8c2:	7902                	ld	s2,32(sp)
 8c4:	6a42                	ld	s4,16(sp)
 8c6:	6aa2                	ld	s5,8(sp)
 8c8:	6b02                	ld	s6,0(sp)
 8ca:	b7f5                	j	8b6 <malloc+0xea>
