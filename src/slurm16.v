/*
 *	slurm16.v: slurm16 processor
 *
 * 	- 8x 16 bit registers
 *  - 64kB Memory space
 *  - 16 bit RISC instructions
 */

module slurm16 (
	input CLK,
	input RSTb	
);

wire C;
wire Z;
wire S;

wire [3:0] aluOp;
wire [15:0] pout;

wire [7:0] LD_reg_ALUb;
wire [7:0] LD_reg_Mb;
wire [7:0] LD_reg_Pb;

wire [2:0] ALU_A_SEL;
wire [2:0] ALU_B_SEL;

wire M_ENb;
wire [2:0] M_SEL;
wire [2:0] MADDR_SEL;

wire [7:0] INCb;
wire [7:0] DECb;

wire ALU_B_from_inP_b;

wire mem_OEb;
wire mem_WRb;

wire [15:0] mem_address;
wire [15:0] mem_data;

wire [15:0] aluA;
wire [15:0] aluB;
wire [15:0] aluOut;

pipeline16 pip0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.memoryIn(mem_data),
	.C(C),	
	.Z(Z),
	.S(S),	
	.aluOp(aluOp),
	.pout(pout),	
	.LD_reg_ALUb(LD_reg_ALUb), 	
	.LD_reg_Mb(LD_reg_Mb), 
	.LD_reg_Pb(LD_reg_Pb), 
	.ALU_A_SEL(ALU_A_SEL),   		
 	.ALU_B_SEL(ALU_B_SEL),   	
	.M_ENb(M_ENb),					  
	.M_SEL(M_SEL), 
	.MADDR_SEL(MADDR_SEL), 
	.INCb(INCb),  	  
	.DECb(DECb),  	  
	.ALU_B_from_inP_b(ALU_B_from_inP_b),	
	.mem_OEb(mem_OEb), 
	.mem_WRb(mem_WRb)  
);

memory_controller
#(.BITS(16), .ADDRESS_BITS(16))
mem0
(
	.CLK(CLK),	
	.ADDRESS(mem_address),
	.DATA(mem_data),
	.OEb(mem_OEb), 
	.WRb(mem_WRb) 
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

register_file
#(.REG_BITS(3), .BITS(16))
reg0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.inALU(aluOut),
	.LD_reg_ALUb(LD_reg_ALUb), 
	.inM(mem_data), 
	.LD_reg_Mb(LD_reg_Mb),
	.inP(pout), 
	.LD_reg_Pb(LD_reg_Pb), 
	.ALU_A_SEL(ALU_A_SEL),   		
 	.ALU_B_SEL(ALU_B_SEL),   	
	.M_ENb(M_ENb),					 
 	.M_SEL(M_SEL),    
 	.MADDR_SEL(MADDR_SEL),	
	.INCb(INCb), 
	.DECb(DECb), 
	.ALU_B_from_inP_b(ALU_B_from_inP_b),	
 	.aluA_out(aluA),
 	.aluB_out(aluB),
 	.m_out(mem_data),
	.m_addr_out(mem_address) 
);

endmodule
