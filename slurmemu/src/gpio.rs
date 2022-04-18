/*
 *
 *  Sprite rendering 
 *
 *
 */

use super::slurm16_soc::*;

pub struct GpioCore {
   gpio_in : u8, 
   gpio_saved : u8
}

impl GpioCore {

    pub fn new() -> Self {
        GpioCore {
            gpio_in : 0,
            gpio_saved : 0
        }
    }

    pub fn push_button(& mut self, button : SlurmButton)
    {
        match button
        {
            SlurmButton::UP =>
                self.gpio_in |= 1,
            SlurmButton::DOWN =>
                self.gpio_in |= 2,
            SlurmButton::LEFT =>
                self.gpio_in |= 4,
            SlurmButton::RIGHT =>
                self.gpio_in |= 8,
            SlurmButton::A => 
                self.gpio_in |= 16,
            SlurmButton::B =>
                self.gpio_in |= 32
       }
    }

    pub fn release_button(& mut self, button : SlurmButton)
    {
        match button
        {
            SlurmButton::UP =>
                self.gpio_in &= !1,
            SlurmButton::DOWN =>
                self.gpio_in &= !2,
            SlurmButton::LEFT =>
                self.gpio_in &= !4,
            SlurmButton::RIGHT =>
                self.gpio_in &= !8,
            SlurmButton::A => 
                self.gpio_in &= !16,
            SlurmButton::B =>
                self.gpio_in &= !32
       }
 
    }

    pub fn step(& mut self) -> bool /* interrupt */ {
        let mut int : bool = false;
        if self.gpio_in != self.gpio_saved {
            int = true;
        }
        self.gpio_saved = self.gpio_in;
        int
    }

    pub fn port_op(&mut self, port : u16, _val: u16, _write : bool) -> u16
    {
        match port & 0x0f {
            0 => /* output register */ {},
            1 => /* input register */ return self.gpio_saved as u16,
            _ => {},
        }
        return 0;
    }

}

