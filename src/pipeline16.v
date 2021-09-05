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
	output [4:0]    aluOp,

	/* pipeline output register */
	output [15:0]   pout,

	/* control signals to register file */
	output [15 : 0]  LD_reg_ALUb, /* Active low bit vector to load
												register(s) from ALU output */
	output [15 : 0]  LD_reg_Mb,  /* Active low bit vector to load
												register(s) from memory */
	output  [15 : 0] LD_reg_Pb,  /* Active low bit vector to load
												register(s) from pipeline (constants in instruction words etc) */

	output [3 : 0]  ALU_A_SEL,   		/* index of register driving ALU A bus */
 	output [3 : 0]  ALU_B_SEL,   		/* index of register driving ALU B bus */

	output M_ENb,					    /* enable register to drive memory bus */
 	output [3 : 0] M_SEL,       	    /* index of register driving memory bus */

 	output [3 : 0] MADDR_SEL,   		/* index of register driving memory address bus */
	output MADDR_ALU_SELb,				/* select MADDR from ALU output */
	output MADDR_POUT_SELb,				/* select MADDR from POUT */


	output [15 : 0] INCb,  	  			/* active low register increment */
	output [15 : 0] DECb,  	  			/* active low register decrement */

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

reg [4:0]    aluOp_reg;
reg [3:0]    pout_reg;
reg [11:0]   imm_reg;
reg [11:0]   imm_reg_next;
reg [15 : 0]  LD_reg_ALUb_reg;
reg [15 : 0]  LD_reg_Mb_reg;
reg [15 : 0]  LD_reg_Pb_reg;
reg [3 : 0]  ALU_A_SEL_reg;
reg [3 : 0]  ALU_B_SEL_reg;
reg M_ENb_reg;
reg [3 : 0] M_SEL_reg;
reg [3 : 0] MADDR_SEL_reg;
reg MADDR_ALU_SELb_reg;				/* select MADDR from ALU output */
reg MADDR_POUT_SELb_reg;				/* select MADDR from POUT */
reg [15 : 0] INCb_reg;
reg [15 : 0] DECb_reg;
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
assign MADDR_ALU_SELb = MADDR_ALU_SELb_reg;
assign MADDR_POUT_SELb = MADDR_POUT_SELb_reg;
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
input Z_in;
input S_in;
input C_in;
begin
	case(p0[10:8])
		3'b000:		/* 0x0 - BZ, branch if ZERO */
			if (Z_in == 1'b1) branch_taken_p0 = 1'b1;
			else branch_taken_p0 = 1'b0;
	
		3'b001:		/* 0x1 - BNZ, branch if not ZERO */
			if (Z_in == 1'b0) branch_taken_p0 = 1'b1;
			else branch_taken_p0 = 1'b0;
	
		3'b010:		/* 0x2 - BS, branch if SIGN */
			if (S_in == 1'b1) branch_taken_p0 = 1'b1;
			else branch_taken_p0 = 1'b0;
	
		3'b011:		/* 0x3 - BNS, branch if not SIGN */
			if (S_in == 1'b0) branch_taken_p0 = 1'b1;
			else branch_taken_p0 = 1'b0;
	
		3'b100:		/* 0x4 - BC, branch if CARRY */
			if (C_in == 1'b1) branch_taken_p0 = 1'b1;
			else branch_taken_p0 = 1'b0;
	
		3'b101:		/* 0x5 - BNC, branch if not CARRY */
			if (C_in == 1'b0) branch_taken_p0 = 1'b1;
			else branch_taken_p0 = 1'b0;
		3'b110:		/* 0x6 - BA, branch always */
			branch_taken_p0 = 1'b1;
		3'b111:		/* 0x7 - BL, branch link */
			branch_taken_p0 = 1'b0; /* don't branch in p0 */
	endcase
end
endfunction

/* register to increment or decrement */
function [3:0] inc_dec_reg_p0;
input [15:0] p0;
	inc_dec_reg_p0 = p0[3:0];
endfunction

/* alu operation from pipeline stage 0 */
function [3:0] alu_op_p0;
input [15:0] p0;
	alu_op_p0 = p0[11:8];
endfunction

/* alu operation for single register alu op */
function [3:0] alu_op_single_reg;
input [15:0] p0;
	alu_op_single_reg = p0[7:4];
endfunction

/* source register for alu operations in pipeline stage 0 */
function [3:0] src_reg_p0;
input [15:0] p0;
	src_reg_p0 = p0[3:0];
endfunction

/* dest register for alu operations in pipeline stage 0 */
function [3:0] dest_reg_p0;
input [15:0] p0;
	dest_reg_p0 = p0[7:4];
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

function is_branch_reg_ind;
input [15:0] ins;
	is_branch_reg_ind = ins[11];
endfunction

function [2:0] branch_reg_ind;
input [15:0] ins;
		branch_reg_ind = ins[6:4];
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

function [3:0] memory_store_source;
input [15:0] p0;
	memory_store_source = p0[7:4];
endfunction

function [3:0] memory_store_index;
input [15:0] p0;
	memory_store_index = p0[3:0];
endfunction

function [3:0] memory_load_destination;
input [15:0] p0;
	memory_load_destination = p0[7:4];
endfunction

function [3:0] memory_load_index;
input [15:0] p0;
	memory_load_index = p0[3:0];
endfunction

function [3:0] class12_idx_reg_p0;
input [15:0] p0;
	class7_idx_reg_p0 = p0[12:9];
endfunction

/* is a relative branch taken based */
function rel_branch_taken;
input [15:0] p0;
input Z_in;
input S_in;
input C_in;
begin
	case(p0[12:10])
		3'b000:		/* 0x0 - BZ, branch if ZERO */
			if (Z_in == 1'b1) rel_branch_taken = 1'b1;
			else rel_branch_taken = 1'b0;
		3'b001:		/* 0x1 - BNZ, branch if not ZERO */
			if (Z_in == 1'b0) rel_branch_taken = 1'b1;
			else rel_branch_taken = 1'b0;
		3'b010:		/* 0x2 - BS, branch if SIGN */
			if (S_in == 1'b1) rel_branch_taken = 1'b1;
			else rel_branch_taken = 1'b0;
		3'b011:		/* 0x3 - BNS, branch if not SIGN */
			if (S_in == 1'b0) rel_branch_taken = 1'b1;
			else rel_branch_taken = 1'b0;
		3'b100:		/* 0x4 - BC, branch if CARRY */
			if (S_in == 1'b1) rel_branch_taken = 1'b1;
			else rel_branch_taken = 1'b0;
		3'b101:		/* 0x5 - BNC, branch if not CARRY */
			if (S_in == 1'b0) rel_branch_taken = 1'b1;
			else rel_branch_taken = 1'b0;
		3'b110:		/* 0x6 - BA, branch always */
			rel_branch_taken = 1'b1;
		3'b111:		/* 0x7 - BL, branch link */
			rel_branch_taken = 1'b0; /* BL handled separately */
	endcase
end
endfunction

function is_rel_branch_link;
input [15:0] ins;
	is_rel_branch_link = (ins[12:10] == 3'b111) ? 1'b1 : 1'b0;
endfunction

function [4:0] rel_branch_const_upper;
input [15:0] ins;
	rel_branch_const_upper = ins[8:4];
endfunction

function [3:0] rel_branch_const_lower;
input [15:0] ins;
	rel_branch_const_lower = ins[3:0];
endfunction

function rel_branch_const_sign;
input [15:0] ins;
	rel_branch_const_sign = ins[8];
endfunction

function [3:0] alu_op3;
input [15:0] ins;
	alu_op3 = ins[12:9];
endfunction

function [2:0] alu_dest_reg3;
input [15:0] ins;
	alu_dest_reg3 = ins[8:6];
endfunction

function [2:0] alu_src_reg3;
input [15:0] ins;
	alu_src_reg3 = ins[2:0];
endfunction

function [2:0] alu_src2_reg3;
input [15:0] ins;
	alu_src2_reg3 = ins[5:3];
endfunction


/* instruction fetch / decode / execute logic */
always @(*)
begin
	aluOp_reg 		= 5'b0000;
	pout_reg  		= 4'b0000;
	LD_reg_ALUb_reg = 8'hff;
	LD_reg_Mb_reg   = 8'hff;
	LD_reg_Pb_reg   = 8'hff;
	ALU_A_SEL_reg   = 3'b000;
	ALU_B_SEL_reg   = 3'b000;
	M_ENb_reg 			= 1'b1;
	M_SEL_reg 			= 3'b000;	
	MADDR_SEL_reg 		= 3'b000;
	MADDR_ALU_SELb_reg	= 1'b1;
	MADDR_POUT_SELb_reg	= 1'b1;
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
		16'h01xx: begin /* ret / iret */
				aluOp_reg 				 = 5'b00000; 												// move
				ALU_B_SEL_reg			 = ret_or_iret(pipeline_stage0_reg) ? 4'b1101 : 4'b1110;    // move LR or ILR (interrupt link register)
				LD_reg_ALUb_reg			 = 16'h7fff;												// move LR / ILR to PC  
				INCb_reg[15] 			 = 1'b1; 													// don't increment r7
				pipeline_stage0_reg_next = NOP_INSTRUCTION; 										// feed nop
				LD_reg_ALUb_reg 		 = 16'h7fff; 	 											// load r7 from alu 
				delay_slot_reg_next  	 = 1'b1;
				end
		16'h02xx: begin /* increment */
				INCb_reg[inc_dec_reg_p0(pipeline_stage0_reg)] = 1'b0;
				end
		16'h03xx: begin /* decrement */
				DECb_reg[inc_dec_reg_p0(pipeline_stage0_reg)] = 1'b0;
				end
		16'h04xx: begin /* single register ALU operation */
				aluOp_reg[3:0] 	  		= alu_op_single_reg(pipeline_stage0_reg);
				aluOp_reg[4] = 1'b1;
				ALU_A_SEL_reg 			= src_reg_p0(pipeline_stage0_reg);
				ALU_B_SEL_reg 			= src_reg_p0(pipeline_stage0_reg);
				LD_reg_ALUb_reg 	= {16{1'b1}} ^ (1 << src_reg_p0(pipeline_stage0_reg)); 
				end
		16'h1xxx:   /* IMM */
			imm_reg_next = pipeline_stage0_reg[11:0];
		16'h2xxx:   /* ALU OP, REG, REG */
		begin
			aluOp_reg[3:0] 	  		= alu_op_p0(pipeline_stage0_reg);
			aluOp_reg[4] = 1'b0;
			ALU_A_SEL_reg 			= dest_reg_p0(pipeline_stage0_reg);
			ALU_B_SEL_reg 			= src_reg_p0(pipeline_stage0_reg);

			LD_reg_ALUb_reg 	= {16{1'b1}} ^ (1 << dest_reg_p0(pipeline_stage0_reg)); 
		end
		16'h3xxx: /* ALU OP, REG, IMM */
		begin
			aluOp_reg[3:0] 	  			= alu_op_p0(pipeline_stage0_reg);
			aluOp_reg[4] = 1'b0;
			pout_reg 				= imm_reg_p0(pipeline_stage0_reg);
			ALU_A_SEL_reg 			= dest_reg_p0(pipeline_stage0_reg);
			ALU_B_from_inP_b_reg 	= 1'b0;
				
			LD_reg_ALUb_reg 		= {16{1'b1}} ^ (1 << dest_reg_p0(pipeline_stage0_reg)); 			
		end
		16'h4xxx: /* branch */
		begin
			if (branch_taken_p0(pipeline_stage0_reg, Z, S, C) == 1'b1) begin
				if (is_branch_reg_ind(pipeline_stage0_reg)) begin
					pipeline_stage0_reg_next = NOP_INSTRUCTION;
					INCb_reg[15] 			 = 1'b1; 				// don't increment r15
					LD_reg_ALUb_reg 		 = 16'h7fff; 	 		    // load PC from alu 
			        ALU_B_from_inP_b_reg     = 1'b0;
					aluOp_reg  				 = 5'b00001;
					ALU_A_SEL_reg			 = branch_reg_ind(pipeline_stage0_reg); // move reg indirect to PC
					delay_slot_reg_next = 1'b1;
				end else begin
					pipeline_stage0_reg_next = NOP_INSTRUCTION;
					INCb_reg[15] 			 = 1'b1; 			// don't increment r15
					LD_reg_Pb_reg 			 = 16'h7fff; 	 		// load r15 from pout 
					pout_reg 				 = imm_reg_p0(pipeline_stage0_reg);
					delay_slot_reg_next = 1'b1;
				end
			end
			else if (is_branch_link(pipeline_stage0_reg) == 1'b1) begin
				/*
 				 *		For branch link, we stop PC from incrementing, and move PC to R14 (LR)
 				 */
				
				if (is_branch_reg_ind(pipeline_stage0_reg)) begin
					aluOp_reg 				 = 5'b00000; 		// move
					ALU_B_SEL_reg			 = 4'b1111;          // move PC
					LD_reg_ALUb_reg			 = 16'hbfff;			// move PC to LR (r14)  
					INCb_reg[15] 			 = 1'b1; 			// don't increment r15
					pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
					imm_reg_next			 = imm_reg; // preserve imm
					pout_reg 				 = imm_reg_p0(pipeline_stage0_reg); // load immediate into lowest 4 bits of pout
					pipeline_stall_reg_next  = 1'b1;
				end else begin
					aluOp_reg 				 = 5'b00000; 		// move
					ALU_B_SEL_reg			 = 4'b1111;         // move PC
					LD_reg_ALUb_reg			 = 16'hbfff;		// move PC to LR (r14)  
					INCb_reg[15] 			 = 1'b1; 			// don't increment r15
					pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
					pout_reg 				 = imm_reg_p0(pipeline_stage0_reg); // load immediate into lowest 4 bits of pout
					LD_reg_Pb_reg 			 = 16'h7fff; 	 		// load r15 from pout 
					delay_slot_reg_next 	 = 1'b1;
				end

			end	
		end
		16'h5xxx: begin /* memory, reg, reg index */ 
		
			if (is_memory_load_or_store(pipeline_stage0_reg) == 1'b0) begin // load
				pipeline_stall_reg_next  = 1'b1; 			// We stall the pipeline so on the next cycle we can access memory	
				MADDR_SEL_reg 			 = memory_load_index(pipeline_stage0_reg);
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				DECb_reg[15] 			 = 1'b0; 			// decrement r15 this cycle
			end	
			else begin // store
				MADDR_SEL_reg 	= memory_store_index(pipeline_stage0_reg);
				M_ENb_reg  		= 1'b0;
				M_SEL_reg  		= memory_store_source(pipeline_stage0_reg);
				mem_OEb_reg     = 1'b1;
				mem_WRb_reg	   	= 1'b0;
				INCb_reg[memory_store_index(pipeline_stage0_reg)] = memory_post_increment(pipeline_stage0_reg); // increment?
				DECb_reg[memory_store_index(pipeline_stage0_reg)] = memory_post_decrement(pipeline_stage0_reg); // decrement?
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				DECb_reg[15] 			 = 1'b0; 			// decrement r15 this cycle
			end

			INCb_reg[15] 			 = 1'b1; 			// don't increment r7 this cycle
		end
		16'h6xxx: begin /* memory, reg, immediate index */
   			if (is_memory_load_or_store(pipeline_stage0_reg) == 1'b0) begin // load
				pout_reg                                 = imm_reg_p0(pipeline_stage0_reg); // load immediate into lowest 4 bits of pout
		    	MADDR_POUT_SELb_reg    = 1'b0;
				imm_reg_next = imm_reg; // preserve imm
				pipeline_stall_reg_next  = 1'b1; 			// We stall the pipeline so on the next cycle we can access memory	
				MADDR_SEL_reg 			 = memory_load_index(pipeline_stage0_reg);
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				DECb_reg[15] 			 = 1'b0; 			// decrement r7 this cycle
			end	
			else begin // store
				pout_reg                                 = imm_reg_p0(pipeline_stage0_reg); // load immediate into lowest 4 bits of pout
		    	MADDR_POUT_SELb_reg    = 1'b0;
				M_ENb_reg  		= 1'b0;
				M_SEL_reg  		= memory_store_source(pipeline_stage0_reg);
				mem_OEb_reg     = 1'b1;
				mem_WRb_reg	   	= 1'b0;
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				DECb_reg[15] 			 = 1'b0; 			// decrement r7 this cycle
			end
			INCb_reg[15] 			 = 1'b1; 			// don't increment r7 this cycle
		end
		16'h7xxx: begin 
			// reserved	
		end
		16'b100xxxxxxxxxxxxx:  /* ALU op, reg, reg, reg */
		begin
			aluOp_reg[3:0] 	  	= alu_op3(pipeline_stage0_reg);
			aluOp_reg[4]		= 1'b0;
			ALU_A_SEL_reg 		= alu_src2_reg3(pipeline_stage0_reg);
			ALU_B_SEL_reg 		= alu_src_reg3(pipeline_stage0_reg);

			LD_reg_ALUb_reg 	= {16{1'b1}} ^ (1 << alu_dest_reg3(pipeline_stage0_reg)); 
		end
		16'b101xxxxxxxxxxxxx: begin /* relative branch */
			if (rel_branch_taken(pipeline_stage0_reg, Z, S, C) == 1'b1) begin
				// Branch taken: move relative constant to imm_reg
		        INCb_reg[15]              = 1'b1;            // don't increment r15
                pipeline_stage0_reg_next  = NOP_INSTRUCTION; // feed nop
                imm_reg_next[11:5] 		  = {7{rel_branch_const_sign(pipeline_stage0_reg)}};
				imm_reg_next[4:0] 		  = rel_branch_const_upper(pipeline_stage0_reg);
				delay_slot_reg_next  	  = 1'b1;
			end
			else if (is_rel_branch_link(pipeline_stage0_reg) == 1'b1) begin
				// Branch-link: move PC to link register and relative constant to imm_reg
				imm_reg_next[11:5] = {7{rel_branch_const_sign(pipeline_stage0_reg)}};
				imm_reg_next[4:0] = rel_branch_const_upper(pipeline_stage0_reg);
				aluOp_reg                = 5'b00000;         // move
                ALU_B_SEL_reg            = 4'b1111;          // move PC
                LD_reg_ALUb_reg          = 16'hbfff;           // move PC to LR (r14)  
                INCb_reg[15]             = 1'b1;            // don't increment r15
                pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
                delay_slot_reg_next  = 1'b1;
			end	
		end
		16'b110xxxxxxxxxxxxx: begin /* memory, reg, reg + immediate index */ 

			ALU_A_SEL_reg                   = class12_idx_reg_p0(pipeline_stage0_reg);
            ALU_B_from_inP_b_reg    = 1'b0;
            MADDR_ALU_SELb_reg    = 1'b0;  
			aluOp_reg  = 5'b00001;
			pout_reg                                 = imm_reg_p0(pipeline_stage0_reg); // load immediate into lowest 4 bits of pout
		
			if (is_memory_load_or_store(pipeline_stage0_reg) == 1'b0) begin // load
				imm_reg_next = imm_reg; // preserve imm
				pipeline_stall_reg_next  = 1'b1; 			// We stall the pipeline so on the next cycle we can access memory	
				MADDR_SEL_reg 			 = memory_load_index(pipeline_stage0_reg);
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				DECb_reg[15] 			 = 1'b0; 			// decrement r15 this cycle
			end	
			else begin // store
				M_ENb_reg  		= 1'b0;
				M_SEL_reg  		= memory_store_source(pipeline_stage0_reg);
				mem_OEb_reg     = 1'b1;
				mem_WRb_reg	   	= 1'b0;
				pipeline_stage0_reg_next = NOP_INSTRUCTION; // feed nop
				DECb_reg[15] 	= 1'b0; 			// decrement r15 this cycle
			end
			INCb_reg[15] 			 = 1'b1; 			// don't increment r15 this cycle
		end
		default: ;
	endcase

	// Stage 1

	casex(pipeline_stage1_reg)
		16'h4xxx: /* branch */
		begin
			if (is_branch_link(pipeline_stage1_reg) == 1'b1) begin
				
				DECb_reg[14] = 1'b0; // Decrement link register - to account for off by one in PC when loaded
				if (is_branch_reg_ind(pipeline_stage1_reg)) begin
					LD_reg_ALUb_reg 		 = 16'h7fff; 	 		    // load PC from alu 
					ALU_B_from_inP_b_reg     = 1'b0;
					aluOp_reg  				 = 5'b00001;
					pout_reg                 = imm_reg_p0(pipeline_stage1_reg); // load immediate into lowest 4 bits of pout
					ALU_A_SEL_reg			 = branch_reg_ind(pipeline_stage1_reg); // move reg indirect to PC
					delay_slot_reg_next = 1'b1;
				end else begin
				end
			end	
		end
		16'h5xxx: /* memory reg, reg index */		
			if (is_memory_load_or_store(pipeline_stage1_reg) == 1'b1) begin // store
					pipeline_stage0_reg_next = NOP_INSTRUCTION;
			end	
			else begin // load
				MADDR_SEL_reg 			 = memory_load_index(pipeline_stage1_reg);
				mem_OEb_reg      		 = 1'b0;
				mem_WRb_reg	   			 = 1'b1;
				LD_reg_Mb_reg 			 = {16{1'b1}} ^ (1 << memory_load_destination(pipeline_stage1_reg));
				INCb_reg[memory_store_index(pipeline_stage1_reg)] = memory_post_increment(pipeline_stage1_reg); // increment?
				DECb_reg[memory_store_index(pipeline_stage1_reg)] = memory_post_decrement(pipeline_stage1_reg); // decrement?
			end
		16'h6xxx:  /* memory reg, immediate index */		
			if (is_memory_load_or_store(pipeline_stage1_reg) == 1'b1) begin // store
			end	
			else begin // load
				pout_reg				= imm_reg_p0(pipeline_stage1_reg); // load immediate into lowest 4 bits of pout
		    	MADDR_POUT_SELb_reg    	= 1'b0;
				mem_OEb_reg      		= 1'b0;
				mem_WRb_reg	   			= 1'b1;
				LD_reg_Mb_reg 			= {16{1'b1}} ^ (1 << memory_load_destination(pipeline_stage1_reg));
			end
		16'h7xxx;
		16'b101xxxxxxxxxxxxx: begin /* relative branch */
			if ((rel_branch_taken(pipeline_stage1_reg, Z, S, C) == 1'b1) || (is_rel_branch_link(pipeline_stage1_reg) == 1'b1)) begin
				    LD_reg_ALUb_reg 		 = 16'h7fff; 	 		    // load PC from alu 
					ALU_B_from_inP_b_reg     = 1'b0;
					aluOp_reg  				 = 5'b00001;
					pout_reg                 = rel_branch_const_lower(pipeline_stage1_reg); // load immediate into lowest 4 bits of pout
					ALU_A_SEL_reg			 = 4'b1111; // add PC + relative constant
					delay_slot_reg_next 	 = 1'b1;	
                	INCb_reg[15]             = 1'b1;            // don't increment r7
			end	
		end
		16'b110xxxxxxxxxxxxx: begin   /* memory reg, reg + immediate index */
			if (is_memory_load_or_store(pipeline_stage1_reg) == 1'b1) begin // store
			end	
			else begin // load
				ALU_A_SEL_reg           = class12_idx_reg_p0(pipeline_stage1_reg);
				ALU_B_from_inP_b_reg    = 1'b0;
				MADDR_ALU_SELb_reg    	= 1'b0;  
				aluOp_reg  				= 5'b00001;
				pout_reg                = imm_reg_p0(pipeline_stage1_reg); // load immediate into lowest 4 bits of pout
				mem_OEb_reg      		= 1'b0;
				mem_WRb_reg	   			= 1'b1;
				LD_reg_Mb_reg 			= {16{1'b1}} ^ (1 << memory_load_destination(pipeline_stage1_reg));
			end
		end
		default:;
	endcase
end

endmodule
