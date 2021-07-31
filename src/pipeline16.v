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
	output [3:0] aluOp,

	/* pipeline output register */
	output [15:0] pout,

	/* control signals to register file */
	output [7 : 0] LD_reg_ALUb, /* Active low bit vector to load
												register(s) from ALU output */
	output [7 : 0] LD_reg_Mb,  /* Active low bit vector to load
												register(s) from memory */
	output  [7 : 0] LD_reg_Pb,  /* Active low bit vector to load
												register(s) from pipeline (constants in instruction words etc) */

	output [2 : 0]  ALU_A_SEL,   		/* index of register driving ALU A bus */
 	output [2 : 0]  ALU_B_SEL,   		/* index of register driving ALU B bus */

	output M_ENb,					  /* enable register to drive memory bus */
 	output [2 : 0] M_SEL,       /* index of register driving memory
												bus */

 	output [2 : 0] MADDR_SEL,   /* index of register driving memory 
											  address bus */

	output [7 : 0] INCb,  	  /* active low register increment */

	output ALU_B_from_inP_b,	/* 1 = ALU B from registers, 0 = ALU B from inP (pipeline constant register) */

	/* control signals to memory */

	output mem_OEb, /* output enable */
	output mem_WRb  /* write memory */
);

reg [15:0] pipeline_stage0_reg;
reg [15:0] pipeline_stage0_reg_next;

reg [15:0] pipeline_stage1_reg;

reg [15:0] pipeline_stage2_reg;

reg pipeline_stall_reg;
reg pipeline_stall_reg_next;

localparam NOP_INSTRUCTION = 16'h0000;

reg [3:0] aluOp_reg;
reg [3:0] pout_reg;
reg [11:0] imm_reg;
reg [11:0] imm_reg_next;
reg [7 : 0] LD_reg_ALUb_reg;
reg [7 : 0] LD_reg_Mb_reg;
reg [7 : 0] LD_reg_Pb_reg;
reg [2 : 0]  ALU_A_SEL_reg;
reg [2 : 0]  ALU_B_SEL_reg;
reg M_ENb_reg;
reg [2 : 0] M_SEL_reg;
reg [2 : 0] MADDR_SEL_reg;
reg [7 : 0] INCb_reg;
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
assign ALU_B_from_inP_b = ALU_B_from_inP_b_reg;
assign mem_OEb = mem_OEb_reg;
assign mem_WRb = mem_WRb_reg;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pipeline_stage0_reg <= NOP_INSTRUCTION;
		pipeline_stage1_reg <= NOP_INSTRUCTION;
		pipeline_stage1_reg <= NOP_INSTRUCTION;
		pipeline_stall_reg <= 0;
		imm_reg <= 12'h000;
	end
	else begin
		pipeline_stage0_reg <= pipeline_stage0_reg_next;
		pipeline_stage1_reg <= pipeline_stage0_reg;
		pipeline_stage2_reg <= pipeline_stage1_reg;
		pipeline_stall_reg  <= pipeline_stall_reg_next;
		imm_reg <= imm_reg_next;
	end
end

function branch_taken_p0;
input [15:0] p0;
begin
	case(p0[11:8])
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
			branch_taken_p0 = 1'b1;
	endcase
end
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
	ALU_B_from_inP_b_reg = 1'b1;
	mem_OEb_reg = 1'b1;
	mem_WRb_reg = 1'b1;

	pipeline_stall_reg_next = 1'b0;
	imm_reg_next = 12'h000;


	if (pipeline_stall_reg == 1'b1) begin
		pipeline_stage0_reg_next = NOP_INSTRUCTION;
	end else begin			
		MADDR_SEL_reg 	= 3'd7; // PC register is r7	
		pipeline_stage0_reg_next = memoryIn;
		INCb_reg[7] 		= 1'b0; // increment r7	
		mem_OEb_reg = 1'b0;
	end

	
	casex(pipeline_stage0_reg)
		16'h0000:	;/* NOP */
		16'h1xxx:   /* IMM */
			imm_reg_next = pipeline_stage0_reg[11:0];
		16'h2xxx:   /* ALU OP, REG, REG */
		begin
			aluOp_reg 	  = pipeline_stage0_reg[11:8];
			ALU_A_SEL_reg = pipeline_stage0_reg[6:4];
			ALU_B_SEL_reg = pipeline_stage0_reg[2:0];
			LD_reg_ALUb_reg = {8{1'b1}} ^ (1 << pipeline_stage0_reg[6:4]); 
		end
		16'h3xxx: /* ALU OP, REG, IMM */
		begin
			aluOp_reg 	  = pipeline_stage0_reg[11:8];
			pout_reg = pipeline_stage0_reg[3:0];
			ALU_A_SEL_reg = pipeline_stage0_reg[6:4];
			ALU_B_from_inP_b_reg = 1'b0;
			LD_reg_ALUb_reg = {8{1'b1}} ^ (1 << pipeline_stage0_reg[6:4]); 			
		end
		16'h4xxx: /* branch */
		begin
			if (branch_taken_p0(pipeline_stage0_reg) == 1'b1) begin
				pipeline_stage0_reg_next = NOP_INSTRUCTION;
				INCb_reg[7] 		= 1'b1; // don't increment r7
				aluOp_reg = 4'b0000;
				ALU_B_from_inP_b_reg = 1'b0;
				LD_reg_ALUb_reg = {8{1'b1}} ^ (1 << 7); // load r7 from pout (contstant) 
				mem_OEb_reg = 1'b0;
				pout_reg = pipeline_stage0_reg[3:0];
				pipeline_stall_reg_next = 1'b1;
			end
				
		end
		default: ;
	endcase

end

endmodule
