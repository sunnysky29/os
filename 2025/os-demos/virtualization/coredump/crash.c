#include <stdio.h>

void let_me_crash(int n) {
    unsigned long x = 0x114514;
    for (int i = 0; i < n; i++) {
        x *= 16;
    }

    *(int *)x = 114514;
}

int main() {
    // To debug a core dump:
    // 1. ulimit -c unlimited  (core dump size)
    // 2. gdb crash core-file
    let_me_crash(3);
}
