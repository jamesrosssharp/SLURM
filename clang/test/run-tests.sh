#!/bin/sh
# Differential tests: each program is built natively with the host compiler
# and for SLURM16 with clang (at several optimization levels); the outputs
# printed by the simulator must match the host outputs exactly.
#
# Usage: test/run-tests.sh [test names...]
TOP=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD:-$TOP/build}
CLANG=$BUILD/bin/clang
SIM=${SIM:-$BUILD/bin/slurm16-sim}
OUT=$BUILD/test-output
OPTS=${OPTS:-"-O0 -O1 -O2 -Os"}
mkdir -p "$OUT"

tests=$*
[ -z "$tests" ] && tests=$(cd "$TOP/test" && ls -d *.c *.cpp */)

pass=0
fail=0
for t in $tests; do
  t=${t%/}
  src=$TOP/test/$t
  base=${t%.*}
  # A directory is one program made of all the sources in it.
  [ -d "$src" ] && src=$(ls "$src"/*.c "$src"/*.cpp 2>/dev/null)
  case $t in
    *.cpp|*-cxx) hostcc="c++ -std=c++17"; tcc="$CLANG++ -std=c++17" ;;
    *) hostcc="cc -std=c11"; tcc="$CLANG -std=c11" ;;
  esac
  if ! $hostcc -O1 -w -o "$OUT/$base.host" $src; then
    echo "FAIL $t (host build)"
    fail=$((fail + 1))
    continue
  fi
  "$OUT/$base.host" > "$OUT/$base.expected"
  for o in $OPTS; do
    name="$base$o"
    if ! $tcc --target=slurm16 $o -o "$OUT/$name.elf" $src \
        > "$OUT/$name.build.log" 2>&1; then
      echo "FAIL $t $o (build, see $OUT/$name.build.log)"
      fail=$((fail + 1))
      continue
    fi
    "$SIM" "$OUT/$name.elf" > "$OUT/$name.out" 2> "$OUT/$name.err"
    status=$?
    if [ $status -ne 0 ] || ! cmp -s "$OUT/$name.out" "$OUT/$base.expected"; then
      echo "FAIL $t $o (exit $status, diff $OUT/$name.out $OUT/$base.expected)"
      fail=$((fail + 1))
    else
      echo "PASS $t $o"
      pass=$((pass + 1))
    fi
  done
done
echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
