#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>

void demo_dup_offset() {
    int fd1 = open("sample.txt", O_RDWR | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    if (fd1 < 0) {
        perror("Failed to open sample.txt");
        exit(EXIT_FAILURE);
    }

    // Duplicate the file descriptor
    int fd2 = dup(fd1);

    if (fd2 < 0) {
        perror("Failed to duplicate file descriptor");
        close(fd1);
        exit(EXIT_FAILURE);
    }

    // Write "A" to the file
    write(fd1, "A", 1);

    // Write "B" using the duplicated file descriptor
    write(fd2, "B", 1);

    // Close both file descriptors
    close(fd1);
    close(fd2);

    // Read the content of the file to check the result
    char buffer[3] = {0}; // 2 characters + null terminator
    fd1 = open("sample.txt", O_RDONLY);
    if (fd1 < 0) {
        perror("Failed to open sample.txt for reading");
        exit(EXIT_FAILURE);
    }
    read(fd1, buffer, 2);
    printf("Content of sample.txt: %s\n", buffer); // Should print "AB"
    close(fd1);
}

void demo_fork_offset() {
    int fd = open("sample.txt", O_RDWR | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    if (fd < 0) {
        perror("Failed to open sample.txt");
        exit(EXIT_FAILURE);
    }

    // Write "C" to the file

    pid_t pid = fork();
    if (pid < 0) {
        perror("Failed to fork");
        close(fd);
        exit(EXIT_FAILURE);
    } else if (pid == 0) {
        // Child process
        write(fd, "D", 1);
        close(fd);
        exit(EXIT_SUCCESS);
    } else {
        // Parent process
        wait(NULL); // Wait for child to finish
        write(fd, "C", 1);
        close(fd);
    }

    // Read the content of the file to check the result
    fd = open("sample.txt", O_RDONLY);
    if (fd < 0) {
        perror("Failed to open sample.txt for reading");
        exit(EXIT_FAILURE);
    }
    char buffer[3] = {0}; // 2 characters + null terminator
    read(fd, buffer, 2);
    printf("Content of sample.txt after fork: %s\n", buffer); // Should print "CD"
    close(fd);
}

int main() {
    demo_dup_offset();
    demo_fork_offset();
    return 0;
}
