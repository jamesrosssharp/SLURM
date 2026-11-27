/*
 * actors.c: the enemies and power ups from KakaduEnemies.png, the score
 * and John's hearts.
 *
 *   wombats    walk along a floor, turning at walls and edges
 *   radioactive wombats
 *              fly back and forth, and after John when he's near
 *   cockatoos  fly back and forth, bobbing
 *   coins      10 points
 *   hearts     a heart back (50 points if he has them all)
 *   stars      ten seconds when enemies can't hurt him and he beats them
 *              by touching them
 *
 * John beats an enemy by landing on it (and bounces off), or with his 10%
 * GST ray; otherwise it costs him a heart. With none left the level starts
 * again.
 */

#include "jpta.h"
#include "kakadu.h"

struct john john;
unsigned short score;
short health;
short hurt;
short star;

enum { A_NONE, A_FLYER, A_WOMBAT, A_BIRD, A_COIN, A_HEART, A_STAR, A_PUFF, A_SHOT, A_HIT };

#define IS_ENEMY(t)	((t) == A_FLYER || (t) == A_WOMBAT || (t) == A_BIRD)

/*
 * Positions are 1/16 pixels: x is the middle; y is the feet for wombats,
 * the middle for everything else.
 */
struct actor {
	short type;
	short x, y;
	short vx, vy;
	short dir;		/* -1 left, 1 right */
	short t;		/* frames: animation, and waiting */
	short x0, x1, y0;	/* fliers: where they fly */
};

/*
 * Where things start, in the level's tiles: col, row. Walkers and power
 * ups drop from there to the floor below; fliers fly from col to 'to'.
 */
struct spawn {
	short type;
	short col, row, to;
};

static const struct spawn spawns[] = {
	/* the surface */
	{ A_COIN, 5, 2 }, { A_COIN, 6, 2 }, { A_COIN, 7, 2 },	/* on the island */
	{ A_COIN, 10, 6 }, { A_COIN, 12, 6 }, { A_COIN, 16, 4 },
	{ A_COIN, 24, 2 }, { A_STAR, 30, 2 },
	{ A_FLYER, 14, 4, 21 },
	{ A_BIRD, 9, 3, 20 },
	/* the upper caves */
	{ A_COIN, 3, 13 }, { A_COIN, 9, 13 }, { A_COIN, 11, 13 },
	{ A_HEART, 20, 14 },
	{ A_COIN, 23, 11 }, { A_COIN, 29, 11 },
	{ A_WOMBAT, 10, 13 },
	{ A_FLYER, 23, 12, 28 },
	/* the bottom cavern */
	{ A_COIN, 4, 21 }, { A_COIN, 6, 21 }, { A_STAR, 7, 21 },	/* left ledge */
	{ A_COIN, 20, 21 }, { A_COIN, 22, 21 },			/* right ledge */
	{ A_COIN, 12, 25 }, { A_COIN, 17, 25 },
	{ A_HEART, 28, 23 },
	{ A_WOMBAT, 11, 25 }, { A_WOMBAT, 18, 25 },
	{ A_BIRD, 2, 21, 26 },
};

#define N_SPAWNS	(sizeof(spawns) / sizeof(spawns[0]))
#define MAX_ACTORS	(N_SPAWNS + 12)		/* room for puffs and shots */

static struct actor actors[MAX_ACTORS];

/* Collision boxes, from the actor's x, y in pixels: left, top, right, bottom */
struct box {
	short l, t, r, b;
};

static const struct box boxes[] = {
	[A_FLYER]  = { -16, -16, 16, 14 },
	[A_WOMBAT] = { -20, -26, 20, 0 },
	[A_BIRD]   = { -12, -9, 12, 9 },
	[A_COIN]   = { -7, -7, 7, 7 },
	[A_HEART]  = { -7, -7, 7, 7 },
	[A_STAR]   = { -9, -9, 9, 9 },
	[A_SHOT]   = { -4, -4, 4, 4 },
};

#define GRAVITY		4
#define MAX_FALL	64
#define FLY_SPEED	10	/* radioactive wombats, 1/16 pixel a frame */
#define NEAR		128	/* and they come after John from this close */
#define SHOT_SPEED	64
#define SHOT_LIFE	45	/* frames */
#define MAX_SHOTS	3
#define STAR_TIME	600
#define HURT_TIME	90

