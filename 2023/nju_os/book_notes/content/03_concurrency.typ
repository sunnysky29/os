#import "../template.typ": *
#pagebreak()
= Concurrency

== Introduction to Concurrency

- threads: own PC, private registers, private stack, shared address space
- process control block (PCB): to store the state of a processes
- thread control blocks (TCBs): to store the state of each thread of a process.

if there are two threads that are running on a single processor, when switching from running one (T1) to running the other (T2), *a context switch* must take place

#image("images/2023-10-30-21-38-29.png", width: 60%)

=== Why Use Threads

- Parallelism(尽可能多用 CPU)
- To avoid blocking program progress due to slow I/O

=== An Example: Thread Creation

```c
#include <assert.h>
#include <pthread.h>
#include <stdio.h>

void *mythread(void *arg) {
    printf("%s\n", (char *)arg);
    return NULL;
}
int main() {
    pthread_t p1, p2;
    int rc;
    printf("main: begin\n");
    pthread_create(&p1, NULL, mythread, "A");
    pthread_create(&p2, NULL, mythread, "B");

    // wait for the thread to complete
    pthread_join(p1, NULL);
    pthread_join(p2, NULL);
    printf("main: begin\n");

    return 0;
}
```

#image("images/2023-10-30-21-42-03.png", width: 60%)
#image("images/2023-10-30-21-42-14.png", width: 60%)
#image("images/2023-10-30-21-42-22.png", width: 60%)

```c
#include <assert.h>
#include <pthread.h>
#include <stdio.h>

static volatile int counter = 0;

void *mythread(void *arg) {
    printf("%s: begin\n", (char *)arg);
    int i;
    for (i = 0; i < 1e7; i++) {
        counter = counter + 1;
    }
    printf("%s: done\n", (char *)arg);
    return NULL;
}

int main() {
    pthread_t p1, p2;
    int rc;
    printf("main: begin (counter = %d)\n", counter);
    pthread_create(&p1, NULL, mythread, "A");
    pthread_create(&p2, NULL, mythread, "B");

    pthread_join(p1, NULL);
    pthread_join(p2, NULL);
    printf("main: done with both (counter = %d)\n", counter);

    return 0;
}
```

output:

```sh
❯ ./test
main: begin (counter = 0)
A: begin
B: begin
A: done
B: done
main: done with both (counter = 10921243)
❯ ./test
main: begin (counter = 0)
A: begin
B: begin
B: done
A: done
main: done with both (counter = 10472806)
```

*Threads make life complicated*

==== The Heart Of The Problem: Uncontrolled Scheduling

Disassemble `counter = counter + 1;`

```asm
100 mov 0x8049a1c, %eax     // %eax = counter
105 add $0x1, %eax          // %eax = %eax + 1
108 mov %eax, 0x8049a1c     // counter = %eax
```

> suppose that the variable `counter` is located at address `0x8049a1c`.
> x86 has variable-length instructions; this `mov` instruction takes up 5 bytes of memory, and the `add` only 3

#image("images/2023-10-31-21-07-52.png")

*Synchronization primitives(hardware support) + some help from the operating system*, we will be able to build multi-threaded code that accesses critical sections in a synchronized and controlled manner.

=== key concurrency terms

- A *critical section* is a piece of code that accesses a shared resource, usually a variable or data structure.
- A *race condition* (or *data race* [NM92]) arises if multiple threads of execution enter the critical section at roughly the same time; both attempt to update the shared data structure, leading to a surprising outcome.
- An *indeterminate* program consists of one or more race conditions; the output of the program varies from run to run, depending on which threads ran when. The outcome is thus *not deterministic*, something we usually expect from computer systems.
- To avoid these problems, threads should use some kind of *mutual exclusion* primitives; doing so guarantees that only a single thread ever enters a critical section, thus avoiding races, and resulting in deterministic program outputs.

== Interface: Thread API

*better used as a reference*

