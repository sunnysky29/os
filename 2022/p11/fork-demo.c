/*

gcc fork-demo.c   && ./a.out
Hello World from (179508, 179509, 179511)
Hello World from (0, 179510, 179512)
Hello World from (179508, 0, 179513)
Hello World from (0, 179510, 0)
Hello World from (179508, 0, 0)
Hello World from (179508, 179509, 0)
Hello World from (0, 0, 179514)
Hello World from (0, 0, 0)

*/

#include <unistd.h>
#include <stdio.h>

int main() {
  pid_t pid1 = fork();
  pid_t pid2 = fork();
  pid_t pid3 = fork();
  printf("Hello World from (%d, %d, %d)\n", pid1, pid2, pid3);
}
