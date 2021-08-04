//
// AST.CPP : abstract syntax tree class
//

#include <string>
#include <sstream>
#include <utility>
#include <cstdint>
#include <iomanip>
#include <fstream>

#include "AST.h"

void AST::addPlusToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kPlus;
    m_currentStatement.expression.addElement(e);
}

void AST::addMinusToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kMinus;
    m_currentStatement.expression.addElement(e);
}

void AST::addLeftParenthesisToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kLeftParenthesis;
    m_currentStatement.expression.addElement(e);
}

void AST::addRightParenthesisToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kRightParenthesis;
    m_currentStatement.expression.addElement(e);
}

void AST::addDivToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kDiv;
    m_currentStatement.expression.addElement(e);
}

void AST::addMultToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kMult;
    m_currentStatement.expression.addElement(e);
}

void AST::addShiftLeftToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kShiftLeft;
    m_currentStatement.expression.addElement(e);
}

void AST::addShiftRightToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kShiftRight;
    m_currentStatement.expression.addElement(e);
}

void AST::addAndToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kAnd;
    m_currentStatement.expression.addElement(e);
}

void AST::addOrToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kOr;
    m_currentStatement.expression.addElement(e);
}

void AST::addXorToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kXor;
    m_currentStatement.expression.addElement(e);
}

void AST::addNotToCurrentStatementExpression()
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kNot;
    m_currentStatement.expression.addElement(e);
}

void AST::addIntToCurrentStatementExpression(int val)
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kInt;
    e.v.sval = val;
    m_currentStatement.expression.addElement(e);
}

void AST::addUIntToCurrentStatementExpresion(unsigned int val)
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kUInt;
    e.v.uval = val;
    m_currentStatement.expression.addElement(e);
}

void AST::addStringToCurrentStatementExpression(char* string)
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kString;
    e.v.string = string;
    m_currentStatement.expression.addElement(e);
}

void AST::addStringLiteralToCurrentStatementExpression(char* string)
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kStringLiteral;
    e.v.string = string;
    m_currentStatement.expression.addElement(e);
}

void AST::addCharLiteralToCurrentStatementExpression(char* string)
{
    ExpressionElement e;
    e.elem = ExpressionElementType::kCharLiteral;
    e.v.string = string;
    m_currentStatement.expression.addElement(e);
}

void AST::addTwoRegisterOpcode(int linenum, char* opcode, char* regDest, char* regSrc)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.regSrc = convertReg(regSrc);
    m_currentStatement.regDest = convertReg(regDest);
    m_currentStatement.type = StatementType::TWO_REGISTER_OPCODE;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addOneRegisterAndExpressionOpcode(int linenum, char* opcode, char* regDest)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.regDest = convertReg(regDest);
    m_currentStatement.type = StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION;
    m_currentStatement.expression.lineNum = linenum;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addExpressionOpcode(int linenum, char* opcode)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.type = StatementType::OPCODE_WITH_EXPRESSION;
    m_currentStatement.expression.lineNum = linenum;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addStandaloneOpcode(int linenum, char* opcode)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.type = StatementType::STANDALONE_OPCODE;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addExpressionPseudoOp(int linenum, char* pseudoOp)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.pseudoOp = convertPseudoOp(pseudoOp);
    m_currentStatement.expression.lineNum = linenum;
    m_currentStatement.type = StatementType::PSEUDO_OP_WITH_EXPRESSION;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addIndirectAddressingOpcode(int linenum, char* opcode, char* regDest, char* regIdx, char* regOffset)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.type = StatementType::INDIRECT_ADDRESSING_OPCODE;
    m_currentStatement.regDest = convertReg(regDest);
    m_currentStatement.regInd = convertReg(regIdx);
    m_currentStatement.regOffset = convertReg(regOffset);
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addIndirectAddressingOpcodeWithExpression(int linenum, char* opcode, char* regDest, char* regIdx)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.type = StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION;
    m_currentStatement.regDest = convertReg(regDest);
    m_currentStatement.regInd = convertReg(regIdx);
    m_currentStatement.expression.lineNum = linenum;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addOneRegisterOpcode(int linenum, char* opcode, char* regDest)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.opcode = convertOpCode(opcode);
    m_currentStatement.regDest = convertReg(regDest);
    m_currentStatement.type = StatementType::ONE_REGISTER_OPCODE;
    m_currentStatement.expression.lineNum = linenum;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addLabel(int linenum, char* label)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.label = label;
    m_currentStatement.type = StatementType::LABEL;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addTimes(int linenum)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.type = StatementType::TIMES;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

