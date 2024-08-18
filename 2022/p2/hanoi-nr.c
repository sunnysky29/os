
/*
typedef struct {
  int pc, n;        // pc: 程序计数器，用于跟踪当前的执行位置。n: 代表汉诺塔盘子的数量。
  char from, to, via; // from: 盘子从哪个柱子移动；to: 盘子移动到哪个柱子；via: 中转柱子。
} Frame; // 定义一个结构体，表示栈帧，用于存储函数调用的状态。

#define call(...) ({ *(++top) = (Frame) { .pc = 0, __VA_ARGS__ }; }) // 宏定义：将函数调用的状态（包括参数）压入栈中，并将栈顶指针 top 向上移动。
                                                                    我们可以确定 __VA_ARGS__ 是用于宏中传递变长参数的机制
                                                                    //  什么是函数调用 ：创建一个新的 frame,pc 初始化为0， 将所有的变参数丢进去
#define ret()     ({ top--; }) // 宏定义：将栈顶指针 top 向下移动，表示函数调用返回。top 用于管理函数执行的状态栈，通过递增和递减 top 来模拟函数调用和返回
#define goto(loc) ({ f->pc = (loc) - 1; }) // 宏定义：设置当前栈帧的程序计数器 pc 的值为 loc-1，相当于跳转到 loc 位置执行。

void hanoi(int n, char from, char to, char via) { // 汉诺塔问题的主函数，n 表示盘子的数量，from、to、via 表示三个柱子的标识符。
  Frame stk[64], *top = stk - 1; // 声明一个栈（数组）用于存储最多 64 个栈帧，并初始化栈顶指针 top 为栈底之前的位置。
  call(n, from, to, via); // 初始化函数调用，将参数 n、from、to 和 via 压入栈中，并设置程序计数器 pc 为 0。
  
  for (Frame *f; (f = top) >= stk; f->pc++) { // 遍历栈中的每个帧，从栈顶到栈底。设置 f 指向当前栈帧，并增加 pc 以跟踪程序执行位置。
    switch (f->pc) { // 根据程序计数器 pc 的值决定执行哪个代码块。
      case 0: // pc 为 0 时的情况
        if (f->n == 1) { // 如果只有一个盘子
          printf("%c -> %c\n", f->from, f->to); // 打印从 from 柱子到 to 柱子的移动操作。
          goto(4); // 跳转到 pc = 4 位置，处理返回操作。
        } 
        break;
      case 1: // pc 为 1 时的情况
        call(f->n - 1, f->from, f->via, f->to); // 递归调用，移动 n-1 个盘子从 from 到 via，通过 to 作为中转柱子。
        break;
      case 2: // pc 为 2 时的情况
        call(1, f->from, f->to, f->via); // 递归调用，移动 1 个盘子从 from 到 to，通过 via 作为中转柱子。
        break;
      case 3: // pc 为 3 时的情况
        call(f->n - 1, f->via, f->to, f->from); // 递归调用，移动 n-1 个盘子从 via 到 to，通过 from 作为中转柱子。
        break;
      case 4: // pc 为 4 时的情况
        ret(); // 返回上一个调用，即栈顶指针 top 向下移动。
        break;
      default: 
        assert(0); // 如果 pc 的值不在 0 到 4 之间，则断言失败，程序错误。
    }
  }
}
关键证据
栈帧结构 (Frame):

typedef struct 定义了 Frame 结构体，用于保存函数的状态，包括程序计数器 (pc)、盘子的数量 (n)、三个柱子的标识符 (from, to, via)。
宏定义:

call(...) 宏用于将当前的函数状态压入栈中，并将 pc 初始化为 0，表示函数开始执行。
ret() 宏用于将栈顶指针 top 向下移动，模拟函数的返回。
goto(loc) 宏用于修改当前帧的 pc 值，实现跳转。
汉诺塔函数 (hanoi):

使用 call() 宏来保存函数调用的状态并模拟递归。
for 循环遍历栈中每个 Frame，根据 pc 的值决定当前执行的操作，模拟递归调用的不同阶段。
程序计数器 (pc):

通过 pc 来控制程序的执行流，模拟了函数的不同执行阶段，并通过 goto 实现了从不同的执行阶段跳转回适当的位置。
这个实现利用了栈帧和程序计数器的技巧，避免了使用递归函数调用的堆栈空间，从而模拟了递归的行为。
*/

typedef struct {
  int pc, n;  
  char from, to, via;
} Frame; // 栈帧


#define call(...) ({ *(++top) = (Frame) { .pc = 0, __VA_ARGS__ }; })
#define ret()     ({ top--; })
#define goto(loc) ({ f->pc = (loc) - 1; })

void hanoi(int n, char from, char to, char via) {
  Frame stk[64], *top = stk - 1;
  call(n, from, to, via);
  for (Frame *f; (f = top) >= stk; f->pc++) {
    switch (f->pc) {
      case 0: if (f->n == 1) { printf("%c -> %c\n", f->from, f->to); goto(4); } break;
      case 1: call(f->n - 1, f->from, f->via, f->to);   break;
      case 2: call(       1, f->from, f->to,  f->via);  break;
      case 3: call(f->n - 1, f->via,  f->to,  f->from); break;
      case 4: ret();                                    break;
      default: assert(0);
    }
  }
}



