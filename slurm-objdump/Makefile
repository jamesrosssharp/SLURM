
all: slurm-objdump

SRC = 	main.cpp 	\
	../common/host/ELF/ElfFile.cpp	\
	Disassembly.cpp

      
INCLUDE = ../common/host/ELF/ElfFile.h			\
	  Disassembly.h					\
	  ../common/host/SLURM/slurm16InstructionSet.h


slurm-objdump:	$(SRC) $(INCLUDE)
	g++ $(SRC) -std=c++11 -lfl -I../common -o slurm-objdump



