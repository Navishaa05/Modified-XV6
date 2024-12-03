# xv6

# System Calls

In the given initial xv-6 code,the following syscalls have been added:

1. `getSysCount `
   It counts the number of times a specific system call was called by a process and prints it.

2. `sigalarm`
   If an application calls sigalarm(n, fn) , then after every n ”ticks” of CPU time that the program consumes, the kernel will cause application function fn to be called. When fn returns, the application will resume where it left off.

3. `sigreturn`
   This is to reset the process state to before the handler was called. This system call needs to be made at the end of the handler so the process can resume where it left off.

Here is the implementation of the given syscalls

```c
uint64
sys_getSysCount(void)
{
  int k;
  argint(0, &k);
  struct proc *p = myproc();
  return p->syscall_count[k];
}
```

```c
uint64 sys_sigalarm(void)
{
  int time;
  uint64 handler;
  argaddr(1, &handler);
  argint(0, &time);

  struct proc *p = myproc();
  p->alarm_interval = time;
  p->handler = handler;
  p->ticks = 0;
  p->alarm_flag = 0;

  return 0;
}
```

```c
uint64 sys_sigreturn(void)
{
  struct proc *p = myproc();
  memmove(p->trapframe, &p->alarm_trapframe, sizeof(struct trapframe));
  p->alarm_flag = 0;
  return p->trapframe->a0;
}
```
