Games and demos
===============

All the games and demos are built with the clang SLURM16 toolchain (see
`clang/README.md`; run `clang/build.sh` first). In each directory:

    make          # builds build/<name>.bin, the flash image
    make dump     # disassembles the program

Run a flash image in the emulator (from the `slurmemu-ng` directory):

    build/slurmemu-ng ../games_n_demos/bootloader/build/bootloader.bin \
        ../games_n_demos/<Project>/build/<name>.bin ../games_n_demos/<Project>/build/<name>.elf

SlurmDemo uses SlurmOS (`common/slurmos`). The other projects share:

| File | Purpose |
|------|---------|
| `game.mk` | build rules: compile `src/*.c`, assemble `src/*.asm`, link, make the flash image |
| `game.ld` | linker script: program at 0x200 (where the boot loader puts it), `hidata` (graphics, samples, buffers) at 0x8000 |
| `include/game_io.h` | the routines in each project's `top.asm` / `interrupt.asm` (`putc`, `__in`, `__out`, `__sleep`, ...) |
| `legacy-asm.py` | converts assembly in the old `slurmasm` format (as written by the asset generators) for `slurmasm-ng` at build time |

Assembly routines called from C follow the clang calling convention:
arguments in r4-r7 then on the stack at [sp + 0], [sp + 2], ...; the result
in r2; r10-r12 and r15 must be preserved, r1-r9 may be clobbered.
Interrupt handlers that call C must therefore save r1-r9 and r15 (and the
flags).
