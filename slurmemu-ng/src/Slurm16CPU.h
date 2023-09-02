/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

Slurm16CPU.h: CPU Emulator

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

#include <cstdint>

class PortController;

class Slurm16CPU 
{

    public:

        Slurm16CPU();
        ~Slurm16CPU();

        void execute_one_instruction(PortController* pcon, std::uint16_t* mem, std::uint8_t irq);  

        std::uint16_t get_register(std::uint8_t reg) { return m_regs[reg & 0x7f]; }

        std::uint8_t get_c_flag() { return m_c; }

    protected:

        using ins_t = void (*) (Slurm16CPU*, std::uint16_t, std::uint16_t*, PortController*);

        /* IMM instruction */
        static void imm_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* ALU operations */
        static void alu_mov_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_mov_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_add_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_add_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_adc_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_adc_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_sub_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_sub_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_sbb_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_sbb_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_and_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_and_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_or_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_or_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_xor_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_xor_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_mul_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_mul_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_mulu_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_mulu_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_rrn_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_rrn_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_rln_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_rln_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_cmp_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_cmp_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);


        /* branch operations */ 


        /* memory operations */


        /* init */

        void calc_tables();

        /* members */

        static constexpr int kNumRegs = 128;
        static constexpr int kNumLoRegs = 16;
        static constexpr int kTwoPower16 = 65536;       
 
        std::uint8_t m_z;
        std::uint8_t m_c;
        std::uint8_t m_s;
        std::uint8_t m_v;
        
        std::uint8_t m_z_int;
        std::uint8_t m_c_int;
        std::uint8_t m_s_int;
        std::uint8_t m_v_int;
        
        std::uint16_t m_imm_hi;
        std::uint16_t m_imm_int;

        std::uint16_t m_pc;
        std::uint16_t m_regs[kNumRegs];

        bool m_int_flag;
        bool m_halt;

        /* Will these LUTs improve performance, or won't they fit in cache - would raw instructions be better? Should really test */
        ins_t m_instruction_jump_table[kTwoPower16];    /* 4 bytes * 64k = 256k */
        std::uint16_t* m_reg_lo_nibble_table[kTwoPower16];  /* table to select register based on bits 3:0 : 4 bytes * 64k = 256k */
        std::uint16_t* m_reg_mid_nibble_table[kTwoPower16]; /* table to select register based on bits 7:4 : 256k */
        std::uint16_t* m_reg_hi_nibble_table[kTwoPower16];  /* table to select register based on bits 11:8 : 256k */
        
        std::uint8_t m_zero_table[kTwoPower16]; /* table to compare to zero : 64k   */
        std::uint8_t m_sign_table[kTwoPower16]; /* table to decode sign bit : 64k   */
        std::uint8_t m_carry_table[kTwoPower16]; /* table to decode carry bit : 64k */

        /* total LUTs: 1,216 kBytes : hard to fit in cache... */

};