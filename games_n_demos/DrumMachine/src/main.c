
#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>


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

extern short Bassdrum;

struct sample g_samples[4] = {
	{
		// Kick drum
		(char*)&Bassdrum,
		1,
		0,
		22050,
		0,
		0,
		9468
	}
};

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

void play_sample()
{

	#define SAMPLE 0

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

	//for (i = 0; i < 512; i++)
	//{		__out(0x3000 | i, 0);
	//		__out(0x3200 | i, 0);
	//}
	__out(0x3400, 1);

}

int main()
{
	int count = 0;
	
	enable_interrupts();

	init_audio();

	while(1)
	{
	/*	if (vsync)
		{
			vsync = 0;
			count += 1;
			if (count == 50)
			{
				play_sample();
				count = 0;
			}
		}
	*/

		__sleep();
		//my_printf("Interrupt!");
	}
}
