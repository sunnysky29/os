/*

peterson 算法 ， 会报错

/p4$ gcc peterson-simple.c  -lpthread
df@moss:~/codes/os/2022/p4$ ./a.out
a.out: peterson-simple.c:17: critical_section: Assertion `atomic_fetch_add(&nested, 1) == 0' failed.
Aborted
*/

#include "thread.h"

#define A 1
#define B 2

atomic_int nested;
atomic_long count;

void critical_section() {
  long cnt = atomic_fetch_add(&count, 1);
  assert(atomic_fetch_add(&nested, 1) == 0);
  atomic_fetch_add(&nested, -1);
}

int volatile x = 0, y = 0, turn = A;

void TA() {
    while (1) {
/* PC=1 */  x = 1;
/* PC=2 */  turn = B;
/* PC=3 */  while (y && turn == B) ; // 同时成立，才盲等待
            critical_section();
/* PC=4 */  x = 0;
    }
}

void TB() {
  while (1) {
/* PC=1 */  y = 1;
/* PC=2 */  turn = A;
/* PC=3 */  while (x && turn == A) ;
            critical_section();
/* PC=4 */  y = 0;
  }
}

int main() {
  create(TA);
  create(TB);
}
