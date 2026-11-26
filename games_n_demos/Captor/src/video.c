/*
 * video.c: sprites, the scrolling map, the text layer and the story screens
 * for Captor.
 *
 * Video memory (word addresses): the sprite sheet at 0x8000 and the tile set
 * at 0xc000, copied there by the boot loader. The story screens load their
 * pictures over them by DMA from the asset bundle in flash, and the sprite
 * sheet and tile set are loaded back afterwards.
 *
 * Background layer 0 (in front) is the text layer: 8x8 characters from the
 * font rows of the tile set, in a 128x60 tile map. Background layer 1 is the
 * map: 16x16 tiles in a 64 tile wide window of 32 rows, streamed from flash
 * into one of two buffers while the other is displayed.
 */

#include <game_io.h>
#include "video.h"
#include "bundle.h"
#include "frames.h"

/* sprite.asm / palette.asm / top.asm */
extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);
extern void load_palette(const short* palette, int offset, int len);

/* assets.asm */
extern short sprites_palette[], silver_palette[], tiles_palette[], text_palette[];
extern short title_palette[], magnus_palette[], ace1_palette[], ace2_palette[];
extern unsigned char map_buf1[], map_buf2[], text_map[];

/* Set by the interrupt handlers in top.asm */
volatile short vsync;
volatile short flash_complete;

#define SPRITE_SHEET	0x8000
#define TILE_SET	0xc000
#define TEXT_STRIDE	128		/* text map row length in tiles */
#define TEXT_ROWS	60
#define MAP_WIN_ROWS	32		/* rows in a map buffer */

/*
 * Screen modes. Sprite coordinates and background rows and columns count
 * from the start of the raster, a little before the top left corner of the
 * screen.
 */
struct mode {
	short sprite_x, sprite_y;	/* screen (0, 0) in sprite coordinates */
	short bg_left, bg_top;		/* screen (0, 0) in background raster coordinates */
	short cols, rows;		/* text layer size */
	short width;
};

static const struct mode modes[2] = {
	{ 48, 38, 48, 33, 80, 60, SCREEN_W },	/* 640x480 */
	{ 24, 16, 24, 16, 40, 30, STORY_W },	/* 320x240 */
};
static const struct mode* mode = &modes[0];

/*
 * Flash DMA
 */

#define SPI_FLASH_ADDR_LO	0x4000
#define SPI_FLASH_ADDR_HI	0x4001
#define SPI_FLASH_CMD		0x4002
#define SPI_FLASH_DMA_ADDR	0x4005
#define SPI_FLASH_DMA_COUNT	0x4006

static short dma_active;

static void flash_wait(void)
{
	while (dma_active && !flash_complete)
		__sleep();
	dma_active = 0;
}

/* Copy words from flash (word address) to memory (word address) */
static void flash_dma(unsigned long from, unsigned short to, unsigned short words)
{
	flash_wait();
	flash_complete = 0;
	dma_active = 1;
	__out(SPI_FLASH_ADDR_LO, (unsigned short)from);
	__out(SPI_FLASH_ADDR_HI, (unsigned short)(from >> 16));
	__out(SPI_FLASH_DMA_ADDR, to);
	__out(SPI_FLASH_DMA_COUNT, words - 1);
	__out(SPI_FLASH_CMD, 1);
}

#define WORD_ADDR(p)	((unsigned short)(p) >> 1)

/*
 * Sprites: each frame is built in a shadow copy of the sprite registers and
 * copied to the hardware at the start of the next vertical blank.
 */

#define MAX_SPRITES	160

static unsigned short shadow_x[MAX_SPRITES];
static unsigned short shadow_y[MAX_SPRITES];
static unsigned short shadow_h[MAX_SPRITES];
static unsigned short shadow_a[MAX_SPRITES];

static short n_sprites;		/* sprites in the frame being built */
static short n_ready;		/* sprites in the finished frame */
static short n_shown;		/* sprites enabled in the hardware */

/* The hardware draws (width + 1) pixels, rows y to h inclusive */
static void sprite_raw(unsigned short addr, short x, short y, short w, short h,
		       short pal, short stride256)
{
	if (n_sprites == MAX_SPRITES)
		return;
	x += mode->sprite_x;
	y += mode->sprite_y;
	shadow_x[n_sprites] = (x & 0x3ff) | (1 << 10) | ((pal & 15) << 11) | (stride256 << 15);
	shadow_y[n_sprites] = (y & 0x3ff) | (((w - 1) & 0x3f) << 10);
	shadow_h[n_sprites] = (y + h - 1) & 0x3ff;
	shadow_a[n_sprites] = addr;
	n_sprites++;
}

void sprite_begin(void)
{
	n_sprites = 0;
}

