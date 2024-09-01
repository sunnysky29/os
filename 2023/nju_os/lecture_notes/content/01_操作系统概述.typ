#import "../template.typ": *
= 操作系统概述

== (Why): 为什么要学操作系统?

=== 为什么要学 "任何东西"?

为什么要学操作系统呢? 为什么要学微积分/离散数学/XXXX/...?

=== 学过微积分以后, 再看为什么要学微积分

微积分的几个重要主题

- 启蒙, 应用与挑战 (Newton 时代)
  - 机械论世界观 (模型驱动的系统分析)
  - 数学是理解世界的 "基本工具": 导数, 微积分基本定理, ...
- 严格化与公理化 (Cauchy 时代)
  - 各种卡出的 bug (Weierstrass 函数, Peano 曲线...)
- 大规模问题的数值计算 (von Neumann 时代)
  - 优化, 有限元, PID...
  - AI 是未来人类社会的 "基本工具"

三个主题应该根据学科特点各有侧重 我自己的感受: 学了很多, 但好像都没学懂

=== 为什么要学 "任何东西"?

重走从无到有的发现历程:

- 基本思想, 基本方法, 里程碑, 走过的弯路
  - 最终目的: 应用/创新 (做题得分不是目的而是手段)
  - 如果只是记得几个结论, 那 ChatGPT 已经做得很好了

学习 "任何东西" 的现代方法:

- 使用辅助工具加速探索
  - 数值/符号计算: numpy, sympy, sage, Mathematica, ...
  - 可视化: matplotlib
    - All-in-one: Jupyter (2017 ACM Software System Award)
    - Life is short; you need Python
- (正好我有一个微积分相关的案例):#link("..\demo\01_demo\Exploration_and_Discovery_of_Mathematical_Concepts.ipynb")[Exploration_and_Discovery_of_Mathematical_Concepts]

=== 为什么学习操作系统?

你体内的 "编程力量" 尚未完全觉醒

- 每天都在用的东西, 你还没搞明白
  - 为什么能创建窗口?为什么 Ctrl-C 有时不能退出程序?
  - 为什么有的程序能把组里服务器的 128 个 CPU 用满?
- 你每天都在用的东西, 你实现不出来
  - 浏览器, 编译器, IDE, 游戏/外挂, 杀毒软件, 病毒...

《操作系统》带你补完 "编程" 的技术体系

- 悟性好: 学完课程就在系统方向 "毕业"
  - 具有编写一切 "能写出来" 程序的能力 (具备阅读论文的能力)
- 悟性差: 内力大增
  - 可能工作中的某一天想起上课提及的内容

== (What): 到底什么是操作系统?

=== 什么是操作系统?

_Operating System: A body of software, in fact, that is responsible for making it easy to run programs (even allowing you to seemingly run many at the same time), allowing programs to share memory, enabling programs to interact with devices, and other fun stuff like that. (OSTEP)_

"programs" 就完了?那么多复杂的程序呢！
"shared memory, interact with devices, ..."?
"管理软/硬件资源, 为程序提供服务" 的程序?

=== 理解操作系统

"精准" 的教科书定义毫无意义 (但作者得被迫去写)

- 定义是 "全部" 的一个极简表达
  - 如果只想 "了解", 那可以读一下定义
  - 如果想学习操作系统, 就必须理解 "全部"

操作系统 "全部" 的 overview:

#tip("Tip")[
这门课我们不需要太多关注定义,而是需要重点去关注*全部*
]

- 操作系统如何从一开始变成现在这样的?
- 三个重要的线索
  - 硬件 (计算机)
  - 软件 (程序)
  - 操作系统 (管理硬件和软件的软件)

=== 复习: 理解计算机硬件 (电路)

前导知识: 数字逻辑电路/计算机系统基础

- 一个极简的公理系统 (导线, 时钟, 逻辑门, 触发器)
  - 建立在公理体系上的数字系统设计 (包括计算机)
  - 前导课程目标: 能根据需求实现数字系统

