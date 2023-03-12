/*
 *
 *	Sprite rendering 
 *
 *
 */

use std::cmp;

const LINEBUFFER_SIZE : usize = 1024;

pub struct SpriteCore {
	x_ram : [u16; 256],
	y_ram : [u16; 256],
	h_ram : [u16; 256],
	a_ram : [u16; 256],
	line_buffers : [[u8; LINEBUFFER_SIZE] ; 2], 
	collision_buffers : [[u8; LINEBUFFER_SIZE] ; 2], 
	active_buffer : usize,
	prev_hs : bool,
	collision_ram : [u16; 256],
}

impl SpriteCore {

	pub fn new() -> Self {
		SpriteCore {
			x_ram: [0; 256],
			y_ram: [0; 256],
			h_ram: [0; 256],
			a_ram: [0; 256],
			line_buffers : [[0; LINEBUFFER_SIZE] ; 2],
			collision_buffers : [[0; LINEBUFFER_SIZE] ; 2],
			active_buffer : 0,
			prev_hs : false,
			collision_ram : [0; 256],
		}
	}

	pub fn read_collision_ram(& self, addr: u8) -> u16
	{
		return self.collision_ram[addr as usize];
	}

	pub fn write_x_mem(& mut self, addr: u8, data: u16)
	{
		self.x_ram[addr as usize] = data;
	}

	pub fn write_y_mem(& mut self, addr: u8, data: u16)
	{
		self.y_ram[addr as usize] = data;
	}

	pub fn write_h_mem(& mut self, addr: u8, data: u16)
	{
		self.h_ram[addr as usize] = data;
	}

	pub fn write_a_mem(& mut self, addr: u8, data: u16)
	{
		self.a_ram[addr as usize] = data;
	}

	pub fn collision_check(& mut self, render_buffer: usize, xcoord: u16, sprite: usize)
	{
		let coll = self.collision_buffers[render_buffer][xcoord as usize];	

		if coll != 0xff
		{
			self.collision_ram[sprite] |= 1 << (coll >> 4);
		}

		self.collision_buffers[render_buffer][xcoord as usize] = sprite as u8;	
	}

