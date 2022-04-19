
extern void load_copper_list(short* list, int len);
extern void load_palette(short* palette, int offset, int len);

short copperList[] = {
		0x6000,
/*		0x6f00,
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
	unsigned short frames_die[13];
};

extern short pacman_sprite_sheet;
extern short pacman_spritesheet_palette;
extern short pacman_tilemap;
extern short pacman_tileset;
extern short pacman_tileset_palette;

#define SPRITE_PACMAN 0
#define SPRITE_GHOST1 1

#define ORIENTATION_UP 1
#define ORIENTATION_DOWN 2
#define ORIENTATION_LEFT 4
#define ORIENTATION_RIGHT 8

struct Sprite sprites[] = {
	{	/* SPRITE_PACMAN */
		24 + 160 - 8 + 4 ,
		16 + 120 - 8 + 29,
		16,
		16,
		0,
		0,
		0,
		ORIENTATION_UP,
		0,
		{64*2*16, 64*2*16+4, 8, 64*2*16+4},
		{64*3*16, 64*3*16+4, 8, 64*3*16+4},
		{64*1*16, 64*1*16+4, 8, 64*1*16+4},
		{0, 4, 8, 4},
		{8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56}
	},
	{	/* SPRITE_GHOST1 */
		24 + 160 - 8,
		16 + 128 - 8 + 29 - 32,
		16,
		16,
		0,
		-1,
		0,
		ORIENTATION_UP,
		8,
		{(16*5*64) + 12, (16 * 5 * 64) + 8, (16*5*64) + 12, (16 * 5 * 64) + 8},
		{(16*5*64) + 12, (16 * 5 * 64) + 8, (16*5*64) + 12, (16 * 5 * 64) + 8},
		{(16*5*64) + 12, (16 * 5 * 64) + 8, (16*5*64) + 12, (16 * 5 * 64) + 8},
		{(16*5*64) + 12, (16 * 5 * 64) + 8, (16*5*64) + 12, (16 * 5 * 64) + 8},
		{0}
	},
	
	
	
	/*	{	400,
		100,
		16,
		16,
		1,
		1,
		0,
		{(16*5*64) + 12, (16 * 5 * 64) + 8, (16*5*64) + 12, (16 * 5 * 64) + 8}
	},
	{
		200,
		200,
		16,
		16,
		-1,
		-1,
		0,
		{64*4*16, 64*4*16+4,64*4*16, 64*4*16+4}
	},
	{
		600,
		300,
		16,
		16,
		2,
		1,
		0,
		{8 + 64*3*16, 8 + 64*3*16, 8 + 64*3*16, 8 + 64*3*16 }
	},
	{
		280,
		400,
		16,
		16,
		-1,
		2,
		0,
		{12 + 64*3*16, 12 + 64*3*16, 12 + 64*3*16, 12 + 64*3*16 }	
	},
	{
		250,
		150,
		16,
		16,
		-2,
		-1,
		0,
		{16 + 64*3*16, 16 + 64*3*16, 16 + 64*3*16, 16 + 64*3*16 }	
	}
*/
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

void update_sprites()
{
	int i;

	for (i = 0; i < COUNT_OF(sprites); i++)
	{
		struct Sprite* sp = &sprites[i];
		short x, y, h, a, frame;
		
		sp->frame = (sp->frame) & 15;
		
		x = MAKE_SPRITE_X(sp->x, 1, 0, 1);
		y = MAKE_SPRITE_Y(sp->y, sp->width);
		h = MAKE_SPRITE_H(sp->y + sp->height);
		frame = sp->frame;
		
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
		}

		load_sprite_x(i, x);
		load_sprite_y(i, y);
		load_sprite_h(i, h);
		load_sprite_a(i, a);

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
			sp->vx = 0;
			sp->vy = 0;
			sp->frame = 0;
		}

	}
}

short bg_x = 73;
short bg_y = 0; //10;
short vx = 0;
short vy = 0;

void update_background()
{


	// Set BG enable and pal hi
	
	__out(0x5d00, 0x1 | (1<<4));

	// Set X
	
	__out(0x5d01, bg_x);

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
	__out(0x7000, 0x2);
	global_interrupt_enable();
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
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_UP;
	}

	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3 + offsets[i]) >> 3;
			short cur_map_y = (y + bg_y + 3 + 4 + 8) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_DOWN;
	}

	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 4 - 8) >> 3;
			short cur_map_y = (y + bg_y + 3 + offsets[i]) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_LEFT;
	}

	for (i = 0; i < iter; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 4 + 8) >> 3;
			short cur_map_y = (y + bg_y + 3 + offsets[i]) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_RIGHT;
	}

	/*if (old_map_x != g_cur_map_x || old_map_y != g_cur_map_y)
	{
		trace_dec(mask);
		trace_char('\n');
		trace_char('\n');
		old_map_x = g_cur_map_x;
		old_map_y = g_cur_map_y;
	}*/

	return mask;
}

