/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	inout [BITS - 1 : 0] DATA,
	input OEb, /* output enable */
	input WRb  /* write memory */  
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA = (OEb == 1'b0) ? dout : {BITS{1'bz}};

always @(posedge CLK)
begin
	if (WRb == 1'b0)
		RAM[ADDRESS] <= DATA;
	else
		dout <= RAM[ADDRESS];
end

endmodule
