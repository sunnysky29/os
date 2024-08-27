/*
hello world 程序！！
利用 thread.h 就可以写出利用多处理器的程序！
操作系统会自动把线程放置在不同的处理器上
在后台运行，可以看到 CPU 使用率超过了 100%

gcc multi_hello.c  -lpthread  &&  ./a.out      

*/

#include "thread.h"

void Ta() { while (1) { printf("a"); } }
void Tb() { while (1) { printf("b"); } }

int main() {
  create(Ta);
  create(Tb);

}

// ----------------------------------
// void Ta() { while (1) { printf("---"); } }
// void Tb() { while (1) { printf("oo"); } }

// int main() {
//   create(Ta);
//   create(Tb);

// }

