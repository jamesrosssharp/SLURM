/*
 *	Execute pipeline stage: execute instruction (alu, branch, load / store)
 *	
 *
 */

module slurm16_cpu_execute #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
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
	output [BITS - 1:0] memory_out,

	/* port op */
	output [ADDRESS_BITS - 1:0] port_address,
	output [BITS - 1:0] port_out, 
	output port_rd,
	output port_wr,

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
						new_pc_r = regA + imm_reg;
						load_pc_r = 1'b1;
				end
			end
			INSTRUCTION_CASEX_RET_IRET: begin
				new_pc_r = regA;
				load_pc_r = 1'b1;
			end
		endcase
	end
end

/* determine IO peek / poke */

reg [ADDRESS_BITS - 1:0] port_address_r;
reg [BITS - 1:0] port_out_r; 
reg port_rd_r;
reg port_wr_r;

assign port_address = port_address_r;
assign port_out 	= port_out_r;
assign port_rd 		= port_rd_r;
assign port_wr 		= port_wr_r;

always @(*)
begin
	port_address_r = {ADDRESS_BITS{1'b0}};
	port_out_r = {BITS{1'b0}};
	port_rd_r = 1'b0;
	port_wr_r = 1'b0;

	if (is_executing) begin
		casex(instruction)
			INSTRUCTION_CASEX_PEEK_POKE: begin
				port_address_r = regB + imm_reg;
				if (is_io_poke_from_ins(instruction) == 1'b1) begin
					port_wr_r = 1'b1;
					port_out_r = regA;
				end else
					port_rd_r = 1'b1;
			end
		endcase
	end
end

/* determine load / store */

reg load_memory_r;
reg store_memory_r;
reg [ADDRESS_BITS - 1:0] load_store_address_r;
reg [BITS - 1:0] memory_out_r;

assign load_memory = load_memory_r;
assign store_memory = store_memory_r;
assign load_store_address = load_store_address_r;
assign memory_out = memory_out_r;

always @(*)
begin
	load_store_address_r = {ADDRESS_BITS{1'b0}};
	memory_out_r 		 = {BITS{1'b0}};
	load_memory_r 		 = 1'b0;
	store_memory_r 		 = 1'b0;

	if (is_executing) begin
		casex(instruction)
			INSTRUCTION_CASEX_LOAD_STORE: begin
				load_store_address_r = regB + imm_reg;
				if (is_load_store_from_ins(instruction) == 1'b1) begin
					store_memory_r = 1'b1;
					memory_out_r = regA;
				end else
					load_memory_r = 1'b1;
			end
		endcase
	end
end



endmodule
