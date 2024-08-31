/*

互斥锁


$ gcc sum-scalability1.c  -O2 -lpthread


df@moss:~/codes/os/2022/p5$  time ./a.out 1

real    0m0.118s
user    0m0.105s
sys     0m0.000s
df@moss:~/codes/os/2022/p5$  time ./a.out 2

real    0m0.565s
user    0m0.658s
sys     0m0.432s
df@moss:~/codes/os/2022/p5$  time ./a.out 6

real    0m0.461s
user    0m0.606s
sys     0m1.717s
df@moss:~/codes/os/2022/p5$  time ./a.out 32

real    0m0.562s
user    0m0.599s
sys     0m9.694s


*/

#include "thread.h"
#include "thread-sync.h"

#define N 10000000
mutex_t lock = MUTEX_INIT();

long n, sum = 0;

void Tsum() {
  for (int i = 0; i < n; i++) {
    mutex_lock(&lock);
    sum++;
    mutex_unlock(&lock);
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
