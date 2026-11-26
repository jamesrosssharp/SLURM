/*
 * game.c: BloodLust - a parallax scrolling shooter.
 *
 * The player's airship flies west over a blood red lake, at the foot of the
 * mountains of the demon lord. Dragons, bug-planes, skiffs and boomerangs
 * attack in waves; giants wade through the lake. At the end of every stage
 * the demon rises from the water.
 *
 * Positions are in 1/16 pixel (12.4 fixed point) unless stated otherwise.
 */

#include <game_io.h>
#include "game.h"
#include "video.h"
#include "frames.h"

/*
 * Input
 */

#define KEY_UP		1
#define KEY_DOWN	2
#define KEY_LEFT	4
#define KEY_RIGHT	8
#define KEY_A		16
#define KEY_B		32

static unsigned short keys, keys_prev;

static unsigned short read_keys(void)
{
	return __in(0x1001);
}

/*
 * Utilities
 */

#define FX(px)		((short)((px) * 16))
#define PX(fx)		((short)((fx) >> 4))

static unsigned short rng_state = 0xace1;

static unsigned short rnd(void)
{
	/* 16 bit xorshift */
	rng_state ^= rng_state << 7;
	rng_state ^= rng_state >> 9;
	rng_state ^= rng_state << 8;
	return rng_state;
}

/* random number in [0, n) */
static short rnd_n(short n)
{
	return (short)(rnd() % (unsigned short)n);
}

/* sin(2 pi i / 64) * 64 */
static const signed char sine64[64] = {
	0, 6, 12, 19, 24, 30, 36, 41, 45, 49, 53, 56, 59, 61, 63, 64,
	64, 64, 63, 61, 59, 56, 53, 49, 45, 41, 36, 30, 24, 19, 12, 6,
	0, -6, -12, -19, -24, -30, -36, -41, -45, -49, -53, -56, -59, -61, -63, -64,
	-64, -64, -63, -61, -59, -56, -53, -49, -45, -41, -36, -30, -24, -19, -12, -6,
};

static short sine(short phase)
{
	return sine64[phase & 63];
}

static short abs16(short v)
{
	return v < 0 ? -v : v;
}

/*
 * Objects
 */

enum obj_type {
	OBJ_NONE,
	OBJ_BOLT,	/* player shot */
	OBJ_ORB,	/* enemy shot */
	OBJ_BUG,
	OBJ_SKIFF,
	OBJ_BOOMERANG,
	OBJ_DRAGON,
	OBJ_GIANT,
	OBJ_DEMON,
	OBJ_EXPLOSION,
	OBJ_EMBER,
};

struct obj {
	unsigned char type;
	unsigned char flash;	/* frames to draw in the flash palette */
	short x, y;		/* 12.4 */
	short vx, vy;		/* 12.4 per frame */
	short hp;
	short t;		/* age in frames */
	short base_y;		/* for wave motion */
	short param;
};

#define MAX_OBJS	56

static struct obj objs[MAX_OBJS];

static struct obj* spawn(unsigned char type, short x, short y)
{
	short i;
	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if (o->type == OBJ_NONE)
		{
			o->type = type;
			o->flash = 0;
			o->x = x;
			o->y = y;
			o->vx = 0;
			o->vy = 0;
			o->hp = 1;
			o->t = 0;
			o->base_y = y;
			o->param = 0;
			return o;
		}
	}
	return 0;
}

static short count_type(unsigned char type)
{
	short i, n = 0;
	for (i = 0; i < MAX_OBJS; i++)
		if (objs[i].type == type)
			n++;
	return n;
}

static short is_enemy(unsigned char type)
{
	return type >= OBJ_BUG && type <= OBJ_DEMON;
}

