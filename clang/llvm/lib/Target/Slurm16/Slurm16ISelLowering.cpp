//===-- Slurm16ISelLowering.cpp - SLURM16 DAG Lowering Implementation -----===//

#include "Slurm16ISelLowering.h"
#include "Slurm16.h"
#include "Slurm16MachineFunctionInfo.h"
#include "Slurm16SelectionDAGInfo.h"
#include "Slurm16Subtarget.h"
#include "Slurm16TargetMachine.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/KnownBits.h"

using namespace llvm;

#define DEBUG_TYPE "slurm16-lower"

Slurm16TargetLowering::Slurm16TargetLowering(const TargetMachine &TM,
                                             const Slurm16Subtarget &STI)
    : TargetLowering(TM), Subtarget(STI) {
  addRegisterClass(MVT::i16, &Slurm16::GPRRegClass);
  computeRegisterProperties(STI.getRegisterInfo());

  setStackPointerRegisterToSaveRestore(Slurm16::R13);
  setBooleanContents(ZeroOrOneBooleanContent);
  setBooleanVectorContents(ZeroOrOneBooleanContent);

  for (MVT VT : MVT::integer_valuetypes()) {
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i1, Promote);
  }

  // Shifts: constant amounts are custom lowered to single bit shifts or
  // multiplies; variable amounts use a loop (custom inserter).
  setOperationAction(ISD::SHL, MVT::i16, Custom);
  setOperationAction(ISD::SRL, MVT::i16, Custom);
  setOperationAction(ISD::SRA, MVT::i16, Custom);
  setOperationAction(ISD::ROTL, MVT::i16, Custom);
  setOperationAction(ISD::ROTR, MVT::i16, Custom);
  setOperationAction(ISD::SHL_PARTS, MVT::i16, Expand);
  setOperationAction(ISD::SRL_PARTS, MVT::i16, Expand);
  setOperationAction(ISD::SRA_PARTS, MVT::i16, Expand);

  setOperationAction(ISD::GlobalAddress, MVT::i16, Custom);
  setOperationAction(ISD::ExternalSymbol, MVT::i16, Custom);
  setOperationAction(ISD::BlockAddress, MVT::i16, Custom);
  setOperationAction(ISD::JumpTable, MVT::i16, Custom);
  setOperationAction(ISD::ConstantPool, MVT::i16, Custom);

  setOperationAction(ISD::BR_JT, MVT::Other, Expand);
  setOperationAction(ISD::BR_CC, MVT::i16, Custom);
  setOperationAction(ISD::BRCOND, MVT::Other, Expand);
  setOperationAction(ISD::SETCC, MVT::i16, Expand);
  setOperationAction(ISD::SELECT, MVT::i16, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::i16, Custom);

  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Legal);

  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i16, Expand);
  setOperationAction(ISD::STACKSAVE, MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE, MVT::Other, Expand);

  setOperationAction(ISD::CTTZ, MVT::i16, Expand);
  setOperationAction(ISD::CTLZ, MVT::i16, Expand);
  setOperationAction(ISD::CTPOP, MVT::i16, Expand);
  setOperationAction(ISD::BSWAP, MVT::i16, Legal);

  // Hardware multiplier: low half, signed high half and unsigned high half.
  setOperationAction(ISD::MUL, MVT::i16, Legal);
  setOperationAction(ISD::MULHS, MVT::i16, Legal);
  setOperationAction(ISD::MULHU, MVT::i16, Legal);
  setOperationAction(ISD::SMUL_LOHI, MVT::i16, Expand);
  setOperationAction(ISD::UMUL_LOHI, MVT::i16, Expand);

  // No divider.
  setOperationAction(ISD::SDIV, MVT::i16, LibCall);
  setOperationAction(ISD::UDIV, MVT::i16, LibCall);
  setOperationAction(ISD::SREM, MVT::i16, LibCall);
  setOperationAction(ISD::UREM, MVT::i16, LibCall);
  setOperationAction(ISD::SDIVREM, MVT::i16, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i16, Expand);

  // Carry arithmetic through the flags register.
  setOperationAction(ISD::ADDC, MVT::i16, Legal);
  setOperationAction(ISD::ADDE, MVT::i16, Legal);
  setOperationAction(ISD::SUBC, MVT::i16, Legal);
  setOperationAction(ISD::SUBE, MVT::i16, Legal);

  setOperationAction(ISD::VASTART, MVT::Other, Custom);
  setOperationAction(ISD::VAARG, MVT::Other, Expand);
  setOperationAction(ISD::VAEND, MVT::Other, Expand);
  setOperationAction(ISD::VACOPY, MVT::Other, Expand);

  setOperationAction(ISD::FRAMEADDR, MVT::i16, Custom);
  setOperationAction(ISD::RETURNADDR, MVT::i16, Custom);

  setMinFunctionAlignment(Align(2));
  setPrefFunctionAlignment(Align(2));

  // Single core, no atomic instructions: atomics become __atomic_* calls.
  setMaxAtomicSizeInBitsSupported(0);

  // Prefer inline expansion of small memory operations.
  MaxStoresPerMemset = 8;
  MaxStoresPerMemcpy = 8;
  MaxStoresPerMemmove = 8;
}

