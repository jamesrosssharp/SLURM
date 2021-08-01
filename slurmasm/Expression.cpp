#include "Expression.h"
#include "AST.h"
#include <sstream>
#include <iostream>

#include <string.h>

const int kMaxStringLength = 1024;

bool Expression::evaluate(int32_t &value, SymbolTable &syms)
{

    //
    //  Expressions are like the following:
    //
    // ((1 + 2) * 7 + 3 ) / 8
    //
    // They have been tokenised by the lexer and so processing them
    // is as follows:
    //
    // - scan for sub-expressions and recursively evaluate

    Expression  e, sube;
    uint32_t    stackDepth = 0;
    Expression* curExp = &e;

    e.lineNum = lineNum;

    for (ExpressionElement& elem : elements)
    {

        switch (elem.elem)
        {
            case ExpressionElementType::kLeftParenthesis:
                if (stackDepth == 0)
                {
                    curExp = &sube;
                    sube.lineNum = lineNum;
                    sube.reset();
                }
                else
                {
                    curExp->addElement(elem);
                }
                stackDepth++;
                break;
            case ExpressionElementType::kRightParenthesis:
                if (stackDepth == 0)
                {
                    std::cout << elem << std::endl;

                    std::stringstream ss;
                    ss << "unbalanced parenthesis, on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                }

                stackDepth --;

                if (stackDepth == 0)
                {
                    curExp = &e;
                    int32_t subValue = 0;
                    if (! sube.evaluate(subValue, syms))
                        return false;
                    else
                    {
                        ExpressionElement subElem;
                        subElem.elem = ExpressionElementType::kInt;
                        subElem.v.sval = subValue;
                        e.addElement(subElem);
                    }
                }
                else
                {
                    curExp->addElement(elem);
                }

                break;
            case ExpressionElementType::kString:
            {
                // substitute symbols

                Symbol* sym = nullptr;

                try {
                    sym = &syms.at(elem.v.string);
                }
                catch (std::out_of_range)
                {
                    std::stringstream ss;
                    ss << "undefined symbol" << elem.v.string << ", on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                }

                if (! sym->evaluated)
                {
                    return false;
                }

                ExpressionElement symElem;
                symElem.elem = ExpressionElementType::kInt;
                symElem.v.sval = sym->value;
                curExp->addElement(symElem);

                break;
            }
            default:
                curExp->addElement(elem);
                break;
        }

    }


    // - recursively reduce expression (TODO: operator precedence?)

        // unary plus / minus, not

        // mult, div

    e = e.doOp(ExpressionElementType::kMult, [] (int32_t left, int32_t right) -> int32_t { return left * right; });
    e = e.doOp(ExpressionElementType::kDiv, [] (int32_t left, int32_t right) -> int32_t { return left / right; });

        // add, subtract

    e = e.doOp(ExpressionElementType::kPlus, [] (int32_t left, int32_t right) -> int32_t { return left + right; });
    e = e.doOp(ExpressionElementType::kMinus, [] (int32_t left, int32_t right) -> int32_t { return left - right; });

        // shl, shr

    e = e.doOp(ExpressionElementType::kShiftLeft, [] (int32_t left, int32_t right) -> int32_t { return left << right; });
    e = e.doOp(ExpressionElementType::kShiftRight, [] (int32_t left, int32_t right) -> int32_t { return left >> right; });

        // and

    e = e.doOp(ExpressionElementType::kAnd, [] (int32_t left, int32_t right) -> int32_t { return left & right; });

        // xor

    e = e.doOp(ExpressionElementType::kXor, [] (int32_t left, int32_t right) -> int32_t { return left ^ right; });

        // or

    e = e.doOp(ExpressionElementType::kOr, [] (int32_t left, int32_t right) -> int32_t { return left | right; });

    // expression should now consist of a single integer

    if (e.elements.size() != 1 ||
            ! (e.elements[0].elem == ExpressionElementType::kInt ||
               e.elements[0].elem == ExpressionElementType::kUInt ||
               e.elements[0].elem == ExpressionElementType::kCharLiteral))
    {
        std::stringstream ss;
        ss << "Expression couldn't be reduced on line " << lineNum << " " << e.elements.size() << " " << e << std::endl;
        throw std::runtime_error(ss.str());
    }
    else
    {
        if (e.elements[0].elem == ExpressionElementType::kCharLiteral)
        {
            value = e.elements[0].charLiteralValue();
        }
        else
        {
            value = e.elements[0].v.sval;
        }
    }

    return true;
}


Expression Expression::doOp(ExpressionElementType type, std::function<int32_t (int32_t left, int32_t right)> func)
{

    Expression e;
    bool foundOp = false;

    ExpressionElementType op = ExpressionElementType::kNone;

    ExpressionElement* left = nullptr;

    int idx = 1;

    e.lineNum = lineNum;

    for (ExpressionElement& mid : elements)
    {

        if (mid.elem == type)
        {

            foundOp = true;

            ExpressionElement* right;

            try {
                right = &elements.at(idx);
            }
            catch (std::out_of_range)
            {
                std::stringstream ss;
                ss << "multiplication / division without right operand on line " << lineNum << std::endl;
                throw std::runtime_error(ss.str());
            }

            int32_t lval, rval;

            if (left == nullptr)
            {
                std::stringstream ss;
                ss << "binary operator " << (uint32_t)type << " without left operand on line " << lineNum << std::endl;
                throw std::runtime_error(ss.str());
            }

            switch (left->elem)
            {
                case ExpressionElementType::kInt:
                    lval = left->v.sval;
                    break;
                case ExpressionElementType::kUInt:
                    lval = left->v.uval;
                    break;
                case ExpressionElementType::kCharLiteral:
                    lval = (int32_t)left->v.string[0];
                    break;
                default:
                    std::stringstream ss;
                    ss << "unexpected element, on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                    break;
            }

            switch (right->elem)
            {
                case ExpressionElementType::kInt:
                    rval = right->v.sval;
                    break;
                case ExpressionElementType::kUInt:
                    rval = right->v.uval;
                    break;
                case ExpressionElementType::kCharLiteral:
                    rval = (int32_t)right->v.string[0];
                    break;
                default:
                    std::stringstream ss;
                    ss << "unexpected element, on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                    break;
            }

            int32_t value = func(lval, rval);

            ExpressionElement result;

            result.v.sval = value;
            result.elem = ExpressionElementType::kInt;

            e.addElement(result);

            // Add in rest of elements to expression

            for (int i = idx + 1; i < elements.size(); i++)
                e.addElement(elements[i]);

            goto done;
        }
        else
        {
            if (left != nullptr)
                e.addElement(*left);
        }

        left = &mid;
        idx ++;
    }

    if (left != nullptr)
        e.addElement(*left);

done:
    if (foundOp)
        return e.doOp(type, func);
    else
        return e;
}

bool Expression::isStringLiteral(char*& stringLit)
{
    if (elements.size() == 1 && elements[0].elem == ExpressionElementType::kStringLiteral)
    {
        stringLit = elements[0].v.string;
        return true;
    }
    return false;
}

char* Expression::substituteSpecialChars(char* stringLit)
{
    char* newString = new char[::strlen(stringLit)];

    uint32_t pos = 0;
    uint32_t newPos = 0;

    while (pos < kMaxStringLength)
    {
        if (stringLit[pos] == '\0')
        {
            break;
        }

        if (stringLit[pos] == '\\')
        {
            pos++;
            switch (stringLit[pos])
            {
                case 'n':
                    newString[newPos++] = '\n';
                    break;
                case 'r':
                    newString[newPos++] = '\r';
                    break;
                case '0':
                    newString[newPos++] = '\0';
                    break;
            }
        }
        else
        {
            newString[newPos++] = stringLit[pos];
        }
        pos++;
    }

    newString[newPos] = '\0';

    return newString;
}

uint32_t Expression::stringLength(char* stringLit)
{
    char* newString = substituteSpecialChars(stringLit);
    uint32_t len = strlen(newString);
    delete [] newString;
    return len;
}
