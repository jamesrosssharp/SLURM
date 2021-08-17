/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WRb  /* write memory */  
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

always @(posedge CLK)
begin
	if (WRb == 1'b0)
		RAM[ADDRESS] <= DATA_IN;
	else
		dout <= RAM[ADDRESS];
end

endmodule
