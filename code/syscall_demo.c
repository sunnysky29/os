
/*

https://jyywiki.cn/OS/2021/slides/C2.slides.html#/2/1
https://www.bilibili.com/video/BV1HN41197Ko?p=4&vd_source=abeb4ad4122e4eff23d97059cf088ab4

$ gcc syscall_demo.c
$ ./a.out
$ echo $?   #查看上一个系统调用的返回值
42
--------------------

 gcc syscall_demo.c -static -Wl,--entry=main
这个选项告诉链接器 (ld) 指定程序的入口点是 main 函数。

  40173e:       00 00
  401740:       e9 4b ff ff ff          jmp    401690 <register_tm_clones>

0000000000401745 <main>:    <-----------
  401745:       f3 0f 1e fa             endbr64
  401749:       55                      push   %rbp
  40174a:       48 89 e5


df@moss:~/g15/codes/os/code$ readelf  -h a.out
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 03 00 00 00 00 00 00 00 00
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - GNU
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x401745
  Start of program headers:          64 (bytes into file)
  Start of section headers:          898208 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         10
  Size of section headers:           64 (bytes)
  Number of section headers:         32
  Section header string table index: 31


gdb  调试：

(gdb) starti
Starting program: a.out

Program stopped.
0x0000000000401745 in main ()  <----------

*/

#include <unistd.h>
#include <sys/syscall.h>

int main() {
  syscall(SYS_exit, 42);
}