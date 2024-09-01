# AbstractMachine 规约 (Specifications)

## 1\. 基本概念

AbstractMachine 上运行的程序称为 “kernel” (内核)。这个名字通常表示直接运行在硬件上、对硬件有直接控制的代码。不仅是操作系统内核，像在 GPU 上运行的二进制文件也称为 “kernel”。

AbstractMachine 上的 kernel 被编译成一个目标体系结构/平台上可执行的文件，并可以直接在环境 (如计算机硬件、虚拟机等) 上执行，例如：

- x86 (x86 32-bit), qemu (模拟器)
- x86_64 (x86 64-bit), qemu (模拟器)
- riscv64 (RISC-V 64-bit), nemu (模拟器)
- native (作为本地进程运行)

在《操作系统》实验中，请大家以 x86_64-qemu 为基准平台，其他实现作为参考。

## 2\. TRM (Turing Machine): C 语言运行环境

Kernel 是一个 C 语言书写的程序。C 程序执行的状态包括：

- 栈，概念上，包含函数调用栈帧的链表，每一帧都有独立的 PC (程序计数器)、参数和局部变量。
- 只读代码。
- 只读数据，写入只读数据 (如常量字符串) 将导致 undefined behavior。
- 读写数据，包括所有静态变量和一个可用的堆区。

以上所有的状态都存储在同一个平坦的地址空间中，并可以使用指针访问 (栈、代码、数据、堆区互不相交且连续存储)；内存的非法访问是 undefined behavior。我们不妨假定执行一条语句会从状态 $s$ 迁移到 $s'$，记作 $s\\to s'$。

Kernel 执行的具体约定：

- Kernel 被 TRM 加载，从 `main` 开始运行；
- `main` 运行时带有一个参数 `const char *args`，允许程序启动时传递一个字符串参数：
  - 在运行 (`make run`) 时设置 `mainargs` 环境变量，即可向 kernel 传递参数
  - 参数字符串的长度 (包含末尾的 `\0`) 不超过 1024 字节
- Kernel 在运行时遵循状态机的执行，其中：
  - 可使用的堆栈大小不少于 4 KiB
  - 堆区的大小和位置在运行时确定，通过 `heap` 变量获取

Kernel 在运行时允许调用 AbstractMachine API，此时的状态迁移 $s\\to s'$ 由 AbstractMachine 定义。

### 2.1. `Area` 结构体

```c
typedef struct Area {
  void *start, *end;
} Area;
```

表示左闭右开区间 `[start, end)` 的一段内存。我们假设地址空间的最后一个字节 (例如 32-bit 平台下地址 `0xffffffff`) 永远不会被包含在某个 `Area` 中，因此 `end` 不会溢出。内存区间

```c
(Area) {
  .start = (void *)0;
  .end   = (void *)0xffffffff;
}
```

的最后一个字节的地址是 `0xfffffffe`。`klib-macros.h` 提供了一些区间的构造/判断的宏：

```c
#define RANGE(st, ed)       (Area) { .start = (void *)(st), .end = (void *)(ed) }
#define IN_RANGE(ptr, area) ((area).start <= (ptr) && (ptr) < (area).end)
```

### 2.2. `heap`: 物理内存堆区

```c
extern Area heap;
```

标记一段连续的、代码可以使用的物理内存 `[heap.start, heap.end)`，这段内存 (堆区) kernel 可以任意读写。

**多处理器：安全**。`heap` 在 `main` 被调用前初始化，之后则不会改变 (任意处理器都可以自由读取它)。修改 `heap` 导致 undefined behavior；Kernel 没有任何理由需要修改它。

### 2.3. `putch`: 打印字符

```c
void putch(char ch);
```

向默认的调试终端打印 ASCII 码为 `ch` 的字符：

- 对 x86 (x86-64) QEMU 平台，向 COM1 输出，通过 QEMU 的 `-serial` 可以选择输出位置。
- 对 native 平台，输出到 stdout。
- 对真实的硬件平台，向调试串口输出。

**多处理器：安全**。putch 是最基本的调试功能，因此 AbstractMachine 的实现负责保证它在多处理器上的安全性。

### 2.4. `halt`: 终止 AbstractMachine

```c
void halt(int code) __attribute__((__noreturn__));
```

