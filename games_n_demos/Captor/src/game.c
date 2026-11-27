/*
 * game.c: Captor - a vertical scrolling shooter.
 *
 * The trillionaire Magnus Grasp'em holds your sister captive in his vast
 * sewage treatment complex. Fly up the sludge river, through four stages of
 * fighters, jets, bombers, gunboats and gun emplacements, sink his
 * dreadnought at the end of each stage, and set her free.
 *
 * Controls: the d-pad flies the plane, A fires, B makes an evasive roll
 * (three per plane; you cannot be hit while rolling). Shoot down a whole
 * formation of fighters and a worker escapes from the works: pick him up for
 * more guns and some energy.
 *
 * Positions are in 1/16 pixel (12.4 fixed point) screen coordinates unless
 * stated otherwise; ground and sea targets are fixed to the map.
 */

#include <game_io.h>
#include "game.h"
#include "video.h"
#include "frames.h"
#include "spawns.h"
#include "bundle.h"

#define KEY_UP		1
#define KEY_DOWN	2
#define KEY_LEFT	4
#define KEY_RIGHT	8
#define KEY_A		16
#define KEY_B		32

#define FX(px)		((short)((px) * 16))
#define PX(fx)		((short)((fx) >> 4))

static unsigned short keys, keys_prev;

static unsigned short read_keys(void)
{
	return __in(0x1001);
}

static short pressed(unsigned short k)
{
	return (keys & k) && !(keys_prev & k);
}

/*
 * Utilities
 */

static unsigned short rnd_state = 0x1234;

static unsigned short rnd(void)
{
	rnd_state ^= rnd_state << 7;
	rnd_state ^= rnd_state >> 9;
	rnd_state ^= rnd_state << 8;
	return rnd_state;
}

static short rnd_n(short n)
{
	return (short)(rnd() % (unsigned short)n);
}

static short abs16(short v)
{
	return v < 0 ? -v : v;
}

/* sine table, 64 steps per turn, amplitude 16 */
static const signed char sine64[64] = {
	0, 2, 3, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 15, 16, 16,
	16, 16, 16, 15, 15, 14, 13, 12, 11, 10, 9, 8, 6, 5, 3, 2,
	0, -2, -3, -5, -6, -8, -9, -10, -11, -12, -13, -14, -15, -15, -16, -16,
	-16, -16, -16, -15, -15, -14, -13, -12, -11, -10, -9, -8, -6, -5, -3, -2,
};

static short sine(short a)
{
	return sine64[a & 63];
}

/*
 * Objects
 */

enum {
	OBJ_NONE,
	OBJ_TRACER,	/* player shot */
	OBJ_SHOT,	/* enemy shot */
	OBJ_FIGHTER,
	OBJ_WING,
	OBJ_JET,
	OBJ_LEADER,
	OBJ_BOMBER,
	OBJ_GUNBOAT,	/* on the map */
	OBJ_BUNKER,	/* on the map */
	OBJ_AAGUN,	/* on the map */
	OBJ_BOSS,
	OBJ_EXPLOSION,
	OBJ_MAN,	/* worker to pick up */
};

struct obj {
	unsigned char type;
	unsigned char flash;	/* frames to draw white after a hit */
	short x, y;		/* screen position */
	short vx, vy;
	short t;		/* age in frames */
	short hp;
	short param;		/* type specific */
	short param2;
	short mx, my;		/* map position (map objects): 1/16 px, px */
	unsigned char formation;
	unsigned char frame;	/* type specific frame choice */
};

#define MAX_OBJS	72
static struct obj objs[MAX_OBJS];

