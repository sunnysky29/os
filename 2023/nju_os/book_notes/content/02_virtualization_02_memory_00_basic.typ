#import "../template.typ": *
#pagebreak()
= memory virtualization

== Address Spaces

=== Early Systems

The OS was a set of routines (a library, really) that sat in memory, and there would be one running program (a process) that currently sat in physical memory and used the rest of memory.

#image("images/2023-12-12-20-46-40.png", width: 50%)

=== Multiprogramming and Time Sharing

- the era of *multiprogramming*: Multiple processes were ready to run at a given time, and the OS would switch between them.
- the era of *time sharing*: The notion of interactivity became important, as many users might be concurrently using a machine, each waiting for (or hoping for) a timely response from their currently-executing tasks.

One way to implement time sharing would be:

run one process for a short while, giving it full access to all memory, then stop it, save all of its state to some kind of disk (including all of physical memory), load some other process’s state, run it for a while.

A big problem: it is way too slow, particularly as memory grows.

As the figure below shows, leave processes in memory while switching between them, allowing the OS to implement time sharing efficiently.
#image("images/2023-12-12-20-53-33.png", width: 50%)

Allowing multiple programs to reside concurrently in memory makes *protection* an important issue.

=== The Address Space

#definition("Definition")[
*Address Space*: it is the running program’s view of memory in the system.
]

- the code of the program (the instructions) have to live in memory
- a stack to keep track of where it is in the function call chain as well as to allocate local variables and pass parameters and return values to and from routines
- the heap is used for dynamically-allocated, user-managed memory

Code is static (and thus easy to place in memory), so we can place it at the top of the address space and know that it won’t need any more space as the program runs.
#image("images/2023-12-12-21-00-52.png", width: 70%)

Virtualizing memory example:

Process A in tries to perform a load at address 0 (which we will call a virtual address)

Somehow the OS, in tandem with some *hardware support*, will have to make sure the load doesn’t actually go to physical address 0 but rather to physical address 320KB (where A is loaded into memory).

This is the key to virtualization of memory, which underlies every modern computer system in the world.

==== THE PRINCIPLE OF ISOLATION
- If two entities are properly isolated from one another:
  - One can fail without affecting the other.

#example("Example")[
- Memory isolation: running programs cannot affect the operation of the underlying OS
- Walling off pieces of the OS from other pieces of the OS such as microkernels
]

=== Goals of A VM system:

- transparency: the program shouldn’t be aware of the fact that memory is virtualized
- efficiency: both in terms of time and space .
- protection: protect processes from one another as well as the OS itself from processes.

== Memory API

=== Types of Memory

- *stack memory*(also called automatic memory), and allocations and deallocations of it are managed implicitly by the compiler for you, the programmer.
- *heap memory*, where all allocations and deallocations are explicitly handled by you, the programmer.

=== `malloc`

`sizeof` is generally thought of a s compile-time operator, meaning that the actual size is known at compile time.

=== `free`

=== Common Errors

==== Forgetting To Allocate Memory

```c
char *src = "hello";
char *dst; // oops! unallocated
strcpy(dst, src); // segfault and die
```

==== Not Allocating Enough Memory

```c
char *src = "hello";
char *dst = (char *) malloc(strlen(src)); // too small!
strcpy(dst, src); // work properly
```

==== Forgetting to Initialize Allocated Memory

==== Forgetting To Free Memory

==== Freeing Memory Before You Are Done With It

==== Freeing Memory Repeatedly

==== Calling free() Incorrectly

==== WHY NO MEMORY IS LEAKED ONCE YOUR PROCESS EXITS

The reason is simple: there are really two levels of memory management in the system.

- The first level of memory management is performed by the OS, which hands out memory to processes when they run, and takes it back when processes exit (or otherwise die).
- The second level of management is within each process, for example within the heap when you call `malloc()` and `free()`.

Even if you fail to call `free()` (and thus leak memory in the heap), the operating system will reclaim all the memory of the process (including those pages for code, stack, and, as relevant here, heap) when the program is finished running. No matter what the state of your heap in your address space, the OS takes back all of those pages when the process dies, thus ensuring that no memory is lost despite the fact that you didn’t free it.

- For short-lived programs, leaking memory often does not cause any operational problems (though it may be considered poor form).
- For a long-running server (such as a web server or database management system, which never exit), leaked memory is a much bigger issue, and will eventually lead to a crash when the application runs out of memory.

Check out both `purify` and `valgrind`; both are excellent at helping you locate the source of your memory-related problems.

