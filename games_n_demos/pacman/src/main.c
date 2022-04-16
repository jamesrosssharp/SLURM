
extern void load_copper_list(short* list, int len);
extern void load_palette(short* palette, int len);

short copperList[] = {
		0x6f00,
		0x7010,
		0x60f0,
		0x7010,
		0x600f,
		0x7010,
		0x6fff,
		0x7010,
		0x4200,
		0x1000,
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
extern short pacman_palette;

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
	}

/*spr1:
	dw 400
	dw 100
	dw 1
	dw 1
	dw pacman_sprite_sheet + (16 * 5 * 64) + 12
	dw  pacman_sprite_sheet + (16 * 5 * 64) + 8
	dw  pacman_sprite_sheet + (16 * 5 * 64) + 12
	dw  pacman_sprite_sheet + (16 * 5 * 64) + 8
spr2:
	dw 200
	dw 200
	dw -1
	dw -1
	dw pacman_sprite_sheet + 0 + (64*4*16)
	dw pacman_sprite_sheet + 4 + (64*4*16)
	dw pacman_sprite_sheet + 0 + (64*4*16)
	dw pacman_sprite_sheet + 4 + (64*4*16)
spr3:
	dw 600
	dw 300
	dw 2
	dw 1
	dw pacman_sprite_sheet + 8 + (64*3*16)
	dw pacman_sprite_sheet + 8 + (64*3*16)
	dw pacman_sprite_sheet + 8 + (64*3*16)
	dw pacman_sprite_sheet + 8 + (64*3*16)
spr4:
	dw 280
	dw 400
	dw -1
	dw 2
	dw pacman_sprite_sheet + 12 + (64*3*16)
	dw pacman_sprite_sheet + 12 + (64*3*16)
	dw pacman_sprite_sheet + 12 + (64*3*16)
	dw pacman_sprite_sheet + 12 + (64*3*16)
spr5:
	dw 250
	dw 150
	dw -2
	dw -1
	dw pacman_sprite_sheet + 16 + (64*3*16)
	dw pacman_sprite_sheet + 16 + (64*3*16)
	dw pacman_sprite_sheet + 16 + (64*3*16)
	dw pacman_sprite_sheet + 16 + (64*3*16)
spr6:
	dw 250
	dw 150
	dw -2
	dw 0
	dw pacman_sprite_sheet + 20 + (64*3*16)
	dw pacman_sprite_sheet + 20 + (64*3*16)
	dw pacman_sprite_sheet + 20 + (64*3*16)
	dw pacman_sprite_sheet + 20 + (64*3*16)
spr7:
	dw 250
	dw 150
	dw 1
	dw -1
	dw pacman_sprite_sheet + 24 + (64*3*16)
	dw pacman_sprite_sheet + 24 + (64*3*16)
	dw pacman_sprite_sheet + 24 + (64*3*16)
	dw pacman_sprite_sheet + 24 + (64*3*16)
spr8:
	dw 250
	dw 150
	dw -2
	dw 3
	dw pacman_sprite_sheet + 28 + (64*3*16)
	dw pacman_sprite_sheet + 28 + (64*3*16)
	dw pacman_sprite_sheet + 28 + (64*3*16)
	dw pacman_sprite_sheet + 28 + (64*3*16)
		*/



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

void enable_interrupts()
{
	__out(0x7000, 0x2);
	global_interrupt_enable();
}

int main()
{
	load_copper_list(copperList, COUNT_OF(copperList));
	load_palette(&pacman_palette, 16);

	enable_interrupts();

	while (1)
	{
		update_sprites();
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
