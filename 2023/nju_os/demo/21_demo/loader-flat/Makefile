all: loader minimal

loader: loader.c
	gcc -ggdb $< -o $@

minimal: minimal.S
	gcc -S minimal.S > minimal.s
	as minimal.s -o minimal.o
	ld minimal.o -o $@
	objcopy -O binary --only-section=.text minimal minimal.bin

clean:
	rm -f loader minimal *.o *.s *.bin