SDValue Slurm16TargetLowering::LowerOperation(SDValue Op,
                                              SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  case ISD::SHL:
  case ISD::SRL:
  case ISD::SRA:
    return LowerShifts(Op, DAG);
  case ISD::ROTL:
  case ISD::ROTR:
    return LowerRotate(Op, DAG);
  case ISD::GlobalAddress:
    return LowerGlobalAddress(Op, DAG);
  case ISD::ExternalSymbol:
    return LowerExternalSymbol(Op, DAG);
  case ISD::BlockAddress:
    return LowerBlockAddress(Op, DAG);
  case ISD::JumpTable:
    return LowerJumpTable(Op, DAG);
  case ISD::ConstantPool:
    return LowerConstantPool(Op, DAG);
  case ISD::BR_CC:
    return LowerBR_CC(Op, DAG);
  case ISD::SELECT_CC:
    return LowerSELECT_CC(Op, DAG);
  case ISD::VASTART:
    return LowerVASTART(Op, DAG);
  case ISD::FRAMEADDR:
    return LowerFRAMEADDR(Op, DAG);
  case ISD::RETURNADDR:
    return LowerRETURNADDR(Op, DAG);
  default:
    llvm_unreachable("unimplemented operation");
  }
}

//===----------------------------------------------------------------------===//
// Shifts
//===----------------------------------------------------------------------===//

/// Shift \p X by the constant \p Amt (1-15) using target nodes, which the
/// DAG combiner leaves alone.
static SDValue lowerConstantShift(unsigned Opc, SDValue X, unsigned Amt,
                                  const SDLoc &DL, SelectionDAG &DAG) {
  EVT VT = X.getValueType();
  switch (Opc) {
  case ISD::SHL:
    if (Amt == 1)
      return DAG.getNode(Slurm16ISD::LSL, DL, VT, X);
    // x << n == x * 2^n
    return DAG.getNode(Slurm16ISD::MULLO, DL, VT, X,
                       DAG.getConstant(1u << Amt, DL, VT));
  case ISD::SRL:
    if (Amt == 1)
      return DAG.getNode(Slurm16ISD::LSR, DL, VT, X);
    // x >>u n == hi16(x *u 2^(16-n))
    return DAG.getNode(Slurm16ISD::UMULHI, DL, VT, X,
                       DAG.getConstant(1u << (16 - Amt), DL, VT));
  case ISD::SRA:
    if (Amt == 1)
      return DAG.getNode(Slurm16ISD::ASR, DL, VT, X);
    // x >>s n == hi16(x *s 2^(16-n)); 2^(16-n) <= 0x4000 is positive.
    return DAG.getNode(Slurm16ISD::SMULHI, DL, VT, X,
                       DAG.getConstant(1u << (16 - Amt), DL, VT));
  }
  llvm_unreachable("unknown shift");
}

SDValue Slurm16TargetLowering::LowerShifts(SDValue Op,
                                           SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  auto *C = dyn_cast<ConstantSDNode>(Op.getOperand(1));
  if (!C)
    return Op; // Selected to a shift loop pseudo.

  SDValue X = Op.getOperand(0);
  uint64_t Amt = C->getZExtValue();
  if (Amt == 0)
    return X;
  if (Amt >= 16)
    return DAG.getUNDEF(VT);
  return lowerConstantShift(Op.getOpcode(), X, Amt, DL, DAG);
}

