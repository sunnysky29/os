#include <thread.h>
#include <thread-sync.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define NTASKS 6

struct edge {
    int src, dst;
} edges[] = {
    {0, 1},
    {0, 2},
    {0, 3},
    {1, 4},
    {2, 4},
    {4, 5},
};

struct task {
    int pending_deps;
    cond_t cv;
} tasks[NTASKS];

// The big, simple lock to protect everyone.
mutex_t mutex = MUTEX_INIT();

void T_worker(int tid) {
    tid--;

    mutex_lock(&mutex);
    while (!(tasks[tid].pending_deps == 0)) {
        // We can proceed only if all dependencies are cleared.
        cond_wait(&tasks[tid].cv, &mutex);
    }
    mutex_unlock(&mutex);

    // Some simulated computation
    printf("Computing node #%d...\n", tid);
    sleep(1);

    mutex_lock(&mutex);
    for (int i = 0; i < LENGTH(edges); i++) {
        struct task *t = &tasks[edges[i].dst];
        if (edges[i].src == tid) {
            // Update all successors of this task
            t->pending_deps--;
            if (t->pending_deps == 0) {
                // Same as signal: there's at most one waiting
                cond_broadcast(&t->cv);
            }
        }
    }
    mutex_unlock(&mutex);
}

int main() {
    for (int i = 0; i < NTASKS; i++) {
        tasks[i].pending_deps = 0;
        cond_init(&tasks[i].cv);
    }

    for (int i = 0; i < LENGTH(edges); i++) {
        tasks[edges[i].dst].pending_deps++;
    }

    for (int i = 0; i < NTASKS; i++) {
        spawn(T_worker);
    }

    join();
    printf("Execution completed.\n");
}
