#import "../template.typ": *
#pagebreak()
= Linux 操作系统

== Linux 操作系统

_25 Aug 1991, The Birthday of Linux > Hello, everybody out there using minix – I’m doing a (free) operating system (just a hobby, won’t be big and professional like gnu) for 386(486) AT clones. This has been brewing since April, and is starting to get ready. > —— Linus Torvalds (时年 21 岁)_

类似于 “我写了一个加强版的操作系统实验, 现在与大家分享”

- 发布在 comp.os.minix
  - 因为还依赖 Minix 的工具链 (从零开始做东西是不现实的)
  - 跑的都是 GNU 的程序: gcc, bash, ...
- 从此改变世界
  - “Just for fun: the story of an accidental revolutionary”

=== Minix?

- Minix: 完全用于教学的真实操作系统
  - by Andrew S. Tanenbaum

年轻人的第一个 “全功能” 操作系统

- Minix1 (1987): UNIXv7 兼容
  - Linus 实现 Linux 的起点
- #link("http://download.minix3.org/previous-versions/Intel-2.0.4/")[ Minix2 ] (1997):
  POSIX 兼容
  - 更加完备的系统, 书后附全部内核代码
- #link("http://minix3.org/")[ Minix3 ] (2006): POSIX/NetBSD 兼容
  - 一度是世界上应用最广的操作系统
    - Intel ME 人手一个

=== Tanenbaum/Linus "Linux is Obsolete" Debate

在 comp.os.minix 上关于 Linux 的讨论越来越多了

- Andrew Tanenbaum 做出了 “官方回应”
  - 觉得 “太落后”
- Linus 完全不服气
  - #link("https://www.oreilly.com/openbook/opensources/book/appa.html")[ 全文 ]
- Ken Thompson 也参与了讨论
  - 他已经在 ~10 年前获得了图灵奖……

=== 后来大家知道的故事

#image("images/2023-11-26-09-12-18.png")

- Linux 2.0 引入多处理器 (Big Kernel Lock, 内核不能并行)
- Linux 2.4 内核并行
- 2002 年才引入 Read-Copy-Update (RCU) 无锁同步
- 2003 年 Linux 2.6 发布, 随云计算开始起飞

=== Linux 的 “两面”

Kernel(一个可执行的二进制序列, 由硬件厂商加载到内存)

- 加载第一个进程
  - 相当于在操作系统中 “放置一个位于初始状态的状态机”
  - Single user model (高权限)
- 包含一些进程可操纵的操作系统对象
  - 例如`/dev/console`, 然后调试信息就会打印到控制台上 > linux 启动的时候,
    某一个时刻, 字体变了. 实际上就是在启动过程中, 对终端做了一些配置.
- 除此之外 “什么也没有”
  - Linux 变为一个中断 (系统调用) 处理程序

Linux Kernel 系统调用上的发行版和应用生态

