//===-- Slurm16MCAsmInfo.h - SLURM16 asm properties -------------*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_MCTARGETDESC_SLURM16MCASMINFO_H
#define LLVM_LIB_TARGET_SLURM16_MCTARGETDESC_SLURM16MCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;

class Slurm16MCAsmInfo : public MCAsmInfoELF {
  void anchor() override;

public:
  explicit Slurm16MCAsmInfo(const Triple &TT);

  // There is no integrated assembler: output is always assembled by
  // slurmasm-ng, and inline asm is passed through verbatim.
  void setUseIntegratedAssembler(bool Value) override {
    MCAsmInfo::setUseIntegratedAssembler(false);
  }
  void setParseInlineAsmUsingAsmParser(bool Value) override {
    MCAsmInfo::setParseInlineAsmUsingAsmParser(false);
  }
};

} // namespace llvm

#endif
