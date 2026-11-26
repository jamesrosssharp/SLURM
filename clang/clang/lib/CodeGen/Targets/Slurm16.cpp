//===- Slurm16.cpp - SLURM16 ABI implementation ---------------------------===//
//
// Argument classification is the generic one (aggregates are passed byval,
// i.e. copied onto the stack). va_list is a char pointer into the stack
// argument area, where every variadic argument (including byval aggregates)
// is stored inline in 2 byte aligned slots.
//
//===----------------------------------------------------------------------===//

#include "ABIInfoImpl.h"
#include "TargetInfo.h"

using namespace clang;
using namespace clang::CodeGen;

namespace {

class Slurm16ABIInfo : public DefaultABIInfo {
public:
  Slurm16ABIInfo(CodeGenTypes &CGT) : DefaultABIInfo(CGT) {}

  RValue EmitVAArg(CodeGenFunction &CGF, Address VAListAddr, QualType Ty,
                   AggValueSlot Slot) const override {
    return emitVoidPtrVAArg(CGF, VAListAddr, Ty, /*IsIndirect=*/false,
                            getContext().getTypeInfoInChars(Ty),
                            CharUnits::fromQuantity(2),
                            /*AllowHigherAlign=*/false, Slot);
  }
};

class Slurm16TargetCodeGenInfo : public TargetCodeGenInfo {
public:
  Slurm16TargetCodeGenInfo(CodeGenTypes &CGT)
      : TargetCodeGenInfo(std::make_unique<Slurm16ABIInfo>(CGT)) {}
};

} // namespace

std::unique_ptr<TargetCodeGenInfo>
CodeGen::createSlurm16TargetCodeGenInfo(CodeGenModule &CGM) {
  return std::make_unique<Slurm16TargetCodeGenInfo>(CGM.getTypes());
}
