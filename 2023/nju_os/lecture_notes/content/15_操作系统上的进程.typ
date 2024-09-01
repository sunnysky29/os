#import "../template.typ": *
#pagebreak()
= 操作系统上的进程

== 线程、进程和操作系统

=== ThreadOS 中的线程切换

#image("images/2023-11-25-20-52-47.png")
计算机硬件也是状态机

- “共享的内存，容纳了多个状态机”
  - 共享的代码
  - 共享的全局变量
  - 启动代码的堆栈 (仅启动代码可用)
  - $T_{1}$ 的 Task (仅 $T_{1}$ 和中断处理程序可用)
    - 堆栈 (中断时，寄存器保存在堆栈上)
  - $T_{2}$ 的 Task (仅 $T_{2}$ 和中断处理程序可用)
    - 堆栈 (中断时，寄存器保存在堆栈上)
- 状态迁移
  - 执行指令或响应中断

==== practice

#image("images/2023-11-25-20-53-04.png")

```sh
0x0000000000101640 in yield ()
(gdb) p tasks[0]
$1 = {{next = 0x105640 <tasks+8192>, entry = 0x0, context = 0x105590 <tasks+8016
>}, stack = "@V\020", '\000' <repeats 13 times>, "\220U\020", '\000' <repeats 80
45 times>...}
(gdb) p *tasks[0]->context
$2 = {cr3 = 0x0, rax = 0, rbx = 0, rcx = 0, rdx = 0, rbp = 0, rsi = 1048944, rdi = 0, r8 = 0, r9 = 0, r10 = 0, r11 = 0, r12 = 0, r13 = 0, r14 = 0, r15 = 0, rip = 1058556, cs = 8, rflags = 512, rsp = 1070656, ss = 0, rsp0 = 0}
(gdb) p/x &tasks
$5 = 0x103640
(gdb) p/x *tasks[0]->context.rsp
$3 = 0x103640
(gdb) p/x $rsp
$4 = 0x20a7b8
```

```c
void yield() {
  interrupt(0x81);
}
```

```asm
int $0x81
```

#tip("Tip")[
x86 架构中的`int`指令用于产生一个软中断（software interrupt）或异常该指令的语法如下： `int imm8`. 其中，`imm8`是一个立即数（immediate），表示中断向量号（interrupt vector number）。这个中断向量号对应着一段中断处理程序（interrupt handler）的地址，当`int`指令被执行时，处理器将跳转到相应的中断处理程序。 
]

#tip("Tip")[
在 x86 架构中，有一些预定义的中断向量号，用于处理特定的中断事件。例如，中断向量号为 `0x80` 的中断用于系统调用（system call）操作，在 Linux 等操作系统中经常被使用。
]

执行完`int $0x81后`,再看 rsp 的值:

```sh
(gdb) layout asm
(gdb) si
0x0000000000101644 in yield ()
(gdb) p/x $rsp
$7 = 0x20a7b8
(gdb) si
0x00000000001028a2 in __am_irq129 ()
(gdb) p/x $rsp
$8 = 0x20a788
```

#image("images/2023-11-25-20-53-16.png")

#tip("Tip")[
`rdi` 是函数调用的第一个参数
]

这部分代码十分精妙, 需要花时间去阅读和调试. 不要忘了给 am 开`-g`

=== 什么是操作系统？

#image("images/2023-11-25-21-12-23.png")
虚拟化：操作系统同时保存多个状态机

- C 程序 = 状态机
  - 初始状态：main(argc, argv)
  - 状态迁移：指令执行
    - 包括特殊的系统调用指令 syscall
- 有一类特殊的系统调用可以管理状态机
  - `CreateProcess(exec_file)`
    - 指定一个二进制代码, 在系统里面创建一个新的状态机(windows api)
  - `TerminateProcess()`
  #tip("Tip")[
  提供怎样的 syscall 是自己可以设计的
  ]

从线程到进程：虚拟存储系统

- 通过虚拟内存实现每次 “拿出来一个执行”
- 中断后进入操作系统代码，“换一个执行”

整个世界都是由最初的 init 状态机创建出来的.
#image("images/2023-11-25-21-12-14.png")

== 复制状态机：fork()

=== 状态机管理：创建状态机

如果要创建状态机，我们应该提供什么样的 API？

UNIX 的答案: `fork`

