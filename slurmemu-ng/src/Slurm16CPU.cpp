/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

Slurm16CPU.cpp: CPU Emulator

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

#include "Slurm16CPU.h"

Slurm16CPU::Slurm16CPU()    :
    m_z(0),
    m_c(0),
    m_s(0),
    m_v(0),
    m_z_int(0),
    m_c_int(0),
    m_s_int(0),
    m_v_int(0),
    m_imm_hi(0),
    m_imm_int(0),
    m_pc(0),
    m_int_flag(false),
    m_halt(false)
{
    calc_tables(); 
}

Slurm16CPU::~Slurm16CPU()
{

}

void Slurm16CPU::execute_one_instruction(PortController* pcon, std::uint16_t* mem, std::uint8_t irq)
{

} 

void Slurm16CPU::calc_tables()
{
        //ins_t m_instruction_jump_table[65536];
        //std::uint16_t* m_reg_lo_nibble_table[65536];  /* table to select register based on bits 3:0 */
        //std::uint16_t* m_reg_mid_nibble_table[65536]; /* table to select register based on bits 7:4 */
        //std::uint16_t* m_reg_hi_nibble_table[65536];  /* table to select register based on bits 11:8 */
        
        //std::uint8_t m_zero_table[65536]; /* table to compare to zero */
        //std::uint8_t m_sign_table[65536]; /* table to decode sign bit */
        //std::uint8_t m_carry_table[65536]; /* table to decode carry bit */

}
