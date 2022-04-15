//
//  GFX Core
//
//

use super::slurm16_soc::*;

use super::copper::*;

pub struct Gfx {

    x: u16,
    y: u16,

    copper: Copper,
}

const H_BACK_PORCH : u16 = 48; 
const V_BACK_PORCH : u16 = 33; 
const H_SYNC_PULSE : u16 = 96;
const H_FRONT_PORCH : u16 = 16;
const V_FRONT_PORCH : u16 = 10;
const V_SYNC_PULSE : u16 = 2;

const TOTAL_X : u16 = 800;
const TOTAL_Y : u16 = 525;

impl Gfx {

    pub fn new() -> Self {
        Gfx { 
            x: 0,
            y: 0,
            copper: Copper::new()
        }
    }

    #[allow(unused_must_use)]
    pub fn port_op(& mut self, port : u16, val: u16, write : bool) -> u16
    {

        if write  // Port write
        {
            match (port & 0xf00) >> 8 {

                0x4 | 0x5 =>  { self.copper.write_mem(port & 0x1ff, val); }

            }
        }

        return 0;
    }

    pub fn step_render(& mut self, fb: &mut [[[u8; NUM_OF_COLOR]; VISIBLE_SCREEN_WIDTH]; VISIBLE_SCREEN_HEIGHT])
    {

        let hs = self.x >= TOTAL_X - H_FRONT_PORCH - H_SYNC_PULSE;
        let vs = self.y >= TOTAL_Y - V_FRONT_PORCH - V_SYNC_PULSE; 

        let (r, g, b, xout, yout, regwr, reg, data) = self.copper.step(self.x, self.y, hs, vs);

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

        if self.x > TOTAL_X
        {
            self.x = 0;
            self.y += 1;
        }

        if self.y > TOTAL_Y
        {
            self.y = 0;
            self.x = 0;
        }
       


    }

}
