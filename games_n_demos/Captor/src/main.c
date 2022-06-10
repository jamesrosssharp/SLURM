
#define COUNT_OF(x) (sizeof(x)/sizeof(x[0]))

extern void load_bl_copper_list(void);
extern void update_bl_copper_list(void);
extern void load_palette(short* palette, int offset, int len);

extern short bloodlust_copper_list;
extern short bloodlust_sprites_palette;
extern short bloodlust_tiles_palette;
extern short ace1_palette;
extern short ace2_palette;

extern short bg1_tilemap;
extern short bg2_tilemap;

#define MAKE_SPRITE_X(x, en, pal, stride) (((x) & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y) ((y & 0x3ff))
#define MAKE_SPRITE_A(a) (a)

extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

struct Sprite {
	short enabled;
	short i; /* sprite index */
	short x;
	short y;
	short vx;
	short vy;
	short frame;
	unsigned short frames[4];
	unsigned short width[4];
	unsigned short height[4];
	short xofs[4];
};

struct Sprite sprites[] =  {
	{ /* Player plane */
		1,
		0,
		320,
		240,
		0,
		0,
		0,
		{6, 47, 6, 47},
		{34,34,34,34},
		{36,36,36,36},
		{0,0,0,0},
	},
	{ /* Enemy barrel-roll plane */
		1,
		1,
		320,
		40,
		0,
		1,
		0,
		{14 + 37*64, 38 + 77*64, 14 + 37*64, 38 + 77*64},
		{34,34,34,34},
		{40,40,40,40},
		{0,0,0,0},
	},
	{ /* Health bar below 1 */
		1,
		2,
		400 + 100,
		33,
		0,
		0,
		0,
		{118*64, 118*64, 118*64, 118*64},
		{64,64,64,64},
		{27,27,27,27},
		{0,0,0,0},
	},
	{ /* Health bar below 2 */
		1,
		3,
		464 + 100,
		33,
		0,
		0,
		0,
		{118*64 + 16, 118*64 + 16, 118*64 + 16, 118*64 + 16},
		{64,64,64,64},
		{27,27,27,27},
		{0,0,0,0},
	},
	{ /* Health bar below 3 */
		1,
		4,
		528 + 100,
		33,
		0,
		0,
		0,
		{118*64 + 32, 118*64 + 32, 118*64 + 32, 118*64 + 32},
		{34,34,34,34},
		{27,27,27,27},
		{0,0,0,0},
	},
	{ /* Health bar above 1 */
		1,
		5,
		400 + 100,
		33,
		0,
		0,
		0,
		{145*64, 145*64, 145*64, 145*64},
		{64,64,64,64},
		{27,27,27,27},
		{0,0,0,0},
	},
	{ /* Health bar above 2 */
		1,
		6,
		464 + 100,
		33,
		0,
		0,
		0,
		{145*64 + 16, 145*64 + 16, 145*64 + 16, 145*64 + 16},
		{64,64,64,64},
		{27,27,27,27},
		{0,0,0,0},
	},
	{ /* Health bar above 3 */
		1,
		7,
		528 + 100,
		33,
		0,
		0,
		0,
		{145*64 + 32, 145*64 + 32, 145*64 + 32, 145*64 + 32},
		{1,8,16,31},
		{27,27,27,27},
		{0,0,0,0},
	},
	{ /* little man */
		1,
		8,
		100,
		33,
		0,
		1,
		0,
		{60 + 152*64, 60 + 166*64, 60 + 159*64, 60 + 166*64},
		{7, 9, 7, 9},
		{7, 3, 7, 3},
		{0, -1, 0, -1},
	}
};

void update_sprite(struct Sprite* sp)
{
	short x, y, h, a, frame;
	
	frame = ((sp->frame) & 63) >> 4;
	
	x = MAKE_SPRITE_X(sp->x + sp->xofs[frame], sp->enabled, 0, 1);
	y = MAKE_SPRITE_Y(sp->y, sp->width[frame] - 1);
	h = MAKE_SPRITE_H(sp->y + sp->height[frame] - 1);

	a = MAKE_SPRITE_A(0x8000 + (sp->frames[frame]));

	load_sprite_x(sp->i, x);
	load_sprite_y(sp->i, y);
	load_sprite_h(sp->i, h);
	load_sprite_a(sp->i, a);

	sp->x += sp->vx;
	sp->y += sp->vy;

	if (sp->x > 640 + 60)
		sp->x = 8;
	if (sp->x < 8)
		sp->x = 640 + 60;

	sp->frame ++;

}

