def Tprint(name):
  sys_write(f'{name}')

def main():
  for name in 'AB':
    sys_spawn(Tprint, name)

# Outputs:
# AB
# BA
