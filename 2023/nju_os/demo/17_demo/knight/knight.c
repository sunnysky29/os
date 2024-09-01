#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdint.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdarg.h>
#include <fcntl.h>

#define MAX_WATCH 65536

struct game {
    const char *name;  // Name of the binary
    int pid;           // Process ID

    int memfd;       // Address space of the process
    int bits;        // Search bit-width (16, 32, or 64)
    bool has_watch;  // Watched values
    uintptr_t watch[MAX_WATCH];
};

FILE *popens(const char *fmt, ...);
uint64_t mem_load(char *mem, int off, int bits);

void scan(struct game *g, uint32_t val) {
    uintptr_t start, kb;
    char perm[16];
    FILE *fp = popens("pmap -x $(pidof %s) | tail -n +3", g->name);
    int nmatch = 0;

    while (fscanf(fp, "%lx", &start) == 1) {
        fscanf(fp, "%ld%*ld%*ld%s%*[^\n]s", &kb, perm);
        if (perm[1] != 'w') continue;  // Non-writable areas

        uintptr_t size = kb * 1024;
        char *mem = calloc(size + 16, 1);  // Ignores error handling for brevity
                                           // Don't do this in production!
        lseek(g->memfd, start, SEEK_SET);
        size = read(g->memfd, mem, size);

        printf("Scanning %lx--%lx\n", start, start + size);

        if (!g->has_watch) {
            // First-time search; scan all memory
            for (int off = 0; off < size; off += 2) {
                uint64_t v = mem_load(mem, off, g->bits);
                if (v == val && nmatch < MAX_WATCH) {
                    g->watch[nmatch++] = start + off;
                }
            }
        } else {
            // Search in the watched values
            for (int i = 0; i < MAX_WATCH; i++) {
                intptr_t off = g->watch[i] - start;
                if (g->watch[i] && 0 <= off && off < size) {
                    uint64_t v = mem_load(mem, off, g->bits);
                    if (v == val)
                        nmatch++;
                    else
                        g->watch[i] = 0;
                }
            }
        }
        free(mem);
    }
    pclose(fp);

    if (nmatch > 0) {
        g->has_watch = true;
    }
    printf("There are %d match(es).\n", nmatch);
}

void overwrite(struct game *g, uint64_t val) {
    int nwrite = 0;
    for (int i = 0; i < MAX_WATCH; i++)
        if (g->watch[i]) {
            lseek(g->memfd, g->watch[i], SEEK_SET);
            write(g->memfd, &val, g->bits / 8);
            nwrite++;
        }
    printf("%d value(s) written.\n", nwrite);
}

void reset(struct game *g) {
    for (int i = 0; i < MAX_WATCH; i++) {
        g->watch[i] = 0;
    }
    g->has_watch = false;
    printf("Search for %d-bit values in %s.\n", g->bits, g->name);
}

int load_game(struct game *g, const char *name) {
    FILE *pid_fp;
    int ret = 0;

    g->name = name;
    g->bits = 32;
    reset(g);

    pid_fp = popens("pidof %s", g->name);
    if (fscanf(pid_fp, "%d", &g->pid) != 1) {
        fprintf(stderr, "Panic: fail to get pid of \"%s\".\n", g->name);
        ret = -1;
        goto release;
    }

    char buf[64];
    snprintf(buf, sizeof(buf), "/proc/%d/mem", g->pid);
    g->memfd = open(buf, O_RDWR);
    if (g->memfd < 0) {
        perror("/proc/[pid]/mem");
        ret = -1;
        goto release;
    }

release:
    if (pid_fp) pclose(pid_fp);
    return ret;
}

void close_game(struct game *g) {
    if (g->memfd >= 0) {
        close(g->memfd);
    }
}

int main(int argc, char *argv[]) {
    long val;
    char buf[64];
    struct game game;

    if (load_game(&game, argv[1]) < 0) {
        goto release;
    }

    while (!feof(stdin)) {
        printf("(%s %d) ", game.name, game.pid);
        if (scanf("%s", buf) <= 0) goto release;

        switch (buf[0]) {
            case 'q':
                goto release;
                break;
            case 'b':
                scanf("%ld", &val);
                game.bits = val;
                reset(&game);
                break;
            case 's':
                scanf("%ld", &val);
                scan(&game, val);
                break;
            case 'w':
                scanf("%ld", &val);
                overwrite(&game, val);
                break;
            case 'r':
                reset(&game);
                break;
        }
    }

release:
    close_game(&game);
    return 0;
}

FILE *popens(const char *fmt, ...) {
    char cmd[128];
    va_list args;
    va_start(args, fmt);
    vsnprintf(cmd, sizeof(cmd), fmt, args);
    va_end(args);
    FILE *ret = popen(cmd, "r");
    assert(ret);
    return ret;
}

uint64_t mem_load(char *mem, int off, int bits) {
    uint64_t val = *(uint64_t *)(&mem[off]);
    switch (bits) {
        case 16:
            val &= 0xffff;
            break;
        case 32:
            val &= 0xffffffff;
            break;
        case 64:
            break;
        default:
            assert(0);
    }
    return val;
}
