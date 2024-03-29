use super::uart::Uart;
use super::gfx::Gfx;
use super::interrupt_controller::InterruptController;
use super::gpio::GpioCore;
use super::flash::FlashDMA;
use super::audio::AudioCore;
use super::scratch::Scratch;
use super::timer::Timer;

use std::io::{self, Write};

pub struct PortController {
	pub uart: Uart,
	pub exit: bool,
	pub gfx: Gfx,
	pub interrupt_controller: InterruptController,
	pub gpio: GpioCore,
	pub flash: FlashDMA,
	pub audio: AudioCore,
	pub scratch: Scratch,
	pub timer: Timer,
}

///		The PortController simply implements the port address map
impl PortController {

	pub fn new() -> Self 
	{
		PortController { 
			uart: Uart::new(),
			gfx:  Gfx::new(),
			exit: false,
			interrupt_controller: InterruptController::new(),
			gpio: GpioCore::new(),
			flash: FlashDMA::new(),
			audio: AudioCore::new(),
			scratch: Scratch::new(),
			timer: Timer::new()
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
			1 => return self.gpio.port_op(port, val, write),
			// 2 - PWM
			// 3 - Audio
			3 => return self.audio.port_op(port, val, write),
			// 4 - SPI
			4 => return self.flash.port_op(port, val, write),
			// 5 - GFX
			5 => return self.gfx.port_op(port, val, write),
			// 6 - Trace port
			6 => self.handle_trace(port, val, write),
			// 7 - Interrupt controller
			7 => return self.interrupt_controller.port_op(port, val, write),
			// 8 - scratch pad RAM
			8 => return self.scratch.port_op(port, val, write),
			// 9 - timer
			9 => return self.timer.port_op(port, val, write),
			// Else, do nothing
			_ => ()
		}
		return 0;
	}
}

