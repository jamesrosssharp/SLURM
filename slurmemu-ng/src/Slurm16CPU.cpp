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
#include "PortController.h"

#include <vector>
#include <iostream>
#include <iomanip>

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
    for (int i = 0; i < kNumRegs; i++)
    {
        m_regs[i] = 0;
    } 

    calc_tables(); 
}

Slurm16CPU::~Slurm16CPU()
{

}

void Slurm16CPU::execute_one_instruction(PortController* pcon, std::uint16_t* mem, std::uint8_t irq)
{

    std::uint16_t instruction = mem[m_pc >> 1];

    ins_t ifunc = m_instruction_jump_table[instruction];

    if (ifunc != nullptr)
    {
        ifunc(this, instruction);
    }
    else
    {
        std::cout << "Undefined instruction at 0x" << std::hex << std::setw(4) << m_pc << std::endl;
    }

    // Clear zero reg, just in case
    m_regs[0] = 0;
} 

void Slurm16CPU::calc_tables()
{
        
        /* compute instruction jump table */

        struct ins_mask {
            std::uint16_t mask;
            std::uint16_t val;
            ins_t    ptr;
        };

        std::vector<struct ins_mask> insts = {
            {0xff00, 0x2000, alu_mov_reg_reg},
            {0xff00, 0x3000, alu_mov_reg_imm},
            {0xff00, 0x2100, alu_add_reg_reg},
            {0xff00, 0x3100, alu_add_reg_imm},
        };

        for (std::uint32_t j = 0; j < kTwoPower16; j++)
        {
            m_instruction_jump_table[j] = nullptr;
        }

        for (const auto &i : insts)
        {
            for (std::uint32_t j = 0; j < kTwoPower16; j++)
            {
                std::uint16_t a = (j & ~i.mask) | (i.val & i.mask);

                //std::cout << "Jump table " << std::hex << a << " = " << (void*)i.ptr << std::endl;

                m_instruction_jump_table[a] = i.ptr;
            }
        } 

        /* compute register lookups */

        struct reg_lut {
            std::uint16_t** tab;
            std::uint16_t  mask;
            int shift;
        };        

        std::vector<struct reg_lut> r_luts = {
            {m_reg_lo_nibble_table, 0x000f, 0},
            {m_reg_mid_nibble_table, 0x00f0, 4},
            {m_reg_hi_nibble_table, 0x0f00, 8}
        };

        for (const auto &l : r_luts)
        {
            for (std::uint32_t j = 0; j < kTwoPower16; j++)
            {
                std::uint16_t r = (j & l.mask) >> l.shift;
                l.tab[j] = &m_regs[r];               
            } 
        }

        /* compute zero, sign, carry table */
        
        for (std::uint32_t i = 0; i < kTwoPower16; i++)
        {
            m_zero_table[i] = (i == 0) ? 1 : 0;
            m_sign_table[i] = (i & 0x8000) ? 1 : 0;
            m_carry_table[i] = (i != 0) ? 1 : 0;
        }

}

#define R_DEST(cpu, ins) \
    cpu->m_reg_mid_nibble_table[ins]

#define R_SRC(cpu, ins) \
    cpu->m_reg_lo_nibble_table[ins]

#define ZERO_FLAG(val) \
    cpu->m_zero_table[(val)]

#define SIGN_FLAG(val) \
    cpu->m_sign_table[(val)]

#define CARRY_FLAG(val) \
    cpu->m_carry_table[(val)]

void Slurm16CPU::alu_mov_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    *r_dest = *r_src;
    /* flags unaffected */
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
}

void Slurm16CPU::alu_mov_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    *r_dest = imm;
    /* flags unaffected */
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
}

void Slurm16CPU::alu_add_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t sum = *r_dest;
    sum += *r_src;
    /* flags unaffected */
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum >> 16);
    cpu->m_v = !(SIGN_FLAG(*r_dest ^ *r_src) && SIGN_FLAG((*r_src ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_add_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint32_t sum = *r_dest;
    sum += imm;
    /* flags unaffected */
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum >> 16);
    cpu->m_v = !(SIGN_FLAG(*r_dest ^ imm) && SIGN_FLAG((imm ^ sum) & 0xffff)); 
    *r_dest = sum;
}

