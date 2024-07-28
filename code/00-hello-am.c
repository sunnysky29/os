#include <am.h>

void say(const char *s) {
  for (; *s; s++) putch(*s);
}

int main() {
  say("hello world!!\n");
  return 0;
}