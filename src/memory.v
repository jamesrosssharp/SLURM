/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */  

	input [ADDRESS_BITS - 1 : 0] GFX_ADDRESS,
	input GFX_VALID,
	output GFX_READY
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

reg ready;

assign GFX_READY = ready;

always @(posedge CLK)
begin
	if (GFX_VALID == 1'b1) begin
			dout <= RAM[GFX_ADDRESS];
			ready <= 1'b1;
	end else begin
		ready <= 1'b0;
		if (WR == 1'b1)
			RAM[ADDRESS] <= DATA_IN;
		else
			dout <= RAM[ADDRESS];
	end
end

endmodule
