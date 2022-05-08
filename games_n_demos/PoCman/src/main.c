
extern void load_copper_list(short* list, int len);
extern void load_palette(short* palette, int offset, int len);

short copperList[] = {
		0x6000,
		/*0x6f00,
		0x7007,
		0x60f0,
		0x7007,
		0x600f,
		0x7007,
		0x60ff,
		0x7007,
		0x4200,
		0x1001,*/
		0x2fff		 
};

struct Sprite {
	short enabled;
	short i; /* sprite index */
	short x;
	short y;
	short width;
	short height;
	short vx;
	short vy;
	short frame;
	short orientation;
	short frames_in_cycle;
	unsigned short frames_up[4];
	unsigned short frames_down[4];
	unsigned short frames_left[4];
	unsigned short frames_right[4];
	unsigned short frames_die_spawn[13];
	unsigned short frames_scatter[4];
	unsigned short frames_dead[2]; /* dead ghosts going to ghost house */
};

#define GHOST_STATE_IDLE			  0
#define GHOST_STATE_LEAVE_GHOST_HOUSE 1
#define GHOST_STATE_CHASE_POCMAN	  2
#define GHOST_STATE_SCATTER			  3

struct Ghost {
	struct Sprite sp;
	short state;
	short idle_count;
	short scatter_x;
	short scatter_y;
};

extern short pacman_sprite_sheet;
extern short pacman_spritesheet_palette;
extern short pacman_tilemap;
extern short pacman_tileset;
extern short pacman_tileset_palette;

#define ORIENTATION_UP 1
#define ORIENTATION_DOWN 2
#define ORIENTATION_LEFT 4
#define ORIENTATION_RIGHT 8
#define ORIENTATION_SPAWN 16
#define ORIENTATION_DIE	  32

struct Sprite pocman_start = 	{	
		1,
		0,
		24 + 160 - 8 + 4 ,
		16 + 120 - 8 + 29 + 24,
		16,
		16,
		0,
		0,
		0,
		ORIENTATION_SPAWN,
		26,
		{64*2*16, 64*2*16+4, 8, 64*2*16+4},
		{64*3*16, 64*3*16+4, 8, 64*3*16+4},
		{64*1*16, 64*1*16+4, 8, 64*1*16+4},
		{0, 4, 8, 4},
		{8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56},
		{0},
		{0}
	};

struct Sprite pocman;

#define N_GHOSTS 4

