
int main() {
  asm volatile ("cli");  // CLI, 中断禁止（Clear Interrupt Flag）。这条指令会关闭处理器的中断响应，使得处理器不再响应硬件中断信号。
  while (1);

}
