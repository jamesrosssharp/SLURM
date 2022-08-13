//
//	Emulate Copper
//

enum CopperState {
	Idle,
	Begin,
	Execute,
	WaitV,
	WaitH,
	WriteReg,
}

pub struct Copper {
	enable : bool,
	copper_list: [u16; 512],
	copper_pc: u16,
	copper_state: CopperState,
	r : u8,
	g : u8,
	b : u8,
	reg_addr : u16,
	hv_wait : u16,
	y_flip: u16,
	y_flip_en: bool,
	x_pan: u16,
	global_alpha: u8,
	alpha_override : bool
}

impl Copper {

	pub fn new() -> Self {
		Copper { 
			enable : false,
			copper_list: [0 as u16; 512],
			copper_pc: 0 as u16,
			copper_state: CopperState::Idle,
			r 		: 255,
			g 		: 0,
			b 		: 0,
			reg_addr 	: 0,
			hv_wait 	: 0,
			y_flip 		: 0,
			y_flip_en 	: false,
			x_pan 		: 0,
			global_alpha 	: 15,
			alpha_override  : true
		}
	}

	pub fn get_alpha(&mut self) -> (bool, u8)
	{
		(self.alpha_override, self.global_alpha)
	}

	pub fn write_mem(& mut self, addr: u16, data: u16)
	{
		self.copper_list[addr as usize] = data;
	}

	pub fn begin(& mut self)
	{
		// Wait state
		self.copper_state = CopperState::Execute;
	}

	pub fn port_op(& mut self, port : u16, val: u16, write : bool) -> u16
	{
		if write {
			match port & 0xf {
				0 => /* copper control */ { self.enable = val & 1 == 1; },
				1 => /* copper Y flip */ {
					self.y_flip = val & 0x1ff;
					self.y_flip_en = (val & 0x8000) == 0x8000;
				},
				2 => /* background color */ {
					self.r = ((val & 0xf00) >> 4) as u8;
					self.g = (val & 0x0f0) as u8;
					self.b = ((val & 0x00f) << 4) as u8;
				},
				3 => /* x pan */ {
					self.x_pan = val;
				},
				4 => /* alpha */ {
					self.alpha_override = (val & 0x8000) == 0x8000;
					self.global_alpha   = (val & 0xf) as u8;
				},
				_ => {},
			}
		}

		0
	}

	pub fn execute(& mut self, x : u16, y : u16)
	{
		let mut inc_pc : bool = true;

		let ins = self.copper_list[(self.copper_pc & 0x1ff) as usize];

		match (ins & 0xf000) >> 12 { 
			0x1 => /* jump */
			{
				inc_pc = false;
				self.copper_pc = ins & 0x1ff;
			},
			0x2 => /* V wait */
			{
				self.hv_wait = ins & 0x3ff;
				self.copper_state = CopperState::WaitV;
			},
			0x3 => /* H wait */
			{
				self.hv_wait = ins & 0x3ff;
				self.copper_state = CopperState::WaitH; 
			},
			0x4 => /* skip V */
			{
				if y >= ins & 0x3ff {
					self.copper_state = CopperState::Begin;
					self.copper_pc += 2;
					inc_pc = false;
				}
			},
			0x5 => /* skip H */
			{
				if x >= ins & 0x3ff {
					self.copper_state = CopperState::Begin;
					self.copper_pc += 2;
					inc_pc = false;
				}
	 
			},
			0x6 => /* update background color and wait next scanline */
			{
				self.r = ((ins & 0xf00) >> 4) as u8;
				self.g = (ins & 0x0f0) as u8;
				self.b = ((ins & 0x00f) << 4) as u8;
				self.hv_wait = y + 1;
				self.copper_state = CopperState::WaitV;
			},
			0x7 => /* V wait N */
			{
				self.hv_wait = y + (ins & 0x3ff);
				self.copper_state = CopperState::WaitV;
	
			},
			0x8 => /* H wait N */
			{
				self.hv_wait = x + (ins & 0x3ff);
				self.copper_state = CopperState::WaitH;
			},
			0x9 => /* write gfx register */
			{

			},
			0xa => /* x pan write */
			{
				self.x_pan = ins & 0x3ff; 
			},
			0xb => /* x pan write and v wait next scanline */
			{
				self.x_pan = ins & 0x3ff; 
				self.hv_wait = y + 1;
				self.copper_state = CopperState::WaitV;
			},
			0xc => /* write background color */ {
				self.r = ((ins & 0xf00) >> 4) as u8;
				self.g = (ins & 0x0f0) as u8;
				self.b = ((ins & 0x00f) << 4) as u8; 
			},
			0xd => /* write alpha */ {
				self.global_alpha = (ins & 0xf) as u8;
			},
			_ => {}
		}

		if inc_pc {
			self.copper_pc += 1;
		}
	}

	pub fn wait_hv(& mut self, wait : u16)
	{
		if wait >= self.hv_wait {
			self.copper_state = CopperState::Execute;
		}
	}
	
	pub fn write_reg(& mut self) -> (bool, u16, u16)
	{
		let reg_data = self.copper_list[(self.copper_pc & 0x1ff) as usize];
		self.copper_state = CopperState::Execute; 
		return (true, self.reg_addr, reg_data);
	}

	pub fn step(& mut self, x : u16, y : u16, _hs: bool, vs: bool) -> 
		(u8 /* BG Color R */, u8 /* G */, u8 /* B */, u16 /* x out */, u16 /* y out */, bool /* register write? */, u16 /* register address */, u16 /* register data */) 
	{


		if vs {

			if self.enable { self.copper_state = CopperState::Begin;}
			self.copper_pc = 0;
		}
		else
		{

			match self.copper_state
			{
				CopperState::Idle => {}, 
				CopperState::Begin => self.begin(),
				CopperState::Execute => self.execute(x, y),
				CopperState::WaitV => self.wait_hv(y),
				CopperState::WaitH => self.wait_hv(x),
				CopperState::WriteReg => {
					let (write_reg, reg, reg_data) = self.write_reg();
					return (self.r, self.g, self.b, x, y, write_reg, reg, reg_data);
				}
			}

		}

		let mut yy = y;

		if self.y_flip_en && y > self.y_flip {
			yy = (self.y_flip - y) + self.y_flip;
		}

		(self.r, self.g, self.b, x + self.x_pan, yy, false, 0, 0)

	}

}
