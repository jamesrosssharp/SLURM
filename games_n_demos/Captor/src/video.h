/*
 * video.h: sprites, the scrolling map, the text layer and the story screens
 * for Captor.
 */

#ifndef VIDEO_H
#define VIDEO_H

#include "sprite_frame.h"

#define SCREEN_W	640	/* game screen (640x480 mode) */
#define SCREEN_H	480
#define STORY_W		320	/* story screens (320x240 mode) */
#define STORY_H		240

/* Palette banks */
enum { PAL_SPRITES, PAL_TILES, PAL_TEXT, PAL_FLASH, PAL_IMAGE_A, PAL_IMAGE_B, PAL_SILVER };

/* Pictures for the story screens */
enum { PIC_TITLE, PIC_MAGNUS };

void video_init(void);

/* Copy the finished frame to the hardware: call at the start of vblank */
void video_vblank(void);

/* Sprites, in screen coordinates. Drawn in order: later ones on top. */
void sprite_begin(void);
void sprite_draw(const struct sprite_frame* f, short x, short y, short pal);
/* Draw only the leftmost w pixels of a frame */
void sprite_draw_w(const struct sprite_frame* f, short x, short y, short pal, short w);
void sprite_end(void);

/* Text layer: 8x8 characters, 80x60 on the game screen, 40x30 on the
 * story screens */
void text_clear(void);
void text_print(short col, short row, const char* s);
void text_center(short row, const char* s);
void text_number(short col, short row, unsigned long v, short digits);
void text_clear_row(short row);

/* The map scrolls up from the bottom (MAP_H) towards row 0 */
extern unsigned short cam_x;	/* map pixel at the left of the screen */
extern long cam_y;		/* map pixel at the top of the screen */
void map_start(short row);	/* camera at the top of a map row */
void map_scroll(short speed);	/* speed in 1/16 pixel per frame */
void map_set_x(unsigned short x);

/* Screens */
void screen_game(void);		/* 640x480: map, sprites, text */
void screen_picture(short pic);	/* 320x240: a picture, text below it */
void screen_panorama(void);	/* 640x480: the pilot, no text */

#endif
