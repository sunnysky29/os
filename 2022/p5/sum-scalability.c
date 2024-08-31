/*
自旋锁效率问题验证
线程越多，效率越低
自旋锁缺陷

$ gcc sum-scalability.c  -O2 -lpthread
df@moss:~/codes/os/2022/p5$ ./a.out
a.out: sum-scalability.c:18: main: Assertion `argc == 2' failed.
Aborted

df@moss:~/codes/os/2022/p5$ time ./a.out 1

real    0m0.097s
user    0m0.085s
sys     0m0.000s
df@moss:~/codes/os/2022/p5$ time ./a.out 2

real    0m0.358s
user    0m0.655s
sys     0m0.000s
df@moss:~/codes/os/2022/p5$ time ./a.out 6

real    0m1.263s
user    0m7.448s
sys     0m0.000s
df@moss:~/codes/os/2022/p5$ time ./a.out 32

real    0m9.476s
user    3m2.441s
sys     0m0.259s


*/

#include "thread.h"
#include "thread-sync.h"

#define N 10000000
spinlock_t lock = SPIN_INIT();

long n, sum = 0;

void Tsum() {
  for (int i = 0; i < n; i++) {
    spin_lock(&lock);
    sum++;
    spin_unlock(&lock);
  }
}

int main(int argc, char *argv[]) {
  assert(argc == 2);
  int nthread = atoi(argv[1]);
  n = N / nthread;
  for (int i = 0; i < nthread; i++) {
    create(Tsum);
  }
  join();
  assert(sum == n * nthread);
}
