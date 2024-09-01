#import "../template.typ": *
#pagebreak()
= 应用视角的操作系统

== 汇编代码和最小可执行文件

=== 构造最小的 Hello, World “应用程序”

```c
int main() {
  printf("Hello, World\n");
}
```

gcc 编译出来的文件一点也不小

- `objdump` 工具可以查看对应的汇编代码
- `--verbose` 可以查看所有编译选项 (真不少)
  - `printf` 变成了 `puts@plt`
- `-Wl,--verbose` 可以查看所有链接选项 (真不少)
  - 原来链接了那么多东西
  - 还解释了 `end` 符号的由来
- `-static` 会链接 `libc` (大量的代码)

`.c`-(cc)->`.i`-(cc)->`.s`-(as)->`.o`-(ld)->`a.out`

=== 强行构造最小的 Hello, World？

我们可以手动链接编译的文件, 直接指定二进制文件的入口

- 直接用 `ld` 链接失败
  - `ld` 不知道怎么链接 `printf`
- 不调用 `printf` 可以链接
  - 但得到奇怪的警告 (可以定义成 `_start` 避免警告)
  - 而且 Segmentation Fault 了
- `while (1);` 可以链接并正确运行

问题: 为什么会 Segmentation Fault？

- 当然是观察程序的执行了
  - 初学者必须克服的恐惧: STFW/RTFM ([ M 非常有用
    ](https://sourceware.org/gdb/documentation/))
  - `starti` 可以帮助我们从第一条指令开始执行程序

=== 解决异常退出

CPU 是无情的执行指令的机器, 有办法让程序 “停下来” 吗？

纯 “计算” 的状态机: 不行

- 没有 “停机” 的指令
- 解决办法: 用一条特殊的指令请操作系统帮忙

```
movq $SYS_exit,  %rax   = exit(
movq $1,         %rdi   =   status=1
syscall                 = );
```

- 把 “系统调用” 的参数放到寄存器中
- 执行 syscall, 操作系统接管程序
  - 程序把控制权完全交给操作系统
  - 操作系统可以改变程序状态甚至终止程序

=== 对一些细节的补充解释

为什么用 gcc 编译？

gcc 会进行预编译 (可以使用 *ASSEMBLER* 宏区分汇编/C 代码) ANSI Escape Code
的更多应用

#link("https://git.busybox.net/busybox/tree/editors/vi.c")[ vi.c ] from busybox
`dialog --msgbox 'Hello, OS World!' 8 32`
`ssh -o 'HostKeyAlgorithms +ssh-rsa' sshtron.zachlatta.com`
更重要的问题: 怎样才能变强？

问正确的问题, 用正确的方式找答案 syscall (2), syscalls (2) -- RTFM & RTFSC Q & A
论坛；Q & A 机器人

=== 汇编代码的状态机模型

Everything is a state machine: 计算机 = 数字电路 = 状态机

- 状态 = 内存 M + 寄存器 R
- 初始状态 = ABI 规定 (例如有一个合法的 %rsp)
- 状态迁移 = 执行一条指令
  - 我们花了一整个《计算机系统基础》解释这件事
  - gdb 同样可以观察状态和执行

操作系统上的程序

- 所有的指令都只能计算
  - deterministic: mov, add, sub, call, ...
  - non-deterministic: rdrand, ...
  - syscall 把 (M,R) 完全交给操作系统

`.c`-(cc)->`.i`-(cc)->`.s`-(as)->`.o`-(ld)->`a.out` low level 理解: (M, R)-(取
M[R[pc]], 执行)->次态(M1,R1)-(系统调用,syscall)->

== 理解高级语言程序

你能写一个 C 语言代码的 “解释器” 吗？

#tip("Tip")[
gdb 类似于一个 C 语言的解释器
]

如果能, 你就完全理解了高级语言 和 “电路模拟器”, “RISC-V 模拟器” 类似 实现 gdb
里的 “单步执行”

```c
while (1) {
  stmt = fetch_statement();
  execute(stmt);
}
```

“解释器” 的例子: 用基础结构模拟函数调用和递归

- 试试汉诺塔吧

递归实现

```c
void hanoi(int n, char from, char to, char via) {
  if(n==1){
    printf("%c -> %c\n",from,to);
  }else{
    hanoi(n-1,from,via,to);
    hanoi(1,from,to,via);
    hanoi(n-1,via,to,from);
  }
}
```

这个问题已经超出了 90% 程序员的能力范围 ChatGPT 竟然改写对了！而且给出了非常优雅
(但也有缺陷) 的实现

```c
void hanoi_non_recursive(int n, char from, char to, char via) {
  struct Element { int n; char from; char to; char via; };
  std::stack<Element> elements;
  elements.push({n, from, to, via});
  while (!elements.empty()) {
    auto e = elements.top();
    elements.pop();
    if (e.n == 1) {
      printf("%c -> %c\n", e.from, e.to);
    } else {
      elements.push({e.n - 1, e.via, e.to, e.from});
      elements.push({1, e.from, e.to, e.via});
      elements.push({e.n - 1, e.from, e.via, e.to});
    }
  }
}
```

当然, ChatGPT 也没能完全理解

=== 简单 C 程序的状态机模型 (语义)

对 C 程序做出简化

简化: 改写成每条语句至多一次运算/函数调用的形式 真的有这种工具 ([ C Intermediate
Language ](https://cil-project.github.io/cil/)) 和[ 解释器
](https://gitlab.com/zsaleeba/picoc)

状态机定义

- 状态 = 堆 + 栈
- 初始状态 = main 的第一条语句
- 状态迁移 = 执行一条语句中的一小步 
#tip("Tip")[
这还只是 “粗浅” 的理解
]

Talk is cheap. Show me the code. (Linus Torvalds)
任何真正的理解都应该落到可以执行的代码

状态

- Stack frame 的列表 + 全局变量

初始状态

- 仅有一个 frame: main(argc, argv) ；全局变量为初始值

状态迁移

- 执行 frames.top.PC 处的简单语句
- 函数调用 = push frame (frame.PC = 入口)
- 函数返回 = pop frame

然后看看我们的非递归汉诺塔 (更本质), 更正确的实现:

```c
#include <assert.h>
#include <stdio.h>
typedef struct Frame {
    int pc, n;
    char from, to, via;
} Frame;

#define call(...) ({ *(++top) = (Frame){.pc = 0, __VA_ARGS__}; })
#define ret() ({ --top; })
#define goto(loc) ({ f->pc = (loc)-1; })

void hanoi2(int n, char from, char to, char via) {
    Frame stk[64], *top = stk - 1;
    call(n, from, to, via);
    for (Frame *f; (f = top) >= stk; (f->pc)++) {
        n = f->n; from = f->from; to = f->to; via = f->via;
        switch (f->pc) {
            case 0: if (n == 1) { printf("%c -> %c\n", from, to); goto(4); } break;
            case 1: call(n - 1, from, via, to); break;
            case 2: call(1, from, to, via); break;
            case 3: call(n - 1, via, to, from); break;
            case 4: ret();break;
            default: assert(0);
        }
    }
}
```

从这里看函数状态迁移:

- 调用:在栈帧的顶部加个栈帧, pc=0;
- 返回:把顶部的栈帧抹除;
- 执行:取顶部栈帧的 pc 执行;

#tip("Tip")[
赋值语句, `if` 语句, `goto` 语句这三个就可以改写所有的 C 程序. 这就是编译器!
]

== 理解编译器

我们有两种状态机

- 高级语言代码 .c
  - 状态: 栈, 全局变量；状态迁移: 语句执行
- 汇编指令序列 .s
  - 状态: (M,R)；状态迁移: 指令执行

编译器是二者之间的桥梁: $.s="compile"\(.c\)$

那到底什么是编译器？

不同的优化级别产生不同的指令序列 凭什么说一个 $.s="compile"(.c)$ 是 “对的” 还是
“错的”？

=== $.s="compile"(.c)$: 编译正确性

.c 执行中所有*外部观测者可见的行为*, 必须在 .s 中保持一致

- External function calls (链接时确定)
  - 如何调用由 Application Binary Interface (ABI) 规定
  - 可能包含系统调用, 因此不可更改, 不可交换
- 编译器提供的 “不可优化” 标注
  - `volatile` [load | store | inline assembly]
- Termination
  - .c 终止当且仅当 .s 终止

*在此前提下, 任何翻译都是合法的* (例如我们期望更快或更短的代码)

- 编译优化的实际实现: (context-sensitive) rewriting rules
- 代码示例: 观测编译器优化行为和 compiler barrier

== 操作系统上的软件 (应用程序)

=== 操作系统中的任何程序

任何程序 = minimal.S = 调用 syscall 的状态机

可执行文件是操作系统中的对象

与大家日常使用的文件 (a.c, README.txt) 没有本质区别 操作系统提供 API 打开, 读取,
改写 (都需要相应的权限) 查看可执行文件

vim, cat, xxd 都可以直接 “查看” 可执行文件 vim 中二进制的部分无法 “阅读”,
但可以看到字符串常量 使用 `xxd` 可以看到文件以 "\x7f" "ELF" 开头 Vscode 有
binary editor 插件

=== 系统中常见的应用程序

Core Utilities (coreutils)

- Standard programs for text and file manipulation
- 系统中安装的是 #link("https://www.gnu.org/software/coreutils/")[ GNU Coreutils ]
  - 有较小的替代品 #link("https://www.busybox.net/")[ busybox ]

系统/工具程序

bash, #link("https://www.gnu.org/software/binutils/")[ binutils ], apt, ip, ssh, vim,
tmux, jdk, python, ... 这些工具的原理不复杂 (例如 apt 是 dpkg 的套壳), 但琐碎 [
Ubuntu Packages ](https://packages.ubuntu.com/) (和 apt-file 工具)
支持文件名检索 其他各种应用程序

Vscode, 浏览器, 音乐播放器……

=== 打开程序的执行: Trace (追踪)

如果知道程序和操作系统的交互, 就可以勾勒出程序运行所有的轮廓.

In general, trace refers to the process of following anything from the beginning
to the end. For example, the traceroute command follows each of the network hops
as your computer connects to another computer.

这门课中很重要的工具: strace

- System call trace(打印出所有的系统调用)
- 允许我们观测状态机的执行过程
  - Demo: 试一试最小的 Hello World
  - 在这门课中, 你能理解 strace 的输出并在你自己的操作系统里实现相当一部分系统调用
    (mmap, execve, ...)

strace 是一个非常重要的命令行工具, 帮助我们 “观测”
应用程序和操作系统的边界.实际上, 任何程序的执行就是状态机在计算机上的运行, 因此
“用合适的方式观测状态机执行” 就是我们理解程序的根本方法.调试器, trace, profiler
提供了不同侧面的理解手段, 这三个工具将会在课程中反复出现.

如果你感到 strace 的结果不那么友善,
用适当的工具处理它就非常重要了.课堂上我们展示了用命令行工具进行处理的
“传统方法”:

```sh
❯ strace ls |& grep -e read -e write
```

可以实现系统调用的过滤等.

=== 操作系统中 “任何程序” 的一生

任何程序 = minimal.S = 调用 syscall 的状态机

- 被操作系统加载
  - 通过另一个进程执行 execve 设置为初始状态
- 状态机执行
  - 进程管理: fork, execve, exit, ...
  - 文件/设备管理: open, close, read, write, ...
  - 存储管理: mmap, brk, ...
- 调用 `_exit (exit_group)` 退出

(初学者对这一点会感到有一点惊讶)

- 说好的浏览器, 游戏, 杀毒软件, 病毒呢？都是这些 API 吗？
- 我们有 strace, 就可以自己做实验了！

=== 动手实验: 观察程序的执行

工具程序代表: 编译器 (gcc)

- 主要的系统调用: `execve`, `read`, `write`
- `strace -f gcc a.c` (gcc 会启动其他进程)
  - 可以管道给编辑器 `vim -`
  - `:set nowrap`
  - 编辑器里还可以 `%!grep` (细节/技巧):`%!grep execve`,`%!grep -e execve -e open`, `%!grep -v ENOENT`
  - `:%s/, /\r/g`, 可以清晰地看到参数

图形界面程序代表: 编辑器 (`xedit`)

- 主要的系统调用: `poll`, `recvmsg`, `writev`
- `strace xedit`
  - 图形界面程序和 X-Window 服务器按照 X11 协议通信
  - 虚拟机中的 xedit 将 X11 命令通过 ssh (X11 forwarding) 转发到 Host >
    系统里面只有一个程序有访问屏幕的权限,
    其他的程序都会跟这个程序通信来进行屏幕的操作

=== 各式各样的应用程序

都在操作系统 API (syscall) 和操作系统中的对象上构建

- 窗口管理器
  - 管理设备和屏幕 (read/write/mmap)
  - 进程间通信 (send, recv)
- 任务管理器
  - 访问操作系统提供的进程对象 (readdir/read)
  - 参考 gdb 里的 `info proc *`
- 杀毒软件
  - 文件静态扫描 (read)
  - 主动防御 (ptrace)
  - 其他更复杂的安全机制……

== 编程实践

=== minimal

==== demo01

hello.c

```c
#include <stdio.h>

int main() {
    printf("hello world!");
}
```

#tip("Tip")[
C 在没有显式`return`的时候会默认`return 0`
]

```sh
❯ gcc hello.c
❯ file a.out
a.out: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=c2dcf81554e16f44aa79827b6fcb46af0
f7feb1c, for GNU/Linux 3.2.0, not stripped
```

#tip("Tip")[
`file`可以帮忙猜一个文件是什么.
]

