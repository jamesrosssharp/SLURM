/* alu.v : ALU */

module alu
#(parameter BITS = 16)
(
	input CLK,	/* ALU has memory for flags */
	input RSTb,

	input [BITS-1:0]  A,
	input [BITS-1:0]  B,
	input [4:0]       aluOp,
	output [BITS-1:0] aluOut,

	input execute,

	output C, /* carry flag */
	output Z, /* zero flag */
	output S /* sign flag */
);

reg C_flag_reg = 1'b0;
reg C_flag_reg_next;

assign C = C_flag_reg;

reg Z_flag_reg = 1'b0;
reg Z_flag_reg_next;

assign Z = Z_flag_reg;

reg S_flag_reg = 1'b0;
reg S_flag_reg_next;

assign S = S_flag_reg;

wire [BITS : 0] addOp = {1'b0,A} + {1'b0,B}; 
wire [BITS : 0] subOp = {1'b0,A} - {1'b0,B}; 

wire [BITS - 1 : 0] orOp = A | B;
wire [BITS - 1 : 0] andOp = A & B; 
wire [BITS - 1 : 0] xorOp = A ^ B;

wire [BITS - 1 : 0] rolcOp = {B[BITS - 2:0],C};
wire [BITS - 1 : 0] rorcOp = {C, B[BITS - 1:1]};

wire [BITS - 1 : 0] lslOp = {B[BITS - 2:0],1'b0};
wire [BITS - 1 : 0] asrOp = {B[BITS-1], B[BITS - 1:1]};
wire [BITS - 1 : 0] lsrOp = {1'b0, B[BITS - 1:1]};

wire [2*BITS - 1 : 0] mulOp;

mult m0 (A, B, mulOp);


reg [BITS - 1 : 0] out;
reg [BITS - 1 : 0] out_r;
assign aluOut = out_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		C_flag_reg <= 1'b0;
		Z_flag_reg <= 1'b0;
		S_flag_reg <= 1'b0;
		out_r <= {BITS{1'b0}};
	end
	else if(execute) begin
		C_flag_reg <= C_flag_reg_next;
		Z_flag_reg <= Z_flag_reg_next;
		S_flag_reg <= S_flag_reg_next;
		out_r <= out;
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
		5'd0:	begin /* move - pass B (source) through to register file */
			out = B;				
		end
		5'd1: begin /* add */
			out = addOp[BITS - 1:0];
			C_flag_reg_next = addOp[BITS];
			Z_flag_reg_next = (addOp[BITS - 1:0] == 16'h0000 /*{BITS{1'b0}} */) ? 1'b1 : 1'b0;
			S_flag_reg_next = addOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		5'd2: begin /* adc */
			out = addOp[BITS - 1:0];
			C_flag_reg_next = addOp[BITS];
			Z_flag_reg_next = (addOp[BITS - 1:0] == 16'h0000 /*{BITS{1'b0}}*/) ? 1'b1 : 1'b0;
			S_flag_reg_next = addOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		5'd3: begin /* sub */ 
			out = subOp[BITS - 1:0];
			C_flag_reg_next = subOp[BITS];
			Z_flag_reg_next = (subOp[BITS - 1:0] == 16'h0000/*{BITS{1'b0}}*/) ? 1'b1 : 1'b0;
			S_flag_reg_next = subOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		5'd4: begin /* sbb */ 
			out = subOp[BITS - 1:0];
			C_flag_reg_next = subOp[BITS];
			Z_flag_reg_next = (subOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;
			S_flag_reg_next = subOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		5'd5: begin /* and */
			out = andOp;
			Z_flag_reg_next = (andOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;
			C_flag_reg_next = 1'b0;
			S_flag_reg_next = andOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		5'd6: begin /* or */
			out = orOp;
			Z_flag_reg_next = (orOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
			C_flag_reg_next = 1'b0;
			S_flag_reg_next = orOp[BITS - 1] ? 1'b1 : 1'b0;	
		end
		5'd7: begin /* xor */
			out = xorOp;
			C_flag_reg_next = 1'b0;
			S_flag_reg_next = orOp[BITS - 1] ? 1'b1 : 1'b0;	
			Z_flag_reg_next = (xorOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		/* multiplier? */
		5'd8: begin /* mul */
			out = mulOp[BITS - 1:0];
			Z_flag_reg_next = (mulOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;
			C_flag_reg_next = 1'b0;
			S_flag_reg_next = mulOp[BITS - 1] ? 1'b1 : 1'b0;
		end
		5'd9: begin /* mulu */
			out = mulOp[2*BITS - 1:BITS];
			Z_flag_reg_next = (mulOp[2*BITS - 1:BITS] == {BITS{1'b0}}) ? 1'b1 : 1'b0;
			C_flag_reg_next = 1'b0;
			S_flag_reg_next = mulOp[2*BITS - 1] ? 1'b1 : 1'b0;
		end
		/* barrel shifter? */
		5'd10: ; /* bsr */
		5'd11: ; /* bsl */

		5'd12: begin /* cmp */
			out = A;
			C_flag_reg_next = subOp[BITS];
			Z_flag_reg_next = (subOp[BITS - 1:0] == 16'h0000/*{BITS{1'b0}}*/) ? 1'b1 : 1'b0;
			S_flag_reg_next = subOp[BITS - 1] ? 1'b1 : 1'b0;
		end	

		5'd13: begin /* test */
			out = A;
			Z_flag_reg_next = (andOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end

		/* 14 - 15 reserved */


		/* extended ADC operations  - single register only (no immediate) */
		5'd16: begin /* asr */
			out = asrOp;	
			Z_flag_reg_next = (asrOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		5'd17: begin /* lsr */
			out = lsrOp;
			Z_flag_reg_next = (lsrOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		5'd18: begin /* lsl */
			out = lslOp;
			Z_flag_reg_next = (lslOp[BITS - 1:0] == {BITS{1'b0}}) ? 1'b1 : 1'b0;	
		end
		5'd19: begin // rolc
			out = rolcOp;
			C_flag_reg_next = B[BITS - 1];	
		end
		5'd20: begin // rorc
			out = rorcOp;
			C_flag_reg_next = B[0];	
		end
		5'd21: ; // rol
		5'd22: ; // ror	
		5'd23:	begin // clear carry
			out = 0;		
			C_flag_reg_next = 1'b0;
		end
		5'd24:	begin // set carry
			out = 0;		
			C_flag_reg_next = 1'b1;
		end
		5'd25:	begin // clear zero 
			out = 0;		
			Z_flag_reg_next = 1'b0;
		end
		5'd26:	begin // set zero
			out = 0;		
			Z_flag_reg_next = 1'b1;
		end
		5'd27: begin // clear sign 
			out = 0;
			S_flag_reg_next = 1'b0;
		end	
		5'd28: begin // set sign
			out = 0;
			S_flag_reg_next = 1'b1;
		end
		5'd29: begin	// Store flags
			out = {13'h0000, S, C, Z};
		end
		5'd30: begin // Restore flags
			C_flag_reg_next = B[1];
			S_flag_reg_next = B[2];
			Z_flag_reg_next = B[0];
		end
		5'd31: ; 
		default: ; /* reserved */	
	endcase				
end

endmodule  
