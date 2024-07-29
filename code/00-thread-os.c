/*
得到  多线程os

*/

#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define MAX_CPU 8

typedef union task {
  struct {
    const char *name;    //线程名字
    union task *next;    //  下一个线程
    void      (*entry)(void *);  // 保存的寄存器现场
    Context    *context;
  };
  uint8_t stack[4096 * 3];  // 线程堆栈分配， 4kb*3
} Task;

Task *currents[MAX_CPU];
#define current currents[cpu_current()]

// user-defined tasks

int locked = 0;
void lock()   { while (atomic_xchg(&locked, 1)); }
void unlock() { atomic_xchg(&locked, 0); }

void func(void *arg) { // 每个线程执行的代码
  while (1) {
    lock();
    printf("Thread-%s on CPU #%d\n", arg, cpu_current());
    // printf("%s", arg);
    unlock();
    for (int volatile i = 0; i < 10000; i++) ;   //空循环
  }
}

Task tasks[] = {
  { .name = "A", .entry = func },
  { .name = "B", .entry = func },
  { .name = "C", .entry = func },
  { .name = "D", .entry = func },
  { .name = "E", .entry = func },
};

// ------------------
// Event ev, ： 中断类型
// Context *ctx ： 寄存器现场
// current : 当前运行的线程
Context *on_interrupt(Event ev, Context *ctx) {  // 中断处理
  extern Task tasks[];
  if (!current) current = &tasks[0];  // 为空，第一次中断 
  else          current->context = ctx;
  do {
    current = current->next;  // current 切换
  } while ((current - tasks) % cpu_count() != cpu_current());
  return current->context;  
}

void mp_entry() {
  iset(true);   // 每个处理器所做的操作都完全相同
  yield();  // 随后，os main 函数就不再返回了，os 变成--> 中断处理程序
}

int main() {
  cte_init(on_interrupt);  // 注册中断处理函数，处理中断，调用 on_interrupt

  for (int i = 0; i < LENGTH(tasks); i++) {
    Task *task    = &tasks[i];
    Area stack    = (Area) { &task->context + 1, task + 1 };
    task->context = kcontext(stack, task->entry, (void *)task->name);
    task->next    = &tasks[(i + 1) % LENGTH(tasks)];  // 若干 task ---> 循环链表
  }
  mpe_init(mp_entry);
  
}