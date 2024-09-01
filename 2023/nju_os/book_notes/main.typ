#import "template.typ": *

#show: template.with(
  title: [OSTEP],
  short_title: "operating system - three easy pieces",
  description: [
    OSTEP笔记。
  ],
  date: datetime(year: 2023, month: 10, day: 30),
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

  // bibliography_file: "refs.bib",
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

#include "content/01_intro.typ"
#include "content/02_virtualization_01_CPU_00_basic.typ"
#include "content/02_virtualization_01_CPU_01_sheduling.typ"
#include "content/02_virtualization_02_memory_00_basic.typ"
#include "content/02_virtualization_02_memory_01_segement.typ"
#include "content/02_virtualization_02_memory_02_paging.typ"
#include "content/02_virtualization_02_memory_03_swapping.typ"
#include "content/02_virtualization_02_memory_04_VM.typ"
#include "content/03_concurrency.typ"
#include "content/04_persistence_01_hardware&&raid.typ"
#include "content/04_persistence_02_filesystem.typ"
