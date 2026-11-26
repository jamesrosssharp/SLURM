# clang.mk: toolchain settings for building SlurmOS programs with the clang
# SLURM16 backend (see clang/README.md).
#
# Requires clang/build.sh to have been run. Set CLANG_BUILD to use a build
# somewhere else.

SLURM_TOP   := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)
CLANG_BUILD ?= $(SLURM_TOP)/clang/build

CC      = $(CLANG_BUILD)/bin/clang
AS      = $(CLANG_BUILD)/bin/slurmasm-ng
LD      = $(CLANG_BUILD)/bin/slurmlink
CPP     = cpp
OBJCOPY = $(SLURM_TOP)/slurm-objcopy/slurm-objcopy
OBJDUMP = $(SLURM_TOP)/slurm-objdump/slurm-objdump

# -nostdlibinc: SlurmOS provides its own headers (printf.h, malloc.h, ...);
# clang's freestanding headers (stdarg.h, stdint.h, ...) remain available.
CFLAGS ?= -Os
CFLAGS += --target=slurm16 -ffreestanding -nostdlibinc -Wno-unused-value

# Compiler support routines from the clang SLURM16 runtime: division, wide
# shifts, soft float (compiler-rt) and memcpy / memset. The runtime's C
# library (printf, malloc, exit, ...) is not used: SlurmOS has its own.
CLANG_RT      = $(CLANG_BUILD)/slurm16/lib/rt
CLANG_RT_OBJS = $(CLANG_RT)/libgcc16.o $(CLANG_RT)/string.o \
                $(wildcard $(CLANG_RT)/crt_*.o)