static const struct sprite_frame* obj_frame(const struct obj* o)
{
	switch (o->type)
	{
	case OBJ_BOLT:		return &FRAME_BOLT;
	case OBJ_ORB:		return &FRAME_ORB;
	case OBJ_BUG:		return &FRAME_BUG;
	case OBJ_SKIFF:		return &FRAME_SKIFF;
	case OBJ_BOOMERANG:	return &FRAME_BOOMERANG;
	case OBJ_DRAGON: {
		static const struct sprite_frame* const flap[4] = {
			&FRAME_DRAGON1, &FRAME_DRAGON2, &FRAME_DRAGON3, &FRAME_DRAGON2 };
		return flap[(o->t >> 3) & 3];
	}
	case OBJ_GIANT: {
		static const struct sprite_frame* const walk[4] = {
			&FRAME_GIANT2, &FRAME_GIANT1, &FRAME_GIANT3, &FRAME_GIANT1 };
		return walk[(o->t >> 4) & 3];
	}
	case OBJ_DEMON:
		return o->param ? &FRAME_DEMON_ATTACK : &FRAME_DEMON_IDLE;
	case OBJ_EXPLOSION:	return &FRAME_ORB;
	case OBJ_EMBER: {
		static const struct sprite_frame* const ember[3] = {
			&FRAME_EMBER0, &FRAME_EMBER1, &FRAME_EMBER2 };
		return ember[o->param];
	}
	}
	return 0;
}

/* Axis aligned hit box test between two frames at two positions */
static short overlap(const struct sprite_frame* fa, short ax, short ay,
		     const struct sprite_frame* fb, short bx, short by)
{
	ax += fa->hx;
	ay += fa->hy;
	bx += fb->hx;
	by += fb->hy;
	return ax < bx + fb->hw && bx < ax + fa->hw &&
	       ay < by + fb->hh && by < ay + fa->hh;
}

/*
 * Game state
 */

enum game_state { ST_TITLE, ST_PLAY, ST_GAME_OVER };

static short state;
static short state_t;		/* frames in the current state */
static short attract;		/* the autopilot is playing */

static unsigned long score;
static unsigned long hi_score = 20000;
static short lives;
static short stage;
static unsigned long next_bonus;

static struct {
	short x, y;		/* 12.4 */
	short alive;
	short invuln;		/* frames of invulnerability left */
	short cooldown;
	short respawn;		/* frames until respawn */
	short power;		/* 0: single shot, 1: double shot */
} player;

/* Wave script */
static short wave_t;		/* frames since the start of the stage */
static short wave_idx;
static short boss_active;
static short banner;		/* which text banner to show */
static short banner_t;

enum { BANNER_NONE, BANNER_READY, BANNER_WARNING, BANNER_STAGE };

#define PLAYFIELD_TOP		16
#define PLAYFIELD_BOTTOM	(WATER_LINE - 4)

/*
 * Effects
 */

static void explode(short x, short y, short size)
{
	short i;
	struct obj* o = spawn(OBJ_EXPLOSION, x - FX(9), y - FX(11));
	if (o)
		o->param = 24;
	for (i = 0; i < size; i++)
	{
		o = spawn(OBJ_EMBER, x, y);
		if (!o)
			break;
		o->vx = (short)(rnd_n(96) - 48);
		o->vy = (short)(rnd_n(96) - 64);
		o->param = rnd_n(3);
		o->hp = 20 + rnd_n(20);	/* lifetime */
		o->base_y = 1;		/* debris: falls with gravity */
	}
}

static void add_score(unsigned long pts)
{
	if (attract)
		return;
	score += pts;
	if (score > hi_score)
		hi_score = score;
	if (score >= next_bonus)
	{
		lives++;
		next_bonus += 30000;
	}
}

/* Fire an orb from (x, y) towards the player */
static void fire_orb(short x, short y, short speed)
{
	short dx = player.x - x;
	short dy = player.y - y;
	short m = abs16(dx) > abs16(dy) ? abs16(dx) : abs16(dy);
	struct obj* o;

	if (!player.alive || m == 0)
		return;
	o = spawn(OBJ_ORB, x - FX(9), y - FX(11));
	if (!o)
		return;
	/* speed * (dx, dy) / max(|dx|, |dy|), computed in 32 bits */
	o->vx = (short)((long)dx * speed / m);
	o->vy = (short)((long)dy * speed / m);
}

/*
 * Enemies
 */

