/*
 *
 *	CPU Top: the top level for the CPU
 *
 */

module cpu_top
(
	input CLK,
	input RSTb,

	output [ADDRESS_BITS - 1:0] 	memory_address,
	input  [BITS - 1:0] 		memory_in,
	output [BITS - 1:0]		memory_out,
	output				memory_valid,	/* memory request */
	output				memory_wr,	/* memory write */
	input				memory_ready,	/* memory ready - from arbiter */
	output [1:0]			memory_wr_mask, /* write mask - for byte wise access to memory */

	output [ADDRESS_BITS - 1:0] 	port_address,
	input  [BITS - 1:0]		port_in,
	output [BITS - 1:0]		port_out,
	output				port_rd,
	output				port_wr,

	input  				interrupt,	/* interrupt line from interrupt controller */	
	input  [3:0]			irq,		/* irq from interrupt controller */
	output				cpu_debug_pin
);

assign cpu_debug_pin = 1'b0;

/* Machine is 16 bit with 16 bit address bus, and 16 registers */
localparam BITS = 16;
localparam ADDRESS_BITS = 16;
localparam REGISTER_BITS = 4;

wire [15:0] pipeline_stage0;
wire [15:0] pipeline_stage1;
wire [15:0] pipeline_stage2;
wire [15:0] pipeline_stage3;
wire [15:0] pipeline_stage4;

wire [15:0] pc_stage4;

wire [15:0] imm_reg;

wire load_pc;
wire [15:0] new_pc;

wire hazard_1;
wire hazard_2;
wire hazard_3;

wire [REGISTER_BITS - 1 : 0] hazard_reg0;
wire modifies_flags0;

wire [REGISTER_BITS - 1 : 0] hazard_reg1;
wire [REGISTER_BITS - 1 : 0] hazard_reg2;
wire [REGISTER_BITS - 1 : 0] hazard_reg3;
wire modifies_flags1;
wire modifies_flags2;
wire modifies_flags3;

wire interrupt_flag_set;
wire interrupt_flag_clear;
wire halt;

wire [14:0] cache_request_address;
wire [31:0] cache_line;
wire cache_miss; 


wire data_memory_success;
wire bank_switch;

wire is_executing;

cpu_pipeline #(.REGISTER_BITS(REGISTER_BITS), .BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) pip0
(
	CLK,
	RSTb,

	pipeline_stage0,
	pipeline_stage1,
	pipeline_stage2,
	pipeline_stage3,
	pipeline_stage4,

	pc_stage4,

	imm_reg,

	load_pc,
	new_pc,

	hazard_1,
	hazard_2,
	hazard_3,

	hazard_reg0,	
	modifies_flags0,

	hazard_reg1,
	hazard_reg2,
	hazard_reg3,
	modifies_flags1,
	modifies_flags2,
	modifies_flags3,

	interrupt_flag_set,
	interrupt_flag_clear,
	halt,

	interrupt,	
	irq,	

	cache_request_address, 
	cache_line,
	cache_miss, 

	data_memory_success,
	bank_switch,
	load_memory | store_memory,

	is_executing
);

wire [14:0] instruction_memory_address;
wire instruction_memory_rd_req;
wire instruction_memory_success;
wire [14:0] instruction_memory_requested_address;
wire [15:0] instruction_memory_data;

wire instruction_will_queue;

cpu_instruction_cache cache0 (
	CLK,
	RSTb,

	cache_request_address, 
	cache_line,
	cache_miss, 

	instruction_memory_address,
	instruction_memory_rd_req,	
	
	instruction_memory_success,	
	instruction_memory_requested_address,	
	instruction_memory_data,

	instruction_will_queue
);

wire load_memory;
wire store_memory;
wire [15:0] load_store_address;
wire [15:0] store_memory_data;
wire [1:0] store_memory_wr_mask;

wire [15:0] data_memory_data_out;
wire [1:0] data_memory_wr_mask_out;



cpu_memory_interface mem0 (
	CLK,
	RSTb,

	instruction_memory_address,
	instruction_memory_rd_req,

	instruction_memory_data,
	instruction_memory_requested_address, 
	instruction_memory_success,	
	instruction_will_queue,

	load_store_address[15:1],
	store_memory_data,
	load_memory,
	store_memory,
	store_memory_wr_mask,

	data_memory_data_out,
	data_memory_success,	
	data_memory_wr_mask_out,

	bank_switch,

	memory_address,	
	memory_out,
	memory_in,
	memory_wr_mask,
	memory_wr,
	memory_valid,		
	memory_ready,

	halt	
);

wire [REGISTER_BITS - 1:0] regA_sel;
wire [REGISTER_BITS - 1:0] regB_sel;
 
cpu_decode #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS), .REGISTER_BITS(REGISTER_BITS)) cpu_dec0
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
cpu_decode #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS), .REGISTER_BITS(REGISTER_BITS)) cpu_dec1
(
	CLK,
	RSTb,

	pipeline_stage0,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel0, /* register A select */
	regB_sel0  /* register B select */
);

wire [REGISTER_BITS - 1:0]  		regIn_sel;
wire [BITS - 1:0] 			regOutA_data;
wire [BITS - 1:0] 			regOutB_data;
wire [BITS - 1:0] 			regIn_data;

cpu_register_file
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
wire V;

wire [4:0] aluOp;
wire [BITS - 1:0] aluA;
wire [BITS - 1:0] aluB;

wire [ADDRESS_BITS - 1:0] ex_port_address;
wire [BITS - 1:0] ex_port_out;
wire ex_port_rd;
wire ex_port_wr;

cpu_execute #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_exec0
(
	CLK,
	RSTb,
	pipeline_stage2,		
	is_executing,
	Z,
	C,
	S,
	V,
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
	new_pc,
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
	S, /* sign flag */
	V  /* signed overflow flag */
);

cpu_writeback #(.REGISTER_BITS(REGISTER_BITS), .BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_wr0
(
	pipeline_stage4,		/* instruction in pipeline slot 4 */
	aluOut,
	memory_in, 
	port_in, 

	/* write back register select and data */
	regIn_sel,
	regIn_data,

	pc_stage4,
	data_memory_wr_mask_out,

	C,
	Z,
	S,
	V


);

cpu_port_interface #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_prt0 (
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

cpu_hazard haz0
(
	pipeline_stage0,

	regA_sel0,
	regB_sel0,

	hazard_reg0,	
	modifies_flags0,					

	hazard_reg1,	
	hazard_reg2,
	hazard_reg3,
	modifies_flags1,
	modifies_flags2,
	modifies_flags3,

	hazard_1,
	hazard_2,
	hazard_3
);


endmodule
