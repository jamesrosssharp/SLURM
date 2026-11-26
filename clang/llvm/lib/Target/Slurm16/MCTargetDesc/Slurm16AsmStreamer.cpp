//===-- Slurm16AsmStreamer.cpp - slurmasm-ng assembly output --------------===//
//
// An MCStreamer that writes assembly in the dialect understood by
// slurmasm-ng (the SLURM16 assembler), which is quite different from GNU as:
//
//   - sections:        ".section text"   (the assembler prepends the '.')
//   - functions:       ".function name" ... ".endfunc" (creates .text.name)
//   - data:            "db x", "dw x", "dd x" - one value per line
//   - zero fill:       ".times N db 0"
//   - alignment:       ".align N" (in bytes)
//   - symbol binding:  ".global name", ".weak name" (must be defined in the
//                      same file), ".extern name"
//   - labels on their own line, and the file must finish with ".end"
//
//===----------------------------------------------------------------------===//

#include "Slurm16AsmNames.h"
#include "Slurm16MCTargetDesc.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/Casting.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
#include <set>
#include <vector>

using namespace llvm;

// Weak definitions (C++ inline functions, templates, vtables, ...) need a
// slurmlink that allows several weak definitions of a symbol and sees
// references to weak symbols in its section garbage collection. With an older
// slurmlink, -slurm16-weak-symbols=false emits them as global symbols instead
// (correct as long as each is defined in only one object file).
static cl::opt<bool> EmitWeakSymbols(
    "slurm16-weak-symbols", cl::init(true), cl::Hidden,
    cl::desc("Emit .weak for weak definitions (default); otherwise emit "
             "them as global symbols"));

namespace {

class Slurm16AsmStreamer final : public MCStreamer {
  std::unique_ptr<formatted_raw_ostream> OSOwner;
  formatted_raw_ostream &OS;
  std::unique_ptr<MCInstPrinter> InstPrinter;

  /// Name of the section currently selected in the output ("" = none).
  std::string EmittedSection;
  /// The section selected by the compiler is not loadable (debug info etc.)
  /// and its contents are dropped.
  bool Discarding = false;
  /// Inside a ".function" block.
  bool InFunction = false;

  SetVector<const MCSymbol *> Globals;
  SetVector<const MCSymbol *> Weaks;
  SetVector<const MCSymbol *> Referenced;
  DenseSet<const MCSymbol *> Defined;
  /// Every section selected in the output.
  SetVector<std::string, std::vector<std::string>, std::set<std::string>>
      UsedSections;
  /// Output section of each label.
  DenseMap<const MCSymbol *, std::string> LabelSection;

  void collectSymbols(const MCExpr &E);
  void emitDataLine(const char *Directive, const MCExpr *Value);
  void closeFunction();

public:
  Slurm16AsmStreamer(MCContext &Ctx, std::unique_ptr<formatted_raw_ostream> OS,
                     std::unique_ptr<MCInstPrinter> IP)
      : MCStreamer(Ctx), OSOwner(std::move(OS)), OS(*OSOwner),
        InstPrinter(std::move(IP)) {
    Ctx.setUseNamesOnTempLabels(true);
  }

  bool hasRawTextSupport() const override { return true; }
  bool isVerboseAsm() const override { return false; }

  void changeSection(MCSection *Section, uint32_t Subsection) override;
  void emitLabel(MCSymbol *Symbol, SMLoc Loc) override;
  void emitAssignment(MCSymbol *Symbol, const MCExpr *Value) override;
  bool emitSymbolAttribute(MCSymbol *Symbol, MCSymbolAttr Attribute) override;
  void emitCommonSymbol(MCSymbol *Symbol, uint64_t Size,
                        Align ByteAlignment) override;
  void emitLocalCommonSymbol(MCSymbol *Symbol, uint64_t Size,
                             Align ByteAlignment) override;
  void emitZerofill(MCSection *Section, MCSymbol *Symbol = nullptr,
                    uint64_t Size = 0, Align ByteAlignment = Align(1),
                    SMLoc Loc = SMLoc()) override;
  void emitBytes(StringRef Data) override;
  void emitValueImpl(const MCExpr *Value, unsigned Size, SMLoc Loc) override;
  void emitIntValue(uint64_t Value, unsigned Size) override;
  void emitFill(const MCExpr &NumBytes, uint64_t FillValue,
                SMLoc Loc = SMLoc()) override;
  void emitValueToAlignment(Align Alignment, int64_t Fill = 0,
                            uint8_t FillLen = 1,
                            unsigned MaxBytesToEmit = 0) override;
  void emitCodeAlignment(Align Alignment, const MCSubtargetInfo *STI,
                         unsigned MaxBytesToEmit = 0) override;
  void emitInstruction(const MCInst &Inst, const MCSubtargetInfo &STI) override;
  void emitRawTextImpl(StringRef String) override;
  void emitELFSize(MCSymbol *Symbol, const MCExpr *Value) override {}
  void emitFileDirective(StringRef Filename) override {}
  void emitFileDirective(StringRef Filename, StringRef CompilerVersion,
                         StringRef TimeStamp, StringRef Description) override {}
  void emitIdent(StringRef IdentString) override {}
  void finishImpl() override;
};

} // namespace

