//===-- Slurm16MCTargetDesc.cpp - SLURM16 Target Descriptions -------------===//

#include "Slurm16MCTargetDesc.h"
#include "Slurm16InstPrinter.h"
#include "Slurm16MCAsmInfo.h"
#include "TargetInfo/Slurm16TargetInfo.h"
#include "llvm/MC/MCDwarf.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#define ENABLE_INSTR_PREDICATE_VERIFIER
#include "Slurm16GenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "Slurm16GenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "Slurm16GenRegisterInfo.inc"

static MCInstrInfo *createSlurm16MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitSlurm16MCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createSlurm16MCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitSlurm16MCRegisterInfo(X, Slurm16::R15);
  return X;
}

static MCAsmInfo *createSlurm16MCAsmInfo(const MCRegisterInfo &MRI,
                                         const Triple &TT,
                                         const MCTargetOptions &Options) {
  MCAsmInfo *MAI = new Slurm16MCAsmInfo(TT);
  // CFA = sp on entry.
  MCCFIInstruction Inst = MCCFIInstruction::cfiDefCfa(
      nullptr, MRI.getDwarfRegNum(Slurm16::R13, true), 0);
  MAI->addInitialFrameState(Inst);
  return MAI;
}

static MCSubtargetInfo *
createSlurm16MCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  if (CPU.empty())
    CPU = "generic";
  return createSlurm16MCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU, FS);
}

static MCInstPrinter *createSlurm16MCInstPrinter(const Triple &T,
                                                 unsigned SyntaxVariant,
                                                 const MCAsmInfo &MAI,
                                                 const MCInstrInfo &MII,
                                                 const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new Slurm16InstPrinter(MAI, MII, MRI);
  return nullptr;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeSlurm16TargetMC() {
  Target &T = getTheSlurm16Target();
  TargetRegistry::RegisterMCAsmInfo(T, createSlurm16MCAsmInfo);
  TargetRegistry::RegisterMCInstrInfo(T, createSlurm16MCInstrInfo);
  TargetRegistry::RegisterMCRegInfo(T, createSlurm16MCRegisterInfo);
  TargetRegistry::RegisterMCSubtargetInfo(T, createSlurm16MCSubtargetInfo);
  TargetRegistry::RegisterMCInstPrinter(T, createSlurm16MCInstPrinter);
  TargetRegistry::RegisterAsmStreamer(T, createSlurm16AsmStreamer);
}
