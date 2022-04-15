//
//  Emulate Copper
//

enum CopperState {
    Begin   = 0,
/*    Execute = 1,
    WaitV  = 2,
    WaitH  = 3,
    WriteReg = 4,*/
}

pub struct Copper {

    copper_list: [u16; 512],
    copper_pc: u16,
    copper_state: CopperState 
}

impl Copper {

   pub fn new() -> Self {
        Copper { 
            copper_list: [0 as u16; 512],
            copper_pc: 0 as u16,
            copper_state: CopperState::Begin
        }
    }

    pub fn write_mem(& mut self, addr: u16, data: u16)
    {
        self.copper_list[addr as usize] = data;
    }

    pub fn step(& mut self, x : u16, y : u16, _hs: bool, _vs: bool) -> (u8 /* BG Color R */, u8 /* G */, u8 /* B */, u16 /* x out */, u16 /* y out */, bool /* register write? */, u16 /* register address */, u16 /* register data */) {

        let R : u8 = 255;
        let G : u8 = 0;
        let B : u8 = 0;

        (R, G, B, x, y, false, 0, 0)
    }

}