static std::string mapSectionName(const MCSection *Section, bool &Discard) {
  Discard = false;
  StringRef Name = Section->getName();
  if (const auto *ELF = dyn_cast<MCSectionELF>(Section)) {
    if (!(ELF->getFlags() & ELF::SHF_ALLOC)) {
      Discard = true;
      return "";
    }
  }
  if (Name == ".text" || Name.starts_with(".text."))
    return "text";
  if (Name == ".bss" || Name.starts_with(".bss.") || Name == ".sbss" ||
      Name.starts_with(".sbss.") || Name.starts_with(".tbss"))
    return "bss";
  if (Name == ".data" || Name.starts_with(".data.") || Name == ".sdata" ||
      Name.starts_with(".sdata.") || Name.starts_with(".rodata") ||
      Name.starts_with(".srodata") || Name.starts_with(".tdata"))
    return "data";
  if (Name.starts_with(".init_array") || Name.starts_with(".ctors"))
    return "init_array";
  if (Name.starts_with(".fini_array") || Name.starts_with(".dtors"))
    return "fini_array";
  if (Name.starts_with(".note") || Name.starts_with(".comment") ||
      Name.starts_with(".debug") || Name.starts_with(".llvm")) {
    Discard = true;
    return "";
  }
  // User defined section: drop the leading '.', which the assembler adds
  // back.
  Name.consume_front(".");
  return Slurm16::getAsmSymbolName(Name);
}

void Slurm16AsmStreamer::closeFunction() {
  if (InFunction) {
    OS << "\t.endfunc\n";
    InFunction = false;
  }
}

void Slurm16AsmStreamer::changeSection(MCSection *Section,
                                       uint32_t Subsection) {
  MCStreamer::changeSection(Section, Subsection);
  bool Discard;
  std::string Name = mapSectionName(Section, Discard);
  Discarding = Discard;
  if (Discard || Name == EmittedSection)
    return;
  closeFunction();
  OS << "\t.section " << Name << "\n";
  EmittedSection = Name;
  UsedSections.insert(Name);
}

void Slurm16AsmStreamer::emitLabel(MCSymbol *Symbol, SMLoc Loc) {
  MCStreamer::emitLabel(Symbol, Loc);
  if (Discarding)
    return;
  Defined.insert(Symbol);
  LabelSection[Symbol] = EmittedSection;
  Slurm16::printSymbol(OS, *Symbol);
  OS << ":\n";
}

void Slurm16AsmStreamer::emitAssignment(MCSymbol *Symbol, const MCExpr *Value) {
  MCStreamer::emitAssignment(Symbol, Value);
  int64_t V;
  if (Value->evaluateAsAbsolute(V)) {
    Defined.insert(Symbol);
    Slurm16::printSymbol(OS, *Symbol);
    OS << " equ " << V << "\n";
    return;
  }
  // slurmasm-ng has no symbol aliases. A function alias is implemented as a
  // trampoline that branches to the aliasee.
  if (const auto *Ref = dyn_cast<MCSymbolRefExpr>(Value)) {
    const MCSymbol *Target = &Ref->getSymbol();
    auto It = LabelSection.find(Target);
    if (It != LabelSection.end() && It->second == "text") {
      closeFunction();
      if (EmittedSection != "text") {
        OS << "\t.section text\n";
        EmittedSection = "text";
        UsedSections.insert("text");
      }
      Defined.insert(Symbol);
      LabelSection[Symbol] = "text";
      Referenced.insert(Target);
      Slurm16::printSymbol(OS, *Symbol);
      OS << ":\n\tba ";
      Slurm16::printSymbol(OS, *Target);
      OS << "\n";
      return;
    }
  }
  getContext().reportError(SMLoc(), "SLURM16: alias '" + Symbol->getName() +
                                        "' is not supported (slurmasm-ng has "
                                        "no symbol aliases)");
}

