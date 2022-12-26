/*
 *	Register file: slurm16
 *
 *	2x Block RAMs used as register file
 *
 *	r0 always reads as zero
 *
 */

module slurm16_cpu_registers
#(parameter REG_BITS = 4 /* default 2**4 = 16 registers */, parameter BITS = 16 /* default 16 bits */)
(
	input CLK,
	input RSTb,
	input [REG_BITS - 1 : 0] regIn,
	input [REG_BITS - 1 : 0] regOutA,
	input [REG_BITS - 1 : 0] regOutB,	
	output reg [BITS - 1 : 0] regOutA_data,
	output reg [BITS - 1 : 0] regOutB_data,
	input  [BITS - 1 : 0] regIn_data
);

reg [BITS - 1: 0] regFileA [2**REG_BITS - 1 : 0];
reg [BITS - 1: 0] regFileB [2**REG_BITS - 1 : 0];

always @(posedge CLK)
begin
	regFileA[regIn] <= regIn_data;
	regFileB[regIn] <= regIn_data;

	if (regOutA == 4'd0)
		regOutA_data <= 16'h0;
	else
		regOutA_data <= regFileA[regOutA];

	if (regOutB == 4'd0)
		regOutB_data <= 16'h0;	
	else
		regOutB_data <= regFileB[regOutB];
end


endmodule
