/*
原子操作，lock指令前缀

gcc sum-atomic.c  -O2  -lpthread  &&   ./a.out
sum = 200000000

*/

#include "thread.h"

#define N 100000000

long sum = 0;

void Tsum() {
  for (int i = 0; i < N; i++) {
    asm volatile("lock addq $1, %0": "+m"(sum));  //内联汇编， √ lock
  }
}

int main() {
  create(Tsum);
  create(Tsum);
  join();
  printf("sum = %ld\n", sum);
}
