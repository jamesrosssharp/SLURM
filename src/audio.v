/*
 *
 *	i2s audio core
 *
 *	Interface to CPU is via block RAM fifo; CPU writes to left and right buffers
 *
 */

module audio
#(parameter BITS = 16, ADDRESS_BITS = 12, CLK_FREQ = 25125000)
(
	input CLK,	
	input RSTb,

	// Port interface
	input 	[ADDRESS_BITS - 1 : 0]  ADDRESS,
	input 	[BITS - 1 : 0] DATA_IN,
	output 	[BITS - 1 : 0] DATA_OUT,
	input 	WR,  /* write memory */

	// I2S 
	output 	mclk,
	output 	lr_clk,
	output 	sclk,
	output 	sdat,

	// Interrupt 
	output  irq
	
);

localparam MCLK_FREQ  = CLK_FREQ / 2;
localparam LRCLK_FREQ = MCLK_FREQ / 512;
localparam SCLK_FREQ  = LRCLK_FREQ * 64;


assign mclk = CLK;

reg lr_clk_r = 1'b0;
reg lr_clk_r_next;

assign lr_clk = lr_clk_r;

reg sclk_r = 1'b0;
reg sclk_r_next;

assign sclk = sclk_r;

reg [8:0] lr_clk_count_r = 0; // CLK / 512
reg [2:0] sclk_count_r = 0;   // CLK / 16

reg [63:0] serial_data_r = {64{1'b0}};
reg [63:0] serial_data_r_next;

assign sdat = serial_data_r[63]; // serial data out

reg [8:0] left_rd_addr, left_rd_addr_next;
wire [15:0] left_rd_data;

reg left_wr;

bram #(.BITS(16), .ADDRESS_BITS(9)) left_bram
(
	CLK,
	left_rd_addr,
	left_rd_data,
	ADDRESS[8:0],
	DATA_IN,
	left_wr
);

reg [8:0] right_rd_addr, right_rd_addr_next;
wire [15:0] right_rd_data;

reg right_wr;

bram #(.BITS(16), .ADDRESS_BITS(9)) right_bram
(
	CLK,
	right_rd_addr,
	right_rd_data,
	ADDRESS[8:0],
	DATA_IN,
	right_wr
);

assign irq = right_rd_addr[8] ^ right_rd_addr_next[8];

reg control_run, control_run_next;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		left_rd_addr  <= 9'd0;
		right_rd_addr <= 9'd0;
		control_run <= 1'b0;
	end else begin
		lr_clk_count_r 	<= lr_clk_count_r + 1;	
		sclk_count_r 	<= sclk_count_r + 1;
		lr_clk_r 		<= lr_clk_r_next;
		sclk_r 			<= sclk_r_next;
		serial_data_r 	<= serial_data_r_next;

		left_rd_addr  <= left_rd_addr_next;
		right_rd_addr <= right_rd_addr_next;
		control_run   <= control_run_next;
	end
end

always @(*)
begin
	lr_clk_r_next = lr_clk_r;
	sclk_r_next = sclk_r;
	if (lr_clk_count_r == 9'd0)
		lr_clk_r_next = !lr_clk_r;
	if (sclk_count_r == 3'd0)
		sclk_r_next = !sclk_r;
end

always @(*)
begin
	serial_data_r_next = serial_data_r;

	left_rd_addr_next  = left_rd_addr;
	right_rd_addr_next = right_rd_addr;
	

	if (lr_clk_r_next != lr_clk_r) begin
		serial_data_r_next = {64{1'b0}};

		if (control_run == 1'b1) begin
			if (lr_clk_r == 1'b0) begin // Left channel going to right channel
				serial_data_r_next[62:47] = right_rd_data;
				right_rd_addr_next = right_rd_addr + 1;	
			end else begin
				serial_data_r_next[62:47] = left_rd_data;
				left_rd_addr_next = left_rd_addr + 1;	
			end
		end else
			serial_data_r_next[62:47] = 16'd0; 			
	
	end
	else if (sclk_r_next == 1'b0 && sclk_r == 1'b1) begin
		serial_data_r_next = {serial_data_r[62:0],1'b0};
	end

end

reg [15:0] dout;
assign DATA_OUT = dout;

always @(*)
begin
	left_wr  = 1'b0;
	right_wr = 1'b0;
	control_run_next = control_run;
	dout = 16'd0;
// verilator lint_off CASEX
	casex (ADDRESS)
		12'b000xxxxxxxxx:	/* left BRAM : 512 words */
			left_wr = WR;
		12'b001xxxxxxxxx:	/* right BRAM : 512 */
			right_wr = WR;
		12'h400:	/* Control reg */
			if (WR == 1'b1) begin
				control_run_next = DATA_IN[0];
			end
		12'h401: /* Left read pointer */
			dout = {7'd0, left_rd_addr};
		12'h402: /* Right read pointer */
			dout = {7'd0, right_rd_addr};
		default:;
	endcase
end



endmodule
