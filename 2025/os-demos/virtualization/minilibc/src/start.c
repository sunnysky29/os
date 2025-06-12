#include "../include/minilibc.h"

/* 
 * This is the program entry point that the kernel jumps to.
 * It sets up the environment, calls main, and then exits.
 */

__attribute__((optimize("omit-frame-pointer")))
void _start(void) {
    /* 
     * When the program starts, the stack looks like this:
     * [lowest address] argc, argv[0], argv[1], ..., argv[n], 0, envp[0], ... [highest address]
     * We need to get these values off the stack to pass to main
     */
    register int argc asm("edi");
    register char** argv asm("rsi");
    
    /* Get argc and argv from the stack using inline assembly */
    __asm__ volatile (
        "mov 8(%%rsp), %0\n"      /* Get argc from stack */
        "lea 16(%%rsp), %1\n"     /* Get address of argv[0] */
        : "=r" (argc), "=r" (argv) /* Output operands */
    );
    
    /* Call initialization functions before main */
    _init();
    
    /* Call main with the arguments */
    register int result asm ("eax") = main(argc, argv);
    
    /* Exit with the result of main */
    exit(result);
}

/* Initialization function that runs before main */
void _init(void) {
    /* This would normally set up things like stdio */
    /* For our minimal implementation, we'll leave it empty */
}

/* Cleanup function that runs at program termination */
void _fini(void) {
    /* This would normally clean up resources */
    /* For our minimal implementation, we'll leave it empty */
}

/* Exit function that terminates the program */
void exit(int status) {
    /* Call cleanup routines */
    _fini();
    
    /* Use system call to exit */
    __asm__ volatile (
        "mov %0, %%rdi\n"    /* First argument: exit status */
        "mov $60, %%rax\n"   /* System call number for exit */
        "syscall\n"          /* Make the system call */
        : 
        : "r" ((long)status)
        : "%rax", "%rdi"
    );
    
    /* Should never reach here */
    while(1);
} 
