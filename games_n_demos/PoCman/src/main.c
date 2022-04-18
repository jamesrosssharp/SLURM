
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

#define ORIENTATION_UP 0
#define ORIENTATION_DOWN 1
#define ORIENTATION_LEFT 2
#define ORIENTATION_RIGHT 3

struct Sprite sprites[] = {
	{	/* SPRITE_PACMAN */
		24 + 160 - 8,
		16 + 120 - 8 + 29,
		16,
		16,
		0,
		0,
		0,
		ORIENTATION_UP,
		{64*2*16, 64*2*16+4, 8, 64*2*16+4},
		{64*3*16, 64*3*16+4, 8, 64*3*16+4},
		{64*1*16, 64*1*16+4, 8, 64*1*16+4},
		{0, 4, 8, 4},
		{8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56}
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

		sp->x += sp->vx;
		sp->y += sp->vy;

		sp->x &= 1023;
		sp->y &= 511;
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

	// Test up

	mask = 0xf;

	for (i = 0; i < 3; i++)
	{
			short cur_map_x = (x + bg_x + 3  + 2 + i*2) >> 3;
			short cur_map_y = (y + bg_y + 3 + 4 - 4) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_UP;

			if (old_map_x != g_cur_map_x || old_map_y != g_cur_map_y)
			{

				trace_dec(cur_map_x);
				trace_char(' ');
				trace_dec(cur_map_y);
				trace_char(' ');
				trace_dec(cur_map_tile);
				trace_char(' ');
				trace_dec(i);
				trace_char('\n');
			}
	}

	for (i = 0; i < 3; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 2 + i*2) >> 3;
			short cur_map_y = (y + bg_y + 3 + 4 + 4) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_DOWN;
	}

	for (i = 0; i < 3; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 4 - 4) >> 3;
			short cur_map_y = (y + bg_y + 3 + 2 + i*2) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_LEFT;
	}

	for (i = 0; i < 3; i++)
	{
			short cur_map_x = (x + bg_x + 3 + 4 + 4) >> 3;
			short cur_map_y = (y + bg_y + 3 + 2 + i*2) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
	
			if (cur_map_tile < 42)
				mask &= ~COLLISION_CAN_RIGHT;
	}


/*	for (i = 0; i < 3; i++)
	{
		for (j = 0; j < 3; j++)
		{
			short cur_map_x = (x + bg_x + 3 + i*4) >> 3;
			short cur_map_y = (y + bg_y + 3 + j*4) >> 3;
	
			unsigned char* cur_map_tile_p = (unsigned char*)&pacman_tilemap + ((cur_map_x) + ((cur_map_y) << 6));
			unsigned char cur_map_tile = *cur_map_tile_p;
			
			//if (i == 2 && j == 2)
			//	continue;

			if (old_map_x != g_cur_map_x || old_map_y != g_cur_map_y)
			{

				trace_dec(cur_map_x);
				trace_char(' ');
				trace_dec(cur_map_y);
				trace_char(' ');
				trace_dec(cur_map_tile);
				trace_char(' ');
				trace_dec(i);
				trace_char(' ');
				trace_dec(j);
				trace_char('\n');
			}


			if (cur_map_tile < 42)
				collisions[i + j*3] = 0;
			else
				collisions[i + j*3] = 1;	
		}
	}

	if (collisions[0] && collisions[1] && collisions[2])
		mask |= COLLISION_CAN_UP;

	if (collisions[6] && collisions[7] && collisions[8])
		mask |= COLLISION_CAN_DOWN;

	if (collisions[0] && collisions[3] && collisions[6])
		mask |= COLLISION_CAN_LEFT;

	if (collisions[2] && collisions[5] && collisions[3])
		mask |= COLLISION_CAN_RIGHT;
*/
	if (old_map_x != g_cur_map_x || old_map_y != g_cur_map_y)
	{
		trace_dec(mask);
		trace_char('\n');
		trace_char('\n');
		old_map_x = g_cur_map_x;
		old_map_y = g_cur_map_y;
	}

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

	short collision = collision_detect(sprites[0].x, sprites[0].y);

//	trace_hex(collision);
//	trace_char('\n');

	keys = __in(0x1001);

	keys &= collision;

	if ((keys & UP_KEY))
	{
		dy = -1;
		sprites[0].orientation = ORIENTATION_UP;
	}

	else if ((keys & DOWN_KEY))
	{
		dy = 1;
		sprites[0].orientation = ORIENTATION_DOWN;
	}

	else if (keys & LEFT_KEY) 
	{
		dx = -1;
		sprites[0].orientation = ORIENTATION_LEFT;
	}

	else if (keys & RIGHT_KEY)
	{
		dx = 1;
		sprites[0].orientation = ORIENTATION_RIGHT;
	}

	sprites[0].x += dx;
	sprites[0].y += dy;

	eat(sprites[0].x, sprites[0].y);

	if (sprites[0].x > 320 + 60)
		sprites[0].x = 8;
	if (sprites[0].x < 8)
		sprites[0].x = 320 + 60;

	if (dx || dy)
		sprites[0].frame ++;
	else
		sprites[0].frame = 0;
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