void AST::addEqu(int linenum, char* label)
{
    m_currentStatement.lineNum = linenum;
    m_currentStatement.type = StatementType::EQU;
    m_currentStatement.expression.lineNum = linenum;
    m_currentStatement.label = label;
    m_statements.push_back(m_currentStatement);
    m_currentStatement.reset();
}

OpCode AST::convertOpCode(char* opcode)
{
    std::string s(opcode);

    for (auto & c: s)
        c = toupper(c);

    if (s == "ADC")
    {
        return OpCode::ADC;
    }
    else if (s == "ADD")
    {
        return OpCode::ADD;
    }
    else if (s == "AND")
    {
        return OpCode::AND;
    }
    else if (s == "BA")
    {
        return OpCode::BA;
    }
    else if (s == "BC")
    {
        return OpCode::BC;
    }
    else if (s == "BL")
    {
        return OpCode::BL;
    }
    else if (s == "BNC")
    {
        return OpCode::BNC;
    }
    else if (s == "BNS")
    {
        return OpCode::BNS;
    }
    else if (s == "BNZ")
    {
        return OpCode::BNZ;
    }
    else if (s == "BS")
    {
        return OpCode::BS;
    }
    else if (s == "BZ")
    {
        return OpCode::BZ;
    }
    else if (s == "CC")
    {
        return OpCode::CC;
    }
    else if (s == "CS")
    {
        return OpCode::CS;
    }
    else if (s == "CZ")
    {
        return OpCode::CZ;
    }
    else if (s == "DECM")
    {
        return OpCode::DECM;
    }
    else if (s == "IMM")
    {
        return OpCode::IMM;
    }
    else if (s == "INCM")
    {
        return OpCode::INCM;
    }
    else if (s == "IRET")
    {
        return OpCode::IRET;
    }
    else if (s == "LD")
    {
        return OpCode::LD;
    }
	else if (s == "LSL")
    {
        return OpCode::LSL;
    }
    else if (s == "LSR")
    {
        return OpCode::LSR;
    }
    else if (s == "MOV")
    {
        return OpCode::MOV;
    }
    else if (s == "NOP")
    {
        return OpCode::NOP;
    }
    else if (s == "OR")
    {
        return OpCode::OR;
    }
    else if (s == "RET")
    {
        return OpCode::RET;
    }
    else if (s == "ROL")
    {
        return OpCode::ROL;
    }
    else if (s == "ROLC")
    {
        return OpCode::ROLC;
    }
    else if (s == "RORC")
    {
        return OpCode::RORC;
    }
    else if (s == "SBB")
    {
        return OpCode::SBB;
    }
    else if (s == "SC")
    {
        return OpCode::SC;
    }
    else if (s == "SS")
    {
        return OpCode::SS;
    }
    else if (s == "ST")
    {
        return OpCode::ST;
    }
    else if (s == "SUB")
    {
        return OpCode::SUB;
    }
    else if (s == "SZ")
    {
        return OpCode::SZ;
    }
    else if (s == "XOR")
    {
        return OpCode::XOR;
    }

    return OpCode::None;

}

PseudoOp AST::convertPseudoOp(char* pseudoOp)
{

    std::string s(pseudoOp);

    for (auto & c: s)
        c = toupper(c);

    if (s == ".ORG")
    {
        return PseudoOp::ORG;
    }
    else if (s == ".ALIGN")
    {
        return PseudoOp::ALIGN;
    }
    else if (s == "DW")
    {
        return PseudoOp::DW;
    }
    else if (s == "DD")
    {
        return PseudoOp::DD;
    }

}

Register AST::convertReg(char* reg)
{

    std::string s(reg);

    for (auto & c: s)
        c = tolower(c);

    if (s == "r0")
    {
        return Register::r0;
    }
    else if (s == "r1")
    {
        return Register::r1;
    }
    else if (s == "r2")
    {
        return Register::r2;
    }
    else if (s == "r3")
    {
        return Register::r3;
    }
    else if (s == "r4")
    {
        return Register::r4;
    }
    else if (s == "r5")
    {
        return Register::r5;
    }
    else if (s == "r6")
    {
        return Register::r6;
    }
    else if (s == "r7")
    {
        return Register::r7;
    }

    return Register::None;
}

