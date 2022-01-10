/*
 *
 *	CPU writeback : write results from ALU or memory back into registers
 *
 *
 *
 */

module slurm16_cpu_writeback #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 4 */
	input [BITS - 1:0] aluOut,
	input [BITS - 1:0] memory_in, 
	input [BITS - 1:0] port_in, 

	/* write back register select and data */
	output [REGISTER_BITS - 1:0] reg_wr_sel,
	output [BITS - 1:0] reg_out 

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
			reg_out_r 		= aluOut; 	
		end
		INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
			reg_wr_addr_r 	= reg_dest_from_ins(instruction);
			reg_out_r 		= aluOut; 	
		end
		//16'h4xxx: begin /* branch */
		//	if (is_branch_link_from_ins(instruction) == 1'b1) begin
		//		reg_wr_addr_r   = LINK_REGISTER; /* link register */
		//		reg_out_r		= result_stage4_r;
		//	end
		//end
		//16'b110xxxxxxxxxxxxx:	begin /* load store */
		//	if (is_load_store_from_ins(instruction) == 1'b0) begin /* load */
		//		// write back value 
		//		reg_wr_addr_r = reg_dest_from_ins(instruction);
		//		reg_out_r = memoryIn;
		//	end	
		//end
		//16'b111xxxxxxxxxxxxx: begin /* io peek? */
		//	if (is_io_poke_from_ins(instruction) == 1'b0) begin
		//		reg_wr_addr_r = reg_dest_from_ins(instruction);
		//		reg_out_r = portIn;
		//	end
		//end
		default: ;
	endcase
end


endmodule
