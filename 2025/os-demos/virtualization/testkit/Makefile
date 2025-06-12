CFLAGS := -Wall -g -I.

SRCS := main.c
OBJS := $(SRCS:.c=)

test: all
	-@bash -c "TK_VERBOSE=1 ./main"

all: $(OBJS)

%: %.c testkit.c
	gcc $(CFLAGS) $< testkit.c -o $@

clean:
	rm -f $(OBJS)

.PHONY: all clean
