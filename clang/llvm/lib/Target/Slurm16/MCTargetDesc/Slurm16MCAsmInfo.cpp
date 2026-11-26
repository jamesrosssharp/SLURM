//===-- Slurm16MCAsmInfo.cpp - SLURM16 asm properties ---------------------===//

#include "Slurm16MCAsmInfo.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

void Slurm16MCAsmInfo::anchor() {}

Slurm16MCAsmInfo::Slurm16MCAsmInfo(const Triple &TT) {
  CodePointerSize = 2;
  CalleeSaveStackSlotSize = 2;
  MaxInstLength = 4;

  // slurmasm-ng accepts "//", "/* */" and "#" comments.
  CommentString = "//";
  PrivateGlobalPrefix = ".L";
  PrivateLabelPrefix = ".L";

  Data8bitsDirective = "\tdb\t";
  Data16bitsDirective = "\tdw\t";
  Data32bitsDirective = "\tdd\t";
  Data64bitsDirective = nullptr;
  ZeroDirective = nullptr;
  AsciiDirective = nullptr;
  AscizDirective = nullptr;
  GlobalDirective = "\t.global\t";
  WeakDirective = "\t.weak\t";
  HasDotTypeDotSizeDirective = false;
  HasSingleParameterDotFile = false;
  HasIdentDirective = false;
  AlignmentIsInBytes = true;

  SupportsDebugInformation = false;
  ExceptionsType = ExceptionHandling::None;

  UseIntegratedAssembler = false;
  ParseInlineAsmUsingAsmParser = false;
}
