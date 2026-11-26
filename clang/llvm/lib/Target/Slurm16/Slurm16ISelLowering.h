//===-- Slurm16ISelLowering.h - SLURM16 DAG Lowering Interface --*- C++ -*-===//

#ifndef LLVM_LIB_TARGET_SLURM16_SLURM16ISELLOWERING_H
#define LLVM_LIB_TARGET_SLURM16_SLURM16ISELLOWERING_H

#include "Slurm16.h"
#include "Slurm16SelectionDAGInfo.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLowering.h"

namespace llvm {
class Slurm16Subtarget;

class Slurm16TargetLowering : public TargetLowering {
  const Slurm16Subtarget &Subtarget;

public:
  explicit Slurm16TargetLowering(const TargetMachine &TM,
                                 const Slurm16Subtarget &STI);

  MVT getScalarShiftAmountTy(const DataLayout &, EVT) const override {
    return MVT::i16;
  }
  MVT::SimpleValueType getCmpLibcallReturnType() const override {
    return MVT::i16;
  }

  SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;

  void computeKnownBitsForTargetNode(const SDValue Op, KnownBits &Known,
                                     const APInt &DemandedElts,
                                     const SelectionDAG &DAG,
                                     unsigned Depth = 0) const override;

  MachineBasicBlock *
  EmitInstrWithCustomInserter(MachineInstr &MI,
                              MachineBasicBlock *BB) const override;

  ConstraintType getConstraintType(StringRef Constraint) const override;
  std::pair<unsigned, const TargetRegisterClass *>
  getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                               StringRef Constraint, MVT VT) const override;

  bool isLegalICmpImmediate(int64_t Imm) const override { return true; }
  bool isLegalAddImmediate(int64_t Imm) const override { return true; }
  bool isLegalAddressingMode(const DataLayout &DL, const AddrMode &AM,
                             Type *Ty, unsigned AS,
                             Instruction *I = nullptr) const override;

  unsigned getJumpTableEncoding() const override {
    return MachineJumpTableInfo::EK_BlockAddress;
  }

private:
  SDValue LowerShifts(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerRotate(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerExternalSymbol(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBlockAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerJumpTable(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerConstantPool(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBR_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerVASTART(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const;

  SDValue getCompare(SDValue LHS, SDValue RHS, ISD::CondCode CC,
                     SDValue &TargetCC, const SDLoc &DL,
                     SelectionDAG &DAG) const;

  MachineBasicBlock *emitSelect(MachineInstr &MI, MachineBasicBlock *BB) const;
  MachineBasicBlock *emitShift(MachineInstr &MI, MachineBasicBlock *BB) const;

  SDValue LowerFormalArguments(SDValue Chain, CallingConv::ID CallConv,
                               bool IsVarArg,
                               const SmallVectorImpl<ISD::InputArg> &Ins,
                               const SDLoc &DL, SelectionDAG &DAG,
                               SmallVectorImpl<SDValue> &InVals) const override;
  SDValue LowerCall(TargetLowering::CallLoweringInfo &CLI,
                    SmallVectorImpl<SDValue> &InVals) const override;
  bool CanLowerReturn(CallingConv::ID CallConv, MachineFunction &MF,
                      bool IsVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      LLVMContext &Context, const Type *RetTy) const override;
  SDValue LowerReturn(SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      const SmallVectorImpl<SDValue> &OutVals, const SDLoc &DL,
                      SelectionDAG &DAG) const override;
  SDValue LowerCallResult(SDValue Chain, SDValue InGlue,
                          CallingConv::ID CallConv, bool IsVarArg,
                          const SmallVectorImpl<ISD::InputArg> &Ins,
                          const SDLoc &DL, SelectionDAG &DAG,
                          SmallVectorImpl<SDValue> &InVals) const;
};

} // namespace llvm

#endif
