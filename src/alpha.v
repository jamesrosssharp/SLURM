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

/*wire [3:0] one_minus_alpha = 4'b1111 - alpha;

wire [15:0] m1a = {r0, 8'd0, g0};
wire [15:0] m1b = {one_minus_alpha, 8'd0, one_minus_alpha};

wire [15:0] m2a = {b0, 8'd0, r1};
wire [15:0] m2b = {one_minus_alpha, 8'd0, alpha};

wire [15:0] m3a = {g1, 8'd0, b1};
wire [15:0] m3b = {alpha, 8'd0, alpha};

wire [31:0] out1;
wire [31:0] out2;
wire [31:0] out3;

mult m0 (m1a, m1b, out1);
mult m1 (m2a, m2b, out2);
mult m2 (m3a, m3b, out3);

assign rout = out1[31:28] + out2[7:4] + 1;
assign gout = out1[7:4]   + out3[31:28] + 1;
assign bout = out2[31:28] + out3[7:4] + 1;
*/

assign rout = r0;
assign gout = g0;
assign bout = b0;


endmodule
