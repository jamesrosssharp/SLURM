
#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

extern void load_copper_list(short* list, int len);
extern void load_palette(short* palette, int offset, int len);

#define COUNT_OF(x) ((sizeof(x)) / (sizeof(x[0])))

short copperList[] = {
		0x6000,
		0x6f00,
		0x7007,
		0x60f0,
		0x7007,
		0x600f,
		0x7007,
		0x60ff,
		0x7007,
		0x4200,
		0x1001,
		0x2fff		 
};



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
extern short Snare;
extern short ClosedHihat;

struct sample g_samples[4] = {
	{
		// Kick drum
		(char*)&Bassdrum,
		1,
		0,
		22050,
		0,
		9468,
		9468
	},
	{
		(char*)&Snare,
		1,
		0,
		8000,
		0,
		0,
		9258
	},
	{
		(char*)&ClosedHihat,
		1,
		0,
		11000,
		0,
		0,
		4670
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

void play_sample(short freq, short SAMPLE)
{

	//#define SAMPLE 0
	//#define CHANNEL 0
	//#define CHANNEL2 4
	int channels[] = {1, 4, 2};

	int CHANNEL = channels[SAMPLE];

	//for (CHANNEL = 0; CHANNEL < 4; CHANNEL += 2)
	//{

	//if (channel_info[CHANNEL].frequency)
	//	return;

	channel_info[CHANNEL].sample_start = g_samples[SAMPLE].offset;
	channel_info[CHANNEL].sample_end   = g_samples[SAMPLE].offset + g_samples[SAMPLE].sample_len;

	channel_info[CHANNEL].loop_start = g_samples[SAMPLE].offset + g_samples[SAMPLE].loop_start;
	channel_info[CHANNEL].loop_end   = g_samples[SAMPLE].offset + g_samples[SAMPLE].loop_end;

	channel_info[CHANNEL].sample_pos = g_samples[SAMPLE].offset;
	channel_info[CHANNEL].frequency = freq; //g_samples[SAMPLE].speed;	

	//g_samples[SAMPLE].speed += 1000;

	//my_printf("Speed: %d\r\n", g_samples[SAMPLE].speed);

	channel_info[CHANNEL].phase = 0;

	channel_info[CHANNEL].volume = 63;
	channel_info[CHANNEL].loop   = g_samples[SAMPLE].loop;	
	channel_info[CHANNEL].bits   = g_samples[SAMPLE].bit_depth + 1; // 1 = 8 bit, 2 = 16 bit

	//}

}

void init_audio()
{
	int i;

	// Clear audio buffer and enable


	for (i = 0; i < 512; i++)
	{		__out(0x3000 | i, 0);
			__out(0x3200 | i, 0);
	}
	__out(0x3400, 1);

}


#define UP_KEY 1
#define DOWN_KEY 2
#define LEFT_KEY 4
#define RIGHT_KEY 8
#define A_KEY 16
#define B_KEY 32



int main()
{
	int count = 0;
	short old_keys = 0;
	short frame = 0;

	load_copper_list(copperList, COUNT_OF(copperList));
	__out(0x5d20, 1);



	enable_interrupts();

	//play_sample(22050);
	init_audio();

	while(1)
	{

		short keys =  __in(0x1001);
	


		if ((keys & UP_KEY) && ((keys ^ old_keys) & UP_KEY)) play_sample(24000, 0);
		if ((keys & DOWN_KEY) && ((keys ^ old_keys) & DOWN_KEY)) play_sample(22000, 0);
		if ((keys & LEFT_KEY) && ((keys ^ old_keys) & LEFT_KEY)) play_sample(20000, 1);
		if ((keys & RIGHT_KEY) && ((keys ^ old_keys) & RIGHT_KEY)) play_sample(10000, 1);
		if ((keys & A_KEY) && ((keys ^ old_keys) & A_KEY)) play_sample(8000, 2);
		if ((keys & B_KEY) && ((keys ^ old_keys) & B_KEY)) play_sample(11000, 2);

		old_keys = keys;

		//my_printf("Interrupt!");
		if (vsync)
		{
			//vsync = 0;
			//count += 1;
			//if (count == 4)
			//{
				frame++;
			//	count = 0;
			//}
		}
		copperList[0] = 0x7000 | (frame & 31);
		load_copper_list(copperList, COUNT_OF(copperList));
	

		__sleep();
	}
}
