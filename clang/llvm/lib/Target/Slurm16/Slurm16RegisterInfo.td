//===-- Slurm16RegisterInfo.td - SLURM16 Register defs -----*- tablegen -*-===//
//
// SLURM16 has 16 x 16-bit registers:
//   r0      - always zero
//   r1-r12  - general purpose
//   r13     - stack pointer (sp)
//   r14     - interrupt link register (ilr) - clobbered asynchronously by
//             interrupts, so it is never allocated
//   r15     - link register (lr)
//
// The ALU flags (Z, C, S, V) are modelled as a single, non-allocatable
// register "flags".
//
//===----------------------------------------------------------------------===//

class Slurm16Reg<bits<16> num, string n, list<string> alt = []>
    : Register<n, alt> {
  let HWEncoding = num;
  let Namespace = "Slurm16";
}

foreach I = 0-15 in {
  def R#I : Slurm16Reg<I, "r"#I>, DwarfRegNum<[I]>;
}

def FLAGS : Slurm16Reg<16, "flags">;

// General purpose registers. The allocation order prefers caller-saved
// registers, then callee-saved registers. r0, r13 and r14 are reserved.
def GPR : RegisterClass<"Slurm16", [i16], 16,
    (add R1, R2, R3, R4, R5, R6, R7, R8, R9,
         R10, R11, R12, R15,
         R0, R13, R14)>;

// The flags register (not allocatable).
def CCR : RegisterClass<"Slurm16", [i16], 16, (add FLAGS)> {
  let CopyCost = -1;
  let isAllocatable = 0;
}
