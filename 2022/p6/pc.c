/*

生产者-消费者

gcc   pc.c  -lpthread   &&  ./a.out  3

括号检查：
moss:~/codes/os/2022/p6$ ./a.out  3 | python3  pc-check.py  3
100000 Ok.
100000 Ok.
100000 Ok.
100000 Ok.
100000 Ok.
*/

#include "thread.h"
#include "thread-sync.h"

int n, count = 0;
mutex_t lk = MUTEX_INIT();

void Tproduce() {
  while (1) {
retry:
    mutex_lock(&lk);
    if (count == n) {   // 满了
      mutex_unlock(&lk);
      goto retry;
    }
    count++;
    printf("(");
    mutex_unlock(&lk);
  }
}

void Tconsume() {
  while (1) {
retry:
    mutex_lock(&lk);
    if (count == 0) {
      mutex_unlock(&lk);
      goto retry;
    }
    count--;
    printf(")");
    mutex_unlock(&lk);
  }
}

int main(int argc, char *argv[]) {
  assert(argc == 2);
  n = atoi(argv[1]);
  setbuf(stdout, NULL);
  for (int i = 0; i < 8; i++) {
    create(Tproduce);
    create(Tconsume);
  }
}
