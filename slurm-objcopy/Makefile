
all: slurm-objcopy

SRC = 	main.cpp 	\
	../common/host/ELF/ElfFile.cpp

      
INCLUDE = ../common/host/ELF/ElfFile.h


slurm-objcopy:	$(SRC) $(INCLUDE)
	g++ $(SRC) -std=c++11 -lfl -I../common -o slurm-objcopy



