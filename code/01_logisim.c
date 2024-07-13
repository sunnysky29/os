/*

7段数码管模拟
gcc  01_logisim.c --> a.out
A = 1; B = 1; C = 1; D = 1; E = 1; F = 1; G = 0;
A = 0; B = 1; C = 1; D = 0; E = 0; F = 0; G = 0;
A = 1; B = 1; C = 0; D = 1; E = 1; F = 0; G = 1;
A = 1; B = 1; C = 1; D = 1; E = 1; F = 1; G = 0;
........

./a.out  |  python3 01_seven-seg.py

     _________
    __       __
    __       __
    __       __
    __       __
    __________
   __       __
   __       __
   __       __
   __       __
    _________


*/

 

#define REGS_FOREACH(_)  _(X) _(Y)
#define OUTS_FOREACH(_)  _(A) _(B) _(C) _(D) _(E) _(F) _(G)
#define RUN_LOGIC        X1 = !X && Y; \
                         Y1 = !X && !Y; \
                         A  = (!X && !Y) || (X && !Y); \
                         B  = 1; \
                         C  = (!X && !Y) || (!X && Y); \
                         D  = (!X && !Y) || (X && !Y); \
                         E  = (!X && !Y) || (X && !Y); \
                         F  = (!X && !Y); \
                         G  = (X && !Y); 

#define DEFINE(X)   static int X, X##1;
#define UPDATE(X)   X = X##1;
#define PRINT(X)    printf(#X " = %d; ", X);

int main() {
  REGS_FOREACH(DEFINE);
  OUTS_FOREACH(DEFINE);
  while (1) { // clock
    RUN_LOGIC;
    OUTS_FOREACH(PRINT);
    REGS_FOREACH(UPDATE);
    putchar('\n');
    fflush(stdout);
    sleep(1);
  }
}
