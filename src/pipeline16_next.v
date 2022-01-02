/*
 *
 *	slurm16 pipeline
 *
 *	Next next version - handle memory interfacing correctly, so that gfx / audio / cpu / flash dma 
 *	can share resources.
 *
 *  Also needs interrupts
 *
 */

module 
pipeline16
(
	input CLK,
	input RSTb,

	/* flags from ALU */
	input C,	
	input Z,
	input S,

	/* control signals to ALU */
	output [4:0]    aluOp,

	output [15:0]	aluA,
	output [15:0]	aluB,

	input  [15:0]   aluOut,

	output aluExecute,

	/* register file interface */

	output [15:0]   regFileIn,
	output [4:0]    regWrAddr,

	output [4:0]    regARdAddr,
	output [4:0]    regBRdAddr,

	input  [15:0]	regA,
	input  [15:0] 	regB,

	/* control signals to / from memory */

	input  [15:0] 	memoryIn,
	output [15:0] 	memoryOut,
	output [15:0] 	memoryAddr,

	output valid,
	input  ready,
	output wr,

	/* IO port signals */

	input  [15:0] portIn,
	output [15:0] portOut,
	output [15:0] portAddress,
	output portRd,
	output portWr, 

	/* interrupt lines: spi flash dma, audio, video */

	input [3:0] irq

);

localparam REG_BITS = 5; /* 16 registers, but use 5 bits */
localparam BITS = 16;

