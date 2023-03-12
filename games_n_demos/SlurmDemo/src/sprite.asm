//extern void load_sprite_x(short sprite, short x);
	.function load_sprite_x
	.global load_sprite_x
load_sprite_x:
	out [r4, 0x5000], r5
	ret
	.endfunc

//extern void load_sprite_y(short sprite, short y);
	.function load_sprite_y
	.global load_sprite_y
load_sprite_y:
	out [r4, 0x5100], r5
	ret
	.endfunc

//extern void load_sprite_h(short sprite, short h);

	.function load_sprite_h
	.global load_sprite_h
load_sprite_h:
	out [r4, 0x5200], r5
	ret
	.endfunc

//extern void load_sprite_a(short sprite, short a);

	.function load_sprite_a
	.global load_sprite_a
load_sprite_a:
	out [r4, 0x5300], r5
	ret
	.endfunc

	.end
