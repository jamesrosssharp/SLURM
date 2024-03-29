/*
 *	
 *	SLURM16 CPU pipeline  
 *
 *
 */

module slurm16_cpu_pipeline #(parameter REGISTER_BITS = 7, BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	/* Instruction input */
	output 	instruction_request,	/* asserted if the pipeline is fetching instructions */
	input 	instruction_valid,	/* asserted if the instruction requested was fetched from memory. deasserted on e.g. cache miss */
	output [ADDRESS_BITS - 2 : 0] 	instruction_address, /* the address to fetch the next instruction from */
	input  [BITS - 1 : 0] 		instruction_in,
	input  [ADDRESS_BITS - 2 : 0]	instruction_address_in,

	/* Pipeline stage output */
	output [BITS - 1 : 0]	pipeline_stage_0,
	output [BITS - 1 : 0]	pipeline_stage_1,
	output [BITS - 1 : 0]	pipeline_stage_2,
	output [BITS - 1 : 0]	pipeline_stage_3,
	output [BITS - 1 : 0]	pipeline_stage_4,
 
	output [ADDRESS_BITS - 1 : 0] pc_stage_4,

	output nop_stage_2, /* tell execute stage not to change any state (or request mem) */
	output nop_stage_4, /* do not write back */

	output [11:0] imm_reg,

	/* Flags input / output */

	input Z_in,
	input C_in,
	input V_in,
	input S_in,

	output reg Z_out,
	output reg C_out,
	output reg V_out,
	output reg S_out,

	output reg flags_load,	/* asserted on e.g. interrupt return to load flags from shadow register, or on memory except to reload flags from
				   faulting instruction */
	
	/* pipeline hazards */

 	input hazard_1, /* hazard between instruction in slot0 and slot1 */
        input hazard_2, /* hazard between instruction in slot0 and slot2 */
        input hazard_3, /* hazard between instruction in slot0 and slot3 */

        input [REGISTER_BITS - 1:0]     hazard_reg0,    /*  import hazard computation, it will move with pipeline in pipeline module */
        input                           modifies_flags0,                                                /*  import flag hazard conditions */

        output [REGISTER_BITS - 1:0]    hazard_reg1,            /* export pipelined hazards */
        output [REGISTER_BITS - 1:0]    hazard_reg2,
        output [REGISTER_BITS - 1:0]    hazard_reg3,
        output                          modifies_flags1,
        output                          modifies_flags2,
        output                          modifies_flags3,

	/* Control signals */

	input halt_request,		/* Sleep instruction requests CPU halt - must latch */

	input interrupt_req,		/* Interrupt request from interrupt controller */
	input [3:0] irq,		/* IRQ from interrupt controller */ 

	input load_pc_request,		/* Branch instruction */
	input [ADDRESS_BITS - 1 : 0] load_pc_address,

	input interrupt_flag_clear,
	input interrupt_flag_set,

	input memory_request_successful,	/* Memory request was successful. This means that an instruction in
						   pipeline stage 3 issued a memory request. For a load, this means
						   that memory data is available for writeback. For a store, this means
						   that the data write has been committed */

	input is_mem_request, 			/* execute stage logic will determine if the instruction is a memory request */
	input cond_pass_in,			/* conditional evaluates to true or false in execute stage */

	output load_return_address,		/* load interrupt return address into interrupt link register in writeback stage */

	output cond_pass_stage4,

	/* Debugger stuff */

	output reg cpu_debug_pin,	/* This is basically a crude serial interface that transmits PC so we know where we are if there is a lock up */
	
	input [31:0] cpu_debug_wire,	/* debugging info from one level up */

	/* interrupt context output to writeback stage for STIX operation */

	output [15:0] interrupt_context_out,

	/* reg B input from decode stage - for RSIX operation */

	input [15:0] reg_B_input_stage2,

	output debug_trigger,

	output [15:0] debug_data

);

`include "cpu_decode_functions.v"
`include "slurm16_cpu_defs.v"


/* Pipeline state vectors */

