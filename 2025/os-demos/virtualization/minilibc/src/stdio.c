#include "../include/minilibc.h"

/* Implementation of write() using system calls */
ssize_t write(int fd, const void* buf, size_t count) {
    ssize_t ret;
    __asm__ volatile (
        "mov %1, %%rdi\n"    /* File descriptor */
        "mov %2, %%rsi\n"    /* Buffer */
        "mov %3, %%rdx\n"    /* Count */
        "mov $1, %%rax\n"    /* System call number for write */
        "syscall\n"          /* Make the system call */
        "mov %%rax, %0\n"    /* Save the result */
        : "=r" (ret)
        : "r" ((long)fd), "r" (buf), "r" (count)
        : "%rax", "%rdi", "%rsi", "%rdx"
    );
    return ret;
}

/* Print an integer to a buffer */
static int print_int(char* buffer, int number) {
    char temp[20];  /* Buffer for converted digits */
    int i = 0;
    int count = 0;
    int negative = 0;
    
    /* Handle negative numbers */
    if (number < 0) {
        negative = 1;
        number = -number;
    }
    
    /* Handle special case of 0 */
    if (number == 0) {
        temp[i++] = '0';
    } else {
        /* Convert number to characters */
        while (number > 0) {
            temp[i++] = '0' + (number % 10);
            number /= 10;
        }
    }
    
    /* Add negative sign if needed */
    if (negative) {
        buffer[count++] = '-';
    }
    
    /* Copy digits in correct order */
    while (i > 0) {
        buffer[count++] = temp[--i];
    }
    
    return count;
}

/* Simple puts implementation */
int puts(const char* s) {
    size_t len = strlen(s);
    ssize_t written = write(1, s, len);
    if (written < 0) {
        return -1;
    }
    
    /* Write newline character */
    written = write(1, "\n", 1);
    if (written < 0) {
        return -1;
    }
    
    return 0;
}

/* Simple printf implementation supporting only %s and %d format specifiers */
int printf(const char* format, ...) {
    va_list args;
    va_start(args, format);
    
    const char* p;
    char buffer[1024];  /* Fixed buffer for simplicity */
    int count = 0;
    
    for (p = format; *p; p++) {
        if (*p != '%') {
            buffer[count++] = *p;
            continue;
        }
        
        /* Handle format specifier */
        p++;
        switch (*p) {
            case 's': {
                char* s = va_arg(args, char*);
                if (s == NULL) {
                    s = "(null)";
                }
                size_t len = strlen(s);
                for (size_t i = 0; i < len; i++) {
                    buffer[count++] = s[i];
                }
                break;
            }
            case 'd': {
                int num = va_arg(args, int);
                count += print_int(buffer + count, num);
                break;
            }
            case '%': {
                buffer[count++] = '%';
                break;
            }
            default: {
                buffer[count++] = '%';
                buffer[count++] = *p;
                break;
            }
        }
    }
    
    va_end(args);
    
    /* Write the buffer to stdout */
    write(1, buffer, count);
    
    return count;
} 