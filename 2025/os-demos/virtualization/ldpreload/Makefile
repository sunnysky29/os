CC = gcc
CFLAGS = -Wall -Wextra -fPIC
LDFLAGS = -shared -ldl

all: libmalloc_hook.so test_program

libmalloc_hook.so: malloc_hook.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

test_program: test.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f libmalloc_hook.so test_program 