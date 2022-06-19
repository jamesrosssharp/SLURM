/*
 *
 *	CPU Top: the top level for the CPU
 *
 */

module slurm16_cpu_top
(
	input CLK,
	input RSTb,

	output [ADDRESS_BITS - 1:0] memory_address,
	input  [BITS - 1:0] 		memory_in,
	output [BITS - 1:0]			memory_out,
	output						memory_valid,	/* memory request */
	output						memory_wr,		/* memory write */
	input						memory_ready,	/* memory ready - from arbiter */
	output [1:0]				memory_wr_mask, /* write mask - for byte wise access to memory */

	output [ADDRESS_BITS - 1:0] port_address,
	input  [BITS - 1:0]			port_in,
	output [BITS - 1:0]		    port_out,
	output						port_rd,
	output						port_wr,

	input  						interrupt,		/* interrupt line from interrupt controller */	
	input  [3:0]				irq,			/* irq from interrupt controller */
	output						cpu_debug_pin
);

/* Machine is 16 bit with 16 bit address bus, and 16 registers */
localparam BITS = 16;
localparam ADDRESS_BITS = 16;
localparam REGISTER_BITS = 4;

wire load_memory;
wire store_memory;
wire halt;
wire wake;

wire [ADDRESS_BITS - 1:0] pc;
wire [ADDRESS_BITS - 1:0] load_store_address;

assign cpu_debug_pin = memory_ready;

wire [BITS - 1:0] store_memory_data;

wire is_executing;
wire is_fetching;
wire memory_is_instruction;
wire [ADDRESS_BITS - 1:0] memory_address_prev_plus_two;

wire interrupt_flag_set;
wire interrupt_flag_clear;

wire [1:0] memory_wr_mask_delayed;

wire stall_memory_pipeline_stage3;

slurm16_cpu_memory_interface #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_mem0  (
	CLK,
	RSTb,

	load_memory, 	/* perform a load operation next */
	store_memory,	/* perform a store operation next */
	halt,			/* put the CPU to sleep */
	wake,			/* wake the CPU up */

	pc, /* pc input from pc module */
	load_store_address, /* load store address */
	store_memory_data, /* data to store to memory */
	store_memory_wr_mask, /* write mask for memory write from execute stage */

	memory_address, /* memory address - to memory arbiter */
	memory_out,		/* memory output */

	memory_valid,						/* memory valid signal - request to mem. arbiter */
	memory_ready,						/* grant - from memory arbiter */
	memory_wr,							/* write to memory */
	memory_wr_mask,						/* write mask to memory */

	is_executing,						/* CPU is currently executing */
	is_fetching,							/* CPU is currently fetching */

	memory_is_instruction,				/* current value of memory in is an instruction */
	memory_address_prev_plus_two,		/* points to return address */
	memory_wr_mask_delayed,				/* delayed memory write mask - for writeback */

	stall_memory_pipeline_stage3

);

wire stall;
wire stall_start ;
wire stall_end;

wire [BITS - 1:0] pipeline_stage0;
wire [BITS - 1:0] pipeline_stage1;
wire [BITS - 1:0] pipeline_stage2;
wire [BITS - 1:0] pipeline_stage3;
wire [BITS - 1:0] pipeline_stage4;

wire [ADDRESS_BITS - 1:0] pc_stage4;

wire [BITS - 1:0] imm_reg;
wire load_pc;

wire [REGISTER_BITS - 1:0] hazard_reg0; 
wire modifies_flags0;

wire [REGISTER_BITS - 1:0] hazard_reg1;
wire [REGISTER_BITS - 1:0] hazard_reg2;
wire [REGISTER_BITS - 1:0] hazard_reg3;
wire modifies_flags1;
wire modifies_flags2;
wire modifies_flags3;

wire hazard1;

cpu_pipeline #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_pip0
(
	CLK,
	RSTb,

	memory_in,
	memory_address_prev_plus_two,

	is_executing, /* CPU is executing */

	stall,		  /* pipeline is stalled */
	stall_start,  /* pipeline has started to stall */
	stall_end,	  /* pipeline is about to end stall */

	pipeline_stage0,
	pipeline_stage1,
	pipeline_stage2,
	pipeline_stage3,
	pipeline_stage4,

	pc_stage4,
	imm_reg,
	load_pc,

	hazard_reg0,		/*  import hazard computation, it will move with pipeline in pipeline module */
	modifies_flags0,	/*  import flag hazard conditions */ 

	hazard_reg1,		/* export pipelined hazards */
	hazard_reg2,
	hazard_reg3,
	modifies_flags1,
	modifies_flags2,
	modifies_flags3,

	hazard1,

	memory_is_instruction,

	interrupt_flag_set,
	interrupt_flag_clear,

	interrupt,
	irq,

	pc_in,

	wake,

	stall_memory_pipeline_stage3

);