static short enemy_points(unsigned char type)
{
	switch (type)
	{
	case OBJ_BUG:		return 100;
	case OBJ_SKIFF:		return 200;
	case OBJ_BOOMERANG:	return 150;
	case OBJ_DRAGON:	return 500;
	case OBJ_GIANT:		return 400;
	case OBJ_DEMON:		return 5000;
	}
	return 0;
}

static void spawn_enemy(unsigned char type, short y)
{
	struct obj* o = spawn(type, FX(-48), FX(y));
	short difficulty = stage;
	if (!o)
		return;

	switch (type)
	{
	case OBJ_BUG:
		o->vx = 22 + difficulty * 2;
		o->hp = 1;
		break;
	case OBJ_SKIFF:
		o->x = FX(-32);
		o->vx = 34 + difficulty * 3;
		o->hp = 2;
		o->param = 60 + rnd_n(120);	/* frames until it fires */
		break;
	case OBJ_BOOMERANG:
		o->x = FX(-16);
		o->vx = 80;			/* decelerates and comes back */
		o->hp = 1;
		break;
	case OBJ_DRAGON:
		o->x = FX(-72);
		o->vx = 14 + difficulty;
		o->hp = 6 + difficulty * 2;
		o->param = 90;
		break;
	case OBJ_GIANT:
		/* wades through the lake: feet below the water line */
		o->x = FX(-40);
		o->y = FX(WATER_LINE - 44);
		o->vx = 20;
		o->hp = 8 + difficulty * 2;
		o->param = 100 + rnd_n(100);
		break;
	case OBJ_DEMON:
		/* rises out of the lake */
		o->x = FX(16);
		o->y = FX(WATER_LINE + 8);
		o->vy = -6;
		o->hp = 60 + difficulty * 30;
		o->param = 0;
		boss_active = 1;
		break;
	}
}

static void update_enemy(struct obj* o)
{
	switch (o->type)
	{
	case OBJ_BUG:
		o->y = o->base_y + sine(o->t) * 5 / 2 * 4;
		break;

	case OBJ_SKIFF:
		if (--o->param == 0)
			fire_orb(o->x + FX(15), o->y + FX(5), 40 + stage * 4);
		break;

	case OBJ_BOOMERANG:
		/* thrown east, slows down, curves towards the player, returns */
		o->vx -= 2;
		if (o->vy == 0 && o->vx < 30)
			o->vy = (player.y > o->y) ? 6 : -6;
		break;

	case OBJ_DRAGON:
		o->y = o->base_y + sine(o->t >> 1) * 3 / 2 * 4;
		if (--o->param == 0)
		{
			fire_orb(o->x + FX(60), o->y + FX(12), 36 + stage * 4);
			o->param = 110 - stage * 10;
			if (o->param < 40)
				o->param = 40;
		}
		break;

	case OBJ_GIANT:
		if (--o->param == 0)
		{
			/* hurls a boomerang */
			struct obj* b = spawn(OBJ_BOOMERANG, o->x + FX(16), o->y + FX(10));
			if (b)
			{
				b->vx = 70;
				b->hp = 1;
			}
			o->param = 150 + rnd_n(100);
		}
		break;

	case OBJ_DEMON:
		if (o->vy < 0 && o->y <= FX(28))
			o->vy = 0;		/* risen */
		if (o->vy == 0)
		{
			short phase = o->t & 255;
			/* bob up and down, lunge every so often */
			o->y = FX(28) + sine(o->t >> 1) * 4;
			o->param = phase >= 200 && phase < 232;	/* attack pose */
			if (phase == 210 || phase == 220 || phase == 230)
			{
				short k;
				/* a fan of orbs from the claw */
				for (k = 0; k < 3 + (stage > 1); k++)
				{
					struct obj* b = spawn(OBJ_ORB, o->x + FX(140), o->y + FX(90));
					if (b)
					{
						b->vx = 40 + stage * 4;
						b->vy = (short)((k - 1) * 14 + rnd_n(9) - 4);
					}
				}
			}
			if ((o->t & 63) == 0)
				fire_orb(o->x + FX(70), o->y + FX(40), 44 + stage * 4);
			if (phase == 0)
				sky_flash(12);	/* lightning */
		}
		break;
	}
}

