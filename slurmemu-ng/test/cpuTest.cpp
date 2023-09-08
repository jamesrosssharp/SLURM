/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng: Next-Generation Slurm16 emulator

cpuTest.cpp: CPU Tester

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

#include <gtest/gtest.h>

#include <Slurm16CPU.h>

class Slurm16CPUTest : public ::testing::Test {
    protected:

        void SetUp() override {
            m_cpu = new Slurm16CPU();
        }

        void TearDown() override {
            delete m_cpu;
        }

        Slurm16CPU *m_cpu;
};

TEST_F(Slurm16CPUTest, TestMov)
{

    constexpr int kNumInst = 3;
    uint16_t memory[kNumInst] = {0x3013 /* mov r1, 3 */, 0x2021 /* mov r2, r1 */, 0x3037 /* mov r3, 7 */};

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 3);
    ASSERT_EQ(m_cpu->get_register(2), 3);
    ASSERT_EQ(m_cpu->get_register(3), 7);
}

TEST_F(Slurm16CPUTest, TestAdd)
{

    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x3013 /* mov r1, 3 */, 0x2021 /* mov r2, r1 */, 0x2112 /* add r1, r2 */, 0x3127 /* add r2, 7 */};

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 6);
    ASSERT_EQ(m_cpu->get_register(2), 10);
}

TEST_F(Slurm16CPUTest, TestAdc)
{

    constexpr int kNumInst = 5;
    uint16_t memory[kNumInst] = {0x1fff /* imm 0xfff0 */, 0x301f /* mov r1, 0xffff */, 0x3021 /* mov r2, 1 */, 0x2112 /* add r1, r2 */, 0x2220 /* adc r2, r0 */};

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0);
    ASSERT_EQ(m_cpu->get_register(2), 2);
}

TEST_F(Slurm16CPUTest, TestIMM)
{
    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x1fff /* imm 0xfff0 */, 0x301f /* mov r1, 0xffff */, 0x1123 /* imm 0x1230 */, 0x3024 /* mov r2, 0x1234 */, };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0xffff);
    ASSERT_EQ(m_cpu->get_register(2), 0x1234);
}

TEST_F(Slurm16CPUTest, TestSub)
{
    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x3015 /* mov r1, 5 */, 0x3312 /* sub r1, 2 */, 0x3027 /* mov r2, 7 */, 0x2321 /* sub r2, r1 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 3);
    ASSERT_EQ(m_cpu->get_register(2), 4);

}

TEST_F(Slurm16CPUTest, TestSbb)
{
    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x3012 /* mov r1, 2 */, 0x3315 /* sub r1, 5 */, 0x3027 /* mov r2, 7 */, 0x2421 /* sbb r2, r1 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0xfffd);
    ASSERT_EQ(m_cpu->get_register(2), 9);

}

TEST_F(Slurm16CPUTest, TestAnd)
{
    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x1123 /* imm 0x1230 */, 0x3014 /* mov r1, 0x1234 */, 0x10f0 /* imm 0x0f00 */, 0x351f /* and r1, 0x0f0f */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0x0204);

}

TEST_F(Slurm16CPUTest, TestOr)
{
    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x1103 /* imm 0x1030 */, 0x3010 /* mov r1, 0x1030 */, 0x1020 /* imm 0x0200 */, 0x3614 /* or r1, 0x0204 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0x1234);

}

TEST_F(Slurm16CPUTest, TestXor)
{
    constexpr int kNumInst = 4;
    uint16_t memory[kNumInst] = {0x1fff /* imm 0xfff0 */, 0x301f /* mov r1, 0xffff */, 0x1fff /* imm 0xfff0 */, 0x371f /* xor r1, 0xffff */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0);

}

TEST_F(Slurm16CPUTest, TestMul)
{
    constexpr int kNumInst = 6;
    uint16_t memory[kNumInst] = {0x3013 /* mov r1, 3 */, 0x3812 /* mul r1, 2 */, 0x1fff /* imm 0xfff0 */, 0x302f /* mov r2, -1 */, 0x3032 /* mov r3, 2 */, 0x2823 /* mul r2, r3 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 6);
    ASSERT_EQ(m_cpu->get_register(2), (uint16_t)-2);

}

TEST_F(Slurm16CPUTest, TestMulu)
{
    constexpr int kNumInst = 5;
    uint16_t memory[kNumInst] = {0x1fff /* imm 0xfff0 */, 0x301f /* mov r1, -1 */, 0x1010 /* imm 0xfff0 */, 0x3020 /* mov r2, -256 */, 0x2912 /* mulu r1, r2 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0xffff);

}

TEST_F(Slurm16CPUTest, TestRRN)
{
    constexpr int kNumInst = 3;
    uint16_t memory[kNumInst] = {0x1123 /* imm 0x1230 */, 0x3014 /* mov r1, 0x1234 */, 0x2a21 /* rrn r2, r1 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0x1234);
    ASSERT_EQ(m_cpu->get_register(2), 0x4123);

}

TEST_F(Slurm16CPUTest, TestRLN)
{
    constexpr int kNumInst = 3;
    uint16_t memory[kNumInst] = {0x1123 /* imm 0x1230 */, 0x3014 /* mov r1, 0x1234 */, 0x2b21 /* rln r2, r1 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0x1234);
    ASSERT_EQ(m_cpu->get_register(2), 0x2341);

}

TEST_F(Slurm16CPUTest, TestCMP)
{
    constexpr int kNumInst = 3;
    uint16_t memory[kNumInst] = {0x3012 /* mov r1, 2 */, 0x3024 /* mov r2, 0x4 */, 0x2c12 /* cmp r1, r2 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 2);
    ASSERT_EQ(m_cpu->get_c_flag(), 1);

}

TEST_F(Slurm16CPUTest, TestTest)
{

    constexpr int kNumInst = 3;
    uint16_t memory[kNumInst] = {0x3012 /* mov r1, 2 */, 0x3024 /* mov r2, 0x4 */, 0x2d12 /* test r1, r2 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 2);
    ASSERT_EQ(m_cpu->get_z_flag(), 1);

}

TEST_F(Slurm16CPUTest, TestUMULU)
{

    constexpr int kNumInst = 5;
    uint16_t memory[kNumInst] = {0x1fff /* imm 0xfff0 */, 0x301f /* mov r1, 0xffff */, 0x1010 /* imm 0xfff0 */, 0x3020 /* mov r2, 0x100 */, 0x2e12 /* umulu r1, r2 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), (0xffffUL * 0x100UL) >> 16);

}

TEST_F(Slurm16CPUTest, TestBswap)
{

    constexpr int kNumInst = 3;
    uint16_t memory[kNumInst] = {0x1123 /* imm 0x1230 */, 0x3014 /* mov r1, 0x1234 */, 0x2f21 /* bwap r2, r1 */ };

    for (int i = 0; i < kNumInst; i++)
        m_cpu->execute_one_instruction(nullptr, memory, 0);

    ASSERT_EQ(m_cpu->get_register(0), 0);
    ASSERT_EQ(m_cpu->get_register(1), 0x1234);
    ASSERT_EQ(m_cpu->get_register(2), 0x3412);
}
