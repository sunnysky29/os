/*
条件变量：实现生产者-消费者

1 p + 2 c ，会出问题

gcc   pc-cv.c  -lpthread   &&  ./a.out  3

gcc   pc-cv.c  -lpthread   &&  ./a.out  1  | head  -c 512


*/


#include "thread.h"
#include "thread-sync.h"

int n, count = 0;
mutex_t lk = MUTEX_INIT();
cond_t cv = COND_INIT();

void Tproduce() {
  while (1) {
    mutex_lock(&lk);
    if (count == n) {
      cond_wait(&cv, &lk);
    }
    printf("("); count++;
    cond_signal(&cv);
    mutex_unlock(&lk);
  }
}

void Tconsume() {
  while (1) {
    mutex_lock(&lk);
    if (count == 0) {
      pthread_cond_wait(&cv, &lk);
    }
    printf(")"); count--;
    cond_signal(&cv);
    mutex_unlock(&lk);
  }
}

int main(int argc, char *argv[]) {
  assert(argc == 2);
  n = atoi(argv[1]);
  setbuf(stdout, NULL);
  for (int i = 0; i < 1; i++) {  // p-c 数量
    create(Tproduce);
    create(Tconsume);
    create(Tconsume);

  }
}
