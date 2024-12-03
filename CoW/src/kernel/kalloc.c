// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define KERNBASE 0x80000000L
#define PA2REF(pa) (((uint64)(pa) - KERNBASE) / PGSIZE)

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

// Simple reference counting
#define NPAGE ((PHYSTOP - KERNBASE) / PGSIZE)
int ref_count[NPAGE];
struct spinlock ref_lock;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  initlock(&ref_lock, "ref_count");
  memset(ref_count, 0, sizeof(ref_count));
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  acquire(&ref_lock);
  int idx = ((uint64)pa - KERNBASE) / PGSIZE;
  if(ref_count[idx] > 1) {
    ref_count[idx]--;
    release(&ref_lock);
    return;
  }
  ref_count[idx] = 0;
  release(&ref_lock);

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r) {
    memset((char*)r, 5, PGSIZE);
    acquire(&ref_lock);
    ref_count[((uint64)r - KERNBASE) / PGSIZE] = 1;
    release(&ref_lock);
  }
  return (void*)r;
}

void
incref(uint64 pa)
{
  acquire(&ref_lock);
  ref_count[(pa - KERNBASE) / PGSIZE]++;
  release(&ref_lock);
}

int
getref(uint64 pa)
{
  int idx = (pa - KERNBASE) / PGSIZE;
  acquire(&ref_lock);
  int ref = ref_count[idx];
  release(&ref_lock);
  return ref;
}
