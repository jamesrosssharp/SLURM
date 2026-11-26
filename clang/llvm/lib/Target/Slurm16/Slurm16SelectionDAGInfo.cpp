//===-- Slurm16SelectionDAGInfo.cpp - SLURM16 SelectionDAG Info -----------===//

#include "Slurm16SelectionDAGInfo.h"

#define GET_SDNODE_DESC
#include "Slurm16GenSDNodeInfo.inc"

using namespace llvm;

Slurm16SelectionDAGInfo::Slurm16SelectionDAGInfo()
    : SelectionDAGGenTargetInfo(Slurm16GenSDNodeInfo) {}

Slurm16SelectionDAGInfo::~Slurm16SelectionDAGInfo() = default;
