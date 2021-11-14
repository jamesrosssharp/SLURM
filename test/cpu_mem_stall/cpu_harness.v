/*
 *	cpu_harness.v: slurm16 processor harness
 *
 */

module cpu_harness #(
	parameter CLOCK_FREQ = 10000000
) (
	input CLK,
	input RSTb,
	input  memBUSY,
	input [15:0] memoryIn,
	output [15:0] memoryOut,
	output [15:0] memoryAddr,
	output mem_RD,
	output mem_WR
);

wire C;
wire Z;
wire S;

wire [4:0] aluOp;

wire [15:0] aluA;
wire [15:0] aluB;

wire [15:0] aluOut;

wire [4:0] regIn;
wire [4:0] regOutA;
wire [4:0] regOutB;
wire [15:0] regIn_data;
wire [15:0] regOutA_data;
wire [15:0] regOutB_data;

register_file
#(.REG_BITS(5), .BITS(16)) reg0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.regIn(regIn),
	.regOutA(regOutA),
	.regOutB(regOutB),	
	.regOutA_data(regOutA_data),
	.regOutB_data(regOutB_data),
	.regIn_data(regIn_data)
);

pipeline16 pip0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.C(C),	
	.Z(Z),
	.S(S),	
	.aluOp(aluOp),
	.aluA(aluA),
	.aluB(aluB),
	.aluOut(aluOut),
	.regFileIn(regIn_data),
	.regWrAddr(regIn),
	.regARdAddr(regOutA),
	.regBRdAddr(regOutB),
	.regA(regOutA_data),
	.regB(regOutB_data),
	.BUSY(memBUSY),
	.memoryIn(memoryIn),
	.memoryOut(memoryOut),
	.memoryAddr(memoryAddr),
	.mem_RD(mem_RD),
	.mem_WR(mem_WR)  
);


alu 
#(.BITS(16))
alu0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.A_in(aluA),
	.B_in(aluB),
	.aluOp_in(aluOp),
	.aluOut(aluOut),
	.C(C), 
	.Z(Z), 	
	.S(S) 
);

endmodule
