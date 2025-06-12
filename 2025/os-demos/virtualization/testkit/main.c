#include <stdio.h>
#include <string.h>
#include <testkit.h>

int main(int argc, const char *argv[]) {
    // Print all command line arguments.
    for (int i = 0; i < argc; i++) {
        printf("argv[%d] = %s\n", i, argv[i]);
    }

    if (argv[1] && strcmp(argv[1], "crash") == 0) {
        printf("Ready to crash\n");
        *(int volatile *)0 = 0;
    }

    exit(1);
}

int add(int a, int b) {
    return a + b;
}

UnitTest(test_simple) {
    assert(add(1, 2) == 3);
}

UnitTest(test_fail) {
    assert(114514 == 0x114514);
}

UnitTest(test_timeout) {
    while (1);
}

SystemTest(test_exit_fail, (const char *[]){}) {
    assert(result->exit_status == 0);
}

SystemTest(test_exit_pass, (const char *[]){}) {
    assert(result->exit_status == 1);
}

SystemTest(test_timeout, ((const char *[]){"arg1", "arg2"})) {
    while (1);
}

SystemTest(test_system_pass, (const char *[]){"hola hello"}) {
    tk_assert(
        strstr(result->output, "hello") != NULL,
        "hello should appear in the output"
    );
}
SystemTest(test_system_segfault, (const char *[]){"crash"}) {
    // Should not reach here.
    assert(0);
}
