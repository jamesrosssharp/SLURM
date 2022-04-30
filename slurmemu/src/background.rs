//
//  Background core : emulate background_controller2.v
//
//  N.B: Some modifications made to operation that need to be implemented in RTL: these
//  are configurable tilemap stride and tile size.
//

const LINEBUFFER_SIZE : usize = 1024;

const STRIDE256 : u16 = 0;
const STRIDE128 : u16 = 1;
const STRIDE64  : u16 = 2;
/*const STRIDE32  : u16 = 3;*/

const SIZE16X16 : u16 = 0;
/*const SIZE8X8 : u16 = 1;*/

pub struct BackgroundCore {
    
    tilemap_x : u16,
    tilemap_y : u16,
    tilemap_address : u16,
    tileset_address : u16,
    tilemap_stride  : u16, 
    tile_size : u16,
    palette_hi : u16,
    bg_enable : bool,

    tilemap2_x : u16,
    tilemap2_y : u16,
    tilemap2_address : u16,
    tileset2_address : u16,
    tilemap2_stride  : u16, 
    tile_size2 : u16,
    palette_hi2 : u16,
    bg_enable2 : bool,

    line_buffers : [[[u8; LINEBUFFER_SIZE] ; 2] ; 2], 
    active_buffer : usize,
    prev_hs : bool,

}

impl BackgroundCore {

    pub fn new() -> Self {
        BackgroundCore {
            tilemap_x : 0,
            tilemap_y : 0,
            tilemap_address : 0,
            tileset_address : 0,
            tilemap_stride : STRIDE256,
            tile_size : SIZE16X16,
            palette_hi : 0,
            bg_enable : false,

            tilemap2_x : 0,
            tilemap2_y : 0,
            tilemap2_address : 0,
            tileset2_address : 0,
            tilemap2_stride : STRIDE256,
            tile_size2 : SIZE16X16,
            palette_hi2 : 0,
            bg_enable2 : false,

            line_buffers : [[[0; LINEBUFFER_SIZE] ; 2] ; 2],
            active_buffer : 0,
            prev_hs : false,
 
        }
    }

    pub fn port_op(& mut self, port : u16, val : u16, write : bool) -> u16 {

        if write
        {
            match port
            {
                0 => /* control reg */ {
                    self.bg_enable = (val & 1) != 0;
                    self.palette_hi = (val & 0xf0) >> 4;
                    self.tilemap_stride = (val & 0x300) >> 8;
                    self.tile_size = (val & 0x8000) >> 15;
                },
                1 => /* tile map X */ {
                    self.tilemap_x = val;
                },
                2 => /* tile map Y */ {
                    self.tilemap_y = val;
                },
                3 => /* tile map address */ {
                    self.tilemap_address = val;
                },
                4 => /* tile set address */ {
                    self.tileset_address = val;
                },
                // Layer 2
                5 => /* control reg */ {
                    self.bg_enable2 = (val & 1) != 0;
                    self.palette_hi2 = (val & 0xf0) >> 4;
                    self.tilemap2_stride = (val & 0x300) >> 8;
                    self.tile_size2 = (val & 0x8000) >> 15;
                },
                6 => /* tile map X */ {
                    self.tilemap2_x = val;
                },
                7 => /* tile map Y */ {
                    self.tilemap2_y = val;
                },
                8 => /* tile map address */ {
                    self.tilemap2_address = val;
                },
                9 => /* tile set address */ {
                    self.tileset2_address = val;
                },
            
                _ => {},
            }
        }

        return 0;
    }

    pub fn stride_val(& self, stride : u16) -> u16
    {
        match stride {
            STRIDE256 => 256,
            STRIDE128 => 128,
            STRIDE64 => 64,
            _ => 32
        }
    }

