module top
(
	output UART_TX,

	output GPIO1,
	output GPIO2,

	output RED_LED,
	output GREEN_LED,
	output BLUE_LED,
	
);

wire clk;

localparam CLOCKFREQ = 6000000;

SB_HFOSC inthosc (
  .CLKHFPU(1'b1),
  .CLKHFEN(1'b1),
  .CLKHF(clk)
);
defparam inthosc.CLKHF_DIV = "0b11";


reg [20:0] COUNT = 0;
wire RSTb = (COUNT < 10000) ? 1'b0 : 1'b1;

always @(posedge clk)
begin
	if (COUNT < 100000)
		COUNT <= COUNT + 1;	
end

wire [15:0] PINS;

assign UART_TX = PINS[15];
assign GPIO1 = PINS[0];
assign GPIO2 = PINS[1];
assign RED_LED = PINS[8];
assign GREEN_LED = PINS[9];
assign BLUE_LED = PINS[10];



slurm16 #(
	.CLOCK_FREQ(CLOCKFREQ)
) slm0 (
	clk,
	RSTb,
	PINS
);



endmodule
