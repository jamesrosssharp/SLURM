/* vim: set et ts=4 sw=4: */

/*

	slurmemu-ng : Next-Generation SlURM16 Emulator

AudioSDL2.cpp : manage audio buffers 

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

#include <stdexcept>
#include <math.h>
#include <cstdint>

#include "AudioSDL2.h"

#define PI 3.14159265358

void audioCallback(void*  userdata,
                       Uint8* stream,
                       int    len)
{
    static float my_angle = 0;

    for (int i = 0; i < len; i++)
    {
        stream[i] = (std::int8_t)(64.0 * sin(my_angle));
        my_angle += 500.0/48000.0*2*3.14;
        if (my_angle >= 2*3.14) my_angle -= 2*3.14;
    }

}

AudioSDL2::AudioSDL2()
{

    m_audioSpec.freq = 48000;
    m_audioSpec.format = AUDIO_S8;
    m_audioSpec.channels = 2;
    m_audioSpec.samples = 4096;
    m_audioSpec.callback = audioCallback;
    m_audioSpec.userdata = (void*)this;

    if ( SDL_OpenAudio(&m_audioSpec, NULL) < 0 )
    {
        fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
        throw std::runtime_error("Could not open audio");	
    }
	
	/* Start playing */
	SDL_PauseAudio(0);

}

AudioSDL2::~AudioSDL2()
{

    SDL_PauseAudio(1);
    SDL_CloseAudio();

}

