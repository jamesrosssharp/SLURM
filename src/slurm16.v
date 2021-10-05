/*
 *	slurm16.v: slurm16 processor (next)
 *
 * 	- 16 x 16 bit registers
 *  - 128kB Memory space
 *  - 16 bit RISC instructions
 */

module slurm16 #(
	parameter CLOCK_FREQ = 10000000
) (
	input CLK,
	input RSTb,
	output [31:0] PINS,
	input  [7:0]  INPUT_PINS,

	/* SPI 1 */
	output MO,
    output MO_OE,
    input  MI,
    output SO,
    output SO_OE,
    input  SI,
    output SSb,
    output SSb_OE,
    output SCK_O,
    input  SCK_I,
    output SCK_OE

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

wire memBUSY;
wire [15:0] memoryIn;
wire [15:0] memoryOut;
wire [15:0] memoryAddr;
wire mem_RD;
wire mem_WR;

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

memory_controller
#(.BITS(16), .ADDRESS_BITS(16), .CLOCK_FREQ(CLOCK_FREQ))
mem0
(
	.CLK(CLK),	
	.RSTb(RSTb),
	.ADDRESS(memoryAddr),
	.DATA_IN(memoryOut),
	.DATA_OUT(memoryIn),
	.memWR(mem_WR), 
	.memRD(mem_RD), 
	.memBUSY(memBUSY),
	.PINS(PINS),
	.INPUT_PINS(INPUT_PINS), 
	.MO(MO),
    .MO_OE(MO_OE),
    .MI(MI),
    .SO(SO),
    .SO_OE(SO_OE),
    .SI(SI),
    .SSb(SSb),
    .SSb_OE(SSb_OE),
    .SCK_O(SCK_O),
    .SCK_I(SCK_I),
    .SCK_OE(SCK_OE)
);



endmodule
