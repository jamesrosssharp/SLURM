

SRCDIR=../../../../src

include ../../../common/slurmsrc.mk

all: $(SOURCE)
	verilator --Wno-lint --cc --exe --build -I$(SRCDIR) -LDFLAGS "-lSDL2" --top-module slurm16 sim_main.cpp $(SOURCE)

