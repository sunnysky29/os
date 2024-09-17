#!/bin/bash

# make    ARCH=native -nB  > make.log
make    ARCH=native -nB  \
  | grep -ve '^\(\#\|echo\|mkdir\|make\)' \
  | sed "s#$AM_HOME#\$AM_HOME#g" \
  | sed "s#$PWD#.#g" \
  | vim -