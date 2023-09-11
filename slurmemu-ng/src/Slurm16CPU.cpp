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

    ins_t ifunc = m_instruction_jump_table[instruction >> 8];

    if (ifunc != nullptr)
    {
        ifunc(this, instruction, mem, pcon);
    }
    else
    {
        std::cout << "Undefined instruction at 0x" << std::hex << std::setw(4) << std::setfill('0') << m_pc << std::endl;
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
            {0xf000, 0x1000, imm_ins},
            {0xff00, 0x2000, alu_mov_reg_reg},
            {0xff00, 0x3000, alu_mov_reg_imm},
            {0xff00, 0x2100, alu_add_reg_reg},
            {0xff00, 0x3100, alu_add_reg_imm},
            {0xff00, 0x2200, alu_adc_reg_reg},
            {0xff00, 0x3200, alu_adc_reg_imm},
            {0xff00, 0x2300, alu_sub_reg_reg},
            {0xff00, 0x3300, alu_sub_reg_imm},
            {0xff00, 0x2400, alu_sbb_reg_reg},
            {0xff00, 0x3400, alu_sbb_reg_imm},
            {0xff00, 0x2500, alu_and_reg_reg},
            {0xff00, 0x3500, alu_and_reg_imm},
            {0xff00, 0x2600, alu_or_reg_reg},
            {0xff00, 0x3600, alu_or_reg_imm},
            {0xff00, 0x2700, alu_xor_reg_reg},
            {0xff00, 0x3700, alu_xor_reg_imm}, 
            {0xff00, 0x2800, alu_mul_reg_reg},
            {0xff00, 0x3800, alu_mul_reg_imm}, 
            {0xff00, 0x2900, alu_mulu_reg_reg},
            {0xff00, 0x3900, alu_mulu_reg_imm}, 
            {0xff00, 0x2a00, alu_rrn_reg_reg},
            {0xff00, 0x3a00, alu_rrn_reg_imm}, 
            {0xff00, 0x2b00, alu_rln_reg_reg},
            {0xff00, 0x3b00, alu_rln_reg_imm}, 
            {0xff00, 0x2c00, alu_cmp_reg_reg}, 
            {0xff00, 0x3c00, alu_cmp_reg_imm},
            {0xff00, 0x2d00, alu_test_reg_reg}, 
            {0xff00, 0x3d00, alu_test_reg_imm},
            {0xff00, 0x2e00, alu_umulu_reg_reg}, 
            {0xff00, 0x3e00, alu_umulu_reg_imm},
            {0xff00, 0x2f00, alu_bswap_reg_reg}, 
            {0xff00, 0x3f00, alu_bswap_reg_imm},
            {0xff00, 0x4000, bz},
            {0xff00, 0x4100, bnz},
            {0xff00, 0x4200, bs},
            {0xff00, 0x4300, bns},
            {0xff00, 0x4400, bc},
            {0xff00, 0x4500, bnc},
            {0xff00, 0x4600, bv},
            {0xff00, 0x4700, bnv},
            {0xff00, 0x4800, blt},
            {0xff00, 0x4900, ble},
            {0xff00, 0x4a00, bgt},
            {0xff00, 0x4b00, bge},
            {0xff00, 0x4c00, bleu},
            {0xff00, 0x4d00, bgtu},
            {0xff00, 0x4e00, ba},
            {0xff00, 0x4f00, bl},
            {0xff00, 0x5000, movz},
            {0xff00, 0x5100, movnz},
            {0xff00, 0x5200, movs},
            {0xff00, 0x5300, movns},
            {0xff00, 0x5400, movc},
            {0xff00, 0x5500, movnc},
            {0xff00, 0x5600, movv},
            {0xff00, 0x5700, movnv},
            {0xff00, 0x5800, movlt},
            {0xff00, 0x5900, movle},
            {0xff00, 0x5a00, movgt},
            {0xff00, 0x5b00, movge},
            {0xff00, 0x5c00, movleu},
            {0xff00, 0x5d00, movgtu},
            {0xff00, 0x5e00, mova},
            {0xff00, 0x5f00, mova},
         };

        for (std::uint32_t j = 0; j < kTwoPower8; j++)
        {
            m_instruction_jump_table[j] = nullptr;
        }

        for (const auto &i : insts)
        {
            for (std::uint32_t j = 0; j < kTwoPower8; j++)
            {
                std::uint8_t a = (((j << 8) & ~i.mask) | (i.val & i.mask)) >> 8;

                m_instruction_jump_table[a] = i.ptr;
            }
        } 
}

#define R_DEST(cpu, ins) \
    &cpu->m_regs[ (ins >> 4) & 0xf ]

