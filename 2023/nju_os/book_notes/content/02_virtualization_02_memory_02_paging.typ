#import "../template.typ": *
#pagebreak()
== Intro to Paging

Another approach to solve the external-fragment problems: to chop up space into *fixed-sized* pieces.

- We divide it into fixed-sized units, each of which we call a *page*.
- Correspondingly,we view physical memory as an array of fixed-sized slots called *page frames*; each of these frames can contain a single virtual-memory page.

=== A Simple Example And Overview

A tiny address space, only 64 bytes total in size, with four 16-byte pages (virtual pages 0, 1, 2, and 3).

#image("images/2023-12-14-21-34-34.png", width: 70%)

Physical memory, as shown in Figure below, also consists of a number of fixed-sized slots, in this case eight page frames (making for a 128-byte physical memory, also ridiculously small).
#image("images/2023-12-14-21-35-20.png", width: 70%)

The advantages of paging:

- The most important improvement will be flexibility: we won’t, for example, make assumptions about the direction the heap and stack grow and how they are used.
- Another advantage is the simplicity of free-space management that paging affords. Perhaps the OS keeps a free list of all free pages for this, and just grabs the first four free pages off of this list.

To record where each virtual page of the address space is placed in physical memory, the operating system usually keeps a *per-process* data structure known as a *page table*.(One of the most important data structures!)

The major role of the page table is to store address translations for each of the virtual pages of the address space, thus letting us know where in physical memory each page resides.

#tip("Tip")[
  Most page table structures we discuss are per-process structures; an exception we’ll touch on is the *inverted page table*.  
] 

For our simple example, the page table would thus have the following four entries: (Virtual Page 0 → Physical Frame 3), (VP 1→PF 7), (VP 2→PF 5), and (VP 3→PF 2).

==== how does it works?

Let’s imagine the process with that tiny address space (64 bytes) is performing a memory access:

```
movl <virtual address>, %eax
```

the explicit load of the data from address `<virtual address>` into the register `eax`.

To translate this virtual address that the process generated, we have to first split it into two components: the *virtual page number (VPN)*, and the *offset* within the page.

For this example, we need 6 bits total for our virtual address (2^6 = 64). Thus, our virtual address can be conceptualized as follows:
#image("images/2023-12-14-21-42-54.png", width: 50%)

- The page size is 16 bytes in a 64-byte address space; thus we need to be able to select 4 pages, and the top 2 bits of the address do just that. Thus, we have a 2-bit virtual page number (VPN).
- The remaining bits tell us which byte of the page we are interested in, 4 bits in this case; we call this the offset.

For example, let us assume the load above was to virtual address 21:

```
movl 21, %eax
```

Turning “21” into binary form, we get “010101”, Thus, the virtual address “21” is on the 5th (“0101”th) byte of virtual page “01” (or 1).

With our virtual page number, we can now index our page table and find which physical frame virtual page 1 resides within.

In the page table above the *physical frame number (PFN)* (also sometimes called the *physical page number or PPN*) is 7 (binary 111). Thus, we can translate this virtual address by replacing the VPNwith the PFNand then issue the load to physical memory. Our final physical address is 1110101.
#image("images/2023-12-14-21-47-41.png", width: 70%)

#tip("Tip")[
Note the offset stays the same.
]

- Where are these page tables stored?
- What are the typical contents of the page table?
- How big are the tables?
- Does paging make the system (too) slow?

=== Where Are Page Tables Stored?

For example, imagine a typical 32-bit address space, with 4KB pages.

This virtual address splits into a 20-bit VPN and 12-bit offset.

Horribly! 2^20 pages, assuming we need 4 bytes per *page table entry (PTE)* to hold the physical translation plus any other useful stuff, we get an immense *4MB* of memory needed for each page table!

Because page tables are so big,we don’t keep any special on-chip hardware in the MMU to store the page table of the currently-running process.

Instead, we store the page table for each process in memory somewhere.
#image("images/2023-12-14-21-53-57.png", width: 70%)

=== What’s Actually In The Page Table?

The page table is just a data structure that is used to map virtual addresses (or really, virtual page numbers) to physical addresses (physical frame numbers).

The simplest data structure is called a linear page table, which is just an array.

