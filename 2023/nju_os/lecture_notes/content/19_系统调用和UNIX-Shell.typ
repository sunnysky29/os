#import "../template.typ": *
#pagebreak()
= 系统调用和 UNIX Shell

#image("images/2023-12-06-20-05-05.png")

```sh
❯ file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=897f49cafa98c11d63e619e7e40352f
855249c13, for GNU/Linux 3.2.0, stripped
❯ ldd
ldd: missing file arguments
Try `ldd --help' for more information.
❯ ldd /bin/ls
        linux-vdso.so.1 (0x00007ffe6d8c8000)
        libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007fb971cd2000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb971aaa000)
        libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fb971a13000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fb971d34000)
❯ ldd /bin/busybox
        not a dynamic executable
```

== (UNIX) Shell

=== 为用户封装操作系统 API

我们需要一个 “用户能直接操作” 的程序管理操作系统对象。

需求分析

- 我们每天都拿操作系统做什么？
  - 启动应用程序
    - 即时通信
    - 影音娱乐
    - ...
- 我们需要一个程序能协调多个应用程序

=== 为用户封装操作系统 API

#image("images/2023-12-06-20-05-20.png")
Shell: Kernel 的 “外壳”

- “与人类直接交互的第一个程序”

=== The UNIX Shell

“终端” 时代的伟大设计; “Command-line interface” (CLI) 的巅峰

*Shell 是一门 “把用户指令翻译成系统调用” 的编程语言*

- 原来我们一直在编程
  - 直到有了 Graphical Shell (GUI)
  - Windows, Gnome, Symbian, Android

=== 脾气有点小古怪的 UNIX 世界

“Unix is user-friendly; it's just choosy about who its friends are.”

但如果把 shell 理解成编程语言，“不好用” 好像也没什么毛病了 你见过哪个编程语言 “好用” 的？

#tip("Tip")[
(UNIX 世界有很多历史遗留约定), 在当时那个很紧凑的计算力下, 做了一个既方便编译器实现, 又比较好用的妥协.
]

=== The Shell Programming Language

基于文本替换的快速工作流搭建

- 重定向: `cmd > file < file 2> /dev/null`
- 顺序结构: `cmd1; cmd2, cmd1 && cmd2, cmd1 || cmd2`
- 管道: `cmd1 | cmd2`
- 预处理: `$()`, `<()`
- 变量/环境变量、控制流……

Job control

- 类比窗口管理器里的 “叉”、“最小化”
- jobs, fg, bg, wait
- (今天的 GUI 并没有比 CLI 多做太多事)

==== `ls -l | wc -l`

#image("images/2023-12-06-20-05-29.png")
shell 语言表达式的值是什么呢? -> 翻译成系统调用. 先做字符串的预编译,
基于文本的替换. 解析成语法树, 最终翻译成系统调用的序列.

#tip("Tip")[
shell 是 kernel 和人之间的桥梁
]

=== 人工智能时代，我们为什么还要读手册？

今天的人工智能还是 “被动” 的

- 它还不能很好地告诉你，你应该去找什么
- Manual 是一个 complete source
  - 当然，AI 可以帮助你更快速地浏览手册、理解程序的行为

Let's RTFM, with ChatGPT Copilot!

- man sh - command interpreter(强烈推荐!!!)
- Read the friendly manual 😃

==== 举例

dash 里的`-f`选项: disable pathname expansion.

```sh
❯ ls *
linux:
Makefile  init  minimal.S

sh:
Makefile  init.gdb  lib.h  sh.c  visualize.py
❯ bash -c -f "ls *"
ls: cannot access '*': No such file or directory
```

例如里面的重定向:

```txt
Redirections
    Redirections are used to change where a command reads its input or sends its output.  In general, redirections open, close, or duplicate an existing reference to
    a file.  The overall format used for redirection is:

          [n] redir-op file

    where redir-op is one of the redirection operators mentioned previously.  Following is a list of the possible redirections.  The [n] is an optional number between
    0 and 9, as in ‘3’ (not ‘[3]’), that refers to a file descriptor.

          [n]> file   Redirect standard output (or n) to file.
          [n]>| file  Same, but override the -C option.
          [n]>> file  Append standard output (or n) to file.
          [n]< file   Redirect standard input (or n) from file.
          [n1]<&n2    Copy file descriptor n2 as stdout (or fd n1).  fd n2.
          [n]<&-      Close standard input (or n).
          [n1]>&n2    Copy file descriptor n2 as stdin (or fd n1).  fd n2.
          [n]>&-      Close standard output (or n).
          [n]<> file  Open file for reading and writing on standard input (or n).
