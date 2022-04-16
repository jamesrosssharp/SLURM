extern crate slurm_emulator;
use slurm_emulator::slurm16_soc::*;

use std::env;
use std::process;

use std::time::{Duration, Instant};

extern crate piston_window;
use piston_window::*;

extern crate image as im;

use fps_counter::*;

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

    let scale = 1.5;

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

    let mut fps_counter = FPSCounter::default();
    while let Some(e) = window.next() {
        if let Some(_) = e.render_args() {

             let mut cycles = 0;

             while cycles < 25125000 / 60 {

                soc.step(& mut fb);

                cycles += 1;
             }

             for j in 0..VISIBLE_SCREEN_HEIGHT {
                for i in 0..VISIBLE_SCREEN_WIDTH {
                    let x = i as u32;
                    let y = j as u32;
                    let color = fb[j][i];
                    canvas.put_pixel(x, y, im::Rgba([color[0], color[1], color[2], 255]));
                }
            }
            
            texture.update(&mut texture_context, &canvas).unwrap();
            window.draw_2d(&e, |c, g, device| {
                // Update texture before rendering.
                texture_context.encoder.flush(device);

                clear([0.0; 4], g);
                image(&texture, c.transform.scale(scale as f64, scale as f64), g);
            });

            window.set_title(format!("[slurm-emulator] fps:{}", fps_counter.tick()));
        }
    }

}
