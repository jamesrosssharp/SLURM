//===-- Slurm16SelectionDAGInfo.h - SLURM16 SelectionDAG Info ---*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16SELECTIONDAGINFO_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16SELECTIONDAGINFO_H

#include "llvm/CodeGen/SelectionDAGTargetInfo.h"

#define GET_SDNODE_ENUM
#include "Slurm16GenSDNodeInfo.inc"

namespace llvm {

class Slurm16SelectionDAGInfo : public SelectionDAGGenTargetInfo {
public:
  Slurm16SelectionDAGInfo();
  ~Slurm16SelectionDAGInfo() override;
};

} // namespace llvm

#endif
