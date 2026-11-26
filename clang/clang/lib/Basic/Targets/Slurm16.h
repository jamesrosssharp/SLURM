//===--- Slurm16.h - Declare SLURM16 target feature support -----*- C++ -*-===//

#ifndef LLVM_CLANG_LIB_BASIC_TARGETS_SLURM16_H
#define LLVM_CLANG_LIB_BASIC_TARGETS_SLURM16_H

#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/TargetOptions.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

namespace clang {
namespace targets {

class LLVM_LIBRARY_VISIBILITY Slurm16TargetInfo : public TargetInfo {
  static const char *const GCCRegNames[];

public:
  Slurm16TargetInfo(const llvm::Triple &Triple, const TargetOptions &)
      : TargetInfo(Triple) {
    TLSSupported = false;
    BigEndian = false;
    BoolWidth = BoolAlign = 8;
    IntWidth = 16;
    IntAlign = 16;
    LongWidth = 32;
    LongLongWidth = 64;
    LongAlign = LongLongAlign = 16;
    ShortWidth = ShortAlign = 16;
    HalfWidth = HalfAlign = 16;
    FloatWidth = 32;
    FloatAlign = 16;
    DoubleWidth = LongDoubleWidth = 64;
    DoubleAlign = LongDoubleAlign = 16;
    LongDoubleFormat = &llvm::APFloat::IEEEdouble();
    PointerWidth = 16;
    PointerAlign = 16;
    SuitableAlign = 16;
    DefaultAlignForAttributeAligned = 16;
    MinGlobalAlign = 8;
    SizeType = UnsignedInt;
    IntMaxType = SignedLongLong;
    IntPtrType = SignedInt;
    PtrDiffType = SignedInt;
    WCharType = SignedInt;
    WIntType = SignedInt;
    Char16Type = UnsignedInt;
    Char32Type = UnsignedLong;
    SigAtomicType = SignedInt;
    MaxAtomicPromoteWidth = MaxAtomicInlineWidth = 0;
    resetDataLayout(
        "e-m:e-p:16:16-i8:8-i16:16-i32:16-i64:16-f32:16-f64:16-a:8-n16-S16");
  }

  void getTargetDefines(const LangOptions &Opts,
                        MacroBuilder &Builder) const override;

  llvm::SmallVector<Builtin::InfosShard> getTargetBuiltins() const override {
    return {};
  }

  bool allowsLargerPreferedTypeAlignment() const override { return false; }

  bool hasFeature(StringRef Feature) const override {
    return Feature == "slurm16";
  }

  ArrayRef<const char *> getGCCRegNames() const override;

  ArrayRef<TargetInfo::GCCRegAlias> getGCCRegAliases() const override {
    static const TargetInfo::GCCRegAlias GCCRegAliases[] = {
        {{"sp"}, "r13"},
        {{"ilr"}, "r14"},
        {{"lr"}, "r15"},
    };
    return llvm::ArrayRef(GCCRegAliases);
  }

  bool validateAsmConstraint(const char *&Name,
                             TargetInfo::ConstraintInfo &Info) const override {
    switch (*Name) {
    case 'I': // Any 16 bit immediate.
      Info.setRequiresImmediate();
      return true;
    }
    return false;
  }

  std::string_view getClobbers() const override { return ""; }

  BuiltinVaListKind getBuiltinVaListKind() const override {
    return TargetInfo::CharPtrBuiltinVaList;
  }

  bool isValidCPUName(StringRef Name) const override {
    return Name == "generic" || Name == "slurm16";
  }
  bool setCPU(const std::string &Name) override {
    return isValidCPUName(Name);
  }
};

} // namespace targets
} // namespace clang

#endif
