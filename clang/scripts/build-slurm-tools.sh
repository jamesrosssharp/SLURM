#!/bin/sh
# Build slurmasm-ng and slurmlink out of tree (without touching the generated
# files checked into their source directories).
set -e
TOP=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${1:-$TOP/clang/build/slurm-tools}
mkdir -p "$OUT/asm" "$OUT/link"

cd "$OUT/asm"
bison -d -o slurmasm-ng.tab.c "$TOP/slurmasm-ng/slurmasm-ng.y"
flex -o lex.yy.c "$TOP/slurmasm-ng/slurmasm-ng.lex"
g++ -O2 -std=c++11 -w -include cstdint -I"$TOP/slurmasm-ng" -I"$TOP/common" -I. \
  slurmasm-ng.tab.c lex.yy.c \
  "$TOP"/slurmasm-ng/AST.cpp "$TOP"/slurmasm-ng/SymbolTable.cpp \
  "$TOP"/slurmasm-ng/Statement.cpp "$TOP"/slurmasm-ng/Expression.cpp \
  "$TOP"/slurmasm-ng/OpCode.cpp "$TOP"/slurmasm-ng/Assembly.cpp \
  "$TOP"/slurmasm-ng/Relocation.cpp "$TOP"/slurmasm-ng/RelocationTable.cpp \
  "$TOP"/common/host/ELF/ElfFile.cpp "$TOP"/slurmasm-ng/Cond.cpp \
  "$TOP"/slurmasm-ng/PseudoOp.cpp "$TOP"/slurmasm-ng/ExReg.cpp \
  -lfl -o "$OUT/slurmasm-ng"

cd "$OUT/link"
bison -d -o slurmlink.tab.c "$TOP/slurmlink/slurmlink.y"
flex -o lex.yy.c "$TOP/slurmlink/slurmlink.lex"
g++ -O2 -std=c++17 -w -include cstdint -I"$TOP/slurmlink" -I"$TOP/common" -I. \
  slurmlink.tab.c lex.yy.c \
  $(for f in AST Expression MemoryStatement Assignment SectionsStatement \
      SectionBlockStatement SectionBlockStatementSectionList Linker LinkerMemory; \
    do echo "$TOP/slurmlink/$f.cpp"; done) \
  "$TOP"/common/host/ELF/ElfFile.cpp -lfl -o "$OUT/slurmlink"
echo "Built $OUT/slurmasm-ng and $OUT/slurmlink"