#define R_SRC(cpu, ins) \
    &cpu->m_regs[ ins & 0xf ]

#define ZERO_FLAG(val) \
    ((val) == 0)

#define SIGN_FLAG(val) \
    !!((val) & 0x8000)

#define CARRY_FLAG(val) \
    !!((val) & 0x10000)

void Slurm16CPU::alu_mov_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    *r_dest = *r_src;
    /* flags unaffected */
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
}

void Slurm16CPU::alu_mov_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    *r_dest = imm;
    /* flags unaffected */
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
}

void Slurm16CPU::alu_add_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t sum = *r_dest;
    sum += *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = !(SIGN_FLAG(*r_dest ^ *r_src) && SIGN_FLAG((*r_src ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_add_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint32_t sum = *r_dest;
    sum += imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = !(SIGN_FLAG(*r_dest ^ imm) && SIGN_FLAG((imm ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_adc_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t sum = *r_dest;
    sum += *r_src + cpu->m_c;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (!SIGN_FLAG(*r_dest ^ *r_src) && SIGN_FLAG((*r_src ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_adc_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint32_t sum = *r_dest;
    sum += imm + cpu->m_c;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (!SIGN_FLAG(*r_dest ^ imm) && SIGN_FLAG((imm ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::imm_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    cpu->m_imm_hi = instruction & 0x0fff;
    cpu->m_pc += 2;
}

void Slurm16CPU::alu_sub_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t sum = *r_dest;
    sum -= *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (SIGN_FLAG(*r_dest ^ *r_src) && !SIGN_FLAG((*r_src ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_sub_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint32_t sum = *r_dest;
    sum -= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (SIGN_FLAG(*r_dest ^ imm) && !SIGN_FLAG((imm ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_sbb_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t sum = *r_dest;
    sum -= *r_src + cpu->m_c;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (SIGN_FLAG(*r_dest ^ *r_src) && !SIGN_FLAG((*r_src ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_sbb_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint32_t sum = *r_dest;
    sum -= imm + cpu->m_c;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (SIGN_FLAG(*r_dest ^ imm) && !SIGN_FLAG((imm ^ sum) & 0xffff)); 
    *r_dest = sum;
}

void Slurm16CPU::alu_and_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint16_t res = *r_dest;
    res &= *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_and_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint16_t res = *r_dest;
    res &= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_or_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint16_t res = *r_dest;
    res |= *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_or_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint16_t res = *r_dest;
    res |= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_xor_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint16_t res = *r_dest;
    res ^= *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_xor_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint16_t res = *r_dest;
    res ^= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_mul_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    int32_t res = (int32_t)*r_dest;
    int32_t src = (int32_t)*r_src;
    res *= src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_mul_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    int32_t imm = (int32_t)((cpu->m_imm_hi << 4) | (instruction & 0xf));
    int32_t res = (int32_t)*r_dest;
    res *= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res;
}

void Slurm16CPU::alu_mulu_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    int32_t res = (int32_t)(int16_t)*r_dest;
    int32_t src = (int32_t)(int16_t)*r_src;
    res *= src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res >> 16;
}

void Slurm16CPU::alu_mulu_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    int32_t imm = (int32_t)(int16_t)((cpu->m_imm_hi << 4) | (instruction & 0xf));
    int32_t res = (int32_t)(int16_t)*r_dest;
    res *= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res >> 16;
}

void Slurm16CPU::alu_rrn_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint16_t res = (*r_src >> 4) | (*r_src << 12);
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    *r_dest = res;
}

void Slurm16CPU::alu_rrn_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = ((cpu->m_imm_hi << 4) | (instruction & 0xf));
    uint16_t res = (imm >> 4) | (imm << 12);
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    *r_dest = res >> 16;
}

void Slurm16CPU::alu_rln_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint16_t res = (*r_src << 4) | (*r_src >> 12);
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    *r_dest = res;
}

void Slurm16CPU::alu_rln_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = ((cpu->m_imm_hi << 4) | (instruction & 0xf));
    uint16_t res = (imm << 4) | (imm >> 12);
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    *r_dest = res >> 16;
}

void Slurm16CPU::alu_cmp_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t sum = *r_dest;
    sum -= *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (SIGN_FLAG(*r_dest ^ *r_src) && !SIGN_FLAG((*r_src ^ sum) & 0xffff)); 
}

void Slurm16CPU::alu_cmp_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint32_t sum = *r_dest;
    sum -= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(sum & 0xffff);
    cpu->m_s = SIGN_FLAG(sum & 0xffff);
    cpu->m_c = CARRY_FLAG(sum);
    cpu->m_v = (SIGN_FLAG(*r_dest ^ imm) && !SIGN_FLAG((imm ^ sum) & 0xffff)); 
}

void Slurm16CPU::alu_test_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint16_t res = *r_dest;
    res &= *r_src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
}

void Slurm16CPU::alu_test_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = (cpu->m_imm_hi << 4) | (instruction & 0xf);
    uint16_t res = *r_dest;
    res &= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
}

void Slurm16CPU::alu_umulu_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    uint32_t res = (uint32_t)(uint16_t)*r_dest;
    uint32_t src = (uint32_t)(uint16_t)*r_src;
    res *= src;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res >> 16;
}

void Slurm16CPU::alu_umulu_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint32_t imm = (uint32_t)(uint16_t)((cpu->m_imm_hi << 4) | (instruction & 0xf));
    uint32_t res = (uint32_t)(uint16_t)*r_dest;
    res *= imm;
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    cpu->m_z = ZERO_FLAG(res & 0xffff);
    cpu->m_s = SIGN_FLAG(res & 0xffff);
    cpu->m_c = 0;
    *r_dest = res >> 16;
}

void Slurm16CPU::alu_bswap_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t* r_src  = R_SRC(cpu, instruction);
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    *r_dest = (*r_src >> 8) | (*r_src << 8);
}

void Slurm16CPU::alu_bswap_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    uint16_t* r_dest = R_DEST(cpu, instruction);
    uint16_t imm = ((cpu->m_imm_hi << 4) | (instruction & 0xf));
    cpu->m_imm_hi = 0;
    cpu->m_pc += 2;
    *r_dest = (imm >> 8) | (imm << 8);
}

#define BRANCH(cond) \
    uint16_t* r_dest = R_DEST(cpu, instruction);    \
    uint32_t imm = (uint32_t)(uint16_t)((cpu->m_imm_hi << 4) | (instruction & 0xf));    \
    if (cond) cpu->m_pc = *r_dest + imm;    \
    else cpu->m_pc += 2;    \
    cpu->m_imm_hi = 0


void Slurm16CPU::bz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_z);
}

void Slurm16CPU::bnz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(!cpu->m_z);
}

void Slurm16CPU::bs(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_s);
}