`objdump -d a.out`查看反汇编, 发现其实不多, 还发现把`printf`优化成了`puts@plt`,
省了一个换行.`puts`函数真正的实现是在 libc 语言的标准库里.

`gcc -static hello.c`发现 好长!

`gcc -static --verbose hello.c`可以查看到很多有用的信息
`gcc -static -Wl,--verbose hello.c`可以打印出 gcc 的链接选项.

有关`Wl`:
`-Wl` 是 GCC 编译器的一个选项, 用于向链接器 (ld) 传递参数.

在 `-Wl` 后面, 可以跟随一个`,`和一系列要传递给链接器的参数.每个参数必须以逗号分隔.这些参数会被直接传递给链接器,
影响链接器的行为和生成的可执行文件.

常见的使用情况包括:

- 指定连接器使用的库路径: 可以使用 `-Wl,-L` 参数指定链接器要搜索的库文件路径.例如, `-Wl,-L/usr/local/lib` 将告诉链接器在 `/usr/local/lib` 路径下搜索库文件.
- 指定连接器链接的库: 使用 `-Wl,-l` 参数来指定链接器要链接的库.例如, `-Wl,-lmylib` 将告诉链接器链接名为 `mylib.so` 或 `mylib.a` 的库文件.
- 指定连接器的其他选项: 除了库路径和库名称之外, 还可以使用 `-Wl` 将其他选项传递给链接器.例如, `-Wl,--no-as-needed` 将禁用链接时的需要性检查.

