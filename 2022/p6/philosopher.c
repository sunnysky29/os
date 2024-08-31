/*
哲学家吃饭

失败尝试：
gcc philosopher.c  -lpthread   &&  ./a.out 

dead lock :
T1 Got 1
T2 Got 2
T4 Got 4
T5 Got 5
T3 Got 3


*/

#include "thread.h"
#include "thread-sync.h"

#define N 5
sem_t locks[N];

void Tphilosopher(int id) {
  int lhs = (id - 1) % N;
  int rhs = id % N;
  while (1) {
    P(&locks[lhs]);
    printf("T%d Got %d\n", id, lhs + 1);
    P(&locks[rhs]);
    printf("T%d Got %d\n", id, rhs + 1);
    V(&locks[lhs]);
    V(&locks[rhs]);
  }
}

int main(int argc, char *argv[]) {
  for (int i = 0; i < N; i++) {
      SEM_INIT(&locks[i], 1);
  }
  for (int i = 0; i < N; i++) {
    create(Tphilosopher);
  }
}
