/*
预估 栈的大小---> 8192KB
gcc ./04_stack-probe.c  -lpthread   && ./a.out  | sort  -nk 6 

*/


/*
[T3] Stack size @ n = 149504: 0x7fd9e9338df7 +7008 KiB
[T3] Stack size @ n = 150528: 0x7fd9e9338df7 +7056 KiB
[T3] Stack size @ n = 151552: 0x7fd9e9338df7 +7104 KiB
[T3] Stack size @ n = 152576: 0x7fd9e9338df7 +7152 KiB
[T3] Stack size @ n = 153600: 0x7fd9e9338df7 +7200 KiB
[T3] Stack size @ n = 154624: 0x7fd9e9338df7 +7248 KiB
[T3] Stack size @ n = 155648: 0x7fd9e9338df7 +7296 KiB
[T3] Stack size @ n = 156672: 0x7fd9e9338df7 +7344 KiB
[T3] Stack size @ n = 157696: 0x7fd9e9338df7 +7392 KiB
[T3] Stack size @ n = 158720: 0x7fd9e9338df7 +7440 KiB
[T3] Stack size @ n = 159744: 0x7fd9e9338df7 +7488 KiB
[T3] Stack size @ n = 160768: 0x7fd9e9338df7 +7536 KiB
[T3] Stack size @ n = 161792: 0x7fd9e9338df7 +7584 KiB
[T3] Stack size @ n = 162816: 0x7fd9e9338df7 +7632 KiB
[T3] Stack size @ n = 163840: 0x7fd9e9338df7 +7680 KiB
[T3] Stack size @ n = 164864: 0x7fd9e9338df7 +7728 KiB
[T3] Stack size @ n = 165888: 0x7fd9e9338df7 +7776 KiB
[T3] Stack size @ n = 166912: 0x7fd9e9338df7 +7824 KiB
[T3] Stack size @ n = 167936: 0x7fd9e9338df7 +7872 KiB
[T3] Stack size @ n = 168960: 0x7fd9e9338df7 +7920 KiB
[T3] Stack size @ n = 169984: 0x7fd9e9338df7 +7968 KiB
[T3] Stack size @ n = 171008: 0x7fd9e9338df7 +8016 KiB
[T3] Stack size @ n = 172032: 0x7fd9e9338df7 +8064 KiB
[T3] Stack size @ n = 173056: 0x7fd9e9338df7 +8112 KiB
[T3] Stack size @ n = 174080: 0x7fd9e9338df7 +8160 KiB
*/


#include "threads_2021.h"

__thread char *base, *now; // thread-local variables
__thread int id;

// objdump to see how thread local variables are implemented
void set_base(char *ptr) { base = ptr; }
void set_now(char *ptr)  { now = ptr; }
void *get_base()         { return &base; }
void *get_now()          { return &now; }

void stackoverflow(int n) {
  char x;
  if (n == 0) set_base(&x);
  set_now(&x);
  if (n % 1024 == 0) {
    printf("[T%d] Stack size @ n = %d: %p +%ld KiB\n",
      id, n, base, (base - now) / 1024);
  }
  stackoverflow(n + 1);
}

void probe(int tid) {
  id = tid;
  printf("[%d] thread local address %p\n", id, &base);
  stackoverflow(0);
}

int main() {
  setbuf(stdout, NULL);
  for (int i = 0; i < 4; i++) {
    create(probe);
  }
  join(NULL);
}



// ==========================================================
//  2024 版本
// ==========================================================

/*
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

// #include "thread.h"

// __thread char *base, *cur; // thread-local variables
// __thread int id;

// // objdump to see how thread-local variables are implemented
// __attribute__((noinline)) void set_cur(void *ptr) { cur = ptr; }
// __attribute__((noinline)) char *get_cur()         { return cur; }

// void stackoverflow(int n) {
//   set_cur(&n);
//   if (n % 1024 == 0) {
//     int sz = base - get_cur();
//     printf("Stack size of T%d >= %d KB\n", id, sz / 1024);
//   }
//   stackoverflow(n + 1);
// }

// void Tprobe(int tid) {
//   id = tid;
//   base = (void *)&tid;
//   stackoverflow(0);
// }

// int main() {
//   setbuf(stdout, NULL);
//   for (int i = 0; i < 4; i++) {
//     create(Tprobe);
//   }
// }
