//===-- Slurm16InstrInfo.td - SLURM16 Instruction defs -----*- tablegen -*-===//
//
// SLURM16 instructions.
//
// The assembly syntax printed here is the syntax accepted by slurmasm-ng.
// Instructions taking a 16 bit immediate are encoded by the assembler as an
// optional "imm" prefix (when the value does not fit in 4 unsigned bits, or is
// a relocatable expression) followed by the instruction proper, hence those
// instructions are given a worst case size of 4 bytes.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format
//===----------------------------------------------------------------------===//

class Slurm16Inst<dag outs, dag ins, string asmstr, list<dag> pattern,
                  int size = 2>
    : Instruction {
  let Namespace = "Slurm16";
  let OutOperandList = outs;
  let InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
  let Size = size;
  let hasSideEffects = 0;
}

class Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Slurm16Inst<outs, ins, asmstr, pattern, 0> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}

//===----------------------------------------------------------------------===//
// Type profiles and DAG nodes
//===----------------------------------------------------------------------===//

def SDT_Slurm16Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_Slurm16CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>,
                                              SDTCisVT<1, i16>]>;
def SDT_Slurm16CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>,
                                            SDTCisVT<1, i16>]>;
def SDT_Slurm16Wrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                   SDTCisPtrTy<0>]>;
def SDT_Slurm16Cmp          : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>,
                                                   SDTCisVT<0, i16>]>;
def SDT_Slurm16BrCC         : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                                   SDTCisVT<1, i16>]>;
def SDT_Slurm16SelectCC     : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                                   SDTCisSameAs<1, 2>,
                                                   SDTCisVT<3, i16>]>;
def SDT_Slurm16Unary        : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                   SDTCisVT<0, i16>]>;
def SDT_Slurm16Binary       : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                   SDTCisSameAs<0, 2>,
                                                   SDTCisVT<0, i16>]>;

def Slurm16retglue : SDNode<"Slurm16ISD::RET_GLUE", SDTNone,
                            [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def Slurm16call    : SDNode<"Slurm16ISD::CALL", SDT_Slurm16Call,
                            [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                             SDNPVariadic]>;
def Slurm16callseq_start : SDNode<"ISD::CALLSEQ_START",
                                  SDT_Slurm16CallSeqStart,
                                  [SDNPHasChain, SDNPOutGlue]>;
def Slurm16callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_Slurm16CallSeqEnd,
                                  [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def Slurm16Wrapper  : SDNode<"Slurm16ISD::Wrapper", SDT_Slurm16Wrapper>;
def Slurm16cmp      : SDNode<"Slurm16ISD::CMP", SDT_Slurm16Cmp, [SDNPOutGlue]>;
def Slurm16brcc     : SDNode<"Slurm16ISD::BR_CC", SDT_Slurm16BrCC,
                             [SDNPHasChain, SDNPInGlue]>;
def Slurm16selectcc : SDNode<"Slurm16ISD::SELECT_CC", SDT_Slurm16SelectCC,
                             [SDNPInGlue]>;

// Single bit shifts / rotates.
def Slurm16lsl : SDNode<"Slurm16ISD::LSL", SDT_Slurm16Unary>;
def Slurm16lsr : SDNode<"Slurm16ISD::LSR", SDT_Slurm16Unary>;
def Slurm16asr : SDNode<"Slurm16ISD::ASR", SDT_Slurm16Unary>;
def Slurm16rol : SDNode<"Slurm16ISD::ROL", SDT_Slurm16Unary>;
// Nibble rotates.
def Slurm16rln : SDNode<"Slurm16ISD::RLN", SDT_Slurm16Unary>;
def Slurm16rrn : SDNode<"Slurm16ISD::RRN", SDT_Slurm16Unary>;
// High half of a multiply. Used to implement constant right shifts. These are
// separate from ISD::MULHU / ISD::MULHS so that the DAG combiner does not turn
// them back into shifts.
def Slurm16umulhi : SDNode<"Slurm16ISD::UMULHI", SDT_Slurm16Binary>;
def Slurm16mullo  : SDNode<"Slurm16ISD::MULLO", SDT_Slurm16Binary>;
def Slurm16smulhi : SDNode<"Slurm16ISD::SMULHI", SDT_Slurm16Binary>;

//===----------------------------------------------------------------------===//
// Operands
//===----------------------------------------------------------------------===//

def imm16 : Operand<i16> {
  let PrintMethod = "printImmOperand";
}

def brtarget : Operand<OtherVT>;
def calltarget : Operand<i16>;

def memsrc : Operand<i16> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops GPR, imm16);
}

