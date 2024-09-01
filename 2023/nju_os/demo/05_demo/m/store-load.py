def T1():
  heap.x = 1
  sys_sched()
  sys_write(heap.y)

def T2():
  heap.y = 1
  sys_sched()
  sys_write(heap.x)

def main():
  heap.x, heap.y = 0, 0
  sys_spawn(T1)
  sys_spawn(T2)

# Outputs:
# 01
# 11
