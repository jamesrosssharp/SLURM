
pub const RAM_SIZE : usize = 512;

pub struct Scratch {
	ram: [u16; RAM_SIZE], 
}

impl Scratch {

	pub fn new() -> Self {
		Scratch {
			ram : [0; RAM_SIZE],
		}
	}

	pub fn port_op(& mut self, port : u16, val: u16, write : bool) -> u16
	{
		let mut ret : u16 = 0;

		if write {
			self.ram[(port & 0x1ff) as usize] = val;
		}
		else {
			ret = self.ram[(port & 0x1ff) as usize];
		}
		ret
	}

}