def cc : Operand<i16> {
  let PrintMethod = "printCCOperand";
}

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;

//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//

let Defs = [R13], Uses = [R13] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "# ADJCALLSTACKDOWN $amt1 $amt2",
                              [(Slurm16callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "# ADJCALLSTACKUP $amt1 $amt2",
                              [(Slurm16callseq_end timm:$amt1, timm:$amt2)]>;
}

// dst = address of frame object (expanded by eliminateFrameIndex into
// "mov dst, sp; add dst, offset").
let Defs = [FLAGS] in
def ADDframe : Pseudo<(outs GPR:$dst), (ins i16imm:$base, i16imm:$offset),
                      "# ADDframe PSEUDO", []>;

let usesCustomInserter = 1 in {
  let Uses = [FLAGS] in
  def Select16 : Pseudo<(outs GPR:$dst),
                        (ins GPR:$src, GPR:$src2, i16imm:$cc),
                        "# Select16 PSEUDO",
                        [(set GPR:$dst,
                          (Slurm16selectcc GPR:$src, GPR:$src2, imm:$cc))]>;
  let Defs = [FLAGS] in {
  def Shl16 : Pseudo<(outs GPR:$dst), (ins GPR:$src, GPR:$cnt),
                     "# Shl16 PSEUDO",
                     [(set GPR:$dst, (shl GPR:$src, GPR:$cnt))]>;
  def Srl16 : Pseudo<(outs GPR:$dst), (ins GPR:$src, GPR:$cnt),
                     "# Srl16 PSEUDO",
                     [(set GPR:$dst, (srl GPR:$src, GPR:$cnt))]>;
  def Sra16 : Pseudo<(outs GPR:$dst), (ins GPR:$src, GPR:$cnt),
                     "# Sra16 PSEUDO",
                     [(set GPR:$dst, (sra GPR:$src, GPR:$cnt))]>;
  }
}

//===----------------------------------------------------------------------===//
// Moves
//===----------------------------------------------------------------------===//

// "mov" does not affect the flags.
let isMoveReg = 1 in
def MOVrr : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs), "mov $rd, $rs", []>;

let isReMaterializable = 1, isAsCheapAsAMove = 1, isMoveImm = 1 in
def MOVri : Slurm16Inst<(outs GPR:$rd), (ins imm16:$imm), "mov $rd, $imm",
                        [(set GPR:$rd, imm:$imm)], 4>;

def : Pat<(i16 (Slurm16Wrapper tglobaladdr:$a)),   (MOVri tglobaladdr:$a)>;
def : Pat<(i16 (Slurm16Wrapper texternalsym:$a)),  (MOVri texternalsym:$a)>;
def : Pat<(i16 (Slurm16Wrapper tblockaddress:$a)), (MOVri tblockaddress:$a)>;
def : Pat<(i16 (Slurm16Wrapper tjumptable:$a)),    (MOVri tjumptable:$a)>;
def : Pat<(i16 (Slurm16Wrapper tconstpool:$a)),    (MOVri tconstpool:$a)>;

//===----------------------------------------------------------------------===//
// ALU operations
//===----------------------------------------------------------------------===//

// Two address register-register and register-immediate ALU operations.
multiclass ALU2<string opstr, SDPatternOperator node, bit commutes,
                list<Register> uses = []> {
  let Defs = [FLAGS], Uses = uses, Constraints = "$rd = $rs1" in {
    let isCommutable = commutes in
    def rr : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
                         opstr # " $rd, $rs2",
                         [(set GPR:$rd, (node GPR:$rs1, GPR:$rs2))]>;
    def ri : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs1, imm16:$imm),
                         opstr # " $rd, $imm",
                         [(set GPR:$rd, (node GPR:$rs1, imm:$imm))], 4>;
  }
}

defm ADD   : ALU2<"add",   add,  1>;
defm ADC   : ALU2<"adc",   adde, 1, [FLAGS]>;
defm SUB   : ALU2<"sub",   sub,  0>;
defm SBB   : ALU2<"sbb",   sube, 0, [FLAGS]>;
defm AND   : ALU2<"and",   and,  1>;
defm OR    : ALU2<"or",    or,   1>;
defm XOR   : ALU2<"xor",   xor,  1>;
defm MUL   : ALU2<"mul",   mul,  1>;
defm MULU  : ALU2<"mulu",  mulhs, 1>;
defm UMULU : ALU2<"umulu", mulhu, 1>;

