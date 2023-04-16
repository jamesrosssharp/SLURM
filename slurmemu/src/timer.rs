

pub struct Timer {

	pub en: bool,
	pub count: u32,
	pub count_out: u16,
	pub match_val: u16,
}

impl Timer {

    pub fn new() -> Self {
        Timer { 
		en: false,
		count: 0,
		count_out: 0,
		match_val: 0
	}
    }

    pub fn port_op(& mut self, _port : u16, val: u16, write : bool) -> u16
    {
	let mut ret : u16 = 0;

        if write {
        	match _port & 0xf
		{
			0 =>	self.en = val & 1 == 1,
			1 =>	self.match_val = val,
			_ =>  (),
		}
	}

        return self.count_out;
    }

    pub fn step(& mut self) -> bool
    {
	if self.en
	{
		self.count = (self.count + 1) & 0x007fffff;
	}
	self.count_out = (self.count >> 7) as u16;
	return self.count_out == self.match_val;
    }

}
