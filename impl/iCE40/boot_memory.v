/* boot_memory.v : boot memory */

module boot_memory
#(parameter BITS = 16, ADDRESS_BITS = 8)
(
  input CLK,
  input [ADDRESS_BITS - 1 : 0]  ADDRESS,
  input [BITS - 1 : 0] DATA_IN,
  output [BITS - 1 : 0] DATA_OUT,
  input WR
);

localparam ROM_ADDRESS_BITS = 8;

reg [BITS - 1:0] mem [(1 << ROM_ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;
assign DATA_OUT = dout;
initial mem[0] = 16'h1004;
initial mem[1] = 16'h4e0a;
initial mem[2] = 16'h1009;
initial mem[3] = 16'h4e0c;
initial mem[4] = 16'h1009;
initial mem[5] = 16'h4e0c;
initial mem[6] = 16'h1009;
initial mem[7] = 16'h4e0c;
initial mem[8] = 16'h1009;
initial mem[9] = 16'h4e0c;
initial mem[10] = 16'h1009;
initial mem[11] = 16'h4e0c;
initial mem[12] = 16'h0000;
initial mem[13] = 16'h0000;
initial mem[14] = 16'h0000;
initial mem[15] = 16'h0000;
initial mem[16] = 16'h0000;
initial mem[17] = 16'h0000;
initial mem[18] = 16'h0000;
initial mem[19] = 16'h0000;
initial mem[20] = 16'h0000;
initial mem[21] = 16'h0000;
initial mem[22] = 16'h0000;
initial mem[23] = 16'h0000;
initial mem[24] = 16'h0000;
initial mem[25] = 16'h0000;
initial mem[26] = 16'h0000;
initial mem[27] = 16'h0000;
initial mem[28] = 16'h0000;
initial mem[29] = 16'h0000;
initial mem[30] = 16'h0000;
initial mem[31] = 16'h0000;
initial mem[32] = 16'h1004;
initial mem[33] = 16'h3011;
initial mem[34] = 16'hf010;
initial mem[35] = 16'h1004;
initial mem[36] = 16'h4e00;
initial mem[37] = 16'h3012;
initial mem[38] = 16'h1400;
initial mem[39] = 16'hf012;
initial mem[40] = 16'h1002;
initial mem[41] = 16'h3048;
initial mem[42] = 16'h1fff;
initial mem[43] = 16'h303f;
initial mem[44] = 16'h3331;
initial mem[45] = 16'h1005;
initial mem[46] = 16'h4108;
initial mem[47] = 16'h3341;
initial mem[48] = 16'h1005;
initial mem[49] = 16'h4104;
initial mem[50] = 16'h3018;
initial mem[51] = 16'h1400;
initial mem[52] = 16'hf000;
initial mem[53] = 16'h1400;
initial mem[54] = 16'hf011;
initial mem[55] = 16'h1010;
initial mem[56] = 16'h3030;
initial mem[57] = 16'h1400;
initial mem[58] = 16'hf035;
initial mem[59] = 16'h1ff0;
initial mem[60] = 16'h3030;
initial mem[61] = 16'h1400;
initial mem[62] = 16'hf036;
initial mem[63] = 16'h3018;
initial mem[64] = 16'h1700;
initial mem[65] = 16'hf010;
initial mem[66] = 16'h1fff;
initial mem[67] = 16'h309f;
initial mem[68] = 16'h1700;
initial mem[69] = 16'hf091;
initial mem[70] = 16'h0601;
initial mem[71] = 16'h3031;
initial mem[72] = 16'h1400;
initial mem[73] = 16'hf032;
initial mem[74] = 16'h0700;
initial mem[75] = 16'h0600;
initial mem[76] = 16'h1020;
initial mem[77] = 16'h4e00;
initial mem[78] = 16'h1fff;
initial mem[79] = 16'h309f;
initial mem[80] = 16'h1700;
initial mem[81] = 16'hf091;
initial mem[82] = 16'h0101;
initial mem[83] = 16'h0000;
always @(posedge CLK)
begin
  if (WR == 1'b1) mem[ADDRESS] <= DATA_IN; 
       dout <= mem[ADDRESS];
end
endmodule
