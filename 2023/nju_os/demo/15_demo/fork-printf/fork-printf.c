#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

int main() {
    int n = 2;
    for (int i = 0; i < n; i++) {
        fork();
        printf("Hello\n");
    }
    for (int i = 0; i < n; i++) {
        wait(NULL);
    }
}
