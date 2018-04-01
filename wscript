#! /usr/bin/env python
# encoding: utf-8

VERSION='0.0.0'
APPNAME='dynamic-cast'

top = '.'
out = 'build'

def options(opt):
    opt.load('compiler_cxx')
    opt.load('gas')

def configure(conf):
    conf.load('compiler_cxx')
    conf.load('gas')
    # Google benchmark location
    import os
    conf.env.CXXFLAGS = ['-std=c++14', '-O3']
    conf.env.LIB_BENCHMARK = 'benchmark'
    conf.env.BENCHMARK_ROOT='/usr/local/Cellar/google-benchmark/1.3.0/'
    conf.env.LIBPATH_BENCHMARK = os.path.join(conf.env.BENCHMARK_ROOT, 'lib')
    conf.env.INCLUDES_BENCHMARK = os.path.join(conf.env.BENCHMARK_ROOT, 'include')

def build(bld):
    print(bld.env.LIBPATH_BENCHMARK)
    bld.read_stlib(bld.env.LIB_BENCHMARK, paths=[bld.env.LIBPATH_BENCHMARK], export_includes=[bld.env.INCLUDES_BENCHMARK])
    bld.objects(features='cxx asm',
        source = ['asm/memcopy.s', 'asm/rdtsc.s'],
        target = 'asmtest')
    bld.program(source=['benchmark.cpp'], use = ['asmtest', 'benchmark'], target='test')
