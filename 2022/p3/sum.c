/*

gcc  sum.c   -lpthread     &&  ./a.out
while true; do ./a.out; done  

*/
#include "thread.h"

#define N 100000000

long sum = 0;

void Tsum() {
  for (int i = 0; i < N; i++) {
    sum++;
    // asm volatile("add $1, %0": "+m"(sum));  // 汇编都不行 
    // asm volatile("lock add $1, %0": "+m"(sum));  // √

  }
}

int main() {
  create(Tsum);
  create(Tsum);
  join();
  printf("sum = %ld\n", sum);
}