// Add / sub always produce carry.
def : Pat<(addc GPR:$a, GPR:$b), (ADDrr GPR:$a, GPR:$b)>;
def : Pat<(addc GPR:$a, imm:$b), (ADDri GPR:$a, imm:$b)>;
def : Pat<(subc GPR:$a, GPR:$b), (SUBrr GPR:$a, GPR:$b)>;
def : Pat<(subc GPR:$a, imm:$b), (SUBri GPR:$a, imm:$b)>;

// Symbolic immediates.
def : Pat<(add GPR:$a, (Slurm16Wrapper tglobaladdr:$g)),
          (ADDri GPR:$a, tglobaladdr:$g)>;
def : Pat<(add GPR:$a, (Slurm16Wrapper texternalsym:$g)),
          (ADDri GPR:$a, texternalsym:$g)>;
def : Pat<(add GPR:$a, (Slurm16Wrapper tconstpool:$g)),
          (ADDri GPR:$a, tconstpool:$g)>;
def : Pat<(add GPR:$a, (Slurm16Wrapper tjumptable:$g)),
          (ADDri GPR:$a, tjumptable:$g)>;

// Multiplies used to implement constant shifts.
def : Pat<(Slurm16mullo GPR:$a, imm:$b), (MULri GPR:$a, imm:$b)>;
def : Pat<(Slurm16umulhi GPR:$a, imm:$b), (UMULUri GPR:$a, imm:$b)>;
def : Pat<(Slurm16smulhi GPR:$a, imm:$b), (MULUri GPR:$a, imm:$b)>;
def : Pat<(Slurm16umulhi GPR:$a, GPR:$b), (UMULUrr GPR:$a, GPR:$b)>;
def : Pat<(Slurm16smulhi GPR:$a, GPR:$b), (MULUrr GPR:$a, GPR:$b)>;

// Compare / test.
let Defs = [FLAGS] in {
def CMPrr : Slurm16Inst<(outs), (ins GPR:$a, GPR:$b), "cmp $a, $b",
                        [(Slurm16cmp GPR:$a, GPR:$b)]>;
def CMPri : Slurm16Inst<(outs), (ins GPR:$a, imm16:$imm), "cmp $a, $imm",
                        [(Slurm16cmp GPR:$a, imm:$imm)], 4>;
def TESTrr : Slurm16Inst<(outs), (ins GPR:$a, GPR:$b), "test $a, $b", []>;
def TESTri : Slurm16Inst<(outs), (ins GPR:$a, imm16:$imm), "test $a, $imm",
                         [], 4>;
}

// Unary register-register operations: rd <- f(rs). These do not modify the
// flags.
def BSWAPrr : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs), "bswap $rd, $rs",
                          [(set GPR:$rd, (bswap GPR:$rs))]>;
def RLNrr   : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs), "rln $rd, $rs",
                          [(set GPR:$rd, (Slurm16rln GPR:$rs))]>;
def RRNrr   : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs), "rrn $rd, $rs",
                          [(set GPR:$rd, (Slurm16rrn GPR:$rs))]>;

// Single register operations (operate in place).
class ALU1<string opstr, SDPatternOperator node>
    : Slurm16Inst<(outs GPR:$rd), (ins GPR:$rs), opstr # " $rd",
                  [(set GPR:$rd, (node GPR:$rs))]> {
  let Constraints = "$rd = $rs";
  let Defs = [FLAGS];
}

def LSL : ALU1<"lsl", Slurm16lsl>;
def LSR : ALU1<"lsr", Slurm16lsr>;
def ASR : ALU1<"asr", Slurm16asr>;
def ROL : ALU1<"rol", Slurm16rol>;

let Uses = [FLAGS] in {
def ROLC : ALU1<"rolc", null_frag>;
def RORC : ALU1<"rorc", null_frag>;
}

//===----------------------------------------------------------------------===//
// Loads and stores
//===----------------------------------------------------------------------===//

