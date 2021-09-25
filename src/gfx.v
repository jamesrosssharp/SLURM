module gfx #(parameter BITS = 16, parameter BANK_ADDRESS_BITS = 14, parameter ADDRESS_BITS = 12)
(
	input  CLK,
	input  RSTb,
	input  [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input  [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input  WR, 

	output HS,
	output VS,
	output [3:0] BB,
	output [3:0] RR,
	output [3:0] GG,

	// Memory Bank DMA ports

	output [BANK_ADDRESS_BITS - 1 : 0] B1_ADDR,
	input  [BITS - 1 : 0] B1_DOUT,
	output B1_RD,

	output [BANK_ADDRESS_BITS - 1 : 0] B2_ADDR,
	input  [BITS - 1 : 0] B2_DOUT,
	output B2_RD,

	output [BANK_ADDRESS_BITS - 1 : 0] B3_ADDR,
	input  [BITS - 1 : 0] B3_DOUT,
	output B3_RD,

	output [BANK_ADDRESS_BITS - 1 : 0] B4_ADDR,
	input  [BITS - 1 : 0] B4_DOUT,
	output B4_RD

);

reg [9:0] hcount = 10'd0;
reg [9:0] vcount = 10'd0;

localparam H_FRONT_PORCH = 16;
localparam H_SYNC_PULSE  = 96;
localparam H_BACK_PORCH  = 48;
localparam H_TOTAL_PORCH = H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
localparam H_PIXELS = 640;

localparam V_FRONT_PORCH = 10;
localparam V_SYNC_PULSE  = 2;
localparam V_BACK_PORCH  = 33;
localparam V_TOTAL_PORCH = V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;
localparam V_DISPLAY_LINES = 480;
localparam V_LINES = V_DISPLAY_LINES + V_TOTAL_PORCH;

assign HS = (hcount >= (H_PIXELS + H_BACK_PORCH + H_FRONT_PORCH)) ? 1'b0 : 1'b1;
assign VS = (vcount >= (V_LINES - V_SYNC_PULSE)) ? 1'b0 : 1'b1;

wire frameTick = (hcount == 10'd0 && vcount == 10'd0) ? 1'b1 : 1'b0;

wire [9:0] x = hcount;
wire [9:0] y = vcount;

wire spriteActive;
wire [11:0] spriteColor;

always @(posedge CLK)
begin
	hcount <= hcount + 1;

	if (hcount == 10'd799) begin
		if (vcount == 10'd524)
			vcount <= 10'd0;
		else
			vcount <= vcount + 1;
		hcount <= 10'd0;
	end
end

pacman_sprite pac0
(
	CLK,
	RSTb,
	frameTick,
	x,
	y,
	spriteColor,
	spriteActive
);

wire [11:0] color_next = spriteActive ? spriteColor : 12'h00f; 
reg [11:0] color;

always @(posedge CLK)
begin
	color <= color_next;
end

wire DE = (hcount >= H_BACK_PORCH && hcount < (H_BACK_PORCH + H_PIXELS + 32) && vcount >= V_BACK_PORCH && vcount < (V_DISPLAY_LINES + V_BACK_PORCH + 16));

assign RR = DE ? color[11:8]  : 4'b0000;
assign GG = DE ? color[7:4]  : 4'b0000;
assign BB = DE ? color[3:0] : 4'b0000;

endmodule