static struct obj* spawn(unsigned char type, short x, short y)
{
	short i;
	for (i = 0; i < MAX_OBJS; i++)
		if (objs[i].type == OBJ_NONE)
		{
			struct obj* o = &objs[i];
			o->type = type;
			o->flash = 0;
			o->x = x;
			o->y = y;
			o->vx = o->vy = 0;
			o->t = 0;
			o->hp = 1;
			o->param = o->param2 = 0;
			o->formation = 0;
			o->frame = 0;
			return o;
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
	return type >= OBJ_FIGHTER && type <= OBJ_BOSS;
}

static short on_map(unsigned char type)
{
	return type >= OBJ_GUNBOAT && type <= OBJ_AAGUN;
}

/* The squadron leader's barrel roll: frames, and frames shown each */
#define LEADER_ROLL_FRAMES	16
#define LEADER_ROLL_STEP	4
#define LEADER_ROLL_TIME	(LEADER_ROLL_FRAMES * LEADER_ROLL_STEP)

static const struct sprite_frame* obj_frame(const struct obj* o)
{
	switch (o->type)
	{
	case OBJ_TRACER:	return &FRAME_TRACER;
	case OBJ_SHOT:		return &FRAME_SHOT;
	case OBJ_FIGHTER: {
		static const struct sprite_frame* const f[9] = {
			&FRAME_FIGHTER_DOWN0, &FRAME_FIGHTER_DOWN1, &FRAME_FIGHTER_DOWN2,
			&FRAME_FIGHTER_DOWN4, &FRAME_FIGHTER_UP4,
			&FRAME_FIGHTER_UP2, &FRAME_FIGHTER_UP1, &FRAME_FIGHTER_UP0,
			&FRAME_FIGHTER_UP3 };
		return f[o->frame];
	}
	case OBJ_WING:		return &FRAME_WING;
	case OBJ_JET:		return (o->t & 4) ? &FRAME_JET1 : &FRAME_JET2;
	case OBJ_LEADER: {
		/* level, over onto its back and round to level again; rolling
		 * the other way plays the frames backwards */
		static const struct sprite_frame* const f[LEADER_ROLL_FRAMES] = {
			&FRAME_LEADER, &FRAME_LEADER_ROLL1, &FRAME_LEADER_ROLL2,
			&FRAME_LEADER_ROLL3, &FRAME_LEADER_ROLL4, &FRAME_LEADER_ROLL5,
			&FRAME_LEADER_ROLL6, &FRAME_LEADER_ROLL7, &FRAME_LEADER_ROLL8,
			&FRAME_LEADER_ROLL9, &FRAME_LEADER_ROLL10, &FRAME_LEADER_ROLL11,
			&FRAME_LEADER_ROLL12, &FRAME_LEADER_ROLL13, &FRAME_LEADER_ROLL14,
			&FRAME_LEADER_ROLL15 };
		short i = o->param ? (LEADER_ROLL_TIME - o->param) / LEADER_ROLL_STEP : 0;
		return f[o->param2 > 0 ? i : (LEADER_ROLL_FRAMES - i) % LEADER_ROLL_FRAMES];
	}
	case OBJ_BOMBER:	return &FRAME_BOMBER;
	case OBJ_GUNBOAT:	return o->vx < 0 ? &FRAME_GUNBOAT_L : &FRAME_GUNBOAT_R;
	case OBJ_BUNKER: {
		static const struct sprite_frame* const f[3] = {
			&FRAME_BUNKER1, &FRAME_BUNKER2, &FRAME_BUNKER3 };
		return f[o->frame];
	}
	case OBJ_AAGUN:		return &FRAME_AAGUN;
	case OBJ_BOSS:		return &FRAME_BATTLESHIP;
	case OBJ_EXPLOSION: {
		static const struct sprite_frame* const f[5] = {
			&FRAME_EXP1, &FRAME_EXP2, &FRAME_EXP3, &FRAME_RING1, &FRAME_RING2 };
		return f[o->t >> 2 < 5 ? o->t >> 2 : 4];
	}
	case OBJ_MAN:		return (o->t & 16) ? &FRAME_MAN1 : &FRAME_MAN2;
	}
	return &FRAME_SHOT;
}

/* Hit box test between two frames at two positions (pixels) */
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

/* Centre of an object, in 1/16 px */
static short centre_x(const struct obj* o)
{
	const struct sprite_frame* f = obj_frame(o);
	return o->x + FX(f->hx + f->hw / 2);
}

static short centre_y(const struct obj* o)
{
	const struct sprite_frame* f = obj_frame(o);
	return o->y + FX(f->hy + f->hh / 2);
}

/*
 * Game state
 */

enum { ST_TITLE, ST_STORY, ST_PLAY, ST_GAME_OVER, ST_VICTORY, ST_ENDING };

static short state;
static short state_t;
static short attract;		/* the autopilot is playing */
static unsigned long score, hi_score = 20000;
static short stage;		/* 0..3 */
static long stage_px;		/* pixels scrolled this stage */
static short stage_frac;
static short boss_active;
static short message_t;		/* frames left to show the centre message */
static short hud_dirty;

#define N_STAGES	4
#define STAGE_LENGTH	3600	/* pixels of map before the dreadnought */
#define SCROLL_SPEED	8	/* 1/16 pixel per frame */

#define ENERGY_MAX	100	/* = the width of the energy bar */

static struct {
	short x, y;
	short alive;
	short respawn;		/* frames until the next plane */
	short invuln;
	short cooldown;
	short roll;		/* frames left of a roll */
	short rolls;		/* rolls left */
	short energy;
	short power;		/* 0..2 */
	short lives;
} player;

#define PLAYER_TOP	40
#define PLAYER_BOTTOM	(SCREEN_H - 40)

/* Formations of fighters: a worker escapes when all are shot down */
#define MAX_FORMATIONS	8
static struct {
	short left;		/* still flying */
	short shot;		/* shot down */
	short size;
	short silver;		/* carries a worker */
} formations[MAX_FORMATIONS];

static void add_score(unsigned long pts)
{
	if (attract)
		return;
	score += pts;
	if (score > hi_score)
		hi_score = score;
	hud_dirty = 1;
}

static void explode(short x, short y)
{
	struct obj* o = spawn(OBJ_EXPLOSION, x - FX(15), y - FX(16));
	if (o)
		o->param = rnd_n(3);
}

/* Fire a shot from (x, y) at the player */
static void fire_at_player(short x, short y, short speed)
{
	short dx, dy, m;
	struct obj* o;

	if (!player.alive || y > FX(SCREEN_H - 16))
		return;
	dx = player.x + FX(17) - x;
	dy = player.y + FX(18) - y;
	m = abs16(dx) > abs16(dy) ? abs16(dx) : abs16(dy);
	if (m == 0)
		return;
	o = spawn(OBJ_SHOT, x - FX(3), y - FX(3));
	if (!o)
		return;
	o->vx = (short)((long)dx * speed / m);
	o->vy = (short)((long)dy * speed / m);
}

static short shot_speed(void)
{
	return 40 + stage * 6;
}

/*
 * Enemies
 */

/* Fighter flight plans */
enum { PLAN_DIVE, PLAN_LOOP, PLAN_SWOOP_L, PLAN_SWOOP_R };

static void fighter_frame(struct obj* o)
{
	/* nose down while diving, through the roll frames to nose up */
	if (o->vy > FX(1))
		o->frame = abs16(o->vx) > FX(1) ? 1 : 0;
	else if (o->vy > FX(1) / 2)
		o->frame = 2;
	else if (o->vy > 0)
		o->frame = 3;
	else if (o->vy > -FX(1) / 2)
		o->frame = 4;
	else if (o->vy > -FX(1))
		o->frame = 5;
	else
		o->frame = abs16(o->vx) > FX(1) ? 6 : 7;
}

static void update_fighter(struct obj* o)
{
	switch (o->param)
	{
	case PLAN_DIVE:
		/* dive, then bank towards the player */
		if (o->y > FX(160) && o->t < 400)
		{
			if (player.x + FX(10) > o->x && o->vx < FX(2))
				o->vx += 2;
			else if (player.x + FX(10) < o->x && o->vx > -FX(2))
				o->vx -= 2;
		}
		break;
	case PLAN_LOOP:
		/* dive, turn round and climb back up */
		if (o->y > FX(o->param2))
			o->vy -= 3;
		if (o->vy < -FX(3))
			o->vy = -FX(3);
		break;
	case PLAN_SWOOP_L:
	case PLAN_SWOOP_R:
		/* come in from a top corner and curve across and down */
		if (o->t > 30)
		{
			short d = o->param == PLAN_SWOOP_L ? -1 : 1;
			if (abs16(o->vx) > FX(1) / 2)
				o->vx += d * 2;
			if (o->vy < FX(3))
				o->vy += 2;
		}
		break;
	}
	fighter_frame(o);
	if (o->t == 40 + (o->formation & 3) * 9 && rnd_n(3) < 1 + stage)
		fire_at_player(centre_x(o), centre_y(o), shot_speed());
}

static void update_enemy(struct obj* o)
{
	switch (o->type)
	{
	case OBJ_FIGHTER:
		update_fighter(o);
		break;

	case OBJ_WING:
		o->vx = sine(o->t + o->param) * 3;
		break;

	case OBJ_JET:
		/* climbs from behind, straight and fast */
		break;

	case OBJ_LEADER:
		/* param: frames left of a barrel roll, param2: its direction */
		if (o->param == 0 && (o->t == 50 || o->t == 170))
		{
			o->param = LEADER_ROLL_TIME;
			o->param2 = o->x < FX(SCREEN_W / 2 - 17) ? 1 : -1;
		}
		if (o->param)
		{
			/* a corkscrew: slide sideways, fastest on its back */
			o->param--;
			o->vx = o->param2 * sine((LEADER_ROLL_TIME - o->param) / 2) * 3 / 2;
			if (o->param == 0)
				o->vx = 0;
		}
		else if (o->y < FX(320) && (o->t % 50) == 25)
			fire_at_player(centre_x(o), centre_y(o) - FX(10), shot_speed());
		break;

	case OBJ_BOMBER:
		if (o->y < FX(400) && (o->t % (60 - stage * 8)) == 0)
		{
			fire_at_player(o->x + FX(8), o->y + FX(20), shot_speed());
			fire_at_player(o->x + FX(28), o->y + FX(20), shot_speed());
		}
		break;

	case OBJ_GUNBOAT:
	case OBJ_BUNKER:
	case OBJ_AAGUN:
		/* fixed to the map: the gunboats steam across it */
		o->mx += o->vx;
		if (o->y > FX(-10) && o->y < FX(SCREEN_H - 120) &&
		    (o->t % o->param) == o->param2)
			fire_at_player(centre_x(o), centre_y(o), shot_speed());
		break;

	case OBJ_BOSS:
	{
		short phase = o->t % 240;
		/* sails in from the top, then steams to and fro */
		if (o->y < FX(56))
			o->vy = FX(1) / 2;
		else
		{
			o->vy = 0;
			if (o->vx == 0)
				o->vx = FX(1);
			if ((o->x > FX(SCREEN_W - 170) && o->vx > 0) || (o->x < FX(16) && o->vx < 0))
				o->vx = -o->vx;
			/* the turrets fire at the player */
			if ((phase % (40 - stage * 5)) == 0)
			{
				fire_at_player(o->x + FX(40), o->y + FX(13), shot_speed());
				fire_at_player(o->x + FX(104), o->y + FX(13), shot_speed());
			}
			/* and every so often a fan of shots from the bow */
			if (phase == 120 || (stage > 1 && phase == 200))
			{
				short k;
				for (k = -3; k <= 3; k++)
				{
					struct obj* s = spawn(OBJ_SHOT, o->x + FX(140), o->y + FX(14));
					if (s)
					{
						s->vx = k * 12;
						s->vy = shot_speed();
					}
				}
			}
		}
		break;
	}
	}
}

static short enemy_points(unsigned char type)
{
	switch (type)
	{
	case OBJ_FIGHTER:	return 100;
	case OBJ_WING:		return 200;
	case OBJ_JET:		return 150;
	case OBJ_LEADER:	return 500;
	case OBJ_BOMBER:	return 1000;
	case OBJ_GUNBOAT:	return 500;
	case OBJ_BUNKER:	return 800;
	case OBJ_AAGUN:		return 600;
	case OBJ_BOSS:		return 10000;
	}
	return 0;
}

static void show_message(void);

static void kill_enemy(struct obj* o, short by_player)
{
	short cx = centre_x(o), cy = centre_y(o);

	if (by_player)
		add_score(enemy_points(o->type));

	if (o->type == OBJ_FIGHTER && o->formation)
	{
		short f = o->formation;
		formations[f].left--;
		if (by_player)
			formations[f].shot++;
		/* a whole silver formation shot down: a worker escapes */
		if (formations[f].left == 0 && formations[f].shot == formations[f].size &&
		    formations[f].silver)
		{
			struct obj* m = spawn(OBJ_MAN, cx - FX(5), cy);
			if (m)
				m->vy = FX(1) / 2;
		}
	}

	if (o->type == OBJ_BOSS)
	{
		short i;
		for (i = 0; i < 8; i++)
			explode(o->x + FX(10 + rnd_n(130)), o->y + FX(rnd_n(26)));
		boss_active = 0;
		message_t = 0;
		state_t = 0;
		if (stage == N_STAGES - 1 && !attract)
		{
			state = ST_VICTORY;
		}
		else
		{
			stage++;
			stage_px = 0;
			message_t = 180;
			show_message();
		}
	}
	else
	{
		explode(cx, cy);
		if (o->type == OBJ_BOMBER || o->type == OBJ_LEADER || on_map(o->type))
			explode(cx + FX(rnd_n(16) - 8), cy + FX(rnd_n(16) - 8));
	}
	o->type = OBJ_NONE;
}

/*
 * Waves
 */

static short wave_timer;
static short next_formation = 1;

static short new_formation(short size)
{
	short f = next_formation;
	next_formation = next_formation % (MAX_FORMATIONS - 1) + 1;
	formations[f].left = size;
	formations[f].shot = 0;
	formations[f].size = size;
	formations[f].silver = rnd_n(3) == 0;
	return f;
}

/* A queue of fighters entering one after another */
static struct {
	short left;
	short timer;
	short spacing;
	short x, dx;
	short plan, turn;
	short formation;
} queue[3];

static void launch_fighters(short n, short x, short dx, short plan, short spacing)
{
	short i;
	for (i = 0; i < 3; i++)
		if (queue[i].left == 0)
		{
			queue[i].left = n;
			queue[i].timer = 0;
			queue[i].spacing = spacing;
			queue[i].x = x;
			queue[i].dx = dx;
			queue[i].plan = plan;
			queue[i].turn = 200 + rnd_n(120);
			queue[i].formation = new_formation(n);
			return;
		}
}

static void run_queues(void)
{
	short i;
	for (i = 0; i < 3; i++)
	{
		if (queue[i].left == 0 || queue[i].timer-- > 0)
			continue;
		{
			struct obj* o;
			short x = queue[i].x, y = -40;
			if (queue[i].plan == PLAN_SWOOP_L)
				x = SCREEN_W + 10, y = 40;
			else if (queue[i].plan == PLAN_SWOOP_R)
				x = -40, y = 40;
			o = spawn(OBJ_FIGHTER, FX(x), FX(y));
			if (o)
			{
				o->param = queue[i].plan;
				o->param2 = queue[i].turn;
				o->formation = (unsigned char)queue[i].formation;
				o->hp = 1;
				switch (queue[i].plan)
				{
				case PLAN_DIVE:
				case PLAN_LOOP:
					o->vy = FX(3) + stage * 4;
					break;
				case PLAN_SWOOP_L:
					o->vx = -FX(4);
					o->vy = FX(1) / 2;
					break;
				case PLAN_SWOOP_R:
					o->vx = FX(4);
					o->vy = FX(1) / 2;
					break;
				}
			}
			else
				formations[queue[i].formation].left--;
			queue[i].x += queue[i].dx;
			queue[i].left--;
			queue[i].timer = queue[i].spacing;
		}
	}
}

static void spawn_wave(void)
{
	short kind = rnd_n(stage == 0 ? 6 : 8);
	short x = 60 + rnd_n(SCREEN_W - 160);

	switch (kind)
	{
	case 0:
	case 1:
		/* a column of fighters diving at the player */
		launch_fighters(5, x, 0, PLAN_DIVE, 14);
		break;
	case 2:
		/* a line of fighters that loop back */
		launch_fighters(5, x < 320 ? x : x - 160, 40, PLAN_LOOP, 8);
		break;
	case 3:
		/* fighters swooping in from a top corner */
		launch_fighters(5, 0, 0, rnd_n(2) ? PLAN_SWOOP_L : PLAN_SWOOP_R, 12);
		break;
	case 4:
	{
		/* jets climbing from behind */
		short i;
		for (i = 0; i < 2 + stage; i++)
		{
			struct obj* o = spawn(OBJ_JET, FX(40 + rnd_n(SCREEN_W - 120)), FX(SCREEN_H + 20 + i * 40));
			if (o)
				o->vy = -FX(5) - stage * 6;
		}
		break;
	}
	case 5:
	{
		/* flying wings, weaving */
		short i;
		for (i = 0; i < 3; i++)
		{
			struct obj* o = spawn(OBJ_WING, FX(x), FX(-40 - i * 40));
			if (o)
			{
				o->vy = FX(3) + stage * 4;
				o->hp = 2;
				o->param = i * 8;
			}
		}
		break;
	}
	case 6:
	{
		/* a squadron leader climbing from behind */
		struct obj* o = spawn(OBJ_LEADER, FX(x), FX(SCREEN_H + 20));
		if (o)
		{
			o->vy = -FX(2);
			o->hp = 4 + stage;
		}
		break;
	}
	case 7:
	{
		/* a bomber, slowly climbing over the player */
		struct obj* o = spawn(OBJ_BOMBER, FX(x), FX(SCREEN_H + 20));
		if (o)
		{
			o->vy = -FX(1);
			o->hp = 12 + stage * 4;
		}
		break;
	}
	}
}

/* Ground targets and gunboats from the spawn table, as the map scrolls */
static short next_spawn;

static void spawn_map_objects(void)
{
	/* map row just above the top of the screen */
	short row = (short)((cam_y - 48) >> 4);

	while (next_spawn < N_SPAWNS && SPAWNS[next_spawn].row > row + 40)
		next_spawn++;		/* already scrolled past */
	while (next_spawn < N_SPAWNS && SPAWNS[next_spawn].row >= row)
	{
		const struct spawn* s = &SPAWNS[next_spawn++];
		struct obj* o;
		if (boss_active || rnd_n(4) == 0)
			continue;
		if (s->type == SPAWN_GROUND)
		{
			short aa = rnd_n(3) == 0;
			o = spawn(aa ? OBJ_AAGUN : OBJ_BUNKER, 0, 0);
			if (!o)
				continue;
			o->frame = rnd_n(3);
			o->hp = aa ? 3 : 6;
			o->param = aa ? 50 : 90;
		}
		else
		{
			o = spawn(OBJ_GUNBOAT, 0, 0);
			if (!o)
				continue;
			o->vx = rnd_n(2) ? 6 : -6;
			o->hp = 5;
			o->param = 100;
		}
		o->param -= stage * 10;
		o->param2 = rnd_n(o->param);
		o->mx = FX(s->col * 16);
		o->my = s->row * 16;
	}
}

static void run_waves(void)
{
	if (boss_active)
		return;
	if (stage_px >= STAGE_LENGTH)
	{
		struct obj* o = spawn(OBJ_BOSS, FX(SCREEN_W / 2 - 76), FX(-30));
		if (o)
		{
			o->hp = 120 + stage * 60;
			boss_active = 1;
			message_t = 150;
			show_message();
		}
		return;
	}
	if (--wave_timer <= 0)
	{
		spawn_wave();
		wave_timer = 100 - stage * 12 + rnd_n(50);
	}
	run_queues();
	spawn_map_objects();
}

/*
 * Player
 */

static void player_spawn(void)
{
	player.x = FX(SCREEN_W / 2 - 17);
	player.y = FX(SCREEN_H - 90);
	player.alive = 1;
	player.invuln = 120;
	player.cooldown = 0;
	player.roll = 0;
	player.rolls = 3;
	player.energy = ENERGY_MAX;
	hud_dirty = 1;
}

static void player_damage(short amount)
{
	if (!player.alive || player.invuln || player.roll)
		return;
	player.energy -= amount;
	player.invuln = 30;
	hud_dirty = 1;
	if (player.energy <= 0)
	{
		player.energy = 0;
		player.alive = 0;
		player.respawn = 100;
		if (player.power > 0)
			player.power--;
		explode(player.x + FX(17), player.y + FX(18));
		explode(player.x + FX(10), player.y + FX(10));
		explode(player.x + FX(24), player.y + FX(26));
		if (!attract)
			player.lives--;
	}
}

/* The autopilot (attract mode): line up under the nearest enemy, keep
 * away from shots, roll out of trouble. Returns a key mask. */
static unsigned short autopilot(void)
{
	unsigned short k = KEY_A;
	short tx = player.x;
	short ty = FX(SCREEN_H - 110);
	short best = 32767;
	short i;

	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if (is_enemy(o->type) && o->y > FX(-20) && o->y < player.y - FX(40))
		{
			short d = player.y - o->y;
			if (d < best)
			{
				best = d;
				tx = centre_x(o) - FX(17);
			}
		}
	}
	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* o = &objs[i];
		if ((o->type == OBJ_SHOT || (is_enemy(o->type) && o->type != OBJ_BOSS)) &&
		    abs16(centre_x(o) - (player.x + FX(17))) < FX(30) &&
		    o->y > player.y - FX(90) && o->y < player.y + FX(40))
		{
			tx = centre_x(o) > player.x + FX(17) ? player.x - FX(40) : player.x + FX(40);
			if (o->y > player.y - FX(24) && player.rolls > 1 && !player.roll)
				k |= KEY_B;
		}
	}
	if (tx < player.x - FX(3))
		k |= KEY_LEFT;
	else if (tx > player.x + FX(3))
		k |= KEY_RIGHT;
	if (ty < player.y - FX(3))
		k |= KEY_UP;
	else if (ty > player.y + FX(3))
		k |= KEY_DOWN;
	return k;
}

