//===-- Slurm16AsmPrinter.cpp - SLURM16 LLVM assembly writer --------------===//

#include "MCTargetDesc/Slurm16AsmNames.h"
#include "MCTargetDesc/Slurm16InstPrinter.h"
#include "Slurm16.h"
#include "Slurm16MCInstLower.h"
#include "Slurm16TargetMachine.h"
#include "TargetInfo/Slurm16TargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

namespace {
class Slurm16AsmPrinter : public AsmPrinter {
public:
  Slurm16AsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer), ID) {}

  StringRef getPassName() const override { return "SLURM16 Assembly Printer"; }

  void emitInstruction(const MachineInstr *MI) override;
  void emitFunctionEntryLabel() override;
  void emitFunctionBodyEnd() override;

  void PrintSymbolOperand(const MachineOperand &MO, raw_ostream &O) override;
  void printOperand(const MachineInstr *MI, int OpNo, raw_ostream &O);
  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       const char *ExtraCode, raw_ostream &O) override;
  bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                             const char *ExtraCode, raw_ostream &O) override;

  static char ID;
};
} // namespace

void Slurm16AsmPrinter::emitInstruction(const MachineInstr *MI) {
  Slurm16_MC::verifyInstructionPredicates(MI->getOpcode(),
                                          getSubtargetInfo().getFeatureBits());
  Slurm16MCInstLower Lower(OutContext, *this);
  MCInst TmpInst;
  Lower.Lower(MI, TmpInst);
  EmitToStreamer(*OutStreamer, TmpInst);
}

void Slurm16AsmPrinter::emitFunctionEntryLabel() {
  // ".function name" places the function in its own sub-section
  // (.text.name), which slurmlink can garbage collect.
  if (OutStreamer->hasRawTextSupport())
    OutStreamer->emitRawText("\t.function " +
                             Slurm16::getAsmSymbolName(CurrentFnSym->getName()));
  AsmPrinter::emitFunctionEntryLabel();
}

void Slurm16AsmPrinter::emitFunctionBodyEnd() {
  if (OutStreamer->hasRawTextSupport())
    OutStreamer->emitRawText(StringRef("\t.endfunc"));
}

void Slurm16AsmPrinter::PrintSymbolOperand(const MachineOperand &MO,
                                           raw_ostream &O) {
  Slurm16::printSymbol(O, *getSymbol(MO.getGlobal()));
  if (MO.getOffset() > 0)
    O << '+' << MO.getOffset();
  else if (MO.getOffset() < 0)
    O << MO.getOffset();
}

void Slurm16AsmPrinter::printOperand(const MachineInstr *MI, int OpNo,
                                     raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand(OpNo);
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << Slurm16InstPrinter::getRegisterName(MO.getReg());
    return;
  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    return;
  case MachineOperand::MO_MachineBasicBlock:
    Slurm16::printSymbol(O, *MO.getMBB()->getSymbol());
    return;
  case MachineOperand::MO_GlobalAddress:
    PrintSymbolOperand(MO, O);
    return;
  case MachineOperand::MO_ExternalSymbol:
    O << Slurm16::getAsmSymbolName(MO.getSymbolName());
    return;
  default:
    llvm_unreachable("SLURM16: unsupported inline asm operand");
  }
}

bool Slurm16AsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                        const char *ExtraCode,
                                        raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return AsmPrinter::PrintAsmOperand(MI, OpNo, ExtraCode, O);
  printOperand(MI, OpNo, O);
  return false;
}

bool Slurm16AsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                              unsigned OpNo,
                                              const char *ExtraCode,
                                              raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return true;
  O << '[';
  printOperand(MI, OpNo, O);
  O << ", ";
  printOperand(MI, OpNo + 1, O);
  O << ']';
  return false;
}

char Slurm16AsmPrinter::ID = 0;

INITIALIZE_PASS(Slurm16AsmPrinter, "slurm16-asm-printer",
                "SLURM16 Assembly Printer", false, false)

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeSlurm16AsmPrinter() {
  RegisterAsmPrinter<Slurm16AsmPrinter> X(getTheSlurm16Target());
}
