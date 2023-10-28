/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

    PortController.cpp: Emulate the SlURM16 Port Controller

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

#include "PortController.h"
#include <cstdio>

PortController::PortController(const char* flash_file)  :
    m_flash(flash_file)
{


}

PortController::~PortController()
{


}

#define PORT_UART       0x0000
#define PORT_GPIO       0x1000 
#define PORT_AUDIO      0x3000
#define PORT_SPI_FLASH  0x4000
#define PORT_GFX        0x5000
#define PORT_INTC       0x7000 
#define PORT_SCRATCH    0x8000 
#define PORT_TIMER      0x9000 


void    PortController::port_wr(uint16_t port, uint16_t value)
{
    switch (port & 0xf000)
    {
        case PORT_UART:  /* UART */
            uart_wr(port, value);
            break;
        case PORT_GPIO: /* GPIO */
            m_gpio.port_op(port, true, value);
            break;
        case PORT_AUDIO: /* AUDIO */
            m_audio.port_op(port, true, value);
            break;
        case PORT_SPI_FLASH: /* FLASH DMA */
            m_flash.port_op(port, true, value);
            break;
        case PORT_GFX: /* GFX CORE */
            m_gfx.port_op(port, true, value);
            break;
        case PORT_INTC: /* INTERRUPT CONTROLLER */
            m_intcon.port_op(port, true, value);
            break;  
        case PORT_SCRATCH: /* SCRATCHPAD RAM */
            m_scratch.port_op(port, true, value);
            break;
        case PORT_TIMER: /* TIMER */
            m_tim.port_op(port, true, value);
            break;
        default:
            break;
    }

}

uint16_t PortController::port_rd(uint16_t port)
{
    switch (port & 0xf000)
    {
        case PORT_UART:  /* UART */
            return uart_rd(port);
        case PORT_GPIO: /* GPIO */
            return m_gpio.port_op(port, false, 0);
        case PORT_AUDIO: /* audio */
            return m_audio.port_op(port, false, 0);
        case PORT_SPI_FLASH: /* FLASH DMA */
            return m_flash.port_op(port, false, 0);
        case PORT_GFX: /* GFX CORE */
            return m_gfx.port_op(port, false, 0);
        case PORT_INTC: /* INTERRUPT CONTROLLER */
            return m_intcon.port_op(port, false, 0);
         case PORT_SCRATCH: /* SCRATCHPAD RAM */
            return m_scratch.port_op(port, false, 0);
        case PORT_TIMER: /* TIMER */
            return m_tim.port_op(port, false, 0);
        default:
            break;
    }
    return 0;
}

void    PortController::uart_wr(uint16_t port, uint16_t value)
{
    printf("%c", (char)value);
    fflush(0);
}

uint16_t    PortController::uart_rd(uint16_t port)
{
    return 1;
}

int PortController::step(std::uint16_t* mem, bool& emitAudio, std::int16_t& left, std::int16_t& right, bool& hs, bool& vs)
{
    bool flash_int = m_flash.step(mem);
    bool timer = m_tim.step(mem);
    bool gpio = m_gpio.step(mem);
    bool audio = m_audio.step(mem, emitAudio, left, right); 
  
    m_gfx.step(mem, hs, vs);

    return m_intcon.step(flash_int, vs, hs, timer, gpio, audio);     
}

