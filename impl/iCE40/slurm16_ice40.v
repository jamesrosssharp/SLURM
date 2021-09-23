module top
(
	output UART_TX,

	output GPIO1,
	output GPIO2,

	output RED_LED,
	output GREEN_LED,
	output BLUE_LED,

	output [3:0] BB,
	output [3:0] RR,
	output [3:0] GG,
	
	output HS,
	output VS,

	input CLK12

);

//wire clk12;
wire clk;

localparam CLOCKFREQ = 25125000;
//localparam CLOCKFREQ = 12000000;

/*SB_HFOSC inthosc (
  .CLKHFPU(1'b1),
  .CLKHFEN(1'b1),
  .CLKHF(clk12)
);
defparam inthosc.CLKHF_DIV = "0b10";
*/
wire locked;

 SB_PLL40_PAD #(
      .FEEDBACK_PATH("SIMPLE"),
      .PLLOUT_SELECT("GENCLK"),
       .DIVR(4'b0000),
       .DIVF(7'b1000010),
       .DIVQ(3'b101),
       .FILTER_RANGE(3'b001),
     ) SB_PLL40_CORE_inst (
       .RESETB(1'b1),
       .BYPASS(1'b0),
       .PACKAGEPIN(CLK12),
       .PLLOUTCORE(clk),
    );
/*
SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0000),		// DIVR =  0
		.DIVF(7'b1000010),	// DIVF = 66
		.DIVQ(3'b101),		// DIVQ =  5
		.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(CLK12),
		.PLLOUTCORE(clk)
		);
*/
//assign clk = clk12;

reg [20:0] COUNT = 0;
wire RSTb = (COUNT < 10000) ? 1'b0 : 1'b1;

always @(posedge clk)
begin
	if (COUNT < 100000)
		COUNT <= COUNT + 1;	
end

wire [31:0] PINS;

assign UART_TX = PINS[15];
assign GPIO1 = PINS[0];
assign GPIO2 = PINS[1];
assign RED_LED = PINS[8];
assign GREEN_LED = PINS[9];
assign BLUE_LED = PINS[10];

/*assign BB = PINS[19:16];
assign RR = PINS[23:20];
assign GG = PINS[27:24];
assign HS = PINS[28];
assign VS = PINS[29];
*/


slurm16 #(
	.CLOCK_FREQ(CLOCKFREQ)
) slm0 (
	clk,
	RSTb,
	PINS
);

reg [9:0] hcount = 10'd0;
reg [9:0] vcount = 10'd0;

assign RR = (hcount > 47 && hcount < 688 && vcount > 33 && vcount < 513) ? hcount[3:0] & vcount[3:0] : 4'b0000;
assign BB = (hcount > 47 && hcount < 688 && vcount > 33 && vcount < 513) ? hcount[4:1] & vcount[4:1] : 4'b0000;
assign GG = (hcount > 47 && hcount < 688 && vcount > 33 && vcount < 513) ? hcount[5:2] & vcount[5:2] : 4'b0000;

assign HS = (hcount > (800 - 96 - 16)) ? 1'b0 : 1'b1;
assign VS = (vcount > 525 - 12) ? 1'b0 : 1'b1;


always @(posedge clk)
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

endmodule