static void kill_enemy(struct obj* o)
{
	const struct sprite_frame* f = obj_frame(o);
	short cx = o->x + FX(f->hx + f->hw / 2);
	short cy = o->y + FX(f->hy + f->hh / 2);

	add_score(enemy_points(o->type));

	if (o->type == OBJ_DEMON)
	{
		short i;
		for (i = 0; i < 6; i++)
			explode(o->x + FX(30 + rnd_n(70)), o->y + FX(20 + rnd_n(90)), 6);
		sky_flash(40);
		boss_active = 0;
		banner = BANNER_STAGE;
		banner_t = 0;
	}
	else
		explode(cx, cy, o->type == OBJ_DRAGON || o->type == OBJ_GIANT ? 10 : 5);

	o->type = OBJ_NONE;
}

/*
 * The wave script for a stage: (frame, enemy, y, count, spacing).
 * Times are in frames at 60 Hz. The demon appears after the last wave.
 */

struct wave {
	short t;
	unsigned char type;
	short y;
	unsigned char count;
	unsigned char spacing;
};

static const struct wave waves[] = {
	{ 120,  OBJ_BUG,	40,  5, 14 },
	{ 300,  OBJ_BUG,	100, 5, 14 },
	{ 480,  OBJ_SKIFF,	30,  3, 40 },
	{ 600,  OBJ_GIANT,	0,   1, 0  },
	{ 720,  OBJ_BUG,	70,  6, 12 },
	{ 900,  OBJ_DRAGON,	40,  1, 0  },
	{ 1080, OBJ_SKIFF,	110, 3, 40 },
	{ 1200, OBJ_BUG,	30,  4, 12 },
	{ 1200, OBJ_BUG,	110, 4, 12 },
	{ 1380, OBJ_GIANT,	0,   2, 140 },
	{ 1500, OBJ_DRAGON,	30,  1, 0  },
	{ 1560, OBJ_DRAGON,	90,  1, 0  },
	{ 1800, OBJ_SKIFF,	60,  5, 30 },
	{ 1980, OBJ_BUG,	50,  8, 10 },
	{ 2200, OBJ_DRAGON,	60,  2, 90 },
};

#define N_WAVES		(short)(sizeof(waves) / sizeof(waves[0]))
#define BOSS_TIME	2600

/* Pending spawns of a wave in progress */
static struct {
	unsigned char type;
	short y;
	short left;
	short spacing;
	short timer;
} pending[4];

static void run_waves(void)
{
	short i;

	while (wave_idx < N_WAVES && waves[wave_idx].t <= wave_t)
	{
		const struct wave* w = &waves[wave_idx++];
		for (i = 0; i < 4; i++)
			if (pending[i].left == 0)
			{
				pending[i].type = w->type;
				pending[i].y = w->y;
				pending[i].left = w->count;
				pending[i].spacing = w->spacing;
				pending[i].timer = 0;
				break;
			}
	}

	for (i = 0; i < 4; i++)
	{
		if (pending[i].left && pending[i].timer-- <= 0)
		{
			spawn_enemy(pending[i].type, pending[i].y);
			pending[i].left--;
			pending[i].timer = pending[i].spacing;
		}
	}

	/* Boom-erangs from nowhere, now and then */
	if (wave_t > 400 && !boss_active && rnd_n(400) == 0)
		spawn_enemy(OBJ_BOOMERANG, 20 + rnd_n(110));

	if (wave_t == BOSS_TIME - 180)
	{
		banner = BANNER_WARNING;
		banner_t = 0;
	}
	if (wave_t == BOSS_TIME)
		spawn_enemy(OBJ_DEMON, 0);

	/* The boss stays until it is killed: the clock stops just after it
	 * appears (so it appears only once) */
	if (wave_t <= BOSS_TIME || !boss_active)
		wave_t++;
}

static void start_stage(void)
{
	short i;
	wave_t = 0;
	wave_idx = 0;
	boss_active = 0;
	for (i = 0; i < 4; i++)
		pending[i].left = 0;
	sky_set_stage(stage);
	banner = BANNER_READY;
	banner_t = 0;
}

/*
 * Player
 */

