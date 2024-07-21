/*
与 03_min_hello_asm.S 等价， c 语言实现

$ gcc 03_min_hello_syscall.c
$ ./a.out
Hello, OS World

---------------
汇编时候，显示源码
$ gcc -g  03_min_hello_syscall.c
$ objdump -S -d a.out | less
........
    syscall(SYS_write, 1, hello, LENGTH(hello));
    1151:       b9 1d 00 00 00          mov    $0x1d,%ecx
    1156:       48 8d 05 b3 0e 00 00    lea    0xeb3(%rip),%rax        # 2010 <hello>
    115d:       48 89 c2                mov    %rax,%rdx
    1160:       be 01 00 00 00          mov    $0x1,%esi
    1165:       bf 01 00 00 00          mov    $0x1,%edi
    116a:       b8 00 00 00 00          mov    $0x0,%eax
    116f:       e8 dc fe ff ff          call   1050 <syscall@plt>  // 动态链接，

*/

# include <unistd.h>
# include <sys/syscall.h>

#define LENGTH(arr) (sizeof(arr) / sizeof(arr[0]))

const char hello[] = "\033[01;31mHello, OS World\033[0m\n";

int main() {
    syscall(SYS_write, 1, hello, LENGTH(hello));
    syscall(SYS_exit, 1);
}