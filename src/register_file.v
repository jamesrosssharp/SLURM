/*
 *	Register file: slurm-next
 *
 * 	Use block ram to implement register file, to eliminate high LUT usage due to
 * 	muxes etc
 *
 *	New register assignment:
 *
 *	R0 - R11: general purpose registers
 *	R12: Frame pointer
 *	R13: Stack pointer
 *	R14: Interrupt Link Register
 *	R15: Link Register
 *
 *	The rest of the block RAM is scratch
 *  
 *  We use two block RAMs, and write same value to both block RAMs on write, 
 *  on read there are two register selects to select each of A and B independently
 *
 */

module register_file
#(parameter REG_BITS = 5 /* default 2**5 = 16 registers, 16 dummy */, parameter BITS = 16 /* default 16 bits */)
(
	input CLK,
	input RSTb,
	input [REG_BITS - 1 : 0] regIn,
	input [REG_BITS - 1 : 0] regOutA,
	input [REG_BITS - 1 : 0] regOutB,	
	output [BITS - 1 : 0] regOutA_data,
	output [BITS - 1 : 0] regOutB_data,
	input  [BITS - 1 : 0] regIn_data
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

//	if (regOutA == regIn)
//		outA <= regIn_data;
//	else
		outA <= regFileA[regOutA];

//	if (regOutB == regIn)
//		outB <= regIn_data;
//	else
		outB <= regFileB[regOutB];
end


endmodule
