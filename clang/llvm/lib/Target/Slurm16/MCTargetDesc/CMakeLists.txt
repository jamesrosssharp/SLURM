add_llvm_component_library(LLVMSlurm16Desc
  Slurm16AsmNames.cpp
  Slurm16AsmStreamer.cpp
  Slurm16InstPrinter.cpp
  Slurm16MCAsmInfo.cpp
  Slurm16MCTargetDesc.cpp

  LINK_COMPONENTS
  MC
  Slurm16Info
  Support
  TargetParser

  ADD_TO_COMPONENT
  Slurm16
  )
