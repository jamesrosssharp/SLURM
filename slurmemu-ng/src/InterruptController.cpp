/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

InterruptController.cpp: Handle interrupts

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

#include <InterruptController.h>

InterruptController::InterruptController()
{

}

InterruptController::~InterruptController()
{

}

std::uint16_t InterruptController::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{

    if (write)
    {
        switch (port & 0xf)
        {
            case 0:
                m_interrupt_enabled = wr_val;
                break;
            case 1:
                m_interrupt_pending = m_interrupt_pending & (!wr_val);
                break;
        }
    }
    else
    {
        switch (port & 0xf)
        {
            case 0:
                return m_interrupt_enabled;
            case 2:
                return m_interrupt_pending;
        }
    }

    return 0;
}

int InterruptController::step(bool flash_int, bool vs, bool hs, bool timer, bool gpio, bool audio)
{
    if (hs)
        m_interrupt_pending |= 1 << (HSYNC_INTERRUPT - 1);

    if (vs)
        m_interrupt_pending |= 1 << (VSYNC_INTERRUPT - 1);

    if (audio)
        m_interrupt_pending |= 1 << (AUDIO_INTERRUPT - 1);

    if (flash_int)
        m_interrupt_pending |= 1 << (FLASH_INTERRUPT - 1);

    if (gpio)
        m_interrupt_pending |= 1 << (GPIO_INTERRUPT - 1);

    if (timer)
        m_interrupt_pending |= 1 << (TIMER_INTERRUPT - 1);

    int arr[NUM_INTERRUPTS] = {HSYNC_INTERRUPT, VSYNC_INTERRUPT, AUDIO_INTERRUPT, FLASH_INTERRUPT, GPIO_INTERRUPT, TIMER_INTERRUPT}; 

    for (int i = 0; i < NUM_INTERRUPTS; i++)
        if ((m_interrupt_pending & m_interrupt_enabled) & (1 << (arr[i] - 1)))
            return arr[i];

    return 0;
} 

