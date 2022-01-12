`timescale 1 ns / 1 ps
module tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

wire [31:0] PINS;
wire [7:0] INPUT_PINS; 

slurm16 #(
.CLOCK_FREQ(10000000)
) cpu0 (
	CLK,
	RSTb,
	PINS,
	INPUT_PINS
);

wire UART_TX = PINS[15];

initial begin 
	#150 RSTb = 1'b1;
end

integer i;

reg [7:0] UART_BYTE = 8'h00;

integer f;

initial begin
    f = $fopen("simout.txt", "w");
end

localparam BAUD_TICK = 1e9/115200;

always begin
	@(negedge UART_TX);
	#(BAUD_TICK/2); // start bit
	UART_BYTE <= 8'h00;
	for (i = 0; i < 8; i += 1) begin
		#BAUD_TICK; // bits
		UART_BYTE <= {UART_TX, UART_BYTE[7:1]};	
	end
	#BAUD_TICK; // stop bit
	$fwrite(f, "%c", UART_BYTE);
end


initial begin
    $dumpvars(0, tb);
	# 2000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.cpu0.reg0.regFileA[j]);
end

endmodule