static void fire_tracer(short x, short vx)
{
	struct obj* o = spawn(OBJ_TRACER, player.x + FX(x), player.y);
	if (o)
	{
		o->vx = vx;
		o->vy = -FX(11);
	}
}

static void update_player(unsigned short k, unsigned short new_keys)
{
	short speed = FX(3);

	if (!player.alive)
	{
		if (--player.respawn == 0 && (player.lives > 0 || attract))
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
	if (player.x < FX(0))
		player.x = FX(0);
	if (player.x > FX(SCREEN_W - 35))
		player.x = FX(SCREEN_W - 35);
	if (player.y < FX(PLAYER_TOP))
		player.y = FX(PLAYER_TOP);
	if (player.y > FX(PLAYER_BOTTOM - 37))
		player.y = FX(PLAYER_BOTTOM - 37);

	if (player.roll)
	{
		player.roll--;
		return;		/* no shooting while rolling */
	}
	if ((new_keys & KEY_B) && player.rolls > 0)
	{
		player.roll = 48;
		player.rolls--;
		hud_dirty = 1;
	}

	if (player.cooldown)
		player.cooldown--;
	if ((k & KEY_A) && player.cooldown == 0 && count_type(OBJ_TRACER) < 18)
	{
		player.cooldown = 6;
		switch (player.power)
		{
		case 0:
			fire_tracer(11, 0);
			fire_tracer(21, 0);
			break;
		case 1:
			fire_tracer(4, 0);
			fire_tracer(12, 0);
			fire_tracer(20, 0);
			fire_tracer(28, 0);
			break;
		default:
			fire_tracer(8, 0);
			fire_tracer(16, 0);
			fire_tracer(24, 0);
			fire_tracer(4, -FX(2));
			fire_tracer(28, FX(2));
			break;
		}
	}
}

/*
 * Update
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

		if (on_map(o->type))
		{
			update_enemy(o);
			o->x = FX(PX(o->mx) - (short)cam_x);
			o->y = FX((short)(o->my - cam_y));
			if (o->y > FX(SCREEN_H + 40) || o->x < FX(-80) || o->x > FX(SCREEN_W + 16))
				o->type = OBJ_NONE;
			continue;
		}

		o->x += o->vx;
		o->y += o->vy;

		switch (o->type)
		{
		case OBJ_TRACER:
			if (o->y < FX(-12))
				o->type = OBJ_NONE;
			break;
		case OBJ_SHOT:
			if (o->y < FX(-12) || o->y > FX(SCREEN_H + 4) ||
			    o->x < FX(-12) || o->x > FX(SCREEN_W + 4))
				o->type = OBJ_NONE;
			break;
		case OBJ_EXPLOSION:
			if (o->t >= 22)
				o->type = OBJ_NONE;
			break;
		case OBJ_MAN:
			o->x += sine(o->t >> 1) * 2;
			if (o->y > FX(SCREEN_H + 8))
				o->type = OBJ_NONE;
			break;
		default:
			if (is_enemy(o->type))
			{
				update_enemy(o);
				if (o->type != OBJ_BOSS && o->t > 30 &&
				    (o->y > FX(SCREEN_H + 60) || o->y < FX(-80) ||
				     o->x < FX(-90) || o->x > FX(SCREEN_W + 50)))
				{
					if (o->type == OBJ_FIGHTER && o->formation)
						formations[o->formation].left--;
					o->type = OBJ_NONE;
				}
			}
			break;
		}
	}

	/* Tracers against enemies */
	for (i = 0; i < MAX_OBJS; i++)
	{
		struct obj* b = &objs[i];
		if (b->type != OBJ_TRACER)
			continue;
		for (j = 0; j < MAX_OBJS; j++)
		{
			struct obj* e = &objs[j];
			if (!is_enemy(e->type) || e->y < FX(-30))
				continue;
			if (overlap(&FRAME_TRACER, PX(b->x), PX(b->y),
				    obj_frame(e), PX(e->x), PX(e->y)))
			{
				b->type = OBJ_NONE;
				e->flash = 3;
				if (--e->hp <= 0)
					kill_enemy(e, 1);
				else
					add_score(10);
				break;
			}
		}
	}

	/* Enemies and their shots against the player; workers picked up */
	if (player.alive)
	{
		for (i = 0; i < MAX_OBJS; i++)
		{
			struct obj* e = &objs[i];
			if (e->type != OBJ_SHOT && e->type != OBJ_MAN &&
			    (!is_enemy(e->type) || on_map(e->type)))
				continue;
			if (!overlap(obj_frame(e), PX(e->x), PX(e->y),
				     &FRAME_PLAYER, PX(player.x), PX(player.y)))
				continue;
			if (e->type == OBJ_MAN)
			{
				e->type = OBJ_NONE;
				if (player.power < 2)
					player.power++;
				player.energy += 30;
				if (player.energy > ENERGY_MAX)
					player.energy = ENERGY_MAX;
				add_score(1000);
				message_t = -90;	/* "RESCUED" */
				show_message();
				hud_dirty = 1;
			}
			else if (e->type == OBJ_SHOT)
			{
				if (!player.roll && !player.invuln)
				{
					e->type = OBJ_NONE;
					player_damage(25);
				}
			}
			else if (!player.roll && !player.invuln)
			{
				player_damage(50);
				if (e->type != OBJ_BOSS && e->type != OBJ_BOMBER)
					kill_enemy(e, 0);
			}
		}
	}
}

