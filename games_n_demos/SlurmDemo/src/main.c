
#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

#include "printf.h"
#include "music.h"

volatile short flash_complete 	= 0;
volatile short vsync 		= 0;
volatile short audio 		= 0;

void enable_interrupts()
{
	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA | SLURM_INTERRUPT_AUDIO);
	global_interrupt_enable();
}

int main()
{

	my_printf("Hello world Slurm Demo!\n");

	enable_interrupts();
	init_music_player();

	while (1)
	{
		if (audio)
		{
			chip_tune_play();
			audio = 0;
		}
		__sleep();
	}

	return 0;
}
