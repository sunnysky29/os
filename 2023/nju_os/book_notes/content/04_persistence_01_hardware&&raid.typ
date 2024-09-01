#import "../template.typ": *
#pagebreak()
= hardware&&raid

== Hard Disk Drives

=== The Interface

The drive consists of a large number of sectors (*512-byte blocks*), each of which can be read or written. The sectors are numbered from 0 to n − 1 (address space)on a disk with n sectors.

Multi-sector operations are possible; indeed, many file systems will read or write 4KB at a time (or more).

However, when updating the disk, the only guarantee drive manufacturers make is that a single 512-byte write is *atomic*.

#tip("Tip")[
*a torn write*: if an untimely power loss occurs, only a portion of a larger write may complete
]

==== Assumptions

1. Accessing two blocks near one-another within the drive’s address space will be faster than accessing two blocks that are far apart.
2. Accessing blocks in a contiguous chunk (i.e., a sequential read or write) is the fastest access mode, and usually much faster than any more random access pattern.

=== Basic Geometry

#image("images/2024-02-29-20-24-44.png", width: 50%)

A disk may have one or more *platters*; each platter has 2 sides, each of which is called a *surface*.

Data is encoded on each surface in concentric circles of sectors; we call one such concentric circle *a track*.

The process of reading and writing is accomplished by the *disk head*.

The disk head is attached to a single *disk arm*, which moves across the surface to position the head over the desired track.

These platters are usually made of some hard material (such as aluminum), and then coated with *a thin magnetic layer* that enables the drive to persistently store bits.

The rate of rotation is often measured in *rotations per minute (RPM)*

=== A Simple Disk Drive

Assume we have a simple disk with a single track:
#image("images/2024-02-29-20-30-28.png", width: 50%)

#tip("Tip")[
This track has just 12 sectors, each of which is 512 bytes in size,and the surface is rotating counter-clockwise.
]

==== Single-track Latency: The Rotational Delay

Imagine we now receive a request to read block 0:

Just wait for the desired sector to rotate under the disk head. (*rotational delay*)

In the example, if the full rotational delay is R, the disk has to incur a rotational delay of about R/2 to wait for 0 to come under the read/write head.

==== Multiple Tracks: Seek Time

#image("images/2024-02-29-20-33-54.png", width: 80%)

A read to sector 11:
first move the disk arm to the correct track (in this case, the outermost one), in a process known as a *seek*.

#tip("Tip")[
Seeks + rotations, are one of the most costly disk operations.
]

The seek:

- an *acceleration* phase as the disk arm gets moving;
- *coasting* as the arm is moving at full speed
- *deceleration* as the arm slows down
- *settling* as the head is carefully positioned over the correct track
  #tip("Tip")[
    The *settling time* is often quite significant, e.g., 0.5 to 2 ms
  ]

When sector 11 passes under the disk head, the final phase of I/O will take place, known as the *transfer*, where data is either read from or written to the surface.

And thus, we have a complete picture of I/O time: *seek -> rotation -> transfer*

==== Some Other Details

===== track skew

Many drives employ some kind of *track skew* to make sure that sequential reads can be properly serviced even when crossing track boundaries.
#image("images/2024-02-29-20-39-22.png", width: 50%)

#tip("Tip")[
Sectors are often skewed like this because when switching from one track to another
]

===== multi-zoned

Outer tracks tend to have more sectors than inner tracks.

These tracks are often referred to as *multi-zoned* disk drives, where the disk is organized into multiple zones, and where a zone is consecutive set of tracks on a surface.

Each zone has the same number of sectors per track, and outer zones have more sectors than inner zones.

===== track buffer

An important part of any modern disk drive is its cache, for historical reasons sometimes called a track buffer.(usually around 8 or 16 MB)

For example, when reading a sector from the disk, the drive might decide to read in all of the sectors on that track and cache them in its memory.

On writes, the drive has a choice: should it acknowledge the write has completed when it has put the data in its memory, or after the write has actually been written to disk?

The former is called write back(fast but dangerous) caching, and the latter write through.

=== I/O Time: Doing The Math

