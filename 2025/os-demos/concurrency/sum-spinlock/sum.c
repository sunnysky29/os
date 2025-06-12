#include <thread.h>

// We create 3 threads in this example.
#define T        3
#define N  1000000

#define UNLOCKED 0  // ✅ (can go)
#define LOCKED   1  // ❌ (cannot go)

typedef struct {
    int status;
} lock_t;

lock_t lock_var = { UNLOCKED };

#define cmpxchg __sync_val_compare_and_swap

void spin_lock(lock_t *lk) {
retry:
    if (cmpxchg(&lk->status, UNLOCKED, LOCKED) != UNLOCKED) {
        goto retry;
    }
}

void spin_unlock(lock_t *lk) {
    lk->status = UNLOCKED;
    __sync_synchronize();
}

long volatile sum = 0;

void T_sum(int tid) {
    for (int i = 0; i < N; i++) {
        spin_lock(&lock_var);

        // This critical section is even longer; but
        // it should be safe--there will be no conurrency.
        // We also marked sum as volatile to make sure it is
        // loaded and stored in each loop iteration.
        for (int _ = 0; _ < 10; _++) {
            sum++;
        }

        spin_unlock(&lock_var);
    }

    printf("Thread %d: sum = %ld\n", tid, sum);
}

int main() {
    for (int i = 0; i < T; i++) {
        create(T_sum);
    }

    join();

    printf("sum  = %ld\n", sum);
    printf("%d*n = %ld\n", T * 10, T * 10L * N);
}