- 做一份状态机完整的复制 (内存、寄存器现场)
  #image("images/2023-11-25-21-17-43.png")

`int fork();`

- 立即复制状态机 (完整的内存)
  - 复制失败返回 -1 (errno)
- 新创建进程返回 0
- 执行 fork 的进程返回子进程的进程号

=== Fork Bomb

模拟状态机需要资源

- 只要不停地创建进程，系统还是会挂掉的
- Don't try it (or try it in docker)
  - 你们交这个到 Online Judge 是不会挂的

==== 代码解析: Fork Bomb

```bash
:(){:|:&};:   = 刚才的一行版本

:() {         = 格式化一下
  : | : &
}; :

fork() {      = bash: 允许冒号作为标识符……
  fork | fork &
}; fork
```

#tip("Tip")[
很快系统资源就会被耗尽.
]

=== 这次你们记住 Fork 了！

因为状态机是复制的，因此总能找到 “父子关系”

因此有了进程树 (pstree)

```sh
systemd-+-ModemManager---2*[{ModemManager}]
        |-NetworkManager---2*[{NetworkManager}]
        |-accounts-daemon---2*[{accounts-daemon}]
        |-at-spi-bus-laun-+-dbus-daemon
        |                 `-3*[{at-spi-bus-laun}]
        |-at-spi2-registr---2*[{at-spi2-registr}]
        |-atd
        |-avahi-daemon---avahi-daemon
        |-colord---2*[{colord}]
        ...
