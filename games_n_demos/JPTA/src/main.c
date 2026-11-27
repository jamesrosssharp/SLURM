/*
 * JPTA: John walks around level 1; the view follows him. Left and right
 * walk, up and down climb ladders, B jumps (higher the longer it's held),
 * A fires his 10% GST ray, and off a ledge he falls. The enemies and power ups are in actors.c.
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
 * frames stay in flash and the one on show is copied there by DMA. The
 * enemy and power up frames (kakadu.h) are copied by DMA at the start to
 * KAKADU_RAM, in the top half of the program's memory, which it doesn't use.
 */

#include <game_io.h>
#include "jpta.h"
#include "kakadu.h"

extern void load_palette(const short* palette, int offset, int len);
extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

/* Set by the interrupt handlers in top.asm */
volatile short vsync;
volatile short flash_complete;

#define BG_LEFT		24	/* screen (0, 0) in background raster coordinates */
#define BG_TOP		16
#define SPRITE_LEFT	24	/* screen (0, 0) in sprite coordinates */
#define SPRITE_TOP	16

#define KEY_UP		1
#define KEY_DOWN	2
#define KEY_LEFT	4
#define KEY_RIGHT	8
#define KEY_A		16
#define KEY_B		32
#define SHOT_GAP	12	/* frames between shots */

/* John's speed, in 1/16 pixel (per frame, and per frame per frame) */
#define MAX_SPEED	32
#define ACCEL		4
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

#define SLOT_WORDS	16		/* slots side by side in the 64 word rows */
#define SPRITE_ROW	64		/* words from one row of a slot to the next */

static short slot_frame[2] = { -1, -1 };	/* frame in each slot */
static short shown;				/* slot the hardware is showing */
static short pending;				/* slot for the next vblank */

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

/*
 * Sprites: each frame's are listed in a copy of the sprite registers,
 * written to the hardware at the next vblank. Later ones are drawn on top.
 * All are 5 bpp, in rows 64 words (256 nibbles) apart.
 */

#define MAX_SPRITES	64
#define MAX_PART_W	48	/* pixels: the most the width field can count at 5 bpp */

static unsigned short shadow_x[MAX_SPRITES], shadow_y[MAX_SPRITES];
static unsigned short shadow_h[MAX_SPRITES], shadow_a[MAX_SPRITES];
static short n_sprites;		/* in the frame being built */
static short n_shown;		/* enabled in the hardware */

/* The width field counts 4 per 3 pixels at 5 bpp (the last pixel's count) */
#define WIDTH_5BPP(px)	(((px) - 1) / 3 * 4 + ((px) - 1) % 3)

/* A w x h picture at word address addr, at screen x, y, clipped */
static void sprite_raw(unsigned short addr, short x, short y, short w, short h, short pal)
{
	if (n_sprites == MAX_SPRITES || x >= SCREEN_W || y >= SCREEN_H)
		return;
	/* off the left of the raster: drop whole words (3 pixels) */
	if (x < -SPRITE_LEFT)
	{
		short words = (-SPRITE_LEFT - x + 2) / 3;
		addr += words;
		x += words * 3;
		w -= words * 3;
	}
	/* and off the top, whole rows */
	if (y < -SPRITE_TOP)
	{
		short rows = -SPRITE_TOP - y;
		addr += rows * SPRITE_ROW;
		y += rows;
		h -= rows;
	}
	if (y + h > SCREEN_H)
		h = SCREEN_H - y;
	if (w <= 0 || h <= 0)
		return;
	x += SPRITE_LEFT;
	y += SPRITE_TOP;
	shadow_x[n_sprites] = (x & 0x3ff) | (1 << 10) | (pal << 11) | (1 << 15);
	shadow_y[n_sprites] = (y & 0x3ff) | (WIDTH_5BPP(w) << 10);
	shadow_h[n_sprites] = ((y + h - 1) & 0x3ff) | (1 << 15);
	shadow_a[n_sprites] = addr;
	n_sprites++;
}

