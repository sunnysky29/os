def main():
  heap.table = '✅'

  # 1st lock()
  while True:
    seen = heap.table
    heap.table = '❌'
    sys_sched()
    if seen == '✅':
      break

  # 2nd lock()
  while True:
    seen = heap.table
    heap.table = '❌'
    sys_sched()
    if seen == '✅':
      break