std::ostream& operator << (std::ostream& os, const AST& ast)
{
    for (const Statement& s : ast.m_statements)
        os << s;

    return os;
}

std::ostream& operator << (std::ostream& os, const Statement& s)
{

    os << "Statement line " << s.lineNum << " : ";

   switch(s.type)
    {
        case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
            os << s.opcode << " " << s.regDest << " " << s.expression << std::endl;
        break;
        case StatementType::TWO_REGISTER_OPCODE:
            os << s.opcode << " " << s.regDest << " " << s.regSrc << std::endl;
        break;
        case StatementType::ONE_REGISTER_OPCODE:
           os << s.opcode << " " << s.regDest << std::endl;
        break;
        case StatementType::INDIRECT_ADDRESSING_OPCODE:
           os << s.opcode << " " << s.regDest << " " << s.regInd << " " << s.regOffset << std::endl;
        break;
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
          os << s.opcode << " " << s.regDest << " " << s.regInd << " " << s.expression << std::endl;
        break;
        case StatementType::OPCODE_WITH_EXPRESSION:
            os << s.opcode << " " << s.expression << std::endl;
        break;
        case StatementType::PSEUDO_OP_WITH_EXPRESSION:
            os << s.pseudoOp << " " << s.expression << std::endl;
        break;
        case StatementType::STANDALONE_OPCODE:
            os << s.opcode << std::endl;
        break;
        case StatementType::LABEL:
            os << s.label << ":" << std::endl;
        break;
        case StatementType::TIMES:
            os << "times" << " " << s.expression << " ";
        break;
        case StatementType::EQU:
            os << "EQU" << " " << s.label << " " << s.expression << std::endl;
        break;
    }

    return os;
}

std::ostream& operator << (std::ostream& os, const ExpressionElement& elem)
{

    switch(elem.elem)
    {
        case ExpressionElementType::kLeftParenthesis:
            os << " ( ";
            break;
        case ExpressionElementType::kRightParenthesis:
            os << " ) ";
            break;
        case ExpressionElementType::kPlus:
            os << " + ";
            break;
        case ExpressionElementType::kMinus:
            os << " - ";
            break;
        case ExpressionElementType::kDiv:
            os << " / ";
            break;
        case ExpressionElementType::kMult:
            os << " * ";
            break;
        case ExpressionElementType::kShiftLeft:
            os << " << ";
            break;
        case ExpressionElementType::kShiftRight:
            os << " >> ";
            break;
        case ExpressionElementType::kAnd:
            os << " & ";
            break;
        case ExpressionElementType::kOr:
            os << " | ";
            break;
        case ExpressionElementType::kXor:
            os << " ^ ";
            break;
        case ExpressionElementType::kNot:
            os << " ~ ";
            break;
        case ExpressionElementType::kInt:
            os << elem.v.sval;
            break;
        case ExpressionElementType::kUInt:
            os << elem.v.uval;
            break;
        case ExpressionElementType::kString:
        case ExpressionElementType::kStringLiteral:
        case ExpressionElementType::kCharLiteral:
            os << elem.v.string;
            break;
    }

    return os;
}

std::ostream& operator << (std::ostream& os, const Expression& e)
{
    for (ExpressionElement elem : e.elements)
    {
        os << elem;
    }
    return os;
}