void Slurm16TargetLowering::computeKnownBitsForTargetNode(
    const SDValue Op, KnownBits &Known, const APInt &DemandedElts,
    const SelectionDAG &DAG, unsigned Depth) const {
  Known.resetAll();
  auto *C = dyn_cast<ConstantSDNode>(Op.getOperand(Op.getNumOperands() - 1));
  switch (Op.getOpcode()) {
  case Slurm16ISD::LSL:
    Known.Zero.setLowBits(1);
    break;
  case Slurm16ISD::LSR:
    Known.Zero.setHighBits(1);
    break;
  case Slurm16ISD::MULLO:
    if (C && C->getAPIntValue().isPowerOf2())
      Known.Zero.setLowBits(C->getAPIntValue().logBase2());
    break;
  case Slurm16ISD::UMULHI:
    if (C && C->getAPIntValue().isPowerOf2())
      Known.Zero.setHighBits(16 - C->getAPIntValue().logBase2());
    break;
  default:
    break;
  }
}

SDValue Slurm16TargetLowering::LowerRotate(SDValue Op,
                                           SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  auto *C = dyn_cast<ConstantSDNode>(Op.getOperand(1));
  if (!C)
    return SDValue(); // Expand.
  unsigned Amt = C->getZExtValue() & 15;
  if (Op.getOpcode() == ISD::ROTR)
    Amt = (16 - Amt) & 15;
  SDValue X = Op.getOperand(0);
  switch (Amt) {
  case 0:
    return X;
  case 1:
    return DAG.getNode(Slurm16ISD::ROL, DL, VT, X);
  case 4:
    return DAG.getNode(Slurm16ISD::RLN, DL, VT, X);
  case 8:
    return DAG.getNode(ISD::BSWAP, DL, VT, X);
  case 12:
    return DAG.getNode(Slurm16ISD::RRN, DL, VT, X);
  default:
    break;
  }
  SDValue Lo = lowerConstantShift(ISD::SHL, X, Amt, DL, DAG);
  SDValue Hi = lowerConstantShift(ISD::SRL, X, 16 - Amt, DL, DAG);
  return DAG.getNode(ISD::OR, DL, VT, Lo, Hi);
}

//===----------------------------------------------------------------------===//
// Addresses
//===----------------------------------------------------------------------===//

SDValue Slurm16TargetLowering::LowerGlobalAddress(SDValue Op,
                                                  SelectionDAG &DAG) const {
  auto *N = cast<GlobalAddressSDNode>(Op);
  SDValue Result = DAG.getTargetGlobalAddress(N->getGlobal(), SDLoc(Op),
                                              MVT::i16, N->getOffset());
  return DAG.getNode(Slurm16ISD::Wrapper, SDLoc(Op), MVT::i16, Result);
}

SDValue Slurm16TargetLowering::LowerExternalSymbol(SDValue Op,
                                                   SelectionDAG &DAG) const {
  const char *Sym = cast<ExternalSymbolSDNode>(Op)->getSymbol();
  SDValue Result = DAG.getTargetExternalSymbol(Sym, MVT::i16);
  return DAG.getNode(Slurm16ISD::Wrapper, SDLoc(Op), MVT::i16, Result);
}

SDValue Slurm16TargetLowering::LowerBlockAddress(SDValue Op,
                                                 SelectionDAG &DAG) const {
  auto *N = cast<BlockAddressSDNode>(Op);
  SDValue Result =
      DAG.getTargetBlockAddress(N->getBlockAddress(), MVT::i16, N->getOffset());
  return DAG.getNode(Slurm16ISD::Wrapper, SDLoc(Op), MVT::i16, Result);
}

SDValue Slurm16TargetLowering::LowerJumpTable(SDValue Op,
                                              SelectionDAG &DAG) const {
  auto *JT = cast<JumpTableSDNode>(Op);
  SDValue Result = DAG.getTargetJumpTable(JT->getIndex(), MVT::i16);
  return DAG.getNode(Slurm16ISD::Wrapper, SDLoc(JT), MVT::i16, Result);
}

SDValue Slurm16TargetLowering::LowerConstantPool(SDValue Op,
                                                 SelectionDAG &DAG) const {
  auto *CP = cast<ConstantPoolSDNode>(Op);
  SDValue Result;
  if (CP->isMachineConstantPoolEntry())
    Result = DAG.getTargetConstantPool(CP->getMachineCPVal(), MVT::i16,
                                       CP->getAlign(), CP->getOffset());
  else
    Result = DAG.getTargetConstantPool(CP->getConstVal(), MVT::i16,
                                       CP->getAlign(), CP->getOffset());
  return DAG.getNode(Slurm16ISD::Wrapper, SDLoc(Op), MVT::i16, Result);
}