$T_(I/O) = T_("seek") + T_("rotation") + T_("transfer")$
$R_(I/O) = ("Size"_("Transfer"))/(T_(I/O))$

#three-line-table[
|\              | Cheetah 15K.5 | Barracuda |
| ------------ | ------------- | --------- |
| Capacity     | 300 GB        | 1 TB      |
| RPM          | 15,000        | 7,200     |
| Average Seek | 4 ms          | 9 ms      |
| Max Transfer | 125 MB/s      | 105 MB/s  |
| Platters     | 4             | 4         |
| Cache        | 16 MB         | 16/32 MB  |
| Connects via | SCSI          | SATA      |
]

==== random workload

Assuming each 4 KB read occurs at a random location on disk

$T_("seek") = 4 "ms", T_"rotation" = 2 "ms", T_"transfer" = 30 "microsecs"$

The average seek time (4milliseconds) is just taken as the average time reported by the manufacturer; note that a full seek (from one end of the surface to the other) would likely take two or three times longer.

The average rotational delay is calculated from the RPM directly. 15000 RPM is equal to 250 RPS (rotations per second); thus, each rotation takes 4 ms. On average, the disk will encounter a half rotation and thus 2 ms is the average time.

Finally, the transfer time is just the size of the transfer over the peak transfer rate.

==== sequential workload

assume the size of the transfer is 100 MB.

Thus, $T_(I/O)$ for the Cheetah and Barracuda is about 800 ms and 950 ms, respectively.

The rates of I/O are thus very nearly the peak transfer rates of 125 MB/s and 105 MB/s, respectively.

#three-line-table[
|\                 | Cheetah   | Barracuda |
| --------------- | --------- | --------- |
| RI/O Random     | 0.66 MB/s | 0.31 MB/s |
| RI/O Sequential | 125 MB/s  | 105 MB/s  |
]

Figure 37.6 summarizes these numbers.

#tip("Tip")[
When at all possible, transfer data to and from disks in a sequential manner.
]

In many books and papers, you will see average disk-seek time cited as being roughly one-third of the full seek time. Where does this come from?

=== Disk Scheduling

Given a set of I/O requests, the *disk scheduler* examines the requests and decides which one to schedule next.

The disk scheduler will try to follow *the principle of SJF (shortest job first)* in its operation.

==== SSTF: Shortest Seek Time First

STF orders the queue of I/O requests by track, *picking requests on the nearest track* to complete first.

SSTF is not a panacea, for the following reasons.

First, the drive geometry is not available to the host OS; rather, it sees an array of blocks (easily fixed nearest-block-first (NBF))

The second problem is more fundamental: *starvation*.

==== Elevator (a.k.a. SCAN or C-SCAN)

To avoid starvation.

The algorithm, originally called *SCAN*, simply moves back and forth across the disk servicing requests in order across the tracks.

Let’s call a single pass across the disk (from outer to inner tracks, or inner to outer) a *sweep*.

If a request comes for a block on a track that has already been serviced on this sweep of the disk, it is not handled immediately, but rather queued until the next sweep (in the other direction).

===== F-SCAN

Freezing the queue to be serviced when it is doing a sweep

This action places requests that come in during the sweep into a queue to be serviced later.

===== C-SCAN

short for Circular SCAN

The algorithm only sweeps from outer-to-inner, and then resets at the outer track to begin again.

#tip("Tip")[
Doing so is a bit more fair to inner and outer tracks, as pure back-and-forth SCAN favors the middle tracks,
]

For reasons that should now be clear, the SCAN algorithm is sometimes referred to as the *elevator* algorithm.

Because it behaves like an elevator which is either going up or down and not just servicing requests to floors based on which floor is closer.

In particular, SCAN(or SSTF even) do not actually adhere as closely to the principle of SJF as they could.

==== SPTF: Shortest Positioning Time First

#image("images/2024-02-29-21-05-46.png", width: 50%)

In the example, the head is currently positioned over sector 30 on the inner track.

The scheduler thus has to decide: should it schedule sector 16 (on the middle track) or sector 8 (on the outer track) for its next request. So which should it service next?

