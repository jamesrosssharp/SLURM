//===-- Slurm16CallingConv.td - Calling Conventions --------*- tablegen -*-===//
//
// SLURM16 C calling convention (compatible with the lcc slurm16-ng port):
//
//   - Arguments in r4, r5, r6, r7 (16-bit pieces, wider values are split
//     into little-endian 16-bit pieces), the rest on the stack at [sp + 0],
//     [sp + 2], ... at the point of the call.
//   - Variadic functions pass all arguments on the stack.
//   - Return values in r2 (r2:r3 for 32-bit, r2-r5 for 64-bit values).
//   - Callee saved: r10, r11, r12, r15 (lr). Everything else is clobbered.
//
//===----------------------------------------------------------------------===//

def RetCC_Slurm16 : CallingConv<[
  CCIfType<[i8], CCPromoteToType<i16>>,
  CCIfType<[i16], CCAssignToReg<[R2, R3, R4, R5]>>
]>;

def CC_Slurm16_Stack : CallingConv<[
  CCIfType<[i8], CCPromoteToType<i16>>,
  CCIfByVal<CCPassByVal<2, 2>>,
  CCIfType<[i16], CCAssignToStack<2, 2>>
]>;

def CC_Slurm16 : CallingConv<[
  CCIfType<[i8], CCPromoteToType<i16>>,
  CCIfByVal<CCPassByVal<2, 2>>,
  CCIfType<[i16], CCAssignToReg<[R4, R5, R6, R7]>>,
  CCIfType<[i16], CCAssignToStack<2, 2>>
]>;

def CSR_Slurm16 : CalleeSavedRegs<(add R15, R10, R11, R12)>;

// Interrupt handlers must preserve every register they touch.
def CSR_Slurm16_Interrupt : CalleeSavedRegs<(add R15, R1, R2, R3, R4, R5, R6,
                                                 R7, R8, R9, R10, R11, R12)>;