The OS *indexes the array by the virtual page number (VPN)*, and looks up the page-table entry (PTE) at that index in order to find the desired physical frame number (PFN).

==== valid bit

A *valid bit* is common to indicate whether the particular translation is valid.

All the unused space in-between will be marked invalid, and if the process tries to access such memory, it will generate a trap to the OS which will likely terminate the process.

#tip("Tip")[
The valid bit is crucial for supporting a sparse address space; by simply marking all the unused pages in the address space invalid, we remove the need to allocate physical frames for those pages and thus save a great deal of memory.
]

==== others

- *Protection bits*: Indicate whether the page could be read from, written to, or executed from.
- *present bit*: Indicates whether this page is in physical memory or on disk (i.e., it has been swapped out).
- *A dirty bit*: Indicating whether the page has been modified since it was brought into memory.
- *A reference bit* (a.k.a. *accessed bit*) is sometimes used to track whether a page has been accessed, and is useful in determining which pages are popular and thus should be kept in memory; such knowledge is critical during *page replacement*.

==== x86 architecture PTE

#image("images/2023-12-14-21-55-03.png")

- a present bit (P);
- a read/write bit (R/W) which determines if writes are allowed to this page;
- a user/supervisor bit (U/S) which determines if user-mode processes can access the page;
- a few bits (PWT, PCD, PAT, and G) that determine how hardware caching works for these pages;
- an accessed bit (A) and a dirty bit (D);
- and finally, the page frame number (PFN) itself.

=== Paging: Also Too Slow

```
movl 21, %eax
```

To fetch the desired data, the system must first translate the virtual address (21) into the correct physical address (117).

Thus, before fetching the data from address 117, the system must first fetch the proper page table entry from the process’s page table, perform the translation, and then load the data from physical memory.

To do so, the hardware must know where the page table is for the currently-running process. Let’s assume for now that a single *page-table base register* contains the physical address of the starting location of the page table.

```c
VPN = (VirtualAddress & VPN_MASK) >> SHIFT
PTEAddr = PageTableBaseRegister + (VPN * sizeof(PTE))
offset = VirtualAddress & OFFSET_MASK
PhysAddr = (PFN << SHIFT) | offset
```

In our example,

- `VPN_MASK` to `0x30`
- `SHIFT` is set to `4`

```c
// Extract the VPN from the virtual address
VPN = (VirtualAddress & VPN_MASK) >> SHIFT

// Form the address of the page-table entry (PTE)
PTEAddr = PTBR + (VPN * sizeof(PTE))

// Fetch the PTE
PTE = AccessMemory(PTEAddr)

// Check if process can access the page
if (PTE.Valid == False)
    RaiseException(SEGMENTATION_FAULT)
else if (CanAccess(PTE.ProtectBits) == False)
    RaiseException(PROTECTION_FAULT)
else
    // Access is OK: form physical address and fetch it
    offset = VirtualAddress & OFFSET_MASK
    PhysAddr = (PTE.PFN << PFN_SHIFT) | offset
    Register = AccessMemory(PhysAddr)
```

Paging requires us to perform one extra memory reference in order to first fetch the translation from the page table.

Without careful design of both hardware and software, page tables will cause the system to run too slowly, as well as take up too much memory

=== A Memory Trace

```c
int array[1000];
...
for (i = 0; i < 1000; i++)
    array[i] = 0;
```

```asm
1024 movl $0x0,(%edi,%eax,4)  // %edi+4*%eax=0
1028 incl %eax                // %eax++
1032 cmpl $0x03e8,%eax        // 1000=%eax?
1036 jne 0x1024               // 1000!=%eax -> 1024
```

- We assume a virtual address space of size 64KB.
- We also assume a page size of 1KB.

#image("images/2023-12-15-18-18-23.png", width: 80%)

First, there is the virtual page the *code* lives on.

Because the page size is 1KB, virtual address 1024 resides on the second page of the virtual address space (VPN=1, as VPN=0 is the first page).

Let’s assume this virtual page maps to physical frame 4 (VPN 1→PFN 4).

Next, there is the array itself. Its size is 4000 bytes (1000 integers), and we assume that it resides at virtual addresses 40000 through 44000 (not including the last byte).

