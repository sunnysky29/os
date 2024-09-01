def Tworker(enter, exit):
  for _ in range(2):
    while True:
      seen = heap.table
      heap.table = '❌'
      sys_sched()
      if seen == '✅':
        break
    sys_sched()
    sys_write(enter)
    sys_sched()
    sys_write(exit)
    sys_sched()
    heap.table = '✅'
    sys_sched()

def main():
  heap.table = '✅'
  sys_spawn(Tworker, '(', ')')
  sys_spawn(Tworker, '[', ']')

# Outputs:
# ()()[][]
# ()[]()[]
# ()[][]()
# []()()[]
# []()[]()
# [][]()()
