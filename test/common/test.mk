
all: sim

.PHONY: sim

AS=../../../slurmasm/slurmasm
MEMCONV=../../../scripts/genmem.py

IVERILOG_RUN=@iverilog -g2012 -pfileline=1  -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE) 2>&1 >sim_wrn.txt &&	\
			 vvp   -n $(PROJECT)_design 2>&1 >>sim_wrn.txt 
	
MEM_INIT=mem_init1.mem mem_init2.mem mem_init3.mem mem_init4.mem

rom_image.meminit: Boot.asm
	$(AS) Boot.asm -o rom_image
	python3 $(MEMCONV) rom_image rom_image.meminit
	cp rom_image.meminit rom_image.mem

%.mem: %.asm
	$(AS) $^ -o $(basename $@)
	python3 $(MEMCONV) $(basename $@) $@


sim: $(SOURCE) tb.v rom_image.meminit $(MEM_INIT)
	@rm -f simout.txt
	$(IVERILOG_RUN)
	@cat simout.txt
	@diff -q	simout.txt simout.correct || (echo "\n\n==============\nTEST FAILED :(\n==============\n\n"; exit 1)
	@echo "==============\nTEST PASSED!\n==============\n" 
	
dump.vcd: $(SOURCE) tb.v rom_image.meminit $(MEM_INIT)
	$(IVERILOG_RUN)

view: dump.vcd config.gtkw
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm -f $(PROJECT)_design
	rm -f dump.vcd
	rm -f rom_image
	rm -f rom_image.meminit
	rm -f rom_image.mem
	rm -f mem_init1
	rm -f mem_init1.mem
	rm -f mem_init2
	rm -f mem_init2.mem
	rm -f mem_init3
	rm -f mem_init3.mem
	rm -f mem_init4
	rm -f mem_init4.mem
	rm -f simout.txt
	rm -f sim_wrn.txt
