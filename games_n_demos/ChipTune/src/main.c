
#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

#include <bundle.h>

#include "printf.cc"

void enable_interrupts()
{
	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA | SLURM_INTERRUPT_AUDIO);
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

// This struct shadows struct slurmsng_sample 
struct sample {
	char* offset;
	char bit_depth;
	char loop;
	unsigned short speed;
	unsigned short loop_start;
	unsigned short loop_end;
	unsigned short sample_len;
};

struct sample g_samples[16];

extern short calculate_flash_offset_hi(short base_lo, short base_hi, short offset_lo, short offset_hi);
extern short calculate_flash_offset_lo(short base_lo, short base_hi, short offset_lo, short offset_hi);
extern void  add_offset(short* base_lo, short* base_hi, short offset_lo, short offset_hi);

extern char music_heap;
extern char pattern_A;
extern char pattern_B;

struct channel_t {
	char* sample_start;
	char* sample_end;

	char* loop_start;
	char* loop_end;

	char* sample_pos;
	short frequency;	// 0 = channel off

	short phase;

	char  volume;
	char  loop;	// 1 = loop, 0 = no loop
	char  bits;	// 1 = 16 bit, 0 = 8 bit
	char  pad;
};


extern struct channel_t channel_info[]; 

#define MUSIC_HEAP_SIZE_BYTES 24*1024

void do_flash_dma(short base_lo, short base_hi, short offset_lo, short offset_hi, void* address, short count)
{
	short lo = calculate_flash_offset_lo(base_lo, base_hi, offset_lo, offset_hi);
	short hi = calculate_flash_offset_hi(base_lo, base_hi, offset_lo, offset_hi);

	my_printf("Offset hi: %x\r\n", hi);
	my_printf("Offset lo: %x\r\n", lo);
	my_printf("address: %x count: %d\r\n", address, count);

	__out(SPI_FLASH_ADDR_LO, lo);
	__out(SPI_FLASH_ADDR_HI, hi);
	__out(SPI_FLASH_DMA_ADDR, (unsigned short)address >> 1);
	__out(SPI_FLASH_DMA_COUNT, count);
	
	flash_complete = 0;
	__out(SPI_FLASH_CMD, 1);

	while (!flash_complete)
		__sleep();
}

short my_add(short a, short b)
{
	return a + b;
}

int load_slurm_sng()
{
	char *data;
	char *heap = &music_heap;
	char *heap_end = &music_heap + MUSIC_HEAP_SIZE_BYTES;
	int i;
	int heap_offset = 0;
	short offset_lo = 0;
	short offset_hi = 0;

	my_printf("Hello world! %d\r\n", 22);		

	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, 0, 0, (void*)&sng_hdr, sizeof(sng_hdr) / sizeof(short));

	my_printf("Playlist offset lo: %x hi: %x\r\n", sng_hdr.pl_offset_lo, sng_hdr.pl_offset_hi);
	my_printf("Playlist len: %d\r\n", sng_hdr.playlist_size);

	offset_lo = sng_hdr.pl_offset_lo;
	offset_hi = sng_hdr.pl_offset_hi;

	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, (void*)&pl_hdr, sizeof(pl_hdr) / sizeof(short));

	my_printf("Playlist chunk len: %d\r\n", pl_hdr.chunklen);

	add_offset(&offset_lo, &offset_hi, 4, 0);

	my_printf("Heap: %x\n", heap);

	do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, heap, pl_hdr.chunklen >> 1);

	for (i = 0; i < sng_hdr.playlist_size; i++)
		my_printf("Pl %d: %d\r\n", i, heap[i]);


	pl.pl_len = sng_hdr.playlist_size;
	pl.pl = (char*) heap; 

	// This hack is to work around lcc getting kids in wrong order
	// such that the addition is corrupted
	heap = (char*)my_add((short)pl_hdr.chunklen,(short)heap);

	my_printf("Num samples: %d\r\n", sng_hdr.num_samples);

	offset_lo = sng_hdr.sample_offset_lo;
	offset_hi = sng_hdr.sample_offset_hi;

	for (i = 0; i < sng_hdr.num_samples; i++)
	{
		struct sample* samp = (struct sample*)&g_samples[i];
		do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, (void*)samp, sizeof(struct slurmsng_sample) / sizeof(short));
		my_printf("Sample: %d len: %d\r\n", i, samp->sample_len);

		add_offset(&offset_lo, &offset_hi, sizeof(struct slurmsng_sample), 0);
	
		if ((unsigned short)(heap + samp->sample_len) > (unsigned short)heap_end)
		{
			my_printf("Samples too large! %x %x %x\r\n", heap, (heap + samp->sample_len), heap_end);
			return -1;
		}

		samp->offset = heap;

		do_flash_dma(chiptune_rom_offset_lo, chiptune_rom_offset_hi, offset_lo, offset_hi, (void*)heap, samp->sample_len >> 1);

		heap = (char*)my_add((short)heap, (short)samp->sample_len);

		add_offset(&offset_lo, &offset_hi, samp->sample_len, 0);
	}

	my_printf("Loaded %d bytes of samples. \r\n", heap - &music_heap);

	return 0;

}

void play_sample()
{

	#define SAMPLE 1

	channel_info[0].sample_start = g_samples[SAMPLE].offset;
	channel_info[0].sample_end   = g_samples[SAMPLE].offset + g_samples[SAMPLE].sample_len;

	channel_info[0].loop_start = g_samples[SAMPLE].offset + g_samples[SAMPLE].loop_start;
	channel_info[0].loop_end   = g_samples[SAMPLE].offset + g_samples[SAMPLE].loop_end;

	channel_info[0].sample_pos = g_samples[SAMPLE].offset;
	channel_info[0].frequency = g_samples[SAMPLE].speed;	

	channel_info[0].phase = 0;

	channel_info[0].volume = 64;
	channel_info[0].loop   = g_samples[SAMPLE].loop;	
	channel_info[0].bits   = g_samples[SAMPLE].bit_depth + 1; // 1 = 8 bit, 2 = 16 bit

}

void init_audio()
{
	int i;

	// Clear audio buffer and enable

	play_sample();

	for (i = 0; i < 512; i++)
	{		__out(0x3000 | i, 0);
			__out(0x3200 | i, 0);
	}
	__out(0x3400, 1);

}

int main()
{
	int count = 0;
	
	enable_interrupts();
	load_slurm_sng();

	init_audio();

	while(1)
	{
		if (vsync)
		{
			vsync = 0;
			count += 1;
			if (count == 50)
			{
				play_sample();
				count = 0;
			}
		}

		__sleep();
		my_printf("Interrupt!");
	}
}
