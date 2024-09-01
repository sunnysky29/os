#include "thread.h"

#define N 100000000

long sum = 0;

int x = 0;
void Tsum() {
    x = 1;
    asm volatile("" ::: "memory");
    x = 1;
}

int main() {
    create(Tsum);
    create(Tsum);
    join();
    printf("sum = %ld\n", sum);
}
