

SRCDIR=../../../../src

include ../../../common/slurmsrc.mk

all: $(SOURCE)
	verilator --Wno-lint --cc --exe --build -I$(SRCDIR) --top-module tb sim_main.cpp tb.v $(SOURCE)

