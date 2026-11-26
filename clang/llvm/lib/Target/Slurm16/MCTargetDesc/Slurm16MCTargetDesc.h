//===-- Slurm16MCTargetDesc.h - SLURM16 Target Descriptions -----*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_MCTARGETDESC_SLURM16MCTARGETDESC_H
#define LLVM_LIB_TARGET_SLURM16_MCTARGETDESC_SLURM16MCTARGETDESC_H

#include "llvm/Support/DataTypes.h"
#include <memory>

namespace llvm {
class formatted_raw_ostream;
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstPrinter;
class MCStreamer;

/// Create the streamer that writes slurmasm-ng syntax assembly.
MCStreamer *createSlurm16AsmStreamer(MCContext &Ctx,
                                     std::unique_ptr<formatted_raw_ostream> OS,
                                     std::unique_ptr<MCInstPrinter> IP,
                                     std::unique_ptr<MCCodeEmitter> CE,
                                     std::unique_ptr<MCAsmBackend> TAB);
} // namespace llvm

#define GET_REGINFO_ENUM
#include "Slurm16GenRegisterInfo.inc"

#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_MC_HELPER_DECLS
#include "Slurm16GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "Slurm16GenSubtargetInfo.inc"

#endif
