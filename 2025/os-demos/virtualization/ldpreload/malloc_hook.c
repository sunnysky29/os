#define _GNU_SOURCE
#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stddef.h>
#include <pthread.h>

// Function pointers to the real malloc and free
static void* (*real_malloc)(size_t) = NULL;
static void (*real_free)(void*) = NULL;

// Mutex to prevent output interleaving
static pthread_mutex_t trace_mutex = PTHREAD_MUTEX_INITIALIZER;

// Initialize the real function pointers
static void init_real_functions() {
    real_malloc = dlsym(RTLD_NEXT, "malloc");
    real_free = dlsym(RTLD_NEXT, "free");
}

// Our malloc hook
void* malloc(size_t size) {
    // Initialize real functions if needed
    if (!real_malloc) {
        init_real_functions();
    }

    // Call real malloc
    void* ptr = real_malloc(size);

    // Print trace
    pthread_mutex_lock(&trace_mutex);
    fprintf(stderr, "[TRACE] malloc(%zu) = %p\n", size, ptr);
    pthread_mutex_unlock(&trace_mutex);

    return ptr;
}

// Our free hook
void free(void* ptr) {
    // Initialize real functions if needed
    if (!real_free) {
        init_real_functions();
    }

    // Print trace before freeing
    pthread_mutex_lock(&trace_mutex);
    fprintf(stderr, "[TRACE] free(%p)\n", ptr);
    pthread_mutex_unlock(&trace_mutex);

    // Call real free
    real_free(ptr);
} 