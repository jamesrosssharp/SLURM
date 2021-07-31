/* alu.v : ALU */

module alu
#(parameter BITS = 16)
(
	input CLK,	/* ALU has memory for flags */
	input RSTb,

	input [BITS-1:0]  A,
	input [BITS-1:0]  B,
	input [3:0]       aluOp,
	output [BITS-1:0] aluOut,

	output C, /* carry flag */
	output Z, /* zero flag */
	output S /* sign flag */
);

reg C_flag_reg;
reg C_flag_reg_next;

assign C = C_flag_reg;

reg Z_flag_reg;
reg Z_flag_reg_next;

assign Z = Z_flag_reg;

reg S_flag_reg;
reg S_flag_reg_next;

assign S = S_flag_reg;

wire [BITS : 0] addOp = {1'b0,A} + {1'b0,B}; 
wire [BITS : 0] subOp = {1'b0,A} - {1'b0,B}; 

wire [BITS - 1 : 0] orOp = A | B;
wire [BITS - 1 : 0] andOp = A & B; 
wire [BITS - 1 : 0] xorOp = A ^ B;

wire [BITS - 1 : 0] rolOp = {A[BITS - 2:0],C};
wire [BITS - 1 : 0] rorOp = {C, A[BITS - 1:1]};

reg [BITS - 1 : 0] out;
assign aluOut = out;

/* TODO: Multiplication */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		C_flag_reg <= 0;
		Z_flag_reg <= 0;
		S_flag_reg <= 0;
	end
	else begin
		C_flag_reg <= C_flag_reg_next;
		Z_flag_reg <= Z_flag_reg_next;
		S_flag_reg <= S_flag_reg_next;
	end
end

always @(*)
begin

	/* flags retain their value if not changed */
	C_flag_reg_next = C_flag_reg;
	Z_flag_reg_next = Z_flag_reg;
	S_flag_reg_next = S_flag_reg;

	out = 0;

	case (aluOp)
		4'd0:	begin /* move - pass A through to register file */
			out = A;				
		end
		4'd1:	begin /* clear carry */
			out = 0;		
			C_flag_reg_next = 1'b0;
		end
		4'd2:	begin /* set carry */
			out = 0;		
			C_flag_reg_next = 1'b1;
		end
		4'd3:	begin /* clear zero */
			out = 0;		
			Z_flag_reg_next = 1'b0;
		end
		4'd4:	begin /* set zero */
			out = 0;		
			Z_flag_reg_next = 1'b1;
		end
		4'd5: begin /* clear sign */
			out = 0;
			S_flag_reg_next = 1'b0;
		end	
		4'd6: begin /* set sign */
			out = 0;
			S_flag_reg_next = 1'b1;
		end	
		4'd7: begin /* add */
			out = addOp;
			C_flag_reg_next = addOp[BITS];
			Z_flag_reg_next = (addOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;
			S_flag_reg_next = addOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		4'd8: begin /* sub / cmp */ 
			out = subOp;
			C_flag_reg_next = subOp[BITS];
			Z_flag_reg_next = (subOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;
			S_flag_reg_next = subOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		4'd9, /* mul */
		4'd10: begin /* muls */
			out = 0;
		end
		4'd11: begin /* and / test */
			out = andOp;
			Z_flag_reg_next = (andOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		4'd12: begin /* or */
			out = orOp;
			Z_flag_reg_next = (orOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		4'd13: begin /* xor */
			out = xorOp;
			Z_flag_reg_next = (xorOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		4'd14: begin /* rol */
			out = rolOp;
			C_flag_reg_next = A[BITS - 1];	
		end
		4'd13: begin /* eor */
			out = rorOp;
			C_flag_reg_next = A[0];	
		end
	endcase				
end

endmodule  
