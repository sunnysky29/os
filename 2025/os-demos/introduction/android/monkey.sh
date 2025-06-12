#!/bin/bash

pkg=$(adb shell pm list packages | fzf)
pkg=$(echo $pkg | cut -d: -f2)
adb shell monkey -p $pkg -v 1000
