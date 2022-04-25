/*
 *
 *	CPU pipeline : 
 *
 *	- manage pipeline
 *  - keep track of immediate register
 *
 */

module slurm16_cpu_pipeline #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
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

	output wake
);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [BITS - 1:0] pipeline_stage0_r, pipeline_stage0_r_next;
reg [BITS - 1:0] pipeline_stage1_r, pipeline_stage1_r_next;
reg [BITS - 1:0] pipeline_stage2_r, pipeline_stage2_r_next;
reg [BITS - 1:0] pipeline_stage3_r, pipeline_stage3_r_next;
reg [BITS - 1:0] pipeline_stage4_r, pipeline_stage4_r_next;

reg [ADDRESS_BITS - 1:0] pc_stage0_r, pc_stage0_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage1_r, pc_stage1_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage2_r, pc_stage2_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage3_r, pc_stage3_r_next;
reg [ADDRESS_BITS - 1:0] pc_stage4_r, pc_stage4_r_next;

reg [REGISTER_BITS - 1:0] hazard_reg1_r, hazard_reg1_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg2_r, hazard_reg2_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg3_r, hazard_reg3_r_next;

reg [BITS - 1:0] instruction_fifo [7:0];
reg [ADDRESS_BITS - 1:0] pc_fifo  [7:0];


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

reg [2:0] mask_count_r, mask_count_r_next;
reg [1:0] stall_mask_count_r, stall_mask_count_r_next;
reg [1:0] alt_pip_ld_count_r, alt_pip_ld_count_r_next;
reg [2:0] stall_count_r, stall_count_r_next; // pipeline fifo wr ptr
reg [2:0] stall_read_count_r, stall_read_count_r_next; // pipeline fifo rd ptr

reg interrupt_flag_r, interrupt_flag_r_next;