struct Ghost ghosts[N_GHOSTS];
struct Ghost ghosts_start[N_GHOSTS] = {
	{
		{	/* PINK GHOST */
			1,
			16,
			24 + 160 - 8 ,
			16 + 128 - 8 + 29 - 32 + 10 - 4,
			16,
			16,
			0,
			-1,
			0,
			ORIENTATION_UP,
			8,
			{(16*5*64) + 16, (16 * 5 * 64) + 20, (16*5*64) + 16, (16 * 5 * 64) + 20},
			{(16*5*64) + 24, (16 * 5 * 64) + 28, (16*5*64) + 24, (16 * 5 * 64) + 28},
			{(16*5*64) + 8, (16 * 5 * 64) + 12, (16*5*64) + 8, (16 * 5 * 64) + 12},
			{(16*5*64) + 0, (16 * 5 * 64) + 4, (16*5*64) + 0, (16 * 5 * 64) + 4},
			{0},
			{0},
			{0}
		},
		GHOST_STATE_IDLE,
		100,
		11,
		5
	},
	{
		{	/* RED GHOST */
			1,
			17,
			24 + 160 - 8 + 16 ,
			16 + 128 - 8 + 29 - 32 + 10 - 4,
			16,
			16,
			0,
			-1,
			0,
			ORIENTATION_UP,
			8,
			{(16*4*64) + 16, (16 * 4 * 64) + 20, (16*4*64) + 16, (16 * 4 * 64) + 20},
			{(16*4*64) + 24, (16 * 4 * 64) + 28, (16*4*64) + 24, (16 * 4 * 64) + 28},
			{(16*4*64) + 8, (16 * 4 * 64) + 12, (16*4*64) + 8, (16 * 4 * 64) + 12},
			{(16*4*64) + 0, (16 * 4 * 64) + 4, (16*4*64) + 0, (16 * 4 * 64) + 4},
			{0},
			{0},
			{0}
		},
		GHOST_STATE_IDLE,
		1000,
		36,5,
	},
	{
		{	/* BLUE GHOST */
			1,
			18,
			24 + 160 - 8 - 16 ,
			16 + 128 - 8 + 29 - 32 + 10 - 4,
			16,
			16,
			0,
			-1,
			0,
			ORIENTATION_UP,
			8,
			{(16*6*64) + 16, (16 * 6 * 64) + 20, (16*6*64) + 16, (16 * 6 * 64) + 20},
			{(16*6*64) + 24, (16 * 6 * 64) + 28, (16*6*64) + 24, (16 * 6 * 64) + 28},
			{(16*6*64) + 8, (16 * 6 * 64) + 12, (16*6*64) + 8, (16 * 6 * 64) + 12},
			{(16*6*64) + 0, (16 * 6 * 64) + 4, (16*6*64) + 0, (16 * 6 * 64) + 4},
			{0},
			{0},
			{0}
		},
		GHOST_STATE_IDLE,
		2000,
		36,29,
	},
	{
		{	/* ORANGE GHOST */
			1, 
			19,
			24 + 160 - 8 ,
			16 + 128 - 8 + 29 - 32 - 6 - 4,
			16,
			16,
			0,
			-1,
			0,
			ORIENTATION_UP,
			8,
			{(16*7*64) + 16, (16 * 7 * 64) + 20, (16*7*64) + 16, (16 * 7 * 64) + 20},
			{(16*7*64) + 24, (16 * 7 * 64) + 28, (16*7*64) + 24, (16 * 7 * 64) + 28},
			{(16*7*64) + 8, (16 * 7 * 64) + 12, (16*7*64) + 8, (16 * 7 * 64) + 12},
			{(16*7*64) + 0, (16 * 7 * 64) + 4, (16*7*64) + 0, (16 * 7 * 64) + 4},
			{0},
			{0},
			{0}

		},
		GHOST_STATE_CHASE_POCMAN,
		2000,
		11,29,
	}
};

#define COUNT_OF(x) ((sizeof(x)) / (sizeof(x[0])))

#define MAKE_SPRITE_X(x, en, pal, stride) ((x & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y) ((y & 0x3ff))
#define MAKE_SPRITE_A(a) (a)

extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

void start_game();

void update_sprite(struct Sprite* sp)
{
	short x, y, h, a, frame;
	
	
	x = MAKE_SPRITE_X(sp->x, sp->enabled, 0, 1);
	y = MAKE_SPRITE_Y(sp->y, sp->width - 1);
	h = MAKE_SPRITE_H(sp->y + sp->height - 1);
	frame = sp->frame;
	frame = (sp->frame) & 15;
	
	switch(sp->orientation)
	{
		case ORIENTATION_UP:
			a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_up[frame >> 2]));
			break;
		case ORIENTATION_DOWN:
			a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_down[frame >> 2]));
			break;
		case ORIENTATION_LEFT:
			a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_left[frame >> 2]));
			break;
		case ORIENTATION_RIGHT:
			a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_right[frame >> 2]));
			break;
		case ORIENTATION_DIE:
			if (sp -> frame > 26) sp->frame = 26;
			a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_die_spawn[sp->frame>>1]));
			break;
		case ORIENTATION_SPAWN:
			if (sp -> frame > 26) sp->frame = 26;
			//a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_die_spawn[13 - (sp->frame>>1)]));
			a = MAKE_SPRITE_A(((unsigned short)&pacman_sprite_sheet >> 1) + (sp->frames_left[2]));
			break;
	}

	load_sprite_x(sp->i, x);
	load_sprite_y(sp->i, y);
	load_sprite_h(sp->i, h);
	load_sprite_a(sp->i, a);

	if (sp->frames_in_cycle)
	{
		sp->x += sp->vx;
		sp->y += sp->vy;
		sp->frames_in_cycle--;

		if (sp->x > 320 + 60)
			sp->x = 8;
		if (sp->x < 8)
			sp->x = 320 + 60;

		sp->frame ++;

	}
	else
	{
		if (sp->orientation == ORIENTATION_DIE)
		{
			start_game();
		}
		//else if (sp->orientation == ORIENTATION_SPAWN) sp->orientation = ORIENTATION_UP;
		sp->vx = 0;
		sp->vy = 0;
		sp->frame = 0;
	}
}