=== Thread Creation

```c
#include <pthread.h>
int pthread_create(
    // init object
    pthread_t *thread,
    // stack size/scheduling priority/...
    const pthread_attr_t *attr,
    // function
    void * (*start_routine)(void*),
    // args for function
    void * arg
);
```

`void *` allows "any"

=== Thread Completion

```c
int pthread_join(
    // which one to wait
    pthread_t thread,
    // return value
    void *value_ptr
);
```

example:

```c
typedef struct __myarg_t {
    int a;
    int b;
} myarg_t;

typedef struct __myret_t {
    int x;
    int y;
} myret_t;

 void *mythread(void *arg) {
    myarg_t *m = (myarg_t *) arg;
    printf("%d %d\n", m->a, m->b);
    myret_t *r = malloc(sizeof(myret_t));
    r->x = 1;
    r->y = 2;
    return (void *) r;
 }

int main(int argc, char *argv[]) {
    pthread_t p;
    myret_t *m;

    myarg_t args = {10, 20};
    Pthread_create(&p, NULL, mythread, &args);

    // (void *) &m = (void *) r
    Pthread_join(p, (void *) &m);
    printf("returned %d %d\n", m->x, m->y);
    free(m);
    return 0;
}
```

> 不能返回函数栈中的地址, 因为栈弹出后, 地址会被"清理".

=== Locks

locks<->critical section

```c
int pthread_mutex_lock(pthread_mutex_t *mutex);
int pthread_mutex_unlock(pthread_mutex_t *mutex);
```

example:

```c
pthread_mutex_t lock;
pthread_mutex_lock(&lock);
x = x + 1; // or whatever your critical section is
pthread_mutex_unlock(&lock);
```

But *No init! No check error code!*

`pthread_mutex_t` must be initialized:

- `PTHREAD_MUTEX_INITIALIZER`
  - `pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;`
- `pthread_mutex_init(..)`(runtime)
  ```c
  int rc = pthread_mutex_init(&lock, NULL);
  assert(rc == 0); // always check success!
  // an example warpper
  // Use this to keep your code clean but check for failures
  // Only use if exiting program is OK upon failure
  void Pthread_mutex_lock(pthread_mutex_t *mutex) {
      int rc = pthread_mutex_lock(mutex);
      assert(rc == 0);
  }
  ```
  > Note that a corresponding call to `pthread_mutex_destroy()` should also be made, when you are done with the lock

When does a thread acquire the lock?

- No other thread holds the lock: acquire the lock.
- Another thread hold the lock: wait util acquire the lock.

```c
// returns after a timeout or after acquiring the lock, whichever happens first
int pthread_mutex_timedlock(pthread_mutex_t *mutex, struct timespec *abs_timeout);
// returns failure if the lock is already held;
// special version withe a timeout of zero
int pthread_mutex_trylock(pthread_mutex_t *mutex);
```

> Both of these versions should generally be avoided; however, there are a few cases where avoiding getting stuck.

=== Condition Variables

```c
// put the calling thread to sleep
// and thus waits for some other thread to signal it
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex);
int pthread_cond_signal(pthread_cond_t *cond);
```

example:

```c
// T1
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;

Pthread_mutex_lock(&lock);
while (ready == 0)
    // release the lock when sleeping
    Pthread_cond_wait(&cond, &lock);
Pthread_mutex_unlock(&lock);

// T2
// when signaling, the thread must be locked
Pthread_mutex_lock(&lock);
ready = 1;
Pthread_cond_signal(&cond);
Pthread_mutex_unlock(&lock);
```

t2(has the lock held, signaling) --wake up--> t1(waiting) --> t1 reacquire the lock

A lazy way?

```c
// waiting
while (ready == 0)
    ; // spin

// signaling
ready = 1;
```

*Don't ever do this!!!*

=== Compiling and Running

