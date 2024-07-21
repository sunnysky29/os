/*
https://www.bilibili.com/video/BV1N741177F5/?p=3&spm_id_from=pageDriver&vd_source=abeb4ad4122e4eff23d97059cf088ab4

main 的开始/结束并不是整个程序的开始/结束。
*/

// $ strace  ./a.out
// execve("./a.out", ["./a.out"], 0x7ffec862bab0 /* 29 vars */) = 0
// brk(NULL)                               = 0x5623f7928000
// arch_prctl(0x3001 /* ARCH_??? */, 0x7fff8aeed0c0) = -1 EINVAL (Invalid argument)
// mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f77c0b51000
// access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
// openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
// newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=52095, ...}, AT_EMPTY_PATH) = 0
// mmap(NULL, 52095, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f77c0b44000
// close(3)                                = 0
// openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
// read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P\237\2\0\0\0\0\0"..., 832) = 832
// pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
// pread64(3, "\4\0\0\0 \0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0"..., 48, 848) = 48
// pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0I\17\357\204\3$\f\221\2039x\324\224\323\236S"..., 68, 896) = 68
// newfstatat(3, "", {st_mode=S_IFREG|0755, st_size=2220400, ...}, AT_EMPTY_PATH) = 0
// pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
// mmap(NULL, 2264656, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f77c091b000
// mprotect(0x7f77c0943000, 2023424, PROT_NONE) = 0
// mmap(0x7f77c0943000, 1658880, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x28000) = 0x7f77c0943000
// mmap(0x7f77c0ad8000, 360448, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1bd000) = 0x7f77c0ad8000
// mmap(0x7f77c0b31000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x215000) = 0x7f77c0b31000
// mmap(0x7f77c0b37000, 52816, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f77c0b37000
// close(3)                                = 0
// mmap(NULL, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f77c0918000
// arch_prctl(ARCH_SET_FS, 0x7f77c0918740) = 0
// set_tid_address(0x7f77c0918a10)         = 1921243
// set_robust_list(0x7f77c0918a20, 24)     = 0
// rseq(0x7f77c09190e0, 0x20, 0, 0x53053053) = 0
// mprotect(0x7f77c0b31000, 16384, PROT_READ) = 0
// mprotect(0x5623f7552000, 4096, PROT_READ) = 0
// mprotect(0x7f77c0b8b000, 8192, PROT_READ) = 0
// prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
// munmap(0x7f77c0b44000, 52095)           = 0
// newfstatat(1, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0), ...}, AT_EMPTY_PATH) = 0
// getrandom("\xd4\xe3\x20\x5c\x20\x75\x2a\xcc", 8, GRND_NONBLOCK) = 8
// brk(NULL)                               = 0x5623f7928000
// brk(0x5623f7949000)                     = 0x5623f7949000
// write(1, "hello world\n", 12hello world
// )           = 12
// write(1, "from main !!\n", 13from main !!
// )          = 13
// write(1, "goodbye, OS world!!\n", 20goodbye, OS world!!
// )   = 20
// exit_group(0)                           = ?
// +++ exited with 0 +++


#include <stdio.h>

__attribute__((constructor)) void hello() {
    printf("hello world\n");
}

__attribute__((destructor)) void goodbye() {
    printf("goodbye, OS world!!\n");
}


int main() {
    printf("from main !!\n");
}