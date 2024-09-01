#import "../template.typ": *
#pagebreak()
= CPU virtualization

== Process

=== Introduction

The *process* is a *running program*.

=== time sharing and space sharing
- Q: How can the OS provide the illusion of a nearly-endless supply of said CPUs?
- A: Virtualizing the CPU. By running one process, then stopping it and running another, and so forth, the OS can promote the illusion that many virtual CPUs exist when in fact there is only one physical CPU (or a few). (*time sharing of the CPU*)

- Time sharing is a basic technique used by an OS to share a resource.
  - By allowing the resource to be used for a little while by one entity, and then a little while by another, and so forth, the resource in question (e.g., the CPU, or a network link) can be shared by many.
- Space sharing, where a resource is divided (in space) among those who wish to use it.
  - For example, disk space is naturally a space-shared resource; once a block is assigned to a file, it is normally not assigned to another file until the user deletes the original file.

=== To implement virtualization of the CPU:

- some low-level machinery (*mechanisms*)
  - time-sharing mechanism
- some high-level intelligence(*policies*)
  - scheduling policy

=== The Abstraction: The Process

==== Machine State

the component of machine state the comprises a process:

- memory(called ites address sapce)
- registers
  - some particularly special registers:
    - program counter(PC)
    - stack pointer
    - frame pointer
      #tip("Tip")[
      They are used to manage the stack for function parameters, local variables, and return addresses
      ]

=== Interlude: Process API

Process API forms:

- Create(create a process)
- Destroy(destroy a process)
- Wait(wait for a process to stop running)
- Miscellaneous Control(suspend, resume...)
- Status(get some info about a process)

=== Process Creation: A Little More Detail

==== load the process

#image("images/2023-12-04-19-59-55.png", width: 60%)

The first thing that the OS must do to run a program is to load its code and any static data (e.g., initialized variables) into memory, into the address space of the process.

In early (or simple) operating systems, the loading process is done *eagerly*; modern OSes perform the process *lazily*(paging and swapping)

==== before running the process

- Some memory must be allocated for the program’s *run-time stack* (or just *stack*).
  #tip("Tip")[
    The OS will also likely initialize the stack with arguments; specifically, it will fill in the parameters to the `main()` function, i.e., `argc` and the `argv` array.  
  ] 
- The OS may also allocate some memory for the program’s *heap*.
  #tip("Tip")[
    The heap will be small at first; as the program runs, and requests more memory via the `malloc()` library API, the OS may get involved and allocate more memory to the process to help satisfy such calls.  
  ] 
- The OS will also do some other initialization tasks, particularly as related to input/output (I/O).
  #tip("Tip")[
  Each process by default has three open file descriptors, for standard input, output, and error.  
  ]
- Finally set the stage for program execution, one last task: to start the program running at the entry point, namely `main()`.By jumping to the `main()` routine, the OS transfers control of the CPU to the newly-created process, and thus the program begins its execution.

=== Process States

States:

- Running
- Ready
- Blocked.

#image("images/2023-12-04-19-59-31.png", width:60%)
#image("images/2023-12-04-20-00-23.png", width:60%)
#image("images/2023-12-04-20-00-32.png", width:60%)

=== Data Structures

To track the state of each process, the OS likely will keep some kind of *process list* for all processes that are ready and some additional information to track which process is currently running.

==== an OS needs to track about each process in the xv6 kernel

```c
// Saved registers for kernel context switches.
struct context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID

  // wait_lock must be held when using this:
  struct proc *parent;         // Parent process

  // these are private to the process, so p->lock need not be held.
  uint64 kstack;               // Virtual address of kernel stack
  uint64 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};
```

*context switch*:

- The register context will hold, for a stopped process, the contents of its registers.
- When a process is stopped, its registers will be saved to this memory location; by restoring these registers (i.e., placing their values back into the actual physical registers), the OS can resume running the process.

Sometimes a system will have an *initial state* that the process is in when it is being created. Also, a process could be placed in a *final state* where it has exited but has not yet been cleaned up (in UNIX-based systems, this is called the *zombie state*).

#tip("Tip")[
 *Final state* can be useful as it allows other processes (usually the parent that created the process) to examine the return code of the process and see if the just-finished process executed successfully (usually, programs return zero in UNIX-based systems when they have accomplished a task successfully, and non-zero otherwise).
]

When finished, the parent will make one final call (e.g., `wait()`) to wait for the completion of the child, and to also indicate to the OS that it can clean up any relevant data structures that referred to the now-extinct process.

==== DATA STRUCTURE — THE PROCESS LIST

Operating systems are replete with various important data structures. The *process list* (also called the *task list*) is the first such structure.

Sometimes people refer to the individual structure that stores information about a process as a *Process Control Block (PCB)*, a fancy way of talking about a C structure that contains information about each process (also sometimes called a *process descriptor*).

