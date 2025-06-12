debug: sample hanoi
	gdb -x run.gdb sample && mv plot.md sample.md
	gdb -x run.gdb hanoi && mv plot.md hanoi.md

sample: sample.c
	gcc -g -O0 -o $@ $^

hanoi: hanoi.c
	gcc -g -O0 -o $@ $^

clean:
	rm -rf plot.md sample.md hanoi.md sample hanoi
