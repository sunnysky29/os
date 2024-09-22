/*

随机数 
gcc   rdrand.c   -O1  -g  && ./a.out

*/

#include <stdio.h>
#include <stdint.h>

int main() {
  uint64_t val;
  asm volatile ("rdrand %0": "=r"(val));
  printf("rdrand returns %016lx\n", val);
}
