extern crate slurm_emulator;
use slurm_emulator::slurm16_soc::*;

use std::env;
use std::process;

extern crate piston_window;
use piston_window::*;

extern crate image as im;

use fps_counter::*;

extern crate sdl2;

use sdl2::audio::AudioSpecDesired;


#[allow(dead_code)]
fn main() -> Result<(), String> {

    let mut soc = Slurm16SoC::new();

    // Load a ROM file

    let args: Vec<String> = env::args().collect();

    if args.len() != 3
    {
        println!("Usage: {} <boot rom> <flash file>\n", args[0]);
        process::exit(1);
    }

    let bytes = std::fs::read(&args[1]).unwrap();
    
    let mut rom_data : Vec<u16> = Vec::new();

    for byte_pair in bytes.chunks_exact(2) {
        let short : u16 = u16::from_le_bytes([byte_pair[0], byte_pair[1]]);
        //println!("{:x}", short);
        rom_data.push(short);
    }
    soc.set_memory(&rom_data, 0, std::cmp::min(rom_data.len(), 256));  

    let bytes = std::fs::read(&args[2]).unwrap();
    
    let mut flash_data : Vec<u16> = Vec::new();

    for byte_pair in bytes.chunks_exact(2) {
        let short : u16 = u16::from_le_bytes([byte_pair[0], byte_pair[1]]);
        flash_data.push(short);
    }
    soc.set_flash(&flash_data);  

    let scale = 1.0;

    let width = ((VISIBLE_SCREEN_WIDTH as f32) * scale) as u32;
    let height = ((VISIBLE_SCREEN_HEIGHT as f32) * scale) as u32;

    let mut fb = [[[0; NUM_OF_COLOR]; VISIBLE_SCREEN_WIDTH]; VISIBLE_SCREEN_HEIGHT];

    let opengl = OpenGL::V3_2;
    let mut window: PistonWindow = WindowSettings::new("slurm16 emulator", (width, height))
        .exit_on_esc(true)
        .graphics_api(opengl)
        .build()
        .unwrap();

    let mut canvas = im::ImageBuffer::new(width, height);
    let mut texture_context = TextureContext {
        factory: window.factory.clone(),
        encoder: window.factory.create_command_buffer().into(),
    };
    let mut texture: G2dTexture =
        Texture::from_image(&mut texture_context, &canvas, &TextureSettings::new()).unwrap();

    /* set up audio device */

    let sdl_context = sdl2::init()?;
    let audio_subsystem = sdl_context.audio()?;

    let desired_spec = AudioSpecDesired {
        freq: Some(48_000),
        channels: Some(2),
        // mono  -
        samples: None, // default sample size
    };

    let audio_device = audio_subsystem.open_queue::<i16, _>(None, &desired_spec)?;

    const AUDIO_BUF_SIZE : usize = 8192;

    let mut audio_buf : Vec<i16> = vec![];

    let mut fps_counter = FPSCounter::default();
    while let Some(e) = window.next() {
        if let Some(_) = e.render_args() {

             let mut cycles = 0;
             let mut fired = false;
                
             while cycles < 25125000 / 60 {

                let mut audio : [i16; 2] = [0 ; 2];

                let (vs_int, emit_audio) = soc.step(& mut fb, &mut audio);  

                if vs_int && !fired
                {
                    fired = true;
                    for j in 0..VISIBLE_SCREEN_HEIGHT {
                                for i in 0..VISIBLE_SCREEN_WIDTH {
                                    let x = i as u32;
                                    let y = j as u32;
                                    let color = fb[j][i];
                                    canvas.put_pixel(x, y, im::Rgba([color[0], color[1], color[2], 255]));
                                }
                            }
                           
                }

                if emit_audio
                {
                    audio_buf.push(audio[0]);
                    audio_buf.push(audio[1]);
                    audio_buf.push(audio[0]);
                    audio_buf.push(audio[1]);
                    
		    if audio_buf.len() == AUDIO_BUF_SIZE {
                    
                        audio_device.queue_audio(&audio_buf)?;
                        audio_device.resume();
                        audio_buf.clear();
                    }
                }

                cycles += 1;
             }

           
            texture.update(&mut texture_context, &canvas).unwrap();
            window.draw_2d(&e, |c, g, device| {
                // Update texture before rendering.
                texture_context.encoder.flush(device);

                clear([0.0; 4], g);
                image(&texture, c.transform.scale(scale as f64, scale as f64), g);
            });

            window.set_title(format!("[slurm-emulator] fps:{} pc:{:#01x}", fps_counter.tick(), soc.get_pc()));
        }
         if let Some(Button::Keyboard(key)) = e.release_args() {
            match key {
                Key::A => soc.release_button(SlurmButton::A),
                Key::S => soc.release_button(SlurmButton::B),
                Key::Up => soc.release_button(SlurmButton::UP),
                Key::Down => soc.release_button(SlurmButton::DOWN),
                Key::Left => soc.release_button(SlurmButton::LEFT),
                Key::Right => soc.release_button(SlurmButton::RIGHT),
                _ => {}
            }
        }
        if let Some(Button::Keyboard(key)) = e.press_args() {
            match key {
                Key::A => soc.push_button(SlurmButton::A),
                Key::S => soc.push_button(SlurmButton::B),
                Key::Up => soc.push_button(SlurmButton::UP),
                Key::Down => soc.push_button(SlurmButton::DOWN),
                Key::Left => soc.push_button(SlurmButton::LEFT),
                Key::Right => soc.push_button(SlurmButton::RIGHT),
                _ => {}
            }
        }
    }

    Ok(())
}
