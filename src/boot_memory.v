/* boot_memory.v : boot memory */

module boot_memory
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,	
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR
);

reg [BITS - 1:0] MEM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

initial begin
        $display("Loading rom.");
        $readmemh("rom_image.mem", MEM);
end

always @(posedge CLK)
begin
	if (WR == 1'b1)
		MEM[ADDRESS] <= DATA_IN;
	dout <= MEM[ADDRESS];
end

endmodule
