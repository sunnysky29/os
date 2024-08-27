#include "thread.h"

// void Ta() { while (1) { printf("a"); } }
// void Tb() { while (1) { printf("b"); } }

// int main() {
//   create(Ta);
//   create(Tb);

// }


void Ta() { while (1) { ; } }
// void Tb() { while (1) { printf("b"); } }

int main() {
  create(Ta);
  create(Ta);
  create(Ta);
  // create(Tb);

}
