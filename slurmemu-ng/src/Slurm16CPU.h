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

    private:

        /* ALU operations */
        void alu_mov(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_add(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_adc(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_sub(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_sbb(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_cmp(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_and(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_test(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_or(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_xor(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_mul(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_mulu(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_rrn(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_rln(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_umulu(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);
        void alu_bswap(std::uint8_t reg_dest, std::uint16_t src1, std::uint16_t src2);

        /* Logical operations */
        void alu_asr(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_lsr(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_lsl(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_rolc(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_rorc(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_rol(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_ror(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_cc(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_sc(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_cz(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_sz(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_cs(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_ss(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_stf(std::uint8_t reg_dest, std::uint16_t src1);
        void alu_rsf(std::uint8_t reg_dest, std::uint16_t src1);

        /* branch operations */ 


        /* memory operations */


        std::uint8_t z;
        std::uint8_t c;
        std::uint8_t s;
        std::uint8_t v;
        
        std::uint8_t z_int;
        std::uint8_t c_int;
        std::uint8_t s_int;
        std::uint8_t v_int;
        
        std::uint16_t imm_hi;
        std::uint16_t imm_int;

        std::uint16_t pc;
        std::uint16_t regs[128];

        bool int_flag;
        bool halt;
}
