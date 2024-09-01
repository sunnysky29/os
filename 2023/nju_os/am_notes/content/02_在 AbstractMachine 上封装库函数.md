# 在 AbstractMachine 上封装库函数
## Klib: 操作系统内核最小的运行库

AbstractMachine 提供的 API 只是 “最少” 的、用于访问硬件的 API。如果你希望写一点真正的代码，必定会涉及许多应用逻辑，常用的内存/字符串处理、抽象数据类型……我们给大家列出了一些你们在实现操作系统中可能会用到的函数，它们看起来就像是 C 标准库的子集。

### 1\. 常用 C 语言函数 (klib.h)

```c
// string.h
void  *memset    (void *s, int c, size_t n);
void  *memcpy    (void *dst, const void *src, size_t n);
void  *memmove   (void *dst, const void *src, size_t n);
int    memcmp    (const void *s1, const void *s2, size_t n);
size_t strlen    (const char *s);
char  *strcat    (char *dst, const char *src);
char  *strcpy    (char *dst, const char *src);
char  *strncpy   (char *dst, const char *src, size_t n);
int    strcmp    (const char *s1, const char *s2);
int    strncmp   (const char *s1, const char *s2, size_t n);

// stdlib.h
void   srand     (unsigned int seed);
int    rand      (void);
void  *malloc    (size_t size);
void   free      (void *ptr);
int    abs       (int x);
int    atoi      (const char *nptr);

// stdio.h
int    printf    (const char *format, ...);
int    sprintf   (char *str, const char *format, ...);
int    snprintf  (char *str, size_t size, const char *format, ...);
int    vsprintf  (char *str, const char *format, va_list ap);
int    vsnprintf (char *str, size_t size, const char *format, va_list ap);
```

我们虽然声明了这些函数，但如果你调用它们的话，会得到一个无情的 panic。查看代码会发现所有这些函数虽然定了实现，但却无一例外是 “空的”。没错，这些库函数是用 C 语言和 AbstractMachine 共同实现的——我们已经准备好了抽象层，那么剩下的任务就是编程习题了。关于这些函数，Linux manpages 是很不错的起点 (而不是对它们的行为想当然)——你不必实现得和系统完全一致，毕竟这些函数的使用者是你们自己。

```c
int printf(const char *fmt, ...) {
  panic("Not implemented");
}
```

### 2\. 一些有用的宏 (klib-macros.h)

比起上面的库，我们还给大家提供了很多有意义的宏。宏的实现比库要难一些 (通常大家熟练程度会低一些)，所以我们就代劳了。首先是最重要的一系列辅助调试的宏：

```c
#define assert(cond) \
  do { \
    if (!(cond)) { \
      printf("Assertion fail at %s:%d\n", __FILE__, __LINE__); \
      halt(1); \
    } \
  } while (0)

#define static_assert(const_cond) \
  static char CONCAT(_static_assert_, __LINE__) [(const_cond) ? 1 : -1] __attribute__((unused))

#define panic_on(cond, s) \
  ({ if (cond) { \
      putstr("AM Panic: "); putstr(s); \
      putstr(" @ " __FILE__ ":" TOSTRING(__LINE__) "  \n"); \
      halt(1); \
    } })

#define panic(s) panic_on(1, s)
```

可不要低估这些看似 “没用” 的宏——你的程序里充满了可能出现 bug 的地方，而进行防御性地检查是帮助你快速定位 bug 的最佳方案，否则等到虚拟机重启/crash 的时候再进行调试，付出的代价可以就多多了。

此外，我们还封装了一些大家可能会用到的函数，例如二进制整数的取证 (在内存管理时非常有用)、数组的长度、区间的包含关系等：
```c
#define ROUNDUP(a, sz)      ((((uintptr_t)a) + (sz) - 1) & ~((sz) - 1))
#define ROUNDDOWN(a, sz)    ((((uintptr_t)a)) & ~((sz) - 1))
#define LENGTH(arr)         (sizeof(arr) / sizeof((arr)[0]))
#define RANGE(st, ed)       (Area) { .start = (void *)(st), .end = (void *)(ed) }
#define IN_RANGE(ptr, area) ((area).start <= (ptr) && (ptr) < (area).end)
#define putstr(s) \
  ({ for (const char *p = s; *p; p++) putch(*p); })
```


如果想使用 I/O 设备，下面的宏也对 low-level 的 AbstractMachine API 作了一点小小的包装：

```c
#define io_read(reg) \
  ({ reg##_T __io_param; \
    ioe_read(reg, &__io_param); \
    __io_param; })

#define io_write(reg, ...) \
  ({ reg##_T __io_param = (reg##_T) { __VA_ARGS__ }; \
    ioe_write(reg, &__io_param); })
```

这可以使得你可以直接读出/写入设备寄存器而无需定义变量，值得大家花一点时间研究。

### 3\. 更多的库函数

以上并不是实现操作系统你所需的全部。实现抽象数据类型，例如列表、队列等，会使你事半功倍，不必在复杂、难度的代码泥潭中挣扎。其中一个非常好的例子就是 Linux 的 `list_head`。交给大家 RTFM 啦！当然，大家在实现 “最小” 操作系统的时候，可以采用更简单的办法，例如长度固定的数组，这样可以更容易地写出正确的代码。
