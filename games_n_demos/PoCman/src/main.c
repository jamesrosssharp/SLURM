
char* str = "Hello world!\n";

#define COUNT_OF(x) ((sizeof(x)) / (sizeof(x[0])))

void puts(char* str)
{
	char c;
	while(c = *str++)
		putc(c);
}

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

extern void load_copper_list(short* list, int len);

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
		1,
		24 + 160 - 8 + 4 ,
		16 + 120 - 8 + 29 + 24,
		16,
		16,
		0,
		0,
		0,
		ORIENTATION_UP,
		26,
		{64*2*16, 64*2*16+4, 8, 64*2*16+4},
		{64*3*16, 64*3*16+4, 8, 64*3*16+4},
		{64*1*16, 64*1*16+4, 8, 64*1*16+4},
		{0, 4, 8, 4},
		{8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56},
		{0},
		{0}
	};

#define MAKE_SPRITE_X(x, en, pal, stride) ((x & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y) ((y & 0x3ff))
#define MAKE_SPRITE_A(a) (a)

extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

extern short pacman_sprite_sheet;
extern short pacman_spritesheet_palette;
extern short pacman_tilemap;
extern short pacman_tileset;
extern short pacman_tileset_palette;



void update_sprite(struct Sprite* sp)
{
	short x, y, h, a;
   	unsigned short	frame;
	
	
	x = MAKE_SPRITE_X(sp->x, sp->enabled, 0, 1);
	y = MAKE_SPRITE_Y(sp->y, sp->width - 1);
	h = MAKE_SPRITE_H(sp->y + sp->height - 1);
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
		sp->vx = 0;
		sp->vy = 0;
		sp->frame = 0;
	}
}

void enable_interrupts()
{
	__out(0x7000, 0x2);
	global_interrupt_enable();
}

short bg_x = 89;
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



#define UP_KEY 1
#define DOWN_KEY 2
#define LEFT_KEY 4
#define RIGHT_KEY 8
#define A_KEY 16
#define B_KEY 32

short keys = 0;

void process_keys() 
{
	//short old_keys = keys;

	short dx = 0;
	short dy = 0;

	short new_orientation;

	struct Sprite* pax = &pocman_start;

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

	/*eat(pax->x, pax->y);*/

	update_sprite(pax);

}



short frame = 0;

int main()
{


//	puts(str);
	
	load_copper_list(copperList, COUNT_OF(copperList));
	__out(0x5d20, 1);

	load_palette(&pacman_spritesheet_palette, 0, 16);
	load_palette(&pacman_tileset_palette, 16, 16);

/*	__out(0x5000, 320 | 1<<10 | 1<<15);
	__out(0x5100, 15<<10 | 240);
	__out(0x5200, 256);
	__out(0x5300, 0x4000);
*/
	enable_interrupts();

	while(1)
	{
		process_keys();
		//update_sprite(&pocman_start);
		//frame = __in(0x5f00);
		//copperList[0] = 0x7000 | (frame++ & 31);
		//load_copper_list(copperList, COUNT_OF(copperList));
		update_background();
		__sleep();			
	}
}