/*
 * Drawing
 */

static void draw_objects(void)
{
	short i, pass;

	/* Map objects first, then aircraft (big ones under small ones), then
	 * explosions, workers, shots and the player on top */
	static const unsigned char order[] = {
		OBJ_GUNBOAT, OBJ_BUNKER, OBJ_AAGUN, OBJ_BOSS, OBJ_BOMBER, OBJ_LEADER,
		OBJ_FIGHTER, OBJ_WING, OBJ_JET, OBJ_EXPLOSION, OBJ_MAN, OBJ_TRACER, 0 };

	for (pass = 0; order[pass]; pass++)
		for (i = 0; i < MAX_OBJS; i++)
		{
			struct obj* o = &objs[i];
			if (o->type != order[pass])
				continue;
			sprite_draw(obj_frame(o), PX(o->x), PX(o->y),
				    o->flash ? PAL_FLASH :
				    (o->type == OBJ_FIGHTER && formations[o->formation].silver) ?
				    PAL_SILVER : PAL_SPRITES);
		}

	if (player.alive && !(player.invuln & 4))
	{
		const struct sprite_frame* f = &FRAME_PLAYER;
		if (player.roll)
		{
			static const struct sprite_frame* const roll[6] = {
				&FRAME_PLAYER_ROLL1, &FRAME_PLAYER_ROLL2, &FRAME_PLAYER_ROLL3,
				&FRAME_PLAYER_ROLL4, &FRAME_PLAYER_ROLL5, &FRAME_PLAYER_ROLL6 };
			f = roll[(48 - player.roll) / 8];
		}
		else if ((keys & KEY_A || attract) && player.cooldown > 3)
			f = &FRAME_PLAYER_FIRE;
		/* centre the narrower roll frames on the plane */
		sprite_draw(f, PX(player.x) + (35 - f->w) / 2, PX(player.y), PAL_SPRITES);
	}

	/* Shots last, so they are never hidden */
	for (i = 0; i < MAX_OBJS; i++)
		if (objs[i].type == OBJ_SHOT)
			sprite_draw(&FRAME_SHOT, PX(objs[i].x), PX(objs[i].y), PAL_SPRITES);

	/* Energy bar */
	sprite_draw(&FRAME_BAR_EMPTY, SCREEN_W - 112, 2, PAL_SPRITES);
	if (player.energy > 0)
		sprite_draw_w(&FRAME_BAR_FULL, SCREEN_W - 112, 2, PAL_SPRITES, player.energy);
}

