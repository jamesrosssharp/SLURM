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

#define WINDOW_WIDTH 	640
#define WINDOW_HEIGHT 	480

float getFPS() {
    static std::chrono::time_point<std::chrono::high_resolution_clock> oldTime = std::chrono::high_resolution_clock::now();
    static int fps; fps++;

    float ret = 0.0;

    auto msecs = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now() - oldTime);

    if (msecs.count() != 0)
        ret = fps * 1000 / msecs.count();

    if (std::chrono::duration_cast<std::chrono::seconds>(std::chrono::high_resolution_clock::now() - oldTime) >= std::chrono::seconds{ 1 }) {

        oldTime = std::chrono::high_resolution_clock::now();

        fps = 0;
    }

    return ret;
}



int main(int argc, char** argv)
{
    std::uint32_t window_flags = SDL_WINDOW_OPENGL;
    SDL_Window *window = SDL_CreateWindow("slurmemu-ng", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, window_flags);
  
    SDL_GLContext Context = SDL_GL_CreateContext(window);

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
                    default:
                        break;
                }
            }
            else if (Event.type == SDL_QUIT)
            {
                running = false;
            }
        }
     
        glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
        glClearColor(1.f, 0.f, 0.f, 0.f);
        glClear(GL_COLOR_BUFFER_BIT);

        SDL_GL_SwapWindow(window);

        float fps = getFPS();

        std::stringstream s;

        s << "slurmemu-ng : " << fps << " FPS";

        SDL_SetWindowTitle(window, s.str().c_str());

        usleep(16000);

    }

}
