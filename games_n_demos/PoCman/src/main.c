
extern void load_copper_list(short* list, int len);
extern void load_palette(short* palette, int offset, int len);

short copperList[] = {
		0x6000,
/*		0x6f00,
		0x7007,
		0x60f0,
		0x7007,
		0x600f,
		0x7007,
		0x60ff,
		0x7007,
		0x4200,
		0x1001,*/
		0x2fff		 
};

struct Sprite {
	short x;
	short y;
	short width;
	short height;
	short vx;
	short vy;
	short frame;
	unsigned short frame_offsets[4];
};

extern short pacman_sprite_sheet;
extern short pacman_spritesheet_palette;
extern short pacman_tilemap;
extern short pacman_tileset;
extern short pacman_tileset_palette;

struct Sprite sprites[] = {
	{
		320,
		240,
		16,
		16,
		1,
		0,
		0,
		{0, 4, 8, 4}
	},
	{	400,
		100,
		16,
		16,
		1,
		1,
		0,
		{(16*5*64) + 12, (16 * 5 * 64) + 8, (16*5*64) + 12, (16 * 5 * 64) + 8}
	},
	{
		200,
		200,
		16,
		16,
		-1,
		-1,
		0,
		{64*4*16, 64*4*16+4,64*4*16, 64*4*16+4}
	},
	{
		600,
		300,
		16,
		16,
		2,
		1,
		0,
		{8 + 64*3*16, 8 + 64*3*16, 8 + 64*3*16, 8 + 64*3*16 }
	},
	{
		280,
		400,
		16,
		16,
		-1,
		2,
		0,
		{12 + 64*3*16, 12 + 64*3*16, 12 + 64*3*16, 12 + 64*3*16 }	
	},
	{
		250,
		150,
		16,
		16,
		-2,
		-1,
		0,
		{16 + 64*3*16, 16 + 64*3*16, 16 + 64*3*16, 16 + 64*3*16 }	
	}

};

#define COUNT_OF(x) ((sizeof(x)) / (sizeof(x[0])))

#define MAKE_SPRITE_X(x, en, pal, stride) ((x & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y) ((y & 0x3ff))
#define MAKE_SPRITE_A(a) (a)

extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

void update_sprites()
{
	int i;

	for (i = 0; i < COUNT_OF(sprites); i++)
	{
		struct Sprite* sp = &sprites[i];

		short x = MAKE_SPRITE_X(sp->x, 1, 0, 1);
		short y = MAKE_SPRITE_Y(sp->y, sp->width);
		short h = MAKE_SPRITE_H(sp->y + sp->height);
		short frame = sp->frame;
		short a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frame_offsets[frame >> 2]));

		load_sprite_x(i, x);
		load_sprite_y(i, y);
		load_sprite_h(i, h);
		load_sprite_a(i, a);

		sp->frame = (sp->frame + 1) & 15;
		sp->x += sp->vx;
		sp->y += sp->vy;

		sp->x &= 1023;
		sp->y &= 511;
	}
}

short bg_x = 73;
short bg_y = 0; //10;
short vx = 0;
short vy = 0;

void update_background()
{


	// Set BG enable and pal hi
	
	__out(0x5d00, 0x1 | (1<<4));

	// Set X
	
	__out(0x5d01, bg_x);

	// Set Y
	
	__out(0x5d02, bg_y);

	// Set map address

	__out(0x5d03, (unsigned short)&pacman_tilemap >> 1);

	// Set tile set address
	
	__out(0x5d04, (unsigned short)&pacman_tileset >> 1);

	bg_x += vx;
	bg_y += vy;

	if (bg_x > 150)
	{
		bg_x = 149;
		vx = 0-vx;
		vy = 0-vy;
	}
	else if (bg_x < 0)
	{
		vx = 0-vx;
		vy = 0-vy;
		bg_x = 0;
	}
}

void enable_interrupts()
{
	__out(0x7000, 0x2);
	global_interrupt_enable();
}

int main()
{
	
	short frame = 0;
	
	load_copper_list(copperList, COUNT_OF(copperList));
	load_palette(&pacman_spritesheet_palette, 0, 16);
	load_palette(&pacman_tileset_palette, 16, 16);


	enable_interrupts();

	while (1)
	{
		update_background();
		update_sprites();
//		copperList[0] = 0x7000 | (frame++ & 31);
		load_copper_list(copperList, COUNT_OF(copperList));
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
