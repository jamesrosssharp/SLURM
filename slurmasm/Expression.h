#pragma once

#include <cstdint>
#include <functional>

#include "Symbol.h"

enum class ExpressionElementType : uint32_t
{
    kNone = 0,
    kLeftParenthesis,
    kRightParenthesis,
    kPlus,
    kMinus,
    kDiv,
    kMult,
    kShiftLeft,
    kShiftRight,
    kAnd,
    kOr,
    kXor,
    kNot,
    kInt,
    kUInt,
    kString,
    kStringLiteral,
    kCharLiteral,
};

struct ExpressionElement
{
    ExpressionElementType elem;
    union
    {
        char* string;
        unsigned int uval;
        int     sval;
        float   fval;
    } v;

    int32_t charLiteralValue()
    {
        if (elem == ExpressionElementType::kCharLiteral)
        {
            return (int32_t)v.string[0];
        }
        throw std::runtime_error("Not a char literal!");
    }

};

struct Expression
{
    void addElement(ExpressionElement& e)
    {
        elements.push_back(e);
    }

    std::vector<ExpressionElement> elements;

    void reset()
    {
        elements.clear();
        lineNum = 0;
        value = 0;
    }

    uint32_t lineNum;

    int32_t value;

    bool evaluate(int32_t& value, SymbolTable& syms);
    bool isStringLiteral(char*& stringLit);

    Expression doOp(ExpressionElementType type, std::function<int32_t (int32_t left, int32_t right)> func);

    static char* substituteSpecialChars(char* stringLit);
    static uint32_t stringLength(char* stringLit);

};

