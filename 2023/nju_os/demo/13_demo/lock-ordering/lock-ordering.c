#include "thread-sync.h"
#include "thread.h"

#define N 5

sem_t avail[N];

void Tphilosopher(int id) {
    int lhs = (id + N - 1) % N;
    int rhs = id % N;

    // Enforce lock ordering
    if (lhs > rhs) {
        int tmp = lhs;
        lhs = rhs;
        rhs = tmp;
    }

    while (1) {
        P(&avail[lhs]);
        printf("+ %d by T%d\n", lhs, id);
        P(&avail[rhs]);
        printf("+ %d by T%d\n", rhs, id);

        // Eat

        printf("- %d by T%d\n", lhs, id);
        printf("- %d by T%d\n", rhs, id);
        V(&avail[lhs]);
        V(&avail[rhs]);
    }
}

int main() {
    for (int i = 0; i < N; i++) {
        SEM_INIT(&avail[i], 1);
    }
    for (int i = 0; i < N; i++) {
        create(Tphilosopher);
    }
}
