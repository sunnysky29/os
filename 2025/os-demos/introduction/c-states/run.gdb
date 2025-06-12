# Author: o3-mini
# (这个代码写得并不好)

# 先在 main 处设置断点，并启动程序
break main
run

python
import gdb
import json
import re

def get_stack_state():
    """
    返回一个列表，每项为一个帧的状态，格式为字典：
      {"function": 函数名, "locals": {变量: 值, ...} }
    从 main 开始（call stack 底部）到当前最新的帧。
    注：仅提取 gdb 能获取到的局部变量，不包含参数。
    """
    state = []
    # 从最新帧往上遍历
    frame = gdb.newest_frame()
    while frame is not None:
        try:
            fname = frame.name() or "??"
            if '__' in fname:
                break
            
            local_vars = {}
            # 使用 frame.block 遍历变量（注意：可能包含块内变量）
            block = frame.block()
            while block:
                for symbol in block:
                    if symbol.is_variable or symbol.is_argument:
                        try:
                            # 尝试读取变量值
                            v = symbol.value(frame)
                            if hasattr(v, 'address'):
                                if v.address > 0x6fffffffffff:
                                    local_vars[symbol.print_name] = str(v)
                                elif not state:
                                    local_vars[symbol.print_name] = str(v)
                        except Exception:
                            pass
                block = block.superblock
            state.append({"function": fname, "locals": local_vars})
        except Exception:
            pass
        frame = frame.older()
    state.reverse()
    # 只保留从 main 开始的帧（假设 main 为入口）
    for i, frame_info in enumerate(state):
        if frame_info["function"] == "main":
            return state[i:]
    return state

def format_state(state):
    """
    将给定的 call stack 状态格式化成一行文本，
    每个帧格式为：函数名: {var1=val1, var2=val2}
    多帧之间用 " / " 分隔。
    """
    lines = []
    for frame in state:
        # 将局部变量按“变量=值”拼接为逗号分隔的字符串
        locals_str = "<br>".join(f"{k} = {v}" for k,v in frame["locals"].items())
        lines.append(locals_str)
    return "<hr>".join(lines)

# 用于记录每一步的 (stack_state, label) 迁移信息
transitions = []

def current_line():
    frame = gdb.newest_frame()
    sal = frame.find_sal()
    with open(sal.symtab.filename, 'r') as f:
         lines = f.readlines()
         line = sal.line
         return f"{line} - " + lines[line - 1].replace(";", "").strip()

# 在程序刚停在 main 入口处时记录状态
init_state = get_stack_state()
transitions.append((init_state, current_line()))

# 开始单步跟踪
while True:
    prev_state = transitions[-1][0]
    prev_depth = len(prev_state)
    try:
        # 单步执行一行（step 会进入函数内部）
        gdb.execute("step", to_string=True)
    except gdb.error:
        # 如果发生错误（例如程序结束），退出循环
        break

    # 尝试获取当前执行行：使用当前栈帧的符号位置信息
    try:
        code_line = current_line()
    except Exception:
        code_line = "unknown"

    new_state = get_stack_state()
    new_depth = len(new_state)

    # 判断是否发生函数调用或返回：通过栈深度的变化区分
    if new_depth > prev_depth:
        label = "call " + new_state[-1]["function"]
    elif new_depth < prev_depth:
        label = code_line
    else:
        label = code_line

    transitions.append( (new_state, label) )

    # 当 main 不在 call stack 内时（即 main 返回）则结束跟踪
    if not any(frame["function"] == "main" for frame in new_state):
        break

# 调试结束后，在 main 完成后输出 plot.md 文件，使用 mermaid 的 stateDiagram-v2 格式展现状态转移图
try:
    with open("plot.md", "w", encoding="utf-8") as f:
        f.write("```mermaid\n")
        f.write("stateDiagram-v2\n")

        for i, (state, _) in enumerate(transitions):
            f.write(f"    S{i}: {format_state(state)}\n")

        # 定义状态节点时使用索引 S0, S1, …；状态内容格式化为 call stack 中各帧的函数及局部变量
        def state_name(i, state):
            return "S{}".format(i)
        # 初始状态
        f.write("    [*] --> S0\n")
        for i in range(1, len(transitions)):
            f.write("    " + state_name(i-1, transitions[i-1][0]) + " --> " + state_name(i, transitions[i][0]) +
                    " : " + transitions[i-1][1] + "\n")
        f.write("```\n")
    print("plot.md generated.")
except Exception as e:
    print("Error writing plot.md:", e)

end

# 程序执行完毕后退出 gdb
quit
