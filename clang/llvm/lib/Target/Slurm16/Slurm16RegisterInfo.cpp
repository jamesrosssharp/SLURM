//===-- Slurm16RegisterInfo.cpp - SLURM16 Register Information ------------===//

#include "Slurm16RegisterInfo.h"
#include "Slurm16.h"
#include "Slurm16FrameLowering.h"
#include "Slurm16InstrInfo.h"
#include "Slurm16Subtarget.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

#define DEBUG_TYPE "slurm16-reg-info"

#define GET_REGINFO_TARGET_DESC
#include "Slurm16GenRegisterInfo.inc"

// The return address register is the link register r15.
Slurm16RegisterInfo::Slurm16RegisterInfo() : Slurm16GenRegisterInfo(Slurm16::R15) {}

static bool isInterruptHandler(const MachineFunction &MF) {
  return MF.getFunction().hasFnAttribute("interrupt");
}

const MCPhysReg *
Slurm16RegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  if (MF && isInterruptHandler(*MF))
    return CSR_Slurm16_Interrupt_SaveList;
  return CSR_Slurm16_SaveList;
}

const uint32_t *
Slurm16RegisterInfo::getCallPreservedMask(const MachineFunction &MF,
                                          CallingConv::ID CC) const {
  return CSR_Slurm16_RegMask;
}

BitVector Slurm16RegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(Slurm16::R0);  // Hard wired zero.
  Reserved.set(Slurm16::R13); // Stack pointer.
  Reserved.set(Slurm16::R14); // Interrupt link register.
  if (getFrameLowering(MF)->hasFP(MF))
    Reserved.set(Slurm16::R12); // Frame pointer.
  return Reserved;
}

const TargetRegisterClass *
Slurm16RegisterInfo::getPointerRegClass(const MachineFunction &MF,
                                        unsigned Kind) const {
  return &Slurm16::GPRRegClass;
}

bool Slurm16RegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                              int SPAdj, unsigned FIOperandNum,
                                              RegScavenger *RS) const {
  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  const Slurm16FrameLowering *TFI = getFrameLowering(MF);
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();

  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();

  // Object offsets are relative to the incoming stack pointer (the CFA).
  int64_t Offset = MFI.getObjectOffset(FrameIndex);

  // Prologue / epilogue code always runs with sp at its post-prologue value,
  // and runs before the frame pointer is set up (or after it has been
  // restored), so it is always sp relative.
  bool UseFP = TFI->hasFP(MF) && !MI.getFlag(MachineInstr::FrameSetup) &&
               !MI.getFlag(MachineInstr::FrameDestroy);
  Register BaseReg;
  if (UseFP) {
    BaseReg = Slurm16::R12;
  } else {
    BaseReg = Slurm16::R13;
    Offset += MFI.getStackSize() + SPAdj;
  }

  if (MI.getOpcode() == Slurm16::ADDframe) {
    // dst = frame address + offset  ->  mov dst, base ; add dst, offset
    Offset += MI.getOperand(FIOperandNum + 1).getImm();
    Register DstReg = MI.getOperand(0).getReg();
    BuildMI(MBB, II, DL, TII.get(Slurm16::MOVrr), DstReg).addReg(BaseReg);
    if (Offset != 0)
      BuildMI(MBB, II, DL, TII.get(Slurm16::ADDri), DstReg)
          .addReg(DstReg)
          .addImm(Offset);
    MI.eraseFromParent();
    return true;
  }

  // Memory operand: [FI, imm] -> [base, imm + offset].
  Offset += MI.getOperand(FIOperandNum + 1).getImm();
  if (!isInt<16>(Offset) && !isUInt<16>(Offset))
    report_fatal_error("SLURM16: frame offset out of range");
  MI.getOperand(FIOperandNum).ChangeToRegister(BaseReg, false);
  MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
  return false;
}

Register Slurm16RegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return getFrameLowering(MF)->hasFP(MF) ? Slurm16::R12 : Slurm16::R13;
}
