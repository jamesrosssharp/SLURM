/* vim: set et ts=4 sw=4: */

/*
	$PROJECT

$FILE: $DESC

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

#include "GPIO.h"

void GPIO::push_button(GpioEnum button) const
{
    switch (button)
    {
        case BUTTON_UP:
            m_button_bits |= 1;
            break;
        case BUTTON_DOWN:
            m_button_bits |= 2;
            break;
        case BUTTON_LEFT:
            m_button_bits |= 4;
            break;
        case BUTTON_RIGHT:
            m_button_bits |= 8;
            break;
        case BUTTON_A:
            m_button_bits |= 16;
            break;
        case BUTTON_B:
            m_button_bits |= 32;
            break; 
    }
}

void GPIO::release_button(GpioEnum button) const
{
    switch (button)
    {
        case BUTTON_UP:
            m_button_bits &= ~1;
            break;
        case BUTTON_DOWN:
            m_button_bits &= ~2;
            break;
        case BUTTON_LEFT:
            m_button_bits &= ~4;
            break;
        case BUTTON_RIGHT:
            m_button_bits &= ~8;
            break;
        case BUTTON_A:
            m_button_bits &= ~16;
            break;
        case BUTTON_B:
            m_button_bits &= ~32;
            break; 
    }
}

std::uint16_t GPIO::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    switch (port & 0xf)
    {
        case 1: return m_prev_button_bits; 
        default: ;
    }
    return 0;
} 

bool GPIO::step(std::uint16_t* mem)
{
    (void) mem;
    bool gpio_int = false;

    if (m_button_bits != m_prev_button_bits)
        gpio_int = true;

    m_prev_button_bits = m_button_bits;

    return gpio_int;
}



