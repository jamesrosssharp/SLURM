
volatile short flash_complete = 0;
volatile short vsync = 0;

#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

#include <bundle.h>

#include "printf.cc"

void enable_interrupts()
{
	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA);
	global_interrupt_enable();
}

struct slurmsng_header sng_hdr;

extern short calculate_flash_offset_hi(short base_lo, short base_hi, short offset_lo, short offset_hi);
extern short calculate_flash_offset_lo(short base_lo, short base_hi, short offset_lo, short offset_hi);

void do_flash_dma(short base_lo, short base_hi, short offset_lo, short offset_hi, void* address, short count)
{
	short lo = calculate_flash_offset_lo(base_lo, base_hi, offset_lo, offset_hi);
	short hi = calculate_flash_offset_hi(base_lo, base_hi, offset_lo, offset_hi);

	my_printf("Offset hi: %x\n", hi);
	my_printf("Offset lo: %x\n", lo);
	my_printf("address: %x count: %d\n", address, count);

	__out(SPI_FLASH_ADDR_LO, lo);
	__out(SPI_FLASH_ADDR_HI, hi);
	__out(SPI_FLASH_DMA_ADDR, (unsigned short)address >> 1);
	__out(SPI_FLASH_DMA_COUNT, count);
	
	flash_complete = 0;
	__out(SPI_FLASH_CMD, 1);

	while (!flash_complete)
		__sleep();
}

void load_slurm_sng()
{
	char *data;
	int i;

	my_printf("Hello world! %d\n", 22);		

	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, 0, 0, (void*)&sng_hdr, sizeof(sng_hdr) / sizeof(short));

	my_printf("Num samples: %d\n", sng_hdr.num_samples);

}

int main()
{
//	enable_interrupts();
	load_slurm_sng();
	
	while(1);
}
