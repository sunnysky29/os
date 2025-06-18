#include "../include/minilibc.h"

int main(int argc, char** argv) {
    /* Test string functions */
    char buffer[100];
    strcpy(buffer, "Hello from mini libc!");
    printf("String copied: %s\n", buffer);
    printf("Length of string: %d\n", strlen(buffer));
    
    /* Test printf with %d format */
    printf("Number of arguments: %d\n", argc);
    
    /* Print all command line arguments */
    printf("Command line arguments:\n");
    for (int i = 0; i < argc; i++) {
        printf("  argv[%d]: %s\n", i, argv[i]);
    }
    
    /* Test memory allocation */
    char* mem = (char*)malloc(50);
    if (mem) {
        strcpy(mem, "Memory allocation works!");
        printf("Allocated memory: %s\n", mem);
        free(mem);
    } else {
        printf("Memory allocation failed!\n");
    }
    
    /* Test puts function */
    puts("This is printed using puts()");
    
    return 42; /* Return a specific value to check if exit() works */
} 