/* A kakadu.h frame: wider ones are drawn as more than one sprite */
void sprite_frame(short f, short x, short y, short pal)
{
	const struct kframe* k = &kframes[f];
	unsigned short addr = k->addr;
	short w = k->w;

	while (w > 0)
	{
		sprite_raw(addr, x, y, w > MAX_PART_W ? MAX_PART_W : w, k->h, pal);
		addr += MAX_PART_W / 3;
		x += MAX_PART_W;
		w -= MAX_PART_W;
	}
}

/* At the start of vblank: the layers and the sprites together */
static void vblank(void)
{
	short l, i;
	for (l = 0; l < 2; l++)
		for (i = 0; i < 5; i++)
			__out(0x5d00 + l * 5 + i, layer_reg[l][i]);
	for (i = 0; i < n_sprites; i++)
	{
		load_sprite_x(i, shadow_x[i]);
		load_sprite_y(i, shadow_y[i]);
		load_sprite_h(i, shadow_h[i]);
		load_sprite_a(i, shadow_a[i]);
	}
	for (; i < n_shown; i++)
		load_sprite_x(i, 0);
	n_shown = n_sprites;
	shown = pending;
}

/*
 * Movement helpers
 */

static short clamp(short v, short lo, short hi)
{
	return v < lo ? lo : v > hi ? hi : v;
}

static short abs16(short v)
{
	return v < 0 ? -v : v;
}

static short approach(short v, short target)
{
	if (v < target)
		return v + ACCEL < target ? v + ACCEL : target;
	if (v > target)
		return v - ACCEL > target ? v - ACCEL : target;
	return v;
}

/*
 * The level's collision map (level.h): what's solid at a pixel, and where
 * the ladders are.
 */

static const unsigned char* const map0 = (const unsigned char*)level_bg0;
static const unsigned char* const map1 = (const unsigned char*)level_bg1;

/* The tile (0-511) in a map cell */
static short tile_at(short px, short py)
{
	short cell = (py >> 4) * LEVEL_W + (px >> 4);
	unsigned char t = map0[cell];
	return t != 0xff ? t : 256 + map1[cell];
}

static short is_ladder(short tile)
{
	return (tile_ladder[tile >> 4] >> (tile & 15)) & 1;
}

static short ladder_at(short px, short py)
{
	if (px < 0 || py < 0 || px >= LEVEL_PX_W || py >= LEVEL_PX_H)
		return 0;
	return is_ladder(tile_at(px, py));
}

/* Is any of the rectangle x0-x1, y0-y1 (inclusive) solid? Outside the
 * level is solid, except above it. */
short solid(short x0, short y0, short x1, short y1)
{
	short x, y;

	if (x0 < 0 || x1 >= LEVEL_PX_W || y1 >= LEVEL_PX_H)
		return 1;
	if (y0 < 0)
		y0 = 0;
	if (y1 < y0)
		return 0;
	/* one test per 4x4 block, each block's top left corner */
	for (y = y0 & ~3; y <= y1; y += 4)
		for (x = x0 & ~3; x <= x1; x += 4)
		{
			short t = tile_at(x, y);
			if ((tile_solid[t] >> (((y & 15) >> 2) * 4 + ((x & 15) >> 2))) & 1)
				return 1;
		}
	return 0;
}

/*
 * John (jpta.h)
 */

#define STEP_UP		4	/* the highest bump he walks over */
#define CENTRE		(JOHN_W / 2)

#define GRAVITY		5	/* 1/16 pixel per frame per frame */
#define MAX_FALL	80
#define CLIMB_SPEED	16
#define JUMP_SPEED	116	/* up to about 84 pixels high: onto the island and the ledges */
#define JUMP_CUT	32	/* letting go of A early: rise no faster than this */

/* Would John's box hit anything with his sprite at pixel x, y? Only the
 * part above his feet's STEP_UP rows if 'body' */
static short box_hits(struct john* j, short x, short y, short body)
{
	return solid(x + HB_L, y + HB_T, x + HB_R - 1, y + HB_B - 1 - (body ? STEP_UP : 0));
}

static short ground_under(struct john* j, short x, short y)
{
	return solid(x + HB_L, y + HB_B, x + HB_R - 1, y + HB_B);
}

