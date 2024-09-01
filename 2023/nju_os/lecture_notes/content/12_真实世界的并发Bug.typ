#import "../template.typ": *
#pagebreak()
= 真实世界的并发 Bug

== 伤人性命的并发 Bug

=== 先回顾一个并发 Bug

在捡起东西的瞬间 “拿起” 物品，“拿起” 的物品会变成 “捡起” 的物品

- 视频
- 似乎是由共享状态引起的

```js
v = "$1";
// Expected timing
// InHand = v;

Event(pickup) {
    v = "$99";
    Inventory.append(v);
}

// Actual timing
InHand = v;
```

=== “Killed by a Machine”

Therac-25 Incident (1985-1987)

- 至少导致 6 人死亡
- 事件驱动导致的并发 bug (没有多线程)

=== The Therac-25

在更早的产品中，使用电路互锁 (interlock) 在 assert fail 时停机

```
assert mode in [XRay, Electron]
assert mirror in [On, Off]
assert not (mode == XRay and mirror == Off)
```

=== The Killer Software Bug in History

原子性 + 异步执行假设导致的灾难

- 选择 X-ray Mode
  - 机器开始移动 mirror
  - 需要 ~8s 完成
- 此时切换到 Electron Mode
  - 射线源以 X-ray Mode 运行
  - Mirror 尚未到位
  - Malfunction 54
    - 每天处理各种 Malfunction 的操作员下意识地 Continue
    - 灾难发生

=== 这甚至不是 Therac-25 里的最后一个杀人 Bug

问题修复后……

- If the operator sent a command at the exact moment the counter overflowed, the
  machine would skip setting up some of the beam accessories

最终解决方法

- 独立的硬件安全方案
- 在大计量照射发生时直接停机

== 死锁

=== 死锁 (Deadlock)

#tip("Tip")[
A deadlock is a state in which each member of a group is waiting for another member, including itself, to take action.
]

出现线程 “互相等待” 的情况

=== AA-Deadlock

Model checker 可以告诉你为什么

```c
lock(&lk);
// lk = LOCKED;
lock(&lk);
// while (xchg(&lk, LOCKED) == LOCKED) ;
```

看起来很傻，你觉得自己不会犯这错误？

- 不，你会犯的！
- 真实系统的复杂性等着你
  - 多层函数调用
  - 隐藏的控制流

例如内核代码:
```c
Tworker(){
    func();
    lock(&lk);
    interrupt();
    unlock(&lk);
}

interrupt(){
    ...
    lock(&lk);  // 寄
    interrupt();
    unlock(&lk);
    ...
}
```

例如多层函数：

```c
Tworker(){
    func();
    lock(&lk);
    func2(..);
    unlock(&lk);
}

func2(..){
    ...
    func3(..);
}

func3(..){
    ...
    lock(&lk);  // 寄
    ...
}
```

=== ABBA-Deadlock

哲 ♂ 学家吃饭问题

#code(caption: [哲学家吃饭死锁])[
```c
void Tphilosopher() {
  P(&avail[lhs]);
  P(&avail[rhs]);
  // ...
  V(&avail[lhs]);
  V(&avail[rhs]);
}
```
]

- T1 : P(1) - 成功, P(2) - 等待
- T2 : P(2) - 成功, P(3) - 等待
- T3 : P(3) - 成功, P(4) - 等待
- T4 : P(4) - 成功, P(5) - 等待
- T5 : P(5) - 成功, P(1) - 等待

=== 死锁产生的必要条件

[ System deadlocks (1971)
](https://dl.acm.org/doi/10.1145/356586.356588)：死锁产生的四个必要条件(原文很好，值得一读)

- 用 “资源” 来描述
  - 状态机视角：就是 “当前状态下持有的锁 (校园卡/球)”

1. Mutual-exclusion - 一张校园卡只能被一个人拥有
2. Wait-for - 一个人等其他校园卡时，不会释放已有的校园卡
3. No-preemption - 不能抢夺他人的校园卡
4. Circular-chain - 形成校园卡的循环等待关系

四个条件 “缺一不可”

- 打破任何一个即可避免死锁(但实际上要校园卡依然有互斥的作用，要打破123是非常困难的)
- 在程序逻辑正确的前提下 “打破” 根本没那么容易……

例如2(一个人等待其他校园卡时，不会释放已有的校园卡)：
```c
lock(A)
action1;
    lock(B)
    ...
    unlock(B)
action2;
unlock(A)
```
如果破坏这个条件，即等待B的时候可以把A释放掉，那action1和action2就可以分开了，就不是互斥了。

#tip("Tip")[
    消除循环等待是个更为经济划算的方法。
]

