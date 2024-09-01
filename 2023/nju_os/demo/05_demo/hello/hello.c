#include "thread.h"

int x;

void Thello(int id) {
    x++;
    printf("%d\n", x);
}

int main() {
    for (int i = 0; i < 10; i++) {
        spawn(Thello);
    }
}
