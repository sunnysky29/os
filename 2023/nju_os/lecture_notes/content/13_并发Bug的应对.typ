#import "../template.typ": *
#pagebreak()
= 并发 Bug 的应对

== 死锁的应对

=== 回顾：死锁产生的必要条件

#link("https://dl.acm.org/doi/10.1145/356586.356588")[ System deadlocks ]
(1971)：死锁产生的四个必要条件

- 用 “资源” 来描述
  - 状态机视角：就是 “当前状态下持有的锁 (校园卡/球)”

- Mutual-exclusion - 一张校园卡只能被一个人拥有
- Wait-for - 一个人等其他校园卡时，不会释放已有的校园卡
- No-preemption - 不能抢夺他人的校园卡
- Circular-chain - 形成校园卡的循环等待关系

- 站着说话不腰疼的教科书：
  - “理解了死锁的原因，尤其是产生死锁的四个必要条件，就可以最大可能地避免、预防和解除死锁。所以，在系统设计、进程调度等方面注意如何不让这四个必要条件成立，如何确定资源的合理分配算法，避免进程永久占据系统资源。此外，也要防止进程在处于等待状态的情况下占用资源。因此，对资源的分配要给予合理的规划。”

不能称为是一个合理的 argument

- 对于玩具系统/模型
  - 我们可以直接证明系统是 deadlock-free 的
- 对于真正的复杂系统
  - Bullshit

=== 如何在实际系统中避免死锁？

四个条件中最容易达成的: 避免循环等待(如何让任何上锁的等待关系都没有环？)

Lock ordering(有向无环图，拓扑排序，直接规定一个顺序)

- 任意时刻系统中的锁都是有限的
- 严格按照固定的顺序获得所有锁 (Lock Ordering)，就可以消灭循环等待
  - “在任意时刻获得 “最靠后” 锁的线程总是可以继续执行”
- 例子：修复哲学家吃饭问题
  - 如何发生死锁的？(编号代表叉子)
  #example("Example")[
    - T1: 1 2
    - T2: 2 3
    - T3: 3 1
  ]
  - 人为规定先获得编号小的那一把锁，再获得编号大的那一把
    #example("Example")[
      - T1: 1 2
      - T2: 2 3
      - T3: 1 3
    ]
  #code(caption: [lock-ordering])[
  ```c
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
    ```
  ]

=== Lock Ordering: 应用 (Linux Kernel: rmap.c)

#tip("Tip")[
    实际情况下就是采用lock-ordering的，而且应用的很广泛。
]

#image("images/2024-03-18-21-06-49.png")

Emmm…… Textbooks will tell you that if you always lock in the same order, you
will never get this kind of deadlock. *Practice will tell you that this approach doesn't scale*: when I create a new lock, I don't understand enough of the kernel to figure out where in the 5000 lock hierarchy it will fit.

The best locks are encapsulated: they never get exposed in headers, and are never held around calls to non-trivial functions outside the same file. You can read through this code and see that it will never deadlock, because it never tries to grab another lock while it has that one. People using your code don't even need to know you are using a lock.

—— #link( "https://www.kernel.org/doc/html/latest/kernel-hacking/locking.html",)[ Unreliable Guide to Locking ] by Rusty Russell

- 最终犯错的还是人

#tip("Tip")[
    - 比如说项目里面用到了lock-ordering,但是实际的代码又不符合，希望这个时候编译器直接给个错误。
]

== Bug 的本质和防御性编程

=== 回顾：调试理论

程序 = 物理世界过程在信息世界中的投影

Bug = 违反程序员对 “物理世界” 的假设和约束

- Bug 违反了程序的 specification
  - 该发生的必须发生
  - 不该发生的不能发生
- Fault → Error → Failure

=== 编程语言与 Bugs

编译器/编程语言

- 只管 “翻译” 代码，不管和实际需求 (规约) 是否匹配
  - “山寨支付宝” 中的余额 balance
    - 正常人看到 0 → 18446744073709551516 都认为 “这件事不对” (“balance” 自带
      no-underflow 的含义)

怎么才能编写出 “正确” (符合 specification) 的程序？

