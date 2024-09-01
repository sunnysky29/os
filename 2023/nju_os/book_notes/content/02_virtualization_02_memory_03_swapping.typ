#import "../template.typ": *
#pagebreak()
= Swap

== Swapping: Mechanism

We’ve been assuming that every address space of every running process fits into memory. We will now relax these big assumptions, and assume that we wish to support many concurrently-running large address spaces.

To do so, we require an additional level in the *memory hierarchy*. To support large address spaces, the OS will need a place to stash away portions of address spaces that currently aren’t in great demand.

For now, just assume we have *a big and relatively-slow device* which we can use to help us build the illusion of a very large virtual memory, even bigger than physical memory itself. In modern systems, this role is usually served by *a hard disk drive*.

A contrast is found in older systems that used *memory overlays*, which required programmers to manually move pieces of code or data in and out of memory as they were needed

The invention of multiprogramming almost demanded the ability to swap out some pages, as early machines clearly could not hold all the pages needed by all processes at once.

Thus, the combination of multiprogramming and ease-of-use leads us to want to support using more memory than is physically available.

=== Swap Space

The first thing we will need to do is to reserve some space on the disk for moving pages back and forth. We generally refer to such space as *swap space*.

We _swap_ pages out of memory to it and _swap_ pages into memory from it.

Thus, we will simply assume that the OS can read from and write to the swap space, in page-sized units. To do so, the OS will need to remember the *disk address* of a given page.

The size of the swap space is important, but let us assume for simplicity that it is very large for now.

#image("images/2023-12-20-18-43-59.png", width: 80%)

Swap space is not the only on-disk location for swapping traffic.

Assume you are running a program binary. The code pages from this binary are initially found on disk, and when the program runs, they are loaded into memory.However, if the system needs to make room in physical memory for other needs, it can safely re-use the memory space for these code pages, knowing that it can later swap them in again from the on-disk binary in the file system.

=== The Present Bit

Now that we have some space on the disk, we need to add some machinery higher up in the system in order to support swapping pages to and from the disk.

Let us assume, for simplicity, that we have a system with a hardware-managed TLB.

Recall first what happens on a memory reference. The running process generates virtual memory references, and, the hardware translates them into physical addresses before fetching the desired data from memory.

If we wish to allow pages to be swapped to disk, however, we must add even more machinery. Specifically, when the hardware looks in the PTE, it may find that the page is not present in physical memory.

The way the hardware/OS determines this is through a new piece of information in each page-table entry, known as the *present bit*.

- If the present bit is set to one, it means the page is present in physical memory and everything proceeds as above;
- If it is set to zero, the page is not in memory but rather on disk somewhere.

The act of accessing a page that is not in physical memory is commonly referred to as a *page fault*. Upon a page fault, the OS is invoked to service the page fault. A particular piece of code, known as a *page-fault handler*.

==== SWAPPING TERMINOLOGY AND OTHER THINGS

Terminology in virtual memory systems can be a little confusing and variable across machines and operating systems.

For example, a *page fault* more generally could refer to any reference to a page table that generates a fault of some kind:

- a page-not-present fault
- illegal memory accesses

Indeed, it is odd that we call what is definitely a legal access (to a page mapped into the virtual address space of a process, but simply not in physical memory at the time) a “fault” at all; really, it should be called a *page miss*. But often, when people say a program is “page faulting”, they mean that it is accessing parts of its virtual address space that the OS has swapped out to disk.

=== The Page Fault

If a page is not present, the OS is put in charge to handle the page fault.

#tip("Tip")[
Virtually all systems handle page faults in software; even with a hardware-managed TLB.
]

If a page is not present and has been swapped to disk, the OS will need to swap the page into memory in order to service the page fault.

How will the OS know where to find the desired page?

In many systems, *the page table* is a natural place to store such information. Thus, the OS could use the bits in the PTE normally used for data such as the PFN of the page for a disk address.

