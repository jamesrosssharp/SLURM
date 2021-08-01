/* pipeline16.v : 16 bit pipeline */

module pipeline16
(
	input CLK,
	input RSTb,
	input [15:0] memoryIn,

	/* flags from ALU */
	input C,	
	input Z,
	input S,

	/* control signals to ALU */
	output [3:0]    aluOp,

	/* pipeline output register */
	output [15:0]   pout,

	/* control signals to register file */
	output [7 : 0]  LD_reg_ALUb, /* Active low bit vector to load
												register(s) from ALU output */
	output [7 : 0]  LD_reg_Mb,  /* Active low bit vector to load
												register(s) from memory */
	output  [7 : 0] LD_reg_Pb,  /* Active low bit vector to load
												register(s) from pipeline (constants in instruction words etc) */

	output [2 : 0]  ALU_A_SEL,   		/* index of register driving ALU A bus */
 	output [2 : 0]  ALU_B_SEL,   		/* index of register driving ALU B bus */

	output M_ENb,					    /* enable register to drive memory bus */
 	output [2 : 0] M_SEL,       	    /* index of register driving memory bus */

 	output [2 : 0] MADDR_SEL,   		/* index of register driving memory address bus */

	output [7 : 0] INCb,  	  			/* active low register increment */
	output [7 : 0] DECb,  	  			/* active low register decrement */

	output ALU_B_from_inP_b,			/* 1 = ALU B from registers, 0 = ALU B from inP (pipeline constant register) */

	/* control signals to memory */

	output mem_OEb, /* output enable */
	output mem_WRb  /* write memory */
);

reg [15:0] pipeline_stage0_reg;
reg [15:0] pipeline_stage0_reg_next;

reg [15:0] pipeline_stage1_reg;

reg pipeline_stall_reg;
reg pipeline_stall_reg_next;

reg delay_slot_reg;
reg delay_slot_reg_next;

localparam NOP_INSTRUCTION = 16'h0000;

reg [3:0]    aluOp_reg;
reg [3:0]    pout_reg;
reg [11:0]   imm_reg;
reg [11:0]   imm_reg_next;
reg [7 : 0]  LD_reg_ALUb_reg;
reg [7 : 0]  LD_reg_Mb_reg;
reg [7 : 0]  LD_reg_Pb_reg;
reg [2 : 0]  ALU_A_SEL_reg;
reg [2 : 0]  ALU_B_SEL_reg;
reg M_ENb_reg;
reg [2 : 0] M_SEL_reg;
reg [2 : 0] MADDR_SEL_reg;
reg [7 : 0] INCb_reg;
reg [7 : 0] DECb_reg;
reg ALU_B_from_inP_b_reg;
reg mem_OEb_reg;
reg mem_WRb_reg;

assign aluOp = aluOp_reg;
assign pout = {imm_reg, pout_reg};
assign LD_reg_ALUb = LD_reg_ALUb_reg;
assign LD_reg_Mb = LD_reg_Mb_reg;
assign LD_reg_Pb = LD_reg_Pb_reg;
assign ALU_A_SEL = ALU_A_SEL_reg;
assign ALU_B_SEL = ALU_B_SEL_reg;
assign M_ENb = M_ENb_reg;
assign M_SEL = M_SEL_reg;
assign MADDR_SEL = MADDR_SEL_reg;
assign INCb = INCb_reg;
assign DECb = DECb_reg;
assign ALU_B_from_inP_b = ALU_B_from_inP_b_reg;
assign mem_OEb = mem_OEb_reg;
assign mem_WRb = mem_WRb_reg;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pipeline_stage0_reg <= NOP_INSTRUCTION;
		pipeline_stage1_reg <= NOP_INSTRUCTION;
		pipeline_stall_reg 	<= 0;
		imm_reg 			<= 12'h000;
		delay_slot_reg 		<= 0;
	end
	else begin
		pipeline_stage0_reg <= pipeline_stage0_reg_next;
		pipeline_stage1_reg <= pipeline_stage0_reg;
		pipeline_stall_reg  <= pipeline_stall_reg_next;
		imm_reg 			<= imm_reg_next;
		delay_slot_reg 		<= delay_slot_reg_next;
	end
end