/* Left and right, a pixel at a time, stepping up small bumps */
static void move_x(struct john* j)
{
	short x = PX(j->x), y = PX(j->y);
	short to = PX(j->x + j->vx);
	short dir = to > x ? 1 : -1;

	while (x != to)
	{
		short s;
		if (box_hits(j, x + dir, y, 1))
			break;
		/* his feet are in something low: up onto it, if there's room */
		for (s = 0; s <= STEP_UP && box_hits(j, x + dir, y - s, 0); s++)
			;
		if (s > STEP_UP || (s && !j->on_ground))
			break;
		x += dir;
		y -= s;
	}
	if (x == to)
		j->x += j->vx;
	else
	{
		j->x = FX(x);
		j->vx = 0;
	}
	if (y != PX(j->y))
		j->y = FX(y);
}

/* Up and down, a pixel at a time: landing, or bumping his head */
static void move_y(struct john* j)
{
	short x = PX(j->x), y = PX(j->y);
	short to = PX(j->y + j->vy);
	short dir = to > y ? 1 : -1;

	while (y != to)
	{
		if (dir > 0 ? ground_under(j, x, y) : box_hits(j, x, y - 1, 0))
			break;
		y += dir;
	}
	if (y == to)
		j->y += j->vy;
	else
	{
		j->y = FX(y);
		j->vy = 0;
	}
}

/* The middle of the ladder at pixel px, py */
static short ladder_middle(short px, short py)
{
	short left = (px & ~15) - ((tile_at(px, py) & 1) ? 16 : 0);
	return left + 16;
}

/* dx, dy: the arrow keys (-1, 0, 1); jump: A was just pressed; held: A is down */
static void update_john(struct john* j, short dx, short dy, short jump, short held)
{
	short x = PX(j->x), y = PX(j->y);
	short cx = x + CENTRE;
	short feet = y + HB_B;
	short was_climbing = j->climbing;

	/* Onto a ladder: up from in front of one, or down from the top of one */
	if (!j->climbing && !dx &&
	    ((dy < 0 && ladder_at(cx, feet - 1)) || (dy > 0 && ladder_at(cx, feet))))
	{
		short mid = ladder_middle(cx, dy < 0 ? feet - 1 : feet);
		if (cx - mid < 8 && mid - cx < 8)
		{
			j->climbing = 1;
			j->x = FX(mid - CENTRE);
			j->vx = 0;
		}
	}
	/* and off it by walking away, or jumping */
	if (j->climbing && (dx || jump))
		j->climbing = 0;

	if (j->climbing)
	{
		x = PX(j->x);
		cx = x + CENTRE;
		j->vx = 0;
		j->vy = dy * CLIMB_SPEED;
		/* no higher than the top of the ladder */
		if (dy < 0 && !ladder_at(cx, feet - 2))
			j->vy = 0;
		move_y(j);
		y = PX(j->y);
		feet = y + HB_B;
		/* at the bottom: standing on the floor */
		if (dy > 0 && !ladder_at(cx, feet) && ground_under(j, x, y))
			j->climbing = 0;
		j->on_ground = 0;
		return;
	}

	/* just off a ladder at the bottom, his feet can be in its floor */
	{
		short s;
		for (s = 0; s <= 8 && box_hits(j, x, y - s, 0); s++)
			;
		if (s && s <= 8)
			j->y = FX(y - s);
	}

	if (jump && (j->on_ground || was_climbing))
	{
		j->vy = -JUMP_SPEED;
		j->on_ground = 0;
	}
	else if (!held && j->vy < -JUMP_CUT)
		j->vy = -JUMP_CUT;

	j->vx = approach(j->vx, dx * MAX_SPEED);
	if (j->vx)
		move_x(j);

	/* With a ladder at his middle he holds on: he can walk off it sideways
	 * (or across the top of one) without falling through. Jumping up past
	 * one, he doesn't. */
	x = PX(j->x);
	y = PX(j->y);
	if (j->vy >= 0 && ladder_at(x + CENTRE, y + HB_B - 1))
	{
		j->vy = 0;
		j->on_ground = 1;
		return;
	}

	j->vy += GRAVITY;
	if (j->vy > MAX_FALL)
		j->vy = MAX_FALL;
	if (j->on_ground && j->vy > 0)
	{
		/* walking down a slope or a step: keep his feet on the ground */
		short s;
		x = PX(j->x);
		y = PX(j->y);
		for (s = 0; s <= STEP_UP && !ground_under(j, x, y + s); s++)
			;
		if (s && s <= STEP_UP)
		{
			j->y = FX(y + s);
			j->vy = 0;
		}
	}
	move_y(j);
	j->on_ground = ground_under(j, PX(j->x), PX(j->y));
	if (j->on_ground && j->vy > 0)
		j->vy = 0;
}

