/*
验证超标量执行，证明一个时钟周期可以执行多条指令

时钟速度为 3.2 GHz 的 CPU 每秒执行 32 亿个周期

gcc -O2  ilp-demo.c 

022/p10$ ./a.out
23.39G instructions/s

*/

#include <stdio.h>
#include <time.h>

#define LOOP 1000000000ul

__attribute__((noinline)) void loop() {
  for (long i = 0; i < LOOP; i++) {
    asm volatile(
      "mov $1, %%rax;"
      "mov $1, %%rdi;"
      "mov $1, %%rsi;"
      "mov $1, %%rdx;"
      "mov $1, %%rcx;"
      "mov $1, %%r10;"
      "mov $1, %%r8;"
      "mov $1, %%r9;"
    :::"rax", "rdi", "rsi", "rdx", "rcx", "r10", "r8", "r9");
  }
}

int main() {
  clock_t st = clock();
  loop();
  clock_t ed = clock();
  double inst = LOOP * (8 + 2) / 1000000000;
  double ips = inst / ((ed - st) * 1.0 / CLOCKS_PER_SEC);
  printf("%.2lfG instructions/s\n", ips);
}
