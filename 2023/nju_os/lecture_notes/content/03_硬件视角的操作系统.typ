#import "../template.typ": *
#pagebreak()
= 硬件视角的操作系统

== 回顾：计算机硬件

=== 计算机硬件 = 数字电路

数字电路模拟器 (Logisim)

- 基本构件：wire, reg, NAND
- 每一个时钟周期
- 先计算 wire 的值
- 在周期结束时把值锁存至 reg

"模拟" 的意义

- 程序是 "严格的数学对象"
- 实现模拟器意味着 "完全掌握系统行为"

=== 计算机硬件的状态机模型

不仅是程序, 整个计算机系统也是一个状态机

- 状态：内存和寄存器数值
- 初始状态：手册规定 (CPU Reset)
- 状态迁移
  - 任意选择一个处理器 cpu
  - 响应处理器外部中断
  - 从 cpu.PC 取指令执行

到底谁定义了状态机的行为？ 我们如何控制 "什么程序运行"？ 为了让 "操作系统"
这个程序能够正确启动, 计算机硬件系统必定和程序员之间存在约定——首先就是 Reset
的状态, 然后是 Reset 以后执行的程序应该做什么.

== 硬件与程序员的约定

=== Bare-metal 与程序员的约定

Bare-metal 与厂商的约定

- CPU Reset 后的状态 (寄存器值)
  - 厂商自由处理这个地址上的值
  - Memory-mapped I/O

#tip("Tip")[
reset 后,cpu 就是无情的执行指令的机器, 主板生产厂商只要在 reset pc 所指向的位置放上一段代码, 就会运行. 
]

#tip("Tip")[
厂商会在主板上放一个小的固件芯片,这个芯片里面存储有代码, 有数据. 比如重启电脑时候的 logo, 就是厂商写进去的 ROM(只读存储器, 存储系统引导程序)里的一部分. 这是主板厂商和 cpu 厂商之间的约定. 厂商还会和操作系统开发者再有一层约定, 厂商为操作系统开发者提供 Firmware
]

#tip("Tip")[
Firmware 嵌入式设备中的一种软件类型, 它是一组指令和数据, 被存储在硬件设备的非易失性存储器(如闪存, EEPROM).与操作系统不同, 固件通常被永久地编程到硬件设备中, 以执行特定的功能或控制设备的操作.
]

- 管理硬件和系统配置
- 把存储设备上的代码加载到内存
  - 例如存储介质上的第二级 loader (加载器)
  - 或者直接加载操作系统 (嵌入式系统)

=== x86 Family: CPU Reset

