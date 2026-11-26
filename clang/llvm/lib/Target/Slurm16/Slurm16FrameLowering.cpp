//===-- Slurm16FrameLowering.cpp - SLURM16 Frame Information --------------===//
//
// Stack frame layout (the stack grows down, sp = r13, fp = r12):
//
//   incoming sp (CFA) ->  +----------------------------+
//                         | incoming stack arguments   |  (above CFA)
//                         +----------------------------+  <- CFA
//                         | callee saved registers     |
//                         | locals / spill slots       |
//                         | outgoing call arguments    |
//   sp after prologue ->  +----------------------------+
//
// When a frame pointer is required it holds the CFA (the value of sp on
// entry to the function).
//
//===----------------------------------------------------------------------===//

#include "Slurm16FrameLowering.h"
#include "Slurm16.h"
#include "Slurm16InstrInfo.h"
#include "Slurm16MachineFunctionInfo.h"
#include "Slurm16Subtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

bool Slurm16FrameLowering::hasFPImpl(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  return MF.getTarget().Options.DisableFramePointerElim(MF) ||
         MFI.hasVarSizedObjects() || MFI.isFrameAddressTaken();
}

bool Slurm16FrameLowering::hasReservedCallFrame(
    const MachineFunction &MF) const {
  return !MF.getFrameInfo().hasVarSizedObjects();
}

static void adjustSP(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                     const DebugLoc &DL, const TargetInstrInfo &TII,
                     int64_t Amount, MachineInstr::MIFlag Flag) {
  if (Amount == 0)
    return;
  unsigned Opc = Amount < 0 ? Slurm16::SUBri : Slurm16::ADDri;
  BuildMI(MBB, MBBI, DL, TII.get(Opc), Slurm16::R13)
      .addReg(Slurm16::R13)
      .addImm(Amount < 0 ? -Amount : Amount)
      .setMIFlag(Flag);
}

void Slurm16FrameLowering::emitPrologue(MachineFunction &MF,
                                        MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetInstrInfo &TII = *STI.getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  uint64_t StackSize = MFI.getStackSize();

  // Allocate the frame.
  adjustSP(MBB, MBBI, DL, TII, -(int64_t)StackSize, MachineInstr::FrameSetup);

  // Skip over the callee saved register spills.
  while (MBBI != MBB.end() && MBBI->getFlag(MachineInstr::FrameSetup))
    ++MBBI;

  // Set up the frame pointer: fp = CFA = sp + StackSize.
  if (hasFP(MF)) {
    BuildMI(MBB, MBBI, DL, TII.get(Slurm16::MOVrr), Slurm16::R12)
        .addReg(Slurm16::R13)
        .setMIFlag(MachineInstr::FrameSetup);
    if (StackSize)
      BuildMI(MBB, MBBI, DL, TII.get(Slurm16::ADDri), Slurm16::R12)
          .addReg(Slurm16::R12)
          .addImm(StackSize)
          .setMIFlag(MachineInstr::FrameSetup);
  }
}

void Slurm16FrameLowering::emitEpilogue(MachineFunction &MF,
                                        MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetInstrInfo &TII = *STI.getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.getFirstTerminator();
  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  uint64_t StackSize = MFI.getStackSize();

  // If sp may have been moved by dynamic allocations, restore it from the
  // frame pointer before the callee saved registers are reloaded.
  if (hasFP(MF) && MFI.hasVarSizedObjects()) {
    MachineBasicBlock::iterator FirstRestore = MBBI;
    while (FirstRestore != MBB.begin() &&
           std::prev(FirstRestore)->getFlag(MachineInstr::FrameDestroy))
      --FirstRestore;
    BuildMI(MBB, FirstRestore, DL, TII.get(Slurm16::MOVrr), Slurm16::R13)
        .addReg(Slurm16::R12)
        .setMIFlag(MachineInstr::FrameDestroy);
    adjustSP(MBB, FirstRestore, DL, TII, -(int64_t)StackSize,
             MachineInstr::FrameDestroy);
  }

  // Deallocate the frame.
  adjustSP(MBB, MBBI, DL, TII, StackSize, MachineInstr::FrameDestroy);

  // Interrupt handlers return with iret.
  if (MF.getFunction().hasFnAttribute("interrupt") && MBBI != MBB.end() &&
      MBBI->getOpcode() == Slurm16::RET)
    MBBI->setDesc(TII.get(Slurm16::IRET));
}

MachineBasicBlock::iterator Slurm16FrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const {
  const TargetInstrInfo &TII = *STI.getInstrInfo();
  if (!hasReservedCallFrame(MF)) {
    int64_t Amount = I->getOperand(0).getImm();
    if (Amount != 0) {
      Amount = alignTo(Amount, getStackAlign());
      if (I->getOpcode() == Slurm16::ADJCALLSTACKDOWN)
        Amount = -Amount;
      adjustSP(MBB, I, I->getDebugLoc(), TII, Amount, MachineInstr::NoFlags);
    }
  }
  return MBB.erase(I);
}

void Slurm16FrameLowering::determineCalleeSaves(MachineFunction &MF,
                                                BitVector &SavedRegs,
                                                RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  if (hasFP(MF))
    SavedRegs.set(Slurm16::R12);
}

bool Slurm16FrameLowering::spillCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    ArrayRef<CalleeSavedInfo> CSI, const TargetRegisterInfo *TRI) const {
  const TargetInstrInfo &TII = *STI.getInstrInfo();
  DebugLoc DL = MI != MBB.end() ? MI->getDebugLoc() : DebugLoc();
  for (const CalleeSavedInfo &I : CSI) {
    MCRegister Reg = I.getReg();
    if (!MBB.isLiveIn(Reg))
      MBB.addLiveIn(Reg);
    BuildMI(MBB, MI, DL, TII.get(Slurm16::ST))
        .addReg(Reg, RegState::Kill)
        .addFrameIndex(I.getFrameIdx())
        .addImm(0)
        .setMIFlag(MachineInstr::FrameSetup);
  }
  return true;
}

bool Slurm16FrameLowering::restoreCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    MutableArrayRef<CalleeSavedInfo> CSI,
    const TargetRegisterInfo *TRI) const {
  const TargetInstrInfo &TII = *STI.getInstrInfo();
  DebugLoc DL = MI != MBB.end() ? MI->getDebugLoc() : DebugLoc();
  for (const CalleeSavedInfo &I : CSI) {
    BuildMI(MBB, MI, DL, TII.get(Slurm16::LD), I.getReg())
        .addFrameIndex(I.getFrameIdx())
        .addImm(0)
        .setMIFlag(MachineInstr::FrameDestroy);
  }
  return true;
}
