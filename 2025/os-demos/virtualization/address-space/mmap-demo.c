// Author: claude-3.7-sonnet

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // Example 1: Allocate memory using mmap
    void *mem1 = mmap(
        NULL,                   // Let the kernel choose the address
        4096,                   // Allocate 4KB
        PROT_READ | PROT_WRITE, // Read and write permissions
        MAP_PRIVATE | MAP_ANONYMOUS, // Private mapping not backed by a file
        -1,                     // No file descriptor needed for anonymous mapping
        0                       // No offset
    );
    
    if (mem1 == MAP_FAILED) {
        perror("mmap anonymous");
        return 1;
    }
    
    // Write to the allocated memory
    sprintf(mem1, "This is allocated memory at %p\n", mem1);
    printf("%s", (char*)mem1);
    
    // Example 2: Map the executable itself (argv[0])
    int fd = open(argv[0], O_RDONLY);
    if (fd == -1) {
        perror("open");
        return 1;
    }
    
    // Get file size
    struct stat st;
    if (fstat(fd, &st) == -1) {
        perror("fstat");
        close(fd);
        return 1;
    }
    
    // Map the executable file
    void *exe_map = mmap(
        NULL,                   // Let the kernel choose the address
        st.st_size,             // Map the whole file
        PROT_READ,              // Read-only permissions
        MAP_PRIVATE,            // Private mapping
        fd,                     // File descriptor
        0                       // Start from the beginning of the file
    );
    
    if (exe_map == MAP_FAILED) {
        perror("mmap file");
        close(fd);
        return 1;
    }
    
    printf("Mapped executable at %p, size: %ld bytes\n", exe_map, st.st_size);
    
    // Display first 16 bytes of the executable (usually the ELF header magic)
    printf("First 16 bytes of executable: ");
    for (int i = 0; i < 16; i++) {
        printf("%02x ", ((unsigned char*)exe_map)[i]);
    }
    printf("\n");
    
    // Clean up
    munmap(mem1, 4096);
    munmap(exe_map, st.st_size);
    close(fd);
    
    return 0;

}
