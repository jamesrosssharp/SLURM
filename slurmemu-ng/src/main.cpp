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

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <iostream>
#include <memory>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

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

/*
 * The emulator runs on its own thread, paced by the clock at the speed of the
 * hardware: 25 MHz, 800 x 525 cycles a frame. At each vsync it copies what
 * the renderer needs into a frame snapshot. The main thread handles SDL
 * events and draws the newest snapshot, so drawing and the buffer swap never
 * hold up the emulation.
 */

static constexpr double kClockHz = 25000000.0;
static constexpr double kFramePeriod = TOTAL_X * TOTAL_Y / kClockHz;   /* 16.8 ms: 59.52 Hz */

/* Triple buffered frames: the emulator fills 'back', the renderer draws
 * 'front', and 'ready' holds the newest finished frame between them */
class FrameExchange {

    public:

        FrameExchange() :
            m_back(new FrameSnapshot), m_ready(new FrameSnapshot), m_front(new FrameSnapshot) {}

        FrameSnapshot& back() { return *m_back; }

        /* emulator: the back frame is finished */
        void publish()
        {
            {
                std::lock_guard<std::mutex> lock(m_mutex);
                std::swap(m_back, m_ready);
                m_new = true;
            }
            m_cv.notify_one();
        }

        /* renderer: the newest frame, if there is one it hasn't drawn;
         * waits up to 'timeout' for one */
        const FrameSnapshot* take(std::chrono::milliseconds timeout)
        {
            std::unique_lock<std::mutex> lock(m_mutex);
            if (!m_cv.wait_for(lock, timeout, [this] { return m_new; }))
                return nullptr;
            std::swap(m_ready, m_front);
            m_new = false;
            return m_front.get();
        }

    private:

        std::unique_ptr<FrameSnapshot> m_back, m_ready, m_front;
        std::mutex m_mutex;
        std::condition_variable m_cv;
        bool m_new = false;
};

/* Things the main thread hands to the emulator thread */
struct EmulatorInput {
    std::mutex mutex;
    std::vector<std::pair<GpioEnum, bool>> buttons;     /* pushed (true) or released */
    std::uint32_t collisions[256];
    bool newCollisions = false;
};

static void emulate(Slurm16SoC* soc, ElfDebug* edbg, AudioSDL2* aud, FrameExchange* frames,
                    EmulatorInput* input, std::atomic<bool>* running, std::atomic<int>* frameCount,
                    std::atomic<std::uint16_t>* pc)
{
    using clock = std::chrono::steady_clock;
    const auto period = std::chrono::duration_cast<clock::duration>(std::chrono::duration<double>(kFramePeriod));
    auto next = clock::now();

    std::vector<std::pair<GpioEnum, bool>> buttons;
    std::uint32_t collisions[256];

    while (*running)
    {
        bool newCollisions = false;
        {
            std::lock_guard<std::mutex> lock(input->mutex);
            buttons.swap(input->buttons);
            if (input->newCollisions)
            {
                memcpy(collisions, input->collisions, sizeof(collisions));
                input->newCollisions = false;
                newCollisions = true;
            }
        }
        for (auto& b : buttons)
        {
            if (b.second)
                soc->get_pcon().getGPIO().push_button(b.first);
            else
                soc->get_pcon().getGPIO().release_button(b.first);
        }
        buttons.clear();
        if (newCollisions)
            soc->setCollisionMap(collisions);

        /* One frame, up to and including the vsync */
        bool vs = false;
        do
        {
            bool emitAudio, hs = false;
            std::int16_t left = 20, right = 37;

            vs = false;
            soc->executeOneCycle(emitAudio, left, right, *edbg, hs, vs);

            if (emitAudio)
                aud->feedRingbuffer(left, right);
        }
        while (!vs);

        soc->snapshot(frames->back());
        frames->publish();
        (*frameCount)++;
        *pc = soc->get_cpu().get_pc();

        /* Wait for the frame's time to be up. If we have fallen well behind
         * (the machine was busy), start again from now rather than rushing
         * to catch up */
        next += period;
        auto now = clock::now();
        if (now > next + 6 * period)
            next = now;
        else
            std::this_thread::sleep_until(next);
    }
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

    bool full_screen = false;

    FrameExchange frames;
    EmulatorInput input;
    std::atomic<bool> running = true;
    std::atomic<int> emuFrames = 0;
    std::atomic<std::uint16_t> pc = 0;

    std::thread emulator(emulate, soc, &edbg, &aud, &frames, &input, &running, &emuFrames, &pc);

    auto button = [&input](GpioEnum b, bool pushed) {
        std::lock_guard<std::mutex> lock(input.mutex);
        input.buttons.emplace_back(b, pushed);
    };

    int drawnFrames = 0;
    float renderMs = 0;
    auto statsTime = std::chrono::steady_clock::now();

    while (running)
    {
        SDL_Event Event;
        while (SDL_PollEvent(&Event))
        {
            if (Event.type == SDL_KEYDOWN || Event.type == SDL_KEYUP)
            {
                bool down = Event.type == SDL_KEYDOWN;

                switch (Event.key.keysym.sym)
                {
                    case SDLK_ESCAPE:
                        if (down)
                            running = false;
                        break;
                    case 'f':
                        if (!down || Event.key.repeat)
                            break;
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
                        button(BUTTON_A, down);
                        break;
                    case 'b':
                        button(BUTTON_B, down);
                        break;
                    case SDLK_UP:
                        button(BUTTON_UP, down);
                        break;
                    case SDLK_DOWN:
                        button(BUTTON_DOWN, down);
                        break;
                    case SDLK_LEFT:
                        button(BUTTON_LEFT, down);
                        break;
                    case SDLK_RIGHT:
                        button(BUTTON_RIGHT, down);
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

        /* Draw the newest frame; if none has come, look at the events again */
        const FrameSnapshot* frame = frames.take(std::chrono::milliseconds(20));

        if (frame)
        {
            int w, h;
            std::uint32_t collisions[256];
            bool gotCollisions;

            SDL_GetWindowSize(window, &w, &h);

            renderMs = r.renderScene(*frame, w, h, collisions, gotCollisions);

            if (gotCollisions)
            {
                std::lock_guard<std::mutex> lock(input.mutex);
                memcpy(input.collisions, collisions, sizeof(collisions));
                input.newCollisions = true;
            }

            SDL_GL_SwapWindow(window);
            drawnFrames++;
        }

        /* Once a second: emulated and drawn frames per second in the title */
        auto now = std::chrono::steady_clock::now();
        double secs = std::chrono::duration<double>(now - statsTime).count();

        if (secs >= 1.0)
        {
            std::stringstream s;

            s << "slurmemu-ng : " << std::fixed << std::setprecision(1)
              << emuFrames.exchange(0) / secs << " FPS (" << drawnFrames / secs << " drawn), PC = "
              << std::hex << std::setw(4) << std::setfill('0') << pc.load()
              << std::dec << " R: " << renderMs << " ms";

            SDL_SetWindowTitle(window, s.str().c_str());

            drawnFrames = 0;
            statsTime = now;
        }
    }

    emulator.join();

    printf("Bye!\n");
    exit(EXIT_SUCCESS);
}
