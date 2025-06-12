#include <thread.h>
#include <thread-sync.h>

static mutex_t lk = MUTEX_INIT();

extern int conductor_beat;

// Condition variable for synchronizing beats
cond_t cv = COND_INIT();

void wait_for_beat(int current_beat) {
    mutex_lock(&lk);

    // To proceed only when current_beat falls behind.
    // And we don't need a "local copy" here.
    while (!(current_beat < conductor_beat)) {
        cond_wait(&cv, &lk);
    }

    mutex_unlock(&lk);
}

void release_beat() {
    mutex_lock(&lk);
    conductor_beat++;
    cond_broadcast(&cv);  // Wake up potential waiting threads.
    mutex_unlock(&lk);
}

// This is a bad hack; I'm lazy.
#include "main.c"
