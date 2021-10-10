`timescale 1 ns / 1 ps
module sprite_tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

reg [3:0] ADDRESS;
reg [15:0] DATA_IN;
reg WR = 1'b0;

reg [9:0] display_x = 10'd0;
reg [9:0] display_y = 10'd0;

wire isActive;

wire [17:0] sprite_address;

wire [3:0] pal_hi;

memory_sprite sp0
(
    CLK,
    RSTb,

    ADDRESS,
    DATA_IN,
    WR,

    display_x,
    display_y,
         
    isActive,

    sprite_address,

	pal_hi
);


initial begin 
	#150 RSTb = 1'b1;
	#100 ADDRESS = 0;
		 DATA_IN = 10'd2;
		 WR = 1;
	#100 WR = 0;
	#100 ADDRESS = 1;
		 DATA_IN = 10'd2;
		 WR = 1;
	#100 WR = 0;
end

always @(posedge CLK)
begin
	display_x <= display_x + 1;
	if (display_x == 10'd799) begin
		display_x <= 0;
		display_y <= display_y + 1;
		if (display_y == 10'd600) begin
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
