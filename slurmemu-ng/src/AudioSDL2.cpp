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
#include <cstdint>

#include "AudioSDL2.h"

#define PI 3.14159265358

std::binary_semaphore m_sem{0};

void audioCallback(void*  userdata,
                       Uint8* stream,
                       int    len)
{
    AudioSDL2* a = (AudioSDL2*)userdata;

    a->fillStream((std::uint8_t*)stream, len);

}

void AudioSDL2::fillStream(std::uint8_t* stream, int len)
{

    int consumed = 0;

    while ((len >= 4) && (m_rb_tail != m_rb_head))
    {
       

        *stream++ = m_left_rb[m_rb_tail] >> 8;
        *stream++ = m_right_rb[m_rb_tail] >> 8;
        *stream++ = m_left_rb[m_rb_tail] >> 8;
        *stream++ = m_right_rb[m_rb_tail] >> 8;
        
        m_rb_tail++;
        m_rb_tail %= kRBSize;

        len -= 4;

        consumed++;
    }

 //   printf("Consumed: %d left: %d\n", consumed, len);

    static float my_angle = 0;

    for (int i = 0; i < len; i++)
    {
        *stream++ = 0; //(std::int8_t)(64.0 * sin(my_angle));
        my_angle += 500.0/48000.0*2*3.14;
        if (my_angle >= 2*3.14) my_angle -= 2*3.14;
    }


    m_sem.release();

}

AudioSDL2::AudioSDL2()  :
    m_rb_head(0),
    m_rb_tail(0)
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

void AudioSDL2::feedRingbuffer(std::int16_t left, std::int16_t right)
{
    int space;

   // printf("Feed audio!\n");

    while ((space = ((m_rb_tail - m_rb_head - 1) & (kRBSize - 1))) == 0)
    {
        m_sem.acquire();
    }

    m_left_rb[m_rb_head] = left;
    m_right_rb[m_rb_head] = right;

    m_rb_head++;

    m_rb_head %= kRBSize;
}
