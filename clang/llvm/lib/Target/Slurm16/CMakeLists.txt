add_llvm_component_group(Slurm16)

set(LLVM_TARGET_DEFINITIONS Slurm16.td)

tablegen(LLVM Slurm16GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM Slurm16GenCallingConv.inc -gen-callingconv)
tablegen(LLVM Slurm16GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM Slurm16GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM Slurm16GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM Slurm16GenSDNodeInfo.inc -gen-sd-node-info)
tablegen(LLVM Slurm16GenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(Slurm16CommonTableGen)

add_llvm_target(Slurm16CodeGen
  Slurm16AsmPrinter.cpp
  Slurm16FrameLowering.cpp
  Slurm16InstrInfo.cpp
  Slurm16ISelDAGToDAG.cpp
  Slurm16ISelLowering.cpp
  Slurm16MCInstLower.cpp
  Slurm16RegisterInfo.cpp
  Slurm16SelectionDAGInfo.cpp
  Slurm16Subtarget.cpp
  Slurm16TargetMachine.cpp

  LINK_COMPONENTS
  AsmPrinter
  CodeGen
  CodeGenTypes
  Core
  MC
  SelectionDAG
  Slurm16Desc
  Slurm16Info
  Support
  Target
  TargetParser

  ADD_TO_COMPONENT
  Slurm16
  )

add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
