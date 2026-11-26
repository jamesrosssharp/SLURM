//===-- Slurm16InstPrinter.cpp - Convert SLURM16 MCInst to asm syntax -----===//
//
// Prints instructions in the syntax accepted by slurmasm-ng.
//
//===----------------------------------------------------------------------===//

#include "Slurm16InstPrinter.h"
#include "Slurm16AsmNames.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

// Include the auto-generated portion of the assembly writer.
#include "Slurm16GenAsmWriter.inc"

void Slurm16InstPrinter::printRegName(raw_ostream &O, MCRegister Reg) {
  O << getRegisterName(Reg);
}

void Slurm16InstPrinter::printInst(const MCInst *MI, uint64_t Address,
                                   StringRef Annot, const MCSubtargetInfo &STI,
                                   raw_ostream &O) {
  printInstruction(MI, Address, O);
  printAnnotation(O, Annot);
}

void Slurm16InstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                      raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    printRegName(O, Op.getReg());
  } else if (Op.isImm()) {
    O << (int16_t)Op.getImm();
  } else {
    assert(Op.isExpr() && "unknown operand kind in printOperand");
    Slurm16::printExpr(O, *Op.getExpr());
  }
}

void Slurm16InstPrinter::printImmOperand(const MCInst *MI, unsigned OpNo,
                                         raw_ostream &O) {
  printOperand(MI, OpNo, O);
}

void Slurm16InstPrinter::printMemOperand(const MCInst *MI, unsigned OpNo,
                                         raw_ostream &O) {
  O << '[';
  printOperand(MI, OpNo, O);
  O << ", ";
  printOperand(MI, OpNo + 1, O);
  O << ']';
}

static const char *condName(int64_t CC) {
  switch (CC) {
  case 0:  return "z";
  case 1:  return "nz";
  case 2:  return "s";
  case 3:  return "ns";
  case 4:  return "ltu";
  case 5:  return "geu";
  case 6:  return "v";
  case 7:  return "nv";
  case 8:  return "lt";
  case 9:  return "le";
  case 10: return "gt";
  case 11: return "ge";
  case 12: return "leu";
  case 13: return "gtu";
  default: llvm_unreachable("invalid condition code");
  }
}

void Slurm16InstPrinter::printCCOperand(const MCInst *MI, unsigned OpNo,
                                        raw_ostream &O) {
  O << condName(MI->getOperand(OpNo).getImm());
}
