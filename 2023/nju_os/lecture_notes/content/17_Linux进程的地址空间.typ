#import "../template.typ": *
#pagebreak()

= Linux 进程的地址空间

== Linux 进程的地址空间

两个很基本 (但也很困难) 的问题

以下程序的 (可能) 输出是什么?

```c
printf("%p\n", main);
```

何种指针访问不会引发 segmentation fault?

```c
char *p = random();
*p; // 什么时候访问合法?
```

=== 查看进程的地址空间

pmap (1) - report memory of a process

- Claim: pmap 是通过访问 procfs (/proc/) 实现的
- 如何验证这一点?`strace`

查看进程的地址空间

- 等程序运行起来后 (gdb)，使用 `pmap` 命令查看地址空间
- 地址空间是若干连续的 “内存段”
  - “段” 的内存可以根据权限访问
  - 不在段内/违反权限的内存访问 触发 SIGSEGV

gpt 回答:what kind of tools can help me print out the address space of a linux
process?

- pmap
- cat /proc/[pid]/maps
- gdb
- readelf
- objdump
- lsof
- nm

==== minimal

```sh
❯ gcc -c minimal.S && ld minimal.o -o minimal && ./minimal
Hello, OS World
```

立刻执行完毕, 那应该怎么直接看地址空间呢?

1. 可以找个不会终止的程序, 例如 shell
2. 在 minimal 里面加个死讯和
3. gdb 来暂停, 在暂停的时候查看地址空间

```
starti -> 使得程序进入execve加载程序后的初始状态
layout asm -> 显示汇编
info inferiors-> 得到pid
!pmap pid
```

> `!`可以在 gdb 里面执行命令, 就像 vim 里面一样

```
(gdb) !pmap 6726
6726:   .../minimal
0000000000400000      4K r---- minimal
0000000000401000      4K r-x-- minimal
00007ffff7ff9000     16K r----   [ anon ]
00007ffff7ffd000      8K r-x--   [ anon ]
00007ffffffde000    132K rw---   [ stack ]
 total              164K
```

#image("images/2023-12-06-13-18-58.png")

这就解答了一开始的问题, 即哪些地址可以访问.

使用`cat /proc/[pid]/maps`

```
(gdb) !cat /proc/6726/maps
00400000-00401000 r--p 00000000 08:20 220712                             .../minimal
00401000-00402000 r-xp 00001000 08:20 220712                             .../minimal
7ffff7ff9000-7ffff7ffd000 r--p 00000000 00:00 0                          [vvar]
7ffff7ffd000-7ffff7fff000 r-xp 00000000 00:00 0                          [vdso]
7ffffffde000-7ffffffff000 rw-p 00000000 00:00 0                          [stack]
```

`pmap`是通过`proc/[pid]/maps`实现的, 怎么证明? `strace pmap [pid]`,
可以发现里面有一段

```
openat(AT_FDCWD, "/proc/6726/maps", O_RDONLY) = 3
newfstatat(3, "", {st_mode=S_IFREG|0444, st_size=0, ...}, AT_EMPTY_PATH) = 0
read(3, "00400000-00401000 r--p 00000000 "..., 1024) = 515
write(1, "0000000000400000      4K r---- m"..., 390000000000400000      4K r---- minimal
) = 39
write(1, "0000000000401000      4K r-x-- m"..., 390000000000401000      4K r-x-- minimal
) = 39
write(1, "00007ffff7ff9000     16K r----  "..., 4200007ffff7ff9000     16K r----   [ anon ]
) = 42
write(1, "00007ffff7ffd000      8K r-x--  "..., 4200007ffff7ffd000      8K r-x--   [ anon ]
) = 42
write(1, "00007ffffffde000    132K rw---  "..., 4300007ffffffde000    132K rw---   [ stack ]
) = 43
read(3, "", 1024)                       = 0
close(3)                                = 0
```

`man 5 proc`手册获取更多信息.

==== hello

`gcc hello.c -static -o hello && gdb hello`

