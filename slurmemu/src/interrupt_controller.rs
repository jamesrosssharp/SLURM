/*
 *
 *  Interrupt controller
 *
 *
 */

const HSYNC_INTERRUPT : u8 = 1;
const VSYNC_INTERRUPT : u8 = 2;
const AUDIO_INTERRUPT : u8 = 3;
const FLASH_INTERRUPT : u8 = 4;
const GPIO_INTERRUPT  : u8 = 5;
const TIMER_INTERRUPT  : u8 = 6;

pub struct InterruptController {

    interrupt_pending : u8,
    interrupt_enabled : u8,

}

impl InterruptController {

    pub fn new() -> Self {
        InterruptController {
            interrupt_pending : 0,
            interrupt_enabled : 0
        }
    }

    pub fn port_op(&mut self, port : u16, val: u16, write : bool) -> u16
    {
        //println!("Interrupt port op {:#01x} {:#01x} {}", port, val, write);

        match port & 0xf {
            0 => { let a : u8 = self.interrupt_enabled; /* read / set enabled */
                    if write { self.interrupt_enabled = val as u8; }
                    return a as u16;
                },
            1 => { if write { /* clear pending */
                        self.interrupt_pending = self.interrupt_pending & (!val as u8);
                    }
            },
            2 => { return self.interrupt_pending as u16},  /* read out pending */
            _ => ()
        }
        return 0;
    }

    pub fn process_irq(&mut self, hs : bool, vs : bool, audio : bool, flash : bool, gpio : bool, timer: bool) -> u8 /* IRQ -> zero means no IRQ raised */ {

        //println!("process_irq: {} {} {} {}", hs, vs, self.interrupt_pending, self.interrupt_enabled);

        if hs {
            self.interrupt_pending |= 1 << (HSYNC_INTERRUPT - 1);
        }
        if vs {
            self.interrupt_pending |= 1 << (VSYNC_INTERRUPT - 1);
        }
        if audio {
            self.interrupt_pending |= 1 << (AUDIO_INTERRUPT - 1);
        }
        if flash {
            self.interrupt_pending |= 1 << (FLASH_INTERRUPT - 1);
        }
        if gpio {
            self.interrupt_pending |= 1 << (GPIO_INTERRUPT - 1);
        }
	if timer {
	    self.interrupt_pending |= 1 << (TIMER_INTERRUPT - 1);
	}

	/*if a > 1
	{
		println!("Double int");
	}*/

        let ints : Vec<u8> = vec![HSYNC_INTERRUPT, VSYNC_INTERRUPT, AUDIO_INTERRUPT, FLASH_INTERRUPT, GPIO_INTERRUPT, TIMER_INTERRUPT];

        for int in ints {
            if (self.interrupt_pending & self.interrupt_enabled) & (1 << (int - 1)) != 0 {
                //println!("Firing IRQ!{}", int);
                return int;
            }
        }
        return 0;
    }
}

