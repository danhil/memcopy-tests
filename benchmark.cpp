#include <iostream>
#include <benchmark/benchmark.h>

// RDTSC read functions
extern "C" size_t RDTSCStart();
extern "C" size_t RDTSCStop();
// Naive memcopy
extern "C" void * naive_memcopy(void *desc, const void *src, size_t size);

// Non naive AVX/SSE memcopy
extern "C" void * memcopy(void *dest, const void *src, uint32_t size);

// Define another benchmark
static void BM_NaiveCopy(benchmark::State& state) {
  char* src = new char[state.range(0)];
  char* dst = new char[state.range(0)];
  memset(src, 'x', state.range(0));
  for (auto _ : state) {
    benchmark::DoNotOptimize(naive_memcopy(static_cast<void*>(dst), static_cast<const void*>(src), state.range(0)));
    state.SetBytesProcessed(int64_t(state.iterations()) *
                          int64_t(state.range(0)));
  }
  delete[] src;
  delete [] dst;
}
BENCHMARK(BM_NaiveCopy)->Range(4, 8<<10);

// Define another benchmark
static void BM_FastCopy(benchmark::State& state) {
  char* src = new char[state.range(0)];
  char* dst = new char[state.range(0)];
  memset(src, 'x', state.range(0));
  for (auto _ : state) {
    benchmark::DoNotOptimize(memcopy(static_cast<void*>(dst), static_cast<const void*>(src), state.range(0)));
    state.SetBytesProcessed(int64_t(state.iterations()) *
                          int64_t(state.range(0)));
  }
  delete[] src;
  delete [] dst;
}
BENCHMARK(BM_FastCopy)->Range(4, 8<<10);

// Define another benchmark
static void BM_NativeCopy(benchmark::State& state) {
  char* src = new char[state.range(0)];
  char* dst = new char[state.range(0)];
  memset(src, 'x', state.range(0));
  for (auto _ : state) {
    benchmark::DoNotOptimize(memcpy(static_cast<void*>(dst), static_cast<const void*>(src), state.range(0)));
    state.SetBytesProcessed(int64_t(state.iterations()) *
                          int64_t(state.range(0)));
  }
  delete[] src;
  delete [] dst;
}
BENCHMARK(BM_NativeCopy)->Range(4, 8<<10);
BENCHMARK_MAIN();