short bg_x = 73;
short bg_y = 0; //10;
short vx = 0;
short vy = 0;

void update_background()
{
	// set 320x240 mode
	__out(0x5f02, 1);

	// Set BG enable and pal hi
	
	__out(0x5d00, 0x1 | (1<<4) | (2<<8) | (1<<15));

	// Set X
	
	__out(0x5d01, bg_x + 16);

	// Set Y
	
	__out(0x5d02, bg_y);

	// Set map address

	__out(0x5d03, (unsigned short)&pacman_tilemap >> 1);

	// Set tile set address
	
	__out(0x5d04, (unsigned short)&pacman_tileset >> 1);

	bg_x += vx;
	bg_y += vy;

	if (bg_x > 150)
	{
		bg_x = 149;
		vx = 0-vx;
		vy = 0-vy;
	}
	else if (bg_x < 0)
	{
		vx = 0-vx;
		vy = 0-vy;
		bg_x = 0;
	}
}

void enable_interrupts()
{
	__out(0x7000, 0x2 | 0x4); // Audio and video interrupts
	global_interrupt_enable();
}

void disable_interrupts()
{
	global_interrupt_disable();
}


short keys = 0;

#define UP_KEY 1
#define DOWN_KEY 2
#define LEFT_KEY 4
#define RIGHT_KEY 8
#define A_KEY 16
#define B_KEY 32

short old_map_tile;

#define COLLISION_CAN_UP 	1
#define COLLISION_CAN_DOWN 	2
#define COLLISION_CAN_LEFT 	4
#define COLLISION_CAN_RIGHT 8

short old_map_x;
short old_map_y;


short collision_detect(short x, short y)
{
	short mask = 0;
	short collisions[9];
	int i;
	int j;

	short g_cur_map_x = (x + bg_x + 3 + 4) >> 3;
	short g_cur_map_y = (y + bg_y + 3 + 4) >> 3;

	short offsets[3] = {4,1,7};

#define iter 1

	mask = 0xf;
	
	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3  + offsets[i]) >> 3;
			short cur_map_y = (y + bg_y + 3 + 4 - 8) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42 || cur_map_tile == 87)
				mask &= ~COLLISION_CAN_UP;
	}

	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3 + offsets[i]) >> 3;
			short cur_map_y = (y + bg_y + 3 + 4 + 8) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42 || cur_map_tile == 87)
				mask &= ~COLLISION_CAN_DOWN;
	}

	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 4 - 8) >> 3;
			short cur_map_y = (y + bg_y + 3 + offsets[i]) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42 || cur_map_tile == 87)
				mask &= ~COLLISION_CAN_LEFT;
	}

	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 4 + 8) >> 3;
			short cur_map_y = (y + bg_y + 3 + offsets[i]) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42 || cur_map_tile == 87)
				mask &= ~COLLISION_CAN_RIGHT;
	}

	return mask;
}


short complement_orientation(short orient);

void scatter_ghosts()
{
	int i;

	for (i = 0; i < COUNT_OF(ghosts); i++)
	{
		if (ghosts[i].state == GHOST_STATE_CHASE_POCMAN)
		{
			ghosts[i].idle_count = 100;
			ghosts[i].state = GHOST_STATE_SCATTER;
			ghosts[i].sp.orientation = complement_orientation(ghosts[i].sp.orientation);
		}
	}
}

void eat(short x, short y)
{
	short cur_map_x = (x + bg_x + 3 + 4) >> 3;
	short cur_map_y = (y + bg_y + 3 + 4) >> 3;
	
	unsigned char* cur_map_tile_p = ((unsigned char*)&pacman_tilemap + (cur_map_x) + ((cur_map_y) << 6));
	unsigned char cur_map_tile = *cur_map_tile_p;
	
	if (cur_map_tile == 83)
		*cur_map_tile_p = 0xff;

	if (cur_map_tile == 85)
	{
		*cur_map_tile_p = 0xff;
		scatter_ghosts();
	}
}

