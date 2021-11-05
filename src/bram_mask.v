/* bram.v : dual port memory */

module bram_mask
#(parameter BITS = 16, ADDRESS_BITS = 8)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  RD_ADDRESS,
	output [BITS - 1 : 0] DATA_OUT,
	
	input [ADDRESS_BITS - 1 : 0] WR_ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	input WR,  
	input [15:0] WR_mask
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

integer i;

always @(posedge CLK)
begin
	if (WR == 1'b1) begin
		for (i = 0; i < 16; i = i + 1) begin
			if (WR_mask[i] == 1'b0)
				RAM[WR_ADDRESS][i] <= DATA_IN[i];
		end
	end
	dout <= RAM[RD_ADDRESS];
end

endmodule
