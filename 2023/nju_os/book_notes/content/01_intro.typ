#import "../template.typ": *

= intro

- demo code: https://github.com/remzi-arpacidusseau/ostep-code
- homework: https://github.com/remzi-arpacidusseau/ostep-homework
- projects: https://github.com/remzi-arpacidusseau/ostep-projects

The book is about *virtualization*, *concurrency*, and *persistence* of the operating system.

== So what happens when a program runs?

A running program does one very simple thing: it executes instructions.
The processor fetches an instruction from memory, decodes it and executes it. After it is done with this instruction, the processor moves on to the next instruction, and so on, and so on, until the program finally completes1. This is the Von Neumann model of computing.

While a lot of other wild things are going on with the primary goal of making the system *easy to use*. OS is in charge of making sure the system operates correctly and efficiently in an easy-to-use manner.

== virtualization

The OS takes a physical resource (such as the processor, or memory, or a disk) and transforms it into a more general, powerful, and easy-to-use virtual form of itself.

A typical OS, in fact, exports a few hundred *system calls* that are available to applications. Because the OS provides these calls to run programs, access memory and devices, and other related actions, we also sometimes say that the OS provides *a standard library* to applications.

The OS is sometimes known as a resource manager.

=== Virtualizing The CPU

```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <assert.h>
#include "common.h"

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: cpu <string>\n");
        exit(1);
    }
    char *str = argv[1];
    while (1) {
        Spin(1);
        printf("%s\n", str);
    }
    return 0;
}
```

```sh
prompt> ./cpu A & ; ./cpu B & ; ./cpu C & ; ./cpu D &
[1] 7353
[2] 7354
[3] 7355
[4] 7356
A
B
D
C
A
B
D
C
A
C
B
D
...
```

=== Virtualizing Memory

```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

int main(int argc, char *argv[]) {
    int *p = malloc(sizeof(int)); // a1
    assert(p != NULL);
    printf("(%d) address pointed to by p: %p\n", getpid(), p); // a2
    *p = 0; // a3
    while (1) {
        Spin(1);
        *p = *p + 1;
        printf("(%d) p: %d\n", getpid(), *p); // a4
    }
    return 0;
}
```

```sh
prompt> ./mem &; ./mem &
[1] 24113
[2] 24114
(24113) address pointed to by p: 0x200000
(24114) address pointed to by p: 0x200000
(24113) p: 1
(24114) p: 1
(24114) p: 2
(24113) p: 2
(24113) p: 3
(24114) p: 3
(24113) p: 4
(24114) p: 4
...
```

Each process accesses its own private *virtual address space* (sometimes just called its *address space*), which the OS somehow maps onto the physical memory of the machine.

== Concurrency

```c
#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "common_threads.h"

volatile int counter = 0;
int loops;

void *worker(void *arg) {
    int i;
    for (i = 0; i < loops; i++) {
	counter++;
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
	fprintf(stderr, "usage: threads <loops>\n");
	exit(1);
    }
    loops = atoi(argv[1]);
    pthread_t p1, p2;
    printf("Initial value : %d\n", counter);
    Pthread_create(&p1, NULL, worker, NULL);
    Pthread_create(&p2, NULL, worker, NULL);
    Pthread_join(p1, NULL);
    Pthread_join(p2, NULL);
    printf("Final value   : %d\n", counter);
    return 0;
}
```

```sh
prompt> gcc -o thread thread.c -Wall -pthread
prompt> ./thread 1000
Initial value : 0
Final value : 2000
```

```sh
prompt> ./thread 100000
Initial value : 0
Final value : 143012 // huh??
prompt> ./thread 100000
Initial value : 0
Final value : 137298 // what the??
```

A key part of the program above, where the shared counter is incremented, takes three instructions: one to load the value of the counter from memory into a register, one to increment it, and one to store it back into memory. Because these three instructions do not execute atomically (all at once), strange things can happen.

== persistence

The software in the operating system that usually manages the disk is called the *file system*. It is assumed that often times, users will want to *share* information that is in files.

```c
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>

int main(int argc, char *argv[]) {
    int fd = open("/tmp/file", O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    assert(fd >= 0);
    char buffer[20];
    sprintf(buffer, "hello world\n");
    int rc = write(fd, buffer, strlen(buffer));
    assert(rc == (strlen(buffer)));
    fsync(fd);
    close(fd);
    return 0;
}
```

The file system has to do a fair bit of work: first figuring out where on disk this new data will reside, and then keeping track of it in various structures the file system maintains. Doing so requires issuing I/O requests to the underlying storage device, to either read existing structures or update (write) them. As anyone who has written a *device driver* knows, getting a device to do something on your behalf is an intricate and detailed process. It requires a deep knowledge of the low-level device interface and its exact semantics. Fortunately, the OS provides a standard and simple way to access devices through its system calls. Thus, the OS is sometimes seen as a *standard library*.

To handle the problems of system crashes during writes, most file systems incorporate some kind of intricate write protocol, such as *journaling* or *copy-on-write*, carefully ordering writes to disk to ensure that if a failure occurs during the write sequence, the system can recover to reasonable state afterwards.

== Design Goals

One goal in designing and implementing an operating system is to provide *high performance*; another way to say this is our goal is to *mini-mize the overheads* of the OS. Virtualization and making the system easy to use are well worth it, but not at any cost; thus, we must strive to provide virtualization and other OS features without excessive overheads. These overheads arise in a number of forms: extra time (more instructions) and extra space (in memory or on disk).

Another goal will be to provide *protection* between applications, as well as between the OS and applications.Protection is at the heart of one of the main principles underlying an operating system, which is that of *isolation*; isolating processes from one another is the key to protection and thus underlies much of what an OS must do.

The operating system must also run *non-stop*; when it fails, all applications running on the system fail as well. Because of this dependence, operating systems often strive to provide a high degree of *reliability*.

Other goals: energy-efficiency, security, mobility...

== History

- Early Operating Systems: Just Libraries
- -> Beyond Libraries: Protection
- -> The Era of Multiprogramming
- -> The Modern Era
