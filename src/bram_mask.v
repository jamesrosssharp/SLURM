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
	input [3:0] WR_mask
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

always @(posedge CLK)
begin
	if (WR == 1'b1) begin
		if (WR_mask[0] == 1'b1)
			RAM[WR_ADDRESS][3:0] <= DATA_IN[3:0];
		if (WR_mask[1] == 1'b1)
			RAM[WR_ADDRESS][7:4] <= DATA_IN[7:4];
		if (WR_mask[2] == 1'b1)
			RAM[WR_ADDRESS][11:8] <= DATA_IN[11:8];
		if (WR_mask[3] == 1'b1)
			RAM[WR_ADDRESS][15:12] <= DATA_IN[15:12];
	end
	dout <= RAM[RD_ADDRESS];
end

endmodule
