#include "thread.h"

#define N 100000000

long sum = 0;

void atomic_inc(long *ptr) {
    asm volatile("lock incq %0"  // Atomic + memory fence
                 : "+m"(*ptr)
                 :
                 : "memory");
}

void Tsum() {
    for (int i = 0; i < N; i++) {
        atomic_inc(&sum);
    }
}

int main() {
    create(Tsum);
    create(Tsum);
    join();
    printf("sum = %ld\n", sum);
}
