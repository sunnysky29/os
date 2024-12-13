**建模理解并发求和**：原本这是一道期中测验题——我们要求同学们给出一个合法的线程调度，它输出最小的 `sum` 值。Online Judge 显示，几乎没有同学第一次就构造出正确的调度：通常 Wrong Answer 若干次后才能意识到 `sum` 可能有更小的值。

https://www.bilibili.com/video/BV1jx4y1S7cP?spm_id_from=333.788.videopod.sections&vd_source=abeb4ad4122e4eff23d97059cf088ab4


~~~

mosaic  -c sum.py   | collect

并发执行三个 T_sum，sum 的最小值是多少？  -->2
初始时 sum = 0; 假设单行语句的执行是原子的
void T_sum() {
    for (int i = 0; i < 3; i++) {
        int t = load(sum);
        t += 1;
        store(sum, t);
    }
}


⏎ sum = 7⏎ sum = 4⏎
sum = 7⏎ sum = 7⏎ sum = 5⏎
sum = 7⏎ sum = 7⏎ sum = 6⏎
sum = 7⏎ sum = 7⏎ sum = 7⏎
sum = 7⏎ sum = 7⏎ sum = 8⏎
sum = 7⏎ sum = 7⏎ sum = 9⏎
sum = 7⏎ sum = 8⏎ sum = 3⏎
sum = 7⏎ sum = 8⏎ sum = 4⏎
sum = 7⏎ sum = 8⏎ sum = 5⏎
sum = 7⏎ sum = 8⏎ sum = 6⏎
sum = 7⏎ sum = 8⏎ sum = 7⏎
sum = 7⏎ sum = 8⏎ sum = 8⏎
sum = 7⏎ sum = 8⏎ sum = 9⏎
sum = 7⏎ sum = 9⏎ sum = 9⏎
sum = 8⏎ sum = 3⏎ sum = 3⏎
sum = 8⏎ sum = 4⏎ sum = 4⏎
sum = 8⏎ sum = 5⏎ sum = 5⏎
sum = 8⏎ sum = 6⏎ sum = 6⏎
sum = 8⏎ sum = 7⏎ sum = 7⏎
sum = 8⏎ sum = 8⏎ sum = 3⏎
sum = 8⏎ sum = 8⏎ sum = 4⏎
sum = 8⏎ sum = 8⏎ sum = 5⏎
sum = 8⏎ sum = 8⏎ sum = 6⏎
sum = 8⏎ sum = 8⏎ sum = 7⏎
sum = 8⏎ sum = 8⏎ sum = 8⏎
sum = 8⏎ sum = 8⏎ sum = 9⏎
sum = 8⏎ sum = 9⏎ sum = 9⏎
sum = 9⏎ sum = 9⏎ sum = 9⏎
|V| = 124313, |E| = 223735.
There are 310 distinct outputs.
~~~