==== Logisim Demo

数字电路模拟器

- 基本构件: wire, reg, NAND, NOT, AND, NOR
- 每一个时钟周期
  - 先计算 wire 的值
  - 在周期结束时把值锁存至 reg

会编程, 你就拥有全世界！

- 同样的方式可以模拟任何数字系统 (包括计算机系统)
- 同时还体验了 UNIX 哲学
  - Make each program do one thing well
  - Expect the output of every program to become the input to another

=== 复习: 理解计算机软件 (程序)

前导课程: C 程序设计/计算机系统基础

- 高级语言代码 -> 指令序列 -> 二进制文件 -> 处理器执行
  - 前导课程目标: 能将需求实现; 掌握工具使用; 阅读汇编指令

=== #link("..\demo\01_demo\rvemu\rvemu.c")[ RVEmu Demo ]

如果你的指令和设备实现得够完善, 就能直接启动 Linux

=== 理解操作系统

本课程讨论狭义的操作系统

- 操作系统: 硬件和软件的中间层
  - 对单机 (多处理器) 作出抽象
  - 支撑多个程序执行
- 学术界谈论的 "操作系统" 是更广义的 "System"
  - 例子: 对多台计算机抽象 (分布式系统)

理解操作系统

- 理解硬件 (计算机) 和软件 (程序) 的发展历史
- 夹在中间的就是操作系统

==== ENIAC: 1946.2.14

==== ENIAC: 1946.2.14

"图灵机" 的数字电路实现

执行完一条指令后, 可以根据结果跳转到任意一条指令 (用物理线路 "hard-wire")
重编程需要重新接线: Emulator and Programming the ENIAC

===== 1940s 的计算机硬件

电子计算机的实现

- 逻辑门: 真空电子管
- 存储器: 延迟线 (delay lines)
- 输入/输出: 打孔纸带/指示灯

打印平方数, 素数表, 计算弹道...

- 解释了《程序设计》教课书上经典习题的来源 (是时候改一改了)
- 大家还在和真正的 "bugs" 战斗

没有操作系统。

能把程序放上去就很了不起了

- 程序直接用指令操作硬件
- 不需要画蛇添足的程序来管理它

===== 1950s 的计算机硬件

更快更小的逻辑门 (晶体管), 更大的内存 (磁芯), 丰富的 I/O 设备 I/O
设备的速度已经严重低于处理器的速度, 中断机制出现 (1953)

更复杂的通用的数值计算

- 高级语言和 API 诞生 (Fortran, 1957): 一行代码, 一张卡片
  - 80 行的规范沿用至今 (细节: 打印机会印刷本行代码)

Fortran 已经 "足够好用"

自然科学, 工程机械, 军事...对计算机的需求暴涨

```fortran
C---- THIS PROGRAM READS INPUT FROM THE CARD READER,
C---- 3 INTEGERS IN EACH CARD, CALCULATE AND OUTPUT
C---- THE SUM OF THEM.
  100 READ(5,10) I1, I2, I3
   10 FORMAT(3I5)
      IF (I1.EQ.0 .AND. I2.EQ.0 .AND. I3.EQ.0) GOTO 200
      ISUM = I1 + I2 + I3
      WRITE(6,20) I1, I2, I3, ISUM
   20 FORMAT(7HSUM OF , I5, 2H, , I5, 5H AND , I5,
     *   4H IS , I6)
      GOTO 100
  200 STOP
      END
```

库函数 + 管理程序排队运行的调度代码。

写程序 (戳纸带), 跑程序都是非常费事的

- 计算机非常贵 ($50,000−$1,000,000), 一个学校只有一台
- 算力成为一种服务: 多用户轮流共享计算机, operator 负责调度

操作系统的概念开始形成

