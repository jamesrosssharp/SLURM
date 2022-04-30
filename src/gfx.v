module gfx #(parameter BITS = 16, parameter BANK_ADDRESS_BITS = 14, parameter ADDRESS_BITS = 12)
(
	input  CLK,
	input  RSTb,

	// IO Interface
	input  [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input  [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input  WR, 

	output HS,
	output VS,
	output [3:0] BB,
	output [3:0] RR,
	output [3:0] GG,

	// Memory ports (read only):

	//  sprite controller

	output [15:0] spcon_memory_address,
	input  [15:0] spcon_memory_data,
	output spcon_rvalid,
	input  spcon_rready,

	// BG0

	output [15:0] bg0_memory_address,
	input  [15:0] bg0_memory_data,
	output bg0_rvalid,
	input bg0_rready,

	// BG1

	output [15:0] bg1_memory_address,
	input [15:0] bg1_memory_data,
	output bg1_rvalid,
	input bg1_rready,

	// Overlay

	output [15:0] ov_memory_address,
	input [15:0] ov_memory_data,
	output ov_rvalid,
	input  ov_rready,

	// IRQs

	output irq_hsync,
	output irq_vsync
);

assign bg1_rvalid = 1'b0;

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

assign irq_hsync = (hcount == (H_PIXELS + H_BACK_PORCH + H_FRONT_PORCH)) ? 1'b1 : 1'b0; 
assign irq_vsync = (vcount == (V_LINES - V_SYNC_PULSE) && hcount == 10'd0) ? 1'b1 : 1'b0; 

wire frameTick = (hcount == 10'd0 && vcount == 10'd0) ? 1'b1 : 1'b0;

wire V_tick_next = frameTick;
wire H_tick_next = (hcount == 10'd0) ? 1'b1 : 1'b0;

reg V_tick;
reg H_tick;

reg video_mode_r, video_mode_r_next; /* 0 = 640 x 480, 1 = 320 x 240 */

always @(posedge CLK)
begin
	V_tick <= V_tick_next;
	H_tick <= H_tick_next;
	if (RSTb == 1'b0) begin
		video_mode_r <= 1'b0;
	end else
		video_mode_r <= video_mode_r_next;
end

wire [9:0] x = (video_mode_r == 1'b0) ? hcount : {1'b0, hcount[9:1]};
wire [9:0] y = (video_mode_r == 1'b0) ? vcount : {1'b0, vcount[9:1]};

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

/*wire [15:0] spcon_memory_address;
wire [15:0] spcon_memory_data;
wire spcon_rvalid;
wire  spcon_rready;
*/
wire [15:0] spcon_collision_data;


/*wire [15:0] ov_memory_address;
wire [15:0] ov_memory_data;
wire ov_rvalid;
wire  ov_rready;
*/


wire [7:0] bg0_color_index;

/*
wire [15:0] bg0_memory_address;
wire [15:0] bg0_memory_data;
wire bg0_rvalid;
wire bg0_rready;
*/
reg WR_bg0;

wire [7:0] bg1_color_index = 8'd0;
/*
wire [15:0] bg1_memory_address = 16'd0;
wire [15:0] bg1_memory_data;
wire bg1_rvalid = 1'b0;
wire bg1_rready;
*/
assign bg1_rvalid = 1'b0;

reg WR_bg1 = 1'b0;

reg WR_cpr;
wire [11:0] COPPER_ADDRESS;
wire COPPER_WR;
wire [15:0] COPPER_DATA_OUT;
wire [11:0] background_color;
wire [9:0] display_x_out;
wire [9:0] display_y_out;

wire [11:0] addr = (COPPER_WR == 1'b1) ? COPPER_ADDRESS : ADDRESS;
wire WR_sig = (COPPER_WR == 1'b1) ? 1'b1 : WR;
wire [15:0] data_out_cpr = (COPPER_WR == 1'b1) ? COPPER_DATA_OUT : DATA_IN;

reg WR_fb_reg;
reg WR_fb_pal;

wire [15:0] fb_color = 16'h0000;

/*wire [15:0] fb_memory_address;
wire [15:0] fb_memory_data;
wire fb_rvalid;
wire fb_rready;
*/
wire alpha_override_out;
wire [3:0] alpha_out;

sprite_controller spcon0
(
	CLK,
	RSTb,

	addr[9:0],
	data_out_cpr,
	WR_sprite,

	V_tick,
	H_tick,

	display_x_out,
	display_y_out,
	1'b1, 
	spcon_color_index,

	spcon_memory_address,
	spcon_memory_data,
	spcon_rvalid, 
	spcon_rready,

	ADDRESS[7:0],
	spcon_collision_data
);

background_controller2 bgcon0
(
	CLK,
	RSTb,

	addr[3:0],
	data_out_cpr,
	WR_bg0,

	V_tick,
	H_tick,

	display_x_out,
	display_y_out,
	1'b1,
	bg0_color_index,
	bg0_memory_address,
	bg0_memory_data,
	bg0_rvalid,
	bg0_rready 
);

assign ov_rvalid = 1'b0;

copper cpr0 (
	CLK,
	RSTb,

	addr,
	data_out_cpr,
	WR_cpr,

	V_tick,
	H_tick,

	x,
	y,

	COPPER_ADDRESS,
	COPPER_WR,
	COPPER_DATA_OUT,

	background_color,	

	display_x_out,
	display_y_out,

	alpha_override_out,
	alpha_out
);

wire [11:0] color;
reg WR_pal;

reg [7:0] color_index;
reg [7:0] color_index_r;

always @(*)
begin
	if (spcon_color_index[3:0] == 4'd0) 
		// if (bg1_color_index[3:0] == 4'd0)
			if (bg0_color_index[3:0] == 4'd0)
					color_index = 0;
			else
				color_index = bg0_color_index;
		//else
		//	color_index = bg1_color_index;
	else
		color_index = spcon_color_index;
end


bram #(.BITS(12), .ADDRESS_BITS(8)) pal0  (
	CLK,
	color_index,
	color,
	
	addr[7:0],
	data_out_cpr[11:0],
	WR_pal  
);

always @(posedge CLK)
begin
	if (frameTick)
		frameCount <= frameCount + 1;
	color_index_r = color_index;
end

wire [11:0] theColor = color_index_r[3:0] == 4'h0 ? background_color : color;

wire [3:0] rout;
wire [3:0] bout;
wire [3:0] gout;

reg [3:0] rout_r;
reg [3:0] bout_r;
reg [3:0] gout_r;

alpha a0 (
	theColor[11:8],
	theColor[7:4],
	theColor[3:0],
	fb_color[11:8],
	fb_color[7:4],
	fb_color[3:0],
	alpha_override_out ? alpha_out : fb_color[15:12],
	rout,
	bout,
	gout
);

always @(posedge CLK)
begin
	rout_r <= rout;
	bout_r <= gout;
	gout_r <= bout;
end

wire DE = (hcount >= H_BACK_PORCH && hcount < (H_BACK_PORCH + H_PIXELS + 32) && vcount >= V_BACK_PORCH && vcount < (V_DISPLAY_LINES + V_BACK_PORCH + 16));

assign RR = DE ? rout_r  : 4'b0000;
assign GG = DE ? gout_r  : 4'b0000;
assign BB = DE ? bout_r  : 4'b0000;

// Memory interface

reg [BITS - 1:0] dout_r;

assign DATA_OUT = dout_r;

// Memory read

reg [ADDRESS_BITS - 1:0] addr_r;

always @(posedge CLK)
begin
	addr_r = ADDRESS;
end


always @(*)
begin
	dout_r = {BITS{1'b0}};
	casex (addr_r)
		12'hf00:	/* frame count register */
			dout_r = frameCount;
		12'hf01:	/* display y register */
			dout_r[9:0] = y;
		12'h7xx:	/* collision read out */
			dout_r = spcon_collision_data;
	endcase
end


always @(*)
begin
	WR_sprite = 1'b0;
	WR_pal = 1'b0;
	WR_bg0 = 1'b0;
	WR_bg1 = 1'b0;
	WR_cpr = 1'b0;
	WR_fb_reg = 1'b0;
	WR_fb_pal = 1'b0;
	video_mode_r_next = video_mode_r;
	casex (addr)
		12'hf00:; 	/* frame count register */ 
		12'hf01:;   /* display y register */
		12'hf02:
			if (WR == 1'b1)
				video_mode_r_next = DATA_IN[0];
		12'hexx:    /* palette regiser */
			WR_pal = WR_sig;
		12'hd0x:    /* bg0 */
			WR_bg0 = WR_sig;
		12'hd1x:    /* bg1 */
			WR_bg1 = WR_sig;
		12'hd2x:	/* copper registers */
			WR_cpr = WR_sig;
		12'hd3x:	/* framebuffer registers */
			WR_fb_reg = WR_sig;
		12'h6xx:	/* framebuffer palette */
			WR_fb_pal = WR_sig;
		12'h7xx:	; /* collision read out */ 
		12'h0xx, 12'h1xx, 12'h2xx, 12'h3xx: /* sprite */
			WR_sprite = WR_sig;
		12'h4xx, 12'h5xx:  /* copper list memory */
			WR_cpr = WR_sig;
	endcase
end


endmodule
