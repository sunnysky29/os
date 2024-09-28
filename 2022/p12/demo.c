#include <stdio.h>

int main(){
    unsigned *p;
    // p = (void *)main;
    p = (void *)(0x12345678l);

    printf("%x\n", *p);
}
