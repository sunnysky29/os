#include <thread.h>

void T_a() {
    while (1) {
        printf("a");
    }
}

void T_b() {
    while (1) {
        printf("b");
    }
}

int main() {
    setbuf(stdout, NULL);
    spawn(T_a);
    spawn(T_b);
}