static void player_spawn(void)
{
	player.x = FX(250);
	player.y = FX(70);
	player.alive = 1;
	player.invuln = 120;
	player.cooldown = 0;
}

static void player_hit(void)
{
	if (player.invuln || !player.alive)
		return;
	explode(player.x + FX(12), player.y + FX(11), 12);
	sky_flash(8);
	player.alive = 0;
	player.respawn = 90;
	player.power = 0;
	if (!attract)
		lives--;
}

/* The autopilot (attract mode): chase the nearest enemy's height, dodge
 * shots, and keep firing. Returns a key mask. */
static unsigned short autopilot(void)
{
	unsigned short k = KEY_A;
	short target_y = FX(70);
	short best = 32767;
	short i;

	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if (is_enemy(o->type) && o->x < player.x)
		{
			short d = player.x - o->x;
			if (d < best)
			{
				best = d;
				target_y = o->y + FX(obj_frame(o)->hy + obj_frame(o)->hh / 2) - FX(11);
			}
		}
	}
	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if ((o->type == OBJ_ORB || o->type == OBJ_BOOMERANG) &&
		    o->x < player.x + FX(20) && o->x > player.x - FX(70) &&
		    abs16(o->y - player.y) < FX(24))
			target_y = o->y > player.y ? o->y - FX(40) : o->y + FX(40);
	}
	if (target_y < player.y - FX(2))
		k |= KEY_UP;
	else if (target_y > player.y + FX(2))
		k |= KEY_DOWN;
	if (player.x > FX(240 + sine(state_t >> 2) / 2))
		k |= KEY_LEFT;
	else
		k |= KEY_RIGHT;
	return k;
}

static void update_player(unsigned short k)
{
	short speed = FX(2);

	if (!player.alive)
	{
		if (--player.respawn == 0 && (lives > 0 || attract))
			player_spawn();
		return;
	}
	if (player.invuln)
		player.invuln--;

	if (k & KEY_UP)
		player.y -= speed;
	if (k & KEY_DOWN)
		player.y += speed;
	if (k & KEY_LEFT)
		player.x -= speed;
	if (k & KEY_RIGHT)
		player.x += speed;

	if (player.x < FX(8))
		player.x = FX(8);
	if (player.x > FX(SCREEN_W - 28))
		player.x = FX(SCREEN_W - 28);
	if (player.y < FX(PLAYFIELD_TOP))
		player.y = FX(PLAYFIELD_TOP);
	if (player.y > FX(PLAYFIELD_BOTTOM - 22))
		player.y = FX(PLAYFIELD_BOTTOM - 22);

	if (player.cooldown)
		player.cooldown--;
	if ((k & KEY_A) && player.cooldown == 0 && count_type(OBJ_BOLT) < 8)
	{
		struct obj* b;
		if (player.power)
		{
			b = spawn(OBJ_BOLT, player.x - FX(14), player.y + FX(3));
			if (b)
				b->vx = -FX(6);
			b = spawn(OBJ_BOLT, player.x - FX(14), player.y + FX(12));
			if (b)
				b->vx = -FX(6);
		}
		else
		{
			b = spawn(OBJ_BOLT, player.x - FX(14), player.y + FX(8));
			if (b)
				b->vx = -FX(6);
		}
		player.cooldown = 8;
	}
}

/*
 * Object update and collisions
 */

