//===-- Slurm16AsmNames.cpp - Symbol name legalization for slurmasm-ng ----===//

#include "Slurm16AsmNames.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/Casting.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static bool isReservedWord(StringRef Name) {
  static const StringSet<> Reserved = {
      // Opcodes (see slurmasm-ng.lex).
      "adc", "add", "and", "asr", "ba", "bc", "bl", "bnc", "bns", "bnz", "bs",
      "bz", "bv", "bnv", "cc", "cs", "cz", "imm", "iret", "ld", "lsl", "lsr",
      "mov", "nop", "or", "ret", "rol", "ror", "rolc", "rorc", "sbb", "sc",
      "ss", "st", "sub", "sz", "xor", "cmp", "test", "in", "out", "sleep",
      "sti", "cli", "stf", "rsf", "mul", "mulu", "umulu", "bne", "beq", "bge",
      "blt", "ble", "bgt", "ldb", "ldbsx", "stb", "bltu", "bleu", "bgtu",
      "bgeu", "rrn", "rln", "bswap", "stix", "rsix", "ld.ex", "ldb.ex",
      "ldbsx.ex", "stb.ex", "st.ex",
      // Pseudo ops.
      ".align", "dw", "dd", "db", ".global", ".function", ".endfunc", ".weak",
      ".extern", ".section", ".times", ".end", "equ",
      // Registers.
      "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10",
      "r11", "r12", "r13", "r14", "r15"};
  if (Reserved.contains(Name))
    return true;

  // Extended registers: x[0-9]+
  if (Name.size() > 1 && Name[0] == 'x' &&
      Name.drop_front().find_first_not_of("0123456789") == StringRef::npos)
    return true;

  // Hexadecimal literals: [0-9a-fA-F]+h
  if (Name.size() > 1 && Name.back() == 'h' &&
      Name.drop_back().find_first_not_of("0123456789abcdefABCDEF") ==
          StringRef::npos)
    return true;

  // Conditional ALU ops, e.g. "add.z".
  size_t Dot = Name.find('.');
  if (Dot != StringRef::npos && Dot != 0) {
    StringRef Op = Name.substr(0, Dot);
    if (Op == "add" || Op == "adc" || Op == "and" || Op == "or" ||
        Op == "sbb" || Op == "sub" || Op == "xor" || Op == "mov" ||
        Op == "mul" || Op == "mulu" || Op == "umulu")
      return true;
  }
  return false;
}

static bool isIdentStart(char C) {
  return (C >= 'a' && C <= 'z') || (C >= 'A' && C <= 'Z') || C == '_' ||
         C == '.';
}

static bool isIdentChar(char C) {
  return isIdentStart(C) || (C >= '0' && C <= '9');
}

std::string Slurm16::getAsmSymbolName(StringRef Name) {
  bool NeedsRewrite = Name.empty() || !isIdentStart(Name[0]) ||
                      isReservedWord(Name);
  for (char C : Name)
    if (!isIdentChar(C))
      NeedsRewrite = true;
  if (!NeedsRewrite)
    return Name.str();

  std::string Out;
  raw_string_ostream OS(Out);
  OS << "_S16_";
  for (char C : Name) {
    if (isIdentChar(C))
      OS << C;
    else
      OS << "_" << format_hex_no_prefix((unsigned char)C, 2) << "_";
  }
  return Out;
}

void Slurm16::printSymbol(raw_ostream &OS, const MCSymbol &Sym) {
  OS << getAsmSymbolName(Sym.getName());
}

void Slurm16::printExpr(raw_ostream &OS, const MCExpr &Expr) {
  switch (Expr.getKind()) {
  case MCExpr::Constant:
    OS << cast<MCConstantExpr>(Expr).getValue();
    return;
  case MCExpr::SymbolRef:
    printSymbol(OS, cast<MCSymbolRefExpr>(Expr).getSymbol());
    return;
  case MCExpr::Unary: {
    const MCUnaryExpr &UE = cast<MCUnaryExpr>(Expr);
    switch (UE.getOpcode()) {
    case MCUnaryExpr::Minus:
      OS << '-';
      break;
    case MCUnaryExpr::Not:
      OS << '~';
      break;
    case MCUnaryExpr::Plus:
      break;
    case MCUnaryExpr::LNot:
      report_fatal_error("SLURM16: logical not is not supported by "
                         "slurmasm-ng expressions");
    }
    OS << '(';
    printExpr(OS, *UE.getSubExpr());
    OS << ')';
    return;
  }
  case MCExpr::Binary: {
    const MCBinaryExpr &BE = cast<MCBinaryExpr>(Expr);
    // Common case: symbol +/- constant.
    if (BE.getOpcode() == MCBinaryExpr::Add) {
      if (const auto *RHS = dyn_cast<MCConstantExpr>(BE.getRHS())) {
        printExpr(OS, *BE.getLHS());
        int64_t V = RHS->getValue();
        if (V < 0)
          OS << '-' << -V;
        else
          OS << '+' << V;
        return;
      }
    }
    if (BE.getOpcode() == MCBinaryExpr::Sub) {
      if (const auto *RHS = dyn_cast<MCConstantExpr>(BE.getRHS())) {
        printExpr(OS, *BE.getLHS());
        int64_t V = RHS->getValue();
        if (V < 0)
          OS << '+' << -V;
        else
          OS << '-' << V;
        return;
      }
    }
    const char *Op;
    switch (BE.getOpcode()) {
    case MCBinaryExpr::Add: Op = "+"; break;
    case MCBinaryExpr::Sub: Op = "-"; break;
    case MCBinaryExpr::Mul: Op = "*"; break;
    case MCBinaryExpr::Div: Op = "/"; break;
    case MCBinaryExpr::Shl: Op = "<<"; break;
    case MCBinaryExpr::LShr:
    case MCBinaryExpr::AShr: Op = ">>"; break;
    case MCBinaryExpr::And: Op = "&"; break;
    case MCBinaryExpr::Or: Op = "|"; break;
    case MCBinaryExpr::Xor: Op = "^"; break;
    default:
      report_fatal_error("SLURM16: unsupported operator in expression");
    }
    OS << '(';
    printExpr(OS, *BE.getLHS());
    OS << Op;
    printExpr(OS, *BE.getRHS());
    OS << ')';
    return;
  }
  case MCExpr::Target:
  case MCExpr::Specifier:
    report_fatal_error("SLURM16: unsupported expression kind");
  }
}
