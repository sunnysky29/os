#!/bin/bash



gdb -ex "set confirmation off" \
    -ex "source gdbutil" \
    -ex "file ./xv6-public/kernel" \
    -ex "target remote localhost:26000" \
    -ex "layout src"