Let’s assume these virtual-to-physical mappings for the example: (VPN39->PFN7), (VPN 40->PFN 8), (VPN 41->PFN 9), (VPN 42->PFN 10).

We are now ready to trace the memory references of the program.

Compile program -> VPN -> PPN

When it runs, each instruction fetch will generate two memory references:

- fetch the inst VA
- then access the corresponding page table in memory (memory access).
- then find the corresponding inst PA in the page table
- finally fetch the inst according to the inst PA(memory access)

If the inst has other access memory operation, then increment the access num for 2. For example: `1024 movl $0x0,(%edi,%eax,4)  // %edi+4*%eax=0` need to access the array.

- First fetch the array VA,
- then access the corresponding page table in memory (memory access).
- then find the corresponding array PA in the page table
- finally fetch the inst according to the array PA(memory access)

There are 10 memory accesses per loop, which includes four instruction fetches, one explicit update of memory, and five page table accesses to translate those four fetches and one explicit update.

==== THE PAGE TABLE

=== Summary

Paging has many advantages over previous approaches (such as segmentation).

- First, it does not lead to external fragmentation, as paging (by design) divides memory into fixed-sized units.
- Second, it is quite flexible, enabling the sparse use of virtual address spaces.

However, implementing paging support without care will lead to

- a slower machine (with many extra memory accesses to access the page table)
- as well as memory waste (with memory filled with page tables instead of useful application data).

== Paging: Faster Translations (TLBs)

To speed address translation, we are going to add what is called *a translation-lookaside buffer, or TLB*.

A TLB is part of the chip’s *memory-management unit (MMU),* and is simply a hardware cache of popular virtual-to-physical address translations; thus, a better name would be *an address-translation cache*.

=== TLB Basic Algorithm

Assuming *a simple linear page table* (i.e., the page table is an array) and *a hardware-managed TLB* (i.e., the hardware handles much of the responsibility of page table accesses;)

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
  else if (CanAccess(PTE.ProtectBits) == False)
    RaiseException(PROTECTION_FAULT)
  else
    TLB_Insert(VPN, PTE.PFN, PTE.ProtectBits)
    RetryInstruction()
```

The TLB, like all caches, is built on the premise that in the common case, translations are found in the cache (i.e., are hits).

When a miss occurs, the high cost of paging is incurred; it is our hope to avoid TLB misses as much as we can.

=== Example: Accessing An Array

Let’s assume:

- We have *an array of 10 4-byte integers* in memory, starting at virtual address 100.
- We have *a small 8-bit virtual address space*, with *16-byte pages*; thus, a virtual address breaks down into a 4-bit VPN (there are 16 virtual pages) and a 4-bit offset (there are 16 bytes on each of those pages).
  #image("images/2023-12-16-20-10-48.png", width: 50%)
- consider *a simple loop* that accesses each array element:
  ```c
  int sum = 0;
  for (i = 0; i < 10; i++) {
    sum += a[i];
  }
  ```
  > pretend that the only memory accesses the loop generates are *only to the array*

When the first array element (`a[0]`) is accessed, the CPU will see a load to virtual address 100. The hardware extracts the VPN from this (VPN=06), and uses that to check the TLB for a valid translation. Assuming this is the first time the program accesses the array, the result will be *a TLB miss*.

The next access is to `a[1]`, and there is some good news here: a TLB hit! Because the second element of the array is packed next to the first, it lives on the same page.
....

TLB activity during our ten accesses to the array:
```
miss, hit, hit, miss, hit, hit, hit, miss, hit, hit.
```

TLB hit rate = hits/accesses = 70%

The TLB improves performance due to *spatial locality*.

If the page size had simply been twice as big (32 bytes, not 16), the array access would suffer even fewer misses.

As typical page sizes are more like 4KB, these types of dense, array-based accesses achieve excellent TLB performance, encountering only a single miss per page of accesses.

#tip("Tip")[
 Theoretically, the bigger the page size is, the fewer misses.   
] 

One last point about TLB performance: if the program, soon after this loop completes, accesses the array again, assuming that we have a big enough TLB to cache the needed translations:

```
hit, hit, hit, hit, hit, hit, hit, hit, hit, hit.
```

#tip("Tip")[
In this case, the TLB hit rate would be high because of *temporal locality*
]

=== Who Handles The TLB Miss?

the hardware, or the software (OS)

==== Hardware

The hardware has to know exactly *where the page tables are* located in memory (via a page table base register), as well as their *exact format*.

On a miss:

- the hardware would “walk” the page table
- find the correct page-table entry and extract the desired translation
- update the TLB with the translation
- retry the instruction.

An example of an “older” architecture that has hardware-managed TLBs is the Intel x86 architecture, which uses *a fixed multi-level page table*; the current page table is pointed to by the `CR3` register.

#tip("Tip")[
CISC
]

==== OS

More modern architectures (e.g., MIPS R10k or Sun’s SPARC v9 [WG00], both *RISC* or reduced-instruction set computers) have what is known as *a software-managed TLB*.

On a TLB miss, the hardware simply raises an exception, which

- pauses the current instruction stream
- raises the privilege level to kernel mode
- jumps to a trap handler.

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
  RaiseException(TLB_MISS)
```

