/*
 *	Execute pipeline stage: execute instruction (alu, branch, load / store)
 *	
 *
 */

module slurm16_cpu_execute #(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 2 */

	input is_executing,

	/* flags (for branches) */

	input Z,
	input C,
	input S,

	input [BITS - 1:0] regA,
	input [BITS - 1:0] regB,

	/* immediate register */
	input [BITS - 1:0] imm_reg,

	/* memory op */
	output load_memory,
	output store_memory,
	output [ADDRESS_BITS - 1:0] load_store_address,

	/* alu op */
	output [4:0] aluOp,
	output [BITS - 1:0] aluA,
	output [BITS - 1:0] aluB,

	/* load PC for branch / (i)ret, etc */
	output load_pc,
	output [ADDRESS_BITS - 1:0] new_pc

);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [4:0] 		alu_op_r, alu_op_r_next;
assign aluOp  = alu_op_r;

reg [BITS - 1:0] aluA_r, aluA_r_next;
reg [BITS - 1:0] aluB_r, aluB_r_next;

assign aluA = aluA_r;
assign aluB = aluB_r;

/* sequential logic */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		alu_op_r <= 5'd0;
		aluA_r <= {BITS{1'b0}};
		aluB_r <= {BITS{1'b0}};
	end else begin
		alu_op_r <= alu_op_r_next;
		aluA_r <= aluA_r_next;
		aluB_r <= aluB_r_next;
	end
end

/* combinational logic */

/* determine ALU operation */

always @(*)
begin

	aluA_r_next = aluA_r;
	aluB_r_next = aluB_r;
	alu_op_r_next = alu_op_r; 
	
	if (is_executing) begin	
			aluA_r_next = regA;
			aluB_r_next = regB;
			alu_op_r_next = 5'd0; /* mov - noop */

			casex (instruction)
				INSTRUCTION_CASEX_ALUOP_SINGLE_REG:	begin /* alu op, reg */
					alu_op_r_next 	= single_reg_alu_op_from_ins(instruction);
				end
				INSTRUCTION_CASEX_ALUOP_REG_REG:   begin /* alu op, reg reg */
					alu_op_r_next 	= alu_op_from_ins(instruction);
				end
				INSTRUCTION_CASEX_ALUOP_REG_IMM:	begin	/* alu op, reg imm */
					aluB_r_next 	= imm_reg;
					alu_op_r_next 	= alu_op_from_ins(instruction);
				end
				default: ;
			endcase
	end
end

/* determine branch */

reg 	load_pc_r;
assign  load_pc = load_pc_r;

reg [ADDRESS_BITS - 1:0] new_pc_r;
assign new_pc = new_pc_r;

always @(*)
begin
	load_pc_r = 1'b0;
	new_pc_r = {ADDRESS_BITS{1'b0}};

	if (is_executing) begin
		casex(instruction)
			INSTRUCTION_CASEX_BRANCH: begin
				if (branch_taken_from_ins(instruction, Z, S, C) == 1'b1) begin
						new_pc_r = imm_reg;
						load_pc_r = 1'b1;
				end
			end
		endcase
	end
end

endmodule
