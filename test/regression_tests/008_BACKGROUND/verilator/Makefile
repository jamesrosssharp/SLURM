

SRCDIR=../../../../src

include ../../../common/slurmsrc.mk

all: obj_dir/Vslurm16

obj_dir/Vslurm16: $(SOURCE) sim_main.cpp
	verilator --Wno-lint --cc --exe --build -I$(SRCDIR) -LDFLAGS "-lSDL2" --top-module slurm16 sim_main.cpp $(SOURCE)

run: obj_dir/Vslurm16 obj_dir/mem_init1.mem obj_dir/mem_init2.mem obj_dir/mem_init3.mem obj_dir/mem_init4.mem obj_dir/rom_image.mem
	cd obj_dir && ./Vslurm16

obj_dir/mem_init1.mem: ../mem_init1
	dd if=../mem_init1 of=obj_dir/mem_init1 bs=32768 count=1
	python3 ../../../../scripts/genmem.py obj_dir/mem_init1 obj_dir/mem_init1.mem

obj_dir/mem_init2.mem: ../mem_init2
	dd if=../mem_init2 of=obj_dir/mem_init2 bs=32768 count=1
	python3 ../../../../scripts/genmem.py obj_dir/mem_init2 obj_dir/mem_init2.mem

obj_dir/mem_init3.mem: ../mem_init3
	dd if=../mem_init3 of=obj_dir/mem_init3 bs=32768 count=1
	python3 ../../../../scripts/genmem.py obj_dir/mem_init3 obj_dir/mem_init3.mem

obj_dir/mem_init4.mem: ../mem_init4
	dd if=../mem_init4 of=obj_dir/mem_init4 bs=32768 count=1
	python3 ../../../../scripts/genmem.py obj_dir/mem_init4 obj_dir/mem_init4.mem

obj_dir/rom_image.mem: ../rom_image.mem
	cp ../rom_image.mem obj_dir/