== Interlude: Process API

=== The `fork()` System Call

=== The `wait()` System Call

=== The `exec()` System Call

=== Why? Motivating The API

The separation of `fork()` and `exec()` is essential in building a UNIX shell, because it lets the shell run code after the call to `fork()` but before the call to `exec()`; this code can alter the environment of the about-to-be-run program, and thus enables a variety of interesting features to be readily built.

```sh
prompt> wc p3.c > newfile.txt
```

In the example above, the output of the program `wc` is redirected into the output file `newfile.txt`, when the child is created, before calling `exec()`, the shell closes standard output and opens the file `newfile.txt`. By doing so, any output from the soon-to-be-running program `wc` are sent to the file instead of the screen.

=== Process Control And Users

There are a lot of other interfaces for interacting with processes in UNIX systems.

`kill()` system call is used to send signals to a process, including directives to pause, die, and other useful imperatives.

- control-c sends a `SIGINT` (interrupt) to the process (normally terminating it)
- control-z sends a `SIGTSTP` (stop) signal thus pausing the process in mid-execution
  > you can resume it later with a command, e.g., the `fg` built-in command found in many shells.

To use this form of communication, a process should use the `signal()` system call to “catch” various signals.

Doing so ensures that when a particular signal is delivered to a process, it will suspend its normal execution and run a particular piece of code in response to the signal.

==== Who can send a signal to a process, and who cannot?

Modern systems include a strong conception of the notion of a user.

The user, after entering a password to establish credentials, logs in to gain access to system resources.

The user may then launch one or many processes, and exercise full control over them (pause them, kill them, etc.). Users generally can only control their own processes; it is the job of the operating system to parcel out resources (such as CPU,memory, and disk) to each user (and their processes) to meet overall system goals.

THE SUPERUSER (ROOT):A system generally needs a user who can administer the system, and is not limited in the way most users are.

=== Useful Tools

- `ps` command allows you to see which processes are running;
- `top` is also quite helpful, as it displays the processes of the system and how much CPU and other resources they are eating up.
  #tip("Tip")[
   Humorously, many times when you run it, top claims it is the top resource hog; perhaps it is a bit of an egomaniac.
  ]
- The command `kill` can be used to send arbitrary signals to processes, as can the slightly more user friendly `killall`.
- `MenuMeters`: CPU meters you can use to get a quick glance understanding of the load on your system, we can see how much CPU is being utilized at any moment in time.

*In general, the more information about what is going on, the better.*

== Mechanism: Limited Direct Execution
There are a few challenges, however, in building such virtualization machinery.

- *performance*: how can we implement virtualization without adding excessive overhead to the system?
- *control*: how can we run processes efficiently while retaining control over the CPU?
  #tip("Tip")[
   Control is particularly important to the OS, as it is in charge of resources; without control, a process could simply run forever and take over the machine, or access information that it should not be allowed to access.   
  ]

=== Basic Technique: Limited Direct Execution

==== "direct execution" part

"direct execution" part idea: just run the program directly on CPU.
#image("images/2023-12-12-19-59-56.png",width: 80%)

problems:

- *protection*
- *time sharing*

Without limits on running programs, the OS wouldn’t be in control of anything and thus would be *just a library*

=== Problem #1: Restricted Operations

- Running on the CPU introduces a problem: What if the process wishes to perform some kind of restricted operation, such as:
  - issuing an I/O request to a disk
  - gaining access to more system resources such as CPU or memory?
    #tip("Tip")[
     Without giving the process complete control over the system. How can the OS and hardware work together to do so?   
    ] 

One simple approach: let any process do whatever it wants.

Absolutely a bad way, no protection at all!!

==== user/kernel mode

The approach we take is to introduce a new processor mode. known as *user mode*

- *user mode* code that runs in user mode is restricted in what it can do.
  - For example, when running in user mode, a process can’t issue I/O requests; doing so would result in the processor raising an exception; the OS would then likely kill the process.
- *Kernel mode*, which the operating system (or kernel) runs in. Code that runs can do what it likes.

==== System call

What should a user process do when it wishes to perform some kind of privileged operation?

*System call*, allow the kernel to carefully expose certain key pieces of functionality to user programs.(accessing the file system, creating and destroying processes, communicating with other processes, and allocating more memory...)

==== Trap
To execute a system call, a program must execute a special trap instruction.

- This instruction simultaneously jumps into the kernel and raises the privilege level to kernel mode
- Once in the kernel, the system can thus do the required work for the calling process.

When finished, the OS calls a special *return-from-trap* instruction,

- returns into the calling user program
- while simultaneously reducing the privilege level back to user mode.

When executing a trap, the hardware must save enough of the caller’s registers in order to be able to return correctly when the OS issues the return-from-trap instruction. On x86, for example,

