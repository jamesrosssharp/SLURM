
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

volatile short flash_complete = 0;
volatile short vsync = 0;



struct slurmsng_header sng_hdr;
struct slurmsng_playlist pl_hdr;

struct playlist {
	short pl_len;
	char* pl;
};

struct playlist pl;

char* sample_offsets[16];

extern short calculate_flash_offset_hi(short base_lo, short base_hi, short offset_lo, short offset_hi);
extern short calculate_flash_offset_lo(short base_lo, short base_hi, short offset_lo, short offset_hi);
extern void  add_offset(short* base_lo, short* base_hi, short offset_lo, short offset_hi);

extern char music_heap;
extern char pattern_A;
extern char pattern_B;

#define MUSIC_HEAP_SIZE_BYTES 24*1024

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
	char *heap = &music_heap;
	int i;
	int heap_offset = 0;
	short offset_lo = 0;
	short offset_hi = 0;

	my_printf("Hello world! %d\n", 22);		

	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, 0, 0, (void*)&sng_hdr, sizeof(sng_hdr) / sizeof(short));

	my_printf("Playlist len: %d\n", sng_hdr.playlist_size);

	offset_lo = sng_hdr.pl_offset_lo;
	offset_hi = sng_hdr.pl_offset_hi;

	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, (void*)&pl_hdr, sizeof(pl_hdr) / sizeof(short));

	my_printf("Playlist chunk len: %d\n", pl_hdr.chunklen);

	add_offset(&offset_lo, &offset_hi, 4, 0);
		
	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, heap, pl_hdr.chunklen >> 1);

	for (i = 0; i < sng_hdr.playlist_size; i++)
		my_printf("Pl %d: %d\n", i, heap[i]);


	pl.pl_len = sng_hdr.playlist_size;
	pl.pl = (char*) heap; 

	heap += pl_hdr.chunklen;

	my_printf("Num samples: %d\n", sng_hdr.num_samples);

	offset_lo = sng_hdr.sample_offset_lo;
	offset_hi = sng_hdr.sample_offset_hi;

	for (i = 0; i < sng_hdr.num_samples; i++)
	{
		struct slurmsng_sample samp;
		do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, (void*)&samp, sizeof(struct slurmsng_sample) / sizeof(short));
		my_printf("Magic: %c%c Sample: %d len: %d\n", samp.magic[0], samp.magic[1], i, samp.sample_len);

		add_offset(&offset_lo, &offset_hi, samp.sample_len + sizeof(struct slurmsng_sample), 0);
		
	}

}

int main()
{
//	enable_interrupts();
	load_slurm_sng();
	
	while(1);
}