//===----------------------------------------------------------------------===//
// Comparisons
//===----------------------------------------------------------------------===//

static Slurm16CC::CondCode getSlurm16CC(ISD::CondCode CC) {
  switch (CC) {
  case ISD::SETEQ:  return Slurm16CC::COND_Z;
  case ISD::SETNE:  return Slurm16CC::COND_NZ;
  case ISD::SETLT:  return Slurm16CC::COND_LT;
  case ISD::SETLE:  return Slurm16CC::COND_LE;
  case ISD::SETGT:  return Slurm16CC::COND_GT;
  case ISD::SETGE:  return Slurm16CC::COND_GE;
  case ISD::SETULT: return Slurm16CC::COND_C;
  case ISD::SETUGE: return Slurm16CC::COND_NC;
  case ISD::SETULE: return Slurm16CC::COND_LEU;
  case ISD::SETUGT: return Slurm16CC::COND_GTU;
  default:
    llvm_unreachable("invalid integer condition code");
  }
}

SDValue Slurm16TargetLowering::getCompare(SDValue LHS, SDValue RHS,
                                          ISD::CondCode CC, SDValue &TargetCC,
                                          const SDLoc &DL,
                                          SelectionDAG &DAG) const {
  // cmp only takes an immediate as its second operand.
  if (isa<ConstantSDNode>(LHS) && !isa<ConstantSDNode>(RHS)) {
    std::swap(LHS, RHS);
    CC = ISD::getSetCCSwappedOperands(CC);
  }
  TargetCC = DAG.getConstant(getSlurm16CC(CC), DL, MVT::i16);
  return DAG.getNode(Slurm16ISD::CMP, DL, MVT::Glue, LHS, RHS);
}

SDValue Slurm16TargetLowering::LowerBR_CC(SDValue Op, SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS = Op.getOperand(2);
  SDValue RHS = Op.getOperand(3);
  SDValue Dest = Op.getOperand(4);
  SDLoc DL(Op);

  SDValue TargetCC;
  SDValue Flag = getCompare(LHS, RHS, CC, TargetCC, DL, DAG);
  return DAG.getNode(Slurm16ISD::BR_CC, DL, MVT::Other, Chain, Dest, TargetCC,
                     Flag);
}

SDValue Slurm16TargetLowering::LowerSELECT_CC(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);
  SDValue TrueV = Op.getOperand(2);
  SDValue FalseV = Op.getOperand(3);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(4))->get();
  SDLoc DL(Op);

  SDValue TargetCC;
  SDValue Flag = getCompare(LHS, RHS, CC, TargetCC, DL, DAG);
  SDValue Ops[] = {TrueV, FalseV, TargetCC, Flag};
  return DAG.getNode(Slurm16ISD::SELECT_CC, DL, Op.getValueType(), Ops);
}

//===----------------------------------------------------------------------===//
// Varargs, frame / return address
//===----------------------------------------------------------------------===//

SDValue Slurm16TargetLowering::LowerVASTART(SDValue Op,
                                            SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  auto *FuncInfo = MF.getInfo<Slurm16MachineFunctionInfo>();
  SDLoc DL(Op);
  SDValue FrameIndex =
      DAG.getFrameIndex(FuncInfo->getVarArgsFrameIndex(), MVT::i16);
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  return DAG.getStore(Op.getOperand(0), DL, FrameIndex, Op.getOperand(1),
                      MachinePointerInfo(SV));
}

SDValue Slurm16TargetLowering::LowerFRAMEADDR(SDValue Op,
                                              SelectionDAG &DAG) const {
  MachineFrameInfo &MFI = DAG.getMachineFunction().getFrameInfo();
  MFI.setFrameAddressIsTaken(true);
  SDLoc DL(Op);
  if (Op.getConstantOperandVal(0) != 0)
    report_fatal_error("SLURM16: __builtin_frame_address only supports "
                       "depth 0");
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, Slurm16::R12, MVT::i16);
}

SDValue Slurm16TargetLowering::LowerRETURNADDR(SDValue Op,
                                               SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MF.getFrameInfo().setReturnAddressIsTaken(true);
  SDLoc DL(Op);
  if (Op.getConstantOperandVal(0) != 0)
    report_fatal_error("SLURM16: __builtin_return_address only supports "
                       "depth 0");
  Register Reg = MF.addLiveIn(Slurm16::R15, &Slurm16::GPRRegClass);
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, Reg, MVT::i16);
}