- 操作 (operate) 任务 (jobs) 的系统 (system)
  - "批处理系统" = 程序的自动切换 (换卡) + 库函数 API
  - Disk Operating Systems (DOS)
    - 操作系统中开始出现 "设备", "文件", "任务" 等对象和 API

===== 1960s 的计算机硬件

集成电路, 总线出现

- 更快的处理器
- 更快, 更大的内存; 虚拟存储出现
  - 可以同时载入多个程序而不用 "换卡" 了
- 更丰富的 I/O 设备; 完善的中断/异常机制

更多的高级语言和编译器出现

- COBOL (1960), APL (1962), BASIC (1965)
  - Bill Gates 和 Paul Allen 在 1975 年实现了 Altair 8800 上的 BASIC 解释器

计算机科学家们已经在今天难以想象的计算力下开发惊奇的程序

能载入多个程序到内存且调度它们的管理程序。

为防止程序之间形成干扰, 操作系统自然地将共享资源 (如设备) 以 API 形式管理起来

- 有了进程 (process) 的概念
- 进程在执行 I/O 时, 可以将 CPU 让给另一个进程
  - 在多个地址空间隔离的程序之间切换
  - 虚拟存储使一个程序出 bug 不会 crash 整个系统

操作系统中自然地增加进程管理 API

- 既然可以在程序之间切换, 为什么不让它们定时切换呢?
- Multics (MIT, 1965): 现代分时操作系统诞生

===== 1970s+ 的计算机硬件

集成电路空前发展, 个人电脑兴起, "计算机" 已与今日无大异

- CISC 指令集; 中断, I/O, 异常, MMU, 网络
- 个人计算机 (PC 机), 超级计算机...

PASCAL (1970), C (1972), ...

- 今天能办到的, 那个时代已经都能办到了——上天入地, 图像声音视频, 人工智能...
- 个人开发者 (Geek Network) 走上舞台

分时系统走向成熟, UNIX 诞生并走向完善, 奠定了现代操作系统的形态。

- 1973: 信号 API, 管道 (对象), grep (应用程序)
- 1983: BSD socket (对象)
- 1984: procfs (对象)...
- UNIX 衍生出的大家族
  - 1BSD (1977), GNU (1983), MacOS (1984), AIX (1986), Minix (1987), Windows (1985),
    Linux 0.01 (1991), Windows NT (1993), Debian (1996), Windows XP (2002), Ubuntu
    (2004), iOS (2007), Android (2008), Windows 10 (2015), ...

===== 今天的操作系统

通过 "虚拟化" 硬件资源为程序运行提供服务的软件。

空前复杂的系统之一

- 更复杂的处理器和内存
  - 非对称多处理器 (ARM big.LITTLE; Intel P/E-cores)
  - Non-uniform Memory Access (NUMA)
  - 更多的硬件机制 Intel-VT/AMD-V, TrustZone/SGX, TSX, ...
- 更多的设备和资源
  - 网卡, SSD, GPU, FPGA...
- 复杂的应用需求和应用环境
  - 服务器, 个人电脑, 智能手机, 手表, 手环, IoT/微控制器...

=== 课程内容概述

操作系统: 软件硬件之间的桥梁

- 本课程中的软件: 多线程 Linux 应用程序
- 本课程中的硬件: 现代多处理器系统

(设计/应用视角,自顶而下) 操作系统为应用提供什么服务?

- *操作系统 = 对象 + API*
- 课程涉及: POSIX + 部分 Linux 特性

(实现/硬件视角,自底而上) 如何实现操作系统提供的服务?

- *操作系统 = C 程序*
  - 完成初始化后就成为 interrupt/trap/fault handler
- 课程涉及: xv6, 自制迷你操作系统

== (How): 怎么学操作系统?

=== 对 "教学" 的一些思考

#tip("Tip")[
_热情且聪明的学生...听说相对论, 量子力学...但是, 当他们学完两年以前那种课程 (斜面, 静电这样的内容) 后, 许多人就泄气了_ ——The Feynman Lectures on Physics 
]

