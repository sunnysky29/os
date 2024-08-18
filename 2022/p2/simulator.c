/*
数字模拟电路的 模拟器

gcc -E simulator.c ： 宏展开

# 33 "simulator.c"
int main() {
  static int X, X1; static int Y, Y1;;
  while (1) {
    X1 = !X && Y; Y1 = !X && !Y;;
    printf("X" " = %d; ", X); printf("Y" " = %d; ", Y);;
    X = X1; Y = Y1;;
    putchar('\n'); sleep(1);
  }
}
------------------------------------------------

执行结果：
X = 0; Y = 0;
X = 0; Y = 1;
X = 1; Y = 0;
X = 0; Y = 0;
X = 0; Y = 1;
X = 1; Y = 0;
X = 0; Y = 0;
X = 0; Y = 1;
X = 1; Y = 0;
X = 0; Y = 0;
X = 0; Y = 1;
X = 1; Y = 0;
X = 0; Y = 0;
X = 0; Y = 1;

*/

#include <stdio.h>
#include <unistd.h>


#define REGS_FOREACH(_)  _(X) _(Y)
#define RUN_LOGIC        X1 = !X && Y; \
                         Y1 = !X && !Y;
#define DEFINE(X)        static int X, X##1;
#define UPDATE(X)        X = X##1;
#define PRINT(X)         printf(#X " = %d; ", X);

int main() {
  REGS_FOREACH(DEFINE);
  while (1) { // clock
    RUN_LOGIC;
    REGS_FOREACH(PRINT);
    REGS_FOREACH(UPDATE);
    putchar('\n'); sleep(1);
  }
}