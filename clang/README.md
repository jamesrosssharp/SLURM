SLURM16 clang / LLVM backend
============================

A C and C++ compiler for the SLURM16 CPU (`src/slurm16_cpu_*.v`), built on
LLVM/clang 21. The compiler emits assembly in the dialect of `slurmasm-ng`;
`slurmasm-ng` assembles it and `slurmlink` links it, both driven by clang.

    clang --target=slurm16 -O2 -o game.elf main.c sprites.c   # compile + link
    clang --target=slurm16 -O2 -S foo.c                        # foo.s (slurmasm-ng syntax)
    clang --target=slurm16 -O2 -c foo.c                        # foo.o (via slurmasm-ng)
    clang++ --target=slurm16 -O2 -o app.elf app.cpp

Building
--------

    ./build.sh

This fetches LLVM 21 (`llvm-project/`, not checked in), links the sources in
this directory into it, applies `patches/llvm-project.patch`, then builds
clang, the SLURM tools, the simulator and the runtime into `build/`. A full
build takes a few hours on 4 cores. Set `JOBS` to change parallelism (each
compile job needs about 1 GB of RAM).

Running
-------

`build/bin/slurm16-sim` is a small headless instruction set simulator that
follows the HDL's semantics (including its flag quirks). UART writes (port
0x0000) and the trace port (0x6000 decimal / 0x6001 char / 0x6002 hex, as
`src/trace.v`) go to stdout; port 0x6006 or `sleep` ends the simulation, and
the exit code is `r2` (`main`'s return value). It starts at `_start` (or
`start`). `-t` traces every instruction.

    build/bin/slurm16-sim app.elf

The `.elf` files can also be turned into binaries with `slurm-objcopy` and
run on the emulator or hardware.

Tests
-----

    test/run-tests.sh

Every program in `test/` (a directory is one multi-file program) is built
for the host and for SLURM16 at `-O0 -O1 -O2 -Os`; the simulator output must
match the host output exactly
(integer arithmetic at 8/16/32/64 bits, soft-float, control flow, varargs,
structs by value, jump tables, C++ classes / virtual calls / templates /
static constructors / new and delete, ...).

Layout
------

| Path | Contents |
|------|----------|
| `llvm/lib/Target/Slurm16/` | The LLVM backend |
| `clang/lib/Basic/Targets/Slurm16.*` | clang target info (type sizes, macros) |
| `clang/lib/Driver/ToolChains/Slurm16.*` | clang driver toolchain (runs slurmasm-ng / slurmlink) |
| `patches/llvm-project.patch` | Registration of the above in LLVM / clang (triple, CMake, driver) |
| `runtime/` | crt0, default linker script, mini libc, C++ ABI support |
| `tools/slurm16-sim/` | Instruction set simulator used by the tests |
| `scripts/` | Out of tree build of slurmasm-ng / slurmlink, runtime build |
| `test/` | Differential test programs |

Target summary
--------------

Data model: `char` 8 bits (signed), `short`/`int` 16, `long` 32, `long long`
64, pointers 16, `float` 32 and `double` 64 (IEEE, software emulated). The
maximum alignment of any type is 2 bytes. `size_t` is `unsigned int`.

Calling convention (compatible with the lcc `slurm16_ng` port, so existing
assembly routines like `putc(r4)` can be called directly):

| Register | Use |
|----------|-----|
| r0 | always zero |
| r1 - r9 | caller saved; r4 - r7 hold the first four 16 bit argument words |
| r2 (r2:r3, r2-r5) | return value (16, 32, 64 bit) |
| r10 - r12 | callee saved (r12 is the frame pointer when one is needed) |
| r13 | stack pointer |
| r14 | interrupt link register - never used by compiled code |
| r15 | link register (saved by non-leaf functions) |