//===----------------------------------------------------------------------===//
// Calling convention
//===----------------------------------------------------------------------===//

#include "Slurm16GenCallingConv.inc"

SDValue Slurm16TargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();
  auto *FuncInfo = MF.getInfo<Slurm16MachineFunctionInfo>();

  if (MF.getFunction().hasFnAttribute("interrupt") && !Ins.empty())
    report_fatal_error("SLURM16: interrupt handlers cannot have arguments");

  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins,
                                IsVarArg ? CC_Slurm16_Stack : CC_Slurm16);

  if (IsVarArg)
    FuncInfo->setVarArgsFrameIndex(
        MFI.CreateFixedObject(2, CCInfo.getStackSize(), true));

  for (unsigned I = 0, E = ArgLocs.size(); I != E; ++I) {
    CCValAssign &VA = ArgLocs[I];
    SDValue ArgValue;
    if (VA.isRegLoc()) {
      Register VReg = RegInfo.createVirtualRegister(&Slurm16::GPRRegClass);
      RegInfo.addLiveIn(VA.getLocReg(), VReg);
      ArgValue = DAG.getCopyFromReg(Chain, DL, VReg, VA.getLocVT());
    } else {
      assert(VA.isMemLoc());
      ISD::ArgFlagsTy Flags = Ins[I].Flags;
      if (Flags.isByVal()) {
        int FI = MFI.CreateFixedObject(Flags.getByValSize(),
                                       VA.getLocMemOffset(), true);
        InVals.push_back(DAG.getFrameIndex(FI, MVT::i16));
        continue;
      }
      unsigned ObjSize = VA.getLocVT().getStoreSize();
      int FI = MFI.CreateFixedObject(ObjSize, VA.getLocMemOffset(), true);
      SDValue FIN = DAG.getFrameIndex(FI, MVT::i16);
      ArgValue = DAG.getLoad(VA.getLocVT(), DL, Chain, FIN,
                             MachinePointerInfo::getFixedStack(MF, FI));
    }

    if (VA.getLocInfo() == CCValAssign::SExt)
      ArgValue = DAG.getNode(ISD::AssertSext, DL, VA.getLocVT(), ArgValue,
                             DAG.getValueType(VA.getValVT()));
    else if (VA.getLocInfo() == CCValAssign::ZExt)
      ArgValue = DAG.getNode(ISD::AssertZext, DL, VA.getLocVT(), ArgValue,
                             DAG.getValueType(VA.getValVT()));
    if (VA.getLocInfo() != CCValAssign::Full)
      ArgValue = DAG.getNode(ISD::TRUNCATE, DL, VA.getValVT(), ArgValue);
    InVals.push_back(ArgValue);
  }

  return Chain;
}

