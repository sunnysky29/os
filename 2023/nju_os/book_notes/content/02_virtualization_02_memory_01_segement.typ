#import "../template.typ": *
#pagebreak()
== Segmentation

#image("images/2023-12-14-15-50-09.png", width: 30%)

Although the space between the stack and heap is not being used by the process, it is still taking up physical memory when we relocate the entire address space somewhere in physical memory.

Thus, the simple approach of using a base and bounds register pair to virtualize memory is wasteful.

=== Segmentation: Generalized Base/Bounds

To solve this problem, an idea was born, and it is called *segmentation*.

The idea is simple: instead of having just one base and bounds pair in our MMU, why not have a base and bounds pair per logical segment of the address space?

We have three logically-different segments: code, stack, and heap. With a base and bounds pair per segment, we can place each segment independently in physical memory. Just like the figure below:
#image("images/2023-12-14-20-24-44.png", width:50%)
Only used memory is allocated space in physical memory, and thus large address spaces with large amounts of unused address space (which we sometimes call *sparse address spaces*) can be accommodated.

Figure below shows the register values for the example above; each bounds register holds the size of a segment.
#image("images/2023-12-14-20-27-31.png", width:30%)

==== example

Assume a reference is made to virtual address 100 (which is in the code segment).

- When the reference takes place (say, on an instruction fetch), the hardware will add the base value to the offset into this segment (100 in this case) to arrive at the desired physical address: 100 + 32KB, or 32868.
- It will then check that the address is within bounds (100 is less than 2KB), find that it is, and issue the reference to physical memory address 32868.

Now let’s look at an address in the heap, virtual address 4200.

- If we just add the virtual address 4200 to the base of the heap (34KB), we get a physical address of 39016, which is not the correct physical address.
- What we need to first do is extract the offset into the heap, i.e., which byte(s) in this segment the address refers to. Because the heap starts at virtual address 4KB (4096), the offset of 4200 is actually `4200-4096`, or `104`.
- We then take this offset (104) and add it to the base register physical address (34K) to get the desired result: 34920.

==== The segmentation fault

The term segmentation fault or violation arises from a memory access on a segmented machine to an illegal address.

What if we tried to refer to an illegal address, such as 7KB which is beyond the end of the heap?

You can imagine what will happen: the hardware detects that the address is out of bounds, traps into the OS, likely leading to the termination of the offending process. Then *segmentation fault*!!

#tip("Tip")[
Humorously, the term persists, even on machines with no support for segmentation at all.   
]

=== Which Segment Are We Referring To?

How does it know the offset into a segment, and to which segment an address refers?

One common approach, sometimes referred to as an *explicit* approach:

- based on the top few bits of the virtual address
  #tip("Tip")[
   this technique was used in the VAX/VMS system   
  ] 

In our example above, we have three segments; thus we need two bits to accomplish our task.
If we use the top two bits of our 14-bit virtual address to select the segment, our virtual address looks like this:
#image("images/2023-12-14-20-37-08.png", width: 80%)

- The top two bits are 00, the hardware knows the virtual address is in the code segment, and thus uses the code base and bounds pair to relocate the address to the correct physical location.
  - physical_addr = virtual_addr + base
- If the top two bits are 01, the hardware knows the address is in the heap, and thus uses the heap base and bounds.
  - physical_addr = offset + base
  #tip("Tip")[
    - offset = virtual_addr - segment_virtual_start_addr
    - Note the offset eases the bounds check too: we can simply check if the offset is less than the bounds; if not, the address is illegal.
  ]

If base and bounds were arrays (with one entry per segment), the hardware would be doing something like this to obtain the desired physical address:

```c
// get top 2 bits of 14-bit VA
Segment = (VirtualAddress & SEG_MASK) >> SEG_SHIFT
// now get offset
Offset = VirtualAddress & OFFSET_MASK
if (Offset >= Bounds[Segment])
    RaiseException(PROTECTION_FAULT)
else
    PhysAddr = Base[Segment] + Offset
    Register = AccessMemory(PhysAddr)
```

In our running example:

