
/*

山寨多线程支付宝
原子性的丧失

gcc  alipay.c   -lpthread     &&  ./a.out
while true; do ./a.out; done


*/

#include "thread.h"

unsigned long balance = 100;

void Alipay_withdraw(int amt) {
  if (balance >= amt) {
    usleep(1); // unexpected delays， 1微秒
    balance -= amt;
  }
}

void Talipay(int id) {
  Alipay_withdraw(100);
}

int main() {
  create(Talipay);
  create(Talipay);
  join();
  printf("balance = %lu\n", balance);
}
