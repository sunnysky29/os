


视频讲解 ： https://www.bilibili.com/video/BV15T4y1Q76V/?spm_id_from=333.788&vd_source=abeb4ad4122e4eff23d97059cf088ab4 ， 
理解并发程序执行 (Peterson算法、模型检验与软件自动化工具) [南京大学2022操作系统-P4]


p4:
~~~

python3  model-checker.py   ../mutex-bad.py |  python3  visualize.py  > a.html

python3  model-checker.py   ../mutex-bad.py |  python3  visualize.py  -t  > b.html


python3  model-checker.py   ../peterson-flag.py  |  python3 visualize.py  -r  >  peterson.html


~~~


p5: 
~~~
python3  model-checker.py   ../p5/spinlock.py |  python3  visualize.py -t > p5/a.html


~~~