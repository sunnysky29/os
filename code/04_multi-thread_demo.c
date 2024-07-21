/*
多线程程序
利用 thread.h 就可以写出利用多处理器的程序！
操作系统会自动把线程放置在不同的处理器上
在后台运行，可以看到 CPU 使用率超过了 100%

gcc 04_multi-thread_demo.c    -lpthread  && ./a.out      

bbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbabaabbababbbabaaabababababababa
abababababababababababababababababababababababababababaababababababab
abababababababababababababababababababababababababababababababaaabababaaaabababbbabaaaababaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

*/

#include "thread.h"

void Ta() { while (1) { printf("a"); } }
void Tb() { while (1) { printf("b"); } }

int main() {
  create(Ta);
  create(Tb);
}




// // ------------------------------------------
// // strace ./a.out
// // rt_sigprocmask(SIG_BLOCK, ~[], [], 8)   = 0
// // clone3({flags=CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID, child_tid=0x7fd04c049910, parent_tid=0x7fd04c049910, exit_signal=0, stack=0x7fd04b849000, stack_size=0x7fff00, tls=0x7fd04c049640} => {parent_tid=[1063061]}, 88) = 1063061
// // rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
// // futex(0x7fd04c049910, FUTEX_WAIT_BITSET|FUTEX_CLOCK_REALTIME, 1063061, NULL, FUTEX_BITSET_MATCH_ANYVim: Reading from stdin...


// void Ta() { while (1) { ; } }
// void Tb() { while (1) { ; } }

// int main() {
//   create(Ta);

// }
