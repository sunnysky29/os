

: '

makefile2graph：从输入中提取文件依赖关系（如源文件 → 目标文件等），
                  生成 DOT 图。
                它只关心 Makefile 中定义的规则和依赖关系 ，
                 不会解析或追踪命令行中的具体操作细节 。
                 用于可视化 Makefile 的依赖关系
make：
    -d：打印调试信息（包含依赖关系细节）
    -B：强制重新编译所有目标（确保依赖关系完整）
    -n：干跑模式（只打印命令不实际执行）
grep -v 'n402\|n00000000'   过滤删除带 n402 行

'

make -nB | \
    makefile2graph | \
    grep -v 'n402\|n00000000' | \
    sed 's|/.*/opensbi/||g' | \
    dot -Goverlap=scale -Grankdir=LR -Tsvg -o deps.svg