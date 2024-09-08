
/*

数据竞争

df@moss:~/codes/os/2022/p8$ gcc -g  sum.c   -fsanitize=thread
df@moss:~/codes/os/2022/p8$ ./a.out
==================
WARNING: ThreadSanitizer: data race (pid=504773)
  Read of size 8 at 0x562902878640 by thread T2:
    #0 Tsum /home/df/codes/os/2022/p8/sum.c:14 (a.out+0x15bf)
    #1 wrapper /home/df/codes/os/2022/p8/thread.h:21 (a.out+0x12fb)

  Previous write of size 8 at 0x562902878640 by thread T1:
    #0 Tsum /home/df/codes/os/2022/p8/sum.c:14 (a.out+0x15d9)
    #1 wrapper /home/df/codes/os/2022/p8/thread.h:21 (a.out+0x12fb)

  Location is global 'sum' of size 8 at 0x562902878640 (a.out+0x000000004640)

  Thread T2 (tid=504776, running) created by main thread at:
    #0 pthread_create ../../../../src/libsanitizer/tsan/tsan_interceptors_posix.cpp:969 (libtsan.so.0+0x605b8)
    #1 create /home/df/codes/os/2022/p8/thread.h:32 (a.out+0x1470)
    #2 main /home/df/codes/os/2022/p8/sum.c:20 (a.out+0x1630)

  Thread T1 (tid=504775, running) created by main thread at:
    #0 pthread_create ../../../../src/libsanitizer/tsan/tsan_interceptors_posix.cpp:969 (libtsan.so.0+0x605b8)
    #1 create /home/df/codes/os/2022/p8/thread.h:32 (a.out+0x1470)
    #2 main /home/df/codes/os/2022/p8/sum.c:19 (a.out+0x1621)

SUMMARY: ThreadSanitizer: data race /home/df/codes/os/2022/p8/sum.c:14 in Tsum
==================

*/
#include "thread.h"

#define N 100000000

long sum = 0;

void Tsum() {
  for (int i = 0; i < N; i++) {
    sum++;
  }
}

int main() {
  create(Tsum);
  create(Tsum);
  join();
  printf("sum = %ld\n", sum);
}
