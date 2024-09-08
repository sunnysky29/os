/*
AddressSanitizer (asan); (paper): 非法内存访问
Buffer (heap/stack/global) overflow, use-after-free, use-after-return, double-free, ...
Demo: uaf.c; kasan

 gcc -g uaf.c   -fsanitize=address

df@moss:~/codes/os/2022/p8$ ./a.out
=================================================================
==495511==ERROR: AddressSanitizer: heap-use-after-free on address 0x602000000010 at pc 0x55a237da5267 bp 0x7ffec676e200 sp 0x7ffec676e1f0
WRITE of size 4 at 0x602000000010 thread T0
    #0 0x55a237da5266 in main /home/df/codes/os/2022/p8/uaf.c:13
    #1 0x7f85d460ed8f in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58
    #2 0x7f85d460ee3f in __libc_start_main_impl ../csu/libc-start.c:392
    #3 0x55a237da5104 in _start (/mnt/c/Users/dufei/codes/os/2022/p8/a.out+0x1104)

0x602000000010 is located 0 bytes inside of 4-byte region [0x602000000010,0x602000000014)
freed by thread T0 here:
    #0 0x7f85d48c2537 in __interceptor_free ../../../../src/libsanitizer/asan/asan_malloc_linux.cpp:127
    #1 0x55a237da522f in main /home/df/codes/os/2022/p8/uaf.c:12
    #2 0x7f85d460ed8f in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58

previously allocated by thread T0 here:
    #0 0x7f85d48c2887 in __interceptor_malloc ../../../../src/libsanitizer/asan/asan_malloc_linux.cpp:145
    #1 0x55a237da51de in main /home/df/codes/os/2022/p8/uaf.c:10
    #2 0x7f85d460ed8f in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58

SUMMARY: AddressSanitizer: heap-use-after-free /home/df/codes/os/2022/p8/uaf.c:13 in main
Shadow bytes around the buggy address:
  0x0c047fff7fb0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7fc0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7fd0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7fe0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7ff0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
=>0x0c047fff8000: fa fa[fd]fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8010: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8020: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8030: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8040: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8050: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07
  Heap left redzone:       fa
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
  Shadow gap:              cc
==495511==ABORTING
df@moss:~/codes/os/2022/p8$

*/

#include <stdlib.h>
#include <string.h>

int main() {
  int *ptr = malloc(sizeof(int));
  *ptr = 1;
  free(ptr);
  *ptr = 1;
}
