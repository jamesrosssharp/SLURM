
all: boot_memory.v

boot_memory.v: rom_image.mem
	python3 ../../../scripts/genrom.py

rom_image.mem: boot.bin
	python3 ../../../scripts/genmem.py $< $@

boot.bin: Bootloader.asm
	../../../slurmasm/slurmasm $< -o $@

clean:
	rm -rf boot_memory.v boot.bin rom_image.mem