SDValue Slurm16TargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                         SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  SDLoc &DL = CLI.DL;
  SmallVectorImpl<ISD::OutputArg> &Outs = CLI.Outs;
  SmallVectorImpl<SDValue> &OutVals = CLI.OutVals;
  SmallVectorImpl<ISD::InputArg> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  CallingConv::ID CallConv = CLI.CallConv;
  bool IsVarArg = CLI.IsVarArg;
  MachineFunction &MF = DAG.getMachineFunction();

  CLI.IsTailCall = false;

  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, IsVarArg ? CC_Slurm16_Stack : CC_Slurm16);

  unsigned NumBytes = CCInfo.getStackSize();
  MVT PtrVT = MVT::i16;

  Chain = DAG.getCALLSEQ_START(Chain, NumBytes, 0, DL);

  SmallVector<std::pair<unsigned, SDValue>, 4> RegsToPass;
  SmallVector<SDValue, 12> MemOpChains;
  SDValue StackPtr;

  for (unsigned I = 0, E = ArgLocs.size(); I != E; ++I) {
    CCValAssign &VA = ArgLocs[I];
    SDValue Arg = OutVals[I];

    switch (VA.getLocInfo()) {
    default:
      llvm_unreachable("Unknown loc info!");
    case CCValAssign::Full:
      break;
    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, DL, VA.getLocVT(), Arg);
      break;
    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, DL, VA.getLocVT(), Arg);
      break;
    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, DL, VA.getLocVT(), Arg);
      break;
    }

    if (VA.isRegLoc()) {
      RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
      continue;
    }

    assert(VA.isMemLoc());
    if (!StackPtr.getNode())
      StackPtr = DAG.getCopyFromReg(Chain, DL, Slurm16::R13, PtrVT);
    SDValue PtrOff =
        DAG.getNode(ISD::ADD, DL, PtrVT, StackPtr,
                    DAG.getIntPtrConstant(VA.getLocMemOffset(), DL));
    ISD::ArgFlagsTy Flags = Outs[I].Flags;
    if (Flags.isByVal()) {
      SDValue SizeNode = DAG.getConstant(Flags.getByValSize(), DL, MVT::i16);
      MemOpChains.push_back(DAG.getMemcpy(
          Chain, DL, PtrOff, Arg, SizeNode, Flags.getNonZeroByValAlign(),
          /*isVolatile*/ false, /*AlwaysInline=*/true, /*CI=*/nullptr,
          std::nullopt, MachinePointerInfo(), MachinePointerInfo()));
    } else {
      MemOpChains.push_back(
          DAG.getStore(Chain, DL, Arg, PtrOff, MachinePointerInfo()));
    }
  }

  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, MemOpChains);

  SDValue InGlue;
  for (const auto &[Reg, N] : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg, N, InGlue);
    InGlue = Chain.getValue(1);
  }

  if (auto *G = dyn_cast<GlobalAddressSDNode>(Callee))
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), DL, MVT::i16,
                                        G->getOffset());
  else if (auto *ES = dyn_cast<ExternalSymbolSDNode>(Callee))
    Callee = DAG.getTargetExternalSymbol(ES->getSymbol(), MVT::i16);

  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);
  for (const auto &[Reg, N] : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg, N.getValueType()));

  const TargetRegisterInfo *TRI = Subtarget.getRegisterInfo();
  const uint32_t *Mask = TRI->getCallPreservedMask(MF, CallConv);
  Ops.push_back(DAG.getRegisterMask(Mask));

  if (InGlue.getNode())
    Ops.push_back(InGlue);

  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  Chain = DAG.getNode(Slurm16ISD::CALL, DL, NodeTys, Ops);
  InGlue = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, NumBytes, 0, InGlue, DL);
  InGlue = Chain.getValue(1);

  return LowerCallResult(Chain, InGlue, CallConv, IsVarArg, Ins, DL, DAG,
                         InVals);
}

SDValue Slurm16TargetLowering::LowerCallResult(
    SDValue Chain, SDValue InGlue, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());
  CCInfo.AnalyzeCallResult(Ins, RetCC_Slurm16);

  for (CCValAssign &VA : RVLocs) {
    Chain = DAG.getCopyFromReg(Chain, DL, VA.getLocReg(), VA.getLocVT(), InGlue)
                .getValue(1);
    InGlue = Chain.getValue(2);
    SDValue Val = Chain.getValue(0);
    if (VA.getLocVT() != VA.getValVT())
      Val = DAG.getNode(ISD::TRUNCATE, DL, VA.getValVT(), Val);
    InVals.push_back(Val);
  }
  return Chain;
}

bool Slurm16TargetLowering::CanLowerReturn(
    CallingConv::ID CallConv, MachineFunction &MF, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs, LLVMContext &Context,
    const Type *RetTy) const {
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, Context);
  return CCInfo.CheckReturn(Outs, RetCC_Slurm16);
}

SDValue
Slurm16TargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                                   bool IsVarArg,
                                   const SmallVectorImpl<ISD::OutputArg> &Outs,
                                   const SmallVectorImpl<SDValue> &OutVals,
                                   const SDLoc &DL, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  if (MF.getFunction().hasFnAttribute("interrupt") && !Outs.empty())
    report_fatal_error("SLURM16: interrupt handlers cannot return a value");

  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, *DAG.getContext());
  CCInfo.AnalyzeReturn(Outs, RetCC_Slurm16);

  SDValue Glue;
  SmallVector<SDValue, 4> RetOps(1, Chain);
  for (unsigned I = 0; I != RVLocs.size(); ++I) {
    CCValAssign &VA = RVLocs[I];
    assert(VA.isRegLoc() && "Can only return in registers!");
    SDValue Val = OutVals[I];
    if (VA.getLocInfo() == CCValAssign::SExt)
      Val = DAG.getNode(ISD::SIGN_EXTEND, DL, VA.getLocVT(), Val);
    else if (VA.getLocInfo() == CCValAssign::ZExt)
      Val = DAG.getNode(ISD::ZERO_EXTEND, DL, VA.getLocVT(), Val);
    else if (VA.getLocInfo() == CCValAssign::AExt)
      Val = DAG.getNode(ISD::ANY_EXTEND, DL, VA.getLocVT(), Val);
    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(), Val, Glue);
    Glue = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  RetOps[0] = Chain;
  if (Glue.getNode())
    RetOps.push_back(Glue);
  return DAG.getNode(Slurm16ISD::RET_GLUE, DL, MVT::Other, RetOps);
}

