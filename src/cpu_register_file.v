/*
 *	Register file: slurm16
 *
 *	2x Block RAMs used as register file
 *
 *	r0 always reads as zero
 *
 */

module slurm16_cpu_register_file
#(parameter REG_BITS = 4 /* default 2**4 = 16 registers */, parameter BITS = 16 /* default 16 bits */)
(
	input CLK,
	input RSTb,
	input [REG_BITS - 1 : 0] regIn,
	input [REG_BITS - 1 : 0] regOutA,
	input [REG_BITS - 1 : 0] regOutB,	
	output [BITS - 1 : 0] regOutA_data,
	output [BITS - 1 : 0] regOutB_data,
	input  [BITS - 1 : 0] regIn_data,
	input is_executing
);

reg [BITS - 1: 0] outA;
reg [BITS - 1: 0] outB;

assign regOutA_data = outA;
assign regOutB_data = outB;

reg [BITS - 1: 0] regFileA [2**REG_BITS - 1 : 0];
reg [BITS - 1: 0] regFileB [2**REG_BITS - 1 : 0];

always @(posedge CLK)
begin
	regFileA[regIn] <= regIn_data;
	regFileB[regIn] <= regIn_data;

	if (is_executing) begin
		if (regOutA == 4'd0)
			outA <= 16'h0;
		else if (regOutA == regIn)
			outA <= regIn_data;
		else
			outA <= regFileA[regOutA];

		if (regOutB == 4'd0)
			outB <= 16'h0;	
		else if (regOutB == regIn)
			outB <= regIn_data;
		else
			outB <= regFileB[regOutB];
	end
end


endmodule
