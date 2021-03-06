//
//  Emulate Audio core
//

pub const AUDIO_RAM_SIZE : usize = 512;

pub struct AudioCore {

    left_ram  : [i16; AUDIO_RAM_SIZE],
    right_ram : [i16; AUDIO_RAM_SIZE],
    run       : bool,
    left_read_pointer : usize,
    right_read_pointer : usize,
    ticks : u32,
    prev_left_read_high : bool,
    left_accu : i16,
    right_accu : i16
}

impl AudioCore {

    pub fn new() -> Self {
        AudioCore {
            left_ram  : [0; AUDIO_RAM_SIZE],
            right_ram : [0; AUDIO_RAM_SIZE],
            run : false,
            left_read_pointer  : 0,
            right_read_pointer : 0,
            ticks : 0,
            prev_left_read_high : false,
            left_accu : 0,
            right_accu : 0,
        }
    }

    pub fn step(& mut self, audio_out: &mut [i16; 2]) -> (bool /* emit audio */, bool /* Audio int */)
    {
        let mut audio_int = false;
        let mut emit_audio = false;

        if self.run {
            self.ticks += 1;

            // Emit 1 sample every 1024 ticks

            if self.ticks == 1024 {
         
                self.ticks = 0;
                emit_audio  = true;

                self.left_accu += self.left_ram[self.left_read_pointer]; 
                self.right_accu += self.right_ram[self.right_read_pointer];

                self.left_accu /= 2;
                self.right_accu /= 2;

                audio_out[0] = self.left_accu; 
                audio_out[1] = self.right_accu; 
                self.left_read_pointer  += 1;
                self.right_read_pointer += 1;
               
                self.left_read_pointer  &= AUDIO_RAM_SIZE - 1;
                self.right_read_pointer &= AUDIO_RAM_SIZE - 1;

                let new_left_read_high      = self.left_read_pointer & (AUDIO_RAM_SIZE >> 1) == (AUDIO_RAM_SIZE >> 1);
                if self.prev_left_read_high != new_left_read_high {
                    audio_int = true;
                }
                self.prev_left_read_high = new_left_read_high;
            }
        }

        (emit_audio, audio_int)
    }

    pub fn port_op(& mut self, port : u16, val: u16, write : bool) -> u16
    {
        if write {

            if (port & 0xfff) == 0x400 {
                self.run = val & 1 == 1;
            }
            else if (port & 0xe00) == 0x000 {
                self.left_ram[(port & 0x1ff) as usize] = val as i16;
            }
            else if (port & 0xe00) == 0x200 {
                self.right_ram[(port & 0x1ff) as usize] = val as i16;
            }

        }
        else {

            if (port & 0xf00) == 0x400 {
              match port & 0xf {
                    1 => return self.left_read_pointer as u16,
                    2 => return self.right_read_pointer as u16,
                    _ => {},
              }
            }
        }

        0
    }

}


