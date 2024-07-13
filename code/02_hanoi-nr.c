/*
汉诺塔 非递归版本

------------------------------------
C 程序的状态机模型 (语义，semantics)
状态 = stack frame 的列表 (每个 frame 有 PC) + 全局变量
初始状态 = main(argc, argv), 全局变量初始化
迁移 = 执行 top stack frame PC 的语句; PC++
函数调用 = push frame (frame.PC = 入口)
函数返回 = pop frame

应用：将任何递归程序就地转为非递归


*/

#include <assert.h>
#include <stdio.h>

typedef struct {
  int pc, n;
  char from, to, via;
} Frame;

#define call(...) ({ *(++top) = (Frame) { .pc = 0, __VA_ARGS__ }; })
#define ret()     ({ top--; })
#define goto(loc) ({ f->pc = (loc) - 1; })

void hanoi(int n, char from, char to, char via) {
  Frame stk[64], *top = stk - 1;
  call(n, from, to, via);
  for (Frame *f; (f = top) >= stk; f->pc++) {
    n = f->n; from = f->from; to = f->to; via = f->via;
    switch (f->pc) {
      case 0: if (n == 1) { printf("%c -> %c\n", from, to); goto(4); } break;
      case 1: call(n - 1, from, via, to);   break;
      case 2: call(    1, from, to,  via);  break;
      case 3: call(n - 1, via,  to,  from); break;
      case 4: ret();                        break;
      default: assert(0);
    }
  }
}