static void update_objects(void)
{
	short i, j;

	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if (o->type == OBJ_NONE)
			continue;

		o->t++;
		if (o->flash)
			o->flash--;
		o->x += o->vx;
		o->y += o->vy;

		switch (o->type)
		{
		case OBJ_BOLT:
		case OBJ_ORB:
			if (o->x < FX(-40) || o->x > FX(SCREEN_W + 8) ||
			    o->y < FX(-24) || o->y > FX(WATER_LINE))
				o->type = OBJ_NONE;
			break;
		case OBJ_EXPLOSION:
			if (--o->param == 0)
				o->type = OBJ_NONE;
			break;
		case OBJ_EMBER:
			if (o->base_y)			/* debris */
			{
				o->vy += 3;
				if (--o->hp == 0)
					o->type = OBJ_NONE;
			}
			else if (o->x > FX(SCREEN_W + 4))	/* foreground parallax */
				o->type = OBJ_NONE;
			break;
		default:
			if (is_enemy(o->type))
			{
				update_enemy(o);
				if (o->type == OBJ_DEMON)
					break;
				if (o->x > FX(SCREEN_W + 8) || (o->type == OBJ_BOOMERANG && o->x < FX(-24)))
					o->type = OBJ_NONE;
			}
			break;
		}
	}

	/* Player bolts against enemies */
	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* b = &objs[i];
		if (b->type != OBJ_BOLT)
			continue;
		for (j = 0; j < MAX_OBJS; j++)
		{
			struct obj* e = &objs[j];
			if (!is_enemy(e->type))
				continue;
			if (e->type == OBJ_DEMON && e->vy != 0)
				continue;	/* invulnerable while rising */
			if (overlap(&FRAME_BOLT, PX(b->x), PX(b->y),
				    obj_frame(e), PX(e->x), PX(e->y)))
			{
				b->type = OBJ_NONE;
				e->flash = 4;
				if (--e->hp <= 0)
					kill_enemy(e);
				else
					add_score(10);
				break;
			}
		}
	}

	/* Enemies and their shots against the player */
	if (player.alive && !player.invuln)
	{
		for (i = 0; i < MAX_OBJS; i++)
		{
			struct obj* e = &objs[i];
			if (e->type != OBJ_ORB && !is_enemy(e->type))
				continue;
			if (overlap(obj_frame(e), PX(e->x), PX(e->y),
				    &FRAME_PLAYER, PX(player.x), PX(player.y)))
			{
				player_hit();
				if (e->type == OBJ_ORB)
					e->type = OBJ_NONE;
				break;
			}
		}
	}

	/* Foreground embers drifting past (the nearest parallax layer) */
	if (rnd_n(6) == 0 && count_type(OBJ_EMBER) < 12)
	{
		struct obj* o = spawn(OBJ_EMBER, FX(-4), FX(PLAYFIELD_TOP + rnd_n(WATER_LINE - PLAYFIELD_TOP)));
		if (o)
		{
			o->vx = 40 + rnd_n(32);
			o->vy = (short)(rnd_n(9) - 4);
			o->param = rnd_n(3);
		}
	}
}

/*
 * Drawing
 */

static void draw_number(unsigned long v, short digits, short x, short y)
{
	short i;
	for (i = digits - 1; i >= 0; i--)
	{
		sprite_draw(FRAME_DIGITS[v % 10], x + i * 10, y, PAL_SPRITES);
		v /= 10;
	}
}

static void draw_objects(void)
{
	short i;

	/* Big things first, so smaller things are drawn on top of them */
	for (i = 0; i < MAX_OBJS; i++)
		if (objs[i].type == OBJ_DEMON || objs[i].type == OBJ_GIANT ||
		    objs[i].type == OBJ_DRAGON)
		{
			struct obj* o = &objs[i];
			sprite_draw(obj_frame(o), PX(o->x), PX(o->y),
				    o->flash ? PAL_FLASH : PAL_SPRITES);
		}

	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if (o->type == OBJ_NONE || o->type == OBJ_DEMON || o->type == OBJ_GIANT ||
		    o->type == OBJ_DRAGON)
			continue;
		if (o->type == OBJ_EXPLOSION && (o->param & 2))
			continue;	/* flicker */
		sprite_draw(obj_frame(o), PX(o->x), PX(o->y),
			    (o->flash || (o->type == OBJ_EXPLOSION && o->param > 16)) ? PAL_FLASH : PAL_SPRITES);
	}

	if (player.alive && !(player.invuln & 4))
		sprite_draw(&FRAME_PLAYER, PX(player.x), PX(player.y), PAL_SPRITES);
}

static void draw_hud(void)
{
	short i;

	sprite_draw(&FRAME_TEXT_SCORE, 6, 2, PAL_SPRITES);
	draw_number(score, 7, 72, 3);
	for (i = 0; i < lives && i < 5; i++)
		sprite_draw(&FRAME_LIFE, SCREEN_W - 16 - i * 14, 3, PAL_SPRITES);
}

