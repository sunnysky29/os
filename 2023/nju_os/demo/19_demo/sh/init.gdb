set follow-fork-mode child
set detach-on-fork off
set follow-exec-mode same
set confirm off
set pagination off
source visualize.py
break _start
run
n 2
define hook-stop
    pdump
end