立即终止整个 AbstractMachine 的运行，并返回数字编号 `code` (0-255)：

- 对 QEMU 平台，虚拟机将直接终止，终止前会向调试终端打印信息 (例如返回代码)。
- 对 native 平台，代码将退出，进程的返回代码为 `code`。
- 对真实的硬件平台，根据硬件的支持关闭或进入死循环状态。

**多处理器：安全**。在任意处理器上执行 `halt` 都会终止整个 Kernel 的执行。

## 3\. MPE (Multi-Processing Extension) 共享内存多处理器

进入共享内存多处理器模式。假设系统中有 $n$ 个处理器，在完成 MPE 初始化后，系统中就有多个并行执行、共享内存且拥有独立堆栈的状态机。

**数据竞争**：两个处理器同时 (在状态机模型中意味着先后) 访问一个共享内存位置，并且至少有一个是写是数据竞争。数据竞争 (data race) 在 AbstractMachine 是 undefined behavior，应当严格避免。

### 3.1. `mpe_init`: 启动多处理器

```c
int mpe_init(void (*entry)());
```

启动系统中多处理器的执行，每个处理器都跳转到 `entry` 开始执行，执行流共享代码、数据；每个执行流有独立的堆栈和寄存器。

**限制**：在一次 kernel 运行中，只能调用一次 (多次调用后)，且调用后 `entry` 不能返回。

### 3.2. `cpu_count`: 处理器个数

```c
int cpu_count();
```

返回系统中处理器的个数，在整个 AbstractMachine 执行期间数值不会变化。

**多处理器：安全**。由于处理器数量不变，因此 `cpu_count` 的实现通常实现是一个共享内存 (或设备寄存器) 的读操作。编程时 (例如实现操作系统时) 你可以假设系统中处理器的个数不超过 8 个。

### 3.3. `cpu_current`: 当前处理器编号

```c
int cpu_current();
```

返回当前执行流的 CPU 编号，从 `0` 开始，例如 `cpu_count() == 4`，则在四个 CPU 上分别调用 `cpu_current()` 将分别得到 `0`, `1`, `2`, `3`。

**多处理器：安全**。任何处理器在任何时候皆可调用。

### 3.4. `atomic_xchg`: 内存交换

```c
int atomic_xchg(volatile int *addr, int newval);
```

原子 (不会被其他处理器的原子操作打断) 地交换内存地址中的数值，等价于以下 C 代码：

```c
int atomic_xchg(volatile int *addr, int newval) {
  int *ret = *addr;
  *addr = newval;
  return ret;
}
```

**多处理器：安全**。你可以假设这是 Kernel 中唯一支持的原子操作，可以用于消除数据竞争。如果你希望使用更复杂的原子操作，在支持的体系结构上可以考虑 `stdatomic.h` 和 GCC builtin 的函数。

## 4\. IOE (I/O Extension) 设备管理

为了实现操作系统提供的一些基础的 I/O 设备访问。在 AbstractMachine 中，我们对常见的设备进行了抽象，把它们简化为了一组可以读或写的控制寄存器，通过读/写这些寄存器实现设备状态的读取和控制。

### 4.1. `ioe_init`: 初始化 I/O 扩展

```c
bool ioe_init();
```

完成系统中 I/O 设备的初始化。

**限制**：在一次 kernel 运行中只能调用一次，且必须在 `mpe_init` 之前。

### 4.2. `ioe_read/ioe_write`: I/O 设备读写

```c
void ioe_read (int reg, void *buf);
void ioe_write(int reg, void *buf);
```

