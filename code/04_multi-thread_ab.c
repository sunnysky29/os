/*
多线程程序
利用 thread.h 就可以写出利用多处理器的程序！
操作系统会自动把线程放置在不同的处理器上
在后台运行，可以看到 CPU 使用率超过了 100%

gcc 04_multi-thread_demo_ab.c    -lpthread  && ./a.out      
-lpthread  不加也能顺利编译运行，有点奇怪？？？????

bbbbbbbbbbbbbbbbbbbbbbbbabaa

*/

#include "threads_2021.h"

void a() { while (1) { printf("a"); } }
void b() { while (1) { printf("b"); } }

int main() {
  setbuf(stdout, NULL);
  create(a);
  create(b);
}