When run the trap handler, the code will

- lookup the translation in the page table
- use special “privileged” instructions to update the TLB
- and return from the trap
- at this point, the hardware retries the instruction (resulting in a TLB hit)

===== the return-from-trap instruction

The return-from-trap instruction needs to be a little different than the return-from-trap we saw before when servicing a system call.

- In the latter case, the return-from-trap should resume execution at the instruction *after* the trap into the OS.
- In the former case, when returning from a TLB miss-handling trap, the hardware must resume execution at the instruction that *caused* the trap, this retry thus lets the instruction run again, this time resulting in a TLB hit.

Depending on how a trap or exception was caused, the hardware must save a different PCwhen trapping into the OS.

===== an infinite chain of TLB misses

When running the TLBmiss-handling code, the OS needs to be extra careful not to cause an infinite chain of TLB misses to occur.

- keep TLB miss handlers in physical memory (where they are *unmapped* and not subject to address translation)
- reserve some entries in the TLB for permanently-valid translations and use some of those permanent translation slots for the handler code itself; these *wired* translations always hit in the TLB.

===== advantage

- flexibility: The OS can use any data structure it wants to implement the page table, without necessitating hardware change.
- simplicity: The hardware doesn’t do much on a miss: just raise an exception and let the OS TLB miss handler do the rest.

=== TLB Contents: What’s In There?

A typical TLB might have 32, 64, or 128 entries and be what is called *fully associative*(any given translation can be anywhere in the TLB). The hardware will search the entire TLB in parallel to find the desired translation.

A TLB entry might look like this:

```
|VPN|PPN|other bits|
```

- a valid bit, which says whether the entry has a valid translation or not.
- protection bits, which determine how a page can be accessed (as in the page table)
- a few other fields, including
  - an address-space identifier
  - a dirty bit
  - ...

=== TLB Issue: Context Switches

The TLB contains virtual-to-physical translations that are only valid for the currently running process.

As a result, when switching from one process to another, the hardware or OS must be careful to ensure that the about-to-be-run process does not accidentally use translations from some previously run process. (2 processes, what will happen if the same VPN is mapped to different PPNs, horrible!)

There are a number of possible solutions to this problem.

- One approach is to simply *flush* the TLB on context switches, thus emptying it before running the next process.
  - a software-based system, this can be accomplished with an explicit (and privileged) hardware instruction;
  - a hardware-managed TLB, the flush could be enacted when the page-table base register is changed.
  - In either case, the flush operation simply sets all valid bits to 0, essentially clearing the contents of the TLB.
    #tip("Tip")[
     Each time a process runs, it must incur TLB misses as it touches its data and code pages. If the OS switches between processes frequently, this cost may be high.   
    ] 
- add hardware support to enable sharing of the TLB across context switches
  #tip("Tip")[
  - Some hardware systems provide *an address space identifier (ASID)* field in the TLB.
  - You can think of the ASID as a process identifier (PID), but usually it has fewer bits (e.g., 8 bits for the ASID versus 32 bits for a PID).
  ] 

Thus, with *address-space identifiers*, the TLB can hold translations from different processes at the same time without any confusion.

