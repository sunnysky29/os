/*
多线程
共享内存带来的更多问题
使用内联汇编，屏蔽编译器优化---> 结果依然是错的！！！

gcc 04_xx.c    -lpthread  && ./a.out    

$ gcc 04_multi-thread_sum1.c && ./a.out


*/

#include "threads_2021.h"
#define PREFIX "lock "

long sum=0;

void do_sum() {
  for (int i=0; i < 10000000; i++){
    // sum ++;                                                    // wrong!!!
    // asm volatile("addq $1, %0": "=m"(sum));                   // wrong!!!
    asm volatile(PREFIX "addq $1, %0": "=m"(sum));               // √

  }
}

void print() {
  printf("sum = %ld\n", sum);
}

int main() {
  for (int i = 0; i < 4; i++)  // 4个线程
    create(do_sum);
  join(print);
}