localparam INS_BITS = BITS;
localparam NOP_BITS = 1;
localparam PC_BITS  = ADDRESS_BITS - 1;
localparam IMM_BITS = BITS * 3 / 4;
localparam HAZ_REG_BITS = REGISTER_BITS;
localparam HAZ_FLAG_BITS = 1;
localparam FLAGS_BITS = 4;
localparam MEM_RQ_BITS = 1;
localparam COND_PASS_BITS = 1;

localparam TOTAL_PIPELINE_SV_BITS = INS_BITS + NOP_BITS + PC_BITS + IMM_BITS + HAZ_REG_BITS + HAZ_FLAG_BITS + FLAGS_BITS + MEM_RQ_BITS + COND_PASS_BITS;

/*
 *	Pipeline stage state vector (SLURM16):
 *
 * 	|    57  |   56   |  55 - 52    |    51    | 50 - 44  | 43 - 32 | 31 - 17 | 16 - 1 |  0  |
 *	------------------------------------------------------------------------------------------
 *	|   COND | MEM RQ |   FLAGS     | HAZ FLAG |  HAZ REG |  IMM    |  PC     |  INS   | NOP |
 */

localparam NOP_BIT = 0;
localparam INS_LSB = 1;
localparam INS_MSB = 16;
localparam PC_LSB  = 17;
localparam PC_MSB  = 31;
localparam IMM_LSB = 32;
localparam IMM_MSB = 43;
localparam HAZ_REG_LSB = 44;
localparam HAZ_REG_MSB = 50;
localparam HAZ_FLAG_BIT = 51;
localparam FLAGS_LSB = 52;
localparam FLAGS_MSB = 55;
localparam FLAG_C = 52;
localparam FLAG_Z = 53;
localparam FLAG_S = 54;
localparam FLAG_V = 55;

localparam MEM_RQ_BIT = 56;
localparam COND_PASS_BIT = 57;

reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip0 = {TOTAL_PIPELINE_SV_BITS{1'b0}};	// Fetch
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip1 = {TOTAL_PIPELINE_SV_BITS{1'b0}};	// Decode
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip2 = {TOTAL_PIPELINE_SV_BITS{1'b0}};	// Execute
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip3 = {TOTAL_PIPELINE_SV_BITS{1'b0}};	// Mem req.
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip4 = {TOTAL_PIPELINE_SV_BITS{1'b0}};	// Write back
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip5 = {TOTAL_PIPELINE_SV_BITS{1'b0}};	// Final

reg interrupt_flag_r = 1'b0;

reg [ADDRESS_BITS - 2 : 0] pc_r = {(ADDRESS_BITS - 1){1'b0}};
reg [ADDRESS_BITS - 2 : 0] prev_pc_r = {(ADDRESS_BITS - 1){1'b0}};

reg [IMM_BITS - 1 : 0] imm_r = {IMM_BITS{1'b0}};

assign imm_reg = imm_r;

reg halt_request_lat_r;
wire halt = halt_request_lat_r || halt_request;

/* debug */

//assign debug_data = {pip4[PC_MSB : PC_LSB], pip4[NOP_BIT]};
assign debug_data = {12'h0, state_r};
//assign debug_data = {pip4[IMM_MSB: IMM_LSB], 4'd0};
//assign debug_data = {12'h0, pip4[FLAG_C], pip4[FLAG_Z], pip4[FLAG_V], pip4[FLAG_S]};
assign debug_trigger = ({pip4[PC_MSB : PC_LSB], 1'b0} == 15'h0278);

/*
 *	
 *	Shadow copy of imm_r and flags for interrupt context	
 *
 */

reg [IMM_BITS - 1 : 0] int_imm_r = {IMM_BITS{1'b0}};
reg int_C_r = 1'b0;
reg int_S_r = 1'b0;
reg int_Z_r = 1'b0;
reg int_V_r = 1'b0;

assign interrupt_context_out[15:4] = int_imm_r;
assign interrupt_context_out[3] = int_V_r;
assign interrupt_context_out[2] = int_S_r;
assign interrupt_context_out[1] = int_C_r;
assign interrupt_context_out[0] = int_Z_r;


/*
 *	Combinational logic
 *
 */

wire mem_exception = pip4[MEM_RQ_BIT] && !memory_request_successful && !pip4[NOP_BIT]; 

/*	
 *	Pipeline states
 */

localparam st_reset 	= 4'd0;
localparam st_halt 	= 4'd1;
localparam st_execute 	= 4'd2;
localparam st_interrupt = 4'd3;
localparam st_stall1	= 4'd4;
localparam st_stall2    = 4'd5;
localparam st_stall3    = 4'd6;
localparam st_ins_stall1 = 4'd7;
localparam st_ins_stall2 = 4'd8;
localparam st_mem_except1 = 4'd9;
localparam st_mem_except2 = 4'd10;
localparam st_pre_execute = 4'd11;
localparam st_halt2 = 4'd12;

reg [3:0] state_r;

/* 
 *
 * Assign outputs 
 *
 *
 */

/* We will stop requesting instructions in the halt state, freeing up instruction memory (which may be shared)
 * for use by other perhiperals 
 */
assign instruction_request = (state_r != st_halt) && (state_r != st_halt2);
assign instruction_address = pc_r;

assign pipeline_stage_0 = pip0[INS_MSB : INS_LSB];
assign pipeline_stage_1 = pip1[INS_MSB : INS_LSB];
assign pipeline_stage_2 = pip2[INS_MSB : INS_LSB];
assign pipeline_stage_3 = pip3[INS_MSB : INS_LSB];
assign pipeline_stage_4 = pip4[INS_MSB : INS_LSB];

assign pc_stage_4 = {pip4[PC_MSB : PC_LSB], 1'b0};

assign hazard_reg1 = pip1[HAZ_REG_MSB:HAZ_REG_LSB]; 
assign hazard_reg2 = pip2[HAZ_REG_MSB:HAZ_REG_LSB];
assign hazard_reg3 = pip3[HAZ_REG_MSB:HAZ_REG_LSB];
assign modifies_flags1 = pip1[HAZ_FLAG_BIT];
assign modifies_flags2 = pip2[HAZ_FLAG_BIT];
assign modifies_flags3 = pip3[HAZ_FLAG_BIT];

assign load_return_address = (state_r == st_interrupt);

assign cond_pass_stage4 = pip4[COND_PASS_BIT];

assign nop_stage_2 = pip2[NOP_BIT];
assign nop_stage_4 = pip4[NOP_BIT] || mem_exception;

reg pipeline_can_interrupt;

reg [ADDRESS_BITS - 2:0] halt_pc = 15'd0;

always @(posedge CLK)
begin
	if (halt_request)
		halt_pc <= pip2[PC_MSB:PC_LSB] + 15'd1;
end

always @(*)
begin
	
	pipeline_can_interrupt = 1'b1;

	if (pip1[NOP_BIT] == 1'b0)
	casex(pip1[INS_MSB:INS_LSB])
		INSTRUCTION_CASEX_BYTE_LOAD_STORE, INSTRUCTION_CASEX_LOAD_STORE, INSTRUCTION_CASEX_PEEK_POKE:
			pipeline_can_interrupt = 1'b0;
		default: ;
	endcase
	if (pip2[NOP_BIT] == 1'b0)
	casex(pip2[INS_MSB:INS_LSB])
		INSTRUCTION_CASEX_BYTE_LOAD_STORE, INSTRUCTION_CASEX_LOAD_STORE, INSTRUCTION_CASEX_PEEK_POKE:
			pipeline_can_interrupt = 1'b0;
		default: ;
	endcase
	if (pip3[NOP_BIT] == 1'b0)
	casex(pip3[INS_MSB:INS_LSB])
		INSTRUCTION_CASEX_BYTE_LOAD_STORE, INSTRUCTION_CASEX_LOAD_STORE, INSTRUCTION_CASEX_PEEK_POKE:
			pipeline_can_interrupt = 1'b0;
		default: ;
	endcase
end

/*	
 *	Pipeline state machine 		
 *
 *	
 *
 */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state_r <= st_reset;
	end
	else begin

		case (state_r)
			st_reset: begin
				state_r <= st_pre_execute;
			end
			st_pre_execute: begin
				state_r <= st_execute;
			end	
			st_halt: 
				state_r <= st_halt2;
			st_halt2: begin
				/*
				 *	We could have a memory exception when in state halt.
				 *	We will ignore this corner case and make sure that we
				 *	are not performing any memory accesses before a halt.
				 *
				 *	Do we need a memory barrier instruction?
				 *
				 */ 

				if (interrupt_req)
					state_r <= st_pre_execute;
			end
			st_execute: begin
				
				/* If the instruction in pip3 is valid, and we have interrupt condition, 
 				 * initiate interrupt. pip3 will => pip4, where we will fetch return address,
 				 * imm_reg, and flags from.
				 */
				if (interrupt_req && interrupt_flag_r && pip3[NOP_BIT] == 1'b0 && pipeline_can_interrupt)
					state_r <= st_interrupt;
				else if (mem_exception)				
					state_r <= st_mem_except1;
				/*
 				 *	Stall on hazard, iff we are not taking a branch and the instruction in
 				 *	pip0 is valid.
 				 *
 				 */ 
				else if (hazard_1 && !load_pc_request && pip0[NOP_BIT] == 1'b0 && pip1[NOP_BIT] == 1'b0)
					state_r <= st_stall1;
				else if (hazard_2 && !load_pc_request && pip0[NOP_BIT] == 1'b0 && pip2[NOP_BIT] == 1'b0)
					state_r <= st_stall2;
				else if (hazard_3 && !load_pc_request && pip0[NOP_BIT] == 1'b0 && pip3[NOP_BIT] == 1'b0)
					state_r <= st_stall3;
				else if (halt && pipeline_can_interrupt)
					state_r <= st_halt;
				else if (load_pc_request)
					state_r <= st_pre_execute; 
				else if (instruction_valid == 1'b0)
					state_r <= st_ins_stall1;
				
			end
			st_interrupt: begin
				state_r <= st_pre_execute;	
			end
			st_stall1: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else
					state_r <= st_stall2;
			end
			st_stall2: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else if (load_pc_request)
					state_r <= st_pre_execute;	
				else
					state_r <= st_stall3;
			end
			st_stall3: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else if (load_pc_request)
					state_r <= st_pre_execute;
				else
					state_r <= st_execute;
			end
			st_ins_stall1: begin	// This is a wait state while PC is rewound to previous value
				if (mem_exception)
					state_r <= st_mem_except1;
				else
					state_r <= st_ins_stall2;
			end
			st_ins_stall2: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else if (load_pc_request)
					state_r <= st_pre_execute;
				else if (instruction_valid == 1'b1)
					state_r <= st_execute;
			end
			st_mem_except1:	 /* we clear pipeline in this state and get ready to refetch from failing instruction */
				state_r <= st_mem_except2;
			st_mem_except2:
				state_r <= st_execute;
			default:
				state_r <= st_reset;			

		endcase

	end	

end

/*
 *
 *	PC
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pc_r <= {(ADDRESS_BITS - 1){1'b0}};
			prev_pc_r <= {(ADDRESS_BITS - 1){1'b0}};
		end
		st_pre_execute: begin
			pc_r <= pc_r + 1;
			prev_pc_r <= pc_r;
		end
		st_halt: begin	
			pc_r <= halt_pc;
			prev_pc_r <= halt_pc;
		end
		st_halt2:	; 
		st_execute: begin
			if (load_pc_request == 1'b1) begin
				pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1];
				prev_pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1]; 
			end 
			else if (instruction_valid == 1'b0 ||
				(hazard_1 && !load_pc_request && pip0[NOP_BIT] == 1'b0 && pip1[NOP_BIT] == 1'b0) ||
				(hazard_2 && !load_pc_request && pip0[NOP_BIT] == 1'b0 && pip2[NOP_BIT] == 1'b0) ||
				(hazard_3 && !load_pc_request && pip0[NOP_BIT] == 1'b0 && pip3[NOP_BIT] == 1'b0)) begin
				pc_r <= prev_pc_r;
			end else begin
				pc_r <= pc_r + 1;
				prev_pc_r <= pc_r;
			end			
		end
		st_interrupt: begin	
			pc_r <= {10'd0, irq,1'b0};
			prev_pc_r <= {10'd0, irq, 1'b0};
		end
		st_stall1, st_stall2, st_ins_stall1:
			if (load_pc_request == 1'b1) begin
				pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1];
				prev_pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1]; 
			end
		st_stall3:
			if (load_pc_request == 1'b1) begin
				pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1];
				prev_pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1]; 
			end 
			else begin
				pc_r <= pc_r + 1;
				prev_pc_r <= pc_r;
			end
		st_ins_stall2:
			if (load_pc_request == 1'b1) begin
				pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1];
				prev_pc_r <= load_pc_address[ADDRESS_BITS - 1 : 1]; 
			end 
			else if (instruction_valid && !mem_exception) begin
				pc_r <= pc_r + 1;
				prev_pc_r <= pc_r;
			end
		st_mem_except1: begin
			pc_r <= pip5[PC_MSB:PC_LSB];
			prev_pc_r <= pip5[PC_MSB:PC_LSB]; 
		end
		st_mem_except2: begin
			pc_r <= pc_r + 1;
			prev_pc_r <= pc_r;
		end
		default:;
	endcase
end

/*
 *
 *	Pipeline stage 0 (fetch)
 *
 */

always @(posedge CLK)
begin

	pip0[INS_MSB : INS_LSB] 	<= instruction_in;
	pip0[PC_MSB : PC_LSB] 		<= instruction_address_in;
	pip0[IMM_MSB : IMM_LSB] 	<= 12'h000;
	pip0[HAZ_REG_MSB : HAZ_REG_LSB] <= 4'h0;
	pip0[HAZ_FLAG_BIT] 		<= 1'b0;
	pip0[FLAGS_MSB : FLAGS_LSB]	<= { FLAGS_BITS {1'b0}}; 
	pip0[MEM_RQ_BIT]		<= 1'b0;
	pip0[COND_PASS_BIT] 		<= 1'b0;

	// We nop out pip0 in every state except execute
	case (state_r)
		st_reset, st_pre_execute, st_halt, st_halt2, st_stall1, st_stall2, st_stall3, st_ins_stall1, st_mem_except1, st_mem_except2, st_interrupt, st_ins_stall2:
			pip0[NOP_BIT] <= 1'b1;
		default:
			if (load_pc_request || halt || mem_exception)
				pip0[NOP_BIT] <= 1'b1;
			else
				pip0[NOP_BIT] <= 1'b0;	
	endcase

end

/*
 *
 *	Pipeline stage 1 (decode)
 *
 */

always @(posedge CLK)
begin

	// In every state except st_stall{x} we advance pip1
	case (state_r)
		st_stall1, st_stall2, st_stall3:	;	// Hold instruction in the slot
		default: begin
			pip1[PC_MSB : INS_LSB] 		<= pip0[PC_MSB : INS_LSB];
			pip1[HAZ_REG_MSB : HAZ_REG_LSB] <= hazard_reg0;
			pip1[HAZ_FLAG_BIT] 		<= modifies_flags0;
		end
	endcase

	pip1[FLAGS_MSB : FLAGS_LSB]	<= { FLAGS_BITS {1'b0}}; 
	pip1[MEM_RQ_BIT]		<= 1'b0;
	pip1[COND_PASS_BIT] 		<= 1'b0;

	// We nop out pip1 in st_reset, st_halt, st_interrupt, st_mem_except1 and st_ins_stall1 (because instruction coming in from pip0 is invalid if cache missed)
	case (state_r)
		st_reset, st_pre_execute, st_halt, st_halt2, st_interrupt, st_mem_except1, st_ins_stall1:
			pip1[NOP_BIT] <= 1'b1;
		/* preserve nop bit in stall states unless branch taken */
		st_stall1, st_stall2, st_stall3: 
			if (load_pc_request || halt || mem_exception)
				pip1[NOP_BIT] <= 1'b1;
		default:
			if (load_pc_request || halt)
				pip1[NOP_BIT] <= 1'b1;
			else
				pip1[NOP_BIT] <= pip0[NOP_BIT];
	endcase
end

/*
 *
 *	Pipeline stage 2 (execute)
 *
 */

always @(posedge CLK)
begin

	pip2[HAZ_FLAG_BIT : INS_LSB] 	<= pip1[HAZ_FLAG_BIT : INS_LSB];
	pip2[MEM_RQ_BIT]		<= 1'b0;
	pip2[COND_PASS_BIT] 		<= 1'b0;

	// Nop out instruction in st_reset, st_halt, st_halt2, st_interrupt, st_mem_except1, st_stall{x}
	case (state_r)
		st_reset, st_pre_execute, st_halt, st_halt2, st_interrupt, st_mem_except1, st_stall1, st_stall2, st_stall3:
			pip2[NOP_BIT] <= 1'b1;
		default:
			if (load_pc_request || halt || mem_exception)
				pip2[NOP_BIT] <= 1'b1;
			else
				pip2[NOP_BIT] <= pip1[NOP_BIT];
	endcase
end

/*
 *
 *	Pipeline stage 3 (memory request)
 *
 */

always @(posedge CLK)
begin

	pip3[FLAGS_MSB : INS_LSB] 	<= pip2[FLAGS_MSB : INS_LSB];
	pip3[MEM_RQ_BIT]		<= is_mem_request;
	pip3[COND_PASS_BIT] 		<= cond_pass_in;
	pip3[IMM_MSB : IMM_LSB] 	<= imm_r;
	pip3[FLAG_C]			<= C_in;
	pip3[FLAG_Z]			<= Z_in;
	pip3[FLAG_S]			<= S_in;
	pip3[FLAG_V]			<= V_in; 

	// Nop out instruction in st_reset, st_interrupt, st_mem_except1, st_halt, st_halt2
	case (state_r)
		st_reset, st_interrupt, st_mem_except1, st_halt, st_halt2:
			pip3[NOP_BIT] <= 1'b1;
		default:
			if (mem_exception)
				pip3[NOP_BIT] <= 1'b1;
			else
				pip3[NOP_BIT] <= pip2[NOP_BIT];
	endcase
end

/*
 *
 *	Pipeline stage 4 (writeback)
 *
 */

always @(posedge CLK)
begin
	pip4[COND_PASS_BIT : INS_LSB] <= pip3[COND_PASS_BIT : INS_LSB];

	// Nop out instruction in st_reset, st_interrupt, st_mem_except1
	case (state_r)
		st_reset, st_interrupt, st_mem_except1, st_halt, st_halt2:
			pip4[NOP_BIT] <= 1'b1;
		default:
			if (mem_exception)
				pip4[NOP_BIT] <= 1'b1;
			else
				pip4[NOP_BIT] <= pip3[NOP_BIT];
	endcase

end

/*
 *
 *	Pipeline stage 5  (final)
 *
 */
always @(posedge CLK)
begin
	pip5 <= pip4;
	/* we only zero these out so hopefully these bits will optimize away */
	pip5[HAZ_FLAG_BIT : HAZ_REG_LSB] <= {(HAZ_REG_BITS + HAZ_FLAG_BITS){1'b0}};
end


/*
 *
 *	imm reg
 *
 *
 */
always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		imm_r <= {IMM_BITS{1'b0}};
	end
	else begin
		// In mem except1, reload the imm reg from the faulting instruction
		if (state_r == st_mem_except1)
			imm_r <= pip5[IMM_MSB:IMM_LSB];
		// Else if we have an iret, reload the imm reg
		else if (pip2[INS_MSB:INS_LSB] == IRET_INSTRUCTION && pip2[NOP_BIT] == 1'b0)
			imm_r <= int_imm_r; 
		// If there is an un-NOP'ed imm instruction in slot 2, set imm reg
		else if (pip2[INS_MSB:INS_MSB - 3] == 4'h1 && pip2[NOP_BIT] == 1'b0)
			imm_r <= pip2[INS_MSB - 4: INS_LSB];
		// Else if the instruction is not a nop, clear the imm register
		else if (pip2[INS_MSB:INS_LSB] != NOP_INSTRUCTION && pip2[NOP_BIT] == 1'b0)
			imm_r <= {IMM_BITS{1'b0}};		

	end
end

/* int_imm_r : shadow int register for interrupts */

always @(posedge CLK)
begin
	if (state_r == st_interrupt)
		int_imm_r <= pip4[IMM_MSB:IMM_LSB];
	else begin
		// If instruction in pip2 is a RSIX,
		// restore int_imm_r
		casex (pip2[INS_MSB:INS_LSB])
			INSTRUCTION_CASEX_RSIX: begin /* restore interrupt context */
				if (!pip2[NOP_BIT])
					int_imm_r <= reg_B_input_stage2[15:4];
			end	
			default: ;
		endcase

	end
end


/* interrupt flag */

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		interrupt_flag_r <= 1'b0;
	else if (state_r == st_interrupt)
		interrupt_flag_r <= 1'b0;
	else if (interrupt_flag_set == 1'b1)
		interrupt_flag_r <= 1'b1;
	else if (interrupt_flag_clear == 1'b1)
		interrupt_flag_r <= 1'b0;
end

/* interrupt copy of flags */

always @(posedge CLK)
begin
	if (state_r == st_interrupt) begin
	/*	int_C_r <= pip4[FLAG_C];
		int_S_r <= pip4[FLAG_S];
		int_Z_r <= pip4[FLAG_Z];
		int_V_r <= pip4[FLAG_V];
	*/
		int_C_r <= pip3[FLAG_C];
		int_S_r <= pip3[FLAG_S];
		int_Z_r <= pip3[FLAG_Z];
		int_V_r <= pip3[FLAG_V];
	

		/*int_C_r <= C_in;
		int_Z_r <= Z_in;
		int_S_r <= S_in;
		int_V_r <= V_in;*/

 	end else begin
		// If instruction in pip2 is a RSIX, 
		// restore interrupt flags.
		casex (pip2[INS_MSB:INS_LSB])
			INSTRUCTION_CASEX_RSIX: begin /* restore interrupt context */
				if (!pip2[NOP_BIT])
				begin
					int_C_r <= reg_B_input_stage2[1];
					int_S_r <= reg_B_input_stage2[2];
					int_Z_r <= reg_B_input_stage2[0];
					int_V_r <= reg_B_input_stage2[3];
				end
			end	
			default: ;
		endcase
	end
end

/* load flags */

always @(*)
begin
	flags_load = 1'b0;
	
	C_out = int_C_r;
	Z_out = int_Z_r;
	V_out = int_V_r;
	S_out = int_S_r;

	// If IRET, reload flags from shadow set
	if (pip2[INS_MSB : INS_LSB] == IRET_INSTRUCTION && !pip2[NOP_BIT]) begin
		flags_load = 1'b1;
	end
 	// If mem except, reload flags from preserved flags in pip5
/*	else if (state_r == st_mem_except1) begin
		C_out = pip5[FLAG_C];
		Z_out = pip5[FLAG_Z];
		V_out = pip5[FLAG_V];
		S_out = pip5[FLAG_S];
 		flags_load = 1'b1;
	end
*/
end

/* latch halt requests */

always @(posedge CLK)
begin
	if (state_r == st_halt)
		halt_request_lat_r <= 1'b0;
	else if (halt_request)
		halt_request_lat_r <= 1'b1;
end


/* 
 *
 * Debug decoding of states
 *
 */

`ifdef SIM

reg [63:0] ascii_state;

always @(*)
begin
	case (state_r)
		st_reset:
			ascii_state = "reset";
		st_halt:
			ascii_state = "halt";
		st_execute:
			ascii_state = "exec";
		st_interrupt:
			ascii_state = "intrp";
		st_stall1:
			ascii_state = "stall1";
		st_stall2:
			ascii_state = "stall2";
		st_stall3: 
			ascii_state = "stall3";
		st_ins_stall1: 
			ascii_state = "istall1";
		st_ins_stall2:
			ascii_state = "istall2";
		st_mem_except1:
			ascii_state = "mexcpt1";
		st_mem_except2:
			ascii_state = "mexcpt2";
		st_pre_execute:
			ascii_state = "prexec";
		st_halt2:
			ascii_state = "halt2";
	endcase
end

`include "slurm16_debug_functions.v"

reg [135:0] ascii_instruction0;
reg [135:0] ascii_instruction1;
reg [135:0] ascii_instruction2;
reg [135:0] ascii_instruction3;
reg [135:0] ascii_instruction4;

always @(*)
begin
	if (pip0[NOP_BIT])
		ascii_instruction0[7:0] = "*";
	else
		ascii_instruction0[7:0] = " ";
	ascii_instruction0[135:8] = disassemble(pip0[INS_MSB:INS_LSB]);

	if (pip1[NOP_BIT])
		ascii_instruction1[7:0] = "*";
	else
		ascii_instruction1[7:0] = " ";
	ascii_instruction1[135:8] = disassemble(pip1[INS_MSB:INS_LSB]);

	if (pip2[NOP_BIT])
		ascii_instruction2[7:0] = "*";
	else
		ascii_instruction2[7:0] = " ";
	
	ascii_instruction2[135:8] = disassemble(pip2[INS_MSB:INS_LSB]);

	if (pip3[NOP_BIT])
		ascii_instruction3[7:0] = "*";
	else
		ascii_instruction3[7:0] = " ";
	
	ascii_instruction3[135:8] = disassemble(pip3[INS_MSB:INS_LSB]);

	if (pip4[NOP_BIT])
		ascii_instruction4[7:0] = "*";
	else
		ascii_instruction4[7:0] = " ";
	
	ascii_instruction4[135:8] = disassemble(pip4[INS_MSB:INS_LSB]);
end

/* Break up pipeline into debuggable sections */

wire [15:0] debug_pc0 = {pip0[PC_MSB : PC_LSB], 1'b0};
wire [15:0] debug_pc1 = {pip1[PC_MSB : PC_LSB], 1'b0};
wire [15:0] debug_pc2 = {pip2[PC_MSB : PC_LSB], 1'b0};
wire [15:0] debug_pc3 = {pip3[PC_MSB : PC_LSB], 1'b0};
wire [15:0] debug_pc4 = {pip4[PC_MSB : PC_LSB], 1'b0};

wire [15:0] debug_op0 = pip0[INS_MSB : INS_LSB];
wire [15:0] debug_op1 = pip1[INS_MSB : INS_LSB];
wire [15:0] debug_op2 = pip2[INS_MSB : INS_LSB];
wire [15:0] debug_op3 = pip3[INS_MSB : INS_LSB];
wire [15:0] debug_op4 = pip4[INS_MSB : INS_LSB];

wire [15:0] debug_pc = {pc_r, 1'b0};

`endif

/* Debug PIN */

/*localparam debug_state_idle = 4'd0;
localparam debug_state_start = 4'd1;
localparam debug_state_start_bit = 4'd2;
localparam debug_state_bits = 4'd3;
localparam debug_state_stop_bit = 4'd4;

reg [3:0] debug_state = debug_state_idle;
reg [15:0] data_lat   = 16'd0;
reg [3:0] debug_count       = 4'd0;

always @(posedge CLK)
begin
//	cpu_debug_pin <= interrupt_flag_r; 

	case (debug_state)
		debug_state_idle: begin
			debug_count <= debug_count + 1;
			if (debug_count == 4'd15)
				debug_state <= debug_state_start;
			cpu_debug_pin <= 1'b1;
		end
		debug_state_start: begin
			//data_lat <= {pc_r, 1'b1};
			data_lat <= {state_r, 4'b0101};
			debug_state <= debug_state_start_bit;
		end
		debug_state_start_bit: begin
			cpu_debug_pin <= 1'b0;
			debug_state <= debug_state_bits;
		end
		debug_state_bits: begin
			debug_count <= debug_count + 1;
			if (debug_count == 4'd15)
				debug_state <= debug_state_stop_bit;
			cpu_debug_pin <= data_lat[0];
			data_lat[14:0] <= data_lat[15:1];
		end
		debug_state_stop_bit: begin
			cpu_debug_pin <= 1'b0;
			debug_state <= debug_state_idle;	
		end
	endcase
end
*/

/*cpu_debug_core cr0 (
	CLK,
	RSTb,

	state_r == st_ins_stall1, 
	
	{pc_r, 1'b0, 4'd0, state_r, 3'd0, interrupt_flag_r, irq},
//	{pc_r, 1'b0, pip0[INS_MSB:INS_LSB]},
//	cpu_debug_wire,
	1'b0,

	cpu_debug_pin
);
*/
assign cpu_debug_pin = 1'b1;


endmodule
