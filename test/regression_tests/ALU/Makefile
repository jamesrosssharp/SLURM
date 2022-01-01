
SRCDIR=../../../src

SOURCE= $(SRCDIR)/alpha.v	\
$(SRCDIR)/alu.v				\
$(SRCDIR)/audio.v			\
$(SRCDIR)/background_controller2.v	\
$(SRCDIR)/background_controller.v	\
$(SRCDIR)/baudgen.v					\
$(SRCDIR)/bram_mask.v				\
$(SRCDIR)/bram.v					\
$(SRCDIR)/copper.v					\
$(SRCDIR)/fb_doubler.v				\
$(SRCDIR)/fb_scale.v				\
$(SRCDIR)/gfx_next.v				\
$(SRCDIR)/gpio.v					\
$(SRCDIR)/memory_arbiter.v			\
$(SRCDIR)/memory_controller_next.v	\
$(SRCDIR)/memory_next.v				\
$(SRCDIR)/mult.v					\
$(SRCDIR)/pipeline16_next.v			\
$(SRCDIR)/port_controller.v			\
$(SRCDIR)/pwm_led.v					\
$(SRCDIR)/register_file.v			\
$(SRCDIR)/rom.v						\
$(SRCDIR)/slurm16_next.v			\
$(SRCDIR)/spi_flash.v				\
$(SRCDIR)/sprite_controller.v		\
$(SRCDIR)/trace.v					\
$(SRCDIR)/uart_tx.v					\
$(SRCDIR)/uart.v

PROJECT=alu

all: sim

.PHONY: sim

AS=../../../slurmasm/slurmasm

rom_image.mem: Boot.asm
	$(AS) Boot.asm -o rom_image

mem_init2.mem: App.asm
	$(AS) App.asm -o mem_init2

sim:	dump.vcd

dump.vcd: $(SOURCE) $(PROJECT)_tb.v rom_image.mem mem_init2.mem
	iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design

view: dump.vcd config.gtkw
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm rom_image
	rm rom_image.mem
