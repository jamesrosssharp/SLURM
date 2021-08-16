module top
(
	output UART_TX,
	output LED
);

wire clk;

localparam CLOCKFREQ = 12000000;

SB_HFOSC inthosc (
  .CLKHFPU(1'b1),
  .CLKHFEN(1'b1),
  .CLKHF(clk)
);
defparam inthosc.CLKHF_DIV = "0b10";


reg [12:0] COUNT = 0;
wire RSTb = (COUNT < 1000) ? 1'b0 : 1'b1;

always @(posedge clk)
begin
	if (COUNT < 1010)
		COUNT <= COUNT + 1;	
end

wire [15:0] PINS;

assign UART_TX = PINS[15];
assign LED = clk;

slurm16 #(
	.CLOCK_FREQ(CLOCKFREQ)
) slm0 (
	clk,
	RSTb,
	PINS
);



endmodule
