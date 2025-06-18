
/*
 gcc -nostartfiles -nostdlib -static test1.c && (./a.out; echo $?)

使用 -nostartfiles 后，你就必须自己定义入口点（如 _start）
-nostdlib 不链接 C 标准库, 这意味着不能使用任何标准库函数（如 printf, exit, malloc 等）


关于寄存器：
+----------------------------+
|           rax (64)         |
+---------+---------+--------+
          | eax (32)          |
          +----+------+
               | ax (16)
               +---+---+
                   |  |  
                  ah al

     ter used to signal an error.

       Arch/ABI    Instruction           System  Ret  Ret  Error    Notes
                                         call #  val  val2
       ───────────────────────────────────────────────────────────────────
       alpha       callsys               v0      v0   a4   a3       1, 6
       x86-64      syscall               rax     rax  rdx  -        5
       x32         syscall               rax     rax  rdx  -        5


       Arch/ABI      arg1  arg2  arg3  arg4  arg5  arg6  arg7  Notes
       ──────────────────────────────────────────────────────────────
       alpha         a0    a1    a2    a3    a4    a5    -
       x86-64        rdi   rsi   rdx   r10   r8    r9    -
       x32           rdi   rsi   rdx   r10   r8    r9    -




*/

void _start() {
    // 定义字符串在函数内部（这样它会位于代码段）
    const char msg[] = "Hellowolld\n";
    
    __asm__(
        ".intel_syntax noprefix\n"   // 使用 Intel 语法
        
        // sys_write(1, msg, 6) - 注意长度改为6以包含换行符
        "mov rax, 1\n"       // sys_write
        "mov rdi, 1\n"       // fd = stdout
        "lea rsi, [%0]\n"    //  将 msg 的地址加载到 rsi（sys_write 的第二个参数）
        "mov rdx, 3\n"       // 长度 ，字节单位
        "syscall\n"

        // // 将sys_write的返回值作为退出码
        "mov rdi, rax\n"     // 将rax的值移到rdi（退出码参数）

        // sys_exit(0)
        "mov rax, 60\n"      // sys_exit
        // "mov rdi, 2\n"     // 退出码
        "syscall\n"
        
        : // 无输出
        : "r" (msg)          // 输入：将msg的地址传给汇编
        : "rax", "rdi", "rsi", "rdx" // 破坏的寄存器
    );
}

