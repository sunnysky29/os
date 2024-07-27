/*
多线程程序
编译的不同优化 对并发的结果也有影响
https://www.bilibili.com/video/BV1N741177F5?p=4&vd_source=abeb4ad4122e4eff23d97059cf088ab4

gcc 04_xx.c    -lpthread  && ./a.out    

$ gcc -O1 04_multi-thread_sum.c && ./a.out
sum = 100000000
0000000000001203 <do_sum>:
    1203:       f3 0f 1e fa             endbr64
    1207:       48 8b 15 0a 2e 00 00    mov    0x2e0a(%rip),%rdx        # 4018 <sum>
    120e:       48 8d 42 01             lea    0x1(%rdx),%rax
    1212:       48 81 c2 01 e1 f5 05    add    $0x5f5e101,%rdx
    1219:       48 89 c1                mov    %rax,%rcx
    121c:       48 83 c0 01             add    $0x1,%rax
    1220:       48 39 d0                cmp    %rdx,%rax
    1223:       75 f4                   jne    1219 <do_sum+0x16>
    1225:       48 89 0d ec 2d 00 00    mov    %rcx,0x2dec(%rip)        # 4018 <sum>
    122c:       c3                      ret

-----------------------------------------------------------

$ gcc -O2 04_multi-thread_sum.c && ./a.out
sum = 200000000

00000000000012a0 <do_sum>:
    12a0:       f3 0f 1e fa             endbr64
    12a4:       48 81 05 69 2d 00 00    addq   $0x5f5e100,0x2d69(%rip)        # 4018 <sum>
    12ab:       00 e1 f5 05
    12af:       c3   

-----------------------------------------------------------
$ gcc -O0 04_multi-thread_sum.c && ./a.out
sum = 100267466  (n < x < 2n)


*/

#include "threads_2021.h"

long sum=0;

void do_sum() {
  for (int i=0; i < 100000000; i++){
    sum ++; 
  }
}

void print(){
  printf("sum = %ld\n", sum);
}


int main() {
  create(do_sum);
  create(do_sum);
  join(print);
}


