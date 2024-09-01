#import "../template.typ": *
#pagebreak()
= 持久数据的可靠性

== 持久数据的可靠性

=== 持久存储：性能

存储：只要 CPU (DMA) 能处理得过来，我就能提供足够的带宽！

- Computer System 的 “industry” 传统——做真实有用的系统

=== 持久存储：可靠性

任何物理存储介质都有失效的可能

- 临时失效：Kernel panic；断电
- 永久失效
  - 极小概率事件：战争爆发/三体人进攻地球/世界毁灭 😂
  - 小概率事件：硬盘损坏 (大量重复 = 必然发生)

=== Failure Model (1): Fail-stop

磁盘可能在某个时刻忽然彻底无法访问

- 机械故障、芯片故障……
  - 磁盘好像就 “忽然消失” 了 (数据完全丢失)
  - 假设磁盘能报告这个问题 (如何报告？)

你的磁盘发生 fail-stop 会对你带来什么影响？

=== Failure Model (2): System Crash

真实的磁盘

- `bwrite` 会被磁盘缓存，并且以不可控的顺序被 persist
  - 在任何时候，系统都可能 crash
- `bsync` 会等待所有 `bwrite` 落盘

#image("images/2024-02-27-12-10-06.png")

System crash 会对你带来什么影响？ 真的没有影响？(Model checker 告诉你影响)

=== 更多的 Failure Mode

Data corruption

