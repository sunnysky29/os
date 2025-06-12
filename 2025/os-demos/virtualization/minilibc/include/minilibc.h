#ifndef MINILIBC_H
#define MINILIBC_H

#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <sys/types.h>

/* Memory functions */
void* malloc(size_t size);
void free(void* ptr);

/* String functions */
size_t strlen(const char* s);
char* strcpy(char* dest, const char* src);

/* I/O functions */
int printf(const char* format, ...);
int puts(const char* s);
ssize_t write(int fd, const void* buf, size_t count);

/* Program startup/exit */
extern int main(int argc, char** argv);
void exit(int status) __attribute__((noreturn));

/* This is used internally but exposed for educational purposes */
void _start(void) __attribute__((noreturn));
void _init(void);
void _fini(void);

#endif /* MINILIBC_H */ 