void process_keys() 
{
	short old_keys = keys;

	short dx = 0;
	short dy = 0;

	short new_orientation;

	struct Sprite* pax = &pocman;

	short collision = collision_detect(pax->x, pax->y);

	keys = __in(0x1001);

	keys &= collision;

	if ((keys & UP_KEY))
	{
		dy = -1;
		new_orientation = ORIENTATION_UP;
	}

	else if ((keys & DOWN_KEY))
	{
		dy = 1;
		new_orientation = ORIENTATION_DOWN;
	}

	else if (keys & LEFT_KEY) 
	{
		dx = -1;
		new_orientation = ORIENTATION_LEFT;
	}

	else if (keys & RIGHT_KEY)
	{
		dx = 1;
		new_orientation = ORIENTATION_RIGHT;
	}

	/* cornering */

	if (pax->frames_in_cycle == 0 && (dx || dy) && pax->orientation != ORIENTATION_DIE)
	{
		pax->frames_in_cycle = 8;
		pax->vx = dx;
		pax->vy = dy;
		pax->orientation = new_orientation;
	}

	eat(pax->x, pax->y);

	update_sprite(pax);

}

short rand = 417;
short run = 10;

short complement_orientation(short orient)
{
	switch (orient)
	{
		case ORIENTATION_LEFT:
			return ORIENTATION_RIGHT;
		case ORIENTATION_RIGHT:
			return ORIENTATION_LEFT;
		case ORIENTATION_UP:
			return ORIENTATION_DOWN;
		case ORIENTATION_DOWN:
			return ORIENTATION_UP;
	}
	return ORIENTATION_UP;
}

void update_ghosts()
{
	int i;

	for (i = 0; i < COUNT_OF(ghosts); i++)
	{

		struct Ghost* gh = &ghosts[i];
		struct Sprite* sp = &gh->sp;

		if (gh->state == GHOST_STATE_CHASE_POCMAN || gh->state == GHOST_STATE_SCATTER)
		{			
			struct Sprite* pac = &pocman;
			short collision = collision_detect(sp->x,sp->y);

			short spx; 
			short spy;
			short px; 
			short py;

			unsigned short dist_up;
			unsigned short dist_down;
			unsigned short dist_left;
			unsigned short dist_right;

			unsigned short min_dist;

			short dx;
			short dy;
			short new_orientation = sp->orientation;

			short compl_orient = complement_orientation(sp->orientation);
			short masked_collision = collision & ~compl_orient;
			short has_mult = (masked_collision != 1) && (masked_collision != 2) && (masked_collision != 4) && (masked_collision != 8);

			spx = sp->x >> 3;
			spy = sp->y >> 3;

			if (gh->state == GHOST_STATE_CHASE_POCMAN)
			{
				px = pac->x >> 3;
				py = pac->y >> 3;
			}
			else
			{
				px = gh->scatter_x;
				py = gh->scatter_y;
			}


			dist_up = (spx - px)*(spx - px) + ((spy - 1)-py)*((spy - 1)-py);
			dist_down = (spx-px)*(spx-px) + ((spy + 1)-py)*((spy + 1)-py);
			dist_left = ((spx-1)-px)*((spx-1)-px) + (spy-py)*(spy-py);
			dist_right = ((spx+1)-px)*((spx+1)-px) + (spy-py)*(spy-py);

			min_dist = 32767;

			dx = 0;
			dy = 0;

			update_sprite(sp);

			if ((dist_up < min_dist) && (masked_collision & ORIENTATION_UP))
				min_dist = dist_up;
			if ((dist_down < min_dist) && (masked_collision & ORIENTATION_DOWN))
				min_dist = dist_down;
			if ((dist_left < min_dist) && (masked_collision & ORIENTATION_LEFT))
				min_dist = dist_left;
			if ((dist_right < min_dist) && (masked_collision & ORIENTATION_RIGHT))
				min_dist = dist_right;

			if ( (collision & COLLISION_CAN_UP) && (sp->orientation != ORIENTATION_DOWN) && (!has_mult || (dist_up == min_dist)))
			{
				new_orientation = ORIENTATION_UP;
				dy = -1;
			}
			else if ( (collision & COLLISION_CAN_LEFT) && (sp->orientation != ORIENTATION_RIGHT) && (!has_mult || (dist_left == min_dist)))
			{
				dx = -1;
				new_orientation = ORIENTATION_LEFT;
			}
			else if ( (collision & COLLISION_CAN_RIGHT) && (sp->orientation != ORIENTATION_LEFT) && (!has_mult || (dist_right == min_dist)))
			{
				new_orientation = ORIENTATION_RIGHT;
				dx = 1;
			}
			else if ( (collision & COLLISION_CAN_DOWN) && (sp->orientation != ORIENTATION_UP) && (!has_mult || (dist_down == min_dist)))
			{
				dy = 1;
				new_orientation = ORIENTATION_DOWN;
			}

			if (sp->frames_in_cycle == 0 && (dx || dy))
			{
				sp->frames_in_cycle = 8;
				sp->vx = dx;
				sp->vy = dy;
				sp->orientation = new_orientation;
			}

			if (gh->state == GHOST_STATE_SCATTER)
			{
				if (gh->idle_count-- == 0)
					gh->state = GHOST_STATE_CHASE_POCMAN;
			}

		}
		else if (gh->state == GHOST_STATE_LEAVE_GHOST_HOUSE)
		{
			#define GHOST_LEAVE_X (21*8+4)

			if (sp->x != GHOST_LEAVE_X)
			{

				if (sp->x > GHOST_LEAVE_X)
				{
					sp->frames_in_cycle = sp->x - GHOST_LEAVE_X;
					sp->vx = -1;
					sp->orientation = ORIENTATION_LEFT;
				}
				else
				{
					sp->frames_in_cycle = GHOST_LEAVE_X - sp->x;
					sp->vx = 1;
					sp->orientation = ORIENTATION_RIGHT;
				}

			}
			else
			{
				if (sp->frames_in_cycle == 0)
				{
					sp->frames_in_cycle = 16;
					sp->vx = 0;
					sp->vy = -1;
					sp->orientation = ORIENTATION_UP;
				}
			}

			if (sp->y == 14*8)
				gh->state = GHOST_STATE_CHASE_POCMAN;

			update_sprite(sp);
		}
		else if (gh->state == GHOST_STATE_IDLE)
		{
			if (gh->idle_count-- == 0)
				gh->state = GHOST_STATE_LEAVE_GHOST_HOUSE;
			if (sp->frames_in_cycle == 0)
			{
				sp->frames_in_cycle = 16;
				sp->vx = 0;
				sp->vy = 0;
				sp->orientation = ORIENTATION_UP;
			}
			
			update_sprite(sp);
		}
	}
}