- the hardware also needs to *know which process is currently running* in order to perform translations
- and thus the OS must, on a context switch, *set some privileged register* to the ASID of the current process.

There are two entries for two different processes with two different VPNs that point to the same physical page:
#image("images/2023-12-16-21-14-02.png", width: 50%)
This situation might arise, for example, when two processes share a page (a code page, for example).

=== Issue: Replacement Policy

As with any cache, and thus also with the TLB, one more issue that we must consider is cache replacement.
The goal, of course, being to *minimize the miss rate* (or *increase hit rate*) and thus improve performance.

- *least-recently-used or LRU*: it is likely that an entry that has not recently been used is a good candidate for eviction.
- *random policy*: evicts a TLB mapping at random.

A “reasonable” policy such as LRU behaves quite unreasonably when a program loops over n + 1 pages with a TLB of size n:
In this case, LRU misses upon every access, whereas random does much better.

=== A Real TLB Entry

This example is from the MIPS R4000, a modern system that uses software-managed TLBs. A slightly simplified MIPS TLB entry:
#image("images/2023-12-16-21-19-25.png")
The MIPS R4000 supports a 32-bit address space with 4KB pages.

==== bits

- There are only 19 bits for the VPN; as it turns out, user addresses will only come from half the address space (the rest reserved for the kernel).
- The VPN translates to up to a 24-bit physical frame number (PFN), and hence can support systems with up to 64GB of (physical)main memory (2^24 4KB pages).
- There are a few other interesting bits in the MIPS TLB.
  - a global bit (G), which is used for pages that are globally-shared among processes. Thus, if the global bit is set, the ASID is ignored.
  - the 8-bit ASID, which the OS can use to distinguish between address spaces.
  - Coherence (C) bits, which determine how a page is cached by the hardware (a bit beyond the scope of these notes)
  - a dirty bit which is marked when the page has been written to (we’ll see the use of this later)
  - a valid bit which tells the hardware if there is a valid translation present in the entry
  - a page mask field (not shown), which supports multiple page sizes
  - some of the 64 bits are unused (shaded gray in the diagram).

One question for you: what should the OS do if there are more than 256 (28) processes running at a time?

https://stackoverflow.com/questions/52813239/how-many-bits-there-are-in-a-tlb-asid-tag-for-intel-processors-and-how-to-handl

==== reserved for the OS

MIPS TLBs usually have 32 or 64 of these entries

- Most of which are used by user processes as they run
- A few are reserved for the OS

*A wired register* can be set by the OS to tell the hardware how many slots of the TLB to reserve for the OS

The OS uses these reserved mappings for code and data that it wants to access during critical times, where a TLB miss would be problematic (e.g., in the TLB miss handler).

==== update the TLB

TheMIPS provides four such instructions:

- `TLBP`, which probes the TLB to see if a particular translation is in there;
- `TLBR`, which reads the contents of a TLB entry into registers;
- `TLBWI`, which replaces a specific TLB entry;
- `TLBWR`, which replaces a random TLB entry.

The OS uses these instructions to manage the TLB’s contents. It is of course critical that these instructions are privileged.

=== Summary

*The TLB coverage*: If the number of pages a program accesses in a short period of time exceeds the number of pages that fit into the TLB, the program will generate a large number of TLB misses, and thus run quite a bit more slowly.

One solution is to include support for larger page sizes:

By mapping key data structures into regions of the program’s address space that are mapped by larger pages, the effective coverage of the TLB can be increased.

#tip("Tip")[
 Support for large pages is often exploited by programs such as *a database management system (a DBMS)*   
] 

TLB access can easily become a bottleneck in the CPU pipeline, in particular with what is called *a physically-indexed cache*.

With such a cache, address translation has to take place before the cache is accessed, which can slow things down quite a bit.

Because of this potential problem, people have looked into all sorts of clever ways to *access caches with virtual addresses*, thus avoiding the expensive step of translation in the case of a cache hit.

#tip("Tip")[
Such a *virtually-indexed cache* solves some performance problems, but introduces new issues into hardware design as well. See Wiggins’s fine survey for more details.
]

== Paging: Smaller Tables

We now tackle the second problem that paging introduces: page tables are too big and thus consume too much memory.

Assume again a 32-bit address space (232 bytes), with 4KB (2^12 byte) pages and a 4-byte page-table entry.

