/*
汉诺塔递归

 gcc -g hanoi-main.c  && ./a.out

*/

#include <stdio.h>
#include <assert.h>

// #include "hanoi-r.c"
#include "hanoi-nr.c"  // 非递归


int main() {

    hanoi(6, 'a', 'b' ,'c');
}