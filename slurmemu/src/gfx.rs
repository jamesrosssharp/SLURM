//
//  GFX Core
//
//

use super::slurm16_soc::*;

pub struct Gfx {

    x: u16,
    y: u16,

}

const H_BACK_PORCH : u16 = 48; 
const V_BACK_PORCH : u16 = 33; 


impl Gfx {

    pub fn new() -> Self {
        Gfx { 
            x: 0,
            y: 0
        }
    }

    #[allow(unused_must_use)]
    pub fn port_op(& self, _port : u16, _val: u16, _write : bool) -> u16
    {
        return 0;
    }

    pub fn step_render(& mut self, fb: &mut [[[u8; NUM_OF_COLOR]; VISIBLE_SCREEN_WIDTH]; VISIBLE_SCREEN_HEIGHT])
    {

        self.x += 1;

        if self.x > 800
        {
            self.x = 0;
            self.y += 1;
        }

        if self.y > 525
        {
            self.y = 0;
            self.x = 0;
        }
        
        if (self.x >= H_BACK_PORCH) && (self.x < H_BACK_PORCH + VISIBLE_SCREEN_WIDTH as u16) && (self.y >= V_BACK_PORCH) && (self.y < V_BACK_PORCH + VISIBLE_SCREEN_HEIGHT as u16)
        {
            let u = (self.x - H_BACK_PORCH) as usize;
            let v = (self.y - V_BACK_PORCH) as usize;


            fb[v][u][0] = 0xff;
            fb[v][u][1] = 0;
            fb[v][u][2] = 0;

        }


    }

}
