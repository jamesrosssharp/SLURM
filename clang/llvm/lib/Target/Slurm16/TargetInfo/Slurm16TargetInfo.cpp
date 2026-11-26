//===-- Slurm16TargetInfo.cpp - SLURM16 Target Implementation -------------===//

#include "TargetInfo/Slurm16TargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

Target &llvm::getTheSlurm16Target() {
  static Target TheSlurm16Target;
  return TheSlurm16Target;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeSlurm16TargetInfo() {
  RegisterTarget<Triple::slurm16> X(getTheSlurm16Target(), "slurm16",
                                    "SLURM16 [experimental]", "Slurm16");
}