static void draw_hud(void)
{
	if (!hud_dirty)
		return;
	hud_dirty = 0;
	if (attract)
	{
		text_print(2, 1, "DEMO      ");
		text_print(2, 2, "              ");
	}
	else
	{
		text_print(2, 1, "SCORE");
		text_number(8, 1, score, 7);
		text_print(2, 2, "PLANES");
		text_number(9, 2, player.lives > 0 ? player.lives : 0, 1);
		text_print(12, 2, "ROLLS");
		text_number(18, 2, player.rolls, 1);
	}
	text_print(28, 1, "HI");
	text_number(31, 1, hi_score, 7);
	text_print(42, 1, "STAGE");
	text_number(48, 1, stage + 1, 1);
	text_print(59, 1, "ENERGY");
}

static void show_message(void)
{
	short r;
	for (r = 26; r <= 32; r++)
		text_clear_row(r);
	hud_dirty = 1;
	if (message_t == 0)
		return;
	if (message_t < 0)
	{
		text_center(29, "WORKER RESCUED!");
		return;
	}
	if (boss_active)
	{
		text_center(27, "WARNING!");
		text_center(29, "MAGNUS'S DREADNOUGHT IS APPROACHING");
	}
	else if (stage_px == 0 && stage > 0)
	{
		text_center(27, "DREADNOUGHT SUNK!");
		text_center(29, "STAGE");
		text_number(43, 29, stage + 1, 1);
	}
	else
	{
		text_center(27, "STAGE");
		text_number(43, 27, stage + 1, 1);
		text_center(29, "GET READY");
	}
	if (attract)
		text_center(32, "PRESS FIRE TO PLAY");
}

