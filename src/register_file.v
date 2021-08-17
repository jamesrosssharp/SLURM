/* register_file.v : a register file  */

module register_file
#(parameter REG_BITS = 3 /* default 2**3 = 8 registers */, parameter BITS = 16 /* default 16 bits */)
(
	input CLK,
	input RSTb,
	input [BITS - 1 : 0] 		inALU,
	input [2**REG_BITS - 1 : 0] LD_reg_ALUb, /* Active low bit vector to load
												register(s) from ALU output */
	input [BITS - 1 : 0] 		inM, 
	input [2**REG_BITS - 1 : 0] LD_reg_Mb,  /* Active low bit vector to load
												register(s) from memory */
	input [BITS - 1 : 0] 		inP, 
	input [2**REG_BITS - 1 : 0] LD_reg_Pb,  /* Active low bit vector to load
												register(s) from pipeline (constants in instruction words etc) */

	input [REG_BITS  - 1: 0] ALU_A_SEL,   		/* index of register driving ALU A bus */
 	input [REG_BITS - 1: 0]  ALU_B_SEL,   		/* index of register driving ALU B bus */

	input M_ENb,					  /* enable register to drive memory bus */
 	input [REG_BITS - 1 : 0] M_SEL,       /* index of register driving memory
												bus */

 	input [REG_BITS - 1 : 0] MADDR_SEL,   /* index of register driving memory 
											  address bus */
	input MADDR_ALU_SELb,				/* select MADDR from ALU output */
	input MADDR_POUT_SELb,				/* select MADDR from POUT */


	input [2**REG_BITS - 1 : 0] INCb,  	  /* active low register increment */
	input [2**REG_BITS - 1 : 0] DECb,  	  /* active low register deccrement */

	input ALU_B_from_inP_b,	/* 1 = ALU B from registers, 0 = ALU B from inP (pipeline constant register) */

 	output [BITS - 1 : 0] aluA_out,
 	output [BITS - 1 : 0] aluB_out,
 	output [BITS - 1 : 0] m_out,
	output [BITS - 1 : 0] m_addr_out 
);


wire [BITS - 1:0] aluB_wr;


wire [BITS - 1:0] out [2**REG_BITS - 1:0];

assign aluA_out = out[ALU_A_SEL];
assign aluB_out = (ALU_B_from_inP_b == 1'b0) ? inP : out[ALU_B_SEL];
assign m_out = (M_ENb == 1'b0) ? out[M_SEL] : {BITS{1'b0}};

reg [BITS - 1 : 0] m_addr_out_r;
assign m_addr_out = m_addr_out_r;

always @(*)
begin
	if (MADDR_ALU_SELb == 1'b0)
		m_addr_out_r = inALU;
	else if (MADDR_POUT_SELb == 1'b0)
		m_addr_out_r = inP;
	else
		m_addr_out_r = out[MADDR_SEL];
end

genvar j;
generate
	for (j = 0; j < 2**REG_BITS; j = j+1)
		begin: Gen_Modules
			register #(BITS) register_inst (
				CLK, 		
				RSTb,	
				inALU,    
				LD_reg_ALUb[j], 
				inM,	
				LD_reg_Mb[j],
				inP,
				LD_reg_Pb[j],
				out[j],
				INCb[j],	
				DECb[j]	
			);
		end
endgenerate

endmodule 
