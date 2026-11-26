#!/bin/sh
# Build and install the SLURM16 C/C++ runtime with the freshly built clang.
#
# Installs into <build>/slurm16 (found by the driver as <clang dir>/../slurm16):
#   include/         slurm16.h and a minimal C library interface
#   lib/crt0.o       start up code
#   lib/slurm16.ld   default linker script
#   lib/rt/*.o       runtime library objects (libc subset, C++ ABI support,
#                    integer and soft-float helpers from compiler-rt)
set -e
TOP=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD:-$TOP/build}
CLANG=$BUILD/bin/clang
AS=$BUILD/bin/slurmasm-ng
PREFIX=$BUILD/slurm16
CRT=$TOP/llvm-project/compiler-rt/lib/builtins

mkdir -p "$PREFIX/include" "$PREFIX/lib/rt"
rm -f "$PREFIX"/lib/rt/*.o
cp "$TOP"/runtime/include/*.h "$PREFIX/include/"
cp "$TOP/runtime/src/slurm16.ld" "$PREFIX/lib/"

"$AS" -o "$PREFIX/lib/crt0.o" "$TOP/runtime/src/crt0.asm" > /dev/null

CFLAGS="--target=slurm16 -O2 -ffreestanding -fno-builtin -Wall -Wno-unused"

for f in string stdio stdlib libgcc16; do
  "$CLANG" $CFLAGS -c "$TOP/runtime/src/$f.c" -o "$PREFIX/lib/rt/$f.o"
done
"$CLANG" $CFLAGS -fno-exceptions -fno-rtti -c "$TOP/runtime/src/cxxrt.cpp" \
  -o "$PREFIX/lib/rt/cxxrt.o"

# Generic compiler-rt builtins.
CRT_SOURCES="
  divsi3 udivsi3 modsi3 umodsi3 divmodsi4 udivmodsi4
  divdi3 udivdi3 moddi3 umoddi3 divmoddi4 udivmoddi4
  muldi3 ashldi3 ashrdi3 lshrdi3 negdi2 cmpdi2 ucmpdi2
  clzsi2 ctzsi2 clzdi2 ctzdi2 popcountsi2 popcountdi2
  paritysi2 paritydi2 ffssi2 ffsdi2 bswapsi2 bswapdi2
  mulosi4 mulodi4 absvsi2 absvdi2 addvsi3 addvdi3 subvsi3 subvdi3
  mulvsi3 mulvdi3 negvsi2 negvdi2
  addsf3 subsf3 mulsf3 divsf3 negsf2 comparesf2
  adddf3 subdf3 muldf3 divdf3 negdf2 comparedf2
  extendsfdf2 truncdfsf2
  fixsfsi fixunssfsi fixsfdi fixunssfdi
  fixdfsi fixunsdfsi fixdfdi fixunsdfdi
  floatsisf floatunsisf floatdisf floatundisf
  floatsidf floatunsidf floatdidf floatundidf
  powisf2 powidf2 fp_mode
"
for f in $CRT_SOURCES; do
  "$CLANG" $CFLAGS -w -I"$CRT" -c "$CRT/$f.c" -o "$PREFIX/lib/rt/crt_$f.o"
done

echo "SLURM16 runtime installed in $PREFIX"