void check_ghost_player_collisions()
{
	int i;
	short collided = 0;

	for (i = 0; i < 4; i++)
	{
		short coll = __in(0x5710 + i);
		collided |= coll & 1;
	}
	if (collided & 1)
	{
		if (pocman.orientation != ORIENTATION_DIE)
		{

			int i;
			pocman.frame = 0;
			pocman.orientation = ORIENTATION_DIE;
			pocman.frames_in_cycle = 26;
			pocman.vx = 0;
			pocman.vy = 0;
	
			for (i = 0; i < N_GHOSTS; i++)
			{
				ghosts[i].sp.enabled = 0;	
			}
		}
	}
}


short frame = 0;

void start_game()
{
	int i;
	short* sp_from = (short*)&pocman_start;
	short* sp_to = (short*)&pocman;

	short* gh_from = (short*)&ghosts_start;
	short* gh_to = (short*)&ghosts;

	for (i = 0; i < sizeof(struct Sprite) / sizeof(short); i++)
		*sp_to++ = *sp_from++;

	for (i = 0; i < N_GHOSTS*sizeof(struct Ghost)/sizeof(short); i++)
		*gh_to++ = *gh_from++;

	frame = 0;
}

#include "pocman_sound.c"

extern volatile short g_vsync;
extern volatile short g_audio;


int main()
{
	int i;
	
	load_copper_list(copperList, COUNT_OF(copperList));
	// Enable copper
	__out(0x5d20, 1);

	load_palette(&pacman_spritesheet_palette, 0, 16);
	load_palette(&pacman_tileset_palette, 16, 16);

	init_sound();

	start_game();


	while (1)
	{
		disable_interrupts();

		if (g_audio)
		{
			mix_audio();
			g_audio = 0;
		}

		if (g_vsync)
		{
			check_ghost_player_collisions();
			update_ghosts();
			process_keys();
			update_background();
			//update_sound();
			g_vsync = 0;
		}

//		copperList[0] = 0x7000 | (frame++ & 31);
//		load_copper_list(copperList, COUNT_OF(copperList));

		enable_interrupts();
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
