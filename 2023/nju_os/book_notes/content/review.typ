#import "../template.typ": *

= 简介

操作系统三座大山: 虚拟化，并发，持久化

总目标： easy to use

设计目标：高性能，低能耗，保护（隔离），可靠性（系统崩溃了，寄）
#tip("Tip")[
其他目标：节能，安全性，可移植性....
]

早期操作系统，就是一个库。
-> 有了保护
-> 多程序
-> 现代

= CPU 虚拟化

== 进程
问题：1个CPU如何制造出有许多CPU的假象？
答：多个程序之间来回切换。(time-sharing)

如何实现?
- machinery low lever 机制： time-sharing
- 高级策略：调度策略

进程的抽象: 进程是个状态机(内存，寄存器)

进程的一些api:
- Create(create a process)
- Destroy(destroy a process)
- Wait(wait for a process to stop running)
- Miscellaneous Control(suspend, resume…)
- Status(get some info about a process)

运行一个进程之前：
- 加载代码和静态数据到内存（进程的地址空间）
  #tip("Tip")[
      早期的操作系统，the loading process is done *eagerly*, 现在是lazily(paging and swapping)
  ]
- os给进程的栈和堆分配内存
- 初始化工作，例如IO相关
- 接着从程序的入口(跳到`main`)开始无情地执行指令

进程的状态： Running Ready Blocked

进程的数据结构(xv6-kernel)：
#code(caption: [struct proc])[
```c
// Saved registers for kernel context switches.
struct context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID

  // wait_lock must be held when using this:
  struct proc *parent;         // Parent process

  // these are private to the process, so p->lock need not be held.
  uint64 kstack;               // Virtual address of kernel stack
  uint64 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};
```
]

上下文切换：进程停止的时候，寄存器被存储在内存里，进程恢复运行的时候从内存恢复寄存器的值。

- 初始状态：进程被创建的时候。
- 最终状态：进程停止但尚未被清理的示（有时候叫僵尸状态zombie state）
  - 最终状态一般被父母进程用来检测退出码(0表示成功，非0失败)
- 当进程运行结束的时候，进程一般会调用`wait()`系统调用来等待孩子进程的完成，并且通知OS可以清理相关的数据结构

数据结构：进程列表(Process list) 里面存储的是 *进程控制块(PCB)*

== 常见的Process API：
- `fork()`
- `wait()`
- `exec()`
- `kill()`
  - <C-c> 发送`SIGINT`信号，终止进程
  - <C-z> 发送`SIGSTP`信号，暂停进程（可以使用`fg`进行恢复）
- ...

== Mechanism: Limited Direct Execution

虚拟化两方面的挑战：
1. 性能: 如何实现虚拟化而不消耗太多系统性能。
2. 控制: 进程切换

=== 直接执行

#image("images/2023-12-12-19-59-56.png",width: 80%)

问题：
1. 保护(如果没有保护，那OS不就是一个library吗？)
2. 分时

=== 问题1：限制性操作

如果进程想要执行一些限制性操作，例如I/O操作或者获取更多系统资源？

简单的解决方案：不进行保护

引入user/kernel mode:
- user mode： 用户代码只能在user mode里面执行,例如在用户模式下，进程无法直接I/O操作，否则会异常然后OS直接杀死进程
- kernel mode：神！！！

当用户进程想要执行一些特权操作的时候就要使用syscall.
为了执行syscall, 必须限制性一条特殊的Trap指令:
- 进入kernel-mode(必须保存相应的寄存器), 然后执行syscall
- 返回用户进程(返回user-mode)

#tip("Tip")[
trap如何知道执行哪个系统调用呢？
1. 没法让用户进程直接指定指令地址，这样就失去了保护作用。(syscall编号)
2. 系统在启动的时候设置一个trap table，告诉硬件当特定的异常出现的时候应该执行哪些指令：
  - hard-disk interrup出现
  - 键盘中断出现
  - 用户进程系统调用(把syscall number放在一个寄存器或者栈的指定位置，trap handler检查有效性然后执行)
  - 。。。
]

#image("images/2023-12-12-20-37-13.png", width: 90%)

=== 问题2: 进程切换

如果一个进程在CPU上运行，那意味着OS不在运行，那操作系统能干啥？如何让OS重新获得CPU的控制权用来进程切换？

方案1: OS相信进程，进程自己会周期性地放弃CPU。什么样的进程呢？
- 会使用系统调用的进程。（`yield`syscall不做啥事儿，仅仅把控制权交还给os）
- 一些做了违法操作的进程(例如除0异常)

但是万一程序死循环了？只能重启了。

于是*计时器中断*

==== 上下文切换

OS重获控制权之后，继续当前运行的进程还是进行切换?(由scheduler进行决策)

上下文切换:
1. 把当前进程的的寄存器，pc，放到kernel stack里面(一个进程有一个kernel stack)
2. 把下面一个将要运行的进程的寄存器，pc，从kernel stack恢复(改变kernel stack指针)

#image("images/2023-12-12-20-37-13.png", width: 90%)

有两种上下文切换：
- 第一种是timer interrupt: 隐式地把当前进程信息进行硬件保存。(保存到当前进程的内核栈)
- 第二种是OS调度的切换: 显式地把当前进程信息进行软件保存。(保存到当前内存里面的进程数据结构里)

=== 并发问题？

一般来说再一个中断执行时需要关中断。(关中断时间太长实际上并不好)

#tip("Tip")[
上下文切换的执行时间？ 可以使用`lmbench`
]

== 调度

调度指标: *性能*, *公平性*

== 内存虚拟化

早期的操作系统就是一个库，运行的进程直接放在物理内存里面。
#image("images/2023-12-12-20-46-40.png", width: 50%)

- 多道: 许多进程，os对这些进程进行切换(引入保护的问题)
- 分时: 多用户用一个机器，每个用户等待自己任务的响应

=== 地址空间

地址空间: 正在运行的程序 眼中的 操作系统的内存。
#image("images/2023-12-12-21-00-52.png", width: 70%)

#tip("Tip")[
- 隔离原则： 两个实体，一个寄了不会影响另一个。
  - 内存隔离：进程寄了不会影响操作系统。
]

虚拟内存的设置目标：
1. 透明(程序不知道自己的内存是虚拟化的)
2. 时空效率
3. 保护

=== 地址转换