void eat(short x, short y)
{
	short cur_map_x = (x + bg_x + 3 + 4) >> 3;
	short cur_map_y = (y + bg_y + 3 + 4) >> 3;
	
	unsigned char* cur_map_tile_p = ((unsigned char*)&pacman_tilemap + (cur_map_x) + ((cur_map_y) << 6));
	unsigned char cur_map_tile = *cur_map_tile_p;
	
	if ((cur_map_tile) == 83)
		*cur_map_tile_p = 0xff;

	/*if (old_map_x != cur_map_x || old_map_y != cur_map_y)
	{
		int i, j; 

		trace_dec(cur_map_x);
		trace_char(' ');
		trace_dec(cur_map_y);
		trace_char(' ');
		trace_dec(cur_map_tile);
		trace_char('\n');

		old_map_x = cur_map_x;
		old_map_y = cur_map_y;

		for (i = 0; i < 3; i++)
		{
			for (j = 0; j < 3; j++)
			{
				unsigned char* cur_map_tile_p = ((unsigned char*)&pacman_tilemap + (cur_map_x + i - 1) + ((cur_map_y + j - 1) << 6));
				trace_hex(cur_map_tile_p);
				trace_char(' ');	
			}
		}
		trace_char('\n');
	}
	*/

}

void process_keys() 
{
	short old_keys = keys;

	short dx = 0;
	short dy = 0;

	short new_orientation;

	struct Sprite* pax = &sprites[SPRITE_PACMAN];

	short collision = collision_detect(pax->x, pax->y);

//	trace_hex(collision);
//	trace_char('\n');

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

	if (pax->frames_in_cycle == 0 && (dx || dy))
	{
		pax->frames_in_cycle = 8;
		pax->vx = dx;
		pax->vy = dy;
		pax->orientation = new_orientation;
	}

	eat(pax->x, pax->y);
	
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

}

void update_ghosts()
{

	struct Sprite* sp = &sprites[SPRITE_GHOST1];
	struct Sprite* pac = &sprites[SPRITE_PACMAN];
	short collision = collision_detect(sp->x,sp->y);

	short spx = sp->x >> 3;
	short spy = sp->y >> 3;
	short px = pac->x >> 3;
	short py = pac->y >> 3;


	unsigned short dist_up = (spx - px)*(spx - px) + ((spy - 1)-py)*((spy - 1)-py);
	unsigned short dist_down = (spx-px)*(spx-px) + ((spy + 1)-py)*((spy + 1)-py);
	unsigned short dist_left = ((spx-1)-px)*((spx-1)-px) + (spy-py)*(spy-py);
	unsigned short dist_right = ((spx+1)-px)*((spx+1)-px) + (spy-py)*(spy-py);

	unsigned short min_dist = 32767;

	short dx = 0;
	short dy = 0;
	short new_orientation = sp->orientation;

	short compl_orient = complement_orientation(sp->orientation);
	short masked_collision = collision & ~compl_orient;
	short has_mult = (masked_collision != 1) && (masked_collision != 2) && (masked_collision != 4) && (masked_collision != 8);

	if ((dist_up < min_dist) && (masked_collision & ORIENTATION_UP))
		min_dist = dist_up;
	if ((dist_down < min_dist) && (masked_collision & ORIENTATION_DOWN))
		min_dist = dist_down;
	if ((dist_left < min_dist) && (masked_collision & ORIENTATION_LEFT))
		min_dist = dist_left;
	if ((dist_right < min_dist) && (masked_collision & ORIENTATION_RIGHT))
		min_dist = dist_right;

	trace_hex(sp->orientation);
	trace_char(' ');
	trace_hex(masked_collision);
	trace_char(' ');
	trace_hex(has_mult);
	trace_char(' ');
	trace_dec(min_dist);
	trace_char(' ');
	trace_dec(dist_up);
	trace_char(' ');
	trace_dec(dist_down);
	trace_char(' ');
	trace_dec(dist_left);
	trace_char(' ');
	trace_dec(dist_right);
	trace_char('\n');

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

	/*	else {
		short a = collision;

		if (a & COLLISION_CAN_LEFT)
			sp->x--;
		else if (a & COLLISION_CAN_RIGHT)
			sp->x++;
		else if (a & COLLISION_CAN_UP)
			sp->y--;
		else if (a & COLLISION_CAN_DOWN)
			sp->y++;

	}	
*/
	if (sp->frames_in_cycle == 0 && (dx || dy))
	{
		sp->frames_in_cycle = 8;
		sp->vx = dx;
		sp->vy = dy;
		sp->orientation = new_orientation;
	}

	run -= 1;

	rand *= 7143;
}

int main()
{
	
	short frame = 0;
	
	load_copper_list(copperList, COUNT_OF(copperList));
	load_palette(&pacman_spritesheet_palette, 0, 16);
	load_palette(&pacman_tileset_palette, 16, 16);


	enable_interrupts();

	while (1)
	{
		update_ghosts();
		process_keys();
		update_background();
		update_sprites();
//		copperList[0] = 0x7000 | (frame++ & 31);
		load_copper_list(copperList, COUNT_OF(copperList));
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
