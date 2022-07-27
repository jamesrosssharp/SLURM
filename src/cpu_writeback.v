/*
 *
 *	CPU writeback : write results from ALU or memory back into registers
 *
 *
 *
 */

module cpu_writeback #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
(
	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 4 */
	input [BITS - 1:0] aluOut,
	input [BITS - 1:0] memory_in, 
	input [BITS - 1:0] port_in, 

	/* write back register select and data */
	output [REGISTER_BITS - 1:0] reg_wr_sel,
	output [BITS - 1:0] reg_out,

	input [ADDRESS_BITS - 1: 0] pc_stage4,
	input [1:0] memory_wr_mask_delayed,

	input C,
	input Z,
	input S,
	input V

);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [REGISTER_BITS - 1:0] reg_wr_addr_r;
assign reg_wr_sel = reg_wr_addr_r;

reg [BITS - 1:0] reg_out_r;
assign reg_out = reg_out_r;

always @(*)
begin

	reg_wr_addr_r = 4'd0;	// We can write anything we want to r0, as it always reads back as 0x0000.
	reg_out_r = {BITS{1'b0}};

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
				reg_out_r	= pc_stage4;
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
		INSTRUCTION_CASEX_INTERRUPT: begin /* interrupt? */
			reg_wr_addr_r   = INTERRUPT_LINK_REGISTER; 
			reg_out_r		= pc_stage4;
		end
		INSTRUCTION_CASEX_COND_MOV: begin
			if (branch_taken_from_ins(instruction, Z, S, C, V) == 1'b1) begin
				reg_wr_addr_r = reg_dest_from_ins(instruction);
				reg_out_r = aluOut;
			end
		end
		default: ;
	endcase
end


endmodule
