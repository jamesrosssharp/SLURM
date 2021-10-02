module audio
#(parameter BITS = 16, ADDRESS_BITS = 8, CLK_FREQ = 25125000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output [3:0] PINS /* output pins */ 
);

localparam MCLK_FREQ  = CLK_FREQ / 2;
localparam LRCLK_FREQ = MCLK_FREQ / 256;
localparam SCLK_FREQ  = LRCLK_FREQ * 64;

assign DATA_OUT = {BITS{1'b0}};

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

reg [23:0] sq_wave_count_r = 24'h00000;
reg [23:0] sq_wave_count_r_next;

reg sq_wave_val_r = 1'b0;
reg sq_wave_val_r_next;

reg [63:0] serial_data_r = {64{1'b0}};
reg [63:0] serial_data_r_next;

assign PINS[3] = serial_data_r[63]; // serial data out

reg [BITS - 1:0] phase_r = {BITS{1'b0}};
reg [BITS - 1:0] phase_r_next;

reg [BITS - 1:0] ampl_r = {BITS{1'b0}};
reg [BITS - 1:0] ampl_r_next;

reg [BITS - 1:0] ampl_neg_r = {BITS{1'b0}};
reg [BITS - 1:0] ampl_neg_r_next;

always @(posedge CLK)
begin
	m_clk_r <= !m_clk_r;
	lr_clk_count_r <= lr_clk_count_r + 1;	
	sclk_count_r <= sclk_count_r + 1;
	lr_clk_r <= lr_clk_r_next;
	sclk_r <= sclk_r_next;
	sq_wave_count_r <= sq_wave_count_r_next;
	sq_wave_val_r <= sq_wave_val_r_next;
	serial_data_r <= serial_data_r_next;
	phase_r <= phase_r_next;
	ampl_r <= ampl_r_next;
	ampl_neg_r <= ampl_neg_r_next;
end

always @(*)
begin
	sq_wave_count_r_next = sq_wave_count_r + phase_r;
	lr_clk_r_next = lr_clk_r;
	sclk_r_next = sclk_r;
	sq_wave_val_r_next = sq_wave_val_r;
	if (lr_clk_count_r == 7'd0)
		lr_clk_r_next = !lr_clk_r;
	if (sclk_count_r == 2'd0)
		sclk_r_next = !sclk_r;
	if (sq_wave_count_r > 24'h7fffff) begin
		sq_wave_count_r_next = 24'h000000;
		sq_wave_val_r_next = !sq_wave_val_r;
	end
end

always @(*)
begin
	serial_data_r_next = serial_data_r;

	if (lr_clk_r_next != lr_clk_r) begin
		serial_data_r_next = {64{1'b0}};
		serial_data_r_next[62:47] = (sq_wave_val_r == 1'b1) ? ampl_neg_r : ampl_r;
	end
	else if (sclk_r_next == 1'b0 && sclk_r == 1'b1) begin
		serial_data_r_next = {serial_data_r[62:0],1'b0};
	end

end

always @(*)
begin
	phase_r_next = phase_r;
	ampl_r_next = ampl_r;
	ampl_neg_r_next = ampl_neg_r;


	case (ADDRESS)
		8'h00:	/* Freq reg */
			if (WR == 1'b1) begin
				phase_r_next = DATA_IN; 
			end
		8'h01: /* Amplitude register */
			if (WR == 1'b1) begin
				ampl_r_next = DATA_IN;
				ampl_neg_r_next = -DATA_IN;
			end
		default:;
	endcase
end



endmodule
