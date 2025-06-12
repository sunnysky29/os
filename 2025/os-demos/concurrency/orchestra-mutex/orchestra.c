#include <thread.h>
#include <thread-sync.h>

mutex_t locks[] = {
    MUTEX_INIT(),
    MUTEX_INIT(),
    MUTEX_INIT(),
    MUTEX_INIT(),
};

void init() {
    // This is main()
    for (int i = 0; i < 4; i++) {
        mutex_lock(&locks[i]);
    }
}

void wait_for_beat(int current_beat, int tid) {
    // This is T_player
    mutex_lock(&locks[tid - 1]);
}

void release_beat() {
    // This is T_conductor
    for (int i = 0; i < 4; i++) {
        // !!! This hack is undefined behavior.
        // (But it magically works.)
        mutex_unlock(&locks[i]);
    }
}

// This is a bad hack; I'm lazy.
#include "main.c"