==== demo02

直接强行走一遍流程: hello.c

```c
int main() { printf("hello world!"); }
```

```sh
❯ gcc -c hello.c
....(一些warning)
❯ objdump -d hello.o
hello.o:     file format elf64-x86-64
Disassembly of section .text:
0000000000000000 <main>:
   0:   f3 0f 1e fa             endbr64
   4:   55                      push   %rbp
   5:   48 89 e5                mov    %rsp,%rbp
   8:   48 8d 05 00 00 00 00    lea    0x0(%rip),%rax        = f <main+0xf>
   f:   48 89 c7                mov    %rax,%rdi
  12:   b8 00 00 00 00          mov    $0x0,%eax
  17:   e8 00 00 00 00          call   1c <main+0x1c>
  1c:   b8 00 00 00 00          mov    $0x0,%eax
  21:   5d                      pop    %rbp
  22:   c3                      ret
❯ ld hello.o
ld: warning: cannot find entry symbol _start; defaulting to 0000000000401000
ld: hello.o: in function `main':
hello.c:(.text+0x18): undefined reference to `printf'
```

```c
int main() {}
```

```sh
❯ gcc -c hello.c
❯ objdump -d hello.o

hello.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:   f3 0f 1e fa             endbr64
   4:   55                      push   %rbp
   5:   48 89 e5                mov    %rsp,%rbp
   8:   b8 00 00 00 00          mov    $0x0,%eax
   d:   5d                      pop    %rbp
   e:   c3                      ret
❯ ld hello.o
ld: warning: cannot find entry symbol _start; defaulting to 0000000000401000
❯ ld hello.o -e main
❯ objdump -d a.out
a.out:     file format elf64-x86-64
Disassembly of section .text:
0000000000401000 <main>:
  401000:       f3 0f 1e fa             endbr64
  401004:       55                      push   %rbp
  401005:       48 89 e5                mov    %rsp,%rbp
  401008:       b8 00 00 00 00          mov    $0x0,%eax
  40100d:       5d                      pop    %rbp
  40100e:       c3                      ret
❯ ./a.out
[1]    2048 segmentation fault  ./a.out
```

