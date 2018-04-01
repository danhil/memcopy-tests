.text
# parameters rdi rsi rdx rcx r8 r9 -> stack 
.global _naive_memcopy
_naive_memcopy:
  movq %rdi, %rax # destination is returned
  xorq %r10,%r10 # clear counter
  cmpq %rdx, %r10
  je return
loop:
  movb (%rsi, %r10), %r11B
  movb %r11B, (%rdi, %r10)
  incq %r10
  cmpq %rdx, %r10 
  jl loop
return:
  ret

 # %rax -> destination buffer
 # %rsi -> source buffer
 # %rdx length
.LTW: #less than word copy, length [0, 3]
        movzbl    (%rsi), %ecx #move byte zero extend
        movb      %cl, (%rax) #move lower ecx byte to dest, length is > 0 < 4
        add       $2, %edx #(length - 4) + 2 < 0 return;
        jnc       .LEND
        movzwl    (%rsi, %rdx), %ecx
        movw      %cx, (%rax, %rdx) #move last 2 bytes to destination
        ret $0

.LTQ: #less than quad copy, length [0, 7] 
    test      %rdx, %rdx #size == 0
    jz        .LEND
    sub       $4, %edx 
    jb        .LTW
    # Simple case, overlapping move of byte at src and src[max - 4]
    movl       (%rsi, %rdx), %edi #move src[rangemax-4] byte to edi
    movl       %esi, (%rax) #move first byte to dest
    movl       %edi, (%rax, %rdx) #move src[rangemax-4] to overlapping dst[rangemax-4]

.LEND:
    ret $0

#define __AVX__
# void * memcpy(void* destination (RDI), void* source (RSI), uint32_t length (RDX));
# We first handle the end operand in order to retreive even 32-byte chunks. Then we copy 32/64 byte chunks on each iteration
.align    16
.global    _memcopy
_memcopy:
    movq %rdi, %rax # destination is returned
    movq %rdx, %rcx # move length to rcx
    cmp $8, %rdx # check if length < 8 set CF if overflow
    jb .LTQ

    movq -8(%rsi, %rdx), %r8 # move the last byte to r8
    movq %r8, -8(%rdi, %rdx) # move the last source byte to last dest
    movq (%rsi), %r9 # move source ptr to r9
    and $24, %rcx #check what the remaining value is
    jz .L32 #value >= 32 bytes in even 32 byte chunks
    #have < 32 byte chunk, need to move 16 bytes indo dest 
    mov %r9, (%rdi)
    mov %rcx, %r8
    sub $16, %rcx # sets CF flag if overflow
    jb .LT32 # jump if CF flag is set
#ifndef __AVX__
    movdqu (%rsi, %rcx), %xmm1
    movdqu %xmm1, (%rdi, %rcx)
#else
    vmovdqu (%rsi, %rcx), %xmm1
    vmovdqu %xmm1, (%rdi, %rcx)
#endif

.LT32:
    add %r8, %rsi
    and $-32, %rdx
    jnz .L32AdjDest
    ret $0

.align 16
.L32AdjDest:
    add %r8, %rdi

.L32:
#ifndef __AVX__
// Move 32 byte chunks to rdi 
    movdqu (%rsi), %xmm0
    movdqu 16(%rsi), %xmm1
#else
    vmovdqu (%rsi), %ymm0 #load 32 bytes
#endif
    shr $6, %rdx #Shift out 64 bytes, CF contains last bit shifted _out_ of the destination operand
    jnc .L64Read32 #Larger than 32 bytes (32 was shifted out)
#ifndef __AVX__
    movdqu %xmm0, (%rdi)
    movdqu %xmm1, 16(%rdi)
#else
    vmovdqu %ymm0, (%rdi) #store 32 bytes
#endif
    lea 32(%rsi), %rsi
    jnz .L64_adjDI
#ifdef __AVX__
    vzeroupper
#endif
    ret $0

.L64_adjDI:
    add $32, %rdi

.L64:
#ifndef __AVX__
    movdqu (%rsi), %xmm0
    movdqu 16(%rsi), %xmm1
#else
    vmovdqu (%rsi), %ymm0
#endif

.L64Read32: #copy 64 byte chunks, upper 32 bytes preloaded
#ifndef __AVX__
    movdqu 32(%rsi), %xmm2
    movdqu 48(%rsi), %xmm3
    add $64, %rsi
    movdqu %xmm0, (%rdi)
    movdqu %xmm1, 16(%rdi)
    movdqu %xmm2, 32(%rdi)
    movdqu %xmm3, 48(%rdi)
#else
    vmovdqu 32(%rsi), %ymm1
    add $64, %rsi
    vmovdqu %ymm0, (%rdi)
    vmovdqu %ymm1, 32(%rdi)
#endif
    add $64, %rdi
    dec %rdx
    jnz .L64

#ifdef __AVX__
    vzeroupper
#endif
    ret $0