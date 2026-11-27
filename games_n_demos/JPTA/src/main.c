/*
 * JPTA: walk John around level 1 with the arrow keys; the view follows him.
 *
 * The tile set has 512 tiles but a background layer can only name 256 (one
 * byte a tile), so the level is split over both background layers
 * (assets/tmx2bg.py): layer 0 shows the cells that use tiles 0-255 and
 * layer 1 the cells that use tiles 256-511, each empty (0xff) where the
 * other has the tile. To keep the picture together the two layers always
 * get the same scroll position, written to both in the same vertical blank.
 *
 * Video memory (word addresses): tiles 0-255 at 0x8000 and tiles 256-511
 * at 0xc000, copied there from the asset bundle by the boot loader. That
 * fills it, except for the unused tiles 448-511 (SPRITE_RAM), so John's
 * frames stay in flash and the one on show is copied there by DMA.
 */

#include <game_io.h>
#include "level.h"
#include "john.h"

extern void load_palette(const short* palette, int offset, int len);
extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

/* Set by the interrupt handlers in top.asm */
volatile short vsync;
volatile short flash_complete;

#define SCREEN_W	320	/* 320x240 mode */
#define SCREEN_H	240
#define BG_LEFT		24	/* screen (0, 0) in background raster coordinates */
#define BG_TOP		16
#define SPRITE_LEFT	24	/* screen (0, 0) in sprite coordinates */
#define SPRITE_TOP	16

#define LEVEL_PX_W	(LEVEL_W * 16)
#define LEVEL_PX_H	(LEVEL_H * 16)

#define KEY_UP		1
#define KEY_DOWN	2
#define KEY_LEFT	4
#define KEY_RIGHT	8

/* John's speed, in 1/16 pixel (per frame, and per frame per frame) */
#define MAX_SPEED	32
#define ACCEL		4
#define FX(px)		((short)((px) * 16))
#define STEP_PX		5	/* pixels walked per frame of the walk cycle */

#define WORD_ADDR(p)	((unsigned short)(p) >> 1)

/*
 * Flash DMA
 */

#define SPI_FLASH_ADDR_LO	0x4000
#define SPI_FLASH_ADDR_HI	0x4001
#define SPI_FLASH_CMD		0x4002
#define SPI_FLASH_DMA_ADDR	0x4005
#define SPI_FLASH_DMA_COUNT	0x4006

/* Copy words from flash (word address) to memory (word address), and wait */
static void flash_copy(unsigned long from, unsigned short to, unsigned short words)
{
	flash_complete = 0;
	__out(SPI_FLASH_ADDR_LO, (unsigned short)from);
	__out(SPI_FLASH_ADDR_HI, (unsigned short)(from >> 16));
	__out(SPI_FLASH_DMA_ADDR, to);
	__out(SPI_FLASH_DMA_COUNT, words - 1);
	__out(SPI_FLASH_CMD, 1);
	while (!flash_complete)
		__sleep();
}

/*
 * Background layers. The registers start at 0x5d00 (layer 0) and 0x5d05
 * (layer 1): control, X, Y, tile map address, tile set address.
 */
#define BG_ENABLE	1
#define BG_PAL(p)	((p) << 4)
#define BG_STRIDE(s)	((s) << 8)

static unsigned short layer_reg[2][5];	/* written at the next vblank */

/*
 * A layer's Y register can't be negative, so the map is started a whole row
 * early (above the top of the screen) and Y moved down by a row to match.
 */
static void set_layer(short layer, const unsigned short* map, unsigned short tileset,
		      short x, short y)
{
	unsigned short* r = layer_reg[layer];
	short k = (BG_TOP + 15) / 16;		/* rows to start early */

	r[0] = BG_ENABLE | BG_PAL(0) | BG_STRIDE(LEVEL_STRIDE);
	r[1] = (x + 16 - BG_LEFT) & 0x3ff;
	r[2] = y + k * 16 - BG_TOP;
	r[3] = WORD_ADDR(map) - k * (LEVEL_W / 2);
	r[4] = tileset;
}

/* Both layers from the one camera position: they never get out of step */
static void set_camera(short x, short y)
{
	set_layer(0, level_bg0, TILESET0, x, y);
	set_layer(1, level_bg1, TILESET1, x, y);
}

/*
 * John's sprite. The frame on show is in one of two slots in SPRITE_RAM; a
 * new frame is copied into the other slot, which the hardware isn't
 * reading, and the sprite moves over to it at the next vblank.
 */

#define JOHN_PAL	2		/* 5 bpp: colours 32-63 */
#define SLOT_WORDS	16		/* slots side by side in the 64 word rows */
#define SPRITE_ROW	64		/* words from one row of a slot to the next */

static short slot_frame[2] = { -1, -1 };	/* frame in each slot */
static short shown;				/* slot the hardware is showing */
static short pending;				/* slot for the next vblank */
static unsigned short sprite_reg[4];		/* x, y, h, a: written at the next vblank */

static void load_frame(short slot, short frame)
{
	unsigned long from = JOHN_FLASH + (unsigned long)frame * JOHN_FRAME_WORDS;
	unsigned short to = SPRITE_RAM + slot * SLOT_WORDS;
	short row;

	for (row = 0; row < JOHN_H; row++)
	{
		flash_copy(from, to, JOHN_WORDS);
		from += JOHN_WORDS;
		to += SPRITE_ROW;
	}
	slot_frame[slot] = frame;
}

