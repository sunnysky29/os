// Note: this file is statically linked.

// 10MB of data.
char arr[10485760];

int main() {
    // 10MB of NOP instructions.
    asm volatile(
        ".rept 10485760;"
        "nop;"
        ".endr;"
    );
}
