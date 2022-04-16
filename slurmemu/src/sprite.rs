/*
 *
 *  Sprite rendering 
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
    active_buffer : usize,
    prev_hs : bool,
}

impl SpriteCore {

    pub fn new() -> Self {
        SpriteCore {
            x_ram: [0; 256],
            y_ram: [0; 256],
            h_ram: [0; 256],
            a_ram: [0; 256],
            line_buffers : [[0; LINEBUFFER_SIZE] ; 2],
            active_buffer : 0,
            prev_hs : false,
        }
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

    pub fn render_line(& mut self, mem: & mut Vec<u16>,  _x : u16,  y : u16, render_buffer : usize)
    {
        // Clear render buffer
        for i in 0..LINEBUFFER_SIZE {
            self.line_buffers[render_buffer][i] = 0;
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


                if y >= sprite_y && y < sprite_end_y && sprite_enable {

                    let mut xcoord = sprite_x;
                    let mut addr = sprite_address + if stride == 0 { (y - sprite_y) * 128 / 4 } else { (y - sprite_y) * 256 / 4 };


                    while (xcoord < sprite_x + sprite_width) && ((xcoord as usize) < LINEBUFFER_SIZE)  {
                        let data : u16 = mem[addr as usize];

                        match cmp::min(sprite_x + sprite_width - xcoord, LINEBUFFER_SIZE as u16 - xcoord)
                        {
                            1 => {
                                self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)  | data & 0xf) as u8;
                            },
                            2 => {
                                self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)  | data & 0xf) as u8;
                                self.line_buffers[render_buffer][(xcoord + 1) as usize] = ((pal_hi << 4)  | ((data & 0xf0) >> 4)) as u8;
                            },
                            3 => {
                                self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)  | data & 0xf) as u8;
                                self.line_buffers[render_buffer][(xcoord + 1) as usize] = ((pal_hi << 4)  | ((data & 0xf0) >> 4)) as u8;
                                self.line_buffers[render_buffer][(xcoord + 2) as usize] = ((pal_hi << 4)  | ((data & 0xf00) >> 8)) as u8;
                            },
                            _ => {
                                self.line_buffers[render_buffer][xcoord as usize] = ((pal_hi << 4)  | data & 0xf) as u8;
                                self.line_buffers[render_buffer][(xcoord + 1) as usize] = ((pal_hi << 4)  | ((data & 0xf0) >> 4)) as u8;
                                self.line_buffers[render_buffer][(xcoord + 2) as usize] = ((pal_hi << 4)  | ((data & 0xf00) >> 8)) as u8;
                                self.line_buffers[render_buffer][(xcoord + 3) as usize] = ((pal_hi << 4)  | ((data & 0xf000) >> 12)) as u8;
                            },
                        }


                        addr += 1;
                        xcoord += 4;
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

        self.prev_hs = hs;

        return self.line_buffers[self.active_buffer][x as usize];
    }
    
}

