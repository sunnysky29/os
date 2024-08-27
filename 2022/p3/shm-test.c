
/*

证明线程确实共享内存

gcc shm-test.c  -lpthread     &&  ./a.out

Thread  id : 1
Thread  id : 3
Thread  id : 2
Thread  id : 4
Thread  id : 6
Thread  id : 5
Thread  id : 9
Thread  id : 10
Thread  id : 7
Thread  id : 8
Hello from thread #1
Hello from thread #2
Hello from thread #3
Hello from thread #4
Hello from thread #5
Hello from thread #6
Hello from thread #7
Hello from thread #8
Hello from thread #9
Hello from thread #A
*/

#include "thread.h"

int x = 0;

void Thello(int id) {
  printf("Thread  id : %d\n", id);
  usleep(id * 100000);
  printf("Hello from thread #%c\n", "123456789ABCDEF"[x++]);
}

int main() {
  for (int i = 0; i < 10; i++) {
    create(Thello);
  }
}
