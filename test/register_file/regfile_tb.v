`timescale 1 ns / 1 ps
module regfile_tb;

parameter REG_BITS  = 3; 	/* 8 registers */
parameter BITS 		= 16; 	/* 16 bit registers */

reg RSTb = 0;
reg CLK  = 0;

always #10 CLK <= !CLK; // ~ 50MHz

initial begin
    #100 RSTb <= 1;
end

reg [BITS - 1 : 0] 			 inALU 		 = 0;
reg [2**REG_BITS - 1 : 0] 	 LD_reg_ALUb = 8'hff;
reg [BITS - 1 : 0] 			 inM 		 = 0;
reg [2**REG_BITS - 1 : 0] 	 LD_reg_Mb   = 8'hff;
reg [BITS - 1 : 0] 			 inP 		 = 0;
reg [2**REG_BITS - 1 : 0] 	 LD_reg_Pb   = 8'hff;

reg [REG_BITS - 1 : 0] ALU_A_SEL = 0;
reg ALU_A_0_b 					 = 1;
reg ALU_A_1_b 					 = 1;
 
reg [REG_BITS - 1 : 0] ALU_B_SEL = 0;
 
reg M_ENb = 1;

reg [REG_BITS - 1 : 0] 		M_SEL 	  = 0;
reg [REG_BITS - 1 : 0] 		MADDR_SEL = 0;
reg [2**REG_BITS - 1 : 0] 	INCb 	  = 8'hff;	

wire [BITS - 1 : 0] aluA_out;
wire [BITS - 1 : 0] aluB_out;
wire [BITS - 1 : 0] m_out;
wire [BITS - 1 : 0] m_addr_out;

initial begin
    #200 inP <= 16'h3;
	LD_reg_Pb <= 8'hfe;
	#20 inP <= 16'h2;
	LD_reg_Pb <= 8'hfd;
	#20 LD_reg_Pb <= 8'hff;
	ALU_A_SEL <= 3'b000;
	ALU_B_SEL <= 3'b001;
	#20 INCb <= 8'hfe;
end

register_file
#(.REG_BITS(REG_BITS), .BITS(BITS))
regfile
(	CLK,
	RSTb,
	inALU,
	LD_reg_ALUb, 
	inM, 
	LD_reg_Mb,
	inP, 
	LD_reg_Pb,  	
	ALU_A_SEL,	
	ALU_A_0_b,	
	ALU_A_1_b,
	ALU_B_SEL,
	M_ENb,					   	
	M_SEL,
 	MADDR_SEL,   
	INCb,  	 
 	aluA_out,
 	aluB_out,
 	m_out,
	m_addr_out 
);

initial begin
    $dumpfile("regfile.vcd");
    $dumpvars(0, regfile_tb);
    # 100000 $finish;
end

endmodule
