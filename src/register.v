/* register.v : a register in the register file */

module register
#(parameter BITS = 16)
(
	input  CLK, 		/* CLK 	 */
	input  RSTb,		/* Reset */
	input  [BITS - 1 : 0] inALU,    /* input to register from ALU */
	input  LDb_ALU, 			    /* load register from ALU     */

	input  [BITS - 1 : 0] inM,	    /* input from memory 		 */
	input  LDb_M,				    /* load register from memory  */

	input  [BITS - 1 : 0] inP,		/* input from pipeline */
	input  LDb_P,

	output [BITS - 1 : 0] outA,     /* output to ALU A    	 */
	input  OEb_A, 				    /* output enable         */

	output [BITS - 1 : 0] outB,     /* output to ALU B    	 */
	input  OEb_B, 				    /* output enable         */

	output [BITS - 1 : 0] outM,     /* output to Memory   	 */
	input  OEb_M, 					/* output enable         */

	output [BITS - 1 : 0] outMADDR, /* output to Memory Address */
	input  OEb_MADDR, 				/* output enable         */
	input  INCb						/* increment 			 */			
);

reg [BITS - 1 : 0] Reg;
reg [BITS - 1 : 0] Reg_next;

assign outA = OEb_A ? {BITS{1'bZ}} : Reg;
assign outB = OEb_B ? {BITS{1'bZ}} : Reg;
assign outM = OEb_M ? {BITS{1'bZ}} : Reg;
assign outMADDR = OEb_MADDR ? {BITS{1'bZ}} : Reg;

always @(posedge CLK)
begin
	if (RSTb == 0)
		Reg <= {BITS{1'b0}};
	else
		Reg <= Reg_next;
end

always @(*)
begin
	Reg_next = Reg;

	if (LDb_ALU == 0) 
		Reg_next = inALU;
	else if (LDb_M == 0)
		Reg_next = inM;
	else if (LDb_P == 0)
		Reg_next = inP;
	else if (INCb == 0)
		Reg_next = Reg + 1;
end

endmodule
