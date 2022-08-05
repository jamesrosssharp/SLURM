/*
 *	alpha.v
 *
 *	Alpha channel mixing
 *
 */

module alpha (
	input [3:0] r0,
	input [3:0] g0,
	input [3:0] b0,

	input [3:0] r1,
	input [3:0] g1,
	input [3:0] b1,

	input [3:0] alpha,

	output [3:0] rout,
	output [3:0] gout,
	output [3:0] bout
);

reg [4:0] alpha_expand;
reg [4:0] one_minus_alpha_expand;

always @(*)
begin
	case (alpha)
		4'd0: begin
			alpha_expand = 5'd0;
			one_minus_alpha_expand = 5'd16;
		end
		4'd1: begin
			alpha_expand = 5'd1;
			one_minus_alpha_expand = 5'd15;
		end
		4'd2: begin
			alpha_expand = 5'd2;
			one_minus_alpha_expand = 5'd14;
		end
		4'd3: begin
			alpha_expand = 5'd3;
			one_minus_alpha_expand = 5'd13;
		end
		4'd4: begin
			alpha_expand = 5'd4;
			one_minus_alpha_expand = 5'd12;
		end
		4'd5: begin
			alpha_expand = 5'd6;
			one_minus_alpha_expand = 5'd10;
		end
		4'd6: begin
			alpha_expand = 5'd7;
			one_minus_alpha_expand = 5'd9;
		end
		4'd7: begin
			alpha_expand = 5'd8;
			one_minus_alpha_expand = 5'd8;
		end
		4'd8: begin
			alpha_expand = 5'd9;
			one_minus_alpha_expand = 5'd7;
		end
		4'd9: begin
			alpha_expand = 5'd10;
			one_minus_alpha_expand = 5'd6;
		end
		4'd10: begin
			alpha_expand = 5'd11;
			one_minus_alpha_expand = 5'd5;
		end
		4'd11: begin
			alpha_expand = 5'd12;
			one_minus_alpha_expand = 5'd4;
		end
		4'd12: begin
			alpha_expand = 5'd13;
			one_minus_alpha_expand = 5'd3;
		end
		4'd13: begin
			alpha_expand = 5'd14;
			one_minus_alpha_expand = 5'd2;
		end
		4'd14: begin
			alpha_expand = 5'd15;
			one_minus_alpha_expand = 5'd1;
		end
		4'd15: begin
			alpha_expand = 5'd16;
			one_minus_alpha_expand = 5'd0;
		end
		default: begin
			alpha_expand = 5'd0;
			one_minus_alpha_expand = 5'd16;
		end
	endcase

end




wire [15:0] m1a = {12'd0, r0};
wire [15:0] m1b = {11'd0, one_minus_alpha_expand};

wire [15:0] m2a = {12'd0, r1};
wire [15:0] m2b = {11'd0, alpha_expand};

wire [15:0] m3a = {12'd0, g0};
wire [15:0] m3b = {11'd0, one_minus_alpha_expand};

wire [15:0] m4a = {12'd0, g1};
wire [15:0] m4b = {11'd0, alpha_expand};

wire [15:0] m5a = {12'd0, b0};
wire [15:0] m5b = {11'd0, one_minus_alpha_expand};

wire [15:0] m6a = {12'd0, b1};
wire [15:0] m6b = {11'd0, alpha_expand};

wire [31:0] out1;
wire [31:0] out2;
wire [31:0] out3;
wire [31:0] out4;
wire [31:0] out5;
wire [31:0] out6;

unsigned_mult m0 (m1a, m1b, out1);
unsigned_mult m1 (m2a, m2b, out2);
unsigned_mult m2 (m3a, m3b, out3);
unsigned_mult m3 (m4a, m4b, out4);
unsigned_mult m4 (m5a, m5b, out5);
unsigned_mult m5 (m6a, m6b, out6);

assign rout = out1[7:4] + out2[7:4];
assign gout = out3[7:4] + out4[7:4];
assign bout = out5[7:4] + out6[7:4];


endmodule