#tip("Tip")[
_Education is not the filling of a pail, but the lighting of a fire_——William Butler Yeats
]

我们读书的时代 (2009): 大家都说操作系统很难教

- 使用~~豆瓣评分高达 5.7/10~~ 的 "全国优秀教材"
  - 没有正经的实验 (16-bit code), 错误的工具链, 调试全靠猜
  - 为了一点微不足道的分数内卷, 沾沾自喜, 失去 integrity
    - 长此以往, 脖子都要被卡断了
- 同时, 课堂教学是最容易被改善的
  - 这门课告诉你可以变得更强, 真正的强

=== 学习操作系统: 现代方法

读得懂的教科书和阅读材料:Operating Systems: Three Easy Pieces

问题驱动, 用代码说话

- Demo 小程序, 各类系统工具 (strace, gdb, ...) 的使用
- xv6-riscv, AbstractMachine
- RTFM, STFW, RTFSC (F can be a colorful word)

=== Prerequisites

计算机专业学生必须具备的核心素质。

是一个合格的操作系统用户

1. 会 STFW/RTFM 自己动手解决问题
2. 不怕使用任何命令行工具
3. vim, tmux, grep, gcc, binutils, ...

不怕写代码

- 能管理一定规模 (数千行) 的代码
- 能在出 bug 时默念 "机器永远是对的, 我肯定能调出来的"
  - 然后开始用正确的工具/方法调试

#tip("Tip")[
给 "学渣" 们的贴心提示: 不要尝试 "架空学习", 回头补基础
]

=== 0. 学术诚信 (Academic Integrity)

Academic integrity 不是底线, 而是 "自发的要求"

对 "不应该做的事情" 有清楚的认识 不将代码上传到互联网
主动不参考别人完成的实验代码 不使用他人测试用例 (depends)
有些行为可能使你得到分数, 但失去应有的训练

=== 1. 成为 Power User

感到 Linux/PowerShell/... 很难用?

- 没有建立信心, 没有理解基本逻辑:计算机科学自学指南
- 没有找对材料/没有多问 "能不能再做点什么":Baidu v.s. Google/Github/SO v.s.
  ChatGPT
- 没有用对工具 (man v.s. tldr; 该用 IDE 就别 Vim):过了入门阶段, 都会好起来

=== 2. 学会写代码

写代码 = 创造有趣的东西

- 命令行 + 浏览器就是全世界 
#tip("Tip")[
我们还有 `sympy`, `sage`, `z3`, `rich`, ... 呢
]
- 不需要讲语言特性, 设计模式, ...:编就对了; 你自然而然会需要它们的

=== 最重要的: Get Your Hands Dirty

#tip("Tip")[
听课看书都不重要。独立完成编程作业即可理解操作系统。
]

应用视角 (设计): Mini Labs x 6(使用 OS API 实现 "黑科技" 代码) 硬件视角 (实现):
OS Labs x 5(自己动手实现一个真正的操作系统) 全部 Online Judge:

- 代码不规范 -> `-Wall` `-Werror` 编译出错
- 代码不可移植 -> 编译/运行时出错: `int x = (int)&y;`
- 硬编码路径/文件名 -> 运行时出错: `open("/home/a/b", ...)`

== 编程实践

=== Demo：数学概念的探索与发现

```py
= Life is short; you need Python.
import z3
import numpy as np
import sympy as sp
import matplotlib.pyplot as plt

x = sp.symbols('x')

def plot(f, points=[], draw_label=True, draw_points=True):
    """Plot a sympy symbolic polynomial f."""

    xmin = min([x_ for x_, _ in points], default=-1) - 0.1
    xmax = max([x_ for x_, _ in points], default=1) + 0.1

    xs = np.arange(xmin, xmax, (xmax - xmin) / 100)
    ys = [f.subs(x, x_) for x_ in xs]

    plt.grid(True)
    plt.plot(xs, ys)
    if draw_points:
        plt.scatter(
            [x_ for x_, y_ in points],
            [y_ for x_, y_ in points],
        )
    if draw_label:
        for x_, y_ in points:
            plt.text(x_, y_, f'$({x_},{y_})$', va='bottom', ha='center')
        plt.title(f'$y = {sp.latex(f)}$')
```