static short abs16(short v)
{
	return v < 0 ? -v : v;
}

static struct actor* new_actor(short type, short x, short y)
{
	short i;
	for (i = 0; i < MAX_ACTORS; i++)
		if (actors[i].type == A_NONE)
		{
			struct actor* a = &actors[i];
			a->type = type;
			a->x = x;
			a->y = y;
			a->vx = a->vy = 0;
			a->dir = 1;
			a->t = 0;
			return a;
		}
	return 0;
}

static void puff(short x, short y)
{
	new_actor(A_PUFF, x, y);
}

/* The floor under pixel x, y: the first solid row at or below y */
static short floor_below(short x, short y)
{
	while (y < LEVEL_PX_H - 1 && !solid(x - 4, y, x + 4, y))
		y++;
	return y;
}

void actors_start(void)
{
	short i;

	for (i = 0; i < MAX_ACTORS; i++)
		actors[i].type = A_NONE;
	for (i = 0; i < N_SPAWNS; i++)
	{
		const struct spawn* s = &spawns[i];
		short x = s->col * 16 + 8;
		short y = s->row * 16 + 8;
		struct actor* a;

		if (s->type != A_BIRD && s->type != A_FLYER)
		{
			y = floor_below(x, y);
			if (s->type >= A_COIN)
				y -= 14;		/* power ups float over the floor */
		}
		a = new_actor(s->type, FX(x), FX(y));
		if (s->type == A_BIRD || s->type == A_FLYER)
		{
			a->x0 = FX(s->col * 16);
			a->x1 = FX(s->to * 16);
			a->y0 = a->y;
			a->vx = s->type == A_BIRD ? 16 : FLY_SPEED;
		}
		a->t = i * 7;		/* so they don't all move together */
	}
	score = 0;
	health = MAX_HEALTH;
	hurt = star = 0;
}

/*
 * Movement
 */

static void walk_wombat(struct actor* a)
{
	short x = PX(a->x), y = PX(a->y);
	short front = x + a->dir * 22;

	/* falling, if there's nothing under it: a pixel at a time, to land */
	if (!solid(x - 10, y, x + 10, y))
	{
		short to;
		a->vy += GRAVITY;
		if (a->vy > MAX_FALL)
			a->vy = MAX_FALL;
		to = PX(a->y + a->vy);
		while (y < to && !solid(x - 10, y, x + 10, y))
			y++;
		if (solid(x - 10, y, x + 10, y))
		{
			a->y = FX(y);
			a->vy = 0;
		}
		else
			a->y += a->vy;
		if (PX(a->y) >= LEVEL_PX_H)
			a->type = A_NONE;
		return;
	}
	/* turn at a wall, or at the edge of the floor */
	if (solid(front, y - 24, front, y - 6) || !solid(front, y, front, y + 3))
		a->dir = -a->dir;
	else if (a->t & 1)
		a->x += FX(a->dir);
}

/* Up and down, about 10 pixels: a sine, a sixteenth of a turn a step */
static const signed char bob[16] = { 0, 4, 7, 9, 10, 9, 7, 4, 0, -4, -7, -9, -10, -9, -7, -4 };

/* Radioactive wombats: back and forth, bobbing, until John comes near;
 * then after him, but not through walls */
static void fly_flyer(struct actor* a)
{
	short x = PX(a->x), y = PX(a->y);
	short jx = PX(john.x) + JOHN_W / 2, jy = PX(john.y) + JOHN_H / 2;
	const struct box* b = &boxes[A_FLYER];
	short dx = 0, dy = 0;

	if (abs16(jx - x) < NEAR && abs16(jy - y) < NEAR)
	{
		dx = jx < x - 4 ? -FLY_SPEED : jx > x + 4 ? FLY_SPEED : 0;
		dy = jy < y - 4 ? -FLY_SPEED : jy > y + 4 ? FLY_SPEED : 0;
		a->y0 = a->y;		/* bob from here when it gives up */
		if (dx)
			a->dir = dx > 0 ? 1 : -1;
	}
	else
	{
		if (a->x <= a->x0)
			a->vx = FLY_SPEED;
		if (a->x >= a->x1)
			a->vx = -FLY_SPEED;
		dx = a->vx;
		dy = a->y0 + FX(bob[(a->t >> 3) & 15]) / 2 - a->y;
		a->dir = dx > 0 ? 1 : -1;
	}
	/* each way only if it doesn't fly into the level */
	if (dx && !solid(PX(a->x + dx) + b->l, y + b->t, PX(a->x + dx) + b->r, y + b->b))
		a->x += dx;
	else if (dx && !(abs16(jx - x) < NEAR))
		a->vx = -a->vx;
	x = PX(a->x);
	if (dy && !solid(x + b->l, PX(a->y + dy) + b->t, x + b->r, PX(a->y + dy) + b->b))
		a->y += dy;
}

