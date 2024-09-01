sh: sh.c
	gcc -O1 -g3 -ggdb -ffreestanding -c sh.c
	ld -o sh sh.o

debug:
	gdb -x init.gdb sh

clean:
	rm -f sh *.o
