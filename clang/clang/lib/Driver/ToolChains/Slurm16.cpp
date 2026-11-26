//===--- Slurm16.cpp - SLURM16 ToolChain Implementations ------------------===//

#include "Slurm16.h"
#include "clang/Driver/CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/InputInfo.h"
#include "clang/Driver/Options.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/VirtualFileSystem.h"

using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools;
using namespace clang;
using namespace llvm::opt;

Slurm16ToolChain::Slurm16ToolChain(const Driver &D, const llvm::Triple &Triple,
                                   const ArgList &Args)
    : ToolChain(D, Triple, Args) {
  // Look for slurmasm-ng / slurmlink next to clang first, then in PATH.
  getProgramPaths().push_back(D.Dir);
}

std::string Slurm16ToolChain::getRuntimeDir() const {
  if (!getDriver().SysRoot.empty())
    return getDriver().SysRoot;
  SmallString<128> Dir(getDriver().Dir);
  llvm::sys::path::append(Dir, "..", "slurm16");
  return std::string(Dir);
}

Tool *Slurm16ToolChain::buildAssembler() const {
  return new tools::slurm16::Assembler(*this);
}

Tool *Slurm16ToolChain::buildLinker() const {
  return new tools::slurm16::Linker(*this);
}

void Slurm16ToolChain::AddClangSystemIncludeArgs(
    const ArgList &DriverArgs, ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(options::OPT_nostdinc))
    return;
  if (!DriverArgs.hasArg(options::OPT_nobuiltininc)) {
    SmallString<128> Dir(getDriver().ResourceDir);
    llvm::sys::path::append(Dir, "include");
    addSystemInclude(DriverArgs, CC1Args, Dir.str());
  }
  if (DriverArgs.hasArg(options::OPT_nostdlibinc))
    return;
  SmallString<128> Dir(getRuntimeDir());
  llvm::sys::path::append(Dir, "include");
  addSystemInclude(DriverArgs, CC1Args, Dir.str());
}

void Slurm16ToolChain::addClangTargetOptions(const ArgList &DriverArgs,
                                             ArgStringList &CC1Args,
                                             Action::OffloadKind) const {
  CC1Args.push_back("-nostdsysteminc");
  // There is no runtime support for atexit registration of static
  // destructors other than the minimal one in the SLURM16 runtime.
  if (!DriverArgs.hasFlag(options::OPT_fuse_cxa_atexit,
                          options::OPT_fno_use_cxa_atexit, false))
    CC1Args.push_back("-fno-use-cxa-atexit");
}

void slurm16::Assembler::ConstructJob(Compilation &C, const JobAction &JA,
                                      const InputInfo &Output,
                                      const InputInfoList &Inputs,
                                      const ArgList &Args,
                                      const char *LinkingOutput) const {
  claimNoWarnArgs(Args);
  ArgStringList CmdArgs;

  Args.AddAllArgValues(CmdArgs, options::OPT_Wa_COMMA, options::OPT_Xassembler);

  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());

  assert(Inputs.size() == 1 && "slurmasm-ng takes a single input file");
  CmdArgs.push_back(Inputs[0].getFilename());

  const char *Exec =
      Args.MakeArgString(getToolChain().GetProgramPath("slurmasm-ng"));
  C.addCommand(std::make_unique<Command>(JA, *this, ResponseFileSupport::None(),
                                         Exec, CmdArgs, Inputs, Output));
}

void slurm16::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                   const InputInfo &Output,
                                   const InputInfoList &Inputs,
                                   const ArgList &Args,
                                   const char *LinkingOutput) const {
  const auto &TC = static_cast<const toolchains::Slurm16ToolChain &>(
      getToolChain());
  ArgStringList CmdArgs;

  // Linker script: -T <script>, else the default from the runtime.
  CmdArgs.push_back("-s");
  if (const Arg *A = Args.getLastArg(options::OPT_T)) {
    CmdArgs.push_back(A->getValue());
    A->claim();
  } else {
    SmallString<128> LD(TC.getRuntimeDir());
    llvm::sys::path::append(LD, "lib", "slurm16.ld");
    CmdArgs.push_back(Args.MakeArgString(LD));
  }

  assert((Output.isFilename() || Output.isNothing()) && "Invalid output.");
  if (Output.isFilename()) {
    CmdArgs.push_back("-o");
    CmdArgs.push_back(Output.getFilename());
  }

  bool NoStartFiles = Args.hasArg(options::OPT_nostartfiles) ||
                      Args.hasArg(options::OPT_nostdlib);
  bool NoDefaultLibs = Args.hasArg(options::OPT_nodefaultlibs) ||
                       Args.hasArg(options::OPT_nostdlib);

  SmallString<128> LibDir(TC.getRuntimeDir());
  llvm::sys::path::append(LibDir, "lib");

  if (!NoStartFiles) {
    SmallString<128> Crt0(LibDir);
    llvm::sys::path::append(Crt0, "crt0.o");
    CmdArgs.push_back(Args.MakeArgString(Crt0));
  }

  for (const InputInfo &II : Inputs)
    if (II.isFilename())
      CmdArgs.push_back(II.getFilename());

  // -lfoo: slurmlink has no archive support, so look for foo.o / libfoo.o
  // in the -L paths and the runtime lib directory.
  SmallVector<std::string, 4> LibPaths;
  for (const Arg *A : Args.filtered(options::OPT_L))
    LibPaths.push_back(A->getValue());
  LibPaths.push_back(std::string(LibDir));
  for (const Arg *A : Args.filtered(options::OPT_l)) {
    A->claim();
    bool Found = false;
    for (const std::string &P : LibPaths) {
      for (const char *Fmt : {"lib%s.o", "%s.o"}) {
        SmallString<128> Path(P);
        char Buf[256];
        snprintf(Buf, sizeof(Buf), Fmt, A->getValue());
        llvm::sys::path::append(Path, Buf);
        if (TC.getVFS().exists(Path)) {
          CmdArgs.push_back(Args.MakeArgString(Path));
          Found = true;
          break;
        }
      }
      if (Found)
        break;
    }
    if (!Found)
      C.getDriver().Diag(diag::err_drv_no_such_file)
          << (Twine("lib") + A->getValue() + ".o").str();
  }

  // The runtime library is a directory of objects (slurmlink has no archive
  // support); unreferenced sections are discarded by the linker.
  if (!NoDefaultLibs) {
    SmallString<128> RTDir(LibDir);
    llvm::sys::path::append(RTDir, "rt");
    std::vector<std::string> Objs;
    std::error_code EC;
    for (llvm::vfs::directory_iterator It = TC.getVFS().dir_begin(RTDir, EC),
                                       End;
         It != End && !EC; It.increment(EC))
      if (llvm::sys::path::extension(It->path()) == ".o")
        Objs.push_back(std::string(It->path()));
    llvm::sort(Objs);
    for (const std::string &O : Objs)
      CmdArgs.push_back(Args.MakeArgString(O));
  }

  const char *Exec =
      Args.MakeArgString(getToolChain().GetProgramPath("slurmlink"));
  C.addCommand(std::make_unique<Command>(JA, *this, ResponseFileSupport::None(),
                                         Exec, CmdArgs, Inputs, Output));
}
