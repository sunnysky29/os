N, Tp, Tc = 2, 3, 3

def Tproduce(nm):
  while not (heap.empty > 0):  # P(empty)
    sys_sched()
  heap.empty -= 1
  sys_sched()

  sys_write('(')
  sys_sched()

  heap.fill += 1  # V(fill)

def Tconsume(nm):
  while not (heap.fill > 0):  # P(fill)
    sys_sched()
  heap.fill -= 1
  sys_sched()

  sys_write(')')
  sys_sched()

  heap.empty += 1  # V(empty)

def main():
  heap.fill = 0
  heap.empty = N

  for i in range(Tp):
    sys_spawn(Tproduce, f'Tp{i+1}')
  for i in range(Tc):
    sys_spawn(Tconsume, f'Tc{i+1}')

# Outputs:
# (()())
# (())()
# ()(())
# ()()()
