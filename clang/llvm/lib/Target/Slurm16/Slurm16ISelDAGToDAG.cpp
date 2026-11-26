//===-- Slurm16ISelDAGToDAG.cpp - A dag to dag inst selector for SLURM16 --===//

#include "Slurm16.h"
#include "Slurm16SelectionDAGInfo.h"
#include "Slurm16TargetMachine.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "slurm16-isel"
#define PASS_NAME "SLURM16 DAG->DAG Pattern Instruction Selection"

namespace {
class Slurm16DAGToDAGISel : public SelectionDAGISel {
public:
  Slurm16DAGToDAGISel() = delete;
  Slurm16DAGToDAGISel(Slurm16TargetMachine &TM, CodeGenOptLevel OptLevel)
      : SelectionDAGISel(TM, OptLevel) {}

private:
#include "Slurm16GenDAGISel.inc"

  void Select(SDNode *N) override;
  bool SelectAddr(SDValue Addr, SDValue &Base, SDValue &Disp);
  bool SelectInlineAsmMemoryOperand(const SDValue &Op,
                                    InlineAsm::ConstraintCode ConstraintID,
                                    std::vector<SDValue> &OutOps) override;
  bool getSymbolDisp(SDValue N, int64_t Offset, SDValue &Disp);
};

class Slurm16DAGToDAGISelLegacy : public SelectionDAGISelLegacy {
public:
  static char ID;
  Slurm16DAGToDAGISelLegacy(Slurm16TargetMachine &TM, CodeGenOptLevel OptLevel)
      : SelectionDAGISelLegacy(
            ID, std::make_unique<Slurm16DAGToDAGISel>(TM, OptLevel)) {}
};
} // namespace

char Slurm16DAGToDAGISelLegacy::ID;

INITIALIZE_PASS(Slurm16DAGToDAGISelLegacy, DEBUG_TYPE, PASS_NAME, false, false)

FunctionPass *llvm::createSlurm16ISelDag(Slurm16TargetMachine &TM,
                                         CodeGenOptLevel OptLevel) {
  return new Slurm16DAGToDAGISelLegacy(TM, OptLevel);
}

/// If N is a Wrapper around a symbol, produce a target symbol displacement
/// with \p Offset added.
bool Slurm16DAGToDAGISel::getSymbolDisp(SDValue N, int64_t Offset,
                                        SDValue &Disp) {
  if (N.getOpcode() != Slurm16ISD::Wrapper)
    return false;
  SDValue Sym = N.getOperand(0);
  SDLoc DL(N);
  if (auto *G = dyn_cast<GlobalAddressSDNode>(Sym)) {
    Disp = CurDAG->getTargetGlobalAddress(G->getGlobal(), DL, MVT::i16,
                                          G->getOffset() + Offset);
    return true;
  }
  if (auto *CP = dyn_cast<ConstantPoolSDNode>(Sym)) {
    if (CP->isMachineConstantPoolEntry())
      Disp = CurDAG->getTargetConstantPool(CP->getMachineCPVal(), MVT::i16,
                                           CP->getAlign(),
                                           CP->getOffset() + Offset);
    else
      Disp = CurDAG->getTargetConstantPool(CP->getConstVal(), MVT::i16,
                                           CP->getAlign(),
                                           CP->getOffset() + Offset);
    return true;
  }
  if (Offset != 0)
    return false;
  if (isa<ExternalSymbolSDNode>(Sym) || isa<JumpTableSDNode>(Sym) ||
      isa<BlockAddressSDNode>(Sym)) {
    Disp = Sym;
    return true;
  }
  return false;
}

/// Addressing mode: [reg + disp], where disp is a 16 bit constant or a
/// symbol (+ constant). Absolute addresses use r0 as the base.
bool Slurm16DAGToDAGISel::SelectAddr(SDValue N, SDValue &Base, SDValue &Disp) {
  SDLoc DL(N);
  SDValue R0 = CurDAG->getRegister(Slurm16::R0, MVT::i16);

  if (auto *FIN = dyn_cast<FrameIndexSDNode>(N)) {
    Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), MVT::i16);
    Disp = CurDAG->getTargetConstant(0, DL, MVT::i16);
    return true;
  }

  if (getSymbolDisp(N, 0, Disp)) {
    Base = R0;
    return true;
  }

  if (auto *C = dyn_cast<ConstantSDNode>(N)) {
    Base = R0;
    Disp = CurDAG->getSignedTargetConstant((int16_t)C->getSExtValue(), DL, MVT::i16);
    return true;
  }

  if (CurDAG->isBaseWithConstantOffset(N)) {
    SDValue Op0 = N.getOperand(0);
    int64_t Off = cast<ConstantSDNode>(N.getOperand(1))->getSExtValue();
    if (auto *FIN = dyn_cast<FrameIndexSDNode>(Op0)) {
      Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), MVT::i16);
      Disp = CurDAG->getSignedTargetConstant((int16_t)Off, DL, MVT::i16);
      return true;
    }
    if (getSymbolDisp(Op0, Off, Disp)) {
      Base = R0;
      return true;
    }
    // (add (add reg, sym), const)
    if (Op0.getOpcode() == ISD::ADD) {
      for (unsigned I = 0; I < 2; ++I)
        if (getSymbolDisp(Op0.getOperand(I), Off, Disp)) {
          Base = Op0.getOperand(1 - I);
          return true;
        }
    }
    Base = Op0;
    Disp = CurDAG->getSignedTargetConstant((int16_t)Off, DL, MVT::i16);
    return true;
  }

  // (add reg, sym)
  if (N.getOpcode() == ISD::ADD) {
    for (unsigned I = 0; I < 2; ++I)
      if (getSymbolDisp(N.getOperand(I), 0, Disp)) {
        Base = N.getOperand(1 - I);
        return true;
      }
  }

  Base = N;
  Disp = CurDAG->getTargetConstant(0, DL, MVT::i16);
  return true;
}

bool Slurm16DAGToDAGISel::SelectInlineAsmMemoryOperand(
    const SDValue &Op, InlineAsm::ConstraintCode ConstraintID,
    std::vector<SDValue> &OutOps) {
  SDValue Op0, Op1;
  switch (ConstraintID) {
  default:
    return true;
  case InlineAsm::ConstraintCode::m:
    if (!SelectAddr(Op, Op0, Op1))
      return true;
    break;
  }
  OutOps.push_back(Op0);
  OutOps.push_back(Op1);
  return false;
}

void Slurm16DAGToDAGISel::Select(SDNode *Node) {
  SDLoc DL(Node);

  if (Node->isMachineOpcode()) {
    Node->setNodeId(-1);
    return;
  }

  switch (Node->getOpcode()) {
  default:
    break;
  case ISD::FrameIndex: {
    int FI = cast<FrameIndexSDNode>(Node)->getIndex();
    SDValue TFI = CurDAG->getTargetFrameIndex(FI, MVT::i16);
    SDValue Zero = CurDAG->getTargetConstant(0, DL, MVT::i16);
    if (Node->hasOneUse()) {
      CurDAG->SelectNodeTo(Node, Slurm16::ADDframe, MVT::i16, TFI, Zero);
      return;
    }
    ReplaceNode(Node, CurDAG->getMachineNode(Slurm16::ADDframe, DL, MVT::i16,
                                             TFI, Zero));
    return;
  }
  }

  SelectCode(Node);
}