//===----------------------------------------------------------------------===//
// Inline asm
//===----------------------------------------------------------------------===//

TargetLowering::ConstraintType
Slurm16TargetLowering::getConstraintType(StringRef Constraint) const {
  if (Constraint.size() == 1 && Constraint[0] == 'r')
    return C_RegisterClass;
  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass *>
Slurm16TargetLowering::getRegForInlineAsmConstraint(
    const TargetRegisterInfo *TRI, StringRef Constraint, MVT VT) const {
  if (Constraint.size() == 1 && Constraint[0] == 'r')
    return std::make_pair(0U, &Slurm16::GPRRegClass);
  return TargetLowering::getRegForInlineAsmConstraint(TRI, Constraint, VT);
}

bool Slurm16TargetLowering::isLegalAddressingMode(const DataLayout &DL,
                                                  const AddrMode &AM, Type *Ty,
                                                  unsigned AS,
                                                  Instruction *I) const {
  // [reg + imm16], [r0 + global + imm16], [reg + global + imm16]
  if (AM.Scale == 0)
    return isInt<16>(AM.BaseOffs) || isUInt<16>(AM.BaseOffs);
  // A scaled register with no base register is [reg + global + imm].
  if (AM.Scale == 1 && !AM.HasBaseReg)
    return isInt<16>(AM.BaseOffs) || isUInt<16>(AM.BaseOffs);
  return false;
}

//===----------------------------------------------------------------------===//
// Custom inserters
//===----------------------------------------------------------------------===//

/// Return true if the flags are read after \p MI (before being redefined) in
/// its block or are live out of it.
static bool flagsLiveAfter(MachineInstr &MI, MachineBasicBlock *BB) {
  for (MachineBasicBlock::iterator I = std::next(MI.getIterator()),
                                   E = BB->end();
       I != E; ++I) {
    if (I->readsRegister(Slurm16::FLAGS, nullptr))
      return true;
    if (I->definesRegister(Slurm16::FLAGS, nullptr))
      return false;
  }
  for (MachineBasicBlock *Succ : BB->successors())
    if (Succ->isLiveIn(Slurm16::FLAGS))
      return true;
  return false;
}

MachineBasicBlock *
Slurm16TargetLowering::emitSelect(MachineInstr &MI,
                                  MachineBasicBlock *BB) const {
  const TargetInstrInfo &TII = *BB->getParent()->getSubtarget().getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction *F = BB->getParent();
  MachineFunction::iterator It = ++BB->getIterator();

  bool FlagsLive = flagsLiveAfter(MI, BB);

  //  thisMBB:
  //    bcc sinkMBB
  //  copy0MBB:   (fallthrough, false value)
  //  sinkMBB:
  //    dst = phi [true, thisMBB], [false, copy0MBB]
  MachineBasicBlock *ThisMBB = BB;
  MachineBasicBlock *Copy0MBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *SinkMBB = F->CreateMachineBasicBlock(LLVM_BB);
  F->insert(It, Copy0MBB);
  F->insert(It, SinkMBB);

  SinkMBB->splice(SinkMBB->begin(), BB, std::next(MI.getIterator()),
                  BB->end());
  SinkMBB->transferSuccessorsAndUpdatePHIs(BB);

  BB->addSuccessor(Copy0MBB);
  BB->addSuccessor(SinkMBB);
  BuildMI(BB, DL, TII.get(Slurm16::BCC))
      .addMBB(SinkMBB)
      .addImm(MI.getOperand(3).getImm());

  Copy0MBB->addSuccessor(SinkMBB);

  if (FlagsLive) {
    Copy0MBB->addLiveIn(Slurm16::FLAGS);
    SinkMBB->addLiveIn(Slurm16::FLAGS);
  }

  BuildMI(*SinkMBB, SinkMBB->begin(), DL, TII.get(Slurm16::PHI),
          MI.getOperand(0).getReg())
      .addReg(MI.getOperand(1).getReg())
      .addMBB(ThisMBB)
      .addReg(MI.getOperand(2).getReg())
      .addMBB(Copy0MBB);

  MI.eraseFromParent();
  return SinkMBB;
}

MachineBasicBlock *
Slurm16TargetLowering::emitShift(MachineInstr &MI,
                                 MachineBasicBlock *BB) const {
  MachineFunction *F = BB->getParent();
  MachineRegisterInfo &RI = F->getRegInfo();
  const TargetInstrInfo &TII = *F->getSubtarget().getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();

  unsigned Opc;
  switch (MI.getOpcode()) {
  default:
    llvm_unreachable("Invalid shift opcode!");
  case Slurm16::Shl16:
    Opc = Slurm16::LSL;
    break;
  case Slurm16::Srl16:
    Opc = Slurm16::LSR;
    break;
  case Slurm16::Sra16:
    Opc = Slurm16::ASR;
    break;
  }

  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator It = ++BB->getIterator();
  MachineBasicBlock *LoopBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *RemBB = F->CreateMachineBasicBlock(LLVM_BB);
  F->insert(It, LoopBB);
  F->insert(It, RemBB);

  RemBB->splice(RemBB->begin(), BB, std::next(MI.getIterator()), BB->end());
  RemBB->transferSuccessorsAndUpdatePHIs(BB);

  BB->addSuccessor(LoopBB);
  BB->addSuccessor(RemBB);
  LoopBB->addSuccessor(RemBB);
  LoopBB->addSuccessor(LoopBB);

  const TargetRegisterClass *RC = &Slurm16::GPRRegClass;
  Register Cnt = RI.createVirtualRegister(RC);
  Register ShiftReg = RI.createVirtualRegister(RC);
  Register ShiftReg2 = RI.createVirtualRegister(RC);
  Register ShiftAmt = RI.createVirtualRegister(RC);
  Register ShiftAmt2 = RI.createVirtualRegister(RC);
  Register Dst = MI.getOperand(0).getReg();
  Register Src = MI.getOperand(1).getReg();
  Register Amt = MI.getOperand(2).getReg();

  // BB:
  //   cnt = and amt, 15
  //   bz RemBB
  BuildMI(BB, DL, TII.get(Slurm16::ANDri), Cnt).addReg(Amt).addImm(15);
  BuildMI(BB, DL, TII.get(Slurm16::BCC)).addMBB(RemBB).addImm(Slurm16CC::COND_Z);

  // LoopBB:
  //   r  = phi [src, BB], [r2, LoopBB]
  //   n  = phi [cnt, BB], [n2, LoopBB]
  //   r2 = shift r
  //   n2 = sub n, 1
  //   bnz LoopBB
  BuildMI(LoopBB, DL, TII.get(Slurm16::PHI), ShiftReg)
      .addReg(Src)
      .addMBB(BB)
      .addReg(ShiftReg2)
      .addMBB(LoopBB);
  BuildMI(LoopBB, DL, TII.get(Slurm16::PHI), ShiftAmt)
      .addReg(Cnt)
      .addMBB(BB)
      .addReg(ShiftAmt2)
      .addMBB(LoopBB);
  BuildMI(LoopBB, DL, TII.get(Opc), ShiftReg2).addReg(ShiftReg);
  BuildMI(LoopBB, DL, TII.get(Slurm16::SUBri), ShiftAmt2)
      .addReg(ShiftAmt)
      .addImm(1);
  BuildMI(LoopBB, DL, TII.get(Slurm16::BCC))
      .addMBB(LoopBB)
      .addImm(Slurm16CC::COND_NZ);

  // RemBB:
  //   dst = phi [src, BB], [r2, LoopBB]
  BuildMI(*RemBB, RemBB->begin(), DL, TII.get(Slurm16::PHI), Dst)
      .addReg(Src)
      .addMBB(BB)
      .addReg(ShiftReg2)
      .addMBB(LoopBB);

  MI.eraseFromParent();
  return RemBB;
}

MachineBasicBlock *
Slurm16TargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
                                                   MachineBasicBlock *BB) const {
  switch (MI.getOpcode()) {
  case Slurm16::Select16:
    return emitSelect(MI, BB);
  case Slurm16::Shl16:
  case Slurm16::Srl16:
  case Slurm16::Sra16:
    return emitShift(MI, BB);
  default:
    llvm_unreachable("unexpected instruction with custom inserter");
  }
}