- When the OS receives a page fault for a page, it looks in the PTE to find the address, and issues the request to disk to fetch the page into memory.
- The disk I/O completes, the OS will then update the page table to mark the page as present, update the PFN field of the page-table entry (PTE) to record the in-memory location of the newly-fetched page, and retry the instruction.
- This next attempt may generate a TLB miss, which would then be serviced and update the TLB with the translation.
- Finally, a last restart would find the translation in the TLB and thus proceed to fetch the desired data or instruction from memory at the translated physical address.

#tip("Tip")[
Note that while the I/O is in flight, the process will be in the blocked state. Thus, the OS will be free to run other ready processes while the page fault is being serviced.
]

==== WHY HARDWARE DOESN’T HANDLE PAGE FAULTS

- First, page faults to disk are slow; even if the OS takes a long time to handle a fault, executing tons of instructions, the disk operation itself is traditionally so slow that the extra overheads of running software are minimal.(*performance*)
- Second, to be able to handle a page fault, the hardware would have to understand swap space, how to issue I/Os to the disk, and a lot of other details which it currently doesn’t know much about.(*simplicity*)

=== If Memory Is Full?

Before we assumed there is plenty of free memory in which to *page in* a page from swap space. Memory may be full (or close to it). Thus, the OS might like to first *page out* one or more pages to make room for the new page(s) the OS is about to bring in. The process of picking a page to kick out, or *replace* is known as the *page-replacement policy*.

=== Page Fault Control Flow

==== Hardware

#code(caption: [Page Fault Control Flow - Hardware])[
```c
VPN = (VirtualAddress & VPN_MASK) >> SHIFT
(Success, TlbEntry) = TLB_Lookup(VPN)
if (Success == True) // TLB Hit
    if (CanAccess(TlbEntry.ProtectBits) == True)
        Offset = VirtualAddress & OFFSET_MASK
        PhysAddr = (TlbEntry.PFN << SHIFT) | Offset
        Register = AccessMemory(PhysAddr)
    else
        RaiseException(PROTECTION_FAULT)
else // TLB Miss
    PTEAddr = PTBR + (VPN * sizeof(PTE))
    PTE = AccessMemory(PTEAddr)
    if (PTE.Valid == False)
        RaiseException(SEGMENTATION_FAULT)
    else
        if (CanAccess(PTE.ProtectBits) == False)
            RaiseException(PROTECTION_FAULT)
        else if (PTE.Present == True)
            // assuming hardware-managed TLB
            TLB_Insert(VPN, PTE.PFN, PTE.ProtectBits)
            RetryInstruction()
        else if (PTE.Present == False)
            RaiseException(PAGE_FAULT)
```
]

==== Software

#code(caption: [Page Fault Control Flow - Software])[
```c
PFN = FindFreePhysicalPage()
if (PFN == -1) // no free page found
    PFN = EvictPage() // run replacement algorithm
DiskRead(PTE.DiskAddr, PFN) // sleep (waiting for I/O)
PTE.present = True // update page table with present
PTE.PFN = PFN // bit and translation (PFN)
RetryInstruction() // retry instruction
```
]

The retry will result in a TLB miss, and then, upon another retry, a TLB hit, at which point the hardware will be able to access the desired item.

=== When Replacements Really Occur

The way we’ve described how replacements occur assumes that the OS waits until memory is entirely full, and only then replaces (evicts) a page to make room for some other page.

As you can imagine, this is a little bit unrealistic, and there are many reasons for the OS to *keep a small portion of memory free more proactively*.

To keep a small amount of memory free, most operating systems thus have some kind of *high watermark (HW)* and *low watermark (LW)* to help decide when to start evicting pages from memory.

How this works is as follows:

When the OS notices that there are fewer than LW pages available, a background thread that is responsible for freeing memory runs. The thread evicts pages until there are HW pages available. The background thread, sometimes called the *swap daemon* or *page daemon*, then goes to sleep, happy that it has freed some memory for running processes and the OS to use.