CPU Reset ([ Intel® 64 and IA-32 Architectures Software Developer’s Manual
](https://software.intel.com/en-us/articles/intel-sdm), Volume 3A/3B)

- 寄存器会有确定的初始状态
  - EIP = 0x0000fff0
  - CR0 = 0x60000010
    - 处理器处于 16-bit 模式
  - EFLAGS = 0x00000002
    - Interrupt disabled
- TFM (5,000 页+)
  - 最需要的 Volume 3A 只有 ~400 页 (我们更需要 AI)

=== 其他平台上的 CPU Reset

Reset 后处理器都从固定地址 (Reset Vector) 启动

- MIPS: `0xbfc00000`
  - Specification 规定
- ARM: `0x00000000`
  - Specification 规定
  - 允许配置 Reset Vector Base Address Register(这样软件可以自由设置, 可以不从 `0x00000000` 来启动.)
- RISC-V: Implementation defined
  - 给厂商最大程度的自由

Firmware 负责加载操作系统

- 开发板：直接把加载器写入 ROM
- QEMU：-kernel 可以绕过 Firmware 直接加载内核 (RTFM)

=== x86 CPU Reset 之后：到底执行了什么？

状态机 (初始状态) 开始执行

- 从 PC 取指令, 译码, 执行...
- 开始执行厂商 "安排好" 的 Firmware 代码
  - x86 Reset Vector 是一条向 Firmware 跳转的 `jmp` 指令

Firmware: #link("https://www.zhihu.com/question/21672895")[ BIOS vs. UEFI ]

- 一个小 "操作系统"
  - 管理, 配置硬件；加载操作系统
- Legacy BIOS (Basic I/O System)
  - IBM PC 所有设备/BIOS 中断是有 specification 的 (成就了 "兼容机")
- UEFI (Unified Extensible Firmware Interface)

==== 为什么需要 UEFI？

今天的 Firmware 面临麻烦得多的硬件： 指纹锁, USB 转接器上的 Linux-to-Go 优盘, 山寨网卡上的 PXE 网络启动, USB 蓝牙转接器连接的蓝牙键盘, ...

这些设备都需要 "驱动程序" 才能访问 解决 BIOS 逐渐碎片化的问题

==== 回到 Legacy BIOS: 约定

BIOS 提供一个机制:将程序员的代码载入内存

- Legacy BIOS (逐个扫描, A 盘,B 盘..)把第一个可引导设备的第一个 512 字节(MBR,Master Boot Record, 0 号扇区)加载到物理内存的 `0x7c00` 位置
  - 此时处理器处于 16-bit 模式
  - 规定 CS:IP = `0x7c00`, `(R[CS] << 4) | R[IP] == 0x7c00`
    - 可能性 1：`CS = 0x07c0`, `IP = 0`
    - 可能性 2：`CS = 0`, `IP = 0x7c00`
  - 其他没有任何约束

虽然最多只有 446 字节代码 (64B 分区表 + 2B 标识) 但控制权已经回到程序员手中了！ 你甚至可以让 ChatGPT 给你写一个 Hello World, 当然, 他是抄作业的 (而且是有些小问题的)

===== 举例

cpu reset(intel) CS:IP(`0xffffh`:`0x0000h`) 形成 physical address `0xffff0-`>Firmware 把 MBR 加载到内存的 0x7c00

```
                        0x7c00
                        |
                        v
      -----------------------------------------------
      |                 |                  |
      |                 |    MBR           |
      |                 |                  |
      -----------------------------------------------
                        ^
                        |
                       pc
```

为了标记一个分区可不可以启动, 会在 512 字节的最后写上两个字节的 magic number:
0x55,0xAA,表示可以启动.

#tip("Tip")[
追问, 到底哪些指令把这个 512 字节搬到了内存.
]

=== 能不能看一下代码？

_Talk is cheap. Show me the code. ——Linus Torvalds_

有没有可能我们真的去看从 CPU Reset 以后每一条指令的执行？

计算机系统公理：你想到的就一定有人做到

模拟方案：QEMU 传奇黑客, 天才程序员 Fabrice Bellard 的杰作 QEMU, A fast and
portable dynamic translator (USENIX ATC'05) Android Virtual Device, VirtualBox, ... 背后都是 QEMU 真机方案：JTAG (Joint Test Action Group) debugger 一系列 (物理) 调试寄存器, 可以实现 gdb 接口 (!!!)

=== ️🌶️ UEFI 上的操作系统加载

标准化的加载流程

- 磁盘必须按 GPT (GUID Partition Table) 方式格式化
- 预留一个 FAT32 分区 (lsblk/fdisk 可以看到)
- Firmware 能够加载任意大小的 PE 可执行文件 .efi(挂在相应的 FAT32
  分区之后可以看到相应的.efi 文件)
  - 没有 legacy boot 512 字节限制
  - EFI 应用可以返回 firmware

更好的程序支持

- 设备驱动框架
- 更多的功能, 例如 Secure Boot, 只能启动 "信任" 的操作系统

#tip("Tip")[
和 legacy bios 基本上一样的. 只是多了一些额外的约定.
]

=== 小插曲：Hacking Firmware (1998)

Firmware 通常是只读的 (当然)...

Intel 430TX (Pentium) 芯片组允许写入 Flash ROM 只要向 Flash BIOS 写入特定序列, Flash ROM 就变为可写 留给 Firmware 更新的通道 要得到这个序列其实并不困难, 似乎文档里就有 🤔 Boom... CIH 病毒的作者陈盈豪被逮捕, 但并未被定罪

== 实现最小 "操作系统"

=== 我们已经获得的能力

为硬件直接编程

- 可以让机器运行任意不超过 510 字节的指令序列
- 编写任何指令序列 (状态机)
  - 只要能问出问题, 就可以 RTFM/STFW/ChatGPT 找到答案
    - "如何在汇编里生成 n 个字节的 0"
    - "如何在 x86 16-bit mode 打印字符"

操作系统：就一个 C 程序

- 用 510 字节的指令完成磁盘 → 内存的加载
- 初始化 C 程序的执行环境
- 操作系统就开始运行了！

=== 实现操作系统：觉得 "心里没底"？

心路历程

- 曾经的我：哇！这也可以？
- 现在的我：哦.呵呵呵.

大学的真正意义

- 迅速消化数十年来建立起的学科体系
  - 将已有的思想和方法重新组织, 为大家建立好 "台阶"
- 破除 "写操作系统很难", "写操作系统很牛" 类似的错误认识
  - 操作系统真的就是个 C 程序
  - 你只是需要 "被正确告知" 一些额外的知识
    - 然后写代码, 吃苦头
    - 从而建立正确的 "专业世界观"

=== Bare-metal 上的 C 代码

为了让下列程序能够 "运行起来"：

```c
int main() {
  printf("Hello, World\n");
}
```

我们需要准备什么？

- MBR 上的 "启动加载器" (Boot Loader)
- 我们可以通过编译器控制 C 程序的行为
  - 静态链接/PIC (位置无关代码)
  - Freestanding (不使用任何标准库)
  - 自己手工实现库函数 (putch, printf, ...)
    - 有亿点点细节：RTFSC!

=== 进入细节的海洋

好消息：我们提供了运行 C 程序的框架代码和库 坏消息：框架代码也太复杂了吧

- 被 ICS PA 支配的恐惧再次袭来...
  - 读懂 Makefile 需要 STFW, RTFM, 大量的精力
  - 读了很久都没读到重要的地方 → 本能地放弃

例如阅读 am 的 makefile 花一点时间想 "有更好的办法吗？"

- 花几分钟创建一个小工具："构建理解工具"
  - UNIX Philosophy
  - 把复杂的构建过程分解成流程 + 可理解的单点
- Get out of your comfort zone

==== (1) 生成镜像和启动虚拟机

观察 AbstractMachine 程序编译过程的正确方法：

```sh
make -nB \
  | grep -ve '^\(\#\|echo\|mkdir\|make\)' \
  | sed "s#$AM_HOME#\$AM_HOME#g" \
  | sed "s#$PWD#.#g" \
  | vim -
```

Command line tricks

- `make -nB` (RTFM)
- `grep`: 文本过滤, 省略了一些干扰项
  - `echo` (提示信息), `mkdir` (目录建立), `make` (sub-goals)
- `sed`: 让输出更易读
  - 将绝对路径替换成相对路径
- `vim`: 更舒适的编辑/查看体验

==== (2) 改进文本可读性

想要看得更清楚一些？

`:%s/ /\r /g`

- 每一个命令就像 "一句话"
- AI 落后, 一代人就落后
  - 我的学习历程 (~2010)：看书, 在床上刷 Wikipedia

编译/链接

- `-std=gnu11`, `-m64`, `-mno-sse`, `-I`, `-D`, ...
  - 它们是导致 vscode 里红线的原因
- `-melf_x86_64`, `-N`, `-Ttext-segment=0x00100000`
  - 链接了需要的库 (am-x86_64-qemu.a, klib-x86_64-qemu.a)

==== (3) 启动加载器 (Boot Loader)

假设 MBR 后紧跟 ELF Binary (真正的的加载器有更多 stages)

- 16-bit → 32-bit
- ELF32/64 的加载器
- 按照约定的磁盘镜像格式加载

代码讲解： am/src/x86/qemu/boot/start.S 和 main.c 最终完成了 C 程序的加载
(它们都可以调试)

```c
if (elf32->e_machine == EM_X86_64) {
  ((void(*)())(uint32_t)elf64->e_entry)();
} else {
  ((void(*)())(uint32_t)elf32->e_entry)();
}
```

=== 我们承诺的 "操作系统"

就是一个 C 程序

- 只不过调用了更多的 API (之后解释)
  - 使用了正确的工具, 就没什么困难的

支持固定的 "线程"

- Ta - while (1) printf("a");
- Tb - while (1) printf("b");
  - 允许并发执行

== 编程实践

=== mbr

mbr.S

```asm
#define SECT_SIZE  512

.code16  // 16-bit assembly

// Entry of the code
.globl _start
_start:
  lea   (msg), %si   // R[si] = &msg;

again:
  movb  (%si), %al   // R[al] = *R[si]; <--+
  incw  %si          // R[si]++;           |
  orb   %al, %al     // if (!R[al])        |
  jz    done         //   goto done; --+   |
  movb  $0x0e, %ah   // R[ah] = 0x0e;  |   |
  movb  $0x00, %bh   // R[bh] = 0x00;  |   |
  int   $0x10        // bios_call();   |   |
  jmp   again        // goto again; ---+---+
                     //                |
done:                //                |
  jmp   .            // goto done; <---+

// Data: const char msg[] = "...";
msg:
  .asciz "This is a baby step towards operating systems!\r\n"

// Magic number for bootable device
.org SECT_SIZE - 2
.byte 0x55, 0xAA
```

`int   $0x10        // bios_call();`这里可以跳转到 firmware 执行. qemu 的
firmware 在内存的什么位置?

```makefile
mbr.img: mbr.S
  gcc -ggdb -c $<
  ld mbr.o -Ttext 0x7c00
  objcopy -S -O binary -j .text a.out $@
```

首先编译出 mbr.o, 接着链接到 0x7c00 处.
`objcopy -S -O binary -j .text a.out $@`：这行指令使用 objcopy 工具将 a.out
可执行文件中的只读 `.text` 段复制到一个二进制文件 mbr.img 中.`-S` 选项表示去除所有符号信息, `-O binary` 选项表示输出二进制格式文件, `-j .text` 选项表示只复制 `.text` 段.

看一下这 512 个字节:

```
❯ xxd mbr.img
00000000: 8d36 157c 8a04 4608 c074 08b4 0eb7 00cd  .6.|..F..t......
00000010: 10eb f1eb fe54 6869 7320 6973 2061 2062  .....This is a b
00000020: 6162 7920 7374 6570 2074 6f77 6172 6473  aby step towards
00000030: 206f 7065 7261 7469 6e67 2073 7973 7465   operating syste
00000040: 6d73 210d 0a00 0000 0000 0000 0000 0000  ms!.............
00000050: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000060: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000070: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000080: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000090: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000000a0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000000b0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000000c0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000000d0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000000e0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000000f0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000100: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000110: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000120: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000130: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000140: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000150: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000160: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000170: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000180: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000190: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000001a0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000001b0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000001c0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000001d0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000001e0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
000001f0: 0000 0000 0000 0000 0000 0000 0000 55aa  ..............U.
```

=== qemu 调试

gdb 调试的时候是 16 位模式, 代码是 64 位的, 所以会有些小问题比如在`x/10i $cs * 16 + $rip`的时候.

```sh
❯ qemu-system-x86_64 -s -S mbr.img &
[1] 26553
....
❯ gdb
GNU gdb (Ubuntu 12.1-0ubuntu1~22.04) 12.1
....
0x000000000000fff0 in ?? ()
(gdb) p $rip
$1 = (void (*)()) 0xfff0
(gdb) p/x $cs
$3 = 0xf000
(gdb) p/x $cs * 16 + $rip
$4 = 0xffff0
(gdb) x/10i $cs * 16 + $rip
   0xffff0:     (bad)
   0xffff1:     pop    %rbx
   0xffff2:     loopne 0xffff4
   0xffff4:     lock xor %dh,(%rsi)
   0xffff7:     (bad)
   0xffff8:     xor    (%rbx),%dh
   0xffffa:     (bad)
   0xffffb:     cmp    %edi,(%rcx)
   0xffffd:     add    %bh,%ah
   0xfffff:     add    %al,(%rax)
(gdb) x/10x $cs * 16 + $rip
0xffff0:        0x00e05bea      0x2f3630f0      0x392f3332      0x00fc0039
0x100000:       0x00000000      0x00000000      0x00000000      0x00000000
0x100010:       0x00000000      0x00000000
(gdb) si
0x000000000000e05b in ?? ()
(gdb) p/x $cs * 16 + $rip
$5 = 0xfe05b
(gdb) x/10i $cs * 16 + $rip
   0xfe05b:     cs cmpw $0xffc8,(%rsi)
   0xfe060:     (bad)
   0xfe061:     add    %cl,(%rdi)
   0xfe063:     test   %ecx,-0x10(%rax)
   0xfe066:     xor    %edx,%edx
   0xfe068:     mov    %edx,%ss
   0xfe06a:     mov    $0x7000,%sp
   0xfe06e:     add    %al,(%rax)
   0xfe070:     mov    $0xfc1c,%dx
   0xfe074:     (bad)
(gdb) b *0x7c00
Breakpoint 1 at 0x7c00
(gdb) c
Continuing.
Breakpoint 1, 0x0000000000007c00 in ?? ()
```

起初 pc 在`0xffff0`, 接着单步执行一步跳转到`0xfe05b`.接着打断点在`0x7c00`,运行.

可以看到 #image("images/2023-09-22-17-24-28.png")
但是 hello 还没有打印出来. 然后`layout asm`看看就是刚刚汇编代码.

`man qemu-system`:
`-S`: Do not start CPU at startup (you must type 'c' in the monitor).
`-s`: Shorthand for `-gdb tcp::1234`, i.e. open a gdbserver on TCP port 1234
(see the GDB usage chapter in the System Emulation Users Guide).

#tip("Tip")[
`0xffff0` 这个地址处的代码是一个跳转指令, 用于将控制权转移到实际的 BIOS 代码所在的内存地址.
]