std::ostream& operator << (std::ostream& os, const OpCode& op)
{
    if (op == OpCode::IMM)
    {
        os << "IMM";
    }
    else if (op == OpCode::ADD)
    {
        os << "ADD";
    }
    else if (op == OpCode::ADC)
    {
        os << "ADC";
    }
    else if (op == OpCode::SUB)
    {
        os << "SUB";
    }
    else if (op == OpCode::SBB)
    {
        os << "SBB";
    }
    else if (op == OpCode::AND)
    {
        os << "AND";
    }
    else if (op == OpCode::OR)
    {
        os << "OR";
    }
    else if (op == OpCode::XOR)
    {
        os << "XOR";
    }
    else if (op == OpCode::SLA)
    {
        os << "SLA";
    }
    else if (op == OpCode::SLX)
    {
        os << "SLX";
    }
    else if (op == OpCode::SL0)
    {
        os << "SL0";
    }
    else if (op == OpCode::SL1)
    {
        os << "SL1";
    }
    else if (op == OpCode::RL)
    {
        os << "RL";
    }
    else if (op == OpCode::SRA)
    {
        os << "SRA";
    }
    else if (op == OpCode::SRX)
    {
        os << "SRX";
    }
    else if (op == OpCode::SR0)
    {
        os << "SR0";
    }
    else if (op == OpCode::SR1)
    {
        os << "SR1";
    }
    else if (op == OpCode::RR)
    {
        os << "RR";
    }
    else if (op == OpCode::CMP)
    {
        os << "CMP";
    }
    else if (op == OpCode::TEST)
    {
        os << "TEST";
    }
    else if (op == OpCode::LOAD)
    {
        os << "LOAD";
    }
    else if (op == OpCode::MUL)
    {
        os << "MUL";
    }
    else if (op == OpCode::MULS)
    {
        os << "MULS";
    }
    else if (op == OpCode::DIV)
    {
        os << "DIV";
    }
    else if (op == OpCode::DIVS)
    {
        os << "DIVS";
    }
    else if (op == OpCode::BSL)
    {
        os << "BSL";
    }
    else if (op == OpCode::BSR)
    {
        os << "BSR";
    }
    else if (op == OpCode::FMUL)
    {
        os << "FMUL";
    }
    else if (op == OpCode::FDIV)
    {
        os << "FDIV";
    }
    else if (op == OpCode::FADD)
    {
        os << "FADD";
    }
    else if (op == OpCode::FSUB)
    {
        os << "FSUB";
    }
    else if (op == OpCode::FCMP)
    {
        os << "FCMP";
    }
    else if (op == OpCode::FINT)
    {
        os << "FINT";
    }
    else if (op == OpCode::FFLT)
    {
        os << "FFLT";
    }
    else if (op == OpCode::NOP)
    {
        os << "NOP";
    }
    else if (op == OpCode::SLEEP)
    {
        os << "SLEEP";
    }
    else if (op == OpCode::JUMP)
    {
        os << "JUMP";
    }
    else if (op == OpCode::JUMPZ)
    {
        os << "JUMPZ";
    }
    else if (op == OpCode::JUMPC)
    {
        os << "JUMPC";
    }
    else if (op == OpCode::JUMPNZ)
    {
        os << "JUMPNZ";
    }
    else if (op == OpCode::JUMPNC)
    {
        os << "JUMPNC";
    }
    else if (op == OpCode::CALL)
    {
        os << "CALL";
    }
    else if (op == OpCode::CALLZ)
    {
        os << "CALLZ";
    }
    else if (op == OpCode::CALLC)
    {
        os << "CALLC";
    }
    else if (op == OpCode::CALLNZ)
    {
        os << "CALLNZ";
    }
    else if (op == OpCode::CALLNC)
    {
        os << "CALLNC";
    }
    else if (op == OpCode::SVC)
    {
        os << "SVC";
    }
    else if (op == OpCode::RET)
    {
        os << "RET";
    }
    else if (op == OpCode::RETI)
    {
        os << "RETI";
    }
    else if (op == OpCode::RETE)
    {
        os << "RETE";
    }
    else if (op == OpCode::LDW)
    {
        os << "LDW";
    }
    else if (op == OpCode::STW)
    {
        os << "STW";
    }
    else if (op == OpCode::LDSPR)
    {
        os << "LDSPR";
    }
    else if (op == OpCode::STSPR)
    {
        os << "STSPR";
    }
    else if (op == OpCode::OUT)
    {
        os << "OUT";
    }
    else if (op == OpCode::IN)
    {
        os << "IN";
    }
    else
    {
        os << "NIL";
    }
    return os;
}

std::ostream& operator << (std::ostream& os, const PseudoOp& ps)
{
    if (ps == PseudoOp::ORG)
    {
        os << "ORG";
    }
    else if (ps == PseudoOp::ALIGN)
    {
        os << "ALIGN";
    }
    else if (ps == PseudoOp::DW)
    {
        os << "DW";
    }
    else if (ps == PseudoOp::DD)
    {
        os << "DD";
    }
    else
    {
        os << "NIL";
    }
    return os;
}

std::ostream& operator << (std::ostream& os, const Symbol& sym)
{
    os << "Symbol : " << sym.string << " " << "Defined in: " << sym.definedIn;
    os << " Referred to by: ";
    for (Statement* s : sym.referredBy)
        os << s << " ";
    os << " Evaluated: " << sym.evaluated << " value: " << sym.value;
    return os;
}