bool Slurm16AsmStreamer::emitSymbolAttribute(MCSymbol *Symbol,
                                             MCSymbolAttr Attribute) {
  switch (Attribute) {
  case MCSA_Global:
    Globals.insert(Symbol);
    return true;
  case MCSA_Weak:
  case MCSA_WeakDefinition:
  case MCSA_WeakReference:
    if (EmitWeakSymbols)
      Weaks.insert(Symbol);
    else
      Globals.insert(Symbol);
    return true;
  default:
    // Types, visibility, etc. have no slurmasm-ng equivalent.
    return true;
  }
}

void Slurm16AsmStreamer::emitCommonSymbol(MCSymbol *Symbol, uint64_t Size,
                                          Align ByteAlignment) {
  // No common symbols: allocate in .bss.
  MCSection *Cur = getCurrentSectionOnly();
  closeFunction();
  if (EmittedSection != "bss") {
    OS << "\t.section bss\n";
    EmittedSection = "bss";
    UsedSections.insert("bss");
  }
  bool SavedDiscard = Discarding;
  Discarding = false;
  if (ByteAlignment.value() > 1)
    OS << "\t.align " << ByteAlignment.value() << "\n";
  Globals.insert(Symbol);
  Defined.insert(Symbol);
  Slurm16::printSymbol(OS, *Symbol);
  OS << ":\n";
  if (Size)
    OS << "\t.times " << Size << " db 0\n";
  Discarding = SavedDiscard;
  // Re-select the previous section on the next directive.
  if (Cur) {
    bool D;
    std::string N = mapSectionName(Cur, D);
    if (!D && N != EmittedSection) {
      OS << "\t.section " << N << "\n";
      EmittedSection = N;
    }
  }
}

void Slurm16AsmStreamer::emitLocalCommonSymbol(MCSymbol *Symbol, uint64_t Size,
                                               Align ByteAlignment) {
  emitCommonSymbol(Symbol, Size, ByteAlignment);
  Globals.remove(Symbol);
}

void Slurm16AsmStreamer::emitZerofill(MCSection *Section, MCSymbol *Symbol,
                                      uint64_t Size, Align ByteAlignment,
                                      SMLoc Loc) {
  if (Symbol)
    emitLocalCommonSymbol(Symbol, Size, ByteAlignment);
}

void Slurm16AsmStreamer::emitBytes(StringRef Data) {
  if (Discarding)
    return;
  // Runs of zero bytes are compressed into .times.
  size_t I = 0;
  while (I < Data.size()) {
    size_t J = I;
    while (J < Data.size() && Data[J] == 0)
      ++J;
    if (J - I >= 4) {
      OS << "\t.times " << (J - I) << " db 0\n";
      I = J;
      continue;
    }
    OS << "\tdb " << (unsigned)(unsigned char)Data[I] << "\n";
    ++I;
  }
}

void Slurm16AsmStreamer::collectSymbols(const MCExpr &E) {
  switch (E.getKind()) {
  case MCExpr::SymbolRef:
    Referenced.insert(&cast<MCSymbolRefExpr>(E).getSymbol());
    return;
  case MCExpr::Binary:
    collectSymbols(*cast<MCBinaryExpr>(E).getLHS());
    collectSymbols(*cast<MCBinaryExpr>(E).getRHS());
    return;
  case MCExpr::Unary:
    collectSymbols(*cast<MCUnaryExpr>(E).getSubExpr());
    return;
  default:
    return;
  }
}

void Slurm16AsmStreamer::emitDataLine(const char *Directive,
                                      const MCExpr *Value) {
  collectSymbols(*Value);
  OS << "\t" << Directive << " ";
  Slurm16::printExpr(OS, *Value);
  OS << "\n";
}

