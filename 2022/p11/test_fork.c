
#include <stdio.h>
#include <unistd.h>

int main() {
    pid_t pid = fork();

    if (pid < 0) {
        // 错误处理
        perror("Fork failed");
    } else if (pid == 0) {
        // 子进程执行
        printf("This is the child process.\n");
    } else {
        // 父进程执行
        printf("This is the parent process, child PID: %d\n", pid);
    }
    return 0;
}