To compile them, you must include the header `pthread.h` in your code. On the link line, you must also explicitly link with the `pthreads` library, by adding the `-pthread` flag.

```sh
prompt> gcc -o main main.c -Wall -pthread
```

=== THREAD API GUIDELINES

- Keep it simple. As simple as possible.
- Minimize thread interactions.
- Initialize locks and condition variables.
- Check your return codes.
- Be careful with how you pass arguments to, and return values from, threads.
- Each thread has its own stack.
- Always use condition variables to signal between threads.
- Use the manual pages.

== Locks

=== Locks: The Basic Idea

A lock is just a variable.
It is either unlocked and thus no thread holds the lock, or locked, and thus exactly one thread holds the lock and presumably is in a critical section.

> We could store other information in the data type as well. (Such as which thread holds the lock, or a queue for ordering lock acquisition)

The semantics of the `lock()` and `unlock()` routines are simple.

- Calling the routine `lock()` tries to acquire the lock; if no other thread holds the lock, the thread will acquire the lock and enter the critical section
  > this thread is sometimes said to be *the owner of the lock*.
- If another thread then calls `lock()` on that same lock variable, it will not return while the lock is held by another thread; in this way, other threads are prevented from entering the critical section while the first thread that holds the lock is in there.
- Once the owner of the lock calls `unlock()`, the lock is now available (free) again. If no other threads are waiting for the lock, the state of the lock is simply changed to free. If there are waiting threads, one of them will notice (or be informed of) this change of the lock's state, acquire the lock, and enter the critical section.

Thus locks help transform the chaos that is traditional OS scheduling into a more controlled activity.

=== Pthread Locks

The name that the POSIX library uses for a lock is a `mutex`, as it is used to provide *mutual exclusion* between threads.

We use our wrappers that check for errors upon lock and unlock.

```c
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

Pthread_mutex_lock(&lock); // wrapper; exits on failure
balance = balance + 1;
Pthread_mutex_unlock(&lock);
```

We may be using different locks to protect different variables. Doing so can increase concurrency:

- instead of one big lock that is used any time any critical section is accessed (*a coarse-grained locking strategy*), one will often protect different data and data structures with different locks, thus allowing more threads to be in locked code at once (*a more fine-grained approach*)

=== Building A Lock

How should we build a lock? What hardware support is needed? What OS support?

=== Evaluating Locks

We should first understand what our goals are, and thus we ask how to evaluate the efficacy of a particular lock implementation. To evaluate whether a lock works (and works well), we should first establish some basic criteria.

- The first is whether the lock does its basic task, which is *to provide mutual exclusion*.
  - Basically, does the lock work, preventing multiple threads from entering a critical section?
- The second is *fairness*.
  - Does each thread contending for the lock get a fair shot at acquiring it once it is free?
  - Does any thread contending for the lock starve while doing so?
- The final criterion is *performance*, specifically the time overheads added by using the lock. There are a few different cases that are worth considering here.
  - One is the case of no contention; when a single thread is running and grabs and releases the lock, what is the overhead of doing so?
  - Another is the case where multiple threads are contending for the lock on a single CPU; in this case, are there performance concerns?
  - Finally, how does the lock perform when there are multiple CPUs involved, and threads on each contending for the lock?

=== Controlling Interrupts

One of the earliest solutions used to provide mutual exclusion was to *disable interrupts for critical sections;* this solution was invented for single-processor systems. The code would look like this:

```c
void lock() {
    DisableInterrupts();
}
void unlock() {
    EnableInterrupts();
}
```

The main positive of this approach is its *simplicity*. Without interruption, a thread can be sure that the code it executes will execute and that no other thread will interfere with it.

The negatives, unfortunately, are many.

