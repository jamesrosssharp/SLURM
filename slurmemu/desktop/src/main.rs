extern crate slurm_emulator;
use slurm_emulator::slurm16_soc::Slurm16SoC;

use std::env;
use std::process;

#[allow(dead_code)]
fn main() {

    let mut soc = Slurm16SoC::new();

    // Load a ROM file

    let args: Vec<String> = env::args().collect();

    if args.len() != 2
    {
        println!("Usage: {} <rom file>\n", args[0]);
        process::exit(1);
    }

    let bytes = std::fs::read(&args[1]).unwrap();
    
    let mut rom_data : Vec<u16> = Vec::new();

    for byte_pair in bytes.chunks_exact(2) {
        let short : u16 = u16::from_le_bytes([byte_pair[0], byte_pair[1]]);
        //println!("{:x}", short);
        rom_data.push(short);
    }
    soc.set_memory(&rom_data, 0, rom_data.len());  

    soc.run();
    //soc.single_step();
}