    pub fn render_line(&mut self, mem: & mut Vec<u16>,  _x : u16, y : u16, render_buffer : usize, layer : usize, 
                        tilemap_x : u16, tilemap_y : u16, tilemap_address : u16, tilemap_stride : u16, tileset_address : u16, tile_size : u16, palette_hi : u16)
    {
        let mut xcoord = 16;

        let mut addr : usize = match tile_size {
            SIZE16X16  => /* 16x16 */ ((tilemap_address as usize) << 1) + ((tilemap_x as usize)>>4) + (((tilemap_y + y)>>4)* self.stride_val(tilemap_stride)) as usize, 
            _ => /* 8x8 */ ((tilemap_address as usize) << 1) + ((tilemap_x as usize)>>3) + (((tilemap_y + y)>>3) * self.stride_val(tilemap_stride)) as usize,
            
        };

        //println!("addr {} {} {} ", addr, self.tilemap_address, self.tilemap_x);

        let tile_y = match tile_size {
            SIZE16X16 => (tilemap_y + y) & 0xf,
            _ => (tilemap_y + y) & 0x7,
        };

        let mut tile_x = match tile_size {
           SIZE16X16 => (tilemap_x) & 0xf,
            _ => (tilemap_x) & 0x7,  
        };

        while xcoord < 720 {

            // Look up tile
            let mapdata : u16 = mem[(addr>>1)];

            // Which byte has tile index
            let tile : u16 = match addr & 1 {
                0 => (mapdata & 0xff) as u16,
                _ => ((mapdata >> 8) & 0xff) as u16,
            };

            // Compute address in tilemap for pixel data
         
            if tile != 0xff
            {

                let tileset_addr : usize = match tile_size {
                    SIZE16X16 => ((tileset_address as usize)<<2) + (((tile&0xf) << 4) as usize) + (((tile & 0xf0) << 8) as usize)  + ((tile_y as usize)<<8) + tile_x as usize,
                    _ => ((tileset_address as usize)<<2) + (((tile % 32) * 8) as usize) + (((tile as usize) / 32) * 256*8)  + ((tile_y as usize)<<8) + tile_x as usize,
     
                };

                //println!("{}", addr >> 1);

                let tiledata : u16 = mem[(tileset_addr >> 2)];
                let pix : u8 = match tileset_addr & 0x3 {
                    0 => (tiledata & 0xf) as u8,
                    1 => ((tiledata >> 4) & 0xf) as u8,
                    2 => ((tiledata >> 8) & 0xf) as u8,
                    _ => ((tiledata >> 12) & 0xf) as u8,
                };

                self.line_buffers[layer][render_buffer][xcoord] = ((palette_hi as u8) << 4) | pix;

            }
            else {
                self.line_buffers[layer][render_buffer][xcoord] = 0;
            }

            tile_x += 1;

            match self.tile_size {
                SIZE16X16 => {
                    if tile_x == 16 {
                        tile_x = 0;
                        addr += 1;
                    }
                },
                _  => {
                    if tile_x == 8 {
                        tile_x = 0;
                        addr += 1;
                    }
                }
            }

            xcoord += 1;
        }
    }

    pub fn step(& mut self, mem: & mut Vec<u16>, x : u16, y : u16, hs: bool, _vs: bool) -> u8 /* index of sprite pixel at x, y */
    {
        if hs && hs != self.prev_hs {
            // Buffer flip
            let render_buffer : usize =  self.active_buffer;
            if self.active_buffer == 0 { self.active_buffer = 1;} else { self.active_buffer = 0;};
            
            if self.bg_enable {
                self.render_line(mem, x, y, render_buffer, 0, self.tilemap_x, self.tilemap_y, self.tilemap_address, self.tilemap_stride, self.tileset_address, self.tile_size, self.palette_hi);
            }

            if self.bg_enable2 {
                self.render_line(mem, x, y, render_buffer, 1, self.tilemap2_x, self.tilemap2_y, self.tilemap2_address, self.tilemap2_stride, self.tileset2_address, self.tile_size2, self.palette_hi2);
            }
        }

        self.prev_hs = hs;

        let col1 = self.line_buffers[0][self.active_buffer][x as usize];
        let col2 = self.line_buffers[1][self.active_buffer][x as usize];

        if col1 & 0xf == 0 { return col2; } else { return col1; }
    }
  
}