==== 把调试步骤存储成文件

调过头了怎么办?存储成文件`init.gdb`

```gdb
= Kill process (QEMU) on gdb exits
define hook-quit
  kill
end

= Connect to remote
target remote localhost:1234
file a.out
wa *0x7c00
break *0x7c00
layout src
continue
```

```makefile
debug: mbr.img
  qemu-system-x86_64 -s -S $< &  = Run QEMU in background
  gdb -x init.gdb  = RTFM: gdb (1)
```

`make debug` 很丝滑地进入 `0x7c00` 的调试界面.然后`q`还能丝滑地退出 gdb.

==== 想知道 0x7c00 到底是谁加载的

`wa *0x7c00`, 然后`make debug`发现一开始只有两个字节被加载了, 剩下的都是 0.
然后单步执行几步之后才开始逐渐加载到内存.

```sh
Hardware watchpoint 1: *0x7c00

Old value = 0
New value = 13965
0x000000000000a718 in ?? ()
(gdb) x/10x 0x7c00
0x7c00 <_start>:        0x0000368d      0x00000000      0x00000000      0x00000000
0x7c10 <again+12>:      0x00000000      0x00000000      0x00000000      0x00000000
0x7c20 <msg+11>:        0x00000000      0x00000000
(gdb) si

Hardware watchpoint 1: *0x7c00

Old value = 13965
New value = 2081765005
0x000000000000a718 in ?? ()
0x000000000000a718 in ?? ()
0x000000000000a718 in ?? ()
0x000000000000a718 in ?? ()
(gdb) x/10x 0x7c00
0x7c00 <_start>:        0x7c15368d      0x0846048a      0x00000000      0x00000000
0x7c10 <again+12>:      0x00000000      0x00000000      0x00000000      0x00000000
0x7c20 <msg+11>:        0x00000000      0x00000000
```

=== 编译运行操作系统内核

am 的 makefile 让我们成功生成了直接在硬件上运行的程序.

#tip("Tip")[
CMake 背后做了很多东西, 不清楚细节很难调试. Makefile 可以把底层所有的细节都展现出来.
]

看源码很难, 看执行的过程就会容易一些.(状态机的描述和状态机的状态转移)

理解 Abstract machine 的 makefile

```sh
make -nB \
  | grep -ve '^\(\#\|echo\|mkdir\|make\)' \
  | sed "s#$AM_HOME#\$AM_HOME#g" \
  | sed "s#$PWD#.#g" \
  | vim -
```

接着`:%s/ /\r/g`
