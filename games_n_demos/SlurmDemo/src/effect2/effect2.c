/*

	SlurmDemo : A demo to show off SlURM16

effect2.c : copper bars

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include "copper.h"
#include "rtos.h"
#include <slurminterrupt.h>

#include <applet.h>
#include <bundle.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_CODE_BASE);

#define COPPER_BAR_HEIGHT 16

struct copper_bar {
	short y;
	short vy;
	short x;
	short vx;
	short id;
};

struct copper_bar bar1 = {0, 0, 0, 0, 0};
struct copper_bar bar2 = {0, 0, 0, 0, 1};

short cpr_idx = 0;

unsigned short the_copper_list[512];

unsigned short bar1_colors[COPPER_BAR_HEIGHT] = {
	0x0000,	// 0
	0x0002, // 1
	0x0004, // 2
	0x0006, // 3
	0x0008, // 4
	0x000a, // 5
	0x000c, // 6
	0x000e, // 7
	0x000f, // 8
	0x000f, // 9
	0x022f, // 10
	0x0aaf, // 11
	0x0fff, // 12
	0x0aaf, // 13
	0x000a, // 14
	0x0004, // 15

};

unsigned short bar2_colors[COPPER_BAR_HEIGHT] = {
	0x0000,	// 0
	0x0200, // 1
	0x0400, // 2
	0x0600, // 3
	0x0800, // 4
	0x0a00, // 5
	0x0c00, // 6
	0x0e00, // 7
	0x0f00, // 8
	0x0f00, // 9
	0x0f22, // 10
	0x0faa, // 11
	0x0fff, // 12
	0x0aaf, // 13
	0x0a00, // 14
	0x0400, // 15

};

char sine_table[256] = {
          0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 16, 17, 19, 20, 22, 23,
         24, 26, 27, 29, 30, 32, 33, 34, 36, 37, 38, 39, 41, 42, 43, 44,
         45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56, 57, 58, 59,
         59, 60, 60, 61, 61, 62, 62, 62, 63, 63, 63, 64, 64, 64, 64, 64,
         64, 64, 64, 64, 64, 64, 63, 63, 63, 62, 62, 62, 61, 61, 60, 60,
         59, 59, 58, 57, 56, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46,
         45, 44, 43, 42, 41, 39, 38, 37, 36, 34, 33, 32, 30, 29, 27, 26,
         24, 23, 22, 20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2,
          0, -2, -3, -5, -6, -8, -9,-11,-12,-14,-16,-17,-19,-20,-22,-23,
        -24,-26,-27,-29,-30,-32,-33,-34,-36,-37,-38,-39,-41,-42,-43,-44,
        -45,-46,-47,-48,-49,-50,-51,-52,-53,-54,-55,-56,-56,-57,-58,-59,
        -59,-60,-60,-61,-61,-62,-62,-62,-63,-63,-63,-64,-64,-64,-64,-64,
        -64,-64,-64,-64,-64,-64,-63,-63,-63,-62,-62,-62,-61,-61,-60,-60,
        -59,-59,-58,-57,-56,-56,-55,-54,-53,-52,-51,-50,-49,-48,-47,-46,
        -45,-44,-43,-42,-41,-39,-38,-37,-36,-34,-33,-32,-30,-29,-27,-26,
        -24,-23,-22,-20,-19,-17,-16,-14,-12,-11, -9, -8, -6, -5, -3, -2,
};


int frame = 0;

void do_copper_bars()
{
	// Wait until bar1_y 
	int i;
	int j;
	
	struct copper_bar *b1;
	struct copper_bar *b2;
	unsigned short *b1_cols;
	unsigned short *b2_cols;
	unsigned short ov = 0;

	int h1 = COPPER_BAR_HEIGHT;
	int h2 = COPPER_BAR_HEIGHT;
	int st2 = 0;

	cpr_idx = 0;
	
	if (bar1.y > bar2.y)
	{
		// Blue bar lower down than red bar
		b1 = &bar2;
		b2 = &bar1;
		b1_cols = bar2_colors;
		b2_cols = bar1_colors;
	}
	else
	{
		// red bar lower than blue bar
		b1 = &bar1;
		b2 = &bar2;
		b1_cols = bar1_colors;
		b2_cols = bar2_colors;
	}

	// Check for overlap

	if (b1->y + COPPER_BAR_HEIGHT > b2->y)
	{
		if (b1->id == 0)
		{
			h1 = (b2->y - b1->y);
		}
		else
		{
			st2 = COPPER_BAR_HEIGHT - (b2->y - b1->y);
		}
		ov = 1;
	}

	the_copper_list[cpr_idx++] = COPPER_VWAIT(b1->y);

	for (i = 0; i < h1; i++)
	{
		if (b1->y + i > 260)
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(0x0000);
		else
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(b1_cols[i]);
		cpr_idx++;
	}

	if (!ov)
	{
		the_copper_list[cpr_idx++] = COPPER_VWAIT(b2->y);
	}

	for (j = st2; j < h2; j++)
	{
		if (b2->y + j > 260)
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(0x0000);
		else
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(b2_cols[j]);
		cpr_idx++;
	}

	the_copper_list[cpr_idx++] = COPPER_BG(0x000);
	the_copper_list[cpr_idx++] = COPPER_VWAIT(0xfff);

}

void do_vertical_copper_bars()
{
	int i;
	int j;
	
	unsigned short *b1_cols;
	unsigned short *b2_cols;
	struct copper_bar *b1;
	struct copper_bar *b2;
	
	int w1 = COPPER_BAR_HEIGHT;
	int w2 = COPPER_BAR_HEIGHT;
	int st2 = 0;
	int ov = 0;

	cpr_idx = 0;
	
	if (bar1.x > bar2.x)
	{
		// Blue bar lower down than red bar
		b1 = &bar2;
		b2 = &bar1;
		b1_cols = bar2_colors;
		b2_cols = bar1_colors;
	}
	else
	{
		// red bar lower than blue bar
		b1 = &bar1;
		b2 = &bar2;
		b1_cols = bar1_colors;
		b2_cols = bar2_colors;
	}

	// Check for overlap

	if (b1->x + COPPER_BAR_HEIGHT > b2->x)
	{
		if (b1->id == 0)
		{
			w1 = (b2->x - b1->x);
		}
		else
		{
			st2 = COPPER_BAR_HEIGHT - (b2->x - b1->x);
		}
		ov = 1;
	}

	the_copper_list[cpr_idx++] = 0x0000; 
	the_copper_list[cpr_idx++] = COPPER_HWAIT(b1->x);

	for (i = 0; i < w1; i++)
	{
		the_copper_list[cpr_idx++] = COPPER_BG(b1_cols[i]);
		the_copper_list[cpr_idx++] = COPPER_BG(b1_cols[i]);
	}	

	if (!ov)
	{
		the_copper_list[cpr_idx++] = COPPER_HWAIT(b2->x);
	}

	for (i = st2; i < w2; i++)
	{
		the_copper_list[cpr_idx++] = COPPER_BG(b2_cols[i]);
		the_copper_list[cpr_idx++] = COPPER_BG(b2_cols[i]);
	}	

	the_copper_list[cpr_idx++] = COPPER_BG(0x000);
	the_copper_list[cpr_idx++] = COPPER_HWAIT(399);
	the_copper_list[cpr_idx++] = COPPER_JUMP(0x001);

	//vtors->copper_list_load(the_copper_list, cpr_idx);
}

void do_sound_copper_bars()
{
	int i, j;

	cpr_idx = 0;

	the_copper_list[cpr_idx++] = COPPER_VWAIT(20);
	the_copper_list[cpr_idx++] = COPPER_BG(0x000);

	for (i = 0; i < 128; i++)
	{
		the_copper_list[cpr_idx++] = COPPER_HWAIT((((short)(vtors->__in(0x8000 + i*2) + vtors->__in(0x8100 + i*2))  >> 8) + 180) & 0xfff);
		the_copper_list[cpr_idx++] = COPPER_BG(0xfff);
		the_copper_list[cpr_idx++] = COPPER_BG_WAIT(bar1_colors[(i + frame) & 0xf]);
		the_copper_list[cpr_idx++] = COPPER_BG_WAIT(bar1_colors[(i + frame) & 0xf]);
	}
	
	the_copper_list[cpr_idx++] = COPPER_BG(0x000);
	the_copper_list[cpr_idx++] = COPPER_VWAIT(0xfff);

}

mutex_t eff2_mutex = RTOS_MUTEX_INITIALIZER;

#define TILES_ADDRESS_LO 0x8000
#define TILES_ADDRESS_HI 0x0001
#define TILES_WORD_ADDRESS 0xc000

#define BLOCKS_ADDRESS_LO 0x0000
#define BLOCKS_ADDRESS_HI 0x0001
#define BLOCKS_WORD_ADDRESS 0x8000

#define BLOCKS_FRAMEBUFFER_LO 0x4000
#define BLOCKS_FRAMEBUFFER_HI 0x0001
#define BLOCKS_FRAMEBUFFER_WORD_ADDRESS   0xa000



char scrollText[] = "How about some old skool raster bars      ";
int scroll_x_major = 64;
int scroll_x_minor = 0;
char *scrollText_ptr  = scrollText;

void update_scrolling_text()
{	
	

	scroll_x_minor --;
	
	if (scroll_x_minor < 0)
	{
		scroll_x_minor = 7;

		scroll_x_major--;
			
		if (scroll_x_major < 0)
		{
			scroll_x_major = 7;
			scrollText_ptr++;
		}


	}
	
}

int sinus = 0;

static void my_vsync_handler()
{
	vtors->copper_list_load(the_copper_list, cpr_idx);

	clear_fb(BLOCKS_FRAMEBUFFER_LO);
	blit_text(BLOCKS_FRAMEBUFFER_LO, TILES_ADDRESS_LO + 16384, scrollText_ptr, scroll_x_major - 8, 16, 8);

	vtors->background_set_x_y(0, 7 - scroll_x_minor, (sine_table[(sinus++ << 1) & 0xff] >> 1) + 32);
	vtors->background_update();

	vtors->rtos_unlock_mutex_from_isr(&eff2_mutex);
}

unsigned short bg_palette[16];

void blit_rect_clip(unsigned short fb_upper_lo, unsigned short x, unsigned short y, unsigned short from_upper_lo, unsigned short x_from, unsigned short y_from);



void blit_text(unsigned short fb_upper_lo, unsigned short text_upper_lo, const char* text, int x, int y, int n)
{
	char c;

	while (n--)
	{

		int idx;
		int xx;
		int yy;

		c = *text++;
	
		if (c >= 'a' && c <= 'z')
		{
			idx = c - 'a' + 10;
		} 
		else if (c >= 'A' && c <= 'Z')
		{
			idx = c - 'A' + 10;
		}
		else if (c >= '0' && c <= '9')
		{
			idx = c - '0';
		}
		else if (c == ' ')
		{
			x += 8;
			if (x > 64)
				break;
			continue;
		}

		xx = (idx * 8) & 0xff;
		yy = (((idx * 8) & 0x100) >> 8) * 8;

		blit_rect_clip(fb_upper_lo, x, y, text_upper_lo, xx, yy);

		x += 8;

		if (x >= 64)
			break;

	}
}

void clear_fb(unsigned short fb_upper_lo);


void main(void)
{
	int i, j;

	vtors->storage_load_synch(bg_tiles_flash_offset_lo, bg_tiles_flash_offset_hi, 0, 0, TILES_ADDRESS_LO, TILES_ADDRESS_HI, (bg_tiles_flash_size_lo>>1));
	vtors->storage_load_synch(blocks_pal_flash_offset_lo, blocks_pal_flash_offset_hi, 0, 0, (unsigned short)bg_palette, 0, (sizeof(bg_palette)>>1));

	vtors->load_palette(bg_palette, 0, 16);

	vtors->storage_load_synch(blocks_flash_offset_lo, blocks_flash_offset_hi, 0, 0, BLOCKS_ADDRESS_LO, BLOCKS_ADDRESS_HI, (blocks_flash_size_lo>>1));
	
	clear_fb(BLOCKS_FRAMEBUFFER_LO);

	vtors->background_set(0, 
		    1, 
		    0,
		    0, 
		    0, 
		    BLOCKS_FRAMEBUFFER_WORD_ADDRESS, 
		    BLOCKS_WORD_ADDRESS,
		    TILE_WIDTH_8X8,
		    TILE_MAP_STRIDE_64);

	vtors->background_update();

	//blit_text(BLOCKS_FRAMEBUFFER_LO, TILES_ADDRESS_LO + 16384, "Hello world!", 0, 10);

	// Add a vsync interrupt handler
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	bar1.y = 10;
	bar1.x = 10;
	bar1.vy = 3;
	bar1.vx = 3;

	bar2.y = 230;
	bar2.x = 310;
	bar2.vx = -2;
	bar2.vy = -2;

	do_copper_bars();
	vtors->copper_list_load(the_copper_list, cpr_idx);
	vtors->copper_set_alpha(0x8008);
	vtors->copper_control(1);

	while (frame < 1000)
	{

		unsigned short btns;
	
		vtors->rtos_lock_mutex(&eff2_mutex);
		
		do_copper_bars();
		
		frame++;
		
		if (frame < 64)
			vtors->pwm_set(0, 0, frame);

		btns = vtors->__in(0x1001);

		if (btns & 1)
			bar1.y++;
		if (btns & 2)
			bar1.y--;

		bar1.y += bar1.vy;
		bar2.y += bar2.vy;

		if (bar1.vy > 0 && bar1.y > 230)
			bar1.vy = -bar1.vy;
		if (bar1.vy < 0 && bar1.y < 10)
			bar1.vy = -bar1.vy;

		if (bar2.vy > 0 && bar2.y > 230)
			bar2.vy = -bar2.vy;
		if (bar2.vy < 0 && bar2.y < 10)
			bar2.vy = -bar2.vy;

		update_scrolling_text();

	}

	// Outtro

	while (bar1.y < 300)
	{
		frame++;

		vtors->rtos_lock_mutex(&eff2_mutex);

		do_copper_bars();
	
		if (bar1.y > 250)
			vtors->pwm_set(0, 0, 300 - bar1.y);

		bar1.y += 4;
		bar2.y -= 4;

		update_scrolling_text();

	}

	// Vertical copper bars

	frame = 0;

	while (frame < 1000)
	{
		unsigned short btns;

		vtors->rtos_lock_mutex(&eff2_mutex);

		do_vertical_copper_bars();
		
		frame++;
		
		btns = vtors->__in(0x1001);

		if (btns & 1)
			bar1.x++;
		if (btns & 2)
			bar1.x--;

		bar1.x += bar1.vx;
		bar2.x += bar2.vx;

		if (bar1.vx > 0 && bar1.x > 330)
			bar1.vx = -bar1.vx;
		if (bar1.vx < 0 && bar1.x < 30)
			bar1.vx = -bar1.vx;

		if (bar2.vx > 0 && bar2.x > 330)
			bar2.vx = -bar2.vx;
		if (bar2.vx < 0 && bar2.x < 30)
			bar2.vx = -bar2.vx;

		update_scrolling_text();
	}

	// Sound copper bars

	frame = 0;

	while (frame < 700)
	{
		frame++;
		vtors->rtos_lock_mutex(&eff2_mutex);

		do_sound_copper_bars();	

		update_scrolling_text();

	}

	vtors->pwm_set(0, 0, 0);

	vtors->copper_control(0);

	vtors->copper_set_alpha(0x0000);

	vtors->background_set(0, 
		    0, 
		    0,
		    0, 
		    0, 
		    BLOCKS_FRAMEBUFFER_WORD_ADDRESS, 
		    BLOCKS_WORD_ADDRESS,
		    TILE_WIDTH_8X8,
		    TILE_MAP_STRIDE_64);

	vtors->background_update();

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);
}


