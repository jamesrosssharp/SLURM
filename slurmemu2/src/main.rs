mod slurm16_cpu;

use crate::slurm16_cpu::Slurm16CPU;

fn main() {


    let mut cpu = Slurm16CPU::new();
    let mem : Vec<u16> = vec![0x1123];
    cpu.execute_one_instruction(&mem);


    println!("Hello, world!");
}
