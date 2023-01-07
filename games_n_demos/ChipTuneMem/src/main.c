
#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

#include <bundle.h>

#include "printf.cc"

#define MIX_CHANNELS 8

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



unsigned short note_table_hi[] = {
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	1,	1,	1,	1,	1,	1,	1,	1,	1,	1,	1,	1,
	2,	2,	2,	2,	2,	2,	2,	2,	3,	3,	3,	3,
	4,	4,	4,	4,	5,	5,	5,	5,	6,	6,	7,	7,
	8,	8,	8,	9,	10,	10,	11,	11,	12,	13,	14,	15
};

unsigned short note_table_lo[] = {
	2004,	2130,	2255,	2380,	2506,	2631,	2882,	3007,	3132,	3383,	3633,	3759,
	4009,	4260,	4511,	4761,	5137,	5388,	5764,	6140,	6390,	6891,	7267,	7643,
	8145,	8646,	9147,	9648,	10275,	10901,	11528,	12280,	12906,	13783,	14535,	15412,
	16290,	17292,	18294,	19422,	20550,	21803,	23181,	24560,	25938,	27567,	29196,	30825,
	32705,	34710,	36715,	38970,	41226,	43732,	46238,	49120,	52002,	55135,	58393,	61776,
	0,	3884,	8019,	12405,	17041,	21928,	27066,	32580,	38469,	44734,	51250,	58142,
	0,	7769,	16039,	24810,	34083,	43857,	54258,	65285,	11528,	23933,	36965,	50874,
	125,	15663,	32204,	49747,	2756,	22304,	43105,	65160,	23056,	47867,	8520,	36339,
	250,	31326,	64408,	33958,	5513,	44734,	20801,	64909,	46113,	30199,	17041,	7142
};

void enable_interrupts()
{
	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA | SLURM_INTERRUPT_AUDIO);
	global_interrupt_enable();
}

volatile short flash_complete 	= 0;
volatile short vsync 		= 0;
volatile short audio 		= 0;

struct slurmsng_header 		*sng_hdr;
struct slurmsng_playlist 	*pl_hdr;

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

struct sample* g_samples[16];

struct channel_t {
	char* loop_start;
	char* loop_end;

	char* sample_pos;
	short frequency;	// 0 = channel off
	short frequency_hi;	

	short phase;
	short phase_hi;

	short  volume;

	char   effect;
	char   param;
	char   base_note;
	char   note_deviation;  // fine note slide in 4.4 format
	short  volume_effect;
	char   sample;
	char   pad;
	
};

extern struct channel_t channel_info[]; 

short my_add(short a, short b)
{
	return a + b;
}

extern char song_data;

char *patterns[2];

int load_slurm_sng()
{
	int i;
	struct sample* samp;
	char *pattern;

	sng_hdr = (struct slurmsng_header*)&song_data; 
	
	//my_printf("Playlist offset lo: %x hi: %x\r\n", sng_hdr->pl_offset_lo, sng_hdr->pl_offset_hi);
	//my_printf("Playlist len: %d\r\n", sng_hdr->playlist_size);

	// Get playlist

	pl_hdr = (struct slurmsng_playlist*)((char*)&song_data + sng_hdr->pl_offset_lo);

	//my_printf("Playlist chunk len: %d\r\n", pl_hdr->chunklen);

	pl.pl_len = sng_hdr->playlist_size;
	pl.pl = (char*) pl_hdr + 4; 

	//my_printf("Playlist offset: %x\r\n", pl.pl);

	// Get samples

	//my_printf("Num samples: %d\r\n", sng_hdr->num_samples);
	
	samp =  (struct sample*)((char*)&song_data + sng_hdr->sample_offset_lo);
 	
	for (i = 0; i < sng_hdr->num_samples; i++)
	{
		g_samples[i] = samp;
		//my_printf("Sample %d: %x %d\r\n", i, g_samples[i], samp->sample_len);
		
		g_samples[i]->offset = (char*)(samp + 1);
		samp = (struct sample*)(((char*)(samp + 1)) + samp->sample_len);
	}

	// Get patterns

	pattern = ((char*)&song_data + sng_hdr->pattern_offset_lo + 4);

	for (i = 0; i < 2; i++)
	{
		patterns[i] = pattern;
		//my_printf("Pattern: %d %x\n", i, pattern);
		pattern += 64*8*4;
	}

	return 0;
}

short note_mul_asm(short lo, short hi, short c5speed);
short note_mul_asm_hi(short lo, short hi, short c5speed);

