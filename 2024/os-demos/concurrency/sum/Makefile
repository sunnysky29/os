all: sum

# CFLAGS := -I$(TLIB_PATH)
CFLAGS := -O1 -I$(TLIB_PATH)  # 编译优化； 无优化（默认）。-O1：轻度优化，编译时间较快，生成的代码稍微优化。 -O2：更高级的优化，常用于发布版本。
 # -O3：最高级别的优化，可能会增加编译时间。


sum: sum.c Makefile
	gcc $(CFLAGS) -o $@ $<

clean:
	rm -f sum
