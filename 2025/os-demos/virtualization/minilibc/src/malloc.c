#include "../include/minilibc.h"

/* System call number for mmap and munmap */
#define SYS_MMAP 9
#define SYS_MUNMAP 11

/* Very simple malloc implementation using mmap */
void* malloc(size_t size) {
    /* Align size to 8 bytes */
    size = (size + 7) & ~7;
    
    /* Add space for size information */
    size_t total_size = size + sizeof(size_t);
    
    /* Request memory from the system using mmap */
    void* block = (void*)0; // Initialize block
    __asm__ volatile (
        "mov $0, %%rdi\n"      /* Address (NULL) */
        "mov %1, %%rsi\n"      /* Size */
        "mov $3, %%rdx\n"      /* PROT_READ | PROT_WRITE */
        "mov $34, %%r10\n"     /* MAP_PRIVATE | MAP_ANONYMOUS */
        "mov $-1, %%r8\n"      /* File descriptor */
        "mov $0, %%r9\n"       /* Offset */
        "mov $9, %%rax\n"      /* mmap system call number */
        "syscall\n"
        "mov %%rax, %0\n"      /* Store the returned pointer */
        : "=r" (block)
        : "r" (total_size)
        : "%rax", "%rdi", "%rsi", "%rdx", "%r10", "%r8", "%r9"
    );
    
    if (block == (void*)-1) {
        return NULL;
    }
    
    /* Store the size at the beginning of the block */
    *(size_t*)block = size;
    
    /* Return the memory after the size field */
    return (char*)block + sizeof(size_t);
}

/* Simple free implementation using munmap */
void free(void* ptr) {
    if (ptr) {
        /* Get the size stored at the beginning of the block */
        size_t size = *(size_t*)((char*)ptr - sizeof(size_t));
        
        /* Unmap the memory using munmap */
        __asm__ volatile (
            "mov %0, %%rdi\n"      /* Pointer to the block */
            "mov %1, %%rsi\n"      /* Size */
            "mov $11, %%rax\n"     /* munmap system call number */
            "syscall\n"
            :
            : "r" ((uintptr_t)ptr - sizeof(size_t)), "r" (size + sizeof(size_t))
            : "%rax", "%rdi", "%rsi"
        );
    }
} 
