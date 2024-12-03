#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_getSysCount(void)
{

  int mask;
  argint(0, &mask);

  struct proc *p = myproc();
  int syscall_num = 0;
  uint64 count = 0;

  while ((mask & 1) == 0 && syscall_num < 32)
  {
    mask >>= 1;
    syscall_num++;
  }

  count = p->syscall_count[syscall_num];

  return count;
}

uint64 sys_sigreturn(void)
{
  struct proc *p = myproc();
  struct trapframe *old_tf = p->trapframe;
  struct trapframe *new_tf = p->new_trapframe;
  old_tf->kernel_sp = new_tf->kernel_sp;
  old_tf->kernel_trap = new_tf->kernel_trap;
  old_tf->kernel_satp = new_tf->kernel_satp;
  old_tf->kernel_hartid = new_tf->kernel_hartid;
  *old_tf = *new_tf;
  p->bool_sigalarm = 0;
  return old_tf->a0;
}

uint64 sys_sigalarm(void)
{
  uint64 handle;
  int ticks;
  struct proc *pa = myproc();
  argaddr(1, &handle);
  argint(0, &ticks);
  if (handle < 0 || ticks < 0)
  {
    return -1;
  }
  pa->interval = ticks;
  pa->handler = handle;
  pa->bool_sigalarm = 0;
  pa->till_tick = 0;

  return 0;
}

uint64
sys_settickets(void)
{
  int number;
  argint(0, &number);

  return settickets(number);
}
