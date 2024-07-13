/*
预估 栈的大小---> 8192KB
gcc ./04_stack-probe.c  -lpthread   && ./a.out  | sort  -nk 6 

Stack size of T1 >= 0 KB
Stack size of T2 >= 0 KB
Stack size of T3 >= 0 KB
Stack size of T4 >= 0 KB
Stack size of T1 >= 64 KB
Stack size of T2 >= 64 KB
Stack size of T3 >= 64 KB
Stack size of T4 >= 64 KB
Stack size of T1 >= 128 KB
............
Stack size of T2 >= 7616 KB
Stack size of T2 >= 7680 KB
Stack size of T2 >= 7744 KB
Stack size of T2 >= 7808 KB
Stack size of T2 >= 7872 KB
Stack size of T2 >= 7936 KB
Stack size of T2 >= 8000 KB
Stack size of T2 >= 8064 KB
Stack size of T2 >= 8128 KB

*/

#include "04_thread.h"

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
