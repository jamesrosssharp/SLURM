
#define COUNT_OF(x) (sizeof(x)/sizeof(x[0]))

extern void load_palette(short* palette, int offset, int len);

extern short mandelbrot_palette;

#define MAKE_SPRITE_X(x, en, pal, stride) ((x & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y) ((y & 0x3ff))
#define MAKE_SPRITE_A(a) (a)

void set_up_sprites()
{
	// We can have 4x 64x240 sprites to form a 256x240 image
	
	short x = MAKE_SPRITE_X(32 + 24, 1, 0, 1);
	short y = MAKE_SPRITE_Y(16, 63);
	short h = MAKE_SPRITE_H(33+240);
	short a = MAKE_SPRITE_A(0x4000);

	load_sprite_x(0, x);
	load_sprite_y(0, y);
	load_sprite_h(0, h);
	load_sprite_a(0, a);

	x = MAKE_SPRITE_X(32 + 24 + 64, 1, 0, 1);
	a = MAKE_SPRITE_A(0x4000 + 16);

	load_sprite_x(1, x);
	load_sprite_y(1, y);
	load_sprite_h(1, h);
	load_sprite_a(1, a);

	x = MAKE_SPRITE_X(32 + 24 + 128, 1, 0, 1);
	a = MAKE_SPRITE_A(0x4000 + 32);

	load_sprite_x(2, x);
	load_sprite_y(2, y);
	load_sprite_h(2, h);
	load_sprite_a(2, a);


	x = MAKE_SPRITE_X(32 + 24 + 192, 1, 0, 1);
	a = MAKE_SPRITE_A(0x4000 + 48);

	load_sprite_x(3, x);
	load_sprite_y(3, y);
	load_sprite_h(3, h);
	load_sprite_a(3, a);

}

char col = 0x12;
char blah = 5;
void clear_screen()
{
	unsigned short i;
	char* ptr = (char*)0x8000;
	for (i = 0; i < 256*120; i++)
	//for (i = 0; i < (256*4); i++)
	{
		*ptr++ = col++;
	}
	col ++;
}

extern short mandel_loop(short r, short i);

void render_mandelbrot()
{
	short r1 = -1 * 128 - 64;
	short i1 = -1 * 128;

	short dr = 1;
	short di = 1;

	char* buffer = (char*)(0x8000);
	int i;

	//trace_hex(0x666);
	for (i = 0; i < 240; i++)
	{
		int r;
		short rr = r1;
		//trace_dec(i1);
		for (r = 0; r < 128; r++)
		{
			short iter; 
			short iter2;
			char  byte;

			//trace_hex(rr);
			iter = mandel_loop(rr, i1);			


			rr += dr;
			iter2 = mandel_loop(rr, i1);

			byte = iter | (iter2 << 4);
			*buffer++ = byte;

			rr += dr;
		}
		i1 += di;
	}
}

void enable_interrupts()
{
	__out(0x7000, 0x2);
	global_interrupt_enable();
}
short ticks = 0;
void cycle_palette()
{
	short* pal = (short*)&mandelbrot_palette;
	short last = pal[15];
	int i;

	ticks ++;
	if (ticks == 4)
		ticks = 0;
	else 
		return;

	for (i = 14; i > 0; i--) {
		pal[i+1] = pal[i];
	}
	pal[1] = last;
	load_palette(&mandelbrot_palette, 0, 16);
}

int main()
{
	int i;

 	// set 320x240 mode
    __out(0x5f02, 1);

	// set bg color to black
	__out(0x5d22, 0x0);

	load_palette(&mandelbrot_palette, 0, 16);

	set_up_sprites();
	
	clear_screen();
	enable_interrupts();
	
	for (i = 0; i < 250; i++)
	{
		__sleep();
	}

	render_mandelbrot();
	
	while (1)
	{
		cycle_palette();
		//clear_screen();
		__sleep();
	}
	putc('!');
	exit();
	return 0;
}
