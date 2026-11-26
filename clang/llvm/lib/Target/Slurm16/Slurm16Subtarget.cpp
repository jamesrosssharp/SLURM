//===-- Slurm16Subtarget.cpp - SLURM16 Subtarget Information --------------===//

#include "Slurm16Subtarget.h"
#include "Slurm16SelectionDAGInfo.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "slurm16-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "Slurm16GenSubtargetInfo.inc"

void Slurm16Subtarget::anchor() {}

Slurm16Subtarget &
Slurm16Subtarget::initializeSubtargetDependencies(StringRef CPU, StringRef FS) {
  StringRef CPUName = CPU;
  if (CPUName.empty())
    CPUName = "generic";
  ParseSubtargetFeatures(CPUName, /*TuneCPU*/ CPUName, FS);
  return *this;
}

Slurm16Subtarget::Slurm16Subtarget(const Triple &TT, const std::string &CPU,
                                   const std::string &FS,
                                   const TargetMachine &TM)
    : Slurm16GenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS),
      InstrInfo(initializeSubtargetDependencies(CPU, FS)),
      FrameLowering(*this), TLInfo(TM, *this) {
  TSInfo = std::make_unique<Slurm16SelectionDAGInfo>();
}

Slurm16Subtarget::~Slurm16Subtarget() = default;

const SelectionDAGTargetInfo *Slurm16Subtarget::getSelectionDAGInfo() const {
  return TSInfo.get();
}
