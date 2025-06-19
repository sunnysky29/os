

# -d：打印调试信息（包含依赖关系细节）
# -B：强制重新编译所有目标（确保依赖关系完整）
# -n：干跑模式（只打印命令不实际执行）
#  grep -v 'n402\|n00000000'   过滤删除带 n402 行

make -nB | \
    makefile2graph | \
    grep -v 'n402\|n00000000' | \
    sed 's|/.*/opensbi/||g' | \
    dot -Goverlap=scale -Grankdir=LR -Tsvg -o deps.svg