#include <stdio.h>
#include <unistd.h>

int main() {
    pid_t x = fork();
    pid_t y = fork();
    printf("%d %d\n", x, y);
}