static void fly_bird(struct actor* a)
{
	a->x += a->vx;
	if (a->x <= a->x0)
		a->vx = 16;
	if (a->x >= a->x1)
		a->vx = -16;
	a->dir = a->vx > 0 ? 1 : -1;
	a->y = a->y0 + FX(bob[(a->t >> 2) & 15]);
}

/*
 * Meeting John
 */

static void john_box(struct box* b)
{
	short x = PX(john.x), y = PX(john.y);
	b->l = x + HB_L;
	b->r = x + HB_R - 1;
	b->t = y + HB_T;
	b->b = y + HB_B - 1;
}

static short touching(const struct box* j, const struct actor* a)
{
	const struct box* r = &boxes[a->type];
	short x = PX(a->x), y = PX(a->y);
	return j->r >= x + r->l && j->l <= x + r->r && j->b >= y + r->t && j->t <= y + r->b;
}

static void beaten(struct actor* a, short points)
{
	const struct box* r = &boxes[a->type];
	puff(a->x, a->y + FX((r->t + r->b) / 2));
	a->type = A_NONE;
	score += points;
}

static void hurt_john(const struct actor* a)
{
	short jx = PX(john.x) + JOHN_W / 2;

	health--;
	hurt = HURT_TIME;
	john.climbing = 0;
	john.vy = -48;
	john.vx = jx < PX(a->x) ? -48 : 48;	/* knocked away */
}

static void meet_john(struct actor* a)
{
	struct box j;

	john_box(&j);
	if (!touching(&j, a))
		return;
	switch (a->type)
	{
	case A_FLYER:
	case A_WOMBAT:
	case A_BIRD:
		if (star)
			beaten(a, 200);
		else if (john.vy > 0 && j.b <= PX(a->y) + boxes[a->type].t + 10)
		{
			/* landed on it */
			beaten(a, 100);
			john.vy = -80;
		}
		else if (!hurt)
			hurt_john(a);
		break;
	case A_COIN:
		beaten(a, 10);
		break;
	case A_HEART:
		if (health < MAX_HEALTH)
		{
			health++;
			beaten(a, 0);
		}
		else
			beaten(a, 50);
		break;
	case A_STAR:
		star = STAR_TIME;
		beaten(a, 50);
		break;
	}
}

/*
 * John's 10% GST ray
 */

void actors_shoot(short x, short y, short dir)
{
	short i, n = 0;
	struct actor* a;

	for (i = 0; i < MAX_ACTORS; i++)
		if (actors[i].type == A_SHOT)
			n++;
	if (n >= MAX_SHOTS)
		return;
	a = new_actor(A_SHOT, FX(x), FX(y));
	if (a)
	{
		a->vx = dir * SHOT_SPEED;
		a->dir = dir;
	}
}

static void move_shot(struct actor* s)
{
	short i, x, y;

	s->x += s->vx;
	x = PX(s->x);
	y = PX(s->y);
	if (s->t > SHOT_LIFE || solid(x - 2, y - 2, x + 2, y + 2))
	{
		s->type = A_HIT;
		s->t = 0;
		return;
	}
	for (i = 0; i < MAX_ACTORS; i++)
	{
		struct actor* e = &actors[i];
		const struct box* b = &boxes[e->type];
		short ex = PX(e->x), ey = PX(e->y);
		if (!IS_ENEMY(e->type))
			continue;
		if (x + 4 >= ex + b->l && x - 4 <= ex + b->r && y + 4 >= ey + b->t && y - 4 <= ey + b->b)
		{
			beaten(e, 100);
			s->type = A_HIT;
			s->t = 0;
			return;
		}
	}
}

