//===-- Slurm16TargetMachine.h - Define TargetMachine for SLURM16 -*- C++ -*-=//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16TARGETMACHINE_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16TARGETMACHINE_H

#include "Slurm16Subtarget.h"
#include "llvm/CodeGen/CodeGenTargetMachineImpl.h"
#include <optional>

namespace llvm {

class Slurm16TargetMachine : public CodeGenTargetMachineImpl {
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
  Slurm16Subtarget Subtarget;

public:
  Slurm16TargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                       StringRef FS, const TargetOptions &Options,
                       std::optional<Reloc::Model> RM,
                       std::optional<CodeModel::Model> CM, CodeGenOptLevel OL,
                       bool JIT);
  ~Slurm16TargetMachine() override;

  const Slurm16Subtarget *getSubtargetImpl(const Function &F) const override {
    return &Subtarget;
  }

  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }

  MachineFunctionInfo *
  createMachineFunctionInfo(BumpPtrAllocator &Allocator, const Function &F,
                            const TargetSubtargetInfo *STI) const override;
};

} // namespace llvm

#endif
