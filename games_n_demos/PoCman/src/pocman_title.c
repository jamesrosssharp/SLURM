
#define TITLE_OFFSET 0x8000


void set_up_sprites()
{
	// We can have 5x 64x200 sprites to form a 320x200 image
	
	short x = MAKE_SPRITE_X(24, 1, 2, 0);
	short y = MAKE_SPRITE_Y(16+20, 63);
	short h = MAKE_SPRITE_H(33+200);
	short a = MAKE_SPRITE_A(TITLE_OFFSET);

	load_sprite_x(0, x);
	load_sprite_y(0, y);
	load_sprite_h(0, h);
	load_sprite_a(0, a);

	x = MAKE_SPRITE_X(24 + 64, 1, 2, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 16);

	load_sprite_x(1, x);
	load_sprite_y(1, y);
	load_sprite_h(1, h);
	load_sprite_a(1, a);

	x = MAKE_SPRITE_X(24 + 128, 1, 2, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 32);

	load_sprite_x(2, x);
	load_sprite_y(2, y);
	load_sprite_h(2, h);
	load_sprite_a(2, a);


	x = MAKE_SPRITE_X(24 + 192, 1, 2, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 48);

	load_sprite_x(3, x);
	load_sprite_y(3, y);
	load_sprite_h(3, h);
	load_sprite_a(3, a);

	x = MAKE_SPRITE_X(24 + 256, 1, 2, 0);
	a = MAKE_SPRITE_A(TITLE_OFFSET + 64);

	load_sprite_x(4, x);
	load_sprite_y(4, y);
	load_sprite_h(4, h);
	load_sprite_a(4, a);

}

void kill_sprites()
{
	int i;
	for (i = 0; i < 5; i++)
	{
		load_sprite_x(i, 0);
	}
}



void do_title_pic()
{

	// Set up sprites
	set_up_sprites();
	

	// Wait for A button
	while (1)
	{
		short keys = __in(0x1001);

		if ((keys & A_KEY))
		{
			break;
		}

	}

	kill_sprites();
}

