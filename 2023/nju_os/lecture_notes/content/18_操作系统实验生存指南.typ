#import "../template.typ": *
#pagebreak()
= 操作系统实验生存指南

== 回归初心

=== Computer Science 的主线

看看 #link("https://csrankings.org/")[ csrankings ] 上的大类 (排名仅供娱乐)

- Theory
  - 什么是 “计算”
- Systems
  - 什么是 “计算机”
- AI
  - 如何用 “计算”、“计算机” (和数据) 实现智能
- Interdisciplinary

我们是如何 “approach” 计算机科学的？

- By talking to computers (via programming languages)

=== 学编程语言时的痛苦与迷茫

虽然被教育 “机器永远是对的”，但它怎么就不对呢？

- 因为程序是状态机 (严格的数学对象)
  - 编程语言是你第一次遇上 “无情执行指令的机器”
- 过去的数学从未如此严格
  - 哪怕是阅卷的数学老师，都有可能被你骗过
  - (考试通过结果 “校验” 你的过程，老师并不喜欢证明题)
    - 有点像 zero-knowledge proof

人类有趣的本能

- NOI2023 江苏省代表队选拔赛选手：坚持认为 Segmentation Fault 是因为机器出问题了

=== 为什么？该怎么办？

写 “好” 的程序

- (我反对编程自学，当然前提是你的老师会 “编程”)
  - 不言自明
  - 不言自证
  - 据调试理论，还有 “能帮助理解状态机执行”

一个有趣的例子：dsu.c

- 如何对应到上面几点？

=== 精益求精

代码里的细节

- Guidelines
  - #link("https://google.github.io/styleguide/cppguide.html")[ Google ], [ GNU
    ](https://www.gnu.org/prep/standards/html_node/Writing-C.html), [ CERT-C
    ](https://www.gnu.org/prep/standards/html_node/Writing-C.html)
- 变量起哪些名字？
  - 编程学习的革命：AskGPT: Is it a good idea to use variable name "rc" for a
    variable holding a 0/-1 return value of an API/system call in C?
    - 服气：我十多年 RTFSC 积累的经验，在 AI 面前一文不值
- 软件工程早有这种研究
  - 可惜走上了刷 accuracy 的不归路
- 还有哪些可能的写法？
  - memcpy 还是结构体赋值？

=== 另一个例子

mosaic.py

Following #link("https://pep8.org/")[ PEP-8 ] 每行 80 个字符不会出现 “过度复杂的行”

=== On the Naturalness of Programs

程序是人类世界需求向数字世界的投影

- 状态机、计算过程和自然语言
- AI 编程的兴起

Programming for fun

- #link("https://www.ioccc.org/")[ The International Obfuscated C Code Contest ]
  - 写出绝对不可读，但又绝对可用的代码
  - #link("https://jyywiki.cn/pages/OS/img/ioccc-spoiler.html")[ 一个程序的诞生 ]

=== Timothy Roscoe's Keynote on OSDI/ATC'21

我们置身变化的世界中 (常看常新)
#image("images/2023-11-28-15-04-53.png")

== 用好工具

=== 计算机系统公理

1. 机器永远是对的
  - (ICS PA/OS Labs: 怕是不用多说了)
2. 未测代码永远是错的
  - (ICS PA/OS Labs: 怕是不用多说了)
3. 让你感到不适的 tedious 工作，一定有办法提高效率
  - 推论：我们应该分辨出什么工作是 tedious 的

“三省吾身：滚去编程了吗？写测试用例了吗？回看自己的工作流程了吗？”

- AI 构建学习阶梯
- 在方方面面强迫我们三省吾身
- 人类文明进入新纪元

=== 更进一步：连接两个世界

程序 = 计算机系统 = 状态机

- 调试器的本质是 “检查状态”
- 我们能不能用自己想要的方式去检查状态？
  - 例如，像 model checker 那样把一个链表绘制出来？
- AskGPT: How to use Python to parse and check/visualize C/C++ program state in
  GDB?
  - GPT-4 甚至给出了正确的[ 文档 URL
    ](https://sourceware.org/gdb/onlinedocs/gdb/Python-API.html)

然后我们就可以做任何事了

- [ TUI Window API
  ](https://sourceware.org/gdb/onlinedocs/gdb/TUI-Windows-In-Python.html#TUI-Windows-In-Python)
- 甚至，我们可以做另一个 debugging front-end
  - [ gdbgui
    ](https://sourceware.org/gdb/onlinedocs/gdb/TUI-Windows-In-Python.html#TUI-Windows-In-Python)

=== 调试困难的根本原因

我们只能检查一个瞬间的状态

- Reverse debugging 的成本还是太高了
- 而且 time-travel 也很难操作
- 如果我们能精简状态就好了！
- 精简状态不就行了吗……

自己动手做工具

- 调试 thread-os

=== 我们需要的：想象力

The UNIX Philosophy

- Keep it simple, stupid
- 把 gdb 状态导出 serialize 到文件/管道中
- 由另一个程序负责处理
- 就像我们的 interactive state space explorer

assertions 也不一定要写在 C 代码里

- 导出的状态可以做任何 trace analysis
