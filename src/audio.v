module audio
#(parameter BITS = 16, ADDRESS_BITS = 8, CLK_FREQ = 25125000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output [3:0] PINS, /* output pins */ 
);

localparam MCLK_FREQ  = CLK_FREQ / 2;
localparam LRCLK_FREQ = MCLK_FREQ / 256;
localparam SCLK_FREQ  = LRCLK_FREQ * 64;

reg m_clk_r;

assign PINS[0] = CLK;

reg lr_clk_r = 1'b0;
reg lr_clk_r_next;

assign PINS[1] = lr_clk_r;

reg sclk_r = 1'b0;
reg sclk_r_next;

assign PINS[2] = sclk_r;

reg [7:0] lr_clk_count_r; // CLK / 256
reg [1:0] sclk_count_r;   // CLK / 8

reg [19:0] sq_wave_count_r = 20'h00000;

reg sq_wave_val_r = 1'b0;
reg sq_wave_val_r_next;

assign PINS[3] = sq_wave_val_r; // serial data out

always @(posedge CLK)
begin
	m_clk_r <= !m_clk_r;
	lr_clk_count_r <= lr_clk_count_r + 1;	
	sclk_count_r <= sclk_count_r + 1;
	lr_clk_r <= lr_clk_r_next;
	sclk_r <= sclk_r_next;
	sq_wave_count_r <= sq_wave_count_r + 1;
	sq_wave_val_r <= sq_wave_val_r_next;
end

always @(*)
begin
	lr_clk_r_next = lr_clk_r;
	sclk_r_next = sclk_r;
	sq_wave_val_r_next = sq_wave_val_r;
	if (lr_clk_count_r == 7'd0)
		lr_clk_r_next = !lr_clk_r;
	if (sclk_count_r == 2'd0)
		sclk_r_next = !sclk_r;
	if (sq_wave_count_r == 20'd0)
		sq_wave_val_r_next = !sq_wave_val_r;
end



endmodule