得到"最小"的 C 程序, 但是运行会有 segmentation fault.

有关`ld`的`-e`(entry symbol)选项: 链接可执行文件时, 使用 `-e` 可以告诉链接器将程序的控制权设置为指定的符号所在的地址,
从而作为程序的起始点. 在命令 `ld hello.o -e main` 中, `-e main` 的作用是将程序的入口点设置为 `main` 函数所在的地址,
程序将从 `main` 函数开始执行.

```c
int main(){while(1);}
```

重复上面操作发现死循环可以正常执行

现在用 gdb 来调试, 使用 `starti`

```sh
(gdb) starti
Program stopped.
0x0000000000401000 in main ()

...(layout asm, info registers)
> 0x401000 <main>         endbr64
  0x401004 <main+4>       push   %rbp
  0x401005 <main+5>       mov    %rsp,%rbp
  0x401008 <main+8>       mov    $0x0,%eax
  0x40100d <main+13>      pop    %rbp
  0x40100e <main+14>      ret

(gdb) si
0x0000000000401004 in main ()
0x0000000000401005 in main ()
0x0000000000401008 in main ()
0x000000000040100d in main ()
0x000000000040100e in main ()
(gdb) p $rsp
$1 = (void *) 0x7fffffffe4c0
(gdb) x $rsp
0x7fffffffe4c0: 0x00000001
(gdb) si
0x0000000000000001 in ?? ()
```