- `SEG_MASK` -> `0x3000`,
- `SEG_SHIFT` -> `12`
- `OFFSET_MASK` -> `0xFFF`.

Some systems put *code* in the same segment as the *heap* and thus use only one bit to select which segment to use.

=== Implicit approach

The hardware determines the segment by noticing how the address was formed.

- If, for example, the address was generated from the program counter (i.e., it was an instruction fetch), then the address is within the code segment.
- If the address is based off of the stack or base pointer, it must be in the stack segment.
- Any other address must be in the heap.

=== What About The Stack?

one critical difference: it *grows backwards*, translation must proceed differently.

- In physical memory, it starts at 28KB and grows back to 26KB.
- Corresponding to virtual addresses 16KB to 14KB.

The first thing we need is a little extra hardware support. Instead of just base and bounds values, the hardware also needs to know which way the segment grows.
#image("images/2023-12-14-20-50-41.png", width: 50%)

==== example

In this example, assume we wish to access virtual address 15KB, which should map to physical address 27KB. Our virtual address, in binary form, thus looks like this: 11 1100 0000 0000 (hex 0x3C00). The hardware uses the top two bits (11) to designate the segment, but then we are left with an offset of 3KB(`segment_virtual_start_addr - virtual_addr`->`18-15`).

To obtain the correct negative offset, we must *subtract the maximum segment size* from 3KB:

- In this example, suppose that a segment can be 4KB, and thus the correct *negative_offset = `3KB - 4KB = -1KB`* .
- We simply add the negative offset (-1KB) to the base (28KB) to arrive at the correct physical address: 27KB.

#tip("Tip")[
    The bounds check can be calculated by ensuring the absolute value of the negative offset is less than the segment’s size.
] 

=== Support for Sharing

Specifically, to save memory, sometimes it is useful to share certain memory segments between address spaces. In particular, *code sharing* is common and still in use in systems today.

To support sharing, we need a little extra support from the hardware, in the form of *protection bits*:

- Add a few bits per segment, indicating whether or not a program can read or write a segment, or perhaps execute code that lies within the segment.

By setting a code segment to read-only, the same code can be shared across multiple processes, without worry of harming isolation.

While each process still thinks that it is accessing its own private memory, the OS is secretly sharing memory which cannot be modified by the process, and thus the illusion is preserved.

An example: the code segment is set to read and execute, and thus *the same physical segment in memory could be mapped into multiple virtual address spaces*

#image("images/2023-12-14-21-05-04.png", width: 80%)

In addition to checking whether a virtual address is within bounds, the hardware also has to check whether a particular access is permissible.
If a user process tries to write to a read-only segment, or execute from a non-executable segment, the hardware should raise an exception, and thus let the OS deal with the offending process.

=== Fine-grained vs. Coarse-grained Segmentation

*coarse-grained*: it chops up the address space into relatively large, coarse chunks.
*fine-grained*: more flexible and allowed for address spaces to consist of a large number of smaller segments

Supporting many segments requires even further hardware support, with a *segment table* of some kind stored in memory. Such segment tables usually support the creation of a very large number of segments, and thus enable a system to use segments in more flexible ways than we have thus far discussed.

The thinking at the time was that by having *fine-grained* segments, the OS could better learn about which segments are in use and which are not and thus utilize main memory more effectively.

=== OS Support

The first is an old one: what should the OS do on a context switch?

- the segment registers must be saved and restored.

The second, and more important, issue is managing free space in physical memory.

- previous fixed size -> easy
- now variable-sized

==== external fragmentation

The general problem that arises is that physical memory quickly becomes full of little holes of free space, making it difficult to allocate new segments, or to grow existing ones. We call this problem *external fragmentation*

#image("images/2023-12-14-21-13-52.png", width: 80%)
In the example, a process comes along and wishes to allocate a 20KB segment. In that example, there is 24KB free, but not in one contiguous segment (rather, in three non-contiguous chunks). Thus, the OS cannot satisfy the 20KB request.

One solution: to compact physical memory by rearranging the existing segments.

However, compaction is expensive, as copying segments is memory-intensive and generally uses a fair amount of processor time.

