#import "../template.typ": *
#pagebreak()
= 并发控制: 同步 (2)

== 信号量

=== 复习：生产者-消费者、互斥、条件变量

打印 “合法” 的括号序列 (())()

- 左括号对应 push
- 右括号对应 pop

```c
#define CAN_PRODUCE (count < n)
#define CAN_CONSUME (count > 0)

wait_until(CAN_PRODUCE) with (mutex) {
  count++;
  printf("(");
}

wait_until(CAN_CONSUME) with (mutex) {
  count--;
  printf(")");
}
```

=== 信号量：一种条件变量的特例

```c
void P(sem_t *sem) { // wait
  wait_until(sem->count > 0) {
    sem->count--;
  }
}

void V(sem_t *sem) { // post (signal)
  atomic {
    sem->count++;
  }
}
```

正是因为条件的特殊性，信号量不需要 broadcast

- P 失败时立即睡眠等待
- 执行 V 时，唤醒任意等待的线程

=== 理解信号量 (1)

初始时 `count = 1` 的特殊情况

互斥锁是信号量的特例

```c
#define YES 1
#define NO 0

void lock() {
    wait_until(count == YES) {
        count = NO;
    }
}

void unlock() {
    count = YES;
}
```

=== 理解信号量 (2)

P - prolaag (try + decrease/down/wait/acquire)

- 试着从袋子里取一个球
  - 如果拿到了，离开
  - 如果袋子空了，排队等待

V - verhoog (increase/up/post/signal/release)

- 往袋子里放一个球
  - 如果有人在等球，他就可以拿走刚放进去的球了
  - 放球-拿球的过程实现了同步

#tip("Tip")[
信号量是一种管理信号资源的同步对象。
]

=== 理解信号量 (3)

扩展的互斥锁：一个手环 → n 个手环

- 让更多同学可以进入更衣室
  - 管理员(信号量)可以持有任意数量的手环 (count, 更衣室容量上限)
  - 先进入更衣室的同学先进入游泳池
  - 手环用完后需要等同学出来
- 信号量对应了 “资源数量”

=== 信号量：实现优雅的生产者-消费者

信号量设计的重点

- 考虑 “球”/“手环” (每一单位的 “_资源_”) 是什么
- 生产者/消费者 = 把球从一个袋子里放到另一个袋子里(一单位资源就是一堆括号。)

#image("./images/PV.png")

```c
// empty -> 还有多少空余的空间可以打左括号
// fill  -> 有多少左括号已经有配对的右括号
sem_t fill, empty;

void Tproduce() {
  P(&empty);
  printf("("); // 注意共享数据结构访问需互斥
  V(&fill);
}
void Tconsume() {
  P(&fill);
  printf(")");
  V(&empty);
}

// 一个命令行参数代表嵌套深度。
int main(int argc, char *argv[]) {
    assert(argc == 2);
    SEM_INIT(&fill, 0);
    SEM_INIT(&empty, atoi(argv[1]));
    for (int i = 0; i < 8; i++) {
        create(Tproduce);
        create(Tconsume);
    }
}
```

== 信号量：应用

信号量的两种典型应用

1. 实现一次临时的 happens-before
  - 初始：s = 0
  - A; V(s)
  - P(s); B
    - 假设 s 只被使用一次，保证 A happens-before B
      #image("./images/A-happens-before-B.png")
      >
      这里比条件变量好用。如果使用条件变量，A先broadcast/signal那B来的时候也许已经丢了。还需要用额外的变量告诉B
      A的任务已经完成。（信号量自带一个计数器，所以实现上会简单一些）
2. 实现计数型的同步
  - 初始：done = 0
  - Tworker: V(done)
  - Tmain: P(done) × T

对应了两种线程 join 的方法 T1->T2->… v.s. 完成就行，不管顺序

第一种：

```
T1              T2              Tmain
..
..                              P(T1 done)
..                              P(T2 done)
V(T1 done)
                V(T2 done)
```

第二种

```
T1              T2              Tmain
..
..                              P(done)*|T|
V(done)
                V(done)
```

#tip("Tip")[
用个循环。
]

两种方法各有优点，第一种可以控制顺序，例如先有第一个结果再有第二个结果。
第二种，只有执行完了就可以被唤醒一次。（可以知道相对每个线程执行完的时间）