=== Underlying OS Support

One such system call is called `brk`, which is used to change the location of the program’s break: the location of the end of the heap.

It takes one argument (the address of the new break), and thus either increases or decreases the size of the heap based on whether the new break is larger or smaller than the current break. An additional call `sbrk` is passed an increment but otherwise serves a similar purpose.

#tip("Tip")[
 Note that you should never directly call either `brk` or `sbrk`. They are used by the memory-allocation library; if you try to use them, you will likely make something go (horribly) wrong. Stick to malloc() and free() instead.   
] 

You can also obtain memory from the operating system via the `mmap()` call:

By passing in the correct arguments, `mmap()` can create an anonymous memory region within your program—a region which is not associated with any particular file but rather with swap space. This memory can then also be treated like a heap and managed as such. `man mmap` for more details.

=== Other Calls

- `calloc()` allocates memory and also zeroes it before returning
- `realloc()` can also be useful, when you’ve allocated space for something (say, an array), and then need to add something to it: `realloc()` makes a new larger region of memory, copies the old region into it, and returns the pointer to the new region.

== Mechanism: Address Translation
*Efficiency* and *control* together are two of the main goals of any modern operating system.

- the OS, with a little hardware support, tries its best to get out of the way of the running program, to deliver an *efficient* virtualization
- by *interposing* at those critical points in time, the OS ensures that it maintains control over the hardware
  #tip("Tip")[
  - INTERPOSITION IS POWERFUL: *Interposition* is a generic and powerful technique that is often used to great effect in computer systems.  
  - In virtualizing memory, the hardware will interpose on each memory access, and translate each virtual address issued by the process to a physical address where the desired information is actually stored.
  - almost any well-defined interface can be interposed upon, to add new functionality or improve some other aspect of the system.
  - *One of the usual benefits of such an approach is transparency; the interposition often is done without changing the client of the interface, thus requiring no changes to said client.*
  ]

The generic technique:

- *hardware-based address translation*, or just *address translation*
  - changing *the virtual address* provided by the instruction to a *physical address* where the desired information is actually located

The OS must:

- get involved at key points to set up the hardware so that the correct translations take place;
- manage memory, keeping track of which locations are free and which are in use.

=== Assumptions

- the user’s address space must be placed *contiguously* in physical memory
- the size of the address space is not too big
- it is *less than the size of physical memory*
- each address space is exactly the *same size*

=== An Example

What we need to do? Why we need such a mechanism?

#code(caption: [Example - C])[
```c
void func() {
    int x = 3000; // thanks, Perry.
    x = x + 3; // this is the line of code we are interested in
    ...
```
]

#code(caption: [Example -Assembly])[
```c
128: movl 0x0(%ebx), %eax ;load 0+ebx into eax
132: addl $0x03, %eax ;add 3 to eax register
135: movl %eax, 0x0(%ebx) ;store eax back to mem
```
]

#image("images/2023-12-14-14-31-58.png", width: 30%)

#tip("Tip")[
It presumes that the address of `x` has been placed in the register `ebx`, and the initial value of `x` is 3000.
]

The following memory accesses take place:

- Fetch instruction at address 128
- Execute this instruction (load from address 15 KB)
- Fetch instruction at address 132
- Execute this instruction (no memory reference)
- Fetch the instruction at address 135
- Execute this instruction (store to address 15 KB)

From the program’s perspective, its address space starts at address 0 and grows to a maximum of 16 KB.

- How can we relocate this process in memory in a way that is transparent to the process?
- How can we provide the illusion of a virtual address space starting at 0, when in reality the address space is located at some other physical address?

In the figure:
#image("images/2023-12-14-14-34-39.png", width: 50%)

- the OS using the first slot of physical memory for itself,
- it has relocated the process from the example above into the slot starting at physical memory address 32 KB
- The other two slots are free (16 KB-32 KB and 48 KB-64 KB)

=== Dynamic (Hardware-based) Relocation

Introduced in the first *time-sharing machines* of the late 1950’s is a simple idea referred to as *base and bounds*; the technique is also referred to as *dynamic relocation*.

We’ll need two hardware registers within each CPU:

- *A base register* is used to transform virtual addresses (generated by the program) into physical addresses.
- *A bounds (or limit) register* ensures that such addresses are within the confines of the address space.

Each program is written and compiled as if it is loaded at address zero; when a program starts running, the OS decides where in physical memory it should be loaded and sets the base register to that value.

