// Author: Claude-3.7-sonnet (Cursor IDE)

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/resource.h>

int main() {
    pid_t pid = getpid();
    printf("pid: %d\n", pid);

    pid_t ppid = getppid();
    printf("ppid: %d\n", ppid);
    printf("\n--- Additional Process Information ---\n");
    
    // Get the user ID and group ID
    uid_t uid = getuid();
    gid_t gid = getgid();
    printf("User ID: %d\n", uid);
    printf("Group ID: %d\n", gid);
    
    // Get the effective user ID and group ID
    uid_t euid = geteuid();
    gid_t egid = getegid();
    printf("Effective User ID: %d\n", euid);
    printf("Effective Group ID: %d\n", egid);
    
    // Get the number of open file descriptors
    int num_fds = sysconf(_SC_OPEN_MAX);
    printf("Max open file descriptors: %d\n", num_fds);
    
    // Get the process priority
    int priority = getpriority(PRIO_PROCESS, 0);
    printf("Process priority: %d\n", priority);

    // Display process status from /proc/self/status
    FILE *status_file = fopen("/proc/self/status", "r");
    if (status_file) {
        char line[256];
        printf("\n--- Process Status (/proc/self/status) ---\n");
        while (fgets(line, sizeof(line), status_file)) {
            // Print interesting fields like name, state, memory usage
            if (strncmp(line, "Name:", 5) == 0 ||
                strncmp(line, "State:", 6) == 0 ||
                strncmp(line, "PPid:", 5) == 0 ||
                strncmp(line, "Uid:", 4) == 0 ||
                strncmp(line, "VmSize:", 7) == 0) {
                printf("%s", line);
            }
        }
        fclose(status_file);
    }
    
    // Display command line
    printf("\n--- Command Line (/proc/self/cmdline) ---\n");
    int cmdline_fd = open("/proc/self/cmdline", O_RDONLY);
    if (cmdline_fd >= 0) {
        char buffer[256];
        ssize_t bytes_read = read(cmdline_fd, buffer, sizeof(buffer) - 1);
        if (bytes_read > 0) {
            buffer[bytes_read] = '\0';
            // Replace null bytes with spaces for display
            for (int i = 0; i < bytes_read - 1; i++) {
                if (buffer[i] == '\0') buffer[i] = ' ';
            }
            printf("Command line: %s\n", buffer);
        }
        close(cmdline_fd);
    }
    
    // Display current working directory
    printf("\n--- Current Directory (/proc/self/cwd) ---\n");
    char cwd[256] = {0};
    if (readlink("/proc/self/cwd", cwd, sizeof(cwd) - 1) != -1) {
        cwd[sizeof(cwd) - 1] = '\0';
        printf("Current directory: %s\n", cwd);
    }
    
    return 0;
}
