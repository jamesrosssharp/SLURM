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

	input [BITS - 1:0] memory_in,
	input [ADDRESS_BITS - 1:0] memory_address, /* this will point to PC + 1, which we will progress 
												  through the pipeline so we can store it for bl (branch and link) instructions */

	input is_executing, /* CPU is executing */

	input stall,		/* pipeline is stalled */
	input stall_start,  /* pipeline has started to stall */
	input stall_end,	/* pipeline is about to end stall */

	output [BITS - 1:0] pipeline_stage0,
	output [BITS - 1:0] pipeline_stage1,
	output [BITS - 1:0] pipeline_stage2,
	output [BITS - 1:0] pipeline_stage3,
	output [BITS - 1:0] pipeline_stage4,

	output [ADDRESS_BITS - 1:0] pc_stage4,

	output [BITS - 1:0] imm_reg,

	input load_pc,	/* PC is loaded from execute stage - i.e. branch / (i)ret - flush pipeline and mask until pipeline is synched */ 

	input [REGISTER_BITS - 1:0] hazard_reg0,	/*  import hazard computation, it will move with pipeline in pipeline module */
	input modifies_flags0,						/*  import flag hazard conditions */ 

	output [REGISTER_BITS - 1:0] hazard_reg1,		/* export pipelined hazards */
	output [REGISTER_BITS - 1:0] hazard_reg2,
	output [REGISTER_BITS - 1:0] hazard_reg3,
	output modifies_flags1,
	output modifies_flags2,
	output modifies_flags3,

	input hazard1,
	input memory_is_instruction,

	input			interrupt_flag_set,	/* cpu interrupt flag set */
	input			interrupt_flag_clear,	/* cpu interrupt flag clear */
	
	input  			interrupt,		/* interrupt line from interrupt controller */	
	input  [3:0]	irq,				/* irq from interrupt controller */

	input [ADDRESS_BITS - 1:0] pc_in,

	output wake,

	input stall_memory_pipeline_stage3
);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [BITS - 1:0] pipeline_stage1_r, pipeline_stage1_r_next;
reg [BITS - 1:0] pipeline_stage2_r, pipeline_stage2_r_next;
reg [BITS - 1:0] pipeline_stage3_r, pipeline_stage3_r_next;
reg [BITS - 1:0] pipeline_stage4_r, pipeline_stage4_r_next;

reg [ADDRESS_BITS - 1:0] pc_stage1_r, pc_stage1_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage2_r, pc_stage2_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage3_r, pc_stage3_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage4_r, pc_stage4_r_next;

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

assign pc_stage4 = pc_stage4_r;

assign pipeline_stage0 = pipeline_stage0_r;
assign pipeline_stage1 = pipeline_stage1_r;
assign pipeline_stage2 = pipeline_stage2_r;
assign pipeline_stage3 = pipeline_stage3_r;
assign pipeline_stage4 = pipeline_stage4_r;

reg [11:0] imm_r;
reg [11:0] imm_r_next;

reg [BITS - 1:0] imm_stage2_r;
reg [BITS - 1:0] imm_stage2_r_next;

assign imm_reg = imm_stage2_r;

reg interrupt_flag_r, interrupt_flag_r_next;

reg wake_r;
assign wake = wake_r;

// FIFO Cache

wire [31:0] fifo_in = {memory_address, memory_in};

wire [31:0] fifo_out;
wire fifo_empty;
wire fifo_full;

wire wr_fifo = memory_is_instruction;
wire rd_fifo = is_executing && !stall && !fifo_empty;

cpu_instruction_cache_fifo #(
	.FIFO_DEPTH_BITS(4),
	.FIFO_WIDTH_BITS(32)	
) cache0
(
	CLK,
	RSTb && !load_pc,

	fifo_in,
	fifo_out,

	fifo_empty,	
	fifo_full,	

	wr_fifo,
	rd_fifo	
);

reg fifo_empty_reg;
reg [3:0] branch_mask_count_r;

wire branch_mask = branch_mask_count_r != 4'd0;

always @(posedge CLK)	fifo_empty_reg <= fifo_empty;

wire [15:0] pipeline_stage0_r = fifo_empty_reg || branch_mask || stall ? NOP_INSTRUCTION  : fifo_out[15:0];
wire [15:0] pc_stage0_r = fifo_out[31:16];