void actors_update(void)
{
	short i;

	if (hurt)
		hurt--;
	if (star)
		star--;
	for (i = 0; i < MAX_ACTORS; i++)
	{
		struct actor* a = &actors[i];
		if (a->type == A_NONE)
			continue;
		a->t++;
		switch (a->type)
		{
		case A_FLYER:
			fly_flyer(a);
			break;
		case A_WOMBAT:
			walk_wombat(a);
			break;
		case A_BIRD:
			fly_bird(a);
			break;
		case A_PUFF:
			if (a->t >= 20)
				a->type = A_NONE;
			continue;
		case A_SHOT:
			move_shot(a);
			continue;
		case A_HIT:
			if (a->t >= 8)
				a->type = A_NONE;
			continue;
		}
		if (a->type != A_NONE)
			meet_john(a);
	}
	if (health <= 0)
	{
		/* out of hearts: start again */
		actors_start();
		john_start();
	}
}

/*
 * Drawing
 */

static const unsigned char coin_frames[6] = { K_COIN0, K_COIN1, K_COIN2, K_COIN3, K_COIN4, K_COIN5 };
static const unsigned char heart_frames[8] = { K_HEART0, K_HEART1, K_HEART2, K_HEART1,
					       K_HEART0, K_HEART0, K_HEART0, K_HEART0 };
static const unsigned char star_frames[4] = { K_STAR0, K_STAR1, K_STAR2, K_STAR3 };
static const unsigned char bird_frames[2][4] = {
	{ K_BIRD_L_GLIDE, K_BIRD_L_UP, K_BIRD_L_GLIDE, K_BIRD_L_CURL },
	{ K_BIRD_R_GLIDE, K_BIRD_R_UP, K_BIRD_R_GLIDE, K_BIRD_R_CURL },
};
static const unsigned char puff_frames[4] = { K_PUFF0, K_PUFF1, K_PUFF2, K_PUFF3 };

static short frame_of(const struct actor* a)
{
	short right = a->dir > 0;

	switch (a->type)
	{
	case A_FLYER:
		if ((a->t >> 3) & 1)
			return right ? K_FLYER_R1 : K_FLYER_L1;
		return right ? K_FLYER_R0 : K_FLYER_L0;
	case A_SHOT:
		return K_SHOT0;
	case A_HIT:
		return a->t < 4 ? K_SHOT1 : K_SHOT2;
	case A_WOMBAT:
		return right ? K_WOMBAT_R : K_WOMBAT_L;
	case A_BIRD:
		return bird_frames[right][(a->t / 6) & 3];
	case A_COIN:
		return coin_frames[(a->t / 5) % 6];
	case A_HEART:
		return heart_frames[(a->t / 6) & 7];
	case A_STAR:
		return star_frames[(a->t / 6) & 3];
	default:
		return puff_frames[(a->t / 5) & 3];
	}
}

void actors_draw(short cam_x, short cam_y)
{
	short i;

	for (i = 0; i < MAX_ACTORS; i++)
	{
		const struct actor* a = &actors[i];
		short f, x, y;
		const struct kframe* k;

		if (a->type == A_NONE)
			continue;
		f = frame_of(a);
		k = &kframes[f];
		x = PX(a->x) - cam_x - k->w / 2;
		y = PX(a->y) - cam_y;
		if (a->type == A_WOMBAT)
			y -= k->h;		/* standing on its feet */
		else
			y -= k->h / 2;
		if (a->type == A_WOMBAT && (a->t & 16))
			y--;			/* a waddle */
		if (x + k->w <= -24 || x >= SCREEN_W || y + k->h <= 0 || y >= SCREEN_H)
			continue;
		sprite_frame(f, x, y, PAL_KAKADU);
	}
}

/* Hearts at the top left, the score at the top right */
void hud_draw(void)
{
	short i, x;
	unsigned short s = score;

	for (i = 0; i < health; i++)
		sprite_frame(K_HEART0, 6 + i * 18, 6, PAL_KAKADU);
	x = SCREEN_W - 6 - 12;
	for (i = 0; i < 5; i++)
	{
		sprite_frame(K_DIGIT0 + s % 10, x, 6, PAL_KAKADU);
		s /= 10;
		x -= 12;
	}
}