破案了, `rsp` 存储了当前线程的堆栈顶部的地址.这里弹出了一个非法的地址, 寄!

#tip("Tip")[
- RBP(Base Pointer): 栈底指针.
- RSP(Stack Pointer): 栈顶指针.
- EAX: 通用寄存器.一个 32 位的寄存器, 经常用于存储函数的返回值或临时变量.
]

==== demo03

minimal.S

```c
#include <sys/syscall.h>

.globl _start
_start:
    movq $SYS_write,    %rax // write(
    movq $1,            %rdi //    fd=1,
    movq $st,           %rsi //    buf=st,
    movq $(ed-st),      %rdx //    count=ed-st
    syscall                  // );

    movq $SYS_exit,     %rax // exit(
    movq $1,            %rdi //    status=1,
    syscall                  // );
st:
    .ascii "\033[01;31mHello, OS World\033[0m\n"
ed:
```

```sh
❯ gcc -c minimal.S
❯ ld minimal.o
❯ ./a.out
Hello, OS World
```

把 `minimal` 对应的 `a.out` 使用 vim 打开 然后`:%!xxd`

这也是一个命令行哲学, 举例:

```
1
2
1
1
22
2
3
1
1
```

想要把 1 留下, 其余的删掉.`:%!grep 1`

=== hanoi

