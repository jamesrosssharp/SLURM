`timescale 1 ns / 1 ps
module fb_tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

reg [9:0] ADDRESS;
reg [15:0] DATA_IN;
reg WR_reg = 1'b0;
reg WR_pal = 1'b0;


reg [9:0] display_x = 10'd0;
reg [9:0] display_y = 10'd0;

wire isActive;

wire [17:0] sprite_address;

wire [3:0] pal_hi;

wire H_tick = (display_x == 10'd0) ? 1'b1 : 1'b0;
wire V_tick = (display_y == 10'd0) ? 1'b1 : 1'b0;

wire [15:0] color;
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

fb_scale fb0
(
	CLK,
	RSTb,

	ADDRESS,
	DATA_IN,
	WR_reg,
	WR_pal,

	V_tick,
	H_tick,

	display_x,
	display_y,
	1'b1,
	color,

	memory_address,
	memory_data,
	rvalid,
	rready
);

initial begin 
	#150 RSTb = 1'b1;

	#100 ADDRESS = 16'h1;
		 DATA_IN = 16'd160;
		 WR_reg = 1;
	#100 WR_reg = 0;

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

initial begin
    $dumpfile("fb_scale.vcd");
    $dumpvars(0, fb_tb);
	# 10000000 $finish;
end

/*genvar j;
for (j = 0; j < 2; j = j + 1) begin
    initial $dumpvars(0, con0.fetchbuffer[j]);
    initial $dumpvars(0, con0.fetchbuffer_next[j]);
end*/

endmodule
