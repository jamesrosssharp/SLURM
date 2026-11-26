//===-- Slurm16FrameLowering.h - Frame info for SLURM16 ---------*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16FRAMELOWERING_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16FRAMELOWERING_H

#include "llvm/CodeGen/TargetFrameLowering.h"

namespace llvm {

class Slurm16Subtarget;

class Slurm16FrameLowering : public TargetFrameLowering {
  const Slurm16Subtarget &STI;

protected:
  bool hasFPImpl(const MachineFunction &MF) const override;

public:
  explicit Slurm16FrameLowering(const Slurm16Subtarget &STI)
      : TargetFrameLowering(StackGrowsDown, Align(2), 0, Align(2)), STI(STI) {}

  void emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const override;

  MachineBasicBlock::iterator
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;

  bool hasReservedCallFrame(const MachineFunction &MF) const override;

  void determineCalleeSaves(MachineFunction &MF, BitVector &SavedRegs,
                            RegScavenger *RS) const override;

  bool spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 ArrayRef<CalleeSavedInfo> CSI,
                                 const TargetRegisterInfo *TRI) const override;
  bool
  restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MI,
                              MutableArrayRef<CalleeSavedInfo> CSI,
                              const TargetRegisterInfo *TRI) const override;
};

} // namespace llvm

#endif
