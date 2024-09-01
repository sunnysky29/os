def main():
  heap.buf = ''
  for _ in range(2):
    sys_fork()
    heap.buf += '⭐️'
  sys_write(heap.buf)

# Outputs:
# ⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️
