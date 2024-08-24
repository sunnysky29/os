/*
编译器，编译优化 理解 
gcc  -O2 -c a.c && objdump -d a.o
*/
extern int g;

void foo(int x){
    g++;
    // asm volatile ("nop" :: "r"(x));
    asm volatile ("nop" :: "r"(x): "memory");   // compiler  barrier, 不可优化

    g++;

}