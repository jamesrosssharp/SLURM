`timescale 1 ns / 1 ps
module sprite_tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

reg [9:0] ADDRESS;
reg [15:0] DATA_IN;
reg WR = 1'b0;

reg [9:0] display_x = 10'd0;
reg [9:0] display_y = 10'd0;

wire isActive;

wire [17:0] sprite_address;

wire [3:0] pal_hi;

wire H_tick = (display_x == 10'd0) ? 1'b1 : 1'b0;
wire V_tick = (display_y == 10'd0) ? 1'b1 : 1'b0;

wire [7:0] color_index;
wire [15:0] memory_address;

reg [15:0] memory_data = 16'haa55;
wire rvalid;
wire rready = rvalid;

wire [15:0] collision_list_data;

sprite_controller con0
(
    CLK,
    RSTb,

    ADDRESS,
    DATA_IN,
    WR,

    V_tick,
    H_tick,

    display_x,
	display_y,
	1'b1,
    color_index,

    memory_address,
    memory_data,
    rvalid, 
    rready,
	collision_list_data
);

initial begin 
	#150 RSTb = 1'b1;
	// Sprite channel 0
	#100 ADDRESS = 16'h0;
		 DATA_IN = 16'h0002 | 16'h0400;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 16'h100;
		 DATA_IN = 16'h0002 | 16'hfc00;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 10'h200;
		 DATA_IN = 16'h0012;
		 WR = 1;
	#100 WR = 0;
	// Sprite channel 1
	#100 ADDRESS = 16'hf;
		 DATA_IN = 16'h003 | 16'h0400 | 16'h3800;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 16'h10f;
		 DATA_IN = 16'h0002 | 16'hfc00;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 10'h20f;
		 DATA_IN = 16'h0012;
		 WR = 1;
	#100 WR = 0;
	// Sprite channel 2
	#100 ADDRESS = 16'h2;
		 DATA_IN = 16'h0011 | 16'h0400 | 16'h7800;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 16'h102;
		 DATA_IN = 16'h0003 | 16'hfc00;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 10'h202;
		 DATA_IN = 16'h0012;
		 WR = 1;
	#100 WR = 0;
	//
	#100 ADDRESS = 10'h000f;	
end

always @(posedge CLK)
begin
	display_x <= display_x + 1;
	if (display_x == 10'd799) begin
		display_x <= 0;
		display_y <= display_y + 1;
		if (display_y == 10'd525) begin
			display_y <= 0;
		end
	end

end

wire [31:0] PINS;
reg  [7:0] INPUT_PINS = 8'h00;

initial begin
    $dumpfile("sprite_test.vcd");
    $dumpvars(0, sprite_tb);
	# 10000000 $finish;
end

genvar j;
for (j = 0; j < 256; j = j + 1) begin
    initial $dumpvars(0, con0.bm0.RAM[j]);
end

endmodule
