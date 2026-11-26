//===--- Slurm16.h - SLURM16 ToolChain Implementations ----------*- C++ -*-===//
//
// The SLURM16 toolchain drives the SLURM tools:
//   - slurmasm-ng to assemble the compiler's output,
//   - slurmlink to link, using a linker script (-T / default slurm16.ld).
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_SLURM16_H
#define LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_SLURM16_H

#include "clang/Driver/Tool.h"
#include "clang/Driver/ToolChain.h"

namespace clang {
namespace driver {
namespace tools {
namespace slurm16 {

class LLVM_LIBRARY_VISIBILITY Assembler final : public Tool {
public:
  Assembler(const ToolChain &TC)
      : Tool("slurm16::Assembler", "slurmasm-ng", TC) {}
  bool hasIntegratedCPP() const override { return false; }
  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
};

class LLVM_LIBRARY_VISIBILITY Linker final : public Tool {
public:
  Linker(const ToolChain &TC) : Tool("slurm16::Linker", "slurmlink", TC) {}
  bool hasIntegratedCPP() const override { return false; }
  bool isLinkJob() const override { return true; }
  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
};

} // namespace slurm16
} // namespace tools

namespace toolchains {

class LLVM_LIBRARY_VISIBILITY Slurm16ToolChain : public ToolChain {
public:
  Slurm16ToolChain(const Driver &D, const llvm::Triple &Triple,
                   const llvm::opt::ArgList &Args);

  /// Directory holding the SLURM16 runtime (include/, lib/).
  std::string getRuntimeDir() const;

protected:
  Tool *buildAssembler() const override;
  Tool *buildLinker() const override;

public:
  bool IsIntegratedAssemblerDefault() const override { return false; }
  bool isPICDefault() const override { return false; }
  bool isPIEDefault(const llvm::opt::ArgList &Args) const override {
    return false;
  }
  bool isPICDefaultForced() const override { return false; }
  bool SupportsProfiling() const override { return false; }
  bool hasBlocksRuntime() const override { return false; }
  UnwindTableLevel
  getDefaultUnwindTableLevel(const llvm::opt::ArgList &Args) const override {
    return UnwindTableLevel::None;
  }
  void
  AddClangSystemIncludeArgs(const llvm::opt::ArgList &DriverArgs,
                            llvm::opt::ArgStringList &CC1Args) const override;
  void addClangTargetOptions(const llvm::opt::ArgList &DriverArgs,
                             llvm::opt::ArgStringList &CC1Args,
                             Action::OffloadKind) const override;
  void AddClangCXXStdlibIncludeArgs(
      const llvm::opt::ArgList &DriverArgs,
      llvm::opt::ArgStringList &CC1Args) const override {}
  void AddCXXStdlibLibArgs(const llvm::opt::ArgList &Args,
                           llvm::opt::ArgStringList &CmdArgs) const override {}
};

} // namespace toolchains
} // namespace driver
} // namespace clang

#endif
