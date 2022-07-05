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

	input hazard_1, /* hazard between instruction in slot0 and slot1 */
	input hazard_2, /* hazard between instruction in slot0 and slot2 */
	input hazard_3, /* hazard between instruction in slot0 and slot3 */

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
	input				halt,
	input 				wake,

	input				interrupt,		/* interrupt line from interrupt controller */	
	input  [3:0]			irq,			/* irq from interrupt controller */

	/* instruction cache memory interface */
	output 	[14:0] cache_request_address, /* request address from the cache */
	input 	[31:0] cache_line,
	input 	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	input   invalidate_cache,  /* asserted in execute stage to invalidate cache */
	input 	invalidation_done, /* asserted when cache has been invalidated */

	/* data memory interface */
	input	data_memory_success,
	input   bank_switch,	/* memory interface is switching banks or otherwise busy */
	input	data_memory_was_requested

);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

// CPU State machine

localparam st_halt 		= 4'd0;
localparam st_execute 		= 4'd1;
localparam st_wait_cache1 	= 4'd2;
localparam st_wait_cache2	= 4'd3;
localparam st_stall_2		= 4'd4;
localparam st_stall_3		= 4'd5;
localparam st_stall_4		= 4'd6;
localparam st_mem_stall1	= 4'd7;
localparam st_mem_stall2	= 4'd8;
localparam st_invalidate_cache	= 4'd9;
localparam st_wait_invalidate	= 4'd10;

reg [3:0] state, next_state;

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		state <= st_wait_invalidate;
	else
		state <= next_state;
end

always @(*)
begin
	next_state = state;

	case (state)
		st_halt:
			if (wake == 1'b1)
				next_state = st_execute;
		st_execute: begin
			// In order of priority (each item higher up the chain
			// trumps the lower items):
			// Memory stall?

			if (data_memory_was_requested && (data_memory_success == 1'b0))
				next_state = st_mem_stall1;

			// Hazard?
			else if (hazard_1 == 1'b1)
				next_state = st_stall_2;
			else if (hazard_2 == 1'b1)
				next_state = st_stall_3;
			else if (hazard_3 == 1'b1)
				next_state = st_stall_4;	

			// Cache invalidate?
			else if (invalidate_cache == 1'b1)
				next_state = st_invalidate_cache;
			// Cache miss?
			else if (cache_miss == 1'b1)
				next_state = st_wait_cache1;
		end
		st_wait_cache1:
			// Wait state while PC returns to previous value
			next_state = st_wait_cache2;	
			
		st_wait_cache2:
			if (cache_miss == 1'b0)	
				next_state = st_execute;
		st_stall_2:
			next_state = st_stall_3;
		st_stall_3:
			next_state = st_stall_4;
		st_stall_4:
			next_state = st_execute;
		st_mem_stall1:
			// Wait state while PC returns to previous value
			next_state = st_mem_stall2;
		st_mem_stall2:
			if (bank_switch == 1'b0)
				next_state = st_execute;	
		st_invalidate_cache:
			next_state = st_wait_invalidate;
		st_wait_invalidate:
			if (invalidation_done == 1'b1)
				next_state = st_execute;

	endcase

	// In some states, we can jump out of the state if there is a memory
	// stall (which trumps everything)
	
	case (state)
		st_wait_cache1,
		st_wait_cache2,
		st_stall_2,
		st_stall_3,
		st_stall_4,
		st_invalidate_cache,
		st_wait_invalidate:
			if (data_memory_was_requested && (data_memory_success == 1'b0))
				next_state = st_mem_stall1;
		default: ;
	endcase
end

// PC

reg [14:0] pc, pc_next, pc_prev, pc_prev_next;

assign cache_request_address = pc;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pc_prev <= 15'd0;
		pc <= 15'd0;
	end
	else begin
		pc <= pc_next;
		pc_prev <= pc_prev_next;
	end
end

always @(*)
begin
	pc_next = pc;
	pc_prev_next = pc;


	case (state)
		st_halt:	;
		st_execute: begin 
			pc_next = pc + 1;
			
			if ((data_memory_was_requested && (data_memory_success == 1'b0)) || 
				(hazard_1 == 1'b1) || (hazard_2 == 1'b1) || (hazard_3 == 1'b1) ||
				(invalidate_cache == 1'b1) || (cache_miss == 1'b1)) begin
				pc_prev_next = pc_prev;
				pc_next = pc_prev;
			end	
		end			
		st_wait_cache1:	;
		st_wait_cache2:	;
		st_stall_2:	;
		st_stall_3:	;
		st_stall_4:	;
		st_mem_stall1:	;
		st_mem_stall2:	;
		st_invalidate_cache:	;
		st_wait_invalidate:	;
	endcase

end


// Pipeline



// Imm reg



// Interrupt flag


endmodule