// Mask branches (give 4 cycles from when branch is taken to mask input to
// pipeline)

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		branch_mask_count_r <= 4'd0;
	else if (load_pc == 1'b1)
		branch_mask_count_r <= 4'd4;
	else if (branch_mask_count_r != 4'd0)
		branch_mask_count_r <= branch_mask_count_r - 1;

end

// Branch target

reg [ADDRESS_BITS - 1:0] branch_target;

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		branch_target <= {ADDRESS_BITS{1'b0}};
	else
		branch_target <= pc_in;
end

// Sequential logic
always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pipeline_stage1_r <= NOP_INSTRUCTION;
		pipeline_stage2_r <= NOP_INSTRUCTION;
		pipeline_stage3_r <= NOP_INSTRUCTION;
		pipeline_stage4_r <= NOP_INSTRUCTION;
		pc_stage1_r <= {ADDRESS_BITS{1'b0}};
		pc_stage2_r <= {ADDRESS_BITS{1'b0}};
		pc_stage3_r <= {ADDRESS_BITS{1'b0}};
		pc_stage4_r <= {ADDRESS_BITS{1'b0}};
		imm_r 			<= 12'h000;
		imm_stage2_r 	<= {BITS{1'b0}};
		hazard_reg1_r	<= R0;
		hazard_reg2_r	<= R0;
		hazard_reg3_r	<= R0;
		modifies_flags1_r <= 1'b0;
		modifies_flags2_r <= 1'b0;
		modifies_flags3_r <= 1'b0;
		interrupt_flag_r <= 1'b0;
	end else begin
		pipeline_stage1_r <= pipeline_stage1_r_next;
		pipeline_stage2_r <= pipeline_stage2_r_next;
		pipeline_stage3_r <= pipeline_stage3_r_next;
		pipeline_stage4_r <= pipeline_stage4_r_next;
		pc_stage1_r <= pc_stage1_r_next;
		pc_stage2_r <= pc_stage2_r_next;
		pc_stage3_r <= pc_stage3_r_next;
		pc_stage4_r <= pc_stage4_r_next;
		imm_r 			<= imm_r_next;
		imm_stage2_r 	<= imm_stage2_r_next;
		hazard_reg1_r	<= hazard_reg1_r_next;
		hazard_reg2_r	<= hazard_reg2_r_next;
		hazard_reg3_r	<= hazard_reg3_r_next;
		interrupt_flag_r <= interrupt_flag_r_next;
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

// Wake

always @(*)
begin

	wake_r = 1'b0;		

	if (interrupt)
		wake_r = 1'b1;

end

//
//
//


//
//	Actual pipeline logic
//

reg clear_imm;

always @(*) 
begin
	pipeline_stage1_r_next = pipeline_stage0_r;
	pipeline_stage2_r_next = pipeline_stage1_r;
	pipeline_stage3_r_next = pipeline_stage2_r;
	pipeline_stage4_r_next = pipeline_stage3_r;

	pc_stage1_r_next = pc_stage0_r;
	pc_stage2_r_next = pc_stage1_r;
	pc_stage3_r_next = pc_stage2_r;
	pc_stage4_r_next = pc_stage3_r;

	hazard_reg1_r_next = hazard_reg0;
	hazard_reg2_r_next = hazard_reg1_r;
	hazard_reg3_r_next = hazard_reg2_r;



	if (load_pc == 1'b1) begin
		pipeline_stage1_r_next = NOP_INSTRUCTION;
		pipeline_stage2_r_next = NOP_INSTRUCTION;
	end
end

// Immediate register
always @(*)
begin
	imm_r_next = {12{1'b0}};

	// Don't change on a nop
	if ((pipeline_stage1_r == NOP_INSTRUCTION) && !load_pc) 
		imm_r_next = imm_r;

	if ((!is_executing || stall) && !load_pc && !(clear_imm && pipeline_stage1_r != NOP_INSTRUCTION))
		 imm_r_next = imm_r;

	imm_stage2_r_next = imm_stage2_r;

	if (is_executing)
			imm_stage2_r_next 	= {imm_r, imm_lo_from_ins(pipeline_stage1_r)};

	casex (pipeline_stage1_r)
		INSTRUCTION_CASEX_IMM:   	/* imm */
			/* there might be a spurious imm in p1 on a branch */
			if (!load_pc)
				imm_r_next 	= imm_r_from_ins(pipeline_stage1_r);
		default: ;
	endcase
end

endmodule
