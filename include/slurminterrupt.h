
/* Interrupt bitmask definitions */

#define SLURM_INTERRUPT_HSYNC_IDX		0
#define SLURM_INTERRUPT_VSYNC_IDX		1
#define SLURM_INTERRUPT_AUDIO_IDX		2
#define SLURM_INTERRUPT_FLASH_DMA_IDX		3

// We should define one in terms of the other but lcc is
// not smart enough to evaluate at compile time (?)

#define SLURM_INTERRUPT_HSYNC		1
#define SLURM_INTERRUPT_VSYNC		2
#define SLURM_INTERRUPT_AUDIO		4
#define SLURM_INTERRUPT_FLASH_DMA	8

#define NUM_SLURM_INTERRUPTS		16

