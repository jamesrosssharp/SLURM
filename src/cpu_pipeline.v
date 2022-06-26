/*
 *
 *	CPU pipeline : 
 *
 *	- manage pipeline
 *  - keep track of immediate register
 *
 */

module cpu_pipeline #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	output [BITS - 1:0] pipeline_stage0,
	output [BITS - 1:0] pipeline_stage1,
	output [BITS - 1:0] pipeline_stage2,
	output [BITS - 1:0] pipeline_stage3,
	output [BITS - 1:0] pipeline_stage4,

	output [ADDRESS_BITS - 1:0] pc_stage4,

	output [BITS - 1:0] imm_reg,

	input load_pc,	/* PC is loaded from execute stage - i.e. branch / (i)ret - flush pipeline and mask until pipeline is synched */ 
	input [BITS - 1:0] new_pc,


	input [REGISTER_BITS - 1:0] 	hazard_reg0,	/*  import hazard computation, it will move with pipeline in pipeline module */
	input 				modifies_flags0,						/*  import flag hazard conditions */ 

	output [REGISTER_BITS - 1:0] 	hazard_reg1,		/* export pipelined hazards */
	output [REGISTER_BITS - 1:0] 	hazard_reg2,
	output [REGISTER_BITS - 1:0] 	hazard_reg3,
	output				modifies_flags1,
	output 				modifies_flags2,
	output 				modifies_flags3,

	input				interrupt_flag_set,	/* cpu interrupt flag set */
	input				interrupt_flag_clear,	/* cpu interrupt flag clear */
	
	input				interrupt,		/* interrupt line from interrupt controller */	
	input  [3:0]			irq,			/* irq from interrupt controller */

	/* instruction cache memory interface */
	output [ADDRESS_BITS - 1:0]	instruction_cache_memory_address, /* memory address for instruction cache to fetch from */
	input  [BITS - 1:0]		instruction_cache_memory_data,	  /* incoming data from memory to cache */
	output				instruction_cache_valid,	  /* address valid from cache */
	input				instruction_cache_rdy		  /* data ready to cache */

);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [2*BITS - 1:0] pipeline_stage1_r, pipeline_stage1_r_next;	// Each pipeline stage is tagged with PC in the high word
reg [2*BITS - 1:0] pipeline_stage2_r, pipeline_stage2_r_next;
reg [2*BITS - 1:0] pipeline_stage3_r, pipeline_stage3_r_next;
reg [2*BITS - 1:0] pipeline_stage4_r, pipeline_stage4_r_next;

reg [REGISTER_BITS - 1:0] hazard_reg1_r, hazard_reg1_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg2_r, hazard_reg2_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg3_r, hazard_reg3_r_next;

assign hazard_reg1 = hazard_reg1_r;
assign hazard_reg2 = hazard_reg2_r;
assign hazard_reg3 = hazard_reg3_r;

reg modifies_flags1_r, modifies_flags1_r_next;
reg modifies_flags2_r, modifies_flags2_r_next;
reg modifies_flags3_r, modifies_flags3_r_next;

assign modifies_flags1 = modifies_flags1_r;
assign modifies_flags2 = modifies_flags2_r;
assign modifies_flags3 = modifies_flags3_r;

assign pc_stage4 = pipeline_stage4_r[2*BITS - 1 : BITS];

assign pipeline_stage0 = pipeline_stage0_r[BITS - 1 : 0];
assign pipeline_stage1 = pipeline_stage1_r[BITS - 1 : 0];
assign pipeline_stage2 = pipeline_stage2_r[BITS - 1 : 0];
assign pipeline_stage3 = pipeline_stage3_r[BITS - 1 : 0];
assign pipeline_stage4 = pipeline_stage4_r[BITS - 1 : 0];

reg [11:0] imm_r;
reg [11:0] imm_r_next;

reg [BITS - 1:0] imm_stage2_r;
reg [BITS - 1:0] imm_stage2_r_next;

assign imm_reg = imm_stage2_r;

reg interrupt_flag_r, interrupt_flag_r_next;


reg [BITS - 1:0] pc, pc_next;

// CPU State machine

localparam cpust_halt 	  = 4'd0;
localparam cpust_execute  = 4'd1;
localparam cpust_rewindpc = 4'd2;
// TODO: More states, such as when there is a memory stall etc.

reg [3:0] state, state_next;

wire [2*BITS - 1 : 0] pipeline_stage0_r;

wire cache_miss;

// Instruction cache
cpu_instruction_cache cache0 (
	CLK,
	RSTb,

	pc, /* request address from the cache */
	
	pipeline_stage0_r,

	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	/* memory interface to memory arbiter */
	instruction_cache_valid,
	instruction_cache_rdy,
	instruction_cache_memory_address,
	instruction_cache_memory_data
);



// Sequential logic
always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pipeline_stage1_r <= {16'd0, NOP_INSTRUCTION};
		pipeline_stage2_r <= {16'd0, NOP_INSTRUCTION};
		pipeline_stage3_r <= {16'd0, NOP_INSTRUCTION};
		pipeline_stage4_r <= {16'd0, NOP_INSTRUCTION};
		imm_r			<= 12'h000;
		imm_stage2_r	<= {BITS{1'b0}};
		hazard_reg1_r	<= R0;
		hazard_reg2_r	<= R0;
		hazard_reg3_r	<= R0;
		modifies_flags1_r <= 1'b0;
		modifies_flags2_r <= 1'b0;
		modifies_flags3_r <= 1'b0;
		interrupt_flag_r <= 1'b0;
		pc <= 16'd0;
		state <= cpust_execute;
	end else begin
		pipeline_stage1_r <= pipeline_stage1_r_next;
		pipeline_stage2_r <= pipeline_stage2_r_next;
		pipeline_stage3_r <= pipeline_stage3_r_next;
		pipeline_stage4_r <= pipeline_stage4_r_next;
		imm_r			<= imm_r_next;
		imm_stage2_r	<= imm_stage2_r_next;
		hazard_reg1_r	<= hazard_reg1_r_next;
		hazard_reg2_r	<= hazard_reg2_r_next;
		hazard_reg3_r	<= hazard_reg3_r_next;
		interrupt_flag_r <= interrupt_flag_r_next;
		pc <= pc_next;
		state <= state_next;
	end
end

// Combinational logic

// Interrupt flag

reg pipeline_clear_interrupt;

always @(*)
begin
	interrupt_flag_r_next = interrupt_flag_r; 

	if (interrupt_flag_set) begin
		interrupt_flag_r_next = 1'b1;
	end

	if (interrupt_flag_clear || pipeline_clear_interrupt) begin
		interrupt_flag_r_next = 1'b0;
	end

end

//
//	Actual pipeline logic
//

reg clear_imm = 1'b0;

always @(*) 
begin
	pipeline_stage1_r_next = pipeline_stage0_r;
	pipeline_stage2_r_next = pipeline_stage1_r;
	pipeline_stage3_r_next = pipeline_stage2_r;
	pipeline_stage4_r_next = pipeline_stage3_r;

	hazard_reg1_r_next = hazard_reg0;
	hazard_reg2_r_next = hazard_reg1_r;
	hazard_reg3_r_next = hazard_reg2_r;

	modifies_flags1_r = modifies_flags0;
	modifies_flags2_r = modifies_flags1_r;
	modifies_flags3_r = modifies_flags2_r;

end

endmodule