void Slurm16CPU::bns(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(!cpu->m_s);
}

void Slurm16CPU::bc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_c);
}

void Slurm16CPU::bnc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(!cpu->m_c);
}

void Slurm16CPU::bv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_v);
}

void Slurm16CPU::bnv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(!cpu->m_v);
}

void Slurm16CPU::blt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_v != cpu->m_s);
}

void Slurm16CPU::ble(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_z || (cpu->m_v != cpu->m_s));
}

void Slurm16CPU::bgt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(!cpu->m_z && (cpu->m_v == cpu->m_s));
}

void Slurm16CPU::bge(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH((cpu->m_v == cpu->m_s));
}

void Slurm16CPU::bleu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(cpu->m_c || cpu->m_z);
}

void Slurm16CPU::bgtu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(!cpu->m_c && !cpu->m_z);
}

void Slurm16CPU::ba(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    BRANCH(true);
}

void Slurm16CPU::bl(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    cpu->m_regs[15] = cpu->m_pc;
    BRANCH(true);
}

#define COND_MOV(cond) \
    uint16_t* r_dest = R_DEST(cpu, instruction);    \
    uint16_t* r_src = R_SRC(cpu, instruction);      \
    if (cond) *r_dest = *r_src;    \
    cpu->m_pc += 2;    \
    cpu->m_imm_hi = 0


void Slurm16CPU::movz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_z);
}

void Slurm16CPU::movnz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(!cpu->m_z);
}

void Slurm16CPU::movs(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_s);
}

void Slurm16CPU::movns(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(!cpu->m_s);
}

void Slurm16CPU::movc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_c);
}

void Slurm16CPU::movnc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(!cpu->m_c);
}

void Slurm16CPU::movv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_v);
}

void Slurm16CPU::movnv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(!cpu->m_v);
}

void Slurm16CPU::movlt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_v != cpu->m_s);
}

void Slurm16CPU::movle(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_z || (cpu->m_v != cpu->m_s));
}

void Slurm16CPU::movgt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(!cpu->m_z && (cpu->m_v == cpu->m_s));
}

void Slurm16CPU::movge(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV((cpu->m_v == cpu->m_s));
}

void Slurm16CPU::movleu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(cpu->m_c || cpu->m_z);
}

void Slurm16CPU::movgtu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(!cpu->m_c && !cpu->m_z);
}

void Slurm16CPU::mova(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon)
{
    COND_MOV(true);
}