给了 chatgpt 一个更难的题, 翻车了 (思路基本正确, 但不再优雅)

```c
int f(int n) {
  if (n <= 1) return 1;
  return f(n - 1) + g(n - 2);
}

int g(int n) {
  if (n <= 1) return 1;
  return f(n + 1) + g(n - 1);
}
```

(你们会写这个的非递归吗, 提示, pc 可以带 f 和 g 的, 一个`f.0`, 一个`g.1`)
先看看汇编代码

```
f_g.o:     file format elf64-x86-64
Disassembly of section .text:

0000000000000000 <f>:
   0:  f3 0f 1e fa            endbr64
   4:  55                     push   %rbp
   5:  48 89 e5               mov    %rsp,%rbp
   8:  53                     push   %rbx
   9:  48 83 ec 18            sub    $0x18,%rsp
   d:  89 7d ec               mov    %edi,-0x14(%rbp)
  10:  83 7d ec 01            cmpl   $0x1,-0x14(%rbp)
  14:  7f 07                  jg     1d <f+0x1d>
  16:  b8 01 00 00 00         mov    $0x1,%eax
  1b:  eb 1e                  jmp    3b <f+0x3b>
  1d:  8b 45 ec               mov    -0x14(%rbp),%eax
  20:  83 e8 01               sub    $0x1,%eax
  23:  89 c7                  mov    %eax,%edi
  25:  e8 00 00 00 00         call   2a <f+0x2a>
  2a:  89 c3                  mov    %eax,%ebx
  2c:  8b 45 ec               mov    -0x14(%rbp),%eax
  2f:  83 e8 02               sub    $0x2,%eax
  32:  89 c7                  mov    %eax,%edi
  34:  e8 00 00 00 00         call   39 <f+0x39>
  39:  01 d8                  add    %ebx,%eax
  3b:  48 8b 5d f8            mov    -0x8(%rbp),%rbx
  3f:  c9                     leave
  40:  c3                     ret

0000000000000041 <g>:
  41:  f3 0f 1e fa            endbr64
  45:  55                     push   %rbp
  46:  48 89 e5               mov    %rsp,%rbp
  49:  53                     push   %rbx
  4a:  48 83 ec 18            sub    $0x18,%rsp
  4e:  89 7d ec               mov    %edi,-0x14(%rbp)
  51:  83 7d ec 01            cmpl   $0x1,-0x14(%rbp)
  55:  7f 07                  jg     5e <g+0x1d>
  57:  b8 01 00 00 00         mov    $0x1,%eax
  5c:  eb 1e                  jmp    7c <g+0x3b>
  5e:  8b 45 ec               mov    -0x14(%rbp),%eax
  61:  83 c0 01               add    $0x1,%eax
  64:  89 c7                  mov    %eax,%edi
  66:  e8 00 00 00 00         call   6b <g+0x2a>
  6b:  89 c3                  mov    %eax,%ebx
  6d:  8b 45 ec               mov    -0x14(%rbp),%eax
  70:  83 e8 01               sub    $0x1,%eax
  73:  89 c7                  mov    %eax,%edi
  75:  e8 00 00 00 00         call   7a <g+0x39>
  7a:  01 d8                  add    %ebx,%eax
  7c:  48 8b 5d f8            mov    -0x8(%rbp),%rbx
  80:  c9                     leave
  81:  c3                     ret
```

