//
//  Emulate Copper
//

enum CopperState {
    Begin   = 0,
    Execute = 1,
    WaitV  = 2,
    WaitH  = 3,
    WriteReg = 4,
}

pub struct Copper {

    copper_list: [u16; 512],
    copper_pc: u16,
    copper_state: CopperState,
    r : u8,
    g : u8,
    b : u8,
    reg_addr : u16,
    hv_wait : u16
}

impl Copper {

   pub fn new() -> Self {
        Copper { 
            copper_list: [0 as u16; 512],
            copper_pc: 0 as u16,
            copper_state: CopperState::Begin,
            r : 255,
            g : 0,
            b : 0,
            reg_addr : 0,
            hv_wait : 0
        }
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

            },
			0xb => /* x pan write and v wait next scanline */
            {

            },
			0xc => /* write background color */ {
                self.r = ((ins & 0xf00) >> 4) as u8;
                self.g = (ins & 0x0f0) as u8;
                self.b = ((ins & 0x00f) << 4) as u8; 
            },
			0xd => /* write alpha */ {

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
            self.copper_state = CopperState::Begin;
            self.copper_pc = 0;
        }
        else
        {

            match self.copper_state
            {
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

        (self.r, self.g, self.b, x, y, false, 0, 0)

    }

}
