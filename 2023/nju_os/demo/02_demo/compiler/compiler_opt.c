void spin_1() {
    int i;
    for (i = 0; i < 100; i++) {
        // Empty loop body
    }
}
void spin_2() {
    volatile int i;
    for (i = 0; i < 100; i++) {
        // Empty loop body
    }
}

int return_1() {
    int x;
    for (int i = 0; i < 100; i++) {
        // Compiler will assign [%0] an assemebly
        asm("movl $1, %0" : "=g"(x));  // x=1
    }
    return x;
}
int return_1_volatile() {
    int x;
    for (int i = 0; i < 100; i++) {
        // Compiler will assign [%0] an assemebly
        asm volatile("movl $1, %0" : "=g"(x));  // x=1
    }
    return x;
}
int foo(int *x) {
    *x = 1;
    *x = 1;
    return *x;
}
void external();
int foo_func_call(int *x) {
    *x = 1;
    external();
    *x = 1;
    return *x;
}
int foo_volatile1(int volatile *x) {
    *x = 1;
    *x = 1;
    return *x;
}

int foo_volatile2(int *volatile x) {
    *x = 1;
    *x = 1;
    return *x;
}
int foo_barrier(int *x) {
    *x = 1;
    asm("" : : : "memory");  // 空的汇编, 它可以把所有的内存都改掉
    *x = 1;
    return *x;
}