```c
#include "thread-sync.h"
#include "thread.h"

#define T 4
#define N 10000000

sem_t done;
long sum = 0;

void atomic_inc(long *ptr) {
    asm volatile("lock incq %0" : "+m"(*ptr) : : "memory");
}

void Tsum() {
    for (int i = 0; i < N; i++) {
        atomic_inc(&sum);
    }
    V(&done);
}

void Tprint() {
    for (int i = 0; i < T; i++) {
        P(&done);
    }
    printf("sum = %ld\n", sum);
}

int main() {
    SEM_INIT(&done, 0);
    for (int i = 0; i < T; i++) {
        create(Tsum);
    }
    create(Tprint);
}
```

=== 例子：实现计算图

对于任何计算图
#image("images/2024-03-18-13-15-24.png")

- 为每个节点分配一个线程(每个边分配一个信号量)
  - 对每条入边执行 P (wait) 操作
  - 完成计算任务
  - 对每条出边执行 V (post/signal) 操作
    - 每条边恰好 P 一次、V 一次
    - PLCS 直接就解决了啊？

```c
void Tworker_d() {
    P(bd); P(ad); P(cd);
    // 完成节点 d 上的计算任务
    V(de);
}
```

乍一看很厉害

- 完美解决了并行问题

实际上……

- 创建那么多线程和那么多信号量 = Time Limit Exceeded
- 解决线程太多的问题
  - 一个线程负责多个节点的计算(例如acd一个线程，bd一个线程。线程之间的同步就变少了，只要三个同步。省了线程和信号量。)
    - 静态划分 → 覆盖问题
    - 动态调度(计算图是动态生成的) → 又变回了生产者-消费者
- 解决信号量太多的问题
  - 计算节点共享信号量
    - 可能出现 “假唤醒” → 又变回了条件变量

==== 例子：毫无意义的练习题

有三种线程

- Ta 若干: 死循环打印 `<`
- Tb 若干: 死循环打印 `>`
- Tc 若干: 死循环打印 `_`

如何同步这些线程，保证打印出 `<><_` 和 `><>_` 的序列？

信号量的困难

- 上一条鱼打印后，`<` 和 `>` 都是可行的
- 我应该 P 哪个信号量？
  - 可以 P 我自己的
  - 由打印 `_` 的线程随机选一个

动态计算图:
```c
#include "thread-sync.h"
#include "thread.h"

#define LENGTH(arr) (sizeof(arr) / sizeof(arr[0]))

enum {
    A = 1,
    B,
    C,
    D,
    E,
    F,
};

struct rule {
    int from, ch, to;
} rules[] = {
    {A, '<', B}, {B, '>', C}, {C, '<', D}, {A, '>', E},
    {E, '<', F}, {F, '>', D}, {D, '_', A},
};
int current = A;
sem_t cont[128];

void fish_before(char ch) {
    P(&cont[(int)ch]);

    // Update state transition
    for (int i = 0; i < LENGTH(rules); i++) {
        struct rule *rule = &rules[i];
        if (rule->from == current && rule->ch == ch) {
            current = rule->to;
        }
    }
}

void fish_after(char ch) {
    int choices[16], n = 0;

    // Find enabled transitions
    for (int i = 0; i < LENGTH(rules); i++) {
        struct rule *rule = &rules[i];
        if (rule->from == current) {
            choices[n++] = rule->ch;
        }
    }

    // Activate a random one
    int c = rand() % n;
    V(&cont[choices[c]]);
}

const char roles[] = ".<<<<<>>>>___";

void fish_thread(int id) {
    char role = roles[id];
    while (1) {
        fish_before(role);
        putchar(role);  // Not lock-protected
        fish_after(role);
    }
}

int main() {
    setbuf(stdout, NULL);
    SEM_INIT(&cont['<'], 1);
    SEM_INIT(&cont['>'], 0);
    SEM_INIT(&cont['_'], 0);
    for (int i = 0; i < strlen(roles); i++) create(fish_thread);
}
```

=== 例子：使用信号量实现条件变量

当然是问 AI 了

- ChatGPT (GPT-3.5) 直接一本正经胡说八道
  - 这个对 LLM 还是太困难了