/* is a branch taken based in pipeline stage 0 */
function branch_taken_p0;
input [15:0] p0;
begin
	case(p0[10:8])
		3'b000:		/* 0x0 - BZ, branch if ZERO */
			if (Z == 1'b1) branch_taken_p0 = 1'b1;
		3'b001:		/* 0x1 - BNZ, branch if not ZERO */
			if (Z == 1'b0) branch_taken_p0 = 1'b1;
		3'b010:		/* 0x2 - BS, branch if SIGN */
			if (S == 1'b1) branch_taken_p0 = 1'b1;
		3'b011:		/* 0x3 - BNS, branch if not SIGN */
			if (S == 1'b0) branch_taken_p0 = 1'b1;
		3'b100:		/* 0x4 - BC, branch if CARRY */
			if (S == 1'b1) branch_taken_p0 = 1'b1;
		3'b101:		/* 0x5 - BNC, branch if not CARRY */
			if (S == 1'b0) branch_taken_p0 = 1'b1;
		3'b110:		/* 0x6 - BA, branch always */
			branch_taken_p0 = 1'b1;
		3'b111:		/* 0x7 - BL, branch link */
			branch_taken_p0 = 1'b0; /* don't branch in p0 */
	endcase
end
endfunction

/* alu operation from pipeline stage 0 */
function [3:0] alu_op_p0;
input [15:0] p0;
	alu_op_p0 = p0[11:8];
endfunction

/* source register for alu operations in pipeline stage 0 */
function [2:0] src_reg_p0;
input [15:0] p0;
	src_reg_p0 = p0[2:0];
endfunction

/* dest register for alu operations in pipeline stage 0 */
function [2:0] dest_reg_p0;
input [15:0] p0;
	dest_reg_p0 = p0[6:4];
endfunction

/* imm register for alu / branch operations in pipeline stage 0 */
function [3:0] imm_reg_p0;
input [15:0] p0;
	imm_reg_p0 = p0[3:0];
endfunction

/* bit 7 indicates whether or not the result of an alu operation should be stored, so it's possible
 * to implement cmp, test and also other instructions which simply affect flags but ignore the alu result */
function store_dest_p0;
input [15:0] p0;
	store_dest_p0 = p0[7];
endfunction

function is_branch_link;
input [15:0] ins;
	is_branch_link = (ins[10:8] == 3'b111) ? 1'b1 : 1'b0;
endfunction

function ret_or_iret;
input [15:0] p0;
	ret_or_iret = p0[0]; // 0 = ret, 1 = iret
endfunction

function is_memory_load_or_store;
input [15:0] p0;
	is_memory_load_or_store = p0[8]; // 0 = load, 1 = store
endfunction

function memory_post_increment;
input [15:0] p0;
	memory_post_increment = p0[9]; // 0 = increment, 1 = no increment
endfunction

function memory_post_decrement;
input [15:0] p0;
	memory_post_decrement = p0[10]; // 0 = decrement, 1 = no increment
endfunction

function [2:0] memory_store_source;
input [15:0] p0;
	memory_store_source = p0[2:0];
endfunction

function [2:0] memory_store_index;
input [15:0] p0;
	memory_store_index = p0[6:4];
endfunction

function [2:0] memory_load_destination;
input [15:0] p0;
	memory_load_destination = p0[2:0];
endfunction

function [2:0] memory_load_index;
input [15:0] p0;
	memory_load_index = p0[6:4];
endfunction

/* instruction fetch / decode / execute logic */
always @(*)
begin
	aluOp_reg 		= 4'b0000;
	pout_reg  		= 4'b0000;
	LD_reg_ALUb_reg = 8'hff;
	LD_reg_Mb_reg   = 8'hff;
	LD_reg_Pb_reg   = 8'hff;
	ALU_A_SEL_reg   = 3'b000;
	ALU_B_SEL_reg   = 3'b000;
	M_ENb_reg 			= 1'b1;
	M_SEL_reg 			= 3'b000;	
	MADDR_SEL_reg 		= 3'b000;
	INCb_reg 			= 8'hff;
	DECb_reg 			= 8'hff;
	ALU_B_from_inP_b_reg = 1'b1;
	mem_OEb_reg = 1'b1;
	mem_WRb_reg = 1'b1;

	pipeline_stall_reg_next = 1'b0;
	delay_slot_reg_next = 1'b0;
	imm_reg_next = 12'h000;

	if (pipeline_stall_reg == 1'b1) begin
		pipeline_stage0_reg_next = NOP_INSTRUCTION;
	end else if (delay_slot_reg == 1'b1) begin // delay slot synchronizes branches, we need to cover two cycles with nops, then resume execution			
		MADDR_SEL_reg 	= 3'd7; // PC register is r7	
		pipeline_stage0_reg_next = NOP_INSTRUCTION;
		mem_OEb_reg = 1'b0;
		INCb_reg[7] = 1'b0;
	end else begin			
		MADDR_SEL_reg 				= 3'd7; // PC register is r7	
		pipeline_stage0_reg_next 	= memoryIn;
		INCb_reg[7] 				= 1'b0; // increment r7	
		mem_OEb_reg 				= 1'b0;
	end
	
	casex(pipeline_stage0_reg)
		16'h0000:	;/* NOP */
		16'h1xxx:   /* IMM */
			imm_reg_next = pipeline_stage0_reg[11:0];
		16'h2xxx:   /* ALU OP, REG, REG */
		begin
			aluOp_reg 	  		= alu_op_p0(pipeline_stage0_reg);
			ALU_A_SEL_reg 		= dest_reg_p0(pipeline_stage0_reg);
			ALU_B_SEL_reg 		= src_reg_p0(pipeline_stage0_reg);

			if (store_dest_p0(pipeline_stage0_reg) == 1'b0)
				LD_reg_ALUb_reg 	= {8{1'b1}} ^ (1 << dest_reg_p0(pipeline_stage0_reg)); 
		end
		16'h3xxx: /* ALU OP, REG, IMM */
		begin
			aluOp_reg 	  			= alu_op_p0(pipeline_stage0_reg);
			pout_reg 				= imm_reg_p0(pipeline_stage0_reg);
			ALU_A_SEL_reg 			= dest_reg_p0(pipeline_stage0_reg);
			ALU_B_from_inP_b_reg 	= 1'b0;
				
			if (store_dest_p0(pipeline_stage0_reg) == 1'b0)
				LD_reg_ALUb_reg 		= {8{1'b1}} ^ (1 << dest_reg_p0(pipeline_stage0_reg)); 			
		end
		16'h4xxx: /* branch */
		begin
			if (branch_taken_p0(pipeline_stage0_reg) == 1'b1) begin
				pipeline_stage0_reg_next = NOP_INSTRUCTION;
				INCb_reg[7] 			 = 1'b1; 			// don't increment r7
				LD_reg_Pb_reg 			 = 8'h7f; 	 		// load r7 from pout 
				pout_reg 				 = imm_reg_p0(pipeline_stage0_reg);
				delay_slot_reg_next = 1'b1;
			end
			else if (is_branch_link(pipeline_stage0_reg) == 1'b1) begin
				/*
 				 *		For branch link, we stop PC from incrementing, and move PC to R6 (LR)
 				 */
				aluOp_reg 				 = 4'b0000; 		// move
				ALU_B_SEL_reg			 = 3'b111;          // move PC
				LD_reg_ALUb_reg			 = 8'hbf;			// move PC to LR (r6)  
				INCb_reg[7] 			 = 1'b1; 			// don't increment r7
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				pout_reg 				 = imm_reg_p0(pipeline_stage0_reg); // load immediate into lowest 4 bits of pout
				LD_reg_Pb_reg 			 = 8'h7f; 	 		// load r7 from pout 
				delay_slot_reg_next = 1'b1;
			end	
		end
		16'h5xxx: begin/* memory, reg, reg index */ 
			pipeline_stall_reg_next = 1'b1; 			// We stall the pipeline so on the next cycle we can access memory	
			MADDR_SEL_reg = memory_store_index(pipeline_stage0_reg);
			INCb_reg[7] 			 = 1'b1; 			// don't increment r7 this cycle
		end
		16'h01xx: begin /* ret / iret */
				aluOp_reg 				 = 4'b0000; 		// move
				ALU_B_SEL_reg			 = ret_or_iret(pipeline_stage0_reg) ? 3'b101 : 3'b110;          // move LR or ILR (interrupt link register)
				LD_reg_ALUb_reg			 = 8'h7f;			// move LR / ILR to PC  
				INCb_reg[7] 			 = 1'b1; 			// don't increment r7
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				LD_reg_ALUb_reg 		 = 8'h7f; 	 		// load r7 from alu 
				delay_slot_reg_next  	 = 1'b1;
				end
		16'h02xx: begin /* increment multiple */
				INCb_reg[6:0] = pipeline_stage0_reg[6:0];
				end
		16'h03xx: begin /* decrement multiple */
				DECb_reg[6:0] = pipeline_stage0_reg[6:0];
				end
		default: ;
	endcase

	// Stage 1

	casex(pipeline_stage1_reg)
		16'h4xxx: /* branch */
		begin
			if (is_branch_link(pipeline_stage1_reg) == 1'b1) begin
				DECb_reg[6] = 1'b0; // Decrement link register - to account for off by one in PC when loaded
			end	
		end
		16'h5xxx: /* memory reg, reg index */		
			if (is_memory_load_or_store(pipeline_stage1_reg) == 1'b1) begin // store
				MADDR_SEL_reg = memory_store_index(pipeline_stage0_reg);
				M_ENb_reg  = 1'b0;
				M_SEL_reg  = memory_store_source(pipeline_stage1_reg);
				mem_OEb_reg      = 1'b1;
				mem_WRb_reg	   = 1'b0;
				INCb_reg[memory_store_index(pipeline_stage1_reg)] = memory_post_increment(pipeline_stage1_reg); // increment?
				DECb_reg[memory_store_index(pipeline_stage1_reg)] = memory_post_decrement(pipeline_stage1_reg); // decrement?
			end	
			else begin // load
				mem_OEb_reg      = 1'b0;
				mem_WRb_reg	   = 1'b1;
				LD_reg_Mb_reg = {8{1'b1}} ^ (1 << memory_load_destination(pipeline_stage1_reg));
				INCb_reg[memory_store_index(pipeline_stage1_reg)] = memory_post_increment(pipeline_stage1_reg); // increment?
				DECb_reg[memory_store_index(pipeline_stage1_reg)] = memory_post_decrement(pipeline_stage1_reg); // decrement?
			end
		default:;
	endcase
end

endmodule