- the processor will push the program counter, flags, and a few other registers onto a per-process *kernel stack*;
- the return-from-trap will pop these values off the stack and resume execution of the user-mode program.

How does the trap know which code to run inside the OS?

The calling process can’t specify an address to jump to. Doing so would allow programs to jump anywhere into the kernel which clearly is a Very Bad Idea

When the machine boots up, it does so in privileged (kernel) mode, and thus is free to configure machine hardware as need be.

The kernel does so by setting up *a trap table* at boot time. The OS thus does is to tell the hardware what code to run when certain exceptional events occur:

- what code should run when a hard-disk interrupt takes place
- when a keyboard interrupt occurs
- when a program makes a system call.....

The OS informs the hardware of the locations of these trap handlers, usually with some kind of special instructions, and thus the hardware knows what to do (i.e., what code to jump to)when system calls and other exceptional events take place.

==== system call number
To specify the exact system call, *a system-call number* is usually assigned to each system call.

- The user code is thus responsible for placing the desired system-call number in a register or at a specified location on the stack;
- The OS, when handling the system call inside the trap handler, examines this number, ensures it is valid, and, if it is, executes the corresponding code.

This level of indirection serves as a form of *protection*; user code cannot specify an exact address to jump to, but rather must request a particular service via number.

==== WHY SYSTEM CALLS LOOK LIKE PROCEDURE CALLS

You may wonder why a call to a system call, such as `open()` or `read()`, looks exactly like a typical procedure call in C; that is, if it looks just like a procedure call, how does the system know it’s a system call, and do all the right stuff?

The simple reason: it is a procedure call, but hidden inside that procedure call is the famous trap instruction.

More specifically: the library uses an agreed-upon calling convention

- the kernel to put the arguments to open in well-known locations (e.g., on the stack, or in specific registers)
- puts the system-call number into a well-known location as well (onto the stack or a register)
- then executes the aforementioned trap instruction, puts the syscall return val into a well-known location too
- the code in the library after the trap unpacks return values and returns control to the program that issued the system call

Thus, the parts of the C library that make system calls are hand-coded in assembly, somebody has already written that assembly for you.

==== BE WARY OF USER INPUTS IN SECURE SYSTEMS

- There are still many other aspects to implementing a secure operating system that we must consider:
  - One of these is the handling of arguments at the system call boundary; the OS must check what the user passes in and ensure that arguments are properly specified, or otherwise reject the call.

#example("Example")[
For example, with a `write()` system call, the user specifies an address of a buffer as a source of the write call. If the user passes in a “bad” address, the OS must detect this and reject the call.
]

In general, a secure system must treat user inputs with great suspicion.

==== Timeline

We assume each process has a kernel stack where registers (including general purpose registers and the program counter) are saved to and restored from (by the hardware)when transitioning into and out of the kernel.

#image("images/2023-12-12-20-37-13.png", width: 90%)

#tip("Tip")[
All privileged inst are highlighted in bold.
]

There are two phases in the *limited direct execution (LDE)* protocol.

=== Problem #2: Switching Between Processes

The next problem with direct execution is achieving a switch between processes.

Specifically, if a process is running on the CPU, this by definition means the OS is not running. If the OS is not running, how can it do anything at all? (hint: it can’t)

So how can the operating system regain control of the CPU so that it can switch between processes?

==== A Cooperative Approach: Wait For System Calls

One approach that some systems have taken in the past is known as the cooperative approach:

The OS trusts the processes of the system to behave reasonably.
Processes that run for too long are assumed to periodically give up the CPU so that the OS can decide to run some other task.

How does a friendly process give up the CPU in this utopian world?

Most processes, as it turns out, transfer control of the CPU to the OS quite frequently by making system calls.

Systems like this often include an explicit `yield` system call, which does nothing except to transfer control to the OS so it can run other processes.

Applications also transfer control to the OS when they do something illegal.

For example, if an application divides by zero, or tries to access memory that it shouldn’t be able to access, it will generate a trap to the OS.

The OS will then have control of the CPU again (and likely terminate the offending process).

Thus, in a cooperative scheduling system, the OS regains control of the CPU by waiting for a system call or an illegal operation of some kind to take place.

==== A Non-Cooperative Approach: The OS Takes Control

What if a process ends up in an infinite loop? In the cooperative approach, your only recourse when a process gets stuck in an infinite loop is to resort to the age-old solution to all problems in computer systems: *reboot the machine*.

How can the OS gain control of the CPU even if processes are not being cooperative? What can the OS do to ensure a rogue process does not take over the machine? *a timer interrupt*

- A timer device can be programmed to raise an interrupt every so many milliseconds.
- When the interrupt is raised, the currently running process is halted, and a pre-configured *interrupt handler* in the OS runs.
- At this point, the OS has regained control of the CPU, and thus can do what it pleases: stop the current process, and start a different one.

