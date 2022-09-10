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
initial mem[1] = 16'h4e00;
initial mem[2] = 16'h1004;
initial mem[3] = 16'h4e0a;
initial mem[4] = 16'h1004;
initial mem[5] = 16'h4e0a;
initial mem[6] = 16'h1004;
initial mem[7] = 16'h4e0a;
initial mem[8] = 16'h1004;
initial mem[9] = 16'h4e0a;
initial mem[10] = 16'h1004;
initial mem[11] = 16'h4e0a;
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
initial mem[33] = 16'h3012;
initial mem[34] = 16'hf010;
initial mem[35] = 16'h1004;
initial mem[36] = 16'h4e00;
initial mem[37] = 16'h1fff;
initial mem[38] = 16'h309f;
initial mem[39] = 16'h1700;
initial mem[40] = 16'hf091;
initial mem[41] = 16'h0101;
initial mem[42] = 16'h0000;
always @(posedge CLK)
begin
  if (WR == 1'b1) mem[ADDRESS] <= DATA_IN; 
       dout <= mem[ADDRESS];
end
endmodule