The answer, of course, is “it depends”.

#tip("Tip")[
In engineering, it turns out “it depends” is almost always the answer, reflecting that trade-offs are part of the life of the engineer.
]

On modern drives, as we saw above, both seek and rotation are roughly equivalent (depending, of course, on the exact requests), and thus SPTF is useful and improves performance.

==== Other Scheduling Issues

===== Where is disk scheduling performed on modern systems?

The OS scheduler usually picks what it thinks the best few requests are (say 16) and issues them all to disk; the disk then uses its internal knowledge of head position and detailed track layout information to service said requests in the best possible (SPTF) order.

===== I/O merging

For example, imagine a series of requests to read blocks 33, then 8, then 34.

The scheduler should *merge* the requests for blocks 33 and 34 into a single two-block request.

===== how long should the system wait before issuing an I/O to disk?

- work-conserving: once it has even a single I/O, should immediately issue the request to the drive
- non-work-conserving:By waiting, a new and “better” request may arrive at the disk, and thus overall efficiency is increased.
  #tip("Tip")[
  when to wait, and for how long, can be tricky
  ]

== Redundant Arrays of Inexpensive Disks (RAIDs)

I/O operations can be the bottleneck for the entire system.

Redundant Array of Inexpensive Disks better known as RAID, a technique to use multiple disks in concert to build a faster, bigger, and more reliable disk system.

Externally, a RAID looks like a disk: a group of blocks one can read or write.

Internally, the RAID is a complex beast, consisting of multiple disks, memory (both volatile and non-), and one or more processors to manage the system.

RAIDs offer a number of advantages: performance, capacity, reliability

#tip("Tip")[
With some form of redundancy, RAIDs can tolerate the loss of a disk and keep operating as if nothing were wrong.
]

When considering how to add new functionality to a system, one should always consider whether such functionality can be added transparently, in a way that demands no changes to the rest of the system.

RAID is a perfect example. Transparency greatly improves the *deployability* of RAID. Amazingly, RAIDs provide these advantages transparently to systems that use them, i.e., a RAID just looks like a big disk to the host system.

=== Interface And RAID Internals

When a file system issues a logical I/O request to the RAID, and then issue one or more physical I/Os to do so.

Consider a RAID that keeps two copies of each block (each one on a separate disk); when writing to such a mirrored RAID system, the RAID will have to perform two physical I/Os for every one logical I/O it is issued.

A RAID system is often built as a separate hardware box, with a standard connection (e.g., SCSI, or SATA) to a host.

At a high level, a RAID is very much a specialized computer system: it has a processor, memory, and disks; however, instead of running applications, it runs specialized software designed to operate the RAID.

=== Fault Model

==== fail-stop fault model

In this model, a disk can be in exactly one of two states: working or failed.

With a working disk, all blocks can be read or written.

In contrast, when a disk has failed, we assume it is permanently lost.

One critical aspect of the fail-stop model is what it assumes about fault detection. Specifically, when a disk has failed, we assume that this is easily detected.

For now, we do not have to worry about more complex “silent” failures such as disk corruption.

We also do not have to worry about a single block becoming inaccessible upon an otherwise working disk (sometimes called a latent sector error).

=== How To Evaluate A RAID

The first axis is capacity; given a set of N disks each with B blocks, how much useful capacity is available to clients of the RAID?

The second axis of evaluation is reliability. How many disk faults can the given design tolerate?

The third axis is performance.

=== RAID Level 0: Striping

The first RAID level is actually not a RAID level at all, in that there is no redundancy.

RAID level 0, or striping as it is better known, serves as an excellent upper-bound on performance and capacity and thus is worth understanding.

Stripe blocks across the disks of the system as follows (assume here a 4-disk array):

#three-line-table[
| Disk 0 | Disk 1 | Disk 2 | Disk 3 |
| ------ | ------ | ------ | ------ |
| 0      | 1      | 2      | 3      |
| 4      | 5      | 6      | 7      |
| 8      | 9      | 10     | 11     |
| 12     | 13     | 14     | 15     |
]