A simpler approach is to use a free-list management algorithm that tries to keep large extents of memory available for allocation.

There are literally hundreds of approaches that people have taken, including classic algorithms like *best-fit* (which keeps a list of free spaces and returns the one closest in size that satisfies the desired allocation to the requester) *worst-fit*, *first-fit*, and more complex schemes like *buddy algorithm*.

No matter how smart the algorithm, external fragmentation will still exist; thus, a good algorithm simply attempts to minimize it. There is no one “best” way to solve the problem.

The only real solution (as we will see in forthcoming chapters) is to avoid the problem altogether, by never allocating memory in variable-sized chunks.

=== Summary

problems:

- The first, as discussed above, is external fragmentation.
- The second and perhaps more important problem is that segmentation still isn’t flexible enough to support our fully generalized, sparse address space.
  #tip("Tip")[
   If we have a large but sparsely-used heap all in one logical segment, the entire heap must still reside in memory in order to be accessed.   
  ] 

== Free Space Management

- fixed-sized units -> easy
- variable-sized units -> more difficult

=== Assumptions

- a basic interface such as that provided by `malloc()` and `free()`.
  #tip("Tip")[
    - Note the implication of the interface: the user, when freeing the space, does not inform the library of its size; thus, the library must be able to figure out how big a chunk of memory is when handed just a pointer to it.
    - The space that this library manages is known historically as the `heap`, and the generic data structure used to manage free space in the heap is some kind of *free list*.
  ]
- For the sake of simplicity, we further assume that primarily we are concerned with *external fragmentation*
  #tip("Tip")[
    Allocators could of course also have the problem of *internal fragmentation*, if an allocator hands out chunks of memory bigger than that requested, any unasked for (and thus unused) space in such a chunk is considered internal fragmentation  
  ] 
- We’ll also assume that once memory is handed out to a client, it cannot be relocated to another location in memory. that memory region is essentially “owned” by the program (and cannot be moved by the library) until the program returns it via a corresponding call to `free()`.
  #tip("Tip")[
    no *compaction* of free space is possible  
  ] 
- We’ll assume that the allocator manages a contiguous region of bytes. For simplicity, we’ll just assume that the region is a single fixed size throughout its life.

=== Low-level Mechanisms

some common mechanisms used inmost allocators:

- the basics of splitting and coalescing
- how one can track the size of allocated regions
- how to build a simple list inside the free space to keep track of what is free and what isn’t

==== Splitting and Coalescing

A free list contains a set of elements that describe the free space still remaining in the heap.
Assume the following 30-byte heap:
#image("images/2023-12-18-07-28-17.png", width: 60%)
Then the free list:
#image("images/2023-12-18-07-28-34.png", width:60%)

===== Splitting

If the request is for something smaller than 10 bytes?

It will find a free chunk of memory that can satisfy the request and split it into two. The first chunk it will return to the caller; the second chunk will remain on the list.

If a request for 1 byte were made:
#image("images/2023-12-18-07-29-57.png", width:60%)

===== Coalescing

Take our example from above once more (free 10 bytes, used 10 bytes, and another free 10 bytes).
#image("images/2023-12-18-07-28-17.png", width: 60%)
What happens when an application calls free(10), thus returning the space in the middle of the heap?
If we simply add this free space back into our list without too much thinking:
#image("images/2023-12-18-07-32-22.png", width: 60%)

#tip("Tip")[
If a user requests 20 bytes, a simple list traversal will not find such a free chunk, and return failure.
]

The idea is simple: when returning a free chunk in memory, look carefully at the addresses of the chunk you are returning as well as the nearby chunks of free space; if the newly freed space sits right next to one (or two, as in this example) existing free chunks, merge them into a single larger free chunk.
#image("images/2023-12-18-07-33-25.png", width: 40%)

==== Tracking The Size Of Allocated Regions

The interface to `free(void *ptr)` does not take a size parameter:

It is assumed that given a pointer, the malloc library can quickly determine the size of the region of memory being freed and thus incorporate the space back into the free list.

To accomplish this task, most allocators store a little bit of extra information in a header block which is kept in memory, usually just before the handed-out chunk of memory.