By performing a number of replacements at once, new performance optimizations become possible.

For example, many systems will *cluster* or *group* a number of pages and write them out at once to the swap partition, thus increasing the efficiency of the disk.

To work with the background paging thread, the control flow in software above should be modified slightly:

Instead of performing a replacement directly, the algorithm would instead simply check if there are any free pages available.

- If not, it would inform the background paging thread that free pages are needed;
- When the thread frees up some pages, it would re-awaken the original thread, which could then page in the desired page and go about its work.

==== DO WORK IN THE BACKGROUND

When you have some work to do, it is often a good idea to do it in the background to increase efficiency and to allow for grouping of operations.

Operating systems often do work in the background; for example, many systems buffer file writes in memory before actually writing the data to disk.

Doing so has many possible benefits:

- increased disk efficiency;
- improved latency of writes, as the application thinks the writes completed quite quickly;
- the possibility of work reduction, as the writes may need never to go to disk (i.e., if the file is deleted);
- and better use of idle time, as the background work may possibly be done when the system is otherwise idle, thus better utilizing the hardware.

== Swapping: Policies

Unfortunately, things get a little more interesting when little memory is free.

In such a case, this *memory pressure* forces the OS to start paging out pages to make room for actively-used pages. Deciding which page (or pages) to *evict* is encapsulated within the *replacement policy* of the OS.

=== Cache Management

Given that main memory holds some subset of all the pages in the system, it can rightly be viewed as a *cache* for virtual memory pages in the system. Thus, our goal in picking a replacement policy for this cache is to minimize the number of *cache misses*(or maximizing the number of *cache hits*).

Knowing the number of cache hits and misses let us calculate the *average memory access time (AMAT)* for a program.
$ "AMAT" = T_(M) + (P_("Miss") \cdot T_(D)) $

- $T_(M)$ -> the cost of accessing memory
- $T_(D)$ -> the cost of accessing disk
- $P_("Miss")$ -> the probability of not finding the data in the cache (a miss);

=== The Optimal Replacement Policy

The optimal replacement policy leads to the fewest number of misses overall.

Belady showed that a simple (but, unfortunately, difficult to implement!) approach that replaces the page that will be accessed furthest in the future is the optimal policy, resulting in the fewest-possible cache misses.

Hopefully, the intuition behind the optimal policy makes sense. Think about it like this:

If you have to throw out some page, why not throw out the one that is needed the furthest from now? By doing so, you are essentially saying that all the other pages in the cache are more important than the one furthest out.

The reason this is true is simple: you will refer to the other pages before you refer to the one furthest out.

Assume a program accesses the following stream of virtual pages: 0, 1, 2, 0, 1, 3, 0, 3, 1, 2, 1.

#image("images/2023-12-21-09-58-59.png", width: 60%)

The first three accesses are misses, as the cache begins in an empty state; such amiss is sometimes referred to as a *cold-start miss (or compulsory miss)*.

Then we refer again to pages 0 and 1, which both hit in the cache.

Finally, we reach another miss (to page 3), but this time the cache is full. Which page should we replace?

With the optimal policy, we examine the future for each page currently in the cache (0, 1, and 2), and see that 0 is accessed almost immediately, 1 is accessed a little later, and 2 is accessed furthest in the future. Thus the optimal policy has an easy choice: evict page 2, resulting in pages 0, 1, and 3 in the cache.

...

Hit rate = Hits/(Hits+Misses) which is 6/(6+5) or 54.5%.

#tip("Tip")[
 We can also compute the hit rate modulo compulsory misses (i.e., ignore the first miss to a given page), resulting in a 85.7% hit rate.   
] 

Sadly, the future is not generally known!

==== COMPARING AGAINST OPTIMAL IS USEFUL

Although optimal is not very practical as a real policy, it is incredibly useful as a comparison point in simulation or other studies.

