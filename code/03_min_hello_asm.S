/* 

最小的 hello  world ！！
gcc 03_min_hello_asm.S  -c && ld 03_min_hello_asm.o

$ ./a.out
Hello, OS World

$  gcc -E 03_min_hello_asm.S  ## 处理预编译结果

  .globl _start
  _start:
    movq $1, %rax
    movq $1, %rdi
    movq $st, %rsi
    movq $(ed - st), %rdx
    syscall
  
    movq $60, %rax
    movq $1, %rdi
    syscall
  
  st:
    .ascii "\033[01;31mHello, OS World\033[0m\n"
  ed:

*/
// ------------------------------------------

#include <sys/syscall.h>

.globl _start
_start:
  movq $SYS_write, %rax   // write(
  movq $1,         %rdi   //   fd=1,
  movq $st,        %rsi   //   buf=st,
  movq $(ed - st), %rdx   //   count=ed-st
  syscall                 // );

  movq $SYS_exit,  %rax   // exit(
  movq $1,         %rdi   //   status=1
  syscall                 // );

st:
  .ascii "\033[01;31mHello, OS World\033[0m\n"
ed:
