/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

main.cpp: Entry point for emulator

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <GL/gl.h>

#include <cstdint>

#include <chrono>
#include <iostream>

#include <unistd.h>

#include <sstream>
#include <iomanip>
#include <string>

#include "Slurm16SoC.h"

#define WINDOW_WIDTH 	640
#define WINDOW_HEIGHT 	480

#include "AudioSDL2.h"
#include "Renderer.h"

#include "ElfDebug.h"

float getFPS() {
    static std::chrono::time_point<std::chrono::high_resolution_clock> oldTime = std::chrono::high_resolution_clock::now();
    static int fps; fps++;

    float ret = 0.0;

    auto msecs = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now() - oldTime);

    if (msecs.count() != 0)
        ret = fps * 1000.0 / msecs.count();

    if (std::chrono::duration_cast<std::chrono::seconds>(std::chrono::high_resolution_clock::now() - oldTime) >= std::chrono::seconds{ 1 }) {

        oldTime = std::chrono::high_resolution_clock::now();

        fps = 0;
    }

    return ret;
}



int main(int argc, char** argv)
{
    if (argc != 4)
    {
        printf("Usage: %s <BOOT_ROM.bin> <FLASH_IMG.bin> <debug.elf>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    Slurm16SoC* soc = new Slurm16SoC(argv[1], argv[2]);

    if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_EVENTS) < 0)
    {
        printf("Could not init SDL!\n");
        exit(EXIT_FAILURE);
    }

    AudioSDL2 aud;

    ElfDebug edbg(argv[3]);

    std::uint32_t window_flags = SDL_WINDOW_OPENGL;
    SDL_Window *window = SDL_CreateWindow("slurmemu-ng", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, window_flags);
  
    SDL_GLContext Context = SDL_GL_CreateContext(window);

    (void)Context;

    Renderer r;

    bool running = true;
    bool full_screen = false;

    while (running)
    {
        SDL_Event Event;
        while (SDL_PollEvent(&Event))
        {
            if (Event.type == SDL_KEYDOWN)
            {
                switch (Event.key.keysym.sym)
                {
                    case SDLK_ESCAPE:
                        running = 0;
                        break;
                    case 'f':
                        full_screen = !full_screen;
                        if (full_screen)
                        {
                            SDL_SetWindowFullscreen(window, window_flags | SDL_WINDOW_FULLSCREEN_DESKTOP);
                        }
                        else
                        {
                            SDL_SetWindowFullscreen(window, window_flags);
                        }
                        break;
                    case 'a':
                        soc->get_pcon().getGPIO().push_button(BUTTON_A);
                        break;
                    case 'b':
                        soc->get_pcon().getGPIO().push_button(BUTTON_B);
                        break;
                    case SDLK_UP:
                        soc->get_pcon().getGPIO().push_button(BUTTON_UP);
                        break;
                    case SDLK_DOWN:
                        soc->get_pcon().getGPIO().push_button(BUTTON_DOWN);
                        break;
                    case SDLK_LEFT:
                        soc->get_pcon().getGPIO().push_button(BUTTON_LEFT);
                        break;
                    case SDLK_RIGHT:
                        soc->get_pcon().getGPIO().push_button(BUTTON_RIGHT);
                        break;
                    default:
                        break;
                }
            }
            else if (Event.type == SDL_KEYUP)
            {
                switch (Event.key.keysym.sym)
                {
                    case 'a':
                        soc->get_pcon().getGPIO().release_button(BUTTON_A);
                        break;
                    case 'b':
                        soc->get_pcon().getGPIO().release_button(BUTTON_B);
                        break;
                    case SDLK_UP:
                        soc->get_pcon().getGPIO().release_button(BUTTON_UP);
                        break;
                    case SDLK_DOWN:
                        soc->get_pcon().getGPIO().release_button(BUTTON_DOWN);
                        break;
                    case SDLK_LEFT:
                        soc->get_pcon().getGPIO().release_button(BUTTON_LEFT);
                        break;
                    case SDLK_RIGHT:
                        soc->get_pcon().getGPIO().release_button(BUTTON_RIGHT);
                        break;
                    default:
                        break;
                }
            }
            else if (Event.type == SDL_QUIT)
            {
                running = false;
            }
        }
     
        float fps = getFPS();

        std::stringstream s;

        s << "slurmemu-ng : " << fps << " FPS, PC = " << std::hex << std::setw(4) << std::setfill('0') << soc->get_cpu().get_pc();

        SDL_SetWindowTitle(window, s.str().c_str());

        for (int i = 0; i < 418750; i++)
        {
            bool emitAudio;
            std::int16_t left = 20, right = 37;
            bool hs = false, vs = false;

            soc->executeOneCycle(emitAudio, left, right, edbg, hs, vs);
       
            if (emitAudio)
                aud.feedRingbuffer(left, right);
        
            if (vs)
            {
                int w, h;

                SDL_GetWindowSize(window, &w, &h);

                /*glViewport(0, 0, w, h);
                glClearColor(1.f, 0.f, 0.f, 0.f);
                glClear(GL_COLOR_BUFFER_BIT);

                glBindTexture(GL_TEXTURE_2D, tex);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);


                glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, 800, 525, 0,  GL_RED, GL_UNSIGNED_BYTE, soc->getGfxCore()->getBG0Texture());
                glBindTexture(GL_TEXTURE_2D, 0);

                glBindTexture(GL_TEXTURE_2D, tex);
                glEnable(GL_TEXTURE_2D);
                glBegin(GL_QUADS);
                glTexCoord2i(0, 1); glVertex2f(-1, -1);
                glTexCoord2i(1, 1); glVertex2f(1, -1);
                glTexCoord2i(1, 0); glVertex2f(1, 1);
                glTexCoord2i(0, 0); glVertex2f(-1, 1);
                glEnd();
                glDisable(GL_TEXTURE_2D);
                glBindTexture(GL_TEXTURE_2D, 0);

                glFlush();
                */

                r.renderScene(soc, w, h);
    
                SDL_GL_SwapWindow(window);

            }
        
        }

    }

    printf("Bye!\n");
    exit(EXIT_SUCCESS);
}