#tip("Tip")[
- `z3`是一个求解任何一个逻辑方程组的工具(推箱子, 数独...) 
- `sympy`符号计算的库.
]

用`sympy`做插值拟合.

```py
def interpolate(n=0, xs=[], ys=[]):
    """Return a polynomial that passes through all given points."""
    n = max(n, len(xs), len(ys))
    if len(xs) == 0: xs = [sp.symbols(f'x{i}') for i in range(n)]
    if len(ys) == 0: ys = [sp.symbols(f'y{i}') for i in range(n)]
    vs = [sp.symbols(f'a{i}') for i in range(n)]
    power = list(range(n))

    cons = [
        sum(
            v * (x_ * k) for v, k in zip(vs, power)
        ) - y
            for x_, y in zip(xs, ys)
    ]

    sol = list(sp.linsolve(cons, vs))[0]

    f = (sum(
        v * (x * k) for v, k in zip(sol, power)
    ))
    return f

= -----------------------------------
xs = [-1, 0, 1, 2, 3]
ys = [-1, 2, 1, 4, 5]
f = interpolate(xs=xs, ys=ys)
plot(f, list(zip(xs, ys)), True)

= -----------------------------------
n = 10
xs = np.arange(-1, 1, 1 / n)
ys = np.sin(xs * n)
f = interpolate(xs=xs, ys=ys)
plot(f, list(zip(xs, ys)), draw_points=True, draw_label=False)
f

= -----------------------------------
sp.simplify(interpolate(3))
```

==== 列表推导式

```py
[expression for item in iterable if condition]
```

列表推导式按照以下步骤操作：

- 从可迭代对象中逐个取出元素。
- 将每个元素应用于表达式，生成一个新的元素。
- 根据条件表达式过滤元素，只保留满足条件的元素。
- 将符合条件的元素组成一个新的列表。

```py
squares = [x*2 for x in range(10)]
= 输出: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
even_numbers = [x for x in numbers if x % 2 == 0]
= 输出: [2, 4, 6, 8, 10]
string = "Hello World"
upper_letters = [char for char in string if char.isupper()]
= 输出: ['H', 'W']
```

==== 格式化字符串

使用 f-strings（格式化字符串字面值）： 在 Python 3.6+ 版本中引入了
f-strings，它允许在字符串前加上 f 前缀，并使用 {} 占位符来嵌入表达式。示例：

```py
name = 'Charlie'
age = 35
print(f'My name is {name} and I am {age} years old.')
```

=== logisim demo
```c
#define PRINT(X) printf(#X " = %d; ", X)
```
其中 `#` 操作符是字符串化操作符，它将宏参数 `X` 转换为一个字符串。当宏被调用时，`#X` 将会被替换为参数 `X` 的字符串表示。

```c
int num = 10;
PRINT(num);
// printf("num" " = %d; ", num);
```

```py
import fileinput
 
DISPLAY = '''
     AAAAAAAAA
    FF       BB
    FF       BB
    FF       BB
    FF       BB
     GGGGGGGG
   EE       CC
   EE       CC
   EE       CC
   EE       CC
    DDDDDDDDD
''' 

= STFW: ANSI Escape Code
CLEAR = '\033[2J\033[1;1f'
BLOCK = {
    0: '\033[37m░\033[0m',
    1: '\033[31m█\033[0m',
}

for line in fileinput.input():
    = Load "A=0; B=1; ..." to current context
    exec(line)

    = Render the seven-segment display
    pic = DISPLAY
    for seg in set(DISPLAY):
        if seg.isalpha():
            val = globals()[seg]  = 0 or 1
            pic = pic.replace(seg, BLOCK[val])

    = Clear screen and display
    print(CLEAR + pic)
```