- Fist, this approach requires us to allow any calling thread to perform *a privileged operation*, and thus trust that this facility is not abused. Here, the trouble manifests in numerous ways:
  - a greedy program could call `lock()` at the beginning of its execution and thus monopolize the processor;
  - worse, an errant or malicious program could call `lock()` and go into an endless loop. In this latter case, the OS never regains control of the system, and there is only one recourse: reboot.
    > Using interrupt disabling as a general purpose synchronization solution requires *too much trust* in applications.
- Second, the approach *does not work on multiprocessors*. If multiple threads are running on different CPUs, and each try to enter the same critical section, it does not matter whether interrupts are disabled; threads will be able to run on other processors, and thus could enter the critical section.
- Third, turning off interrupts for extended periods of time can *lead to interrupts becoming lost*, which can lead to serious systems problems.
  - For example, if the CPU missed the fact that a disk device has finished a read request. How will the OS know to wake the process waiting for said read?
- Finally, and probably least important, this approach can be *inefficient*. Compared to normal instruction execution, code that masks or unmasks interrupts tends to be executed slowly by modern CPUs.

For these reasons, turning off interrupts is only used in limited contexts as a mutual-exclusion primitive.
For example, in some cases an operating system itself will use interrupt masking to guarantee atomicity when accessing its own data structures, or at least to prevent certain messy interrupt handling situations from arising. This usage makes sense, as the trust issue disappears inside the OS, which always trusts itself to perform privileged operations anyhow.

=== A Failed Attempt: Just Using Loads/Stores

We will have to rely on CPU hardware and the instructions it provides us to build a proper lock.

Let's first try to build a simple lock by using a single flag variable.

```c
typedef struct __lock_t { int flag; } lock_t;

void init(lock_t *mutex) {
    // 0 -> lock is available, 1 -> held
    mutex->flag = 0;
}

void lock(lock_t *mutex) {
    while (mutex->flag == 1) // TEST the flag
    ; // spin-wait (do nothing)
    mutex->flag = 1; // now SET it!
}

void unlock(lock_t *mutex) {
    mutex->flag = 0;
}
```

In our imagination:
The first thread that enters the critical section will call `lock()`, which tests whether the flag is equal to 1 (in this case, it is not), and then sets the flag to 1 to indicate that the thread now holds the lock. When finished with the critical section, the thread calls `unlock()` and clears the flag, thus indicating that the lock is no longer held.
If another thread happens to call `lock()` while that first thread is in the critical section, it will simply spin-wait in the while loop for that thread to call `unlock()` and clear the flag. Once that first thread does so, the waiting thread will fall out of the while loop, set the flag to 1 for itself, and proceed into the critical section.

Unfortunately, the code has two problems: one of `correctness`, and another of `performance`.

- The correctness problem is simple to see once you get used to thinking about concurrent programming. Imagine the code interleaving below; assume `flag=0` to begin.
  #image("images/2023-12-23-20-36-40.png", width: 70%)
  > we have obviously failed to provide the most basic requirement: providing *mutual exclusion*.
  > *Remember this situation in mind. Spin locks below just make the interrupt after "while" disappear to solve the problem.*
- The performance problem, is the fact that the way a thread waits to acquire a lock that is already held: it endlessly checks the value of flag, a technique known as *spin-waiting*.
  - Spin-waiting wastes time waiting for another thread to release a lock. The waste is exceptionally high on a uniprocessor, where the thread that the waiter is waiting for cannot even run (at least, until a context switch occurs)!

=== Peterson's algorithm

```c
int flag[2];
int turn;

void int(){
    // indicate you intend to hold the lock w/ 'flag'
    flag[0] = flag[1] = 0;
    // whose turn is it? (thread 0 or 1)
    turn = 0;
}

void lock(){
    // 'self' is the thread ID of caller
    flag[self] = 1;
    // make it other thread's turn
    turn = 1 - self;
    while((flag[1-self] == 1) && (turn == 1 - self))
    ; // spin-wait while it's not your turn
}

void unlock(){
    // simply undo your intent
    flag[self] = 0;
}
```

No hardware support. Don't work on modern hardware (due to relaxed memory consistency models)

