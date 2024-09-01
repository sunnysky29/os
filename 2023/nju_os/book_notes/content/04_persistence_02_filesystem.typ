#import "../template.typ": *
#pagebreak()
= File System

== Files and Directory

== File System Implementation

This chapter is an introduction to *vsfs*(the *Very Simple File System*).

#tip("Tip")[
The file system is pure software.
]

=== The Way To Think

- *data structure*
- *access methods*
  - how does it map the syscalls(like `open`, `read`..) onto its stuctures

#tip("Tip")[
Mental models are what you are really trying to develop when learning about systems.

- For file systems, your mental model should eventually include answers to questions like: 
  - what on-disk structures store the file system’s data and metadata? 
  - What happens when a process opens a file? 
  - Which on-disk structures are accessed during a read or write?
]

=== Overall Organization

- First *divide the disk into blocks*(a commonly-used size of 4KB)

What we need to store in these blocks to build a file system?
- *user data* stored in *data region*
- fs has to track info about each file => *metadata* stored in *inode table*
- fs has to track whether inodes or data blocks are free or allocated => *allocation structure*(here are *data bitmap* and *inode bitmap*)
- *superblock*(contains info about the fs, like a magic number, the number of data blocks and inods, where the inode table begins, and so forth)

#example("Example")[
#image("./images/vsfs-example.png")
- Assume a really small disk with just 64 blocks
- 56 blocks for the *data region*
- 5 blocks for the *inode table*
  - 256 bytes per inode => a block can hold 16 inodes(our file system contains 80 total indoes, which represents the max num of files we can have in the fs)
- 1 block for *data bitmap* and 1 block for *inode bitmap*
  #tip("Tip")[
  A little bit overkilled, but just for simplicity.
  ]
- 1 block for *superblock*
]

=== Inode(Index Node)

Each *inode* is implicitly referred to by *a number* (called the i-number). Given an i-number, you should *directly be able to calculate where on the disk* the corresponding inode is located.

#image("./images/vsfs-inode-table.png")

*The sector address sector of the inode block* can be calculated as follows:
```
blk = (inumber * sizeof(inode_t)) / blockSize;
sector = ((blk * blockSize) + inodeStartAddr) / sectorSize;
```

#example("Example")[
Read inode number 32:
```
blockSize = 256 Byte
sectorSize = 512 Byte
inodeStartAddr = 12KB

blk = 32*sizeof(inode)/blockSize = 32*256/4*1024 = 2
sector = ((blk * blockSize) + inodeStartAddr) / sectorSize = ((2*4*1024)+12*1024)/512 = 40
```
]

Inside each inode is virtually all of the info you need about a file(referred to as *metadata*): 
- its type (e.g., regular file, directory, etc.)
- its size
- the number of blocks allocated to it
- protection information
- some time info
- ...

#image("./images/Simplified-Ext2-Inode.png")

- How inode refers to where data blocks are?
  - One simple approach would be to have one or more *direct pointers* (disk addresses) inside the inode; each pointer refers to one disk block that belongs to the file.

==== The Multi-Level Index

To support bigger files, file system designers have had to introduce different structures within inodes. One common idea is to have a special pointer known as an *indirect pointer*.

#definition("Definition")[
*indirect pointer* points to _a block that contains more pointers_, each of which point to user data
]

#example("Example")[
An inode may have *some fixed number of direct pointers* (e.g., 12), and *a single indirect pointer*.

Assuming 4-KB blocks and 4-byte disk addresses, that adds another 1024 pointers; the file can grow to be (12 + 1024) \* 4K or 4144KB.

- *double indirect pointer*
  - A double indirect block thus adds the possibility to grow files with an additional 1024 · 1024 or 1-million 4KB blocks, in other words supporting files that are over 4GB in size.((12 + 1024 + 1024^2 ) × 4 KB)
- *triple indirect pointer*
  ...
]


- Why use an imbalanced tree like this? Why not a different approach?
  - Many researchers have studied file systems and how they are used, and virtually every time they find certain “truths” that hold across the decades.
  #three-line-table[
    | truth | explanation |
    |   -   |     -       |
    | Most files are small| ˜2K is the most common size|
    |Average file size is growing| Almost 200K is the average|
    |Most bytes are stored in large files|A few big files use most of space|
    |File systems contains lots of files|Almost 100K on average|
    |File systems are roughly half full|Even as disks grow, file systems remain ˜50% full|
    |Directories are typically small|Many have few entries; most have 20 or fewer|
  ]

#tip("Tip")[
A different approach is to use *extents* instead of pointers. 
#definition("Definition")[
*An extent* is simply a disk pointer plus a length (in blocks); all one needs is *a pointer and a length* to specify the on-disk location of a file.
] 

Just *a single extent is limiting*, as one may *have trouble finding a contiguous chunk of on-disk free space when allocating a file*. 

Thus, extent-based file systems often allow for more than one extent, thus giving more freedom to the file system during file allocation.

- *Pointer-based approaches* are the most *flexible* but use a large amount of metadata per file
- Extent-based approaches are less flexible but more *compact*
]

=== Directory

A directory basically just contains *a list of (entry name, inode num- ber) pairs*.

#example("Example")[
Assume a directory dir (inode number 5) has three files in it (`foo`, `bar`, and `foobar_is_a_pretty_longname`).

  #tablem[
    |inum | reclen | strlen | name|
    | -| - | - | - |
    |5| 12| 2| .|
    |2  |12| 3 |..|
    |12 |12| 4 |foo|
    |13 |12| 4 |bar|
    |24 |36| 28| foobar_is_a_pretty_longname|
  ]

each entry has 
- an inode number
- record length (the total bytes for the name plus any left over space)
- string length (the actual length of the name)
- the name of the entry.
]
