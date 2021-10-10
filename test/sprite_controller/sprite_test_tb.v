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

sprite_controller con0
(
    CLK,
    RSTb,

    ADDRESS,
    DATA_IN,
    WR,

    V_tick,
    H_tick,

    display_x - 10'd48,
    color_index,

    memory_address,
    memory_data,
    rvalid, 
    rready 
);

initial begin 
	#150 RSTb = 1'b1;
	// Sprite channel 0
	#100 ADDRESS = 0;
		 DATA_IN = 10'd2;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 1;
		 DATA_IN = 10'd2;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 10'd3;
		 DATA_IN = 10'd1;
		 WR = 1;
	#100 WR = 0;
	// Sprite channel 1
	#100 ADDRESS = 16;
		 DATA_IN = 10'd4;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 17;
		 DATA_IN = 10'd3;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 10'd19;
		 DATA_IN = 10'd1;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 10'd18;
		 DATA_IN = 16'hc000;
		 WR = 1;
	#100 WR = 0;
	// Sprite channel 7
	#100 ADDRESS = 7*16;
		 DATA_IN = 10'd5;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 7*16 + 1;
		 DATA_IN = 10'd3;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 7*16 + 3;
		 DATA_IN = 10'd1;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 7 * 16 + 2;
		 DATA_IN = 16'h8000;
		 WR = 1;
	#100 WR = 0;
	

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
	# 5000000 $finish;
end

endmodule
