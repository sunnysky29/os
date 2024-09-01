#include "thread.h"

int x = 0;

void add(int n) {
    x++;
    printf("x: %d\n", x);
}

int main(int argc, char *argv[]) {
    for (int i = 0; i < 10; i++) {
        spawn(add);
    }
    return 0;
}
