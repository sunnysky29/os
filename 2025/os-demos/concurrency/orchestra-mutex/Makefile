CFLAGS := -O2 -I$(TLIB_PATH)

all: orchestra

orchestra: orchestra.c main.c notes/C1.wav
	gcc $(CFLAGS) -o $@ $<

notes/C1.wav:
	python3 gen-notes.py

clean:
	rm -rf notes orchestra