```gdb
(gdb) starti
Starting program: .../hello

Program stopped.
0x0000000000401650 in _start ()
(gdb) info inferiors
  Num  Description       Connection           Executable
* 1    process 8303      1 (native)           .../hello
(gdb) !pmap 8303
8303:   .../hello
0000000000400000      4K r---- hello
0000000000401000    604K r-x-- hello
0000000000498000    164K r---- hello
00000000004c1000     28K rw--- hello
00000000004c8000     20K rw---   [ anon ]
00007ffff7ff9000     16K r----   [ anon ]
00007ffff7ffd000      8K r-x--   [ anon ]
00007ffffffde000    132K rw---   [ stack ]
 total              976K
(gdb) !cat /proc/8303/maps
00400000-00401000 r--p 00000000 08:20 220725           .../hello
00401000-00498000 r-xp 00001000 08:20 220725           .../hello
00498000-004c1000 r--p 00098000 08:20 220725           .../hello
004c1000-004c8000 rw-p 000c0000 08:20 220725           .../hello
004c8000-004cd000 rw-p 00000000 00:00 0                [heap]
7ffff7ff9000-7ffff7ffd000 r--p 00000000 00:00 0        [vvar]
7ffff7ffd000-7ffff7fff000 r-xp 00000000 00:00 0        [vdso]
7ffffffde000-7ffffffff000 rw-p 00000000 00:00 0        [stack]
```

猜测:

- 第一段是 ro 的 4KB -> elf 头
- 第二段 rx -> code
- 第三段 ro -> rodata
- 第四段 rw -> data

如何验证呢?

=== 操作系统提供查看进程地址空间的机制

RTFM: /proc/[pid]/maps (man 5 proc)

- 进程地址空间中的每一段
  - 地址 (范围) 和权限 (rwxsp)
  - 对应的文件: offset, dev, inode, pathname
    - TFM 里有更详细的解释
  - 和 readelf (-l) 里的信息互相验证
- 好的本能：做一些代码上的调整，观察 address space 的变化
  - 堆 (bss) 内存的大小
  - 栈上的大数组 v.s. memory error

在 hello.c 里面增加:

```c
#define MB * 1048576
char mem[64 MB];
```

`gcc hello.c -static -o hello && gdb hello`

```gdb
21197:   .../hello
0000000000400000      4K r---- hello
0000000000401000    604K r-x-- hello
0000000000498000    164K r---- hello
00000000004c1000     28K rw--- hello
00000000004c8000  65556K rw---   [ anon ]
00007ffff7ff9000     16K r----   [ anon ]
00007ffff7ffd000      8K r-x--   [ anon ]
00007ffffffde000    132K rw---   [ stack ]
 total            66512K
(gdb) !cat /proc/21197/maps
00400000-00401000         r--p 00000000 08:20 220725      .../hello
00401000-00498000         r-xp 00001000 08:20 220725      .../hello
00498000-004c1000         r--p 00098000 08:20 220725      .../hello
004c1000-004c8000         rw-p 000c0000 08:20 220725      .../hello
004c8000-044cd000         rw-p 00000000 00:00 0           [heap]
7ffff7ff9000-7ffff7ffd000 r--p 00000000 00:00 0           [vvar]
7ffff7ffd000-7ffff7fff000 r-xp 00000000 00:00 0           [vdso]
7ffffffde000-7ffffffff000 rw-p 00000000 00:00 0           [stack]
```

=== 更完整的地址空间映象

如果改成动态链接呢?

```gdb
21592:   .../hello
0000555555554000      4K r---- hello
0000555555555000      4K r-x-- hello
0000555555556000      4K r---- hello
0000555555557000      8K rw--- hello
0000555555559000  65536K rw---   [ anon ]
00007ffff7fbd000     16K r----   [ anon ]
00007ffff7fc1000      8K r-x--   [ anon ]
00007ffff7fc3000      8K r---- ld-linux-x86-64.so.2
00007ffff7fc5000    168K r-x-- ld-linux-x86-64.so.2
00007ffff7fef000     44K r---- ld-linux-x86-64.so.2
00007ffff7ffb000     16K rw--- ld-linux-x86-64.so.2
00007ffffffde000    132K rw---   [ stack ]
 total            65948K
(gdb) bt
#0  0x00007ffff7fe3290 in _start () from /lib64/ld-linux-x86-64.so.2
#1  0x0000000000000001 in ?? ()
#2  0x00007fffffffe121 in ?? ()
#3  0x0000000000000000 in ?? ()
```

在这个进程状态机被创建的一瞬间, 还没有`printf`, 而 pc 位于`/lib64/ld-linux-x86-64.so.2`.
静态链接初始化之后, pc 是 elf 文件里标记的 entry, 而动态链接实际上有个
interpreter, 这个解释器就是`/lib64/ld-linux-x86-64.so.2`.(用另外一个程序来执行当前的程序.所以他就是一个加载器
loader.)

在 main 上面打个断点再 continue 查看.