An address space thus has roughly one million virtual pages in it (2^20); multiply by the page-table entry size and you see that our page table is 4MB in size.

Recall also: we usually have one page table for every process in the system!

=== Simple Solution: Bigger Pages

Take our 32-bit address space again, but this time assume 16KB pages.

We would thus have an 18-bit VPN plus a 14-bit offset.

Assuming the same size for each PTE (4 bytes), we now have 2^18 entries in our linear page table and thus a total size of 1MB per page table, a factor of four reduction in size of the page table.

The major problem with this approach, is that big pages lead to waste within each page, a problem known as internal fragmentation (as the waste is internal to the unit of allocation).

Applications thus end up allocating pages but only using little bits and pieces of each.

==== MULTIPLE PAGE SIZES

Many architectures (e.g., MIPS, SPARC, x86-64) now support multiple page sizes.

Usually, a small (4KB or 8KB) page size is used.

However, if a “smart” application requests it, a single large page (e.g., of size 4MB) can be used for a specific portion of the address space, enabling such applications to place a frequently-used (and large) data structure in such a space while consuming only a single TLB entry.

This type of large page usage is common in database management systems and other high-end commercial applications.

The main reason for multiple page sizes is not to save page table space, however; it is to reduce pressure on the TLB, enabling a program to access more of its address space without suffering from too many TLB misses.

Using multiple page sizes makes the OS virtual memory manager notably more complex, and thus large pages are sometimes most easily used simply by exporting a new interface to applications to request large pages directly.

=== Hybrid Approach: Paging and Segments

*Hybrid*: Whenever you have two reasonable but different approaches to something in life, you should always examine the combination of the two to see if you can obtain the best of both worlds.

So we can combining paging and segmentation in order to reduce the memory overhead of page tables.

For the example, we use a tiny 16KB address space with 1KB pages.

#image("images/2023-12-15-18-58-05.png", width: 70%)
#image("images/2023-12-15-18-58-14.png", width: 50%)

From the picture, most of the page table is unused, full of invalid entries.

#tip("Tip")[
 Imagine the page table of a 32-bit address space and all the potential wasted space in there!   
] 

==== have one per logical segment

Instead of having a single page table for the entire address space of the process, why not *have one per logical segment*?

In this example, we might thus have *three page tables, one for the code, heap, and stack* parts of the address space.

Remember with segmentation,

- *a base register* that told us where each segment lived in physical memory
- *a bound or limit register* that told us the size of said segment.

In our hybrid, we still have those structures in the MMU

- The base hold *the physical address of the page table* of that segment.
- The bounds register is used to indicate *the end of the page table* (i.e., how many valid pages it has).

Assume a 32-bit virtual address space with 4KB pages, and an address space split into four segments. We’ll only use three segments for this example: one for code, one for heap, and one for stack.

#image("images/2023-12-18-12-33-32.png")

In the hardware, assume that there are thus three base/bounds pairs, one each for code, heap, and stack.

When a process is running, the base register for each of these segments contains the physical address of a linear page table for that segment;

Thus, each process in the system now has three page tables associated with it. On a context switch, these registers must be changed to reflect the location of the page tables of the newly running process.

On a TLB miss, the hardware uses the segment bits (SN) to determine which base and bounds pair to use.

```c
SN = (VirtualAddress & SEG_MASK) >> SN_SHIFT
VPN = (VirtualAddress & VPN_MASK) >> VPN_SHIFT
AddressOfPTE = Base[SN] + (VPN * sizeof(PTE))
```

The critical difference in our hybrid scheme is the presence of a bounds register per segment; each bounds register holds the value of the maximum valid page in the segment.

problems:

- it still requires us to use segmentation(segmentation is not quite as flexible)
  #tip("Tip")[
  if we have a large but sparsely-used heap, we can still end up with a lot of page table waste.
  ]
- this hybrid causes external fragmentation to arise
  #tip("Tip")[
  page tables now can be of arbitrary size (in multiples of PTEs). Thus, finding free space for them in memory is more complicated.
  ]

=== Multi-level Page Tables

How to get rid of all those invalid regions in the page table instead of keeping them all in memory?
*multi-level page table*: it turns the linear page table into something like a tree.

