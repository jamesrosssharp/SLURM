/*
 *	slurm16.v: slurm16 processor (next next)
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
	input  [7:0]  INPUT_PINS
);

wire C;
wire Z;
wire S;

wire [4:0] aluOp;

wire [15:0] aluA;
wire [15:0] aluB;

wire [15:0] aluOut;

wire [4:0]  regIn;
wire [4:0]  regOutA;
wire [4:0]  regOutB;
wire [15:0] regIn_data;
wire [15:0] regOutA_data;
wire [15:0] regOutB_data;

wire [15:0] cpuMemoryIn;
wire [15:0] cpuMemoryOut;
wire [15:0] cpuMemoryAddr;
wire cpuMemory_ready;
wire cpuMemory_valid;
wire cpuMemory_wr;

wire [15:0] cpuPort_in;
wire [15:0] cpuPort_out;
wire [15:0] cpuPort_address;
wire cpuPort_rd;
wire cpuPort_wr;

wire [3:0] cpuIRQ;

wire [15:0] spcon_memory_address;
wire [15:0] spcon_memory_data;
wire spcon_rvalid;
wire spcon_rready;
wire [15:0] bg0_memory_address;
wire [15:0] bg0_memory_data;
wire bg0_rvalid;
wire bg0_rready;
wire [15:0] bg1_memory_address;
wire [15:0] bg1_memory_data;
wire bg1_rvalid;
wire bg1_rready;
wire [15:0] ov_memory_address;
wire [15:0] ov_memory_data;
wire ov_rvalid;
wire ov_rready;
wire [15:0] fl_memory_address;
wire [15:0] fl_memory_data;
wire fl_wvalid;
wire fl_wready;
wire [15:0] au_memory_address;
wire [15:0] au_memory_data;
wire au_rvalid;
wire au_rready;

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
 	.memoryIn(cpuMemoryIn),
	.memoryOut(cpuMemoryOut),
	.memoryAddr(cpuMemoryAddr),
	.valid(cpuMemory_valid),
	.ready(cpuMemory_ready),
	.wr(cpuMemory_wr),
	.portIn(cpuPort_in),
	.portOut(cpuPort_out),
	.portAddress(cpuPort_address),
	.portRd(cpuPort_rd),
	.portWr(cpuPort_wr),
	.irq(cpuIRQ)
);


alu 
#(.BITS(16))
alu0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.A(aluA),
	.B(aluB),
	.aluOp(aluOp),
	.aluOut(aluOut),
	.C(C), 
	.Z(Z), 	
	.S(S) 
);

// Memory controller (wrapper to arbiter + ROM overlay)


// Port controller

port_controller
#(.BITS(16), .ADDRESS_BITS(16), .CLOCK_FREQ(CLOCK_FREQ))
pc0
(
	.CLK(CLK),	
	.RSTb(RSTb),
	.ADDRESS(cpuPort_address),
	.DATA_IN(cpuPort_out),
	.DATA_OUT(cpuPort_in),
	.memWR(cpuPort_wr), 
	.memRD(cpuPort_rd), 
	.PINS(PINS),
	.INPUT_PINS(INPUT_PINS),
	.spcon_memory_address(spcon_memory_address),
	.spcon_memory_data(spcon_memory_data),
	.spcon_rvalid(spcon_rvalid),
	.spcon_rready(spcon_rready),
	.bg0_memory_address(bg0_memory_address),
	.bg0_memory_data(bg0_memory_data),
	.bg0_rvalid(bg0_rvalid),
	.bg0_rready(bg0_rready),
	.bg1_memory_address(bg1_memory_address),
	.bg1_memory_data(bg1_memory_data),
	.bg1_rvalid(bg1_rvalid),
	.bg1_rready(bg1_rready),
	.ov_memory_address(ov_memory_address),
	.ov_memory_data(ov_memory_data),
	.ov_rvalid(ov_rvalid),
	.ov_rready(ov_rready),
	.fl_memory_address(fl_memory_address),
	.fl_memory_data(fl_memory_data),
	.fl_wvalid(fl_wvalid),
	.fl_wready(fl_wready),
	.au_memory_address(au_memory_address),
	.au_memory_data(au_memory_data),
	.au_rvalid(au_rvalid),
	.au_rready(au_rready),
	.irq(cpuIRQ)
);

memory_controller
#(.BITS(16), .ADDRESS_BITS(16), .CLOCK_FREQ(CLOCK_FREQ))
mem0
(
	CLK,	
	RSTb,

	spcon_memory_address,
	spcon_memory_data,
	spcon_rvalid, // memory address valid
	spcon_rready,  // memory data valid

	bg0_memory_address,
	bg0_memory_data,
	bg0_rvalid, // memory address valid
	bg0_rready,  // memory data valid

	bg1_memory_address,
	bg1_memory_data,
	bg1_rvalid, // memory address valid
	bg1_rready,  // memory data valid

	ov_memory_address,
	ov_memory_data,
	ov_rvalid, // memory address valid
	ov_rready,  // memory data valid

	fl_memory_address,
	fl_memory_data,
	fl_wvalid, // memory address valid
	fl_wready,  // memory data valid
	
	au_memory_address,
	au_memory_data,
	au_rvalid, // memory address valid
	au_rready,  // memory data valid

	cpuMemoryAddr,
	cpuMemoryOut,
	cpuMemoryIn,
	cpuMemory_valid, // memory address valid
	cpuMemory_wr, // CPU is writing to memory
	cpuMemory_ready  // memory access granted
);


endmodule