localparam NOP_INSTRUCTION = {BITS{1'b0}};
localparam LINK_REGISTER   = 5'd15;

reg [BITS - 1:0] pc_r;
reg [BITS - 1:0] pc_r_prev;
reg [BITS - 1:0] pc_r_next;
reg [BITS - 1:0] pc_r_prev_next;

reg [BITS - 1:0] memoryAddr_r;
reg valid_r;
reg wr_r;

reg [BITS - 1:0] memoryOut_stage3_r;
reg [BITS - 1:0] memoryOut_stage3_r_next;

reg [BITS - 1:0] portAddress_r, portAddress_r_next;
assign portAddress = portAddress_r;

reg [BITS - 1:0] portOut_r, portOut_r_next;
assign portOut = portOut_r;

reg portRd_r, portWr_r;
assign portRd = portRd_r;
assign portWr = portWr_r;

assign memoryOut = memoryOut_stage3_r;
assign valid = valid_r;
assign memoryAddr = memoryAddr_r;
assign wr = wr_r;

reg aluExecute_r;
assign aluExecute = aluExecute_r;

/* pipeline registers */

reg [BITS - 1:0] pipelineStage0_r;
reg [BITS - 1:0] pipelineStage0_r_next;

reg [BITS - 1:0] pipelineStage1_r;
reg [BITS - 1:0] pipelineStage1_r_next;

reg [BITS - 1:0] pipelineStage2_r;
reg [BITS - 1:0] pipelineStage2_r_next;

reg [BITS - 1:0] pipelineStage3_r;
reg [BITS - 1:0] pipelineStage3_r_next;

reg [BITS - 1:0] pipelineStage4_r;
reg [BITS - 1:0] pipelineStage4_r_next;

/* alu registers */ 

reg [BITS - 1:0] aluA_r, aluA_r_next;
reg [BITS - 1:0] aluB_r, aluB_r_next;

assign aluA = aluA_r;
assign aluB = aluB_r;

reg [REG_BITS-1:0] regARdAddr_r;
reg [REG_BITS-1:0] regBRdAddr_r;

reg [REG_BITS-1:0] regARdAddr_stage0_r;
reg [REG_BITS-1:0] regBRdAddr_stage0_r;

assign regARdAddr = regARdAddr_r;
assign regBRdAddr = regBRdAddr_r;

reg [4:0] 		alu_op_r, alu_op_r_next;
assign aluOp  = alu_op_r;

reg [11:0] imm_r;
reg [11:0] imm_r_next;

reg [BITS - 1:0] imm_stage2_r;
reg [BITS - 1:0] imm_stage2_r_next;

/* reg file */

reg [BITS - 1:0] reg_out_r;
assign regFileIn = reg_out_r;

reg [REG_BITS - 1:0] reg_wr_addr_r;
assign regWrAddr = reg_wr_addr_r;

// Needs to track pipeline
reg [BITS - 1:0] result_stage2_r;
reg [BITS - 1:0] result_stage2_r_next;
reg [BITS - 1:0] result_stage3_r;
reg [BITS - 1:0] result_stage3_r_next;
reg [BITS - 1:0] result_stage4_r;
reg [BITS - 1:0] result_stage4_r_next;

/* stall logic */

// Needs to track pipeline
reg [REG_BITS-1:0] hazard1_r_next;
reg [REG_BITS-1:0] hazard1_r;
reg [REG_BITS-1:0] hazard2_r;
reg [REG_BITS-1:0] hazard2_r_next;
reg [REG_BITS-1:0] hazard3_r;

// Needs to track pipeline
reg flagsModifiedStage1_r_next;
reg flagsModifiedStage1_r;
reg flagsModifiedStage2_r_next;
reg flagsModifiedStage2_r;
reg flagsModifiedStage3_r;

reg [2:0] stall_count_r;
reg [2:0] stall_count_r_next;

wire partial_pipeline_stall_r = (stall_count_r > 1);

/* branch logic */

// Needs to track pipeline
reg branch_taken2_r;
reg branch_taken2_r_next;
reg branch_taken3_r;
reg branch_taken4_r; 

// Memory load

reg [BITS - 1:0] loadStoreAddr_stage3_r;
reg [BITS - 1:0] loadStoreAddr_stage3_r_next;

reg load_memory; // asserted when the CPU is about to execute a load instruction
reg store_memory; // asserted when the CPU is about to execute a store instruction

/* CPU state */

reg [3:0] cpu_state_r, cpu_state_r_next, prev_cpu_state_r;

localparam cpust_halt 	 	     = 4'b0000; // 0 CPU is halted; instructions not fetched
localparam cpust_execute 	     = 4'b0001; // 1 CPU is executing non-memory instructions
localparam cpust_wait_mem_ready1 = 4'b0010; // 2 Wait state when switching banks
localparam cpust_wait_mem_ready2 = 4'b0011; // 3 CPU is waiting to access a new memory bank for fetching non-memory instructions
localparam cpust_execute_load    = 4'b0100; // 4 CPU is executing load instruction
localparam cpust_wait_mem_load1  = 4'b0101; // 5 Wait state when switching banks to load memory from
localparam cpust_wait_mem_load2  = 4'b0110; // 6 CPU is waiting for memory grant to load from
localparam cpust_execute_store   = 4'b0111; // 7 CPU is executing store instruction
localparam cpust_wait_mem_store1 = 4'b1000; // 8 Wait state when switching banks to store to memory
localparam cpust_wait_mem_store2 = 4'b1001; // 9 CPU is waiting for memory grant to store to
 

function is_branch_link_from_ins;
input [15:0] ins;
	is_branch_link_from_ins = (ins[10:8] == 3'b111) ? 1'b1 : 1'b0;
endfunction

function [11:0] imm_r_from_ins;
input [15:0] ins;
begin
	imm_r_from_ins = ins[11:0];
end
endfunction

function [4:0] alu_op_from_ins;
input [15:0] ins;
begin
	alu_op_from_ins = {1'b0, ins[11:8]}; 
end
endfunction

function [4:0] single_reg_alu_op_from_ins;
input [15:0] ins;
begin
	single_reg_alu_op_from_ins = {1'b1, ins[7:4]}; 
end
endfunction

function [4:0] reg_dest_from_ins;
input [15:0] ins;
begin
	reg_dest_from_ins = {1'b0, ins[7:4]};
end
endfunction

function [4:0] reg_src_from_ins;
input [15:0] ins;
begin
	reg_src_from_ins = {1'b0, ins[3:0]};
end
endfunction

function [4:0] reg_idx_from_ins;
input [15:0] ins;
begin
	reg_idx_from_ins = {1'b0, ins[12:9]};
end
endfunction

function [3:0]  imm_lo_from_ins;
input 	 [15:0] ins;
begin
	imm_lo_from_ins = ins[3:0];	
end
endfunction

function is_load_store_from_ins;
input [15:0] p0;
    is_load_store_from_ins = p0[8]; // 0 = load, 1 = store
endfunction

function is_io_poke_from_ins;
input [15:0] p0;
    is_io_poke_from_ins = p0[8]; // 1 = poke, 0 = peek
endfunction



function uses_flags_for_branch;
input [15:0] ins;
begin
	case(ins[10:8])
		3'b000, 3'b001, 3'b010, 3'b011, 3'b100, 3'b101:
			uses_flags_for_branch = 1'b1;
		default:
			uses_flags_for_branch = 1'b0;
	endcase
end
endfunction

function branch_taken_from_ins;
input [15:0] ins;
input Z_in;
input S_in;
input C_in;
begin
	case(ins[10:8])
		3'b000:		/* 0x0 - BZ, branch if ZERO */
			if (Z_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		3'b001:		/* 0x1 - BNZ, branch if not ZERO */
			if (Z_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		3'b010:		/* 0x2 - BS, branch if SIGN */
			if (S_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		3'b011:		/* 0x3 - BNS, branch if not SIGN */
			if (S_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		3'b100:		/* 0x4 - BC, branch if CARRY */
			if (C_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		3'b101:		/* 0x5 - BNC, branch if not CARRY */
			if (C_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
		3'b110:		/* 0x6 - BA, branch always */
			branch_taken_from_ins = 1'b1;
		3'b111:		/* 0x7 - BL, branch link */
			branch_taken_from_ins = 1'b0; /* don't branch?? */
		/* TODO: redo branches to support c compiler: bge, bgt, ble, blt, beq, bneq */


	endcase
end
endfunction

function is_branch_reg_ind_from_ins;
input [15:0] ins;
	is_branch_reg_ind_from_ins = ins[11];
endfunction

function [4:0] reg_branch_ind_from_ins;
input [15:0] ins;
		reg_branch_ind_from_ins = {1'b0, ins[7:4]};
endfunction

/* sequential logic */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		cpu_state_r <= cpust_wait_mem_ready1;	// We bring CPU out of reset waiting to access instruction memory
		prev_cpu_state_r <= cpust_halt;
		pc_r 		<= 16'd0;				// CPU comes out of reset with PC set to 0x0000
		pc_r_prev 	<= 16'd0;
		pipelineStage0_r <= NOP_INSTRUCTION;
		pipelineStage1_r <= NOP_INSTRUCTION;
		pipelineStage2_r <= NOP_INSTRUCTION;
		pipelineStage3_r <= NOP_INSTRUCTION;
		pipelineStage4_r <= NOP_INSTRUCTION;
		aluA_r 			 <= 16'd0;
		aluB_r 			 <= 16'd0;
		alu_op_r		 <= 5'd0;
		imm_r			 <= {12{1'b0}};
		imm_stage2_r	 <= {BITS{1'b0}};
		hazard1_r		 <= 5'd16;
		hazard2_r		 <= 5'd16;
		hazard3_r		 <= 5'd16;
		flagsModifiedStage1_r		 <= 1'b0;
		flagsModifiedStage2_r		 <= 1'b0;
		flagsModifiedStage3_r		 <= 1'b0;
		stall_count_r				 <= 3'b000;
		branch_taken2_r  <= 1'b0;
		branch_taken3_r  <= 1'b0;
		branch_taken4_r  <= 1'b0;	
		loadStoreAddr_stage3_r		 <= {BITS{1'b0}};
		memoryOut_stage3_r			 <= {BITS{1'b0}};
		result_stage2_r  <= {BITS{1'b0}};
		result_stage3_r  <= {BITS{1'b0}};
		result_stage4_r  <= {BITS{1'b0}};
		portAddress_r    <= {BITS{1'b0}};
		portOut_r    <= {BITS{1'b0}};
	end else begin
		cpu_state_r <= cpu_state_r_next;
		prev_cpu_state_r <= cpu_state_r;
		pc_r 		<= pc_r_next;
		pc_r_prev 	<= pc_r_prev_next;
		pipelineStage0_r <= pipelineStage0_r_next;
		pipelineStage1_r <= pipelineStage1_r_next;
		pipelineStage2_r <= pipelineStage2_r_next;
		pipelineStage3_r <= pipelineStage3_r_next;
		pipelineStage4_r <= pipelineStage4_r_next;
		aluA_r 			 <= aluA_r_next;
		aluB_r 			 <= aluB_r_next;
		alu_op_r	     <= alu_op_r_next;
		imm_r			 <= imm_r_next;
		imm_stage2_r	 <= imm_stage2_r_next;
		/* track to pipeline */
		hazard1_r		 <= hazard1_r_next;
		hazard2_r		 <= hazard2_r_next;
		hazard3_r		 <= hazard2_r;
		flagsModifiedStage1_r	<= flagsModifiedStage1_r_next;
		flagsModifiedStage2_r	<= flagsModifiedStage2_r_next;
		flagsModifiedStage3_r	<= flagsModifiedStage2_r;
		stall_count_r			<= stall_count_r_next;
		branch_taken2_r		<= branch_taken2_r_next;
		branch_taken3_r		<= branch_taken2_r;
		branch_taken4_r		<= branch_taken3_r;
		loadStoreAddr_stage3_r	<= loadStoreAddr_stage3_r_next;
		memoryOut_stage3_r		<= memoryOut_stage3_r_next;
		result_stage2_r <= result_stage2_r_next;
		result_stage3_r <= result_stage3_r_next;
		result_stage4_r <= result_stage4_r_next;
		portAddress_r <= portAddress_r_next;
		portOut_r    <= portOut_r_next;
	end
end

/* combinational logic */

/* interlock logic - determine hazard */

/* 1 - registers that will be written */

always @(*)
begin
	hazard1_r_next = hazard1_r;
	hazard2_r_next = 5'd16;

	if (stall_count_r == 3'b001) begin
		hazard1_r_next = 5'd16;
		hazard2_r_next = hazard1_r;
	end else
	if (stall_count_r == 3'b000) begin
		hazard2_r_next = hazard1_r;
		hazard1_r_next = 5'd16;

		casex (pipelineStage0_r)
			16'h01xx:	begin	/* ret / iret */
				hazard1_r_next = LINK_REGISTER;
			end
			16'h02xx, 16'h03xx: begin
				hazard1_r_next = reg_src_from_ins(pipelineStage0_r);	
			end
			16'h04xx: begin /* alu op reg */
				hazard1_r_next = reg_src_from_ins(pipelineStage0_r);
			end
			16'h2xxx:	begin	/* alu op, reg reg */
				hazard1_r_next = reg_dest_from_ins(pipelineStage0_r);
			end
			16'h3xxx:	begin	/* alu op, reg imm */
				hazard1_r_next = reg_dest_from_ins(pipelineStage0_r);
			end
			16'h5xxx:	begin	/* load / store reg, reg ind */	
				if (is_load_store_from_ins(pipelineStage0_r) == 1'b0) begin /* load */
					hazard1_r_next = reg_dest_from_ins(pipelineStage0_r);	// we will write to this register
				end
			end
			16'h6xxx: 	begin /* load / store, reg, imm address */
				if (is_load_store_from_ins(pipelineStage0_r) == 1'b0) begin /* load */
					hazard1_r_next = reg_dest_from_ins(pipelineStage0_r);	// we will write to this register
				end 
			end
			16'b110xxxxxxxxxxxxx: begin /* memory, reg, reg + immediate index */ 
				if (is_load_store_from_ins(pipelineStage0_r) == 1'b0) begin /* load */
					hazard1_r_next = reg_dest_from_ins(pipelineStage0_r);	// we will write to this register
				end 
			end
			16'b111xxxxxxxxxxxxx: begin /* io peek? */
				if (is_io_poke_from_ins(pipelineStage0_r) == 1'b0) begin
					hazard1_r_next = reg_dest_from_ins(pipelineStage0_r);
				end
			end
			default: ;
		endcase

	end

end

/* 2 - flags that will be written */

always @(*)
begin
	flagsModifiedStage1_r_next = flagsModifiedStage1_r;
	flagsModifiedStage2_r_next = 1'b0;
	
	if (stall_count_r == 3'b000) begin
		flagsModifiedStage1_r_next = 1'b0;
		flagsModifiedStage2_r_next = flagsModifiedStage1_r;
	
		casex (pipelineStage0_r)
			16'h04xx: begin 
				flagsModifiedStage1_r_next = 1'b1;
			end
			16'h2xxx:	begin	
				flagsModifiedStage1_r_next = 1'b1;
			end
			16'h3xxx:	begin	
				flagsModifiedStage1_r_next = 1'b1;
			end
			default: ;
		endcase
	end

end

/* Determine any hazard and set stall_count_r */

always @(*)
begin

	stall_count_r_next = stall_count_r;

	case (cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store:
			stall_count_r_next = (stall_count_r == 3'b000) ? stall_count_r : stall_count_r - 1;
	endcase	


	if (partial_pipeline_stall_r == 1'b0) begin
		
		if ((regARdAddr_stage0_r != 5'd16) && 
			(hazard3_r == regARdAddr_stage0_r))
				stall_count_r_next = 3;
		else
		if ((regBRdAddr_stage0_r != 5'd16) && 
			(hazard3_r == regBRdAddr_stage0_r))
				stall_count_r_next = 3;
		else
		if ((regARdAddr_stage0_r != 5'd16) && 
			(hazard2_r == regARdAddr_stage0_r))
				stall_count_r_next = 4;
		else
		if ((regBRdAddr_stage0_r != 5'd16) && 
			(hazard2_r == regBRdAddr_stage0_r))
				stall_count_r_next = 4;
		else
		if ((regARdAddr_stage0_r != 5'd16) && 
			(hazard1_r == regARdAddr_stage0_r))
				stall_count_r_next = 5;
		else
		if ((regBRdAddr_stage0_r != 5'd16) && 
			(hazard1_r == regBRdAddr_stage0_r))
				stall_count_r_next = 5;
		else begin
		/* flags hazard */
		
		casex (pipelineStage0_r)
			16'h4xxx:	begin 
				if (uses_flags_for_branch(pipelineStage0_r) == 1'b1 && flagsModifiedStage2_r == 1'b1)
					stall_count_r_next = 3;
		
				if (uses_flags_for_branch(pipelineStage0_r) == 1'b1 && flagsModifiedStage1_r == 1'b1)
					stall_count_r_next = 3;
			end
		endcase
		end
	end 

end

// CPU state machine

always @(*)
begin
	aluExecute_r = 1'b0;

	case (prev_cpu_state_r)
		cpust_execute, cpust_execute_load, cpust_execute_store:
			aluExecute_r = 1'b1;
	endcase
end

always @(*)
begin
	cpu_state_r_next = cpu_state_r;

	case (cpu_state_r)
		cpust_halt: ;	 // We should wake on interrupt here	
		/* non-memory instructions (access program memory) */
		cpust_execute: begin
			// TODO: If we are not changing bank, we don't need the penalty
			// and can jump straight to the corresponding execute state
			if (load_memory == 1'b1) begin 
				// If in same bank, short circuit 
				if (pc_r[15:14] == loadStoreAddr_stage3_r_next[15:14])
					cpu_state_r_next = cpust_execute_load;
				else 
					cpu_state_r_next = cpust_wait_mem_load1;
			end
			else if (store_memory == 1'b1) begin
				if (pc_r[15:14] == loadStoreAddr_stage3_r_next[15:14])
					cpu_state_r_next = cpust_execute_store;
				else
					cpu_state_r_next = cpust_wait_mem_store1;
			end else begin
				if (pc_r[15:14] != pc_r_next[15:14])
					cpu_state_r_next = cpust_wait_mem_ready1;
			end
		end 
		cpust_wait_mem_ready1:
			cpu_state_r_next = cpust_wait_mem_ready2;
		cpust_wait_mem_ready2:
			if (ready == 1'b1)
				cpu_state_r_next = cpust_execute;
		/* load instructions (access data memory) */
		cpust_execute_load: begin
			if (load_memory == 1'b0) begin
				if (pc_r_next[15:14] == loadStoreAddr_stage3_r[15:14])
					cpu_state_r_next = cpust_execute;
				else
					cpu_state_r_next = cpust_wait_mem_ready1;
			end
			else if (loadStoreAddr_stage3_r[15:14] != loadStoreAddr_stage3_r_next[15:14])
				cpu_state_r_next = cpust_wait_mem_load1;
		end 
		cpust_wait_mem_load1:
			cpu_state_r_next = cpust_wait_mem_load2;
		cpust_wait_mem_load2:
			if (ready == 1'b1)
				cpu_state_r_next = cpust_execute_load;
		/* store instructions (write to data memory) */
		cpust_execute_store: begin
			if (store_memory == 1'b0) begin
				if (pc_r_next[15:14] == loadStoreAddr_stage3_r[15:14])
					cpu_state_r_next = cpust_execute;
				else
					cpu_state_r_next = cpust_wait_mem_ready1;
			end
			else if (loadStoreAddr_stage3_r[15:14] != loadStoreAddr_stage3_r_next[15:14])
				cpu_state_r_next = cpust_wait_mem_store1;
		end
		cpust_wait_mem_store1:
			cpu_state_r_next = cpust_wait_mem_store2;
		cpust_wait_mem_store2:
			if (ready == 1'b1)
				cpu_state_r_next = cpust_execute_store;
		default:
			cpu_state_r_next = cpust_halt;
	endcase
end


// Handle PC

always @(*)
begin
	pc_r_prev_next = pc_r_prev;
	pc_r_next = pc_r;

	case (cpu_state_r)
		cpust_execute: begin
			pc_r_prev_next = pc_r;
			pc_r_next = pc_r + 1;

			if (partial_pipeline_stall_r == 1'b1) begin
				pc_r_next = pc_r_prev;
				pc_r_prev_next = pc_r_prev;
			end 

			/* Branch in pipeline stage 1 ? */

			if (stall_count_r <= 3'b001) begin
				casex (pipelineStage1_r)
					16'h4xxx:	begin /* branch */
						if (branch_taken_from_ins(pipelineStage1_r, Z, S, C) == 1'b1) begin
							if (is_branch_reg_ind_from_ins(pipelineStage1_r) == 1'b0) begin
								pc_r_next = {imm_r, imm_lo_from_ins(pipelineStage1_r)};
								pc_r_prev_next = pc_r_next;	
							end
						end
						/* branch and link? */
						else if (is_branch_link_from_ins(pipelineStage1_r) == 1'b1) begin
							if (is_branch_reg_ind_from_ins(pipelineStage1_r) == 1'b0) begin
								pc_r_next = {imm_r, imm_lo_from_ins(pipelineStage1_r)};
								pc_r_prev_next = pc_r_next;
							end	
						end
					end
					default: ;
				endcase
			end

			/* Branch in pipeline stage 2 ? */

			casex (pipelineStage2_r)
				16'h01xx:	begin /* ret / iret */
					pc_r_next = regA;
					pc_r_prev_next = pc_r_next;
				end
				16'h4xxx:	 begin /* branch */
					if (is_branch_reg_ind_from_ins(pipelineStage2_r) == 1'b1 && branch_taken2_r == 1'b1) begin
						pc_r_next = regA + imm_stage2_r;
						pc_r_prev_next = pc_r_next;
					end
				end
				default: ;
			endcase
		end
		cpust_wait_mem_ready2:
			if (ready == 1'b1 && stall_count_r == 3'b000  ) begin
				pc_r_prev_next = pc_r;
				pc_r_next = pc_r + 1;
			end
		default: begin
			pc_r_next = pc_r_prev;
			pc_r_prev_next = pc_r_prev;
		end
	endcase
end

// Memory handshaking 

always @(*)
begin
	valid_r = 1'b0;
	memoryAddr_r = 16'd0;
	wr_r = 1'b0;

	case (cpu_state_r)
		cpust_execute,
		cpust_wait_mem_ready2: begin
			valid_r 	 = 1'b1;
			memoryAddr_r = pc_r;
		end
		cpust_execute_load,
		cpust_wait_mem_load2: begin
			memoryAddr_r = loadStoreAddr_stage3_r;
			valid_r = 1'b1; 
		end
		cpust_execute_store,
		cpust_wait_mem_store2: begin
			memoryAddr_r = loadStoreAddr_stage3_r;
			valid_r = 1'b1; 
			wr_r = 1'b1;
		end
		default: ;
	endcase
end

/* load memory? */

always @(*)
begin

	load_memory = 1'b0;
	store_memory = 1'b0;

	casex (pipelineStage2_r)
		16'h5xxx, 16'h6xxx, 16'b110xxxxxxxxxxxxx:	begin /* memory */
			if (is_load_store_from_ins(pipelineStage2_r) == 1'b0) begin /* load */
				load_memory = 1'b1;
			end else begin
				store_memory = 1'b1;
			end
		end
	endcase

end


/* branch logic */

always @(*)
begin
	branch_taken2_r_next = 1'b0;

	casex (pipelineStage1_r)
		16'h4xxx:	begin /* branch */
			if (branch_taken_from_ins(pipelineStage1_r, Z, S, C) == 1'b1) begin	
				branch_taken2_r_next = 1'b1;
			end
			/* branch and link? */
			else if (is_branch_link_from_ins(pipelineStage1_r) == 1'b1) begin
				branch_taken2_r_next = 1'b1;
			end
		end
		default: ;
	endcase
end

// Pipeline

always @(*)
begin

	pipelineStage0_r_next = pipelineStage0_r;
	pipelineStage1_r_next = pipelineStage1_r;
	pipelineStage2_r_next = pipelineStage2_r;
	pipelineStage3_r_next = pipelineStage3_r;
	pipelineStage4_r_next = pipelineStage4_r;

	case (cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store
		: begin 	
			if (prev_cpu_state_r == cpust_execute || prev_cpu_state_r == cpust_wait_mem_ready2) 
				pipelineStage0_r_next = memoryIn;
			else
				pipelineStage0_r_next = NOP_INSTRUCTION;
			pipelineStage1_r_next = pipelineStage0_r;
			pipelineStage2_r_next = pipelineStage1_r;
			pipelineStage3_r_next = pipelineStage2_r;
			pipelineStage4_r_next = pipelineStage3_r;

			if (stall_count_r == 3'b001) begin
				pipelineStage0_r_next = pipelineStage0_r;
				pipelineStage2_r_next = pipelineStage1_r;
				pipelineStage1_r_next = NOP_INSTRUCTION;	
			end
			else if (stall_count_r > 3'b001) begin
				pipelineStage0_r_next = pipelineStage0_r;
				pipelineStage1_r_next = pipelineStage1_r;
				pipelineStage2_r_next = NOP_INSTRUCTION;	
			end
			else begin

				/* If branch taken in stage 1, insert nop as new instruction in stage 1 */

				casex (pipelineStage1_r)
					16'h01xx:   begin
						pipelineStage0_r_next = NOP_INSTRUCTION;
						pipelineStage1_r_next = NOP_INSTRUCTION;
					end
					16'h4xxx:	begin /* branch */
						if (branch_taken_from_ins(pipelineStage1_r, Z, S, C) == 1'b1) begin
							pipelineStage0_r_next = NOP_INSTRUCTION;
							pipelineStage1_r_next = NOP_INSTRUCTION;
						end
						/* branch and link? */
						else if (is_branch_link_from_ins(pipelineStage1_r) == 1'b1) begin
							pipelineStage0_r_next = NOP_INSTRUCTION;
							pipelineStage1_r_next = NOP_INSTRUCTION;
						end
					end
				endcase	

				/* If branch taken in stage 2, insert nop as new instruction in stage 1 */

				casex (pipelineStage2_r)
					16'h01xx: begin
							pipelineStage0_r_next = NOP_INSTRUCTION;
					end
					16'h4xxx: begin
						if (is_branch_reg_ind_from_ins(pipelineStage1_r) == 1'b0 && branch_taken2_r == 1'b1) begin 
							pipelineStage1_r_next = NOP_INSTRUCTION;
							pipelineStage0_r_next = NOP_INSTRUCTION;
						end
						else if (branch_taken2_r == 1'b1)
							pipelineStage0_r_next = NOP_INSTRUCTION;
					end
				endcase

				casex (pipelineStage3_r)
					16'h01xx: begin
							pipelineStage0_r_next = NOP_INSTRUCTION;
					end
				endcase
			end
		end
		cpust_wait_mem_ready1,
		cpust_wait_mem_ready2,
		cpust_wait_mem_load1, 
		cpust_wait_mem_load2,
		cpust_wait_mem_store1,
		cpust_wait_mem_store2: begin
			pipelineStage0_r_next = pipelineStage0_r;
			pipelineStage1_r_next = pipelineStage1_r;
			pipelineStage2_r_next = pipelineStage2_r;
			pipelineStage3_r_next = pipelineStage3_r;
			pipelineStage4_r_next = NOP_INSTRUCTION; // Need to clear final pipeline stage (write back) during these wait states
		end
		default: ;
	endcase
end

/* determine register A + B selection in pipleline stage 1*/

always @(*)
begin
	regARdAddr_r = 5'd16;
	regBRdAddr_r = 5'd16;

	casex (pipelineStage1_r)
		16'h0000:	;	/* nop */
		16'h01xx:	begin	/* ret / iret */
			regARdAddr_r = LINK_REGISTER; // add iret later when needed
		end
		16'h02xx, 16'h03xx: begin
			regBRdAddr_r	= reg_src_from_ins(pipelineStage1_r);
		end
		16'h04xx: begin /* alu op reg */
			regBRdAddr_r	= reg_src_from_ins(pipelineStage1_r);
		end
		16'h2xxx:	begin	/* alu op, reg reg */
			regARdAddr_r	= reg_dest_from_ins(pipelineStage1_r);
			regBRdAddr_r	= reg_src_from_ins(pipelineStage1_r);
		end
		16'h3xxx:	begin	/* alu op, reg imm */
			regARdAddr_r 		= reg_dest_from_ins(pipelineStage1_r);	
		end
		16'h4xxx:	begin /* branch */
			if (is_branch_reg_ind_from_ins(pipelineStage1_r) == 1'b1) 
				regARdAddr_r	= reg_branch_ind_from_ins(pipelineStage1_r);
		end
		16'h5xxx:	begin	/* load / store reg, reg ind */	
			regBRdAddr_r 		= reg_src_from_ins(pipelineStage1_r);	
			regARdAddr_r 		= reg_dest_from_ins(pipelineStage1_r);	
		end
		16'h6xxx: 	begin /* load / store, reg, imm address */
			regARdAddr_r 		= reg_dest_from_ins(pipelineStage1_r);	
		end
		16'b110xxxxxxxxxxxxx: begin /* memory, reg, reg + immediate index */ 
			regBRdAddr_r 		= reg_idx_from_ins(pipelineStage1_r);	
			regARdAddr_r 		= reg_dest_from_ins(pipelineStage1_r);	
		end
		16'b111xxxxxxxxxxxxx: begin /* io peek / poke */
			regBRdAddr_r 		= reg_idx_from_ins(pipelineStage1_r);	
			regARdAddr_r 		= reg_dest_from_ins(pipelineStage1_r);		
		end
		default: ;
	endcase
end

/* reg A / B in pipeline stage 0 */
always @(*)
begin
	regARdAddr_stage0_r = 5'd16;
	regBRdAddr_stage0_r = 5'd16;

	casex (pipelineStage0_r) /* instruction before its loaded */
		16'h0000:	;	/* nop */
		16'h01xx:	begin	/* ret / iret */
			regARdAddr_stage0_r = LINK_REGISTER; // add iret later when needed
		end
		16'h02xx, 16'h03xx: begin
			regBRdAddr_stage0_r	= reg_src_from_ins(pipelineStage0_r);
		end
		16'h04xx: begin /* alu op reg */
			regBRdAddr_stage0_r	= reg_src_from_ins(pipelineStage0_r);
		end
		16'h2xxx:	begin	/* alu op, reg reg */
			regARdAddr_stage0_r	= reg_dest_from_ins(pipelineStage0_r);
			regBRdAddr_stage0_r	= reg_src_from_ins(pipelineStage0_r);
		end
		16'h3xxx:	begin	/* alu op, reg imm */
			regARdAddr_stage0_r 		= reg_dest_from_ins(pipelineStage0_r);	
		end
		16'h4xxx:	begin /* branch */
			if (is_branch_reg_ind_from_ins(memoryIn) == 1'b1) 
				regARdAddr_stage0_r	= reg_branch_ind_from_ins(pipelineStage0_r);
		end
		16'h5xxx:	begin	/* load / store reg, reg ind */	
			regBRdAddr_stage0_r 		= reg_src_from_ins(pipelineStage0_r);	
			regARdAddr_stage0_r 		= reg_dest_from_ins(pipelineStage0_r);	
		end
		16'h6xxx: 	begin /* load / store, reg, imm address */
			regARdAddr_stage0_r 		= reg_dest_from_ins(pipelineStage0_r);	
		end
		16'b110xxxxxxxxxxxxx: begin /* memory, reg, reg + immediate index */ 
			regBRdAddr_stage0_r 		= reg_idx_from_ins(pipelineStage0_r);	
			regARdAddr_stage0_r 		= reg_dest_from_ins(pipelineStage0_r);	
		end
		16'b111xxxxxxxxxxxxx: begin /* io peek / poke */
			regBRdAddr_stage0_r 		= reg_idx_from_ins(pipelineStage0_r);	
			regARdAddr_stage0_r 		= reg_dest_from_ins(pipelineStage0_r);		
		end
		default: ;
	endcase
end

/* io peek / poke */

always @(*)
begin
	portAddress_r_next = portAddress_r;
	portOut_r_next = portOut_r;
	portRd_r = 1'b0;
	portWr_r = 1'b0;

	case (prev_cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store: begin
	
			casex (pipelineStage2_r)
				16'b111xxxxxxxxxxxxx: begin
					portAddress_r_next 	= regB + imm_stage2_r;
				
					if (is_io_poke_from_ins(pipelineStage2_r) == 1'b1) 
						portOut_r_next = regA;
				end
				default: ;
			endcase

			casex (pipelineStage3_r)
				16'b111xxxxxxxxxxxxx:
					if (is_io_poke_from_ins(pipelineStage3_r) == 1'b1) 
						portWr_r = 1'b1; //poke
					else
						portRd_r = 1'b1; // peek
				default: ;
			endcase
		end
	endcase
end

/* immediate register */

always @(*)
begin
	imm_r_next = {12{1'b0}};

	// Don't change on a nop
	if (pipelineStage1_r == 16'h0000) 
		imm_r_next = imm_r;

	if (stall_count_r > 3'b001)
		imm_r_next = imm_r;

	case (cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store: ;
		default: imm_r_next = imm_r;
	endcase

	imm_stage2_r_next = imm_stage2_r;

	case (prev_cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store: begin
			imm_stage2_r_next 	= {imm_r, imm_lo_from_ins(pipelineStage1_r)};
		end
	endcase

	casex (pipelineStage1_r)
		16'h1xxx:   	/* imm */
			imm_r_next 	= imm_r_from_ins(pipelineStage1_r);
		default: ;
	endcase

end

/* determine memory output and memory address */

always @(*)
begin
	loadStoreAddr_stage3_r_next = loadStoreAddr_stage3_r;
	memoryOut_stage3_r_next 	= memoryOut_stage3_r;
	
	case (prev_cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store: begin
			casex (pipelineStage2_r)
				16'h5xxx:	begin /* load store, reg address */
					loadStoreAddr_stage3_r_next = regB;
					memoryOut_stage3_r_next = regA;
				end
				16'h6xxx:	begin /* load store, imm address */
					// Store address
					loadStoreAddr_stage3_r_next = imm_stage2_r;
					memoryOut_stage3_r_next = regA;
				end
				16'b110xxxxxxxxxxxxx: begin /* memory, reg, reg + immediate index */ 
					loadStoreAddr_stage3_r_next = regB + imm_stage2_r;
					memoryOut_stage3_r_next = regA;
				end
			endcase
		end
		default: ;
	endcase	
end

/* determine ALU operation */

always @(*)
begin

	aluA_r_next = aluA_r;
	aluB_r_next = aluB_r;
	alu_op_r_next = alu_op_r; 
	
	case (prev_cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store: begin
	
			aluA_r_next = regA;
			aluB_r_next = regB;
			alu_op_r_next = 5'd0; /* mov - noop */

			casex (pipelineStage2_r)
				16'h04xx:	begin /* alu op, reg */
					alu_op_r_next 	= single_reg_alu_op_from_ins(pipelineStage2_r);
				end
				16'h2xxx:   begin /* alu op, reg reg */
					alu_op_r_next 	= alu_op_from_ins(pipelineStage2_r);
				end
				16'h3xxx:	begin	/* alu op, reg imm */
					aluB_r_next 	= imm_stage2_r;
					alu_op_r_next 	= alu_op_from_ins(pipelineStage2_r);
				end
				default: ;
			endcase
		end
	endcase

end

/* determine result of execution */
always @(*)
begin
	result_stage2_r_next = result_stage2_r; 
	result_stage3_r_next = result_stage3_r;
	result_stage4_r_next = result_stage4_r;

	case (prev_cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store: begin
	
			result_stage2_r_next = pc_r_prev - 1; // PC for write back of link register 
			result_stage3_r_next = result_stage2_r;
			result_stage4_r_next = result_stage3_r;

			casex (pipelineStage2_r)
				16'h02xx:	begin /* inc */
					result_stage3_r_next = regB + 1;
				end
				16'h03xx:   begin /* dec */
					result_stage3_r_next = regB - 1;
				end
			endcase
		end
	endcase
end

/* determine write back register */
always @(*)
begin

	reg_wr_addr_r = 5'd16;
	reg_out_r = result_stage4_r;

	casex (pipelineStage4_r)
		16'h02xx, 16'h03xx: begin /* inc / dec / alu op reg */
			reg_wr_addr_r 	= reg_src_from_ins(pipelineStage4_r);
			reg_out_r 		= result_stage4_r; 	
		end
		16'h04xx: begin /* inc / dec / alu op reg */
			reg_wr_addr_r 	= reg_src_from_ins(pipelineStage4_r);
			reg_out_r 		= aluOut; 	
		end
		16'h3xxx, 16'h2xxx: begin /* alu op */
			reg_wr_addr_r 	= reg_dest_from_ins(pipelineStage4_r);
			reg_out_r 		= aluOut; 	
		end
		16'h4xxx: begin /* branch */
			if (is_branch_link_from_ins(pipelineStage4_r) == 1'b1) begin
				reg_wr_addr_r   = LINK_REGISTER; /* link register */
				reg_out_r		= result_stage4_r;
			end
		end
		16'h5xxx, 16'h6xxx, 16'b110xxxxxxxxxxxxx:	begin /* load store, imm address */
			if (is_load_store_from_ins(pipelineStage4_r) == 1'b0) begin /* load */
				// write back value 
				reg_wr_addr_r = reg_dest_from_ins(pipelineStage4_r);
				reg_out_r = memoryIn;
			end	
		end
		16'b111xxxxxxxxxxxxx: begin /* io peek? */
			if (is_io_poke_from_ins(pipelineStage4_r) == 1'b0) begin
				reg_wr_addr_r = reg_dest_from_ins(pipelineStage4_r);
				reg_out_r = portIn;
			end
		end
		default: ;
	endcase
end

endmodule
