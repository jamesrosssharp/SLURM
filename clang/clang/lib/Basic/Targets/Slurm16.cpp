//===--- Slurm16.cpp - Implement SLURM16 target feature support -----------===//

#include "Slurm16.h"
#include "clang/Basic/MacroBuilder.h"

using namespace clang;
using namespace clang::targets;

const char *const Slurm16TargetInfo::GCCRegNames[] = {
    "r0", "r1", "r2",  "r3",  "r4",  "r5",  "r6",  "r7",
    "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15"};

ArrayRef<const char *> Slurm16TargetInfo::getGCCRegNames() const {
  return llvm::ArrayRef(GCCRegNames);
}

void Slurm16TargetInfo::getTargetDefines(const LangOptions &Opts,
                                         MacroBuilder &Builder) const {
  Builder.defineMacro("__slurm16__");
  Builder.defineMacro("__SLURM16__");
  Builder.defineMacro("__ELF__");
  // There is no hardware floating point.
  Builder.defineMacro("__SOFTFP__");
}
