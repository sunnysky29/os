/*
条件变量：实现生产者-消费者

√

gcc   pc-cv1.c  -lpthread   &&  ./a.out  3

gcc   pc-cv1.c  -lpthread   &&  ./a.out  1  | head  -c 512

gcc   pc-cv1.c  -lpthread   &&  ./a.out  10


*/


#include "thread.h"
#include "thread-sync.h"

int n, count = 0;
mutex_t lk = MUTEX_INIT();
cond_t cv = COND_INIT();

void Tproduce() {
  while (1) {
    mutex_lock(&lk);
    while (!(count != n)) {
      cond_wait(&cv, &lk);
    }

    assert(count != n);
    printf("("); count++;
    // cond_signal(&cv);
    cond_broadcast(&cv);

    mutex_unlock(&lk);
  }
}

void Tconsume() {
  while (1) {
    mutex_lock(&lk);
    while (!(count != 0)) {
      pthread_cond_wait(&cv, &lk);
    }
    assert(count != 0);
    printf(")"); count--;
    cond_broadcast(&cv);
    mutex_unlock(&lk);
  }
}

int main(int argc, char *argv[]) {
  assert(argc == 2);
  n = atoi(argv[1]);
  setbuf(stdout, NULL);
  for (int i = 0; i < 8; i++) {  // p-c 数量
    create(Tproduce);
    create(Tconsume);

  }
}