```gdb
(gdb) !pmap 22293
22293:   .../hello
0000555555554000      4K r---- hello
0000555555555000      4K r-x-- hello
0000555555556000      4K r---- hello
0000555555557000      4K r---- hello
0000555555558000      4K rw--- hello
0000555555559000  65536K rw---   [ anon ]
00007ffff7d80000     12K rw---   [ anon ]
00007ffff7d83000    160K r---- libc.so.6
00007ffff7dab000   1620K r-x-- libc.so.6
00007ffff7f40000    352K r---- libc.so.6
00007ffff7f98000     16K r---- libc.so.6
00007ffff7f9c000      8K rw--- libc.so.6
00007ffff7f9e000     52K rw---   [ anon ]
00007ffff7fbb000      8K rw---   [ anon ]
00007ffff7fbd000     16K r----   [ anon ]
00007ffff7fc1000      8K r-x--   [ anon ]
00007ffff7fc3000      8K r---- ld-linux-x86-64.so.2
00007ffff7fc5000    168K r-x-- ld-linux-x86-64.so.2
00007ffff7fef000     44K r---- ld-linux-x86-64.so.2
00007ffff7ffb000      8K r---- ld-linux-x86-64.so.2
00007ffff7ffd000      8K rw--- ld-linux-x86-64.so.2
00007ffffffde000    132K rw---   [ stack ]
 total            68176K
```

libc 归来! 使用 strace
查看动态链接和静态链接的程序发现两者的差距很大.静态链接很快就开始执行代码,
但是动态链接有很多操作, 这很多操作都是为了把需要的库搬到地址空间.

更改 hello.c:

```c

```

```gdb
(gdb) !pmap 22909
22909:   .../hello
0000555555554000      4K r---- hello
0000555555555000      4K r-x-- hello
0000555555556000      4K r---- hello
0000555555557000      8K rw--- hello
00007ffff7fbd000     16K r----   [ anon ]
00007ffff7fc1000      8K r-x--   [ anon ]
00007ffff7fc3000      8K r---- ld-linux-x86-64.so.2
00007ffff7fc5000    168K r-x-- ld-linux-x86-64.so.2
00007ffff7fef000     44K r---- ld-linux-x86-64.so.2
00007ffff7ffb000     16K rw--- ld-linux-x86-64.so.2
00007ffffffde000    132K rw---   [ stack ]
 total              412K
(gdb) !cat /proc/22909/maps
555555554000-555555555000 r--p 00000000 08:20 220726   .../hello
555555555000-555555556000 r-xp 00001000 08:20 220726   .../hello
555555556000-555555557000 r--p 00002000 08:20 220726   .../hello
555555557000-555555559000 rw-p 00002000 08:20 220726   .../hello
7ffff7fbd000-7ffff7fc1000 r--p 00000000 00:00 0        [vvar]
7ffff7fc1000-7ffff7fc3000 r-xp 00000000 00:00 0        [vdso]
7ffff7fc3000-7ffff7fc5000 r--p 00000000 08:20 59431    /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7ffff7fc5000-7ffff7fef000 r-xp 00002000 08:20 59431    /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7ffff7fef000-7ffff7ffa000 r--p 0002c000 08:20 59431    /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7ffff7ffb000-7ffff7fff000 rw-p 00037000 08:20 59431    /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7ffffffde000-7ffffffff000 rw-p 00000000 00:00 0        [stack]
```

问 gpt `vvar`和`vdso`是什么?

In a Linux process memory space, `vvar` and `vdso` are two special regions that
serve important system-level functions:

1. vvar: `vvar` stands for "virtual dynamic shared object section." It is a small
  region of memory reserved for the kernel to store certain variables that are
  used by the process but need to be kept separate from the process's own data.
  These variables include the thread-local storage (TLS) pointer, which points to
  the thread-specific data area (TSD) used by the thread-local storage mechanism.
  The `vvar` region is mapped into the process's memory space when the process is
  started, and its address is fixed at `0xffffffffff600000`. This address is
  outside the normal user-space address range and is reserved for kernel use.
  - The current time(`time_t`)
  - The page size of the system
  - The process's CPU clock frequency
  - ....
