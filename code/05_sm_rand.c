/*
状态机

生成不同的随机数

*/
#include <stdio.h>
#include <stdint.h>

int main() {
    uint64_t val;
    asm volatile ("rdrand %0": "=r"(val));
    printf("rdradn returns %016lx\n", val);

}