- 系统工具 #link("https://www.gnu.org/software/coreutils/coreutils.html")[ coreutils ], [
  binutils ](https://www.gnu.org/software/binutils/), [ systemd
  ](https://systemd.io/), ... > systemd 才是进程树的根, 但是实际上系统的第一个进程`init`,
  并不是`systemd`, 为啥? 后面解答.
- 桌面系统 Gnome, xfce, Android
- 应用程序 file manager, vscode, ...

== 构建最小 Linux 系统

#image("images/2023-12-05-20-10-11.png")

=== 一个想法

我们能不能控制 Linux Kernel 加载的 “第一个状态机”?

- 计算机系统没有魔法
- 你能想到的事就能实现

挑战 ChatGPT:

- 我希望用 QEMU 在给定的 Linux 内核完成初始化后, 直接执行我自己编写的、静态链接的
  init 二进制文件. 我应该怎么做?

我们的真正壁垒

- 怎样问出好问题
- 怎样回答问出的问题

完全可以构建一个 “只有一个文件” 的 Linux 系统——Linux 系统会首先加载一个 “init
RAM Disk” 或 “init RAM FS”，在作系统最小初始化完成后，将控制权移交给
“第一个进程”。借助互联网或人工智能，你能够找到正确的文档，例如 The kernel’s
command-line parameters 描述了所有能传递给 Linux Kernel 的命令行选项。

恰恰是 UNIX “干净” 的设计 (完成初始化后将控制权移交给第一个进程) 使得 Linus
可以在可控的工程代价下实现 (相当完善的) POSIX
兼容，从而掀起一场操作系统的革命。时至今日，实现接口级的兼容已经是一件极为困难的工程问题，典型的例子是微软的工程师最终抛弃了
API 行为兼容的 Windows Subsystem for Linux 1.0，进而转向了虚拟机上运行的 Linux
内核。

> wsl1 的实现是使用 windows 自己的 api, 将 linux 内核的 api
解释执行(转义式的模拟). 行不通的, 操作系统的对象很复杂, 有很多历史包袱例如`man proc`可以看到很多很多的
specification, 只有完全实现这些, 才能正确地模拟.

为什么现在要做一个操作系统很难? 要么兼容 linux(但是很复杂),
不兼容的话生态又跟不上.

=== 启动 Linux

熟悉的 QEMU, 稍稍有些不熟悉的命令行选项

```makefile
= Requires statically linked busybox

INIT := /init

initramfs:
= Copy kernel and busybox from the host system
  @mkdir -p build/initramfs/bin
  sudo bash -c "cp /boot/vmlinuz build/ && chmod 666 build/vmlinuz"
  cp init build/initramfs/
  cp $(shell which busybox) build/initramfs/bin/

= Pack build/initramfs as gzipped cpio archive
  cd build/initramfs && \
    find . -print0 \
    | cpio --null -ov --format=newc \
    | gzip -9 > ../initramfs.cpio.gz

run:
= Run QEMU with the installed kernel and generated initramfs
  qemu-system-x86_64 \
    -serial mon:stdio \
    -kernel build/vmlinuz \
    -initrd build/initramfs.cpio.gz \
    -machine accel=kvm:tcg \
    -append "console=ttyS0 quiet rdinit=$(INIT)"

clean:
  rm -rf build

.PHONY: initramfs run clean
```

1. `qemu-system-x86_64`: 这是 QEMU 的可执行程序，针对 x86_64（即 64 位 Intel 和 AMD
  处理器）架构的系统。
2. `-serial mon:stdio`:
  这个选项将虚拟机的串行端口输出重定向到当前的标准输入输出设备。`mon:stdio` 表示监控器（QEMU
  的交互式命令行界面）通过标准 I/O 设备进行交互。
3. `-kernel build/vmlinuz`: 指定虚拟机使用的内核映像文件。在这里，`build/vmlinuz` 是内核映像文件的路径。
4. `-initrd build/initramfs.cpio.gz`: 指定初始化 RAM 磁盘的文件，即 initrd。`build/initramfs.cpio.gz` 是
  initrd
  文件的路径，它通常包含了启动操作系统所需的最小系统，并在根文件系统挂载之前被加载。
5. `-machine accel=kvm:tcg`: 这个选项指定虚拟机使用的加速技术。`accel=kvm` 表示如果可用，应使用基于内核的虚拟机（KVM）进行硬件加速。如果
  KVM 不可用，将回退到 TCG（Tiny Code Generator），后者是 QEMU 的纯软件模拟。
6. `-append "console=ttyS0 quiet rdinit=$(INIT)"`:
  这个选项用于向内核传递命令行参数。`console=ttyS0` 告诉内核将控制台输出重定向到第一个串行端口（ttyS0）。`quiet` 参数减少了启动时的日志输出，使得输出更加简洁。`rdinit=$(INIT)` 设置了
  init 程序的路径，这里使用了 shell 变量 `$(INIT)`，它需要在执行 QEMU
  命令之前定义。

==== minimal 作为 init

```sh
❯ gcc -c minimal.S && ld minimal.o
❯ mv a.out minimal
❯ ls
build  init  Makefile  minimal  minimal.o  minimal.S
❯ ./minimal
Hello, OS World
❯ mv minimal build/initramfs
```

然后我们可以把上面 Makefile 里面的 init 换成 minimal
`INIT := /minimal`

`minimal`运行之后销毁, 就没有进程了, 会发生什么?

```
[    0.884772] Run /minimal as init process
Hello, OS World
[    0.900809] Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100
[    0.901147] CPU: 0 PID: 1 Comm: minimal Not tainted 5.17.3 #1
[    0.901463] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS 1.15.0-1 04/01/2014
[    0.901753] Call Trace:
[    0.902268]  <TASK>
[    0.903735]  dump_stack_lvl+0x34/0x44
[    0.904016]  panic+0xef/0x2a6
[    0.904106]  do_exit.cold+0x15/0x45
[    0.904217]  __x64_sys_exit+0x12/0x20
[    0.904312]  do_syscall_64+0x3b/0x90
[    0.904396]  entry_SYSCALL_64_after_hwframe+0x44/0xae
[    0.904767] RIP: 0033:0x40102e
[    0.905134] Code: 00 00 00 48 c7 c7 01 00 00 00 48 c7 c6 2e 10 40 00 48 c7 c2 1c 00 00 00 0f 05 4
8 c7 c0 3c 00 00 00 48 c7 c7 01 00 00 00 0f 05 <1b> 5b 30 31 3b 33 31 6d 48 65 6c 6c 6f 2c 20 4f 53
20 57 6f 72 6c
[    0.905637] RSP: 002b:00007ffd1dff82b0 EFLAGS: 00000202 ORIG_RAX: 000000000000003c
[    0.905999] RAX: ffffffffffffffda RBX: 0000000000000000 RCX: 000000000040102e
[    0.906218] RDX: 000000000000001c RSI: 000000000040102e RDI: 0000000000000001
[    0.906446] RBP: 0000000000000000 R08: 0000000000000000 R09: 0000000000000000
[    0.906599] R10: 0000000000000000 R11: 0000000000000202 R12: 0000000000000000
[    0.906870] R13: 0000000000000000 R14: 0000000000000000 R15: 0000000000000000
[    0.907165]  </TASK>
[    0.907618] Kernel Offset: 0x2a400000 from 0xffffffff81000000 (relocation range: 0xffffffff800000
00-0xffffffffbfffffff)
[    0.908150] ---[ end Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100 ]---
```

给出 panic, 并且打印调用栈以及寄存器信息.

==== busybox

本质上和 minimal 没啥区别, 就是一个静态链接的二进制文件.

```sh
❯ file $(which busybox)
/usr/bin/busybox: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=36c64fc4707a00db11657009501f026401385933, for GNU/Linux 3.2.0, stripped
```

用法:

```sh
❯ busybox ls
Makefile   build      init       minimal    minimal.S  minimal.o  vmlinuz
❯ busybox sh
BusyBox v1.30.1 (Ubuntu 1:1.30.1-7ubuntu3) built-in shell (ash)
Enter 'help' for a list of built-in commands.
~/cs_learning/nju_os/demo/16_demo/linux $ exit
```

busybox 就是一个 unix 常用工具的打包.

> toybox 比 busybox 更小.

可以看看 busybox 的代码, 可以看到一些系统工具的简化实现. 从中能学到不少技巧.
多读源码!

==== `init`

```sh
#!/bin/busybox sh

= initrd, only busybox and /init
BB=/bin/busybox

= (1) Print something and exit
= $BB echo -e "\033[31mHello, OS World\033[0m"
= $BB poweroff -f

= (2) Run a shell on the init console
$BB sh

= (3) Rock'n Roll!
for cmd in $($BB --list); do
  $BB ln -s $BB /bin/$cmd
done
mkdir -p /tmp
mkdir -p /proc && mount -t proc  none /proc
mkdir -p /sys  && mount -t sysfs none /sys
mknod /dev/tty c 4 1
setsid /bin/sh /dev/tty 2>&1
```

`make && make run`之后得到一个就可以运行 busybox 里的 shell.

```
/ = /bin/busybox find /
/
/init
/bin
/bin/busybox
/root
/dev
/dev/console
```

如何把终端移动到真正的 qemu 的机器里面呢? 先终止原终端里面 busybox 的 sh.
接着就会执行后面的"Rock'n Roll"...最后的 setsid 就可以在机器上启动终端.

==== `cpio`

`cpio` 是一个标准的 Unix
工具，用于创建、提取和管理归档文件。归档文件是将多个文件或目录合并成单个文件的一种方式，这在备份和分发文件时非常有用。`cpio` 支持多种归档格式，包括它自己的格式以及
tar 格式。

`cpio` 的名称来源于“copy in and copy
out”的缩写，其设计用于将文件从一个位置复制到另一个位置，可以通过管道与其他命令结合使用，特别是与`find`命令一起用来选择要归档的文件。

在 Makefile 上下文中，`cpio` 用于创建一个新的 initramfs 映像。initramfs（初始
RAM
文件系统）是一个临时的根文件系统，由内核在引导过程中挂载，用于预加载必要的驱动程序和其他资源，直到实际的根文件系统被挂载。

以下是`cpio` 命令的一个例子，该命令通常与 `find` 命令一起用于创建 initramfs：

```bash
find . -print0 | cpio --null -ov --format=newc | gzip -9 > initramfs.cpio.gz
```

这个命令执行的操作如下：

- `find . -print0`：查找当前目录（`.`）下的所有文件和目录，并以空字符（null）终止每个条目，这样即使文件名中包含空格或换行符，`cpio` 也能正确处理。
- `cpio --null -ov --format=newc`：`cpio` 读取来自 `find` 命令的输入，`--null` 表示输入的文件名以空字符终止，`-o` 表示创建归档（copy
  out），`-v` 表示详细模式，`--format=newc` 指定了新的 SVR4（System V Release
  4）cpio 格式。
- `gzip -9`：将 `cpio` 创建的归档压缩为 gzip 格式，`-9` 表示最大压缩率。
- `> initramfs.cpio.gz`：将压缩后的数据重定向到文件 `initramfs.cpio.gz`。

创建完成后，`initramfs.cpio.gz` 就可以被内核在启动时作为 initramfs 使用。

==== initramfs

Initramfs（initial RAM filesystem）是一个在 Linux
系统启动时由内核加载的临时根文件系统。它被存储在内存中，并在系统启动过程的早期阶段被用来准备真正的根文件系统，比如执行硬件检测、加载必要的驱动程序和其他预启动任务。一旦这些任务完成，内核就会切换到真正的根文件系统上，通常是位于硬盘或者其他永久存储设备上。

===== 为什么需要 Initramfs？

在现代 Linux
系统中，许多硬件驱动和文件系统支持都是以模块的形式存在的，这意味着它们不是内核的一部分，而是在需要时加载。在某些情况下，根文件系统可能位于需要这些模块才能访问的设备上。因此，系统启动时需要一个预先加载这些模块的机制，以便内核能够访问并挂载真正的根文件系统。

===== Initramfs 的内容

Initramfs 通常包含以下内容：

- *必要的可执行程序和库*：这些通常包括用于挂载真正的根文件系统的工具，比如`mount`命令。
- *模块*：如果内核需要额外的模块来访问根文件系统（例如，特定的文件系统或 RAID
  控制器驱动），这些模块可以包含在 initramfs 中。
- *初始化脚本*：一个名为`init`的脚本负责协调启动流程，包括加载驱动程序、挂载真正的根文件系统等。

=== 创建和使用 Initramfs

在 Linux 系统中，initramfs 通常是使用`cpio`归档格式创建的，然后被 gzip
压缩。内核在启动时会解压缩并加载 initramfs 到内存中。

创建 initramfs
的过程通常由发行版的构建脚本自动完成，但也可以手动创建。一旦创建了
initramfs，它可以通过引导加载器（如 GRUB）的配置传递给内核。例如，GRUB
配置文件中的一个条目可能包含以下行：

```plaintext
linux /boot/vmlinuz-linux root=/dev/sda1
initrd /boot/initramfs-linux.img
```

这里的`initrd`指令告诉 GRUB 加载`/boot/initramfs-linux.img`作为 initramfs。

===== 切换到真正的根文件系统

启动过程中，initramfs 的`init`脚本会执行必要的步骤来准备真正的根文件系统。这包括加载任何必要的驱动程序、设置网络（如果需要）以及挂载根文件系统。一旦根文件系统被挂载，initramfs
中的 init 脚本会用`exec`命令替换自己为根文件系统上的`/sbin/init`程序（或者任何指定的
init 系统），这个程序接下来将接管系统的其余启动过程。

在切换到真正的根文件系统之后，initramfs
所占用的内存通常会被释放，因为它在系统运行时不再需要。这个过程称为“切换根”（switch_root）。

== initrd 之后

=== initrd: 并不是我们实际看到的 Linux

只是一个内存里的小文件系统

- 我们 “看到” 的都是被 init 创造出来的
  - 加载剩余必要的驱动程序, 例如网卡
  - 根据 fstab 中的信息挂载文件系统, 例如网络驱动器
  - 将根文件系统和控制权移交给另一个程序, 例如 systemd

==== Questions

1. 为什么 systemd 是 pstree 的根?
2. 在系统刚开始启动的时候, 只有一个`initramfs`在内存, 很小,
  仅供系统的初始化使用.这个实话系统里面还没有磁盘, 那磁盘里的那么多工具都去哪儿了?

=== 构建一个 “真正” 的应用世界

系统的启动分为两个阶段, 在`initramfs`之后(系统的一级启动), 必须有一个应用调用`pivot_root`(系统的二级启动)

```c
int pivot_root(const char *new_root, const char *put_old);
```

`pivot_root()` changes the root mount in the mount namespace of the calling
process. More precisely, it moves the root mount to the directory put_old and
makes new_root the new root mount. The calling process must have the
CAP_SYS_ADMIN capability in the user namespace that owns the caller's mount
namespace.

- 执行 /usr/sbin (Kernel 的 init 选项)
  - 看一看系统里的文件是什么吧
  - 计算机系统没有魔法 (一切都有合适的解释)

#image("images/2023-12-05-20-09-17.png")

> 为啥在安装更新软件的时候, 在 initramfs 的时候会卡很久,
因为里面包含了很多系统的对象, 更新的时候要重新打包.

```sh
❯ ls -l /usr/sbin/init
lrwxrwxrwx 1 root root 20 Sep 20 00:57 /usr/sbin/init -> /lib/systemd/systemd
```

这个时候`systemd`就接管了.

=== 例子: #link("https://zhuanlan.zhihu.com/p/619237809")[ NOILinux Lite ]

在 init 时多做一些事

```sh
export PATH=/bin
busybox mknod /dev/sda b 8 0
busybox mkdir -p /newroot
busybox mount -t ext2 /dev/sda /newroot
exec busybox switch_root /newroot/ /etc/init
```

- pivot_root 之后才加载网卡驱动、配置 IP
  - 这些都是 systemd 的工作
  - (你会留意到 tty 字体变了)
- 之后 initramfs 就功成身退, 资源释放
