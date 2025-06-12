#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>

void pstree_demo() {
    printf("%d --> %d\n", getppid(), getpid());

    sleep(1);
    
    int random_value;
    FILE *urandom = fopen("/dev/urandom", "r");
    if (urandom) {
        fread(&random_value, sizeof(int), 1, urandom);
        fclose(urandom);
        if (random_value % 2 == 0) {
            // Early termination
            exit(0);
        }
    } else {
        perror("Failed to open /dev/urandom");
    }
    
    sleep(1);
    
    printf("%d --> %d\n", getppid(), getpid());

    exit(0);
}

void create_process_tree(int depth, int max_depth) {
    if (depth >= max_depth) {
        return;
    }
    
    pid_t pid1, pid2;
    
    // Create first child
    if ((pid1 = fork()) < 0) {
        perror("fork");
        exit(1);
    }
    
    if (pid1 == 0) { // First child
        create_process_tree(depth + 1, max_depth);
        pstree_demo();
    }
    
    // Create second child
    if ((pid2 = fork()) < 0) {
        perror("fork");
        exit(1);
    }
    
    if (pid2 == 0) { // Second child
        create_process_tree(depth + 1, max_depth);
        pstree_demo();
    }
}

int main() {
    srand(time(NULL));
    setbuf(stdout, NULL);
    
    printf("```mermaid\ngraph TD\n");

    // Create a process tree with 5 layers
    create_process_tree(1, 5);

    sleep(1);
    printf("```\n");
    printf("```mermaid\ngraph TD\n");

    sleep(2);
    printf("```\n");
    
    // Wait for all children to finish
    while (wait(NULL) > 0);
    
    return 0;
}
