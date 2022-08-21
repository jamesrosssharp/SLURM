/*
 *
 *	To solve the numerous problems with the memory interface,
 *	we introduce a simple instruction cache. This should improve
 *	performance and allow us to restructure the cpu memory interface.
 *
 *	We may make the cache burst read to improve performance.
 *
 */


module cpu_instruction_cache #(
	parameter CACHE_DEPTH_BITS = 8,
	parameter CACHE_WIDTH_BITS = 32
) (
	input CLK,
	input RSTb,

	input [14:0] cache_request_address, /* request address from the cache */
	
	output [CACHE_WIDTH_BITS - 1:0] address_data,

	output cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	/* ports to memory interface */
	output [14:0] memory_address,
	output memory_rd_req,	/* we are requesting a read - we will get the value in two cycles time */
	
	input memory_success,	/* Arbiter will assert this when we our request was successful */
	input [14:0]  memory_requested_address,	/* Requested address will come back to us */ 
	input [15:0]  memory_data, /* our data */

	input will_queue

);

reg [31:0] data_out;

assign address_data = data_out;

wire [CACHE_DEPTH_BITS - 1 : 0] bram_wr_addr = memory_requested_address[7:0];
wire  [CACHE_WIDTH_BITS - 1 : 0 ] bram_wr_data = {memory_requested_address, 1'b0, memory_data};  
wire wr_bram = memory_success;

/*bram
#(.BITS(CACHE_WIDTH_BITS), .ADDRESS_BITS(CACHE_DEPTH_BITS)) mem0
(
	.CLK(CLK),
	.RD_ADDRESS(cache_request_address[7:0]),
	.DATA_OUT(data_out),
	.WR_ADDRESS(bram_wr_addr),
	.DATA_IN(bram_wr_data),	// In the spare bit we could hide a dirty bit or something
	.WR(wr_bram)
);
*/

reg [CACHE_WIDTH_BITS - 1:0] RAM [(1 << CACHE_DEPTH_BITS) - 1:0];

always @(posedge CLK)
begin
	if (wr_bram == 1'b1) begin
		RAM[bram_wr_addr] <= bram_wr_data;
	end
	data_out <= RAM[cache_request_address[7:0]];
end

localparam MEM_ADDRESS_X_BITS = 5;

reg [14:0] 	address_x, address_xx;
reg [MEM_ADDRESS_X_BITS - 1:0] 	mem_address_x;
assign memory_address = {address_xx[14: MEM_ADDRESS_X_BITS - 1], mem_address_x[MEM_ADDRESS_X_BITS - 2:0]};

reg 	mem_rd_req_r;
assign 	memory_rd_req = mem_rd_req_r; 

assign cache_miss = (address_x != data_out[31:17]) || (data_out[16] != 1'b0);	// bit 16 must be zero to be valid
reg cache_miss_prev;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_xx 	<= 15'd0;
		address_x 	<= 15'd0;
		mem_address_x 	<= {MEM_ADDRESS_X_BITS{1'b0}};
		mem_rd_req_r 	<= 1'b1;
		cache_miss_prev <= 1'b0;
	end
	else begin
		address_xx 	<= address_x;
		address_x 	<= cache_request_address;

		cache_miss_prev <= cache_miss;

		if (((address_x != address_xx) && cache_miss) || (cache_miss == 1'b1 && cache_miss_prev == 1'b1) ) begin	// If we just got a new request, then we will service it.
			mem_address_x 		<= {1'b0, address_x[MEM_ADDRESS_X_BITS - 2:0]};
			mem_rd_req_r 		<= 1'b1;
		end
		else if ((mem_address_x[MEM_ADDRESS_X_BITS - 1] != 1'b1) && (will_queue == 1'b1)) begin
			mem_address_x 		<= mem_address_x + 1;	// Fill cache in our spare time (we need to keep the memory pipeline filled)
			mem_rd_req_r 		<= 1'b1;
		end
		else if (mem_address_x[MEM_ADDRESS_X_BITS - 1] == 1'b1)
			mem_rd_req_r 		<= 1'b0;
				
	end
end


initial RAM[0] = 32'h00010000;
initial RAM[1] = 32'h00010000;
initial RAM[2] = 32'h00010000;
initial RAM[3] = 32'h00010000;
initial RAM[4] = 32'h00010000;
initial RAM[5] = 32'h00010000;
initial RAM[6] = 32'h00010000;
initial RAM[7] = 32'h00010000;
initial RAM[8] = 32'h00010000;
initial RAM[9] = 32'h00010000;
initial RAM[10] = 32'h00010000;
initial RAM[11] = 32'h00010000;
initial RAM[12] = 32'h00010000;
initial RAM[13] = 32'h00010000;
initial RAM[14] = 32'h00010000;
initial RAM[15] = 32'h00010000;
initial RAM[16] = 32'h00010000;
initial RAM[17] = 32'h00010000;
initial RAM[18] = 32'h00010000;
initial RAM[19] = 32'h00010000;
initial RAM[20] = 32'h00010000;
initial RAM[21] = 32'h00010000;
initial RAM[22] = 32'h00010000;
initial RAM[23] = 32'h00010000;
initial RAM[24] = 32'h00010000;
initial RAM[25] = 32'h00010000;
initial RAM[26] = 32'h00010000;
initial RAM[27] = 32'h00010000;
initial RAM[28] = 32'h00010000;
initial RAM[29] = 32'h00010000;
initial RAM[30] = 32'h00010000;
initial RAM[31] = 32'h00010000;
initial RAM[32] = 32'h00010000;
initial RAM[33] = 32'h00010000;
initial RAM[34] = 32'h00010000;
initial RAM[35] = 32'h00010000;
initial RAM[36] = 32'h00010000;
initial RAM[37] = 32'h00010000;
initial RAM[38] = 32'h00010000;
initial RAM[39] = 32'h00010000;
initial RAM[40] = 32'h00010000;
initial RAM[41] = 32'h00010000;
initial RAM[42] = 32'h00010000;
initial RAM[43] = 32'h00010000;
initial RAM[44] = 32'h00010000;
initial RAM[45] = 32'h00010000;
initial RAM[46] = 32'h00010000;
initial RAM[47] = 32'h00010000;
initial RAM[48] = 32'h00010000;
initial RAM[49] = 32'h00010000;
initial RAM[50] = 32'h00010000;
initial RAM[51] = 32'h00010000;
initial RAM[52] = 32'h00010000;
initial RAM[53] = 32'h00010000;
initial RAM[54] = 32'h00010000;
initial RAM[55] = 32'h00010000;
initial RAM[56] = 32'h00010000;
initial RAM[57] = 32'h00010000;
initial RAM[58] = 32'h00010000;
initial RAM[59] = 32'h00010000;
initial RAM[60] = 32'h00010000;
initial RAM[61] = 32'h00010000;
initial RAM[62] = 32'h00010000;
initial RAM[63] = 32'h00010000;
initial RAM[64] = 32'h00010000;
initial RAM[65] = 32'h00010000;
initial RAM[66] = 32'h00010000;
initial RAM[67] = 32'h00010000;
initial RAM[68] = 32'h00010000;
initial RAM[69] = 32'h00010000;
initial RAM[70] = 32'h00010000;
initial RAM[71] = 32'h00010000;
initial RAM[72] = 32'h00010000;
initial RAM[73] = 32'h00010000;
initial RAM[74] = 32'h00010000;
initial RAM[75] = 32'h00010000;
initial RAM[76] = 32'h00010000;
initial RAM[77] = 32'h00010000;
initial RAM[78] = 32'h00010000;
initial RAM[79] = 32'h00010000;
initial RAM[80] = 32'h00010000;
initial RAM[81] = 32'h00010000;
initial RAM[82] = 32'h00010000;
initial RAM[83] = 32'h00010000;
initial RAM[84] = 32'h00010000;
initial RAM[85] = 32'h00010000;
initial RAM[86] = 32'h00010000;
initial RAM[87] = 32'h00010000;
initial RAM[88] = 32'h00010000;
initial RAM[89] = 32'h00010000;
initial RAM[90] = 32'h00010000;
initial RAM[91] = 32'h00010000;
initial RAM[92] = 32'h00010000;
initial RAM[93] = 32'h00010000;
initial RAM[94] = 32'h00010000;
initial RAM[95] = 32'h00010000;
initial RAM[96] = 32'h00010000;
initial RAM[97] = 32'h00010000;
initial RAM[98] = 32'h00010000;
initial RAM[99] = 32'h00010000;
initial RAM[100] = 32'h00010000;
initial RAM[101] = 32'h00010000;
initial RAM[102] = 32'h00010000;
initial RAM[103] = 32'h00010000;
initial RAM[104] = 32'h00010000;
initial RAM[105] = 32'h00010000;
initial RAM[106] = 32'h00010000;
initial RAM[107] = 32'h00010000;
initial RAM[108] = 32'h00010000;
initial RAM[109] = 32'h00010000;
initial RAM[110] = 32'h00010000;
initial RAM[111] = 32'h00010000;
initial RAM[112] = 32'h00010000;
initial RAM[113] = 32'h00010000;
initial RAM[114] = 32'h00010000;
initial RAM[115] = 32'h00010000;
initial RAM[116] = 32'h00010000;
initial RAM[117] = 32'h00010000;
initial RAM[118] = 32'h00010000;
initial RAM[119] = 32'h00010000;
initial RAM[120] = 32'h00010000;
initial RAM[121] = 32'h00010000;
initial RAM[122] = 32'h00010000;
initial RAM[123] = 32'h00010000;
initial RAM[124] = 32'h00010000;
initial RAM[125] = 32'h00010000;
initial RAM[126] = 32'h00010000;
initial RAM[127] = 32'h00010000;
initial RAM[128] = 32'h00010000;
initial RAM[129] = 32'h00010000;
initial RAM[130] = 32'h00010000;
initial RAM[131] = 32'h00010000;
initial RAM[132] = 32'h00010000;
initial RAM[133] = 32'h00010000;
initial RAM[134] = 32'h00010000;
initial RAM[135] = 32'h00010000;
initial RAM[136] = 32'h00010000;
initial RAM[137] = 32'h00010000;
initial RAM[138] = 32'h00010000;
initial RAM[139] = 32'h00010000;
initial RAM[140] = 32'h00010000;
initial RAM[141] = 32'h00010000;
initial RAM[142] = 32'h00010000;
initial RAM[143] = 32'h00010000;
initial RAM[144] = 32'h00010000;
initial RAM[145] = 32'h00010000;
initial RAM[146] = 32'h00010000;
initial RAM[147] = 32'h00010000;
initial RAM[148] = 32'h00010000;
initial RAM[149] = 32'h00010000;
initial RAM[150] = 32'h00010000;
initial RAM[151] = 32'h00010000;
initial RAM[152] = 32'h00010000;
initial RAM[153] = 32'h00010000;
initial RAM[154] = 32'h00010000;
initial RAM[155] = 32'h00010000;
initial RAM[156] = 32'h00010000;
initial RAM[157] = 32'h00010000;
initial RAM[158] = 32'h00010000;
initial RAM[159] = 32'h00010000;
initial RAM[160] = 32'h00010000;
initial RAM[161] = 32'h00010000;
initial RAM[162] = 32'h00010000;
initial RAM[163] = 32'h00010000;
initial RAM[164] = 32'h00010000;
initial RAM[165] = 32'h00010000;
initial RAM[166] = 32'h00010000;
initial RAM[167] = 32'h00010000;
initial RAM[168] = 32'h00010000;
initial RAM[169] = 32'h00010000;
initial RAM[170] = 32'h00010000;
initial RAM[171] = 32'h00010000;
initial RAM[172] = 32'h00010000;
initial RAM[173] = 32'h00010000;
initial RAM[174] = 32'h00010000;
initial RAM[175] = 32'h00010000;
initial RAM[176] = 32'h00010000;
initial RAM[177] = 32'h00010000;
initial RAM[178] = 32'h00010000;
initial RAM[179] = 32'h00010000;
initial RAM[180] = 32'h00010000;
initial RAM[181] = 32'h00010000;
initial RAM[182] = 32'h00010000;
initial RAM[183] = 32'h00010000;
initial RAM[184] = 32'h00010000;
initial RAM[185] = 32'h00010000;
initial RAM[186] = 32'h00010000;
initial RAM[187] = 32'h00010000;
initial RAM[188] = 32'h00010000;
initial RAM[189] = 32'h00010000;
initial RAM[190] = 32'h00010000;
initial RAM[191] = 32'h00010000;
initial RAM[192] = 32'h00010000;
initial RAM[193] = 32'h00010000;
initial RAM[194] = 32'h00010000;
initial RAM[195] = 32'h00010000;
initial RAM[196] = 32'h00010000;
initial RAM[197] = 32'h00010000;
initial RAM[198] = 32'h00010000;
initial RAM[199] = 32'h00010000;
initial RAM[200] = 32'h00010000;
initial RAM[201] = 32'h00010000;
initial RAM[202] = 32'h00010000;
initial RAM[203] = 32'h00010000;
initial RAM[204] = 32'h00010000;
initial RAM[205] = 32'h00010000;
initial RAM[206] = 32'h00010000;
initial RAM[207] = 32'h00010000;
initial RAM[208] = 32'h00010000;
initial RAM[209] = 32'h00010000;
initial RAM[210] = 32'h00010000;
initial RAM[211] = 32'h00010000;
initial RAM[212] = 32'h00010000;
initial RAM[213] = 32'h00010000;
initial RAM[214] = 32'h00010000;
initial RAM[215] = 32'h00010000;
initial RAM[216] = 32'h00010000;
initial RAM[217] = 32'h00010000;
initial RAM[218] = 32'h00010000;
initial RAM[219] = 32'h00010000;
initial RAM[220] = 32'h00010000;
initial RAM[221] = 32'h00010000;
initial RAM[222] = 32'h00010000;
initial RAM[223] = 32'h00010000;
initial RAM[224] = 32'h00010000;
initial RAM[225] = 32'h00010000;
initial RAM[226] = 32'h00010000;
initial RAM[227] = 32'h00010000;
initial RAM[228] = 32'h00010000;
initial RAM[229] = 32'h00010000;
initial RAM[230] = 32'h00010000;
initial RAM[231] = 32'h00010000;
initial RAM[232] = 32'h00010000;
initial RAM[233] = 32'h00010000;
initial RAM[234] = 32'h00010000;
initial RAM[235] = 32'h00010000;
initial RAM[236] = 32'h00010000;
initial RAM[237] = 32'h00010000;
initial RAM[238] = 32'h00010000;
initial RAM[239] = 32'h00010000;
initial RAM[240] = 32'h00010000;
initial RAM[241] = 32'h00010000;
initial RAM[242] = 32'h00010000;
initial RAM[243] = 32'h00010000;
initial RAM[244] = 32'h00010000;
initial RAM[245] = 32'h00010000;
initial RAM[246] = 32'h00010000;
initial RAM[247] = 32'h00010000;
initial RAM[248] = 32'h00010000;
initial RAM[249] = 32'h00010000;
initial RAM[250] = 32'h00010000;
initial RAM[251] = 32'h00010000;
initial RAM[252] = 32'h00010000;
initial RAM[253] = 32'h00010000;
initial RAM[254] = 32'h00010000;
initial RAM[255] = 32'h00010000;

endmodule
