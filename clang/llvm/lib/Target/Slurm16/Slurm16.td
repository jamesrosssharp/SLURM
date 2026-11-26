//===-- Slurm16.td - Describe the SLURM16 Target Machine ---*- tablegen -*-===//
//
// SLURM16: SLightly Useful RISC Machine, 16 bit.
//
// This is the top level entry point for the SLURM16 target.
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// Subtarget features
//===----------------------------------------------------------------------===//

// Allow the backend to use conditional move instructions (class 5). These are
// supported by the HDL CPU and the slurmemu-ng emulator.  They are disabled by
// default because the HDL pipeline does not interlock flag hazards for them.
def FeatureCondMov : SubtargetFeature<"condmov", "HasCondMov", "true",
                                      "Use conditional move instructions">;

//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "Slurm16RegisterInfo.td"
include "Slurm16CallingConv.td"
include "Slurm16InstrInfo.td"

def Slurm16InstrInfo : InstrInfo;

//===----------------------------------------------------------------------===//
// Processors
//===----------------------------------------------------------------------===//

def : ProcessorModel<"generic", NoSchedModel, []>;
def : ProcessorModel<"slurm16", NoSchedModel, []>;

//===----------------------------------------------------------------------===//
// Assembly writer
//===----------------------------------------------------------------------===//

def Slurm16AsmWriter : AsmWriter {
  string AsmWriterClassName = "InstPrinter";
}

//===----------------------------------------------------------------------===//
// Target Declaration
//===----------------------------------------------------------------------===//

def Slurm16 : Target {
  let InstructionSet = Slurm16InstrInfo;
  let AssemblyWriters = [Slurm16AsmWriter];
}
