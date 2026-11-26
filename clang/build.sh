#!/bin/sh
# Build clang/LLVM with the SLURM16 backend, the SLURM tools, the simulator
# and the C/C++ runtime.
#
#   ./build.sh            fetch LLVM (if needed), patch, configure and build
#   JOBS=8 ./build.sh     override the number of parallel compile jobs
#
# Requirements: git, python3 (cmake and ninja are installed in a local venv if
# not found), a C++17 compiler, bison and flex.
set -e
TOP=$(cd "$(dirname "$0")" && pwd)
LLVM_BRANCH=release/21.x
JOBS=${JOBS:-4}
cd "$TOP"

# Build tools.
if ! command -v cmake > /dev/null || ! command -v ninja > /dev/null; then
  [ -x .venv/bin/cmake ] || { python3 -m venv .venv && .venv/bin/pip install -q cmake ninja; }
  PATH=$TOP/.venv/bin:$PATH
  export PATH
fi

# LLVM sources.
if [ ! -d llvm-project ]; then
  git clone --depth 1 --single-branch --branch $LLVM_BRANCH \
    https://github.com/llvm/llvm-project.git llvm-project
fi

# Link the SLURM16 sources into the LLVM tree and apply the registration
# patch (adds the slurm16 triple, the clang target and toolchain).
ln -sfn ../../../../llvm/lib/Target/Slurm16 llvm-project/llvm/lib/Target/Slurm16
for f in Slurm16.h Slurm16.cpp; do
  ln -sfn ../../../../../clang/lib/Basic/Targets/$f \
    llvm-project/clang/lib/Basic/Targets/$f
  ln -sfn ../../../../../clang/lib/Driver/ToolChains/$f \
    llvm-project/clang/lib/Driver/ToolChains/$f
done
if git -C llvm-project apply --check "$TOP/patches/llvm-project.patch" 2> /dev/null; then
  git -C llvm-project apply "$TOP/patches/llvm-project.patch"
elif ! git -C llvm-project apply --reverse --check "$TOP/patches/llvm-project.patch" 2> /dev/null; then
  echo "error: patches/llvm-project.patch does not apply" >&2
  exit 1
fi

# Configure and build LLVM + clang.
if [ ! -f build/build.ninja ]; then
  cmake -G Ninja -S llvm-project/llvm -B build \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_TARGETS_TO_BUILD=MSP430 \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Slurm16 \
    -DLLVM_DEFAULT_TARGET_TRIPLE=slurm16-unknown-none-elf \
    -DLLVM_PARALLEL_LINK_JOBS=1 -DLLVM_PARALLEL_COMPILE_JOBS=$JOBS \
    -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_DOCS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF -DCLANG_INCLUDE_DOCS=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF -DCLANG_ENABLE_ARCMT=OFF \
    -DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_BINDINGS=OFF
fi
ninja -C build -j "$JOBS" clang llc

# SLURM tools (assembler, linker) and the simulator, installed next to clang
# so the driver finds them.
"$TOP/scripts/build-slurm-tools.sh" "$TOP/build/slurm-tools"
cp build/slurm-tools/slurmasm-ng build/slurm-tools/slurmlink build/bin/
c++ -O2 -std=c++17 -o build/bin/slurm16-sim tools/slurm16-sim/slurm16-sim.cpp

# Runtime.
"$TOP/scripts/build-runtime.sh"

echo
echo "Done. Try:"
echo "  $TOP/build/bin/clang --target=slurm16 -O2 -o hello.elf hello.c"
echo "  $TOP/build/bin/slurm16-sim hello.elf"