void AST::buildSymbolTable()
{
    // iterate over all statements and add symbols

    for (Statement& s : m_statements)
    {
        // 1. add all labels
        // 2. add all equates
        if (s.type == StatementType::LABEL ||
            s.type == StatementType::EQU)
        {
            Symbol sym;
            sym.definedIn = &s;
            sym.string = s.label;

            bool found = true;

            // check to see if symbol already exists?
            try
            {
                m_symbolTable.at(s.label);
            }
            catch (...)
            {
                found = false;
            }

            if (found)
            {
                std::stringstream ss;
                ss << "Symbol '" << s.label << "' redefined on line " << s.lineNum << std::endl;
                throw std::runtime_error(ss.str());
            }

            m_symbolTable.emplace(s.label, sym);
            m_symbolList.push_back(&m_symbolTable.at(s.label));
        }
    }

    // find all references to each symbol

    for (Statement& s : m_statements)
    {
        switch(s.type)
        {
            case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
            case StatementType::OPCODE_WITH_EXPRESSION:
            case StatementType::PSEUDO_OP_WITH_EXPRESSION:
            case StatementType::TIMES:
            {
                // find any string in the expression, which could be a symbol
                for (ExpressionElement& e : s.expression.elements)
                {

                    if (e.elem == ExpressionElementType::kString)
                    {
                        Symbol* sym = nullptr;

                        try
                        {
                            sym = &m_symbolTable.at(e.v.string);
                        }
                        catch (std::out_of_range)
                        {
                            std::stringstream ss;
                            ss << "Undefined symbol '" << e.v.string << "' on line " << s.lineNum << std::endl;
                            throw std::runtime_error(ss.str());
                        }

                        sym->referredBy.push_back(&s);
                    }
                }
                break;
            }
            default:

                break;
        }
    }

}

void AST::printSymbolTable()
{
    for (std::pair<const std::string, Symbol>& sp : m_symbolTable)
        std::cout << sp.second << std::endl;
}

void AST::firstPassAssemble()
{

    bool assemblyStarted = false;
    bool orgParsed = false;
    uint32_t curAddress = 0;
    bool isTimes = false;
    Statement* timesStatement = nullptr;

    // Iterate over all statements, insert dummy assembly for each statement, so that in the next
    // stage, the symbols which refer to an address can be resolved.

    for (Statement& s : m_statements)
    {
        switch (s.type)
        {
            case StatementType::LABEL:
                s.address = curAddress;
                isTimes = false;
                break;
            case StatementType::EQU:
                isTimes = false;
                break;
            case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
            case StatementType::OPCODE_WITH_EXPRESSION:
            case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
                assemblyStarted = true;

                if (isTimes)
                {
                    s.timesStatement = timesStatement;
                }

                s.firstPassAssemble(curAddress, m_symbolTable);
                isTimes = false;
                break;
            case StatementType::ONE_REGISTER_OPCODE:
            case StatementType::TWO_REGISTER_OPCODE:
            case StatementType::STANDALONE_OPCODE:
            case StatementType::INDIRECT_ADDRESSING_OPCODE:
                assemblyStarted = true;
                // we can directly assemble the instruction.

                if (isTimes)
                {
                    s.timesStatement = timesStatement;
                }

                s.assemble(curAddress);
                isTimes = false;
                break;
            case StatementType::PSEUDO_OP_WITH_EXPRESSION:

                switch (s.pseudoOp)
                {
                    case PseudoOp::ORG:
                        if (assemblyStarted)
                        {
                            std::stringstream ss;
                            ss << ".org statement after assembly started on line " << s.lineNum << std::endl;
                            throw std::runtime_error(ss.str());
                        }
                        if (orgParsed)
                        {
                            std::stringstream ss;
                            ss << ".org statement already processed at this point, on line " << s.lineNum << std::endl;
                            throw std::runtime_error(ss.str());
                        }
                        if (isTimes)
                        {
                            std::stringstream ss;
                            ss << ".org statement preceded by times, on line " << s.lineNum << std::endl;
                            throw std::runtime_error(ss.str());
                        }

                        if (! s.expression.evaluate(m_orgAddress, m_symbolTable))
                        {
                            std::stringstream ss;
                            ss << ".org statement cannot be evaluated on line " << s.lineNum << std::endl;
                            throw std::runtime_error(ss.str());
                        }

                        curAddress = (uint32_t)m_orgAddress;

                        break;
                    default:

                        if (isTimes)
                        {
                            s.timesStatement = timesStatement;
                        }

                        s.firstPassAssemble(curAddress, m_symbolTable);
                }

                isTimes = false;
                break;
            case StatementType::TIMES:

                timesStatement = &s;

                if (! s.expression.evaluate(s.expression.value, m_symbolTable))
                {
                    std::stringstream ss;
                    ss << ".times statement cannot be evaluated on line " << s.lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                }

                isTimes = true;

                break;
            default:
                break;
        }
    }
}

