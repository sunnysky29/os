#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Testing malloc/free hooks...\n");
    
    // Test single allocation/free
    void* ptr1 = malloc(100);
    printf("Allocated 100 bytes at %p\n", ptr1);
    free(ptr1);
    
    // Test multiple allocations
    void* ptr2 = malloc(200);
    void* ptr3 = malloc(300);
    printf("Allocated 200 bytes at %p\n", ptr2);
    printf("Allocated 300 bytes at %p\n", ptr3);
    
    // Free in reverse order
    free(ptr3);
    free(ptr2);
    
    return 0;
} 
