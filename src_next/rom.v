/* rom.v : rom */

module rom
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,	
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	output [BITS - 1 : 0] DATA_OUT
);

reg [BITS - 1:0] ROM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

initial begin
        $display("Loading rom.");
        $readmemh("rom_image.mem", ROM);
end

always @(posedge CLK)
begin
	dout <= ROM[ADDRESS];
end

endmodule