wire [ADDRESS_BITS-1:0] pc_in;

slurm16_cpu_program_counter #(.ADDRESS_BITS(ADDRESS_BITS)) cpu_pc0
(
	CLK,
	RSTb,

	pc,

	pc_in,		/* PC in for load (branch, ret etc) */
	load_pc,						 /* load the PC */

	is_fetching,   /* CPU is fetching instructions - increment PC */

	stall,		  /* pipeline is stalled */
	stall_start,  /* pipeline has started to stall */
	stall_end	  /* pipeline is about to end stall */
);

wire [REGISTER_BITS - 1:0] regA_sel;
wire [REGISTER_BITS - 1:0] regB_sel;
 
slurm16_cpu_decode #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS), .REGISTER_BITS(REGISTER_BITS)) cpu_dec0
(
	CLK,
	RSTb,

	pipeline_stage1,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel, /* register A select */
	regB_sel  /* register B select */
);

wire [REGISTER_BITS - 1:0] regA_sel0;
wire [REGISTER_BITS - 1:0] regB_sel0;

// Hazard register decoder 
slurm16_cpu_decode #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS), .REGISTER_BITS(REGISTER_BITS)) cpu_dec1
(
	CLK,
	RSTb,

	pipeline_stage0,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel0, /* register A select */
	regB_sel0  /* register B select */
);

wire [REGISTER_BITS - 1:0]  regIn_sel;
wire [BITS - 1:0] 			regOutA_data;
wire [BITS - 1:0] 			regOutB_data;
wire [BITS - 1:0] 			regIn_data;

slurm16_cpu_register_file
#(.REG_BITS(REGISTER_BITS), .BITS(BITS)) reg0
(
	CLK,
	RSTb,
	regIn_sel,
	regA_sel,
	regB_sel,	
	regOutA_data,
	regOutB_data,
	regIn_data,
	is_executing
);

wire Z;
wire C;
wire S;


wire [4:0] aluOp;
wire [BITS - 1:0] aluA;
wire [BITS - 1:0] aluB;

wire [ADDRESS_BITS - 1:0] ex_port_address;
wire [BITS - 1:0] ex_port_out;
wire ex_port_rd;
wire ex_port_wr;
wire [1:0] store_memory_wr_mask;

slurm16_cpu_execute #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_exec0
(
	CLK,
	RSTb,
	pipeline_stage2,		
	is_executing,
	Z,
	C,
	S,
	regOutA_data,
	regOutB_data,
	imm_reg,
	load_memory,
	store_memory,
	load_store_address,
	store_memory_data,
	store_memory_wr_mask,
	ex_port_address,
	ex_port_out, 
	ex_port_rd,
	ex_port_wr,
	aluOp,
	aluA,
	aluB,
	load_pc,
	pc_in,
	interrupt_flag_set,
	interrupt_flag_clear,
	halt
);

wire [BITS - 1:0] aluOut;

alu
#(.BITS(BITS)) alu0
(
	CLK,
	RSTb,

	aluA,
	aluB,
	aluOp,
	aluOut,

	is_executing,

	C, /* carry flag */
	Z, /* zero flag */
	S /* sign flag */
);

slurm16_cpu_writeback #(.REGISTER_BITS(REGISTER_BITS), .BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_wr0
(
	CLK,
	RSTb,

	pipeline_stage4,		/* instruction in pipeline slot 4 */
	aluOut,
	memory_in, 
	port_in, 

	/* write back register select and data */
	regIn_sel,
	regIn_data,

	pc_stage4,
	memory_wr_mask_delayed
);

slurm16_cpu_port_interface #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_prt0 (
	CLK,
	RSTb,

	is_executing,

	ex_port_address,
	ex_port_out,
	ex_port_rd,
	ex_port_wr,

	port_address,
	port_out,
	port_rd,
	port_wr
);

slurm_cpu_hazard #(.BITS(BITS), .REGISTER_BITS(REGISTER_BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_haz0 
(
	CLK,
	RSTb,

	is_executing,
	load_pc,

	pipeline_stage0,	

	regA_sel0,		/* registers that pipeline0 instruction will read from */
	regB_sel0,

	hazard_reg0,	/*  export hazard computation, it will move with pipeline in pipeline module */
	modifies_flags0,/*  export flag hazard conditions */ 

	hazard_reg1,	/* import pipelined hazards */
	hazard_reg2,
	hazard_reg3,
	modifies_flags1,
	modifies_flags2,
	modifies_flags3,

	stall,
	stall_start,
	stall_end,

	hazard1
);




endmodule
