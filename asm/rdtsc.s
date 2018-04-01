.text

.global _RDTSCStart
_RDTSCStart:
  push %rbx
  xor %rax, %rax
  cpuid #full memory barrier, serializes, clobbers rax, rbx, rcx, rdx
  rdtsc #measure
  pop %rbx
  shl $32, %rdx
  # Move the high-order 32 bits into rax
  or %rdx, %rax
  ret $0

.global _RDTSCStop
_RDTSCStop:
  rdtscp #read ts counter, forces retirement of all preceding instructions
  shl $32, %rdx
  push %rbx
  push %rdx
  push %rax
  xor %rax, %rax #clear rax for cpuid call
  cpuid #full memory barrier, serializes, clobbers rax, rbx, rcx, rdx
  pop %rax #restore registers
  pop %rdx
  pop %rbx
  or %rdx, %rax
  ret $0