void enable_interrupts()
{
	__out(0x7000, 0x2 | 0x8 );
	global_interrupt_enable();
}

unsigned short bg_x = 0;
short bg_y = 0; //10;
short vx = 0;
short vy = -1;

extern char tilemap_buf1;
extern char tilemap_buf2;

short cur_buf = 0;

short bg_lo = 0x7b00;
short bg_hi = 0x9;

#define SPI_FLASH_BASE 		0x4000
#define SPI_FLASH_ADDR_LO 	(SPI_FLASH_BASE + 0)
#define SPI_FLASH_ADDR_HI 	(SPI_FLASH_BASE + 1)
#define SPI_FLASH_CMD		(SPI_FLASH_BASE + 2)
#define SPI_FLASH_DATA		(SPI_FLASH_BASE + 3)
#define SPI_FLASH_STATUS	(SPI_FLASH_BASE + 4)
#define SPI_FLASH_DMA_ADDR  (SPI_FLASH_BASE + 5)
#define SPI_FLASH_DMA_COUNT (SPI_FLASH_BASE + 6)


volatile short flash_complete;

short first = 1;

void update_background()
{
	bg_x += vx;
	bg_y += vy;

	if (bg_y == -16*4)
	{
		bg_y = 0;

		if (cur_buf == 0)
		{
			__out(0x5d03, (unsigned short)&tilemap_buf2 >> 1);

			__subtract32(&bg_hi, &bg_lo, 32);

			__out(SPI_FLASH_ADDR_LO, bg_lo);
			__out(SPI_FLASH_ADDR_HI, bg_hi);
			__out(SPI_FLASH_DMA_ADDR, ((unsigned short)&tilemap_buf1) >> 1);
			__out(SPI_FLASH_DMA_COUNT, 1024);

			flash_complete = 0;
			__out(SPI_FLASH_CMD, 1);

			cur_buf = 1;
		}
		else {
			__subtract32(&bg_hi, &bg_lo, 32);

			__out(SPI_FLASH_ADDR_LO, bg_lo);
			__out(SPI_FLASH_ADDR_HI, bg_hi);
			__out(SPI_FLASH_DMA_ADDR, ((unsigned short)&tilemap_buf2) >> 1);
			__out(SPI_FLASH_DMA_COUNT, 1024);

			flash_complete = 0;
			__out(SPI_FLASH_CMD, 1);

			__out(0x5d03, (unsigned short)&tilemap_buf1 >> 1);
			cur_buf = 0;
		}
	}



	// Set X
	
	__out(0x5d01, bg_x);

	// Set Y
	
	__out(0x5d02, bg_y >> 2);


	if (first) 
	{
		// Set BG enable and pal hi
		__out(0x5d00, 0x1 | (1<<4) | (2<<8) | (0<<15));

		// Set map address
		__out(0x5d03, (unsigned short)&tilemap_buf1 >> 1);

		// Set tile set address
		__out(0x5d04, (unsigned short)0xc000);
		first = 0;
	}	

}


void load_background()
{
	// Load the background 

	__out(SPI_FLASH_ADDR_LO, bg_lo);
	__out(SPI_FLASH_ADDR_HI, bg_hi);
	__out(SPI_FLASH_DMA_ADDR, ((unsigned short)&tilemap_buf1) >> 1);
	__out(SPI_FLASH_DMA_COUNT, 1024);
	
	flash_complete = 0;
	__out(SPI_FLASH_CMD, 1);

	while (!flash_complete)
		__sleep();

	__subtract32(&bg_hi, &bg_lo, 32);

	__out(SPI_FLASH_ADDR_LO, bg_lo);
	__out(SPI_FLASH_ADDR_HI, bg_hi);
	__out(SPI_FLASH_DMA_ADDR, ((unsigned short)&tilemap_buf2) >> 1);
	__out(SPI_FLASH_DMA_COUNT, 1024);
	
	flash_complete = 0;
	__out(SPI_FLASH_CMD, 1);

}

