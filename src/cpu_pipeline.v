/*
 *
 *	CPU pipeline : pipeline
 *
 */

module slurm16_cpu_pipeline #(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] memory_in,

	input is_executing, /* CPU is executing */

	input stall,		/* pipeline is stalled */
	input stall_start,  /* pipeline has started to stall */
	input stall_end,	/* pipeline is about to end stall */

	output [BITS - 1:0] pipeline_stage0,
	output [BITS - 1:0] pipeline_stage1,
	output [BITS - 1:0] pipeline_stage2,
	output [BITS - 1:0] pipeline_stage3,
	output [BITS - 1:0] pipeline_stage4

);

reg [BITS - 1:0] pipeline_stage0_r, pipeline_stage0_r_next;
reg [BITS - 1:0] pipeline_stage1_r, pipeline_stage1_r_next;
reg [BITS - 1:0] pipeline_stage2_r, pipeline_stage2_r_next;
reg [BITS - 1:0] pipeline_stage3_r, pipeline_stage3_r_next;
reg [BITS - 1:0] pipeline_stage4_r, pipeline_stage4_r_next;

assign pipeline_stage0 = pipeline_stage0_r;
assign pipeline_stage1 = pipeline_stage1_r;
assign pipeline_stage2 = pipeline_stage2_r;
assign pipeline_stage3 = pipeline_stage3_r;
assign pipeline_stage4 = pipeline_stage4_r;

localparam NOP = {BITS{1'b0}};	// NOP Instruction is all zeros

reg [1:0] mask_count_r, mask_count_r_next;
reg prev_executing;

// Sequential logic
always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pipeline_stage0_r <= NOP;
		pipeline_stage1_r <= NOP;
		pipeline_stage2_r <= NOP;
		pipeline_stage3_r <= NOP;
		pipeline_stage4_r <= NOP;
		prev_executing <= 1'b0;
		mask_count_r <= 2'd0;
	end else begin
		pipeline_stage0_r <= pipeline_stage0_r_next;
		pipeline_stage1_r <= pipeline_stage1_r_next;
		pipeline_stage2_r <= pipeline_stage2_r_next;
		pipeline_stage3_r <= pipeline_stage3_r_next;
		pipeline_stage4_r <= pipeline_stage4_r_next;
		prev_executing <= is_executing;
		mask_count_r <= mask_count_r_next;
	end
end

// Combinational logic

// Mask counter - we don't start loading the pipeline for 3 cycles from when we start executing
// So we instead mask with NOPs until the PC has propagated through to memory data.
// It is expensive to start and stop execution.

always @(*)
begin
	if (prev_executing == 1'b0 && is_executing == 1'b1) 
		mask_count_r_next = 2'd1;
	else if (mask_count_r > 2'd0)
		mask_count_r_next = mask_count_r - 1;
	else
		mask_count_r_next = 2'd0;
end

//
//	Actual pipeline logic
//

always @(*) 
begin
	// execution paused

	pipeline_stage0_r_next = pipeline_stage0_r;
	pipeline_stage1_r_next = pipeline_stage1_r;
	pipeline_stage2_r_next = pipeline_stage2_r;
	pipeline_stage3_r_next = pipeline_stage3_r;
	pipeline_stage4_r_next = pipeline_stage4_r;
 
	// Else if executing, advance pipeline

	if (is_executing && prev_executing) begin
		if (mask_count_r == 2'd0)
			pipeline_stage0_r_next = memory_in;
		else
			pipeline_stage0_r_next = NOP;

		pipeline_stage1_r_next = pipeline_stage0_r;
		pipeline_stage2_r_next = pipeline_stage1_r;
		pipeline_stage3_r_next = pipeline_stage2_r;
		pipeline_stage4_r_next = pipeline_stage3_r;
	end
 
	// Else if pipeline stall, keep instructions in fetch and decode stages,
	// advance execute, memory, and write back stages
	
	if (stall == 1'b1) begin
		pipeline_stage0_r_next = pipeline_stage0_r;
		pipeline_stage1_r_next = pipeline_stage1_r;
		pipeline_stage2_r_next = NOP;
		pipeline_stage3_r_next = pipeline_stage2_r;
		pipeline_stage4_r_next = pipeline_stage3_r;
	end

end

endmodule