void AST::resolveSymbols()
{

    // Iterate over all symbols and resolve their values

    // 1. get address of all labels

    for (Symbol* sym : m_symbolList)
    {
        Statement* statement = sym->definedIn;

        if (statement->type == StatementType::LABEL)
        {
            sym->value = statement->address;
            sym->evaluated = true;
        }
    }

    for (Symbol* sym : m_symbolList)
    {
        if (! sym->evaluated)
        {
            Statement*  statement = sym->definedIn;
            int32_t		value	  = 0;

            if (! statement->expression.evaluate(value, m_symbolTable))
            {
                std::stringstream ss;
                ss << "could not evaluate expression on line " << statement->lineNum << std::endl;
                throw std::runtime_error(ss.str());
            }

            sym->value = value;
            sym->evaluated = true;
        }
    }

}

void AST::evaluateExpressions()
{

    // At this point we should be able to evaluate all expressions.

    for (Statement& s : m_statements)
    {
        int32_t value = 0;
        char* string = nullptr;

        if (! (s.type == StatementType::OPCODE_WITH_EXPRESSION ||
               s.type == StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION ||
               s.type == StatementType::PSEUDO_OP_WITH_EXPRESSION))
            continue;

        if (! s.expression.isStringLiteral(string) &&
            ! s.expression.evaluate(value, m_symbolTable))
        {
                std::stringstream ss;
                ss << "could not evaluate expression on line " << s.lineNum << std::endl;
                throw std::runtime_error(ss.str());
        }

        s.expression.value = value;
    }

}

void AST::assemble()
{

    uint32_t curAddress = 0;

    for (Statement& s : m_statements)
    {
        switch (s.type)
        {
            case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
            case StatementType::OPCODE_WITH_EXPRESSION:
            case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
            {
                curAddress = s.address;
                s.assemble(curAddress);

                break;
            }
            case StatementType::ONE_REGISTER_OPCODE:
            case StatementType::INDIRECT_ADDRESSING_OPCODE:
            case StatementType::TWO_REGISTER_OPCODE:
            case StatementType::STANDALONE_OPCODE:
                // These will already be assembled
                break;
            case StatementType::PSEUDO_OP_WITH_EXPRESSION:

                switch (s.pseudoOp)
                {
                    case PseudoOp::DD:
                    case PseudoOp::DW:
                    {
                        curAddress = s.address;
                        s.assemble(curAddress);
                        break;
                    }
                    default:
                        break;
                }

                break;
            default:
                break;
        }
    }

}

void AST::writeBinOutput(std::string path)
{
    uint32_t maxAddress = m_orgAddress;

    for (Statement& s : m_statements)
        if (s.address > m_orgAddress)
            maxAddress = s.address;

    std::vector<uint16_t> assembly;

    assembly.resize((maxAddress - m_orgAddress) / sizeof(uint16_t));

    for (Statement& s : m_statements)
        for (int i = 0; i < s.assembledWords.size(); i++)
            assembly[(s.address - m_orgAddress) / sizeof(uint16_t) + i] = s.assembledWords[i];


    std::ofstream out;

    out.open(path.c_str(), std::ios_base::out | std::ios_base::binary);

    for (uint16_t word : assembly)
        out.write((char*)&word, sizeof(uint16_t));


}

void AST::printAssembly()
{

    for (Statement&s : m_statements)
    {
        if (s.assembledWords.size() == 0)
            continue;

        std::cout << std::hex << std::setfill('0') << std::setw(6) << s.address << " : ";

        for (uint16_t w : s.assembledWords)
        {
            std::cout << std::setfill('0') << std::setw(4) << w << " ";
        }

        std::cout << std::endl;
    }

}