从编号为 `reg` 的寄存器读取/写入，读取/写入的数据取决于寄存器的编号。设备可能会对寄存器的使用作出额外的规定，请参考 [Abstract Machine 设备文档](https://jyywiki.cn/OS/AbstractMachine/AM_Devices.html)。为了减少大家定义额外的变量，我们推荐使用 klib-macros.h 中封装后的宏访问设备，例如：

```c
*rtc = io_read(AM_TIMER_RTC);
io_read(AM_GPU_STATUS).ready;
io_write(UART_TX, 'X');
```

**多处理器：不安全**：对同一个 I/O 设备的访问必须互斥。值得额外注意的是，`ioe_read` 和 `ioe_write` 的代码可以被 CTE 中断 (这是允许的)。但 Kernel 需要保证在任意时刻对同一个设备只允许有一个尚未返回的 `ioe_read` 或 `ioe_write` 操作，否则将导致 undefined behavior。

## 5\. CTE (Context Extension) 上下文和中断管理

TRM、MPE 和 IOE 能够运行多个处理器上的顺序程序，多个共享内存的执行流 (处理器) 总是执行当前指令。CTE **允许 kernel 管理异步的执行流，允许每个处理器分别在中断/异常发生时执行代码，并保存/切换到其他执行流**。

CTE 允许在程序执行中引入以下异常 (trap) 控制流，包括以下来源：

- 处理器外部中断 (时钟、I/O 设备)
- 指令执行产生的异常 (主动执行的 trap 指令和 undefined behavior 导致的错误)
- 对于 VME ucontext 创建的用户上下文，访问映射权限违反的地址产生的缺页

在异常 (trap) 发生后，会**借用当前执行流的栈**，在栈上保存额外的数据后**关闭中断**，然后**直接在当前栈上**调用 cte_init 时注册好的 handler 函数。handler 返回一个指向执行流的指针，并切换到该执行流执行。

**多处理器：分别响应中断和异常**。当系统中有多个处理器时，每个处理器都可能同时发生中断/异常；但 AbstractMachine 代码实现保证中断处理仅涉及处理器自身的状态 (但会修改处理器的内核栈)。因此 `cte_init` 中注册的处理程序应当小心数据竞争的发生。

### 5.1. `cte_init`: 初始化上下文扩展

```c
bool cte_init(Context *(*handler)(Event ev, Context *ctx));
```

注册中断/系统调用处理程序：在中断/异常/系统调用时，AbstractMachine 会立即保存当前执行流的上下文 (Context, 包括寄存器现场等) 到当前执行流的内核栈 (栈空间由 kcontext/ucontext 指定)，然后调用 `handler`，其中参数 `ev` 是事件的类型：

- `EVENT_ERROR` - 非法访问的异常，例如 #GP
- `EVENT_IRQ_TIMER` - 时钟中断
- `EVENT_IRQ_IODEV` - I/O 设备中断 (键盘、串口……)
- `EVENT_PAGEFAULT` - 缺页异常
- `EVENT_SYSCALL` - 系统调用
- `EVENT_YIELD` - `yield()` 自陷

而 `ctx` 是指向保存在当前执行流信息的指针。`handler` 可以返回任何合法的 `Context` (可以由 `kcontext` 创建，或者是某个 `handler` 保存的参数)。

**限制**：在一次 kernel 运行中只能调用一次，且必须在 `mpe_init` 之前。可以在 IOE 之前或之后初始化。

**ctx 的生存周期**：每个处理器都有一个正在运行的执行流，它可能是：

- MPE 未启动时的 `main` 函数的执行，它使用 AbstractMachine (TRM) 初始化时的内核栈；
- MPE 启动后 `mp_entry` 函数的执行，每个处理器的 `mp_entry` 执行都拥有独立的内核栈；
- 其他由 `kcontext` 创建的上下文在 CPU 上的执行，创建时会指定一个内核栈。

在中断/异常发生后，中断/异常返回时的 context 将会被保存在当前执行流的堆栈上。只有当这个执行流被调度执行 (唯一被调度执行的可能是 `handler()` 的返回) 后被弹出堆栈。也就是说，如果 `handler` 返回到另一个上下文，那么 `ctx` 指针指向的上下文将一直保持有效，直到这一上下文被再次调度或内核栈被释放。

**栈的使用**：因为 trap 会借用当前执行流的堆栈，因此必须保证**当前执行流完全清除栈上的内容后才可以将执行流在另一个处理器上开始执行**。

### 5.2. `iset/ienabled`: 外部中断管理

```c
bool ienabled(void);
void iset(bool enable);
```

读取/写入当前处理器的中断打开/屏蔽状态。其中 `ienabled/iset` 的 `true`/`false` 分别表示中断打开/关闭。注意中断关闭只能屏蔽处理器外的中断 (即 `EVENT_IRQ_TIMER` 和 `EVENT_IRQ_IODEV`)，处理器同步产生的 error, page fault, syscall 和 yield 不能屏蔽。

**多处理器：安全**：每个处理器都有自己独立的中断标志位；`ienabled/iset` 仅能影响当前执行指令 CPU 的中断标志位，不能关闭/查询其他处理器的中断状态。

### 5.3. `yield`: Self-Trapping

```c
void yield();
```

陷入内核执行，将会在当前处理器上调用 `handler(EVENT_YIELD, saved_context)`，其中 `saved_context` 是保存的当前内核上下文。

**多处理器：安全**：执行 `yield` 的当前处理器会完成 self-trapping。

### 5.4. `kcontext`: 创建内核态运行的上下文

```c
Context *kcontext(Area kstack, void (*entry)(void *), void *arg);
```

将 `kstack` 表示的一段内存作为内核栈中创建一个可执行的内核态上下文，返回的 `Context` 指针可以在中断返回时被调度到处理器上执行。首次执行返回的上下文中 PC 为 `entry`，并正确为 `entry` 函数传递了 `arg` 参数。

**多处理器：安全**，但要注意 kstack 区域的合法性，例如 data race 或 double allocation 都导致 undefined behavior。

## 6\. VME (Virtual Memory Extension) 虚拟地址空间

VME 允许为执行流 (上下文 Context) 赋予一个 “虚拟” 的内存视图，每当访问任何内存 $x$ 的时候，都取访问 $f(x)$。VME 提供了描述、修改数据结构 $f$ 的机制。

**限制**：在一次 kernel 运行中只能调用一次，且必须在 `mpe_init` 之前。

### 6.1. `vme_init`: 初始化虚存管理

```c
bool vme_init(void *(*pgalloc)(int), void (*pgfree)(void *));
```

初始化虚拟存储。`pgalloc`、`pgfree` 函数分别用于一个物理页面的分配和回收。注意 `vme_init` 执行时就可能调用 `pgalloc`/`pgfree`，你需要确保它们在 vme_init 调用时处于可用状态。

**多处理器：注意**：pgalloc/pgfree 会在 protect, unprotect 和 map 中被调用，因此请确保你的 pgalloc/pgfree 是多处理器安全的。

### 6.2. `protect`/`unprotect`: 地址空间管理

```c
void protect(AddrSpace *as);
void unprotect(AddrSpace *as);
```

创建/销毁一个地址空间，其中 `protect(as)` 后，`as` 会被初始化：

- `as->pgsize` 是页面的大小 (AbstractMachine 可能返回与实际机器不同的页面大小)。
- `as->area` 是被保护的 (用户态可访问) 地址空间范围。
- `as->ptr` 是 AbstractMachine 私有的指针，例如 x86-qemu 的实现是 CR3 寄存器的数值。

**多处理器：注意**。protect/unprotect 会调用 pgalloc/pgfree 分配或释放页面，并会写入 `as`。

### 6.3. `map`: 修改地址空间映射

```c
void map(AddrSpace *as, void *vaddr, void *paddr, int prot);
```

对地址空间 `as` 建立 `vaddr` $\\to$ `paddr` 的映射，当 `paddr` 为 `NULL` 时，取消该页面的映射。prot 由以下 flag 组成。注意 `vaddr` 和 `paddr` 必须对齐到页面边界 (`as->pgsize`)，且 `vaddr` 必须位于 `as->area`、`paddr` 指向的页面位于 `heap`。

```c
#define MMAP_NONE  0x00000000 // no access
#define MMAP_READ  0x00000001 // can read
#define MMAP_WRITE 0x00000002 // can write
```

**多处理器：注意**。map 会调用 pgalloc/pgfree 分配或释放页面。

### 6.4. `ucontext`: 创建被保护的用户态进程上下文

```c
Context *ucontext(AddrSpace *as, Area kstack, void *entry);
```

与 `kcontext` 类似，创建一个可被调度执行的上下文，它的执行位于低权限的用户态，地址空间由 `as` 指定，初始 PC 为 `entry`。在用户态发生中断/异常会切换到内核态 (kernel) 运行，并切换到内核栈。中断/异常处理程序 (包括保存的上下文) 都存储在 `kstack` 指定的内核栈。

**多处理器：安全**。`ucontext` 仅修改 `kstack` 中的数值，并在其中创建上下文。
