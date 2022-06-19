/* bram.v : dual port memory */

module bram
#(parameter BITS = 16, ADDRESS_BITS = 8)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  RD_ADDRESS,
	output [BITS - 1 : 0] DATA_OUT,
	
	input [ADDRESS_BITS - 1 : 0] WR_ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	input WR  
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

always @(posedge CLK)
begin
	if (WR == 1'b1) begin
		RAM[WR_ADDRESS] <= DATA_IN;
	end

	if ((WR_ADDRESS == RD_ADDRESS) && (WR == 1'b1))
		dout <= DATA_IN;
	else
		dout <= RAM[RD_ADDRESS];
end

endmodule
