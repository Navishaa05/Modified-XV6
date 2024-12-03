#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

#ifdef MLFQ
extern struct Queue mlfq[NMLFQ];
#endif

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8)
  {
    // system call

    if (killed(p))
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0)
  {
    // ok
  }
  else
  {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if (killed(p))
    exit(-1);

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2)
  {

    p->till_tick++;
    if (p->bool_sigalarm == 0 && p->interval > 0 && p->till_tick >= p->interval)
    {
      p->bool_sigalarm = 1;
      p->till_tick = 0;
      // *(p->new_trapframe) = *(p->trapframe);
      p->new_trapframe->kernel_sp = p->trapframe->kernel_sp;
      p->new_trapframe->kernel_trap = p->trapframe->kernel_trap;
      p->new_trapframe->kernel_satp = p->trapframe->kernel_satp;
      p->new_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
      p->new_trapframe->epc = p->trapframe->epc;
      p->new_trapframe->ra = p->trapframe->ra;
      p->new_trapframe->sp = p->trapframe->sp;
      p->new_trapframe->gp = p->trapframe->gp;
      p->new_trapframe->tp = p->trapframe->tp;
      p->new_trapframe->t0 = p->trapframe->t0;
      p->new_trapframe->t1 = p->trapframe->t1;
      p->new_trapframe->t2 = p->trapframe->t2;
      p->new_trapframe->s0 = p->trapframe->s0;
      p->new_trapframe->s1 = p->trapframe->s1;
      p->new_trapframe->a0 = p->trapframe->a0;
      p->new_trapframe->a1 = p->trapframe->a1;
      p->new_trapframe->a2 = p->trapframe->a2;
      p->new_trapframe->a3 = p->trapframe->a3;
      p->new_trapframe->a4 = p->trapframe->a4;
      p->new_trapframe->a5 = p->trapframe->a5;
      p->new_trapframe->a6 = p->trapframe->a6;
      p->new_trapframe->a7 = p->trapframe->a7;
      p->new_trapframe->s2 = p->trapframe->s2;
      p->new_trapframe->s3 = p->trapframe->s3;
      p->new_trapframe->s4 = p->trapframe->s4;
      p->new_trapframe->s5 = p->trapframe->s5;
      p->new_trapframe->s6 = p->trapframe->s6;
      p->new_trapframe->s7 = p->trapframe->s7;
      p->new_trapframe->s8 = p->trapframe->s8;
      p->new_trapframe->s9 = p->trapframe->s9;
      p->new_trapframe->s10 = p->trapframe->s10;
      p->new_trapframe->s11 = p->trapframe->s11;
      p->new_trapframe->t3 = p->trapframe->t3;
      p->new_trapframe->t4 = p->trapframe->t4;
      p->new_trapframe->t5 = p->trapframe->t5;
      p->new_trapframe->t6 = p->trapframe->t6;
      p->trapframe->epc = p->handler;
    }
#ifndef MLFQ
    yield();
#endif
  }
#ifdef MLFQ

  if (myproc()->state == RUNNING)
  {
    if (which_dev == 2 && myproc())
    {
      struct proc *p = myproc();
      if (p->timeslice <= 0)
      {
        if (p->priority  < 3)
        {
          p->priority++;
        }
        switch (p->priority)
        {
        case 0:
          p->timeslice = 1; // For priority 0: 1 timer tick
          break;
        case 1:
          p->timeslice = 4; // For priority 1: 4 timer ticks
          break;
        case 2:
          p->timeslice = 8; // For priority 2: 8 timer ticks
          break;
        case 3:
          p->timeslice = 16; // For priority 3: 16 timer ticks
          break;
        default:
          p->timeslice = 1; // Fallback to 1 tick if priority is invalid
        }
        yield();
      }
      int j = 0;
      while (j < p->priority)
      {
        if (mlfq[j].size)
        {
          yield();
        }
        j++;
      }
    }
  }

#endif

  // if (myproc() != 0 && myproc()->state == RUNNING)
  // {

  //   yield();
  // }

  usertrapret();
}

void usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

// give up the CPU if this is a timer interrupt.
#ifndef MLFQ
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
  {

    yield();
  }
#endif
#ifdef MLFQ
  if (which_dev == 2 && myproc() != 0)
  {
    if (myproc()->state == RUNNING)
    {
      struct proc *p = myproc();
      if (p->timeslice <= 0)
      {
        if (p->priority  < 3)
        {

          p->priority++;
        }
        switch (p->priority)
        {
        case 0:
          p->timeslice = 1; 
          break;
        case 1:
          p->timeslice = 4; 
          break;
        case 2:
          p->timeslice = 8; 
          break;
        case 3:
          p->timeslice = 16; 
          break;
        default:
          p->timeslice = 1; 
        }

        yield();
      }
      int i = 0;
      while (i < p->priority)
      {
        if (mlfq[i].size)
        {
          yield();
        }
        i++;
      }
    }
  }
#endif

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  // for (struct proc *p = proc; p < &proc[NPROC]; p++)
  // {
  //   acquire(&p->lock);
  //   if (p->state == RUNNING)
  //   {
  //     // printf("here");
  //     p->rtime++;
  //   }
  //   // if (p->state == SLEEPING)
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
  release(&tickslock);
}

int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}