void play_sample(short channel, short volume, short note_lo, short note_hi, short SAMPLE, char effect, char param, char note)
{


	if (g_samples[SAMPLE]->loop != 0)
	{
		channel_info[channel].loop_start = g_samples[SAMPLE]->offset + g_samples[SAMPLE]->loop_start;
		channel_info[channel].loop_end   = g_samples[SAMPLE]->offset + g_samples[SAMPLE]->loop_end;
	}
	else
	{
		channel_info[channel].loop_start = g_samples[SAMPLE]->offset + g_samples[SAMPLE]->sample_len;
		channel_info[channel].loop_end   = g_samples[SAMPLE]->offset + g_samples[SAMPLE]->sample_len;
	}

	channel_info[channel].sample_pos = g_samples[SAMPLE]->offset;
	channel_info[channel].frequency  = note_mul_asm(note_lo, note_hi, g_samples[SAMPLE]->speed);	
	channel_info[channel].frequency_hi = note_mul_asm_hi(note_lo, note_hi, g_samples[SAMPLE]->speed);	
	channel_info[channel].phase = 0;

	channel_info[channel].effect = effect;
	channel_info[channel].param = param;

	channel_info[channel].base_note = note;

	channel_info[channel].sample = SAMPLE;

	if (volume < 64)
	{
		channel_info[channel].volume = volume >> 1;
	}
}

void arpeggiate(short tick, int channel)
{
	short dev = 0;
	short sample = channel_info[channel].sample;
	short note_hi, note_lo;

	if (tick == 1 || tick == 3)
	{
		dev = ((channel_info[channel].param & 0xf0) >> 4);
	}
	else if (tick == 2)
	{
		dev = (channel_info[channel].param & 0xf);
	}

	dev += channel_info[channel].base_note;

	note_lo = note_table_lo[dev];
	note_hi = note_table_hi[dev];

	channel_info[channel].frequency  = note_mul_asm(note_lo, note_hi, g_samples[sample]->speed);	
	channel_info[channel].frequency_hi = note_mul_asm_hi(note_lo, note_hi, g_samples[sample]->speed);	
	
}

void update_tick(short tick)
{
	int i = 0;

	for (i = 0; i < MIX_CHANNELS; i++)
	{
		switch (channel_info[i].effect)
		{
			case 2:	/* arpeggio */
				arpeggiate(tick & 3, i);
				break;			
			default: 
				break;
		}
	}		
	
}

void set_volume(short channel, short volume)
{
	if (volume < 64)
	{
		channel_info[channel].volume = volume >> 1;
	}
	
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

short frame = 0;

void do_vsync()
{

	frame++;
	vsync = 0;
	copperList[0] = 0x7000 | (frame & 31);
	load_copper_list(copperList, COUNT_OF(copperList));
	
}

short channels[] = {0,1,2,3,4,5,6,7};

int main()
{
	int i;
	int count = 4;
	int row = 0;
	int cur_patt_buf = 0;
	int ord = 2;

	__out(0x5d20, 1);
	
	enable_interrupts();
	load_slurm_sng();

	for (i = 0; i < MIX_CHANNELS; i++)
		play_sample(i, 0, 0, 0, 0, 0, 0, 0);

	init_audio();

	i = 0;
	
	while(1)
	{
		if (audio)
		{
			char* row_offset;
			int i;

			count += 1;
			if (count == 5)
			{

				row_offset = (cur_patt_buf ? patterns[1] : patterns[0]) + row*32;	


				for (i = 0; i < MIX_CHANNELS; i++)
				{
					char note;
					char volume;
					char sample;
					char effect;
					char effect_param;	

					note = *row_offset++;
					volume = *row_offset++;			
					sample = *row_offset++;
					effect = sample & 0xf;
					sample >>= 4;
					effect_param = *row_offset++;
			
					if (note)
					{
						short note_lo, note_hi;
						note --;

						note_lo = note_table_lo[note];
						note_hi = note_table_hi[note];

						play_sample(channels[i], volume, note_lo, note_hi, --sample, effect, effect_param, note);
					
					}
					else
						set_volume(channels[i], volume);
				}

				row += 1;	
				if (row == 64)
				{
					char pattern;
					short offset_lo;
					short offset_hi;
					int i;

					cur_patt_buf = !cur_patt_buf;
					row = 0;

				}
				count = 0;
			}
			else
			{
				update_tick(count);
			}

			audio = 0;
	
			//print_channel_ptrs();
			mix_audio_2();


		}

		__sleep();
	}
}
