//===-- Slurm16TargetMachine.cpp - Define TargetMachine for SLURM16 -------===//

#include "Slurm16TargetMachine.h"
#include "Slurm16.h"
#include "Slurm16MachineFunctionInfo.h"
#include "TargetInfo/Slurm16TargetInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include <optional>

using namespace llvm;

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeSlurm16Target() {
  RegisterTargetMachine<Slurm16TargetMachine> X(getTheSlurm16Target());
  PassRegistry &PR = *PassRegistry::getPassRegistry();
  initializeSlurm16AsmPrinterPass(PR);
  initializeSlurm16DAGToDAGISelLegacyPass(PR);
}

static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::Static);
}

// Little endian, ELF mangling, 16 bit pointers, 16 bit max alignment.
static const char *Slurm16DataLayout =
    "e-m:e-p:16:16-i8:8-i16:16-i32:16-i64:16-f32:16-f64:16-a:8-n16-S16";

Slurm16TargetMachine::Slurm16TargetMachine(const Target &T, const Triple &TT,
                                           StringRef CPU, StringRef FS,
                                           const TargetOptions &Options,
                                           std::optional<Reloc::Model> RM,
                                           std::optional<CodeModel::Model> CM,
                                           CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, Slurm16DataLayout, TT, CPU, FS, Options,
                               getEffectiveRelocModel(RM),
                               getEffectiveCodeModel(CM, CodeModel::Small), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()),
      Subtarget(TT, std::string(CPU), std::string(FS), *this) {
  initAsmInfo();
}

Slurm16TargetMachine::~Slurm16TargetMachine() = default;

namespace {
class Slurm16PassConfig : public TargetPassConfig {
public:
  Slurm16PassConfig(Slurm16TargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  Slurm16TargetMachine &getSlurm16TargetMachine() const {
    return getTM<Slurm16TargetMachine>();
  }

  void addIRPasses() override;
  bool addInstSelector() override;
};
} // namespace

TargetPassConfig *Slurm16TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new Slurm16PassConfig(*this, PM);
}

MachineFunctionInfo *Slurm16TargetMachine::createMachineFunctionInfo(
    BumpPtrAllocator &Allocator, const Function &F,
    const TargetSubtargetInfo *STI) const {
  return Slurm16MachineFunctionInfo::create<Slurm16MachineFunctionInfo>(
      Allocator, F, STI);
}

void Slurm16PassConfig::addIRPasses() {
  addPass(createAtomicExpandLegacyPass());
  TargetPassConfig::addIRPasses();
}

bool Slurm16PassConfig::addInstSelector() {
  addPass(createSlurm16ISelDag(getSlurm16TargetMachine(), getOptLevel()));
  return false;
}
