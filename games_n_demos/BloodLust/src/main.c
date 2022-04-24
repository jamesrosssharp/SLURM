
#define COUNT_OF(x) (sizeof(x)/sizeof(x[0]))

extern void load_bl_copper_list(void);
extern void update_bl_copper_list(void);
extern void load_palette(short* palette, int offset, int len);

extern short bloodlust_copper_list;
extern short bloodlust_sprites_palette;

#define MAKE_SPRITE_X(x, en, pal, stride) ((x & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
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
	{ /* GIANT */
		1,
		0,
		160,
		110,
		1,
		0,
		0,
		{2*16*64 + 8, 2*16*64, 2*16*64 + 16, 2*16*64},
		{32,32,36,32},
		{56,56,56,56},
		{0,0,-9,0},
	},
	{ /* BULBOUS PLANE */
		1,
		1,
		180,
		60,
		1,
		0,
		0,
		{0, 0, 0, 0},
		{20, 20, 20, 20},
		{16, 16, 16, 16},
		{0, 0, 0, 0},
	},
	{ /* BOOMERANG */
		1,
		2,
		80,
		40,
		2,
		0,
		0,
		{8, 8, 8, 8},
		{16, 16, 16, 16},
		{16, 16, 16, 16},
		{0, 0, 0, 0},
	},
	{ /* BOAT */
		1,
		3,
		40,
		125,
		1,
		0,
		0,
		{12, 12, 12, 12},
		{32, 32, 32, 32},
		{28, 28, 28, 28},
		{0, 0, 0, 0},
	}
};

void update_sprite(struct Sprite* sp)
{
	short x, y, h, a, frame;
	
	frame = ((sp->frame) & 63) >> 4;
	
	x = MAKE_SPRITE_X(sp->x + sp->xofs[frame], sp->enabled, 0, 1);
	y = MAKE_SPRITE_Y(sp->y, sp->width[frame]);
	h = MAKE_SPRITE_H(sp->y + sp->height[frame]);

	a = MAKE_SPRITE_A(0x8000 + (sp->frames[frame]));

	load_sprite_x(sp->i, x);
	load_sprite_y(sp->i, y);
	load_sprite_h(sp->i, h);
	load_sprite_a(sp->i, a);

	sp->x += sp->vx;
	sp->y += sp->vy;

	if (sp->x > 320 + 60)
		sp->x = 8;
	if (sp->x < 8)
		sp->x = 320 + 60;

	sp->frame ++;

}

void enable_interrupts()
{
	__out(0x7000, 0x2);
	global_interrupt_enable();
}

int main()
{

 	// set 320x240 mode
    __out(0x5f02, 1);

	// Set y flip
	__out(0x5d21, 0x8000 | 150);


	load_bl_copper_list();
	load_palette(&bloodlust_sprites_palette, 0, 16);
	//load_palette(&pacman_tileset_palette, 16, 16);
	enable_interrupts();

	while (1)
	{
		int i;
		update_bl_copper_list();
		for (i = 0; i < COUNT_OF(sprites); i++)
			update_sprite(&sprites[i]);
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
