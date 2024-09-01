def Tsum1():
    heap.x += 1
    sys_sched()
    heap.x += 1


def Tsum10():
    heap.x += 10
    sys_sched()
    heap.x += 10


def main():
    heap.x = 0
    pid = sys_fork()
    sys_sched()
    if pid == 0:
        sys_spawn(Tsum1)
        sys_spawn(Tsum10)
    else:
        heap.x = 100
