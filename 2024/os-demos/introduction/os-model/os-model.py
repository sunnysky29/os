#!/usr/bin/env python3

"""30 行代码讲完《操作系统》
进程
系统调用
上下文切换
调度

系统调用
    read(): 返回随机的 0 或 1
    write(s): 向 buffer 输出字符串 s
    spawn(f): 创建一个可运行的状态机 f
"""

import sys
import random
from pathlib import Path

class OS:
    '''
    A minimal executable operating system model. Processes
    are state machines (Python generators) that can be paused
    or continued with local states being saved.
    '''

    '''
    We implement four system calls:

    - read: read a random bit value.
    - write: write a string to the buffer.
    - spawn: create a new state machine (process).
    '''
    SYSCALLS = ['read', 'write', 'spawn']

    class Process:  ## os 的管理对象，就是状态机，当我能访问它时候，假设已经暂停了
        '''
        A "freezed" state machine. The state (local variables,
        program counters, etc.) are stored in the generator
        object.
        '''

        def __init__(self, func, *args):
            # func should be a generator function. Calling
            # func(*args) returns a generator object.
            self._func = func(*args)

            # This return value is set by the OS's main loop.
            self.retval = None

        def step(self):
            '''
            Resume the process with OS-written return value,
            until the next system call is issued.
            '''
            syscall, args, *_ = self._func.send(self.retval)
            self.retval = None
            return syscall, args

    def __init__(self, src):
        # This is a hack: we directly execute the source
        # in the current Python runtime--and main is thus
        # available for calling.
        exec(src, globals())
        self.procs = [OS.Process(main)]  # os 的初始进程
        print(f'__init__, self.procs: {self.procs} !!!!!')
        
        self.buffer = ''

    def run(self):
        # Real operating systems waste all CPU cycles
        # (efficiently, by putting the CPU into sleep) when
        # there is no running process at the moment. Our model
        # terminates if there is nothing to run.
        while self.procs:
            print(f'before self.procs: {self.procs} ')
            
            # There is also a pointer to the "current" process
            # in today's operating systems.
            current = random.choice(self.procs)
            print(f'current:     {current}  <-----------') 
            try:
                # Operating systems handle interrupt and system
                # calls, and "assign" CPU to a process.
                match current.step():  #  会一直运行，直到遇到 syscall
                    case 'read', _:
                        print(f'///read')
                        current.retval = random.choice([0, 1])
                    case 'write', s:
                        print(f'///write')
                        self.buffer += s
                    case 'spawn', (fn, *args):
                        print(f'///spawn')
                        self.procs += [OS.Process(fn, *args)]
                    case _:
                        print(f'-----&&&&&')
                        assert 0

            except StopIteration:
                print(f'proc {current} done , DEL..........')
                # The generator object terminates.
                self.procs.remove(current)
            print(f'after self.procs: {self.procs} ')
            print(f'self.buffer: {self.buffer}')   
            print(f'----'*20)
        return self.buffer

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} file')
        exit(1)

    src = Path(sys.argv[1]).read_text()

    # Hack: patch sys_read(...) -> yield "sys_read", (...)
    for syscall in OS.SYSCALLS:
        src = src.replace(f'sys_{syscall}',
                          f'yield "{syscall}", ')

    stdout = OS(src).run()
    print(stdout)



"""
 ./os-model.py   proc.py
__init__, self.procs: [<__main__.OS.Process object at 0x7f61726dfeb0>] !!!!!
before self.procs: [<__main__.OS.Process object at 0x7f61726dfeb0>]
current:     <__main__.OS.Process object at 0x7f61726dfeb0>  <-----------
///spawn
after self.procs: [<__main__.OS.Process object at 0x7f61726dfeb0>, <__main__.OS.Process object at 0x7f61726de8c0>]
self.buffer:
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726dfeb0>, <__main__.OS.Process object at 0x7f61726de8c0>]
current:     <__main__.OS.Process object at 0x7f61726dfeb0>  <-----------
///spawn
after self.procs: [<__main__.OS.Process object at 0x7f61726dfeb0>, <__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
self.buffer:
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726dfeb0>, <__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
current:     <__main__.OS.Process object at 0x7f61726dfeb0>  <-----------
proc <__main__.OS.Process object at 0x7f61726dfeb0> done , DEL..........
after self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
self.buffer:
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
current:     <__main__.OS.Process object at 0x7f61726de8c0>  <-----------
1111
///write
after self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
self.buffer: A
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
current:     <__main__.OS.Process object at 0x7f61726de9b0>  <-----------
1111
///write
after self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
self.buffer: AB
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
current:     <__main__.OS.Process object at 0x7f61726de9b0>  <-----------
2222
3333
///write
after self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
self.buffer: ABB
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
current:     <__main__.OS.Process object at 0x7f61726de8c0>  <-----------
2222
3333
///write
after self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
self.buffer: ABBA
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>, <__main__.OS.Process object at 0x7f61726de9b0>]
current:     <__main__.OS.Process object at 0x7f61726de9b0>  <-----------
proc <__main__.OS.Process object at 0x7f61726de9b0> done , DEL..........
after self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>]
self.buffer: ABBA
--------------------------------------------------------------------------------
before self.procs: [<__main__.OS.Process object at 0x7f61726de8c0>]
current:     <__main__.OS.Process object at 0x7f61726de8c0>  <-----------
proc <__main__.OS.Process object at 0x7f61726de8c0> done , DEL..........
after self.procs: []
self.buffer: ABBA
--------------------------------------------------------------------------------
ABBA
"""