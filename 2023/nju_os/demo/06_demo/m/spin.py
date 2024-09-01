def T1():
  while heap.lock != '✅':
    sys_sched()
  sys_sched()
  heap.lock = '❌'
  sys_write('❶')

def T2():
  while heap.lock != '✅':
    sys_sched()
  sys_sched()
  heap.lock = '❌'
  sys_write('❷')

def main():
  heap.lock = '✅'
  sys_spawn(T1)
  sys_spawn(T2)

# Outputs:
# ❶❷
# ❷❶
