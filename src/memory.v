/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */  
	output BUSY,

	input [ADDRESS_BITS - 1 : 0] GFX_ADDRESS,
	input GFX_REQ,
	input [BITS - 1 : 0] GFX_DATA_IN,
	input GFX_WR

);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

reg busy_r;
assign BUSY = busy_r;

always @(posedge CLK)
begin
	if (GFX_REQ == 1'b1) begin
		dout <= RAM[GFX_ADDRESS];
		if (GFX_WR == 1'b1)
			RAM[GFX_ADDRESS] <= GFX_DATA_IN;	
		busy_r = 1'b1;
	end else begin
		busy_r = 1'b0;
		if (WR == 1'b1)
			RAM[ADDRESS] <= DATA_IN;
		dout <= RAM[ADDRESS];
	end
end

endmodule
