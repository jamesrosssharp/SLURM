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

reg [15:0] memory [65535:0];

initial begin
        $display("Loading rom.");
        $readmemh("ram_image.mem", memory);
end

initial memory[16'h4000] = 16'h0100;
initial memory[16'h4001] = 16'h0302;
initial memory[16'h4002] = 16'h0504;

wire [15:0] memory_data = memory[memory_address];
wire rvalid;
wire rready = rvalid;

background_controller2 con0
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
    rready 
);

initial begin 
	#150 RSTb = 1'b1;

	// Enable background

	#100 ADDRESS = 16'h0;
		 DATA_IN = 16'h0001;
		 WR = 1;
	#100 WR = 0;

	// Set tilemap address

	#100 ADDRESS = 16'h3;
		 DATA_IN = 16'hc000;
		 WR = 1;
	#100 WR = 0;

	// Set tileset address

	#100 ADDRESS = 16'h4;
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
    $dumpfile("background_controller2.vcd");
    $dumpvars(0, sprite_tb);
	# 10000000 $finish;
end

genvar j;
for (j = 0; j < 2; j = j + 1) begin
    initial $dumpvars(0, con0.fetchbuffer[j]);
    initial $dumpvars(0, con0.fetchbuffer_next[j]);
end



endmodule
