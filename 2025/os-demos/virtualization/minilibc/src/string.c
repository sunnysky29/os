#include "../include/minilibc.h"

/* Calculate the length of a string */
size_t strlen(const char* s) {
    const char* p = s;
    while (*p) {
        p++;
    }
    return p - s;
}

/* Copy a string from src to dest */
char* strcpy(char* dest, const char* src) {
    char* d = dest;
    while ((*d++ = *src++));
    return dest;
}

/* Compare two strings */
int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char*)s1 - *(unsigned char*)s2;
} 