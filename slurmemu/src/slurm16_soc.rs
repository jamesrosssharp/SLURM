


use super::slurm16_cpu::*;
use super::port_controller::*;
use super::uart::*;

use std::{thread, time};

const TARGET_HZ: u64 = 60;
const MEM_SIZE : usize = 65536;

pub struct Slurm16SoC {

    pub mem : Vec<u16>,
    pub cpu : Slurm16CPU,
    pub port_controller : PortController,
    pub uart : Uart,

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
            uart: Uart::new(),
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
    pub fn run(& mut self)
    {
        let target_ft = time::Duration::from_micros(1000000 / TARGET_HZ);
    
        while ! self.exit_run_loop {
            
            let frame_time = time::Instant::now();

            for _j in 0..416_667 {
                self.cpu.execute_one_instruction(&self.mem);
            }

            if let Some(i) = (target_ft).checked_sub(frame_time.elapsed()) {
                thread::sleep(i)
            }
        }
    }

    pub fn trap(& mut self)
    {
        self.exit_run_loop = true;
    }

}