#tip("Tip")[
We call the blocks in the same row a *stripe*
]

This approach is designed to extract the most parallelism from the array when requests are made for contiguous chunks of the array.

#three-line-table[
| Disk 0 | Disk 1 | Disk 2 | Disk 3 |
| ------ | ------ | ------ | ------ |
| 0      | 2      | 4      | 6      |
| 1      | 3      | 5      | 7      |
| 8      | 10     | 12     | 14     |
| 9      | 11     | 13     | 15     |
]

#tip("Tip")[
chunk size:2 blocks
]

We place two 4KB blocks on each disk before moving on to the next disk. Thus, the chunk size of this RAID array is 8KB, and a stripe thus consists of 4 chunks or 32KB of data.

==== THE RAID MAPPING PROBLEM

Take the first striping example above (chunk size = 1 block = 4KB).

Disk = A % number_of_disks
Offset = A / number_of_disks

How these equations would be modified to support different chunk sizes.

==== Chunk Sizes

a small chunk size implies that many files will get striped across many disks

- increasing the parallelism of reads and writes to a single file;
- the positioning time to access blocks across multiple disks increases
  - because the positioning time for the entire request is determined by the maximum of the positioning times of the requests across all drives.

A big chunk size,

- reduces such intra-file parallelism, and thus relies on multiple concurrent requests to achieve high throughput.
- reduce positioning time; if, for example, a single file fits within a chunk and thus is placed on a single disk, the positioning time incurred while accessing it will just be the positioning time of a single disk.

For the rest of this discussion, we will assume that the array uses a chunk size of a single block (4KB).

==== Back To RAID-0 Analysis

- capacity: given N disks each of size B blocks, striping deliversN·B blocks of useful capacity
- reliability: any disk failure will lead to data loss.
- performance: all disks are utilized, often in parallel, to service user I/O requests.

==== Evaluating RAID Performance

- The first is *single-request latency*
- The second is *steady-state throughput*

Two types of workloads: sequential and random. We will assume that a disk can transfer data at S MB/s under a sequential workload, and R MB/s when under a random workload. In general, S is much greater than R (i.e., S ≫ R)

Assume a sequential transfer of size 10MB on average, and a random transfer of 10 KB on average. Also, assume the following disk characteristics:

- Average seek time 7 ms
- Average rotational delay 3 ms
- Transfer rate of disk 50 MB/s

- S = Amount of Data / Time to access = 10 MB/210 ms = 47.62 MB/s
- R = Amount of Data / Time to access = 10 KB/10.195 ms = 0.981 MB/s

==== Back To RAID-0 Analysis, Again

From a latency perspective, the latency of a single-block request should be just about identical to that of a single disk;

From the perspective of steady-state throughput, throughput equals N (the number of disks) multiplied by S (the sequential bandwidth of a single disk). For a large number of random I/Os, we can again use all of the disks, and thus obtain N · R MB/s.

=== RAID Level 1: Mirroring

With a mirrored system, we simply make more than one copy of each block in the system; each copy should be placed on a separate disk.

#three-line-table[
| Disk 0 | Disk 1 | Disk 2 | Disk 3 |
| ------ | ------ | ------ | ------ |
| 0      | 0      | 1      | 1      |
| 2      | 2      | 3      | 3      |
| 4      | 4      | 5      | 5      |
| 6      | 6      | 7      | 7      |
]

The arrangement above is a common one and is sometimes called *RAID-10* or (RAID 1+0) because it uses mirrored pairs (RAID-1) and then stripes (RAID-0) on top of them; another common arrangement is *RAID-01* (or RAID 0+1), which contains two large striping (RAID-0) arrays, and then mirrors (RAID-1) on top of them.

When reading a block from a mirrored array, the RAID has a choice: it can read either copy.

When writing a block, though, no such choice exists: the RAID must update both copies of the data, in order to preserve reliability.

#tip("Tip")[
Do note, though, that these writes can take place in parallel; for example, a write to logical block 5 could proceed to disks 2 and 3 at the same time.
]

==== RAID-1 Analysis

== File System