reg wake_r;
assign wake = wake_r;

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
		pipeline_stage0_r <= NOP_INSTRUCTION;
		pipeline_stage1_r <= NOP_INSTRUCTION;
		pipeline_stage2_r <= NOP_INSTRUCTION;
		pipeline_stage3_r <= NOP_INSTRUCTION;
		pipeline_stage4_r <= NOP_INSTRUCTION;
		pc_stage0_r <= {ADDRESS_BITS{1'b0}};
		pc_stage1_r <= {ADDRESS_BITS{1'b0}};
		pc_stage2_r <= {ADDRESS_BITS{1'b0}};
		pc_stage3_r <= {ADDRESS_BITS{1'b0}};
		pc_stage4_r <= {ADDRESS_BITS{1'b0}};
		mask_count_r 	<= 3'd1; // mask out of reset
		stall_mask_count_r 	<= 2'd0;
		alt_pip_ld_count_r 	<= 2'd0;
		imm_r 			<= 12'h000;
		imm_stage2_r 	<= {BITS{1'b0}};
		hazard_reg1_r	<= R0;
		hazard_reg2_r	<= R0;
		hazard_reg3_r	<= R0;
		modifies_flags1_r <= 1'b0;
		modifies_flags2_r <= 1'b0;
		modifies_flags3_r <= 1'b0;
		stall_count_r <= 3'd0;
		stall_read_count_r <= 3'd0;
		interrupt_flag_r <= 1'b0;
	end else begin
		pipeline_stage0_r <= pipeline_stage0_r_next;
		pipeline_stage1_r <= pipeline_stage1_r_next;
		pipeline_stage2_r <= pipeline_stage2_r_next;
		pipeline_stage3_r <= pipeline_stage3_r_next;
		pipeline_stage4_r <= pipeline_stage4_r_next;
		pc_stage0_r <= pc_stage0_r_next;
		pc_stage1_r <= pc_stage1_r_next;
		pc_stage2_r <= pc_stage2_r_next;
		pc_stage3_r <= pc_stage3_r_next;
		pc_stage4_r <= pc_stage4_r_next;
		mask_count_r 	<= mask_count_r_next;
		stall_mask_count_r 	<= stall_mask_count_r_next;
		alt_pip_ld_count_r 	<= alt_pip_ld_count_r_next;
		imm_r 			<= imm_r_next;
		imm_stage2_r 	<= imm_stage2_r_next;
		hazard_reg1_r	<= hazard_reg1_r_next;
		hazard_reg2_r	<= hazard_reg2_r_next;
		hazard_reg3_r	<= hazard_reg3_r_next;
		modifies_flags1_r <= modifies_flags1_r_next;
		modifies_flags2_r <= modifies_flags2_r_next;
		modifies_flags3_r <= modifies_flags3_r_next;
		stall_count_r <= stall_count_r_next; 
		stall_read_count_r <= stall_read_count_r_next; 
		interrupt_flag_r <= interrupt_flag_r_next;
	end
end

// Combinational logic

// Mask counter - we mask when starting execution from reset and also when PC is loaded 

always @(*)
begin
	if (load_pc)
		mask_count_r_next = 3'd2;
	else if (mask_count_r > 3'd0 && is_executing)
		mask_count_r_next = mask_count_r - 1;
	else
		mask_count_r_next = mask_count_r;
end

// stall masking

always @(*)
begin
	if (stall_end == 1'b1) 
		stall_mask_count_r_next = 2'd2;
	else if (stall_mask_count_r > 2'd0 && is_executing)
		stall_mask_count_r_next = stall_mask_count_r - 1;
	else  
		stall_mask_count_r_next = stall_mask_count_r;
end

// alternate pipeline load on start stall
always @(*)
begin
	if (stall_start == 1'b1 && !load_pc)
		alt_pip_ld_count_r_next = 2'd1;
	else if (alt_pip_ld_count_r > 2'd0)
		alt_pip_ld_count_r_next = alt_pip_ld_count_r - 1;
	else
		alt_pip_ld_count_r_next = alt_pip_ld_count_r;
end

// Stall count - fifo write pointer
always @(*)
begin
	if ((stall_start || alt_pip_ld_count_r > 2'd0) && !load_pc && (stall_mask_count_r == 2'd0) )
			stall_count_r_next = stall_count_r + 1;
	else if (load_pc)
		stall_count_r_next = 3'd0;
	else
		stall_count_r_next = stall_count_r;
end

// Stall read count - fifo read pointer
always @(*)
begin
	if (load_pc)
		stall_read_count_r_next = 3'd0;
	else if (reading_alt_pipeline)
		stall_read_count_r_next = stall_read_count_r + 1;
    else
		stall_read_count_r_next = stall_read_count_r;
end

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

// HACK!!!
//

reg [3:0] stall_count2_r;
always @(posedge CLK)
begin
	if (stall_start == 1'b1)
		stall_count2_r <= 4'd0;
	else if (stall == 1'b1)
		stall_count2_r <= stall_count2_r + 1;
end

// END HACK

//
//	Actual pipeline logic
//

reg reading_alt_pipeline;

always @(*) 
begin
	// execution paused

	// TODO: replace these registers with arrays, to make code neater and more concise

	pipeline_stage0_r_next = pipeline_stage0_r;
	pipeline_stage1_r_next = pipeline_stage1_r;
	pipeline_stage2_r_next = pipeline_stage2_r;
	pipeline_stage3_r_next = pipeline_stage3_r;
	pipeline_stage4_r_next = NOP_INSTRUCTION;

	pc_stage0_r_next = pc_stage0_r;
	pc_stage1_r_next = pc_stage1_r;
	pc_stage2_r_next = pc_stage2_r;
	pc_stage3_r_next = pc_stage3_r;
	pc_stage4_r_next = pc_stage4_r;
 
	hazard_reg1_r_next	= hazard_reg1_r;
	hazard_reg2_r_next	= hazard_reg2_r;
	hazard_reg3_r_next	= hazard_reg3_r;
	
	modifies_flags1_r_next = modifies_flags1_r;
	modifies_flags2_r_next = modifies_flags2_r;
	modifies_flags3_r_next = modifies_flags3_r;
	
	pipeline_clear_interrupt = 1'b0;

	// Else if executing, advance pipeline

	reading_alt_pipeline = 1'b0; // by default, we aren't reading from alternative pipeline

	if (is_executing) begin
		if (mask_count_r == 3'd0 && stall_mask_count_r == 2'd0 && memory_is_instruction) begin	// If we are not masking, take next instruction
			pipeline_stage0_r_next = memory_in; 
			pc_stage0_r_next = memory_address;

			if ((interrupt_flag_r == 1'b1) && (interrupt == 1'b1) && 
				((pipeline_stage1_r[15:12] != 4'd4) && (pipeline_stage2_r[15:12] != 4'd4) &&
				 (pipeline_stage0_r[15:12] != 4'd4) && (pipeline_stage3_r[15:12] != 4'd4) &&
				 (pipeline_stage4_r[15:12] != 4'd4)) /* not branch */
				) begin	// Interrupt?
				pipeline_stage0_r_next = {16'h050, irq}; // Inject INT Instruction
				pipeline_clear_interrupt = 1'b1;

				if (pipeline_stage0_r[15:12] == 4'h1) begin
					pc_stage0_r_next = memory_address - 4;
				end
				else begin
					pc_stage0_r_next = memory_address - 2;
				end

			end

		end else if (stall_mask_count_r > 2'd0) begin	// Else stall mask, take alt pipeline
			reading_alt_pipeline = 1'b1;
			pipeline_stage0_r_next = instruction_fifo[stall_read_count_r];
			pc_stage0_r_next = pc_fifo[stall_read_count_r];
		end else begin
			pipeline_stage0_r_next = NOP_INSTRUCTION;
			pc_stage0_r_next = branch_target; // We set this to branch target because if we are interrupted we need to come back to fetch this address
		end

		pipeline_stage1_r_next = pipeline_stage0_r;
		pipeline_stage2_r_next = pipeline_stage1_r;
		pipeline_stage3_r_next = pipeline_stage2_r;
		pipeline_stage4_r_next = pipeline_stage3_r;

		pc_stage1_r_next = pc_stage0_r;
		pc_stage2_r_next = pc_stage1_r;
		pc_stage3_r_next = pc_stage2_r;
		pc_stage4_r_next = pc_stage3_r;

		hazard_reg1_r_next	= hazard_reg0;
		hazard_reg2_r_next	= hazard_reg1_r;
		hazard_reg3_r_next	= hazard_reg2_r;

		modifies_flags1_r_next = modifies_flags0;
		modifies_flags2_r_next = modifies_flags1_r;
		modifies_flags3_r_next = modifies_flags2_r;

	end
 
	// Else if pipeline stall, keep instructions in fetch and decode stages,
	// advance execute, memory, and write back stages
	
	if (stall == 1'b1 && is_executing) begin
		pipeline_stage0_r_next = pipeline_stage0_r;
		pipeline_stage1_r_next = pipeline_stage1_r;
		pipeline_stage2_r_next = NOP_INSTRUCTION;	// Insert bubble
		pipeline_stage3_r_next = pipeline_stage2_r;
		pipeline_stage4_r_next = pipeline_stage3_r;

		pipeline_clear_interrupt = 1'b0; // If we previously set this flag, we need to clear it, otherwise interrupts will be permanently disabled
										 // without executing the interrupt

		pc_stage0_r_next = pc_stage0_r;
		pc_stage1_r_next = pc_stage1_r;
		// PC stage2 is don't care (with NOP)
		pc_stage3_r_next = pc_stage2_r;
		pc_stage4_r_next = pc_stage3_r;

		hazard_reg2_r_next	= R0; // Insert bubble
		hazard_reg3_r_next	= hazard_reg2_r;

		modifies_flags2_r_next = 1'b0; // Insert bubble
		modifies_flags3_r_next = modifies_flags2_r;

		// Preserve slot 1
		hazard_reg1_r_next  = hazard_reg1_r;
		modifies_flags1_r_next = modifies_flags1_r;
			
		/* if there is a hazard between p0 and p1, but not between p2/p3 and p0, release p1 to clear hazard */
		if (hazard1 && stall_count2_r >= 4'd2) begin
			pipeline_stage1_r_next = NOP_INSTRUCTION;
			pipeline_stage2_r_next = pipeline_stage1_r;

			pc_stage2_r_next = pc_stage1_r;

			hazard_reg2_r_next	= hazard_reg1_r; // Insert bubble
			hazard_reg1_r_next  = R0;

			modifies_flags2_r_next = modifies_flags1_r; // Insert bubble
			modifies_flags1_r_next = 1'b0;
		end
	end

	// If pc is being loaded due to branch or return, flush pipeline up to execute stage, 
	// since these instructions won't execute.

	if (load_pc == 1'b1) begin
		pipeline_stage0_r_next = NOP_INSTRUCTION;
		pipeline_stage1_r_next = NOP_INSTRUCTION;
		pipeline_stage2_r_next = NOP_INSTRUCTION;

		// NOTE: This probably isn't necessary due to masking. Consider removing
		hazard_reg1_r_next	= R0;
		hazard_reg2_r_next	= R0;
		hazard_reg3_r_next	= R0;
		modifies_flags1_r_next = 1'b0;
		modifies_flags2_r_next = 1'b0;	
	end

end

// Immediate register
always @(*)
begin
	imm_r_next = {12{1'b0}};

	// Don't change on a nop
	if ((pipeline_stage1_r == NOP_INSTRUCTION) && !load_pc) 
		imm_r_next = imm_r;

	if (!is_executing || stall && !load_pc)
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

// Alt pipeline: due to inertia reading from PC, to memory address register, instructions will bank up during a stall.
// So we fill an alternative pipeline all the time.

always @(posedge CLK)
begin
	if ((stall_start || alt_pip_ld_count_r > 2'd0) && !load_pc && (stall_mask_count_r == 2'd0)) begin
		instruction_fifo[stall_count_r] <= memory_is_instruction ? memory_in : NOP_INSTRUCTION;
		pc_fifo[stall_count_r] <= memory_is_instruction ? memory_address : {ADDRESS_BITS{1'b0}};
	end
end

endmodule
