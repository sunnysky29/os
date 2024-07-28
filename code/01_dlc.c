/*
link： https://jyywiki.cn/OS/2022/slides/2.slides.html#/1/2

数字逻辑电路模拟器代码， 程序=状态机
运行结果：
X = 0; Y = 0;
X = 0; Y = 1;
X = 1; Y = 0;
X = 0; Y = 0;
X = 0; Y = 1;
X = 1; Y = 0;

可以通过进行宏展开：
gcc -E  00_dlc.c


*/


#include <stdio.h>
#include <unistd.h>

// 宏定义
#define REGS_FOREACH(_)  _(X) _(Y)  //这个宏用来迭代每个寄存器或变量名。它扩展为 _(X) _(Y)
#define RUN_LOGIC        X1 = !X && Y; \
                         Y1 = !X && !Y;
#define DEFINE(X)        static int X, X##1;
#define UPDATE(X)        X = X##1;
#define PRINT(X)         printf(#X " = %d; ", X);



int main() {
  REGS_FOREACH(DEFINE);  // static int X, X1; static int Y, Y1;;
  while (1) { // clock
    RUN_LOGIC;   //  X1 = !X && Y; Y1 = !X && !Y;;
    REGS_FOREACH(PRINT);    // printf("X" " = %d; ", X); printf("Y" " = %d; ", Y);;
    REGS_FOREACH(UPDATE);  //  X = X1; Y = Y1;;
    putchar('\n'); sleep(1);
  }
}
