
#include "OpCode.h"

#include <map>
#include <string>

std::map<std::string, OpCode> opCodeMap = {
	{"ADC", OpCode::ADC},
	{"ADD", OpCode::ADD},
	{"AND", OpCode::AND},
	{"ASR", OpCode::ASR},
	{"BA", OpCode::BA},
	{"BC", OpCode::BC},
	{"BL", OpCode::BL},
	{"BNC", OpCode::BNC},
	{"BNS", OpCode::BNS},
	{"BNZ", OpCode::BNZ},
	{"BS", OpCode::BS},
	{"BSWAP", OpCode::BSWAP},
	{"BZ", OpCode::BZ},
	{"CC", OpCode::CC},
	{"CS", OpCode::CS},
	{"CZ", OpCode::CZ},
	{"IMM", OpCode::IMM},
	{"IN", OpCode::IN},
	{"IRET", OpCode::IRET},
	{"LD", OpCode::LD},
	{"LSL", OpCode::LSL},
	{"LSR", OpCode::LSR},
	{"MOV", OpCode::MOV},
	{"NOP", OpCode::NOP},
	{"OR", OpCode::OR},
	{"OUT", OpCode::OUT},
	{"RET", OpCode::RET},
	{"ROL", OpCode::ROL},
	{"ROLC", OpCode::ROLC},
	{"ROR", OpCode::ROR},
	{"RORC", OpCode::RORC},
	{"SBB", OpCode::SBB},
	{"SC", OpCode::SC},
	{"SS", OpCode::SS},
	{"ST", OpCode::ST},
	{"SUB", OpCode::SUB},
	{"SZ", OpCode::SZ},
	{"XOR", OpCode::XOR},
	{"CMP", OpCode::CMP},
	{"TEST", OpCode::TEST},
	{"STI", OpCode::STI},
	{"CLI", OpCode::CLI},
	{"SLEEP", OpCode::SLEEP},
	{"STF", OpCode::STF},
	{"RSF", OpCode::RSF},
	{"MUL", OpCode::MUL},
	{"MULU", OpCode::MULU},
	{"UMULU", OpCode::UMULU},
	{"BNE", OpCode::BNE},
	{"BEQ", OpCode::BEQ},
	{"BGE", OpCode::BGE},
	{"BGT", OpCode::BGT},
	{"BLE", OpCode::BLE},
	{"BLT", OpCode::BLT},
	{"BLEU", OpCode::BLEU},
	{"BLTU", OpCode::BLTU},
	{"BGEU", OpCode::BGEU},
	{"BGTU", OpCode::BGTU},
	{"BV", OpCode::BV},
	{"BNV", OpCode::BNV},
	{"LDB", OpCode::LDB},
	{"LDBSX", OpCode::LDBSX},
	{"STB", OpCode::STB},
	{"RRN", OpCode::RRN},
	{"RLN", OpCode::RLN},
	{"STIX", OpCode::STIX},
	{"RSIX", OpCode::RSIX},
	{"LD.EX", OpCode::LD_EX},
	{"LDB.EX", OpCode::LDB_EX},
	{"LDBSX.EX", OpCode::LDBSX_EX},
	{"ST.EX", OpCode::ST_EX},
	{"STB.EX", OpCode::STB_EX},
};


OpCode OpCode_convertOpCode(std::string opcode)
{
	return opCodeMap[opcode];
}

std::ostream& operator << (std::ostream& os, const OpCode& o)
{
	for (const auto& kv : opCodeMap)
	{
		if (kv.second == o) os << kv.first;
	}

	return os;
}


