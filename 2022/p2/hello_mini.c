/*

会Segmentation fault !!!!

gcc  -c hello_mini.c  && objdump  -d hello_mini.o

gcc  -c hello_mini.c  && objdump  -d hello_mini.o  && ld hello_mini.o
hello_mini.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <_start>:
   0:   f3 0f 1e fa             endbr64
   4:   55                      push   %rbp
   5:   48 89 e5                mov    %rsp,%rbp
   8:   90                      nop
   9:   5d                      pop    %rbp
   a:   c3                      ret


*/

// #include <stdio.h>
// #include <unistd.h>



int _start() {

    // printf("Hello world \n");
    
}


