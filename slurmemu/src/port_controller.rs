use crate::slurm16_soc::Slurm16SoC;

pub struct PortController {


}

///     The PortController simply implements the port address map
impl PortController {

    pub fn new() -> Self 
    {
        PortController { }
    }

    pub fn handle_trace(&self, soc : &mut Slurm16SoC, port : u16, _val : u16, write : bool)
    {
        if port == 0x6006 && write
        {
            soc.trap();
        }
    }

    pub fn port_op(& self, soc : &mut Slurm16SoC, port : u16, val: u16, write : bool)
    {
   
        match (port & 0xf000) >> 12 {
            // 0 - UART
            0 => soc.uart.port_op(port, val, write),
            // 1 - GPIO
            // 2 - PWM
            // 3 - Audio
            // 4 - SPI
            // 5 - GFX
            // 6 - Trace port
            6 => self.handle_trace( soc, port, val, write),
            // 7 - Interrupt controller
            // 8 - scratch pad RAM
            // Else, do nothing
            _ => ()
        }
    }
}

