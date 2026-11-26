//===-- Slurm16MachineFunctionInfo.h - SLURM16 function info ----*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16MACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16MACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

class Slurm16MachineFunctionInfo : public MachineFunctionInfo {
  /// Frame index of the start of the variadic argument area.
  int VarArgsFrameIndex = 0;

  /// Virtual register holding the incoming sret pointer.
  Register SRetReturnReg;

public:
  Slurm16MachineFunctionInfo() = default;
  Slurm16MachineFunctionInfo(const Function &F,
                             const TargetSubtargetInfo *STI) {}

  MachineFunctionInfo *
  clone(BumpPtrAllocator &Allocator, MachineFunction &DestMF,
        const DenseMap<MachineBasicBlock *, MachineBasicBlock *> &Src2DstMBB)
      const override {
    return DestMF.cloneInfo<Slurm16MachineFunctionInfo>(*this);
  }

  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }

  Register getSRetReturnReg() const { return SRetReturnReg; }
  void setSRetReturnReg(Register Reg) { SRetReturnReg = Reg; }
};

} // namespace llvm

#endif