2. vdso: `vdso` stands for "virtual dynamic shared object." It is another special
  region of memory that contains a set of system call wrappers implemented in
  userspace, allowing user applications to directly access some frequently used
  kernel functions without having to switch to kernel mode via the `syscall` instruction.
  This method is faster and more efficient than traditional system call
  invocation, as it avoids expensive context switches between user and kernel
  modes. The `vdso` region is also mapped into the process's memory space at a
  fixed address (`0x7fffb5f77000` on x86-64 architectures), and it is loaded into
  the process's memory by the kernel during process startup. The contents of `vdso` are
  updated dynamically by the kernel to reflect changes in the kernel's
  implementation of system calls, so they always match the running kernel version.
  - `gettimeofday()`

> 即不进入内核的系统调用.

=== RTFM (5 proc): 我们发现的宝藏

vdso (7): Virtual system calls: 只读的系统调用也许可以不陷入内核执行。

无需陷入内核的系统调用

- 例子: `time (2)`
  - 时间：内核维护秒级的时间 (所有进程映射同一个页面)
- 例子: `gettimeofday (2)`
  - [ RTFSC
    ](https://elixir.bootlin.com/linux/latest/source/lib/vdso/gettimeofday.c#L49)
    (非常聪明的实现)
- 更多的例子：问 GPT 吧！
  - 计算机系统里没有魔法！我们理解了进程地址空间的全部！

可以调试一下, 了解更多细节(如何实现不进入内核的系统调用). 例如可以看到`vdso`地址附近都是系统调用:
#image("images/2023-12-06-16-39-15.png")

== 进程地址空间管理

=== 地址空间 = 带访问权限的内存段

操作系统应该提供一个修改进程地址空间的系统调用

```c
// 映射
// 增加一段
void *mmap(void *addr, size_t length, int prot, int flags,
            int fd, off_t offset);
// 删除一段
int munmap(void *addr, size_t length);
// 修改映射权限
int mprotect(void *addr, size_t length, int prot);
```

本质：在状态机状态上增加/删除/修改一段可访问的内存

- `mmap`: 可以用来申请内存 (`MAP_ANONYMOUS`)，也可以把文件 “搬到” 进程地址空间中

=== 把文件映射到进程地址空间?

Everything is a (file|descriptor); file is a descriptor.

文件描述符是操作系统对象的指针. 那`mmap`就可以把文件的实在内容搬到内存里面取.
在一定的限度下, 文件里的内容和内存里的数据是可以同步的.

它们的确好像没有什么区别

- 文件 = 字节序列 (操作系统中的对象)
- 内存 = 字节序列
- 操作系统允许映射好像挺合理的……
  - 带来了很大的方便
  - ELF loader 用 `mmap` 非常容易实现
    - 解析出要加载哪部分到内存，直接 `mmap` 就完了
    - 我们的 loader 的确是这么做的 (strace)

=== 使用 mmap

==== Example 1: 申请大量内存空间

```c
#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

#define GiB * (1024LL * 1024 * 1024)

int main() {
    volatile uint8_t *p = mmap(NULL, 8 GiB, PROT_READ | PROT_WRITE,
                               MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
    printf("mmap: %lx\n", (uintptr_t)p);
    if ((intptr_t)p == -1) {
        perror("cannot map");
        exit(1);
    }
    *(p + 2 GiB) = 1;
    *(p + 4 GiB) = 2;
    *(p + 7 GiB) = 3;
    printf("Read get: %d\n", *(p + 4 GiB));
    printf("Read get: %d\n", *(p + 6 GiB));
    printf("Read get: %d\n", *(p + 7 GiB));
}
```

- 瞬间完成内存分配
  - 只是在操作系统里面*标记*分配的连续的 8G 内存是属于该进程的.
    并没有实际分配.第一次进行内存访问的时候, 处理器会发生一个异常(内存不存在,
    因为没有分配.), 异常交给 OS 执行, 由于之前`mmap`已经声明了, 于是可以分配 1 page
    的内存.然后进程就可以继续运行了. > 用多少内存, 就分配多少内存.
  - `mmap`/`munmap` 为 `malloc`/`free` 提供了机制
  - `libc` 的大 `malloc` 会直接调用一次 `mmap` 实现
- 不妨 `strace`/`gdb` 看一下

==== Example 2: Everything is a file

- 映射大文件, 只访问其中的一小部分

```c
with open('/dev/sda', 'rb') as fp:
    mm = mmap.mmap(fp.fileno(),
                   prot=mmap.PROT_READ, length=128 << 30)
    hexdump.hexdump(mm[:512])
```

映射磁盘的 128G 内存, 把前 512 字节打印出来.可以看到末尾的`55AA`说明是个可启动的磁盘.

=== Memory-Mapped File: 一致性

但我们好像带来了一些问题……

- 如果把页面映射到文件
  - 修改什么时候生效?
    - 立即生效：那会造成巨大量的磁盘 I/O
    - `unmap` (进程终止) 时生效：好像又太迟了……
- 若干个映射到同一个文件的进程?
  - 共享一份内存?
  - 各自有本地的副本?

请查阅手册，看看操作系统是如何规定这些操作的行为的

- 例如阅读 `msync` (2)
- 这才是操作系统真正的复杂性

== 🌶️ 入侵进程地址空间

=== Hacking Address Spaces

进程 (M,R 状态机) 在 “无情执行指令机器” 上执行

- 状态机是一个封闭世界
- 但如果允许一个进程对其他进程的地址空间有访问权?
  - 意味着可以任意改变另一个程序的行为
    - 听起来就很 cool

一些入侵进程地址空间的例子

- 调试器 (gdb)
  - gdb 可以任意观测和修改程序的状态
- Profiler (perf)
  - 合理的需求，操作系统就必须支持 → Ask GPT!

=== 入侵进程地址空间 (0): 金手指

如果我们能直接物理劫持内存，不就都解决了吗?

- 听起来很离谱，但 “卡带机” 时代的确可以做到！

#image("images/2023-12-06-18-50-20.png")

> ROM 只能 load, RAM 可以 load/store

Game Genie: 一个 Look-up Table (LUT)

- 当 CPU 读地址 a 时读到 x，则替换为 y
  - [ NES Game Genie Technical Notes
    ](https://tuxnes.sourceforge.net/gamegenie.html) ([ 专利
    ](https://patents.google.com/patent/EP0402067A2/en), [ How did it work?
    ](https://www.howtogeek.com/706248/what-was-the-game-genie-cheat-device-and-how-did-it-work/))
  - 今天我们有 [ Intel Processor Trace
    ](https://perf.wiki.kernel.org/index.php/Perf_tools_support_for_Intel®\_Processor_Trace)

> 物理外挂, 简单稳定有效.

=== 入侵进程地址空间 (1): 金山游侠

在进程的内存中找到代表 “金钱”, “生命” 的重要属性并且改掉

包含非常贴心的 “游戏内呼叫” 功能

- 它就是游戏的 (阉割版) “调试器”
- 我们也可以在 Linux 中实现它 (man 5 proc)

> 第一次扫描内存里的金钱数, 会有许多匹配. 减少/增加了钱数, 再扫描相应的钱数, 就可以直接找到相应的存储金钱的地址.

=== 入侵进程地址空间 (2): 按键精灵

大量重复固定的任务 (例如 2 秒 17 枪)

这个简单，就是给进程发送键盘/鼠标事件

- 做个驱动 (可编程键盘/鼠标)
- 利用操作系统/窗口管理器提供的 API
  - #link("https://github.com/jordansissel/xdotool")[ xdotool ] (我们用这玩意测试 vscode
    的插件)
  - #link("https://www.kernel.org/doc/html/latest/input/input.html")[ evdev ]
    (按键显示脚本；主播常用)

=== 入侵进程地址空间 (3): 变速齿轮

调整游戏的逻辑更新速度

比如某[ 神秘公司
](https://baike.baidu.com/item/台湾天堂鸟资讯有限公司/8443017)慢到难以忍受的跑图和战斗

本质：程序是状态机
#image("images/2023-12-06-19-04-32.png")

- 除了 syscall，是不能感知时间的
- 只要 “劫持” 和时间相关的 syscall，就能改变程序对时间的认识
  - 原则上程序仍然可以用间接信息 “感知” 的 (就想表调慢了一样)

=== 定制游戏外挂

“劫持代码” 的本质是 debugger 行为

游戏也是程序，也是状态机 外挂就是 “为这个游戏专门设计的 gdb” 修改 API 调用的值

```c
set_alarm(1000 / FPS); // 希望改成 100 / FPS
```

锁定生命值

- 最简单的生命值锁定是 spin modify
- 还是可能出现 hp < 0 的判定 (尤其是一刀秒的时候)

```c
hp -= damage; // 希望 “消除” 此次修改
if (hp < 0) game_over();
```

=== 代码注入 (hooking)

用一段代码 “勾住” 程序的执行

技术，无论是计算机系统、编程语言还是人工智能，都是给人类带来福祉的。但越强大的技术就也有越 “负面” 的用途。使用游戏外挂破坏游戏的平衡性、利用漏洞入侵计算机系统，或是用任何技术占他人之先、损害他人的利益，都是一件可耻的事情。