Thus, in any study you perform, knowing what the optimal is lets you perform a better comparison, showing *how much improvement is still possible*, and also *when you can stop making your policy better*.

=== A Simple Policy: FIFO

Pages were simply placed in a queue when they enter the system; when a replacement occurs, the page on the tail of the queue (the “first-in” page) is evicted.

#tip("Tip")[
 FIFO has one great strength: it is quite simple to implement.   
] 

#image("images/2023-12-21-10-09-34.png",width: 60%)

Comparing FIFO to optimal, FIFO does notably worse: a 36.4% hit rate (or 57.1% excluding compulsory misses).

FIFO simply can’t determine the importance of blocks.

==== BELADY’S ANOMALY

The memory reference stream: 1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5. The replacement policy they were studying was FIFO. The interesting part: how the cache hit rate changed when moving from a cache size of 3 to 4 pages.

In general, you would expect the cache hit rate to increase (get better) when the cache gets larger. But in this case, with FIFO, it gets worse! This odd behavior is generally referred to as *Belady’s Anomaly*(to the chagrin of his co-authors).

Some other policies, such as LRU, don’t suffer from this problem. As it turns out, LRU has what is known as a *stack property*.

For algorithms with this property, a cache of size N + 1 naturally includes the contents of a cache of size N. Thus, when increasing the cache size, hit rate will either stay the same or improve. FIFO and Random (among others) clearly do not obey the stack property, and thus are susceptible to anomalous behavior.

=== Another Simple Policy: Random

This policy is to simply picks a random page to replace under memory pressure.
#image("images/2023-12-21-10-14-26.png", width: 60%)

How Random does depends entirely upon how lucky (or unlucky) Random gets in its choices.

We can run the Random experiment thousands of times and determine how it does in general. Figure below shows how many hits Random achieves over 10,000 trials, each with a different random seed.
#image("images/2023-12-21-10-15-38.png", width:60%)

=== Using History: LRU

If a program has accessed a page in the near past, it is likely to access it again in the near future.

- One type of historical information a page-replacement policy could use is *frequency*; if a page has been accessed many times, perhaps it should not be replaced as it clearly has some value.
- A more commonly used property of a page is its *recency* of access; the more recently a page has been accessed, perhaps the more likely it will be accessed again.

This family of policies is based on what people refer to as the *principle of locality*.

- The *Least-Frequently-Used (LFU)* policy replaces the least-frequently-used page when an eviction must take place.
- The *Least-Recently- Used (LRU)* policy replaces the least-recently-used page.
#tip("Tip")[
  - Note that the opposites of these algorithms exist: *Most-Frequently-Used (MFU)* and *Most-Recently-Used (MRU)*.
  - In most cases, these policies do not work well, as they ignore the locality most programs exhibit instead of embracing it.
]

#image("images/2023-12-21-20-07-19.png", width: 60%)

In our example, LRU does as well as possible, matching optimal in its performance.

==== TYPES OF LOCALITY

There are two types of locality that programs tend to exhibit.

The first is known as *spatial locality*, which states that if a page P is accessed, it is likely the pages around it (say P − 1 or P + 1) will also likely be accessed.

The second is *temporal locality*, which states that pages that have been accessed in the near past are likely to be accessed again in the near future.

The assumption of the presence of these types of locality plays a large role in the caching hierarchies of hardware systems, which deploy many levels of instruction, data, and address-translation caching to help programs run fast when such locality exists.

=== Workload Examples

We’ll examine more complex *workloads* instead of small traces.

==== no locality workload

Our first workload *has no locality*, which means that each reference is to a random page within the set of accessed pages.

In this simple example, the workload accesses 100 unique pages over time, choosing the next page to refer to at random; overall, 10,000 pages are accessed. In the experiment, we vary the cache size from very small (1 page) to enough to hold all the unique pages (100 page), in order to see how each policy behaves over the range of cache sizes.

#image("images/2023-12-21-20-11-24.png", width: 60%)

