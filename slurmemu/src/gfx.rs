//
//	GFX Core
//
//

use super::slurm16_soc::*;

use super::copper::*;
use super::sprite::*;
use super::background::*;

pub struct Gfx {

	x: u16,
	y: u16,
	frame : u16,

	copper: Copper,
	sprite: SpriteCore,
	bg: BackgroundCore,

	palette : [u16; 256],

	display_mode_halved : bool, /* true = 320x240, false = 640x480 */

}

const H_BACK_PORCH	: u16 = 48; 
const V_BACK_PORCH	: u16 = 33; 
const H_SYNC_PULSE	: u16 = 96;
const H_FRONT_PORCH : u16 = 16;
const V_FRONT_PORCH : u16 = 10;
const V_SYNC_PULSE	: u16 = 2;

const TOTAL_X : u16 = 800;
const TOTAL_Y : u16 = 525;

impl Gfx {

	pub fn new() -> Self {
		Gfx { 
			x: 0,
			y: 0,
			frame: 0,
			copper: Copper::new(),
			sprite: SpriteCore::new(),
			bg: BackgroundCore::new(),
			palette: [0; 256],
			display_mode_halved: false,
		}
	}

	pub fn gfx_reg(& mut self, port : u16, val : u16, write: bool) -> u16
	{

		if write {
			match port & 0xf {
			   2 => /* display mode */ { if val & 1 == 1 { self.display_mode_halved = true } else { self.display_mode_halved = false } }, 
			   _ => {}
			}
		}
		else
		{
			match port & 0xf {
				0 => /* frame count */ { return self.frame },
				1 => /* display y */ { return self.y},
				_ => {},
			}
		}
		return 0;
	}

	#[allow(unused_must_use)]
	pub fn port_op(& mut self, port : u16, val: u16, write : bool) -> u16
	{

		if write  // Port write
		{
			match (port & 0xf00) >> 8 {
				0x0 => /* Sprite X ram */
					self.sprite.write_x_mem((port & 0xff) as u8, val),
				0x1 => /* Sprite Y ram */
					self.sprite.write_y_mem((port & 0xff) as u8, val),
				0x2 => /* Sprite H ram */
					self.sprite.write_h_mem((port & 0xff) as u8, val),
				0x3 => /* Sprite A ram */
					self.sprite.write_a_mem((port & 0xff) as u8, val),
				0x4 | 0x5 => /* Copper list */
					self.copper.write_mem(port & 0x1ff, val),
				0xd => /* Multiple cores */ {
					match (port & 0xf0) >> 4 {
					   0x0 => /* Background */ {
							self.bg.port_op(port & 0xf, val, write);
						},
					   0x2 => /* Copper */ {
							self.copper.port_op(port & 0xf, val, write);
					   },
					   _ => {}
					}

				},
				0xe =>	/* Palette */
					{/*println!("Palette: {:#01x} {:#01x}", port, val);*/ self.palette[(port & 0xff) as usize] = val; },
				0xf => /* gfx core */
				{
					self.gfx_reg(port & 0xff, val, write);	
				},
				_ => {}
			}
		}
		else {

			match (port & 0xf00) >> 8 {
				0x7 => /* collision RAM */ {return self.sprite.read_collision_ram((port & 0xff) as u8)},
				0xf => /* gfx core register */ {return self.gfx_reg(port & 0xff, val, write)},
				_ => {}
			}


		}

		return 0;
	}

	pub fn step_render(& mut self, mem : & mut Vec<u16>, fb: &mut [[[u8; NUM_OF_COLOR]; VISIBLE_SCREEN_WIDTH]; VISIBLE_SCREEN_HEIGHT]) -> (bool /* HS int */ , bool /* VS int */)
	{

		let hs = self.x >= TOTAL_X - H_FRONT_PORCH - H_SYNC_PULSE;
		let vs = self.y >= TOTAL_Y - V_FRONT_PORCH - V_SYNC_PULSE;

		let hs_int = self.x == TOTAL_X - H_FRONT_PORCH - H_SYNC_PULSE;
		let vs_int = (self.y == TOTAL_Y - V_FRONT_PORCH - V_SYNC_PULSE) && (self.x == 0);

		let x = if self.display_mode_halved { self.x >> 1 } else { self.x };
		let y = if self.display_mode_halved { self.y >> 1 } else { self.y };

		let (bg_r, bg_g, bg_b, _xout, _yout, _regwr, _reg, _data) = self.copper.step(x, y, hs, vs);

		let sprite_idx = self.sprite.step(mem, _xout, _yout, hs, vs);

		let bg_idx = self.bg.step(mem, _xout, _yout, hs, vs);

		let mut r : u8 = bg_r;
		let mut g : u8 = bg_g;
		let mut b : u8 = bg_b;

		if (sprite_idx & 0xf) != 0
		{
			r = ((self.palette[sprite_idx as usize] & 0xf00) >> 4) as u8;
			g = (self.palette[sprite_idx as usize] & 0xf0) as u8;
			b = ((self.palette[sprite_idx as usize] & 0xf) << 4) as u8;
		} 
		else if (bg_idx & 0xf) != 0
		{
			r = ((self.palette[bg_idx as usize] & 0xf00) >> 4) as u8;
			g = (self.palette[bg_idx as usize] & 0xf0) as u8;
			b = ((self.palette[bg_idx as usize] & 0xf) << 4) as u8; 
		}

		if (self.x >= H_BACK_PORCH) && (self.x < H_BACK_PORCH + VISIBLE_SCREEN_WIDTH as u16) && (self.y >= V_BACK_PORCH) && (self.y < V_BACK_PORCH + VISIBLE_SCREEN_HEIGHT as u16)
		{
			let u = (self.x - H_BACK_PORCH) as usize;
			let v = (self.y - V_BACK_PORCH) as usize;

			fb[v][u][0] = r;
			fb[v][u][1] = g;
			fb[v][u][2] = b;
		}

		// Increment counters

		self.x += 1;

		if self.x >= TOTAL_X
		{
			self.x = 0;
			self.y += 1;
		}

		if self.y >= TOTAL_Y
		{
			self.y = 0;
			self.x = 0;
			self.frame += 1;
		}

		(hs_int, vs_int)
	}


}
