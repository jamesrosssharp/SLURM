
SRCDIR=../../../src

include ../../common/slurmsrc.mk

PROJECT=pocman

include ../../common/test.mk

CC=../../../slurmcc/lcc/lcc/build/rcc

GAME_BIN=../../../games_n_demos/PoCman/build/pocman.bin

mem_init1.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init1 bs=1 count=32256 seek=512
	python3 ../../../scripts/genmem.py mem_init1 mem_init1.mem

mem_init2.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init2 bs=1 count=32768 skip=32256
	python3 ../../../scripts/genmem.py mem_init2 mem_init2.mem

mem_init3.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init3 bs=1 count=32768 skip=65024
	python3 ../../../scripts/genmem.py mem_init3 mem_init3.mem

mem_init4.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init4 bs=1 count=32768 skip=97792
	python3 ../../../scripts/genmem.py mem_init4 mem_init4.mem

clean:
	rm -f $(PROJECT)_design
#	rm main.c1
#	rm main.asm
#	rm mem_init1.asm
	rm -f mem_init1.mem
	rm -f mem_init1
	rm -f mem_init2.mem
	rm -f mem_init2
	rm -f mem_init3.mem
	rm -f mem_init3
	rm -f mem_init4.mem
	rm -f mem_init4
	rm -f dump.vcd
	rm -f rom_image.meminit
	rm -f rom_image.mem

