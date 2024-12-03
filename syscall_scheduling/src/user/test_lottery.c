#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NPROCS  3  // Number of child processes
#define WORK    10000000  // Amount of work each process does

// Function to perform some work
void perform_work(int n, int pid, int tickets) {
  volatile int i;
  for (i = 0; i < n; i++) {
    if (i % (n / 10) == 0) {
      // Print in a single statement to avoid jumbled output
    //   printf("Process %d with %d tickets is working...\n", pid, tickets);
    }
  }
  exit(0);
}

int main() {
  int pid;
  int tickets[NPROCS] = {4, 5, 6};  // Tickets for each child process
  int i;

  // Set tickets for parent process (lower priority)
  settickets(1);

  // Fork child processes
  for (i = 0; i < NPROCS; i++) {
    pid = fork();
    if (pid < 0) {
      printf("Fork failed!\n");
      exit(1);
    }
    if (pid == 0) {
      // Child process: Set tickets and perform work
      settickets(tickets[i]);
    //   printf("Process %d starts with %d tickets\n", getpid(), tickets[i]);
      perform_work(WORK, getpid(), tickets[i]);
    }
    // Parent continues to fork more children
  }

  // Parent waits for all child processes to finish
  for (i = 0; i < NPROCS; i++) {
    wait(0);
  }

  printf("All child processes finished.\n");
  exit(0);
}