/*
 * States
 */

static void clear_objects(void)
{
	short i;
	for (i = 0; i < MAX_OBJS; i++)
		objs[i].type = OBJ_NONE;
	for (i = 0; i < 3; i++)
		queue[i].left = 0;
}

static void start_game(short is_attract)
{
	attract = is_attract;
	clear_objects();
	score = 0;
	stage = 0;
	stage_px = 0;
	boss_active = 0;
	wave_timer = 120;
	next_spawn = 0;
	player.lives = 3;
	player.power = 0;
	player_spawn();
	screen_game();
	map_start(MAP_H - 32);
	map_set_x(192);
	message_t = 150;
	show_message();
	state = ST_PLAY;
	state_t = 0;
}

static void title_screen(void)
{
	if (state_t == 1)
	{
		screen_picture(PIC_TITLE);
		text_center(26, "RESCUE YOUR SISTER FROM MAGNUS GRASP'EM");
		text_print(13, 28, "HI SCORE");
		text_number(22, 28, hi_score, 7);
	}
	if (state_t & 32)
		text_center(29, "PRESS FIRE");
	else
		text_clear_row(29);

	if (pressed(KEY_A))
	{
		state = ST_STORY;
		state_t = 0;
	}
	else if (state_t > 600)
		start_game(1);
}

