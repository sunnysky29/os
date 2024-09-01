#include <assert.h>
#include <stdio.h>

int cmpxchg(int old, int new, int volatile *ptr) {
    asm volatile("lock cmpxchgl %[new], %[mem]"
                 : "+a"(old), [mem] "+m"(*ptr)
                 : [new] "S"(new)
                 : "memory");
    return old;
}

int cmpxchg_ref(int old, int new, int volatile *ptr) {
    int tmp = *ptr;  // Load
    if (tmp == old) {
        *ptr = new;  // Store (conditionally)
    }
    return tmp;
}

void run_test(int x, int old, int new) {
    int val1 = x;
    int ret1 = cmpxchg(old, new, &val1);

    int val2 = x;
    int ret2 = cmpxchg_ref(old, new, &val2);

    assert(val1 == val2 && ret1 == ret2);
    printf("x = %d -> (cmpxchg %d -> %d) -> x = %d\n", x, old, new, val1);
}

int main() {
    for (int x = 0; x <= 2; x++)
        for (int old = 0; old <= 2; old++)
            for (int new = 0; new <= 2; new ++) run_test(x, old, new);
}
