/*
 *
 *	SLURM16 CPU Top: the top level for the CPU
 *
 */

module slurm16_cpu_top
(
	input CLK,
	input RSTb,

	output [ADDRESS_BITS - 1:0] 	memory_address,
	input  [BITS - 1:0] 		memory_in,
	output [BITS - 1:0]		memory_out,
	output				memory_wr,	/* memory write */
	output 				memory_rd,	/* memory read */
	output [1:0]			memory_wr_mask, /* write mask - for byte wise access to memory */
	input				memory_success,

	output [ADDRESS_BITS - 2:0]	i_memory_address,  /* instruction memory address */	
	input  [BITS - 1:0]		i_data,		   /* instruction memory data */
	input				i_memory_success,  /* instruction memory success */

	output [ADDRESS_BITS - 1:0] 	port_address,
	input  [BITS - 1:0]		port_in,
	output [BITS - 1:0]		port_out,
	output				port_rd,
	output				port_wr,

	input  				interrupt,	/* interrupt line from interrupt controller */	
	input  [3:0]			irq,		/* irq from interrupt controller */
	output				cpu_debug_pin,

	output				debug_trigger,
	output [15:0]			debug_data,
	output 				debug_wr_enable
);

//assign cpu_debug_pin = 1'b0;

/* Machine is 16 bit with 16 bit address bus, and 128 registers */
localparam BITS = 16;
localparam ADDRESS_BITS = 16;
localparam REGISTER_BITS = 7;

wire instruction_request;
wire instruction_valid;
wire [14:0] instruction_address;
wire  [15:0] instruction_in;
wire  [14:0] instruction_address_in;

wire [15:0] pipeline_stage_0;
wire [15:0] pipeline_stage_1;
wire [15:0] pipeline_stage_2;
wire [15:0] pipeline_stage_3;
wire [15:0] pipeline_stage_4;

wire [15:0] pc_stage_4;

wire halt_request;

wire [15:0] load_pc_address;
wire load_pc_request;

wire interrupt_flag_clear;
wire interrupt_flag_set;

wire memory_request_successful = 1'b1;

wire [1:0] memory_mask_delayed = 2'd0;

wire nop_stage4;

wire load_interrupt_return_address;

wire cond_pass_in;

wire [REGISTER_BITS - 1:0] hazard_reg1;
wire [REGISTER_BITS - 1:0] hazard_reg2;
wire [REGISTER_BITS - 1:0] hazard_reg3;

wire modifies_flags1;
wire modifies_flags2;
wire modifies_flags3;

wire [REGISTER_BITS - 1:0]  hazard_reg0;
wire modifies_flags0;

wire hazard_1;
wire hazard_2;
wire hazard_3;

wire nop_stage_2;
wire nop_stage_4;

wire Z;
wire C;
wire V;
wire S;

wire Z_out;
wire C_out;
wire V_out;
wire S_out;

wire flags_load;

wire load_return_address;

wire cond_pass_stage4;

wire [11:0] imm_reg;

wire load_memory;
wire store_memory;

wire data_memory_success;

wire [31:0] cpu_debug_wire = {port_wr, port_address[14:0], port_out};

wire [15:0] interrupt_context_out;

wire [15:0] debug_data_pip;

assign debug_data = debug_data_pip;
//assign debug_wr_enable = (memory_address == 16'h4062);
assign debug_wr_enable = 1'b1; //(pc_stage_4 == 16'h2c0e);
//assign debug_data = {12'd0, V, S, C, Z}; //interrupt_context_out;

//assign debug_data = pc_stage_4;
//assign debug_wr_enable = (memory_wr && memory_address == 16'h3838);

slurm16_cpu_pipeline pip0 (
	CLK,
	RSTb,

	instruction_request,	
	instruction_valid,	
	instruction_address, 
	instruction_in,
	instruction_address_in,

	pipeline_stage_0,
	pipeline_stage_1,
	pipeline_stage_2,
	pipeline_stage_3,
	pipeline_stage_4,
 
	pc_stage_4,

	nop_stage_2,
	nop_stage_4,

	imm_reg,

	Z,
	C,
	V,
	S,

	Z_out,
	C_out,
	V_out,
	S_out,

	flags_load,

 	hazard_1, /* hazard between instruction in slot0 and slot1 */
        hazard_2, /* hazard between instruction in slot0 and slot2 */
        hazard_3, /* hazard between instruction in slot0 and slot3 */

        hazard_reg0,    /*  import hazard computation, it will move with pipeline in pipeline module */
        modifies_flags0,                                                /*  import flag hazard conditions */

        hazard_reg1,            /* export pipelined hazards */
        hazard_reg2,
        hazard_reg3,
        modifies_flags1,
        modifies_flags2,
        modifies_flags3,
	
	halt_request,

	interrupt,
	irq,

	load_pc_request,	
	load_pc_address,

	interrupt_flag_clear,
	interrupt_flag_set,

	data_memory_success,
	load_memory || store_memory,
	cond_pass_in,

	load_return_address,

	cond_pass_stage4,

	cpu_debug_pin,

	cpu_debug_wire,

	interrupt_context_out,
	regB,

	debug_trigger,
	debug_data_pip	
);

