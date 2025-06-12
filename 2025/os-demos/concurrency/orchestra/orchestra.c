#include <thread.h>
#include <thread-sync.h>

static mutex_t lk = MUTEX_INIT();

extern int conductor_beat;

void wait_for_beat(int current_beat) {
retry:
    // Reads should be protected by a mutex.
    mutex_lock(&lk);
    int conductor_beat_ = conductor_beat;
    mutex_unlock(&lk);

    if (current_beat >= conductor_beat_) {
        // There is a pattern here: we "wait" until something
        // (a condition) happens. This is the idea behind the
        // condition variable.
        goto retry;
    }
}

void release_beat() {
    mutex_lock(&lk);
    conductor_beat++;
    mutex_unlock(&lk);
}

// This is a bad hack; I'm lazy.
#include "main.c"
