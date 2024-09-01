#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int hp = 10000;

__attribute__((noinline)) int hit(int damage) { return hp - damage; }

int main() {
    while (1) {
        hp = hit(rand() % 10);
        printf("hp = %d\n", hp);
        usleep(10000);
        if (hp < 0) {
            printf("Game Over\n");
            break;
        }
    }
}
