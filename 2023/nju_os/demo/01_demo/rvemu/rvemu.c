#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef uint32_t u32;

typedef struct {
    u32 op : 7, rd : 5, f3 : 3, rs1 : 5, rs2 : 5, f7 : 7;
} inst_t;
typedef struct {
    u32 on, x[32];
} CPUState;

static inline u32 sext(u32 val, u32 n) {
    // Sign extend n-bit integer val to 32-bit
    u32 mask = ~((1 << n) - 1);
    u32 set = (val >> (n - 1)) & 1;
    u32 ret = set ? (val | mask) : val;
    return ret;
}

// Uncore:
//   inst_fetch - read an instruction from stdin
//   ebreak - hyper call: putchar/putd/exit
static inline bool inst_fetch(inst_t *in) {
    union {
        inst_t i;
        u32 u;
    } u;
    int r = scanf("%x", &u.u);
    *in = u.i;
    return r > 0;
}

static inline void ebreak(CPUState *cpu) {
    switch (cpu->x[10]) {
        case 1: {
            putchar(cpu->x[11]);
            break;
        }
        case 2: {
            printf("%d", cpu->x[11]);
            break;
        }
        case 3: {
            cpu->on = false;
            break;
        }
        default:
            assert(0);
    }
}

int main(int argc, char *argv[]) {
    CPUState cpu = {.on = 1, .x = {0}};  // The RESET state
    for (int i = 0; argv[i + 1] && i < 8; i++) {
        cpu.x[10 + i] = atoi(argv[i + 1]);  // Set a0-a7 to arguments
    }

    inst_t in;
    while (cpu.on && inst_fetch(&in)) {
        // For each fetched instruction, execute it following the RV32I spec
        u32 op = in.op, f3 = in.f3, f7 = in.f7;
        u32 imm = sext((f7 << 5) | in.rs2, 12), shamt = in.rs2;
        u32 rd = in.rd, rs1_u = cpu.x[in.rs1], rs2_u = cpu.x[in.rs2], res = 0;

#define __ else if  // Bad syntactic sugar!
        if (op == 0b0110011 && f3 == 0b000 && f7 == 0b0000000)
            res = rs1_u + rs2_u;
        __(op == 0b0110011 && f3 == 0b000 && f7 == 0b0100000)
        res = rs1_u - rs2_u;
        __(op == 0b0010011 && f3 == 0b000) res = rs1_u + imm;
        __(op == 0b0010011 && f3 == 0b001 && f7 == 0b0000000)
        res = rs1_u << shamt;
        __(op == 0b0010011 && f3 == 0b101 && f7 == 0b0000000)
        res = rs1_u >> shamt;
        __(op == 0b1110011 && f3 == 0b000 && rd == 0 && imm == 1) ebreak(&cpu);
        else assert(0);
        if (rd) cpu.x[rd] = res;
    }
}
