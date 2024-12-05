def Process(name):
    for _ in range(1):
        print('1111')
        sys_write(name)
    print('2222')
    print('3333')
    sys_write(name)
    
    
    
def main():
    sys_spawn(Process, 'A')
    sys_spawn(Process, 'B')
