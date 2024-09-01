
/*

生产者-消费者 
打印 （）

gcc pc-mutex.c   -ggdb
./a.out   2

正确性 检查：
os/2023/p9$ ./a.out   3 |  python3   pc-check.py  3
100000 Ok.
200000 Ok.
300000 Ok.
400000 Ok.
500000 Ok.
600000 Ok.

*/

#include "thread.h"
#include "thread-sync.h"

int n, count = 0;
mutex_t lk = MUTEX_INIT();

#define CAN_PRODUCE (count < n)  // 打印 (
#define CAN_CONSUME (count > 0)   // 打印 ）

void Tproduce() {
  while (1) {
retry:
    mutex_lock(&lk);
    if (!CAN_PRODUCE) {
      mutex_unlock(&lk);
      goto retry;
    } else {
        count++;
        printf("(");  // Push an element into buffer
        mutex_unlock(&lk);
    }

  }
}

void Tconsume() {
  while (1) {
retry:
    mutex_lock(&lk);
    if (!CAN_CONSUME) {
      mutex_unlock(&lk);
      goto retry;
    } else {
        count--;
        printf(")");  // Pop an element from buffer
        mutex_unlock(&lk);
    }

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