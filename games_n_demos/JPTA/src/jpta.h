/*
 * jpta.h: what main.c (John, the screen) and actors.c (enemies and power
 * ups) share.
 */

#ifndef JPTA_H
#define JPTA_H

#include "level.h"
#include "john.h"

#define SCREEN_W	320	/* 320x240 mode */
#define SCREEN_H	240

#define LEVEL_PX_W	(LEVEL_W * 16)
#define LEVEL_PX_H	(LEVEL_H * 16)

#define FX(px)		((short)((px) * 16))	/* pixels to 1/16 pixels */
#define PX(v)		((v) >> 4)

/* Palette banks, for 5 bpp sprites (32 colours each) */
#define PAL_JOHN	2	/* colours 32-63 */
#define PAL_KAKADU	4	/* colours 64-95 */
#define PAL_JOHN_BRIGHT	6	/* colours 96-127 */

/*
 * John. x, y is the top left of his sprite, in 1/16 pixels; he collides
 * with the box HB_L-HB_R, HB_T-HB_B inside it (from below his hair to his
 * feet).
 */
#define HB_L		8
#define HB_R		24	/* exclusive */
#define HB_T		12	/* below his hair: the level has 32 pixel gaps */
#define HB_B		JOHN_H	/* exclusive: the row under his feet */

struct john {
	short x, y;		/* 1/16 pixel */
	short vx, vy;
	short on_ground;
	short climbing;
};

/* The game, kept by actors.c */
extern struct john john;
extern unsigned short score;
extern short health;		/* hearts left */
extern short hurt;		/* frames left of not being hurt again (he blinks) */
extern short star;		/* frames left of the star: enemies can't hurt him */

#define MAX_HEALTH	3

/* main.c */
short solid(short x0, short y0, short x1, short y1);
void sprite_frame(short f, short x, short y, short pal);	/* a kakadu.h frame, at screen x, y */
void john_start(void);

/* actors.c */
void actors_start(void);
void actors_update(void);			/* move them, and meet John */
void actors_shoot(short x, short y, short dir);	/* a shot from x, y, going left (-1) or right (1) */
void actors_draw(short cam_x, short cam_y);
void hud_draw(void);

#endif
