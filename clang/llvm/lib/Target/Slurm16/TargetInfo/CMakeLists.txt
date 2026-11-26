add_llvm_component_library(LLVMSlurm16Info
  Slurm16TargetInfo.cpp

  LINK_COMPONENTS
  MC
  Support

  ADD_TO_COMPONENT
  Slurm16
  )
