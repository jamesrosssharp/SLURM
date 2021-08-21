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

	output [BITS - 1 : 0] out,     /* output (muxed in register file)   	 */

	input  INCb,					/* increment 			 */			
	input  DECb						/* decrement 			 */			
);

reg [BITS - 1 : 0] Reg = {BITS{1'b0}};
reg [BITS - 1 : 0] Reg_next;

assign out =  Reg;

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		Reg <= {BITS{1'b0}};
	else
		Reg <= Reg_next;
end

always @(*)
begin
	Reg_next = Reg;

	if (LDb_ALU == 1'b0) 
		Reg_next = inALU;
	else if (LDb_M == 1'b0)
		Reg_next = inM;
	else if (LDb_P == 1'b0)
		Reg_next = inP;
	else if (INCb == 1'b0)
		Reg_next = Reg + 1;
	else if (DECb == 1'b0)
		Reg_next = Reg - 1;
end

endmodule