void sprite_draw_w(const struct sprite_frame* f, short x, short y, short pal, short max_w)
{
	short i;
	short sh = mode == &modes[0] ? SCREEN_H : STORY_H;

	for (i = 0; i < f->n; i++)
	{
		const struct sprite_part* p = &f->parts[i];
		short px = x + p->dx;
		short py = y + p->dy;
		short w = p->w;
		short h = p->h;
		unsigned short addr = p->addr;

		if (p->dx + w > max_w)
			w = max_w - p->dx;
		if (w <= 0 || px + w <= -mode->sprite_x || px >= mode->width ||
		    py + h <= 0 || py >= sh)
			continue;
		/* Clip the top: the hardware cannot start above raster line 0 */
		if (py < -mode->sprite_y)
		{
			short skip = -mode->sprite_y - py;
			addr += skip * 64;
			h -= skip;
			py += skip;
		}
		if (py + h > sh)
			h = sh - py;
		sprite_raw(addr, px, py, w, h, pal, 1);
	}
}

void sprite_draw(const struct sprite_frame* f, short x, short y, short pal)
{
	sprite_draw_w(f, x, y, pal, 1024);
}

void sprite_end(void)
{
	n_ready = n_sprites;
}

/*
 * Text layer
 */

static const unsigned char* const font = FONT_MAP;

void text_clear(void)
{
	unsigned short* p = (unsigned short*)text_map;
	short i;
	for (i = 0; i < TEXT_STRIDE * TEXT_ROWS / 2; i++)
		p[i] = 0xffff;
}

void text_clear_row(short row)
{
	unsigned short* p = (unsigned short*)&text_map[row * TEXT_STRIDE];
	short i;
	for (i = 0; i < TEXT_STRIDE / 2; i++)
		p[i] = 0xffff;
}

void text_print(short col, short row, const char* s)
{
	unsigned char* p = &text_map[row * TEXT_STRIDE + col];
	while (*s && col < mode->cols)
	{
		unsigned char c = *s++;
		if (c >= 'a' && c <= 'z')
			c -= 32;
		*p++ = (c >= 32 && c < 128) ? font[c - 32] : 255;
		col++;
	}
}

void text_center(short row, const char* s)
{
	short n = 0;
	while (s[n])
		n++;
	text_print((mode->cols - n) / 2, row, s);
}

void text_number(short col, short row, unsigned long v, short digits)
{
	char buf[12];
	short i;
	buf[digits] = 0;
	for (i = digits - 1; i >= 0; i--)
	{
		buf[i] = '0' + (char)(v % 10);
		v /= 10;
	}
	text_print(col, row, buf);
}

/*
 * Background layers. The layer registers start at 0x5d00 (layer 0) and
 * 0x5d05 (layer 1): control, X, Y, tile map address, tile set address.
 *
 * A layer's Y position cannot be negative, so to show a tile map from the
 * top of the screen (bg_top raster rows down), the tile map address is moved
 * back by whole rows instead.
 */

#define BG_ENABLE	1
#define BG_PAL(p)	((p) << 4)
#define BG_STRIDE(s)	((s) << 8)	/* 0: 256 tiles, 1: 128, 2: 64, 3: 32 */
#define BG_TILES_8x8	0x8000

static unsigned short layer_reg[2][5];	/* shadow of the layer registers */

static void bg_layer(short layer, unsigned short ctrl, short x, short y, short tile_px,
		     short row_bytes, unsigned char* map, unsigned short tileset)
{
	short top = mode->bg_top;
	short k = (top + tile_px - 1) / tile_px;	/* rows to move back */
	unsigned short* r = layer_reg[layer];

	r[0] = ctrl;
	r[1] = (x + 16 - mode->bg_left) & 0x3ff;
	r[2] = y + k * tile_px - top;
	r[3] = WORD_ADDR(map - k * row_bytes);
	r[4] = tileset;
}

static void text_layer(short on)
{
	bg_layer(0, on ? (BG_ENABLE | BG_PAL(PAL_TEXT) | BG_STRIDE(1) | BG_TILES_8x8) : 0,
		 0, 0, 8, TEXT_STRIDE, text_map, FONT_TILESET);
}

/*
 * The map. The window of MAP_WIN_ROWS rows starting at map row win_row is
 * displayed from buffer 'front', scrolled down by sub_y pixels; the other
 * buffer is being loaded with the window one row further up.
 */

unsigned short cam_x;
long cam_y;

static short map_on;
static short win_row;
static short sub_y;
static short frac;
static short front;

static unsigned char* map_buffer(short i)
{
	return i ? map_buf2 : map_buf1;
}

static void map_load(short row, short buf)
{
	flash_dma(FLASH_MAP + (unsigned long)row * (MAP_W / 2), WORD_ADDR(map_buffer(buf)),
		  MAP_W / 2 * MAP_WIN_ROWS);
}

static void map_update_regs(void)
{
	cam_y = (long)win_row * 16 + sub_y;
	bg_layer(1, map_on ? (BG_ENABLE | BG_PAL(PAL_TILES) | BG_STRIDE(2)) : 0,
		 cam_x, sub_y, 16, MAP_W, map_buffer(front), TILE_SET);
}

void map_start(short row)
{
	win_row = row;
	sub_y = 0;
	frac = 0;
	front = 0;
	map_load(row, 0);
	flash_wait();
	if (row > 0)
		map_load(row - 1, 1);
	map_on = 1;
	map_update_regs();
}

