//
//  This emulator is based on Rust NES Emulator by K (kamiyaowl@gmail.com)
//
//  https://github.com/kamiyaowl/rust-nes-emulator
//
//

/*use std::io::Read;
use std::io::stdin;
*/

use super::slurm16_cpu::*;
use super::port_controller::*;

//use std::{thread, time};

//const TARGET_HZ: u64 = 60;
const MEM_SIZE : usize = 65536;

pub const NUM_OF_COLOR : usize = 3;
pub const VISIBLE_SCREEN_WIDTH: usize = 640;
pub const VISIBLE_SCREEN_HEIGHT: usize = 480;

pub enum SlurmButton {
    A,
    B,
    UP,
    DOWN,
    LEFT,
    RIGHT
}

pub struct Slurm16SoC {

    pub mem : Vec<u16>,
    pub cpu : Slurm16CPU,
    pub port_controller : PortController,

    pub exit_run_loop : bool,
}

impl Slurm16SoC 
{
    pub fn new() -> Self 
    {
        Slurm16SoC {
            mem: vec![0; MEM_SIZE],
            cpu: Slurm16CPU::new(),
            port_controller: PortController::new(),
            exit_run_loop: false
        }

    }

    /// Set the memory contents
    pub fn set_memory(& mut self, mem : &Vec<u16>, address : u16, len : usize)
    {
        for i in 0..len {
            self.mem[address as usize + i] = mem[i];
        }
    }

    pub fn set_flash(& mut self, flash : &Vec<u16>)
    {
        self.port_controller.flash.set_flash(flash);
    }

    pub fn step(& mut self, fb : &mut [[[u8; NUM_OF_COLOR]; VISIBLE_SCREEN_WIDTH]; VISIBLE_SCREEN_HEIGHT], audio_out: &mut [i16; 2]) -> 
            (bool /* vs int - tell caller to buffer flip */, bool /* emit audio - tell caller to emit an audio buffer */)
    {
        let (hs_int, vs_int) = self.port_controller.gfx.step_render(&mut self.mem, fb);
        let gpio_int = self.port_controller.gpio.step();
        let flash_int = self.port_controller.flash.step(&mut self.mem);
        let (emit_audio, audio_int) = self.port_controller.audio.step(audio_out);
	let timer_int = self.port_controller.timer.step();
        let irq = self.port_controller.interrupt_controller.process_irq(hs_int, vs_int, audio_int, flash_int, gpio_int, timer_int);

        self.cpu.execute_one_instruction(&mut self.mem, &mut self.port_controller, irq);
        (vs_int, emit_audio)
    }

    pub fn push_button(& mut self, button : SlurmButton)
    {
        //println!("Push {}", button as u16);
        self.port_controller.gpio.push_button(button);
    }

    pub fn release_button(& mut self, button : SlurmButton)
    {
        //println!("Release {}", button as u16);
        self.port_controller.gpio.release_button(button);
    }

    pub fn get_pc(&mut self) -> u16
    {
        self.cpu.get_pc()
    }

}
