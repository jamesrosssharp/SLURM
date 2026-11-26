SlurmDemo
=========

A demo to show off some of SLURM16's features. 

Effect 1 - sprite and background scrolling

Effect 2 - Raster bars + alpha text scrolling

Effect 3 - Plasma

Effect 4 - 3D flat shaded torus

Effect 5 - Raycasting demo

Effect 6 - Tunnel

Effect 7 - Star field with tie fighters ?

Effect 8 - Voxel landscape ? Or voxel procedural water?

Effect 9 - Mandel zoomer ?

Effect 10 - procedural fire ?


Building
--------

The demo is built with the clang SLURM16 toolchain (see `clang/README.md`;
run `clang/build.sh` first):

    make build/applet_bundle.h   # builds the six effect applets
    make                         # builds build/slurm_demo.bin

The toolchain settings are in `common/clang.mk`, which `common/slurmos/slurmos.mk`
includes. Assembly routines follow the clang calling convention: arguments in
r4-r7 then on the stack at [sp + 0], [sp + 2], ...; r10-r12 and r15 are
preserved across calls, r1-r9 are not.

Run it in the emulator (from the `slurmemu-ng` directory):

    build/slurmemu-ng ../games_n_demos/bootloader/build/bootloader.bin \
        ../games_n_demos/SlurmDemo/build/slurm_demo.bin \
        ../games_n_demos/SlurmDemo/build/slurm_demo.elf
