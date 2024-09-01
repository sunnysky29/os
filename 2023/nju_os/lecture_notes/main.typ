#import "template.typ": *

#show: template.with(
  title: [OS - JYY Lecture Notes],
  short_title: "Lecture Notes",
  description: [
    JYY OS-2024 课程笔记
  ],
  date: datetime(year: 2023, month: 09, day: 22),
  authors: (
    (
      name: "0x1B05",
      github: "https://github.com/0x1B05",
      homepage: "https://github.com/0x1B05", // 个人主页
      affiliations: "1",
    ),
  ),
  affiliations: (
    (id: "1", name: "NUFE"),
  ),

  paper_size: "a4",
  text_font: "Linux Libertine",
  sc_font: "Noto Sans CJK SC",
  code_font: "DejaVu Sans Mono",
  
  // 主题色
  accent: orange,
  // 封面背景图片
  cover_image: "./figures/Pine_Tree.jpg", // 图片路径或 none
  // 正文背景颜色
  // background_color: "#FAF9DE" // HEX 颜色或 none
)

#include "content/01_操作系统概述.typ"
#include "content/02_应用视角的操作系统.typ"
#include "content/03_硬件视角的操作系统.typ"
#include "content/04_Python建模操作系统.typ"
#include "content/05_多处理器编程：从入门到放弃.typ"
#include "content/06_并发控制基础.typ"
#include "content/07_并发控制-互斥.typ"
#include "content/09_并发控制-同步1.typ"
#include "content/10_并发控制-同步2.typ"
#include "content/11_真实世界的并发编程.typ"
#include "content/12_真实世界的并发Bug.typ"
#include "content/13_并发Bug的应对.typ"
#include "content/14_多处理器系统与中断机制.typ"
#include "content/15_操作系统上的进程.typ"
#include "content/16_Linux操作系统.typ"
#include "content/17_Linux进程的地址空间.typ"
#include "content/18_操作系统实验生存指南.typ"
#include "content/19_系统调用和UNIX-Shell.typ"
#include "content/21_可执行文件和加载.typ"
#include "content/27_设备驱动程序与文件系统.typ"
#include "content/28_FAT和UNIX文件系统.typ"
#include "content/29_持久数据的可靠性.typ"
