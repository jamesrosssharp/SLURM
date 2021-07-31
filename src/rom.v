/* rom.v : rom */

module rom
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,	
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	inout [BITS - 1 : 0] DATA,
	input OEb /* output enable */
);

reg [BITS - 1:0] ROM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA = (OEb == 1'b0) ? dout : {BITS{1'bz}};

initial begin
        $display("Loading rom.");
        $readmemh("rom_image.mem", ROM);
end

always @(posedge CLK)
begin
	dout <= ROM[ADDRESS];
end

endmodule
