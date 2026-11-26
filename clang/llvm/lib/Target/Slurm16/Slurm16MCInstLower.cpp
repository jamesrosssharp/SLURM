//===-- Slurm16MCInstLower.cpp - Convert MachineInstr to MCInst -----------===//

#include "Slurm16MCInstLower.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

MCOperand Slurm16MCInstLower::lowerSymbolOperand(const MachineOperand &MO,
                                                 MCSymbol *Sym) const {
  const MCExpr *Expr = MCSymbolRefExpr::create(Sym, Ctx);
  if (!MO.isJTI() && !MO.isMBB() && MO.getOffset())
    Expr = MCBinaryExpr::createAdd(
        Expr, MCConstantExpr::create(MO.getOffset(), Ctx), Ctx);
  return MCOperand::createExpr(Expr);
}

bool Slurm16MCInstLower::lowerOperand(const MachineOperand &MO,
                                      MCOperand &MCOp) const {
  switch (MO.getType()) {
  default:
    report_fatal_error("SLURM16: unknown operand type");
  case MachineOperand::MO_Register:
    if (MO.isImplicit())
      return false;
    MCOp = MCOperand::createReg(MO.getReg());
    return true;
  case MachineOperand::MO_Immediate:
    MCOp = MCOperand::createImm(MO.getImm());
    return true;
  case MachineOperand::MO_MachineBasicBlock:
    MCOp = MCOperand::createExpr(
        MCSymbolRefExpr::create(MO.getMBB()->getSymbol(), Ctx));
    return true;
  case MachineOperand::MO_GlobalAddress:
    MCOp = lowerSymbolOperand(MO, Printer.getSymbol(MO.getGlobal()));
    return true;
  case MachineOperand::MO_ExternalSymbol:
    MCOp = lowerSymbolOperand(
        MO, Printer.GetExternalSymbolSymbol(MO.getSymbolName()));
    return true;
  case MachineOperand::MO_JumpTableIndex:
    MCOp = lowerSymbolOperand(MO, Printer.GetJTISymbol(MO.getIndex()));
    return true;
  case MachineOperand::MO_ConstantPoolIndex:
    MCOp = lowerSymbolOperand(MO, Printer.GetCPISymbol(MO.getIndex()));
    return true;
  case MachineOperand::MO_BlockAddress:
    MCOp = lowerSymbolOperand(
        MO, Printer.GetBlockAddressSymbol(MO.getBlockAddress()));
    return true;
  case MachineOperand::MO_RegisterMask:
    return false;
  }
}

void Slurm16MCInstLower::Lower(const MachineInstr *MI, MCInst &OutMI) const {
  OutMI.setOpcode(MI->getOpcode());
  for (const MachineOperand &MO : MI->operands()) {
    MCOperand MCOp;
    if (lowerOperand(MO, MCOp))
      OutMI.addOperand(MCOp);
  }
}