/* John starts on the grass at the top left, next to the first ladder */
void john_start(void)
{
	john.x = FX(1 * 16);
	john.y = FX(9 * 16 - JOHN_H);
	john.vx = john.vy = 0;
	john.on_ground = john.climbing = 0;
}

int main(void)
{
	short facing_left = 0;
	short walk = 0, walked = 0;
	unsigned short prev_keys = 0;
	short reload = 0;
	short i;

	__out(0x5f02, 1);		/* 320x240 */
	__out(0x5d20, 0);		/* no copper */
	__out(0x5d21, 0);		/* no mirror */
	/* Colour 0 is see-through in both layers, so the screen background
	 * shows there: make it the same colour */
	__out(0x5d22, tiles_palette[0]);
	load_palette((const short*)tiles_palette, 0, 16);
	load_palette((const short*)john_palette, PAL_JOHN * 16, 32);
	load_palette((const short*)john_bright_palette, PAL_JOHN_BRIGHT * 16, 32);
	load_palette((const short*)kakadu_palette, PAL_KAKADU * 16, 32);

	for (i = 0; i < 256; i++)
		load_sprite_x(i, 0);

	/* vsync and flash DMA interrupts */
	__out(0x7000, 0x2 | 0x8);
	global_interrupt_enable();

	flash_copy(KAKADU_FLASH, KAKADU_RAM, KAKADU_WORDS);
	john_start();
	actors_start();

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
		update_john(&john, dx, dy, (keys & KEY_B) && !(prev_keys & KEY_B), (keys & KEY_B) != 0);
		if (reload)
			reload--;
		if ((keys & KEY_A) && !(prev_keys & KEY_A) && !reload)
		{
			/* from his gun, a little below the middle of him */
			short gx = PX(john.x) + (facing_left ? 2 : JOHN_W - 2);
			actors_shoot(gx, PX(john.y) + 25, facing_left ? -1 : 1);
			reload = SHOT_GAP;
		}
		prev_keys = keys;
		actors_update();

		if (dx < 0)
			facing_left = 1;
		if (dx > 0)
			facing_left = 0;

		/* the walk cycle keeps pace with how far he walks or climbs */
		if ((john.on_ground && john.vx) || (john.climbing && john.vy))
		{
			walked += abs16(john.vx) + abs16(john.vy);
			while (walked >= FX(STEP_PX))
			{
				walked -= FX(STEP_PX);
				walk = (walk + 1) % JOHN_WALK_FRAMES;
			}
			frame = JOHN_WALK + walk;
		}
		else if (john.climbing)
			frame = JOHN_WALK + walk;	/* holding on */
		else
		{
			walked = 0;
			frame = john.on_ground ? JOHN_STAND : JOHN_WALK + 2;	/* falling */
		}
		if (facing_left)
			frame += JOHN_LEFT;
		show_frame(frame);

		/* the view follows John, up to the edges of the level */
		x = PX(john.x);
		y = PX(john.y);
		cam_x = clamp(x + JOHN_W / 2 - SCREEN_W / 2, 0, LEVEL_PX_W - SCREEN_W);
		cam_y = clamp(y + JOHN_H / 2 - SCREEN_H / 2, 0, LEVEL_PX_H - SCREEN_H);
		set_camera(cam_x, cam_y);

		n_sprites = 0;
		actors_draw(cam_x, cam_y);
		/* blinking after he's hurt; flashing with a star */
		if (!(hurt & 4))
			sprite_raw(SPRITE_RAM + pending * SLOT_WORDS, x - cam_x, y - cam_y, JOHN_W, JOHN_H,
				   star && (star > 120 || (star & 8)) && (star & 4) ? PAL_JOHN_BRIGHT : PAL_JOHN);
		hud_draw();

		while (!vsync)
			__sleep();
		vsync = 0;
		vblank();
	}
	return 0;
}
