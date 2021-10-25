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
	input  [BITS - 1 : 0] B1_DIN,
	output B1_VALID,
	input  B1_READY,

	output [BANK_ADDRESS_BITS - 1 : 0] B2_ADDR,
	input  [BITS - 1 : 0] B2_DIN,
	output B2_VALID,
	input  B2_READY,

	output [BANK_ADDRESS_BITS - 1 : 0] B3_ADDR,
	input  [BITS - 1 : 0] B3_DIN,
	output B3_VALID,
	input  B3_READY,

	output [BANK_ADDRESS_BITS - 1 : 0] B4_ADDR,
	input  [BITS - 1 : 0] B4_DIN,
	output B4_VALID,
	input  B4_READY

);

localparam BG_COLOR = 12'h000;

reg [9:0] hcount = 10'd0;
reg [9:0] vcount = 10'd0;

reg [5:0] frameCount = 6'd0;

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

wire V_tick = frameTick;
wire H_tick = (hcount == 10'd0) ? 1'b1 : 1'b0;

wire [9:0] x = hcount;
wire [9:0] y = vcount;

wire spriteActive;
wire [11:0] spriteColor;

reg WR_sprite;

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

wire [7:0] spcon_color_index;

wire [15:0] spcon_memory_address;
wire [15:0] spcon_memory_data;
wire spcon_rvalid;
wire  spcon_rready;

wire [15:0] ov_memory_address;
wire [15:0] ov_memory_data;
wire ov_rvalid;
wire  ov_rready;

wire [7:0] bg0_color_index;
wire [15:0] bg0_memory_address;
wire [15:0] bg0_memory_data;
wire bg0_rvalid;
wire bg0_rready;
reg WR_bg0;

wire [7:0] bg1_color_index;
wire [15:0] bg1_memory_address;
wire [15:0] bg1_memory_data;
wire bg1_rvalid = 1'b0;
wire bg1_rready;
reg WR_bg1;

wire [7:0] bg2_color_index;
wire [15:0] bg2_memory_address;
wire [15:0] bg2_memory_data;
wire bg2_rvalid = 1'b0;
wire bg2_rready;
reg WR_bg2;



gfx_memory_arbiter arb0
(
	CLK,
	RSTb,

	/* sprite controller */
	spcon_memory_address,
	spcon_memory_data,
	spcon_rvalid, 
	spcon_rready, 

	/* background controllers */
	bg0_memory_address,
	bg0_memory_data,
	bg0_rvalid,
	bg0_rready, 

	bg1_memory_address,
	bg1_memory_data,
	bg1_rvalid,
	bg1_rready, 

	bg2_memory_address,
	bg2_memory_data,
	bg2_rvalid,
	bg2_rready, 

	/* overlay controller */
	ov_memory_address,
	ov_memory_data,
	ov_rvalid, 
	ov_rready,  

	B1_ADDR,
	B1_DIN,
	B1_VALID,
	B1_READY,

	B2_ADDR,
	B2_DIN,
	B2_VALID,
	B2_READY,

	B3_ADDR,
	B3_DIN,
	B3_VALID,
	B3_READY,

	B4_ADDR,
	B4_DIN,
	B4_VALID,
	B4_READY
);

sprite_controller spcon0
(
	CLK,
	RSTb,

	ADDRESS[9:0],
	DATA_IN,
	WR_sprite,

	V_tick,
	H_tick,

	x,
	y,
	1'b1, 
	spcon_color_index,

	spcon_memory_address,
	spcon_memory_data,
	spcon_rvalid, 
	spcon_rready
);

background_controller2 #(48, 369, 33, 513) bgcon0
(
	CLK,
	RSTb,

	ADDRESS,
	DATA_IN,
	WR_bg0,

	V_tick,
	H_tick,

	x,
	y,
	1'b1,
	bg0_color_index,
	bg0_memory_address,
	bg0_memory_data,
	bg0_rvalid,
	bg0_rready 
);
/*
background_controller #(48, 369, 33, 513) bgcon1
(
	CLK,
	RSTb,

	ADDRESS,
	DATA_IN,
	WR_bg1,

	V_tick,
	H_tick,

	x,
	y,
	1'b1,
	bg1_color_index,
	bg1_memory_address,
	bg1_memory_data,
	bg1_rvalid,
	bg1_rready 
);

background_controller #(48, 369, 33, 513) bgcon2
(
	CLK,
	RSTb,

	ADDRESS,
	DATA_IN,
	WR_bg2,

	V_tick,
	H_tick,

	x,
	y,
	1'b1,
	bg2_color_index,
	bg2_memory_address,
	bg2_memory_data,
	bg2_rvalid,
	bg2_rready 
);
*/

wire [11:0] color;
reg WR_pal;

reg [7:0] color_index;

always @(*)
begin
	if (spcon_color_index[3:0] == 4'd0) 
	/*	 if (bg0_color_index[3:0] == 4'd0)
			if (bg1_color_index[3:0] == 4'd0)
					color_index = bg2_color_index;
			else
				color_index = bg1_color_index;
		else*/
			color_index = bg0_color_index;
	else
		color_index = spcon_color_index;
end


bram #(.BITS(12), .ADDRESS_BITS(8)) pal0  (
	CLK,
	color_index,
	color,
	
	ADDRESS[7:0],
	DATA_IN[11:0],
	WR_pal  
);

always @(posedge CLK)
begin
	if (frameTick)
		frameCount <= frameCount + 1;
end

wire [11:0] theColor = color_index[3:0] == 4'h0 ? BG_COLOR : color;

wire DE = (hcount >= H_BACK_PORCH && hcount < (H_BACK_PORCH + H_PIXELS + 32) && vcount >= V_BACK_PORCH && vcount < (V_DISPLAY_LINES + V_BACK_PORCH + 16));

assign RR = DE ? theColor[11:8]  : 4'b0000;
assign GG = DE ? theColor[7:4]  : 4'b0000;
assign BB = DE ? theColor[3:0] : 4'b0000;

// Memory interface

reg [BITS - 1:0] dout_r;

assign DATA_OUT = dout_r;

always @(*)
begin
	WR_sprite = 1'b0;
	WR_pal = 1'b0;
	WR_bg0 = 1'b0;
	WR_bg1 = 1'b0;
	WR_bg2 = 1'b0;
	dout_r = {BITS{1'b0}};
	casex (ADDRESS)
		12'hf00:	/* frame count register */
			dout_r = frameCount;
		12'hexx:    /* palette regiser */
			WR_pal = WR;
		12'hd0x:    /* bg0 */
			WR_bg0 = WR;
		12'hd1x:    /* bg1 */
			WR_bg1 = WR;
		12'hd2x:	/* bg2 */
			WR_bg2 = WR;
		default: /* sprite 1 */
			WR_sprite = WR;
	endcase
end


endmodule
