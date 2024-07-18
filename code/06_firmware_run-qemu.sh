# bash 06_firmware_run-qemu.sh  hello.img 
# 调试  512B 的磁盘镜像
# https://www.bilibili.com/video/BV1HN41197Ko/?p=4&vd_source=abeb4ad4122e4eff23d97059cf088ab4
#!/bin/bash

qemu-system-i386 -s -S -drive format=raw,file=$1 &
pid=$!
gdb \
  -ex "target remote localhost:1234" \
  -ex "set confirm off"

kill -9 $!