static void draw_banner(void)
{
	if (banner == BANNER_NONE)
		return;
	banner_t++;
	if ((banner_t & 16) == 0)
	{
		switch (banner)
		{
		case BANNER_READY:
			sprite_draw(&FRAME_TEXT_GET_READY, 106, 60, PAL_SPRITES);
			break;
		case BANNER_WARNING:
			sprite_draw(&FRAME_TEXT_WARNING, 112, 60, PAL_SPRITES);
			break;
		case BANNER_STAGE:
			sprite_draw(&FRAME_TEXT_STAGE, 118, 60, PAL_SPRITES);
			draw_number(stage + 2, 1, 186, 61);
			break;
		}
	}
	if (banner_t > 150)
	{
		if (banner == BANNER_STAGE)
		{
			stage++;
			start_stage();
		}
		else
			banner = BANNER_NONE;
	}
}

/*
 * States
 */

static void clear_objects(void)
{
	short i;
	for (i = 0; i < MAX_OBJS; i++)
		objs[i].type = OBJ_NONE;
}

static void start_game(short is_attract)
{
	clear_objects();
	attract = is_attract;
	score = 0;
	lives = 3;
	stage = 0;
	next_bonus = 30000;
	player.power = 0;
	player_spawn();
	start_stage();
	state = ST_PLAY;
	state_t = 0;
}

static void title_screen(void)
{
	sprite_begin();

	/* The demon watches from the lake */
	{
		static struct obj demon;
		demon.type = OBJ_DEMON;
		demon.t = state_t;
		demon.param = (state_t & 255) > 200;
		sprite_draw(obj_frame(&demon), 16, 30 + sine(state_t >> 2) / 8, PAL_SPRITES);
	}

	sprite_draw(&FRAME_TEXT_TITLE, 128, 20, PAL_SPRITES);
	if (state_t & 32)
		sprite_draw(&FRAME_TEXT_PRESS_A, 186, 110, PAL_SPRITES);
	draw_number(hi_score, 7, 186, 80);
	sprite_end();

	if ((state_t & 255) == 0)
		sky_flash(10);

	if ((keys & KEY_A) && !(keys_prev & KEY_A))
		start_game(0);
	else if (state_t > 600)
		start_game(1);		/* attract mode */
}

void game_frame(void)
{
	unsigned short k;

	keys_prev = keys;
	keys = read_keys();
	state_t++;

	sky_update();

	switch (state)
	{
	case ST_TITLE:
		parallax_update(8);
		title_screen();
		return;

	case ST_PLAY:
		parallax_update(16);

		if (attract)
		{
			/* any key returns to the title, which starts a game */
			if (((keys & KEY_A) && !(keys_prev & KEY_A)) || state_t > 2400)
			{
				state = ST_TITLE;
				state_t = 0;
				clear_objects();
				return;
			}
			k = autopilot();
		}
		else
			k = keys;

		if (score >= 10000 && !player.power && player.alive)
			player.power = 1;

		run_waves();
		update_player(k);
		update_objects();

		sprite_begin();
		draw_objects();
		draw_hud();
		draw_banner();
		if (attract && (state_t & 32))
			sprite_draw(&FRAME_TEXT_PRESS_A, 124, 130, PAL_SPRITES);
		sprite_end();

		if (!player.alive && lives <= 0 && !attract && player.respawn <= 0)
		{
			state = ST_GAME_OVER;
			state_t = 0;
		}
		return;

	case ST_GAME_OVER:
		parallax_update(8);
		update_objects();
		sprite_begin();
		draw_objects();
		draw_hud();
		sprite_draw(&FRAME_TEXT_GAME_OVER, 106, 60, PAL_SPRITES);
		sprite_end();
		if (state_t > 300 || (state_t > 60 && (keys & KEY_A) && !(keys_prev & KEY_A)))
		{
			clear_objects();
			state = ST_TITLE;
			state_t = 0;
		}
		return;
	}
}

void game_init(void)
{
	rng_state ^= __in(0x9000) | 1;
	state = ST_TITLE;
	state_t = 0;
	sky_set_stage(0);
}
