use super::uart::Uart;
use super::gfx::Gfx;
use super::interrupt_controller::InterruptController;

use std::io::{self, Write};

pub struct PortController {
    pub uart: Uart,
    pub exit: bool,
    pub gfx: Gfx,
    pub interrupt_controller: InterruptController,
}

///     The PortController simply implements the port address map
impl PortController {

    pub fn new() -> Self 
    {
        PortController { 
            uart: Uart::new(),
            gfx: Gfx::new(),
            exit: false,
            interrupt_controller: InterruptController::new(),
        }
    }

    pub fn handle_trace(&mut self, port : u16, val : u16, write : bool)
    {
        //println!("handle trace: Port: {:#01x}", port);
        if (port == 0x6006) && write
        {
            self.exit = true;
        }
        else if (port == 0x6000) && write
        {
           print!("{}", val); 
        }
        else if (port == 0x6001) && write
        {
            print!("{}", val as u8 as char);
        }
        else if (port == 0x6002) && write
        {
            print!("{:#01x}", val);
        }
        io::stdout().flush().unwrap();

    }

    pub fn port_op(&mut self, port : u16, val: u16, write : bool) -> u16
    {
   
        match (port & 0xf000) >> 12 {
            // 0 - UART
            0 => return self.uart.port_op(port, val, write),
            // 1 - GPIO
            // 2 - PWM
            // 3 - Audio
            // 4 - SPI
            // 5 - GFX
            5 => return self.gfx.port_op(port, val, write),
            // 6 - Trace port
            6 => self.handle_trace(port, val, write),
            // 7 - Interrupt controller
            7 => return self.interrupt_controller.port_op(port, val, write),
            // 8 - scratch pad RAM
            // Else, do nothing
            _ => ()
        }
        return 0;
    }
}

