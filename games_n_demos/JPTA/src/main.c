
#define COUNT_OF(x) (sizeof(x)/sizeof(x[0]))

extern void load_palette(short* palette, int offset, int len);

extern short john_sprites_palette;

#define MAKE_SPRITE_X(x, en, pal, stride) (((x) & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y, bpp) ((y & 0x3ff) | (bpp << 15))
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
	unsigned short frames[8];
	unsigned short width[8];
	unsigned short height[8];
	short xofs[8];
};

struct Sprite sprites[] =  {
	{ /* John */
		1,
		0,
		160,
		120,
		0,
		0,
		0,
		{0, 9, 19, 29, 38, 48, 2816, 2826},
		{35,39,39,35, 39, 39, 39, 39},
		{43,43,43,43, 43, 43, 43, 43},
		{2,2,0,0,0,0,0,0},
	},
};

void update_sprite(struct Sprite* sp)
{
	short x, y, h, a, frame;
	
	frame = ((sp->frame) & 31) >> 2;
	
	x = MAKE_SPRITE_X(sp->x + sp->xofs[frame], sp->enabled, 0, 1);
	y = MAKE_SPRITE_Y(sp->y, sp->width[frame] - 1);
	h = MAKE_SPRITE_H(sp->y + sp->height[frame] - 1, 1);

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

volatile short vsync;


int main()
{

 	// set 320x240 mode
	__out(0x5f02, 1);
	
	load_palette(&john_sprites_palette, 0, 32);
	enable_interrupts();


	while (1)
	{
		int i;
		if (vsync)
		{
			vsync = 0;
			for (i = 0; i < COUNT_OF(sprites); i++)
				update_sprite(&sprites[i]);
		}
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