	pub fn render_line(& mut self, mem: & mut Vec<u16>,  _x : u16,	y : u16, render_buffer : usize)
	{
		// Clear render buffer
		for i in 0..LINEBUFFER_SIZE {
			self.line_buffers[render_buffer][i] = 0;
			self.collision_buffers[render_buffer][i] = 0xff;
		}

		// Render next scanline
		   
		for i in 0..256 {
	
				// Get sprite X, Y, width, height, enabled, and address

				let sprite_x = self.x_ram[i] & 0x3ff;
				let sprite_enable : bool = (self.x_ram[i] & 0x400) == 0x400;
				let pal_hi = (self.x_ram[i] & 0x7800) >> 11;
				let stride = (self.x_ram[i] & 0x8000) >> 15;
				let sprite_y = self.y_ram[i] & 0x3ff;
				let sprite_width = (self.y_ram[i] & 0xfc00) >> 10;
				let sprite_end_y = self.h_ram[i] & 0x3ff; 
				let sprite_address = self.a_ram[i];
				let bpp5 = (self.h_ram[i] & 0x8000) == 0x8000;

				if y >= sprite_y && y <= sprite_end_y && sprite_enable {

					//println!("SPRITE_DEBUG: {} {} {} {}".format(sprite_x, sprite_y, sprite_width, sprite_end_y);

					let mut xcoord = sprite_x;
					let mut xcoord_count = sprite_x;
		
					let mut addr = sprite_address + if stride == 0 { (y - sprite_y) * 320 / 4 } else { (y - sprite_y) * 256 / 4 };


					while (xcoord_count <= sprite_x + sprite_width) && ((xcoord as usize) < LINEBUFFER_SIZE)	{
						let data : u16 = mem[addr as usize];

						if bpp5
						{
							match cmp::min(sprite_x + sprite_width	+ 1 - xcoord, LINEBUFFER_SIZE as u16 - xcoord)
							{
								1 => {
									if data & 0x1f != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = (((pal_hi << 4) & 0xe0)  | data & 0x1f) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}
								
								},
								2 => {
									if data & 0x1f != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = (((pal_hi << 4) & 0xe0)  | data & 0x1f) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}
									if data & 0x3e0 != 0 {
										self.line_buffers[render_buffer][(xcoord + 1) as usize] = (((pal_hi << 4) & 0xe0)  | ((data & 0x3e0) >> 5)) as u8;
										self.collision_check(render_buffer, xcoord + 1, i);
									}
								},
								_ => {
									if data & 0x1f != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = (((pal_hi << 4) & 0xe0)  | data & 0x1f) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}
									if data & 0x3e0 != 0 {
										self.line_buffers[render_buffer][(xcoord + 1) as usize] = (((pal_hi << 4) & 0xe0)  | ((data & 0x3e0) >> 5)) as u8;
										self.collision_check(render_buffer, xcoord + 1, i);
									}
									if data & 0x7c00 != 0 {
										self.line_buffers[render_buffer][(xcoord + 2) as usize] = (((pal_hi << 4) & 0xe0)  | ((data & 0x7c00) >> 10)) as u8;
										self.collision_check(render_buffer, xcoord + 2, i);
									}
								},
							}

							addr += 1;
							xcoord += 3;
							xcoord_count += 4;
							  
						} 
						else 
						{

							match cmp::min(sprite_x + sprite_width	+ 1 - xcoord, LINEBUFFER_SIZE as u16 - xcoord)
							{
								1 => {
									if data & 0xf != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)	| data & 0xf) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}

								},
								2 => {
									if data & 0xf != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)	| data & 0xf) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}
									if data & 0xf0 != 0 {
										self.line_buffers[render_buffer][(xcoord + 1) as usize] = ((pal_hi << 4)  | ((data & 0xf0) >> 4)) as u8;
										self.collision_check(render_buffer, xcoord + 1, i);
									}
								},
								3 => {
									if data & 0xf != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)	| data & 0xf) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}
									if data & 0xf0 != 0 {
										self.line_buffers[render_buffer][(xcoord + 1) as usize] = ((pal_hi << 4)  | ((data & 0xf0) >> 4)) as u8;
										self.collision_check(render_buffer, xcoord + 1, i);
									}
									if data & 0xf00 != 0 {
										self.line_buffers[render_buffer][(xcoord + 2) as usize] = ((pal_hi << 4)  | ((data & 0xf00) >> 8)) as u8;
										self.collision_check(render_buffer, xcoord + 2, i);
									}
								},
								_ => {
									if data & 0xf != 0 {
										self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)	| data & 0xf) as u8;
										self.collision_check(render_buffer, xcoord, i);
									}
									if data & 0xf0 != 0 {
										self.line_buffers[render_buffer][(xcoord + 1) as usize] = ((pal_hi << 4)  | ((data & 0xf0) >> 4)) as u8;
										self.collision_check(render_buffer, xcoord + 1, i);
									}
									if data & 0xf00 != 0 {
										self.line_buffers[render_buffer][(xcoord + 2) as usize] = ((pal_hi << 4)  | ((data & 0xf00) >> 8)) as u8;
										self.collision_check(render_buffer, xcoord + 2, i);
									}
									if data & 0xf000 != 0 {
										self.line_buffers[render_buffer][(xcoord + 3) as usize] = ((pal_hi << 4)  | ((data & 0xf000) >> 12)) as u8;
										self.collision_check(render_buffer, xcoord + 3, i);
									}
								},
							}

							addr += 1;
							xcoord += 4;
							xcoord_count += 4;
				
						}				
 
					}
				}
			}
	}

	pub fn step(& mut self, mem: & mut Vec<u16>, x : u16, y : u16, hs: bool, _vs: bool) -> u8 /* index of sprite pixel at x, y */
	{
		if hs && hs != self.prev_hs {
			// Buffer flip
			let render_buffer : usize =  self.active_buffer;
			if self.active_buffer == 0 { self.active_buffer = 1;} else { self.active_buffer = 0;};
			self.render_line(mem, x, y, render_buffer);
		}

		if y == 0 { // Clear collision RAM
			self.collision_ram[(x&0xff) as usize] = 0;
		}

		self.prev_hs = hs;

		return self.line_buffers[self.active_buffer][x as usize];
	}
	
}