#tip("Tip")[
- `CLEAR` 是一个 ANSI 转义码，用于清除控制台屏幕，并将光标移动到屏幕左上角；`BLOCK` 是一个字典，它将数字 0 和 1 映射到不同的颜色块，其中数字 0 对应着浅色的块，数字 1 对应着深色的块。 
- `fileinput.input()` 循环遍历输入的行。在每次循环中，代码使用 `exec()` 函数执行当前行的代码，将其中定义的变量加载到当前上下文中。这样，可以通过在输入中设置变量的值来控制七段显示器的显示。
- 通过 `globals()` 函数获取全局变量中与该字母对应的变量（例如 `A`、`B`、`C`、`D`、`E`、`F`、`G`），并根据变量的值选择对应的颜色块进行替换。
]

=== RVEmu demo

#code(caption: [RVEmu demo])[
```c
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef uint32_t u32;

typedef struct {
    u32 op : 7, rd : 5, f3 : 3, rs1 : 5, rs2 : 5, f7 : 7;
} inst_t;
typedef struct {
    u32 on, x[32];
} CPUState;

static inline u32 sext(u32 val, u32 n) {
    // Sign extend n-bit integer val to 32-bit
    u32 mask = ~((1 << n) - 1);
    u32 set = (val >> (n - 1)) & 1;
    u32 ret = set ? (val | mask) : val;
    return ret;
}

// Uncore:
//   inst_fetch - read an instruction from stdin
//   ebreak - hyper call: putchar/putd/exit
static inline bool inst_fetch(inst_t *in) {
    union {
        inst_t i;
        u32 u;
    } u;
    int r = scanf("%x", &u.u);
    *in = u.i;
    return r > 0;
}

static inline void ebreak(CPUState *cpu) {
    switch (cpu->x[10]) {
        case 1: {
            putchar(cpu->x[11]);
            break;
        }
        case 2: {
            printf("%d", cpu->x[11]);
            break;
        }
        case 3: {
            cpu->on = false;
            break;
        }
        default:
            assert(0);
    }
}

int main(int argc, char *argv[]) {
    CPUState cpu = {.on = 1, .x = {0}};  // The RESET state
    for (int i = 0; argv[i + 1] && i < 8; i++) {
        cpu.x[10 + i] = atoi(argv[i + 1]);  // Set a0-a7 to arguments
    }

    inst_t in;
    while (cpu.on && inst_fetch(&in)) {
        // For each fetched instruction, execute it following the RV32I spec
        u32 op = in.op, f3 = in.f3, f7 = in.f7;
        u32 imm = sext((f7 << 5) | in.rs2, 12), shamt = in.rs2;
        u32 rd = in.rd, rs1_u = cpu.x[in.rs1], rs2_u = cpu.x[in.rs2], res = 0;

#define __ else if  // Bad syntactic sugar!
        if (op == 0b0110011 && f3 == 0b000 && f7 == 0b0000000)
            res = rs1_u + rs2_u;
        __(op == 0b0110011 && f3 == 0b000 && f7 == 0b0100000) res = rs1_u - rs2_u;
        __(op == 0b0010011 && f3 == 0b000)                    res = rs1_u + imm;
        __(op == 0b0010011 && f3 == 0b001 && f7 == 0b0000000) res = rs1_u << shamt;
        __(op == 0b0010011 && f3 == 0b101 && f7 == 0b0000000) res = rs1_u >> shamt;
        __(op == 0b1110011 && f3 == 0b000 && rd == 0 && imm == 1) ebreak(&cpu);
        else assert(0);
        if (rd) cpu.x[rd] = res;
    }
}
```
]
