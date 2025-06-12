CC = gcc
CFLAGS = -Wall -Wextra -nostdlib -fno-builtin -fno-stack-protector -no-pie -fPIC -ggdb -O1
AR = ar
RANLIB = ranlib

SRC_DIR = src
INCLUDE_DIR = include
OBJ_DIR = obj
LIB_DIR = lib
TEST_DIR = test

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))
LIB = $(LIB_DIR)/libminilibc.a

TEST_SRCS = $(wildcard $(TEST_DIR)/*.c)
TEST_OBJS = $(patsubst $(TEST_DIR)/%.c,$(OBJ_DIR)/%.o,$(TEST_SRCS))
TEST_BINS = $(patsubst $(TEST_DIR)/%.c,$(TEST_DIR)/%,$(TEST_SRCS))

.PHONY: all clean test dirs

all: dirs $(LIB) test

dirs:
	@mkdir -p $(OBJ_DIR) $(LIB_DIR) $(TEST_DIR)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -I$(INCLUDE_DIR) -c $< -o $@

$(LIB): $(OBJS)
	$(AR) rcs $@ $^
	$(RANLIB) $@

$(OBJ_DIR)/%.o: $(TEST_DIR)/%.c
	$(CC) $(CFLAGS) -I$(INCLUDE_DIR) -c $< -o $@

$(TEST_DIR)/%: $(OBJ_DIR)/%.o $(LIB)
	$(CC) $(CFLAGS) -o $@ $< -L$(LIB_DIR) -lminilibc

test: $(TEST_BINS)

clean:
	rm -rf $(OBJ_DIR) $(LIB_DIR) $(TEST_BINS)