- First, when there is no locality in the workload, it doesn’t matter much which realistic policy you are using; exactly *determined by the size of the cache*.
- Second, when the cache is large enough to fit the entire workload, it also doesn’t matter which policy you use.
- Finally, you can see that optimal performs noticeably better than the realistic policies.

==== 80-20 workload

The next workload we examine is called the “80-20” workload, which exhibits locality: 80% of the references are made to 20% of the pages (the “hot” pages); the remaining 20% of the references are made to the remaining 80% of the pages (the “cold” pages).

In our workload, there are a total 100 unique pages again; thus, “hot” pages are referred to most of the time, and “cold” pages the remainder.

#image("images/2023-12-21-20-26-45.png", width: 60%)

As you can see from the figure, while both random and FIFO do reasonably well, LRU does better, as it is more likely to hold onto the hot pages; as those pages have been referred to frequently in the past, they are likely to be referred to again in the near future.

You might now be wondering: is LRU’s improvement over Random and FIFO really that big of a deal?

The answer, as usual, is “it depends.” If each miss is very costly (not uncommon), then even a small increase in hit rate (reduction in miss rate) can make a huge difference on performance. If misses are not so costly, then of course the benefits possible with LRU are not nearly as important.

==== looping sequential workload

We refer to 50 pages in sequence, starting at 0, then 1, ..., up to page 49, and then we loop, repeating those accesses, for a total of 10,000 accesses to 50 unique pages.

#image("images/2023-12-21-20-30-23.png", width: 60%)

This workload, common in many applications (including important commercial applications such as databases [CD85]), represents a worst case for both LRU and FIFO.

Random has some nice properties; one such property is not having weird corner-case behaviors.

=== Implementing Historical Algorithms

Let’s take, for example, LRU.

Specifically, upon each _page access_, we must update some data structure to move this page to the front of the list (i.e., the MRU side).

Contrast this to FIFO, where the FIFO list of pages is only accessed when a page is evicted (by removing the first-in page) or when a new page is added to the list (to the last-in side).

To keep track of which pages have been least- and most-recently used, the system has to do some accounting work on every memory reference. Clearly, without great care, such accounting could greatly reduce performance.

One method that could help speed this up is to add a little bit of hardware support.

For example, a machine could update, on each page access, a time field in memory (for example, this could be in the per-process page table, or just in some separate array in memory, with one entry per physical page of the system).

Thus, when a page is accessed, the time field would be set, by hardware, to the current time. Then, when replacing a page, the OS could simply scan all the time fields in the system to find the least-recently-used page.

Unfortunately, as the number of pages in a system grows, scanning a huge array of times just to find the absolute least-recently-used page is prohibitively *expensive*.

=== Approximating LRU

Do we really need to find the absolute oldest page to replace? Can we instead survive with an approximation?

The idea requires some hardware support, in the form of a *use bit* (sometimes called the *reference bit*). There is one use bit per page of the system, and the use bits live in memory somewhere (they could be in the per-process page tables, for example, or just in an array somewhere).

Whenever a page is referenced (i.e., read or written), the use bit is set by hardware to 1. The hardware never clears the bit, though (i.e., sets it to 0); that is the responsibility of the OS.

How does the OS employ the use bit to approximate LRU?

There could be a lot of ways, but with the *clock algorithm*, one simple approach was suggested.

Imagine all the pages of the system arranged in a circular list. *A clock hand* points to some particular page to begin with.

When a replacement must occur, the OS checks if the currently-pointed to page P has a use bit of 1 or 0.

- If 1, this implies that page P was recently used and thus is not a good candidate for replacement. Thus, the use bit for P set to 0 (cleared), and the clock hand is incremented to the next page (P + 1).
- The algorithm continues until it finds a use bit that is set to 0, implying this page has not been recently used (or, in the worst case, that all pages have been and that we have now searched through the entire set of pages, clearing all the bits).

