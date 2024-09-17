/*

启动 4 个 处理器
make  ARCH=native run  smp=4


*/

#include <am.h>
#include <klib.h>

void foo() {
    printf("hello from cpu #%d/%d\n", cpu_current(), cpu_count());
    while (1);
}


int main() {

    printf("Memory: [%p %p)\n", heap.start, heap.end);
    mpe_init(foo);

}