let mayLoad = 1 in {
def LD    : Slurm16Inst<(outs GPR:$rd), (ins memsrc:$addr), "ld $rd, $addr",
                        [(set GPR:$rd, (load addr:$addr))], 4>;
def LDB   : Slurm16Inst<(outs GPR:$rd), (ins memsrc:$addr), "ldb $rd, $addr",
                        [(set GPR:$rd, (zextloadi8 addr:$addr))], 4>;
def LDBSX : Slurm16Inst<(outs GPR:$rd), (ins memsrc:$addr), "ldbsx $rd, $addr",
                        [(set GPR:$rd, (sextloadi8 addr:$addr))], 4>;
}

def : Pat<(i16 (extloadi8 addr:$addr)), (LDB addr:$addr)>;

let mayStore = 1 in {
def ST  : Slurm16Inst<(outs), (ins GPR:$rs, memsrc:$addr), "st $addr, $rs",
                      [(store GPR:$rs, addr:$addr)], 4>;
def STB : Slurm16Inst<(outs), (ins GPR:$rs, memsrc:$addr), "stb $addr, $rs",
                      [(truncstorei8 GPR:$rs, addr:$addr)], 4>;
}

//===----------------------------------------------------------------------===//
// Port I/O
//===----------------------------------------------------------------------===//

let hasSideEffects = 1 in {
def IN  : Slurm16Inst<(outs GPR:$rd), (ins memsrc:$port), "in $rd, $port",
                      [], 4>;
def OUT : Slurm16Inst<(outs), (ins GPR:$rs, memsrc:$port), "out $port, $rs",
                      [], 4>;
}

//===----------------------------------------------------------------------===//
// Control flow
//===----------------------------------------------------------------------===//

let isBranch = 1, isTerminator = 1 in {
  let isBarrier = 1 in {
    def BA : Slurm16Inst<(outs), (ins brtarget:$dst), "ba $dst",
                         [(br bb:$dst)], 4>;
    let isIndirectBranch = 1 in
    def BAr : Slurm16Inst<(outs), (ins GPR:$rs), "ba [$rs]",
                          [(brind GPR:$rs)], 4>;
  }
  let Uses = [FLAGS] in
  def BCC : Slurm16Inst<(outs), (ins brtarget:$dst, cc:$cond), "b$cond $dst",
                        [(Slurm16brcc bb:$dst, imm:$cond)], 4>;
}

// r15 is not modelled as a use: it is callee saved, and so live out of return
// blocks.
let isReturn = 1, isTerminator = 1, isBarrier = 1 in
def RET : Slurm16Inst<(outs), (ins), "ret", [(Slurm16retglue)]>;

let isReturn = 1, isTerminator = 1, isBarrier = 1, Uses = [R14],
    hasSideEffects = 1 in
def IRET : Slurm16Inst<(outs), (ins), "iret", []>;

// Calls clobber the link register and the flags. Clobbering of the other
// caller saved registers is described by the call's register mask.
let isCall = 1, Defs = [R15, FLAGS], Uses = [R13] in {
  def BL  : Slurm16Inst<(outs), (ins calltarget:$dst), "bl $dst", [], 4>;
  def BLr : Slurm16Inst<(outs), (ins GPR:$rs), "bl [$rs]",
                        [(Slurm16call GPR:$rs)], 4>;
}

def : Pat<(Slurm16call (i16 tglobaladdr:$dst)), (BL tglobaladdr:$dst)>;
def : Pat<(Slurm16call (i16 texternalsym:$dst)), (BL texternalsym:$dst)>;

//===----------------------------------------------------------------------===//
// Miscellaneous
//===----------------------------------------------------------------------===//

def NOP : Slurm16Inst<(outs), (ins), "nop", []>;

let hasSideEffects = 1 in {
def CLI   : Slurm16Inst<(outs), (ins), "cli", []>;
def STI   : Slurm16Inst<(outs), (ins), "sti", []>;
def SLEEP : Slurm16Inst<(outs), (ins), "sleep", []>;
}

//===----------------------------------------------------------------------===//
// Non-instruction patterns
//===----------------------------------------------------------------------===//

// sign_extend_inreg from i8: (x << 8) >>s 8, both done with multiplies.
def : Pat<(sext_inreg GPR:$a, i8), (MULUri (MULri GPR:$a, 256), 256)>;

// Zero extension of a byte.
def : Pat<(and GPR:$a, 255), (ANDri GPR:$a, 255)>;
