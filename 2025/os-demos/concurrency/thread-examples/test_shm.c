#include <thread.h>
#include <unistd.h>

int x = 0, y = 0;

void inc_x() { while (1) { x++; sleep(1); } }
void inc_y() { while (1) { y++; sleep(2); } }

int main() {
    spawn(inc_x);
    spawn(inc_y);
    while (1) {
        printf("\033[2J\033[H");
        printf("x = %d, y = %d", x, y);
        fflush(stdout);
        usleep(100000);
    }
}
