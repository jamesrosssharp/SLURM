
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
	short frames[4];
};

extern short pacman_sprite_sheet;
extern short pacman_palette;

struct Sprite sprites[] = {
	{
		320,
		240,
		16,
		16,
		0,
		0,
		0,
		{0, 4, 8, 4}
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
		short a = MAKE_SPRITE_A((unsigned short)(&pacman_sprite_sheet) >> 1);

		load_sprite_x(i, x);
		load_sprite_y(i, y);
		load_sprite_h(i, h);
		load_sprite_a(i, a);

	}
}

int main()
{
	trace_hex(&pacman_sprite_sheet);
	load_copper_list(copperList, COUNT_OF(copperList));
	load_palette(&pacman_palette, 16);
	update_sprites();

	putc('!');
	exit();
	return 0;
}