```

== 复刻经典

=== A Zero-dependency UNIX Shell (from xv6)

Shell 是 Kernel 之外的 “壳”

- 它也是一个状态机 (同 minimal.S)
- 完全基于系统调用 API

我们移植了 xv6 的 shell

- 零库函数依赖 (`-ffreestanding` 编译、`ld` 链接)
- 可以作为最小 Linux 的 `init` 程序

支持的功能

- 重定向/管道 `ls > a.txt, ls | wc -l`
- 后台执行 `ls &`
- 命令组合 `(echo a ; echo b) | wc -l`

=== 阅读代码

应该如何阅读 xv6 shell 的代码？

==== strace

- 适当的分屏和过滤
- AI 使阅读文档的成本大幅降低

上屏:`strace -f -o sh.log ./sh`
下屏:`tail -f sh.log`
#image("images/2023-12-06-20-09-47.png")

```sh
(sh-xv6) > /bin/ls
Makefile  init.gdb  lib.h  sh  sh.c  sh.log  sh.o  visualize.py
(sh-xv6) >
```

```log
13932 execve("./sh", ["./sh"], 0x7ffd5c673378 /* 67 vars */) = 0
13932 write(2, "(sh-xv6) > ", 11)       = 11
13932 read(0, "/", 1)                   = 1
13932 read(0, "b", 1)                   = 1
13932 read(0, "i", 1)                   = 1
13932 read(0, "n", 1)                   = 1
13932 read(0, "/", 1)                   = 1
13932 read(0, "l", 1)                   = 1
13932 read(0, "s", 1)                   = 1
13932 read(0, "\n", 1)                  = 1
13932 fork()                            = 13964
13964 execve("/bin/ls", ["/bin/ls"], NULL <unfinished ...>
13932 wait4(-1,  <unfinished ...>
13964 <... execve resumed>)             = 0
13964 brk(NULL)                         = 0x5558bf38a000
13964 arch_prctl(0x3001 /* ARCH_??? */, 0x7ffe83bf4cf0) = -1 EINVAL (Invalid argument)
13964 mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f39e8d6b000
13964 access("/etc/ld.so.preload", R_OK) = -1 ENOENT (No such file or directory)
13964 openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
13964 newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=63055, ...}, AT_EMPTY_PATH) = 0
13964 mmap(NULL, 63055, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f39e8d5b000
13964 close(3)                          = 0
13964 openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libselinux.so.1", O_RDONLY|O_CLOEXEC) = 3
13964 read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\0\0\0\0\0\0\0\0"..., 832) = 832
13964 newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=166280, ...}, AT_EMPTY_PATH) = 0
13964 mmap(NULL, 177672, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f39e8d2f000
13964 mprotect(0x7f39e8d35000, 139264, PROT_NONE) = 0
13964 mmap(0x7f39e8d35000, 106496, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x6000) = 0x7f39e8d35000
13964 mmap(0x7f39e8d4f000, 28672, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x20000) = 0x7f39e8d4f000
13964 mmap(0x7f39e8d57000, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x27000) = 0x7f39e8d57000
13964 mmap(0x7f39e8d59000, 5640, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f39e8d59000
13964 close(3)                          = 0
13964 openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
13964 read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P\237\2\0\0\0\0\0"..., 832) = 832
13964 pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
13964 pread64(3, "\4\0\0\0 \0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0"..., 48, 848) = 48
13964 pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\244;\374\204(\337f#\315I\214\234\f\256\271\32"..., 68, 896) = 68
13964 newfstatat(3, "", {st_mode=S_IFREG|0755, st_size=2216304, ...}, AT_EMPTY_PATH) = 0
13964 pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
13964 mmap(NULL, 2260560, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f39e8b07000
13964 mmap(0x7f39e8b2f000, 1658880, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x28000) = 0x7f39e8b2f000
13964 mmap(0x7f39e8cc4000, 360448, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1bd000) = 0x7f39e8cc4000
13964 mmap(0x7f39e8d1c000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x214000) = 0x7f39e8d1c000
13964 mmap(0x7f39e8d22000, 52816, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f39e8d22000
13964 close(3)                          = 0
13964 openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libpcre2-8.so.0", O_RDONLY|O_CLOEXEC) = 3
13964 read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\0\0\0\0\0\0\0\0"..., 832) = 832
13964 newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=613064, ...}, AT_EMPTY_PATH) = 0
13964 mmap(NULL, 615184, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f39e8a70000
13964 mmap(0x7f39e8a72000, 438272, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x2000) = 0x7f39e8a72000
13964 mmap(0x7f39e8add000, 163840, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x6d000) = 0x7f39e8add000
13964 mmap(0x7f39e8b05000, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x94000) = 0x7f39e8b05000
13964 close(3)                          = 0
13964 mmap(NULL, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f39e8a6d000
13964 arch_prctl(ARCH_SET_FS, 0x7f39e8a6d800) = 0
13964 set_tid_address(0x7f39e8a6dad0)   = 13964
13964 set_robust_list(0x7f39e8a6dae0, 24) = 0
13964 rseq(0x7f39e8a6e1a0, 0x20, 0, 0x53053053) = 0
13964 mprotect(0x7f39e8d1c000, 16384, PROT_READ) = 0
13964 mprotect(0x7f39e8b05000, 4096, PROT_READ) = 0
13964 mprotect(0x7f39e8d57000, 4096, PROT_READ) = 0
13964 mprotect(0x5558bdeec000, 4096, PROT_READ) = 0
13964 mprotect(0x7f39e8da5000, 8192, PROT_READ) = 0
13964 prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
13964 munmap(0x7f39e8d5b000, 63055)     = 0
13964 statfs("/sys/fs/selinux", 0x7ffe83bf4d30) = -1 ENOENT (No such file or directory)
13964 statfs("/selinux", 0x7ffe83bf4d30) = -1 ENOENT (No such file or directory)
13964 getrandom("\x07\x2f\x24\xe8\x5d\xe2\x34\x76", 8, GRND_NONBLOCK) = 8
13964 brk(NULL)                         = 0x5558bf38a000
13964 brk(0x5558bf3ab000)               = 0x5558bf3ab000
13964 openat(AT_FDCWD, "/proc/filesystems", O_RDONLY|O_CLOEXEC) = 3
13964 newfstatat(3, "", {st_mode=S_IFREG|0444, st_size=0, ...}, AT_EMPTY_PATH) = 0
13964 read(3, "nodev\tsysfs\nnodev\ttmpfs\nnodev\tbd"..., 1024) = 478
13964 read(3, "", 1024)                 = 0
13964 close(3)                          = 0
13964 access("/etc/selinux/config", F_OK) = -1 ENOENT (No such file or directory)
13964 ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
13964 ioctl(1, TIOCGWINSZ, {ws_row=26, ws_col=192, ws_xpixel=3072, ws_ypixel=832}) = 0
13964 openat(AT_FDCWD, ".", O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY) = 3
13964 newfstatat(3, "", {st_mode=S_IFDIR|0755, st_size=4096, ...}, AT_EMPTY_PATH) = 0
13964 getdents64(3, 0x5558bf38f920 /* 10 entries */, 32768) = 280
13964 getdents64(3, 0x5558bf38f920 /* 0 entries */, 32768) = 0
13964 close(3)                          = 0
13964 newfstatat(1, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x4), ...}, AT_EMPTY_PATH) = 0
13964 write(1, "Makefile  init.gdb  lib.h  sh  s"..., 64) = 64
13964 close(1)                          = 0
13964 close(2)                          = 0
13964 exit_group(0)                     = ?
13964 +++ exited with 0 +++
13932 <... wait4 resumed>NULL, 0, NULL) = 13964
13932 --- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=13964, si_uid=1000, si_status=0, si_utime=0, si_stime=1} ---
13932 write(2, "(sh-xv6) > ", 11)       = 11
```

==== gdb

- AskGPT: How to debug a process that forks children processes in gdb?
  - AI 也可以帮你解释 (不用去淘文档了)
- 以及，定制的 visualization
  - 对于 Shell，我们应该显示什么？

init.gdb

```gdb
set follow-fork-mode child
set detach-on-fork off
set follow-exec-mode same
set confirm off
set pagination off
source visualize.py
break _start
run
n 2
define hook-stop
    pdump
end
```

1. `set follow-fork-mode child`: 设置在程序调用`fork()`系统调用时如何跟踪子进程。child参数表示在子进程中继续调试，而不是父进程。
2. `set detach-on-fork off`: 设置在程序调用`fork()`系统调用时是否自动脱离当前进程并附加到新创建的子进程。off表示不自动脱离。
3. `set follow-exec-mode same`: 设置在程序调用`exec()`系统调用时如何跟踪执行的新程序。same表示继续跟踪现有进程，而不是启动新的调试会话。
4. `set confirm off`:
  设置GDB在关键操作（例如删除断点）之前是否需要确认。off表示不需要确认。
5. `set pagination off`: 设置GDB是否分页显示输出。off表示禁用分页。
6. `source visualize.py`:
  加载名为visualize.py的Python脚本文件，用于可视化程序的状态。
7. `break _start`: 在程序的`_start`函数处设置断点。
8. `run`: 启动程序并开始调试会话。
9. `n 2`: 运行两次程序，即跳过两行代码。
10. `define hook-stop pdump end`:
  定义当程序停止时执行的命令。这里定义了一个名为pdump的自定义命令，它将输出程序的状态。

这些命令和设置旨在改善GDB调试会话中的交互性和可视化。例如，设置跟踪模式为child和禁用自动分页显示可以更好地跟踪程序状态，而自定义命令pdump可以快速查看程序的状态。

=== 理解管道

#image("images/2023-11-27-13-55-21.png")

== 展望未来

=== UNIX Shell: Traps and Pitfalls

在 “自然语言”、“机器语言” 和 “1970s 的算力” 之间达到优雅的平衡

- 平衡意味着并不总是完美
- 操作的 “优先级”？
  - `ls > a.txt | cat`
    - 我已经重定向给 a.txt 了，cat 是不是就收不到输入了？
  - bash/zsh 的行为是不同的
    - 所以脚本一般都是 `#!/bin/bash` 甚至 `#!/bin/sh` 保持兼容
- 文本数据 “责任自负”
  - 有空格？后果自负！
  - (PowerShell: 我有 object stream pipe 啊喂)

=== 另一个有趣的例子

```
$ echo hello > /etc/a.txt
bash: /etc/a.txt: Permission denied

$ sudo echo hello > /etc/a.txt
bash: /etc/a.txt: Permission denied
```

=== 展望未来

Open question: 我们能否从根本上改变管理操作系统的方式？

需求分析

- Fast Path: 简单任务
  - 尽可能快
  - 100% 准确
- Slow Path: 复杂任务
  - 任务描述本身就可能很长
  - 需要 “编程”

=== 未来的 Shell

自然交互/脑机接口：心想事成

- Shell 就成为了一个应用程序的交互库
  - UNIX Shell 是 “自然语言”、“机器语言” 之间的边缘地带

系统管理与语言模型

- fish, zsh, #link("https://www.warp.dev/")[ Warp ], ...
- Stackoverflow, tldr, #link("https://github.com/nvbn/thefuck")[ thef\*\*k ] (自动修复)
- Command palette of vscode (Ctrl-Shift-P)
- Predictable
  - 流程很快 (无需检查)，但可能犯傻
- Creative
  - 给你惊喜，但偶尔犯错
