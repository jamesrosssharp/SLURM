//===-- Slurm16.h - Top-level interface for SLURM16 -------------*- C++ -*-===//
//
// Entry points for the SLURM16 back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16_H

#include "MCTargetDesc/Slurm16MCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace Slurm16CC {
// Condition codes, encoded exactly as the BRNCH field of SLURM16 branch
// instructions (and the COND field of conditional moves).
enum CondCode {
  COND_Z = 0,    // Z           (eq)
  COND_NZ = 1,   // !Z          (ne)
  COND_S = 2,    // S
  COND_NS = 3,   // !S
  COND_C = 4,    // C           (ltu)
  COND_NC = 5,   // !C          (geu)
  COND_V = 6,    // V
  COND_NV = 7,   // !V
  COND_LT = 8,   // S ^ V
  COND_LE = 9,   // Z | (S ^ V)
  COND_GT = 10,  // !Z & (S == V)
  COND_GE = 11,  // S == V
  COND_LEU = 12, // C | Z
  COND_GTU = 13, // !C & !Z
  COND_INVALID = -1
};

inline CondCode getOppositeCondition(CondCode CC) {
  switch (CC) {
  case COND_Z:   return COND_NZ;
  case COND_NZ:  return COND_Z;
  case COND_S:   return COND_NS;
  case COND_NS:  return COND_S;
  case COND_C:   return COND_NC;
  case COND_NC:  return COND_C;
  case COND_V:   return COND_NV;
  case COND_NV:  return COND_V;
  case COND_LT:  return COND_GE;
  case COND_GE:  return COND_LT;
  case COND_LE:  return COND_GT;
  case COND_GT:  return COND_LE;
  case COND_LEU: return COND_GTU;
  case COND_GTU: return COND_LEU;
  default:       return COND_INVALID;
  }
}

inline const char *getCondName(int CC) {
  switch (CC) {
  case COND_Z:   return "z";
  case COND_NZ:  return "nz";
  case COND_S:   return "s";
  case COND_NS:  return "ns";
  case COND_C:   return "ltu";
  case COND_NC:  return "geu";
  case COND_V:   return "v";
  case COND_NV:  return "nv";
  case COND_LT:  return "lt";
  case COND_LE:  return "le";
  case COND_GT:  return "gt";
  case COND_GE:  return "ge";
  case COND_LEU: return "leu";
  case COND_GTU: return "gtu";
  default:       return "<invalid>";
  }
}
} // namespace Slurm16CC

namespace llvm {
class FunctionPass;
class Slurm16TargetMachine;
class PassRegistry;

FunctionPass *createSlurm16ISelDag(Slurm16TargetMachine &TM,
                                   CodeGenOptLevel OptLevel);

void initializeSlurm16AsmPrinterPass(PassRegistry &);
void initializeSlurm16DAGToDAGISelLegacyPass(PassRegistry &);

} // namespace llvm

#endif
