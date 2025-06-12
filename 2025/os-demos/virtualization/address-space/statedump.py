# Author: claude-3.7-sonnet

import gdb
import re

class StatedumpCommand(gdb.Command):
    """Generate markdown tables of registers and memory mappings."""

    def __init__(self):
        super(StatedumpCommand, self).__init__("statedump", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        self.generate_markdown_table()
        print("Markdown table written to plot.md")

    def get_registers(self):
        registers = []
        # Get general purpose registers
        reg_names = ["rax", "rbx", "rcx", "rdx", "rsi", "rdi", "rbp", "rsp", 
                    "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15", 
                    "rip", "eflags"]

        for reg in reg_names:
            try:
                value = gdb.parse_and_eval("$" + reg)
                hex_val = f"0x{int(value):016x}"
                dec_val = f"{int(value)}"
                registers.append((reg, hex_val, dec_val))
            except:
                registers.append((reg, "N/A", "N/A"))

        return registers

    def get_memory_mappings(self):
        mappings = []
        try:
            # Use GDB's info proc mappings command
            output = gdb.execute("info proc mappings", to_string=True)

            # Parse the output
            lines = output.split('\n')
            for line in lines:
                # Skip header lines and empty lines
                if not line.strip() or "Start Addr" in line or "---" in line:
                    continue

                # Parse mapping line
                parts = re.split(r'\s+', line.strip())
                if len(parts) >= 5:
                    start_addr = parts[0]
                    end_addr = parts[1]
                    size = parts[2]
                    offset = parts[3]
                    perm = parts[4]
                    name = " ".join(parts[5:]) if len(parts) > 5 else ""

                    mappings.append((start_addr, end_addr, size, perm, name))
        except:
            mappings.append(("Error", "retrieving", "memory", "mappings", ""))

        return mappings

    def generate_markdown_table(self):
        registers = self.get_registers()
        mappings = self.get_memory_mappings()

        markdown = "# Registers\n\n"
        markdown += "| Register | Hex Value | Decimal Value |\n"
        markdown += "|----------|-----------|---------------|\n"

        for reg, hex_val, dec_val in registers:
            markdown += f"| {reg} | {hex_val} | {dec_val} |\n"

        markdown += "\n# Memory Mappings\n\n"
        markdown += "| Start Address | End Address | Size | Permissions | Name |\n"
        markdown += "|---------------|-------------|------|--------------|------|\n"

        for start, end, size, perm, name in mappings:
            markdown += f"| {start} | {end} | {size} | {perm} | {name} |\n"

        # Write to file
        with open("plot.md", "w") as f:
            f.write(markdown)

# Initialize the command
StatedumpCommand()
print('Use "statedump" to generate a state dump to plot.md')

class AutoStatedumpCommand(gdb.Command):
    """Automatically generate a state dump at each stop"""
    
    def __init__(self):
        super(AutoStatedumpCommand, self).__init__("auto-statedump", gdb.COMMAND_USER)
        self.enabled = False
        self.statedump = StatedumpCommand()
        
    def invoke(self, arg, from_tty):
        self.enabled = not self.enabled
        if self.enabled:
            gdb.events.stop.connect(self.on_stop)
            print("Auto statedump enabled - will generate a dump at each stop")
        else:
            gdb.events.stop.disconnect(self.on_stop)
            print("Auto statedump disabled")
    
    def on_stop(self, event):
        print("Generating state dump...")
        self.statedump.invoke("", False)

# Initialize the auto-statedump command
AutoStatedumpCommand()
print('Use "auto-statedump" to toggle automatic state dumps at each stop')