We are examining an allocated block of size 20 bytes, `ptr = malloc(20);`
#image("images/2023-12-18-07-34-09.png", width: 70%)

#tip("Tip")[
 When a user requests N bytes of memory, the library searches for *a free chunk of size N plus the size of the header*.   
] 

===== The header

The header minimally contains

- the size of the allocated region
- additional pointers to speed up deallocation
- a magic number to provide additional integrity checking
- ....

Let’s assume a simple header which contains the size of the region and a magic number:

```c
typedef struct __header_t {
  int size;
  int magic;
} header_t;
```

When the user calls `free(ptr)`, the library then uses simple pointer arithmetic
to figure out where the header begins:

```c
void free(void *ptr) {
  header_t *hptr = (void *)ptr - sizeof(header_t);
  ...
```

#image("images/2023-12-18-07-39-54.png", width: 70%)

After obtaining such a pointer to the header, the library can easily:

- determine whether the magic number matches the expected value as a sanity check (`assert(hptr->magic == 1234567)`)
- calculate the total size of the newly-freed region via simple math (i.e., adding the size of the header to size of the region).

==== Embedding A Free List

How do we build a linked list inside the free space itself?

Assume we have a 4096-byte chunk of memory to manage. We first have to initialize said list; initially, the list should have one entry, of size 4096 (minus the header size).

```c
typedef struct __node_t {
  int size;
  struct __node_t *next;
} node_t;
```

Initializes the heap and puts the first element of the free list inside that space.

#tip("Tip")[
  We are assuming that the heap is built within some free space acquired via a call to the system call `mmap()`
] 

```c
// mmap() returns a pointer to a chunk of free space
node_t *head = mmap(NULL, 4096, PROT_READ|PROT_WRITE,
MAP_ANON|MAP_PRIVATE, -1, 0);
head->size = 4096 - sizeof(node_t);
head->next = NULL;
```

After running this code, the status of the list is that it has a single entry, of size 4088.

The head pointer contains the beginning address of this range; let’s assume it is 16KB (though any virtual address would be fine).

#image("images/2023-12-18-07-49-18.png", width: 70%)

Let’s imagine that a chunk of memory is requested, say of size 100 bytes.
The library will first find a chunk that is large enough to accommodate the request; because there is only one free chunk (size: 4088), this chunk will be chosen.
Then, the chunk will be split into two: one chunk big enough to service the request, and the remaining free chunk. Assuming an 8-byte header (an integer size and an integer magic number). Upon the request for 100 bytes, the library allocated 108 bytes out of the existing one free chunk.
#image("images/2023-12-18-07-50-48.png", width: 70%)

Let’s look at the heap when there are three allocated regions, each of 100 bytes (or 108 including the header).
#image("images/2023-12-18-10-40-49.png", width: 70%)

Calling free(16500) (the value 16500 = 16KB+108B).This value is shown in the previous diagram by the pointer `sptr`.
#image("images/2023-12-18-10-42-36.png", width: 70%)

Let’s assume now that the last two in-use chunks are freed. Without coalescing, you might end up with a free list that is highly fragmented:
#image("images/2023-12-18-10-43-19.png", width: 70%)

The solution is simple: go through the list and *merge* neighboring chunks; when finished, the heap will be whole again.

==== Growing The Heap

Specifically, what should you do if the heap runs out of space?
The simplest approach is just to fail.

Most traditional allocators start with a small-sized heap and then request more memory from theOS when they run out.

- Typically, this means they make some kind of system call (e.g., `sbrk` in most UNIX systems) to grow the heap, and then allocate the new chunks from there. To service the `sbrk` request,
  - the OS finds free physical pages
  - maps them into the address space of the requesting process
  - returns the value of the end of the new heap

=== Basic Strategies

The ideal allocator is both fast and minimizes fragmentation.

The stream of allocation and free requests can be arbitrary (after all, they are determined by the programmer), any particular strategy can do quite badly given the wrong set of inputs.

==== Best Fit

First, search through the free list and find chunks of free memory that are as big or bigger than the requested size.

