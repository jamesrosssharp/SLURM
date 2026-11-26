//===-- Slurm16MCInstLower.h - Lower MachineInstr to MCInst -----*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16MCINSTLOWER_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16MCINSTLOWER_H

#include "llvm/Support/Compiler.h"

namespace llvm {
class AsmPrinter;
class MCContext;
class MCInst;
class MCOperand;
class MCSymbol;
class MachineInstr;
class MachineOperand;

class LLVM_LIBRARY_VISIBILITY Slurm16MCInstLower {
  MCContext &Ctx;
  AsmPrinter &Printer;

public:
  Slurm16MCInstLower(MCContext &Ctx, AsmPrinter &Printer)
      : Ctx(Ctx), Printer(Printer) {}
  void Lower(const MachineInstr *MI, MCInst &OutMI) const;
  bool lowerOperand(const MachineOperand &MO, MCOperand &MCOp) const;

private:
  MCOperand lowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym) const;
};

} // namespace llvm

#endif
