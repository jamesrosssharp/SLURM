/*
 *
 *	CPU Top: the top level for the CPU
 *
 */

module slurm16_cpu_top #(parameter BITS = 16, ADDRESS_BITS = 16) 
(
	input CLK,
	input RSTb,

	output [ADDRESS_BITS - 1:0] memory_address,
	input  [BITS - 1:0] 		memory_in,
	output [BITS - 1:0]			memory_out,
	output						memory_valid,	/* memory request */
	output						memory_wr,		/* memory write */
	input						memory_ready,	/* memory ready - from arbiter */

	output [ADDRESS_BITS - 1:0] port_address,
	input  [BITS - 1:0]			port_in,
	output [BITS - 1:0]		    port_out,
	output						port_rd,
	output						port_wr,

	input  [3:0]				irq			/* interrupt lines */
);

wire load_memory = 1'b0;
wire store_memory = 1'b0;
wire halt = 1'b0;
wire wake = 1'b0;

wire [ADDRESS_BITS - 1:0] pc;
wire [ADDRESS_BITS - 1:0] load_store_address = 16'h0000;

wire is_executing;
wire is_fetching;

slurm16_cpu_memory_interface #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_mem0  (
	CLK,
	RSTb,

	load_memory, 	/* perform a load operation next */
	store_memory,	/* perform a store operation next */
	halt,			/* put the CPU to sleep */
	wake,			/* wake the CPU up */

	pc, /* pc input from pc module */
	load_store_address, /* load store address */

	memory_address, /* memory address - to memory arbiter */
	memory_valid,						/* memory valid signal - request to mem. arbiter */
	memory_ready,						/* grant - from memory arbiter */
	memory_wr,							/* write to memory */

	is_executing,						/* CPU is currently executing */
	is_fetching							/* CPU is currently fetching */

);

wire stall = 1'b0;
wire stall_start = 1'b0;
wire stall_end = 1'b0;

wire [BITS - 1:0] pipeline_stage0;
wire [BITS - 1:0] pipeline_stage1;
wire [BITS - 1:0] pipeline_stage2;
wire [BITS - 1:0] pipeline_stage3;
wire [BITS - 1:0] pipeline_stage4;

slurm16_cpu_pipeline #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_pip0
(
	CLK,
	RSTb,

	memory_in,

	is_executing, /* CPU is executing */

	stall,		  /* pipeline is stalled */
	stall_start,  /* pipeline has started to stall */
	stall_end,	  /* pipeline is about to end stall */

	pipeline_stage0,
	pipeline_stage1,
	pipeline_stage2,
	pipeline_stage3,
	pipeline_stage4

);

wire [ADDRESS_BITS-1:0] pc_in = {ADDRESS_BITS{1'b0}};
wire load_pc = 1'b0;

slurm16_cpu_program_counter #(.ADDRESS_BITS(ADDRESS_BITS)) cpu_pc0
(
	CLK,
	RSTb,

	pc,

	pc_in,	/* PC in for load (branch, ret etc) */
	load_pc,							/* load the PC */

	is_fetching,	/* CPU is fetching instructions - increment PC */

	stall,		/* pipeline is stalled */
	stall_start,  /* pipeline has started to stall */
	stall_end	/* pipeline is about to end stall */
);



endmodule
