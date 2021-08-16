/* rom.v : rom */

module rom
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,	
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	inout [BITS - 1 : 0] DATA,
	input OEb /* output enable */
);

localparam ROM_ADDRESS_BITS = 12;

reg [BITS - 1:0] mem [(1 << ROM_ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA = (OEb == 1'b0) ? dout : {BITS{1'bz}};

initial mem[0] = 16'h1fff;
initial mem[1] = 16'h304f;
initial mem[2] = 16'h1001;
initial mem[3] = 16'h3002;
initial mem[4] = 16'h5410;
initial mem[5] = 16'h2611;
initial mem[6] = 16'h1001;
initial mem[7] = 16'h4001;
initial mem[8] = 16'h1100;
initial mem[9] = 16'h6110;
initial mem[10] = 16'h1100;
initial mem[11] = 16'h6021;
initial mem[12] = 16'h35a1;
initial mem[13] = 16'h1000;
initial mem[14] = 16'h400a;
initial mem[15] = 16'h1000;
initial mem[16] = 16'h4604;
initial mem[17] = 16'hb9fe;
initial mem[18] = 16'h0048;
initial mem[19] = 16'h0065;
initial mem[20] = 16'h006c;
initial mem[21] = 16'h006c;
initial mem[22] = 16'h006f;
initial mem[23] = 16'h0020;
initial mem[24] = 16'h0077;
initial mem[25] = 16'h006f;
initial mem[26] = 16'h0072;
initial mem[27] = 16'h006c;
initial mem[28] = 16'h0064;
initial mem[29] = 16'h0021;
initial mem[30] = 16'h000a;
initial mem[31] = 16'h0000;
 
always @(posedge CLK)
begin
	dout <= mem[ADDRESS];
end

endmodule