=== BuildingWorking Spin Locks with Test-And-Set

System designers started to invent hardware support for locking.

The simplest bit of hardware support to understand is known as a *test-and-set (or atomic exchange)* instruction. We define what the test-and-set instruction does via the following C code snippet:

```c
TestAndSet(int *old_ptr, int new) {
    int old = *old_ptr; // fetch old value at old_ptr
    *old_ptr = new; // store 'new' into old_ptr
    return old; // return the old value
}
```

The reason it is called "test and set" is that

- it enables you to "test" the old value (which is what is returned)
- simultaneously "setting" the memory location to a new value

As it turns out, this slightly more powerful instruction is enough to build a simple *spin lock*.

```c
typedef struct __lock_t {
    int flag;
} lock_t;

void init(lock_t *lock) {
    // 0: lock is available, 1: lock is held
    lock->flag = 0;
}

void lock(lock_t *lock) {
    while (TestAndSet(&lock->flag, 1) == 1)
    ; // spin-wait (do nothing)
}

void unlock(lock_t *lock) {
    lock->flag = 0;
}
```

It is the simplest type of lock to build, and simply spins, using CPU cycles, until the lock becomes available. To work correctly on a single processor, it requires *a preemptive scheduler* (i.e., one that will interrupt a thread via a timer, in order to run a different thread, from time to time).

==== Evaluating Spin Locks

- correctness: does it provide mutual exclusion?
  - The answer here is yes: the spin lock only allows a single thread to enter the critical section at a time.
- fairness. How fair is a spin lock to a waiting thread?
  - The answer here, unfortunately, is bad news: spin locks don’t provide any fairness guarantees.
- performance. What are the costs of using a spin lock?
  - imagine threads competing for the lock on a single processor;
    - *painful*. The scheduler might then run every other thread (imagine there are N − 1 others), each of which tries to acquire the lock. In this case, each of those threads will spin for the duration of a time slice before giving up the CPU, a waste of CPU cycles.
  - consider threads spread out across many CPUs.
    - spin locks work reasonably well (if the number of threads roughly equals the number of CPUs).

==== THINK ABOUT CONCURRENCY AS A MALICIOUS SCHEDULER

What you should try to do is to pretend you are a malicious scheduler, one that *interrupts threads at the most inopportune of times* in order to foil their feeble attempts at building synchronization primitives.

=== Compare-And-Swap(or compare-and-exchange)

```c
int CompareAndSwap(int *ptr, int expected, int new) {
    int actual = *ptr;
    if (actual == expected)
        *ptr = new;
    return actual;
}
void lock(lock_t *lock) {
    while (CompareAndSwap(&lock->flag, 0, 1) == 1)
    ; // spin
}
```

Compare-and-swap is a more powerful instruction than test-and-set(when we briefly delve into topics such as *lock-free synchronization*.)
However, if we just build a simple spin lock with it, its behavior is identical to the spin lock we analyzed above.

=== Load-Linked and Store-Conditional

The *load-linked* and *store-conditional* instructions can be used in tandem to build locks and other concurrent structures.

```c
int LoadLinked(int *ptr) {
    return *ptr;
}

int StoreConditional(int *ptr, int value) {
    if (no update to *ptr since LoadLinked to this address) {
        *ptr = value;
        return 1; // success!
    } else {
        return 0; // failed to update
    }
}

void lock(lock_t *lock) {
    while (1) {
        while (LoadLinked(&lock->flag) == 1)
            ; // spin until it’s zero
        if (StoreConditional(&lock->flag, 1) == 1)
            return; // if set-it-to-1 was a success: all done
        // otherwise: try it all over again
    }
}

void lock(lock_t *lock) {
    while (LoadLinked(&lock->flag) ||
        !StoreConditional(&lock->flag, 1))
        ; // spin
}

void unlock(lock_t *lock) {
    lock->flag = 0;
}
```

