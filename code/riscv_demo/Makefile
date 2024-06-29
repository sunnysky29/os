a.out: rvemu.c uncore.c
# RTFM: Automatic variables
	gcc $(CFLAGS) $<

run: a.out
	@echo 2 Head, 4 Feet:
	@cat ji-tu.txt | ./a.out 2 4
	@echo 2 Head, 6 Feet:
	@cat ji-tu.txt | ./a.out 2 6
	@echo 2 Head, 8 Feet:
	@cat ji-tu.txt | ./a.out 2 8
	@echo 35 Head, 94 Feet:
	@cat ji-tu.txt | ./a.out 35 94

clean:
	rm -f a.out