- New Bing 给出了一种 “思路”
  - 第一个 wait 的线程会在持有 mutex 的情况下 P(cond)
  - 从此再也没有人能获得互斥锁……
    - ~~像极了我改期末试卷的体验~~

=== 使用信号量实现条件变量：本质困难

操作系统用自旋锁保证 wait 的原子性

```c
wait(cv, mutex) {
    release(mutex);
    sleep();
}
```

#link("http://birrell.org/andrew/papers/ImplementingCVs.pdf")[ 信号量实现的矛盾 ]

- 不能带着锁睡眠 (NewBing 犯的错误)
- 也不能先释放锁
  - `P(mutex); nwait++; V(mutex);`
  - 此时 signal/broadcast 发生，唤醒了后 wait 的线程
  - `P(sleep);`
- (我们稍后介绍解决这种矛盾的方法)

=== 信号量的使用：小结

信号量是对 “袋子和球/手环” 的抽象

- 实现一次 happens-before，或是计数型的同步
  - 能够写出优雅的代码: `P(empty); printf("("); V(fill)`
- 但并不是所有的同步条件都容易用这个抽象来表达

== 哲 ♂ 学家吃饭问题

=== 哲学家吃饭问题 (E. W. Dijkstra, 1960)

经典同步问题：哲学家 (线程) 有时思考，有时吃饭(五个哲学家，5把叉子)

- 吃饭需要同时得到左手和右手的叉子
- 当叉子被其他人占有时，必须等待，如何完成同步？

=== 成功与失败的尝试


成功的尝试 (万能的方法)

```c
#define CAN_EAT (avail[lhs] && avail[rhs])
mutex_lock(&mutex);
while (!CAN_EAT)
  cond_wait(&cv, &mutex);
avail[lhs] = avail[rhs] = false;
mutex_unlock(&mutex);

mutex_lock(&mutex);
avail[lhs] = avail[rhs] = true;
cond_broadcast(&cv);
mutex_unlock(&mutex);
```

失败的尝试

- 把信号量当互斥锁：先拿一把叉子，再拿另一把叉子

```c
Tphilosopher{
    P(lhs);
    P(rhs);
    eat();
    V(lhs);
    V(rhs);
}
```

Trick: 死锁会在 5 个哲学家 “同时吃饭” 时发生

==== 成功的尝试：信号量

- 破坏这个条件即可
  - 保证任何时候至多只有 4 个人可以吃饭
  - 直观理解：大家先从桌上退出
    - 袋子里有 4 张卡
    - 拿到卡的可以上桌吃饭 (拿叉子)
    - 吃完以后把卡归还到袋子
- 任意 4 个人想吃饭，总有一个可以拿起左右手的叉子
  - 教科书上有另一种解决方法 (lock ordering；之后会讲)

但这真的对吗？

- `philosopher-check.py`
- 在必要的时候使用 model checker

=== 反思：分布与集中

“Leader/follower” - 有一个集中的 “总控”，而非
“各自协调”(有一个服务员来进行叉子的调度，更加公平，之前的实现有可能出现一个哲学家反复吃的情况。)

- 在可靠的消息机制上实现任务分派
  - Leader 串行处理所有请求 (例如：条件变量服务)

```c
void Tphilosopher(int id) {
  send(Twaiter, id, EAT);
  receive(Twatier); // 等待 waiter 把两把叉子递给哲学家
  eat();
  send(Twaiter, id, DONE); // 归还叉子
}

void Twaiter() {
  while (1) {
    (id, status) = receive(Any);
    switch (status) { ... }
  }
}
```

你可能会觉得，管叉子的人是性能瓶颈

- 一大桌人吃饭，每个人都叫服务员的感觉
- Premature optimization is the root of all evil (D. E. Knuth)

抛开 workload 谈优化就是耍流氓
#image("images/2024-03-18-13-21-00.png")

- 吃饭的时间通常远远大于请求服务员的时间
- 如果一个 manager 搞不定，可以分多个 (fast/slow path)
- 把系统设计好，集中管理可以不是瓶颈：[ The Google File System (SOSP'03)
  ](https://pdos.csail.mit.edu/6.824/papers/gfs.pdf) 开启大数据时代
