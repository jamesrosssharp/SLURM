/*
 *	Functions for decoding instructions
 *
 */

/* verilator lint_off UNUSED */
function is_branch_link_from_ins;
input [15:0] ins;
	is_branch_link_from_ins = (ins[11:8] == 4'hf) ? 1'b1 : 1'b0;
endfunction

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

function [4:0] alu_op_from_imm;
input [15:0] imm;
begin
	alu_op_from_imm = {1'b0, imm[7:4]}; 
end
endfunction

function [4:0] single_reg_alu_op_from_ins;
input [15:0] ins;
begin
	single_reg_alu_op_from_ins = {1'b1, ins[7:4]}; 
end
endfunction

function [7:0] reg_dest_from_ins;
input [15:0] ins;
begin
	reg_dest_from_ins = {3'd0, ins[7:4]};
end
endfunction

function [7:0] reg_3dest_from_ins;
input [15:0] ins;
begin
	reg_3dest_from_ins = {3'd0, ins[11:8]};
end
endfunction

function [7:0] reg_src_from_ins;
input [15:0] ins;
begin
	reg_src_from_ins = {3'd0, ins[3:0]};
end
endfunction

function [7:0] reg_idx_from_ins;
input [15:0] ins;
begin
	reg_idx_from_ins = {3'd0, ins[11:8]};
end
endfunction

function [3:0]  imm_lo_from_ins;
input 	 [15:0] ins;
begin
	imm_lo_from_ins = ins[3:0];	
end
endfunction

function is_load_store_from_ins;
input [15:0] p0;
    is_load_store_from_ins = p0[12]; // 0 = load, 1 = store
endfunction

function is_io_poke_from_ins;
input [15:0] p0;
    is_io_poke_from_ins = p0[12]; // 1 = poke, 0 = peek
endfunction



function uses_flags_for_branch;
input [15:0] ins;
begin
	case(ins[11:8])
		4'he, 4'hf:
			uses_flags_for_branch = 1'b0;
		default:
			uses_flags_for_branch = 1'b1;
	endcase
end
endfunction

function branch_taken_from_ins;
input [15:0] ins;
input Z_in;
input S_in;
input C_in;
input V_in;
begin
	case(ins[11:8])
		4'b0000:		/* 0x0 - BZ, BEQ branch if ZERO */
			if (Z_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		4'b0001:		/* 0x1 - BNZ, BNE branch if not ZERO */
			if (Z_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		4'b0010:		/* 0x2 - BS, branch if SIGN */
			if (S_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		4'b0011:		/* 0x3 - BNS, branch if not SIGN */
			if (S_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		4'b0100:		/* 0x4 - BC, BLTU branch if CARRY */
			if (C_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
	
		4'b0101:		/* 0x5 - BNC, BGEU, branch if not CARRY */
			if (C_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
		4'b0110:		/* 0x6 - BV, branch if OVERFLOW */
			if (V_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
		4'b0111:		/* 0x6 - BNV, branch if not OVERFLOW */
			if (V_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
		4'b1000:		/* 0x8 - BLT */
			if ((S_in ^ V_in) == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
		4'b1001:		/* 0x9 - BLE */
			if ((Z_in == 1'b1) || (S_in ^ V_in)) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;
 		4'b1010:		/* 0xa - BGT */
			if ((S_in == V_in) && Z_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;	
		4'b1011:		/* 0xb - BGE */
			if (S_in == V_in) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;	
  		4'b1100:		/* 0xc - BLEU */
			if (C_in == 1'b1 || Z_in == 1'b1) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;	
		4'b1101:		/* 0xd - BGTU */
			if (C_in == 1'b0 && Z_in == 1'b0) branch_taken_from_ins = 1'b1;
			else branch_taken_from_ins = 1'b0;	
		4'b1110:		/* 0xe - BA, branch always */
			branch_taken_from_ins = 1'b1;
		4'b1111:		/* 0xf - BL, branch link */
			branch_taken_from_ins = 1'b1; 	
		default:	
  			branch_taken_from_ins = 1'b0;
	endcase
end
endfunction

function [7:0] reg_branch_ind_from_ins;
input [15:0] ins;
		reg_branch_ind_from_ins = {3'd0, ins[7:4]};
endfunction

function is_interrupt_enable_disable;
input [15:0] ins;
		is_interrupt_enable_disable = ins[0];	// 1 = enabled, 0 = disabled
endfunction

function is_ret_or_iret;
input [15:0] ins;
		is_ret_or_iret = ins[0];	// 1 = iret, 0 = ret
endfunction
/* lint_on */

