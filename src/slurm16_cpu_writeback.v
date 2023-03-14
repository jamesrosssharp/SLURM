/*
 *
 *	CPU writeback : write results from ALU or memory back into registers
 *
 *
 *
 */

module slurm16_cpu_writeback #(parameter REGISTER_BITS = 7, BITS = 16, ADDRESS_BITS = 16)
(
	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 4 */
	input [BITS - 1:0] aluOut,
	input [BITS - 1:0] memory_in, 
	input [BITS - 1:0] port_in, 

	input is_nop,

	/* write back register select and data */
	output [REGISTER_BITS - 1:0] reg_wr_sel,
	output [BITS - 1:0] reg_out,

	input [ADDRESS_BITS - 1: 0] pc_stage4,
	input [1:0] memory_wr_mask_delayed,

	input load_interrupt_return_address,

	/* conditional instruction passed in stage2 */
	input cond_pass,

	// Flags for cond mov
	input Z,
	input C,
	input S,
	input V

);

`include "cpu_decode_functions.v"
`include "slurm16_cpu_defs.v"

reg [REGISTER_BITS - 1:0] reg_wr_addr_r;
assign reg_wr_sel = reg_wr_addr_r;

reg [BITS - 1:0] reg_out_r;
assign reg_out = reg_out_r;

always @(*)
begin

	reg_wr_addr_r = 7'd0;	// We can write anything we want to r0, as it always reads back as 0x0000.
	reg_out_r = {BITS{1'b0}};

	if (load_interrupt_return_address) begin
		reg_wr_addr_r   = INTERRUPT_LINK_REGISTER; /* link register */
		reg_out_r	= pc_stage4;
	end
	else if (!is_nop)
		casex (instruction)
			INSTRUCTION_CASEX_ALUOP_SINGLE_REG : begin /* alu op reg */
				reg_wr_addr_r 	= reg_src_from_ins(instruction);
				reg_out_r 	= aluOut; 	
			end
			INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
				reg_wr_addr_r 	= reg_dest_from_ins(instruction);
				reg_out_r 	= aluOut; 	
			end
			INSTRUCTION_CASEX_BRANCH: begin /* branch */
				if (is_branch_link_from_ins(instruction) == 1'b1) begin
					reg_wr_addr_r   = LINK_REGISTER; /* link register */
					reg_out_r	= pc_stage4 + 16'd2;
				end
			end
			INSTRUCTION_CASEX_BYTE_LOAD_STORE: begin /* byte wise load / store */
				if (is_load_store_from_ins(instruction) == 1'b0) begin /* load */
					// write back value 
					reg_wr_addr_r = reg_dest_from_ins(instruction);
					
					case (memory_wr_mask_delayed)
						2'b10:
							reg_out_r = {8'h00, memory_in[15:8]};
						2'b01:
							reg_out_r = {8'h00, memory_in[7:0]};
						default:;
					endcase
				end	
			end
			INSTRUCTION_CASEX_BYTE_LOAD_SX: begin /* byte wise load with sign extend */
					reg_wr_addr_r = reg_dest_from_ins(instruction);
					
					case (memory_wr_mask_delayed)
						2'b10:
							reg_out_r = memory_in[15] == 1 ? {8'hff, memory_in[15:8]} : {8'd0, memory_in[15:8]};
						2'b01:
							reg_out_r = memory_in[7] == 1 ? {8'hff, memory_in[7:0]} : {8'd0, memory_in[7:0]};
						default:;
					endcase
			end
			INSTRUCTION_CASEX_LOAD_STORE:	begin /* load store */
				if (is_load_store_from_ins(instruction) == 1'b0) begin /* load */
					// write back value 
					reg_wr_addr_r = reg_dest_from_ins(instruction);
					reg_out_r = memory_in;
				end	
			end
			INSTRUCTION_CASEX_PEEK_POKE: begin /* io peek? */
				if (is_io_poke_from_ins(instruction) == 1'b0) begin
					reg_wr_addr_r = reg_dest_from_ins(instruction);
					reg_out_r = port_in;
				end
			end
			INSTRUCTION_CASEX_COND_MOV: begin
				/* For best performance, cond mov, operates on flags in stage4, immediately after an alu op (e.g. cmp) */

				if (branch_taken_from_ins(instruction, Z, S, C, V) == 1'b1) begin
					reg_wr_addr_r = reg_dest_from_ins(instruction);
					reg_out_r = aluOut;
				end
			end
			INSTRUCTION_CASEX_THREE_REG_COND_ALU: begin
				if (cond_pass == 1'b1) begin
					reg_wr_addr_r = reg_3dest_from_ins(instruction);
					reg_out_r = aluOut;	
				end
			end
			default: ;
		endcase
end


endmodule
