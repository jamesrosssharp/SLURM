//extern void load_sprite_x(short sprite, short x);

load_sprite_x:
	out [r4, 0x5000], r5
	ret

//extern void load_sprite_y(short sprite, short y);
load_sprite_y:
	out [r4, 0x5100], r5
	ret

//extern void load_sprite_h(short sprite, short h);
load_sprite_h:
	out [r4, 0x5200], r5
	ret

//extern void load_sprite_a(short sprite, short a);
load_sprite_a:
	out [r4, 0x5300], r5
	ret


