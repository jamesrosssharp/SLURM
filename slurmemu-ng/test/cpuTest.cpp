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