void map_set_x(unsigned short x)
{
	cam_x = x;
	map_update_regs();
}

/* Move the camera one pixel up the map */
static void map_step(void)
{
	if (sub_y > 0)
	{
		sub_y--;
		return;
	}
	if (win_row == 0)
	{
		/* the top of the map: start again from the bottom */
		map_start(MAP_H - MAP_WIN_ROWS);
		sub_y = 15;
		return;
	}
	flash_wait();		/* the window one row up is in the back buffer */
	front ^= 1;
	win_row--;
	sub_y = 15;
	if (win_row > 0)
		map_load(win_row - 1, front ^ 1);
}

void map_scroll(short speed)
{
	frac += speed;
	while (frac >= 16)
	{
		frac -= 16;
		map_step();
	}
	map_update_regs();
}

/*
 * Frame flip
 */

void video_vblank(void)
{
	short i, l;

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

	for (l = 0; l < 2; l++)
		for (i = 0; i < 5; i++)
			__out(0x5d00 + l * 5 + i, layer_reg[l][i]);
}

/*
 * Screens
 */

static void sprites_off(void)
{
	short i;
	for (i = 0; i < 256; i++)
		load_sprite_x(i, 0);
	n_shown = n_ready = n_sprites = 0;
}

/* Sprite sheet and tile set: loaded back after a picture replaced them */
static short sheet_lost, tiles_lost;

static void set_mode(short m)
{
	mode = &modes[m];
	__out(0x5f02, m);
}

void screen_game(void)
{
	flash_wait();
	sprites_off();
	if (sheet_lost)
		flash_dma(FLASH_SPRITES, SPRITE_SHEET, 16384);
	if (tiles_lost)
		flash_dma(FLASH_TILES, TILE_SET, 16384);
	flash_wait();
	sheet_lost = tiles_lost = 0;
	set_mode(0);
	text_clear();
	text_layer(1);
	map_on = 1;
	map_update_regs();
}

/* Show a 320 pixel wide picture, loaded at 'addr', as five 64 pixel strips
 * with a 320 pixel stride */
static void picture_strips(unsigned short addr, short x, short y, short rows, short pal)
{
	short i;
	for (i = 0; i < 5; i++)
		sprite_raw(addr + i * 16, x + i * 64, y, 64, rows, pal, 0);
}

void screen_picture(short pic)
{
	static const unsigned long flash[] = { FLASH_TITLE, FLASH_MAGNUS };
	static const short rows[] = { TITLE_ROWS, MAGNUS_ROWS };
	static const short* const pal[] = { title_palette, magnus_palette };

	flash_wait();
	sprites_off();
	set_mode(1);
	map_on = 0;
	map_update_regs();
	text_clear();
	text_layer(1);
	load_palette(pal[pic], PAL_IMAGE_A * 16, 16);
	flash_dma(flash[pic], SPRITE_SHEET, rows[pic] * 80);
	flash_wait();
	sheet_lost = 1;

	sprite_begin();
	picture_strips(SPRITE_SHEET, 0, 0, rows[pic], PAL_IMAGE_A);
	sprite_end();
}

void screen_panorama(void)
{
	flash_wait();
	sprites_off();
	set_mode(0);
	map_on = 0;
	map_update_regs();
	text_layer(0);		/* the font is in the tile set, which is replaced */
	load_palette(ace1_palette, PAL_IMAGE_A * 16, 16);
	load_palette(ace2_palette, PAL_IMAGE_B * 16, 16);
	flash_dma(FLASH_ACE1, SPRITE_SHEET, ACE1_ROWS * 80);
	flash_dma(FLASH_ACE2, TILE_SET, ACE2_ROWS * 80);
	flash_wait();
	sheet_lost = tiles_lost = 1;

	sprite_begin();
	picture_strips(SPRITE_SHEET, 0, (SCREEN_H - ACE1_ROWS) / 2, ACE1_ROWS, PAL_IMAGE_A);
	picture_strips(TILE_SET, 320, (SCREEN_H - ACE2_ROWS) / 2, ACE2_ROWS, PAL_IMAGE_B);
	sprite_end();
}

void video_init(void)
{
	static const short flash_palette[16] = {
		0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };

	__out(0x5d20, 0);		/* no copper */
	__out(0x5d21, 0);		/* no mirror */
	__out(0x5d22, 0);		/* black background */

	load_palette(sprites_palette, PAL_SPRITES * 16, 16);
	load_palette(silver_palette, PAL_SILVER * 16, 16);
	load_palette(tiles_palette, PAL_TILES * 16, 16);
	load_palette(text_palette, PAL_TEXT * 16, 16);
	load_palette(flash_palette, PAL_FLASH * 16, 16);

	/* vsync and flash DMA interrupts */
	__out(0x7000, 0x2 | 0x8);
	global_interrupt_enable();

	sprites_off();
	text_clear();
	set_mode(0);
}