```c
typedef enum { FUNC_F, FUNC_G } FuncType;

typedef struct Frame {
    int pc, n, retVal;
    FuncType funcType;
} Frame;

#define call(func, arg) \
    ({ *(++top) = (Frame){.pc = 0, .n = (arg), .funcType = (func)}; })
#define ret(value)             \
    ({                         \
        top->retVal = (value); \
        --top;                 \
    })
#define goto(loc) ({ f->pc = (loc)-1; })

int main(int argc, char *argv[]) {
    Frame stk[128], *top = stk - 1;
    int f_result = 0, g_result = 0;
    call(FUNC_F, 5);  // Example: f(5)

    for (Frame *f; (f = top) >= stk; (f->pc)++) {
        int n = f->n;
        FuncType funcType = f->funcType;
        // int retVal = f->retVal;

        if (funcType == FUNC_F) {
            switch (f->pc) {
                case 0:
                    if (n <= 1) {
                        ret(1);
                        goto(3);
                    }
                    break;
                case 1:
                    call(FUNC_F, n - 1);
                    break;
                case 2:
                    call(FUNC_G, n - 2);
                    break;
                case 3:
                    ret((f - 1)->retVal + f->retVal);
                    break;
                default:
                    assert(0);
            }
        } else if (funcType == FUNC_G) {
            switch (f->pc) {
                case 0:
                    if (n <= 1) {
                        ret(1);
                        goto(3);
                    }
                    break;
                case 1:
                    call(FUNC_F, n + 1);
                    break;
                case 2:
                    call(FUNC_G, n - 1);
                    break;
                case 3:
                    ret((f - 1)->retVal + f->retVal);
                    break;
                default:
                    assert(0);
            }
        }
    }

    f_result = stk[0].retVal;
    printf("f2(5) = %d\n", f_result);  // Output should be f(5)

    return 0;
}
```

=== compiler

```c
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
```

=== strace

```sh
❯ strace ./a.out
execve("./a.out", ["./a.out"], 0x7fff2fa08dd0 /* 59 vars */) = 0
write(1, "\33[01;31mHello, OS World\33[0m\n", 28Hello, OS World
) = 28
exit(1)                                 = ?
+++ exited with 1 +++
```

```sh
❯ strace -f gcc hello.c &| vim -
```

`:%!grep execve`, `:%!grep -v ENOENT`, `:%s/, /,\r/g`处理过后:

```
execve("/usr/bin/gcc",
["gcc",
"hello.c"],
0x7ffecbcd1e10 /* 69 vars */) = 0

execve("/usr/lib/gcc/x86_64-linux-gnu/11/cc1",
["/usr/lib/gcc/x86_64-linux-gnu/11"...,
"-quiet",
"-imultiarch",
"x86_64-linux-gnu",
"hello.c",
"-quiet",
"-dumpd

execve("/usr/bin/as",
["as",
"--64",
"-o",
"/tmp/ccrL6MYD.o",
"/tmp/ccbvDLa4.s"],
0x68b5c0 /* 74 vars */ <unfinished ...>

execve("/usr/lib/gcc/x86_64-linux-gnu/11/collect2",
["/usr/lib/gcc/x86_64-linux-gnu/11"...,
"-plugin",
"/usr/lib/gcc/x86_64-linux-gnu/11"...,
"-plugin-opt=/usr/

execve("/usr/bin/ld",
["/usr/bin/ld",
"-plugin",
"/usr/lib/gcc/x86_64-linux-gnu/11"...,
"-plugin-opt=/usr/lib/gcc/x86_64-"...,
"-plugin-opt=-fresolution=/tmp/cc
```

#tip("Tip")[
发现把所有中间结果 都输出到了临时文件里面.
]

== 阅读材料

decode core utils:https://www.maizure.org/projects/decoded-gnu-coreutils/
binutils:https://www.gnu.org/software/binutils/ gdb:
https://sourceware.org/gdb/current/onlinedocs/gdb.html/

=== gdb reverse execution

需要实践一下 process record and replay:
https://sourceware.org/gdb/current/onlinedocs/gdb.html/Process-Record-and-Replay.html#Process-Record-and-Replay
running programs backward:
https://sourceware.org/gdb/current/onlinedocs/gdb.html/Reverse-Execution.html#Reverse-Execution

=== tui

https://sourceware.org/gdb/current/onlinedocs/gdb.html/TUI.html#TUI