In the example above, the OS decides to load the process at physical address 32 KB and thus sets the base register to this value.

So it is translated by:

```
physical address = virtual address + base
```

#example("Example")[
```asm
128: movl 0x0(%ebx), %eax
```

When the hardware needs to fetch this instruction,

- It first adds the value to the base register value of 32 KB (32768) to get a physical address of 32896;
- The hardware then fetches the instruction from that physical address.
- Next, the processor begins executing the instruction.
- The process then issues the load from virtual address 15 KB, which the processor takes and again adds to the base register (32 KB), getting the final physical address of 47 KB and thus the desired contents.
]

==== base and bounds
The bounds register is there to help with protection. A small aside about bound registers, which can be defined in one of two ways:

- it holds the _size_ of the address space.
- it holds the physical address of the end of the address space

#tip("Tip")[
Both methods are logically equivalent; for simplicity, we’ll usually assume the former method.
] 

Specifically, the processor will first check that the memory reference is within bounds to make sure it is legal(no greater than, no negative); in the simple example above, the bounds register would always be set to 16 KB.

The base and bounds registers are hardware structures kept on the chip (one pair per CPU).

Sometimes people call the part of the processor that helps with address translation the *memory management unit (MMU)*.

==== Example Translations

A process with an address space of size 4KB has been loaded at physical address 16KB.
#image("images/2023-12-14-14-59-12.png",width: 70%)

==== SOFTWARE-BASED RELOCATION

The basic technique is referred to as *static relocation*, in which a piece of software known as the loader takes an executable that is about to be run and rewrites its addresses to the desired offset in physical memory.

For example, if an instruction was a load from address 1000 into a register, (e.g., `movl 1000, %eax`), and the address space of the program was loaded starting at address 3000, the loader would rewrite the instruction to offset each address by 3000 (e.g., `movl 4000, %eax`).

Static relocation has numerous problems.

- First and most importantly, it does not provide protection, in general, hardware support is likely needed for true protection.
- Another negative is that once placed, it is difficult to later relocate an address space to another location .

==== Hardware Support: A Summary

#image("images/2023-12-14-15-34-38.png")

The hardware should provide special instructions to modify the base and bounds registers, allowing the OS to change them when different processes run. These instructions are _privileged_; only in kernel (or privileged) mode can the registers be modified.

Finally, the CPU must be able to generate exceptions in situations where a user program tries to access memory illegally.

- “out-of-bounds” exception handler
- “tried to execute a privileged operation while in user mode” handler

==== Operating System Issues

#image("images/2023-12-14-15-40-18.png")

- First, the OS must take action when a process is created, finding space for its address space in memory. It can simply view physical memory as an array of slots, and track whether each one is free or in use.
  #tip("Tip")[
    the OS will have to search a data structure (often called a *free list*) to find room for the new address space and then mark it use  
  ] 
- Second, the OS must do some work when a process is terminated.(i.e., exits gracefully, or is forcefully killed), the OS thus puts its memory back on the free list, and cleans up any associated data structures as need be.
- Third, the OS must also perform a few additional steps when a context switch occurs.
  - The OS must save and restore the base-and-bounds pair when it switches between processes.
  - when the OS decides to stop running a process, it must save the values of the base and bounds registers to memory, in some per-process structure such as the process structure or process control block (PCB).
  - when the OS resumes a running process (or runs it the first time), it must set the values of the base and bounds on the CPU to the correct values for this process.
- Fourth, the OS must provide exception handlers, or functions to be called, as discussed above; the OS installs these handlers at boot time (via privileged instructions).

when a process is stopped (i.e., not running), it is possible for the OS to move an address space from one location in memory to another rather easily. To move a process’s address space:

- the OS first deschedules the process;
- then, the OS copies the address space from the current location to the new location;
- finally, the OS updates the saved base register (in the process structure) to point to the new location.

Note how its memory translations are handled by the hardware with no OS intervention:
#image("images/2023-12-14-15-46-44.png", width: 80%)

=== Summary

inefficiencies: because the process stack and heap are not too big, all of the space between the two is simply wasted. This type of waste is usually called internal fragmentation, as the space inside the allocated unit is not all used (i.e., is fragmented) and thus wasted.

#tip("Tip")[
A different solution might instead place a fixed-sized stack within the address space, just below the code region, and a growing heap below that. However, this limits flexibility by making recursion and deeply-nested function calls challenging, and thus is something we hope to avoid.
]

Our first attempt will be a slight generalization of base and bounds known as *segmentation*.
