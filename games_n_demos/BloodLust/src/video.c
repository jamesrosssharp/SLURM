/*
 * video.c: sprites, parallax backgrounds and copper effects for BloodLust.
 */

#include <game_io.h>
#include "video.h"

/* sprite.asm / palette.asm / copper.asm */
extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);
extern void load_palette(short* palette, int offset, int len);
extern void load_bl_copper_list(void);
extern void update_bl_copper_list(void);

extern unsigned short bloodlust_copper_list[];
extern short bloodlust_sprites_palette;
extern short bloodlust_tiles_palette;
extern short bg1_tilemap;
extern short bg2_tilemap;

/* Screen position (0, 0) in sprite coordinates */
#define SPRITE_X_OFS	24
#define SPRITE_Y_OFS	16

#define MAX_SPRITES	128

#define SPRITE_X(x, en, pal) (((x) & 0x3ff) | (((en) & 1) << 10) | (((pal) & 0xf) << 11) | 0x8000)
#define SPRITE_Y(y, w)	     (((y) & 0x3ff) | (((w) & 0x3f) << 10))

/*
 * The game builds each frame's sprites in a shadow copy of the sprite
 * registers; video_vblank() copies it to the hardware at the start of the
 * next vertical blank, so the display never shows a half updated frame.
 */
static unsigned short shadow_x[MAX_SPRITES];
static unsigned short shadow_y[MAX_SPRITES];
static unsigned short shadow_h[MAX_SPRITES];
static unsigned short shadow_a[MAX_SPRITES];

static short n_sprites;		/* sprites in the frame being built */
static short n_ready;		/* sprites in the finished frame */
static short n_shown;		/* sprites enabled in the hardware */

void sprite_begin(void)
{
	n_sprites = 0;
}

void sprite_draw(const struct sprite_frame* f, short x, short y, short pal)
{
	short i;

	for (i = 0; i < f->n; i++)
	{
		const struct sprite_part* p = &f->parts[i];
		short px = x + p->dx;
		short py = y + p->dy;
		short h = p->h;

		/* Off screen (or above the top, which the hardware cannot clip) */
		if (px + (short)p->w <= -SPRITE_X_OFS || px >= SCREEN_W ||
		    py + h <= 0 || py >= WATER_LINE || n_sprites == MAX_SPRITES)
			continue;

		/* Clip the top: start further down in the sprite data */
		unsigned short addr = p->addr;
		if (py < 0)
		{
			addr += (unsigned short)(-py) * 64;
			h += py;
			py = 0;
		}
		/* Nothing below the water line is drawn: it shows the mirror */
		if (py + h > WATER_LINE)
			h = WATER_LINE - py;

		px += SPRITE_X_OFS;
		py += SPRITE_Y_OFS;

		shadow_x[n_sprites] = SPRITE_X(px, 1, pal);
		shadow_y[n_sprites] = SPRITE_Y(py, p->w);
		shadow_h[n_sprites] = py + h;
		shadow_a[n_sprites] = addr;
		n_sprites++;
	}
}

void sprite_end(void)
{
	n_ready = n_sprites;
}

/*
 * Parallax. Two tile layers: the far mountains move at half the speed of
 * the near ones. Positions are in 1/16 pixel; the hardware wraps the X
 * position within the 256 tile (4096 pixel) wide maps.
 */

static unsigned long far_x;
static unsigned long near_x;
static short near_px, far_px;	/* positions for the next frame */

static void bg_layer(short base, short x, short y, short* tilemap)
{
	/* enable, tile palette, 16x16 tiles */
	__out(base + 0, 0x1 | (PAL_TILES << 4));
	__out(base + 1, x);
	__out(base + 2, y);
	__out(base + 3, (unsigned short)tilemap >> 1);
	__out(base + 4, 0xc000);	/* tile set address */
}

void parallax_update(short speed)
{
	/* speed: near layer speed in 1/16 pixel per frame. The camera travels
	 * west, so the X positions decrease. */
	near_x -= speed;
	far_x -= speed >> 1;

	near_px = (short)(near_x >> 4) & 0xfff;
	far_px = (short)(far_x >> 4) & 0xfff;
}

/*
 * Copper sky: 16 bands of colour, set by the first 16 "set background colour
 * and wait" instructions of the copper list (found by video_init).
 */

#define SKY_BANDS	16
#define COPPER_BG_WAIT	0x6000

static const unsigned short sky_tint[] = {
	0x100,	/* stage 1: blood red */
	0x101,	/* stage 2: violet */
	0x010,	/* stage 3: poison green */
	0x001,	/* stage 4: midnight blue */
	0x110,	/* stage 5: amber */
};

static unsigned short sky_colour[SKY_BANDS];
static short sky_entry[SKY_BANDS];	/* copper list index of each band */
static short flash_frames;

void sky_set_stage(short stage)
{
	short i;
	unsigned short tint = sky_tint[stage % (short)(sizeof(sky_tint) / sizeof(sky_tint[0]))];

	for (i = 0; i < SKY_BANDS; i++)
		sky_colour[i] = tint * i;	/* 0 .. 15 in each tinted channel */
}

void sky_flash(short frames)
{
	flash_frames = frames;
}

void sky_update(void)
{
	short i;

	for (i = 0; i < SKY_BANDS; i++)
	{
		unsigned short c = sky_colour[i];
		if (flash_frames)
			c = (flash_frames & 2) ? 0xfff : 0xccd;
		bloodlust_copper_list[sky_entry[i]] = COPPER_BG_WAIT | c;
	}
	if (flash_frames)
		flash_frames--;
}

void video_vblank(void)
{
	short i;

	for (i = 0; i < n_ready; i++)
	{
		load_sprite_x(i, shadow_x[i]);
		load_sprite_y(i, shadow_y[i]);
		load_sprite_h(i, shadow_h[i]);
		load_sprite_a(i, shadow_a[i]);
	}
	/* Disable the sprites shown last frame but not in this one */
	for (; i < n_shown; i++)
		load_sprite_x(i, 0);
	n_shown = n_ready;

	bg_layer(0x5d00, near_px, 10, &bg2_tilemap);
	bg_layer(0x5d05, far_px, 0, &bg1_tilemap);

	/* animate the water and upload the copper list */
	update_bl_copper_list();
}

static short flash_palette[16];

void video_init(void)
{
	short i;

	/* 320x240 mode */
	__out(0x5f02, 1);
	/* Mirror the screen below the water line */
	__out(0x5d21, 0x8000 | WATER_LINE);
	/* Enable the copper */
	__out(0x5d20, 1);

	for (i = 0; i < 16; i++)
		flash_palette[i] = i ? (short)0xffff : 0;

	load_palette(&bloodlust_sprites_palette, PAL_SPRITES * 16, 16);
	load_palette(&bloodlust_tiles_palette, PAL_TILES * 16, 16);
	load_palette(flash_palette, PAL_FLASH * 16, 16);

	for (i = 0; i < MAX_SPRITES; i++)
		load_sprite_x(i, 0);

	/* Find the sky colour instructions in the copper list */
	{
		short n = 0;
		for (i = 0; i < 64 && n < SKY_BANDS; i++)
			if ((bloodlust_copper_list[i] & 0xf000) == COPPER_BG_WAIT)
				sky_entry[n++] = i;
	}

	sky_set_stage(0);
	sky_update();
	load_bl_copper_list();
	parallax_update(0);
	video_vblank();
}
