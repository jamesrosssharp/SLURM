//===-- Slurm16RegisterInfo.h - SLURM16 Register Information ----*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16REGISTERINFO_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16REGISTERINFO_H

#include "llvm/CodeGen/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "Slurm16GenRegisterInfo.inc"

namespace llvm {

class Slurm16RegisterInfo : public Slurm16GenRegisterInfo {
public:
  Slurm16RegisterInfo();

  const MCPhysReg *getCalleeSavedRegs(const MachineFunction *MF) const override;
  const uint32_t *getCallPreservedMask(const MachineFunction &MF,
                                       CallingConv::ID CC) const override;

  BitVector getReservedRegs(const MachineFunction &MF) const override;

  const TargetRegisterClass *
  getPointerRegClass(const MachineFunction &MF,
                     unsigned Kind = 0) const override;

  bool eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = nullptr) const override;

  Register getFrameRegister(const MachineFunction &MF) const override;
};

} // namespace llvm

#endif
