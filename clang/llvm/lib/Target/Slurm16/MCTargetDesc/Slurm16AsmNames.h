//===-- Slurm16AsmNames.h - Symbol name legalization for slurmasm-ng ------===//
//
// slurmasm-ng identifiers are [a-zA-Z_.][a-zA-Z0-9_.]* and must not collide
// with any of its keywords (opcodes, register names, pseudo ops, hexadecimal
// literals of the form "abch", extended register names "x123", ...).
//
// Symbols which would not lex as an identifier are rewritten
// deterministically, so that all translation units agree on the spelling of
// a given symbol.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SLURM16_MCTARGETDESC_SLURM16ASMNAMES_H
#define LLVM_LIB_TARGET_SLURM16_MCTARGETDESC_SLURM16ASMNAMES_H

#include "llvm/ADT/StringRef.h"
#include <string>

namespace llvm {
class MCExpr;
class MCSymbol;
class raw_ostream;

namespace Slurm16 {

/// Return the spelling of \p Name to be used in slurmasm-ng assembly.
std::string getAsmSymbolName(StringRef Name);

/// Print \p Sym, legalizing its name.
void printSymbol(raw_ostream &OS, const MCSymbol &Sym);

/// Print an expression in slurmasm-ng syntax.
void printExpr(raw_ostream &OS, const MCExpr &Expr);

} // namespace Slurm16
} // namespace llvm

#endif