static void story_screen(void)
{
	if (state_t == 1)
	{
		screen_picture(PIC_MAGNUS);
		text_center(26, "MAGNUS GRASP'EM HAS TAKEN YOUR SISTER.");
		text_center(27, "HE HOLDS HER IN HIS SEWAGE WORKS.");
		text_center(28, "FLY IN AND SET HER FREE!");
	}
	if (state_t > 30 && (pressed(KEY_A) || state_t > 420))
		start_game(0);
}

static void ending_screen(void)
{
	if (state_t == 1)
	{
		screen_picture(PIC_TITLE);
		text_center(26, "MAGNUS GRASP'EM IS FINISHED.");
		text_center(27, "YOUR SISTER IS FREE!");
		text_print(12, 29, "SCORE");
		text_number(18, 29, score, 7);
	}
	if (state_t > 60 && (pressed(KEY_A) || state_t > 900))
	{
		state = ST_TITLE;
		state_t = 0;
	}
}

static void play_frame(void)
{
	unsigned short k = keys;
	unsigned short new_keys = keys & ~keys_prev;

	if (attract)
	{
		if (pressed(KEY_A) || state_t > 3600)
		{
			state = ST_TITLE;
			state_t = 0;
			return;
		}
		k = autopilot();
		new_keys = k & KEY_B;
	}

	map_scroll(SCROLL_SPEED);
	/* the map drifts a little with the plane, as in the old arcade games */
	map_set_x(192 + (PX(player.x) - SCREEN_W / 2) / 4);
	stage_frac += SCROLL_SPEED;
	stage_px += stage_frac >> 4;
	stage_frac &= 15;

	run_waves();
	update_player(k, new_keys);
	update_objects();

	if (state != ST_PLAY)
		return;		/* the last dreadnought sank */

	if (message_t > 0 && --message_t == 0)
		show_message();
	if (message_t < 0 && ++message_t == 0)
		show_message();

	if (!player.alive && player.lives <= 0 && !attract && player.respawn <= 0)
	{
		state = ST_GAME_OVER;
		state_t = 0;
		text_center(29, "GAME OVER");
	}

	sprite_begin();
	draw_objects();
	sprite_end();
	draw_hud();
}

void game_init(void)
{
	state = ST_TITLE;
	state_t = 0;
}

void game_frame(void)
{
	keys_prev = keys;
	keys = read_keys();
	state_t++;
	rnd();

	switch (state)
	{
	case ST_TITLE:
		title_screen();
		break;
	case ST_STORY:
		story_screen();
		break;
	case ST_PLAY:
		play_frame();
		break;
	case ST_GAME_OVER:
		/* the world goes on without you for a while */
		map_scroll(SCROLL_SPEED);
		update_objects();
		sprite_begin();
		draw_objects();
		sprite_end();
		if (state_t > 240 || (state_t > 60 && pressed(KEY_A)))
		{
			state = ST_TITLE;
			state_t = 0;
		}
		break;
	case ST_VICTORY:
		if (state_t == 1)
			screen_panorama();
		if (state_t > 400 || (state_t > 60 && pressed(KEY_A)))
		{
			state = ST_ENDING;
			state_t = 0;
		}
		break;
	case ST_ENDING:
		ending_screen();
		break;
	}
}