#tip("Tip")[
 many modern systems employ it   
] 

The basic idea behind a multi-level page table is simple.

- First, chop up the page table into page-sized units;
- then, if an entire page of page-table entries (PTEs) is invalid, don’t allocate that page of the page table at all.

To track a page of the page table, use a new structure, called the *page directory*. It either can be used to tell you *where a page of the page table is*, or that the entire page of the page table contains no *valid pages*

- It consists of a number of *page directory entries (PDE)*.
- A PDE (minimally) has a valid bit and *a page frame number (PFN)*, similar to a PTE.
  - If the PDE is valid, it means that at least one of the pages of the page table that the entry points to (via the PFN) is valid

#image("images/2023-12-18-14-46-49.png")

#tip("Tip")[
- PTBR -> page table base register
- PDBR -> page directory base register
]

- On the left is the classic linear page table: even though most of the middle regions of the address space are not valid, we still require page-table space allocated for those regions.
- On the right is a multi-level page table: the page directory marks just two pages of the page table as valid (the first and last), thus, just those two pages of the page table reside in memory.
  #tip("Tip")[
   It just makes parts of the linear page table disappear, and tracks which pages of the page table are allocated with the page directory.   
  ] 

==== Advantages:

- First, the multi-level table only allocates page-table space in proportion to the amount of address space you are using; thus it is generally compact and supports sparse address spaces.
- Second, each portion of the page table fits neatly within a page, making it easier to manage memory; the OS can simply grab the next free page when it needs to allocate or grow a page table.

With a multi-level structure, we add a *level of indirection* through use of the page directory, which points to pieces of the page table; that indirection allows us to place page-table pages wherever we would like in physical memory.

==== Negative:

There is a cost to multi-level tables:

on a TLB miss, two loads from memory will be required to get the right translation information from the page table (one for the page directory, and one for the PTE itself), in contrast to just one load with a linear page table.

Another obvious negative is complexity:

Whether it is the hardware or OS handling the page-table lookup (on a TLB miss), doing so is undoubtedly more involved than a simple linear page-table lookup.

==== BE WARY OF COMPLEXITY

What a good systems builder does is implement the least complex system that achieves the task at hand.

For example,

- if disk space is abundant, you shouldn’t design a file system that works hard to use as few bytes as possible;
- if processors are fast, it is better to write a clean and understandable module within the OS than perhaps the most CPU-optimized, hand-assembled code for the task at hand.

Be wary of needless complexity, in prematurely-optimized code or other forms; such approaches make systems harder to understand, maintain, and debug.

_Perfection is finally attained not when there is no longer anything to add, but when there is no longer anything to take away._

==== A Detailed Multi-Level Example

===== Assumption

Address space of size 16KB, with 64-byte pages, assume each PTE is 4 bytes.
-> a 14-bit virtual address space, with 8 bits for the VPN and 6 bits for the offset,

A linear page table would have 2^8 entries:
#image("images/2023-12-18-14-59-34.png", width: 60%)

#tip("Tip")[
page table is 1KB (256 × 4 bytes) in size   
]

- code: virtual pages 0 and 1
- stack: virtual pages 254 and 255
- heap: virtual pages 4 and 5

To build a two-level page table, we *start with our full linear page table and break it up into page-sized units*.

We have 64-byte pages, the 1KB page table can be divided into 16 64-byte pages; each page can hold 16 PTEs.How to construct the index for each from pieces of the VPN?

#image("images/2023-12-18-15-06-01.png", width: 80%)

Once we extract the *page-directory index (PDIndex for short)* from the VPN, we can use it to find the address of the page-directory entry (PDE)with a simple calculation: `PDEAddr = PageDirBase + (PDIndex * sizeof(PDE))`.

If the page-directory entry is marked invalid, we know that the access is invalid, and thus raise an exception.

If, the PDE is valid, we now have to fetch the page-table entry (PTE) from the page of the page table pointed to by this page directory entry. To find this PTE, we have to index into the portion of the page table using the remaining bits of the VPN:

#image("images/2023-12-18-15-08-22.png", width: 80%)