```

#tip("Tip")[
- `fork` 是 unix 世界里面创建进程的唯一方法
- 例如, 先把 1-100,000,000 的质数算出来, 然后 fork 10 个进程, 接下来这 10 个进程就可以共享先前这个算出来的进程表
]

=== 理解 fork: 习题 (1)

阅读程序，写出运行结果

```c
pid_t x = fork();
pid_t y = fork();
printf("%d %d\n", x, y);
```

一些重要问题

- 到底创建了几个状态机？
- pid 分别是多少？
- “状态机视角” 帮助我们严格理解
- 同样，也可以 model check!

```c
❯ gcc fork-demo.c && ./a.out
15625 15626
15625 0
0 15627
0 0
❯ ./a.out
15673 15674
0 15675
15673 0
0 0
❯ ./a.out
15683 15684
15683 0
0 15685
0 0
❯ ./a.out
15693 15694
15693 0
0 15695
0 0
```

#image("images/2023-11-26-08-23-17.png")

=== 理解 fork: 习题 (2)

阅读程序，写出运行结果

```c
for (int i = 0; i < 2; i++) {
  fork();
  printf("Hello\n");
}
```

状态机视角帮助我们严格理解程序行为

- `./a.out`
- `./a.out | cat`
  - 计算机系统里没有魔法
  - (无情执行指令的) 机器永远是对的

```c
❯ gcc fork-printf.c && ./a.out
Hello
Hello
Hello
Hello
Hello
Hello
❯ ./a.out | wc -l
8
❯ ./a.out | cat
Hello
Hello
Hello
Hello
Hello
Hello
Hello
Hello
```

这种神奇的现象怎么调试呢? 任何程序的输出行为都是状态机的行为,
都是执行指令的后果.

`diff <(strace -f ./a.out) <(strace -f ./a.out | cat)`: 输出很多, 没啥参考价值

`strace -f ./a.out`:

```
[pid 17766] write(1, "Hello\nHello\n", 12 <unfinished ...>
[pid 17765] write(1, "Hello\nHello\n", 12 <unfinished ...>
[pid 17764] write(1, "Hello\nHello\n", 12) = 12
write(1, "Hello\nHello\n", 12)          = 12
```

`strace -f sh -c "./a.out | cat"`:

```
[pid 22178] write(1, "Hello\nHello\n", 12 <unfinished ...>
[pid 22179] write(1, "Hello\nHello\n", 12 <unfinished ...>
[pid 22177] write(1, "Hello\nHello\n", 12 <unfinished ...>
[pid 22175] write(1, "Hello\nHello\n", 12 <unfinished ...>
[pid 22176] write(1, "Hello\nHello\nHello\nHello\nHello\nHe"..., 48Hello
```

`printf`不总是直接打印到标准输出的, 会根据标准输出连接的是终端还是管道,
会做不同的行为, 如果是一个管道, 会把输出写到一个 libc 的缓冲区里面, 无法看到.

#image("images/2023-11-26-08-23-07.png")

== 重置状态机：`execve()`

如何从 init 状态机得到一个花花世界的呢?

=== 状态机管理：重置状态机

UNIX 的答案: `execve`

- 将当前进程重置成一个可执行文件描述状态机的初始状态
  `int execve(const char *filename, char * const argv[], char * const envp[]);`

`execve` 行为

#image("images/2023-11-26-08-36-19.png")

- 执行名为 filename 的程序
- 允许对新状态机设置参数 `argv (v)` 和环境变量 `envp (e)`
  - 刚好对应了 `main()` 的参数！
- `execve` 是唯一能够 “执行程序” 的系统调用
  - 因此也是一切进程 `strace` 的第一个系统调用

例如:`vim <(strace -f ls -la 2>&1)`
第一行就是:`execve("/usr/bin/ls", ["ls", "-la"], 0x7ffe4c0f9550 /* 50 vars */) = 0`
任何程序的执行都是从`execve`开始

=== 环境变量

“应用程序执行的环境”

- 使用 `env` 命令查看
  - `PATH`: 可执行文件搜索路径
  - `PWD`: 当前路径
  - `HOME`: home 目录
  - `DISPLAY`: 图形输出
  - `PS1`: shell 的提示符
  - `export`: 告诉 shell 在创建子进程时设置环境变量
- 小技巧：`export ARCH=x86_64-qemu` 或 `export ARCH=native`
  - 上学期的 `AM_HOME` 终于破案了 
  #tip("Tip")[
  `execve`不仅要传入程序本身的参数, 还要传入程序运行的环境.
  ]

```c
#include <stdio.h>
#include <unistd.h>

int main() {
    char *const argv[] = {
        "/bin/bash",
        "-c",
        "env",
        NULL,
    };
    char *const envp[] = {
        "HELLO=WORLD",
        NULL,
    };
    execve(argv[0], argv, envp);
    printf("Hello, World!\n");
}
```

output:

```sh
❯ gcc execve-demo.c && ./a.out
PWD=/home/liuheihei/cs_learning/nju_os/demo/15_demo/execve-demo
HELLO=WORLD
SHLVL=0
_=/usr/bin/env
```

==== 环境变量：PATH

可执行文件搜索路径

还记得 `gcc` 的 `strace` 结果吗？

```
[pid 28369] execve("/usr/local/sbin/as", ["as", "--64", ...
[pid 28369] execve("/usr/local/bin/as", ["as", "--64", ...
[pid 28369] execve("/usr/sbin/as", ["as", "--64", ...
[pid 28369] execve("/usr/bin/as", ["as", "--64", ...
```

这个搜索顺序恰好是 PATH 里指定的顺序

```sh
$ PATH="" /usr/bin/gcc a.c
gcc: error trying to exec 'as': execvp: No such file or directory
$ PATH="/usr/bin/" gcc a.c
```

计算机系统里没有魔法。机器永远是对的。

== 销毁状态机：`_exit()`

=== 状态机管理：销毁状态机

有了 `fork`, `execve` 我们就能自由执行任何程序了，最后只缺一个销毁状态机的函数！
UNIX 的答案: `_exit`(立即摧毁状态机)

`void _exit(int status)`

- 销毁当前状态机，并允许有一个返回值
- 子进程终止会通知父进程 (后续课程解释)
#tip("Tip")[
C标准库里面有个`exit`, 为了和这个系统调用作区分, 于是给系统调用添加了`_`
]

这个简单…… 但问题来了：多线程程序怎么办？

=== 结束程序执行的三种方法

`exit` 的几种写法 (它们是不同)

- `exit(0)` - stdlib.h 中声明的 `libc` 函数
  - 会调用 `atexit`
- `_exit(0)` - glibc 的 `syscall wrapper`
  - 执行 “exit_group” 系统调用终止整个进程 (所有线程)
    - 细心的同学已经在 `strace` 中发现了
  - 不会调用 `atexit`
- `syscall(SYS_exit, 0)`
  - 执行 “exit” 系统调用终止当前线程
  - 不会调用 `atexit`


#tip("Tip")[
The `atexit()` function registers the given function to be called at normal process termination, either via `exit(3)` or via return from the program's `main()`.
]
