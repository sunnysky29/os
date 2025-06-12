CFLAGS := -O1 -g -I$(TLIB_PATH)

SRCS := $(wildcard *.c)
OBJS := $(SRCS:.c=)

# Default target
all: $(OBJS)

%: %.c
	gcc $(CFLAGS) $< -o $@

clean:
	rm -f $(OBJS)

run: all
	@echo ----- Shared Memory Test -----
	@./memory | sort
	@echo ----- Stack Probe Test -----
	@./stack | sort -nk 3  | tail -n 1
