// Create a new file user/syscount.c

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc < 3){
    fprintf(2, "Usage: syscount <mask> command [args]\n");
    exit(1);
  }

  int mask = atoi(argv[1]);
  
  int pid = fork();
  if(pid < 0){
    fprintf(2, "fork failed\n");
    exit(1);
  }
  
  if(pid == 0){
    // Child process
    exec(argv[2], &argv[2]);
    fprintf(2, "exec failed\n");
    exit(1);
  } else {
    // Parent process
    wait(0);
    int count = getSysCount(mask);
    
    char *syscall_names[] = {
      "fork", "exit", "wait", "pipe", "read",
      "kill", "exec", "fstat", "chdir", "dup",
      "getpid", "sbrk", "sleep", "uptime", "open",
      "write", "mknod", "unlink", "link", "mkdir",
      "close", "getSysCount"
    };
    
    int syscall_num = 0;
    while(mask != 1) {
      mask >>= 1;
      syscall_num++;
    }
    
    printf("PID %d called %s %d times\n", pid, syscall_names[--syscall_num], count);
  }
  
  exit(0);
}