=== Fetch-And-Add

One final hardware primitive is the fetch-and-add instruction, which atomically increments a value while returning the old value at a particular address.
we’ll use fetch-and-add to build a more interesting *ticket lock*

```c
int FetchAndAdd(int *ptr) {
    int old = *ptr;
    *ptr = old + 1;
    return old;
}

typedef struct __lock_t {
    int ticket;
    int turn;
} lock_t;

void lock_init(lock_t *lock) {
    lock->ticket = 0;
    lock->turn = 0;
}

void lock(lock_t *lock) {
    int myturn = FetchAndAdd(&lock->ticket);
    while (lock->turn != myturn)
        ; // spin
}

void unlock(lock_t *lock) {
    lock->turn = lock->turn + 1;
}
```

When a thread wishes to acquire a lock, it first does an atomic fetch-and-add on the ticket value; that value is now considered this thread’s “turn” (myturn). The globally shared lock->turn is then used to determine which thread’s turn it is; when (myturn == turn) for a given thread, it is that thread’s turn to enter the critical section. Unlock is accomplished simply by incrementing the turn such that the next waiting thread (if there is one) can now enter the critical section.

Note one important difference with this solution versus our previous
attempts: it ensures progress for all threads.
Once a thread is assigned its ticket value, it will be scheduled at some point in the future (once those in front of it have passed through the critical section and released the lock).  
In our previous attempts, no such guarantee existed; a thread spinning on test-and-set (for example) could spin forever even as other threads acquire and release the lock.

> LESS CODE IS BETTER CODE (LAUER’S LAW)

=== Too much Spinning: What Now?

These solutions can be quite inefficient.
Imagine you are running two threads on a single processor.
Now imagine that one thread (thread 0) is in a critical section and thus has a lock held, and unfortunately gets interrupted.
The second thread (thread 1) now tries to acquire the lock, but finds that it is held. Thus, it begins to spin. And spin. Then it spins some more.
And finally, a timer interrupt goes off, thread 0 is run again, which releases the lock, and finally (the next time it runs, say), thread 1 won’t have to spin so much and will be able to acquire the lock.

Thus it wastes an entire time slice doing nothing but checking a value that isn’t going to change!

The problem gets worse with N threads contending for a lock; N − 1 time slices may be wasted in a similar manner, simply spinning and waiting for a single thread to release the lock.

=== A Simple Approach: Just Yield, Baby

How can we develop a lock that doesn’t needlessly waste time spinning on the CPU?
What to do when a context switch occurs in a critical section, and threads start to spin endlessly, waiting for the interrupted (lock-holding) thread to be run again?

```c
void init() {
    flag = 0;
}

void lock() {
    while (TestAndSet(&flag, 1) == 1)
    yield(); // give up the CPU
}

void unlock() {
    flag = 0;
}
```

We assume an operating system primitive `yield()` which a thread can call when it wants to give up the CPU and let another thread run.

#tip("Tip")[
    A thread can be in one of three states (running, ready, or blocked); yield is simply a system call that moves the caller from the *running* state to the *ready* state, and thus promotes another thread to running. Thus, the yielding process essentially *deschedules* itself.

]

The example with two threads on one CPU;

in this case, our yield-based approach works quite well. If a thread happens to call `lock()` and find a lock held, it will simply yield the CPU, and thus the other thread will run and finish its critical section.

Consider the case where there are many threads (say 100) contending for a lock repeatedly.

In this case, if one thread acquires the lock and is preempted before releasing it, the other 99 will each call `lock()`, find the lock held, and yield the CPU.

#tip("Tip")[
While better than our spinning approach (which would waste 99 time slices spinning), this approach is still costly; the cost of a context switch can be substantial, and there is thus plenty of waste.
]

Worse, we have not tackled the *starvation* problem at all.

A thread may get caught in an endless yield loop while other threads repeatedly enter and exit the critical section.
