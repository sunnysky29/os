#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

#define NUM_FDS 8

void demo_fd_allocation() {
    int fds[NUM_FDS];

    // Allocate file descriptors
    for (int i = 0; i < NUM_FDS; i++) {
        fds[i] = open("/dev/null", O_RDWR);
        if (fds[i] < 0) {
            perror("Failed to open /dev/null");
            exit(EXIT_FAILURE);
        }
        printf("Allocated file descriptor fds[%d]: %d\n", i, fds[i]);
    }

    // Close odd file descriptors
    for (int i = 1; i < NUM_FDS; i += 2) {
        close(fds[i]);
        printf("Closed file descriptor fds[%d]: %d\n", i, fds[i]);
    }

    // Reopen closed file descriptors and check their numbers
    for (int i = 1; i < NUM_FDS; i += 2) {
        fds[i] = open("/dev/null", O_RDWR);
        if (fds[i] < 0) {
            perror("Failed to reopen /dev/null");
            exit(EXIT_FAILURE);
        }
        printf("Reallocated file descriptor fds[%d]: %d\n", i, fds[i]);
    }

    // Close all file descriptors
    for (int i = 0; i < NUM_FDS; i++) {
        close(fds[i]);
        printf("Closed file descriptor fds[%d]: %d\n", i, fds[i]);
    }
}

int main() {
    demo_fd_allocation();
    return 0;
}