void Slurm16AsmStreamer::emitValueImpl(const MCExpr *Value, unsigned Size,
                                       SMLoc Loc) {
  MCStreamer::emitValueImpl(Value, Size, Loc);
  if (Discarding)
    return;
  int64_t V;
  if (Value->evaluateAsAbsolute(V)) {
    emitIntValue(V, Size);
    return;
  }
  // Relocatable values: only 16 bit relocations exist (dw).
  switch (Size) {
  case 2:
    emitDataLine("dw", Value);
    return;
  case 4:
    emitDataLine("dw", Value);
    OS << "\tdw 0\n";
    return;
  default:
    getContext().reportError(Loc, "SLURM16: unsupported relocation size " +
                                      Twine(Size));
  }
}

void Slurm16AsmStreamer::emitIntValue(uint64_t Value, unsigned Size) {
  if (Discarding)
    return;
  switch (Size) {
  case 1:
    OS << "\tdb " << (Value & 0xff) << "\n";
    return;
  case 2:
    OS << "\tdw " << (Value & 0xffff) << "\n";
    return;
  default:
    for (unsigned I = 0; I < Size; I += 2) {
      if (I + 1 < Size)
        OS << "\tdw " << ((Value >> (I * 8)) & 0xffff) << "\n";
      else
        OS << "\tdb " << ((Value >> (I * 8)) & 0xff) << "\n";
    }
  }
}

void Slurm16AsmStreamer::emitFill(const MCExpr &NumBytes, uint64_t FillValue,
                                  SMLoc Loc) {
  if (Discarding)
    return;
  int64_t N;
  if (!NumBytes.evaluateAsAbsolute(N)) {
    getContext().reportError(Loc, "SLURM16: non-constant fill size");
    return;
  }
  if (N > 0)
    OS << "\t.times " << N << " db " << (FillValue & 0xff) << "\n";
}

void Slurm16AsmStreamer::emitValueToAlignment(Align Alignment, int64_t Fill,
                                              uint8_t FillLen,
                                              unsigned MaxBytesToEmit) {
  if (Discarding || Alignment.value() <= 1)
    return;
  OS << "\t.align " << Alignment.value() << "\n";
}

void Slurm16AsmStreamer::emitCodeAlignment(Align Alignment,
                                           const MCSubtargetInfo *STI,
                                           unsigned MaxBytesToEmit) {
  emitValueToAlignment(Alignment);
}

void Slurm16AsmStreamer::emitInstruction(const MCInst &Inst,
                                         const MCSubtargetInfo &STI) {
  MCStreamer::emitInstruction(Inst, STI);
  for (const MCOperand &Op : Inst)
    if (Op.isExpr())
      collectSymbols(*Op.getExpr());
  InstPrinter->printInst(&Inst, 0, "", STI, OS);
  OS << "\n";
}

void Slurm16AsmStreamer::emitRawTextImpl(StringRef String) {
  // The asm printer uses raw text to bracket functions.
  StringRef T = String.trim();
  if (T.starts_with(".function ")) {
    closeFunction();
    InFunction = true;
  } else if (T == ".endfunc") {
    if (!InFunction)
      return;
    InFunction = false;
  }
  OS << String;
  if (!String.ends_with("\n"))
    OS << "\n";
}

void Slurm16AsmStreamer::finishImpl() {
  closeFunction();
  // slurmlink concatenates input sections without aligning them, so keep the
  // size of every section even: otherwise the next object's data would start
  // at an odd address, which word loads cannot access.
  for (const std::string &Name : UsedSections)
    OS << "\t.section " << Name << "\n\t.align 2\n";
  for (const MCSymbol *S : Globals) {
    if (!Defined.count(S) || Weaks.count(S))
      continue;
    OS << "\t.global ";
    Slurm16::printSymbol(OS, *S);
    OS << "\n";
  }
  for (const MCSymbol *S : Weaks) {
    if (!Defined.count(S))
      continue;
    OS << "\t.weak ";
    Slurm16::printSymbol(OS, *S);
    OS << "\n";
  }
  for (const MCSymbol *S : Referenced) {
    if (Defined.count(S) || S->isTemporary())
      continue;
    OS << "\t.extern ";
    Slurm16::printSymbol(OS, *S);
    OS << "\n";
  }
  OS << "\t.end\n";
  OS.flush();
}

MCStreamer *llvm::createSlurm16AsmStreamer(
    MCContext &Ctx, std::unique_ptr<formatted_raw_ostream> OS,
    std::unique_ptr<MCInstPrinter> IP, std::unique_ptr<MCCodeEmitter> CE,
    std::unique_ptr<MCAsmBackend> TAB) {
  return new Slurm16AsmStreamer(Ctx, std::move(OS), std::move(IP));
}