- 磁盘看起来正常，但一部分数据坏了
- [ An analysis of data corruption in the storage stack
  ](https://www.usenix.org/conference/fast-08/analysis-data-corruption-storage-stack)
  (FAST'08)

Fail-slow

- Firmware bug; device error; wear-out; configuration; environment; ...
- [ Fail-slow at scale: Evidence of hardware performance faults in large
  production systems
  ](https://www.usenix.org/system/files/login/articles/login_summer18_06_gunawi.pdf)
  (FAST'18)

#image("images/2024-02-27-12-11-20.png")

== Redundant Array of Inexpensive Disks (RAID)

=== RAID: 存储设备的虚拟化

性能和可靠性，我们能不能全都要呢？

- Redundant Array of Inexpensive (Independent) Disks (RAID)
- 把多个 (不可靠的) 磁盘虚拟成一块非常可靠且性能极高的虚拟磁盘
  - [ A case for redundant arrays of inexpensive disks
    ](https://dl.acm.org/doi/10.1145/971701.50214) (RAID) (SIGMOD'88)
  - 一个 “反向” 的虚拟化
    - 类比：进程/虚存/文件把 “一个设备” 虚拟成多份

遍地是黄金的年代：凑几块盘，掀翻整个产业链！

- “Single Large Expensive Disks” (IBM 3380), v.s.
- “Redundant Array of Inexpensive Disks”

=== RAID: Design Space

RAID (虚拟化) = 虚拟磁盘块到物理磁盘块的 “映射”。

- 虚拟磁盘块可以存储在任何虚拟磁盘上

  - 虚拟磁盘可以并行
  - 存储 >1 份即可实现容错

- RAID-0：更大的容量、更快的速度
  - 读速度 x 2；写速度 x 2
- RAID-1：镜像 (容错)
  - 保持两块盘完全一样
  - 读速度 x 2；写速度保持一致
  - 容错的代价

=== 容错的代价

浪费了一块盘的容量……

- 如果我们有 100 块盘
- 但假设不会有两块盘同时 fail-stop？

能不能只用 1-bit 的冗余，恢复出一个丢失的 bit？

- x = a ⊕ b ⊕ c ⊕ d

  - a = x ⊕ b ⊕ c ⊕ d
  - b = a ⊕ x ⊕ c ⊕ d
  - c = a ⊕ b ⊕ x ⊕ d
  - d = a ⊕ b ⊕ c ⊕ x

- 100 块盘里，99 块盘都是数据！
  - Caveat: random write 性能

=== RAID-5: Rotating Parity

“交错排列” parity block!
#image("images/2024-02-27-12-14-37.png")

=== RAID: 讨论

更快、更可靠、近乎免费的大容量磁盘

- 革了 “高可靠性磁盘” 的命
  - 成为今天服务器的标准配置
- 类似的里程碑
  - #link("https://dl.acm.org/doi/10.1145/1165389.945450")[ The Google file system ]
    (SOSP'03) 和 [ MapReduce: Simplified data processing on large clusters
    ](https://dl.acm.org/doi/10.5555/1251254.1251264) (OSDI'04) 开启 “大数据” 时代

RAID 的可靠性

- RAID 系统发生断电？
  - 例子：RAID-1 镜像盘出现不一致的数据
- 检测到磁盘坏？
  - 自动重组

== 崩溃一致性与崩溃恢复

=== 崩溃一致性 (Crash Consistency)

> Crash Consistency: Move the file system from one consistent state (e.g.,
before the file got appended to) to another atomically (e.g., after the inode,
bitmap, and new data block have been written to disk). >
(你们平时编程时假设不会发生的事，操作系统都要给你兜底)

磁盘不提供多块读写 “all or nothing” 的支持

- 甚至为了性能，没有顺序保证
  - `bwrite` 可能被乱序
  - 所以磁盘还提供了 `bflush` 等待已写入的数据落盘

=== File System Checking (FSCK)

根据磁盘上已有的信息，恢复出 “最可能” 的数据结构

#image("images/2024-02-27-12-16-11.png")

- [ SQCK: A declarative file system checker
  ](https://dl.acm.org/doi/10.5555/1855741.1855751) (OSDI'08)
- #link("https://dl.acm.org/doi/10.1145/3281031")[ Towards robust file system checkers ]
  (FAST'18)
  - “widely used file systems (EXT4, XFS, BtrFS, and F2FS) may leave the file system
    in an uncorrectable state if the repair procedure is interrupted unexpectedly”
    😂

=== 重新思考数据结构的存储

两个 “视角”

- 存储实际数据结构
  - 文件系统的 “直观” 表示
  - crash unsafe
- Append-only 记录所有历史操作
  - “重做” 所有操作得到数据结构的当前状态
  - 容易实现崩溃一致性

二者的融合

- 数据结构操作发生时，用 (2) append-only 记录日志
- 日志落盘后，用 (1) 更新数据结构
- 崩溃后，重放日志并清除 (称为 redo log；相应也可以 undo log)

=== 实现 Atomic Append

用 `bread`, `bwrite` 和 `bflush` 实现 `append()`

#image("images/2024-02-27-12-17-42.png")

1. 定位到 journal 的末尾 (bread)
2. bwrite TXBegin 和所有数据结构操作
3. bflush 等待数据落盘
4. bwrite TXEnd
5. bflush 等待数据落盘
6. 将数据结构操作写入实际数据结构区域
7. 等待数据落盘后，删除 (标记) 日志

=== Journaling: 优化

现在磁盘需要写入双份的数据

- 批处理 (xv6; jbd)
  - 多次系统调用的 Tx 合并成一个，减少 log 的大小
  - jbd: 定期 write back
- Checksum (ext4)
  - 不再标记 TxBegin/TxEnd
  - 直接标记 Tx 的长度和 checksum
- Metadata journaling (ext4 default)
  - 数据占磁盘写入的绝大部分
    - 只对 inode 和 bitmap 做 journaling 可以提高性能
  - 保证文件系统的目录结构是一致的；但数据可能丢失

=== Metadata Journaling

从应用视角来看，文件系统的行为可能很怪异

- 各类系统软件 (git, sqlite, gdbm, ...) 不幸中招
  - [ All file systems are not created equal: On the complexity of crafting
    crash-consistent applications
    ](https://cn.bing.com/search?q=All+file+systems+are+not+created+equal%3A+On+the+complexity+of+crafting+crash-consistent+applications&form=APMCS1&PC=APMC)
    (OSDI'14)
  - (os-workbench 里的小秘密)
- 更多的应用程序可能发生 data loss
  - 我们的工作: GNU coreutils, gmake, gzip, ... 也有问题
  - [ Crash consistency validation made easy
    ](https://dl.acm.org/doi/10.1145/2950290.2950327) (FSE'16)

更为一劳永逸的方案：TxOS

- xbegin/xend/xabort 系统调用实现跨 syscall 的 “all-or-nothing”
  - 应用场景：数据更新、软件更新、check-use……
  - [ Operating systems transactions
    ](https://dl.acm.org/doi/10.1145/1629575.1629591) (SOSP'09)