Wider values are split into little-endian 16 bit words. Arguments that do
not fit in r4-r7 go on the stack at `[sp + 0]`, `[sp + 2]`, ...; variadic
functions receive all their arguments on the stack. Structures are passed
and returned via memory.

Code generation notes:

* Constant shifts use `lsl`/`lsr`/`asr` for 1 bit, and the hardware
  multiplier otherwise (`x << n` = `mul x, 2^n`, `x >> n` = `umulu x,
  2^(16-n)` / `mulu`); variable shifts become a short loop.
* 32/64-bit integer arithmetic uses the carry flag (`adc`/`sbb`) and the
  high-half multiplies (`umulu`); division and soft-float are runtime calls.
* Comparisons always use `cmp` (the HDL computes the sign flag of `xor`
  incorrectly, and the logic ops leave V unchanged).
* Conditional moves / three register conditional ALU ops are not used: the
  HDL pipeline does not interlock the flags for them.
* Symbols that clash with slurmasm-ng keywords (e.g. a C variable called
  `add`, `r1`, `x12` or `beefh`) are emitted as `_S16_<name>`.
* Each function is wrapped in `.function`/`.endfunc`, so slurmlink can drop
  unused functions.

Runtime (`runtime/`, installed into `build/slurm16/`):

* `crt0.o`: installs the vector table at 0, sets up the stack, zeroes
  `.bss`, runs static constructors, calls `main`, then `_exit`.
  Interrupt handlers can be provided (in assembly) by defining
  `__slurm16_irq_vsync`, `__slurm16_irq_hsync`, `__slurm16_irq_audio`, ...
* `slurm16.ld`: default linker script (use `-T script.ld` to replace it).
* `include/`: `slurm16.h` (`__in`, `__out`, `__sleep`, interrupt enable,
  upper bank access), `string.h`, `stdlib.h`, `stdio.h` (UART `printf`),
  `assert.h`; clang's own freestanding headers (`stdint.h`, `stdarg.h`, ...)
  are also available.
* `lib/rt/*.o`: `memcpy`/`memset`/..., `malloc`/`free`, `printf`, 16-bit
  division and 32-bit shift helpers, the C++ ABI bits (`operator new`,
  `__cxa_pure_virtual`, guards) and compiler-rt's integer and soft-float
  builtins. slurmlink has no archive support, so the driver passes all of
  these objects and the linker discards unused sections.

Existing code
-------------

Because the calling convention matches the lcc port, clang-compiled C can be
mixed with the existing assembly and linker scripts. For example
`test/emulator_tests/001_C_COMPARISONS` builds with its own `top.asm` and
`link.ld` (after replacing the lcc-specific `<stdarg.h>` it pastes in with
the standard one) and produces the expected output.

slurmlink notes
---------------

Two slurmlink behaviours affect compiled code:

* Input sections are concatenated without honouring their alignment. The
  compiler therefore pads every section it emits to an even size, so data
  always starts on a word boundary. Hand written assembly that puts an odd
  number of bytes in a section must do the same (`.align 2` at the end).
* Weak symbols: C++ inline functions, templates and vtables are emitted as
  weak definitions in every object that uses them. This needs the slurmlink
  in this repository from the same change as this backend, which keeps the
  first of several weak definitions, sees references to weak symbols in its
  section garbage collection, and no longer crashes when a weak symbol is
  referenced more than once. With an older slurmlink, pass
  `-mllvm -slurm16-weak-symbols=false` to emit weak definitions as plain
  globals (fine as long as each is defined in only one object file).

Limitations
-----------

* C++ exceptions and RTTI are off by default (no unwinder); there is no C++
  standard library.
* No debug information (`-g` is accepted, the debug sections are dropped).
* Atomics are lowered to `__atomic_*` library calls, which the runtime does
  not provide.
* Data symbol aliases are not supported (function aliases are, as branch
  trampolines).
* The upper 64 kB memory bank and the extended registers (x16-x127) are only
  reachable through inline assembly / the `slurm16.h` helpers.
