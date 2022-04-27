

SRCDIR=../../../../src

include ../../../common/slurmsrc.mk

all: obj_dir/Vslurm16

obj_dir/Vslurm16: $(SOURCE)
	verilator --Wno-lint --cc --exe --build -I$(SRCDIR) -LDFLAGS "-lSDL2" --top-module slurm16 sim_main.cpp $(SOURCE)

run: obj_dir/Vslurm16
	cd obj_dir && ./Vslurm16

