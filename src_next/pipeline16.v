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


	/* register file interface */

	output [15:0]   regFileIn,
	output [4:0]    regWrAddr,

	output [4:0]    regARdAddr,
	output [4:0]    regBRdAddr,

	input  [15:0]	regA,
	input  [15:0] 	regB,


	/* control signals to / from memory */

	/* Halt CPU while memory is busy */
	input  BUSY,
	input  [15:0] 	memoryIn,
	output  [15:0] 	memoryOut,
	output [15:0] 	memoryAddr,
	output mem_RD, /* read mem     */
	output mem_WR  /* write mem    */
);

localparam REG_BITS = 5; /* 16 registers */
localparam BITS = 16;

/* Program counter is separate register from main register file */ 
reg [BITS - 1:0] pc_r;
reg [BITS - 1:0] pc_r_next;

reg [BITS - 1:0] memoryAddr_r;
reg mem_RD_r;
reg mem_WR_r;

assign memoryAddr 	= memoryAddr_r;
assign mem_RD 		= mem_RD_r;
assign mem_WR 		= mem_WR_r;

reg [BITS - 1:0] pipelineStage1_r;
reg [BITS - 1:0] pipelineStage1_r_next;

reg [BITS - 1:0] pipelineStage2_r;
reg [BITS - 1:0] pipelineStage2_r_next;

reg [BITS - 1:0] pipelineStage3_r;
reg [BITS - 1:0] pipelineStage3_r_next;

reg [BITS - 1:0] pipelineStage4_r;
reg [BITS - 1:0] pipelineStage4_r_next;

reg [11:0] imm_r;
reg [11:0] imm_r_next;

reg [BITS - 1:0] imm_stage2_r;
reg [BITS - 1:0] imm_stage2_r_next;

reg [BITS - 1:0] aluA_r;
reg [BITS - 1:0] aluB_r;

assign aluA = aluA_r;
assign aluB = aluB_r;

reg [REG_BITS - 1:0] regARdAddr_r;
reg [REG_BITS - 1:0] regBRdAddr_r;

assign regARdAddr = regARdAddr_r;
assign regBRdAddr = regBRdAddr_r;

reg [BITS - 1:0] result_stage3_r;
reg [BITS - 1:0] result_stage3_r_next;

reg [BITS - 1:0] result_stage4_r;
reg [BITS - 1:0] result_stage4_r_next;

reg [BITS - 1:0] reg_out_r;
assign regFileIn = reg_out_r;

reg [REG_BITS - 1:0] reg_wr_addr_r;
assign regWrAddr = reg_wr_addr_r;

reg [4:0] alu_op_r;
assign aluOp = alu_op_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pc_r <= {BITS{1'b0}};
		pipelineStage1_r <= {BITS{1'b0}};
		pipelineStage2_r <= {BITS{1'b0}};
		pipelineStage3_r <= {BITS{1'b0}};
		pipelineStage4_r <= {BITS{1'b0}};
		imm_r			 <= {12{1'b0}};
		imm_stage2_r	 <= {BITS{1'b0}};
		result_stage3_r  <= {BITS{1'b0}};
		result_stage4_r  <= {BITS{1'b0}};
	end
	else begin
		pc_r <= pc_r_next;
		pipelineStage1_r <= pipelineStage1_r_next;
		pipelineStage2_r <= pipelineStage2_r_next;
		pipelineStage3_r <= pipelineStage3_r_next;
		pipelineStage4_r <= pipelineStage4_r_next;
		imm_r			 <= imm_r_next;
		imm_stage2_r	 <= imm_stage2_r_next;
		result_stage3_r <= result_stage3_r_next;
		result_stage4_r <= result_stage4_r_next;
	end
end

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

function [4:0] reg_dest_from_ins;
input [15:0] ins;
begin
	reg_dest_from_ins = {1'b0, ins[7:4]};
end
endfunction

function [3:0]  imm_lo_from_ins;
input 	 [15:0] ins;
begin
	imm_lo_from_ins = ins[3:0];	
end
endfunction

always @(*)
begin

	alu_op_r = 5'b00000;

	result_stage3_r_next = result_stage3_r;
	result_stage4_r_next = result_stage3_r;

	reg_wr_addr_r = 5'd16;	// Default to register 16 (not used) so we have dummy op
	regARdAddr_r = 5'd0;
	regBRdAddr_r = 5'd0;

	aluA_r = {BITS{1'b0}};
	aluB_r = {BITS{1'b0}};

	/* stage 0: fetch */
	memoryAddr_r = pc_r;
	pc_r_next = pc_r + 1;

	pipelineStage1_r_next = memoryIn;
	pipelineStage2_r_next = pipelineStage1_r;
	pipelineStage3_r_next = pipelineStage2_r;
	pipelineStage4_r_next = pipelineStage3_r;

	imm_r_next = 12'h000;

	imm_stage2_r_next = {imm_r, 4'h0};

	/* pipeline stage 1: select register */
	casex (pipelineStage1_r)
		16'h0000:	;	/* nop */
		16'h1xxx:   	/* imm */
			imm_r_next 	= imm_r_from_ins(pipelineStage1_r);
		16'h3xxx:	begin	/* alu op, reg imm */
			imm_stage2_r_next 	= {imm_r, imm_lo_from_ins(pipelineStage1_r)};
			regARdAddr_r 		= reg_dest_from_ins(pipelineStage1_r);	
		end
		default: ;
	endcase

	/* pipeline stage 2: execute alu operation  */
	casex (pipelineStage2_r)
		16'h3xxx:	begin	/* alu op, reg imm */
			aluA_r 		= regA;
			aluB_r 		= imm_stage2_r;
			alu_op_r 	= alu_op_from_ins(pipelineStage2_r);
		end
		default: ;
	endcase

	/* pipeline stage 3 */
	
	casex (pipelineStage3_r)
		16'h3xxx: begin /* alu op, reg imm */
			result_stage4_r_next = aluOut;
		end
		default: ;
	endcase

	/* pipeline stage 4 write back */
	casex (pipelineStage4_r)
		16'h3xxx: begin /* alu op, reg imm */
			reg_wr_addr_r 	= reg_dest_from_ins(pipelineStage4_r);
			reg_out_r 		= result_stage4_r; 	
		end
		default: ;
	endcase


end

endmodule
