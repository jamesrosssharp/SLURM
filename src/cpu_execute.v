/*
 *	Execute pipeline stage: execute instruction (alu, branch, load / store)
 *	
 *
 */

module cpu_execute #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 2 */

	input is_executing,

	/* flags (for branches) */

	input Z,
	input C,
	input S,
	input V,

	input [BITS - 1:0] regA,
	input [BITS - 1:0] regB,

	/* immediate register */
	input [BITS - 1:0] imm_reg,

	/* memory op */
	output load_memory,
	output store_memory,
	output [ADDRESS_BITS - 1:0] load_store_address,
	output [BITS - 1:0] memory_out,
	output [1:0] memory_wr_mask,

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
	output [ADDRESS_BITS - 1:0] new_pc,

	output interrupt_flag_set,
	output interrupt_flag_clear,

	output halt

);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [4:0] 		alu_op_r, alu_op_r_next;
assign aluOp  = alu_op_r;

reg [BITS - 1:0] aluA_r, aluA_r_next;
reg [BITS - 1:0] aluB_r, aluB_r_next;

assign aluA = aluA_r;
assign aluB = aluB_r;

reg interrupt_flag_set_r, interrupt_flag_set_r_a, interrupt_flag_set_r_b;
assign interrupt_flag_set = interrupt_flag_set_r;

reg interrupt_flag_clear_r, interrupt_flag_clear_r_a, interrupt_flag_clear_r_b;
assign interrupt_flag_clear = interrupt_flag_clear_r;


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
				if (branch_taken_from_ins(instruction, Z, S, C, V) == 1'b1) begin
						new_pc_r = regA + imm_reg;
						load_pc_r = 1'b1;
				end
			end
			INSTRUCTION_CASEX_RET_IRET: begin
				new_pc_r = regA;
				load_pc_r = 1'b1;
			end
			INSTRUCTION_CASEX_INTERRUPT: begin
				new_pc_r = {10'b0, instruction[3:0], 2'b0};
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

reg [1:0] memory_wr_mask_r;
assign memory_wr_mask = memory_wr_mask_r;

assign load_memory = load_memory_r;
assign store_memory = store_memory_r;
assign load_store_address = load_store_address_r;
assign memory_out = memory_out_r;

wire [15:0] load_store_addr_w = regB + imm_reg;
wire low_bit_of_address = regB[0] ^ imm_reg[0];


always @(*)
begin
	load_store_address_r = load_store_addr_w;
	memory_out_r 		 = {BITS{1'b0}};
	load_memory_r 		 = 1'b0;
	store_memory_r 		 = 1'b0;
	memory_wr_mask_r	 = 2'b11;

	if (is_executing) begin
		casex(instruction)
			INSTRUCTION_CASEX_BYTE_LOAD_STORE, INSTRUCTION_CASEX_BYTE_LOAD_SX: begin
				if (low_bit_of_address == 1'b1)
					memory_wr_mask_r = 2'b10;
				else
					memory_wr_mask_r = 2'b01;

				if (is_load_store_from_ins(instruction) == 1'b1) begin
					store_memory_r = 1'b1;

					if (low_bit_of_address == 1'b1)
						memory_out_r = {regA[7:0], 8'h00};
					else 
						memory_out_r = regA;

				end else
					load_memory_r = 1'b1;
			end
			INSTRUCTION_CASEX_LOAD_STORE: begin
				if (is_load_store_from_ins(instruction) == 1'b1) begin
					store_memory_r = 1'b1;
					memory_out_r = regA;
				end else
					load_memory_r = 1'b1;
			end
		endcase
	end
end

/* determine interrupt flag set / clear */

always @(*)
begin
	interrupt_flag_set_r = 1'b0;
	interrupt_flag_clear_r = 1'b0;

	casex (instruction) 
		INSTRUCTION_CASEX_INTERRUPT_EN: begin
			if (is_interrupt_enable_disable(instruction) == 1'b0)
				interrupt_flag_clear_r = 1'b1;
			else 
				interrupt_flag_set_r = 1'b1;
		end
		INSTRUCTION_CASEX_RET_IRET:	begin	/* iret? */
			if (is_ret_or_iret(instruction) == 1'b1)
				interrupt_flag_set_r = 1'b1; // set on iret
		end
		INSTRUCTION_CASEX_SLEEP: begin
			interrupt_flag_set_r = 1'b1;
		end
		INSTRUCTION_CASEX_INTERRUPT: begin
			interrupt_flag_clear_r = 1'b1;
		end
		default: ;
	endcase
end

/* sleep ? */

reg halt_r;
assign halt = halt_r;

always @(*)
begin
	halt_r = 1'b0;

	casex(instruction)
		INSTRUCTION_CASEX_SLEEP: begin
			halt_r = 1'b1;	
		end
	endcase
end

endmodule
