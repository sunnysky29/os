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
    case 1: { putchar(cpu->x[11]); break; }
    case 2: { printf("%d", cpu->x[11]); break; }
    case 3: { cpu->on = false; break; }
    default: assert(0);
  }
}