/*
 * video.h: sprites, parallax backgrounds and copper effects for BloodLust.
 */

#ifndef VIDEO_H
#define VIDEO_H

#include "sprite_frame.h"

#define SCREEN_W	320
#define SCREEN_H	240
#define WATER_LINE	160	/* the screen is mirrored below this line: the top
				 * two thirds are the playfield */
#define RASTER_Y_OFS	16	/* screen line 0 is raster line 16 (sprite Y,
				 * copper and mirror registers use raster lines) */

/* Palette banks */
#define PAL_SPRITES	0
#define PAL_TILES	1
#define PAL_FLASH	2	/* every colour white: hit flash */

void video_init(void);

/* Sprites: call sprite_begin(), draw, then sprite_end() once per frame. */
void sprite_begin(void);
void sprite_draw(const struct sprite_frame* f, short x, short y, short pal);
void sprite_end(void);

/* Parallax: scroll the two tile layers (call once per frame). */
void parallax_update(short speed);

/* Copper: sky colours for the stage, and a white flash (frames). */
void sky_set_stage(short stage);
void sky_flash(short frames);
void sky_update(void);

/* Copy the finished frame to the hardware: call at the start of vblank */
void video_vblank(void);

#endif