This *page-table index (PTIndex for short)* can then be used to index into the page table itself, giving us the address of our PTE:
`PTEAddr = (PDE.PFN << SHIFT) + (PTIndex * sizeof(PTE))`

===== Example

We’ll now fill in a multi-level page table with some actual values, and translate a single virtual address.
#image("images/2023-12-18-15-09-39.png", width: 80%)

#tip("Tip")[
instead of allocating the full sixteen pages for a linear page table, we allocate only three: one for the page directory, and two for the chunks of the page table that have valid mappings.   
]

VPNs 254 and 255 (the stack) have valid mappings.

VPN 254: 0x3F80, or 1111 1110 000000 in binary.

- The top 4 bits of the VPN(1111) to index into the page directory, will choose the last entry of the page directory above.(PFN=101)
- The next 4 bits of the VPN (1110) to index into that page of the page table and find the desired PTE.(PFN=55)
- Concatenating PFN=55 (or hex 0x37) with offset=000000, `PhysAddr = (PTE.PFN << SHIFT) + offset = 00 1101 1100 0000 = 0x0DC0`

==== More Than Two Levels

assume a 30-bit virtual address space, and a small (512 byte) page
-> a 21-bit virtual page number component and a 9-bit offset

Our goal in constructing a multi-level page table: to make each piece of the page table fit within a single page.

To *determine how many levels* are needed in a multi-level table to make all pieces of the page table fit within a page, we *start by determining how many page-table entries fit within a page*.

Given our page size of 512 bytes, and assuming a PTE size of 4 bytes, a single page can fit in 128 PTEs.

When we index into a page of the page table, we can thus conclude we’ll need the least significant 7 bits ($log_2{128}$) of the VPN as an index:

#image("images/2023-12-18-15-25-19.png")

If our page directory has 2^14 entries, and thus our goal of making every piece of the multi-level page table fit into a page vanishes.

To remedy this problem, split the page directory itself into multiple pages, and then add another page directory on top of that, to point to the pages of the page directory.

#image("images/2023-12-18-15-26-58.png")

PD Index 0: this index can be used to fetch the page-directory entry from the top-level page directory

If valid, the second level of the page directory is consulted by combining the *PFN from the top-level PDE* and the next part of the VPN (*PD Index 1*).

==== The Translation Process: Remember the TLB

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
  // first, get page directory entry
  PDIndex = (VPN & PD_MASK) >> PD_SHIFT
  PDEAddr = PDBR + (PDIndex * sizeof(PDE))
  PDE = AccessMemory(PDEAddr)
  if (PDE.Valid == False)
    RaiseException(SEGMENTATION_FAULT)
  else
    // PDE is valid: now fetch PTE from page table
    PTIndex = (VPN & PT_MASK) >> PT_SHIFT
    PTEAddr = (PDE.PFN << SHIFT) + (PTIndex * sizeof(PTE))
    PTE = AccessMemory(PTEAddr)
    if (PTE.Valid == False)
      RaiseException(SEGMENTATION_FAULT)
    else if (CanAccess(PTE.ProtectBits) == False)
      RaiseException(PROTECTION_FAULT)
    else
      TLB_Insert(VPN, PTE.PFN, PTE.ProtectBits)
      RetryInstruction()
```

=== Inverted Page Tables

more extreme space savings -> *Inverted Page Tables*

Inverted Page tables keep a single page table that has an entry for each physical page of the system.

The entry tells us which process is using this page, and which virtual page of that process maps to this physical page.

Finding the correct entry is now a matter of searching through this data structure.

A hash table is often built over the base structure to speed up lookups.

=== Swapping the Page Tables to Disk

We have assumed that page tables reside in kernel-owned physical memory. Even with our many tricks to reduce the size of page tables, it is still possible, however, that they may be too big to fit into memory all at once.

Thus, some systems place such page tables in *kernel virtual memory,* thereby allowing the system to *swap* some of these page tables to disk when memory pressure gets a little tight.

=== Summary

The trade-offs such tables present are in time and space.

- In a memory-constrained system(like many older systems), small structures make sense.
- In a system with a reasonable amount of memory and with workloads that actively use a large number of pages, a bigger table that speeds up TLB misses might be the right choice.

_Think of these questions as you fall asleep, and dream the big dreams that only operating-system developers can dream._