So:

- the OS must inform the hardware of which code to run when the timer interrupt occurs
- during the boot sequence, the OS must start the timer(privileged inst)

This hardware feature is essential in helping the OS maintain *control* of the machine.

===== REBOOT IS USEFUL

- Reboot is useful because it moves software back to a known and likely more tested state.
- Reboots also reclaim stale or leaked resources (e.g., memory) which may otherwise be hard to handle.
- Finally, reboots are easy to automate.

==== Saving and Restoring Context

Now that the OS has regained control(whether cooperatively via a system call, or more forcefully via a timer interrupt), a decision has to be made: whether to continue running the currently-running process, or switch to a different one.

#tip("Tip")[
    This decision is made by a part of the operating system known as the *scheduler*
]

If the decision is made to *switch*, the OS then executes a low-level piece of code which we refer to as *a context switch*.

- All the OS has to do is save a few register values for the currently-executing process (onto its kernel stack, for example)
- And restore a few for the soon-to-be-executing process (from its kernel stack).

The OS will execute some low-level assembly code to

- save the general purpose registers, PC, and the kernel stack pointer of the currently-running process,
- and then restore said registers, PC, and switch to the kernel stack for the soon-to-be-executing process.

==== timeline

#image("images/2023-12-18-18-45-50.png", width: 80%)

In this example, Process A is running and then is interrupted by the timer interrupt.

- The hardware saves its registers (onto its kernel stack) and enters the kernel (switching to kernel-mode).
- In the timer interrupt handler, the OS decides to switch from running Process A to Process B.
- At that point, it calls the `switch()` routine, which carefully saves current register values (into the process structure of A), restores the registers of Process B (from its process structure entry), and then switches contexts, specifically by changing the stack pointer to use B’s kernel stack (and not A’s).
- Finally, the OS return-from-trap, which restores B’s registers and starts running it.

There are two types of register saves/restores that happen during this protocol

- The first is when the timer interrupt occurs; in this case, the user registers of the running process are implicitly saved by the hardware, using *the kernel stack of that process*.
- The second is when the OS decides to switch from A to B; in this case, the kernel registers are explicitly *saved by the software* (i.e., the OS), but this time into memory *in the process structure of the process*.

context switch code for xv6:

```asm
# void swtch(struct context *old, struct context *new);
# 
# Save current register context in old
# and then load register context from new.
.globl swtch
swtch:
# Save old registers
movl 4(%esp), %eax  # put old ptr into eax
popl 0(%eax)        # save the old IP
movl %esp, 4(%eax)  # and stack
movl %ebx, 8(%eax)  # and other registers
movl %ecx, 12(%eax)
movl %edx, 16(%eax)
movl %esi, 20(%eax)
movl %edi, 24(%eax)
movl %ebp, 28(%eax)

# Load new registers
movl 4(%esp), %eax  # put new ptr into eax
movl 28(%eax), %ebp # restore other registers
movl 24(%eax), %edi
movl 20(%eax), %esi
movl 16(%eax), %edx
movl 12(%eax), %ecx
movl 8(%eax), %ebx
movl 4(%eax), %esp  # stack is switched here
pushl 0(%eax)       # return addr put in place
ret                 # finally return into new ctxt
```

=== Worried About Concurrency

- What happens when, during a system call, a timer interrupt occurs?
- What happens when you’re handling one interrupt and another one happens?

The OS does indeed need to be concerned as to what happens if, during interrupt or trap handling, another interrupt occurs.*concurrency*

One simple thing an OS might do is disable interrupts during interrupt processing; doing so ensures that when one interrupt is being handled, no other one will be delivered to the CPU.

#tip("Tip")[
The OS has to be careful in doing so; disabling interrupts for too long could lead to lost interrupts, which is (in technical terms) bad.
]

Operating systems also have developed a number of sophisticated *locking schemes* to protect concurrent access to internal data structures.

This enables multiple activities to be on-going within the kernel at the same time, particularly useful on multiprocessors.

==== HOW LONG CONTEXT SWITCHES TAKE

There is a tool called `lmbench` that measures exactly those things, as well as a few other performance measures that might be relevant.

It should be noted that not all operating-system actions track CPU performance.

As Ousterhout observed, many OS operations are *memory intensive*, and memory bandwidth has not improved as dramatically as processor speed over time.

Thus, depending on your workload, buying the latest and greatest processor may not speed up your OS as much as you might hope.

=== Summary

The basic idea of LDE is straightforward: just run the program you want to run on the CPU, but first make sure to set up the hardware so as to limit what the process can do without OS assistance.

In an analogous manner, the OS “baby proofs” the CPU, by first (during boot time) setting up the trap handlers and starting an interrupt timer, and then by only running processes in a restricted mode.
