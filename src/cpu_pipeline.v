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

	input				interrupt,		/* interrupt line from interrupt controller */	
	input  [3:0]			irq,			/* irq from interrupt controller */

	/* instruction cache memory interface */
	output 	[14:0] cache_request_address, /* request address from the cache */
	input 	[31:0] cache_line,
	input 	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	/* data memory interface */
	input	data_memory_success,
	input   bank_switch,	/* memory interface is switching banks or otherwise busy */
	input	data_memory_was_requested,

	/* cpu state */
	output  is_executing

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

reg [3:0] state, next_state, prev_state;

assign is_executing = (state != st_halt);

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state <= st_execute;
		prev_state <= st_halt;
	end else begin
		state <= next_state;
		prev_state <= state;
	end
end

always @(*)
begin
	next_state = state;

	case (state)
		st_halt:
			if (interrupt == 1'b1)
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
	endcase

	// In some states, we can jump out of the state if there is a memory
	// stall (which trumps everything)
	
	case (state)
		st_wait_cache1,
		st_wait_cache2,
		st_stall_2,
		st_stall_3,
		st_stall_4:
			if (data_memory_was_requested && (data_memory_success == 1'b0))
				next_state = st_mem_stall1;
		default: ;
	endcase
end

// PC

reg [14:0] pc, pc_next, pc_prev, pc_prev_next;

assign cache_request_address = pc;

reg load_pc_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pc_prev <= 15'd0;
		pc <= 15'd0;
		load_pc_r <= 1'b0;
	end
	else begin
		pc <= pc_next;
		pc_prev <= pc_prev_next;
		load_pc_r <= load_pc;
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
			
			 if	((hazard_1 == 1'b1) || (hazard_2 == 1'b1) || (hazard_3 == 1'b1) ||
				(cache_miss == 1'b1)) begin
				pc_prev_next = pc_prev;
				pc_next = pc_prev;
			end	
		end			
		st_wait_cache1:	begin
			pc_prev_next = pc_prev;
			pc_next = pc_prev;
		end
		st_wait_cache2:	;
		st_stall_2:	;
		st_stall_3:	;
		st_stall_4:	;
		st_mem_stall1:	
		begin
			pc_prev_next = pc_prev;
			pc_next = pc_prev;
		end
		st_mem_stall2:	;
	endcase

	if (load_pc) begin
		pc_next = new_pc[15:1];
		pc_prev_next = new_pc[15:1];
	end

	if ((data_memory_was_requested == 1'b1) && (data_memory_success == 1'b0)) begin
		pc_next = pc_stage3_r;
		pc_prev_next = pc_stage3_r;
	end 

end

// Pipeline

reg [15:0] pipeline_stage0_r, pipeline_stage0_r_next;
reg [14:0] pc_stage0_r, pc_stage0_r_next;

reg [15:0] pipeline_stage1_r, pipeline_stage1_r_next;
reg [14:0] pc_stage1_r, pc_stage1_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg1_r, hazard_reg1_r_next;
reg modifies_flags1_r, modifies_flags1_r_next;

reg [15:0] pipeline_stage2_r, pipeline_stage2_r_next;
reg [14:0] pc_stage2_r, pc_stage2_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg2_r, hazard_reg2_r_next;
reg modifies_flags2_r, modifies_flags2_r_next;

reg [15:0] pipeline_stage3_r, pipeline_stage3_r_next;
reg [14:0] pc_stage3_r, pc_stage3_r_next;
reg [REGISTER_BITS - 1:0] hazard_reg3_r, hazard_reg3_r_next;
reg modifies_flags3_r, modifies_flags3_r_next;

reg [15:0] pipeline_stage4_r, pipeline_stage4_r_next;
reg [14:0] pc_stage4_r, pc_stage4_r_next;

assign pipeline_stage0 = pipeline_stage0_r;
assign pipeline_stage1 = pipeline_stage1_r;
assign pipeline_stage2 = pipeline_stage2_r;
assign pipeline_stage3 = pipeline_stage3_r;
assign pipeline_stage4 = pipeline_stage4_r;

assign pc_stage4 = {pc_stage4_r + 15'd1, 1'b0};

assign hazard_reg1 = hazard_reg1_r;
assign hazard_reg2 = hazard_reg2_r;
assign hazard_reg3 = hazard_reg3_r;

assign modifies_flags1 = modifies_flags1_r;
assign modifies_flags2 = modifies_flags2_r;
assign modifies_flags3 = modifies_flags3_r;


always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pipeline_stage0_r 	<= 16'd0;
		pc_stage0_r 		<= 15'd0;

		pipeline_stage1_r 	<= 16'd0;
		pc_stage1_r 		<= 15'd0;
		hazard_reg1_r 		<= {REGISTER_BITS{1'b0}};
		modifies_flags1_r 	<= 1'b0;

		pipeline_stage2_r 	<= 16'd0;
		pc_stage2_r 		<= 15'd0;
		hazard_reg2_r 		<= {REGISTER_BITS{1'b0}};
		modifies_flags2_r 	<= 1'b0;

		pipeline_stage3_r 	<= 16'd0;
		pc_stage3_r 		<= 15'd0;
		hazard_reg3_r 		<= {REGISTER_BITS{1'b0}};
		modifies_flags3_r 	<= 1'b0;

		pipeline_stage4_r 	<= 16'd0;
		pc_stage4_r 		<= 15'd0;

	end else begin

		pipeline_stage0_r 	<= pipeline_stage0_r_next;
		pc_stage0_r 		<= pc_stage0_r_next;

		pipeline_stage1_r 	<= pipeline_stage1_r_next;
		pc_stage1_r 		<= pc_stage1_r_next;
		hazard_reg1_r 		<= hazard_reg1_r_next;
		modifies_flags1_r 	<= modifies_flags1_r_next;

		pipeline_stage2_r 	<= pipeline_stage2_r_next;
		pc_stage2_r 		<= pc_stage2_r_next;
		hazard_reg2_r 		<= hazard_reg2_r_next;
		modifies_flags2_r 	<= modifies_flags2_r_next;

		pipeline_stage3_r 	<= pipeline_stage3_r_next;
		pc_stage3_r 		<= pc_stage3_r_next;
		hazard_reg3_r 		<= hazard_reg3_r_next;
		modifies_flags3_r 	<= modifies_flags3_r_next;

		pipeline_stage4_r 	<= pipeline_stage4_r_next;
		pc_stage4_r 		<= pc_stage4_r_next;

	end
end

always @(*)
begin

	pipeline_stage0_r_next 	= pipeline_stage0_r;
	pc_stage0_r_next 	= pc_stage0_r;

	pipeline_stage1_r_next 	= pipeline_stage1_r;
	pc_stage1_r_next 	= pc_stage1_r;
	hazard_reg1_r_next 	= hazard_reg1_r;
	modifies_flags1_r_next 	= modifies_flags1_r;

	pipeline_stage2_r_next 	= pipeline_stage2_r;
	pc_stage2_r_next 	= pc_stage2_r;
	hazard_reg2_r_next 	= hazard_reg2_r;
	modifies_flags2_r_next 	= modifies_flags2_r;

	pipeline_stage3_r_next 	= pipeline_stage3_r;
	pc_stage3_r_next 	= pc_stage3_r;
	hazard_reg3_r_next 	= hazard_reg3_r;
	modifies_flags3_r_next 	= modifies_flags3_r;

	pipeline_stage4_r_next 	= pipeline_stage4_r;
	pc_stage4_r_next 	= pc_stage4_r;


	case (state)
		st_halt:	;
		st_execute: begin 
		
			if (cache_miss == 1'b0 && (state == prev_state) && (load_pc_r == 1'b0)) begin
				pipeline_stage0_r_next 	= cache_line[15:0];
				pc_stage0_r_next 	= cache_line[31:17];
			end else begin
				pipeline_stage0_r_next  = NOP_INSTRUCTION;
				pc_stage0_r_next	= pc_prev;
			end

			pipeline_stage1_r_next 	= pipeline_stage0_r;
			pc_stage1_r_next 	= pc_stage0_r;
			hazard_reg1_r_next 	= hazard_reg0;
			modifies_flags1_r_next 	= modifies_flags0;

			pipeline_stage2_r_next 	= pipeline_stage1_r;
			pc_stage2_r_next 	= pc_stage1_r;
			hazard_reg2_r_next 	= hazard_reg1_r;
			modifies_flags2_r_next 	= modifies_flags1_r;

			pipeline_stage3_r_next 	= pipeline_stage2_r;
			pc_stage3_r_next 	= pc_stage2_r;
			hazard_reg3_r_next 	= hazard_reg2_r;
			modifies_flags3_r_next 	= modifies_flags2_r;

			pipeline_stage4_r_next 	= pipeline_stage3_r;
			pc_stage4_r_next 	= pc_stage3_r;



		end			
		st_wait_cache1,
		st_wait_cache2,
		st_stall_2,
		st_stall_3,
		st_stall_4: begin	
			pipeline_stage0_r_next  = NOP_INSTRUCTION;
			pc_stage0_r_next	= pc_prev;
		
			pipeline_stage1_r_next 	= pipeline_stage1_r;
			pc_stage1_r_next 	= pc_stage1_r;
			hazard_reg1_r_next 	= hazard_reg1;
			modifies_flags1_r_next 	= modifies_flags1;

			pipeline_stage2_r_next 	= NOP_INSTRUCTION;
			pc_stage2_r_next 	= pc_stage1_r;
			hazard_reg2_r_next 	= R0;
			modifies_flags2_r_next 	= 1'b0;

			pipeline_stage3_r_next 	= pipeline_stage2_r;
			pc_stage3_r_next 	= pc_stage2_r;
			hazard_reg3_r_next 	= hazard_reg2_r;
			modifies_flags3_r_next 	= modifies_flags2_r;

			pipeline_stage4_r_next 	= pipeline_stage3_r;
			pc_stage4_r_next 	= pc_stage3_r;




		end
		st_mem_stall1,
		st_mem_stall2:	begin
				pipeline_stage0_r_next  = NOP_INSTRUCTION;
				pc_stage0_r_next	= pc_stage0_r;
			
				pipeline_stage1_r_next 	= NOP_INSTRUCTION;
				pc_stage1_r_next 	= pc_stage1_r;
				hazard_reg1_r_next 	= R0;
				modifies_flags1_r_next 	= 1'b0;

				pipeline_stage2_r_next 	= NOP_INSTRUCTION;
				pc_stage2_r_next 	= pc_stage2_r;
				hazard_reg2_r_next 	= R0;
				modifies_flags2_r_next 	= 1'b0;

				pipeline_stage3_r_next 	= pipeline_stage2_r;
				pc_stage3_r_next 	= pc_stage2_r;
				hazard_reg3_r_next 	= R0;
				modifies_flags3_r_next 	= 1'b0;

				pipeline_stage4_r_next 	= pipeline_stage3_r;
				pc_stage4_r_next 	= pc_stage3_r;
		
		end
	endcase

	if (load_pc == 1'b1) begin
			pipeline_stage0_r_next  = NOP_INSTRUCTION;
			pc_stage0_r_next	= new_pc[15:1];
		
			pipeline_stage1_r_next 	= NOP_INSTRUCTION;
			pc_stage1_r_next 	= new_pc[15:1];
			hazard_reg1_r_next 	= R0;
			modifies_flags1_r_next 	= 1'b0;

			pipeline_stage2_r_next 	= NOP_INSTRUCTION;
			pc_stage2_r_next 	= new_pc[15:1];
			hazard_reg2_r_next 	= R0;
			modifies_flags2_r_next 	= 1'b0;	
	end

	case (state)
		st_execute,  st_wait_cache1, 
                  st_wait_cache2,
                  st_stall_2,     
                  st_stall_3,
                  st_stall_4:

			if ((data_memory_was_requested == 1'b1) && (data_memory_success == 1'b0)) begin

				pipeline_stage0_r_next  = NOP_INSTRUCTION;
				pc_stage0_r_next	= pc_stage3_r;
			
				pipeline_stage1_r_next 	= NOP_INSTRUCTION;
				pc_stage1_r_next 	= pc_stage3_r;
				hazard_reg1_r_next 	= R0;
				modifies_flags1_r_next 	= 1'b0;

				pipeline_stage2_r_next 	= pipeline_stage4_r;
				pc_stage2_r_next 	= pc_stage4_r;
				hazard_reg2_r_next 	= R0;
				modifies_flags2_r_next 	= 1'b0;

				pipeline_stage3_r_next 	= NOP_INSTRUCTION;
				pc_stage3_r_next 	= pc_stage4_r;
				hazard_reg3_r_next 	= R0;
				modifies_flags3_r_next 	= 1'b0;

				pipeline_stage4_r_next 	= NOP_INSTRUCTION;
				pc_stage4_r_next 	= pc_stage4_r;

			end
		default: ;
	endcase

end

// Imm reg

reg [11:0] imm_r;
reg [11:0] imm_r_next;

reg [BITS - 1:0] imm_stage2_r;
reg [BITS - 1:0] imm_stage2_r_next;

assign imm_reg = imm_stage2_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		imm_r 		<= 12'd0;
		imm_stage2_r 	<= 16'd0;
	end else begin
		imm_r 		<= imm_r_next;
		imm_stage2_r 	<= imm_stage2_r_next;
	end
end

always @(*)
begin
	imm_r_next = {12{1'b0}};

	// Don't change on a nop
	if ((pipeline_stage1_r == NOP_INSTRUCTION) && (load_pc == 1'b0)) 
		imm_r_next = imm_r;

	imm_stage2_r_next = imm_stage2_r;

	if (prev_state == st_execute)
		imm_stage2_r_next 	= {imm_r, imm_lo_from_ins(pipeline_stage1_r)};

	casex (pipeline_stage1_r)
		INSTRUCTION_CASEX_IMM:   	/* imm */
			/* there might be a spurious imm in p1 on a branch */
			imm_r_next 	= imm_r_from_ins(pipeline_stage1_r);
		default: ;
	endcase

	if (load_pc_r == 1'b1) begin
		imm_stage2_r_next = 16'd0;
		imm_r_next = 12'd0;
	end
end

// Interrupt flag


endmodule
