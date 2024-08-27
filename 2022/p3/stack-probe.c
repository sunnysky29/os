/*

 gcc stack-probe.c   -lpthread     &&  ./a.out  | sort  -nk 6
通过递归调用，使得栈爆炸，推测栈帧大小的下界
-->  8192 KB

.........
tack size of T2 >= 6976 KB
Stack size of T4 >= 8128 KB
Stack size of T3 >= 8000 KB
Stack size of T1 >= 5504 KB
Stack size of T2 >= 7040 KB
Stack size of T3 >= 8064 KB
Stack size of T1 >= 5568 KB
Stack size of T1 >= 5632 KB
Stack size of T2 >= 7104 KB
Stack size of T1 >= 5696 KB
Stack size of T3 >= 8128 KB
Stack size of T1 >= 5760 KB
Stack size of T2 >= 7168 KB
Segmentation fault

---------
Stack size of T1 >= 7232 KB
Stack size of T1 >= 7296 KB
Stack size of T1 >= 7360 KB
Stack size of T1 >= 7424 KB
Stack size of T1 >= 7488 KB
Stack size of T1 >= 7552 KB
Stack size of T1 >= 7616 KB
Stack size of T1 >= 7680 KB
Stack size of T1 >= 7744 KB
Stack size of T1 >= 7808 KB
Stack size of T1 >= 7872 KB
Stack size of T1 >= 7936 KB
Stack size of T1 >= 8000 KB
Stack size of T1 >= 8064 KB
Stack size of T1 >= 8128 KB

*/

#include "thread.h"

__thread char *base, *cur; // thread-local variables
__thread int id;

// objdump to see how thread-local variables are implemented
__attribute__((noinline)) void set_cur(void *ptr) { cur = ptr; }
__attribute__((noinline)) char *get_cur()         { return cur; }

void stackoverflow(int n) {
  set_cur(&n);
  if (n % 1024 == 0) {
    int sz = base - get_cur();
    printf("Stack size of T%d >= %d KB\n", id, sz / 1024);
  }
  stackoverflow(n + 1);
}

void Tprobe(int tid) {
  id = tid;
  base = (void *)&tid;
  stackoverflow(0);
}

int main() {
  setbuf(stdout, NULL);
  for (int i = 0; i < 4; i++) {
    create(Tprobe);
  }
}
