/*

确认共享内存

gcc 04_multi-thread_shm.c  -lpthread  && ./a.out      

$ ./a.out
Hellpo from  thread #0
Hellpo from  thread #3
Hellpo from  thread #2
Hellpo from  thread #1
.....
Hellpo from  thread #14
Hellpo from  thread #24
Hellpo from  thread #9
Hellpo from  thread #16
Hellpo from  thread #29

*/

#include "threads_2021.h"

void f() {
  static int x = 0;
  printf("Hellpo from  thread #%d\n", x++);
  while (1);  // make sure we're  not just sequentially calling f()
}


int main() {
  for (int i=0; i<8; i++){
    create(f);
  }
  join(NULL);
}

// ==========================================================
//  2024 版本
// ==========================================================

// #include "thread.h"

// int x = 0;  // 全局变量

// void Thello(int id) {
//   printf("Thread id : %d\n", id);
//   usleep(id * 100000);
//   printf("Hello from thread #%c\n", "123456789ABCDEF"[x++]);
// }

// int main() {
//   for (int i = 0; i < 10; i++) {
//     create(Thello);
//   }
// }