- 证明：Annotation verifier (#link("https://dafny-lang.github.io/dafny/")[ Dafny ]), [
  Refinement types ]("https://dl.acm.org/doi/10.1145/113446.113468")
- 推测：Specification mining (#link("http://plse.cs.washington.edu/daikon/")[ Daikon ])
- 构造：#link("https://link.springer.com/article/10.1007/s10009-012-0249-7")[ Program sketching ]
- 编程语言的历史和未来
  - 机器语言 → 汇编语言 → 高级语言 → 自然编程语言

=== 回到现实

今天 (被迫) 的解决方法

- 虽然不太愿意承认，但始终假设自己的代码是错的
- (因为机器永远是对的)

然后呢？

- 首先，做好测试
- 检查哪里错了
- 再检查哪里错了
- 再再检查哪里错了
  - “防御性编程”
  - 把任何你认为可能 “不对” 的情况都检查一遍

=== 防御性编程：实践

_把程序需要满足的条件用 `assert` 表达出来。_

及早检查、及早报告、及早修复

- Peterson 算法中的临界区计数器
  - `assert(nest == 1);`
- 二叉树的旋转
  - `assert(p->parent->left == p || p->parent->right == p);`
- AA-Deadlock 的检查
  - `if (holding(&lk)) panic();`
  - xv6 spinlock 实现示例(非常好)

=== 防御性编程和规约给我们的启发

你知道很多变量的含义

```c
#define CHECK_INT(x, cond) \
 ({ panic_on(!((x) cond), "int check fail: " #x " " #cond); })
#define CHECK_HEAP(ptr) \
 ({ panic_on(!IN_RANGE((ptr), heap)); })
```

变量有 “typed annotation”

- `CHECK_INT(waitlist->count, >= 0);`
- `CHECK_INT(pid, < MAX_PROCS);`
- `CHECK_HEAP(ctx->rip);` `CHECK_HEAP(ctx->cr3);`
- 变量含义改变 → 发生奇怪问题 (overflow, memory error, ...)
  - 不要小看这些检查，它们在底层编程 (M2, L1, ...) 时非常常见
  - 在虚拟机神秘重启/卡住/...前发出警报

== 自动运行时检查

=== 动态程序分析

通用 (固定) bug 模式的自动检查

- ABBA 型死锁
- 数据竞争
- 带符号整数溢出 (undefined behavior)
- Use after free
- ……

动态程序分析：状态机执行历史的一个函数 f(τ)

- 付出程序执行变慢的代价
- 找到更多 bugs

=== Lockdep: 运行时 Lock Ordering 检查

Lockdep 规约 (Specification)

- 为每一个锁确定唯一的 “allocation site” - assert: 同一个 allocation site
  的锁存在全局唯一的上锁顺序

检查方法：printf

- 记录所有观察到的上锁顺序，例如

[x,y,z]⇒x→y,x→z,y→z

- 检查是否存在 x⇝y∧y⇝x
  - 我们有一个 “山寨版” 的例子

#link("https://jyywiki.cn/OS/OS_Lockdep.html")[ Lockdep 的实现 ]

- Since Linux Kernel 2.6.17, also in [ OpenHarmony
  ](https://gitee.com/openharmony)!

=== ThreadSanitizer: 运行时的数据竞争检查

并发程序的执行 trace

- 内存读写指令 (load/store)
- 同步函数调用
- Happens-before: program order 和 release acquire 的传递闭包

对于发生在不同线程且至少有一个是写的 x,y 检查

x≺y∨y≺x

- 实现：Lamport's Vector Clock
- [ Time, clocks, and the ordering of events in a distributed system
  ](https://dl.acm.org/doi/10.1145/359545.359563)

=== 更多的 Sanitizers

现代复杂软件系统必备的支撑工具

- #link("https://clang.llvm.org/docs/AddressSanitizer.html")[ AddressSanitizer ] (asan);
  ([ paper
  ](https://www.usenix.org/conference/atc12/technical-sessions/presentation/serebryany)):
  非法内存访问
  - Buffer (heap/stack/global) overflow, use-after-free, use-after-return,
    double-free, ...
  - Linux Kernel 也有 [ kasan
    ](https://www.kernel.org/doc/html/latest/dev-tools/kasan.html)
- #link("https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")[ ThreadSanitizer ]
  (tsan): 数据竞争
- #link("https://clang.llvm.org/docs/MemorySanitizer.html")[ MemorySanitizer ] (msan):
  未初始化的读取
- #link("https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")[ UBSanitizer ]
  (ubsan): undefined behavior
  - Misaligned pointer, signed integer overflow, ...
  - Kernel 会带着 -fwrapv 编译
- IntelliSanitize
  - 等你开发

== 操作系统实验中的防御性编程

=== 同学们面对的困境

理论很美好，现实很残酷

- 我们的框架直接运行在虚拟机上
  - 根本没法带这些 sanitizers
- 我们根本不可能 “观测每一次共享内存访问”
  - 直接摆烂
  - (困难是摆烂的第一原因)

另一种思路 (rule of thumb)

- 不实现 “完整” 的检查
- 允许存在误报/漏报
- 但实现简单、非常有用

=== 例子：Buffer Overrun 检查

Canary (金丝雀) 对一氧化碳非常敏感

- 用生命预警矿井下的瓦斯泄露 (since 1911)

计算机系统中的 canary

- “牺牲” 一些内存单元，来预警 memory error 的发生
- (程序运行时没有动物受到实质的伤害)

=== Canary 的例子：保护栈空间 (Stack Guard)

```c
#define MAGIC 0x55555555
#define BOTTOM (STK_SZ / sizeof(u32) - 1)
struct stack { char data[STK_SZ]; };

void canary_init(struct stack *s) {
  u32 *ptr = (u32 *)s;
  for (int i = 0; i < CANARY_SZ; i++)
    ptr[BOTTOM - i] = ptr[i] = MAGIC;
}

void canary_check(struct stack *s) {
  u32 *ptr = (u32 *)s;
  for (int i = 0; i < CANARY_SZ; i++) {
    panic_on(ptr[BOTTOM - i] != MAGIC, "underflow");
    panic_on(ptr[i] != MAGIC, "overflow");
  }
}
```

=== 烫烫烫、屯屯屯和葺葺葺

msvc 中 debug mode 的 guard/fence/canary

- 未初始化栈: 0xcccccccc
- 未初始化堆: 0xcdcdcdcd
- 对象头尾: 0xfdfdfdfd
- 已回收内存: 0xdddddddd
  - 手持两把锟斤拷，口中疾呼烫烫烫
  - 脚踏千朵屯屯屯，笑看万物锘锘锘
  - (它们一直在无形中保护你)

```py
(b'\xcc' * 80).decode('gb2312')
```

=== 防御性编程：低配版 Lockdep

不必大费周章记录什么上锁顺序

- 统计当前的 spin count
- 如果超过某个明显不正常的数值 (1,000,000,000) 就报告

```c
int count = 0;
while (xchg(&lk, LOCKED) == LOCKED) {
  if (count++ > SPIN_LIMIT) {
    panic("Spin limit exceeded @ %s:%d\n", __FILE__, __LINE__);
  }
}
```

- 配合调试器和线程 backtrace 一秒诊断死锁

=== 防御性编程：低配版 AddressSanitizer (L1)

内存分配要求：已分配内存 `S=[ℓ0  ,r0 )∪[ℓ1  ,r1 )∪…`

- `kalloc(s)` 返回的 [ℓ,r) 必须满足 [ℓ,r)∩S=∅
  - thread-local allocation + 并发的 free 还蛮容易弄错的

```c
// allocation
for (int i = 0; (i + 1) _ sizeof(u32) <= size; i++) {
    panic_on(((u32 _)ptr)[i] == MAGIC, "double-allocation");
    arr[i] = MAGIC;
}

// free
for (int i = 0; (i + 1) _ sizeof(u32) <= alloc_size(ptr); i++) {
    panic_on(((u32 _)ptr)[i] == 0, "double-free");
    arr[i] = 0;
}
```