== 数据竞争

#tip("Tip")[
    - 所以不上锁不就没有死锁了吗？ 
    - 数据竞争并发bug的根源
]

=== 数据竞争

#definition("Definition")[
    数据竞争：*不同的线程*同时访问*同一内存*，且*至少有一个是写*。
]

- 两个内存访问在 “赛跑”，“跑赢” 的操作先执行 
  - 例子：共享内存上实现的 Peterson 算法

  #tip("Tip")[
      锁消灭了数据竞争。
  ]

==== “跑赢” 并没有想象中那么简单

Weak memory model 允许不同观测者看到不同结果 Since C11: #link("https://en.cppreference.com/w/c/language/memory_model")[ data race is undefined behavior ]

#tip("Tip")[
    读一下更严谨的关于data race的定义。
]

=== 数据竞争：你只要记得

用锁保护好共享数据

消灭一切数据竞争

=== 数据竞争：例子

以下代码概括了你们遇到数据竞争的大部分情况

- 不要笑，你们的 bug 几乎都是这两种情况的变种

```c
// Case #1: 上错了锁
void thread1() { spin_lock(&lk1); sum++; spin_unlock(&lk1); }
void thread2() { spin_lock(&lk2); sum++; spin_unlock(&lk2); }
// race -> UB
// Case #2: 忘记上锁
void thread1() { spin_lock(&lk1); sum++; spin_unlock(&lk1); }
void thread2() { sum++; }
```

=== 为什么不要笑？

不同的线程同时访问同一内存，且至少有一个是写(不同的顺序会导致不同的结果)

- “内存” 可以是地址空间中的任何内存
  - 可以是全部变量
  - 可以是堆区分配的变量
  - 可以是栈
- “访问” 可以是任何代码
  - 可能发生在你的代码里
  - 可以发生在框架代码里
  - 可能是一行你没有读到过的汇编代码
  - 可能时一条 ret 指令(会访问栈，在后面多处理器操作系统内核实验会遇到)

#tip("Tip")[
    找到所有的的线程所有可能访问内存的地方是很难的。
]

== 原子性和顺序违反

=== 并发编程的本质

人类是 sequential creature

- 我们只能用 sequential 的方式来理解并发
  - 程序分成若干 “块”，每一块看起来都没被打断 (原子)
  - 具有逻辑先后的 “块” 被正确同步
    - 例子：produce → (happens-before) → consume

并发控制的机制完全是 “后果自负” 的

- 互斥锁 (lock/unlock) 实现原子性
  - 忘记上锁——原子性违反 (Atomicity Violation, AV)
- 条件变量/信号量 (wait/signal) 实现先后顺序同步
  - 忘记同步——顺序违反 (Order Violation, OV)

=== 那么，程序员用的对不对呢？

“Empirical study” 实证研究

- 收集了 105 个真实系统的并发 bugs(开发环境没有找出来，生产的时候才被发现)
  - MySQL (14/9), Apache (13/4), Mozilla (41/16), OpenOffice (6/2)
  - 观察是否存在有意义的结论

97% 的非死锁并发 bug 都是原子性或顺序错误

- “人类的确是 sequential creature”
- #link("https://dl.acm.org/doi/10.1145/1346281.1346323")[ Learning from mistakes - A comprehensive study on real world concurrency bug characteristics ] (ASPLOS'08, Most Influential Paper Award)

=== 原子性违反 (AV)

“ABA”

- 我以为一段代码没啥事呢，但被人强势插入了
- 即便分别上锁 (消除数据竞争)，依然是 AV
  - Diablo I 里复制物品的例子
  - Therac-25 中 “移动 Mirror + 设置状态”

#image("images/2024-03-18-18-17-51.png")

操作系统中还有更多的共享状态

- “TOCTTOU” - time of check to time of use
  - #image("images/2024-03-18-18-18-05.png")
  #tip("Tip")[
      快捷方式很危险，如果创建了一个系统程序的符号链接，虽然用户没有权限访问， 但是`Sendmail`程序有权限。这里就是利用了`Check`->`Use`间隙进行hack。
  ]
- [ TOCTTOU vulnerabilities in UNIX-style file systems: An anatomical study
  ](https://www.usenix.org/legacy/events/fast05/tech/full_papers/wei/wei.pdf)
  (FAST'05); 我们可以用进程模型复现这个问题！

=== 顺序违反 (OV)

“BA”

- 怎么就没按我预想的顺序(AB)来呢？
  - 例子：concurrent use after free(需要一个同步，在use之后，free之前进行同步)
    #image("images/2024-03-18-18-18-34.png")
