compiler_opt.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <spin_1>:
   0:	f3 0f 1e fa          	endbr64 
   4:	c3                   	ret    
   5:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
   c:	00 00 00 00 

0000000000000010 <spin_2>:
  10:	f3 0f 1e fa          	endbr64 
  14:	c7 44 24 fc 00 00 00 	movl   $0x0,-0x4(%rsp)
  1b:	00 
  1c:	8b 44 24 fc          	mov    -0x4(%rsp),%eax
  20:	83 f8 63             	cmp    $0x63,%eax
  23:	7f 17                	jg     3c <spin_2+0x2c>
  25:	0f 1f 00             	nopl   (%rax)
  28:	8b 44 24 fc          	mov    -0x4(%rsp),%eax
  2c:	83 c0 01             	add    $0x1,%eax
  2f:	89 44 24 fc          	mov    %eax,-0x4(%rsp)
  33:	8b 44 24 fc          	mov    -0x4(%rsp),%eax
  37:	83 f8 63             	cmp    $0x63,%eax
  3a:	7e ec                	jle    28 <spin_2+0x18>
  3c:	c3                   	ret    
  3d:	0f 1f 00             	nopl   (%rax)

0000000000000040 <return_1>:
  40:	f3 0f 1e fa          	endbr64 
  44:	b8 64 00 00 00       	mov    $0x64,%eax
  49:	41 b8 01 00 00 00    	mov    $0x1,%r8d
  4f:	90                   	nop
  50:	83 e8 01             	sub    $0x1,%eax
  53:	75 fb                	jne    50 <return_1+0x10>
  55:	44 89 c0             	mov    %r8d,%eax
  58:	c3                   	ret    
  59:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000000060 <return_1_volatile>:
  60:	f3 0f 1e fa          	endbr64 
  64:	b8 64 00 00 00       	mov    $0x64,%eax
  69:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
  70:	41 b8 01 00 00 00    	mov    $0x1,%r8d
  76:	83 e8 01             	sub    $0x1,%eax
  79:	75 f5                	jne    70 <return_1_volatile+0x10>
  7b:	44 89 c0             	mov    %r8d,%eax
  7e:	c3                   	ret    
  7f:	90                   	nop

0000000000000080 <foo>:
  80:	f3 0f 1e fa          	endbr64 
  84:	c7 07 01 00 00 00    	movl   $0x1,(%rdi)
  8a:	b8 01 00 00 00       	mov    $0x1,%eax
  8f:	c3                   	ret    

0000000000000090 <foo_func_call>:
  90:	f3 0f 1e fa          	endbr64 
  94:	53                   	push   %rbx
  95:	31 c0                	xor    %eax,%eax
  97:	48 89 fb             	mov    %rdi,%rbx
  9a:	c7 07 01 00 00 00    	movl   $0x1,(%rdi)
  a0:	e8 00 00 00 00       	call   a5 <foo_func_call+0x15>
  a5:	c7 03 01 00 00 00    	movl   $0x1,(%rbx)
  ab:	b8 01 00 00 00       	mov    $0x1,%eax
  b0:	5b                   	pop    %rbx
  b1:	c3                   	ret    
  b2:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
  b9:	00 00 00 00 
  bd:	0f 1f 00             	nopl   (%rax)

00000000000000c0 <foo_volatile1>:
  c0:	f3 0f 1e fa          	endbr64 
  c4:	c7 07 01 00 00 00    	movl   $0x1,(%rdi)
  ca:	c7 07 01 00 00 00    	movl   $0x1,(%rdi)
  d0:	8b 07                	mov    (%rdi),%eax
  d2:	c3                   	ret    
  d3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
  da:	00 00 00 00 
  de:	66 90                	xchg   %ax,%ax

00000000000000e0 <foo_volatile2>:
  e0:	f3 0f 1e fa          	endbr64 
  e4:	48 89 7c 24 f8       	mov    %rdi,-0x8(%rsp)
  e9:	48 8b 44 24 f8       	mov    -0x8(%rsp),%rax
  ee:	c7 00 01 00 00 00    	movl   $0x1,(%rax)
  f4:	48 8b 44 24 f8       	mov    -0x8(%rsp),%rax
  f9:	c7 00 01 00 00 00    	movl   $0x1,(%rax)
  ff:	48 8b 44 24 f8       	mov    -0x8(%rsp),%rax
 104:	8b 00                	mov    (%rax),%eax
 106:	c3                   	ret    
 107:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
 10e:	00 00 

0000000000000110 <foo_barrier>:
 110:	f3 0f 1e fa          	endbr64 
 114:	c7 07 01 00 00 00    	movl   $0x1,(%rdi)
 11a:	b8 01 00 00 00       	mov    $0x1,%eax
 11f:	c7 07 01 00 00 00    	movl   $0x1,(%rdi)
 125:	c3                   	ret    