#tip("Tip")[
- Note that this approach is not the only way to employ a use bit to approximate LRU.
- Indeed, any approach which periodically clears the use bits and then differentiates between which pages have use bits of 1 versus 0 to decide which to replace would be fine.
- The clock algorithm of Corbato’s was just one early approach which met with some success, and had the nice property of not repeatedly scanning through all of memory looking for an unused page.

]

#image("images/2023-12-21-20-40-09.png", width: 60%)

As you can see, although it doesn’t do quite as well as perfect LRU, it does better than approaches that don’t consider history at all.

=== Considering Dirty Pages

One small modification to the clock algorithm that is commonly made is the additional consideration of whether a page has been modified or not while in memory. The reason for this:

- If a page has been *modified* and is thus *dirty*, it must be written back to disk to evict it, which is expensive.
- If it has not been modified (and is thus clean), the eviction is free; the physical frame can simply be reused for other purposes without additional I/O.

Thus, some VM systems prefer to evict clean pages over dirty pages.

To support this behavior, the hardware should include a *modified bit* (a.k.a. *dirty bit*).

This bit is set any time a page is written, and thus can be incorporated into the page-replacement algorithm.

The clock algorithm, for example, could be changed to scan for pages that are *both unused and clean* to evict first; failing to find those, then for unused pages that are dirty, and so forth.

=== Other VM Policies

Page replacement is not the only policy the VM subsystem employs (though it may be the most important).

For example, the OS also has to decide when to bring a page into memory. This policy, sometimes called the *page selection* policy (as it was called by Denning [D70]), presents the OS with some different options.

For most pages, the OS simply uses *demand paging*, which means the OS brings the page into memory when it is accessed, “on demand” as it were.

Of course, the OS could guess that a page is about to be used, and thus bring it in ahead of time; this behavior is known as *prefetching* and should only be done when there is reasonable chance of success.

For example, some systems will assume that if a code page P is brought into memory, that code page P+1 will likely soon be accessed and thus should be brought into memory too.

Another policy determines *how the OS writes pages out to disk*. Of course, they could simply be written out one at a time; however, many systems instead collect a number of pending writes together in memory and write them to disk in one write.

This behavior is usually called *clustering* or simply *grouping* of writes, and is effective because of the nature of disk drives, which perform a single large write more efficiently than many small ones.

=== Thrashing

What should the OS do when memory is simply oversubscribed, and the memory demands of the set of running processes simply exceeds the available physical memory?

In this case, the system will constantly be paging, a condition sometimes
referred to as *thrashing*.

Some earlier operating systems had a fairly sophisticated set of mechanisms to both detect and cope with thrashing when it took place.

For example, given a set of processes, a system could decide not to run a subset of processes, with the hope that the reduced set of processes’ *working sets* (the pages that they are using actively) fit in memory and thus can make progress.

This approach, generally known as *admission control*, states that it is sometimes better to do less work well than to try to do everything at once poorly, a situation we often encounter in real life as well as in modern computer systems.

Some current systems take more a draconian approach to memory overload.

For example, some versions of Linux run an *out-of-memory killer* when memory is oversubscribed; this daemon chooses a memory-intensive process and kills it, thus reducing memory in a none-too-subtle manner.

While successful at reducing memory pressure, this approach can have problems, for example, it kills the X server and thus renders any applications requiring the display unusable.

=== Summary

Modern systems add some tweaks to straightforward LRU approximations like clock; for example, *scan resistance* is an important part of many modern algorithms, such as *ARC*.

Scan-resistant algorithms are usually LRU-like but also try to avoid the worst-case behavior of LRU, which we saw with the looping-sequential workload. Thus, the evolution of page-replacement algorithms continues.

However, in many cases the importance of said *algorithms has decreased*, as the discrepancy between memory-access and disk-access times has increased.

Because paging to disk is so expensive, the cost of frequent paging is prohibitive. Thus, the best solution to excessive paging is often a simple (if intellectually unsatisfying) one: *buy more memory*.
