//
//  This emulator is based on Rust NES Emulator by K (kamiyaowl@gmail.com)
//
//  https://github.com/kamiyaowl/rust-nes-emulator
//
//

use std::io::Read;
use std::io::stdin;

use super::slurm16_cpu::*;
use super::port_controller::*;

use std::{thread, time};

const TARGET_HZ: u64 = 60;
const MEM_SIZE : usize = 65536;

pub const NUM_OF_COLOR : usize = 3;
pub const VISIBLE_SCREEN_WIDTH: usize = 640;
pub const VISIBLE_SCREEN_HEIGHT: usize = 480;

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

    ///
    /// Run the SoC. This will step instructions and hardware operations one at a time, locked to
    /// 25 MHz clock (done by sleeping to perform exactly 416,667 operations per gfx buffer flip @ 60
    /// Hz)
    ///
    /// DEPRECATED - SINCE WE NOW USE TIMING FROM PISTON_WINDOW EVENTS IN DESKTOP
    ///
    pub fn run(& mut self)
    {
        let target_ft = time::Duration::from_micros(1000000 / TARGET_HZ);
    
        while ! self.exit_run_loop {
            
            let frame_time = time::Instant::now();

            for _j in 0..416_667 {
                self.cpu.execute_one_instruction(&mut self.mem, &mut self.port_controller);
                if self.port_controller.exit { self.exit_run_loop = true; break; }
            }

            if let Some(i) = (target_ft).checked_sub(frame_time.elapsed()) {
                thread::sleep(i)
            }
        }
        println!("Emulation finished");
    }

    // Single step the CPU with debug
    pub fn single_step(& mut self)
    {
        loop {
            self.cpu.print_pc();     
            self.cpu.execute_one_instruction(&mut self.mem, &mut self.port_controller);
            self.cpu.print_regs();
            if self.port_controller.exit { break; }
            stdin().read(&mut [0]).unwrap();
        }
    }

    pub fn step(& mut self, fb : &mut [[[u8; NUM_OF_COLOR]; VISIBLE_SCREEN_WIDTH]; VISIBLE_SCREEN_HEIGHT])
    {
        self.cpu.execute_one_instruction(&mut self.mem, &mut self.port_controller);
        self.port_controller.gfx.step_render(fb);
    }

}