Then, return the one that is the smallest in that group of candidates; this is the so called best-fit chunk (it could be called *smallest fit* too).

A full search of free space is required

==== Worst Fit

Find the largest chunk and return the requested amount

Keep the remaining (large) chunk on the free list.

A full search of free space is required. Worse, most studies show that it performs badly, leading to excess fragmentation while still having high overheads.

==== First Fit

finds the first block that is big enough and returns the requested amount to the user

the remaining free space is kept free for subsequent requests.

The advantage of First fit is speed.

But Sometimes pollutes the beginning of the free list with small objects.

Thus, how the allocator manages the free list’s order becomes an issue. One approach is to use *address-based ordering*: by keeping the list ordered by the address of the free space, coalescing becomes easier, and fragmentation tends to be reduced.

==== Next Fit

The next fit algorithm keeps an extra pointer to the location within the list where one was looking last.

The idea is to spread the searches for free space throughout the list more uniformly, thus avoiding splintering of the beginning of the list.

=== Other Approaches

==== Segregated Lists

The basic idea is simple:

if a particular application has one (or a few) popular-sized request that it makes, keep a separate list just to manage objects of that size; all other requests are forwarded to a more general memory allocator.

The benefits:

- fragmentation is much less of a concern
- allocation and free requests can be served quite quickly when they are of the right size, as no complicated search of a list is required

This approach introduces new complications into a system:

How much memory should one dedicate to the pool of memory that serves specialized requests of a given size?

The *slab allocator* handles this issue in a rather nice way.

===== slab allocator

Specifically, when the kernel boots up, it allocates a number of object caches for kernel objects that are likely to be requested frequently (such as locks, file-system inodes, etc.); the object caches thus are each segregated free lists of a given size and serve memory allocation and free requests quickly.

- When a given cache is running low on free space, it requests some slabs of memory from a more general memory allocator .
  #tip("Tip")[
   the total amount requested being a multiple of the page size and the object in question   
  ] 
- When the reference counts of the objects within a given slab all go to zero, the general allocator can reclaim them from the specialized allocator, which is often done when the VM system needs more memory.

The slab allocator also goes beyond most segregated list approaches by keeping free objects on the lists in a pre-initialized state.

By keeping freed objects in a particular list in their initialized state, the slab allocator thus avoids frequent initialization and destruction cycles per object and thus lowers overheads noticeably.

==== Buddy Allocation

Some approaches have been designed around making *coalescing* simple. One good example is found in the *binary buddy allocator*.

In such a system, free memory is first conceptually thought of as one big space of size 2^N.

When a request for memory is made, the search for free space recursively divides free space by two until a block that is big enough to accommodate the request is found (and a further split into two would result in a space that is too small). At this point, the requested block is returned to the user.

Here is an example of a 64KB free space getting divided in the search for a 7KB block:

#image("images/2023-12-18-12-17-32.png", width: 60%)

In the example, the leftmost 8KB block is allocated (as indicated by the darker shade of gray) and returned to the user.

#tip("Tip")[
 Note that this scheme can suffer from *internal fragmentation*, as you are only allowed to give out power-of-two-sized blocks.   
] 

The beauty of buddy allocation is found in what happens *when that block is freed*.

When returning the 8KB block to the free list,

- The allocator checks whether the “buddy” 8KB is free; if so, it coalesces the two blocks into a 16KB block.
- The allocator then checks if the buddy of the 16KB block is still free; if so, it coalesces those two blocks.

This recursive coalescing process continues up the tree, either restoring the entire free space or stopping when a buddy is found to be in use.

The reason buddy allocation works so well is that it is simple to determine the buddy of a particular block.

The address of each buddy pair only differs by a single bit; which bit is determined by the level in the buddy tree.

==== Other Ideas

One major problem with many of the approaches described above is their lack of *scaling*.

Specifically, searching lists can be quite slow. More complex data structures to address these costs, trading simplicity for performance. 
Examples include balanced binary trees, splay trees, or partially-ordered trees..

Given that modern systems often have multiple processors and run multi-threaded workloads. It is not surprising that a lot of effort has been spent making allocators work well on multiprocessor-based systems.

the glibc allocator
