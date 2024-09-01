import gdb
from pathlib import Path

REGS = [
    'rax', 'rbx', 'rcx', 'rdx',
    'rbp', 'rsp', 'rsi', 'rdi',
    'r8', 'r9', 'r10', 'r11',
]

class RegDump(gdb.Command):
    def __init__(self):
        super(RegDump, self).__init__(
            "rdump", gdb.COMMAND_DATA, gdb.COMPLETE_SYMBOL
        )

    def invoke(self, arg, _):
        ctx = gdb.parse_and_eval(f'ctx')
        for i, r in enumerate(REGS):
            print(
                f'{r.upper():3} = {int(ctx[r]):016x}',
                end=['  ', '\n'][i % 2]
            )
        print('-' * 40)

RegDump()

def get_source_line(address):
    # by GPT-4

    # Find the source code line corresponding to the given address
    symtab_and_line = gdb.find_pc_line(address)

    # Check if the source code line was found
    if symtab_and_line.symtab is not None:
        # Get the source file name and line number
        filename = symtab_and_line.symtab.filename
        line_number = symtab_and_line.line

        return f'{Path(filename).name}:{line_number}'
    else:
        return "Source code line not found"

class ProcDump(gdb.Command):
    def __init__(self):
        super(ProcDump, self).__init__(
            "pdump", gdb.COMMAND_DATA, gdb.COMPLETE_SYMBOL
        )

    def invoke(self, *_):
        n = gdb.parse_and_eval(f'NTASK')
        for i in range(n):
            tsk = gdb.parse_and_eval(f'tasks[{i}]')
            pc = int(tsk['context']['rip'])
            is_current = int(
                gdb.parse_and_eval(f'&tasks[{i}] == current')
            )
            print(
                f'Proc-{i}{" *"[is_current]} ',
                get_source_line(pc)
            )
        
        print('-' * 40)

ProcDump()