wire [15:0] load_store_address;
wire [15:0] store_memory_data;
wire [1:0] store_memory_wr_mask;

wire [15:0] data_memory_data_out;
wire [1:0] data_memory_wr_mask_out;

wire bank_switch;

/*	instruction_request,	
	instruction_valid,	
	instruction_address, 
	instruction_in,
	instruction_address_in,
*/

slurm16_cpu_memory_interface mem0 (
	CLK,
	RSTb,

	instruction_address,
	instruction_in,
	instruction_address_in, 
	instruction_valid,	

	load_store_address,
	store_memory_data,
	load_memory,
	store_memory,
	store_memory_wr_mask,

	data_memory_data_out,
	data_memory_success,	
	data_memory_wr_mask_out,

	memory_address,	
	memory_out,
	memory_in,
	memory_wr_mask,
	memory_wr,
	memory_rd,
	memory_success,

	i_memory_address,	
	i_data,
	i_memory_success
);

wire [REGISTER_BITS - 1:0] regA_sel;
wire [REGISTER_BITS - 1:0] regB_sel;
 
slurm16_cpu_decode #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS), .REGISTER_BITS(REGISTER_BITS)) cpu_dec0
(
	CLK,
	RSTb,

	pipeline_stage_1,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

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

	pipeline_stage_0,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel0, /* register A select */
	regB_sel0  /* register B select */
);

wire [REGISTER_BITS - 1:0]  		regIn_sel;
wire [BITS - 1:0] 			regA;
wire [BITS - 1:0] 			regB;
wire [BITS - 1:0] 			regIn_data;

slurm16_cpu_registers
#(.REG_BITS(REGISTER_BITS), .BITS(BITS)) reg0
(
	CLK,
	RSTb,
	regIn_sel,
	regA_sel,
	regB_sel,	
	regA,
	regB,
	regIn_data
);

wire [4:0] aluOp;
wire [BITS - 1:0] aluA;
wire [BITS - 1:0] aluB;

wire [ADDRESS_BITS - 1:0] ex_port_address;
wire [BITS - 1:0] ex_port_out;
wire ex_port_rd;
wire ex_port_wr;

//assign debug_data = load_store_address;

slurm16_cpu_execute exec0
(
	CLK,
	RSTb,

	pipeline_stage_2,		/* instruction in pipeline slot 2 */
	nop_stage_2,

	/* flags (for branches) */

	Z,
	C,
	S,
	V,

	/* registers in from decode stage */
	regA,
	regB,

	/* immediate register */
	imm_reg,

	/* memory op */
	load_memory,
	store_memory,
	load_store_address,
	store_memory_data,
	store_memory_wr_mask,

  	ex_port_address,
        ex_port_out,
        ex_port_rd,
        ex_port_wr,

	/* alu op */
	aluOp,
	aluA,
	aluB,

	/* load PC for branch / (i)ret, etc */
	load_pc_request,
	load_pc_address,

	interrupt_flag_set,
	interrupt_flag_clear,

	halt_request,

	cond_pass_in

);

wire [BITS - 1:0] aluOut;

slurm16_cpu_alu alu0
(
	CLK,	/* ALU has memory for flags */
	RSTb,

	aluA,
	aluB,
	aluOp,
	aluOut,

	C, /* carry flag */
	Z, /* zero flag */
	S, /* sign flag */
	V,  /* signed overflow flag */

	C_out,
	Z_out,
	S_out,
	V_out,

	flags_load

);

wire [REGISTER_BITS - 1:0] reg_wr_sel;
wire [15:0] reg_out;

assign regIn_sel = reg_wr_sel;
assign regIn_data = reg_out;

//assign debug_data = {15'd0,nop_stage_4}; //reg_out; //{9'h0, reg_wr_sel};
//assign debug_data = memory_in;
//assign debug_data = reg_out;
//assign debug_wr_enable = (reg_wr_sel == 7'd13);

slurm16_cpu_writeback wb0
(
	pipeline_stage_4,		/* instruction in pipeline slot 4 */
	aluOut,
	memory_in, 
	port_in,

	nop_stage_4,	/* instruction in pipeline slot 4 is NOP'd out */

	/* write back register select and data */
	reg_wr_sel,
	reg_out,

	pc_stage_4,
	data_memory_wr_mask_out,

	load_return_address,

	/* conditional instruction passed in stage2 */
	cond_pass_stage4,

	Z,
	C,
	S,
	V,

	interrupt_context_out
);

cpu_port_interface #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS)) cpu_prt0 (
	CLK,
	RSTb,

	ex_port_address,
	ex_port_out,
	ex_port_rd,
	ex_port_wr,

	port_address,
	port_out,
	port_rd,
	port_wr
);

slurm16_cpu_hazard haz0
(
	pipeline_stage_0,

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
