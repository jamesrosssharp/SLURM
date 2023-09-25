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
        std::uint8_t get_z_flag() { return m_z; }

        std::uint16_t get_pc() const { return m_pc; }

    protected:

        using ins_t = void (*) (Slurm16CPU*, std::uint16_t, std::uint16_t*, PortController*);

        /* NOP instruction */
        static void nop_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* RET / IRET */
        static void ret_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* STIX / RSIX */
        static void stix_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void rsix_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* STI / CLI instructions */
        static void sti_cli_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* SLEEP instruction */
        static void sleep_ins(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

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

        static void alu_test_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_test_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_umulu_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_umulu_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void alu_bswap_reg_reg(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void alu_bswap_reg_imm(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        static void single_reg_alu_op(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* branch operations */ 

        static void bz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bnz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bs(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bns(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bnc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bnv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void blt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void ble(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bgt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bge(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bleu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bgtu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void ba(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void bl(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* cond mov */

        static void movz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movnz(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movs(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movns(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movnc(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movnv(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movlt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movle(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movgt(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movge(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movleu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void movgtu(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void mova(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* memory operations */

        static void byte_load_mem_op(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon); 
        static void byte_load_sx_mem_op(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon); 
        static void byte_store_mem_op(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon); 

        static void word_load_mem_op(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon); 
        static void word_store_mem_op(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon); 


        /* port operations */

        static void port_wr(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);
        static void port_rd(Slurm16CPU* cpu, std::uint16_t instruction, std::uint16_t* mem, PortController* pcon);

        /* init */

        void calc_tables();

        /* members */

        static constexpr int kNumRegs = 128;
        static constexpr int kNumLoRegs = 16;
        static constexpr int kTwoPower16 = 65536;       
        static constexpr int kTwoPower8 = 256;       
 

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

        /* Instruction jump table */
        ins_t m_instruction_jump_table[kTwoPower8];    /* 8 bytes * 256 = 2k */

};