volatile short vsync;

#define TITLE_OFFSET 0x8000
#define TITLE_OFFSET2 0xc000 

void do_title()
{
	__out(SPI_FLASH_ADDR_LO, 0x7f00);
	__out(SPI_FLASH_ADDR_HI, 0x9);
	__out(SPI_FLASH_DMA_ADDR, 0x8000);
	__out(SPI_FLASH_DMA_COUNT, 256*128);
	
	flash_complete = 0;
	__out(SPI_FLASH_CMD, 1);

	while (!flash_complete)
		__sleep();

	#define TITLE_PAL 2

	{
	short x = MAKE_SPRITE_X(24, 1, TITLE_PAL, 0);
	short y = MAKE_SPRITE_Y(16+20, 63);
	short h = MAKE_SPRITE_H(16+20+200);
	short a = MAKE_SPRITE_A(TITLE_OFFSET);

	load_sprite_x(0, x);
	load_sprite_y(0, y);
	load_sprite_h(0, h);
	load_sprite_a(0, a);

	x = MAKE_SPRITE_X(24 + 64, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 16);

	load_sprite_x(1, x);
	load_sprite_y(1, y);
	load_sprite_h(1, h);
	load_sprite_a(1, a);

	x = MAKE_SPRITE_X(24 + 128, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 32);

	load_sprite_x(2, x);
	load_sprite_y(2, y);
	load_sprite_h(2, h);
	load_sprite_a(2, a);


	x = MAKE_SPRITE_X(24 + 192, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 48);

	load_sprite_x(3, x);
	load_sprite_y(3, y);
	load_sprite_h(3, h);
	load_sprite_a(3, a);

	x = MAKE_SPRITE_X(24 + 256, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 64);

	load_sprite_x(4, x);
	load_sprite_y(4, y);
	load_sprite_h(4, h);
	load_sprite_a(4, a);

	x = MAKE_SPRITE_X(24 + 256 + 64, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET2);

	load_sprite_x(5, x);
	load_sprite_y(5, y);
	load_sprite_h(5, h);
	load_sprite_a(5, a);

	x = MAKE_SPRITE_X(24 + 256 + 128, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET2 + 16);

	load_sprite_x(6, x);
	load_sprite_y(6, y);
	load_sprite_h(6, h);
	load_sprite_a(6, a);

	x = MAKE_SPRITE_X(24 + 256 + 192, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET2 + 32);

	load_sprite_x(7, x);
	load_sprite_y(7, y);
	load_sprite_h(7, h);
	load_sprite_a(7, a);


	x = MAKE_SPRITE_X(24 + 512, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET2 + 48);

	load_sprite_x(8, x);
	load_sprite_y(8, y);
	load_sprite_h(8, h);
	load_sprite_a(8, a);

	x = MAKE_SPRITE_X(24 + 512 + 64, 1, TITLE_PAL, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET2 + 64);

	load_sprite_x(9, x);
	load_sprite_y(9, y);
	load_sprite_h(9, h);
	load_sprite_a(9, a);


	}

	while(1);
}

extern short magnus_palette;

int main()
{

 	// set 640x480 mode
    __out(0x5f02, 0);

	// Enable copper
	__out(0x5d20, 1);

	__out(0x5d22, 0);


	//load_bl_copper_list();
	load_palette(&bloodlust_sprites_palette, 0, 16);
	load_palette(&bloodlust_tiles_palette, 16, 16);
	load_palette(&ace1_palette, 32, 16);
	load_palette(&ace2_palette, 48, 16);
	enable_interrupts();

	do_title();
	
	load_background();

	while (1)
	{
		int i;
		if (vsync)
		{
			vsync = 0;
			update_background();
			//update_bl_copper_list();
			for (i = 0; i < COUNT_OF(sprites); i++)
				update_sprite(&sprites[i]);
		}
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
