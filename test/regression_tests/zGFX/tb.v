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
wire [3:0] R = PINS[23:0];
wire [3:0] G = PINS[27:24];
wire [3:0] B = PINS[19:16];
wire HS = PINS[28];
wire VS = PINS[29];

initial begin 
	#150 RSTb = 1'b1;
end

// Write 12 bits color and HS, VS signals to a file, which we will display and animate later to
// verify gfx core



initial begin
    $dumpvars(0, tb);
	# 20000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.reg0.regFileA[j]);
end

endmodule
