// cowtest_read.c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

int main()
{
    int *shared_page;
    int pid;

    // Allocate a page of memory
    shared_page = (int *)sbrk(4096);
    shared_page[0] = 1; // Initialize the page with a value

    // Fork a child process
    pid = fork();

    if (pid < 0)
    {
        printf("Fork failed\n");
        exit(0);
    }

    if (pid == 0)
    {
        // Child process - only read the shared page
        printf("Child: Reading shared_page[0]: %d\n", shared_page[0]);

        // Exit child process
        exit(0);
    }
    else
    {
        // Parent process - wait for child to finish
        wait(0);
        printf("Parent: Read-only test complete.\n");
    }

    exit(0);
}
