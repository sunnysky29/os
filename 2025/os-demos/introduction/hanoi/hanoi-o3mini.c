// Author: o3-mini

#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int n;      // 当前盘数
    char from;  // 源座
    char aux;   // 辅助座
    char to;    // 目标座
    int stage;  // 执行阶段：0表示还未进行左递归调用，1表示左递归返回等待搬盘，2表示右递归调用结束，整个帧结束
} Frame;

#define STACK_SIZE 1000
Frame stack[STACK_SIZE];
int top = -1;

void push(Frame frame) {
    if(top < STACK_SIZE - 1)
        stack[++top] = frame;
    else {
        fprintf(stderr, "Stack overflow!\n");
        exit(1);
    }
}

Frame pop() {
    if(top >= 0)
        return stack[top--];
    else {
        fprintf(stderr, "Stack underflow!\n");
        exit(1);
    }
}

int isEmpty() {
    return top == -1;
}

void move(char from, char to) {
    printf("Move disk from %c to %c\n", from, to);
}

void hanoi(int n, char from, char aux, char to) {
    // 推入初始帧
    Frame init = { n, from, aux, to, 0 };
    push(init);
    
    while(!isEmpty()) {
        // 查看栈顶帧
        Frame *current = &stack[top];

        if(current->n == 1 && current->stage == 0) {
            // 基本情况：只有1个盘直接搬动
            move(current->from, current->to);
            pop();  // 完成当前帧处理
        }
        else if(current->stage == 0) {
            // 第一次进入帧，先模拟调用左递归 hanoi(n-1, from, to, aux)
            current->stage = 1; // 标记已进入左递归阶段
            Frame leftFrame = { current->n - 1, current->from, current->to, current->aux, 0 };
            push(leftFrame);
        }
        else if(current->stage == 1) {
            // 左递归返回，现在进行“搬盘”
            move(current->from, current->to);
            current->stage = 2; // 标记已经搬盘
            // 模拟右递归 hanoi(n-1, aux, from, to)
            Frame rightFrame = { current->n - 1, current->aux, current->from, current->to, 0 };
            push(rightFrame);
        }
        else { // current->stage == 2
            // 右递归处理完毕，退出当前帧
            pop();
        }
    }
}

int main() {
    int n = 3;  // 例如3个盘
    hanoi(n, 'A', 'B', 'C');
    return 0;
}
