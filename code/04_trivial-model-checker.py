#!/usr/bin/env python3

"""
2个线程， 每个线程执行4次 +1 操作得到的结果，演示

结合04_multi-thread_sum1.c
https://www.bilibili.com/video/BV1N741177F5?p=6&spm_id_from=pageDriver&vd_source=abeb4ad4122e4eff23d97059cf088ab4
sum.c，多线程求 
1
+
1
+
…
+
1
1+1+…+1

使用一条指令完成 sum++
48 83 05 xx xx xx xx 01: addq $0x1,xxx(%rip)
运行结果
sum = 12615418
假设指令执行是原子不可分割的，那么 sum 应该完全正确才对
sum = 9894505

反直觉？一条 add 可以看成 t = load(x); t++; store(x, t)
(20 行) trivial-model-checker.py
"""

from itertools import combinations_with_replacement

V = {'x': 0}
P = [ [f't{t} = x', f'x = t{t} + 1'] * m for t, m in enumerate([4, 4]) ]

print('Model checking:')
for t, ops in enumerate(P):
  print(f'T{t+1}:', '; '.join(ops))

I = [ [] ]
for ops in P:
  I_new, l = [], len(I[0]) + 1
  for ins_pos in combinations_with_replacement(range(l), len(ops)):
    for sched in I:
      new_sched = []
      for j in range(l):
        new_sched += [op for k, op in enumerate(ops) if ins_pos[k] == j]
        if j < l - 1: new_sched.append(sched[j])
      I_new.append(new_sched)
  I = I_new

print(f'Found {len(I)} schedules')
for sched in I:
  p = '; '.join([f'{var} = {val}' for var, val in V.items()] + sched)
  exec(p)
  print(', '.join([f'{var} = {globals()[var]}' for var in V]), '|', p)