static void show_frame(short frame)
{
	if (slot_frame[shown] == frame)
		pending = shown;
	else
	{
		pending = shown ^ 1;
		if (slot_frame[pending] != frame)
			load_frame(pending, frame);
	}
}

/* The width field counts 4 per 3 pixels at 5 bpp (the last pixel's count) */
#define WIDTH_5BPP(px)	(((px) - 1) / 3 * 4 + ((px) - 1) % 3)

static void set_sprite(short x, short y)
{
	x += SPRITE_LEFT;
	y += SPRITE_TOP;
	sprite_reg[0] = (x & 0x3ff) | (1 << 10) | (JOHN_PAL << 11) | (1 << 15);
	sprite_reg[1] = (y & 0x3ff) | (WIDTH_5BPP(JOHN_W) << 10);
	sprite_reg[2] = ((y + JOHN_H - 1) & 0x3ff) | (1 << 15);
	sprite_reg[3] = SPRITE_RAM + pending * SLOT_WORDS;
}

/* At the start of vblank: the layers and the sprite together */
static void vblank(void)
{
	short l, i;
	for (l = 0; l < 2; l++)
		for (i = 0; i < 5; i++)
			__out(0x5d00 + l * 5 + i, layer_reg[l][i]);
	load_sprite_x(0, sprite_reg[0]);
	load_sprite_y(0, sprite_reg[1]);
	load_sprite_h(0, sprite_reg[2]);
	load_sprite_a(0, sprite_reg[3]);
	shown = pending;
}

/*
 * Movement
 */

/* Position and speed along one axis, in 1/16 pixel */
struct axis {
	short pos, v;
};

static short approach(short v, short target)
{
	if (v < target)
		return v + ACCEL < target ? v + ACCEL : target;
	if (v > target)
		return v - ACCEL > target ? v - ACCEL : target;
	return v;
}

static void move(struct axis* a, short dir, short max)
{
	a->v = approach(a->v, dir * MAX_SPEED);
	a->pos += a->v;
	if (a->pos < 0)
	{
		a->pos = 0;
		a->v = 0;
	}
	if (a->pos > FX(max))
	{
		a->pos = FX(max);
		a->v = 0;
	}
}

static short clamp(short v, short lo, short hi)
{
	return v < lo ? lo : v > hi ? hi : v;
}

static short abs16(short v)
{
	return v < 0 ? -v : v;
}

int main(void)
{
	/* John's top left corner in the level: on the floor of the bottom cave */
	struct axis jx = { FX(3 * 16), 0 };
	struct axis jy = { FX(28 * 16 - JOHN_H), 0 };
	short facing_left = 0;
	short walk = 0, walked = 0;
	short i;

	__out(0x5f02, 1);		/* 320x240 */
	__out(0x5d20, 0);		/* no copper */
	__out(0x5d21, 0);		/* no mirror */
	/* Colour 0 is see-through in both layers, so the screen background
	 * shows there: make it the same colour */
	__out(0x5d22, tiles_palette[0]);
	load_palette((const short*)tiles_palette, 0, 16);
	load_palette((const short*)john_palette, 32, 32);

	for (i = 0; i < 256; i++)
		load_sprite_x(i, 0);

	/* vsync and flash DMA interrupts */
	__out(0x7000, 0x2 | 0x8);
	global_interrupt_enable();

	while (1)
	{
		unsigned short keys;
		short dx = 0, dy = 0, x, y, cam_x, cam_y, frame;

		keys = __in(0x1001);
		if (keys & KEY_LEFT)
			dx--;
		if (keys & KEY_RIGHT)
			dx++;
		if (keys & KEY_UP)
			dy--;
		if (keys & KEY_DOWN)
			dy++;
		move(&jx, dx, LEVEL_PX_W - JOHN_W);
		move(&jy, dy, LEVEL_PX_H - JOHN_H);

		if (jx.v < 0)
			facing_left = 1;
		if (jx.v > 0)
			facing_left = 0;

		/* the walk cycle keeps pace with how far he goes */
		if (jx.v || jy.v)
		{
			walked += abs16(jx.v) + abs16(jy.v);
			while (walked >= FX(STEP_PX))
			{
				walked -= FX(STEP_PX);
				walk = (walk + 1) % JOHN_WALK_FRAMES;
			}
			frame = JOHN_WALK + walk;
		}
		else
		{
			walked = 0;
			frame = JOHN_STAND;
		}
		if (facing_left)
			frame += JOHN_LEFT;
		show_frame(frame);

		/* the view follows John, up to the edges of the level */
		x = jx.pos >> 4;
		y = jy.pos >> 4;
		cam_x = clamp(x + JOHN_W / 2 - SCREEN_W / 2, 0, LEVEL_PX_W - SCREEN_W);
		cam_y = clamp(y + JOHN_H / 2 - SCREEN_H / 2, 0, LEVEL_PX_H - SCREEN_H);
		set_camera(cam_x, cam_y);
		set_sprite(x - cam_x, y - cam_y);

		while (!vsync)
			__sleep();
		vsync = 0;
		vblank();
	}
	return 0;
}
