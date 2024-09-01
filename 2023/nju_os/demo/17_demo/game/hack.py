#!/usr/bin/env python3

from sys import argv
import subprocess

if len(argv) < 2:
    print(f'Usage {argv[0]} [--hp] [--fast] [--slow]')
    exit(1)

def patch(addr, patch):
    pid = int(subprocess.check_output(['pidof', 'game']))
    with open(f'/proc/{pid}/mem', 'wb') as fp:
        fp.seek(addr)
        fp.write(patch)

def name(symbol):
    for line in subprocess.check_output(['nm', 'game']).splitlines():
        tokens = line.decode('utf-8').split()
        if tokens[-2:] == ['T', symbol]:
            return int(tokens[0], base=16)

if '--hp' in argv:
    # hit -> mov $9999999, %eax; ret
    patch(name('hit'), b'\xb8\x7f\x96\x98\x00\xc3')

if '--slow' in argv:
    # usleep (endbr64) -> shl $0x4, %rdi
    patch(name('usleep'), b'\x48\xc1\xe7\x04')

if '--fast' in argv:
    # usleep (endbr64) -> shr $0x4, %rdi
    patch(name('usleep'), b'\x48\xc1\xef\x04')
