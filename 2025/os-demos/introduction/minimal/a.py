




# a= input('输入：')

# print(f'{a} ???')


# for i  in  a[::-1]:
#     print(f'i: {i} ???')




# for i  in  a[::-2]:
#     print(f'i: {i} ???')


# b= [1,2,3,4,5,6,7,8,9,10,11]
# for j in b[::2]: 
#     print(j)
    


a = [1,2,40]
def sd(a):
    a.append('d')

sd(a)
print(a)

d = {}
value = d.get('key', 0)  # 如果 'key' 不存在，返回 0
print(d, "???")




# while True:
#     try:

#         line=input()
#         a=0
#         b=0
#         c=0
#         d=0
#         flag=True
#         for i in line:
#             if i.isdigit():
#                 a=1
#             elif i.islower():
#                 b=1
#             elif i.isupper():
#                 c=1
#             else:
#                 d=1
#         for j in range(len(line)-2):
#             print(f'j: {j} ???')
#             tmp =line[j:j+3]
#             print(f'tmp: {tmp} ???')
            
#             if line.count(tmp)>1:
#                 flag=False
#         if len(line)>8 and (a+b+c+d)>=3 and flag:
#             print("OK")
#         else:
#             print("NG")
#     except:
#         break


# while 1:
#     pass
#     s = input()
#     count_dic = {}
#     min_ = float('inf')
    
#     for i in s:
#         count_dic[i] =  count_dic.get(i, 0) +1
    
#     min_ = min(count_dic.values())
#     print(f'min: {min_} ???, {count_dic.values()}')
    
#     res = ''
#     for i in s:
#         if count_dic[i]>min_:
#             res += i 
    
#     print(count_dic, res)
    


# a = ['s', '2', 576]
# for i in a[::-1]:
#     print(i, '???')
    
# while True:
#     try:
#         size = int(input())
#         numbers = list(map(int, input().strip().split() ))
#         flag = input()
#         if flag == '0':
#             numbers.sort()
#         else:
#             numbers.sort(reverse=True)
#         print(numbers, '???')
#         print(' '.join(numbers))
#     except:
#         break

# a = [1 ,2 ,6, 2, 5, 9 ,1 ]
# a.sort()
# print(f'a: {a} \n ????')



# while True:
#     try:
#         s = list(input())
#         len_ = len(s)
        
#         l = 0
#         r= len_ -1
#         while l<r:
#             s[l],s[r] = s[r],s[l]
#             l +=  1
#             r -=  1
#         print(''.join(s))        
            
            
        
#     except:
#         break

# import sys

# for line in sys.stdin:
#     a = line.split()
#     print(a, "???")


# num = int(input())
# words = [input().strip() for _ in range(num)]
# print(f'words: {words} ???')
# words.sort()


def quick_sort(arr):
    # 如果数组长度小于等于1，直接返回（递归终止条件）
    if len(arr) <= 1:
        return arr
    
    # 选择基准值（pivot），这里选择中间元素作为基准
    pivot = arr[len(arr) // 2]
    
    # 将数组分为三部分：小于基准、等于基准和大于基准的部分
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    
    # 递归排序左右两部分，然后合并结果
    return quick_sort(left) + middle + quick_sort(right)

# 测试代码

arr = [3, 6, 8, 10, 1, 2, 1]
print("原始数组:", arr)
sorted_arr = quick_sort(arr)
print("排序后数组:", sorted_arr)


from typing import List

# Definition of Interval class
class Interval:
    def __init__(self, a=0, b=0):
        self.start = a
        self.end = b

    def __repr__(self):
        return f"[{self.start} --- {self.end}]"

# Solution class with merge method
class Solution:
    def merge(self, intervals: List[Interval]) -> List[Interval]:
        if not intervals:
            return []

        # Sort intervals based on the start value
        intervals.sort(key=lambda x: x.start)
        print(f'intervals: {intervals} ？？？')
        
        res = [intervals[0]]

        for interval in intervals[1:]:
            last = res[-1]
            if interval.start > last.end:
                # No overlap, add as new interval
                res.append(interval)
            else:
                # Overlap exists, merge the intervals
                last.end = max(last.end, interval.end)

        return res

# Main test code
if __name__ == "__main__":
    # Test case 1
    intervals1 = [
        Interval(80, 100),
        Interval(10, 30),
        Interval(20, 60),
        Interval(150, 180)
    ]
    
    # Test case 2
    intervals2 = [
        Interval(0, 10),
        Interval(10, 20)
    ]

    sol = Solution()

    print("Test Case 1 Output:")
    merged1 = sol.merge(intervals1)
    for interval in merged1:
        print(interval, end=' ')
    print()

    print("Test Case 2 Output:")
    merged2 = sol.merge(intervals2)
    for interval in merged2:
        print(interval, end=' ')
    print()
    
a = ['2', '3', 55, 'rt4']
a.pop(2)
print(a, '????')