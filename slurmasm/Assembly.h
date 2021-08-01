#pragma once

#include <vector>
#include <cstdint>

#include "types.h"
#include "nbInstructionSet.h"



class Assembly
{
public:

    static void makeArithmeticInstructionWithImmediate(uint16_t opcode,
                                                       Register reg,
                                                       int32_t immediate, std::vector<uint16_t>& assembledWords,
                                                       uint32_t lineNum);

    static void makeArithmeticInstruction(uint16_t opcode,
                                                       Register regDest,
                                                       Register regSrc, std::vector<uint16_t>& assembledWords,
                                                       uint32_t lineNum);

    static void makeFlowControlInstruction(OpCode opcode, uint32_t address, uint32_t target, uint32_t lineNum,
                                           std::vector<uint16_t>& assembledWords);

    static void makeLoadStoreWithExpression(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& words, int32_t value,
                                            Register regInd, Register regDest);

    static const uint16_t IMM_INSTRUCTION = NB_IMM_INSTRUCTION;
    static const uint16_t ADD_IMM_INSTRUCTION = NB_ADD_IMM_INSTRUCTION;
    static const uint16_t ADD_REG_INSTRUCTION = NB_ADD_REG_INSTRUCTION;
    static const uint16_t ADC_IMM_INSTRUCTION = NB_ADC_IMM_INSTRUCTION;
    static const uint16_t ADC_REG_INSTRUCTION = NB_ADC_REG_INSTRUCTION;
    static const uint16_t SUB_IMM_INSTRUCTION = NB_SUB_IMM_INSTRUCTION;
    static const uint16_t SUB_REG_INSTRUCTION = NB_SUB_REG_INSTRUCTION;
    static const uint16_t SBB_IMM_INSTRUCTION = NB_SBB_IMM_INSTRUCTION;
    static const uint16_t SBB_REG_INSTRUCTION = NB_SBB_REG_INSTRUCTION;
    static const uint16_t AND_IMM_INSTRUCTION = NB_AND_IMM_INSTRUCTION;
    static const uint16_t AND_REG_INSTRUCTION = NB_AND_REG_INSTRUCTION;
    static const uint16_t OR_IMM_INSTRUCTION = NB_OR_IMM_INSTRUCTION;
    static const uint16_t OR_REG_INSTRUCTION = NB_OR_REG_INSTRUCTION;
    static const uint16_t XOR_IMM_INSTRUCTION = NB_XOR_IMM_INSTRUCTION;
    static const uint16_t XOR_REG_INSTRUCTION = NB_XOR_REG_INSTRUCTION;
    static const uint16_t SLA_INSTRUCTION = NB_SLA_INSTRUCTION;
    static const uint16_t SLX_INSTRUCTION = NB_SLX_INSTRUCTION;
    static const uint16_t SL0_INSTRUCTION = NB_SL0_INSTRUCTION;
    static const uint16_t SL1_INSTRUCTION = NB_SL1_INSTRUCTION;
    static const uint16_t RL_INSTRUCTION = NB_RL_INSTRUCTION;
    static const uint16_t SRA_INSTRUCTION = NB_SRA_INSTRUCTION;
    static const uint16_t SRX_INSTRUCTION = NB_SRX_INSTRUCTION;
    static const uint16_t SR0_INSTRUCTION = NB_SR0_INSTRUCTION;
    static const uint16_t SR1_INSTRUCTION = NB_SR1_INSTRUCTION;
    static const uint16_t RR_INSTRUCTION = NB_RR_INSTRUCTION;
    static const uint16_t CMP_IMM_INSTRUCTION = NB_CMP_IMM_INSTRUCTION;
    static const uint16_t CMP_REG_INSTRUCTION = NB_CMP_REG_INSTRUCTION;
    static const uint16_t TEST_IMM_INSTRUCTION = NB_TEST_IMM_INSTRUCTION;
    static const uint16_t TEST_REG_INSTRUCTION = NB_TEST_REG_INSTRUCTION;
    static const uint16_t LOAD_IMM_INSTRUCTION = NB_LOAD_IMM_INSTRUCTION;
    static const uint16_t LOAD_REG_INSTRUCTION = NB_LOAD_REG_INSTRUCTION;
    static const uint16_t MUL_IMM_INSTRUCTION = NB_MUL_IMM_INSTRUCTION;
    static const uint16_t MUL_REG_INSTRUCTION = NB_MUL_REG_INSTRUCTION;
    static const uint16_t MULS_IMM_INSTRUCTION = NB_MULS_IMM_INSTRUCTION;
    static const uint16_t MULS_REG_INSTRUCTION = NB_MULS_REG_INSTRUCTION;
    static const uint16_t DIV_IMM_INSTRUCTION = NB_DIV_IMM_INSTRUCTION;
    static const uint16_t DIV_REG_INSTRUCTION = NB_DIV_REG_INSTRUCTION;
    static const uint16_t DIVS_IMM_INSTRUCTION = NB_DIVS_IMM_INSTRUCTION;
    static const uint16_t DIVS_REG_INSTRUCTION = NB_DIVS_REG_INSTRUCTION;
    static const uint16_t BSL_INSTRUCTION = NB_BSL_INSTRUCTION;
    static const uint16_t BSR_INSTRUCTION = NB_BSR_INSTRUCTION;
    static const uint16_t FMUL_INSTRUCTION = NB_FMUL_INSTRUCTION;
    static const uint16_t FDIV_INSTRUCTION = NB_FDIV_INSTRUCTION;
    static const uint16_t FADD_INSTRUCTION = NB_FADD_INSTRUCTION;
    static const uint16_t FSUB_INSTRUCTION = NB_FSUB_INSTRUCTION;
    static const uint16_t FCMP_INSTRUCTION = NB_FCMP_INSTRUCTION;
    static const uint16_t FINT_INSTRUCTION = NB_FINT_INSTRUCTION;
    static const uint16_t FFLT_INSTRUCTION = NB_FFLT_INSTRUCTION;
    static const uint16_t NOP_INSTRUCTION = NB_NOP_INSTRUCTION;
    static const uint16_t SLEEP_INSTRUCTION = NB_SLEEP_INSTRUCTION;
    static const uint16_t JUMP_INSTRUCTION = NB_JUMP_INSTRUCTION;
    static const uint16_t JUMPZ_INSTRUCTION = NB_JUMPZ_INSTRUCTION;
    static const uint16_t JUMPC_INSTRUCTION = NB_JUMPC_INSTRUCTION;
    static const uint16_t JUMPNZ_INSTRUCTION = NB_JUMPNZ_INSTRUCTION;
    static const uint16_t JUMPNC_INSTRUCTION = NB_JUMPNC_INSTRUCTION;
    static const uint16_t CALL_INSTRUCTION = NB_CALL_INSTRUCTION;
    static const uint16_t CALLZ_INSTRUCTION = NB_CALLZ_INSTRUCTION;
    static const uint16_t CALLC_INSTRUCTION = NB_CALLC_INSTRUCTION;
    static const uint16_t CALLNZ_INSTRUCTION = NB_CALLNZ_INSTRUCTION;
    static const uint16_t CALLNC_INSTRUCTION = NB_CALLNC_INSTRUCTION;
    static const uint16_t JUMP_REL_INSTRUCTION = NB_JUMP_REL_INSTRUCTION;
    static const uint16_t JUMPZ_REL_INSTRUCTION = NB_JUMPZ_REL_INSTRUCTION;
    static const uint16_t JUMPC_REL_INSTRUCTION = NB_JUMPC_REL_INSTRUCTION;
    static const uint16_t JUMPNZ_REL_INSTRUCTION = NB_JUMPNZ_REL_INSTRUCTION;
    static const uint16_t JUMPNC_REL_INSTRUCTION = NB_JUMPNC_REL_INSTRUCTION;
    static const uint16_t CALL_REL_INSTRUCTION = NB_CALL_REL_INSTRUCTION;
    static const uint16_t CALLZ_REL_INSTRUCTION = NB_CALLZ_REL_INSTRUCTION;
    static const uint16_t CALLC_REL_INSTRUCTION = NB_CALLC_REL_INSTRUCTION;
    static const uint16_t CALLNZ_REL_INSTRUCTION = NB_CALLNZ_REL_INSTRUCTION;
    static const uint16_t CALLNC_REL_INSTRUCTION = NB_CALLNC_REL_INSTRUCTION;
    static const uint16_t SVC_INSTRUCTION = NB_SVC_INSTRUCTION;
    static const uint16_t RET_INSTRUCTION = NB_RET_INSTRUCTION;
    static const uint16_t RETI_INSTRUCTION = NB_RETI_INSTRUCTION;
    static const uint16_t RETE_INSTRUCTION = NB_RETE_INSTRUCTION;
    static const uint16_t LDW_REG_INSTRUCTION = NB_LDW_REG_INSTRUCTION;
    static const uint16_t LDW_IMM_INSTRUCTION = NB_LDW_IMM_INSTRUCTION;
    static const uint16_t STW_REG_INSTRUCTION = NB_STW_REG_INSTRUCTION;
    static const uint16_t STW_IMM_INSTRUCTION = NB_STW_IMM_INSTRUCTION;
    static const uint16_t LDSPR_INSTRUCTION = NB_LDSPR_INSTRUCTION;
    static const uint16_t STSPR_INSTRUCTION = NB_STSPR_INSTRUCTION;
    static const uint16_t OUT_INSTRUCTION = NB_OUT_INSTRUCTION;
    static const uint16_t IN_INSTRUCTION = NB_IN_INSTRUCTION;
    static const uint16_t INCW_INSTRUCTION = NB_INCW_INSTRUCTION;
    static const uint16_t DECW_INSTRUCTION = NB_DECW_INSTRUCTION;

};

