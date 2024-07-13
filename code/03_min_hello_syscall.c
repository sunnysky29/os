/*
异常退出解决： syscall

gcc 03_min_hello_syscall.c  &&  ./a.out; echo $status

*/

#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>

// void _start() {
//     // printf("Hello, World\n");
//     // while (1);
// }

int main() {
    syscall(SYS_exit, 42);
}
